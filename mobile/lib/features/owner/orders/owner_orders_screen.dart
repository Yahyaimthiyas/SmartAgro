import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/colors.dart';
import '../../../core/services/localization_service.dart';
import 'owner_order_details_screen.dart';
import '../../notifications/repositories/notification_repository.dart';
import '../../notifications/models/app_notification.dart';

class OwnerOrdersScreen extends StatefulWidget {
  const OwnerOrdersScreen({super.key});

  @override
  State<OwnerOrdersScreen> createState() => _OwnerOrdersScreenState();
}

class _OwnerOrdersScreenState extends State<OwnerOrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _statusFilter = 'all'; 
  String _searchQuery = '';
  String _paymentFilter = 'all'; 
  bool _adviceOnly = false;
  bool _showFilters = false;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkCreditExpiries();
  }

  Future<void> _checkCreditExpiries() async {
    final now = DateTime.now();
    final snap = await FirebaseFirestore.instance
        .collection('orders')
        .where('paymentMethod', isEqualTo: 'credit')
        .where('status', isEqualTo: 'picked')
        .get();

    for (final doc in snap.docs) {
      final data = doc.data();
      final expiry = (data['creditExpiryDate'] as Timestamp?)?.toDate();
      if (expiry != null) {
        final daysLeft = expiry.difference(now).inDays;
        if (daysLeft <= 3 && daysLeft >= 0) {
           // Notify once per session or use a flag in doc to avoid spam
           NotificationRepository().notifyOwner(
             titleTa: 'கடன் காலக்கெடு முடிகிறது',
             titleEn: 'Credit Expiring Soon',
             bodyTa: 'ஆர்டர் #${doc.id.substring(0,8)} காலாவதியாக இன்னும் $daysLeft நாட்கள் உள்ளன.',
             bodyEn: 'Order #${doc.id.substring(0,8)} expires in $daysLeft days.',
           );
        } else if (daysLeft < 0) {
           NotificationRepository().notifyOwner(
             titleTa: 'கடன் காலாவதியானது!',
             titleEn: 'Credit Expired!',
             bodyTa: 'ஆர்டர் #${doc.id.substring(0,8)} காலக்கெடு முடிந்தது.',
             bodyEn: 'Order #${doc.id.substring(0,8)} has expired.',
           );
        }
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: Text(
          LocalizationService.isTamil ? 'அனைத்து ஆர்டர்கள்' : 'SmartAgro',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.primary),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                indicatorWeight: 3,
                labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold),
                unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500),
                tabs: [
                  Tab(text: LocalizationService.isTamil ? 'நடப்பு' : 'Active'),
                  Tab(text: LocalizationService.isTamil ? 'வரலாறு' : 'History'),
                ],
              ),
              _buildFilterBar(),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrderList(active: true),
          _buildOrderList(active: false),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(child: _buildSearchBar()),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => _showFilterBottomSheet(),
            icon: Icon(Icons.tune, color: _hasActiveFilters() ? AppColors.primary : Colors.grey),
          ),
        ],
      ),
    );
  }

  bool _hasActiveFilters() {
    return _paymentFilter != 'all' || _adviceOnly || _statusFilter != 'all';
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                LocalizationService.isTamil ? 'வடிகட்டிகள்' : 'Filters',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 16),
              _buildFilterSection(
                LocalizationService.isTamil ? 'பணம் செலுத்துதல்' : 'Payment',
                ['all', 'cash', 'credit'],
                _paymentFilter,
                (v) => setState(() { _paymentFilter = v; setS(() {}); }),
              ),
              SwitchListTile(
                title: Text(LocalizationService.isTamil ? 'ஆலோசனை மட்டும்' : 'Advice Only'),
                value: _adviceOnly,
                onChanged: (v) => setState(() { _adviceOnly = v; setS(() {}); }),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  child: Text(LocalizationService.isTamil ? 'விண்ணப்பிக்கவும்' : 'Apply'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSection(String title, List<String> options, String current, Function(String) onSel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: options.map((o) => ChoiceChip(
            label: Text(o.toUpperCase()),
            selected: current == o,
            onSelected: (s) { if (s) onSel(o); },
          )).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildOrderList({required bool active}) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data();
          final status = data['status'] as String? ?? 'reserved';
          final payment = data['paymentMethod'] as String? ?? 'cash';
          final isOnline = data['isOnline'] ?? true;
          final needsAdvice = data['needsDosageAdvice'] == true;

          // Tab split
          bool isActive = (status == 'reserved' || status == 'ready');
          if (active != isActive) return false;

          // Filters
          if (_paymentFilter != 'all' && payment != _paymentFilter) return false;
          if (_adviceOnly && !needsAdvice) return false;
          if (_searchQuery.isNotEmpty && !doc.id.toLowerCase().contains(_searchQuery.toLowerCase())) return false;

          return true;
        }).toList();

        if (docs.isEmpty) return _buildEmptyState();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (ctx, i) => _buildOrderCard(docs[i]),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(child: Text(LocalizationService.tr('owner_orders_empty')));
  }

  Widget _buildOrderCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final status = data['status'] as String;
    final total = (data['totalAmount'] as num).toDouble();
    final payment = data['paymentMethod'] as String;
    final isOnline = data['isOnline'] ?? true;
    final expiry = (data['creditExpiryDate'] as Timestamp?)?.toDate();
    final ts = (data['createdAt'] as Timestamp?)?.toDate();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OwnerOrderDetailsScreen(orderId: doc.id))),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '#${doc.id.substring(0, 8).toUpperCase()}',
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      _FarmerNameDisplay(userId: data['userId'], customerName: data['customerName']),
                      if (ts != null)
                        Text(
                          DateFormat('MMM d, h:mm a').format(ts),
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                        ),
                    ],
                  ),
                  _StatusChip(status: status),
                ],
              ),
              const Divider(height: 24, thickness: 0.8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '₹${total.toStringAsFixed(2)}',
                        style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                      Text(
                        payment.toUpperCase(),
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  if (payment == 'credit' && expiry != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            LocalizationService.isTamil ? 'காலாவதி' : 'Expires',
                            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.error),
                          ),
                          Text(
                            '${expiry.day}/${expiry.month}/${expiry.year}',
                            style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.error),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              // Removed mark as ready from outside as requested
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surfaceTonal,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) {
          setState(() {
            _searchQuery = val;
          });
        },
        decoration: InputDecoration(
          hintText: LocalizationService.tr('owner_orders_search_hint'),
          hintStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
          prefixIcon: const Icon(Icons.search_rounded, size: 22, color: AppColors.textSecondary),
          suffixIcon: _searchQuery.isNotEmpty 
            ? IconButton(
                icon: const Icon(Icons.clear_rounded, size: 20), 
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                }
              ) 
            : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final meta = _statusMeta(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: meta.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        LocalizationService.tr(meta.chipTextKey),
        style: GoogleFonts.inter(color: meta.color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
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
        color: const Color(0xFF0EA5E9),
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

    return ElevatedButton.icon(
      onPressed: () async {
        await _updateOrderStatus(context, orderId, nextStatus!);
      },
      style: ElevatedButton.styleFrom(
         backgroundColor: buttonColor,
         foregroundColor: Colors.white,
         padding: const EdgeInsets.symmetric(vertical: 12),
         elevation: 0,
         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: Icon(icon, size: 20),
      label: Text(
        LocalizationService.tr(labelKey),
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

Future<void> _updateOrderStatus(BuildContext context, String orderId, String newStatus) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final orderRef = FirebaseFirestore.instance.collection('orders').doc(orderId);
    final Map<String, dynamic> updates = {'status': newStatus};
    if (newStatus == 'ready') {
      updates['readyAt'] = FieldValue.serverTimestamp();
    } else if (newStatus == 'picked') {
      updates['pickedAt'] = FieldValue.serverTimestamp();
    }
    await orderRef.update(updates);

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

    messenger.showSnackBar(
      SnackBar(
        content: Text(LocalizationService.tr('owner_orders_status_updated')),
      ),
    );
  } catch (e) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(LocalizationService.tr('owner_orders_status_update_failed')),
      ),
    );
  }
}

class _FarmerNameDisplay extends StatelessWidget {
  final String? userId;
  final String? customerName;

  const _FarmerNameDisplay({this.userId, this.customerName});

  @override
  Widget build(BuildContext context) {
    if (customerName != null && customerName!.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Text(
          customerName!,
          style: GoogleFonts.notoSansTamil(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      );
    }

    if (userId == null) return const SizedBox.shrink();

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data?.data() == null) return const SizedBox.shrink();
        final name = snapshot.data!.data()!['name'] as String?;
        if (name == null || name.isEmpty) return const SizedBox.shrink();
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Text(
            name,
            style: GoogleFonts.notoSansTamil(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        );
      },
    );
  }
}
