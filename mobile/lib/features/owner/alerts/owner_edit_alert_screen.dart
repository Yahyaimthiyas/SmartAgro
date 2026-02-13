import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/colors.dart';
import '../../../core/services/localization_service.dart';

class OwnerEditAlertScreen extends StatefulWidget {
  final String? alertId;

  const OwnerEditAlertScreen({super.key, this.alertId});

  @override
  State<OwnerEditAlertScreen> createState() => _OwnerEditAlertScreenState();
}

class _OwnerEditAlertScreenState extends State<OwnerEditAlertScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleTaController = TextEditingController();
  final _titleEnController = TextEditingController();
  final _descTaController = TextEditingController();
  final _descEnController = TextEditingController();
  final _cropTaController = TextEditingController();
  final _cropEnController = TextEditingController();
  final _actionTaController = TextEditingController();
  final _actionEnController = TextEditingController();

  String? _type; // pest, weather, general
  String? _urgency; // immediate, high, medium, low
  String? _categoryId;
  String? _categoryNameTa;
  String? _categoryNameEn;

  bool _loading = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.alertId != null) {
      _loadAlert();
    }
  }

  @override
  void dispose() {
    _titleTaController.dispose();
    _titleEnController.dispose();
    _descTaController.dispose();
    _descEnController.dispose();
    _cropTaController.dispose();
    _cropEnController.dispose();
    _actionTaController.dispose();
    _actionEnController.dispose();
    super.dispose();
  }

  Future<void> _loadAlert() async {
    setState(() {
      _loading = true;
    });
    try {
      final doc = await FirebaseFirestore.instance.collection('alerts').doc(widget.alertId).get();
      if (!doc.exists) {
        setState(() {
          _loading = false;
        });
        return;
      }
      final data = doc.data()!;
      _type = data['type'] as String?;
      _urgency = data['urgency'] as String?;
      _titleTaController.text = data['title_ta'] as String? ?? '';
      _titleEnController.text = data['title_en'] as String? ?? '';
      _descTaController.text = data['description_ta'] as String? ?? '';
      _descEnController.text = data['description_en'] as String? ?? '';
      _cropTaController.text = data['crop_ta'] as String? ?? '';
      _cropEnController.text = data['crop_en'] as String? ?? '';
      _actionTaController.text = data['action_ta'] as String? ?? '';
      _actionEnController.text = data['action_en'] as String? ?? '';
      _categoryId = data['categoryId'] as String?;
      _categoryNameTa = data['categoryName_ta'] as String?;
      _categoryNameEn = data['categoryName_en'] as String?;
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.alertId != null;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          LocalizationService.tr(
            isEdit ? 'owner_alerts_edit_title_edit' : 'owner_alerts_edit_title_new',
          ),
          style: GoogleFonts.notoSansTamil(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTypeAndUrgencyRow(),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _titleTaController,
                        labelKey: 'owner_alerts_field_title_ta',
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _titleEnController,
                        labelKey: 'owner_alerts_field_title_en',
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _descTaController,
                        labelKey: 'owner_alerts_field_desc_ta',
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _descEnController,
                        labelKey: 'owner_alerts_field_desc_en',
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _cropTaController,
                        labelKey: 'owner_alerts_field_crop_ta',
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _cropEnController,
                        labelKey: 'owner_alerts_field_crop_en',
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _actionTaController,
                        labelKey: 'owner_alerts_field_action_ta',
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _actionEnController,
                        labelKey: 'owner_alerts_field_action_en',
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      _buildCategoryDropdown(),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _onSavePressed,
                          child: _saving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  LocalizationService.tr('owner_alerts_btn_save'),
                                  style: GoogleFonts.notoSansTamil(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildTypeAndUrgencyRow() {
    return Row(
      children: [
        Expanded(child: _buildTypeDropdown()),
        const SizedBox(width: 12),
        Expanded(child: _buildUrgencyDropdown()),
      ],
    );
  }

  Widget _buildTypeDropdown() {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: LocalizationService.tr('owner_alerts_field_type'),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _type,
          isExpanded: true,
          hint: Text(
            LocalizationService.tr('owner_alerts_field_type'),
            style: GoogleFonts.notoSansTamil(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          items: [
            DropdownMenuItem(
              value: 'pest',
              child: Text(
                LocalizationService.tr('owner_alerts_type_pest'),
                style: GoogleFonts.notoSansTamil(fontSize: 13),
              ),
            ),
            DropdownMenuItem(
              value: 'weather',
              child: Text(
                LocalizationService.tr('owner_alerts_type_weather'),
                style: GoogleFonts.notoSansTamil(fontSize: 13),
              ),
            ),
            DropdownMenuItem(
              value: 'general',
              child: Text(
                LocalizationService.tr('owner_alerts_type_general'),
                style: GoogleFonts.notoSansTamil(fontSize: 13),
              ),
            ),
          ],
          onChanged: (value) {
            setState(() {
              _type = value;
            });
          },
        ),
      ),
    );
  }

  Widget _buildUrgencyDropdown() {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: LocalizationService.tr('owner_alerts_field_urgency'),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _urgency,
          isExpanded: true,
          hint: Text(
            LocalizationService.tr('owner_alerts_field_urgency'),
            style: GoogleFonts.notoSansTamil(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          items: [
            DropdownMenuItem(
              value: 'immediate',
              child: Text(
                LocalizationService.tr('owner_alerts_urgency_immediate'),
                style: GoogleFonts.notoSansTamil(fontSize: 13),
              ),
            ),
            DropdownMenuItem(
              value: 'high',
              child: Text(
                LocalizationService.tr('owner_alerts_urgency_high'),
                style: GoogleFonts.notoSansTamil(fontSize: 13),
              ),
            ),
            DropdownMenuItem(
              value: 'medium',
              child: Text(
                LocalizationService.tr('owner_alerts_urgency_medium'),
                style: GoogleFonts.notoSansTamil(fontSize: 13),
              ),
            ),
            DropdownMenuItem(
              value: 'low',
              child: Text(
                LocalizationService.tr('owner_alerts_urgency_low'),
                style: GoogleFonts.notoSansTamil(fontSize: 13),
              ),
            ),
          ],
          onChanged: (value) {
            setState(() {
              _urgency = value;
            });
          },
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelKey,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: LocalizationService.tr(labelKey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('categories')
          .orderBy('sortOrder', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];

        return InputDecorator(
          decoration: InputDecoration(
            labelText: LocalizationService.tr('owner_alerts_field_category'),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _categoryId,
              isExpanded: true,
              hint: Text(
                LocalizationService.tr('owner_alerts_field_category_hint'),
                style: GoogleFonts.notoSansTamil(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              items: [
                for (final doc in docs)
                  DropdownMenuItem(
                    value: doc.id,
                    child: Text(
                      '${doc.data()['name_ta'] ?? ''} / ${doc.data()['name_en'] ?? ''}',
                      style: GoogleFonts.notoSansTamil(fontSize: 13),
                    ),
                  ),
              ],
              onChanged: (value) {
                if (value == null) return;
                final selected = docs.firstWhere((d) => d.id == value);
                final data = selected.data();
                setState(() {
                  _categoryId = value;
                  _categoryNameTa = data['name_ta'] as String?;
                  _categoryNameEn = data['name_en'] as String?;
                });
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _onSavePressed() async {
    final titleTa = _titleTaController.text.trim();
    final descTa = _descTaController.text.trim();

    if (_type == null || _urgency == null || titleTa.isEmpty || descTa.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LocalizationService.tr('owner_alerts_validation_required')),
        ),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final collection = FirebaseFirestore.instance.collection('alerts');
      final docRef = widget.alertId != null
          ? collection.doc(widget.alertId)
          : collection.doc();

      final data = <String, dynamic>{
        'type': _type,
        'urgency': _urgency,
        'title_ta': _titleTaController.text.trim(),
        'title_en': _titleEnController.text.trim(),
        'description_ta': _descTaController.text.trim(),
        'description_en': _descEnController.text.trim(),
        'crop_ta': _cropTaController.text.trim(),
        'crop_en': _cropEnController.text.trim(),
        'action_ta': _actionTaController.text.trim(),
        'action_en': _actionEnController.text.trim(),
      };

      if (_categoryId != null && _categoryId!.isNotEmpty) {
        data['categoryId'] = _categoryId;
        data['categoryName_ta'] = _categoryNameTa ?? '';
        data['categoryName_en'] = _categoryNameEn ?? '';
      }

      if (widget.alertId == null) {
        data['createdAt'] = FieldValue.serverTimestamp();
        await docRef.set(data);
      } else {
        data['updatedAt'] = FieldValue.serverTimestamp();
        await docRef.update(data);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LocalizationService.tr('owner_alerts_save_success')),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LocalizationService.tr('owner_alerts_save_failed')),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(LocalizationService.tr('owner_alerts_delete_confirm_title')),
          content: Text(LocalizationService.tr('owner_alerts_delete_confirm_message')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(LocalizationService.tr('owner_alerts_delete_confirm_no')),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(
                LocalizationService.tr('owner_alerts_delete_confirm_yes'),
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance.collection('alerts').doc(widget.alertId).delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LocalizationService.tr('owner_alerts_delete_success')),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LocalizationService.tr('owner_alerts_save_failed')),
          ),
        );
      }
    }
  }
}

