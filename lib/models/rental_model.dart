// Firebase Firestore scrubbed to prevent [core/no-app] crashes.
// Models updated to use fromMap instead of fromFirestore.

class RentalRecord {
  final String id;
  final String itemName;
  final String siteName;
  final String? siteId; // Link to Quotation if available
  final DateTime startDate;
  final double dailyRate;
  final double quantity;
  final String status; // 'Out' or 'Returned'

  RentalRecord({
    required this.id,
    required this.itemName,
    required this.siteName,
    this.siteId,
    required this.startDate,
    required this.dailyRate,
    required this.quantity,
    this.status = 'Out',
  });

  // -- Automatic Calculations --

  int get totalDays {
    final now = DateTime.now();
    // Inclusive count: if started today, it's 1 day
    return now.difference(startDate).inDays + 1;
  }

  double get runningTotalCost {
    return totalDays * dailyRate * quantity;
  }

  Map<String, dynamic> toMap() {
    return {
      'itemName': itemName,
      'siteName': siteName,
      'siteId': siteId,
      'startDate': startDate.toIso8601String(),
      'dailyRate': dailyRate,
      'quantity': quantity,
      'status': status,
    };
  }

  factory RentalRecord.fromMap(Map<String, dynamic> data, String id) {
    return RentalRecord(
      id: id,
      itemName: data['itemName'] ?? '',
      siteName: data['siteName'] ?? '',
      siteId: data['siteId'],
      startDate: DateTime.parse(data['startDate']),
      dailyRate: (data['dailyRate'] as num?)?.toDouble() ?? 0.0,
      quantity: (data['quantity'] as num?)?.toDouble() ?? 1.0,
      status: data['status'] ?? 'Out',
    );
  }
}
