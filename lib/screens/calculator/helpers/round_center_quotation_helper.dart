import '../calculator_controller.dart';
import '../../../models/quotation.dart';

class RoundCenterQuotationHelper {
  static void addRoundCenterItems(
    CalculatorController ctrl,
    List<QuotationItem> targetList, {
    required String roomName,
    required String ceilingType,
    required String brandName,
    required double factor,
    required double userRate,
    required double q,
  }) {
    double ccL = double.tryParse(ctrl.customCenterLengthController.text.replaceAll(',', '.')) ?? 0.0;
    double ccW = double.tryParse(ctrl.customCenterWidthController.text.replaceAll(',', '.')) ?? 0.0;
    double ccQ = double.tryParse(ctrl.customCenterQuantityController.text.replaceAll(',', '.')) ?? 1.0;
    if (ccQ == 0) ccQ = 1.0;
    double primaryArea = ccL * ccW * ccQ;

    final newItem = QuotationItem(
      roomName: roomName,
      ceilingType: ceilingType,
      unit: ctrl.customCenterUnit.isNotEmpty ? ctrl.customCenterUnit : ctrl.unit,
      length: ccL,
      width: ccW,
      height: 0,
      quantity: q,
      area: primaryArea > 0 ? primaryArea * q : 0.0,
      rate: userRate,
      amount: (primaryArea > 0 ? primaryArea * q : 0.0) * factor * userRate,
      brandName: brandName,
      designName: 'Round Design',
      floor: ctrl.selectedFloor,
      roomNumber: ctrl.roomNumberController.text.trim(),
      colorPattern: ctrl.selectedColorPattern,
      hasCentralDesign: true,
      centralArea: primaryArea,
      centralLength: ccL,
      centralWidth: ccW,
      centralQuantity: ccQ,
      centralUnit: ctrl.customCenterUnit,
    );

    final existingIdx = targetList.indexWhere((item) => item.roomName == roomName && item.designName == 'Round Design');
    if (existingIdx >= 0) {
      targetList[existingIdx] = newItem;
    } else {
      targetList.add(newItem);
    }
  }
}
