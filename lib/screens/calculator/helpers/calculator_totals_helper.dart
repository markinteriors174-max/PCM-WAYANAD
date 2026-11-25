import '../calculator_controller.dart';
import '../../../models/quotation.dart';

class CalculatorTotalsHelper {
  static void updateProjectTotals(CalculatorController ctrl) {
    double subtotal = 0.0;
    double totalAreaSqFt = 0.0;

    final bool hasItems = ctrl.currentItems.isNotEmpty;

    if (hasItems) {
      for (var item in ctrl.currentItems) {
        if (item.isHidden) continue;

        double factor = 1.0;
        if (item.unit == 'Meters' || item.unit == 'SqM') {
          factor = 10.764;
        } else if (item.unit == 'Inches') {
          factor = 1.0 / 144.0;
        } else if (item.unit == 'mm') {
          factor = 10.764 / 1000000.0;
        }

        final double itemAmt = item.amount > 0 ? item.amount : (item.area * factor * item.rate);
        subtotal += itemAmt;
        totalAreaSqFt += item.area * factor;
      }
    }

    double total = subtotal;

    if (ctrl.includeWastage) {
      total = total * 1.05;
      totalAreaSqFt = totalAreaSqFt * 1.05;
    }

    final discountPercent = ctrl.discountPercent;
    final discountAmt = (discountPercent > 0) ? (total * (discountPercent / 100.0)) : 0.0;
    final finalBaseTotal = total - discountAmt;

    // Optional Handwritten Final / Adjusted Amount Override
    final double manualOverride = double.tryParse(ctrl.manualAmountController.text) ?? 0.0;
    final double effectiveTotal = manualOverride > 0 ? manualOverride : finalBaseTotal;

    final double advanceAmt = ctrl.currentPayments.fold(0.0, (sum, item) => sum + item.amount);

    ctrl.projectTotalAmount = effectiveTotal;
    ctrl.projectDiscountAmount = discountAmt;
    ctrl.projectTotalAreaSqFt = totalAreaSqFt;
    ctrl.balanceAmount = effectiveTotal - advanceAmt;
    ctrl.notifyUI();
  }

  static void addPayment(CalculatorController ctrl, PaymentRecord payment) {
    ctrl.currentPayments.add(payment);
    updateProjectTotals(ctrl);
    ctrl.triggerAutoSave();
    ctrl.notifyUI();
  }

  static void deleteQuotationItem(CalculatorController ctrl, int index) {
    if (index >= 0 && index < ctrl.currentItems.length) {
      ctrl.currentItems.removeAt(index);
      updateProjectTotals(ctrl);
      ctrl.triggerAutoSave();
      ctrl.notifyUI();
    }
  }
}
