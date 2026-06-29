import '../calculator_controller.dart';

class CalculatorUnitHelper {
  static void handleUnitChange(CalculatorController ctrl, String newUnit) {
    if (ctrl.unit == newUnit) return;
    
    final wasMetric = ctrl.isMetric;
    final isMetric = newUnit == 'Meters' || newUnit == 'SqM' || newUnit == 'RMT' || newUnit == 'cm' || newUnit == 'mm';
    if (wasMetric != isMetric) {
      if (isMetric) {
        ctrl.centralUnit = 'RMT';
        ctrl.coveUnit = 'RMT';
      } else {
        ctrl.centralUnit = 'RFT';
        ctrl.coveUnit = 'RFT';
      }
    }

    double scale = convertValue(1.0, ctrl.unit, newUnit);
    for (var c in [
      ctrl.lengthController, ctrl.widthController, ctrl.heightController, ctrl.thicknessController,
      ctrl.coveLengthController, ctrl.coveWidthController, ctrl.coveLength2Controller, ctrl.coveWidth2Controller,
      ctrl.centralLengthController, ctrl.centralWidthController
    ]) {
      double v = double.tryParse(c.text) ?? 0;
      if (v > 0) c.text = (v * scale).toStringAsFixed(2);
    }
    double ma = double.tryParse(ctrl.areaController.text) ?? 0;
    if (ma > 0) ctrl.areaController.text = (ma * scale * scale).toStringAsFixed(2);

    if (ctrl.lastLength.isNotEmpty) {
      double lVal = double.tryParse(ctrl.lastLength) ?? 0;
      if (lVal > 0) ctrl.lastLength = (lVal * scale).toStringAsFixed(2);
    }
    if (ctrl.lastWidth.isNotEmpty) {
      double wVal = double.tryParse(ctrl.lastWidth) ?? 0;
      if (wVal > 0) ctrl.lastWidth = (wVal * scale).toStringAsFixed(2);
    }

    ctrl.unit = newUnit; 
    ctrl.updateLivePreview();
    ctrl.notifyUI();
    ctrl.triggerAutoSave();
  }

  static double convertValue(double value, String from, String to) {
    double inMeters;
    String fromBase = _getBaseUnit(from);
    String toBase = _getBaseUnit(to);

    switch (fromBase) {
      case 'Feet': inMeters = value / 3.28084; break;
      case 'Inches': inMeters = value * 0.0254; break;
      case 'mm': inMeters = value / 1000.0; break;
      case 'cm': inMeters = value / 100.0; break;
      case 'Meters': inMeters = value; break;
      default: inMeters = value;
    }
    switch (toBase) {
      case 'Feet': return inMeters * 3.28084;
      case 'Inches': return inMeters / 0.0254;
      case 'mm': return inMeters * 1000.0;
      case 'cm': return inMeters * 100.0;
      case 'Meters': return inMeters;
      default: return inMeters;
    }
  }

  static String _getBaseUnit(String unit) {
    switch (unit) {
      case 'SqFt':
      case 'RFT':
      case 'Feet':
        return 'Feet';
      case 'SqM':
      case 'RMT':
      case 'Meters':
        return 'Meters';
      case 'Inches':
        return 'Inches';
      case 'mm':
        return 'mm';
      case 'cm':
        return 'cm';
      default:
        return unit;
    }
  }
}
