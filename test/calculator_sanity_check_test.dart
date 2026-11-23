// PROTECTED MODULE - DO NOT MODIFY OR OVERWRITE THIS FILE
import 'package:flutter_test/flutter_test.dart';
import 'package:pcm_wayanad/screens/calculator/protected/unified_room_calculator_card.dart';
import 'package:pcm_wayanad/screens/calculator/calculator_controller.dart';
import 'package:pcm_wayanad/screens/calculator/helpers/calculator_preview_helper.dart';

void main() {
  test('Protected Calculator Constants Sanity Check', () {
    expect(CalculatorConstants.defaultUnit, 'Meter');
    expect(CalculatorConstants.defaultRate, 105.0);
  });

  test('Protected Calculator Controller Defaults Sanity Check', () {
    final ctrl = CalculatorController();
    expect(ctrl.unit, 'Meter');
    expect(ctrl.centralUnit, 'Meter');
    expect(ctrl.customCenterUnit, 'Meter');
    expect(ctrl.coveUnit, 'Meter');
    expect(ctrl.rateController.text, '105.0');
    expect(ctrl.centralRateController.text, '105.0');
    expect(ctrl.customCenterRateController.text, '105.0');
    expect(ctrl.coveRateController.text, '105.0');
  });

  test('Protected Calculator Math Formulas Sanity Check', () {
    // 1. Circumference: 2 * pi * r
    final circum = CalculatorMath.calculateCircumference(2.0);
    expect(circum, closeTo(12.56637, 0.0001));

    // 2. Corner deduction: border1 + border2
    final netW = CalculatorMath.calculateNetWidth(5.0, 1.2, 0.8);
    expect(netW, closeTo(3.0, 0.0001));

    // 3. Meter to SQFT conversion: * 10.7639104
    final sqft = CalculatorMath.convertToSqFt(2.0, 'Meter');
    expect(sqft, closeTo(21.52782, 0.0001));
  });

  test('Plain Area and Total Calculation Sanity Check for Meter Unit', () {
    final ctrl = CalculatorController();
    ctrl.unit = 'Meter';
    ctrl.lengthController.text = '3';
    ctrl.widthController.text = '3';
    ctrl.quantityController.text = '1';
    ctrl.rateController.text = '105.0';

    CalculatorPreviewHelper.updateLivePreview(ctrl);

    expect(ctrl.livePreviewMainAreaSqFt, closeTo(96.87519, 0.001));
    expect(ctrl.livePreviewAmount, closeTo(96.87519 * 105.0, 0.01));
  });
}
