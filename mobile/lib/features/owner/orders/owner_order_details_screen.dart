import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/colors.dart';
import '../../../core/services/localization_service.dart';

class OwnerOrderDetailsScreen extends StatelessWidget {
  final String orderId;

  const OwnerOrderDetailsScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('orders').doc(orderId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: AppColors.surface,
            appBar: _buildAppBar(),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            backgroundColor: AppColors.surface,
            appBar: _buildAppBar(),
            body: Center(
              child: Text(
                LocalizationService.tr('msg_order_not_found'),
                style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary),
              ),
            ),
          );
        }

        final data = snapshot.data!.data()!;
        final status = data['status'] as String? ?? 'reserved';
        final total = data['totalAmount'] as num? ?? 0;
        final payment = data['paymentMethod'] as String? ?? 'cash';
        final ts = data['createdAt'] as Timestamp?;
        final created = ts?.toDate();
        final items = (data['items'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
        final userId = data['userId'] as String?;

        final steps = [
          const _StepInfo(
            key: 'reserved',
            titleTa: 'ஆர்டர் பதிவு',
            titleEn: 'Order placed',
            subtitleTa: 'உங்கள் ஆர்டர் கடைக்கு அனுப்பப்பட்டது',
            subtitleEn: 'Your order has been sent to the shop',
          ),
          const _StepInfo(
            key: 'ready',
            titleTa: 'கடை தயார்',
            titleEn: 'Ready at shop',
            subtitleTa: 'பொருட்கள் எடுக்க தயார் நிலையில் உள்ளது',
            subtitleEn: 'Items are ready for pickup',
          ),
          const _StepInfo(
            key: 'picked',
            titleTa: 'பெறப்பட்டது',
            titleEn: 'Picked up',
            subtitleTa: 'நன்றி! ஆர்டர் பெற்றுவிட்டீர்கள்',
            subtitleEn: 'Thank you! Order has been picked up',
          ),
        ];

        int currentIndex = steps.indexWhere((s) => s.key == status);
        if (currentIndex == -1) currentIndex = 0;

        return Scaffold(
          backgroundColor: AppColors.surface,
          appBar: _buildAppBar(),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FarmerInfoSection(userId: userId),
                const SizedBox(height: 12),
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
                              child: Builder(
                                builder: (context) {
                                  final nameTa = item['name_ta'] as String? ?? '';
                                  final nameEn = item['name_en'] as String? ?? '';
                                  final name = LocalizationService.pickTaEn(nameTa, nameEn);
                                  final isTa = LocalizationService.isTamil;

                                  return Text(
                                    name,
                                    style: isTa
                                        ? GoogleFonts.notoSansTamil(fontSize: 13)
                                        : GoogleFonts.poppins(fontSize: 13),
                                  );
                                },
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
          ),
          bottomNavigationBar: _OwnerOrderActions(orderId: orderId, status: status),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Text(
        LocalizationService.tr('owner_order_details_appbar'),
        style: GoogleFonts.notoSansTamil(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
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

  const _StepInfo({
    required this.key,
    required this.titleTa,
    required this.titleEn,
    required this.subtitleTa,
    required this.subtitleEn,
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
    final isTa = LocalizationService.isTamil;
    final title = isTa ? step.titleTa : step.titleEn;
    final subtitle = isTa ? step.subtitleTa : step.subtitleEn;

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
                height: 32,
                color: color,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: isTa
                    ? GoogleFonts.notoSansTamil(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      )
                    : GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: isTa
                    ? GoogleFonts.notoSansTamil(fontSize: 12)
                    : GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FarmerInfoSection extends StatelessWidget {
  final String? userId;

  const _FarmerInfoSection({required this.userId});

  @override
  Widget build(BuildContext context) {
    final id = userId;
    if (id == null) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('users').doc(id).get(),
      builder: (context, snapshot) {
        String? name;
        String? phone;

        if (snapshot.hasData && snapshot.data!.data() != null) {
          final data = snapshot.data!.data()!;
          name = data['name'] as String?;
          phone = data['phone'] as String?;
        }

        final display = name ?? phone ?? '';
        if (display.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.person_outline, size: 24, color: AppColors.primaryDark),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LocalizationService.tr('owner_orders_farmer_label'),
                      style: GoogleFonts.notoSansTamil(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      display,
                      style: GoogleFonts.notoSansTamil(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OwnerOrderActions extends StatelessWidget {
  final String orderId;
  final String status;

  const _OwnerOrderActions({
    required this.orderId,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    String? primaryStatus;
    String? primaryLabelKey;
    bool showCancel = false;

    if (status == 'reserved') {
      primaryStatus = 'ready';
      primaryLabelKey = 'owner_orders_mark_ready';
      showCancel = true;
    } else if (status == 'ready') {
      primaryStatus = 'picked';
      primaryLabelKey = 'owner_orders_mark_picked';
      showCancel = true;
    }

    if (primaryStatus == null && !showCancel) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            if (showCancel) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    await _updateOrderStatus(context, orderId, 'cancelled');
                  },
                  child: Text(
                    LocalizationService.tr('owner_orders_cancel'),
                    style: GoogleFonts.notoSansTamil(fontSize: 13),
                  ),
                ),
              ),
            ],
            if (showCancel && primaryStatus != null) const SizedBox(width: 12),
            if (primaryStatus != null) ...[
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    await _updateOrderStatus(context, orderId, primaryStatus!);
                  },
                  child: Text(
                    LocalizationService.tr(primaryLabelKey!),
                    style: GoogleFonts.notoSansTamil(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

Future<void> _updateOrderStatus(BuildContext context, String orderId, String newStatus) async {
  try {
    final orderRef = FirebaseFirestore.instance.collection('orders').doc(orderId);

    // [STOCK MANAGEMENT]
    await FirebaseFirestore.instance.runTransaction((transaction) async {
       final orderDoc = await transaction.get(orderRef);
       if (!orderDoc.exists) throw Exception("Order not found");
       
       // Update Order Status
       transaction.update(orderRef, {
          'status': newStatus,
          if (newStatus == 'ready') 'readyAt': FieldValue.serverTimestamp(),
          if (newStatus == 'picked') 'pickedAt': FieldValue.serverTimestamp(),
       });

       // Logic: If status becomes 'cancelled', restore stock
       // Note: Verify previous status if needed to avoid double-restoration (e.g. if already cancelled), 
       // but UI shouldn't allow cancelling a cancelled order.
       if (newStatus == 'cancelled') {
          final items = (orderDoc.data()?['items'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
          
          for (final item in items) {
             final productId = item['productId'] as String?;
             final quantity = item['quantity'] as int? ?? 0;
             
             if (productId != null && quantity > 0) {
                final productRef = FirebaseFirestore.instance.collection('products').doc(productId);
                transaction.update(productRef, {
                   'stock': FieldValue.increment(quantity)
                });
             }
          }
       }
    });

    if (context.mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
           content: Text(LocalizationService.tr('owner_orders_status_updated')),
         ),
       );
       Navigator.pop(context); // Close details screen to refresh or go back
    }
  } catch (e) {
    if (context.mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
           content: Text('${LocalizationService.tr('owner_orders_status_update_failed')}: $e'),
           backgroundColor: Colors.red,
         ),
       );
    }
  }
}

