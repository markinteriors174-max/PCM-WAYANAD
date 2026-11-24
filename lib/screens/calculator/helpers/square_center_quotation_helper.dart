import '../calculator_controller.dart';
import '../../../models/quotation.dart';

class SquareCenterQuotationHelper {
  static void addSquareCenterItems(
    CalculatorController ctrl,
    List<QuotationItem> targetList, {
    required String roomName,
    required String ceilingType,
    required String brandName,
    required double factor,
    required double userRate,
    required double q,
  }) {
    double cL = double.tryParse(ctrl.centralLengthController.text.replaceAll(',', '.')) ?? 0.0;
    double cW = double.tryParse(ctrl.centralWidthController.text.replaceAll(',', '.')) ?? 0.0;
    double cQ = double.tryParse(ctrl.centralQuantityController.text.replaceAll(',', '.')) ?? 1.0;
    if (cQ == 0) cQ = 1.0;
    double primaryArea = cL * cW * cQ;

    final newItem = QuotationItem(
      roomName: roomName,
      ceilingType: ceilingType,
      unit: ctrl.centralUnit.isNotEmpty ? ctrl.centralUnit : ctrl.unit,
      length: cL,
      width: cW,
      height: 0,
      quantity: q,
      area: primaryArea > 0 ? primaryArea * q : 0.0,
      rate: userRate,
      amount: (primaryArea > 0 ? primaryArea * q : 0.0) * factor * userRate,
      brandName: brandName,
      designName: 'Square Design',
      floor: ctrl.selectedFloor,
      roomNumber: ctrl.roomNumberController.text.trim(),
      colorPattern: ctrl.selectedColorPattern,
      hasCentralDesign: true,
      centralArea: primaryArea,
      centralLength: cL,
      centralWidth: cW,
      centralQuantity: cQ,
      centralUnit: ctrl.centralUnit,
    );

    final existingIdx = targetList.indexWhere((item) => item.roomName == roomName && (item.designName == 'Square Design' || item.designName == 'Center Design'));
    if (existingIdx >= 0) {
      targetList[existingIdx] = newItem;
    } else {
      targetList.add(newItem);
    }
  }
}
