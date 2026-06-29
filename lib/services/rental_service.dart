import '../models/rental_model.dart';
import 'package:flutter/foundation.dart';

// Firebase Firestore scrubbed to prevent [core/no-app] crashes.
// Rental data management will be migrated to local SQLite if requested.

class RentalService {
  static final RentalService instance = RentalService._init();
  RentalService._init();

  Future<void> addRental(RentalRecord rental) async {
    debugPrint('RentalService: Local Mode (Stub)');
  }

  Future<void> updateRentalStatus(String id, String status) async {
    debugPrint('RentalService: Local Mode (Stub)');
  }

  Future<void> deleteRental(String id) async {
    debugPrint('RentalService: Local Mode (Stub)');
  }

  Stream<List<RentalRecord>> getRentals() {
    return Stream.value([]);
  }

  Stream<List<RentalRecord>> getRentalsBySite(String siteName) {
    return Stream.value([]);
  }
}
