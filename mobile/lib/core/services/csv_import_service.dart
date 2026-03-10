import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:string_similarity/string_similarity.dart';

class ImportRow {
  final Map<String, dynamic> rawData;
  final String rawName;
  final double rawPrice;
  final int rawStock;
  
  bool isNewProduct;
  String? existingDocId;
  int? existingStock;
  double? existingPrice;
  String? error;

  ImportRow({
    required this.rawData,
    required this.rawName,
    required this.rawPrice,
    required this.rawStock,
    this.isNewProduct = true,
  });
}

class CsvImportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Header variations to support real-world supplier bills
  final List<String> _nameHeaders = ['name_en', 'itemname', 'item', 'product', 'name', 'productname'];
  final List<String> _priceHeaders = ['price', 'wholesaleprice', 'rate', 'mrp', 'cost'];
  final List<String> _stockHeaders = ['stock', 'qty', 'quantity', 'amount'];
  final List<String> _unitHeaders = ['unit_en', 'unit', 'size'];
  final List<String> _categoryHeaders = ['category_en', 'category', 'type', 'categoryid'];

  Future<List<ImportRow>> parseAndMatchCsv(String csvString) async {
    // 1. Parse CSV
    final List<List<dynamic>> rows = CsvDecoder(
      fieldDelimiter: null, 
      escapeCharacter: '"',
      dynamicTyping: true,
    ).convert(csvString);

    if (rows.isEmpty || rows.length < 2) {
      throw Exception('CSV file is empty or missing headers');
    }

    // 2. Map Headers
    final List<String> rawHeaders = rows.first.map((e) => e.toString().trim()).toList();
    final Map<String, int> headerIndices = _mapHeaders(rawHeaders);

    if (!headerIndices.containsKey('name') || !headerIndices.containsKey('stock')) {
      throw Exception('CSV must contain at least a Name and Stock/Quantity column.');
    }

    // 3. Fetch existing products from Firestore
    final QuerySnapshot existingProductsSnap = await _firestore.collection('products').get();
    final List<QueryDocumentSnapshot> existingProducts = existingProductsSnap.docs;

    // 4. Process Rows
    final List<ImportRow> resultRows = [];

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty || row.join('').trim().isEmpty) {
        continue; // Skip empty rows
      }

      // Extract required core fields
      final nameIndex = headerIndices['name']!;
      final stockIndex = headerIndices['stock']!;
      final priceIndex = headerIndices['price']; // Price might be missing

      final String rawName = nameIndex < row.length ? row[nameIndex].toString().trim() : '';
      final String rawStockStr = stockIndex < row.length ? row[stockIndex].toString().trim() : '0';
      final String rawPriceStr = (priceIndex != null && priceIndex < row.length) ? row[priceIndex].toString().trim() : '0';

      if (rawName.isEmpty) {
        continue; // Skip if no name
      }

      double price = double.tryParse(rawPriceStr) ?? 0.0;
      int stock = int.tryParse(rawStockStr.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0; // Strip non-numeric from stock

      // Extract all other dynamically matched mapped fields
      final Map<String, dynamic> rowData = {};
      for (int c = 0; c < rawHeaders.length; c++) {
        if (c < row.length) {
          final val = row[c];
          if (val != null && val.toString().trim().isNotEmpty) {
             rowData[rawHeaders[c]] = val;
          }
        }
      }

      final importRow = ImportRow(
        rawData: rowData,
        rawName: rawName,
        rawPrice: price,
        rawStock: stock,
      );

      // Validate
      if (stock <= 0) {
        importRow.error = 'Invalid or zero stock';
      }

      // 5. Match Product
      _matchProduct(importRow, existingProducts);
      
      resultRows.add(importRow);
    }

    return resultRows;
  }

  Map<String, int> _mapHeaders(List<String> rawHeaders) {
    final Map<String, int> mapped = {};
    for (int i = 0; i < rawHeaders.length; i++) {
      final headerStr = rawHeaders[i].toLowerCase().replaceAll(' ', '');
      
      if (_nameHeaders.any((h) => headerStr.contains(h))) {
        mapped['name'] = i;
      } else if (_priceHeaders.any((h) => headerStr.contains(h))) {
        mapped['price'] = i;
      } else if (_stockHeaders.any((h) => headerStr.contains(h))) {
        mapped['stock'] = i;
      } else if (_unitHeaders.any((h) => headerStr.contains(h))) {
        mapped['unit'] = i;
      } else if (_categoryHeaders.any((h) => headerStr.contains(h))) {
        mapped['category'] = i;
      }
    }
    return mapped;
  }

  void _matchProduct(ImportRow importRow, List<QueryDocumentSnapshot> existingProducts) {
    double bestMatchScore = 0.0;
    QueryDocumentSnapshot? bestMatchDoc;

    final targetName = importRow.rawName.toLowerCase();

    for (final doc in existingProducts) {
      final data = doc.data() as Map<String, dynamic>;
      final dbName = (data['name_en'] as String? ?? '').toLowerCase();
      
      if (dbName.isEmpty) {
        continue;
      }

      // Exact match
      if (dbName == targetName) {
        bestMatchDoc = doc;
        bestMatchScore = 1.0;
        break;
      }

      // Fuzzy match
      final score = StringSimilarity.compareTwoStrings(targetName, dbName);
      if (score > bestMatchScore && score > 0.75) { // 75% similarity threshold
        bestMatchScore = score;
        bestMatchDoc = doc;
      }
    }

    if (bestMatchDoc != null) {
      final data = bestMatchDoc.data() as Map<String, dynamic>;
      importRow.isNewProduct = false;
      importRow.existingDocId = bestMatchDoc.id;
      importRow.existingStock = (data['stock'] as num?)?.toInt() ?? 0;
      importRow.existingPrice = (data['price'] as num?)?.toDouble() ?? 0.0;
    }
  }

  Future<void> commitImport(List<ImportRow> rowsToImport) async {
    final WriteBatch batch = _firestore.batch();
    final collection = _firestore.collection('products');

    for (final row in rowsToImport) {
      if (row.error != null) {
        continue;
      }

      if (row.isNewProduct) {
        // Create new product skeleton
        final docRef = collection.doc();
        
        final newProductData = <String, dynamic>{
          'name_en': row.rawName,
          'price': row.rawPrice,
          'stock': row.rawStock,
          'categoryId': _extractField(row.rawData, _categoryHeaders, defaultVal: 'others'),
          'unit_en': _extractField(row.rawData, _unitHeaders, defaultVal: ''),
          'shopId': 'default_shop',
          'createdAt': FieldValue.serverTimestamp(),
          'needsManualUpdate': true, // The flag!
          // Add empty fallbacks for required string fields
          'name_ta': '',
          'unit_ta': '',
          'description_ta': '',
          'description_en': '',
          'dosage_ta': '',
          'dosage_en': '',
          'safety_ta': '',
          'safety_en': '',
          'imageUrl': '',
          'isOfferActive': false,
        };

        // Inject any other raw data matching our exact DB keys dynamically
        final validKeys = ['name_ta', 'unit_ta', 'description_ta', 'description_en', 'dosage_ta', 'dosage_en', 'safety_ta', 'safety_en'];
        row.rawData.forEach((key, value) {
           if (validKeys.contains(key)) {
             newProductData[key] = value.toString();
           }
        });

        batch.set(docRef, newProductData);
      } else {
        // Update existing product
        final docRef = collection.doc(row.existingDocId);
        
        final newStock = (row.existingStock ?? 0) + row.rawStock;
        
        final updateData = <String, dynamic>{
          'stock': newStock,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        // Update price if provided in CSV
        if (row.rawPrice > 0) {
           updateData['price'] = row.rawPrice;
        }

        // Dynamically update any other fields from the CSV that exist
        final validKeys = ['name_ta', 'unit_ta', 'unit_en', 'description_ta', 'description_en', 'dosage_ta', 'dosage_en', 'safety_ta', 'safety_en'];
        row.rawData.forEach((key, value) {
           if (validKeys.contains(key)) {
             updateData[key] = value.toString();
           }
        });

        // Add category if explicitly supplied
        final String? category = _extractField(row.rawData, _categoryHeaders);
        if (category != null && category.isNotEmpty) {
           updateData['categoryId'] = category;
        }

        batch.update(docRef, updateData);
      }
    }

    await batch.commit();
  }

  String? _extractField(Map<String, dynamic> rawData, List<String> headerPatterns, {String? defaultVal}) {
    for (final entry in rawData.entries) {
      final keyClean = entry.key.toLowerCase().replaceAll(' ', '');
      if (headerPatterns.any((h) => keyClean.contains(h))) {
        return entry.value.toString().trim();
      }
    }
    return defaultVal;
  }
}
