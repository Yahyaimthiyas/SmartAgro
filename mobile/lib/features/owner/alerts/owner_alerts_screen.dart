import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/colors.dart';
import '../../../core/services/localization_service.dart';
import 'owner_edit_alert_screen.dart';

class OwnerAlertsScreen extends StatefulWidget {
  const OwnerAlertsScreen({super.key});

  @override
  State<OwnerAlertsScreen> createState() => _OwnerAlertsScreenState();
}

class _OwnerAlertsScreenState extends State<OwnerAlertsScreen> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          LocalizationService.tr('owner_alerts_appbar'),
          style: GoogleFonts.notoSansTamil(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
             color: Colors.white,
             padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
             child: Row(
               children: [
                 _filterChip('all', LocalizationService.tr('alerts_tab_all')),
                 const SizedBox(width: 8),
                 _filterChip('pest', LocalizationService.tr('alerts_tab_pest')),
                 const SizedBox(width: 8),
                 _filterChip('weather', LocalizationService.tr('alerts_tab_weather')),
               ],
             ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('alerts')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];
                final filtered = docs.where((d) {
                  if (_filter == 'all') return true;
                  final type = d.data()['type'] as String? ?? 'general';
                  return type == _filter;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                       mainAxisAlignment: MainAxisAlignment.center,
                       children: [
                          Container(
                             padding: const EdgeInsets.all(24),
                             decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.05),
                                shape: BoxShape.circle,
                             ),
                             child: const Icon(Icons.notifications_off_outlined, size: 48, color: Colors.orange),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            LocalizationService.tr('owner_alerts_empty'),
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
                    final type = data['type'] as String? ?? 'general';
                    final urgency = data['urgency'] as String? ?? 'medium';
                    final titleTa = data['title_ta'] as String? ?? '';
                    final titleEn = data['title_en'] as String? ?? '';
                    final descTa = data['description_ta'] as String? ?? '';
                    final descEn = data['description_en'] as String? ?? '';
                    final ts = data['createdAt'] as Timestamp?;
                    final created = ts?.toDate();

                    return InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => OwnerEditAlertScreen(alertId: doc.id),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: _buildAlertCard(
                        type: type,
                        urgency: urgency,
                        titleTa: titleTa,
                        titleEn: titleEn,
                        descTa: descTa,
                        descEn: descEn,
                        created: created,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const OwnerEditAlertScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add_alert_rounded, color: Colors.white),
        label: Text(
           LocalizationService.tr('owner_alerts_add_fab'),
           style: GoogleFonts.notoSansTamil(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  Widget _filterChip(String value, String label) {
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
        setState(() => _filter = value);
      },
    );
  }

  Widget _buildAlertCard({
    required String type,
    required String urgency,
    required String titleTa,
    required String titleEn,
    required String descTa,
    required String descEn,
    required DateTime? created,
  }) {
    Color bannerColor;
    switch (urgency) {
      case 'immediate':
        bannerColor = Colors.redAccent;
        break;
      case 'high':
        bannerColor = Colors.deepOrange;
        break;
      case 'medium':
        bannerColor = Colors.amber;
        break;
      default:
        bannerColor = AppColors.primary;
    }

    IconData typeIcon;
    switch (type) {
      case 'pest':
        typeIcon = Icons.bug_report_outlined;
        break;
      case 'weather':
        typeIcon = Icons.wb_cloudy_outlined;
        break;
      default:
        typeIcon = Icons.notifications_none;
    }

    final timeText = created == null
        ? ''
        : '${created.day}/${created.month}/${created.year}';

    return Container(
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
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
               width: 6,
               color: bannerColor,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                           children: [
                              Container(
                                 padding: const EdgeInsets.all(6),
                                 decoration: BoxDecoration(
                                    color: bannerColor.withOpacity(0.1),
                                    shape: BoxShape.circle
                                 ),
                                 child: Icon(typeIcon, size: 16, color: bannerColor),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                 decoration: BoxDecoration(
                                    color: bannerColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8)
                                 ),
                                 child: Text(
                                   urgency.toUpperCase(),
                                   style: GoogleFonts.poppins(
                                     fontSize: 10,
                                     fontWeight: FontWeight.bold,
                                     color: bannerColor,
                                   ),
                                 ),
                              ),
                           ],
                        ),
                        Text(
                          timeText,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      titleTa,
                      style: GoogleFonts.notoSansTamil(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (titleEn.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        titleEn,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      descTa,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.notoSansTamil(
                        fontSize: 14,
                        color: AppColors.textPrimary.withOpacity(0.8),
                        height: 1.5
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

