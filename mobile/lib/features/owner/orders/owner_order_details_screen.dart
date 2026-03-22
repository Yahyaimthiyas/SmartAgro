 import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/colors.dart';
import '../../../core/services/localization_service.dart';
import '../../notifications/repositories/notification_repository.dart';
import '../../notifications/models/app_notification.dart';

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
                if (data['needsDosageAdvice'] == true) ...[
                  const SizedBox(height: 16),
                  _buildDosageAdviceSection(context, orderId, data),
                ],
                if (status == 'picked') ...[
                  const SizedBox(height: 16),
                  _OrderFeedbackSection(orderId: orderId),
                ],
              ],
            ),
          ),
          bottomNavigationBar: _OwnerOrderActions(orderId: orderId, status: status, orderData: data),
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
  final Map<String, dynamic> orderData;

  const _OwnerOrderActions({
    required this.orderId,
    required this.status,
    required this.orderData,
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

    if (status == 'reserved' && orderData['needsDosageAdvice'] == true && orderData['dosageAdviceStatus'] == 'requested') {
      // Owner must provide advice first
      return SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Text(
            LocalizationService.isTamil ? 'இந்த ஆர்டருக்கு நீங்கள் முதலில் அளவு ஆலோசனை வழங்க வேண்டும்.' : 'You must provide dosage advice for this order first.',
            style: GoogleFonts.notoSansTamil(fontSize: 14, color: Colors.orange.shade800, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (status == 'reserved' && orderData['dosageAdviceStatus'] == 'provided') {
       return SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Text(
            LocalizationService.isTamil ? 'விவசாயியின் பதிலுக்காகக் காத்திருக்கிறது...' : 'Waiting for farmer\'s response...',
            style: GoogleFonts.notoSansTamil(fontSize: 14, color: Colors.blue.shade800, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
      );
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
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
                        DateTime? expiryDate;
                        if (primaryStatus == 'picked' && orderData['paymentMethod'] == 'credit') {
                           expiryDate = await showDatePicker(
                             context: context,
                             initialDate: DateTime.now().add(const Duration(days: 30)),
                             firstDate: DateTime.now(),
                             lastDate: DateTime.now().add(const Duration(days: 365)),
                             helpText: LocalizationService.isTamil ? 'கடன் காலாவதி தேதியைத் தேர்ந்தெடுக்கவும்' : 'Select Credit Expiry Date',
                           );
                           if (expiryDate == null) return; // User cancelled date selection
                        }
                        await _updateOrderStatus(context, orderId, primaryStatus!, creditExpiry: expiryDate);
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
          ],
        ),
      ),
    );
  }
}

Future<void> _updateOrderStatus(BuildContext context, String orderId, String newStatus, {DateTime? creditExpiry}) async {
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
          if (newStatus == 'cancelled') 'cancelledAt': FieldValue.serverTimestamp(),
          if (creditExpiry != null) 'creditExpiryDate': Timestamp.fromDate(creditExpiry),
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

    // --- Notify Farmer & Owner ---
    try {
      final orderDoc = await orderRef.get();
      final userId = orderDoc.data()?['userId'] as String?;
      
      if (userId != null) {
        String titleTa = '', titleEn = '', bodyTa = '', bodyEn = '';
        
        if (newStatus == 'ready') {
          titleTa = 'ஆர்டர் தயார்';
          titleEn = 'Order Ready';
          bodyTa = 'உங்கள் ஆர்டர் (#$orderId) கடையில் தயாராக உள்ளது. தயவுசெய்து வந்து பெற்றுக்கொள்ளவும்.';
          bodyEn = 'Your order (#$orderId) is ready at the shop. Please pick it up.';
        } else if (newStatus == 'picked') {
          titleTa = 'ஆர்டர் பெறப்பட்டது';
          titleEn = 'Order Delivered';
          bodyTa = 'உங்கள் ஆர்டர் (#$orderId) வெற்றிகரமாக வழங்கப்பட்டது. நன்றி!';
          bodyEn = 'Your order (#$orderId) was successfully delivered. Thank you!';
        } else if (newStatus == 'cancelled') {
          titleTa = 'ஆர்டர் ரத்து செய்யப்பட்டது';
          titleEn = 'Order Cancelled';
          bodyTa = 'உங்கள் ஆர்டர் (#$orderId) ரத்து செய்யப்பட்டது.';
          bodyEn = 'Your order (#$orderId) has been cancelled.';
        }

        if (titleTa.isNotEmpty) {
          await NotificationRepository().sendNotification(
            recipientUid: userId,
            titleTa: titleTa,
            titleEn: titleEn,
            bodyTa: bodyTa,
            bodyEn: bodyEn,
            type: NotificationType.orderUpdate,
            data: {'orderId': orderId, 'status': newStatus},
          );
        }
      }

      // Also notify owner (the request said "send notification to owner and farmer" if delivered)
      if (newStatus == 'picked') {
        await NotificationRepository().notifyOwner(
          titleTa: 'விற்பனை முடிந்தது',
          titleEn: 'Sale Completed',
          bodyTa: 'ஆர்டர் (#$orderId) வழங்கப்பட்டது.',
          bodyEn: 'Order (#$orderId) has been delivered.',
          data: {'orderId': orderId, 'status': 'picked'},
        );
      }
    } catch (e) {
      print('Notification error: $e');
    }
    // ----------------------------

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

Widget _buildDosageAdviceSection(BuildContext context, String orderId, Map<String, dynamic> data) {
  final disease = data['diseaseDetails'] as String? ?? '';
  final advice = data['dosageAdvice'] as String? ?? '';
  final status = data['dosageAdviceStatus'] as String? ?? 'requested';
  final isTa = LocalizationService.isTamil;
  
  return Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.blue.shade100),
    ),
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.medical_information, color: Colors.blue),
            const SizedBox(width: 8),
            Text(
              isTa ? 'அளவு ஆலோசனைத் தேவை' : 'Dosage Advice Request',
              style: GoogleFonts.notoSansTamil(fontWeight: FontWeight.bold, color: Colors.blue.shade800),
            ),
          ],
        ),
        const Divider(height: 24),
        Text(
          isTa ? 'நோய் விவரங்கள்:' : 'Disease Details:',
          style: GoogleFonts.notoSansTamil(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        Text(
          disease,
          style: GoogleFonts.notoSansTamil(fontSize: 14),
        ),
        if (data['diseaseImageUrl'] != null) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              data['diseaseImageUrl'],
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 200,
                  color: Colors.grey.shade100,
                  child: const Center(child: CircularProgressIndicator()),
                );
              },
            ),
          ),
        ],
        if (advice.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            isTa ? 'உங்கள் ஆலோசனை:' : 'Your Advice:',
            style: GoogleFonts.notoSansTamil(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green),
          ),
          Text(
            advice,
            style: GoogleFonts.notoSansTamil(fontSize: 14),
          ),
        ],
        const SizedBox(height: 16),
        if (status == 'requested')
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showAdviceDialog(context, orderId, data),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: Text(isTa ? 'ஆலோசனை வழங்கவும்' : 'Provide Advice'),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
            child: Text(
              isTa ? 'ஆலோசனை வழங்கப்பட்டது' : 'Advice Provided via App Notification',
              style: GoogleFonts.notoSansTamil(fontSize: 12, color: Colors.green.shade800),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    ),
  );
}

// [REMOVED DIRECT COMMS AS REQUESTED]


void _showAdviceDialog(BuildContext context, String orderId, Map<String, dynamic> data) {
  final adviceController = TextEditingController();
  final isTa = LocalizationService.isTamil;
  final List<Map<String, dynamic>> recommended = [];
  bool saveAsTemplate = false;

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setModalState) => AlertDialog(
        title: Text(isTa ? 'ஆலோசனை வழங்கவும்' : 'Provide Dosage Advice'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (data['cropName'] != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.agriculture, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text("${data['cropName']} (${data['diseaseLevel'] ?? ''})", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              TextField(
                controller: adviceController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: isTa ? 'உங்கள் ஆலோசனையை இங்கே உள்ளிடவும்...' : 'Enter your advice here...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: saveAsTemplate,
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(isTa ? 'பொதுவான ஆலோசனையாகச் சேமிக்கவும்' : 'Save as Common Template'),
                onChanged: (v) => setModalState(() => saveAsTemplate = v!),
              ),
              const Divider(),
              Text(
                isTa ? 'பரிந்துரைக்கப்படும் தயாரிப்புகள்' : 'Recommended Products',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              for (var i = 0; i < recommended.length; i++)
                ListTile(
                  dense: true,
                  title: Text(isTa ? recommended[i]['name_ta'] : recommended[i]['name_en']),
                  subtitle: TextField(
                    decoration: const InputDecoration(hintText: 'Dosage (e.g. 5ml/L)', isDense: true),
                    onChanged: (v) => recommended[i]['dosage'] = v,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                    onPressed: () => setModalState(() => recommended.removeAt(i)),
                  ),
                ),
              TextButton.icon(
                onPressed: () async {
                  final result = await _showProductPicker(context);
                  if (result != null) {
                    setModalState(() {
                      recommended.add({...result, 'dosage': ''});
                    });
                  }
                },
                icon: const Icon(Icons.add),
                label: Text(isTa ? 'தயாரிப்பைச் சேர்க்கவும்' : 'Add Product'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isTa ? 'ரத்து' : 'Cancel')),
          ElevatedButton(
            onPressed: () async {
              final adviceText = adviceController.text.trim();
              if (adviceText.isEmpty) return;
              
              await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
                'dosageAdvice': adviceText,
                'recommendedProducts': recommended,
                'dosageAdviceStatus': 'provided',
              });

              if (saveAsTemplate && data['cropName'] != null && data['diseaseDetails'] != null) {
                await FirebaseFirestore.instance.collection('common_diseases').add({
                  'cropName': data['cropName'],
                  'crop_lower': (data['cropName'] as String).toLowerCase(),
                  'diseaseName': data['diseaseDetails'],
                  'disease_lower': (data['diseaseDetails'] as String).toLowerCase(),
                  'level': data['diseaseLevel'],
                  'advice': adviceText,
                  'products': recommended,
                });
              }

              Navigator.pop(ctx);
            },
            child: Text(isTa ? 'அனுப்புக' : 'Send'),
          ),
        ],
      ),
    ),
  );
}

Future<Map<String, dynamic>?> _showProductPicker(BuildContext context) async {
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

class _OrderFeedbackSection extends StatelessWidget {
  final String orderId;

  const _OrderFeedbackSection({required this.orderId});

  @override
  Widget build(BuildContext context) {
    final isTa = LocalizationService.isTamil;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('feedbacks')
          .where('orderId', isEqualTo: orderId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final fbDoc = snapshot.data!.docs.first;
        final fb = fbDoc.data();
        final rating = fb['rating'] as int? ?? 5;
        final comment = fb['comment'] as String? ?? '';
        final imageUrl = fb['imageUrl'] as String?;
        final ownerReply = fb['ownerReply'] as String?;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.amber.shade100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Text(
                    isTa ? 'விவசாயியின் கருத்து' : 'Farmer\'s Feedback',
                    style: GoogleFonts.notoSansTamil(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.amber.shade900),
                  ),
                  Row(
                    children: List.generate(5, (index) => Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 16,
                    )),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (comment.isNotEmpty)
                Text(comment, style: GoogleFonts.notoSansTamil(fontSize: 14)),
              if (imageUrl != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(imageUrl, height: 180, width: double.infinity, fit: BoxFit.cover),
                ),
              ],
              if (ownerReply != null) ...[
                const Divider(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isTa ? 'உங்கள் பதில்:' : 'Your Reply:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.blue)),
                      const SizedBox(height: 4),
                      Text(ownerReply, style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
              ] else ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showOwnerReplyDialog(context, fbDoc.id, isTa),
                    icon: const Icon(Icons.reply, size: 18),
                    label: Text(isTa ? 'பதில் அளிக்கவும்' : 'Send Reply'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showOwnerReplyDialog(BuildContext context, String feedbackId, bool isTa) {
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
