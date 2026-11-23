import '../calculator_controller.dart';
import '../../../models/quotation.dart';

class CalculatorEditQuotationHelper {
  static bool updateQuotationItem(CalculatorController ctrl, int index, Function(String) onError) {
    if (index < 0 || index >= ctrl.currentItems.length) return false;
    
    double l = double.tryParse(ctrl.lengthController.text) ?? 0;
    double w = double.tryParse(ctrl.widthController.text) ?? 0;
    double h = double.tryParse(ctrl.heightController.text) ?? 0;
    double t = double.tryParse(ctrl.thicknessController.text) ?? 0;
    double userRate = double.tryParse(ctrl.rateController.text) ?? 0;
    double q = double.tryParse(ctrl.quantityController.text) ?? 1;

    if (ctrl.selectedDesign == null || ctrl.selectedDesign!.trim().isEmpty) {
      ctrl.selectedDesign = 'Plain Ceiling';
    }

    double factor = 1.0;
    if (ctrl.unit == 'Meters' || ctrl.unit == 'SqM' || ctrl.unit == 'Meter') {
      factor = 10.7639104;
    } else if (ctrl.unit == 'Inches') {
      factor = 1.0 / 144.0;
    } else if (ctrl.unit == 'mm') {
      factor = 10.764 / 1000000.0;
    }

    final roomName = ctrl.selectedRoom == 'Other' ? (ctrl.roomController.text.isEmpty ? 'Custom Room' : ctrl.roomController.text) : (ctrl.selectedRoom ?? 'General');
    final ceilingType = ((ctrl.selectedCeilingType == 'Other' || ctrl.selectedCeilingType == 'More') && ctrl.customCeilingController.text.trim().isNotEmpty)
        ? ctrl.customCeilingController.text.trim()
        : (ctrl.selectedCeilingType ?? 'Gypsum Board');
    final rawBrand = (ctrl.selectedBrand == 'Other' || ctrl.selectedBrand == 'More') ? ctrl.brandController.text : (ctrl.selectedBrand ?? ctrl.brandController.text);
    final rawChannel = (ctrl.selectedChannel == 'Other' || ctrl.selectedChannel == 'More') ? ctrl.channelController.text : (ctrl.selectedChannel ?? ctrl.channelController.text);
    final brandName = (rawBrand.isNotEmpty && rawChannel.isNotEmpty)
        ? '$rawBrand • $rawChannel'
        : (rawBrand.isNotEmpty ? rawBrand : rawChannel);
    
    String baseDesignName = ctrl.selectedDesign == 'Other' 
        ? (ctrl.designController.text.isEmpty ? roomName : ctrl.designController.text) 
        : (ctrl.selectedDesign == 'Plain Design' || ctrl.selectedDesign == 'Plain Ceiling' || ctrl.selectedDesign == 'Ceiling Design' || ctrl.selectedDesign == 'Plain'
            ? 'Plain Ceiling' 
            : ctrl.selectedDesign!);

    double ceilingArea = ctrl.isCeilingDesign ? (ctrl.isAreaUnit ? (l * w) : l) : 0.0;

    List<QuotationItem> newItems = [];
    
    // 1. Main Area Item
    if (ceilingArea > 0 || (l > 0 && w > 0)) {
      double itemArea = ceilingArea * q;
      newItems.add(QuotationItem(
        roomName: roomName, ceilingType: ceilingType, unit: ctrl.unit, length: l, width: w, height: h, quantity: q, area: itemArea, 
        rate: userRate, amount: itemArea * factor * userRate, thickness: t, brandName: brandName, designName: baseDesignName, isCeilingDesign: ctrl.isCeilingDesign,
        floor: ctrl.selectedFloor,
        roomNumber: ctrl.roomNumberController.text.trim(),
        colorPattern: ctrl.selectedColorPattern,
      ));
    }

    // Extra Plain Items
    for (var r in ctrl.extraPlainRows) {
      double len = double.tryParse(r.lengthController.text) ?? 0.0;
      double wid = double.tryParse(r.widthController.text) ?? 0.0;
      double qty = double.tryParse(r.quantityController.text) ?? 1.0;
      double area = ctrl.isAreaUnit ? (len * wid * qty) : (len * qty);
      if (area > 0) {
        double itemArea = area * q;
        newItems.add(QuotationItem(
          roomName: roomName, ceilingType: ceilingType, unit: ctrl.unit, length: len, width: wid, height: 0, quantity: q, area: itemArea, 
          rate: userRate, amount: itemArea * factor * userRate, thickness: t, brandName: brandName, designName: baseDesignName, isCeilingDesign: ctrl.isCeilingDesign,
          floor: ctrl.selectedFloor,
          roomNumber: ctrl.roomNumberController.text.trim(),
          colorPattern: ctrl.selectedColorPattern,
        ));
      }
    }

    // 2. Cove Items
    final double recordedCoveSqft = double.tryParse(ctrl.coveRftController.text) ?? 0.0;
    if (ctrl.hasCove || recordedCoveSqft > 0) {
      double cL = double.tryParse(ctrl.coveLengthController.text) ?? 0.0;
      double cH = double.tryParse(ctrl.coveWidthController.text) ?? 0.0;
      double qL = double.tryParse(ctrl.coveQuantityController.text) ?? 0.0;
      double cW = double.tryParse(ctrl.coveLength2Controller.text) ?? 0.0;
      double cH2 = double.tryParse(ctrl.coveWidth2Controller.text) ?? 0.0;
      if (cH2 == 0.0) cH2 = cH;
      if (cH == 0.0) cH = cH2;
      double qW = double.tryParse(ctrl.coveQuantity2Controller.text) ?? 0.0;

      double primaryCoveArea = (cL * cH * qL) + (cW * cH2 * qW);
      double nativeCoveArea = primaryCoveArea > 0
          ? primaryCoveArea
          : (recordedCoveSqft > 0 ? (recordedCoveSqft / (factor > 0 ? factor : 1.0) / (q > 0 ? q : 1.0)) : 0.0);

      double coveRate = double.tryParse(ctrl.coveRateController.text) ?? 0.0;
      if (coveRate <= 0) coveRate = userRate > 0 ? userRate : 105.0;

      if (nativeCoveArea > 0) {
        double itemArea = nativeCoveArea * q;
        double itemAmount = itemArea * factor * coveRate;
        newItems.add(QuotationItem(
          roomName: roomName,
          ceilingType: ceilingType,
          unit: ctrl.unit, 
          length: cL > 0 ? cL : l,
          width: cH > 0 ? cH : cH2,
          height: 0,
          quantity: q,
          area: itemArea,
          rate: coveRate,
          amount: itemAmount,
          brandName: brandName,
          designName: 'Cove Light',
          hasCove: true,
          coveRft: nativeCoveArea,
          coveRate: coveRate,
          coveLength: cL,
          coveWidth: cH,
          coveQuantity: qL,
          coveLength2: cW,
          coveWidth2: cH2,
          coveQuantity2: qW,
          coveUnit: ctrl.coveUnit,
        ));
      }

      for (var r in ctrl.extraCoveRows) {
        double len = double.tryParse(r.lengthController.text) ?? 0.0;
        double wid = double.tryParse(r.widthController.text) ?? 0.0;
        double qty = double.tryParse(r.quantityController.text) ?? 0.0;
        double area = len * wid * qty;
        if (area > 0) {
          double itemArea = area * q;
          newItems.add(QuotationItem(
            roomName: roomName, ceilingType: ceilingType, unit: ctrl.unit, 
            length: len, width: wid, height: 0,
            quantity: q, area: itemArea, rate: coveRate, amount: itemArea * factor * coveRate, 
            brandName: brandName, designName: 'Cove Light',
            hasCove: true, coveRft: area,
            coveLength: len, coveWidth: wid, coveQuantity: qty,
            coveUnit: ctrl.coveUnit,
          ));
        }
      }
    }

    // 3. Central Items
    if (ctrl.hasCentralDesign) {
      double cL = double.tryParse(ctrl.centralLengthController.text) ?? 0.0;
      double cW = double.tryParse(ctrl.centralWidthController.text) ?? 0.0;
      double cQ = double.tryParse(ctrl.centralQuantityController.text) ?? 0.0;
      double primaryCentralArea = cL * cW * cQ;
      
      if (primaryCentralArea > 0) {
        double itemArea = primaryCentralArea * q;
        newItems.add(QuotationItem(
          roomName: roomName, ceilingType: ceilingType, unit: ctrl.unit, 
          length: cL, width: cW, height: 0,
          quantity: q, area: itemArea, rate: userRate, amount: itemArea * factor * userRate, brandName: brandName, designName: 'Center Design',
          hasCentralDesign: true, centralArea: primaryCentralArea,
          centralLength: cL, centralWidth: cW, centralQuantity: cQ,
          centralUnit: ctrl.centralUnit,
        ));
      }

      for (var r in ctrl.extraCentralRows) {
        double len = double.tryParse(r.lengthController.text) ?? 0.0;
        double wid = double.tryParse(r.widthController.text) ?? 0.0;
        double qty = double.tryParse(r.quantityController.text) ?? 0.0;
        double area = len * wid * qty;
        if (area > 0) {
          double itemArea = area * q;
          newItems.add(QuotationItem(
            roomName: roomName, ceilingType: ceilingType, unit: ctrl.unit, 
            length: len, width: wid, height: 0,
            quantity: q, area: itemArea, rate: userRate, amount: itemArea * factor * userRate,
            brandName: brandName, designName: 'Center Design',
            hasCentralDesign: true, centralArea: area,
            centralLength: len, centralWidth: wid, centralQuantity: qty,
            centralUnit: ctrl.centralUnit,
          ));
        }
      }
    }

    if (newItems.isEmpty && h == 0) { 
      onError('Enter Dimensions, Area or Design elements!'); 
      return false;
    }

    if (newItems.isNotEmpty) {
      ctrl.currentItems.removeAt(index);
      ctrl.currentItems.insertAll(index, newItems);
    }

    ctrl.updateProjectTotals(); 
    ctrl.resetInputs();
    ctrl.triggerAutoSave(); 
    ctrl.notifyUI();
    return true;
  }
}
