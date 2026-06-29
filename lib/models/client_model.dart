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
  });

  double get balanceDue => totalContractAmount - advanceReceived - discount;

  Map<String, dynamic> toMap() {
    return {
      'client_name': clientName,
      'phone_number': phoneNumber,
      'site_location': siteLocation,
      'unitNumber': unitNumber,
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
    };
  }

  factory Client.fromMap(Map<String, dynamic> data, String id) {
    return Client(
      id: id,
      clientName: data['client_name'] ?? data['name'] ?? '',
      phoneNumber: data['phone_number'] ?? data['phone'] ?? '',
      siteLocation: data['site_location'] ?? data['location'] ?? '',
      unitNumber: data['unitNumber'] ?? '',
      clientSelfie: data['client_selfie'] ?? data['selfieUrl'] ?? '',
      totalContractAmount: (data['total_contract_amount'] ?? data['totalAmount'] ?? 0.0).toDouble(),
      advanceReceived: (data['advance_received'] ?? data['paidAmount'] ?? 0.0).toDouble(),
      totalLaborCost: (data['total_labor_cost'] ?? 0.0).toDouble(),
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      status: data['status'] ?? 'Pending',
      assignedWorkers: data['assigned_workers'] ?? '',
      createdAt: data['createdAt'] != null
          ? DateTime.tryParse(data['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      // T2 extension fields
      email: data['email'] as String?,
      customerType: data['customer_type'] as String? ?? 'Direct Customer',
      gstEnabled: data['gstin_enabled'] == true,
      gstin: data['gstin'] as String?,
      nextPaymentDueDate: data['next_payment_due_date'] != null
          ? DateTime.tryParse(data['next_payment_due_date'] as String)
          : null,
      discount: (data['discount_amount'] as num?)?.toDouble() ?? 0.0,
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
    );
  }
}
