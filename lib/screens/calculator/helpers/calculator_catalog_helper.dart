import 'package:shared_preferences/shared_preferences.dart';
import '../calculator_controller.dart';

class CalculatorCatalogHelper {
  static Future<void> addNewCeilingType(CalculatorController ctrl, String name) async {
    if (name.trim().isEmpty || ctrl.ceilingTypes.containsKey(name.trim())) return;
    final cleanName = name.trim();
    
    ctrl.ceilingTypes[cleanName] = 0.0;
    ctrl.brandsMap[cleanName] = ['Other']; // Base default brand
    ctrl.selectedCeilingType = cleanName;
    ctrl.selectedBrand = 'Other';
    
    final prefs = await SharedPreferences.getInstance();
    final customCeilings = prefs.getStringList('custom_ceilings') ?? [];
    customCeilings.add(cleanName);
    await prefs.setStringList('custom_ceilings', customCeilings);
    
    ctrl.notifyUI();
    ctrl.triggerAutoSave();
  }

  static Future<void> addNewBrand(CalculatorController ctrl, String ceilingType, String name) async {
    if (name.trim().isEmpty || !ctrl.brandsMap.containsKey(ceilingType)) return;
    final cleanName = name.trim();
    if (ctrl.brandsMap[ceilingType]!.contains(cleanName)) return;

    ctrl.brandsMap[ceilingType]!.insert(0, cleanName);
    ctrl.selectedBrand = cleanName;

    final prefs = await SharedPreferences.getInstance();
    final customBrands = prefs.getStringList('custom_brands') ?? [];
    customBrands.add('$ceilingType||$cleanName');
    await prefs.setStringList('custom_brands', customBrands);

    ctrl.notifyUI();
    ctrl.triggerAutoSave();
  }

  static Future<void> addNewDesign(CalculatorController ctrl, String name) async {
    if (name.trim().isEmpty || ctrl.designTypes.contains(name.trim())) return;
    final cleanName = name.trim();
    
    ctrl.designTypes.insert(0, cleanName);
    ctrl.selectedDesign = cleanName;

    final prefs = await SharedPreferences.getInstance();
    final customDesigns = prefs.getStringList('custom_designs') ?? [];
    customDesigns.add(cleanName);
    await prefs.setStringList('custom_designs', customDesigns);

    ctrl.notifyUI();
    ctrl.triggerAutoSave();
  }

  static Future<void> removeDesign(CalculatorController ctrl, String name) async {
    ctrl.designTypes.remove(name);
    
    final prefs = await SharedPreferences.getInstance();
    final customDesigns = prefs.getStringList('custom_designs') ?? [];
    if (customDesigns.contains(name)) {
      customDesigns.remove(name);
      await prefs.setStringList('custom_designs', customDesigns);
    }
    
    if (ctrl.selectedDesign == name) {
      ctrl.selectedDesign = null;
      ctrl.designController.clear();
    }
    
    ctrl.notifyUI();
    ctrl.triggerAutoSave();
  }
}
