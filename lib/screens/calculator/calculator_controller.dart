import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/quotation.dart';
import '../../services/database_service.dart';
import 'helpers/calculator_catalog_helper.dart';
import 'helpers/calculator_input_helper.dart';
import 'helpers/calculator_quotation_helper.dart';
import 'helpers/calculator_database_helper.dart';

class CalculatorController extends ChangeNotifier {
  // --- STATE FIELDS ---
  int? activeProjectId;
  bool isSaving = false; // Prevents duplicate saves/stubs
  StreamSubscription? syncSubscription;
  Timer? debounceTimer;
  String lastLength = '';
  String lastWidth = '';

  final clientNameController = TextEditingController();
  final clientLocationController = TextEditingController();
  final folderController = TextEditingController();
  final clientPhoneController = TextEditingController();
  final unitNumberController = TextEditingController(text: 'UNIT-${DateFormat('yyyyMMdd-HHmm').format(DateTime.now())}');
  
  final lengthController = TextEditingController();
  final widthController = TextEditingController();
  final heightController = TextEditingController();
  final thicknessController = TextEditingController();
  final brandController = TextEditingController();
  final designController = TextEditingController();
  final roomController = TextEditingController();
  final quantityController = TextEditingController(text: '1');
  final rateController = TextEditingController();
  final myMarginController = TextEditingController();
  final areaController = TextEditingController(); 
  
  // New project pricing and design controllers
  final globalMaterialCostController = TextEditingController();
  final globalMarginController = TextEditingController();
  final centralAreaController = TextEditingController();
  final centralRateController = TextEditingController();
  final centralLengthController = TextEditingController();
  final centralWidthController = TextEditingController();
  final centralQuantityController = TextEditingController(text: '1');
  final coveRftController = TextEditingController();
  final coveRateController = TextEditingController();
  final coveLengthController = TextEditingController();
  final coveWidthController = TextEditingController();
  final coveQuantityController = TextEditingController(text: '1');
  final coveLength2Controller = TextEditingController();
  final coveWidth2Controller = TextEditingController();
  final coveQuantity2Controller = TextEditingController(text: '1');
  
  final List<CentralDesignRow> extraCentralRows = [];
  final List<CoveLightRow> extraCoveRows = [];
  
  final manualWeightController = TextEditingController();
  final manualAmountController = TextEditingController();
  final originalAmountController = TextEditingController();
  final revisionNoteController = TextEditingController();
  final discountController = TextEditingController(text: '0');
  
  double get discountPercent => double.tryParse(discountController.text) ?? 0.0;
  
  final List<PaymentRecord> currentPayments = [];
  final List<QuotationItem> currentItems = [];

  // Project Progress & Signature State
  String projectStatus = 'Planning';
  String? approvalSignature;

  String unit = 'SqFt';
  String centralUnit = 'SqFt';
  String coveUnit = 'RFT';
  bool get isMetric => unit == 'Meters' || unit == 'SqM' || unit == 'RMT' || unit == 'cm' || unit == 'mm';
  bool get isAreaUnit => unit == 'SqFt' || unit == 'SqM' || unit == 'Meters' || unit == 'Inches' || unit == 'mm' || unit == 'Feet';
  String? selectedRoom = 'Bedroom 1';
  String? selectedCeilingType;
  String? selectedBrand;
  String? selectedDesign;
  
  final List<String> rooms = ['Living Room', 'Bedroom 1', 'Bedroom 2', 'Kitchen', 'Dining Area', 'Bathroom', 'Balcony', 'Cornice', 'Wall Design', 'Other'];
  final List<String> designTypes = ['Plain Design', 'Designer Ceiling', 'Cornice', 'Wall Design', 'Other'];
  final Map<String, double> ceilingTypes = {
    'Gypsum Board': 0.0, 'PVC Board': 0.0, 'Grid Ceiling': 0.0, 'Classic Arch': 0.0, 'Insu Board (Insulation Board)': 0.0,
    'Fiber Cement Board': 0.0, 'Mineral Fiber Board': 0.0, 'Wooden Ceiling Panels': 0.0, 'Metal Ceiling Panels': 0.0,
    'Louvers (Decorative Panels)': 0.0, 'Plywood': 0.0, 'WPC (Wood Plastic Composite)': 0.0, 'Other': 0.0,
  };
  
  final Map<String, List<String>> brandsMap = {
    'Gypsum Board': ['Gyproc', 'USG Boral', 'Saint-Gobain', 'Elephant', 'Shera', 'Other'],
    'PVC Board': ['Premier', 'Euro', 'Local Kerala Brands', 'Other'],
    'Grid Ceiling': ['Armstrong', 'Gyproc', 'USG Boral', 'Local', 'Other'],
    'Classic Arch': ['Local', 'Other'], 'Insu Board (Insulation Board)': ['Local', 'Other'],
    'Fiber Cement Board': ['Local', 'Other'], 'Mineral Fiber Board': ['Local', 'Other'],
    'Wooden Ceiling Panels': ['Local', 'Other'], 'Metal Ceiling Panels': ['Local', 'Other'],
    'Louvers (Decorative Panels)': ['Local', 'Other'], 'Plywood': ['Local', 'Other'],
    'WPC (Wood Plastic Composite)': ['Local', 'Other'], 'Other': ['Local', 'Other'],
  };

  double projectTotalAmount = 0;
  double projectDiscountAmount = 0;
  double balanceAmount = 0;
  double projectTotalAreaSqFt = 0;
  double livePreviewAmount = 0;
  double livePreviewAreaSqFt = 0;
  double livePreviewMainAreaSqFt = 0;
  bool includeWastage = false;
  bool includeDigitalSignature = false;
  bool includeBankDetails = true;
  bool showSavedIndicator = false;
  
  bool isCeilingDesign = true;
  bool hasCentralDesign = false;
  bool hasCove = false;

  Timer? _lookupDebounce;

  void notifyUI() => notifyListeners();

  // --- DYNAMIC LOOKUP LOGIC ---
  void onClientInfoChanged(String value, String field) {
    triggerAutoSave();
    
    _lookupDebounce?.cancel();
    _lookupDebounce = Timer(const Duration(milliseconds: 500), () async {
      if (value.trim().length < 3) return;

      try {
        final quotations = await DatabaseService.instance.getQuotations();
        Quotation? match;

        if (field == 'phone') {
          final cleanPhone = value.replaceAll(RegExp(r'\D'), '');
          if (cleanPhone.length < 5) return;
          match = quotations.cast<Quotation?>().firstWhere(
            (q) => q!.clientPhone.replaceAll(RegExp(r'\D'), '').contains(cleanPhone),
            orElse: () => null,
          );
        } else if (field == 'name') {
          match = quotations.cast<Quotation?>().firstWhere(
            (q) => q!.clientName.toLowerCase().contains(value.toLowerCase()),
            orElse: () => null,
          );
        } else if (field == 'location') {
          match = quotations.cast<Quotation?>().firstWhere(
            (q) => q!.clientLocation.toLowerCase().contains(value.toLowerCase()),
            orElse: () => null,
          );
        }

        if (match != null) {
          // AUTO-FILL only if fields are empty or substantially different to prevent overwriting active typing
          if (field != 'name' && clientNameController.text.isEmpty) {
            clientNameController.text = match.clientName;
          }
          if (field != 'phone' && clientPhoneController.text.isEmpty) {
            clientPhoneController.text = match.clientPhone;
          }
          if (field != 'location' && clientLocationController.text.isEmpty) {
            clientLocationController.text = match.clientLocation;
          }
          
          if (unitNumberController.text.isEmpty || unitNumberController.text.startsWith('UNIT-')) {
            unitNumberController.text = match.unitNumber;
          }
          
          // CRITICAL: If we found a match and the current list is empty, re-fetch and lock history
          if (currentItems.isEmpty && activeProjectId == null) {
            loadQuotationState(match);
          }
          
          notifyUI();
        }
      } catch (e) {
        debugPrint('Lookup Error: $e');
      }
    });
  }

  void disposeAll() {
    syncSubscription?.cancel();
    debounceTimer?.cancel();
    manualWeightController.dispose();
    manualAmountController.dispose();
    myMarginController.dispose();
    globalMaterialCostController.dispose();
    globalMarginController.dispose();
    centralAreaController.dispose();
    centralRateController.dispose();
    centralLengthController.dispose();
    centralWidthController.dispose();
    centralQuantityController.dispose();
    coveRftController.dispose();
    coveRateController.dispose();
    coveLengthController.dispose();
    coveWidthController.dispose();
    coveQuantityController.dispose();
    coveLength2Controller.dispose();
    coveWidth2Controller.dispose();
    coveQuantity2Controller.dispose();
    for (var r in extraCentralRows) {
      r.lengthController.dispose();
      r.widthController.dispose();
      r.quantityController.dispose();
      r.areaController.dispose();
    }
    for (var r in extraCoveRows) {
      r.lengthController.dispose();
      r.widthController.dispose();
      r.quantityController.dispose();
    }
    folderController.dispose();
    thicknessController.dispose();
    brandController.dispose();
    designController.dispose();
    roomController.dispose();
    areaController.dispose();
    originalAmountController.dispose();
    revisionNoteController.dispose();
    discountController.dispose();
  }

  double getDefaultRate(String? ceilingType) {
    final globalCost = double.tryParse(globalMaterialCostController.text) ?? 0.0;
    final globalMarginVal = double.tryParse(globalMarginController.text) ?? 0.0;
    if (globalCost > 0 || globalMarginVal > 0) {
      return globalCost + globalMarginVal;
    }
    if (ceilingType != null) {
      return ceilingTypes[ceilingType] ?? 0.0;
    }
    return 0.0;
  }

  double calculateDefaultCoveRft(double l, double w, String unit) {
    if (l <= 0 || w <= 0) return 0.0;
    final perimeter = 2 * (l + w);
    switch (unit) {
      case 'Meters': return perimeter * 3.28084;
      case 'Inches': return perimeter / 12.0;
      case 'mm': return perimeter / 304.8;
      default: return perimeter; // Feet
    }
  }

  Future<double> getMaterialCostPerSqFt(String ceilingType) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Core built-in materials definition
    final builtIn = {
      'gypsum_board_4x6': {'name': 'Gypsum Board', 'price': 550.0, 'length': 4.0, 'width': 6.0},
      'pvc_panel_10x1': {'name': 'PVC Panel', 'price': 120.0, 'length': 10.0, 'width': 1.0},
      'grid_ceiling_tile_2x2': {'name': 'Grid Ceiling', 'price': 80.0, 'length': 2.0, 'width': 2.0},
      'calcium_silicate_2x2': {'name': 'Calcium Silicate', 'price': 150.0, 'length': 2.0, 'width': 2.0},
      'metal_sheet_4x8': {'name': 'Metal Sheet', 'price': 900.0, 'length': 4.0, 'width': 8.0},
    };
    
    final List<Map<String, dynamic>> allMaterials = [];
    
    for (var entry in builtIn.entries) {
      final id = entry.key;
      final defaultVal = entry.value;
      final price = prefs.getDouble('pricing_${id}_price') ?? defaultVal['price'] as double;
      final length = prefs.getDouble('pricing_${id}_length') ?? defaultVal['length'] as double;
      final width = prefs.getDouble('pricing_${id}_width') ?? defaultVal['width'] as double;
      final name = defaultVal['name'] as String;
      allMaterials.add({
        'id': id,
        'name': name,
        'price': price,
        'length': length,
        'width': width,
      });
    }
    
    final customIds = prefs.getStringList('custom_material_ids') ?? [];
    for (var id in customIds) {
      final name = prefs.getString('pricing_${id}_name') ?? 'Custom Material';
      final price = prefs.getDouble('pricing_${id}_price') ?? 0.0;
      final length = prefs.getDouble('pricing_${id}_length') ?? 1.0;
      final width = prefs.getDouble('pricing_${id}_width') ?? 1.0;
      allMaterials.add({
        'id': id,
        'name': name,
        'price': price,
        'length': length,
        'width': width,
      });
    }
    
    final cleanCeiling = ceilingType.toLowerCase().replaceAll(' ', '');
    Map<String, dynamic>? bestMatch;
    
    for (var mat in allMaterials) {
      final cleanMatName = mat['name'].toString().toLowerCase().replaceAll(' ', '');
      if (cleanCeiling.contains(cleanMatName) || cleanMatName.contains(cleanCeiling)) {
        bestMatch = mat;
        break;
      }
    }
    
    if (bestMatch == null) {
      for (var mat in allMaterials) {
        final name = mat['name'].toString().toLowerCase();
        if (name.contains('gypsum') && cleanCeiling.contains('gypsum')) {
          bestMatch = mat;
          break;
        } else if (name.contains('pvc') && cleanCeiling.contains('pvc')) {
          bestMatch = mat;
          break;
        } else if (name.contains('grid') && cleanCeiling.contains('grid')) {
          bestMatch = mat;
          break;
        } else if (name.contains('calcium') && cleanCeiling.contains('calcium')) {
          bestMatch = mat;
          break;
        } else if (name.contains('metal') && cleanCeiling.contains('metal')) {
          bestMatch = mat;
          break;
        }
      }
    }
    
    if (bestMatch != null) {
      final area = bestMatch['length'] * bestMatch['width'];
      if (area > 0) {
        return ((bestMatch['price'] / area) * 100).truncateToDouble() / 100.0;
      }
    }
    
    return 0.0;
  }

  // --- DELEGATED METHODS ---
  void loadQuotationState(Quotation quotation) {
    // FIX: Guard against accidental state overwrite/clearing if items already exist in current session
    if (currentItems.isNotEmpty && activeProjectId == null) {
      debugPrint('PCM_DEBUG: Skipping auto-load of existing project to protect current session items.');
      return;
    }

    activeProjectId = quotation.id;
    clientNameController.text = quotation.clientName;
    clientLocationController.text = quotation.clientLocation;
    folderController.text = quotation.locationFolder ?? quotation.clientLocation;
    clientPhoneController.text = quotation.clientPhone;
    unitNumberController.text = quotation.unitNumber;
    
    currentItems.clear();
    currentItems.addAll(quotation.items);
    
    manualAmountController.text = quotation.manualAmount > 0 ? quotation.manualAmount.toString() : '';
    manualWeightController.text = quotation.manualWeight > 0 ? quotation.manualWeight.toString() : '';
    globalMaterialCostController.text = quotation.globalMaterialCost > 0 ? quotation.globalMaterialCost.toString() : '';
    globalMarginController.text = quotation.globalMargin > 0 ? quotation.globalMargin.toString() : '';
    originalAmountController.text = quotation.originalAmount != null ? quotation.originalAmount.toString() : '';
    revisionNoteController.text = quotation.revisionNote ?? '';
    discountController.text = quotation.discount > 0 ? quotation.discount.toString() : '0';
    
    currentPayments.clear();
    currentPayments.addAll(quotation.payments);
    
    includeWastage = quotation.includeWastage;
    includeDigitalSignature = quotation.includeDigitalSignature;
    includeBankDetails = quotation.includeBankDetails;
    projectStatus = quotation.projectStatus;
    approvalSignature = quotation.approvalSignature;
    updateProjectTotals();
    notifyUI();
    triggerAutoSave();
  }

  void initLoad(VoidCallback onShowSaved) {
    CalculatorDatabaseHelper.loadRatesFromPrefs(this);
    CalculatorDatabaseHelper.loadUiState(this);
    CalculatorDatabaseHelper.listenForSync(this, onShowSaved);
  }

  Future<void> loadProject(String projectId, VoidCallback onShowSaved) => CalculatorDatabaseHelper.loadProject(this, projectId, onShowSaved);
  void triggerAutoSave() => CalculatorDatabaseHelper.triggerAutoSave(this);
  Future<void> saveToDatabase({bool showSnackBar = true, VoidCallback? onSuccess}) => CalculatorDatabaseHelper.saveToDatabase(this, showSnackBar: showSnackBar, onSuccess: onSuccess);

  void startNewProject() {
    activeProjectId = null;
    clientNameController.clear();
    clientLocationController.clear();
    folderController.clear();
    clientPhoneController.clear();
    unitNumberController.text = 'UNIT-${DateFormat('yyyyMMdd-HHmm').format(DateTime.now())}';
    
    currentItems.clear();
    currentPayments.clear();
    
    manualWeightController.clear();
    manualAmountController.clear();
    originalAmountController.clear();
    revisionNoteController.clear();
    discountController.text = '0';
    
    projectStatus = 'Planning';
    approvalSignature = null;
    
    projectTotalAmount = 0;
    projectDiscountAmount = 0;
    balanceAmount = 0;
    projectTotalAreaSqFt = 0;
    livePreviewAmount = 0;
    livePreviewAreaSqFt = 0;
    livePreviewMainAreaSqFt = 0;
    includeWastage = false;
    includeDigitalSignature = false;
    includeBankDetails = true;
    showSavedIndicator = false;
    
    extraCentralRows.clear();
    extraCoveRows.clear();
    
    resetInputs();
    triggerAutoSave();
  }


  void handleUnitChange(String newUnit) => CalculatorInputHelper.handleUnitChange(this, newUnit);
  void updateLivePreview() => CalculatorInputHelper.updateLivePreview(this);
  void resetInputs() => CalculatorInputHelper.resetInputs(this);
  void loadItemIntoControllers(QuotationItem item) => CalculatorInputHelper.loadItemIntoControllers(this, item);

  void updateProjectTotals() => CalculatorQuotationHelper.updateProjectTotals(this);
  bool addToQuotation(Function(String) onError) => CalculatorQuotationHelper.addToQuotation(this, onError);
  bool updateQuotationItem(int index, Function(String) onError) => CalculatorQuotationHelper.updateQuotationItem(this, index, onError);
  void deleteQuotationItem(int index) => CalculatorQuotationHelper.deleteQuotationItem(this, index);
  
  void deleteSubItem(int index, String type) {
    if (index < 0 || index >= currentItems.length) return;
    final item = currentItems[index];

    double mainArea = item.isCeilingDesign 
        ? (item.length * item.width) 
        : item.length;
    if (item.length == 0 && item.width == 0 && item.area > 0) {
      mainArea = (item.area / item.quantity) - item.coveRft - item.centralArea;
      if (mainArea < 0) mainArea = 0;
    }

    double cove1 = type == 'Cove Light' ? 0.0 : item.coveRft;
    double cove2 = type == 'Central Design' ? 0.0 : item.centralArea;

    double totalSelectedUnit = (mainArea + cove1 + cove2) * item.quantity;

    double factor = 1.0;
    if (item.unit == 'Meters' || item.unit == 'SqM') {
      factor = 10.764;
    } else if (item.unit == 'Inches') {
      factor = 1.0 / 144.0;
    } else if (item.unit == 'mm') {
      factor = 10.764 / 1000000.0;
    }
    double itemAmount = totalSelectedUnit * factor * item.rate;

    currentItems[index] = QuotationItem(
      id: item.id,
      quotationId: item.quotationId,
      roomName: item.roomName,
      ceilingType: item.ceilingType,
      unit: item.unit,
      length: item.length,
      width: item.width,
      height: item.height,
      quantity: item.quantity,
      area: totalSelectedUnit,
      rate: item.rate,
      amount: itemAmount,
      thickness: item.thickness,
      brandName: item.brandName,
      designName: item.designName,
      isCeilingDesign: item.isCeilingDesign,
      hasCentralDesign: type == 'Central Design' ? false : item.hasCentralDesign,
      centralArea: type == 'Central Design' ? 0.0 : item.centralArea,
      centralRate: type == 'Central Design' ? 0.0 : item.centralRate,
      centralLength: type == 'Central Design' ? 0.0 : item.centralLength,
      centralWidth: type == 'Central Design' ? 0.0 : item.centralWidth,
      centralQuantity: type == 'Central Design' ? 1.0 : item.centralQuantity,
      centralUnit: item.centralUnit,
      hasCove: type == 'Cove Light' ? false : item.hasCove,
      coveRft: type == 'Cove Light' ? 0.0 : item.coveRft,
      coveRate: type == 'Cove Light' ? 0.0 : item.coveRate,
      coveLength: type == 'Cove Light' ? 0.0 : item.coveLength,
      coveWidth: type == 'Cove Light' ? 0.0 : item.coveWidth,
      coveQuantity: type == 'Cove Light' ? 1.0 : item.coveQuantity,
      coveLength2: type == 'Cove Light' ? 0.0 : item.coveLength2,
      coveWidth2: type == 'Cove Light' ? 0.0 : item.coveWidth2,
      coveQuantity2: type == 'Cove Light' ? 1.0 : item.coveQuantity2,
      coveUnit: item.coveUnit,
    );

    updateProjectTotals();
    triggerAutoSave();
    notifyUI();
  }

  void addPayment(PaymentRecord payment) => CalculatorQuotationHelper.addPayment(this, payment);

  Future<void> addNewCeilingType(String name) => CalculatorCatalogHelper.addNewCeilingType(this, name);
  Future<void> addNewBrand(String ceilingType, String name) => CalculatorCatalogHelper.addNewBrand(this, ceilingType, name);
  Future<void> addNewDesign(String name) => CalculatorCatalogHelper.addNewDesign(this, name);
  Future<void> removeDesign(String name) => CalculatorCatalogHelper.removeDesign(this, name);
}

class CentralDesignRow {
  final TextEditingController lengthController = TextEditingController();
  final TextEditingController widthController = TextEditingController();
  final TextEditingController quantityController = TextEditingController(text: '1');
  final TextEditingController areaController = TextEditingController();
}

class CoveLightRow {
  final TextEditingController lengthController = TextEditingController();
  final TextEditingController widthController = TextEditingController(); // Height
  final TextEditingController quantityController = TextEditingController(text: '1');
}
