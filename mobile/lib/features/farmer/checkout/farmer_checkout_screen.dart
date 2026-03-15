import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io'; // For File

import '../../../core/constants/colors.dart';
import '../../../core/services/localization_service.dart';
import '../cart/cart_provider.dart';
import '../orders/farmer_order_success_screen.dart';
import '../../notifications/repositories/notification_repository.dart';
import '../../notifications/models/app_notification.dart';
import 'aadhar_verification_screen.dart';

class FarmerCheckoutScreen extends StatefulWidget {
  const FarmerCheckoutScreen({super.key});

  @override
  State<FarmerCheckoutScreen> createState() => _FarmerCheckoutScreenState();
}

class _FarmerCheckoutScreenState extends State<FarmerCheckoutScreen> {
  String _paymentMethod = 'cash';
  bool _isPlacing = false;
  bool _needsDosageAdvice = false;
  final _diseaseController = TextEditingController();
  final _cropController = TextEditingController();
  String _selectedLevel = 'Starting Stage';
  Map<String, dynamic>? _predefinedAdvice;
  bool _isCheckingAdvice = false;

  XFile? _diseaseImage;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
  }

  final List<String> _levels = ['Starting Stage', 'Moderate', 'Advanced', 'More insects in the plant'];

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          LocalizationService.tr('title_checkout'),
          style: GoogleFonts.notoSansTamil(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: cart.items.isEmpty
          ? Center(
              child: Text(
                'கூடை காலியாக உள்ளது',
                style: GoogleFonts.notoSansTamil(fontSize: 14, color: AppColors.textSecondary),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Receipt Card
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.05),
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.receipt_long, color: AppColors.primary),
                                    const SizedBox(width: 12),
                                    Text(
                                      LocalizationService.tr('title_order_summary'),
                                      style: GoogleFonts.notoSansTamil(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryDark,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(height: 1, color: Color(0xFFEEEEEE)),
                              // Items
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  children: [
                                    for (final item in cart.items) ...[
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 12),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    item.nameTa,
                                                    style: GoogleFonts.notoSansTamil(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                  if (item.nameEn.isNotEmpty)
                                                    Text(
                                                      item.nameEn,
                                                      style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              'x${item.quantity}',
                                              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
                                            ),
                                            const SizedBox(width: 16),
                                            Text(
                                              '₹${(item.price * item.quantity).toStringAsFixed(0)}',
                                              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    const Divider(height: 30, thickness: 1, color: Color(0xFFDDDDDD)),
                                    // Total
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          LocalizationService.tr('label_total'),
                                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                                        ),
                                        Text(
                                          '₹${cart.totalAmount.toStringAsFixed(0)}',
                                          style: GoogleFonts.notoSansTamil(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primaryDark,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        Text(
                          LocalizationService.tr('title_pickup_info'),
                          style: GoogleFonts.notoSansTamil(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                               Container(
                                 padding: const EdgeInsets.all(12),
                                 decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    shape: BoxShape.circle,
                                 ),
                                 child: Icon(Icons.store_outlined, color: Colors.orange.shade700),
                               ),
                               const SizedBox(width: 16),
                               Expanded(
                                 child: Column(
                                   crossAxisAlignment: CrossAxisAlignment.start,
                                   children: [
                                     Text(
                                       LocalizationService.tr('pickup_shop_name'),
                                       style: GoogleFonts.notoSansTamil(
                                         fontSize: 14,
                                         fontWeight: FontWeight.bold,
                                       ),
                                     ),
                                     const SizedBox(height: 4),
                                     Text(
                                       LocalizationService.tr('pickup_shop_address'),
                                       style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
                                     ),
                                     const SizedBox(height: 4),
                                     Text(
                                       LocalizationService.tr('pickup_pick_within'),
                                       style: GoogleFonts.poppins(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w500),
                                     ),
                                   ],
                                 ),
                               ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),
                        
                        Text(
                          LocalizationService.tr('title_payment_method'),
                          style: GoogleFonts.notoSansTamil(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        _paymentOption(
                           value: 'cash',
                           title: LocalizationService.tr('payment_cash'),
                           subtitle: '',
                           icon: Icons.payments_outlined,
                        ),
                        const SizedBox(height: 12),
                        _paymentOption(
                           value: 'credit',
                           title: LocalizationService.tr('payment_credit'),
                           subtitle: LocalizationService.tr('payment_credit_note'),
                           icon: Icons.credit_card_outlined,
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // [NEW] Dosage Advice Section
                        Text(
                          LocalizationService.isTamil ? 'அளவு ஆலோசனை தேவையா?' : 'Need Dosage Advice?',
                          style: GoogleFonts.notoSansTamil(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.medical_services_outlined, color: _needsDosageAdvice ? AppColors.primary : Colors.grey),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      LocalizationService.isTamil ? 'ஆசிரியரின் அளவு ஆலோசனை தேவை' : 'I need dosage advice from the owner',
                                      style: GoogleFonts.notoSansTamil(fontSize: 14),
                                    ),
                                  ),
                                  Switch(
                                    value: _needsDosageAdvice, 
                                    onChanged: (v) => setState(() => _needsDosageAdvice = v),
                                    activeColor: AppColors.primary,
                                  ),
                                ],
                              ),
                              if (_needsDosageAdvice) ...[
                                const Divider(height: 24),
                                Text(
                                  LocalizationService.isTamil ? 'அனைத்துப் புலன்களும் கட்டாயம்*' : 'All fields are required*',
                                  style: GoogleFonts.notoSansTamil(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _cropController,
                                  onChanged: (v) {
                                    _searchPredefinedAdvice();
                                    setState(() {}); // Trigger rebuild for disease suggestions
                                  },
                                  decoration: InputDecoration(
                                    hintText: LocalizationService.isTamil ? 'பயிர் பெயர் (எ.கா: தக்காளி)' : 'Crop Name (e.g., Tomato)',
                                    hintStyle: GoogleFonts.notoSansTamil(fontSize: 13, color: Colors.grey),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    labelText: LocalizationService.isTamil ? 'பயிர் *' : 'Crop *',
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // [NEW] Disease Suggestions / Search
                                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                                  stream: FirebaseFirestore.instance
                                      .collection('common_diseases')
                                      .where('crop_lower', isEqualTo: _cropController.text.trim().toLowerCase())
                                      .snapshots(),
                                  builder: (context, snapshot) {
                                    final diseases = snapshot.data?.docs.map((d) => d.data()['diseaseName'] as String).toSet().toList() ?? [];
                                    
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        TextField(
                                          controller: _diseaseController,
                                          onChanged: (v) => _searchPredefinedAdvice(),
                                          decoration: InputDecoration(
                                            hintText: LocalizationService.isTamil ? 'நோய் பெயர்' : 'Disease Name',
                                            hintStyle: GoogleFonts.notoSansTamil(fontSize: 13, color: Colors.grey),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                            labelText: LocalizationService.isTamil ? 'நோய் *' : 'Disease *',
                                          ),
                                        ),
                                        if (diseases.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          const Text('Suggested Diseases:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                                          const SizedBox(height: 4),
                                          Wrap(
                                            spacing: 8,
                                            children: diseases.take(4).map((d) => ActionChip(
                                              label: Text(d, style: const TextStyle(fontSize: 10)),
                                              onPressed: () {
                                                _diseaseController.text = d;
                                                _searchPredefinedAdvice();
                                              },
                                              padding: EdgeInsets.zero,
                                            )).toList(),
                                          ),
                                        ],
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<String>(
                                  value: _selectedLevel,
                                  items: _levels.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                                  onChanged: (v) {
                                    setState(() => _selectedLevel = v!);
                                    _searchPredefinedAdvice();
                                  },
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    labelText: LocalizationService.isTamil ? 'பாதிப்பு நிலை *' : 'Disease Level *',
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Disease Image Picker
                                InkWell(
                                  onTap: _pickImage,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    height: 120,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: _diseaseImage == null ? Colors.grey.shade300 : AppColors.primary, width: 1.5),
                                      borderRadius: BorderRadius.circular(12),
                                      color: _diseaseImage == null ? Colors.grey.shade50 : AppColors.primary.withOpacity(0.05),
                                    ),
                                    child: _diseaseImage == null
                                        ? Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(Icons.add_a_photo_outlined, color: Colors.grey),
                                              const SizedBox(height: 8),
                                              Text(
                                                LocalizationService.isTamil ? 'நோய் பாதிப்பு படம் (கட்டாயம்)' : 'Upload Disease Photo (Required)',
                                                style: GoogleFonts.notoSansTamil(fontSize: 12, color: Colors.grey),
                                              ),
                                            ],
                                          )
                                        : Stack(
                                            fit: StackFit.expand,
                                            children: [
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(12),
                                                child: Image.file(
                                                  File(_diseaseImage!.path),
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                              Positioned(
                                                right: 8,
                                                top: 8,
                                                child: CircleAvatar(
                                                  backgroundColor: Colors.white,
                                                  radius: 14,
                                                  child: IconButton(
                                                    icon: const Icon(Icons.close, size: 14, color: Colors.red),
                                                    onPressed: () => setState(() => _diseaseImage = null),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                                if (_isCheckingAdvice) 
                                  const Padding(
                                    padding: EdgeInsets.only(top: 8),
                                    child: LinearProgressIndicator(),
                                  ),
                                if (_predefinedAdvice != null) ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.blue.shade200),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          LocalizationService.isTamil ? 'இந்த நோய் ஏற்கனவே வரையறுக்கப்பட்டுள்ளது!' : 'This disease is already defined!',
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "${LocalizationService.isTamil ? 'ஆலோசனை:' : 'Advice:'} ${_predefinedAdvice!['advice']}",
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                        const Divider(),
                                        const Text('Recommended Products:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                        for (final p in (_predefinedAdvice!['products'] as List? ?? []))
                                          Text("- ${p['name_en']} (${p['dosage']})", style: const TextStyle(fontSize: 12)),
                                        const Divider(),
                                        StreamBuilder<QuerySnapshot>(
                                          stream: FirebaseFirestore.instance
                                              .collection('feedbacks')
                                              .where('isAdviceFeedback', isEqualTo: true)
                                              .where('diseaseName', isEqualTo: _predefinedAdvice!['diseaseName'])
                                              .snapshots(),
                                          builder: (context, snapshot) {
                                            final count = snapshot.data?.docs.length ?? 0;
                                            final worked = snapshot.data?.docs.where((d) => (d.data() as Map)['adviceEffectiveness'] == 'worked').length ?? 0;
                                            final percent = count > 0 ? (worked / count * 100).toInt() : 0;
                                            
                                            return Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  count > 0 ? '$percent% ${LocalizationService.isTamil ? 'வெற்றி' : 'Success Rate'} ($count)' : (LocalizationService.isTamil ? 'புள்ளிவிவரங்கள் இல்லை' : 'No stats yet'),
                                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.blue.shade900),
                                                ),
                                                if (count > 0)
                                                  TextButton(
                                                    onPressed: () => _showPredefinedReviews(context, _predefinedAdvice!['diseaseName'], LocalizationService.isTamil),
                                                    child: Text(LocalizationService.isTamil ? 'விமர்சனங்கள்' : 'Reviews', style: const TextStyle(fontSize: 11)),
                                                  ),
                                              ],
                                            );
                                          }
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                     color: Colors.white,
                     boxShadow: [
                        BoxShadow(
                           color: Colors.black.withOpacity(0.05),
                           blurRadius: 10,
                           offset: const Offset(0, -4)
                        )
                     ],
                  ),
                  child: SafeArea(
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isPlacing || cart.items.isEmpty ? null : () => _placeOrder(context, cart),
                        style: ElevatedButton.styleFrom(
                           backgroundColor: AppColors.primary,
                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                           elevation: 0,
                        ),
                        child: _isPlacing
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                   Text(
                                    LocalizationService.tr('btn_place_order'),
                                    style: GoogleFonts.notoSansTamil(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.check_circle_outline, color: Colors.white),
                                ],
                            ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _paymentOption({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _paymentMethod == value;
    return InkWell(
      onTap: () => setState(() => _paymentMethod = value),
      borderRadius: BorderRadius.circular(16),
      child: Container(
         padding: const EdgeInsets.all(16),
         decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
               color: isSelected ? AppColors.primary : Colors.grey.shade200,
               width: isSelected ? 2 : 1
            ),
         ),
         child: Row(
            children: [
               Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                     color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.grey.shade50,
                     shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: isSelected ? AppColors.primary : Colors.grey.shade600),
               ),
               const SizedBox(width: 16),
               Expanded(
                 child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       Text(
                          title,
                          style: GoogleFonts.notoSansTamil(
                             fontSize: 15,
                             fontWeight: FontWeight.w600,
                             color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
                          ),
                       ),
                       if(subtitle.isNotEmpty)
                          Text(
                             subtitle,
                             style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
                          )
                    ],
                 ),
               ),
               if(isSelected)
                  const Icon(Icons.radio_button_checked, color: AppColors.primary)
               else
                  const Icon(Icons.radio_button_off, color: Colors.grey),
            ],
         ),
      ),
    );
  }



  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      final image = await picker.pickImage(source: source, imageQuality: 70);
      if (image != null) {
        setState(() => _diseaseImage = image);
      }
    }
  }

  Future<String?> _uploadDiseaseImage(XFile image, String orderId) async {
    try {
      final ref = FirebaseStorage.instance.ref().child('disease_images/$orderId.jpg');
      final uploadTask = await ref.putData(await image.readAsBytes());
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      print("Upload error: $e");
      return null;
    }
  }

  Future<void> _placeOrder(BuildContext context, CartProvider cart) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LocalizationService.tr('error_login_again')),
        ),
      );
      return;
    }
    if (cart.items.isEmpty) return;

    // [UPDATED] Check shop status - Allow ordering but warn
    final shopSnap = await FirebaseFirestore.instance.collection('shop_settings').doc('current').get();
    final isOpen = shopSnap.data()?['isOpen'] ?? true;
    
    if (!isOpen) {
       final proceed = await showDialog<bool>(
         context: context,
         builder: (ctx) => AlertDialog(
           title: Text(LocalizationService.isTamil ? 'கடை மூடப்பட்டுள்ளது' : 'Shop is Closed'),
           content: Text(LocalizationService.isTamil 
             ? 'கடை தற்போது மூடப்பட்டுள்ளது. உங்கள் ஆர்டர் நாளை டெலிவரி செய்யப்படலாம். தொடரலாமா?' 
             : 'The shop is currently closed. Your order may be delivered tomorrow. Do you want to proceed?'),
           actions: [
             TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(LocalizationService.isTamil ? 'ரத்து' : 'Cancel')),
             ElevatedButton(
               onPressed: () => Navigator.pop(ctx, true), 
               style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
               child: Text(LocalizationService.isTamil ? 'தொடர்க' : 'Proceed', style: const TextStyle(color: Colors.white)),
             ),
           ],
         )
       );
       if (proceed != true) return;
    }

    // Validation for Dosage Advice
    if (_needsDosageAdvice && _predefinedAdvice == null) {
      if (_cropController.text.trim().isEmpty || _diseaseController.text.trim().isEmpty || _diseaseImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LocalizationService.isTamil ? "தயவுசெய்து அனைத்து விவரங்களையும் படத்தையும் வழங்கவும்" : "Please provide all details and photo"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() => _isPlacing = true);

    String? verifiedAadhar;

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final userData = userDoc.data();
      final userVillage = userData?['village'] ?? '';

      // --- Aadhar Verification Pre-Flight Check ---
      bool needsAadhar = false;
      double requestedLiters = 0.0;
      for (final item in cart.items) {
        final productDoc = await FirebaseFirestore.instance.collection('products').doc(item.productId).get();
        if (productDoc.exists && productDoc.data()?['categoryId'] == 'pesticides') {
          needsAadhar = true;
          
          double volume = 1.0; // fallback 1 L default
          final unit = item.unitEn.toLowerCase();
          final mlMatch = RegExp(r'(\d+)\s*ml').firstMatch(unit);
          final lMatch = RegExp(r'(\d+(\.\d+)?)\s*l(iter)?s?').firstMatch(unit);
          if (mlMatch != null) {
            volume = double.parse(mlMatch.group(1)!) / 1000.0;
          } else if (lMatch != null) {
            volume = double.parse(lMatch.group(1)!);
          } else {
             // If numeric weight is isolated
             final numMatch = RegExp(r'(\d+(\.\d+)?)').firstMatch(unit);
             if (numMatch != null) {
                // assume Liters/Kg if it's less than 50, otherwise ML/grams
                double val = double.parse(numMatch.group(1)!);
                if (val > 50) volume = val / 1000.0;
                else volume = val;
             }
          }
          requestedLiters += (volume * item.quantity);
        }
      }

      if (needsAadhar) {
        if (!mounted) return;
        setState(() => _isPlacing = false);
        
        verifiedAadhar = await Navigator.of(context).push<String>(
          MaterialPageRoute(builder: (_) => AadharVerificationScreen(requestedLiters: requestedLiters)),
        );
        
        if (verifiedAadhar == null) {
          // User cancelled verification
          return;
        }
        
        setState(() => _isPlacing = true);
      }
      // ---------------------------------------------

      final total = cart.totalAmount;
      final orderId = FirebaseFirestore.instance.collection('orders').doc().id;
      final orderRef = FirebaseFirestore.instance.collection('orders').doc(orderId);

      // Upload Image if needed
      String? diseaseImageUrl;
      if (_needsDosageAdvice && _predefinedAdvice == null && _diseaseImage != null) {
         diseaseImageUrl = await _uploadDiseaseImage(_diseaseImage!, orderId);
      }

      // [STOCK MANAGEMENT] Use a transaction to safely check and reduce stock
      await FirebaseFirestore.instance.runTransaction((transaction) async {
         // 1. Read all product docs to check stock
         for (final item in cart.items) {
            final productRef = FirebaseFirestore.instance.collection('products').doc(item.productId);
            final productDoc = await transaction.get(productRef);
            
            if (!productDoc.exists) {
               throw Exception("Product '${item.nameEn}' no longer exists.");
            }
            
            final currentStock = (productDoc.data()?['stock'] as num?)?.toInt() ?? 0;
            if (currentStock < item.quantity) {
               throw Exception("Insufficient stock for '${item.nameTa}' (Available: $currentStock)");
            }
         }

         // 2. Reduce Stock
         for (final item in cart.items) {
            final productRef = FirebaseFirestore.instance.collection('products').doc(item.productId);
            transaction.update(productRef, {
               'stock': FieldValue.increment(-item.quantity),
               'lastSoldDate': FieldValue.serverTimestamp(),
            });
         }

         // 3. Create Order
         transaction.set(orderRef, {
            'userId': user.uid,
            'shopId': 'default_shop',
            'status': 'reserved',
            'paymentMethod': _paymentMethod,
            'totalAmount': total,
            'customerVillage': userVillage,
            'createdAt': FieldValue.serverTimestamp(),
            'needsDosageAdvice': _needsDosageAdvice && _predefinedAdvice == null,
            'cropName': _cropController.text.trim(),
            'diseaseDetails': _diseaseController.text.trim(),
            'diseaseLevel': _selectedLevel,
            'diseaseImageUrl': diseaseImageUrl,
            'dosageAdvice': _predefinedAdvice?['advice'],
            'recommendedProducts': _predefinedAdvice?['products'],
            'dosageAdviceStatus': _predefinedAdvice != null ? 'provided' : 'requested',
            'items': cart.items.map((item) => {
               'productId': item.productId,
               'name_ta': item.nameTa,
               'name_en': item.nameEn,
               'price': item.price,
               'quantity': item.quantity,
               'unit_ta': item.unitTa,
               'unit_en': item.unitEn,
            }).toList(),
         });

         // 4. Update Aadhar Limit
         if (verifiedAadhar != null) {
            final aadharRef = FirebaseFirestore.instance.collection('aadhar_limits').doc(verifiedAadhar);
            transaction.set(aadharRef, {
               'lastPurchaseTime': FieldValue.serverTimestamp(),
               'userId': user.uid,
               'totalLitersPurchased': FieldValue.increment(requestedLiters),
            }, SetOptions(merge: true));
         }
      });

      cart.clear();

      // --- Notify Owner ---
      try {
        await NotificationRepository().notifyOwner(
          titleTa: 'புதிய ஆணை வரவு',
          titleEn: 'New Order Received',
          bodyTa: 'ஒரு விவசாயி புதிய ஆணையைச் சமர்ப்பித்துள்ளார். எண்: ${orderRef.id}',
          bodyEn: 'A farmer has placed a new order. ID: ${orderRef.id}',
          data: {'orderId': orderRef.id, 'type': 'orderPlaced'},
        );
      } catch (e) {
        print('Notification error: $e');
      }
      // --------------------

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => FarmerOrderSuccessScreen(
            orderId: orderRef.id,
            totalAmount: total,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${LocalizationService.tr('error_failed_place_order')}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isPlacing = false);
      }
    }
  }

  Future<void> _searchPredefinedAdvice() async {
    final crop = _cropController.text.trim().toLowerCase();
    final disease = _diseaseController.text.trim().toLowerCase();
    
    if (crop.isEmpty || disease.isEmpty) {
      if (_predefinedAdvice != null) setState(() => _predefinedAdvice = null);
      return;
    }

    setState(() => _isCheckingAdvice = true);
    
    try {
      final snap = await FirebaseFirestore.instance
          .collection('common_diseases')
          .where('crop_lower', isEqualTo: crop)
          .where('disease_lower', isEqualTo: disease)
          .where('level', isEqualTo: _selectedLevel)
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        setState(() => _predefinedAdvice = snap.docs.first.data());
      } else {
        setState(() => _predefinedAdvice = null);
      }
    } catch (e) {
      print('Advice lookup error: $e');
    } finally {
      setState(() => _isCheckingAdvice = false);
    }
  }

  void _showPredefinedReviews(BuildContext context, String diseaseName, bool isTa) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.7,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isTa ? 'விவசாயிகளின் கருத்துக்கள்' : 'Farmer Feedback',
              style: GoogleFonts.notoSansTamil(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('feedbacks')
                    .where('isAdviceFeedback', isEqualTo: true)
                    .where('diseaseName', isEqualTo: diseaseName)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final docs = snapshot.data!.docs;
                  return ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (ctx, i) {
                      final fb = docs[i].data();
                      final worked = fb['adviceEffectiveness'] == 'worked';
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: worked ? Colors.green.shade50 : Colors.red.shade50,
                          child: Icon(worked ? Icons.check : Icons.close, color: worked ? Colors.green : Colors.red, size: 16),
                        ),
                        title: Text(fb['userName'] ?? 'Farmer', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(fb['comment'] ?? '', style: const TextStyle(fontSize: 12)),
                            if (fb['imageUrl'] != null) ...[
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(fb['imageUrl'], height: 100, width: 150, fit: BoxFit.cover),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
