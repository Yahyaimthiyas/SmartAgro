import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/colors.dart';
import '../../../core/services/localization_service.dart';

class OwnerCropGuideScreen extends StatefulWidget {
  const OwnerCropGuideScreen({super.key});

  @override
  State<OwnerCropGuideScreen> createState() => _OwnerCropGuideScreenState();
}

class _OwnerCropGuideScreenState extends State<OwnerCropGuideScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final isTa = LocalizationService.isTamil;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          isTa ? 'பயிர் மேலாண்மை' : 'Crop Guide Management',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _firestore.collection('crop_guides').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return _buildEmptyState(isTa);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final guide = docs[index].data();
              final guideId = docs[index].id;
              final cropNameEn = guide['cropNameEn'] ?? 'Unknown';
              final cropNameTa = guide['cropNameTa'] ?? '';
              final stages = List<Map<String, dynamic>>.from(guide['stages'] ?? []);

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.shade200)),
                margin: const EdgeInsets.only(bottom: 16),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF0EA5E9).withOpacity(0.1),
                    child: const Icon(Icons.eco, color: Color(0xFF0EA5E9)),
                  ),
                  title: Text(
                    isTa && cropNameTa.isNotEmpty ? cropNameTa : cropNameEn,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('${stages.length} ${isTa ? "நிலைகள்" : "stages"}'),
                  children: [
                    ...stages.map((stage) {
                      return ListTile(
                        title: Text(isTa && stage['titleTa'] != null ? stage['titleTa'] : stage['titleEn']),
                        subtitle: Text('Day ${stage['day']}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit, size: 18),
                          onPressed: () => _editStage(guideId, stages, stages.indexOf(stage)),
                        ),
                      );
                    }).toList(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          TextButton.icon(
                            onPressed: () => _addStage(guideId, stages),
                            icon: const Icon(Icons.add),
                            label: Text(isTa ? 'புதிய நிலை' : 'Add Stage'),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () => _deleteGuide(guideId),
                            icon: const Icon(Icons.delete, color: Colors.red),
                            label: Text(isTa ? 'நீக்கு' : 'Delete', style: const TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewCropGuide,
        backgroundColor: const Color(0xFF0EA5E9),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(isTa ? 'புதிய பயிர்' : 'Add New Crop', style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildEmptyState(bool isTa) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.library_books_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            isTa ? 'பயிர் வழிகாட்டிகள் எதுவும் இல்லை' : 'No crop guides added yet',
            style: GoogleFonts.outfit(fontSize: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _addNewCropGuide,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0EA5E9)),
            child: Text(isTa ? 'இப்போது சேர்' : 'Add Now', style: const TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  Future<void> _addNewCropGuide() async {
    final isTa = LocalizationService.isTamil;
    final nameEnCtrl = TextEditingController();
    final nameTaCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isTa ? 'புதிய பயிர் வழிகாட்டி' : 'New Crop Guide'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameEnCtrl, decoration: const InputDecoration(labelText: 'Crop Name (English)')),
            TextField(controller: nameTaCtrl, decoration: const InputDecoration(labelText: 'Crop Name (Tamil)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isTa ? 'ரத்து' : 'Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameEnCtrl.text.isNotEmpty) {
                await _firestore.collection('crop_guides').add({
                  'cropNameEn': nameEnCtrl.text,
                  'cropNameTa': nameTaCtrl.text,
                  'stages': [],
                  'createdAt': FieldValue.serverTimestamp(),
                });
                Navigator.pop(ctx);
              }
            },
            child: Text(isTa ? 'உருவாக்கு' : 'Create'),
          )
        ],
      ),
    );
  }

  Future<void> _addStage(String guideId, List<Map<String, dynamic>> existingStages) async {
    await _showStageDialog(guideId, existingStages, null);
  }

  Future<void> _editStage(String guideId, List<Map<String, dynamic>> existingStages, int index) async {
    await _showStageDialog(guideId, existingStages, index);
  }

  Future<void> _showStageDialog(String guideId, List<Map<String, dynamic>> existingStages, int? editIndex) async {
    final isTa = LocalizationService.isTamil;
    final titleEnCtrl = TextEditingController(text: editIndex != null ? existingStages[editIndex]['titleEn'] : '');
    final titleTaCtrl = TextEditingController(text: editIndex != null ? existingStages[editIndex]['titleTa'] : '');
    final descEnCtrl = TextEditingController(text: editIndex != null ? existingStages[editIndex]['descEn'] : '');
    final descTaCtrl = TextEditingController(text: editIndex != null ? existingStages[editIndex]['descTa'] : '');
    final dayCtrl = TextEditingController(text: editIndex != null ? existingStages[editIndex]['day'].toString() : '');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(editIndex != null ? (isTa ? 'நிலையைத் திருத்து' : 'Edit Stage') : (isTa ? 'புதிய நிலை' : 'Add New Stage')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: dayCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Day Number')),
              TextField(controller: titleEnCtrl, decoration: const InputDecoration(labelText: 'Title (English)')),
              TextField(controller: titleTaCtrl, decoration: const InputDecoration(labelText: 'Title (Tamil)')),
              TextField(controller: descEnCtrl, decoration: const InputDecoration(labelText: 'Product Recommendation (English)')),
              TextField(controller: descTaCtrl, decoration: const InputDecoration(labelText: 'Product Recommendation (Tamil)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isTa ? 'ரத்து' : 'Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (titleEnCtrl.text.isNotEmpty && dayCtrl.text.isNotEmpty) {
                final newStage = {
                  'id': editIndex != null ? existingStages[editIndex]['id'] : DateTime.now().millisecondsSinceEpoch.toString(),
                  'day': int.tryParse(dayCtrl.text) ?? 1,
                  'titleEn': titleEnCtrl.text,
                  'titleTa': titleTaCtrl.text,
                  'descEn': descEnCtrl.text,
                  'descTa': descTaCtrl.text,
                };

                final updatedStages = List<Map<String, dynamic>>.from(existingStages);
                if (editIndex != null) {
                  updatedStages[editIndex] = newStage;
                } else {
                  updatedStages.add(newStage);
                }
                updatedStages.sort((a, b) => (a['day'] as int).compareTo(b['day'] as int));

                await _firestore.collection('crop_guides').doc(guideId).update({'stages': updatedStages});
                Navigator.pop(ctx);
              }
            },
            child: Text(isTa ? 'சேமி' : 'Save'),
          )
        ],
      ),
    );
  }

  Future<void> _deleteGuide(String guideId) async {
    final isTa = LocalizationService.isTamil;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isTa ? 'நிச்சயமாக நீக்கவா?' : 'Delete Guide?'),
        content: Text(isTa ? 'இந்த பயிர் வழிகாட்டி முற்றிலும் நீக்கப்படும்.' : 'This crop guide will be permanently removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(isTa ? 'ரத்து' : 'Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(isTa ? 'நீக்கு' : 'Delete', style: const TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await _firestore.collection('crop_guides').doc(guideId).delete();
    }
  }
}
