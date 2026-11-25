import 'package:flutter/material.dart';
import '../calculator_controller.dart';

class CalculatorUnitHelper {
  // Sole source of truth for unit options (purely in English - no Malayalam)
  static const List<String> availableUnits = [
    'Meter',
    'SqFt',
    'Feet',
    'Inches',
    'CM',
    'mm',
  ];

  static const List<Color> unitPalette = [
    Color(0xFF2563EB), // Blue
    Color(0xFF16A34A), // Green
    Color(0xFFD97706), // Amber
    Color(0xFF9333EA), // Purple
    Color(0xFFDC2626), // Red
    Color(0xFF0D9488), // Teal
    Color(0xFF4F46E5), // Indigo
    Color(0xFFEA580C), // Orange
  ];

  static Color getUnitColor(String unit, [int? index]) {
    if (index != null && index >= 0) {
      return unitPalette[index % unitPalette.length];
    }
    final hash = unit.codeUnits.fold(0, (prev, el) => prev + el);
    return unitPalette[hash % unitPalette.length];
  }

  static void handleUnitChange(CalculatorController ctrl, String newUnit) {
    if (ctrl.unit == newUnit) return;
    convertPlainUnits(ctrl, ctrl.unit, newUnit);
  }

  static void handleCoveUnitChange(CalculatorController ctrl, String newUnit) =>
      convertCoveUnits(ctrl, ctrl.coveUnit.isNotEmpty ? ctrl.coveUnit : ctrl.unit, newUnit);

  static void handleCenterUnitChange(CalculatorController ctrl, String newUnit) =>
      convertSquareCenterUnits(ctrl, ctrl.centralUnit.isNotEmpty ? ctrl.centralUnit : ctrl.unit, newUnit);

  static void handleCustomCenterUnitChange(CalculatorController ctrl, String newUnit) =>
      convertRoundCenterUnits(ctrl, ctrl.customCenterUnit.isNotEmpty ? ctrl.customCenterUnit : ctrl.unit, newUnit);

  static void convertPlainUnits(CalculatorController ctrl, String oldUnit, String newUnit) {
    if (oldUnit == newUnit) return;
    final wasMetric = ctrl.isMetric;
    final normalized = newUnit.toLowerCase();
    final isMetric = normalized.contains('meter') || normalized.contains('sqm') || normalized.contains('rmt') || normalized == 'cm' || normalized == 'mm';
    if (wasMetric != isMetric) {
      if (isMetric) {
        ctrl.centralUnit = 'RMT';
        ctrl.coveUnit = 'RMT';
      } else {
        ctrl.centralUnit = 'RFT';
        ctrl.coveUnit = 'RFT';
      }
    }

    double scale = convertValue(1.0, oldUnit, newUnit);
    for (var c in [
      ctrl.lengthController, ctrl.widthController, ctrl.heightController, ctrl.thicknessController,
      ctrl.coveLengthController, ctrl.coveWidthController, ctrl.coveLength2Controller, ctrl.coveWidth2Controller,
      ctrl.centralLengthController, ctrl.centralWidthController,
      ctrl.customCenterRadiusController, ctrl.customCenterWidthController,
      ctrl.customCenterDeductionController, ctrl.customCenterDeductionWidthController
    ]) {
      double v = double.tryParse(c.text.replaceAll(',', '.')) ?? 0;
      if (v > 0) c.text = (v * scale).toStringAsFixed(2);
    }

    for (var r in ctrl.extraPlainRows) {
      double lVal = double.tryParse(r.lengthController.text.replaceAll(',', '.')) ?? 0;
      if (lVal > 0) r.lengthController.text = (lVal * scale).toStringAsFixed(2);
      double wVal = double.tryParse(r.widthController.text.replaceAll(',', '.')) ?? 0;
      if (wVal > 0) r.widthController.text = (wVal * scale).toStringAsFixed(2);
    }

    for (var r in ctrl.extraCoveRows) {
      double lVal = double.tryParse(r.lengthController.text.replaceAll(',', '.')) ?? 0;
      if (lVal > 0) r.lengthController.text = (lVal * scale).toStringAsFixed(2);
      double wVal = double.tryParse(r.widthController.text.replaceAll(',', '.')) ?? 0;
      if (wVal > 0) r.widthController.text = (wVal * scale).toStringAsFixed(2);
    }

    for (var r in ctrl.extraCentralRows) {
      double lVal = double.tryParse(r.lengthController.text.replaceAll(',', '.')) ?? 0;
      if (lVal > 0) r.lengthController.text = (lVal * scale).toStringAsFixed(2);
      double wVal = double.tryParse(r.widthController.text.replaceAll(',', '.')) ?? 0;
      if (wVal > 0) r.widthController.text = (wVal * scale).toStringAsFixed(2);
    }

    for (var r in ctrl.extraCustomCentralRows) {
      double lVal = double.tryParse(r.lengthController.text.replaceAll(',', '.')) ?? 0;
      if (lVal > 0) r.lengthController.text = (lVal * scale).toStringAsFixed(2);
      double wVal = double.tryParse(r.widthController.text.replaceAll(',', '.')) ?? 0;
      if (wVal > 0) r.widthController.text = (wVal * scale).toStringAsFixed(2);
    }

    double ma = double.tryParse(ctrl.areaController.text.replaceAll(',', '.')) ?? 0;
    if (ma > 0) ctrl.areaController.text = (ma * scale * scale).toStringAsFixed(2);

    if (ctrl.lastLength.isNotEmpty) {
      double lVal = double.tryParse(ctrl.lastLength.replaceAll(',', '.')) ?? 0;
      if (lVal > 0) ctrl.lastLength = (lVal * scale).toStringAsFixed(2);
    }
    if (ctrl.lastWidth.isNotEmpty) {
      double wVal = double.tryParse(ctrl.lastWidth.replaceAll(',', '.')) ?? 0;
      if (wVal > 0) ctrl.lastWidth = (wVal * scale).toStringAsFixed(2);
    }

    ctrl.unit = newUnit;
    ctrl.updateLivePreview();
    ctrl.updateProjectTotals();
    ctrl.notifyUI();
    ctrl.triggerAutoSave();
  }

  static void convertCoveUnits(CalculatorController ctrl, String oldUnit, String newUnit) {
    if (oldUnit == newUnit) return;
    double scale = convertValue(1.0, oldUnit, newUnit);
    for (var c in [
      ctrl.coveLengthController, ctrl.coveWidthController,
      ctrl.coveLength2Controller, ctrl.coveWidth2Controller
    ]) {
      double v = double.tryParse(c.text.replaceAll(',', '.')) ?? 0;
      if (v > 0) c.text = (v * scale).toStringAsFixed(2);
    }
    for (var r in ctrl.extraCoveRows) {
      double lVal = double.tryParse(r.lengthController.text.replaceAll(',', '.')) ?? 0;
      if (lVal > 0) r.lengthController.text = (lVal * scale).toStringAsFixed(2);
      double wVal = double.tryParse(r.widthController.text.replaceAll(',', '.')) ?? 0;
      if (wVal > 0) r.widthController.text = (wVal * scale).toStringAsFixed(2);
    }
    ctrl.coveUnit = newUnit;
    ctrl.updateLivePreview();
    ctrl.notifyUI();
    ctrl.triggerAutoSave();
  }

  static void convertSquareCenterUnits(CalculatorController ctrl, String oldUnit, String newUnit) {
    if (oldUnit == newUnit) return;
    double scale = convertValue(1.0, oldUnit, newUnit);
    for (var c in [ctrl.centralLengthController, ctrl.centralWidthController]) {
      double v = double.tryParse(c.text.replaceAll(',', '.')) ?? 0;
      if (v > 0) c.text = (v * scale).toStringAsFixed(2);
    }
    for (var r in ctrl.extraCentralRows) {
      double lVal = double.tryParse(r.lengthController.text.replaceAll(',', '.')) ?? 0;
      if (lVal > 0) r.lengthController.text = (lVal * scale).toStringAsFixed(2);
      double wVal = double.tryParse(r.widthController.text.replaceAll(',', '.')) ?? 0;
      if (wVal > 0) r.widthController.text = (wVal * scale).toStringAsFixed(2);
    }
    ctrl.centralUnit = newUnit;
    ctrl.updateLivePreview();
    ctrl.notifyUI();
    ctrl.triggerAutoSave();
  }

  static void convertRoundCenterUnits(CalculatorController ctrl, String oldUnit, String newUnit) {
    if (oldUnit == newUnit) return;
    double scale = convertValue(1.0, oldUnit, newUnit);
    for (var c in [
      ctrl.customCenterRadiusController, ctrl.customCenterWidthController,
      ctrl.customCenterDeductionController, ctrl.customCenterDeductionWidthController
    ]) {
      double v = double.tryParse(c.text.replaceAll(',', '.')) ?? 0;
      if (v > 0) c.text = (v * scale).toStringAsFixed(2);
    }
    for (var r in ctrl.extraCustomCentralRows) {
      double lVal = double.tryParse(r.lengthController.text.replaceAll(',', '.')) ?? 0;
      if (lVal > 0) r.lengthController.text = (lVal * scale).toStringAsFixed(2);
      double wVal = double.tryParse(r.widthController.text.replaceAll(',', '.')) ?? 0;
      if (wVal > 0) r.widthController.text = (wVal * scale).toStringAsFixed(2);
    }
    ctrl.customCenterUnit = newUnit;
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
      case 'Meters':
      case 'Meter': inMeters = value; break;
      default: inMeters = value;
    }
    switch (toBase) {
      case 'Feet': return inMeters * 3.28084;
      case 'Inches': return inMeters / 0.0254;
      case 'mm': return inMeters * 1000.0;
      case 'cm': return inMeters * 100.0;
      case 'Meters':
      case 'Meter': return inMeters;
      default: return inMeters;
    }
  }

  static String _getBaseUnit(String unit) {
    final u = unit.toLowerCase();
    if (u.contains('sqft') || u.contains('rft') || u.contains('feet')) {
      return 'Feet';
    }
    if (u.contains('sqm') || u.contains('rmt') || u.contains('meter')) {
      return 'Meters';
    }
    if (u.contains('inch')) {
      return 'Inches';
    }
    if (u == 'mm') {
      return 'mm';
    }
    if (u == 'cm') {
      return 'cm';
    }
    return unit;
  }
}
