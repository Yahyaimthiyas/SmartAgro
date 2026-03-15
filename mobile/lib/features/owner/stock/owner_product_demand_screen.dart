import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/colors.dart';
import '../../../core/services/localization_service.dart';

class OwnerProductDemandScreen extends StatefulWidget {
  const OwnerProductDemandScreen({super.key});

  @override
  State<OwnerProductDemandScreen> createState() => _OwnerProductDemandScreenState();
}

class _OwnerProductDemandScreenState extends State<OwnerProductDemandScreen> {
  final _demandController = TextEditingController();
  final _customerController = TextEditingController();
  bool _isSaving = false;

  Future<void> _addDemand() async {
    final demand = _demandController.text.trim();
    if (demand.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('productDemand').add({
        'productName': demand,
        'customerName': _customerController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
      _demandController.clear();
      _customerController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(LocalizationService.isTamil ? 'கோரிக்கை பதிவு செய்யப்பட்டது' : 'Demand recorded')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTa = LocalizationService.isTamil;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: Text(isTa ? 'தயாரிப்பு தேவைகள்' : 'Product Demand Tracker', style: GoogleFonts.notoSansTamil(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  controller: _demandController,
                  decoration: InputDecoration(
                    labelText: isTa ? 'தயாரிப்பு பெயர்' : 'Product Name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _customerController,
                  decoration: InputDecoration(
                    labelText: isTa ? 'விவசாயி பெயர் (விருப்பம்)' : 'Farmer Name (Optional)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _addDemand,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSaving 
                      ? const CircularProgressIndicator(color: Colors.white) 
                      : Text(isTa ? 'தேவையைச் சேர்க்கவும்' : 'Add Demand', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('productDemand').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return Center(child: Text(isTa ? 'தேவைகள் எதுவும் இல்லை' : 'No demands recorded yet'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    final ts = data['createdAt'] as Timestamp?;
                    final date = ts != null ? DateFormat('MMM d, yyyy').format(ts.toDate()) : '';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        title: Text(data['productName'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${data['customerName'] ?? ''} • $date'),
                        trailing: IconButton(
                          icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                          onPressed: () => docs[index].reference.delete(),
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
}
