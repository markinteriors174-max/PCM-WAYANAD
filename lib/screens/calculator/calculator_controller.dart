import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/quotation.dart';
import '../../models/client_model.dart';
import '../../models/rate_tier.dart';
import '../../services/database_service.dart';
import '../../services/client_service.dart';
import '../../services/customer_sync_service.dart';
import 'helpers/calculator_catalog_helper.dart';
import 'helpers/calculator_input_helper.dart';
import 'helpers/calculator_quotation_helper.dart';
import 'helpers/calculator_database_helper.dart';
import 'helpers/room_selector_helper.dart';
import 'brands/ceiling_board_brands.dart';
import 'brands/channel_brands.dart';

class CalculatorController extends ChangeNotifier {
  CalculatorController();

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
  final unitNumberController = TextEditingController();

  final headerNameController = TextEditingController(text: 'Madhusoodanan A S');
  final headerPhoneController = TextEditingController(text: '+91 93834 06185');
  final headerLocationController = TextEditingController(text: 'Padinjarathara, Wayanad');
  
  final lengthController = TextEditingController();
  final widthController = TextEditingController();
  final heightController = TextEditingController();
  final thicknessController = TextEditingController();
  final brandController = TextEditingController();
  final channelController = TextEditingController(text: 'Saint-Gobain Gypframe / Gypsteel');
  final customCeilingController = TextEditingController();
  final designController = TextEditingController();
  final roomController = TextEditingController();
  final roomNumberController = TextEditingController(text: '1');
  String selectedFloor = 'Ground Floor';
  String selectedColorPattern = '';
  final quantityController = TextEditingController(text: '1');
  final rateController = TextEditingController(text: '105.0');
  final myMarginController = TextEditingController();
  final areaController = TextEditingController(); 
  
  // New project pricing and design controllers
  final globalMaterialCostController = TextEditingController();
  final globalMarginController = TextEditingController();
  final centralAreaController = TextEditingController();
  final centralRateController = TextEditingController(text: '105.0');
  final centralLengthController = TextEditingController();
  final centralWidthController = TextEditingController();
  final centralQuantityController = TextEditingController(text: '1');
  final centralRadiusController = TextEditingController();
  bool centralDeduction = false;
  final customCenterAreaController = TextEditingController();
  final customCenterRateController = TextEditingController(text: '105.0');
  final customCenterLengthController = TextEditingController();
  final customCenterWidthController = TextEditingController();
  final customCenterQuantityController = TextEditingController(text: '1');
  final customCenterRadiusController = TextEditingController();
  final customCenterDeductionController = TextEditingController();
  final customCenterDeductionLengthController = TextEditingController();
  final customCenterDeductionWidthController = TextEditingController();
  final customCenterDeductionQuantityController = TextEditingController(text: '1');
  final customCenterDeductionAreaController = TextEditingController();
  final customCenterCircleRadiusController = TextEditingController();
  final customCenterCircleAreaM2Controller = TextEditingController();
  final customCenterCircleQtyController = TextEditingController(text: '1');
  final customCenterCircleSqftController = TextEditingController();
  bool customCenterDeduction = false;
  bool customCenterIncludeCircleArea = false;
  String customCenterUnit = 'Meter';
  bool isCustomCenterApplied = false;
  final coveRftController = TextEditingController();
  final coveRateController = TextEditingController(text: '105.0');
  final coveLengthController = TextEditingController();
  final coveWidthController = TextEditingController();
  final coveQuantityController = TextEditingController(text: '1');
  final coveLength2Controller = TextEditingController();
  final coveWidth2Controller = TextEditingController();
  final coveQuantity2Controller = TextEditingController(text: '1');
  
  final List<CentralDesignRow> extraPlainRows = [];
  final List<CentralDesignRow> extraCentralRows = [];
  final List<CentralDesignRow> extraCustomCentralRows = [];
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

  String unit = 'Meter';
  String centralUnit = 'Meter';
  String coveUnit = 'Meter';
  bool get isMetric => unit == 'Meters' || unit == 'SqM' || unit == 'RMT' || unit == 'cm' || unit == 'mm' || unit == 'CM';
  bool get isAreaUnit => unit == 'SqFt' || unit == 'SqM' || unit == 'Meters' || unit == 'Meter' || unit == 'Inches' || unit == 'mm' || unit == 'Feet' || unit == 'CM' || unit == 'cm';
  String? selectedRoom;
  String? selectedCeilingType;
  String? selectedBrand = 'Saint-Gobain Gyproc (Regular & MR Green Board)';
  String? selectedChannel = 'Saint-Gobain Gypframe / Gypsteel';
  String? selectedDesign;
  
  final List<String> rooms = RoomSelectorHelper.masterRoomOptions;
  final List<String> designTypes = ['Plain Ceiling', 'Center Design', 'Designer Ceiling', 'Cornice', 'Wall Design', 'Other'];
  final Map<String, double> ceilingTypes = {
    'Gypsum Board': 0.0, 'PVC Board': 0.0, 'Grid Ceiling': 0.0, 'Classic Arch': 0.0, 'Insu Board (Insulation Board)': 0.0,
    'Fiber Cement Board': 0.0, 'Mineral Fiber Board': 0.0, 'Wooden Ceiling Panels': 0.0, 'Metal Ceiling Panels': 0.0,
    'Louvers (Decorative Panels)': 0.0, 'Plywood': 0.0, 'WPC (Wood Plastic Composite)': 0.0, 'Other': 0.0,
  };
  
  final Map<String, List<String>> brandsMap = {
    'Gypsum Board': CeilingBoardBrands.brands,
    'PVC Board': CeilingBoardBrands.brands,
    'Grid Ceiling': CeilingBoardBrands.brands,
    'Classic Arch': CeilingBoardBrands.brands,
    'Insu Board (Insulation Board)': CeilingBoardBrands.brands,
    'Fiber Cement Board': CeilingBoardBrands.brands,
    'Mineral Fiber Board': CeilingBoardBrands.brands,
    'Wooden Ceiling Panels': CeilingBoardBrands.brands,
    'Metal Ceiling Panels': CeilingBoardBrands.brands,
    'Louvers (Decorative Panels)': CeilingBoardBrands.brands,
    'Plywood': CeilingBoardBrands.brands,
    'WPC (Wood Plastic Composite)': CeilingBoardBrands.brands,
    'Other': CeilingBoardBrands.brands,
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

  bool isPlainCeilingOn = true;
  bool isCoveCeilingOn = false;
  bool isCenterCeilingOn = false;
  bool get isDesignCeilingOn => isCoveCeilingOn;
  set isDesignCeilingOn(bool val) => isCoveCeilingOn = val;
  bool get isCenterDesignOn => isCenterCeilingOn;
  set isCenterDesignOn(bool val) => isCenterCeilingOn = val;

  // Track if cove rate has been manually customized by user
  bool isCoveRateCustomized = false;

  void syncDesignRatesWithMainRate(String newRate, {bool force = false}) {
    final trimmedRate = newRate.trim();
    if (trimmedRate.isEmpty) return;
    if (force || !isCoveRateCustomized || coveRateController.text.trim().isEmpty) {
      coveRateController.text = trimmedRate;
    }
    if (force || centralRateController.text.trim().isEmpty) {
      centralRateController.text = trimmedRate;
    }
  }

  // --- MULTI-RATE TIERS ---
  List<RateTier> rateTiers = RateTierConstants.getDefaultTiers();
  List<String> selectedTierIds = ['BASE', 'Premium', 'Luxury'];
  String? selectedTier = 'BASE';

  void toggleTierSelection(String tierId) {
    if (selectedTierIds.contains(tierId)) {
      selectedTierIds.remove(tierId);
    } else {
      selectedTierIds.add(tierId);
    }
    for (var t in rateTiers) {
      if (t.id == tierId || t.name == tierId) {
        t.isSelected = selectedTierIds.contains(tierId) || selectedTierIds.contains(t.name);
      }
    }
    notifyListeners();
    notifyUI();
  }

  void updateTierDetails(String tierId, String channelName, String boardName) {
    final index = rateTiers.indexWhere((t) => t.id == tierId || t.name == tierId);
    if (index != -1) {
      if (channelName.isNotEmpty) rateTiers[index].channel = channelName;
      if (boardName.isNotEmpty) rateTiers[index].board = boardName;
      notifyListeners();
      notifyUI();
    }
  }

  void selectTier(String tierName) {
    selectedTier = tierName;
    for (var t in rateTiers) {
      t.isSelected = (t.name == tierName);
    }
    final tier = rateTiers.firstWhere((t) => t.name == tierName, orElse: () => rateTiers.first);
    if (tier.rate > 0) {
      final rateStr = tier.rate.toStringAsFixed(0);
      rateController.text = rateStr;
      syncDesignRatesWithMainRate(rateStr);
    }
    if (tier.board.isNotEmpty) {
      selectedBrand = tier.board;
      brandController.text = tier.board;
    }
    if (tier.channel.isNotEmpty) {
      selectedChannel = tier.channel;
      channelController.text = tier.channel;
    }
    updateLivePreview();
    notifyUI();
  }

  void updateActiveBrand(String brand) {
    selectedBrand = brand;
    brandController.text = brand;
    final current = rateTiers.firstWhere((t) => t.name == selectedTier || t.isSelected, orElse: () => rateTiers.first);
    current.board = brand;
    notifyUI();
  }

  void updateActiveChannel(String channel) {
    selectedChannel = channel;
    channelController.text = channel;
    final current = rateTiers.firstWhere((t) => t.name == selectedTier || t.isSelected, orElse: () => rateTiers.first);
    current.channel = channel;
    notifyUI();
  }

  void updateTierChannel(String tierName, String channel) {
    final t = rateTiers.firstWhere((tier) => tier.name == tierName, orElse: () => rateTiers.first);
    t.channel = channel;
    if (t.isSelected || selectedTier == tierName) {
      selectedChannel = channel;
      channelController.text = channel;
    }
    notifyUI();
  }

  void updateTierBoard(String tierName, String board) {
    final t = rateTiers.firstWhere((tier) => tier.name == tierName, orElse: () => rateTiers.first);
    t.board = board;
    if (t.isSelected || selectedTier == tierName) {
      selectedBrand = board;
      brandController.text = board;
    }
    notifyUI();
  }

  void updateTierRate(String tierName, double newRate) {
    final t = rateTiers.firstWhere((tier) => tier.name == tierName, orElse: () => rateTiers.first);
    t.rate = newRate;
    if (t.isSelected || selectedTier == tierName) {
      final rateStr = newRate > 0 ? (newRate % 1 == 0 ? newRate.toInt().toString() : newRate.toString()) : '';
      rateController.text = rateStr;
      syncDesignRatesWithMainRate(rateStr);
      updateLivePreview();
    }
    notifyUI();
  }

  void addTier(String name, double rate, String channel, String board) {
    rateTiers.add(RateTier(
      name: name,
      rate: rate,
      channel: channel,
      board: board,
      showInPdf: true,
      isSelected: false,
    ));
    notifyUI();
  }

  void removeTier(int index) {
    if (index >= 0 && index < rateTiers.length && rateTiers.length > 1) {
      final wasSelected = rateTiers[index].isSelected;
      rateTiers.removeAt(index);
      if (wasSelected && rateTiers.isNotEmpty) {
        selectTier(rateTiers.first.name);
      } else {
        notifyUI();
      }
    }
  }

  void updateTier(int index, RateTier updated) {
    if (index >= 0 && index < rateTiers.length) {
      rateTiers[index] = updated;
      if (updated.isSelected) {
        final rateStr = updated.rate > 0 ? updated.rate.toStringAsFixed(0) : '';
        rateController.text = rateStr;
        syncDesignRatesWithMainRate(rateStr);
        selectedBrand = updated.board;
        updateLivePreview();
      }
      notifyUI();
    }
  }

  void syncTiersWithMaster() {
    if (rateTiers.isEmpty) {
      rateTiers = RateTierConstants.getDefaultTiers();
    } else {
      // Refresh with master defaults while preserving user values
      final defaults = RateTierConstants.getDefaultTiers();
      for (var d in defaults) {
        final existingIndex = rateTiers.indexWhere((t) => t.name == d.name);
        if (existingIndex == -1) {
          rateTiers.add(d);
        }
      }
      final current = rateTiers.firstWhere((t) => t.isSelected, orElse: () => rateTiers.first);
      if (current.rate > 0) {
        final rateStr = current.rate.toStringAsFixed(0);
        rateController.text = rateStr;
        syncDesignRatesWithMainRate(rateStr);
      }
    }
    notifyUI();
  }

  Timer? _lookupDebounce;

  void notifyUI() => notifyListeners();

  // --- DYNAMIC UNIVERSAL LOOKUP LOGIC ---
  void onClientInfoChanged(String value, String field) {
    if (field == 'phone') {
      final cleanDigits = value.replaceAll(RegExp(r'[^\d+]'), '').trim();
      final letters = value.replaceAll(RegExp(r'[\d+\s\-]'), '').trim();

      if (letters.isNotEmpty) {
        if (clientNameController.text.trim().isEmpty || clientNameController.text.trim().toUpperCase() == 'SITE DRAFT') {
          clientNameController.text = letters;
        }
      }
      if (cleanDigits != value && cleanDigits.isNotEmpty) {
        clientPhoneController.value = TextEditingValue(
          text: cleanDigits,
          selection: TextSelection.collapsed(offset: cleanDigits.length),
        );
      }
    }

    if (field == 'id') {
      if (value.trim().isEmpty) {
        activeProjectId = null;
      }
    }

    triggerAutoSave();
    
    _lookupDebounce?.cancel();
    _lookupDebounce = Timer(const Duration(milliseconds: 350), () async {
      final queryVal = value.trim();
      if (queryVal.length < 3) return;

      try {
        Quotation? match;

        if (field == 'id' || field == 'unitNumber' || field == 'projectId') {
          match = await DatabaseService.instance.getQuotationByProjectIdOrUnit(queryVal);
        } else if (field == 'phone' || field == 'name') {
          match = await DatabaseService.instance.findActiveProjectForClient(
            phone: clientPhoneController.text.trim(),
            name: clientNameController.text.trim(),
          );
        } else if (field == 'location') {
          final quotations = await DatabaseService.instance.getQuotations();
          final candidates = quotations.where(
            (q) => q.clientLocation.toLowerCase().contains(queryVal.toLowerCase()),
          ).toList();
          match = candidates.cast<Quotation?>().firstWhere(
            (q) => q!.items.isNotEmpty,
            orElse: () => candidates.isNotEmpty ? candidates.first : null,
          );
        }

        // 2. Query Cloud Firestore if not found in local DB or for Project ID / Phone queries
        if (match == null && (field == 'id' || field == 'unitNumber' || field == 'projectId')) {
          final cloudQ = await CustomerSyncService.instance.getQuotationFromCloud(queryVal);
          if (cloudQ != null) {
            match = cloudQ;
          }
        }

        if (match != null) {
          // AUTO-FILL details & load all saved rooms, SQFT, materials, and rate tiers
          if (field != 'name' && clientNameController.text.isEmpty && match.clientName.isNotEmpty && match.clientName.toUpperCase() != 'SITE DRAFT') {
            clientNameController.text = match.clientName;
          }
          if (field != 'phone' && clientPhoneController.text.isEmpty && match.clientPhone.isNotEmpty) {
            clientPhoneController.text = match.clientPhone;
          }
          if (field != 'location' && clientLocationController.text.isEmpty && match.clientLocation.isNotEmpty) {
            clientLocationController.text = match.clientLocation;
          }
          
          if (field != 'id' && field != 'unitNumber' && field != 'projectId') {
            if (unitNumberController.text.isEmpty || ClientService.isGeneratedTimestampId(unitNumberController.text)) {
              if (match.unitNumber.isNotEmpty) {
                unitNumberController.text = ClientService.normalizeUnitNumber(match.unitNumber).isNotEmpty
                    ? ClientService.normalizeUnitNumber(match.unitNumber)
                    : match.unitNumber;
              }
            }
          }
          if (match.id != null) {
            activeProjectId = match.id;
          }
          
          // Populate state with all rooms, SQFT, materials, and rate tiers
          if (currentItems.isEmpty && match.items.isNotEmpty) {
            loadQuotationState(match, force: true);
          }
          notifyUI();
          CalculatorDatabaseHelper.saveUiState(this);
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
    centralRadiusController.dispose();
    customCenterAreaController.dispose();
    customCenterRateController.dispose();
    customCenterLengthController.dispose();
    customCenterWidthController.dispose();
    customCenterQuantityController.dispose();
    customCenterRadiusController.dispose();
    customCenterDeductionController.dispose();
    customCenterDeductionLengthController.dispose();
    customCenterDeductionWidthController.dispose();
    customCenterDeductionQuantityController.dispose();
    customCenterDeductionAreaController.dispose();
    customCenterCircleRadiusController.dispose();
    customCenterCircleAreaM2Controller.dispose();
    customCenterCircleQtyController.dispose();
    customCenterCircleSqftController.dispose();
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
    for (var r in extraCustomCentralRows) {
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
    headerNameController.dispose();
    headerPhoneController.dispose();
    headerLocationController.dispose();
    folderController.dispose();
    thicknessController.dispose();
    brandController.dispose();
    customCeilingController.dispose();
    designController.dispose();
    roomController.dispose();
    roomNumberController.dispose();
    areaController.dispose();
    originalAmountController.dispose();
    revisionNoteController.dispose();
    discountController.dispose();
  }

  Future<void> loadHeaderSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString('header_name');
    final savedPhone = prefs.getString('header_phone');
    final savedLocation = prefs.getString('header_location');

    if (savedName != null && savedName.isNotEmpty) headerNameController.text = savedName;
    if (savedPhone != null && savedPhone.isNotEmpty) headerPhoneController.text = savedPhone;
    if (savedLocation != null && savedLocation.isNotEmpty) headerLocationController.text = savedLocation;
  }

  Future<void> saveHeaderSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('header_name', headerNameController.text.trim());
    await prefs.setString('header_phone', headerPhoneController.text.trim());
    await prefs.setString('header_location', headerLocationController.text.trim());
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
  /// Restores saved rooms and entries into list state when passing or editing site data
  void loadSavedSiteData(Quotation quotation) {
    loadQuotationState(quotation, force: true);
  }

  void loadQuotationState(Quotation quotation, {bool force = false}) {
    // FIX: Guard against accidental state overwrite/clearing if items already exist in current session (unless forced)
    if (!force && currentItems.isNotEmpty && activeProjectId == null) {
      debugPrint('PCM_DEBUG: Skipping auto-load of existing project to protect current session items.');
      return;
    }

    activeProjectId = quotation.id;
    clientNameController.text = quotation.clientName;
    clientLocationController.text = quotation.clientLocation;
    folderController.text = quotation.locationFolder ?? quotation.clientLocation;
    clientPhoneController.text = quotation.clientPhone;
    unitNumberController.text = ClientService.normalizeUnitNumber(quotation.unitNumber);

    if (quotation.partnerName != null && quotation.partnerName!.isNotEmpty) {
      headerNameController.text = quotation.partnerName!;
    }
    if (quotation.partnerPhone != null && quotation.partnerPhone!.isNotEmpty) {
      headerPhoneController.text = quotation.partnerPhone!;
    }
    if (quotation.partnerLocation != null && quotation.partnerLocation!.isNotEmpty) {
      headerLocationController.text = quotation.partnerLocation!;
    }
    
    currentItems.clear();
    for (var item in quotation.items) {
      if ((item.unit == 'Meters' || item.unit == 'SqM') && (item.hasCove || item.designName == 'Cove Light')) {
        const factor = 10.764;
        double rftVal = item.coveRft.isFinite ? item.coveRft : 0.0;
        double l1 = item.coveLength > 0 ? item.coveLength : item.length;
        double w1 = item.coveWidth > 0 ? item.coveWidth : item.width;
        double q1 = item.coveQuantity > 0 ? item.coveQuantity : 1.0;
        double l2 = item.coveLength2;
        double w2 = item.coveWidth2 > 0 ? item.coveWidth2 : w1;
        double q2 = item.coveQuantity2 > 0 ? item.coveQuantity2 : 0.0;
        double nativeCalc = (l1 * w1 * q1) + (l2 * w2 * q2);
        if (nativeCalc > 0 && (rftVal - (nativeCalc * factor)).abs() < (rftVal - nativeCalc).abs()) {
          rftVal = rftVal / factor;
        }
        final q = item.quantity.isFinite && item.quantity > 0 ? item.quantity : 1.0;
        final rate = item.coveRate > 0 ? item.coveRate : item.rate;
        final trueTotalSqFt = rftVal * q * factor;
        final trueAmount = trueTotalSqFt * rate;
        if (trueAmount > 0 && item.amount > trueAmount * 2) {
          currentItems.add(item.copyWith(
            coveRft: rftVal,
            area: rftVal * q,
            amount: trueAmount,
          ));
          continue;
        }
      }
      currentItems.add(item);
    }
    
    // Preserve manual amount ONLY as a temporary fallback if currentItems is completely empty
    final double effectiveManual = (currentItems.isEmpty && quotation.totalAmount > 0)
        ? quotation.totalAmount
        : (currentItems.isEmpty && quotation.manualAmount > 0 ? quotation.manualAmount : 0.0);

    manualAmountController.text = (currentItems.isEmpty && effectiveManual > 0) ? effectiveManual.toString() : '';
    manualWeightController.text = quotation.manualWeight > 0 ? quotation.manualWeight.toString() : '';
    globalMaterialCostController.text = quotation.globalMaterialCost > 0 ? quotation.globalMaterialCost.toString() : '';
    globalMarginController.text = quotation.globalMargin > 0 ? quotation.globalMargin.toString() : '';
    originalAmountController.text = quotation.originalAmount != null ? quotation.originalAmount.toString() : '';
    revisionNoteController.text = quotation.revisionNote ?? '';
    discountController.text = quotation.discount > 0 ? quotation.discount.toString() : '0';
    
    currentPayments.clear();
    currentPayments.addAll(quotation.payments);
    if (currentPayments.isEmpty && quotation.paidAmount > 0) {
      currentPayments.add(PaymentRecord(
        description: 'Advance Received',
        amount: quotation.paidAmount,
        date: quotation.date.isNotEmpty ? quotation.date : DateFormat('dd-MM-yyyy hh:mm a').format(DateTime.now()),
      ));
    }
    
    includeWastage = quotation.includeWastage;
    includeDigitalSignature = quotation.includeDigitalSignature;
    includeBankDetails = quotation.includeBankDetails;
    projectStatus = quotation.projectStatus;
    approvalSignature = quotation.approvalSignature;

    // Restore saved quotation rate tiers if present
    if (quotation.rateTiers.isNotEmpty) {
      try {
        rateTiers = quotation.rateTiers.map((map) => RateTier.fromMap(map)).toList();
      } catch (e) {
        debugPrint('Error restoring quotation rate tiers: $e');
      }
    }

    updateProjectTotals();
    notifyUI();
    triggerAutoSave();

    // EXPLICIT ROOM ITEMS BINDING:
    // If quotation.items was empty, query DatabaseService for saved room items
    if (currentItems.isEmpty) {
      final qId = activeProjectId;
      final uNum = unitNumberController.text.trim();
      final phone = clientPhoneController.text.trim();
      final name = clientNameController.text.trim();
      if (qId != null || uNum.isNotEmpty || phone.isNotEmpty) {
        DatabaseService.instance.getQuotationItems(
          uNum,
          clientPhone: phone,
          clientName: name,
          quotationId: qId,
        ).then((fetchedItems) {
          if (fetchedItems.isNotEmpty && currentItems.isEmpty) {
            currentItems.clear();
            currentItems.addAll(fetchedItems);
            manualAmountController.clear();
            updateProjectTotals();
            notifyUI();
          }
        }).catchError((e) {
          debugPrint('Error fetching quotation items in loadQuotationState: $e');
        });
      }
    }
  }

  void initLoad(VoidCallback onShowSaved) async {
    await loadHeaderSettings();
    await CalculatorDatabaseHelper.loadRatesFromPrefs(this);
    await CalculatorDatabaseHelper.loadUiState(this);
    CalculatorDatabaseHelper.listenForSync(this, onShowSaved);

    if (currentItems.isEmpty) {
      final uNum = unitNumberController.text.trim();
      final phone = clientPhoneController.text.trim();
      final name = clientNameController.text.trim();
      if (uNum.isNotEmpty || phone.isNotEmpty || (activeProjectId != null && activeProjectId! > 0)) {
        try {
          final items = await DatabaseService.instance.getQuotationItems(
            uNum,
            clientPhone: phone,
            clientName: name,
            quotationId: activeProjectId,
          );
          if (items.isNotEmpty && currentItems.isEmpty) {
            currentItems.clear();
            currentItems.addAll(items);
            updateProjectTotals();
            notifyUI();
          }
        } catch (e) {
          debugPrint('Error fetching items on initLoad: $e');
        }
      }
    }
  }

  Future<void> loadProject(
    String projectId,
    VoidCallback onShowSaved, {
    Client? client,
    Quotation? quotation,
  }) async {
    await CalculatorDatabaseHelper.loadProject(
      this,
      projectId,
      onShowSaved,
      client: client,
      fallbackQuotation: quotation,
    );

    // Explicit room items array binding check
    if (currentItems.isEmpty) {
      final uNum = unitNumberController.text.trim().isNotEmpty
          ? unitNumberController.text.trim()
          : (projectId.trim().isNotEmpty ? projectId.trim() : (client?.unitNumber ?? ''));
      final phone = clientPhoneController.text.trim().isNotEmpty
          ? clientPhoneController.text.trim()
          : (client?.phoneNumber ?? quotation?.clientPhone);
      final name = clientNameController.text.trim().isNotEmpty
          ? clientNameController.text.trim()
          : (client?.clientName ?? quotation?.clientName);

      try {
        final items = await DatabaseService.instance.getQuotationItems(
          uNum,
          altUnit: client?.unitNumber ?? quotation?.unitNumber,
          clientPhone: phone,
          clientName: name,
          quotationId: activeProjectId,
        );
        if (items.isNotEmpty && currentItems.isEmpty) {
          currentItems.clear();
          currentItems.addAll(items);
          manualAmountController.clear();
          updateProjectTotals();
          notifyUI();
        }
      } catch (e) {
        debugPrint('Error binding room items in loadProject: $e');
      }
    }
  }
  void triggerAutoSave() => CalculatorDatabaseHelper.triggerAutoSave(this);
  Future<void> saveToDatabase({bool showSnackBar = true, VoidCallback? onSuccess}) => CalculatorDatabaseHelper.saveToDatabase(this, showSnackBar: showSnackBar, onSuccess: onSuccess);

  void startNewProject() {
    activeProjectId = null;
    clientNameController.clear();
    clientLocationController.clear();
    folderController.clear();
    clientPhoneController.clear();
    unitNumberController.clear();
    
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
    debounceTimer?.cancel();
    CalculatorDatabaseHelper.saveUiState(this);
    notifyUI();
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
    double cove2 = (type == 'Central Design' || type == 'Center Design') ? 0.0 : item.centralArea;

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
      floor: item.floor,
      roomNumber: item.roomNumber,
      colorPattern: item.colorPattern,
      isCeilingDesign: item.isCeilingDesign,
      hasCentralDesign: (type == 'Central Design' || type == 'Center Design') ? false : item.hasCentralDesign,
      centralArea: (type == 'Central Design' || type == 'Center Design') ? 0.0 : item.centralArea,
      centralRate: (type == 'Central Design' || type == 'Center Design') ? 0.0 : item.centralRate,
      centralLength: (type == 'Central Design' || type == 'Center Design') ? 0.0 : item.centralLength,
      centralWidth: (type == 'Central Design' || type == 'Center Design') ? 0.0 : item.centralWidth,
      centralQuantity: (type == 'Central Design' || type == 'Center Design') ? 1.0 : item.centralQuantity,
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
