import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/colors.dart';
import '../../../core/services/localization_service.dart';
import 'farmer_voice_advisory_screen.dart';
import 'farmer_ai_plant_doctor_screen.dart';

class FarmerAdvisoryMessagesScreen extends StatefulWidget {
  const FarmerAdvisoryMessagesScreen({super.key});

  @override
  State<FarmerAdvisoryMessagesScreen> createState() => _FarmerAdvisoryMessagesScreenState();
}

class _FarmerAdvisoryMessagesScreenState extends State<FarmerAdvisoryMessagesScreen> {
  Map<String, bool> _readState = {};
  Map<String, bool> _deletedState = {};

  @override
  void initState() {
    super.initState();
    _loadReadState();
  }

  Future<void> _loadReadState() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('advisory_reads')
          .get();
      final read = <String, bool>{};
      final deleted = <String, bool>{};
      for (final d in snap.docs) {
        final data = d.data();
        read[d.id] = data['readAt'] != null;
        deleted[d.id] = data['deleted'] == true;
      }
      if (mounted) {
        setState(() {
          _readState = read;
          _deletedState = deleted;
        });
      }
    } catch (_) {
      // ignore
    }
  }

  Future<void> _markRead(String messageId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('advisory_reads')
          .doc(messageId)
          .set({
        'readAt': FieldValue.serverTimestamp(),
        'deleted': false,
      }, SetOptions(merge: true));
      if (mounted) {
        setState(() {
          _readState[messageId] = true;
          _deletedState[messageId] = false;
        });
      }
    } catch (_) {}
  }

  Future<void> _hideMessage(String messageId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('advisory_reads')
          .doc(messageId)
          .set({
        'deleted': true,
        'readAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (mounted) {
        setState(() {
          _deletedState[messageId] = true;
          _readState[messageId] = true;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
       return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('advisory_messages')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          final visible = docs.where((d) => _deletedState[d.id] != true).toList();

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: visible.length + 1, // +1 for AI Banner
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              // 0 index is always AI Banner
              if (index == 0) {
                 return _buildAIPlantDoctorBanner();
              }

              final doc = visible[index - 1]; // Offset by 1
              final data = doc.data();
              final titleTa = data['title_ta'] as String? ?? '';
              final titleEn = data['title_en'] as String? ?? '';
              final summaryTa = data['summary_ta'] as String? ?? '';
              final summaryEn = data['summary_en'] as String? ?? '';
              final type = data['type'] as String? ?? 'general';
              final ts = data['createdAt'] as Timestamp?;
              final created = ts?.toDate();
              final isRead = _readState[doc.id] == true;

              return Dismissible(
                key: ValueKey(doc.id),
                background: Container(
                  margin: const EdgeInsets.only(right: 20),
                  alignment: Alignment.centerRight,
                  decoration: BoxDecoration(
                     color: Colors.red.shade100,
                     borderRadius: BorderRadius.circular(16)
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: const Icon(Icons.delete_outline, color: Colors.red),
                ),
                direction: DismissDirection.endToStart,
                confirmDismiss: (direction) async {
                   return await showDialog<bool>(
                      context: context,
                      builder: (context) {
                         return AlertDialog(
                            title: const Text('Hide Message?'),
                            content: const Text('Are you sure you want to hide this message?'),
                            actions: [
                               TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                               TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hide', style: TextStyle(color: Colors.red))),
                            ],
                         );
                      }
                   );
                },
                onDismissed: (_) => _hideMessage(doc.id),
                child: InkWell(
                  onTap: () async {
                    await _markRead(doc.id);
                    if (!mounted) return;
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => FarmerVoiceAdvisoryScreen(messageId: doc.id),
                      ),
                    );
                  },
                  child: _buildMessageTile(
                    titleTa: titleTa,
                    titleEn: titleEn,
                    summaryTa: summaryTa,
                    summaryEn: summaryEn,
                    type: type,
                    created: created,
                    isRead: isRead,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildAIPlantDoctorBanner() {
     return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
           gradient: const LinearGradient(
              colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight
           ),
           borderRadius: BorderRadius.circular(24),
           boxShadow: [
              BoxShadow(color: const Color(0xFF2E7D32).withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 6))
           ]
        ),
        child: Row(
           children: [
              Expanded(
                 child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       Text(
                          "AI Plant Doctor",
                          style: GoogleFonts.poppins(
                             fontSize: 20,
                             fontWeight: FontWeight.bold,
                             color: Colors.white
                          ),
                       ),
                       const SizedBox(height: 8),
                       Text(
                          "Scan your crop to detect diseases & get instant solutions.",
                          style: GoogleFonts.notoSansTamil(
                             fontSize: 13,
                             color: Colors.white.withOpacity(0.9),
                             height: 1.4
                          ),
                       ),
                       const SizedBox(height: 16),
                       ElevatedButton.icon(
                          onPressed: () {
                             Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const FarmerAIPlantDoctorScreen())
                             );
                          },
                          style: ElevatedButton.styleFrom(
                             backgroundColor: Colors.white,
                             foregroundColor: const Color(0xFF2E7D32),
                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
                          ),
                          icon: const Icon(Icons.qr_code_scanner, size: 18),
                          label: Text("Scan Now", style: GoogleFonts.poppins(fontWeight: FontWeight.bold))
                       )
                    ],
                 ),
              ),
              const SizedBox(width: 16),
              Container(
                 padding: const EdgeInsets.all(12),
                 decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle
                 ),
                 child: const Icon(Icons.psychology_alt, color: Colors.white, size: 48),
              )
           ],
        ),
     );
  }

  Widget _buildMessageTile({
    required String titleTa,
    required String titleEn,
    required String summaryTa,
    required String summaryEn,
    required String type,
    required DateTime? created,
    required bool isRead,
  }) {
    Color typeColor;
    IconData typeIcon;
    switch (type) {
      case 'pest':
        typeColor = Colors.redAccent;
        typeIcon = Icons.bug_report_rounded;
        break;
      case 'weather':
        typeColor = Colors.blueAccent;
        typeIcon = Icons.wb_sunny_rounded;
        break;
      case 'offer':
        typeColor = Colors.orangeAccent;
        typeIcon = Icons.local_offer_rounded;
        break;
      default:
        typeColor = AppColors.primary;
        typeIcon = Icons.article_rounded;
    }

    final dateText = created == null
        ? ''
        : '${created.day}/${created.month}/${created.year}';

    return Container(
      decoration: BoxDecoration(
        color: isRead ? Colors.white : const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
           BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4)
           )
        ],
        border: !isRead ? Border.all(color: AppColors.primary.withOpacity(0.2)) : null
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
             // Color Strip
             Container(
                width: 6,
                decoration: BoxDecoration(
                   color: typeColor,
                   borderRadius: const BorderRadius.horizontal(left: Radius.circular(16))
                ),
             ),
             Expanded(
               child: Padding(
                 padding: const EdgeInsets.all(16),
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Row(
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                          Container(
                             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                             decoration: BoxDecoration(
                                color: typeColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8)
                             ),
                             child: Row(
                                children: [
                                   Icon(typeIcon, size: 14, color: typeColor),
                                   const SizedBox(width: 4),
                                   Text(
                                      type.toUpperCase(),
                                      style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: typeColor),
                                   ),
                                ],
                             ),
                          ),
                         Text(
                           dateText,
                           style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textSecondary),
                         ),
                       ],
                     ),
                     const SizedBox(height: 12),
                     Text(
                       titleTa,
                       style: GoogleFonts.notoSansTamil(
                         fontSize: 16,
                         fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                         color: AppColors.textPrimary,
                       ),
                     ),
                     if (titleEn.isNotEmpty) ...[
                       const SizedBox(height: 2),
                       Text(
                         titleEn,
                         style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
                       ),
                     ],
                     const SizedBox(height: 8),
                     Text(
                       summaryTa,
                       maxLines: 2,
                       overflow: TextOverflow.ellipsis,
                       style: GoogleFonts.notoSansTamil(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                     ),
                   ],
                 ),
               ),
             ),
          ],
        ),
      ),
    );
  }
}
