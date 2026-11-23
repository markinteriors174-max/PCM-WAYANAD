import 'package:flutter/material.dart';

/// Data class representing site measurement and design selections for a room.
class RoomData {
  String roomName = 'Living Room';
  String floor = 'Ground Floor';
  String roomNumber = '1';
  int roomCount = 1; // റൂം എണ്ണം (Room Qty / Count)
  String colorPattern = '';

  // Checkbox field for bulk editing selection
  bool isSelected = false;

  // 1. Plain Ceiling
  bool hasPlainCeiling = true;
  double width = 0.0;
  double length = 0.0;
  String unit = 'Feet'; // Feet, Meters, Inches, CM, mm, SqFt
  String ceilingType = 'Plain Ceiling';

  // 2. Cove Light
  bool hasCove = false;
  double coveLength = 0.0;
  double coveWidth = 0.0;
  int coveSides = 4;

  // 3. Center Design / Center Steel Ceiling
  bool hasCenterDesign = false;
  String centerType = 'Center Design'; // 'Center Design', 'Center Steel Ceiling', 'Custom Center Design'
  double centerLength = 0.0;
  double centerWidth = 0.0;
  int centerQty = 1;

  // PDF Visibility (true = excluded from PDF)
  bool isHidden = false;

  // Overrides per room
  String? customBoard;
  String? customChannel;
  double? customRate;

  bool showMoreDetails = false;
  String customNotes = '';

  final TextEditingController widthController = TextEditingController();
  final TextEditingController lengthController = TextEditingController();
  final TextEditingController roomNumberController = TextEditingController(text: '1');
  final TextEditingController roomCountController = TextEditingController(text: '1');
  final TextEditingController customRoomController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  final TextEditingController coveLengthController = TextEditingController();
  final TextEditingController coveWidthController = TextEditingController();
  final TextEditingController coveSidesController = TextEditingController(text: '4');

  final TextEditingController centerLengthController = TextEditingController();
  final TextEditingController centerWidthController = TextEditingController();
  final TextEditingController centerQtyController = TextEditingController(text: '1');

  // Effective value getters syncing controller text with numeric properties
  double get effectiveWidth => width > 0 ? width : (double.tryParse(widthController.text) ?? 0.0);
  double get effectiveLength => length > 0 ? length : (double.tryParse(lengthController.text) ?? 0.0);

  double get plainSqFt {
    if (!hasPlainCeiling) return 0.0;
    final w = effectiveWidth;
    final l = effectiveLength;
    if (w <= 0 && l <= 0) return 0.0;
    final effW = w > 0 ? w : 1.0;
    final effL = l > 0 ? l : 1.0;
    final rawArea = effW * effL;

    switch (unit) {
      case 'Meters':
      case 'SqM':
        return rawArea * 10.7639;
      case 'Inches':
        return rawArea / 144.0;
      case 'CM':
      case 'cm':
        return rawArea / 929.03;
      case 'mm':
        return rawArea * (10.7639 / 1000000.0);
      case 'Feet':
      case 'SqFt':
      default:
        return rawArea;
    }
  }

  double get effectiveCoveLength => coveLength > 0 ? coveLength : (double.tryParse(coveLengthController.text) ?? 0.0);
  double get effectiveCoveWidth => coveWidth > 0 ? coveWidth : (double.tryParse(coveWidthController.text) ?? 0.0);
  int get effectiveCoveSides {
    if (coveSides > 0) return coveSides;
    final parsed = int.tryParse(coveSidesController.text);
    return (parsed != null && parsed > 0) ? parsed : 4;
  }

  double get coveSqFt {
    if (!hasCove) return 0.0;
    final cLen = effectiveCoveLength;
    final cWid = effectiveCoveWidth;
    final sides = effectiveCoveSides;
    if (cLen <= 0 && cWid <= 0) return 0.0;

    final effCLen = cLen > 0 ? cLen : 1.0;
    final effCWid = cWid > 0 ? cWid : 1.0;
    final rawArea = effCLen * effCWid * sides;

    switch (unit) {
      case 'Meters':
      case 'SqM':
        return rawArea * 10.7639;
      case 'Inches':
        return rawArea / 144.0;
      case 'CM':
      case 'cm':
        return rawArea / 929.03;
      case 'mm':
        return rawArea * (10.7639 / 1000000.0);
      case 'Feet':
      case 'SqFt':
      default:
        return rawArea;
    }
  }

  double get effectiveCenterLength => centerLength > 0 ? centerLength : (double.tryParse(centerLengthController.text) ?? 0.0);
  double get effectiveCenterWidth => centerWidth > 0 ? centerWidth : (double.tryParse(centerWidthController.text) ?? 0.0);
  int get effectiveCenterQty {
    if (centerQty > 0) return centerQty;
    final parsed = int.tryParse(centerQtyController.text);
    return (parsed != null && parsed > 0) ? parsed : 1;
  }

  double get centerSqFt {
    if (!hasCenterDesign) return 0.0;
    final cntLen = effectiveCenterLength;
    final cntWid = effectiveCenterWidth;
    final qty = effectiveCenterQty;
    if (cntLen <= 0 && cntWid <= 0) return 0.0;

    final effCntLen = cntLen > 0 ? cntLen : 1.0;
    final effCntWid = cntWid > 0 ? cntWid : 1.0;
    final rawArea = effCntLen * effCntWid * qty;

    switch (unit) {
      case 'Meters':
      case 'SqM':
        return rawArea * 10.7639;
      case 'Inches':
        return rawArea / 144.0;
      case 'CM':
      case 'cm':
        return rawArea / 929.03;
      case 'mm':
        return rawArea * (10.7639 / 1000000.0);
      case 'Feet':
      case 'SqFt':
      default:
        return rawArea;
    }
  }

  double get plainNativeArea {
    final w = effectiveWidth;
    final l = effectiveLength;
    if (!hasPlainCeiling || (w <= 0 && l <= 0)) return 0.0;
    final effW = w > 0 ? w : 1.0;
    final effL = l > 0 ? l : 1.0;
    return effW * effL;
  }

  double get coveNativeArea {
    final cLen = effectiveCoveLength;
    final cWid = effectiveCoveWidth;
    final sides = effectiveCoveSides;
    if (!hasCove || (cLen <= 0 && cWid <= 0)) return 0.0;
    final effCLen = cLen > 0 ? cLen : 1.0;
    final effCWid = cWid > 0 ? cWid : 1.0;
    return effCLen * effCWid * sides;
  }

  double get centerNativeArea {
    final cntLen = effectiveCenterLength;
    final cntWid = effectiveCenterWidth;
    final qty = effectiveCenterQty;
    if (!hasCenterDesign || (cntLen <= 0 && cntWid <= 0)) return 0.0;
    final effCntLen = cntLen > 0 ? cntLen : 1.0;
    final effCntWid = cntWid > 0 ? cntWid : 1.0;
    return effCntLen * effCntWid * qty;
  }

  double get singleRoomNativeArea => plainNativeArea + coveNativeArea + centerNativeArea;

  double get singleRoomSqFt => plainSqFt + coveSqFt + centerSqFt;

  double get calculatedSqFt {
    final qty = roomCount > 0 ? roomCount : 1;
    return singleRoomSqFt * qty;
  }

  void dispose() {
    widthController.dispose();
    lengthController.dispose();
    roomNumberController.dispose();
    roomCountController.dispose();
    customRoomController.dispose();
    notesController.dispose();

    coveLengthController.dispose();
    coveWidthController.dispose();
    coveSidesController.dispose();

    centerLengthController.dispose();
    centerWidthController.dispose();
    centerQtyController.dispose();
  }
}
