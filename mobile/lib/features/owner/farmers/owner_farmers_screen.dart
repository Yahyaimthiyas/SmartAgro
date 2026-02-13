import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/colors.dart';
import '../../../core/services/localization_service.dart';
import 'owner_farmer_details_screen.dart';

class OwnerFarmersScreen extends StatelessWidget {
  const OwnerFarmersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          LocalizationService.tr('owner_title_farmers'),
          style: GoogleFonts.notoSansTamil(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
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
                          color: Colors.green.withOpacity(0.05),
                          shape: BoxShape.circle,
                       ),
                       child: const Icon(Icons.people_outline, size: 48, color: Colors.green),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      LocalizationService.tr('owner_farmers_empty'),
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
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              final id = doc.id;
              final name = data['name'] as String?;
              final phone = data['phone'] as String? ?? '';

              final displayName = name?.isNotEmpty == true ? name! : phone;

              return InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => OwnerFarmerDetailsScreen(userId: id),
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
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child:  Center(
                           child: Text(
                              displayName.substring(0, 1).toUpperCase(),
                              style: GoogleFonts.poppins(
                                 fontSize: 24,
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
                              style: GoogleFonts.notoSansTamil(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (phone.isNotEmpty)
                              Row(
                                 children: [
                                    const Icon(Icons.phone_outlined, size: 14, color: AppColors.textSecondary),
                                    const SizedBox(width: 4),
                                    Text(
                                      phone,
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                 ],
                              ),
                            const SizedBox(height: 8),
                            _FarmerBalancePreview(userId: id),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                    ],
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
          return const SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
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
          color = Colors.red;
        } else if (balance < 0) {
          label = LocalizationService.tr('owner_farmers_balance_negative');
          color = Colors.green;
        } else {
          label = LocalizationService.tr('owner_farmers_balance_zero');
          color = AppColors.textSecondary;
        }

        final absBalance = balance.abs().toStringAsFixed(0);

        return Container(
           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
           decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8)
           ),
           child: Text(
             '$label: ₹$absBalance',
             style: GoogleFonts.notoSansTamil(
               fontSize: 12,
               fontWeight: FontWeight.bold,
               color: color,
             ),
           ),
        );
      },
    );
  }
}

