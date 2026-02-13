import 'dart:io';
import 'dart:math';

class DiagnosisResult {
  final String diseaseNameTa;
  final String diseaseNameEn;
  final double confidence;
  final String descriptionTa;
  final String descriptionEn;
  final String solutionTa;
  final String solutionEn;
  final String severity; // low, medium, high
  final List<String> recommendedProductIds; // Matches dummy product IDs

  DiagnosisResult({
    required this.diseaseNameTa,
    required this.diseaseNameEn,
    required this.confidence,
    required this.descriptionTa,
    required this.descriptionEn,
    required this.solutionTa,
    required this.solutionEn,
    required this.severity,
    required this.recommendedProductIds,
  });
}

class AIService {
  // Simulate network delay and analysis
  Future<DiagnosisResult> analyzeImage(File image) async {
    await Future.delayed(const Duration(seconds: 3)); // Fake processing time

    // Randomize result to show different flows (Demo purpose)
    final random = Random();
    final isDisease = true; // For demo, always find something 80% of time

    if (isDisease) {
      return DiagnosisResult(
        diseaseNameEn: "Rice Blast",
        diseaseNameTa: "நெல் குலை நோய்",
        confidence: 0.85 + (random.nextDouble() * 0.14), // 85-99%
        descriptionEn: "Rice blast is a fungal disease that can affect all above-ground parts of the rice plant. It causes spindle-shaped lesions on leaves.",
        descriptionTa: "நெல் குலை நோய் என்பது நெல் பயிரின் அனைத்து மேல் பகுதிகளையும் பாதிக்கக்கூடிய ஒரு பூஞ்சை நோயாகும். இது இலைகளில் கதிர் வடிவ புண்களை ஏற்படுத்துகிறது.",
        solutionEn: "Use fungicides like Tricyclazole or Isoprothiolane. Avoid excessive nitrogen fertilizer.",
        solutionTa: "ட்ரைசைக்ளாசோல் அல்லது ஐசோப்ரோதியோலேன் போன்ற பூஞ்சைக் கொல்லிகளைப் பயன்படுத்தவும். அதிகப்படியான நைட்ரஜன் உரத்தைத் தவிர்க்கவும்.",
        severity: "high",
        recommendedProductIds: ["prod_fungicide_01", "prod_neem_oil"], // These need to match real product IDs ideally, or we mock product display
      );
    } else {
       // Should default to Healthy, but for demo we focus on disease
       return DiagnosisResult(
        diseaseNameEn: "Healthy Crop",
        diseaseNameTa: "ஆரோக்கியமான பயிர்",
        confidence: 0.98,
        descriptionEn: "Your crop looks healthy! Keep maintaining good irrigation.",
        descriptionTa: "உங்கள் பயிர் ஆரோக்கியமாக இருக்கிறது! நல்ல நீர்ப்பாசனத்தைப் பராமரிக்கவும்.",
        solutionEn: "Add Organic Bio-Fertilizer to boost yield.",
        solutionTa: "மகசூலை அதிகரிக்க இயற்கை உயிர் உரத்தைச் சேர்க்கவும்.",
        severity: "low",
        recommendedProductIds: ["prod_fertilizer_01"],
       );
    }
  }
}
