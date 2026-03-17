import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/colors.dart';
import '../../../core/services/localization_service.dart';
import '../../../core/utils/pdf_utils.dart';

class OwnerInvoiceScreen extends StatelessWidget {
  final Map<String, dynamic> orderData;
  final String orderId;
  final Map<String, dynamic>? customerData;

  const OwnerInvoiceScreen({
    super.key,
    required this.orderId,
    required this.orderData,
    this.customerData,
  });

  @override
  Widget build(BuildContext context) {
    final items = (orderData['items'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    final total = (orderData['totalAmount'] as num? ?? 0).toDouble();
    final ts = orderData['createdAt'] as dynamic;
    DateTime date;
    if (ts is dynamic && ts.runtimeType.toString() == 'Timestamp') {
      date = ts.toDate();
    } else {
      date = DateTime.now();
    }
    
    final formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(date);
    final isTa = LocalizationService.isTamil;

    final customerName = customerData?['name'] ?? orderData['customerName'] ?? (isTa ? 'நேரடி வாடிக்கையாளர்' : 'Walk-in Customer');
    final customerPhone = customerData?['phone'] ?? orderData['customerPhone'] ?? '';
    final customerEmail = customerData?['email'] ?? orderData['customerEmail'] ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          isTa ? 'ஆர்டர் ரசீது' : 'Digital Invoice',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () => _shareBillMenu(context, customerPhone, customerEmail),
          ),
          IconButton(
            icon: const Icon(Icons.print_outlined),
            onPressed: () => _printInvoice(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background Trademark / Watermark
          Positioned(
            right: -50,
            bottom: 100,
            child: Opacity(
              opacity: 0.03,
              child: Icon(Icons.verified_user_rounded, size: 300, color: AppColors.primary),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.agriculture_rounded, size: 40, color: AppColors.primary),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'SMART AGRO SHOP',
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        'Agro-Inputs & Strategic Services',
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isTa ? 'இன்வாய்ஸ் எண்:' : 'Invoice No:',
                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '#$orderId'.toUpperCase(),
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          isTa ? 'தேதி:' : 'Transaction Date:',
                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          formattedDate,
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isTa ? 'வாடிக்கையாளர் விவரம்:' : 'CUSTOMER DETAILS',
                        style: GoogleFonts.outfit(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w800, letterSpacing: 1),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        customerName,
                        style: GoogleFonts.notoSansTamil(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      if (customerPhone.isNotEmpty)
                        Text(
                          customerPhone,
                          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                Text(
                  isTa ? 'தயாரிப்பு விவரங்கள்' : 'ORDER SUMMARY',
                  style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textPrimary, fontWeight: FontWeight.w800, letterSpacing: 1),
                ),
                const SizedBox(height: 8),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                       Expanded(flex: 3, child: Text(isTa ? 'பொருள்' : 'ITEM', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 11, color: AppColors.textSecondary))),
                       Expanded(child: Text(isTa ? 'அளவு' : 'QTY', textAlign: TextAlign.center, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 11, color: AppColors.textSecondary))),
                       Expanded(child: Text(isTa ? 'விலை' : 'PRICE', textAlign: TextAlign.right, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 11, color: AppColors.textSecondary))),
                    ],
                  ),
                ),
                const Divider(),
                
                for (final item in items) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            LocalizationService.pickTaEn(item['name_ta'], item['name_en']),
                            style: GoogleFonts.notoSansTamil(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${item['quantity']}',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (item['originalPrice'] != null && (item['originalPrice'] as num).toDouble() > (item['price'] as num).toDouble())
                                Text(
                                  '₹${(item['originalPrice'] * (item['quantity'] ?? 1)).toStringAsFixed(0)}',
                                  style: GoogleFonts.inter(decoration: TextDecoration.lineThrough, color: Colors.grey, fontSize: 10),
                                ),
                              Text(
                                '₹${((item['price'] ?? 0) * (item['quantity'] ?? 1)).toStringAsFixed(0)}',
                                textAlign: TextAlign.right,
                                style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isTa ? 'மொத்தம்' : 'TOTAL PAYABLE',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white70,
                        ),
                      ),
                      Text(
                        '₹${total.toStringAsFixed(0)}',
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 60),
                
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          isTa ? 'நன்றி! மீண்டும் வருக!' : 'QUALITY PRODUCTS • TRUSTED SERVICE',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isTa ? 'கணினி மூலம் உருவாக்கப்பட்ட விலைப்பட்டியல்' : 'System Generated Digital Receipt',
                        style: GoogleFonts.inter(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)),
          ],
        ),
        child: ElevatedButton(
           onPressed: () => _shareBillMenu(context, customerPhone, customerEmail),
           style: ElevatedButton.styleFrom(
             padding: const EdgeInsets.symmetric(vertical: 16),
             backgroundColor: AppColors.primary,
             foregroundColor: Colors.white,
             elevation: 0,
             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
           ),
           child: Row(
             mainAxisAlignment: MainAxisAlignment.center,
             children: [
               const Icon(Icons.send_rounded, size: 20),
               const SizedBox(width: 12),
               Text(
                 isTa ? 'பில் அனுப்பவும்' : 'Send Digital Receipt',
                 style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
               ),
             ],
           ),
        ),
      ),
    );
  }

  Future<void> _printInvoice(BuildContext context) async {
    try {
      final pdfBytes = await PdfInvoiceApi.generate(orderData, orderId);
      await Printing.layoutPdf(
        onLayout: (format) async => pdfBytes,
        name: 'Invoice_$orderId',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error printing: $e')));
      }
    }
  }

  void _shareBillMenu(BuildContext context, String phone, String email) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            const Text('Send Bill To', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text('Share PDF File'),
              onTap: () {
                Navigator.pop(ctx);
                _sharePdfFile(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline, color: Color(0xFF25D366)),
              title: const Text('WhatsApp'),
              onTap: () {
                Navigator.pop(ctx);
                _launchWhatsApp(context, phone);
              },
            ),
            ListTile(
              leading: const Icon(Icons.message_outlined, color: Colors.blue),
              title: const Text('SMS'),
              onTap: () {
                Navigator.pop(ctx);
                _launchSms(context, phone);
              },
            ),
            ListTile(
              leading: const Icon(Icons.email_outlined, color: Colors.grey),
              title: const Text('Email'),
              onTap: () {
                Navigator.pop(ctx);
                _launchEmail(context, email);
              },
            ),
            ListTile(
              leading: const Icon(Icons.send_rounded, color: Color(0xFF0088CC)),
              title: const Text('Telegram'),
              onTap: () {
                Navigator.pop(ctx);
                _sharePdfFile(context);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _sharePdfFile(BuildContext context) async {
    try {
      final pdfBytes = await PdfInvoiceApi.generate(orderData, orderId);
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/Invoice_$orderId.pdf');
      await file.writeAsBytes(pdfBytes);
      
      await Share.shareXFiles([XFile(file.path)], text: 'Invoice for Order #$orderId');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sharing failed: $e')));
      }
    }
  }

  Future<void> _launchWhatsApp(BuildContext context, String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final message = _getDetailedBillMessage();
    final url = 'whatsapp://send?phone=$cleanPhone&text=${Uri.encodeComponent(message)}';
    
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      // If WhatsApp app is not installed, try web version
      final webUrl = 'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}';
      if (await canLaunchUrl(Uri.parse(webUrl))) {
        await launchUrl(Uri.parse(webUrl), mode: LaunchMode.externalApplication);
      } else {
        _sharePdfFile(context); // Fallback to PDF share
      }
    }
  }

  Future<void> _launchSms(BuildContext context, String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final message = _getDetailedBillMessage();
    final url = 'sms:$cleanPhone?body=${Uri.encodeComponent(message)}';
    
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      _sharePdfFile(context);
    }
  }

  Future<void> _launchEmail(BuildContext context, String email) async {
    final message = _getDetailedBillMessage();
    final url = 'mailto:$email?subject=Order Invoice - Smart Agro Shop&body=${Uri.encodeComponent(message)}';
    
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      _sharePdfFile(context);
    }
  }

  String _getSummaryText() {
    final total = (orderData['totalAmount'] as num? ?? 0).toDouble();
    return 'Hi, here is your bill from Smart Agro Shop.\nOrder ID: #$orderId\nTotal Amount: Rs. ${total.toStringAsFixed(0)}\nThank you for shopping with us!';
  }

  String _getDetailedBillMessage() {
    final items = (orderData['items'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    final total = (orderData['totalAmount'] as num? ?? 0).toDouble();
    final isTa = LocalizationService.isTamil;
    final customerName = customerData?['name'] ?? orderData['customerName'] ?? (isTa ? 'நேரடி வாடிக்கையாளர்' : 'Walk-in Customer');

    StringBuffer buffer = StringBuffer();
    buffer.writeln(isTa ? "*ஸ்மார்ட் அக்ரோ ஷாப்*" : "*SMART AGRO SHOP*");
    buffer.writeln(isTa ? "பில் எண்: #$orderId" : "Bill No: #$orderId");
    buffer.writeln("--------------------------");
    buffer.writeln("${isTa ? "வாடிக்கையாளர்" : "Customer"}: $customerName");
    buffer.writeln("--------------------------");
    
    for (final item in items) {
      final name = LocalizationService.pickTaEn(item['name_ta'], item['name_en']);
      final qty = item['quantity'] ?? 1;
      final price = (item['price'] ?? 0).toDouble();
      
      buffer.writeln("${isTa ? "பொருள்" : "Item"}: $name");
      buffer.writeln("${isTa ? "அளவு" : "Qty"}: $qty  x  ₹${price.toStringAsFixed(0)}");
      buffer.writeln("${isTa ? "மொத்தம்" : "Total"}: ₹${(price * qty).toStringAsFixed(0)}");
      buffer.writeln("---");
    }
    
    buffer.writeln("--------------------------");
    buffer.writeln("${isTa ? "மொத்த தொகை" : "Grand Total"}: ₹${total.toStringAsFixed(0)}");
    buffer.writeln("--------------------------");
    buffer.writeln(isTa ? "நன்றி! மீண்டும் வருக!" : "Thank you! Visit again!");
    
    return buffer.toString();
  }
}
