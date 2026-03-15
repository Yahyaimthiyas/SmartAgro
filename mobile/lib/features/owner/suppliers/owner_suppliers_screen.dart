import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/colors.dart';
import '../../../core/services/localization_service.dart';

class OwnerSuppliersScreen extends StatelessWidget {
  const OwnerSuppliersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isTa = LocalizationService.isTamil;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          isTa ? 'விற்பனையாளர்கள் மேலாண்மை' : 'Supplier Management',
          style: GoogleFonts.notoSansTamil(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('suppliers').orderBy('name').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) return _buildEmptyState(isTa);

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final data = docs[index].data();
              return _SupplierCard(id: docs[index].id, data: data);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSupplierSheet(context),
        label: Text(isTa ? 'விற்பனையாளரைச் சேர்க்க' : 'Add Supplier'),
        icon: const Icon(Icons.add),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildEmptyState(bool isTa) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.business_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(isTa ? 'விற்பனையாளர்கள் யாரும் இல்லை' : 'No suppliers registered yet'),
        ],
      ),
    );
  }
}

class _SupplierCard extends StatelessWidget {
  final String id;
  final Map<String, dynamic> data;

  const _SupplierCard({required this.id, required this.data});

  @override
  Widget build(BuildContext context) {
    final name = data['name'] ?? 'Unknown';
    final contact = data['contactName'] ?? '';
    final phone = data['phone'] ?? '';
    final category = data['category'] ?? 'General';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.business, color: Colors.blue),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.notoSansTamil(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('$contact • $phone', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
                  child: Text(category, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

Future<void> _showAddSupplierSheet(BuildContext context) async {
  final nameController = TextEditingController();
  final contactController = TextEditingController();
  final phoneController = TextEditingController();
  final isTa = LocalizationService.isTamil;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isTa ? 'புதிய விற்பனையாளர்' : 'Add New Supplier', style: GoogleFonts.notoSansTamil(fontWeight: FontWeight.bold, fontSize: 20)),
          const SizedBox(height: 24),
          TextField(
            controller: nameController,
            decoration: InputDecoration(labelText: isTa ? 'நிறுவனத்தின் பெயர்' : 'Company Name', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: contactController,
            decoration: InputDecoration(labelText: isTa ? 'தொடர்பு நபர்' : 'Contact Person', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(labelText: isTa ? 'மொபைல் எண்' : 'Phone Number', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty) return;
                await FirebaseFirestore.instance.collection('suppliers').add({
                  'name': nameController.text.trim(),
                  'contactName': contactController.text.trim(),
                  'phone': phoneController.text.trim(),
                  'category': 'Agro Products',
                  'createdAt': FieldValue.serverTimestamp(),
                });
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: Text(isTa ? 'சேமி' : 'Save Supplier', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    ),
  );
}
