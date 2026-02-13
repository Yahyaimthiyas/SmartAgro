import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/colors.dart';
import '../../../core/services/localization_service.dart';
import 'owner_order_details_screen.dart';

class OwnerOrdersScreen extends StatefulWidget {
  const OwnerOrdersScreen({super.key});

  @override
  State<OwnerOrdersScreen> createState() => _OwnerOrdersScreenState();
}

class _OwnerOrdersScreenState extends State<OwnerOrdersScreen> {
  String _filter = 'all'; // all, reserved, ready, picked, cancelled

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          LocalizationService.tr('owner_title_orders'),
          style: GoogleFonts.notoSansTamil(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
             color: Colors.white,
             padding: const EdgeInsets.symmetric(vertical: 12),
             child: _buildFilters(),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .orderBy('createdAt', descending: true)
                  .limit(50)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];
                final filtered = docs.where((doc) {
                  final data = doc.data();
                  final status = data['status'] as String? ?? 'reserved';
                  if (_filter == 'all') return true;
                  return status == _filter;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                       mainAxisAlignment: MainAxisAlignment.center,
                       children: [
                          Container(
                             padding: const EdgeInsets.all(24),
                             decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.05),
                                shape: BoxShape.circle
                             ),
                             child: const Icon(Icons.receipt_long_outlined, size: 48, color: Colors.blueGrey),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            LocalizationService.tr('owner_orders_empty'),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.notoSansTamil(
                              fontSize: 16,
                              color: AppColors.textSecondary,
                            ),
                          ),
                       ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final doc = filtered[index];
                    final data = doc.data();
                    final id = doc.id;
                    final status = data['status'] as String? ?? 'reserved';
                    final total = data['totalAmount'] as num? ?? 0;
                    final payment = data['paymentMethod'] as String? ?? 'cash';
                    final ts = data['createdAt'] as Timestamp?;
                    final created = ts?.toDate();
                    final userId = data['userId'] as String?;

                    final statusMeta = _statusMeta(status);

                    return InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => OwnerOrderDetailsScreen(orderId: id),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                             BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4)
                             )
                          ]
                        ),
                        child: Column(
                          children: [
                             // Header
                             Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                   children: [
                                      Container(
                                         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                         decoration: BoxDecoration(
                                            color: AppColors.primary.withOpacity(0.08),
                                            borderRadius: BorderRadius.circular(8)
                                         ),
                                         child: Text(
                                            '#${id.substring(0, 8).toUpperCase()}',
                                            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                                         ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: statusMeta.color.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                           children: [
                                              Icon(Icons.circle, size: 8, color: statusMeta.color),
                                              const SizedBox(width: 6),
                                              Text(
                                                LocalizationService.tr(statusMeta.chipTextKey),
                                                style: GoogleFonts.poppins(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: statusMeta.color,
                                                ),
                                              ),
                                           ],
                                        ),
                                      ),
                                   ],
                                ),
                             ),
                             const Divider(height: 1),
                             // Body
                             Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                   crossAxisAlignment: CrossAxisAlignment.start,
                                   children: [
                                      _FarmerInfoText(userId: userId),
                                      const SizedBox(height: 12),
                                      Row(
                                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                         children: [
                                            Column(
                                               crossAxisAlignment: CrossAxisAlignment.start,
                                               children: [
                                                  Text(
                                                     LocalizationService.tr('owner_dashboard_orders_revenue'),
                                                     style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary),
                                                  ),
                                                  Text(
                                                     '₹${total.toStringAsFixed(0)}',
                                                     style: GoogleFonts.notoSansTamil(
                                                        fontSize: 18,
                                                        fontWeight: FontWeight.bold,
                                                        color: AppColors.textPrimary
                                                     ),
                                                  )
                                               ],
                                            ),
                                            Column(
                                               crossAxisAlignment: CrossAxisAlignment.end,
                                               children: [
                                                  Text(
                                                     LocalizationService.tr('label_payment'),
                                                     style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary),
                                                  ),
                                                  Text(
                                                     payment == 'cash'
                                                         ? LocalizationService.tr('payment_cash')
                                                         : LocalizationService.tr('payment_credit'),
                                                     style: GoogleFonts.notoSansTamil(
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.w600,
                                                        color: AppColors.textPrimary
                                                     ),
                                                  )
                                               ],
                                            )
                                         ],
                                      ),
                                      if (created != null) ...[
                                         const SizedBox(height: 12),
                                         Row(
                                            children: [
                                               Icon(Icons.access_time, size: 14, color: AppColors.textSecondary),
                                               const SizedBox(width: 4),
                                               Text(
                                                 '${created.day}/${created.month}/${created.year} · ${created.hour.toString().padLeft(2, '0')}:${created.minute.toString().padLeft(2, '0')}',
                                                 style: GoogleFonts.poppins(
                                                   fontSize: 12,
                                                   color: AppColors.textSecondary,
                                                 ),
                                               ),
                                            ],
                                         )
                                      ]
                                   ],
                                ),
                             ),
                             // Footer Actions
                             if (status == 'reserved' || status == 'ready') ...[
                                const Divider(height: 1),
                                Padding(
                                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                   child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                         _OrderActionButton(
                                           orderId: id,
                                           status: status,
                                         ),
                                      ],
                                   ),
                                )
                             ]
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildFilterChip('all', LocalizationService.tr('owner_orders_filter_all')),
          const SizedBox(width: 8),
          _buildFilterChip('reserved', LocalizationService.tr('owner_orders_filter_reserved')),
          const SizedBox(width: 8),
          _buildFilterChip('ready', LocalizationService.tr('owner_orders_filter_ready')),
          const SizedBox(width: 8),
          _buildFilterChip('picked', LocalizationService.tr('owner_orders_filter_picked')),
          const SizedBox(width: 8),
          _buildFilterChip('cancelled', LocalizationService.tr('owner_orders_filter_cancelled')),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final selected = _filter == value;
    return ChoiceChip(
      label: Text(
        label,
        style: GoogleFonts.notoSansTamil(
          fontSize: 13,
          fontWeight: selected ? FontWeight.bold : FontWeight.w500,
          color: selected ? Colors.white : AppColors.textSecondary,
        ),
      ),
      selected: selected,
      selectedColor: AppColors.primary,
      backgroundColor: Colors.white,
      side: selected ? BorderSide.none : BorderSide(color: Colors.grey.shade300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      onSelected: (_) {
        setState(() {
          _filter = value;
        });
      },
    );
  }
}

class _StatusMeta {
  final String labelKey;
  final String chipTextKey;
  final Color color;

  const _StatusMeta({
    required this.labelKey,
    required this.chipTextKey,
    required this.color,
  });
}

_StatusMeta _statusMeta(String status) {
  switch (status) {
    case 'ready':
      return const _StatusMeta(
        labelKey: 'status_ready_label',
        chipTextKey: 'status_ready',
        color: Colors.orange,
      );
    case 'picked':
      return const _StatusMeta(
        labelKey: 'status_picked_label',
        chipTextKey: 'status_picked',
        color: Colors.green,
      );
    case 'cancelled':
      return const _StatusMeta(
        labelKey: 'status_cancelled_label',
        chipTextKey: 'status_cancelled',
        color: Colors.red,
      );
    case 'reserved':
    default:
      return const _StatusMeta(
        labelKey: 'status_placed_label',
        chipTextKey: 'status_placed',
        color: Colors.blue,
      );
  }
}

class _StatusLabels extends StatelessWidget {
  final _StatusMeta meta;

  const _StatusLabels({required this.meta});

  @override
  Widget build(BuildContext context) {
    final isTa = LocalizationService.isTamil;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          LocalizationService.tr(meta.labelKey),
          style: GoogleFonts.notoSansTamil(
             fontSize: 12,
             fontWeight: FontWeight.bold,
             color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _FarmerInfoText extends StatelessWidget {
  final String? userId;

  const _FarmerInfoText({required this.userId});

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

        return Row(
          children: [
             Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                   color: Colors.grey.shade100,
                   shape: BoxShape.circle
                ),
                child: const Icon(Icons.person, size: 16, color: AppColors.textSecondary),
             ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                     LocalizationService.tr('owner_orders_farmer_label'),
                     style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textSecondary),
                   ),
                   Text(
                    display,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.notoSansTamil(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _OrderActionButton extends StatelessWidget {
  final String orderId;
  final String status;

  const _OrderActionButton({
    required this.orderId,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    String? nextStatus;
    String? labelKey;
    Color buttonColor;
    IconData icon;

    if (status == 'reserved') {
      nextStatus = 'ready';
      labelKey = 'owner_orders_mark_ready';
      buttonColor = Colors.orange;
      icon = Icons.inventory;
    } else if (status == 'ready') {
      nextStatus = 'picked';
      labelKey = 'owner_orders_mark_picked';
      buttonColor = AppColors.primary;
      icon = Icons.check_circle;
    } else {
       return const SizedBox.shrink();
    }

    return TextButton.icon(
      onPressed: () async {
        await _updateOrderStatus(context, orderId, nextStatus!);
      },
      style: TextButton.styleFrom(
         foregroundColor: buttonColor,
         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)
      ),
      icon: Icon(icon, size: 18),
      label: Text(
        LocalizationService.tr(labelKey),
        style: GoogleFonts.notoSansTamil(
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

Future<void> _updateOrderStatus(BuildContext context, String orderId, String newStatus) async {
  try {
    final Map<String, dynamic> updates = {'status': newStatus};
    if (newStatus == 'ready') {
      updates['readyAt'] = FieldValue.serverTimestamp();
    } else if (newStatus == 'picked') {
      updates['pickedAt'] = FieldValue.serverTimestamp();
    }
    await FirebaseFirestore.instance.collection('orders').doc(orderId).update(updates);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(LocalizationService.tr('owner_orders_status_updated')),
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(LocalizationService.tr('owner_orders_status_update_failed')),
      ),
    );
  }
}

