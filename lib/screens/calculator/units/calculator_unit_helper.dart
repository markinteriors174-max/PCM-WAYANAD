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
    if (u == 'cm' || u == 'cm') {
      return 'cm';
    }
    return unit;
  }
}
