// Firebase Firestore scrubbed to prevent [core/no-app] crashes.
// Models updated to use fromMap instead of fromFirestore.

class Worker {
  final String id;
  final String name;
  final String place;
  final String phoneNumber;
  final double dailyRate;
  final String category; // Skilled, Semi-Skilled, Helper
  final bool isActive;
  final double rating;
  final double? homeLat;
  final double? homeLng;

  Worker({
    required this.id,
    required this.name,
    required this.place,
    required this.phoneNumber,
    this.dailyRate = 0.0,
    this.category = 'Skilled',
    this.isActive = true,
    this.rating = 5.0,
    this.homeLat,
    this.homeLng,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'place': place,
      'phoneNumber': phoneNumber,
      'dailyRate': dailyRate,
      'category': category,
      'isActive': isActive,
      'rating': rating,
      'homeLat': homeLat,
      'homeLng': homeLng,
    };
  }

  factory Worker.fromMap(Map<String, dynamic> data, String id) {
    return Worker(
      id: id,
      name: data['name'] ?? '',
      place: data['place'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      dailyRate: (data['dailyRate'] ?? 0.0).toDouble(),
      category: data['category'] ?? 'Skilled',
      isActive: data['isActive'] ?? true,
      rating: (data['rating'] ?? 5.0).toDouble(),
      homeLat: (data['homeLat'] as num?)?.toDouble(),
      homeLng: (data['homeLng'] as num?)?.toDouble(),
    );
  }

  Worker copyWith({
    String? name,
    String? place,
    String? phoneNumber,
    double? dailyRate,
    String? category,
    bool? isActive,
    double? rating,
    double? homeLat,
    double? homeLng,
  }) {
    return Worker(
      id: id,
      name: name ?? this.name,
      place: place ?? this.place,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      dailyRate: dailyRate ?? this.dailyRate,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      rating: rating ?? this.rating,
      homeLat: homeLat ?? this.homeLat,
      homeLng: homeLng ?? this.homeLng,
    );
  }
}

class AdvancePayment {
  final String id;
  final String workerId;
  final double amount;
  final DateTime date;
  final String note;

  AdvancePayment({
    required this.id,
    required this.workerId,
    required this.amount,
    required this.date,
    this.note = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'workerId': workerId,
      'amount': amount,
      'date': date.toIso8601String(),
      'note': note,
    };
  }

  factory AdvancePayment.fromMap(Map<String, dynamic> data, String id) {
    return AdvancePayment(
      id: id,
      workerId: data['workerId'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      date: DateTime.parse(data['date'] ?? DateTime.now().toIso8601String()),
      note: data['note'] ?? '',
    );
  }
}

enum WageMode { daily, contract, hourly }
enum ShiftType { morning, afternoon, evening, night }
enum LaborStatus { active, completed }

class LaborEntry {
  final String id;
  final String workerId;
  final String workerName;
  final String siteName;
  final WageMode mode;
  final ShiftType shiftType;
  final LaborStatus status;
  final double rate;
  final DateTime date;
  
  // Punching Timestamps
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final int totalDurationMinutes;
  
  // Financials
  final double totalWage;
  final double paidAmount;
  final double balance;
  
  // Geolocation
  final double? checkInLat;
  final double? checkInLng;
  final double travelAllowance;
  final double distanceFromHome;

  LaborEntry({
    required this.id,
    required this.workerId,
    required this.workerName,
    required this.siteName,
    required this.mode,
    required this.shiftType,
    required this.status,
    required this.rate,
    required this.date,
    required this.checkInTime,
    this.checkOutTime,
    this.totalDurationMinutes = 0,
    required this.totalWage,
    required this.paidAmount,
    required this.balance,
    this.checkInLat,
    this.checkInLng,
    this.travelAllowance = 0,
    this.distanceFromHome = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'workerId': workerId,
      'workerName': workerName,
      'siteName': siteName,
      'mode': mode.name,
      'shiftType': shiftType.name,
      'status': status.name,
      'rate': rate,
      'date': date.toIso8601String(),
      'checkInTime': checkInTime.toIso8601String(),
      'checkOutTime': checkOutTime?.toIso8601String(),
      'totalDurationMinutes': totalDurationMinutes,
      'totalWage': totalWage,
      'paidAmount': paidAmount,
      'balance': balance,
      'checkInLat': checkInLat,
      'checkInLng': checkInLng,
      'travelAllowance': travelAllowance,
      'distanceFromHome': distanceFromHome,
    };
  }

  factory LaborEntry.fromMap(Map<String, dynamic> data, String id) {
    return LaborEntry(
      id: id,
      workerId: data['workerId'] ?? '',
      workerName: data['workerName'] ?? '',
      siteName: data['siteName'] ?? '',
      mode: WageMode.values.firstWhere((e) => e.name == data['mode'], orElse: () => WageMode.daily),
      shiftType: ShiftType.values.firstWhere((e) => e.name == data['shiftType'], orElse: () => ShiftType.morning),
      status: LaborStatus.values.firstWhere((e) => e.name == data['status'], orElse: () => LaborStatus.completed),
      rate: (data['rate'] ?? 0).toDouble(),
      date: DateTime.parse(data['date']),
      checkInTime: DateTime.parse(data['checkInTime']),
      checkOutTime: data['checkOutTime'] != null ? DateTime.parse(data['checkOutTime']) : null,
      totalDurationMinutes: data['totalDurationMinutes'] ?? 0,
      totalWage: (data['totalWage'] ?? 0).toDouble(),
      paidAmount: (data['paidAmount'] ?? 0).toDouble(),
      balance: (data['balance'] ?? 0).toDouble(),
      checkInLat: (data['checkInLat'] as num?)?.toDouble(),
      checkInLng: (data['checkInLng'] as num?)?.toDouble(),
      travelAllowance: (data['travelAllowance'] ?? 0.0).toDouble(),
      distanceFromHome: (data['distanceFromHome'] ?? 0.0).toDouble(),
    );
  }
}

class SQLiteWorker {
  final int id;
  final String name;
  final double dailyWage;
  final double totalDays;
  final double totalPaid;
  final double? customTotalEarned;
  final double? customNetBalance;
  final String? customStatusText;

  SQLiteWorker({
    required this.id,
    required this.name,
    required this.dailyWage,
    required this.totalDays,
    required this.totalPaid,
    this.customTotalEarned,
    this.customNetBalance,
    this.customStatusText,
  });

  double get totalEarned => customTotalEarned ?? (totalDays * dailyWage);
  double get netBalance => customNetBalance ?? (totalEarned - totalPaid);

  String get statusText {
    if (customStatusText != null) return customStatusText!;
    if (netBalance > 0) return 'Amount to Pay';
    if (netBalance < 0) return 'Amount to Receive';
    return 'Fully Settled';
  }

  factory SQLiteWorker.fromMap(Map<String, dynamic> map) {
    return SQLiteWorker(
      id: map['id'] as int,
      name: map['worker_name'] ?? '',
      dailyWage: (map['daily_wage'] ?? 0.0).toDouble(),
      totalDays: (map['total_days'] ?? 0.0).toDouble(),
      totalPaid: (map['total_paid'] ?? 0.0).toDouble(),
      customTotalEarned: map['total_earned'] != null ? (map['total_earned'] as num).toDouble() : null,
      customNetBalance: map['net_balance'] != null ? (map['net_balance'] as num).toDouble() : null,
      customStatusText: map['status_label'] as String?,
    );
  }
}
