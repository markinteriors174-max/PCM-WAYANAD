import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/quotation.dart';
import '../../../models/rental_model.dart';
import '../../../services/database_service.dart';
import '../../../services/customer_sync_service.dart';
import '../../../services/client_service.dart';
import '../../../models/client_model.dart';
import '../calculator_controller.dart';

class CalculatorDatabaseHelper {
  static Future<void> loadProject(CalculatorController ctrl, String projectId, VoidCallback onShowSaved) async {
    try {
      final id = int.tryParse(projectId);
      
      Quotation? quotation;
      if (id != null) {
        final quotations = await DatabaseService.instance.getQuotations();
        quotation = quotations.cast<Quotation?>().firstWhere((q) => q!.id == id, orElse: () => null);
      }

      // If not found locally (maybe after app update/clear), try fetching from Cloud by unitNumber if available
      if (quotation == null) {
        final cloudQ = await CustomerSyncService.instance.getQuotationFromCloud(projectId);
        if (cloudQ != null) {
          quotation = cloudQ;
          // Save a local copy instantly for offline persistence
          final newId = await DatabaseService.instance.saveFullQuotation(cloudQ);
          quotation = cloudQ.copyWith(id: newId);
        }
      }

      if (quotation == null) return;
      
      ctrl.activeProjectId = quotation.id;
      ctrl.clientNameController.text = quotation.clientName;
      ctrl.clientLocationController.text = quotation.clientLocation;
      ctrl.folderController.text = quotation.locationFolder ?? quotation.clientLocation;
      ctrl.clientPhoneController.text = quotation.clientPhone;
      ctrl.unitNumberController.text = quotation.unitNumber;
      
      ctrl.currentItems.clear();
      ctrl.currentItems.addAll(quotation.items);
      
      ctrl.manualAmountController.text = quotation.manualAmount > 0 ? quotation.manualAmount.toString() : '';
      ctrl.manualWeightController.text = quotation.manualWeight > 0 ? quotation.manualWeight.toString() : '';
      ctrl.globalMaterialCostController.text = quotation.globalMaterialCost > 0 ? quotation.globalMaterialCost.toString() : '';
      ctrl.globalMarginController.text = quotation.globalMargin > 0 ? quotation.globalMargin.toString() : '';
      ctrl.originalAmountController.text = quotation.originalAmount != null ? quotation.originalAmount.toString() : '';
      ctrl.revisionNoteController.text = quotation.revisionNote ?? '';
      ctrl.discountController.text = quotation.discount > 0 ? quotation.discount.toString() : '0';
      
      ctrl.currentPayments.clear();
      ctrl.currentPayments.addAll(quotation.payments);
      
      ctrl.includeWastage = quotation.includeWastage;
      ctrl.projectStatus = quotation.projectStatus;
      ctrl.approvalSignature = quotation.approvalSignature;
      ctrl.updateProjectTotals();
      listenForSync(ctrl, onShowSaved);
      ctrl.notifyUI();
      saveUiState(ctrl);
    } catch (e) {
      debugPrint('Load Error: $e');
    }
  }

  static void listenForSync(CalculatorController ctrl, VoidCallback onSynced) {
    ctrl.syncSubscription?.cancel();
    ctrl.syncSubscription = CustomerSyncService.instance
        .getRegistrations(ctrl.unitNumberController.text)
        .listen((registrations) {
      if (registrations.isNotEmpty) {
        final reg = registrations.first;
        ctrl.clientNameController.text = reg.name;
        ctrl.clientPhoneController.text = reg.phone;
        ctrl.clientLocationController.text = reg.location;
        if (ctrl.folderController.text.isEmpty) ctrl.folderController.text = reg.location;
        triggerAutoSave(ctrl);
        onSynced();
        ctrl.notifyUI();
      }
    });
  }

  static Future<void> loadRatesFromPrefs(CalculatorController ctrl) async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in ctrl.ceilingTypes.keys) {
      ctrl.ceilingTypes[key] = prefs.getDouble('rate_$key') ?? 0.0;
    }
    ctrl.notifyUI();
  }

  static Future<void> saveUiState(CalculatorController ctrl) async {
    final prefs = await SharedPreferences.getInstance();
    if (ctrl.activeProjectId != null) {
      await prefs.setInt('ui_activeProjectId', ctrl.activeProjectId!);
    } else {
      await prefs.remove('ui_activeProjectId');
    }
    await prefs.setString('ui_unitNumber', ctrl.unitNumberController.text);
    await prefs.setString('ui_clientName', ctrl.clientNameController.text);
    await prefs.setString('ui_location', ctrl.clientLocationController.text);
    await prefs.setString('ui_folder', ctrl.folderController.text);
    await prefs.setString('ui_phone', ctrl.clientPhoneController.text);
    await prefs.setString('ui_unit', ctrl.unit);
    await prefs.setString('ui_globalMaterialCost', ctrl.globalMaterialCostController.text);
    await prefs.setString('ui_globalMargin', ctrl.globalMarginController.text);
    await prefs.setString('ui_discount', ctrl.discountController.text);
    if (ctrl.selectedRoom != null) await prefs.setString('ui_room', ctrl.selectedRoom!);
    if (ctrl.selectedCeilingType != null) await prefs.setString('ui_ceiling', ctrl.selectedCeilingType!);
    if (ctrl.selectedBrand != null) await prefs.setString('ui_brand', ctrl.selectedBrand!);
    if (ctrl.selectedDesign != null) await prefs.setString('ui_design', ctrl.selectedDesign!);
    await prefs.setString('ui_customRoom', ctrl.roomController.text);
    await prefs.setString('ui_customBrand', ctrl.brandController.text);
    await prefs.setString('ui_customDesign', ctrl.designController.text);

    // Cache currentItems and currentPayments as JSON for local failsafe
    final itemsList = ctrl.currentItems.map((item) => item.toMap(ctrl.activeProjectId ?? 0)).toList();
    await prefs.setString('ui_cachedItems', jsonEncode(itemsList));
    
    final paymentsList = ctrl.currentPayments.map((p) => p.toMap(ctrl.activeProjectId ?? 0)).toList();
    await prefs.setString('ui_cachedPayments', jsonEncode(paymentsList));
  }

  static Future<void> loadUiState(CalculatorController ctrl) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load active project first if it exists
    final savedProjectId = prefs.getInt('ui_activeProjectId');
    if (savedProjectId != null) {
      try {
        final quotations = await DatabaseService.instance.getQuotations();
        final q = quotations.firstWhere((item) => item.id == savedProjectId);
        ctrl.loadQuotationState(q);
        return; // loadQuotationState handles everything
      } catch (_) {}
    }

    // Hydrate cached items and payments if activeProjectId is null or database loading fails
    final cachedItemsStr = prefs.getString('ui_cachedItems');
    if (cachedItemsStr != null && cachedItemsStr.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(cachedItemsStr);
        ctrl.currentItems.clear();
        ctrl.currentItems.addAll(decoded.map((map) => QuotationItem.fromMap(Map<String, dynamic>.from(map))));
      } catch (e) {
        debugPrint('Error loading cached items: $e');
      }
    }

    final cachedPaymentsStr = prefs.getString('ui_cachedPayments');
    if (cachedPaymentsStr != null && cachedPaymentsStr.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(cachedPaymentsStr);
        ctrl.currentPayments.clear();
        ctrl.currentPayments.addAll(decoded.map((map) => PaymentRecord.fromMap(Map<String, dynamic>.from(map))));
      } catch (e) {
        debugPrint('Error loading cached payments: $e');
      }
    }

    // Fallback to loading individual fields if no active project
    final customCeilings = prefs.getStringList('custom_ceilings') ?? [];
    for (var c in customCeilings) {
      if (!ctrl.ceilingTypes.containsKey(c)) {
        ctrl.ceilingTypes[c] = prefs.getDouble('rate_$c') ?? 0.0;
        ctrl.brandsMap[c] = ['Other'];
      }
    }
    
    final customBrands = prefs.getStringList('custom_brands') ?? [];
    for (var b in customBrands) {
      final parts = b.split('||');
      if (parts.length == 2 && ctrl.brandsMap.containsKey(parts[0])) {
        if (!ctrl.brandsMap[parts[0]]!.contains(parts[1])) {
          ctrl.brandsMap[parts[0]]!.insert(0, parts[1]);
        }
      }
    }
    
    final customDesigns = prefs.getStringList('custom_designs') ?? [];
    for (var d in customDesigns) {
      if (!ctrl.designTypes.contains(d)) ctrl.designTypes.insert(0, d);
    }
    
    ctrl.clientNameController.text = prefs.getString('ui_clientName') ?? '';
    ctrl.clientLocationController.text = prefs.getString('ui_location') ?? '';
    ctrl.folderController.text = prefs.getString('ui_folder') ?? '';
    ctrl.clientPhoneController.text = prefs.getString('ui_phone') ?? '';
    ctrl.unitNumberController.text = prefs.getString('ui_unitNumber') ?? 'UNIT-${DateFormat('yyyyMMdd-HHmm').format(DateTime.now())}';
    ctrl.globalMaterialCostController.text = prefs.getString('ui_globalMaterialCost') ?? '';
    ctrl.globalMarginController.text = prefs.getString('ui_globalMargin') ?? '';
    ctrl.discountController.text = prefs.getString('ui_discount') ?? '0';
    ctrl.unit = prefs.getString('ui_unit') ?? 'SqFt';
    ctrl.selectedRoom = prefs.getString('ui_room');
    
    String? savedCeiling = prefs.getString('ui_ceiling');
    if (savedCeiling?.toLowerCase() == 'gypsum' || savedCeiling?.toLowerCase() == 'gypsum board') {
      savedCeiling = 'Gypsum Board';
    }
    if (savedCeiling?.toLowerCase() == 'pvc ceiling' || savedCeiling?.toLowerCase() == 'pvc board') {
      savedCeiling = 'PVC Board';
    }

    if (savedCeiling != null && ctrl.ceilingTypes.containsKey(savedCeiling)) {
      ctrl.selectedCeilingType = savedCeiling;
    } else {
      ctrl.selectedCeilingType = null;
    }

    String? savedBrand = prefs.getString('ui_brand');
    final effectiveCeiling = ctrl.selectedCeilingType ?? 'Gypsum Board';
    final brands = ctrl.brandsMap[effectiveCeiling] ?? [];
    
    if (savedBrand != null && (brands.contains(savedBrand) || savedBrand == 'Other')) {
      ctrl.selectedBrand = savedBrand;
    } else {
      ctrl.selectedBrand = null;
    }

    ctrl.selectedDesign = prefs.getString('ui_design');
    if (ctrl.selectedDesign != null && !ctrl.designTypes.contains(ctrl.selectedDesign) && ctrl.selectedDesign != 'Other') {
      ctrl.selectedDesign = null;
    }

    ctrl.roomController.text = prefs.getString('ui_customRoom') ?? '';
    ctrl.brandController.text = prefs.getString('ui_customBrand') ?? '';
    ctrl.designController.text = prefs.getString('ui_customDesign') ?? '';
    ctrl.updateProjectTotals();
    ctrl.notifyUI();
  }

  static void triggerAutoSave(CalculatorController ctrl) {
    saveUiState(ctrl);
    ctrl.debounceTimer?.cancel();
    ctrl.debounceTimer = Timer(const Duration(milliseconds: 1500), () {
      saveToDatabase(ctrl, showSnackBar: false);
    });
  }

  static Future<void> saveToDatabase(CalculatorController ctrl, {bool showSnackBar = true, VoidCallback? onSuccess}) async {
    if (ctrl.isSaving) return;
    
    // Failsafe: Avoid inserting empty stubs when starting a completely new project
    if (ctrl.activeProjectId == null && 
        ctrl.currentItems.isEmpty && 
        ctrl.clientNameController.text.trim().isEmpty) {
      if (showSnackBar && onSuccess != null) onSuccess();
      return;
    }

    ctrl.isSaving = true;
    try {
      final normalizedUnit = ClientService.normalizeUnitNumber(ctrl.unitNumberController.text);
      if (ctrl.unitNumberController.text != normalizedUnit) {
        ctrl.unitNumberController.text = normalizedUnit;
      }

      final quota = Quotation(
        id: ctrl.activeProjectId,
        unitNumber: normalizedUnit,
        clientName: ctrl.clientNameController.text.trim(),
        clientPhone: ctrl.clientPhoneController.text.trim(),
        clientLocation: ctrl.clientLocationController.text.trim(),
        locationFolder: ctrl.folderController.text.trim().isNotEmpty ? ctrl.folderController.text.trim() : null,
        date: DateFormat('dd-MM-yyyy hh:mm a').format(DateTime.now()),
        totalAmount: ctrl.projectTotalAmount, paidAmount: ctrl.currentPayments.fold(0.0, (sum, item) => sum + item.amount), balanceAmount: ctrl.balanceAmount,
        items: ctrl.currentItems,
        materials: await DatabaseService.instance.database.then((db) async { if (ctrl.activeProjectId == null) return <MaterialAssignment>[]; final res = await db.query('quotation_materials', where: 'quotationId = ?', whereArgs: [ctrl.activeProjectId]); return res.map((m) => MaterialAssignment.fromMap(m)).toList(); }),
        rentals: await DatabaseService.instance.database.then((db) async { 
          if (ctrl.activeProjectId == null) return <RentalRecord>[]; 
          try {
            final res = await db.query('quotation_rentals', where: 'quotationId = ?', whereArgs: [ctrl.activeProjectId]); 
            return res.map((r) => RentalRecord(
              id: r['id'].toString(), 
              itemName: r['itemName'] as String, 
              siteName: r['siteName'] as String, 
              siteId: r['quotationId']?.toString(), 
              startDate: DateTime.tryParse(r['startDate'] as String? ?? '') ?? DateTime.now(), 
              dailyRate: (r['dailyRate'] as num?)?.toDouble() ?? 0.0, 
              quantity: (r['quantity'] as num?)?.toDouble() ?? 1.0, 
              status: r['status'] as String? ?? 'Out'
            )).toList();
          } catch (e) {
            debugPrint('Error loading rentals: $e');
            return <RentalRecord>[];
          }
        }),
        payments: ctrl.currentPayments,
        manualAmount: double.tryParse(ctrl.manualAmountController.text) ?? 0,
        manualWeight: double.tryParse(ctrl.manualWeightController.text) ?? 0,
        includeWastage: ctrl.includeWastage,
        originalAmount: double.tryParse(ctrl.originalAmountController.text),
        revisionNote: ctrl.revisionNoteController.text.trim().isNotEmpty ? ctrl.revisionNoteController.text.trim() : null,
        globalMaterialCost: double.tryParse(ctrl.globalMaterialCostController.text) ?? 0.0,
        globalMargin: double.tryParse(ctrl.globalMarginController.text) ?? 0.0,
        discount: double.tryParse(ctrl.discountController.text) ?? 0.0,
        projectStatus: ctrl.projectStatus,
        approvalSignature: ctrl.approvalSignature,
      );
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ui_unitNumber', normalizedUnit);

      if (ctrl.activeProjectId != null) {
        await DatabaseService.instance.updateQuotation(quota);
      } else { 
        ctrl.activeProjectId = await DatabaseService.instance.saveFullQuotation(quota); 
        ctrl.notifyUI();
      }

      // PRODUCTION-GRADE MIRRORING: Sync local data to Supabase in the background
      unawaited(CustomerSyncService.instance.saveQuotationToCloud(quota));

      try {
        final double totalLaborCost = await ClientService.instance.fetchTotalLaborCost(normalizedUnit);
        final client = Client(
          id: normalizedUnit,
          clientName: ctrl.clientNameController.text.trim().isEmpty ? 'SITE DRAFT' : ctrl.clientNameController.text.trim(),
          phoneNumber: ctrl.clientPhoneController.text.trim(),
          siteLocation: ctrl.clientLocationController.text.trim(),
          unitNumber: normalizedUnit,
          clientSelfie: '',
          totalContractAmount: ctrl.projectTotalAmount,
          advanceReceived: ctrl.currentPayments.fold(0.0, (sum, item) => sum + item.amount),
          totalLaborCost: totalLaborCost,
          latitude: quota.latitude,
          longitude: quota.longitude,
          createdAt: DateTime.now(),
        );
        await ClientService.instance.updateClient(client);
      } catch (e) {
        debugPrint('Error auto-syncing client financials: $e');
      }
      
      // RE-FETCH & LOCK: Ensure the UI is synced with the latest database ID
      await saveUiState(ctrl);
      
      ctrl.showSavedIndicator = true;
      ctrl.notifyUI();
      Future.delayed(const Duration(seconds: 2), () {
        ctrl.showSavedIndicator = false;
        ctrl.notifyUI();
      });

      if (showSnackBar && onSuccess != null) onSuccess();
    } catch (e) {
      debugPrint('Save Error: $e');
    } finally {
      ctrl.isSaving = false;
    }
  }
}
