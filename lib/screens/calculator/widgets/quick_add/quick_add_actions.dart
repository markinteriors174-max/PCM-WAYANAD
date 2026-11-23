import '../../calculator_controller.dart';

class QuickAddActions {
  static void toggleCentral(CalculatorController ctrl, bool val) {
    ctrl.hasCentralDesign = val;
    ctrl.isCenterCeilingOn = val;
    if (!val) {
      ctrl.centralLengthController.clear();
      ctrl.centralWidthController.clear();
      ctrl.centralQuantityController.text = '1';
      ctrl.centralAreaController.clear();
      ctrl.centralRateController.clear();
    }
    ctrl.updateLivePreview();
    ctrl.triggerAutoSave();
    ctrl.notifyUI();
  }

  static void toggleCove(CalculatorController ctrl, bool val) {
    ctrl.hasCove = val;
    ctrl.isCoveCeilingOn = val;
    ctrl.isDesignCeilingOn = val;
    if (!val) {
      ctrl.coveLengthController.clear();
      ctrl.coveWidthController.clear();
      ctrl.coveQuantityController.text = '1';
      ctrl.coveRftController.clear();
      ctrl.coveRateController.clear();
      ctrl.isCoveRateCustomized = false;
    } else {
      if (ctrl.coveRateController.text.trim().isEmpty && ctrl.rateController.text.trim().isNotEmpty) {
        ctrl.coveRateController.text = ctrl.rateController.text.trim();
      }
    }
    ctrl.updateLivePreview();
    ctrl.triggerAutoSave();
    ctrl.notifyUI();
  }

  static void toggleCeilingDesign(CalculatorController ctrl, bool val) {
    ctrl.isCeilingDesign = val;
    ctrl.isPlainCeilingOn = val;

    if (!val) {
      ctrl.lengthController.clear();
      ctrl.widthController.clear();
      ctrl.quantityController.text = '1';
    }

    ctrl.updateLivePreview();
    ctrl.triggerAutoSave();
    ctrl.notifyUI();
  }
}
