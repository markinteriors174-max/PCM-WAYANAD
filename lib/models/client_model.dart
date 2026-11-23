class Client {
  final String id;
  final String clientName;
  final String phoneNumber;
  final String siteLocation;
  final String unitNumber;
  final String clientSelfie;
  final double totalContractAmount;
  final double advanceReceived;
  final double totalLaborCost;
  final double? latitude;
  final double? longitude;
  final String status;
  final String assignedWorkers;
  final DateTime createdAt;

  // ── T2: Client Hub Extensions ─────────────────────────────────
  final String? email;          // for automated PDF delivery
  final String customerType;    // 'Direct Customer' | 'Builder' | 'Architect'
  final bool gstEnabled;        // GSTIN toggle
  final String? gstin;          // 15-char GSTIN
  final DateTime? nextPaymentDueDate;
  final double discount;        // structural discount on final bill
  final String projectType;     // 'House' ('വീട്') | 'Commercial' | 'Renovation' | 'Villa'
  // ─────────────────────────────────────────────────────────────

  Client({
    required this.id,
    required this.clientName,
    required this.phoneNumber,
    required this.siteLocation,
    required this.unitNumber,
    required this.clientSelfie,
    required this.totalContractAmount,
    required this.advanceReceived,
    required this.totalLaborCost,
    this.latitude,
    this.longitude,
    this.status = 'Pending',
    this.assignedWorkers = '',
    required this.createdAt,
    this.email,
    this.customerType = 'Direct Customer',
    this.gstEnabled = false,
    this.gstin,
    this.nextPaymentDueDate,
    this.discount = 0.0,
    this.projectType = 'House',
  });

  double get balanceDue => totalContractAmount - advanceReceived - discount;

  Map<String, dynamic> toMap() {
    return {
      'client_name': clientName,
      'phone_number': phoneNumber,
      'site_location': siteLocation,
      'unitNumber': _cleanUnitNumber(unitNumber),
      'client_selfie': clientSelfie,
      'total_contract_amount': totalContractAmount,
      'advance_received': advanceReceived,
      'total_labor_cost': totalLaborCost,
      'balance_due': balanceDue,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'assigned_workers': assignedWorkers,
      'createdAt': createdAt.toIso8601String(),
      // T2 extension fields (stored in client_extensions table, mirrored here)
      'email': email,
      'customer_type': customerType,
      'gstin_enabled': gstEnabled,
      'gstin': gstin,
      'next_payment_due_date': nextPaymentDueDate?.toIso8601String().split('T').first,
      'discount_amount': discount,
      'projectType': projectType,
      'category': projectType,
      'siteType': projectType,
    };
  }

  static String _cleanUnitNumber(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    var clean = raw.trim();
    while (clean.startsWith('#')) {
      clean = clean.substring(1).trim();
    }
    clean = clean.replaceAll(RegExp(r'^(pcm-ms-|pcm-|unit-|unit)\s*', caseSensitive: false), '').trim();
    clean = clean.replaceAll(RegExp(r'^(pcm-ms-|pcm-|unit-|unit)\s*', caseSensitive: false), '').trim();
    clean = clean.replaceAll(RegExp(r'UNIT-?', caseSensitive: false), '').trim();
    if (clean.isEmpty) return '';
    return '# PCM-$clean';
  }

  static DateTime _parseDate(dynamic val) {
    if (val == null) return DateTime.now();
    if (val is DateTime) return val;
    if (val is num) return DateTime.fromMillisecondsSinceEpoch(val.toInt());
    if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
    try {
      return (val as dynamic).toDate() as DateTime;
    } catch (_) {
      return DateTime.now();
    }
  }

  factory Client.fromMap(Map<String, dynamic> data, String id) {
    var rawName = (data['client_name'] ?? data['clientName'] ?? data['name'] ?? data['customer_name'] ?? data['customerName'] ?? data['pcm_portal_user'])?.toString().trim() ?? '';
    var rawPhone = (data['phone_number'] ?? data['phoneNumber'] ?? data['clientPhone'] ?? data['phone'] ?? data['mobile'])?.toString().trim() ?? '';

    // Clean phone number so it stores only digits
    String cleanPhone = rawPhone.replaceAll(RegExp(r'[^\d+]'), '').trim();
    String extraNameFromPhone = rawPhone.replaceAll(RegExp(r'[\d+\s\-]'), '').trim();

    if (rawName.isEmpty || rawName.toUpperCase() == 'SITE DRAFT' || rawName == 'PCM SITE') {
      if (extraNameFromPhone.isNotEmpty) {
        rawName = extraNameFromPhone;
      } else {
        rawName = 'PCM SITE';
      }
    }

    final rawLoc = data['site_location'] ?? data['siteLocation'] ?? data['clientLocation'] ?? data['location'] ?? data['locationFolder'] ?? data['place'];
    final loc = rawLoc?.toString() ?? '';

    final rawUnit = data['projectId'] ?? data['rawProjectId'] ?? data['unitNumber'] ?? data['unit_number'] ?? data['unit'] ?? data['site_id'] ?? data['siteId'] ?? id;

    final rawType = (data['projectType'] ?? data['project_type'] ?? data['category'] ?? data['siteType'] ?? data['site_type'] ?? data['buildingType'] ?? data['building_type'] ?? data['type'])?.toString().trim();

    return Client(
      id: id,
      clientName: rawName,
      phoneNumber: cleanPhone,
      siteLocation: loc,
      unitNumber: _cleanUnitNumber(rawUnit.toString()),
      clientSelfie: data['client_selfie'] ?? data['selfieUrl'] ?? '',
      totalContractAmount: (data['total_contract_amount'] ?? data['totalContractAmount'] ?? data['total_amount'] ?? data['totalAmount'] ?? 0.0).toDouble(),
      advanceReceived: (data['advance_received'] ?? data['advanceReceived'] ?? data['paid_amount'] ?? data['paidAmount'] ?? 0.0).toDouble(),
      totalLaborCost: (data['total_labor_cost'] ?? data['totalLaborCost'] ?? 0.0).toDouble(),
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      status: data['status'] ?? 'Pending',
      assignedWorkers: data['assigned_workers'] ?? data['assignedWorkers'] ?? '',
      createdAt: _parseDate(data['createdAt'] ?? data['created_at'] ?? data['timestamp'] ?? data['date']),
      // T2 extension fields
      email: data['email'] as String?,
      customerType: data['customer_type'] as String? ?? 'Direct Customer',
      gstEnabled: data['gstin_enabled'] == true || data['gstEnabled'] == true,
      gstin: data['gstin'] as String?,
      nextPaymentDueDate: data['next_payment_due_date'] != null
          ? DateTime.tryParse(data['next_payment_due_date'] as String)
          : null,
      discount: (data['discount_amount'] ?? data['discount'] as num?)?.toDouble() ?? 0.0,
      projectType: (rawType != null && rawType.isNotEmpty) ? rawType : 'House',
    );
  }

  Client copyWith({
    String? id,
    String? clientName,
    String? phoneNumber,
    String? siteLocation,
    String? unitNumber,
    String? clientSelfie,
    double? totalContractAmount,
    double? advanceReceived,
    double? totalLaborCost,
    double? latitude,
    double? longitude,
    String? status,
    String? assignedWorkers,
    DateTime? createdAt,
    String? email,
    String? customerType,
    bool? gstEnabled,
    String? gstin,
    DateTime? nextPaymentDueDate,
    double? discount,
    String? projectType,
  }) {
    return Client(
      id: id ?? this.id,
      clientName: clientName ?? this.clientName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      siteLocation: siteLocation ?? this.siteLocation,
      unitNumber: unitNumber ?? this.unitNumber,
      clientSelfie: clientSelfie ?? this.clientSelfie,
      totalContractAmount: totalContractAmount ?? this.totalContractAmount,
      advanceReceived: advanceReceived ?? this.advanceReceived,
      totalLaborCost: totalLaborCost ?? this.totalLaborCost,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      assignedWorkers: assignedWorkers ?? this.assignedWorkers,
      createdAt: createdAt ?? this.createdAt,
      email: email ?? this.email,
      customerType: customerType ?? this.customerType,
      gstEnabled: gstEnabled ?? this.gstEnabled,
      gstin: gstin ?? this.gstin,
      nextPaymentDueDate: nextPaymentDueDate ?? this.nextPaymentDueDate,
      discount: discount ?? this.discount,
      projectType: projectType ?? this.projectType,
    );
  }
}
