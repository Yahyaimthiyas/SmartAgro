import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/colors.dart';
import '../../../core/services/csv_import_service.dart';
import '../../../core/services/localization_service.dart';

class OwnerBulkUploadScreen extends StatefulWidget {
  const OwnerBulkUploadScreen({super.key});

  @override
  State<OwnerBulkUploadScreen> createState() => _OwnerBulkUploadScreenState();
}

class _OwnerBulkUploadScreenState extends State<OwnerBulkUploadScreen> {
  final CsvImportService _importService = CsvImportService();
  
  bool _isLoading = false;
  bool _isProcessing = false;
  String? _errorMessage;
  String? _fileName;
  
  List<ImportRow> _parsedRows = [];

  Future<void> _pickFile() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final platformFile = result.files.first;
        final Uint8List? bytes = platformFile.bytes;
        
        if (bytes == null) {
          setState(() {
            _errorMessage = "File could not be read.";
          });
          return;
        }

        setState(() {
          _isLoading = true;
          _errorMessage = null;
          _fileName = platformFile.name;
          _parsedRows = [];
        });

        // Try parsing using utf8. In robust apps, you may want to detect encoding (like UTF-16LE or Windows-1252)
        // Here we default to UTF-8
        String csvString;
        try {
          csvString = utf8.decode(bytes);
        } catch (e) {
          // Fallback if not standard utf8
          csvString = String.fromCharCodes(bytes);
        }

        final rows = await _importService.parseAndMatchCsv(csvString);

        setState(() {
          _parsedRows = rows;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Failed to parse CSV: ${e.toString()}";
      });
    }
  }

  Future<void> _commitUpload() async {
    if (_parsedRows.isEmpty) return;
    
    setState(() {
      _isProcessing = true;
    });

    try {
      await _importService.commitImport(_parsedRows);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bulk upload completed successfully!')),
      );
      Navigator.of(context).pop(); // Go back to stock screen

    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _errorMessage = "Failed to upload to database: ${e.toString()}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    int newCount = _parsedRows.where((r) => r.isNewProduct && r.error == null).length;
    int updateCount = _parsedRows.where((r) => !r.isNewProduct && r.error == null).length;
    int errorCount = _parsedRows.where((r) => r.error != null).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Bulk Product Upload', // LocalizationService.tr('header_bulk_upload')
          style: GoogleFonts.notoSansTamil(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Section - File Picker
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              width: double.infinity,
              child: Column(
                children: [
                  OutlinedButton.icon(
                    onPressed: _isLoading || _isProcessing ? null : _pickFile,
                    icon: const Icon(Icons.upload_file),
                    label: Text(
                      _fileName ?? 'Select CSV File',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: AppColors.primary),
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
            
            // Middle Section - Preview List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _parsedRows.isEmpty
                      ? Center(
                          child: Text(
                            "No data to preview. Pick a valid CSV file.",
                            style: GoogleFonts.poppins(color: Colors.grey.shade500),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _parsedRows.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final row = _parsedRows[index];
                            return _buildPreviewCard(row);
                          },
                        ),
            ),

            // Bottom Section - Summary & Confirm
            if (_parsedRows.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSummaryStat("New", newCount, Colors.green),
                        _buildSummaryStat("Update", updateCount, Colors.blue),
                        if (errorCount > 0)
                           _buildSummaryStat("Error", errorCount, Colors.red),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: (_isProcessing || errorCount == _parsedRows.length) ? null : _commitUpload,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: _isProcessing
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                                "Confirm Upload", // LocalizationService.tr('btn_confirm_upload')
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryStat(String label, int count, MaterialColor color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color.shade800,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewCard(ImportRow row) {
    final bool isError = row.error != null;
    final bool isNew = row.isNewProduct;
    
    final MaterialColor badgeColor = isError ? Colors.red : (isNew ? Colors.green : Colors.blue);
    final String badgeText = isError ? 'ERROR' : (isNew ? 'NEW' : 'UPDATE');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: badgeColor.withOpacity(isError ? 0.5 : 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badgeText,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: badgeColor.shade700,
                  ),
                ),
              ),
              if (isNew && !isError) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    "⚠️ Needs Info",
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              if (row.rawPrice > 0)
                Text(
                  "₹${row.rawPrice}",
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            row.rawName,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          if (isError)
            Text(
              row.error!,
              style: TextStyle(color: Colors.red.shade700, fontSize: 13),
            )
          else if (isNew)
            Text(
              "+${row.rawStock} stock will be added",
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            )
          else
            Row(
              children: [
                Icon(Icons.inventory_2_outlined, size: 14, color: Colors.blue.shade600),
                const SizedBox(width: 4),
                Text(
                  "${row.existingStock} → ${(row.existingStock ?? 0) + row.rawStock}",
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.w500),
                ),
                if (row.rawPrice > 0 && row.rawPrice != row.existingPrice) ...[
                  const SizedBox(width: 12),
                  Icon(Icons.sell_outlined, size: 14, color: Colors.green.shade600),
                  const SizedBox(width: 4),
                  Text(
                    "₹${row.existingPrice} → ₹${row.rawPrice}",
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ]
              ],
            ),
        ],
      ),
    );
  }
}
