import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/colors.dart';
import '../../../core/services/localization_service.dart';

class FeedbackScreen extends StatefulWidget {
  final String orderId;
  final List<Map<String, dynamic>> items;
  final bool isAdviceFeedback;
  final String? diseaseName;
  final String? existingFeedbackId;
  final Map<String, dynamic>? existingData;

  const FeedbackScreen({
    super.key,
    required this.orderId,
    required this.items,
    this.isAdviceFeedback = false,
    this.diseaseName,
    this.existingFeedbackId,
    this.existingData,
  });

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _commentController = TextEditingController();
  int _rating = 5;
  File? _image;
  bool _isSubmitting = false;
  final _picker = ImagePicker();
  String? _selectedProductId;
  String _adviceEffectiveness = 'worked'; // 'worked', 'partial', 'not_worked'
  Set<String> _reviewedProductIds = {};
  bool _checkingExisting = true;

  @override
  void initState() {
    super.initState();
    if (widget.existingData != null) {
      _commentController.text = widget.existingData!['comment'] ?? '';
      _rating = widget.existingData!['rating'] ?? 5;
      _selectedProductId = widget.existingData!['productId'];
      _adviceEffectiveness = widget.existingData!['adviceEffectiveness'] ?? 'worked';
      _checkingExisting = false;
    } else {
      _checkExistingReviews();
    }
  }

  Future<void> _checkExistingReviews() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snap = await FirebaseFirestore.instance
          .collection('feedbacks')
          .where('userId', isEqualTo: user.uid)
          .get();
      
      final reviewed = snap.docs
          .map((d) => d.data()['productId'] as String?)
          .where((id) => id != null)
          .cast<String>()
          .toSet();

      if (mounted) {
        setState(() {
          _reviewedProductIds = reviewed;
          _checkingExisting = false;
          
          // Filter out already reviewed items from the selection list
          // Handle both 'productId' (from order items) and 'id' (from recommended items)
          final availableItems = widget.items.where((it) {
             final pid = it['productId'] ?? it['id'];
             return pid != null && !_reviewedProductIds.contains(pid);
          }).toList();

          if (availableItems.isNotEmpty) {
            _selectedProductId = availableItems.first['productId'] ?? availableItems.first['id'];
          } else {
            _selectedProductId = null;
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _checkingExisting = false);
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera, imageQuality: 50);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitFeedback() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    // For normal reviews, a product must be selected.
    // For advice feedback, we can allow rating the advice itself even without a specific product selected.
    if (!widget.isAdviceFeedback && _selectedProductId == null) return;

    // Double check to prevent concurrent submissions for the same product, but allow if editing existing
    if (widget.existingFeedbackId == null && _selectedProductId != null && _reviewedProductIds.contains(_selectedProductId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(LocalizationService.isTamil ? 'நீங்கள் ஏற்கனவே இந்தத் தயாரிப்பைப் பற்றி கருத்து தெரிவித்துள்ளீர்கள்.' : 'You have already reviewed this product.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      String? imageUrl;
      if (_image != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('feedbacks')
            .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
        await storageRef.putFile(_image!);
        imageUrl = await storageRef.getDownloadURL();
      }

      String productName = widget.existingData?['productName'] ?? 'Product';
      if (_selectedProductId != null && widget.items.isNotEmpty) {
        try {
          final selectedItem = widget.items.firstWhere((it) => (it['productId'] ?? it['id']) == _selectedProductId);
          productName = selectedItem['name_en'] ?? productName;
        } catch (_) {}
      }

      final feedbackData = {
        'userId': user.uid,
        'userName': user.displayName ?? 'Farmer',
        'orderId': widget.orderId,
        'productId': _selectedProductId,
        'productName': productName,
        'rating': _rating,
        'comment': _commentController.text.trim(),
        'imageUrl': imageUrl ?? widget.existingData?['imageUrl'],
        'isAdviceFeedback': widget.isAdviceFeedback,
        'adviceEffectiveness': widget.isAdviceFeedback ? _adviceEffectiveness : null,
        'diseaseName': widget.diseaseName ?? widget.existingData?['diseaseName'],
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.existingFeedbackId != null) {
        await FirebaseFirestore.instance
            .collection('feedbacks')
            .doc(widget.existingFeedbackId)
            .update(feedbackData);
      } else {
        feedbackData['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance.collection('feedbacks').add(feedbackData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(LocalizationService.isTamil ? 'கருத்து சேமிக்கப்பட்டது. நன்றி!' : 'Feedback saved. Thank you!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTa = LocalizationService.isTamil;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          isTa ? 'கருத்துக்களைப் பகிரவும்' : 'Share Feedback',
          style: GoogleFonts.notoSansTamil(fontWeight: FontWeight.bold),
        ),
      ),
      body: _checkingExisting 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.isAdviceFeedback) ...[
              Text(
                isTa ? 'ஆலோசனை எவ்வாறு செயல்பட்டது?' : 'How did the advice work?',
                style: GoogleFonts.notoSansTamil(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                   _buildEffectivenessBtn('worked', Icons.check_circle_outline, Colors.green, isTa ? 'வேலை செய்தது' : 'Worked'),
                   const SizedBox(width: 8),
                   _buildEffectivenessBtn('not_worked', Icons.highlight_off, Colors.red, isTa ? 'வேலை செய்யவில்லை' : 'Didn\'t Work'),
                ],
              ),
              const SizedBox(height: 32),
            ],
            Text(
              isTa ? 'எந்தப் பொருளைப் பற்றி உங்கள் கருத்தைக் கூற விரும்புகிறீர்கள்?' : 'Which product are you reviewing?',
              style: GoogleFonts.notoSansTamil(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            if (widget.existingFeedbackId != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  widget.existingData?['productName'] ?? (isTa ? 'தயாரிப்பு' : 'Product'),
                  style: GoogleFonts.notoSansTamil(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              )
            else if (_selectedProductId == null) 
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isTa ? 'இந்த ஆர்டரில் உள்ள அனைத்து தயாரிப்புகளும் ஏற்கனவே மதிப்பாய்வு செய்யப்பட்டுள்ளன.' : 'All products in this order have already been reviewed.',
                  style: TextStyle(color: Colors.red.shade900, fontSize: 13),
                ),
              )
            else
              Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedProductId,
                  isExpanded: true,
                  items: widget.items.where((it) {
                    final pid = it['productId'] ?? it['id'];
                    return pid != null && !_reviewedProductIds.contains(pid);
                  }).map((item) {
                    final name = LocalizationService.pickTaEn(item['name_ta'], item['name_en']);
                    return DropdownMenuItem(
                      value: (item['productId'] ?? item['id']) as String,
                      child: Text(name, style: GoogleFonts.notoSansTamil(fontSize: 14)),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedProductId = val),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: Column(
                children: [
                   Text(
                    isTa ? 'உங்கள் மதிப்பீடு' : 'Your Rating',
                    style: GoogleFonts.notoSansTamil(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < _rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 40,
                        ),
                        onPressed: () => setState(() => _rating = index + 1),
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              isTa ? 'உங்கள் கருத்துக்கள் (விரும்பினால்)' : 'Your Comments (Optional)',
              style: GoogleFonts.notoSansTamil(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _commentController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: isTa ? 'உங்கள் அனுபவத்தை இங்கே பகிரவும்...' : 'Tell us about your experience...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              isTa ? 'செடியின் புகைப்படம் (தேவைப்பட்டால்)' : 'Photo of Plant (Optional)',
              style: GoogleFonts.notoSansTamil(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                ),
                child: _image != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_image!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt_outlined, size: 40, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text(
                            isTa ? 'கேமராவைத் திறக்க கிளிக் செய்யவும்' : 'Click to open camera',
                            style: GoogleFonts.notoSansTamil(fontSize: 12, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: (_isSubmitting || (!widget.isAdviceFeedback && _selectedProductId == null)) ? null : _submitFeedback,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        isTa ? 'சமர்ப்பிக்கவும்' : 'Submit Feedback',
                        style: GoogleFonts.notoSansTamil(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEffectivenessBtn(String value, IconData icon, Color color, String label) {
    final isSelected = _adviceEffectiveness == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _adviceEffectiveness = value),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? color : Colors.grey.shade300, width: 2),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? color : Colors.grey),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(color: isSelected ? color : Colors.grey, fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
