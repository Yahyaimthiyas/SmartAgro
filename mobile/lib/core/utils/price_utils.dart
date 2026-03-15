import 'package:cloud_firestore/cloud_firestore.dart';

class PriceUtils {
  static double calculateFinalPrice(Map<String, dynamic> data) {
    final originalPrice = (data['price'] as num? ?? 0).toDouble();
    final isOfferActive = data['isOfferActive'] as bool? ?? false;
    final start = data['offerStart'] as Timestamp?;
    final end = data['offerEnd'] as Timestamp?;
    final now = DateTime.now();

    bool active = isOfferActive;
    if (active) {
      if (start != null && now.isBefore(start.toDate())) active = false;
      if (end != null && now.isAfter(end.toDate())) active = false;
    }

    if (!active) return originalPrice;

    final type = data['offerType'] as String? ?? 'percentage';
    final val = (data['offerValue'] as num? ?? 0).toDouble();

    if (type == 'percentage') {
      final discount = (originalPrice * val) / 100;
      return originalPrice - discount;
    } else {
      return val;
    }
  }

  static bool isOfferActuallyActive(Map<String, dynamic> data) {
    final isOfferActive = data['isOfferActive'] as bool? ?? false;
    if (!isOfferActive) return false;

    final start = data['offerStart'] as Timestamp?;
    final end = data['offerEnd'] as Timestamp?;
    final now = DateTime.now();

    if (start != null && now.isBefore(start.toDate())) return false;
    if (end != null && now.isAfter(end.toDate())) return false;

    return true;
  }
}
