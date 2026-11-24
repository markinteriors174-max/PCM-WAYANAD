import '../calculator_controller.dart';
import '../../../models/quotation.dart';
import '../../../utils/calculator_utils.dart';
import 'square_center_quotation_helper.dart';
import 'round_center_quotation_helper.dart';

class CalculatorAddQuotationHelper {
  static bool addToQuotation(CalculatorController ctrl, Function(String) onError) {
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
    final brandName = CalculatorUtils.sanitizeBrandName((rawBrand.isNotEmpty && rawChannel.isNotEmpty)
        ? '$rawBrand • $rawChannel'
        : (rawBrand.isNotEmpty ? rawBrand : rawChannel));
    
    String baseDesignName = ctrl.selectedDesign == 'Other' 
        ? (ctrl.designController.text.isEmpty ? roomName : ctrl.designController.text) 
        : (ctrl.selectedDesign == 'Plain Design' || ctrl.selectedDesign == 'Plain Ceiling' || ctrl.selectedDesign == 'Ceiling Design' || ctrl.selectedDesign == 'Plain'
            ? 'Plain Ceiling' 
            : ctrl.selectedDesign!);

    double ceilingArea = ctrl.isCeilingDesign ? (ctrl.isAreaUnit ? (l * w) : l) : 0.0;
    
    // 1. Main Area Item
    if (ceilingArea > 0 || (l > 0 && w > 0)) {
      double itemArea = ceilingArea * q;
      ctrl.currentItems.add(QuotationItem(
        roomName: roomName, ceilingType: ceilingType, unit: ctrl.unit, 
        length: l, width: w, height: h, quantity: q, area: itemArea, 
        rate: userRate, amount: itemArea * factor * userRate, thickness: t, brandName: brandName,
        designName: baseDesignName, isCeilingDesign: ctrl.isCeilingDesign,
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
        ctrl.currentItems.add(QuotationItem(
          roomName: roomName, ceilingType: ceilingType, unit: ctrl.unit, 
          length: len, width: wid, height: 0, quantity: q, area: itemArea, 
          rate: userRate, amount: itemArea * factor * userRate, thickness: t, brandName: brandName,
          designName: baseDesignName, isCeilingDesign: ctrl.isCeilingDesign,
          floor: ctrl.selectedFloor,
          roomNumber: ctrl.roomNumberController.text.trim(),
          colorPattern: ctrl.selectedColorPattern,
        ));
      }
    }

    // 2. Primary Cove Item
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
        ctrl.currentItems.add(QuotationItem(
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

      // 3. Extra Cove Items
      for (var r in ctrl.extraCoveRows) {
        double len = double.tryParse(r.lengthController.text) ?? 0.0;
        double hgt = double.tryParse(r.widthController.text) ?? 0.0;
        double qty = double.tryParse(r.quantityController.text) ?? 0.0;
        double area = len * hgt * qty;
        if (area > 0) {
          double itemArea = area * q;
          ctrl.currentItems.add(QuotationItem(
            roomName: roomName, ceilingType: ceilingType, unit: ctrl.unit, 
            length: len, width: hgt, height: 0,
            quantity: q, area: itemArea, rate: coveRate, amount: itemArea * factor * coveRate, 
            brandName: brandName, designName: 'Cove Light',
            hasCove: true, coveRft: area,
            coveLength: len, coveWidth: hgt, coveQuantity: qty,
            coveUnit: ctrl.coveUnit,
          ));
        }
      }
    }

    // 4. Center Items (Square Design / Round Design -> exactly 2 measurement rows/entries)
    if (ctrl.hasCentralDesign) {
      if (ctrl.activeCenterType == 'Custom Center') {
        RoundCenterQuotationHelper.addRoundCenterItems(
          ctrl,
          ctrl.currentItems,
          roomName: roomName,
          ceilingType: ceilingType,
          brandName: brandName,
          factor: factor,
          userRate: userRate,
          q: q,
        );
      } else {
        SquareCenterQuotationHelper.addSquareCenterItems(
          ctrl,
          ctrl.currentItems,
          roomName: roomName,
          ceilingType: ceilingType,
          brandName: brandName,
          factor: factor,
          userRate: userRate,
          q: q,
        );
      }
    }

    if (ctrl.currentItems.isEmpty && h == 0) { 
      onError('Enter Dimensions, Area or Design elements!'); 
      return false;
    }

    ctrl.updateProjectTotals(); 
    ctrl.resetInputs(); // Clear for next use
    ctrl.triggerAutoSave(); 
    ctrl.notifyUI();
    return true;
  }
}
