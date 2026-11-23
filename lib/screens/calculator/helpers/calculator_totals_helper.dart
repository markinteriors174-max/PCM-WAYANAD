import '../calculator_controller.dart';
import '../../../models/quotation.dart';

class CalculatorTotalsHelper {
  static void updateProjectTotals(CalculatorController ctrl) {
    double subtotal = 0.0;
    double totalAreaSqFt = 0.0;

    // Check if we have active room measurement items
    final bool hasItems = ctrl.currentItems.isNotEmpty;

    if (hasItems) {
      // Clear any outdated/cached manual amount so it never overrides real room measurements
      ctrl.manualAmountController.clear();

      for (var item in ctrl.currentItems) {
        // Skip hidden/excluded items from calculation
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
    } else {
      // Fallback draft when no room measurement items exist yet
      final double manualAmt = double.tryParse(ctrl.manualAmountController.text) ?? 0.0;
      if (manualAmt > 0) {
        final double advanceAmt = ctrl.currentPayments.fold(0.0, (sum, item) => sum + item.amount);
        ctrl.projectTotalAmount = manualAmt;
        ctrl.projectDiscountAmount = 0.0;
        ctrl.projectTotalAreaSqFt = 0.0;
        ctrl.balanceAmount = manualAmt - advanceAmt;
        ctrl.notifyUI();
        return;
      }
    }

    double total = subtotal;

    // 1. Include 5% Wastage Buffer if enabled
    if (ctrl.includeWastage) {
      total = total * 1.05;
      totalAreaSqFt = totalAreaSqFt * 1.05;
    }

    // 2. Apply Discount if specified
    final discountPercent = ctrl.discountPercent;
    final discountAmt = (discountPercent > 0) ? (total * (discountPercent / 100.0)) : 0.0;
    final finalBaseTotal = total - discountAmt;

    // 3. Deduct advance payments for balance
    final double advanceAmt = ctrl.currentPayments.fold(0.0, (sum, item) => sum + item.amount);

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
