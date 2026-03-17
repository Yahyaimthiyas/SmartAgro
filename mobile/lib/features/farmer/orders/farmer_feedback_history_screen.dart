import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/colors.dart';
import '../../../core/services/localization_service.dart';
import 'feedback_screen.dart';
import '../../../core/widgets/common_image.dart';

class FarmerFeedbackHistoryScreen extends StatelessWidget {
  const FarmerFeedbackHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isTa = LocalizationService.isTamil;

    if (user == null) return const Scaffold(body: Center(child: Text("Please login")));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          isTa ? 'எனது கருத்துக்கள்' : 'My Feedbacks',
          style: GoogleFonts.notoSansTamil(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('feedbacks')
            .where('userId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final docs = snapshot.data?.docs ?? [];
          
          // Client side sorting
          final sortedDocs = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(docs);
          sortedDocs.sort((a, b) {
            final t1 = a.data()['createdAt'] as Timestamp?;
            final t2 = b.data()['createdAt'] as Timestamp?;
            if (t1 == null || t2 == null) return 0;
            return t2.compareTo(t1);
          });

          if (sortedDocs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.rate_review_outlined, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    isTa ? 'கருத்துக்கள் எதுவும் இல்லை' : 'No feedbacks yet',
                    style: GoogleFonts.notoSansTamil(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedDocs.length,
            itemBuilder: (context, index) {
              final doc = sortedDocs[index];
              final data = doc.data();
              return _FeedbackCard(
                feedbackId: doc.id,
                data: data,
                isTa: isTa,
              );
            },
          );
        },
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  final String feedbackId;
  final Map<String, dynamic> data;
  final bool isTa;

  const _FeedbackCard({
    required this.feedbackId,
    required this.data,
    required this.isTa,
  });

  @override
  Widget build(BuildContext context) {
    final rating = data['rating'] as int? ?? 5;
    final comment = data['comment'] as String? ?? '';
    final productName = data['productName'] as String? ?? 'General Advice';
    final imageUrl = data['imageUrl'] as String?;
    final ownerReply = data['ownerReply'] as String?;
    final createdAt = data['createdAt'] as Timestamp?;
    final dateStr = createdAt != null 
        ? "${createdAt.toDate().day}/${createdAt.toDate().month}/${createdAt.toDate().year}"
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        productName,
                        style: GoogleFonts.notoSansTamil(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      dateStr,
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 18,
                    );
                  }),
                ),
                if (comment.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    comment,
                    style: GoogleFonts.notoSansTamil(fontSize: 14, color: AppColors.textPrimary),
                  ),
                ],
                if (imageUrl != null) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CommonImage(
                      imageUrl: imageUrl,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
                if (ownerReply != null) ...[
                  const SizedBox(height: 16),
                  Container(
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
                            const Icon(Icons.reply_rounded, color: Colors.blue, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              isTa ? 'ஆசிரியர் பதில்:' : 'Owner Reply:',
                              style: GoogleFonts.notoSansTamil(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Colors.blue.shade800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ownerReply,
                          style: GoogleFonts.notoSansTamil(fontSize: 13, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _editFeedback(context),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text(isTa ? 'திருத்து' : 'Edit'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                ),
                TextButton.icon(
                  onPressed: () => _confirmDelete(context),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: Text(isTa ? 'நீக்கு' : 'Delete'),
                  style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _editFeedback(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FeedbackScreen(
          orderId: data['orderId'] ?? '',
          items: [], // Not strictly needed for edit mode if we change FeedbackScreen
          existingFeedbackId: feedbackId,
          existingData: data,
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isTa ? 'நீக்குவதை உறுதிப்படுத்தவும்' : 'Confirm Delete'),
        content: Text(isTa ? 'இந்த கருத்தை நீக்க விரும்புகிறீர்களா?' : 'Are you sure you want to delete this feedback?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isTa ? 'ரத்து' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseFirestore.instance.collection('feedbacks').doc(feedbackId).delete();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(isTa ? 'நீக்கப்பட்டது' : 'Deleted successfully')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(isTa ? 'நீக்கு' : 'Delete'),
          ),
        ],
      ),
    );
  }
}
