import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/colors.dart';
import '../../../core/services/localization_service.dart';
import '../../../core/widgets/common_image.dart';

class OwnerFeedbackListScreen extends StatefulWidget {
  const OwnerFeedbackListScreen({super.key});

  @override
  State<OwnerFeedbackListScreen> createState() => _OwnerFeedbackListScreenState();
}

class _OwnerFeedbackListScreenState extends State<OwnerFeedbackListScreen> {
  String _filter = 'all'; // all, products, advice

  @override
  Widget build(BuildContext context) {
    final isTa = LocalizationService.isTamil;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: Text(
          isTa ? 'அனைத்து கருத்துக்கள்' : 'All Feedbacks',
          style: GoogleFonts.notoSansTamil(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _getStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text(isTa ? 'கருத்துக்கள் எதுவும் இல்லை' : 'No feedbacks found'));
                }

                final docs = snapshot.data!.docs;

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final fb = docs[index].data();
                    final docId = docs[index].id;
                    return _buildFeedbackCard(fb, docId, isTa);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _getStream() {
    var query = FirebaseFirestore.instance.collection('feedbacks').orderBy('createdAt', descending: true);
    if (_filter == 'products') {
      query = query.where('isAdviceFeedback', isNotEqualTo: true);
    } else if (_filter == 'advice') {
      query = query.where('isAdviceFeedback', isEqualTo: true);
    }
    return query.snapshots();
  }

  Widget _buildFilterChips() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          _chip('All', 'all'),
          const SizedBox(width: 8),
          _chip('Products', 'products'),
          const SizedBox(width: 8),
          _chip('Advice', 'advice'),
        ],
      ),
    );
  }

  Widget _chip(String label, String value) {
    final isSelected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildFeedbackCard(Map<String, dynamic> fb, String docId, bool isTa) {
    final isAdvice = fb['isAdviceFeedback'] == true;
    final rating = fb['rating'] as int? ?? 5;
    final ownerReply = fb['ownerReply'] as String?;
    final worked = fb['adviceEffectiveness'] == 'worked';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                fb['userName'] ?? 'Farmer',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              if (isAdvice)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: worked ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    worked ? (isTa ? 'பயனுள்ளது' : 'Worked') : (isTa ? 'பயனில்லை' : 'Didn\'t Work'),
                    style: TextStyle(color: worked ? Colors.green : Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                )
              else
                Row(
                  children: List.generate(5, (i) => Icon(Icons.star, size: 14, color: i < rating ? Colors.amber : Colors.grey.shade300)),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isAdvice ? '${fb['diseaseName'] ?? 'Advice'}' : (fb['productName'] ?? 'Product'),
            style: TextStyle(fontSize: 11, color: Colors.blue.shade700, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(fb['comment'] ?? '', style: const TextStyle(fontSize: 13)),
          if (fb['imageUrl'] != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CommonImage(imageUrl: fb['imageUrl'], height: 120, width: double.infinity, fit: BoxFit.cover),
            ),
          ],
          const SizedBox(height: 12),
          if (ownerReply != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isTa ? 'உங்கள் பதில்:' : 'Your Reply:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF0EA5E9))),
                  const SizedBox(height: 4),
                  Text(ownerReply, style: const TextStyle(fontSize: 12)),
                ],
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showReplyDialog(docId, isTa),
                icon: const Icon(Icons.reply, size: 16),
                label: Text(isTa ? 'பதில் அளி' : 'Reply'),
              ),
            ),
          const SizedBox(height: 12),
          _buildRepliesSection(docId, isTa),
        ],
      ),
    );
  }

  Widget _buildRepliesSection(String feedbackId, bool isTa) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('feedbacks')
          .doc(feedbackId)
          .collection('replies')
          .orderBy('createdAt', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox.shrink();

        final replies = snapshot.data!.docs;

        return Column(
          children: [
            const Divider(height: 24),
            ...replies.map((reply) {
              final data = reply.data();
              return Padding(
                padding: const EdgeInsets.only(left: 20, bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.subdirectory_arrow_right, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                data['userName'] ?? 'Farmer',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                (data['createdAt'] as Timestamp?)?.toDate().toString().substring(0, 10) ?? '',
                                style: const TextStyle(fontSize: 9, color: Colors.grey),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(data['comment'] ?? '', style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }

  void _showReplyDialog(String feedbackId, bool isTa) {
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
}
