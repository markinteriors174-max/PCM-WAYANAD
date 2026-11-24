import '../calculator_controller.dart';
import 'cove_calculation_helper.dart';

class CalculatorPreviewHelper {
  static void updateLivePreview(CalculatorController ctrl) {
    double l = double.tryParse(ctrl.lengthController.text.replaceAll(',', '.')) ?? 0;
    double w = double.tryParse(ctrl.widthController.text.replaceAll(',', '.')) ?? 0;
    double userRate = double.tryParse(ctrl.rateController.text.replaceAll(',', '.')) ?? 0;
    double q = double.tryParse(ctrl.quantityController.text.replaceAll(',', '.')) ?? 1;

    double conversionFactor = 1.0;
    if (ctrl.unit == 'Meters' || ctrl.unit == 'SqM' || ctrl.unit == 'Meter') {
      conversionFactor = 10.7639104;
    } else if (ctrl.unit == 'Inches') {
      conversionFactor = 1.0 / 144.0;
    } else if (ctrl.unit == 'mm') {
      conversionFactor = 10.764 / 1000000.0;
    }

    double cove1 = 0;
    if (ctrl.hasCove) {
      double recordedCove = double.tryParse(ctrl.coveRftController.text.replaceAll(',', '.')) ?? 0.0;
      if (recordedCove > 0) {
        cove1 = recordedCove;
      } else {
        double totalCoveArea = CoveCalculationHelper.getLengthRowSqft(ctrl) +
            CoveCalculationHelper.getWidthRowSqft(ctrl) +
            CoveCalculationHelper.getExtraRowsTotalSqft(ctrl);
        ctrl.coveRftController.text = totalCoveArea.toStringAsFixed(2);
        cove1 = totalCoveArea;
      }
      double coveRate = CoveCalculationHelper.getCustomRate(ctrl);
      if (coveRate > 0 && userRate == 0) userRate = coveRate;
    } else {
      ctrl.coveRftController.clear();
    }

    double cove2 = 0;
    if (ctrl.hasCentralDesign) {
      double cove2Length = double.tryParse(ctrl.centralLengthController.text.replaceAll(',', '.')) ?? 0.0;
      double cove2Height = double.tryParse(ctrl.centralWidthController.text.replaceAll(',', '.')) ?? 0.0;
      double cove2Qty = double.tryParse(ctrl.centralQuantityController.text.replaceAll(',', '.')) ?? 0.0;
      cove2 = cove2Length * cove2Height * cove2Qty;
      
      for (var r in ctrl.extraCentralRows) {
        double len = double.tryParse(r.lengthController.text.replaceAll(',', '.')) ?? 0.0;
        double wid = double.tryParse(r.widthController.text.replaceAll(',', '.')) ?? 0.0;
        double qty = double.tryParse(r.quantityController.text.replaceAll(',', '.')) ?? 0.0;
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

    double customCenterArea = 0;
    if (ctrl.isCenterCeilingOn) {
      double rVal = double.tryParse(ctrl.customCenterRadiusController.text.replaceAll(',', '.')) ?? 0.0;
      double deductionVal = double.tryParse(ctrl.customCenterDeductionController.text.replaceAll(',', '.')) ?? 0.0;

      double ccAreaFactor = conversionFactor;
      if (ctrl.customCenterUnit.isNotEmpty) {
        String ccUnit = ctrl.customCenterUnit;
        if (ccUnit.toLowerCase() == 'cm') {
          ccAreaFactor = 1.0 / (30.48 * 30.48);
        } else if (ccUnit.toLowerCase() == 'meters' || ccUnit.toLowerCase() == 'meter' || ccUnit.toLowerCase() == 'sqm' || ccUnit.toLowerCase() == 'm') {
          ccAreaFactor = 10.7639104;
        } else if (ccUnit.toLowerCase() == 'inches' || ccUnit.toLowerCase() == 'inch' || ccUnit.toLowerCase() == 'in') {
          ccAreaFactor = 1.0 / 144.0;
        } else if (ccUnit.toLowerCase() == 'mm') {
          ccAreaFactor = 10.7639104 / 1000000.0;
        } else if (ccUnit.toLowerCase() == 'feet' || ccUnit.toLowerCase() == 'sqft' || ccUnit.toLowerCase() == 'ft') {
          ccAreaFactor = 1.0;
        }
      }

      double mainCircumference = 2 * 3.1415926535 * rVal;
      if (rVal > 0) {
        ctrl.customCenterLengthController.text = mainCircumference.toStringAsFixed(2);
      } else {
        ctrl.customCenterLengthController.clear();
      }

      double primaryL = mainCircumference;
      double primaryW = double.tryParse(ctrl.customCenterWidthController.text.replaceAll(',', '.')) ?? 0.0;
      double primaryQ = double.tryParse(ctrl.customCenterQuantityController.text.replaceAll(',', '.')) ?? 1.0;
      if (primaryQ == 0) primaryQ = 1.0;
      double primarySqFt = (primaryL * primaryW * primaryQ) * ccAreaFactor;
      ctrl.customCenterAreaController.text = primarySqFt > 0 ? primarySqFt.toStringAsFixed(2) : '';

      double extraRowsSqFtSum = 0.0;
      for (var r in ctrl.extraCustomCentralRows) {
        String lenText = r.lengthController.text.trim();
        double len = lenText.isEmpty ? (rVal > 0 ? mainCircumference : 0.0) : (double.tryParse(lenText.replaceAll(',', '.')) ?? 0.0);
        if (len == 0.0 && rVal > 0) {
          len = mainCircumference;
        }
        double b = double.tryParse(r.widthController.text.replaceAll(',', '.')) ?? 0.0;
        double qty = double.tryParse(r.quantityController.text.replaceAll(',', '.')) ?? 1.0;
        if (qty == 0) qty = 1.0;
        double rowSqFt = (len * b * qty) * ccAreaFactor;
        r.areaController.text = rowSqFt > 0 ? rowSqFt.toStringAsFixed(2) : '';
        extraRowsSqFtSum += rowSqFt;
      }

      double fullCircleAreaM2 = 3.1415926535 * rVal * rVal;
      double fullCircleSqFt = fullCircleAreaM2 * ccAreaFactor;
      double deductionAreaM2 = 3.1415926535 * deductionVal * deductionVal;
      double deductionCircleSqFt = deductionAreaM2 * ccAreaFactor;
      double netAreaM2 = deductionVal > 0 ? (fullCircleAreaM2 - deductionAreaM2) : fullCircleAreaM2;
      double netSqFt = deductionVal > 0 ? (fullCircleSqFt - deductionCircleSqFt) : fullCircleSqFt;
      double circleAreaAdd = rVal > 0 ? netSqFt : 0.0;

      ctrl.customCenterCircleRadiusController.text = rVal > 0 ? rVal.toStringAsFixed(1) : '';
      ctrl.customCenterCircleAreaM2Controller.text = rVal > 0 ? netAreaM2.toStringAsFixed(2) : '';
      ctrl.customCenterCircleSqftController.text = rVal > 0 ? netSqFt.toStringAsFixed(2) : '';

      double deductionL = 2 * 3.1415926535 * deductionVal;
      if (deductionVal > 0) {
        ctrl.customCenterDeductionLengthController.text = deductionL.toStringAsFixed(2);
      } else {
        ctrl.customCenterDeductionLengthController.clear();
      }

      double deductionW = double.tryParse(ctrl.customCenterDeductionWidthController.text.replaceAll(',', '.')) ?? 0.0;
      double deductionQ = double.tryParse(ctrl.customCenterDeductionQuantityController.text.replaceAll(',', '.')) ?? 1.0;
      if (deductionQ == 0) deductionQ = 1.0;
      double deductionRowSqFt = deductionVal > 0 ? (deductionL * deductionW * deductionQ) * ccAreaFactor : 0.0;
      ctrl.customCenterDeductionAreaController.text = deductionRowSqFt > 0 ? deductionRowSqFt.toStringAsFixed(2) : '';

      double calculatedCustomCenterArea = primarySqFt + extraRowsSqFtSum + circleAreaAdd + deductionRowSqFt;
      if (ctrl.isCustomCenterApplied) {
        customCenterArea = calculatedCustomCenterArea;
      } else {
        customCenterArea = 0.0;
      }

      double ccRate = double.tryParse(ctrl.customCenterRateController.text.replaceAll(',', '.')) ?? userRate;
      if (ccRate > 0 && userRate == 0) userRate = ccRate;
    }

    double ceilingArea = 0;
    if (ctrl.isCeilingDesign) {
      if (ctrl.isAreaUnit) {
        ceilingArea = l * w;
      } else {
        ceilingArea = l;
      }
    }

    double extraPlainSum = 0;
    for (var r in ctrl.extraPlainRows) {
      double len = double.tryParse(r.lengthController.text.replaceAll(',', '.')) ?? 0.0;
      double wid = double.tryParse(r.widthController.text.replaceAll(',', '.')) ?? 0.0;
      double qty = double.tryParse(r.quantityController.text.replaceAll(',', '.')) ?? 1.0;
      double area = ctrl.isAreaUnit ? (len * wid * qty) : (len * qty);
      extraPlainSum += area;
    }

    bool isInputsEmptyOrZero = ctrl.lengthController.text.trim().isEmpty ||
        ctrl.widthController.text.trim().isEmpty ||
        ctrl.quantityController.text.trim().isEmpty ||
        l == 0 ||
        w == 0 ||
        q == 0;

    double ceilingAreaSqFt = (ceilingArea + extraPlainSum) * conversionFactor * q;
    double totalArea = ceilingAreaSqFt + cove1 + (cove2 * conversionFactor * q) + customCenterArea;

    ctrl.livePreviewMainAreaSqFt = (isInputsEmptyOrZero && extraPlainSum == 0 && !ctrl.hasCentralDesign && !ctrl.hasCove && !ctrl.isCenterCeilingOn) ? 0.0 : ceilingAreaSqFt;
    ctrl.livePreviewAreaSqFt = totalArea;
    double effectiveRate = userRate > 0 ? userRate : 105.0;
    ctrl.livePreviewAmount = ctrl.livePreviewAreaSqFt * effectiveRate;

    if (ctrl.lengthController.text.trim().isEmpty &&
        ctrl.widthController.text.trim().isEmpty &&
        ctrl.extraPlainRows.isEmpty &&
        !ctrl.hasCentralDesign &&
        !ctrl.hasCove &&
        !ctrl.isCenterCeilingOn) {
      ctrl.livePreviewMainAreaSqFt = 0.0;
      ctrl.livePreviewAreaSqFt = 0.0;
      ctrl.livePreviewAmount = 0.0;
    }

    ctrl.notifyUI();
  }
}
