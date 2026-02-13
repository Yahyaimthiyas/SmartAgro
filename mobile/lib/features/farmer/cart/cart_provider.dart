import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CartItem {
  final String productId;
  final String nameTa;
  final String nameEn;
  final num price;
  final String unitTa;
  final String unitEn;
  final String? imageUrl;
  int quantity;
  DateTime lastUpdated;

  CartItem({
    required this.productId,
    required this.nameTa,
    required this.nameEn,
    required this.price,
    required this.unitTa,
    required this.unitEn,
    required this.quantity,
    this.imageUrl,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'nameTa': nameTa,
      'nameEn': nameEn,
      'price': price,
      'unitTa': unitTa,
      'unitEn': unitEn,
      'imageUrl': imageUrl,
      'quantity': quantity,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      productId: map['productId'] as String,
      nameTa: (map['nameTa'] ?? '') as String,
      nameEn: (map['nameEn'] ?? '') as String,
      price: (map['price'] as num?) ?? 0,
      unitTa: (map['unitTa'] ?? '') as String,
      unitEn: (map['unitEn'] ?? '') as String,
      quantity: (map['quantity'] as int?) ?? 1,
      imageUrl: map['imageUrl'] as String?,
      lastUpdated: map['lastUpdated'] != null ? DateTime.tryParse(map['lastUpdated']) : null,
    );
  }
}

class CartProvider with ChangeNotifier {
  static const _storageKey = 'cart_data_v2';
  final Map<String, CartItem> _items = {};
  bool _isLoading = false;

  CartProvider() {
    _initializeCart();
  }

  List<CartItem> get items => _items.values.toList();
  int get itemCount => _items.values.fold(0, (sum, item) => sum + item.quantity);
  num get totalAmount => _items.values.fold(0, (sum, item) => sum + (item.price * item.quantity));
  bool get isLoading => _isLoading;

  Future<void> _initializeCart() async {
    _isLoading = true;
    notifyListeners();

    // 1. Load Local immediate for UI
    await _loadFromPrefs();
    
    // 2. Background Sync & Validate
    _performBackgroundSync();
  }

  Future<void> _performBackgroundSync() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      // 3. Fetch Cloud
      final cloudItems = await _fetchFromFirestore(user.uid);
      
      // 4. Merge (Cloud items updated recently win, else keep local)
      if (cloudItems.isNotEmpty) {
        _mergeItems(cloudItems);
      }

      // 5. Validate Stock & Price
      await _validateStockAndPrices();
      
      // 6. Save back
      await _saveToPrefs();
      if (_items.isNotEmpty) _syncToFirestore();
      
    } catch (e) {
      print("Cart Sync Error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void addItem({
    required String productId,
    required String nameTa,
    required String nameEn,
    required num price,
    required String unitTa,
    required String unitEn,
    String? imageUrl,
    int quantity = 1,
  }) {
    // ABUSE PROTECTION: Limit unique items to 20
    if (!_items.containsKey(productId) && _items.length >= 20) {
      return; 
    }

    if (_items.containsKey(productId)) {
      _items[productId]!.quantity += quantity;
      _items[productId]!.lastUpdated = DateTime.now();
    } else {
      _items[productId] = CartItem(
        productId: productId,
        nameTa: nameTa,
        nameEn: nameEn,
        price: price,
        unitTa: unitTa,
        unitEn: unitEn,
        quantity: quantity,
        imageUrl: imageUrl,
      );
    }
    _saveToPrefs();
    _syncToFirestore();
    notifyListeners();
  }

  void updateQuantity(String productId, int quantity) {
    if (!_items.containsKey(productId)) return;
    if (quantity <= 0) {
      _items.remove(productId);
    } else {
      _items[productId]!.quantity = quantity;
      _items[productId]!.lastUpdated = DateTime.now();
    }
    _saveToPrefs();
    _syncToFirestore();
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.remove(productId);
    _saveToPrefs();
    _syncToFirestore();
    notifyListeners();
  }

  void clear() {
    _items.clear();
    _clearStorage(); // Clear local
    _deleteCloudCart(); // Clear cloud
    notifyListeners();
  }

  // --- Persistence & Sync Logic ---

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'version': 2,
        'timestamp': DateTime.now().toIso8601String(),
        'items': _items.values.map((e) => e.toMap()).toList(),
      };
      await prefs.setString(_storageKey, jsonEncode(data));
    } catch (_) {}
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null) return;

      final decoded = jsonDecode(raw);
      final list = decoded['items'] as List;
      
      for (final itemMap in list) {
        final item = CartItem.fromMap(itemMap);
        _items[item.productId] = item;
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _clearStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  Future<void> _syncToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Saves the entire cart as a single document 'data/cart' subcollection
      // Structure: users/{uid}/cart/active
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .doc('active')
          .set({
        'lastUpdated': FieldValue.serverTimestamp(),
        'items': _items.values.map((e) => e.toMap()).toList(),
        'totalAmount': totalAmount,
        'itemCount': itemCount,
      });
    } catch (e) {
      print("Firestore Sync Fail: $e");
    }
  }

  Future<List<CartItem>> _fetchFromFirestore(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('cart')
          .doc('active')
          .get();

      if (!doc.exists) return [];

      final data = doc.data() ?? {};
      final list = data['items'] as List? ?? [];
      
      return list.map((e) => CartItem.fromMap(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> _deleteCloudCart() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .doc('active')
          .delete();
    } catch (_) {}
  }

  void _mergeItems(List<CartItem> cloudItems) {
    for (final cItem in cloudItems) {
      if (_items.containsKey(cItem.productId)) {
        // Conflict: Use the one with latest timestamp, or Cloud if tied
        // For simplicity, if cloud qty > local qty, take cloud? 
        // Better: Use internal 'lastUpdated'.
        final local = _items[cItem.productId]!;
        if (cItem.lastUpdated.isAfter(local.lastUpdated)) {
          _items[cItem.productId] = cItem;
        }
      } else {
        _items[cItem.productId] = cItem;
      }
    }
  }

  Future<void> _validateStockAndPrices() async {
    // Batch checks are ideal, but for simplicity looping checks (cache handled by Firestore)
    final ids = _items.keys.toList();
    for (final id in ids) {
      try {
        final doc = await FirebaseFirestore.instance.collection('products').doc(id).get();
        if (!doc.exists) {
          _items.remove(id); // Product deleted
          continue;
        }

        final data = doc.data()!;
        final realPrice = (data['price'] as num?) ?? 0;
        final realStock = (data['stock'] as num?)?.toInt() ?? 0;
        final isActive = data['isActive'] as bool? ?? true;

        if (!isActive || realStock <= 0) {
          _items.remove(id);
          continue;
        }

        // [NEW] Offer Logic in Cart
        final isOfferActive = data['isOfferActive'] as bool? ?? false;
        double finalPrice = realPrice.toDouble();
        
        if (isOfferActive) {
           final offerType = data['offerType'] as String? ?? 'percentage';
           final offerValue = (data['offerValue'] as num? ?? 0).toDouble();
           
           if (offerType == 'percentage') {
             final discount = (realPrice * offerValue) / 100;
             finalPrice = realPrice - discount;
           } else {
             finalPrice = offerValue;
           }
           if (finalPrice < 0) finalPrice = 0;
        }

        final backendImage = data['imageUrl'] as String?; // [NEW] Sync Image

        final item = _items[id]!;
        // Update Price OR Image if changed
        if (item.price != finalPrice || backendImage != item.imageUrl) {
          _items[id] = CartItem(
             productId: item.productId,
             nameTa: item.nameTa, 
             nameEn: item.nameEn,
             price: finalPrice, // Updated to Offer Price
             unitTa: item.unitTa,
             unitEn: item.unitEn,
             quantity: item.quantity,
             imageUrl: backendImage ?? item.imageUrl, // [UPDATED] Sync Image
             lastUpdated: DateTime.now()
          );
        }

        // Cap Quantity
        if (item.quantity > realStock) {
          _items[id]!.quantity = realStock;
        }
      } catch (_) {}
    }
  }
}
