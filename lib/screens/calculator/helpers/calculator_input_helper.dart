import '../calculator_controller.dart';
import '../../../models/quotation.dart';
import 'calculator_unit_helper.dart';
import 'calculator_preview_helper.dart';
import 'calculator_reset_helper.dart';

class CalculatorInputHelper {
  static void handleUnitChange(CalculatorController ctrl, String newUnit) =>
      CalculatorUnitHelper.handleUnitChange(ctrl, newUnit);

  static double convertValue(double value, String from, String to) =>
      CalculatorUnitHelper.convertValue(value, from, to);

  static void updateLivePreview(CalculatorController ctrl) =>
      CalculatorPreviewHelper.updateLivePreview(ctrl);

  static void resetInputs(CalculatorController ctrl) =>
      CalculatorResetHelper.resetInputs(ctrl);

  static void loadItemIntoControllers(CalculatorController ctrl, QuotationItem item) =>
      CalculatorResetHelper.loadItemIntoControllers(ctrl, item);
}
