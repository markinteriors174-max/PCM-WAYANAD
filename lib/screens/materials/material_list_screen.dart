import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../../theme/app_theme.dart';
import '../../services/database_service.dart';
import '../../services/database_schema.dart';
import '../../services/pdf_service.dart';
import '../../models/quotation.dart';
import '../../providers/language_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../screens/calculator/project_edit_controller.dart';
import '../../services/customer_sync_service.dart';
import '../../models/labor_models.dart';

// Standalone component imports
import '../../widgets/global_star_appbar.dart';
import 'room_breakdown_calculator.dart';
import 'dispatch_list_tab.dart';
import 'config_hub_tab.dart';
import 'worker_list_tab.dart';
import 'master_rates_tab.dart';

class MaterialListScreen extends StatefulWidget {
  const MaterialListScreen({super.key});

  @override
  State<MaterialListScreen> createState() => _MaterialListScreenState();
}

class _MaterialListScreenState extends State<MaterialListScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  bool _isLoading = true;
  final Map<String, TextEditingController> _controllers = {};
  final List<String> _ceilingTypes = ['GypsumBoard', 'PVC', 'Grid'];

  // Dictionary fields
  Map<String, List<Map<String, dynamic>>> _materialDictionary = {};
  List<String> _categoriesList = [];
  String? _selectedCategoryForNewItem;
  final TextEditingController _newCategoryController = TextEditingController();
  final TextEditingController _newMaterialNameController = TextEditingController();
  String _selectedUnitForNewItem = 'Nos';
  final List<String> _units = ['Nos', 'Box', 'Packet', 'Bags', 'Roll', 'kg', 'Nos/Roll', 'Nos/kg'];

  // Dispatch controllers
  final TextEditingController _dispatchLocationController = TextEditingController();
  final TextEditingController _dispatchClientController = TextEditingController();
  final TextEditingController _dispatchContractorController = TextEditingController();

  // Maps CategoryName||ItemName to qty & rate controllers
  final Map<String, TextEditingController> _dispatchQtyControllers = {};
  final Map<String, TextEditingController> _dispatchRateControllers = {};
  
  // Room breakdowns mapping
  final Map<String, List<MaterialRoomBreakdown>> _roomBreakdowns = {};
  bool _includeBankDetails = false;
  
  double _totalEstimatedCost = 0.0;
  String? _editingDispatchUnitNumber;
  List<SQLiteWorker> _sqliteWorkersList = [];
  
  final Map<String, List<MaterialVariantRow>> _uiVariants = {};
  final List<int> _deletedSubMaterialIds = [];

  @override
  void initState() {
    super.initState();
    for (var type in _ceilingTypes) {
      _controllers[type] = TextEditingController();
    }
    
    DatabaseService.instance.syncSubMaterialsFromSupabase().then((_) {
      if (mounted) {
        _refreshData();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final nav = Provider.of<NavigationProvider>(context, listen: false);
      nav.addListener(_onTabChanged);
      ProjectEditController.instance.addListener(_handleDispatchEditRequest);
      
      final pendingDispatchId = ProjectEditController.instance.pendingDispatchId;
      if (pendingDispatchId != null) {
        ProjectEditController.instance.clearDispatchEdit();
        _loadDispatchList(pendingDispatchId);
      }
    });
    
    _refreshData();
  }

  void _onTabChanged() {
    final nav = Provider.of<NavigationProvider>(context, listen: false);
    if (nav.selectedIndex == 3 && mounted) {
      _refreshData();
    }
  }

  @override
  void dispose() {
    final nav = Provider.of<NavigationProvider>(context, listen: false);
    nav.removeListener(_onTabChanged);
    ProjectEditController.instance.removeListener(_handleDispatchEditRequest);
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    _newCategoryController.dispose();
    _newMaterialNameController.dispose();
    _dispatchLocationController.dispose();
    _dispatchClientController.dispose();
    _dispatchContractorController.dispose();
    for (var controller in _dispatchQtyControllers.values) {
      controller.dispose();
    }
    for (var controller in _dispatchRateControllers.values) {
      controller.dispose();
    }
    for (var rows in _uiVariants.values) {
      for (var row in rows) {
        row.dispose();
      }
    }
    for (var breakdowns in _roomBreakdowns.values) {
      for (var b in breakdowns) {
        b.dispose();
      }
    }
    super.dispose();
  }

  void _handleDispatchEditRequest() {
    final pendingDispatchId = ProjectEditController.instance.pendingDispatchId;
    if (pendingDispatchId != null && mounted) {
      ProjectEditController.instance.clearDispatchEdit();
      _loadDispatchList(pendingDispatchId);
    }
  }

  void _addBreakdownListeners(String key, MaterialRoomBreakdown breakdown) {
    breakdown.qtyController.addListener(() => _onRoomBreakdownChanged(key));
    breakdown.rateController.addListener(() => _onRoomBreakdownChanged(key));
    breakdown.roomController.addListener(() => _calculateTotalEstimatedCost());
  }

  void _onRoomBreakdownChanged(String key) {
    final breakdowns = _roomBreakdowns[key];
    if (breakdowns != null && breakdowns.isNotEmpty) {
      double totalQty = 0.0;
      for (var b in breakdowns) {
        final q = double.tryParse(b.qtyController.text.trim()) ?? 0.0;
        totalQty += q;
      }
      _dispatchQtyControllers[key]?.text = totalQty > 0 ? totalQty.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '') : '';
    } else {
      _dispatchQtyControllers[key]?.clear();
    }
    _calculateTotalEstimatedCost();
  }

  Future<void> _loadDispatchList(String dispatchId) async {
    setState(() => _isLoading = true);
    try {
      Quotation? target;
      final localQuotes = await DatabaseService.instance.getQuotations();
      final matchingLocal = localQuotes.where((q) => q.unitNumber == dispatchId);
      if (matchingLocal.isNotEmpty) {
        target = matchingLocal.first;
      } else {
        target = await CustomerSyncService.instance.getQuotationFromCloud(dispatchId);
      }

      if (target != null) {
        _editingDispatchUnitNumber = target.unitNumber;
        _dispatchLocationController.text = target.clientLocation;
        _dispatchClientController.text = target.clientPhone.isNotEmpty
            ? '${target.clientName} - ${target.clientPhone}'
            : target.clientName;
        _dispatchContractorController.text = target.revisionNote ?? '';
        _includeBankDetails = target.includeBankDetails;

        for (var ctrl in _dispatchQtyControllers.values) {
          ctrl.clear();
        }
        for (var breakdowns in _roomBreakdowns.values) {
          for (var b in breakdowns) {
            b.dispose();
          }
        }
        _roomBreakdowns.clear();

        for (var mat in target.materials) {
          String baseMatName = mat.materialName;
          String category = '';
          String room = '';

          final match = RegExp(r'^(.+)\s*\(([^)]+)\)(?:\s*-\s*(.+))?$').firstMatch(mat.materialName);
          if (match != null) {
            baseMatName = match.group(1)!.trim();
            category = match.group(2)!.trim();
            room = (match.group(3) ?? '').trim();
          } else {
            if (mat.materialName.contains(' - ')) {
              final parts = mat.materialName.split(' - ');
              room = parts.sublist(1).join(' - ').trim();
              final baseAndCat = parts[0].trim();
              if (baseAndCat.contains(' (')) {
                final subParts = baseAndCat.split(' (');
                baseMatName = subParts[0].trim();
                category = subParts[1].replaceAll(')', '').trim();
              } else {
                baseMatName = baseAndCat;
              }
            } else if (mat.materialName.contains(' (')) {
              final parts = mat.materialName.split(' (');
              baseMatName = parts[0].trim();
              category = parts[1].replaceAll(')', '').trim();
            }
          }

          final key = '$category||$baseMatName';
          if (room.isNotEmpty) {
            _roomBreakdowns.putIfAbsent(key, () => []);
            final newB = MaterialRoomBreakdown(
              room: room,
              qty: mat.quantity.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), ''),
              rate: mat.rate > 0 ? mat.rate.toStringAsFixed(2) : '',
            );
            _roomBreakdowns[key]!.add(newB);
            _addBreakdownListeners(key, newB);
          } else {
            if (_dispatchQtyControllers.containsKey(key)) {
              _dispatchQtyControllers[key]!.text = mat.quantity.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
            }
            if (_dispatchRateControllers.containsKey(key)) {
              _dispatchRateControllers[key]!.text = mat.rate > 0 ? mat.rate.toStringAsFixed(2) : '';
            }
          }
        }
        
        _calculateTotalEstimatedCost();
      }
    } catch (e) {
      debugPrint('Error loading dispatch list: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _calculateTotalEstimatedCost() {
    double total = 0.0;
    _materialDictionary.forEach((categoryName, items) {
      for (var item in items) {
        final key = '$categoryName||${item['name']}';
        final breakdowns = _roomBreakdowns[key];
        
        if (breakdowns != null && breakdowns.isNotEmpty) {
          for (var b in breakdowns) {
            final qty = double.tryParse(b.qtyController.text.trim()) ?? 0.0;
            final rate = double.tryParse(b.rateController.text.trim()) ?? (item['rate'] as num?)?.toDouble() ?? 0.0;
            total += qty * rate;
          }
        } else {
          final qtyStr = _dispatchQtyControllers[key]?.text.trim() ?? '';
          final qty = double.tryParse(qtyStr) ?? 0.0;
          if (qty > 0) {
            final rateStr = _dispatchRateControllers[key]?.text.trim() ?? '';
            final rate = double.tryParse(rateStr) ?? (item['rate'] as num?)?.toDouble() ?? 0.0;
            total += qty * rate;
          }
        }
      }
    });
    setState(() {
      _totalEstimatedCost = total;
    });
  }

  Future<String> _saveOrUpdateDispatch(List<MaterialAssignment> activeMaterials) async {
    final location = _dispatchLocationController.text.trim();
    final client = _dispatchClientController.text.trim();
    final contractor = _dispatchContractorController.text.trim();

    String clientName = 'SITE DRAFT';
    String clientPhone = '';
    if (client.isNotEmpty) {
      final parts = client.split('-');
      clientName = parts[0].trim();
      if (parts.length > 1) {
        clientPhone = parts[1].trim();
      }
    }

    final String unitNumber = _editingDispatchUnitNumber ?? 'DISPATCH-${DateFormat('yyyyMMdd-HHmmss').format(DateTime.now())}';
    final String currentDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

    Quotation? existing;
    final localQuotes = await DatabaseService.instance.getQuotations();
    final matchingLocal = localQuotes.where((q) => q.unitNumber == unitNumber);
    if (matchingLocal.isNotEmpty) {
      existing = matchingLocal.first;
    }

    final newQuotation = Quotation(
      id: existing?.id,
      unitNumber: unitNumber,
      clientName: clientName,
      clientPhone: clientPhone,
      clientLocation: location,
      date: existing?.date ?? currentDate,
      totalAmount: _totalEstimatedCost,
      paidAmount: existing?.paidAmount ?? 0,
      balanceAmount: _totalEstimatedCost - (existing?.paidAmount ?? 0),
      items: const [],
      materials: activeMaterials,
      rentals: const [],
      payments: const [],
      revisionNote: contractor,
      includeBankDetails: _includeBankDetails,
      projectStatus: 'Dispatch',
    );

    if (existing != null) {
      await DatabaseService.instance.updateQuotation(newQuotation);
    } else {
      await DatabaseService.instance.saveFullQuotation(newQuotation);
    }

    try {
      await CustomerSyncService.instance.saveQuotationToCloud(newQuotation);
    } catch (e) {
      debugPrint('Cloud sync error: $e');
    }

    setState(() {
      _editingDispatchUnitNumber = unitNumber;
    });

    return unitNumber;
  }

  Future<void> _restoreMasterRates() async {
    try {
      Quotation? cloudMaster = await CustomerSyncService.instance.getQuotationFromCloud('MASTER_RATES');
      if (cloudMaster != null && cloudMaster.materials.isNotEmpty) {
        await DatabaseService.instance.restoreMasterRatesFromMaterials(cloudMaster.materials);
        return;
      }
      final localQuotes = await DatabaseService.instance.getQuotations();
      final matchingLocal = localQuotes.where((q) => q.unitNumber == 'MASTER_RATES');
      if (matchingLocal.isNotEmpty) {
        await DatabaseService.instance.restoreMasterRatesFromMaterials(matchingLocal.first.materials);
      }
    } catch (e) {
      debugPrint('Error restoring master rates: $e');
    }
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    await _restoreMasterRates();
    final prefs = await SharedPreferences.getInstance();
    for (var type in _ceilingTypes) {
      final rate = prefs.getDouble('rate_$type') ?? (type == 'GypsumBoard' ? 120.0 : 90.0);
      _controllers[type]!.text = rate.toStringAsFixed(0);
    }
    
    final dict = await DatabaseService.instance.getMaterialDictionary();
    _materialDictionary = dict;
    _categoriesList = dict.keys.toList();
    if (_categoriesList.isNotEmpty) {
      if (_selectedCategoryForNewItem == null || !_categoriesList.contains(_selectedCategoryForNewItem)) {
        _selectedCategoryForNewItem = _categoriesList.first;
      }
    } else {
      _selectedCategoryForNewItem = null;
    }
    
    for (var rows in _uiVariants.values) {
      for (var row in rows) {
        row.dispose();
      }
    }
    _uiVariants.clear();
    
    dict.forEach((categoryName, items) {
      for (var item in items) {
        final baseName = getBaseName(item['name']);
        final vKey = '$categoryName||$baseName';
        _uiVariants.putIfAbsent(vKey, () => []).add(MaterialVariantRow(
          id: item['id'],
          unit: item['unit'] ?? 'Nos',
          sku: item['sku'] ?? '',
          rate: (item['rate'] as num?)?.toDouble() ?? 0.0,
        ));

        final key = '$categoryName||${item['name']}';
        if (!_dispatchQtyControllers.containsKey(key)) {
          _dispatchQtyControllers[key] = TextEditingController();
          _dispatchQtyControllers[key]!.addListener(_calculateTotalEstimatedCost);
          _dispatchQtyControllers[key]!.addListener(() {
            final qtyStr = _dispatchQtyControllers[key]!.text.trim();
            final qty = double.tryParse(qtyStr) ?? 0.0;
            if (qty > 0) {
              final rateController = _dispatchRateControllers[key]!;
              if (rateController.text.trim().isEmpty) {
                final double initialRate = (item['rate'] as num?)?.toDouble() ?? 0.0;
                if (initialRate > 0) {
                  rateController.text = initialRate.toStringAsFixed(2);
                }
              }
            }
          });
        }
        if (!_dispatchRateControllers.containsKey(key)) {
          final double initialRate = (item['rate'] as num?)?.toDouble() ?? 0.0;
          _dispatchRateControllers[key] = TextEditingController(
            text: initialRate > 0 ? initialRate.toStringAsFixed(2) : '',
          );
          _dispatchRateControllers[key]!.addListener(_calculateTotalEstimatedCost);
        }
      }
    });

    try {
      final dbWorkers = await DatabaseService.instance.getSQLiteWorkers();
      _sqliteWorkersList = dbWorkers.map((w) => SQLiteWorker.fromMap(w)).toList();
    } catch (e) {
      debugPrint('Error loading SQLite workers: $e');
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _saveRates() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      for (var type in _ceilingTypes) {
        final rate = double.tryParse(_controllers[type]!.text) ?? 0.0;
        await prefs.setDouble('rate_$type', rate);
      }
      
      for (var id in _deletedSubMaterialIds) {
        await DatabaseService.instance.deleteSubMaterial(id);
      }
      _deletedSubMaterialIds.clear();

      final List<MaterialAssignment> masterMaterials = [];
      
      for (var entry in _uiVariants.entries) {
        final keyParts = entry.key.split('||');
        final categoryName = keyParts[0];
        final baseName = keyParts[1];
        final rows = entry.value;
        
        for (var row in rows) {
          final sku = row.skuController.text.trim();
          final rate = double.tryParse(row.rateController.text.trim()) ?? 0.0;
          String fullName = baseName;
          final baseMal = DatabaseSchema.getMalayalamTranslation(baseName);
          String fullNameMal = baseMal;
          
          int finalId;
          if (row.id != null) {
            finalId = row.id!;
            await DatabaseService.instance.updateSubMaterial(finalId, fullName, row.unit, sku: sku);
            await DatabaseService.instance.updateSubMaterialRate(finalId, rate);
            await DatabaseService.instance.updateSubMaterialMalayalam(finalId, fullNameMal);
          } else {
            finalId = await DatabaseService.instance.insertSubMaterialWithRate(
              categoryName, fullName, row.unit, rate, fullNameMal, sku: sku
            );
            row.id = finalId;
          }
          
          masterMaterials.add(MaterialAssignment(
            materialName: '$fullName ($categoryName)',
            unit: row.unit,
            rate: rate,
            quantity: 0.0,
            amount: 0.0,
          ));
        }
      }
      
      final masterQuotation = Quotation(
        unitNumber: 'MASTER_RATES',
        clientName: 'MASTER',
        clientPhone: 'RATES',
        clientLocation: 'CLOUD',
        date: DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
        totalAmount: 0.0,
        paidAmount: 0.0,
        balanceAmount: 0.0,
        items: const [],
        materials: masterMaterials,
        projectStatus: 'Rates',
      );
      
      final db = DatabaseService.instance;
      final localQuotes = await db.getQuotations();
      final existing = localQuotes.where((q) => q.unitNumber == 'MASTER_RATES');
      if (existing.isNotEmpty) {
        await db.updateQuotation(masterQuotation.copyWith(id: existing.first.id));
      } else {
        await db.saveFullQuotation(masterQuotation);
      }
      
      try {
        await CustomerSyncService.instance.saveQuotationToCloud(masterQuotation);
      } catch (cloudErr) {
        debugPrint('Cloud sync error: $cloudErr');
      }
      
      await _refreshData();
    } catch (e) {
      debugPrint('Error saving rates: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _generateDispatchPdf() async {
    final location = _dispatchLocationController.text.trim();
    final client = _dispatchClientController.text.trim();
    final contractor = _dispatchContractorController.text.trim();
    
    if (location.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Site Location is mandatory for vehicle dispatch routing.'),
          backgroundColor: AppColors.alertRed,
        ),
      );
      return;
    }
    
    final List<MaterialAssignment> activeMaterials = [];
    
    _materialDictionary.forEach((categoryName, items) {
      for (var item in items) {
        final key = '$categoryName||${item['name']}';
        final breakdowns = _roomBreakdowns[key];
        
        if (breakdowns != null && breakdowns.isNotEmpty) {
          debugPrint('DEBUG: key=$key, breakdowns.length=${breakdowns.length}');
          for (var b in breakdowns) {
            final qty = double.tryParse(b.qtyController.text.trim()) ?? 0.0;
            debugPrint('DEBUG: breakdown room=${b.roomController.text}, qty=$qty');
            if (qty > 0) {
              final rate = double.tryParse(b.rateController.text.trim()) ?? (item['rate'] as num?)?.toDouble() ?? 0.0;
              final roomName = b.roomController.text.trim();
              final matName = roomName.isNotEmpty
                  ? '${item['name']} ($categoryName) - $roomName'
                  : '${item['name']} ($categoryName)';
                  
              activeMaterials.add(MaterialAssignment(
                materialName: matName,
                unit: item['unit'],
                rate: rate,
                quantity: qty,
                amount: qty * rate,
              ));
            }
          }
        } else {
          final qtyStr = _dispatchQtyControllers[key]?.text.trim() ?? '';
          final qty = double.tryParse(qtyStr) ?? 0.0;
          if (qty > 0) {
            final rateStr = _dispatchRateControllers[key]?.text.trim() ?? '';
            final rate = double.tryParse(rateStr) ?? (item['rate'] as num?)?.toDouble() ?? 0.0;
            
            activeMaterials.add(MaterialAssignment(
              materialName: '${item['name']} ($categoryName)',
              unit: item['unit'],
              rate: rate,
              quantity: qty,
              amount: qty * rate,
            ));
          }
        }
      }
    });
    
    if (activeMaterials.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter quantity > 0 for at least one material.'),
          backgroundColor: AppColors.border,
        ),
      );
      return;
    }
    
    String clientName = 'SITE DRAFT';
    String clientPhone = '';
    if (client.isNotEmpty) {
      final parts = client.split('-');
      clientName = parts[0].trim();
      if (parts.length > 1) {
        clientPhone = parts[1].trim();
      }
    }

    String contractorName = '';
    String contractorPhone = '';
    if (contractor.isNotEmpty) {
      final parts = contractor.split('-');
      contractorName = parts[0].trim();
      if (parts.length > 1) {
        contractorPhone = parts[1].trim();
      }
    }

    setState(() => _isLoading = true);
    final String unitNumber = await _saveOrUpdateDispatch(activeMaterials);
    setState(() => _isLoading = false);
    
    final pdfBytes = await PdfService.generateQuotation(
      clientName: clientName,
      clientLocation: location,
      clientPhone: clientPhone,
      unitNumber: unitNumber,
      items: [],
      materials: activeMaterials,
      payments: [],
      totalAmount: _totalEstimatedCost,
      paidAmount: 0.0,
      balanceAmount: _totalEstimatedCost,
      isMaterialList: false,
      isDispatchList: true,
      includeBankDetails: _includeBankDetails,
      contractorName: contractorName,
      contractorPhone: contractorPhone,
    );
    
    if (pdfBytes != null) {
      await PdfService.previewPdf(pdfBytes, 'material_dispatch_list.pdf');
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to generate PDF document.'),
            backgroundColor: AppColors.alertRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final lang = context.watch<LanguageProvider>();
    
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: GlobalStarAppBar(
          title: lang.translate('MATERIALS'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'DISPATCH LIST', icon: Icon(Icons.local_shipping_outlined)),
              Tab(text: 'CONFIG HUB', icon: Icon(Icons.settings_outlined)),
              Tab(text: 'WORKER LIST', icon: Icon(Icons.engineering_outlined)),
              Tab(text: 'MASTER RATES', icon: Icon(Icons.payments_outlined)),
            ],
            indicatorColor: AppColors.background,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1),
            unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal, fontSize: 9),
            labelColor: Colors.white,
          ),
        ),
        body: TabBarView(
          children: [
            DispatchListTab(
              isLoading: _isLoading,
              categoriesList: _categoriesList,
              materialDictionary: _materialDictionary,
              dispatchQtyControllers: _dispatchQtyControllers,
              dispatchRateControllers: _dispatchRateControllers,
              roomBreakdowns: _roomBreakdowns,
              dispatchLocationController: _dispatchLocationController,
              dispatchClientController: _dispatchClientController,
              dispatchContractorController: _dispatchContractorController,
              totalEstimatedCost: _totalEstimatedCost,
              editingDispatchUnitNumber: _editingDispatchUnitNumber,
              includeBankDetails: _includeBankDetails,
              onCalculateTotal: _calculateTotalEstimatedCost,
              onNewDispatch: () {
                setState(() {
                  _editingDispatchUnitNumber = null;
                  _dispatchLocationController.clear();
                  _dispatchClientController.clear();
                  _dispatchContractorController.clear();
                  _totalEstimatedCost = 0.0;
                  for (var ctrl in _dispatchQtyControllers.values) {
                    ctrl.clear();
                  }
                  _materialDictionary.forEach((catName, items) {
                    for (var item in items) {
                      final key = '$catName||${item['name']}';
                      final double r = (item['rate'] as num?)?.toDouble() ?? 0.0;
                      _dispatchRateControllers[key]?.text = r > 0 ? r.toStringAsFixed(2) : '';
                    }
                  });
                  for (var breakdowns in _roomBreakdowns.values) {
                    for (var b in breakdowns) {
                      b.dispose();
                    }
                  }
                  _roomBreakdowns.clear();
                });
              },
              onGeneratePdf: _generateDispatchPdf,
              onIncludeBankDetailsChanged: (val) {
                setState(() {
                  _includeBankDetails = val;
                });
              },
              onAddListener: (key, breakdown) {
                _addBreakdownListeners(key, breakdown);
              },
            ),
            ConfigHubTab(
              isLoading: _isLoading,
              categoriesList: _categoriesList,
              materialDictionary: _materialDictionary,
              newCategoryController: _newCategoryController,
              newMaterialNameController: _newMaterialNameController,
              selectedUnitForNewItem: _selectedUnitForNewItem,
              selectedCategoryForNewItem: _selectedCategoryForNewItem,
              units: _units,
              onRefresh: _refreshData,
              onSelectedCategoryChanged: (val) {
                setState(() {
                  _selectedCategoryForNewItem = val;
                });
              },
              onSelectedUnitChanged: (val) {
                setState(() {
                  _selectedUnitForNewItem = val ?? 'Nos';
                });
              },
            ),
            WorkerListTab(
              isLoading: _isLoading,
              sqliteWorkersList: _sqliteWorkersList,
              onRefresh: _refreshData,
            ),
            MasterRatesTab(
              ceilingTypes: _ceilingTypes,
              controllers: _controllers,
              categoriesList: _categoriesList,
              uiVariants: _uiVariants,
              deletedSubMaterialIds: _deletedSubMaterialIds,
              onSaveRates: _saveRates,
            ),
          ],
        ),
      ),
    );
  }
}
