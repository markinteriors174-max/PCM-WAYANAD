import '../calculator_controller.dart';
import '../../../models/quotation.dart';

class CalculatorResetHelper {
  static void resetInputs(CalculatorController ctrl) {
    ctrl.lengthController.clear(); 
    ctrl.widthController.clear(); 
    ctrl.heightController.clear(); 
    ctrl.thicknessController.clear(); 
    ctrl.areaController.clear(); 
    ctrl.brandController.clear(); 
    ctrl.roomController.clear(); 
    ctrl.designController.clear();
    ctrl.quantityController.text = '1'; 
    ctrl.centralAreaController.clear();
    ctrl.centralRateController.clear();
    ctrl.centralLengthController.clear();
    ctrl.centralWidthController.clear();
    ctrl.centralQuantityController.text = '1';
    ctrl.centralUnit = ctrl.isMetric ? 'SqM' : 'SqFt';
    ctrl.coveRftController.clear();
    ctrl.coveRateController.clear();
    ctrl.coveLengthController.clear();
    ctrl.coveWidthController.clear();
    ctrl.coveQuantityController.text = '1';
    ctrl.coveLength2Controller.clear();
    ctrl.coveWidth2Controller.clear();
    ctrl.coveQuantity2Controller.text = '1';
    ctrl.coveUnit = ctrl.isMetric ? 'RMT' : 'RFT';
    ctrl.isCeilingDesign = true;
    ctrl.hasCentralDesign = false;
    ctrl.hasCove = false;
    ctrl.livePreviewAmount = 0; 
    ctrl.livePreviewAreaSqFt = 0;
    ctrl.livePreviewMainAreaSqFt = 0;
    ctrl.lastLength = '';
    ctrl.lastWidth = '';
    ctrl.extraCentralRows.clear();
    ctrl.extraCoveRows.clear();
    ctrl.notifyUI();
    ctrl.triggerAutoSave();
  }

  static void loadItemIntoControllers(CalculatorController ctrl, QuotationItem item) {
    ctrl.extraCentralRows.clear();
    ctrl.extraCoveRows.clear();
    ctrl.selectedRoom = ctrl.rooms.contains(item.roomName) ? item.roomName : 'Other';
    if (ctrl.selectedRoom == 'Other') ctrl.roomController.text = item.roomName;
    
    String ceilingType = item.ceilingType;
    if (ceilingType.toLowerCase() == 'gypsum' || ceilingType.toLowerCase() == 'gypsum board') {
      ceilingType = 'Gypsum Board';
    }
    if (ceilingType.toLowerCase() == 'pvc ceiling' || ceilingType.toLowerCase() == 'pvc board') {
      ceilingType = 'PVC Board';
    }
    
    ctrl.selectedCeilingType = ceilingType;
    if (ctrl.selectedCeilingType != null && ctrl.brandsMap.containsKey(ctrl.selectedCeilingType)) {
      ctrl.selectedBrand = ctrl.brandsMap[ctrl.selectedCeilingType]!.contains(item.brandName) ? item.brandName : 'Other';
    } else {
      ctrl.selectedBrand = 'Other';
    }
    if (ctrl.selectedBrand == 'Other') ctrl.brandController.text = item.brandName ?? '';

    ctrl.selectedDesign = ctrl.designTypes.contains(item.designName) ? item.designName : 'Other';
    if (ctrl.selectedDesign == 'Other') ctrl.designController.text = item.designName;

    ctrl.unit = item.unit.isNotEmpty ? item.unit : 'SqFt';
    ctrl.lengthController.text = (item.isCeilingDesign && item.length > 0) ? item.length.toString() : '';
    ctrl.widthController.text = (item.isCeilingDesign && item.width > 0) ? item.width.toString() : '';
    ctrl.heightController.text = item.height > 0 ? item.height.toString() : '';
    ctrl.thicknessController.text = item.thickness > 0 ? item.thickness.toString() : '';
    ctrl.quantityController.text = item.quantity > 0 ? item.quantity.toString() : '1';
    ctrl.rateController.text = item.rate > 0 ? item.rate.toString() : '';
    
    ctrl.isCeilingDesign = item.isCeilingDesign || item.hasCentralDesign || item.hasCove;
    ctrl.hasCentralDesign = item.hasCentralDesign;
    
    double centralL = item.centralLength > 0 ? item.centralLength : (item.hasCentralDesign ? item.length : 0.0);
    double centralW = item.centralWidth > 0 ? item.centralWidth : (item.hasCentralDesign ? item.width : 0.0);
    ctrl.centralLengthController.text = centralL > 0 ? centralL.toString() : '';
    ctrl.centralWidthController.text = centralW > 0 ? centralW.toString() : '';
    ctrl.centralAreaController.text = item.centralArea > 0 ? item.centralArea.toString() : '';
    ctrl.centralRateController.text = item.centralRate > 0 ? item.centralRate.toString() : '';
    ctrl.centralQuantityController.text = item.centralQuantity > 0 ? item.centralQuantity.toString() : '1';
    ctrl.centralUnit = item.centralUnit;
    
    ctrl.hasCove = item.hasCove;
    double coveL = item.coveLength > 0 ? item.coveLength : (item.hasCove ? item.length : 0.0);
    double coveW = item.coveWidth > 0 ? item.coveWidth : (item.hasCove ? item.width : 0.0);
    ctrl.coveLengthController.text = coveL > 0 ? coveL.toString() : '';
    ctrl.coveWidthController.text = coveW > 0 ? coveW.toString() : '';
    ctrl.coveRftController.text = item.coveRft > 0 ? item.coveRft.toString() : '';
    ctrl.coveRateController.text = item.coveRate > 0 ? item.coveRate.toString() : '';
    ctrl.coveLengthController.text = coveL > 0 ? coveL.toString() : '';
    ctrl.coveWidthController.text = coveW > 0 ? coveW.toString() : '';
    ctrl.coveQuantityController.text = item.coveQuantity > 0 ? item.coveQuantity.toString() : '1';
    ctrl.coveLength2Controller.text = item.coveLength2 > 0 ? item.coveLength2.toString() : '';
    ctrl.coveWidth2Controller.text = item.coveWidth2 > 0 ? item.coveWidth2.toString() : '';
    ctrl.coveQuantity2Controller.text = item.coveQuantity2 > 0 ? item.coveQuantity2.toString() : '1';
    ctrl.coveUnit = item.coveUnit;
    
    bool isAreaUnit = item.unit == 'SqFt' || item.unit == 'SqM' || item.unit == 'Meters' || item.unit == 'Inches' || item.unit == 'mm' || item.unit == 'Feet';
    double expectedCeilingArea = item.isCeilingDesign ? (isAreaUnit ? (item.length * item.width) : item.length) : 0.0;
    double reconstructedCeilingArea = (item.area / item.quantity) - item.coveRft - item.centralArea;
    if ((reconstructedCeilingArea - expectedCeilingArea).abs() > 0.01) {
       ctrl.areaController.text = reconstructedCeilingArea.toStringAsFixed(2);
    } else {
       ctrl.areaController.text = '';
    }
    
    ctrl.lastLength = item.length > 0 ? item.length.toString() : '';
    ctrl.lastWidth = item.width > 0 ? item.width.toString() : '';
    
    ctrl.updateLivePreview();
    ctrl.notifyUI();
  }
}
