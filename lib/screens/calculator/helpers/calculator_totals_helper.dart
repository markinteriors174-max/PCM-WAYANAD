import '../calculator_controller.dart';
import '../../../models/quotation.dart';

class CalculatorTotalsHelper {
  static void updateProjectTotals(CalculatorController ctrl) {
    double total = 0;
    double totalAreaSqFt = 0;
    for (var item in ctrl.currentItems) {
      total += item.amount;
      double factor = 1.0;
      if (item.unit == 'Meters' || item.unit == 'SqM') {
        factor = 10.764;
      } else if (item.unit == 'Inches') {
        factor = 1.0 / 144.0;
      } else if (item.unit == 'mm') {
        factor = 10.764 / 1000000.0;
      }
      totalAreaSqFt += item.area * factor;
    }
    if (ctrl.includeWastage) {
      total = total * 1.05;
      totalAreaSqFt = totalAreaSqFt * 1.05;
    }

    final discountPercent = ctrl.discountPercent;
    final discountAmt = total * (discountPercent / 100.0);
    final discountedTotal = total - discountAmt;

    double manualAmt = double.tryParse(ctrl.manualAmountController.text) ?? 0;
    final finalBaseTotal = manualAmt > 0 ? manualAmt : discountedTotal;
    double advanceAmt = ctrl.currentPayments.fold(0.0, (sum, item) => sum + item.amount);
    
    ctrl.projectTotalAmount = finalBaseTotal; 
    ctrl.projectDiscountAmount = discountAmt;
    ctrl.projectTotalAreaSqFt = totalAreaSqFt;
    ctrl.balanceAmount = finalBaseTotal - advanceAmt; 
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
