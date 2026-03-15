import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/constants/colors.dart';
import '../../../core/services/localization_service.dart';
import '../../../core/utils/price_utils.dart';
import 'owner_invoice_screen.dart';
import '../../farmer/checkout/aadhar_verification_screen.dart';

class OwnerDirectBillingScreen extends StatefulWidget {
  const OwnerDirectBillingScreen({super.key});

  @override
  State<OwnerDirectBillingScreen> createState() =>
      _OwnerDirectBillingScreenState();
}

class _OwnerDirectBillingScreenState extends State<OwnerDirectBillingScreen> {
  final Map<String, Map<String, dynamic>> _cart =
      {}; // docId -> {data, quantity, finalPrice}
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _customerVillageController = TextEditingController();
  final _customerEmailController = TextEditingController();
  final _adviceController = TextEditingController(); // [NEW]
  final _searchController = TextEditingController();

  String? _foundFarmerId; // [NEW]
  int _farmerPoints = 0; // [NEW]
  String _searchQuery = '';
  bool _isProcessing = false;

  double get _totalAmount {
    double total = 0;
    _cart.forEach((id, item) {
      final price = (item['finalPrice'] as num? ?? 0).toDouble();
      final qty = item['quantity'] as int;
      total += price * qty;
    });
    return total;
  }

  void _addToCart(String id, Map<String, dynamic> data) {
    setState(() {
      final finalPrice = PriceUtils.calculateFinalPrice(data);
      if (_cart.containsKey(id)) {
        _cart[id]!['quantity'] = (_cart[id]!['quantity'] as int) + 1;
      } else {
        _cart[id] = {
          'data': data,
          'quantity': 1,
          'finalPrice': finalPrice,
          'originalPrice': data['price'],
        };
      }
    });
  }

  void _updateQuantity(String id, int delta) {
    setState(() {
      if (_cart.containsKey(id)) {
        final current = _cart[id]!['quantity'] as int;
        if (current + delta > 0) {
          _cart[id]!['quantity'] = current + delta;
        } else {
          _cart.remove(id);
        }
      }
    });
  }

  Future<void> _lookupFarmer() async {
    final phone = _customerPhoneController.text.trim();
    if (phone.length != 10) return;

    final query = await FirebaseFirestore.instance
        .collection('users')
        .where('phone', isEqualTo: '+91$phone')
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      final data = query.docs.first.data();
      setState(() {
        _foundFarmerId = query.docs.first.id;
        _customerNameController.text = data['name'] ?? '';
        _customerVillageController.text = data['village'] ?? '';
        _customerEmailController.text = data['email'] ?? '';
        _farmerPoints = (data['loyaltyPoints'] as num? ?? 0).toInt();
      });
      _showSuccess(
        LocalizationService.isTamil
            ? 'விவசாயி விவரங்கள் கண்டறியப்பட்டன'
            : 'Farmer details found',
      );
    }
  }

  Future<void> _processCheckout() async {
    if (_cart.isEmpty) return;
    if (_customerPhoneController.text.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            LocalizationService.isTamil
                ? 'செல்லுபடியாகும் 10 இலக்க எண்ணை உள்ளிடவும்'
                : 'Enter valid 10-digit phone',
          ),
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    String? verifiedAadhar;
    double requestedLiters = 0.0;

    try {
      // --- Aadhar Verification for Pesticides ---
      bool needsAadhar = false;
      _cart.forEach((id, item) {
        final data = item['data'];
        if (data['categoryId'] == 'pesticides') {
          needsAadhar = true;

          double volume = 1.0;
          final unit = (data['unit_en'] as String? ?? '').toLowerCase();
          final mlMatch = RegExp(r'(\d+)\s*ml').firstMatch(unit);
          final lMatch = RegExp(r'(\d+(\.\d+)?)\s*l(iter)?s?').firstMatch(unit);
          if (mlMatch != null) {
            volume = double.parse(mlMatch.group(1)!) / 1000.0;
          } else if (lMatch != null) {
            volume = double.parse(lMatch.group(1)!);
          } else {
            final numMatch = RegExp(r'(\d+(\.\d+)?)').firstMatch(unit);
            if (numMatch != null) {
              double val = double.parse(numMatch.group(1)!);
              if (val > 50)
                volume = val / 1000.0;
              else
                volume = val;
            }
          }
          requestedLiters += (volume * (item['quantity'] as int));
        }
      });

      if (needsAadhar) {
        if (!mounted) return;
        setState(() => _isProcessing = false);

        verifiedAadhar = await Navigator.of(context).push<String>(
          MaterialPageRoute(
            builder: (_) =>
                AadharVerificationScreen(requestedLiters: requestedLiters),
          ),
        );

        if (verifiedAadhar == null) return; // User cancelled

        setState(() => _isProcessing = true);
      }
      // -----------------------------------------

      final batch = FirebaseFirestore.instance.batch();
      final orderId =
          'SHOP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      final orderRef = FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId);

      final List<Map<String, dynamic>> orderItems = [];
      _cart.forEach((id, item) {
        final data = item['data'];
        final qty = item['quantity'] as int;

        orderItems.add({
          'productId': id,
          'name_ta': data['name_ta'],
          'name_en': data['name_en'],
          'price': item['finalPrice'],
          'originalPrice': item['originalPrice'],
          'quantity': qty,
        });

        final productRef = FirebaseFirestore.instance
            .collection('products')
            .doc(id);
        batch.update(productRef, {
          'stock': FieldValue.increment(-qty),
          'lastSoldDate': FieldValue.serverTimestamp(), // [NEW]
        });
      });

      final orderData = {
        'items': orderItems,
        'totalAmount': _totalAmount,
        'customerName': _customerNameController.text.trim().isEmpty
            ? (LocalizationService.isTamil
                  ? 'நேரடி வாடிக்கையாளர்'
                  : 'Walk-in Customer')
            : _customerNameController.text.trim(),
        'customerPhone': '+91${_customerPhoneController.text.trim()}',
        'customerEmail': _customerEmailController.text.trim(),
        'customerVillage': _customerVillageController.text.trim(),
        'adviceNote': _adviceController.text.trim(), // [NEW] Free Advice Note
        'status': 'picked',
        'paymentMethod': 'cash',
        'type': 'direct_sale',
        'createdAt': FieldValue.serverTimestamp(),
        'farmerId': _foundFarmerId, // [NEW]
      };

      batch.set(orderRef, orderData);

      // --- Credit Loyalty Points ---
      if (_foundFarmerId != null) {
        final earnedPoints = (_totalAmount / 100).floor();
        final userRef = FirebaseFirestore.instance
            .collection('users')
            .doc(_foundFarmerId);

        final Map<String, dynamic> updateData = {
          'lastVisitDate': FieldValue.serverTimestamp(),
          'village': _customerVillageController.text.trim(), // [NEW] Sync village
        };
        if (earnedPoints > 0) {
          updateData['loyaltyPoints'] = FieldValue.increment(earnedPoints);
        }
        batch.update(userRef, updateData);
      }
      // ----------------------------

      if (verifiedAadhar != null) {
        final aadharLimitRef = FirebaseFirestore.instance
            .collection('aadhar_limits')
            .doc(verifiedAadhar);
        batch.set(aadharLimitRef, {
          'lastPurchaseTime': FieldValue.serverTimestamp(),
          'totalLitersPurchased': FieldValue.increment(requestedLiters),
          'lastUserId':
              '', // Direct sale doesn't have a linked farmer userId often
        }, SetOptions(merge: true));
      }

      await batch.commit();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              OwnerInvoiceScreen(orderId: orderId, orderData: orderData),
        ),
      );
    } catch (e) {
      final isTa = LocalizationService.isTamil;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isTa ? 'தோல்வி: $e' : 'Checkout failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _scanQRCode() async {
    final isTa = LocalizationService.isTamil;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isTa ? 'QR குறியீட்டை ஸ்கேன் செய்யவும்' : 'Scan Product QR Code',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: MobileScanner(
                  onDetect: (capture) async {
                    final List<Barcode> barcodes = capture.barcodes;
                    for (final barcode in barcodes) {
                      final String? code = barcode.rawValue;
                      if (code != null) {
                        Navigator.pop(ctx);
                        _handleScannedCode(code);
                        break;
                      }
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _handleScannedCode(String code) async {
    final isTa = LocalizationService.isTamil;
    try {
      // 1. Try finding by Document ID (default)
      var doc = await FirebaseFirestore.instance
          .collection('products')
          .doc(code)
          .get();

      if (doc.exists) {
        _addToCart(doc.id, doc.data()!);
        _showSuccess(
          isTa ? 'தயாரிப்பு சேர்க்கப்பட்டது' : 'Product added to cart',
        );
        return;
      }

      // 2. Try finding by qrId field (manufacturer QR)
      final query = await FirebaseFirestore.instance
          .collection('products')
          .where('qrId', isEqualTo: code)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final foundDoc = query.docs.first;
        _addToCart(foundDoc.id, foundDoc.data());
        _showSuccess(
          isTa ? 'தயாரிப்பு சேர்க்கப்பட்டது' : 'Product added to cart',
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isTa ? 'தயாரிப்பு விவரம் கிடைக்கவில்லை' : 'Product not found',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _addPaddyKit() async {
    final products = await FirebaseFirestore.instance
        .collection('products')
        .get();
    for (var doc in products.docs) {
      final name = (doc.data()['name_en'] ?? '').toLowerCase();
      if (name.contains('paddy') || name.contains('urea')) {
        _addToCart(doc.id, doc.data());
      }
    }
  }

  void _addTomatoKit() async {
    final products = await FirebaseFirestore.instance
        .collection('products')
        .get();
    for (var doc in products.docs) {
      final name = (doc.data()['name_en'] ?? '').toLowerCase();
      if (name.contains('tomato') || name.contains('seeds')) {
        _addToCart(doc.id, doc.data());
      }
    }
  }

  void _addFertilizerKit() async {
    final products = await FirebaseFirestore.instance
        .collection('products')
        .get();
    for (var doc in products.docs) {
      final cat = doc.data()['categoryId'];
      if (cat == 'fertilizers') {
        _addToCart(doc.id, doc.data());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTa = LocalizationService.isTamil;
    // ... truncated

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          isTa ? 'நேரடி விற்பனை' : 'Direct Billing',
          style: GoogleFonts.notoSansTamil(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => _scanQRCode(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Customer Details
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _customerNameController,
                            decoration: InputDecoration(
                              hintText: isTa ? 'பெயர்' : 'Customer Name',
                              prefixIcon: const Icon(Icons.person_outline),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _customerPhoneController,
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            onChanged: (v) {
                              if (v.length == 10) _lookupFarmer();
                            },
                            decoration: InputDecoration(
                              hintText: isTa ? 'மொபைல்' : 'Phone Number',
                              prefixIcon: const Icon(Icons.phone_outlined),
                              suffixIcon: IconButton(
                                icon: const Icon(
                                  Icons.search,
                                  color: AppColors.primary,
                                ),
                                onPressed: _lookupFarmer,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              counterText: "",
                            ),
                          ),
                          if (_foundFarmerId != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4, bottom: 8),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.stars,
                                    color: Colors.orange,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${isTa ? "லாயல்டி புள்ளிகள்" : "Loyalty Points"}: $_farmerPoints',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _customerVillageController,
                            decoration: InputDecoration(
                              hintText: isTa ? 'கிராமம்' : 'Village (Optional)',
                              prefixIcon: const Icon(
                                Icons.location_on_outlined,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _adviceController,
                            decoration: InputDecoration(
                              hintText: isTa ? 'இலவச ஆலோசனை (விரும்பினால்)' : 'Free Advice Note (Optional)',
                              prefixIcon: const Icon(Icons.tips_and_updates_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _customerEmailController,
                            decoration: InputDecoration(
                              hintText: isTa
                                  ? 'மின்னஞ்சல்'
                                  : 'Email (Optional)',
                              prefixIcon: const Icon(Icons.email_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  onChanged: (v) =>
                      setState(() => _searchQuery = v.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: isTa
                        ? 'பெயர் மூலம் தேடுங்கள்...'
                        : 'Search by Products...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // --- CROP KITS (NEW) ---
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _KitChip(
                        label: isTa ? 'நெற்பயிர் கிட்' : 'Paddy Kit',
                        icon: Icons.grass,
                        onTap: () => _addPaddyKit(),
                      ),
                      const SizedBox(width: 8),
                      _KitChip(
                        label: isTa ? 'தக்காளி கிட்' : 'Tomato Kit',
                        icon: Icons.eco,
                        onTap: () => _addTomatoKit(),
                      ),
                      const SizedBox(width: 8),
                      _KitChip(
                        label: isTa ? 'உரம் கிட்' : 'Fertilizer Set',
                        icon: Icons.opacity,
                        onTap: () => _addFertilizerKit(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Row(
              children: [
                // Product Selection
                Expanded(
                  flex: 3,
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('products')
                        .snapshots(),
                    builder: (context, snapshot) {
                      final all = snapshot.data?.docs ?? [];
                      final filtered = all.where((d) {
                        final data = d.data();
                        final nTa = (data['name_ta'] as String? ?? '')
                            .toLowerCase();
                        final nEn = (data['name_en'] as String? ?? '')
                            .toLowerCase();
                        return nTa.contains(_searchQuery) ||
                            nEn.contains(_searchQuery);
                      }).toList();

                      return ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final doc = filtered[index];
                          final data = doc.data();
                          final name = isTa
                              ? (data['name_ta'] ?? data['name_en'])
                              : (data['name_en'] ?? data['name_ta']);
                          final originalPrice = (data['price'] as num? ?? 0)
                              .toDouble();
                          final finalPrice = PriceUtils.calculateFinalPrice(
                            data,
                          );
                          final hasOffer = PriceUtils.isOfferActuallyActive(
                            data,
                          );
                          final stock = data['stock'] as int? ?? 0;

                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              title: Text(
                                name,
                                style: GoogleFonts.notoSansTamil(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (hasOffer) ...[
                                    Text(
                                      '₹$originalPrice',
                                      style: const TextStyle(
                                        decoration: TextDecoration.lineThrough,
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      '₹$finalPrice',
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ] else
                                    Text('₹$originalPrice'),
                                  Text(
                                    '${isTa ? "இருப்பு" : "Stock"}: $stock',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.add_circle,
                                  color: AppColors.primary,
                                ),
                                onPressed: stock > 0
                                    ? () => _addToCart(doc.id, data)
                                    : null,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

                // Cart Summary
                Container(width: 1, color: Colors.grey.shade300),
                Expanded(
                  flex: 2,
                  child: Container(
                    color: Colors.white,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            isTa ? 'கூடை' : 'Cart',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          child: ListView(
                            children: [
                              if (_cart.isNotEmpty)
                                const _PairRecommendationRow(), // [NEW]
                              ..._cart.entries.map((e) {
                                final name = isTa
                                    ? (e.value['data']['name_ta'] ??
                                          e.value['data']['name_en'])
                                    : (e.value['data']['name_en'] ??
                                          e.value['data']['name_ta']);
                                return ListTile(
                                  dense: true,
                                  title: Text(
                                    name,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '₹${e.value['finalPrice']} x ${e.value['quantity']}',
                                      ),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.remove_circle_outline,
                                              size: 18,
                                            ),
                                            onPressed: () =>
                                                _updateQuantity(e.key, -1),
                                          ),
                                          Text('${e.value['quantity']}'),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.add_circle_outline,
                                              size: 18,
                                            ),
                                            onPressed: () =>
                                                _updateQuantity(e.key, 1),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          color: Colors.grey.shade50,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                '${isTa ? "மொத்தம்" : "Total"}: ₹${_totalAmount.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.right,
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: _cart.isEmpty || _isProcessing
                                    ? null
                                    : _processCheckout,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                ),
                                child: _isProcessing
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        isTa
                                            ? 'பணம் பெற்றுக்கொள்'
                                            : 'Pay & Bill',
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KitChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _KitChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: AppColors.primary),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
      onPressed: onTap,
      backgroundColor: Colors.white,
      side: BorderSide(color: AppColors.primary.withOpacity(0.2)),
    );
  }
}

class _PairRecommendationRow extends StatelessWidget {
  const _PairRecommendationRow();

  @override
  Widget build(BuildContext context) {
    final isTa = LocalizationService.isTamil;
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline, size: 16, color: Colors.blue),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  isTa ? 'அடிக்கடி வாங்கியவை' : 'Often bought together',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _SmallRecChip(label: isTa ? 'யூரியா' : 'Urea'),
                const SizedBox(width: 4),
                _SmallRecChip(label: isTa ? 'பூஞ்சைக் கொல்லி' : 'Fungicide'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallRecChip extends StatelessWidget {
  final String label;
  const _SmallRecChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          color: Colors.blue,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
