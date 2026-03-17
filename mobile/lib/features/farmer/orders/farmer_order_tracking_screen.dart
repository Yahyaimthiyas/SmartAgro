import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'feedback_screen.dart';

import '../../../core/constants/colors.dart';
import '../../../core/services/localization_service.dart';
import '../../notifications/repositories/notification_repository.dart';
import '../../../core/widgets/common_image.dart';

class FarmerOrderTrackingScreen extends StatelessWidget {
  final String orderId;

  const FarmerOrderTrackingScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          LocalizationService.tr('title_order_tracking'),
          style: GoogleFonts.notoSansTamil(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('orders').doc(orderId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Text(
                LocalizationService.tr('msg_order_not_found'),
                style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary),
              ),
            );
          }

          final data = snapshot.data!.data()!;
          final status = data['status'] as String? ?? 'reserved';
          final total = data['totalAmount'] as num? ?? 0;
          final payment = data['paymentMethod'] as String? ?? 'cash';
          final ts = data['createdAt'] as Timestamp?;
          final created = ts?.toDate();
          final items = (data['items'] as List<dynamic>? ?? [])
              .cast<Map<String, dynamic>>();

          final placedAt = data['placedAt'] as Timestamp? ?? ts; // Fallback to createdAt
          final readyAt = data['readyAt'] as Timestamp?;
          final pickedAt = data['pickedAt'] as Timestamp?;

          final steps = [
            _StepInfo(
              key: 'reserved',
              titleTa: LocalizationService.tr('status_placed_label'),
              titleEn: LocalizationService.tr('status_placed_label'),
              subtitleTa: LocalizationService.tr('status_placed_subtitle'),
              subtitleEn: LocalizationService.tr('status_placed_subtitle'),
              timestamp: placedAt?.toDate(),
            ),
            _StepInfo(
              key: 'ready',
              titleTa: LocalizationService.tr('status_ready_label'),
              titleEn: LocalizationService.tr('status_ready_label'),
              subtitleTa: LocalizationService.tr('status_ready_subtitle'),
              subtitleEn: LocalizationService.tr('status_ready_subtitle'),
              timestamp: readyAt?.toDate(),
            ),
            _StepInfo(
              key: 'picked',
              titleTa: LocalizationService.tr('status_picked_label'),
              titleEn: LocalizationService.tr('status_picked_label'),
              subtitleTa: LocalizationService.tr('status_picked_subtitle'),
              subtitleEn: LocalizationService.tr('status_picked_subtitle'),
              timestamp: pickedAt?.toDate(),
            ),
            if (status == 'cancelled')
              _StepInfo(
                key: 'cancelled',
                titleTa: LocalizationService.tr('status_cancelled_label'),
                titleEn: LocalizationService.tr('status_cancelled_label'),
                subtitleTa: LocalizationService.tr('status_cancelled_subtitle'),
                subtitleEn: LocalizationService.tr('status_cancelled_subtitle'),
                timestamp: (data['cancelledAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
              ),
          ];

          int currentIndex = steps.indexWhere((s) => s.key == status);
          if (currentIndex == -1) currentIndex = 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${LocalizationService.tr('label_order_id')} $orderId',
                        style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${total.toStringAsFixed(0)}',
                        style: GoogleFonts.notoSansTamil(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (created != null)
                        Text(
                          '${created.day}/${created.month}/${created.year} ${created.hour.toString().padLeft(2, '0')}:${created.minute.toString().padLeft(2, '0')}',
                          style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        payment == 'cash'
                            ? LocalizationService.tr('payment_cash')
                            : LocalizationService.tr('payment_credit'),
                        style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  LocalizationService.tr('title_status_timeline'),
                  style: GoogleFonts.notoSansTamil(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      for (var i = 0; i < steps.length; i++) ...[
                        _TimelineRow(
                          step: steps[i],
                          isActive: i <= currentIndex,
                          isLast: i == steps.length - 1,
                        ),
                        if (i != steps.length - 1) const SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),
                if (data['needsDosageAdvice'] == true) ...[
                   const SizedBox(height: 16),
                   _buildFarmerDosageSection(context, orderId, data),
                ],

                const SizedBox(height: 16),
                Text(
                  LocalizationService.tr('title_items'),
                  style: GoogleFonts.notoSansTamil(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final item in items) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${item['name_ta'] ?? ''} (${item['name_en'] ?? ''})',
                                style: GoogleFonts.notoSansTamil(fontSize: 13),
                              ),
                            ),
                            Text(
                              'x${item['quantity'] ?? 0}',
                              style: GoogleFonts.poppins(fontSize: 13),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '₹${((item['price'] ?? 0) * (item['quantity'] ?? 0)).toStringAsFixed(0)}',
                              style: GoogleFonts.notoSansTamil(fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                      ],
                    ],
                  ),
                ),

                if (data['adviceNote'] != null && data['adviceNote'].toString().trim().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.tips_and_updates, color: Colors.amber, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              LocalizationService.isTamil ? 'இலவச ஆலோசனை' : 'Free Advice Note',
                              style: GoogleFonts.notoSansTamil(fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          data['adviceNote'],
                          style: GoogleFonts.notoSansTamil(fontSize: 14, color: Colors.amber.shade900),
                        ),
                      ],
                    ),
                  ),
                ],

                if (status == 'picked') ...[
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FeedbackScreen(
                              orderId: orderId,
                              items: items,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.rate_review_outlined, color: Colors.white),
                      label: Text(
                        LocalizationService.isTamil ? 'கருத்துக்களைப் பகிரவும்' : 'Give Feedback',
                        style: GoogleFonts.notoSansTamil(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade700,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StepInfo {
  final String key;
  final String titleTa;
  final String titleEn;
  final String subtitleTa;
  final String subtitleEn;
  final DateTime? timestamp;

  const _StepInfo({
    required this.key,
    required this.titleTa,
    required this.titleEn,
    required this.subtitleTa,
    required this.subtitleEn,
    this.timestamp,
  });
}

class _TimelineRow extends StatelessWidget {
  final _StepInfo step;
  final bool isActive;
  final bool isLast;

  const _TimelineRow({
    required this.step,
    required this.isActive,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.primary : AppColors.border;
    
    // Avoid duplication if English string is same as Tamil (or generic fallback)
    final showTitleEn = step.titleEn.isNotEmpty && step.titleEn != step.titleTa;
    final showSubtitleEn = step.subtitleEn.isNotEmpty && step.subtitleEn != step.subtitleTa;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? color : Colors.white,
                border: Border.all(color: color, width: 2),
              ),
              child: isActive
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 50, // Increased height for better spacing with timestamps
                color: color,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                    Expanded(
                      child: Text(
                        step.titleTa,
                        style: GoogleFonts.notoSansTamil(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (step.timestamp != null)
                       Text(
                          _formatTime(step.timestamp!),
                          style: GoogleFonts.poppins(
                             fontSize: 12,
                             fontWeight: FontWeight.w600,
                             color: AppColors.primary
                          ),
                       ),
                 ],
              ),
              
              if (showTitleEn) ...[
                const SizedBox(height: 2),
                Text(
                  step.titleEn,
                  style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
              
              const SizedBox(height: 4),
              Text(
                step.subtitleTa,
                style: GoogleFonts.notoSansTamil(fontSize: 13, color: Colors.black87),
              ),
              
              if (showSubtitleEn) ...[
                const SizedBox(height: 2),
                Text(
                  step.subtitleEn,
                  style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
              if (step.timestamp != null) ...[
                 const SizedBox(height: 4),
                 Text(
                    _formatDate(step.timestamp!),
                    style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey),
                 ),
              ]
            ],
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime dt) {
     final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
     final m = dt.minute.toString().padLeft(2, '0');
     final ampm = dt.hour >= 12 ? 'PM' : 'AM';
     return "$h:$m $ampm";
  }
  
  String _formatDate(DateTime dt) {
     return "${dt.day}/${dt.month}/${dt.year}";
  }
}

Widget _buildFarmerDosageSection(BuildContext context, String orderId, Map<String, dynamic> data) {
  final status = data['dosageAdviceStatus'] as String? ?? 'requested';
  final advice = data['dosageAdvice'] as String? ?? '';
  final recommended = (data['recommendedProducts'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
  final createdTs = data['createdAt'] as Timestamp?;
  final isTa = LocalizationService.isTamil;
  
  bool canSendReminder = false;
  if (status == 'requested' && createdTs != null) {
    final diff = DateTime.now().difference(createdTs.toDate());
    if (diff.inHours >= 1) {
      canSendReminder = true;
    }
  }

  return Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.green.shade100),
    ),
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.medical_services, color: Colors.green),
            const SizedBox(width: 8),
            Text(
              isTa ? 'அளவு ஆலோசனை' : 'Dosage Advice',
              style: GoogleFonts.notoSansTamil(fontWeight: FontWeight.bold, color: Colors.green.shade800),
            ),
          ],
        ),
        const Divider(height: 24),
        if (status == 'requested') ...[
          Text(
            isTa ? 'ஆசிரியர் ஆலோசனையை வழங்க காத்திருக்கிறது...' : 'Waiting for owner to provide advice...',
            style: GoogleFonts.notoSansTamil(fontSize: 13, color: Colors.orange.shade800),
          ),
          if (canSendReminder) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _sendReminder(orderId),
                icon: const Icon(Icons.notifications_active, size: 18),
                label: Text(isTa ? 'நினைவூட்டலை அனுப்பு' : 'Send Reminder'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              ),
            ),
          ],
        ] else ...[
          Text(isTa ? 'ஆசிரியரின் ஆலோசனை:' : 'Owner\'s Advice:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          Text(advice, style: GoogleFonts.notoSansTamil(fontSize: 14)),
          if (recommended.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(isTa ? 'பரிந்துரைக்கப்பட்ட பொருட்கள்:' : 'Recommended Products:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 8),
            for (final p in recommended)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(isTa ? (p['name_ta'] ?? p['name_en']) : (p['name_en'] ?? p['name_ta'])),
                  subtitle: Text('₹${p['price']}'),
                  trailing: TextButton(
                    onPressed: () => _addItemToOrder(orderId, p),
                    child: Text(isTa ? 'சேர்' : 'Add'),
                  ),
                ),
              ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _finaliseOrder(orderId),
              child: Text(isTa ? 'தொடரவும்' : 'Continue with Selection'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: Row(
              children: [
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('feedbacks')
                        .where('isAdviceFeedback', isEqualTo: true)
                        .where('diseaseName', isEqualTo: data['diseaseDetails'])
                        .snapshots(),
                    builder: (context, snapshot) {
                      final count = snapshot.data?.docs.length ?? 0;
                      final worked = snapshot.data?.docs.where((d) => (d.data() as Map)['adviceEffectiveness'] == 'worked').length ?? 0;
                      final percent = count > 0 ? (worked / count * 100).toInt() : 0;
                      
                      return OutlinedButton.icon(
                        onPressed: count > 0 ? () => _showExpertReviews(context, data['diseaseDetails'], isTa) : null,
                        icon: const Icon(Icons.analytics_outlined, size: 18),
                        label: Text(count > 0 ? '$percent% ${isTa ? 'வெற்றி' : 'Success'} ($count)' : (isTa ? 'மதிப்பீடுகள் இல்லை' : 'No Reviews')),
                      );
                    }
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => FeedbackScreen(
                        orderId: orderId,
                        items: recommended,
                        isAdviceFeedback: true,
                        diseaseName: data['diseaseDetails'],
                      )));
                    },
                    icon: const Icon(Icons.rate_review, size: 18),
                    label: Text(isTa ? 'மதிப்பிடு' : 'Rate Help'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  );
}

void _showExpertReviews(BuildContext context, String diseaseName, bool isTa) {
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
            isTa ? 'மற்ற விவசாயிகளின் முடிவுகள்' : 'Other Farmers\' Results',
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
                             fb['createdAt'] != null ? "${(fb['createdAt'] as Timestamp).toDate().day}/${(fb['createdAt'] as Timestamp).toDate().month}" : '',
                             style: const TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ),
                        if (ownerReply != null)
                          Container(
                            margin: const EdgeInsets.only(left: 56, right: 16, bottom: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(isTa ? 'ஆசிரியர் பதில்:' : 'Owner Reply:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.blue)),
                                Text(ownerReply, style: const TextStyle(fontSize: 11)),
                              ],
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

Future<void> _sendReminder(String orderId) async {
  try {
    await NotificationRepository().notifyOwner(
      titleTa: 'அளவு ஆலோசனை நினைவூட்டல்',
      titleEn: 'Dosage Advice Reminder',
      bodyTa: 'ஆர்டர் #$orderId-க்கு விவசாயி இன்னும் ஆலோசனைக்காகக் காத்திருக்கிறார்.',
      bodyEn: 'Farmer is still waiting for dosage advice for Order #$orderId.',
      data: {'orderId': orderId, 'type': 'dosageReminder'},
    );
  } catch (e) {
    print('Reminder error: $e');
  }
}

Future<void> _addItemToOrder(String orderId, Map<String, dynamic> product) async {
  final orderRef = FirebaseFirestore.instance.collection('orders').doc(orderId);
  await FirebaseFirestore.instance.runTransaction((transaction) async {
    final doc = await transaction.get(orderRef);
    final items = List<Map<String, dynamic>>.from(doc.data()?['items'] ?? []);
    final total = (doc.data()?['totalAmount'] as num? ?? 0).toDouble();
    
    items.add({
      'productId': product['id'],
      'name_ta': product['name_ta'],
      'name_en': product['name_en'],
      'price': product['price'],
      'quantity': 1,
      'unit_ta': product['unit_ta'],
      'unit_en': product['unit_en'],
    });

    final newTotal = total + (product['price'] as num? ?? 0);
    
    // Remove from recommended
    final recommended = List<Map<String, dynamic>>.from(doc.data()?['recommendedProducts'] ?? []);
    recommended.removeWhere((p) => p['id'] == product['id']);

    transaction.update(orderRef, {
      'items': items,
      'totalAmount': newTotal,
      'recommendedProducts': recommended,
    });
  });
}

Future<void> _finaliseOrder(String orderId) async {
  await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
    'dosageAdviceStatus': 'finalised',
  });
}
