import '../../calculator_controller.dart';

class QuickAddActions {
  static void toggleCentral(CalculatorController ctrl, bool val) {
    ctrl.hasCentralDesign = val;
    if (!val) {
      ctrl.centralLengthController.clear(); ctrl.centralWidthController.clear();
      ctrl.centralQuantityController.text = '1'; ctrl.centralAreaController.clear(); ctrl.centralRateController.clear();
    }
    ctrl.updateLivePreview(); ctrl.triggerAutoSave(); ctrl.notifyUI();
  }

  static void toggleCove(CalculatorController ctrl, bool val) {
    ctrl.hasCove = val;
    if (!val) {
      ctrl.coveLengthController.clear(); ctrl.coveWidthController.clear();
      ctrl.coveQuantityController.text = '1'; ctrl.coveRftController.clear(); ctrl.coveRateController.clear();
    }
    ctrl.updateLivePreview(); ctrl.triggerAutoSave(); ctrl.notifyUI();
  }

  static void toggleCeilingDesign(CalculatorController ctrl, bool val) {
    ctrl.isCeilingDesign = val;
    if (!val) {
      toggleCentral(ctrl, false);
      toggleCove(ctrl, false);
    }
    ctrl.updateLivePreview(); ctrl.triggerAutoSave(); ctrl.notifyUI();
  }
}
