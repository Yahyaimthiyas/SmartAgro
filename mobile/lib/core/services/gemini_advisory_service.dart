import 'dart:convert';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';

class GeminiAdvisoryService {
  // Provided API Key for the AI Plant Doctor feature
  static const String _apiKey = 'AIzaSyCxaglskTrjSte_qjQ_jmRCpsb0LrZ0zGA';
  static const String _modelName = 'gemini-flash-latest';

  /// Analyzes the plant image using Gemini Flash and returns a structured diagnosis map.
  /// It takes a list of available [shopProducts] to provide highly accurate, real-world recommendations.
  static Future<Map<String, dynamic>> analyzePlantImage(XFile imageFile, List<Map<String, dynamic>> shopProducts) async {
    try {
      final model = GenerativeModel(
        model: _modelName,
        apiKey: _apiKey,
      );

      // Build the catalog string to feed to the AI concisely
      String catalogString = shopProducts.map((p) => "[ID: ${p['id']} | Name: ${p['name']}]").join(", ");

      final bytes = await imageFile.readAsBytes();
      final prompt = '''
You are an expert plant pathologist. Analyze the image for diseases/pests. 
If healthy or not a plant, say so. 

Available Catalog IDs: $catalogString

Output raw JSON:
{
  "isPlant": bool,
  "isHealthy": bool,
  "diseaseName": "string",
  "cause": "short string",
  "remedySuggestion": "Short treatment info. Mention recommended product names from catalog.",
  "recommendedProductIds": ["id1", "id2"], // 1-3 BEST IDs from catalog. If no cure, pick health boosters from catalog.
  "dosage": "string",
  "applicationMethod": "concise instructions",
  "bestTime": "string",
  "safetyPrecautions": "string",
  "expertTips": "string"
}
''';

      int maxRetries = 3;
      int retryCount = 0;
      
      while (retryCount < maxRetries) {
        try {
          final content = [
            Content.multi([
              TextPart(prompt),
              DataPart('image/jpeg', bytes),
            ])
          ];

          final response = await model.generateContent(content);
          String? responseText = response.text;

          if (responseText == null || responseText.isEmpty) {
            throw Exception("Failed to get a response from the AI.");
          }

          // Clean up the response in case Gemini includes markdown codes
          responseText = responseText.replaceAll('```json', '').replaceAll('```', '').trim();
          
          try {
            return jsonDecode(responseText);
          } catch (jsonErr) {
            print("JSON Decode Error: $jsonErr. Response was: $responseText");
            throw Exception("The AI returned an invalid format. Please try again.");
          }
        } catch (e) {
          retryCount++;
          String errorMsg = e.toString();
          
          // Only retry on 503/Busy errors
          if ((errorMsg.contains('503') || errorMsg.contains('UNAVAILABLE')) && retryCount < maxRetries) {
            print("AI Busy (503), retrying ($retryCount/$maxRetries)...");
            await Future.delayed(Duration(seconds: 1 * retryCount));
            continue;
          }
          
          print("Gemini Analysis Error: $e");
          
          if (errorMsg.contains('429') || errorMsg.contains('quota')) {
            throw Exception("API Limit Exceeded: The AI Doctor has reached its daily limit. Please try again tomorrow.");
          } else if (errorMsg.contains('503') || errorMsg.contains('UNAVAILABLE')) {
            throw Exception("AI Server Busy: Google's AI servers are currently under high demand. Please try again in a moment.");
          } else if (errorMsg.contains('403') || errorMsg.contains('API_KEY_INVALID')) {
            throw Exception("Invalid API Key: The AI service is not configured correctly. Please check your Gemini API key.");
          } else if (errorMsg.contains('SocketException')) {
            throw Exception("No Internet: Please check your connection and try again.");
          }
          
          throw Exception("Analysis failed: ${e.toString().replaceAll('Exception: ', '')}");
        }
      }
      throw Exception("Maximum retries reached. AI is currently unavailable.");
    } catch (e) {
      rethrow;
    }
  }
}
