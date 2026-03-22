import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/colors.dart';
import '../../../core/services/localization_service.dart';
import '../../../core/widgets/common_image.dart';
import '../orders/owner_order_details_screen.dart';

class OwnerDiseaseManagementScreen extends StatefulWidget {
  const OwnerDiseaseManagementScreen({super.key});

  @override
  State<OwnerDiseaseManagementScreen> createState() => _OwnerDiseaseManagementScreenState();
}

class _OwnerDiseaseManagementScreenState extends State<OwnerDiseaseManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTa = LocalizationService.isTamil;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        title: Text(
          isTa ? 'நோய் மேலாண்மை' : 'Disease Management',
          style: GoogleFonts.notoSansTamil(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF0EA5E9),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF0EA5E9),
          tabs: [
            Tab(text: isTa ? 'நிபுணர் ஆலோசனைகள்' : 'Common Templates'),
            Tab(text: isTa ? 'புதிய கோரிக்கைகள்' : 'Farmer Requests'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSearchField(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTemplatesTab(),
                _buildRequestsTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: () => _showAddTemplateDialog(),
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(isTa ? 'சேர்' : 'Add New', style: const TextStyle(color: Colors.white)),
              backgroundColor: const Color(0xFF0EA5E9),
            )
          : null,
    );
  }

  Widget _buildSearchField() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
        decoration: InputDecoration(
          hintText: LocalizationService.tr('search_hint'),
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildTemplatesTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('common_diseases').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data();
          final crop = (data['cropName'] ?? '').toString().toLowerCase();
          final disease = (data['diseaseName'] ?? '').toString().toLowerCase();
          return crop.contains(_searchQuery) || disease.contains(_searchQuery);
        }).toList();

        if (docs.isEmpty) {
          return _buildEmptyState(
            icon: Icons.assignment_outlined,
            message: LocalizationService.isTamil ? 'வார்ப்புருக்கள் எதுவும் இல்லை' : 'No templates found',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (ctx, i) {
            final data = docs[i].data();
            return _DiseaseTemplateCard(data: data, docId: docs[i].id);
          },
        );
      },
    );
  }

  Widget _buildRequestsTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('needsDosageAdvice', isEqualTo: true)
          .where('dosageAdviceStatus', isEqualTo: 'requested')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data();
          final crop = (data['cropName'] ?? '').toString().toLowerCase();
          final disease = (data['diseaseDetails'] ?? '').toString().toLowerCase();
          return crop.contains(_searchQuery) || disease.contains(_searchQuery);
        }).toList();

        if (docs.isEmpty) {
          return _buildEmptyState(
            icon: Icons.mark_email_read_outlined,
            message: LocalizationService.isTamil ? 'புதிய கோரிக்கைகள் இல்லை' : 'No new requests',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (ctx, i) {
            final data = docs[i].data();
            return _FarmerRequestCard(data: data, docId: docs[i].id);
          },
        );
      },
    );
  }

  Widget _buildEmptyState({required IconData icon, required String message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(message, style: GoogleFonts.poppins(color: Colors.grey)),
        ],
      ),
    );
  }

  void _showAddTemplateDialog() {
    // Basic implementation of adding a template manually
    // For brevity, I'll reuse the logic but with empty data
    _showTemplateEditor(context, null, {});
  }
}

class _DiseaseTemplateCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;

  const _DiseaseTemplateCard({required this.data, required this.docId});

  @override
  Widget build(BuildContext context) {
    final isTa = LocalizationService.isTamil;
    final products = (data['products'] as List<dynamic>? ?? []);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['cropName'] ?? 'No Crop',
                      style: GoogleFonts.notoSansTamil(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF0EA5E9)),
                    ),
                    Text(
                      data['diseaseName'] ?? 'No Disease',
                      style: GoogleFonts.notoSansTamil(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    // [NEW] Feedback Stats
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('feedbacks')
                          .where('isAdviceFeedback', isEqualTo: true)
                          .where('diseaseName', isEqualTo: data['diseaseName'])
                          .snapshots(),
                      builder: (context, fbSnap) {
                        if (!fbSnap.hasData || fbSnap.data!.docs.isEmpty) return const SizedBox();
                        final docs = fbSnap.data!.docs;
                        final worked = docs.where((d) => d.data()['adviceEffectiveness'] == 'worked').length;
                        final total = docs.length;
                        final percent = (worked / total * 100).toStringAsFixed(0);

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(4)),
                          child: Text(
                            '$percent% ${isTa ? "வெற்றி" : "Success"} ($total ${isTa ? "விவசாயிகள்" : "Farmers"})',
                            style: GoogleFonts.poppins(fontSize: 10, color: Colors.green.shade700, fontWeight: FontWeight.bold),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                onPressed: () => _confirmDelete(context),
              ),
            ],
          ),
          if (data['images'] != null && (data['images'] as List).isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: (data['images'] as List).length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (ctx, idx) => ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CommonImage(
                    imageUrl: data['images'][idx],
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ],
          const Divider(height: 24),
          if (data['level'] != null)
            Text(
              '${isTa ? "நிலை" : "Level"}: ${data['level']}',
              style: GoogleFonts.notoSansTamil(fontSize: 12, color: Colors.grey),
            ),
          const SizedBox(height: 8),
          Text(
            data['advice'] ?? '',
            style: GoogleFonts.notoSansTamil(fontSize: 13),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: products.map((p) {
              final dosageText = (p['dosage_val'] != null && p['dosage_val'].toString().isNotEmpty)
                ? "${p['dosage_val']} ${p['dosage_unit']} ${isTa ? '...' : p['dosage_basis']}"
                : (p['dosage'] ?? '');
              return Chip(
                label: Text("${p['name_en'] ?? ''} ($dosageText)"),
                labelStyle: const TextStyle(fontSize: 10),
                backgroundColor: Colors.blue.shade50,
                padding: EdgeInsets.zero,
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showTemplateEditor(context, docId, data),
                    child: Text(isTa ? 'மாற்றுக' : 'Edit'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showFarmerReviews(context, data['diseaseName']),
                    icon: const Icon(Icons.reviews_outlined, size: 16, color: Colors.white),
                    label: Text(isTa ? 'மதிப்பீடு' : 'Reviews', style: const TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFarmerReviews(BuildContext context, String? diseaseName) {
    final isTa = LocalizationService.isTamil;
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
                  if (docs.isEmpty) return Center(child: Text(isTa ? 'கருத்துக்கள் எதுவும் இல்லை' : 'No reviews yet'));

                  return ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (ctx, i) {
                      final fbDoc = docs[i];
                      final fb = fbDoc.data();
                      final worked = fb['adviceEffectiveness'] == 'worked';
                      final ownerReply = fb['ownerReply'] as String?;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
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
                                    child: CommonImage(imageUrl: fb['imageUrl'], height: 100, width: 150, fit: BoxFit.cover),
                                  ),
                                ],
                              ],
                            ),
                            trailing: Text(
                              _formatDate(fb['createdAt'] as Timestamp?),
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                          ),
                          if (ownerReply != null)
                            Container(
                              margin: const EdgeInsets.only(left: 56, right: 16, bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(isTa ? 'ஆசிரியரின் பதில்:' : 'Owner Reply:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.blue)),
                                  const SizedBox(height: 4),
                                  Text(ownerReply, style: const TextStyle(fontSize: 12)),
                                ],
                              ),
                            )
                          else
                            Padding(
                              padding: const EdgeInsets.only(left: 56, bottom: 8),
                              child: TextButton.icon(
                                onPressed: () => _showReplyDialog(context, fbDoc.id, isTa),
                                icon: const Icon(Icons.reply, size: 16),
                                label: Text(isTa ? 'பதில் அளி' : 'Reply'),
                              ),
                            ),
                        ],
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

  String _formatDate(Timestamp? ts) {
    if (ts == null) return '';
    final d = ts.toDate();
    return "${d.day}/${d.month}/${d.year}";
  }

  void _showReplyDialog(BuildContext context, String feedbackId, bool isTa) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isTa ? 'பதில் அளிக்கவும்' : 'Send Reply'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: isTa ? 'உங்கள் பதிலை இங்கே தட்டச்சு செய்யவும்...' : 'Type your reply here...',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isTa ? 'ரத்து' : 'Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              await FirebaseFirestore.instance.collection('feedbacks').doc(feedbackId).update({
                'ownerReply': controller.text.trim(),
                'repliedAt': FieldValue.serverTimestamp(),
              });
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text(isTa ? 'அனுப்பு' : 'Send', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
     showDialog(
       context: context,
       builder: (ctx) => AlertDialog(
         title: Text(LocalizationService.isTamil ? 'நீக்கவா?' : 'Delete Template?'),
         content: Text(LocalizationService.isTamil ? 'உறுதியாக நீக்க விரும்புகிறீர்களா?' : 'Are you sure you want to delete this template?'),
         actions: [
           TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
           TextButton(
             onPressed: () async {
               await FirebaseFirestore.instance.collection('common_diseases').doc(docId).delete();
               Navigator.pop(ctx);
             }, 
             child: const Text('Delete', style: TextStyle(color: Colors.red))
           ),
         ],
       ),
     );
  }
}

class _FarmerRequestCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;

  const _FarmerRequestCard({required this.data, required this.docId});

  @override
  Widget build(BuildContext context) {
    final isTa = LocalizationService.isTamil;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade100),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.orange.shade100, shape: BoxShape.circle),
                child: const Icon(Icons.notification_important_outlined, color: Colors.orange, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['cropName'] ?? 'No Crop',
                      style: GoogleFonts.notoSansTamil(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Order #$docId',
                      style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (data['diseaseImageUrl'] != null && data['diseaseImageUrl'].toString().isNotEmpty) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CommonImage(
                imageUrl: data['diseaseImageUrl'],
                width: double.infinity,
                height: 150,
                fit: BoxFit.cover,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            '${isTa ? "நோய்" : "Disease"}: ${data['diseaseDetails'] ?? ''}',
            style: GoogleFonts.notoSansTamil(fontSize: 14),
          ),
          if (data['diseaseLevel'] != null)
            Text(
              '${isTa ? "தீவிரம்" : "Severity"}: ${data['diseaseLevel']}',
              style: GoogleFonts.notoSansTamil(fontSize: 12, color: Colors.red.shade700),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OwnerOrderDetailsScreen(orderId: docId))),
                  child: Text(isTa ? 'ஆர்டர் காண்க' : 'View Order'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _showTemplateEditor(context, null, {
                    'cropName': data['cropName'],
                    'diseaseName': data['diseaseDetails'],
                    'level': data['diseaseLevel'],
                    'fromOrderId': docId,
                  }),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  child: Text(isTa ? 'ஆலோசனை அளி' : 'Provide & Publish', style: const TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

void _showTemplateEditor(BuildContext context, String? existingDocId, Map<String, dynamic> initialData) {
  final isTa = LocalizationService.isTamil;
  final cropController = TextEditingController(text: initialData['cropName'] ?? '');
  final diseaseController = TextEditingController(text: initialData['diseaseName'] ?? initialData['diseaseDetails'] ?? '');
  final adviceController = TextEditingController(text: initialData['advice'] ?? '');
  
  final List<String> levelOptions = ['Starting Stage', 'Moderate', 'Advanced', 'More insects in the plant'];
  String selectedLevel = initialData['level'] ?? levelOptions.first;
  if (!levelOptions.contains(selectedLevel)) {
    selectedLevel = levelOptions.first;
  }
  final List<Map<String, dynamic>> products = List.from(initialData['products'] ?? []);
  final List<String> diseaseImages = List.from(initialData['images'] ?? []);

  Future<void> pickImage(StateSetter setS) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      final bytes = await File(pickedFile.path).readAsBytes();
      final base64String = base64Encode(bytes);
      setS(() {
        diseaseImages.add('data:image/jpeg;base64,$base64String');
      });
    }
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 20, right: 20, top: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    existingDocId == null ? (isTa ? 'நிபுணர் ஆலோசனை உருவாக்கு' : 'Create Expert Advice') : (isTa ? 'ஆலோசனையை திருத்து' : 'Edit Advice'),
                    style: GoogleFonts.notoSansTamil(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(onPressed: () => _showMeasurementInfo(ctx), icon: const Icon(Icons.info_outline, color: Colors.blue)),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: cropController,
                decoration: InputDecoration(labelText: isTa ? 'பயிர் பெயர்' : 'Crop Name', border: const OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: diseaseController,
                decoration: InputDecoration(labelText: isTa ? 'நோய் விவரம்' : 'Disease Detail', border: const OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              Text(isTa ? 'நோய் தீவிரம்' : 'Disease Level', style: const TextStyle(fontWeight: FontWeight.bold)),
              DropdownButton<String>(
                value: selectedLevel,
                isExpanded: true,
                items: levelOptions
                    .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                    .toList(),
                onChanged: (v) => setS(() => selectedLevel = v!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: adviceController,
                maxLines: 3,
                decoration: InputDecoration(labelText: isTa ? 'ஆலோசனை' : 'Advice / Dosage Instruction', border: const OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              
              // Disease Images Section
              Text(isTa ? 'நோய் புகைப்படங்கள்' : 'Disease Images', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    ...diseaseImages.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final img = entry.value;
                      return Stack(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CommonImage(imageUrl: img, fit: BoxFit.cover),
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 8,
                            child: GestureDetector(
                              onTap: () => setS(() => diseaseImages.removeAt(idx)),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                child: const Icon(Icons.close, size: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                    GestureDetector(
                      onTap: () => pickImage(setS),
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300, style: BorderStyle.none),
                        ),
                        child: const Icon(Icons.add_a_photo_outlined, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(isTa ? 'பரிந்துரைக்கப்பட்ட தயாரிப்புகள்' : 'Recommended Products', style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextButton.icon(
                    onPressed: () async {
                      final p = await _showProductPickerManual(ctx);
                      if (p != null) {
                        setS(() => products.add({...p, 'dosage': ''}));
                      }
                    }, 
                    icon: const Icon(Icons.add), 
                    label: Text(isTa ? 'சேர்க்க' : 'Add')
                  ),
                ],
              ),
              for (var i = 0; i < products.length; i++)
                _buildProductDosageItem(i, products, setS, isTa),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final cropName = cropController.text.trim();
                    final diseaseName = diseaseController.text.trim();

                    if (cropName.isEmpty || diseaseName.isEmpty) return;
                    
                    final templateData = {
                      'cropName': cropName,
                      'crop_lower': cropName.toLowerCase(),
                      'diseaseName': diseaseName,
                      'disease_lower': diseaseName.toLowerCase(),
                      'level': selectedLevel,
                      'advice': adviceController.text.trim(),
                      'products': products,
                      'images': diseaseImages,
                      'updatedAt': FieldValue.serverTimestamp(),
                    };

                    if (existingDocId != null) {
                      await FirebaseFirestore.instance.collection('common_diseases').doc(existingDocId).update(templateData);
                    } else {
                      await FirebaseFirestore.instance.collection('common_diseases').add(templateData);
                    }

                    // If publishing from a request, update the order too
                    if (initialData['fromOrderId'] != null) {
                      await FirebaseFirestore.instance.collection('orders').doc(initialData['fromOrderId']).update({
                        'dosageAdvice': adviceController.text,
                        'recommendedProducts': products,
                        'dosageAdviceStatus': 'provided',
                      });
                    }

                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.all(16)),
                  child: Text(isTa ? 'வெளியிடுக' : 'Publish Template', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<Map<String, dynamic>?> _showProductPickerManual(BuildContext context) async {
  final isTa = LocalizationService.isTamil;
  final results = await FirebaseFirestore.instance.collection('products').get();
  final products = results.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  
  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (ctx) {
      final searchController = TextEditingController();
      return StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(isTa ? 'தயாரிப்பைத் தேர்ந்தெடுக்கவும்' : 'Pick Product'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: Column(
              children: [
                TextField(
                  controller: searchController,
                  onChanged: (v) => setS(() {}),
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search...'),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: products.length,
                    itemBuilder: (c, i) {
                      final p = products[i];
                      final name = isTa ? (p['name_ta'] ?? p['name_en']) : (p['name_en'] ?? p['name_ta']);
                      if (searchController.text.isNotEmpty && !name.toString().toLowerCase().contains(searchController.text.toLowerCase())) {
                        return const SizedBox.shrink();
                      }
                      return ListTile(
                        title: Text(name),
                        onTap: () => Navigator.pop(ctx, p),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Widget _buildProductDosageItem(int i, List<Map<String, dynamic>> products, StateSetter setS, bool isTa) {
  final item = products[i];
  final name = isTa ? (item['name_ta'] ?? item['name_en']) : (item['name_en'] ?? item['name_ta']);
  
  // Default values for structured dosage if not present
  item['dosage_val'] ??= '';
  item['dosage_unit'] ??= 'ml';
  item['dosage_basis'] ??= 'per Liter';
  item['dosage_notes'] ??= '';

  final List<String> units = ['ml', 'Liter', 'Gram', 'Kg'];
  final List<String> basisOptions = [
    'per Liter', 
    'per 10L Tank', 
    'per 16L Tank', 
    'per Cent', 
    'per Acre', 
    'per Hectare'
  ];

  final List<String> basisOptionsTa = [
    'ஒரு லிட்டருக்கு', 
    '10லி டேங்கிற்கு', 
    '16லி டேங்கிற்கு', 
    'ஒரு சென்ட்டிற்கு', 
    'ஒரு ஏக்கருக்கு', 
    'ஒரு ஹெக்டேருக்கு'
  ];

  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.grey.shade50,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold))),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
              onPressed: () => setS(() => products.removeAt(i)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Amount
            SizedBox(
              width: 70,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Qty',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) => setS(() => item['dosage_val'] = v),
                controller: TextEditingController(text: item['dosage_val'])..selection = TextSelection.collapsed(offset: (item['dosage_val'] as String).length),
              ),
            ),
            const SizedBox(width: 8),
            // Unit
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<String>(
                value: item['dosage_unit'],
                underline: const SizedBox(),
                items: units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                onChanged: (v) => setS(() => item['dosage_unit'] = v!),
              ),
            ),
            const SizedBox(width: 8),
            // Basis
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String>(
                  value: item['dosage_basis'],
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: basisOptions.asMap().entries.map((entry) {
                    return DropdownMenuItem(
                      value: entry.value, 
                      child: Text(isTa ? basisOptionsTa[entry.key] : entry.value, style: const TextStyle(fontSize: 12)),
                    );
                  }).toList(),
                  onChanged: (v) => setS(() => item['dosage_basis'] = v!),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          decoration: InputDecoration(
            hintText: isTa ? 'குறிப்புகள் (எ.கா. மாலையில் தெளிக்கவும்)' : 'Notes (e.g. Spray in evening)',
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onChanged: (v) => item['dosage_notes'] = v,
          controller: TextEditingController(text: item['dosage_notes'])..selection = TextSelection.collapsed(offset: (item['dosage_notes'] as String).length),
        ),
      ],
    ),
  );
}

void _showMeasurementInfo(BuildContext context) {
  final isTa = LocalizationService.isTamil;
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(isTa ? 'முக்கிய அளவீடுகள்' : 'Important Measurements'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _mRow('1 Acre (ஏக்கர்)', '100 Cent (சென்ட்)'),
            _mRow('1 Cent (சென்ட்)', '435.6 Sq.Ft'),
            _mRow('1 Hectare (ஹெக்டேர்)', '2.47 Acre (ஏக்கர்)'),
            const Divider(),
            _mRow('1 Liter (லிட்டர்)', '1000 ml'),
            _mRow('1 Kg (கிலோ)', '1000 Gram'),
            const Divider(),
            _mRow('Pesticide Tank (டேங்க்)', '10L or 16L'),
            _mRow('1 Cent coverage', 'Typically 2-3 Liters water'),
          ],
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
    ),
  );
}

Widget _mRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        Text(value, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    ),
  );
}
