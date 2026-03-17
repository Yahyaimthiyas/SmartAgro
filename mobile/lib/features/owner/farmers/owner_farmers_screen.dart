import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/colors.dart';
import '../../../core/services/localization_service.dart';
import 'owner_create_customer_screen.dart';
import 'owner_farmer_details_screen.dart';

class OwnerFarmersScreen extends StatelessWidget {
  const OwnerFarmersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        centerTitle: false,
        title: Text(
          LocalizationService.tr('owner_title_farmers'),
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const OwnerCreateCustomerScreen()),
        ),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: Text(
          LocalizationService.isTamil ? 'புதிய விவசாயி' : 'Add Customer',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'farmer')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                    Container(
                       padding: const EdgeInsets.all(24),
                       decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          shape: BoxShape.circle,
                       ),
                       child: const Icon(Icons.people_outline_rounded, size: 48, color: AppColors.primary),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      LocalizationService.tr('owner_farmers_empty'),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                 ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              final id = doc.id;
              final name = data['name'] as String?;
              final phone = data['phone'] as String? ?? '';

              final displayName = name?.isNotEmpty == true ? name! : phone;

              return Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => OwnerFarmerDetailsScreen(userId: id),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                             child: Text(
                                displayName.substring(0, 1).toUpperCase(),
                                style: GoogleFonts.outfit(
                                   fontSize: 22,
                                   fontWeight: FontWeight.bold,
                                   color: AppColors.primary
                                ),
                             )
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary
                                ),
                              ),
                              const SizedBox(height: 2),
                              if (phone.isNotEmpty)
                                Text(
                                  phone,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              const SizedBox(height: 8),
                              _FarmerBalancePreview(userId: id),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: AppColors.textPlaceholder),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _FarmerBalancePreview extends StatelessWidget {
  final String userId;

  const _FarmerBalancePreview({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('creditLedger')
          .where('userId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 2);
        }

        final docs = snapshot.data?.docs ?? [];
        double balance = 0;
        for (final doc in docs) {
          final data = doc.data();
          final amount = (data['amount'] as num? ?? 0).toDouble();
          final type = data['type'] as String? ?? 'credit';
          if (type == 'credit') {
            balance += amount;
          } else if (type == 'payment') {
            balance -= amount;
          }
        }

        String label;
        Color color;
        if (balance > 0) {
          label = LocalizationService.tr('owner_farmers_balance_positive');
          color = AppColors.error;
        } else if (balance < 0) {
          label = LocalizationService.tr('owner_farmers_balance_negative');
          color = AppColors.success;
        } else {
          label = LocalizationService.tr('owner_farmers_balance_zero');
          color = AppColors.textSecondary;
        }

        final absBalance = balance.abs().toStringAsFixed(0);

        return Container(
           padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
           decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20)
           ),
           child: Text(
             '$label: ₹$absBalance',
             style: GoogleFonts.inter(
               fontSize: 11,
               fontWeight: FontWeight.bold,
               color: color,
             ),
           ),
        );
      },
    );
  }
}

