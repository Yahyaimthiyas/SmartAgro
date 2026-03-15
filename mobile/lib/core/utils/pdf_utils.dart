import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

class PdfInvoiceApi {
  static Future<Uint8List> generate(Map<String, dynamic> orderData, String orderId) async {
    final pdf = pw.Document();

    final items = (orderData['items'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    final total = (orderData['totalAmount'] as num? ?? 0).toDouble();
    final ts = orderData['createdAt'] as dynamic;
    DateTime date = DateTime.now();
    if (ts is dynamic && ts.runtimeType.toString() == 'Timestamp') {
      date = ts.toDate();
    }
    
    final formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(date);
    final customerName = orderData['customerName'] ?? 'Walk-in Customer';
    final customerPhone = orderData['customerPhone'] ?? '';

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text('SMART AGRO SHOP', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Agro-Inputs & Services', style: pw.TextStyle(fontSize: 12)),
                  pw.SizedBox(height: 20),
                ],
              ),
            ),
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Invoice No: #$orderId', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('Date: $formattedDate'),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Customer:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(customerName),
                    pw.Text(customerPhone),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 30),
            pw.Table(
              border: pw.TableBorder.all(),
              children: [
                pw.TableRow(
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Item', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Qty', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center)),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Price', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
                  ],
                ),
                ...items.map((item) {
                  final price = (item['price'] as num? ?? 0).toDouble();
                  final qty = (item['quantity'] as num? ?? 0).toInt();
                  return pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(item['name_en'] ?? '')),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('$qty', textAlign: pw.TextAlign.center)),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Rs. ${price.toStringAsFixed(2)}', textAlign: pw.TextAlign.right)),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Rs. ${(price * qty).toStringAsFixed(2)}', textAlign: pw.TextAlign.right)),
                    ],
                  );
                }).toList(),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Grand Total:', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Rs. ${total.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ],
            ),
            pw.Spacer(),
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text('Thank you! Visit again!', style: pw.TextStyle(fontStyle: pw.FontStyle.italic)),
                  pw.Text('Computer Generated Invoice'),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return pdf.save();
  }
}
