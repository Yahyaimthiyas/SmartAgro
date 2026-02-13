import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/colors.dart';
import '../../../core/services/localization_service.dart';

class OwnerFarmerDetailsScreen extends StatelessWidget {
  final String userId;

  const OwnerFarmerDetailsScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: Text(
          LocalizationService.tr('owner_farmers_details_appbar'),
          style: GoogleFonts.notoSansTamil(
            fontWeight: FontWeight.bold, // Use system font weight if needed
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          String? name;
          String? phone;
          DateTime? createdAt;

          if (snapshot.hasData && snapshot.data!.data() != null) {
            final data = snapshot.data!.data()!;
            name = data['name'] as String?;
            phone = data['phone'] as String?;
            final ts = data['createdAt'] as Timestamp?;
            createdAt = ts?.toDate();
          }

          final displayName = name?.isNotEmpty == true
              ? name!
              : (phone ?? LocalizationService.tr('owner_farmers_unknown_name'));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FarmerProfileHeader(
                  name: displayName,
                  phone: phone,
                  createdAt: createdAt,
                ),
                const SizedBox(height: 24),
                _CreditLedgerSection(userId: userId),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FarmerProfileHeader extends StatelessWidget {
  final String name;
  final String? phone;
  final DateTime? createdAt;

  const _FarmerProfileHeader({
    required this.name,
    required this.phone,
    required this.createdAt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF66BB6A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: GoogleFonts.notoSansTamil(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (phone != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.phone, color: Colors.white, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    phone!,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (createdAt != null) ...[
             const SizedBox(height: 12),
             Text(
                'Joined: ${createdAt!.day}/${createdAt!.month}/${createdAt!.year}',
                style: GoogleFonts.poppins(
                   fontSize: 12,
                   color: Colors.white.withOpacity(0.8),
                ),
             ),
          ]
        ],
      ),
    );
  }
}

class _CreditLedgerSection extends StatelessWidget {
  final String userId;

  const _CreditLedgerSection({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('creditLedger')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
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

        final isNegative = balance < 0; // Advance payment
        final isPositive = balance > 0; // Credit due
        
        final absBalance = balance.abs().toStringAsFixed(0);
        final statusColor = isPositive ? Colors.red : (isNegative ? Colors.green : Colors.grey);
        final statusIcon = isPositive ? Icons.trending_up : (isNegative ? Icons.check_circle : Icons.balance);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Balance Card
            Container(
               width: double.infinity,
               padding: const EdgeInsets.all(24),
               decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                     BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 5)
                     )
                  ]
               ),
               child: Column(
                  children: [
                     Text(
                        LocalizationService.tr('owner_farmers_balance_zero').split(':')[0], // "Balance" label
                        style: GoogleFonts.notoSansTamil(
                           fontSize: 14,
                           color: AppColors.textSecondary,
                           fontWeight: FontWeight.w600
                        ),
                     ),
                     const SizedBox(height: 8),
                     Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                           Icon(statusIcon, color: statusColor, size: 28),
                           const SizedBox(width: 8),
                           Text(
                              '₹$absBalance',
                              style: GoogleFonts.notoSansTamil(
                                 fontSize: 36,
                                 fontWeight: FontWeight.bold,
                                 color: AppColors.textPrimary
                              ),
                           ),
                        ],
                     ),
                     const SizedBox(height: 8),
                     Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                           color: statusColor.withOpacity(0.1),
                           borderRadius: BorderRadius.circular(12)
                        ),
                        child: Text(
                           isPositive 
                              ? LocalizationService.tr('owner_farmers_balance_positive') // "Credit Due"
                              : (isNegative ? LocalizationService.tr('owner_farmers_balance_negative') : "Settled"),
                           style: GoogleFonts.notoSansTamil(
                              fontSize: 12, 
                              fontWeight: FontWeight.bold,
                              color: statusColor
                           ),
                        ),
                     )
                  ],
               ),
            ),
            
            const SizedBox(height: 24),
            
            // Actions
            Row(
               children: [
                  Expanded(
                     child: _ActionButton(
                        icon: Icons.add,
                        label: LocalizationService.tr('owner_farmers_add_credit'),
                        color: Colors.redAccent,
                        onTap: () => _showAddLedgerEntrySheet(context, userId, 'credit'),
                     ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                     child: _ActionButton(
                        icon: Icons.check,
                        label: LocalizationService.tr('owner_farmers_add_payment'),
                        color: Colors.green,
                        onTap: () => _showAddLedgerEntrySheet(context, userId, 'payment'),
                     ),
                  ),
               ],
            ),

            const SizedBox(height: 32),
            
            // History
            Text(
              LocalizationService.tr('owner_farmers_ledger_section_title'),
              style: GoogleFonts.notoSansTamil(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary
              ),
            ),
            const SizedBox(height: 16),
            
            if (docs.isEmpty)
              Center(
                 child: Column(
                    children: [
                       const SizedBox(height: 20),
                       Icon(Icons.history, size: 48, color: Colors.grey.shade300),
                       const SizedBox(height: 12),
                       Text(
                          LocalizationService.tr('owner_farmers_ledger_empty'),
                          style: GoogleFonts.notoSansTamil(color: AppColors.textSecondary),
                       )
                    ],
                 ),
              )
            else
               ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                     return _LedgerCard(data: docs[index].data());
                  },
               )
          ],
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
   final IconData icon;
   final String label;
   final Color color;
   final VoidCallback onTap;

   const _ActionButton({
      required this.icon,
      required this.label,
      required this.color,
      required this.onTap
   });

   @override
  Widget build(BuildContext context) {
    return InkWell(
       onTap: onTap,
       borderRadius: BorderRadius.circular(16),
       child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
             color: color.withOpacity(0.1),
             borderRadius: BorderRadius.circular(16),
             border: Border.all(color: color.withOpacity(0.2))
          ),
          child: Column(
             children: [
                Icon(icon, color: color),
                const SizedBox(height: 8),
                Text(
                   label,
                   style: GoogleFonts.notoSansTamil(
                      fontWeight: FontWeight.w600,
                      color: color
                   ),
                )
             ],
          ),
       ),
    );
  }
}

class _LedgerCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _LedgerCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final amount = (data['amount'] as num? ?? 0).toDouble();
    final type = data['type'] as String? ?? 'credit';
    final note = data['note'] as String? ?? '';
    final ts = data['createdAt'] as Timestamp?;
    final createdAt = ts?.toDate();

    final isCredit = type == 'credit';
    final color = isCredit ? Colors.red : Colors.green;
    final icon = isCredit ? Icons.arrow_outward : Icons.arrow_downward; // Out (Credit given), Down (Payment received)

    return Container(
       padding: const EdgeInsets.all(16),
       decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
             BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 4)
             )
          ]
       ),
       child: Row(
          children: [
             Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                   color: color.withOpacity(0.1),
                   shape: BoxShape.circle
                ),
                child: Icon(icon, color: color),
             ),
             const SizedBox(width: 16),
             Expanded(
                child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                      Text(
                         isCredit ? "Credit Given" : "Payment Received", // Fallback if key missing, helps debugging
                         style: GoogleFonts.notoSansTamil(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary
                         ),
                      ),
                      if(note.isNotEmpty)
                         Text(
                            note,
                            style: GoogleFonts.notoSansTamil(
                               fontSize: 12,
                               color: AppColors.textSecondary
                            ),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                         ),
                      if(createdAt != null)
                         Text(
                            "${createdAt.day}/${createdAt.month} • ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}",
                             style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey),
                         )
                   ],
                ),
             ),
             Text(
                '₹${amount.toStringAsFixed(0)}',
                style: GoogleFonts.notoSansTamil(
                   fontSize: 16,
                   fontWeight: FontWeight.bold,
                   color: color
                ),
             )
          ],
       ),
    );
  }
}

Future<void> _showAddLedgerEntrySheet(
  BuildContext context,
  String userId,
  String type,
) async {
  final amountController = TextEditingController();
  final noteController = TextEditingController();

  final isCredit = type == 'credit';

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return Container(
        decoration: const BoxDecoration(
           color: Colors.white,
           borderRadius: BorderRadius.vertical(top: Radius.circular(24))
        ),
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              LocalizationService.tr(
                isCredit ? 'owner_farmers_add_credit' : 'owner_farmers_add_payment',
              ),
              style: GoogleFonts.notoSansTamil(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                prefixText: '₹ ',
                labelText: LocalizationService.tr('owner_farmers_ledger_amount_label'),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                filled: true,
                fillColor: const Color(0xFFF8F9FA)
              ),
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              decoration: InputDecoration(
                labelText: LocalizationService.tr('owner_farmers_ledger_note_label'), 
                hintText: "Optional note...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                 filled: true,
                fillColor: const Color(0xFFF8F9FA)
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () async {
                  final amountStr = amountController.text.trim();
                  final amount = double.tryParse(amountStr);
                  if (amount == null || amount <= 0) return;

                  try {
                    await FirebaseFirestore.instance.collection('creditLedger').add({
                      'userId': userId,
                      'amount': amount,
                      'type': type,
                      'note': noteController.text.trim(),
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                    if (context.mounted) Navigator.of(ctx).pop();
                  } catch (e) {
                     // Error handling
                  }
                },
                style: ElevatedButton.styleFrom(
                   backgroundColor: isCredit ? Colors.redAccent : Colors.green,
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                ),
                child: Text(
                  LocalizationService.tr('owner_farmers_ledger_btn_save'),
                  style: GoogleFonts.notoSansTamil(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
