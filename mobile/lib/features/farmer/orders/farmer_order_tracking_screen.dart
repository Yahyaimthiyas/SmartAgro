import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/colors.dart';
import '../../../core/services/localization_service.dart';

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
                          color: AppColors.primaryDark,
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
