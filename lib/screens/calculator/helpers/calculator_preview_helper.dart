import '../calculator_controller.dart';

class CalculatorPreviewHelper {
  static void updateLivePreview(CalculatorController ctrl) {
    double l = double.tryParse(ctrl.lengthController.text) ?? 0;
    double w = double.tryParse(ctrl.widthController.text) ?? 0;
    double userRate = double.tryParse(ctrl.rateController.text) ?? 0;
    double q = double.tryParse(ctrl.quantityController.text) ?? 1;
    double ma = double.tryParse(ctrl.areaController.text) ?? 0;

    double conversionFactor = 1.0;
    if (ctrl.unit == 'Meters' || ctrl.unit == 'SqM') {
      conversionFactor = 10.764;
    } else if (ctrl.unit == 'Inches') {
      conversionFactor = 1.0 / 144.0;
    } else if (ctrl.unit == 'mm') {
      conversionFactor = 10.764 / 1000000.0;
    }

    double cove1 = 0;
    if (ctrl.hasCove) {
      double cL = double.tryParse(ctrl.coveLengthController.text) ?? 0.0;
      double cW = double.tryParse(ctrl.coveLength2Controller.text) ?? 0.0;
      double cH = double.tryParse(ctrl.coveWidth2Controller.text) ?? 0.0;
      if (cH == 0.0) cH = double.tryParse(ctrl.coveWidthController.text) ?? 0.0;
      double qL = double.tryParse(ctrl.coveQuantityController.text) ?? 0.0;
      double qW = double.tryParse(ctrl.coveQuantity2Controller.text) ?? 0.0;

      // UI handles corner deduction (cW = W - 2H). Helpers use value as-is.
      cove1 = (cL * cH * qL) + (cW * cH * qW);

      for (var r in ctrl.extraCoveRows) {
        double len = double.tryParse(r.lengthController.text) ?? 0.0;
        double hgt = double.tryParse(r.widthController.text) ?? 0.0;
        double qty = double.tryParse(r.quantityController.text) ?? 0.0;
        cove1 += len * hgt * qty;
      }

      // Sync display field with the same conversion factor and quantity used in total area
      double totalCoveArea = cove1 * conversionFactor * q;
      ctrl.coveRftController.text = totalCoveArea.toStringAsFixed(2);
    } else {
      ctrl.coveRftController.clear();
    }

    double cove2 = 0;
    if (ctrl.hasCentralDesign) {
      double cove2Length = double.tryParse(ctrl.centralLengthController.text) ?? 0.0;
      double cove2Height = double.tryParse(ctrl.centralWidthController.text) ?? 0.0;
      double cove2Qty = double.tryParse(ctrl.centralQuantityController.text) ?? 0.0;
      cove2 = cove2Length * cove2Height * cove2Qty;
      
      for (var r in ctrl.extraCentralRows) {
        double len = double.tryParse(r.lengthController.text) ?? 0.0;
        double wid = double.tryParse(r.widthController.text) ?? 0.0;
        double qty = double.tryParse(r.quantityController.text) ?? 0.0;
        double area = len * wid * qty;
        double convertedArea = area * conversionFactor * q;
        r.areaController.text = '${convertedArea.toStringAsFixed(2)} SQFT';
        cove2 += area;
      }
      
      double convertedCove2 = cove2 * conversionFactor * q;
      ctrl.centralAreaController.text = '${convertedCove2.toStringAsFixed(2)} SQFT';
    } else {
      ctrl.centralAreaController.clear();
    }

    double ceilingArea = 0;
    if (ctrl.isCeilingDesign) {
      if (ctrl.isAreaUnit) {
        double mainArea = (ma > 0) ? ma : (l * w);
        ceilingArea = mainArea;
      } else {
        ceilingArea = l;
      }
    }

    bool isInputsEmptyOrZero = ctrl.lengthController.text.trim().isEmpty ||
        ctrl.widthController.text.trim().isEmpty ||
        ctrl.quantityController.text.trim().isEmpty ||
        l == 0 ||
        w == 0 ||
        q == 0;

    double totalArea = (ceilingArea + cove1 + cove2) * q;
    ctrl.livePreviewMainAreaSqFt = isInputsEmptyOrZero ? 0.0 : (ceilingArea * conversionFactor * q);
    ctrl.livePreviewAreaSqFt = totalArea * conversionFactor;
    ctrl.livePreviewAmount = ctrl.livePreviewAreaSqFt * userRate;

    if (ctrl.lengthController.text.trim().isEmpty &&
        ctrl.widthController.text.trim().isEmpty &&
        !ctrl.hasCentralDesign &&
        !ctrl.hasCove) {
      ctrl.livePreviewMainAreaSqFt = 0.0;
      ctrl.livePreviewAreaSqFt = 0.0;
      ctrl.livePreviewAmount = 0.0;
    }

    ctrl.notifyUI();
  }
}
