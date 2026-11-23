import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/quotation.dart';

class BillingService {
  static final BillingService instance = BillingService._init();
  BillingService._init();

  // Placeholder Base Office Coordinates (Wayanad Central)
  static const double baseLat = 11.605;
  static const double baseLng = 76.083;

  double calculateDistanceSurcharge(double siteLat, double siteLng) {
    double distanceInMeters = Geolocator.distanceBetween(
      baseLat, baseLng,
      siteLat, siteLng,
    );
    
    // If distance > 15km (15000 meters), add ₹100
    if (distanceInMeters > 15000) {
      return 100.0;
    }
    return 0.0;
  }

  // Helper to update quotation totals with surcharge
  Quotation applyDistanceSurcharge(Quotation quotation) {
    if (quotation.latitude != null && quotation.longitude != null) {
      final surcharge = calculateDistanceSurcharge(quotation.latitude!, quotation.longitude!);
      
      // If a surcharge applies, log it for tracking
      if (surcharge > 0) {
        debugPrint('Distance Surcharge of ₹$surcharge applied to ${quotation.unitNumber}');
      }
      return quotation.copyWith(surcharge: surcharge);
    }
    return quotation;
  }
}
