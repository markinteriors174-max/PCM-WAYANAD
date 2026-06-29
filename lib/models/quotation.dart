import 'rental_model.dart';

class Quotation {
  final int? id;
  final String unitNumber;
  final String clientName;
  final String clientPhone;
  final String clientLocation;
  final String date;
  final double totalAmount;
  final double paidAmount;
  final double balanceAmount;
  final List<QuotationItem> items;
  final List<MaterialAssignment> materials;
  final List<RentalRecord> rentals;
  final List<PaymentRecord> payments;
  
  // Geolocation & Billing
  final double? latitude;
  final double? longitude;
  final double surcharge;

  // Manual Adjustments
  final double manualAmount;
  final double manualWeight;
  final double advancePayment;
  final String? locationFolder;
  final bool includeWastage;
  final bool includeDigitalSignature;
  final bool includeBankDetails;
  final double? originalAmount;
  final String? revisionNote;
  
  // Global pricing settings
  final double globalMaterialCost;
  final double globalMargin;
  final double discount;

  // Project Progress & Approval status
  final String projectStatus;
  final String? approvalSignature;

  Quotation({
    this.id,
    required this.unitNumber,
    required this.clientName,
    required this.clientPhone,
    required this.clientLocation,
    required this.date,
    required this.totalAmount,
    required this.paidAmount,
    required this.balanceAmount,
    required this.items,
    this.materials = const [],
    this.rentals = const [],
    this.payments = const [],
    this.latitude,
    this.longitude,
    this.surcharge = 0,
    this.manualAmount = 0,
    this.manualWeight = 0,
    this.advancePayment = 0,
    this.locationFolder,
    this.includeWastage = false,
    this.includeDigitalSignature = false,
    this.includeBankDetails = true,
    this.originalAmount,
    this.revisionNote,
    this.globalMaterialCost = 0.0,
    this.globalMargin = 0.0,
    this.discount = 0.0,
    this.projectStatus = 'Planning',
    this.approvalSignature,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'unitNumber': unitNumber,
      'clientName': clientName,
      'clientPhone': clientPhone,
      'clientLocation': clientLocation,
      'date': date,
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'balanceAmount': balanceAmount,
      'latitude': latitude,
      'longitude': longitude,
      'locationFolder': locationFolder,
      'manualAmount': manualAmount,
      'manualWeight': manualWeight,
      'advancePayment': advancePayment,
      'includeWastage': includeWastage ? 1 : 0,
      'includeDigitalSignature': includeDigitalSignature ? 1 : 0,
      'includeBankDetails': includeBankDetails ? 1 : 0,
      'originalAmount': originalAmount,
      'revisionNote': revisionNote,
      'globalMaterialCost': globalMaterialCost,
      'globalMargin': globalMargin,
      'discount': discount,
      'projectStatus': projectStatus,
      'approvalSignature': approvalSignature,
    };
  }

  Map<String, dynamic> toCloudMap() {
    return {
      ...toMap(),
      'items': items.map((e) => e.toMap(id ?? 0)).toList(),
      'materials': materials.map((e) => e.toMap(id ?? 0)).toList(),
      'rentals': rentals.map((e) => {
        'itemName': e.itemName,
        'siteName': e.siteName,
        'startDate': e.startDate.toIso8601String(),
        'dailyRate': e.dailyRate,
        'quantity': e.quantity,
        'status': e.status,
      }).toList(),
      'payments': payments.map((e) => e.toMap(id ?? 0)).toList(),
    };
  }

  Quotation copyWith({
    int? id,
    String? unitNumber,
    String? clientName,
    String? clientPhone,
    String? clientLocation,
    String? date,
    double? totalAmount,
    double? paidAmount,
    double? balanceAmount,
    List<QuotationItem>? items,
    List<MaterialAssignment>? materials,
    List<RentalRecord>? rentals,
    List<PaymentRecord>? payments,
    double? latitude,
    double? longitude,
    double? surcharge,
    double? manualAmount,
    double? manualWeight,
    double? advancePayment,
    String? locationFolder,
    bool? includeWastage,
    bool? includeDigitalSignature,
    bool? includeBankDetails,
    double? originalAmount,
    String? revisionNote,
    double? globalMaterialCost,
    double? globalMargin,
    double? discount,
    String? projectStatus,
    String? approvalSignature,
  }) {
    return Quotation(
      id: id ?? this.id,
      unitNumber: unitNumber ?? this.unitNumber,
      clientName: clientName ?? this.clientName,
      clientPhone: clientPhone ?? this.clientPhone,
      clientLocation: clientLocation ?? this.clientLocation,
      date: date ?? this.date,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      balanceAmount: balanceAmount ?? this.balanceAmount,
      items: items ?? this.items,
      materials: materials ?? this.materials,
      rentals: rentals ?? this.rentals,
      payments: payments ?? this.payments,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      surcharge: surcharge ?? this.surcharge,
      manualAmount: manualAmount ?? this.manualAmount,
      manualWeight: manualWeight ?? this.manualWeight,
      advancePayment: advancePayment ?? this.advancePayment,
      locationFolder: locationFolder ?? this.locationFolder,
      includeWastage: includeWastage ?? this.includeWastage,
      includeDigitalSignature: includeDigitalSignature ?? this.includeDigitalSignature,
      includeBankDetails: includeBankDetails ?? this.includeBankDetails,
      originalAmount: originalAmount ?? this.originalAmount,
      revisionNote: revisionNote ?? this.revisionNote,
      globalMaterialCost: globalMaterialCost ?? this.globalMaterialCost,
      globalMargin: globalMargin ?? this.globalMargin,
      discount: discount ?? this.discount,
      projectStatus: projectStatus ?? this.projectStatus,
      approvalSignature: approvalSignature ?? this.approvalSignature,
    );
  }

  factory Quotation.fromMap(Map<String, dynamic> map, List<QuotationItem> items, {List<MaterialAssignment> materials = const [], List<RentalRecord> rentals = const [], List<PaymentRecord> payments = const []}) {
    return Quotation(
      id: map['id'],
      unitNumber: map['unitNumber'] ?? '',
      clientName: map['clientName'] ?? '',
      clientPhone: map['clientPhone'] ?? '',
      clientLocation: map['clientLocation'] ?? '',
      date: map['date'] ?? '',
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (map['paidAmount'] as num?)?.toDouble() ?? 0.0,
      balanceAmount: (map['balanceAmount'] as num?)?.toDouble() ?? 0.0,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      surcharge: (map['surcharge'] as num?)?.toDouble() ?? 0.0,
      manualAmount: (map['manualAmount'] as num?)?.toDouble() ?? 0.0,
      manualWeight: (map['manualWeight'] as num?)?.toDouble() ?? 0.0,
      advancePayment: (map['advancePayment'] as num?)?.toDouble() ?? 0.0,
      locationFolder: map['locationFolder'],
      includeWastage: map['includeWastage'] == 1,
      includeDigitalSignature: map['includeDigitalSignature'] == 1,
      includeBankDetails: map['includeBankDetails'] != 0,
      originalAmount: (map['originalAmount'] as num?)?.toDouble(),
      revisionNote: map['revisionNote'],
      globalMaterialCost: (map['globalMaterialCost'] as num?)?.toDouble() ?? 0.0,
      globalMargin: (map['globalMargin'] as num?)?.toDouble() ?? 0.0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      projectStatus: map['projectStatus'] ?? 'Planning',
      approvalSignature: map['approvalSignature'],
      items: items,
      materials: materials,
      rentals: rentals,
      payments: payments,
    );
  }

  factory Quotation.fromCloudMap(Map<String, dynamic> map) {
    final List<dynamic> itemsList = map['items'] ?? [];
    final items = itemsList.map((e) => QuotationItem.fromMap(Map<String, dynamic>.from(e))).toList();
    
    final List<dynamic> materialsList = map['materials'] ?? [];
    final materials = materialsList.map((e) => MaterialAssignment.fromMap(Map<String, dynamic>.from(e))).toList();
    
    final List<dynamic> rentalsList = map['rentals'] ?? [];
    final rentals = rentalsList.map((e) => RentalRecord(
      id: e['id']?.toString() ?? '',
      itemName: e['itemName'] ?? '',
      siteName: e['siteName'] ?? '',
      siteId: e['quotationId']?.toString() ?? '',
      startDate: DateTime.tryParse(e['startDate'] ?? '') ?? DateTime.now(),
      dailyRate: (e['dailyRate'] as num?)?.toDouble() ?? 0.0,
      quantity: (e['quantity'] as num?)?.toDouble() ?? 0.0,
      status: e['status'] ?? '',
    )).toList();
    
    final List<dynamic> paymentsList = map['payments'] ?? [];
    final payments = paymentsList.map((e) => PaymentRecord.fromMap(Map<String, dynamic>.from(e))).toList();
    
    return Quotation.fromMap(map, items, materials: materials, rentals: rentals, payments: payments);
  }
}

class MaterialAssignment {
  final int? id;
  final int? quotationId;
  final String materialName;
  final String unit;
  final double rate;
  final double quantity;
  final double amount;

  MaterialAssignment({
    this.id,
    this.quotationId,
    required this.materialName,
    required this.unit,
    required this.rate,
    required this.quantity,
    required this.amount,
  });

  Map<String, dynamic> toMap(int quotationId) {
    return {
      'id': id,
      'quotationId': quotationId,
      'materialName': materialName,
      'unit': unit,
      'rate': rate,
      'quantity': quantity,
      'amount': amount,
    };
  }

  factory MaterialAssignment.fromMap(Map<String, dynamic> map) {
    return MaterialAssignment(
      id: map['id'],
      quotationId: map['quotationId'],
      materialName: map['materialName'] ?? '',
      unit: map['unit'] ?? '',
      rate: (map['rate'] as num?)?.toDouble() ?? 0.0,
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

// RentalAssignment is deprecated in favor of RentalRecord in rental_model.dart

class QuotationItem {
  final int? id;
  final int? quotationId;
  final String roomName;
  final String ceilingType;
  final String unit;
  final double length;
  final double width;
  final double height;
  final double quantity;
  final double area;
  final double rate;
  final double amount;
  final double heightExtra;
  final double thickness;
  final String? brandName;
  final String designName;
  
  // Ceiling design fields
  final bool isCeilingDesign;
  final bool hasCentralDesign;
  final double centralArea;
  final double centralRate;
  final double centralLength;
  final double centralWidth;
  final double centralQuantity;
  final String centralUnit;
  final bool hasCove;
  final double coveRft;
  final double coveRate;
  final double coveLength;
  final double coveWidth;
  final double coveQuantity;
  final double coveLength2;
  final double coveWidth2;
  final double coveQuantity2;
  final String coveUnit;

  QuotationItem({
    this.id,
    this.quotationId,
    required this.roomName,
    required this.ceilingType,
    required this.unit,
    required this.length,
    required this.width,
    required this.height,
    required this.quantity,
    required this.area,
    required this.rate,
    required this.amount,
    this.heightExtra = 0,
    this.thickness = 0,
    this.brandName,
    this.designName = 'Standard Design',
    this.isCeilingDesign = false,
    this.hasCentralDesign = false,
    this.centralArea = 0.0,
    this.centralRate = 0.0,
    this.centralLength = 0.0,
    this.centralWidth = 0.0,
    this.centralQuantity = 1.0,
    this.centralUnit = 'SqFt',
    this.hasCove = false,
    this.coveRft = 0.0,
    this.coveRate = 0.0,
    this.coveLength = 0.0,
    this.coveWidth = 0.0,
    this.coveQuantity = 1.0,
    this.coveLength2 = 0.0,
    this.coveWidth2 = 0.0,
    this.coveQuantity2 = 1.0,
    this.coveUnit = 'RFT',
  });

  Map<String, dynamic> toMap(int quotationId) {
    return {
      'id': id,
      'quotationId': quotationId,
      'roomName': roomName,
      'ceilingType': ceilingType,
      'unit': unit,
      'length': length,
      'width': width,
      'height': height,
      'quantity': quantity,
      'area': area,
      'rate': rate,
      'amount': amount,
      'heightExtra': heightExtra,
      'thickness': thickness,
      'brandName': brandName,
      'designName': designName,
      'isCeilingDesign': isCeilingDesign ? 1 : 0,
      'hasCentralDesign': hasCentralDesign ? 1 : 0,
      'centralArea': centralArea,
      'centralRate': centralRate,
      'centralLength': centralLength,
      'centralWidth': centralWidth,
      'centralQuantity': centralQuantity,
      'centralUnit': centralUnit,
      'hasCove': hasCove ? 1 : 0,
      'coveRft': coveRft,
      'coveRate': coveRate,
      'coveLength': coveLength,
      'coveWidth': coveWidth,
      'coveQuantity': coveQuantity,
      'coveLength2': coveLength2,
      'coveWidth2': coveWidth2,
      'coveQuantity2': coveQuantity2,
      'coveUnit': coveUnit,
    };
  }

  factory QuotationItem.fromMap(Map<String, dynamic> map) {
    return QuotationItem(
      id: map['id'],
      quotationId: map['quotationId'],
      roomName: map['roomName'] ?? '',
      ceilingType: map['ceilingType'] ?? '',
      unit: map['unit'] ?? '',
      length: (map['length'] as num?)?.toDouble() ?? 0.0,
      width: (map['width'] as num?)?.toDouble() ?? 0.0,
      height: (map['height'] as num?)?.toDouble() ?? 0.0,
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      area: (map['area'] as num?)?.toDouble() ?? 0.0,
      rate: (map['rate'] as num?)?.toDouble() ?? 0.0,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      heightExtra: (map['heightExtra'] as num?)?.toDouble() ?? 0.0,
      thickness: (map['thickness'] as num?)?.toDouble() ?? 0.0,
      brandName: map['brandName'],
      designName: map['designName'] ?? 'Standard Design',
      isCeilingDesign: map['isCeilingDesign'] == 1 || map['isCeilingDesign'] == true,
      hasCentralDesign: map['hasCentralDesign'] == 1 || map['hasCentralDesign'] == true,
      centralArea: (map['centralArea'] as num?)?.toDouble() ?? 0.0,
      centralRate: (map['centralRate'] as num?)?.toDouble() ?? 0.0,
      centralLength: (map['centralLength'] as num?)?.toDouble() ?? 0.0,
      centralWidth: (map['centralWidth'] as num?)?.toDouble() ?? 0.0,
      centralQuantity: (map['centralQuantity'] as num?)?.toDouble() ?? 1.0,
      centralUnit: map['centralUnit'] ?? 'SqFt',
      hasCove: map['hasCove'] == 1 || map['hasCove'] == true,
      coveRft: (map['coveRft'] as num?)?.toDouble() ?? 0.0,
      coveRate: (map['coveRate'] as num?)?.toDouble() ?? 0.0,
      coveLength: (map['coveLength'] as num?)?.toDouble() ?? 0.0,
      coveWidth: (map['coveWidth'] as num?)?.toDouble() ?? 0.0,
      coveQuantity: (map['coveQuantity'] as num?)?.toDouble() ?? 1.0,
      coveLength2: (map['coveLength2'] as num?)?.toDouble() ?? 0.0,
      coveWidth2: (map['coveWidth2'] as num?)?.toDouble() ?? 0.0,
      coveQuantity2: (map['coveQuantity2'] as num?)?.toDouble() ?? 1.0,
      coveUnit: map['coveUnit'] ?? 'RFT',
    );
  }
}

class PaymentRecord {
  final int? id;
  final int? quotationId;
  final String description;
  final String date;
  final double amount;

  PaymentRecord({
    this.id,
    this.quotationId,
    required this.description,
    required this.date,
    required this.amount,
  });

  Map<String, dynamic> toMap(int quotationId) {
    return {
      'id': id,
      'quotationId': quotationId,
      'description': description,
      'date': date,
      'amount': amount,
    };
  }

  factory PaymentRecord.fromMap(Map<String, dynamic> map) {
    return PaymentRecord(
      id: map['id'],
      quotationId: map['quotationId'],
      description: map['description'] ?? 'Payment',
      date: map['date'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
