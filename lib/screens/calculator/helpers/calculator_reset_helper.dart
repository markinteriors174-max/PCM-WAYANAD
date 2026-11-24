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
    ctrl.selectedRoom = null;
    ctrl.designController.clear();
    ctrl.quantityController.text = '1'; 
    ctrl.unit = 'Meter';
    ctrl.rateController.text = '105.0';
    ctrl.centralAreaController.clear();
    ctrl.centralRateController.text = '105.0';
    ctrl.centralLengthController.clear();
    ctrl.centralWidthController.clear();
    ctrl.centralQuantityController.text = '1';
    ctrl.centralUnit = 'Meter';
    ctrl.customCenterRateController.text = '105.0';
    ctrl.customCenterUnit = 'Meter';
    ctrl.customCenterIncludeCircleArea = false;
    ctrl.coveRftController.clear();
    ctrl.coveRateController.text = '105.0';
    ctrl.isCoveRateCustomized = false;
    ctrl.coveLengthController.clear();
    ctrl.coveWidthController.clear();
    ctrl.coveQuantityController.text = '1';
    ctrl.coveLength2Controller.clear();
    ctrl.coveWidth2Controller.clear();
    ctrl.coveQuantity2Controller.text = '1';
    ctrl.coveUnit = 'Meter';
    ctrl.isCeilingDesign = true;
    ctrl.hasCentralDesign = false;
    ctrl.hasCove = false;
    ctrl.livePreviewAmount = 0; 
    ctrl.livePreviewAreaSqFt = 0;
    ctrl.livePreviewMainAreaSqFt = 0;
    ctrl.lastLength = '';
    ctrl.lastWidth = '';
    ctrl.extraPlainRows.clear();
    ctrl.extraCentralRows.clear();
    ctrl.extraCustomCentralRows.clear();
    ctrl.extraCoveRows.clear();
    ctrl.notifyUI();
    ctrl.triggerAutoSave();
  }

  static void loadItemIntoControllers(CalculatorController ctrl, QuotationItem item) {
    ctrl.extraCentralRows.clear();
    ctrl.extraCoveRows.clear();
    ctrl.selectedRoom = ctrl.rooms.contains(item.roomName) ? item.roomName : 'Other';
    if (ctrl.selectedRoom == 'Other') ctrl.roomController.text = item.roomName;
    if (item.floor.isNotEmpty) ctrl.selectedFloor = item.floor;
    if (item.roomNumber.isNotEmpty) ctrl.roomNumberController.text = item.roomNumber;
    if (item.colorPattern.isNotEmpty) ctrl.selectedColorPattern = item.colorPattern;
    
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

    ctrl.unit = item.unit.isNotEmpty ? item.unit : 'Meter';
    ctrl.lengthController.text = (item.isCeilingDesign && item.length > 0) ? item.length.toString() : '';
    ctrl.widthController.text = (item.isCeilingDesign && item.width > 0) ? item.width.toString() : '';
    ctrl.heightController.text = item.height > 0 ? item.height.toString() : '';
    ctrl.thicknessController.text = item.thickness > 0 ? item.thickness.toString() : '';
    ctrl.quantityController.text = item.quantity > 0 ? item.quantity.toString() : '1';
    ctrl.rateController.text = item.rate > 0 ? item.rate.toString() : '';
    
    ctrl.isCeilingDesign = item.isCeilingDesign || item.hasCentralDesign || item.hasCove;
    ctrl.hasCentralDesign = false;
    ctrl.hasCove = false;
    ctrl.isPlainCeilingOn = false;
    ctrl.isCoveCeilingOn = false;
    ctrl.isCenterCeilingOn = false;

    if (item.hasCove || item.designName.toLowerCase().contains('cove')) {
      ctrl.hasCove = true;
      ctrl.isCoveCeilingOn = true;
    } else if (item.hasCentralDesign) {
      ctrl.hasCentralDesign = true;
      ctrl.isCenterCeilingOn = true;
      final name = item.designName.toLowerCase();
      if (name.contains('round') || name.contains('curve') || name.contains('custom') || name.contains('circle') || name.contains('radius')) {
        ctrl.activeCenterType = 'Custom Center';
      } else {
        ctrl.activeCenterType = 'Standard (Center)';
      }
    } else {
      ctrl.isPlainCeilingOn = true;
      ctrl.isCeilingDesign = item.isCeilingDesign;
    }
    
    double centralL = item.centralLength > 0 ? item.centralLength : (item.hasCentralDesign ? item.length : 0.0);
    double centralW = item.centralWidth > 0 ? item.centralWidth : (item.hasCentralDesign ? item.width : 0.0);
    if (ctrl.activeCenterType == 'Custom Center') {
      ctrl.customCenterLengthController.text = centralL > 0 ? centralL.toString() : '';
      ctrl.customCenterWidthController.text = centralW > 0 ? centralW.toString() : '';
      ctrl.customCenterAreaController.text = item.centralArea > 0 ? item.centralArea.toString() : '';
      ctrl.customCenterRateController.text = item.rate > 0 ? item.rate.toString() : '';
      ctrl.customCenterQuantityController.text = item.centralQuantity > 0 ? item.centralQuantity.toString() : '1';
      ctrl.customCenterUnit = item.centralUnit.isNotEmpty ? item.centralUnit : 'Meter';
    } else {
      ctrl.centralLengthController.text = centralL > 0 ? centralL.toString() : '';
      ctrl.centralWidthController.text = centralW > 0 ? centralW.toString() : '';
      ctrl.centralAreaController.text = item.centralArea > 0 ? item.centralArea.toString() : '';
      ctrl.centralRateController.text = item.rate > 0 ? item.rate.toString() : '';
      ctrl.centralQuantityController.text = item.centralQuantity > 0 ? item.centralQuantity.toString() : '1';
      ctrl.centralUnit = item.centralUnit.isNotEmpty ? item.centralUnit : 'Meter';
    }
    ctrl.customCenterUnit = item.centralUnit.isNotEmpty ? item.centralUnit : 'Meter';
    
    ctrl.hasCove = item.hasCove;
    double coveL = item.coveLength > 0 ? item.coveLength : (item.hasCove ? item.length : (double.tryParse(ctrl.lengthController.text) ?? 0.0));
    double coveW = item.coveWidth > 0 ? item.coveWidth : (item.hasCove ? item.width : (double.tryParse(ctrl.widthController.text) ?? 0.0));
    
    if (ctrl.coveLengthController.text.isEmpty) {
      ctrl.coveLengthController.text = coveL > 0 ? coveL.toString() : (ctrl.lengthController.text.isNotEmpty ? ctrl.lengthController.text : '');
    }
    if (ctrl.coveLength2Controller.text.isEmpty) {
      ctrl.coveLength2Controller.text = coveW > 0 ? coveW.toString() : (ctrl.widthController.text.isNotEmpty ? ctrl.widthController.text : '');
    }
    
    ctrl.coveWidthController.text = item.coveWidth > 0 ? item.coveWidth.toString() : '';
    ctrl.coveRftController.text = item.coveRft > 0 ? item.coveRft.toString() : '';
    ctrl.coveRateController.text = item.coveRate > 0 ? item.coveRate.toString() : '';
    ctrl.isCoveRateCustomized = item.coveRate > 0 && item.rate > 0 && item.coveRate != item.rate;
    ctrl.coveQuantityController.text = item.coveQuantity > 0 ? item.coveQuantity.toString() : '1';
    ctrl.coveWidth2Controller.text = item.coveWidth2 > 0 ? item.coveWidth2.toString() : '';
    ctrl.coveQuantity2Controller.text = item.coveQuantity2 > 0 ? item.coveQuantity2.toString() : '1';
    ctrl.coveUnit = item.coveUnit.isNotEmpty ? item.coveUnit : 'Meter';
    
    bool isAreaUnit = item.unit == 'SqFt' || item.unit == 'SqM' || item.unit == 'Meters' || item.unit == 'Meter' || item.unit == 'Inches' || item.unit == 'mm' || item.unit == 'Feet' || item.unit == 'CM' || item.unit == 'cm';
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
