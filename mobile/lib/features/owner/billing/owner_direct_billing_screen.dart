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
        'isOnline': false,
        'createdAt': FieldValue.serverTimestamp(),
        'farmerId': _foundFarmerId,
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          isTa ? 'நேரடி விற்பனை' : 'Smart POS Billing',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            onPressed: () => _scanQRCode(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildPOSField(
                        controller: _customerPhoneController,
                        label: isTa ? 'கைபேசி எண்' : 'Phone',
                        icon: Icons.phone_android_rounded,
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        onChanged: (v) {
                          if (v.length == 10) _lookupFarmer();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildPOSField(
                        controller: _customerNameController,
                        label: isTa ? 'பெயர்' : 'Name',
                        icon: Icons.person_rounded,
                      ),
                    ),
                  ],
                ),
                if (_foundFarmerId != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.stars_rounded, color: Colors.orange, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '${isTa ? "புள்ளிகள்" : "Points"}: $_farmerPoints',
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.orange.shade800),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildPOSField(
                        controller: _customerVillageController,
                        label: isTa ? 'ஊர்' : 'Village',
                        icon: Icons.location_on_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildPOSField(
                        controller: _adviceController,
                        label: isTa ? 'குறிப்பு' : 'Note',
                        icon: Icons.info_outline_rounded,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                    style: GoogleFonts.inter(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: isTa ? 'தேடுங்கள்...' : 'Search Products...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppColors.borderLight)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppColors.borderLight)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _KitChip(label: isTa ? 'நெல்' : 'Paddy', icon: Icons.grass, onTap: _addPaddyKit),
                const SizedBox(width: 4),
                _KitChip(label: isTa ? 'தக்காளி' : 'Tomato', icon: Icons.eco_rounded, onTap: _addTomatoKit),
                const SizedBox(width: 4),
                _KitChip(label: isTa ? 'உரம்' : 'Urea', icon: Icons.eco, onTap: _addFertilizerKit),
              ],
            ),
          ),

          Expanded(
            child: Row(
              children: [
                // Product Selection
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance.collection('products').snapshots(),
                      builder: (context, snapshot) {
                        final all = snapshot.data?.docs ?? [];
                        final filtered = all.where((d) {
                          final data = d.data();
                          final nTa = (data['name_ta'] as String? ?? '').toLowerCase();
                          final nEn = (data['name_en'] as String? ?? '').toLowerCase();
                          return nTa.contains(_searchQuery) || nEn.contains(_searchQuery);
                        }).toList();

                        return GridView.builder(
                          padding: const EdgeInsets.all(12),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.8,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) => _POSProductCard(
                            doc: filtered[index],
                            onAdd: () => _addToCart(filtered[index].id, filtered[index].data()),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Cart
                Expanded(
                  flex: 2,
                  child: Container(
                    color: AppColors.surface,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.borderLight))),
                          child: Row(
                            children: [
                              const Icon(Icons.shopping_cart_outlined, size: 20),
                              const SizedBox(width: 8),
                              Text(isTa ? 'கூடை' : 'Cart', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
                                child: Text('${_cart.length}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView(
                            children: [
                              if (_cart.isNotEmpty) const _PairRecommendationRow(),
                              ..._cart.entries.map((e) => _CartListItem(
                                item: e.value,
                                onAdd: () => _updateQuantity(e.key, 1),
                                onRemove: () => _updateQuantity(e.key, -1),
                              )).toList(),
                            ],
                          ),
                        ),
                        _buildPaymentFooter(isTa),
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

  Widget _buildPaymentFooter(bool isTa) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.borderLight)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(isTa ? "மொத்தம்" : "Total Amount", style: GoogleFonts.inter(color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
              Text('₹${_totalAmount.toStringAsFixed(0)}', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _cart.isEmpty || _isProcessing ? null : _processCheckout,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _isProcessing
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(isTa ? 'ஆர்டர் செய்' : 'Checkout & Bill', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildPOSField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int? maxLength,
    ValueChanged<String>? onChanged,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      onChanged: onChanged,
      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondary),
        prefixIcon: Icon(icon, size: 20, color: AppColors.primary.withOpacity(0.5)),
        suffixIcon: suffixIcon,
        counterText: "",
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.borderLight)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.borderLight)),
        focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.primary, width: 1.5)),
        filled: true,
        fillColor: AppColors.background.withOpacity(0.3),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}

class _POSProductCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final VoidCallback onAdd;

  const _POSProductCard({required this.doc, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final name = LocalizationService.pickTaEn(data['name_ta'], data['name_en']);
    final price = PriceUtils.calculateFinalPrice(data);
    final stock = data['stock'] as int? ?? 0;
    final imageUrl = data['imageUrl'] as String?;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? Image.network(imageUrl, fit: BoxFit.cover, width: double.infinity)
                      : Container(color: AppColors.background, child: const Icon(Icons.inventory_2_outlined, color: Colors.grey)),
                ),
                if (stock <= 5)
                  Positioned(
                    top: 8, right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.red.withOpacity(0.9), borderRadius: BorderRadius.circular(8)),
                      child: Text('LOW', style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('₹$price', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13)),
                    InkWell(
                      onTap: stock > 0 ? onAdd : null,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: stock > 0 ? AppColors.primary : Colors.grey.shade300, borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CartListItem extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _CartListItem({required this.item, required this.onAdd, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final name = LocalizationService.isTamil ? (item['data']['name_ta'] ?? item['data']['name_en']) : item['data']['name_en'];
    final price = item['finalPrice'] as double;
    final qty = item['quantity'] as int;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.borderLight))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('₹$price', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
              Row(
                children: [
                  IconButton(icon: const Icon(Icons.remove_rounded, size: 16), onPressed: onRemove, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                  const SizedBox(width: 8),
                  Text('$qty', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  IconButton(icon: const Icon(Icons.add_rounded, size: 16), onPressed: onAdd, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                ],
              ),
            ],
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

  const _KitChip({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: AppColors.primary),
      label: Text(label, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold)),
      onPressed: onTap,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      side: BorderSide(color: AppColors.borderLight),
    );
  }
}

class _PairRecommendationRow extends StatelessWidget {
  const _PairRecommendationRow();

  @override
  Widget build(BuildContext context) {
    final isTa = LocalizationService.isTamil;
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isTa ? 'அடிக்கடி வாங்கியவை' : 'Often bought together',
                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _SmallRecChip(label: isTa ? 'யூரியா' : 'Urea'),
                const SizedBox(width: 6),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold),
      ),
    );
  }
}
