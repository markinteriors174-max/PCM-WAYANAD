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
  final List<Map<String, dynamic>> rateTiers;

  // Quotation Authority / Partner Details
  final String? partnerName;
  final String? partnerPhone;
  final String? partnerLocation;

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
    this.rateTiers = const [],
    this.partnerName,
    this.partnerPhone,
    this.partnerLocation,
  });

  static String sanitizeUnitNumber(String? raw) {
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'unitNumber': sanitizeUnitNumber(unitNumber),
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
      'rateTiers': rateTiers,
      'partnerName': partnerName,
      'partnerPhone': partnerPhone,
      'partnerLocation': partnerLocation,
    };
  }

  Map<String, dynamic> toCloudMap() {
    return {
      ...toMap(),
      'quoteId': sanitizeUnitNumber(unitNumber),
      'partnerInfo': {
        'name': partnerName ?? '',
        'phone': partnerPhone ?? '',
        'location': partnerLocation ?? '',
      },
      'partnerName': partnerName ?? '',
      'partnerPhone': partnerPhone ?? '',
      'partnerLocation': partnerLocation ?? '',
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
    List<Map<String, dynamic>>? rateTiers,
    String? partnerName,
    String? partnerPhone,
    String? partnerLocation,
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
      rateTiers: rateTiers ?? this.rateTiers,
      partnerName: partnerName ?? this.partnerName,
      partnerPhone: partnerPhone ?? this.partnerPhone,
      partnerLocation: partnerLocation ?? this.partnerLocation,
    );
  }

  factory Quotation.fromMap(Map<String, dynamic> map, List<QuotationItem> items, {List<MaterialAssignment> materials = const [], List<RentalRecord> rentals = const [], List<PaymentRecord> payments = const []}) {
    var rawName = (map['clientName'] ?? map['client_name'] ?? map['name'])?.toString().trim() ?? '';
    var rawPhone = (map['clientPhone'] ?? map['phone_number'] ?? map['phoneNumber'] ?? map['phone'])?.toString().trim() ?? '';

    String cleanPhone = rawPhone.replaceAll(RegExp(r'[^\d+]'), '').trim();
    String extraNameFromPhone = rawPhone.replaceAll(RegExp(r'[\d+\s\-]'), '').trim();

    if (rawName.isEmpty || rawName.toUpperCase() == 'SITE DRAFT') {
      if (extraNameFromPhone.isNotEmpty) {
        rawName = extraNameFromPhone;
      }
    }

    return Quotation(
      id: map['id'],
      unitNumber: sanitizeUnitNumber(map['unitNumber']?.toString() ?? map['unit_number']?.toString()),
      clientName: rawName.isNotEmpty ? rawName : 'SITE DRAFT',
      clientPhone: cleanPhone,
      clientLocation: map['clientLocation'] ?? map['site_location'] ?? map['location'] ?? '',
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
      rateTiers: (map['rateTiers'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? const [],
      partnerName: (map['partnerInfo'] is Map ? map['partnerInfo']['name'] : null) ?? map['partnerName'] ?? map['partner_name'],
      partnerPhone: (map['partnerInfo'] is Map ? map['partnerInfo']['phone'] : null) ?? map['partnerPhone'] ?? map['partner_phone'],
      partnerLocation: (map['partnerInfo'] is Map ? map['partnerInfo']['location'] : null) ?? map['partnerLocation'] ?? map['partner_location'],
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
  
  // Advanced Room Management fields
  final String floor;
  final String roomNumber;
  final String colorPattern;
  
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
  final bool isHidden;
  final bool isSelected;

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
    this.floor = 'Ground Floor',
    this.roomNumber = '',
    this.colorPattern = 'Warm White (3000K)',
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
    this.isHidden = false,
    this.isSelected = true,
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
      'floor': floor,
      'roomNumber': roomNumber,
      'colorPattern': colorPattern,
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
      'isHidden': isHidden ? 1 : 0,
      'isSelected': isSelected ? 1 : 0,
    };
  }

  factory QuotationItem.fromMap(Map<String, dynamic> map) {
    final l = (map['length'] as num?)?.toDouble() ?? 0.0;
    final w = (map['width'] as num?)?.toDouble() ?? 0.0;
    final q = (map['quantity'] as num?)?.toDouble() ?? 0.0;
    final r = (map['rate'] as num?)?.toDouble() ?? 0.0;

    double areaVal = (map['area'] as num?)?.toDouble() ?? 0.0;
    if (areaVal <= 0 && l > 0 && w > 0) {
      areaVal = l * w * (q > 0 ? q : 1.0);
    }

    double amtVal = (map['amount'] as num?)?.toDouble() ?? 0.0;
    if (amtVal <= 0 && areaVal > 0 && r > 0) {
      amtVal = areaVal * r;
    }

    return QuotationItem(
      id: map['id'],
      quotationId: map['quotationId'],
      roomName: map['roomName'] ?? '',
      ceilingType: map['ceilingType'] ?? '',
      unit: map['unit'] ?? '',
      length: l,
      width: w,
      height: (map['height'] as num?)?.toDouble() ?? 0.0,
      quantity: q,
      area: areaVal,
      rate: r,
      amount: amtVal,
      heightExtra: (map['heightExtra'] as num?)?.toDouble() ?? 0.0,
      thickness: (map['thickness'] as num?)?.toDouble() ?? 0.0,
      brandName: map['brandName'],
      designName: map['designName'] ?? 'Standard Design',
      floor: map['floor'] ?? 'Ground Floor',
      roomNumber: map['roomNumber'] ?? '',
      colorPattern: map['colorPattern'] ?? 'Warm White (3000K)',
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
      isHidden: map['isHidden'] == 1 || map['isHidden'] == true,
      isSelected: map['isSelected'] == null || map['isSelected'] == 1 || map['isSelected'] == true,
    );
  }

  QuotationItem copyWith({
    int? id,
    int? quotationId,
    String? roomName,
    String? ceilingType,
    String? unit,
    double? length,
    double? width,
    double? height,
    double? quantity,
    double? area,
    double? rate,
    double? amount,
    double? heightExtra,
    double? thickness,
    String? brandName,
    String? designName,
    String? floor,
    String? roomNumber,
    String? colorPattern,
    bool? isCeilingDesign,
    bool? hasCentralDesign,
    double? centralArea,
    double? centralRate,
    double? centralLength,
    double? centralWidth,
    double? centralQuantity,
    String? centralUnit,
    bool? hasCove,
    double? coveRft,
    double? coveRate,
    double? coveLength,
    double? coveWidth,
    double? coveQuantity,
    double? coveLength2,
    double? coveWidth2,
    double? coveQuantity2,
    String? coveUnit,
    bool? isHidden,
    bool? isSelected,
  }) {
    return QuotationItem(
      id: id ?? this.id,
      quotationId: quotationId ?? this.quotationId,
      roomName: roomName ?? this.roomName,
      ceilingType: ceilingType ?? this.ceilingType,
      unit: unit ?? this.unit,
      length: length ?? this.length,
      width: width ?? this.width,
      height: height ?? this.height,
      quantity: quantity ?? this.quantity,
      area: area ?? this.area,
      rate: rate ?? this.rate,
      amount: amount ?? this.amount,
      heightExtra: heightExtra ?? this.heightExtra,
      thickness: thickness ?? this.thickness,
      brandName: brandName ?? this.brandName,
      designName: designName ?? this.designName,
      floor: floor ?? this.floor,
      roomNumber: roomNumber ?? this.roomNumber,
      colorPattern: colorPattern ?? this.colorPattern,
      isCeilingDesign: isCeilingDesign ?? this.isCeilingDesign,
      hasCentralDesign: hasCentralDesign ?? this.hasCentralDesign,
      centralArea: centralArea ?? this.centralArea,
      centralRate: centralRate ?? this.centralRate,
      centralLength: centralLength ?? this.centralLength,
      centralWidth: centralWidth ?? this.centralWidth,
      centralQuantity: centralQuantity ?? this.centralQuantity,
      centralUnit: centralUnit ?? this.centralUnit,
      hasCove: hasCove ?? this.hasCove,
      coveRft: coveRft ?? this.coveRft,
      coveRate: coveRate ?? this.coveRate,
      coveLength: coveLength ?? this.coveLength,
      coveWidth: coveWidth ?? this.coveWidth,
      coveQuantity: coveQuantity ?? this.coveQuantity,
      coveLength2: coveLength2 ?? this.coveLength2,
      coveWidth2: coveWidth2 ?? this.coveWidth2,
      coveQuantity2: coveQuantity2 ?? this.coveQuantity2,
      coveUnit: coveUnit ?? this.coveUnit,
      isHidden: isHidden ?? this.isHidden,
      isSelected: isSelected ?? this.isSelected,
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
