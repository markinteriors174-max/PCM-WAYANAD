import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pcm_wayanad/screens/calculator/calculator_controller.dart';
import 'package:pcm_wayanad/screens/calculator/units/calculator_unit_helper.dart';
import 'package:pcm_wayanad/screens/calculator/helpers/calculator_preview_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  test('Unit switching preserves SQFT and rupee amount while converting dimensions', () {
    final ctrl = CalculatorController();
    ctrl.unit = 'Feet';
    ctrl.lengthController.text = '6';
    ctrl.widthController.text = '4';
    ctrl.quantityController.text = '1';
    ctrl.rateController.text = '100.0';

    CalculatorPreviewHelper.updateLivePreview(ctrl);
    final initialSqFt = ctrl.livePreviewAreaSqFt;
    final initialAmount = ctrl.livePreviewAmount;

    expect(initialSqFt, closeTo(24.0, 0.001));
    expect(initialAmount, closeTo(2400.0, 0.01));

    // Switch to Meter
    CalculatorUnitHelper.handleUnitChange(ctrl, 'Meter');
    expect(ctrl.livePreviewAreaSqFt, closeTo(initialSqFt, 0.05));
    expect(ctrl.livePreviewAmount, closeTo(initialAmount, 5.0));
    expect(double.parse(ctrl.lengthController.text), closeTo(1.83, 0.01));
    expect(double.parse(ctrl.widthController.text), closeTo(1.22, 0.01));

    // Switch to mm
    CalculatorUnitHelper.handleUnitChange(ctrl, 'mm');
    expect(ctrl.livePreviewAreaSqFt, closeTo(initialSqFt, 0.1));
    expect(ctrl.livePreviewAmount, closeTo(initialAmount, 10.0));

    // Switch to CM
    CalculatorUnitHelper.handleUnitChange(ctrl, 'CM');
    expect(ctrl.livePreviewAreaSqFt, closeTo(initialSqFt, 0.1));

    // Switch to Inches
    CalculatorUnitHelper.handleUnitChange(ctrl, 'Inches');
    expect(ctrl.livePreviewAreaSqFt, closeTo(initialSqFt, 0.1));
  });

  test('Cove, Center Square, and Center Round unit switching preserves SQFT', () {
    final ctrl = CalculatorController();

    // Cove unit test
    ctrl.hasCove = true;
    ctrl.coveUnit = 'Feet';
    ctrl.coveLengthController.text = '10';
    ctrl.coveWidthController.text = '2';
    CalculatorPreviewHelper.updateLivePreview(ctrl);
    final coveSqFtBefore = ctrl.livePreviewAreaSqFt;
    CalculatorUnitHelper.handleCoveUnitChange(ctrl, 'Meter');
    CalculatorPreviewHelper.updateLivePreview(ctrl);
    expect(ctrl.livePreviewAreaSqFt, closeTo(coveSqFtBefore, 0.1));

    // Center Square unit test
    ctrl.hasCove = false;
    ctrl.hasCentralDesign = true;
    ctrl.centralUnit = 'Feet';
    ctrl.centralLengthController.text = '5';
    ctrl.centralWidthController.text = '5';
    CalculatorPreviewHelper.updateLivePreview(ctrl);
    final centerSqFtBefore = ctrl.livePreviewAreaSqFt;
    CalculatorUnitHelper.handleCenterUnitChange(ctrl, 'mm');
    CalculatorPreviewHelper.updateLivePreview(ctrl);
    expect(ctrl.livePreviewAreaSqFt, closeTo(centerSqFtBefore, 0.5));

    // Center Round unit test
    ctrl.hasCentralDesign = false;
    ctrl.isCenterCeilingOn = true;
    ctrl.customCenterUnit = 'Feet';
    ctrl.customCenterRadiusController.text = '3';
    CalculatorPreviewHelper.updateLivePreview(ctrl);
    final roundSqFtBefore = ctrl.livePreviewAreaSqFt;
    CalculatorUnitHelper.handleCustomCenterUnitChange(ctrl, 'Inches');
    CalculatorPreviewHelper.updateLivePreview(ctrl);
    expect(ctrl.livePreviewAreaSqFt, closeTo(roundSqFtBefore, 0.5));
  });
}
