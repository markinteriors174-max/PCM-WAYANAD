import '../calculator_controller.dart';
import '../../../models/quotation.dart';
import 'calculator_totals_helper.dart';
import 'calculator_add_quotation_helper.dart';
import 'calculator_edit_quotation_helper.dart';

class CalculatorQuotationHelper {
  static void updateProjectTotals(CalculatorController ctrl) =>
      CalculatorTotalsHelper.updateProjectTotals(ctrl);

  static bool addToQuotation(CalculatorController ctrl, Function(String) onError) =>
      CalculatorAddQuotationHelper.addToQuotation(ctrl, onError);

  static bool updateQuotationItem(CalculatorController ctrl, int index, Function(String) onError) =>
      CalculatorEditQuotationHelper.updateQuotationItem(ctrl, index, onError);

  static void addPayment(CalculatorController ctrl, PaymentRecord payment) =>
      CalculatorTotalsHelper.addPayment(ctrl, payment);

  static void deleteQuotationItem(CalculatorController ctrl, int index) =>
      CalculatorTotalsHelper.deleteQuotationItem(ctrl, index);
}
