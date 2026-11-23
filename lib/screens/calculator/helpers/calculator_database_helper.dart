import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/quotation.dart';
import '../../../models/rental_model.dart';
import '../../../services/database_service.dart';
import '../../../services/customer_sync_service.dart';
import '../../../services/client_service.dart';
import '../../../models/client_model.dart';
import '../calculator_controller.dart';
import 'location_picker_helper.dart';

class CalculatorDatabaseHelper {
  static Future<void> loadProject(
    CalculatorController ctrl,
    String projectId,
    VoidCallback onShowSaved, {
    Client? client,
    Quotation? fallbackQuotation,
  }) async {
    try {
      final cleanProjectUnit = ClientService.normalizeUnitNumber(projectId);
      
      Quotation? quotation = await DatabaseService.instance.getQuotationByProjectIdOrUnit(
        projectId,
        altUnit: client?.unitNumber ?? client?.id ?? fallbackQuotation?.unitNumber,
        clientPhone: client?.phoneNumber ?? fallbackQuotation?.clientPhone,
      );

      // If not found locally or if items are empty, try fetching from Cloud by unitNumber if available
      if (quotation == null || quotation.items.isEmpty) {
        final cloudQ = await CustomerSyncService.instance.getQuotationFromCloud(cleanProjectUnit) ??
            (projectId != cleanProjectUnit ? await CustomerSyncService.instance.getQuotationFromCloud(projectId) : null) ??
            (client != null ? await CustomerSyncService.instance.getQuotationFromCloud(client.unitNumber) : null);
        if (cloudQ != null && cloudQ.items.isNotEmpty) {
          quotation = cloudQ;
          // Save a local copy instantly for offline persistence
          final newId = await DatabaseService.instance.saveFullQuotation(cloudQ);
          quotation = cloudQ.copyWith(id: newId);
        }
      }

      // If items are still empty, explicitly query DatabaseService for saved room items
      if (quotation == null || quotation.items.isEmpty) {
        final savedItems = await DatabaseService.instance.getQuotationItems(
          projectId,
          altUnit: client?.unitNumber ?? client?.id ?? fallbackQuotation?.unitNumber,
          clientPhone: client?.phoneNumber ?? fallbackQuotation?.clientPhone,
          clientName: client?.clientName ?? fallbackQuotation?.clientName,
          quotationId: quotation?.id,
        );
        if (savedItems.isNotEmpty) {
          if (quotation != null) {
            quotation = quotation.copyWith(items: savedItems);
          } else if (fallbackQuotation != null) {
            quotation = fallbackQuotation.copyWith(items: savedItems);
          } else if (client != null) {
            quotation = Quotation(
              unitNumber: client.unitNumber,
              clientName: client.clientName,
              clientPhone: client.phoneNumber,
              clientLocation: client.siteLocation,
              locationFolder: client.siteLocation,
              date: DateFormat('dd-MM-yyyy hh:mm a').format(DateTime.now()),
              totalAmount: client.totalContractAmount,
              paidAmount: client.advanceReceived,
              balanceAmount: client.balanceDue,
              manualAmount: client.totalContractAmount,
              items: savedItems,
            );
          }
        }
      }

      if (quotation == null || quotation.items.isEmpty) {
        if (fallbackQuotation != null && fallbackQuotation.items.isNotEmpty) {
          if (quotation != null) {
            quotation = quotation.copyWith(
              items: fallbackQuotation.items,
              materials: fallbackQuotation.materials.isNotEmpty ? fallbackQuotation.materials : quotation.materials,
              totalAmount: quotation.totalAmount > 0 ? quotation.totalAmount : fallbackQuotation.totalAmount,
            );
          } else {
            quotation = fallbackQuotation;
          }
        }
      }

      if (quotation == null) {
        if (fallbackQuotation != null) {
          quotation = fallbackQuotation;
        } else if (client != null) {
          quotation = Quotation(
            unitNumber: client.unitNumber,
            clientName: client.clientName,
            clientPhone: client.phoneNumber,
            clientLocation: client.siteLocation,
            locationFolder: client.siteLocation,
            date: DateFormat('dd-MM-yyyy hh:mm a').format(DateTime.now()),
            totalAmount: client.totalContractAmount,
            paidAmount: client.advanceReceived,
            balanceAmount: client.balanceDue,
            manualAmount: client.totalContractAmount,
            items: const [],
          );
        }
      }

      if (quotation != null && client != null) {
        // Keep quotation items & calculation, but ensure client details are up to date
        quotation = quotation.copyWith(
          clientName: client.clientName.isNotEmpty ? client.clientName : quotation.clientName,
          clientPhone: client.phoneNumber.isNotEmpty ? client.phoneNumber : quotation.clientPhone,
          clientLocation: client.siteLocation.isNotEmpty ? client.siteLocation : quotation.clientLocation,
          paidAmount: client.advanceReceived > 0 ? client.advanceReceived : quotation.paidAmount,
          balanceAmount: client.balanceDue > 0 ? client.balanceDue : quotation.balanceAmount,
        );
      }

      if (quotation == null) return;
      
      ctrl.loadQuotationState(quotation, force: true);

      // Double-check: ensure currentItems is populated if quotation had empty items
      if (ctrl.currentItems.isEmpty) {
        final finalItems = await DatabaseService.instance.getQuotationItems(
          projectId,
          altUnit: ctrl.unitNumberController.text,
          clientPhone: ctrl.clientPhoneController.text,
          clientName: ctrl.clientNameController.text,
          quotationId: ctrl.activeProjectId,
        );
        if (finalItems.isNotEmpty) {
          ctrl.currentItems.clear();
          ctrl.currentItems.addAll(finalItems);
          ctrl.updateProjectTotals();
          ctrl.notifyUI();
        }
      }
      listenForSync(ctrl, onShowSaved);
      saveUiState(ctrl);
      onShowSaved();
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
        if (reg.name.isNotEmpty && reg.name.toUpperCase() != 'SITE DRAFT') {
          ctrl.clientNameController.text = reg.name;
        }
        if (reg.phone.isNotEmpty) ctrl.clientPhoneController.text = reg.phone;
        if (reg.location.isNotEmpty) {
          ctrl.clientLocationController.text = reg.location;
          if (ctrl.folderController.text.isEmpty) ctrl.folderController.text = reg.location;
        }
        if (reg.projectId != null && reg.projectId!.isNotEmpty) {
          final norm = ClientService.normalizeUnitNumber(reg.projectId!);
          if (ctrl.unitNumberController.text != norm) {
            ctrl.unitNumberController.text = norm;
          }
        }
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
    final rawUnitText = ctrl.unitNumberController.text.trim();
    final cleanUnit = ClientService.normalizeUnitNumber(rawUnitText);
    final effectiveUnit = cleanUnit.isNotEmpty ? cleanUnit : rawUnitText;
    await prefs.setString('ui_unitNumber', effectiveUnit);
    await prefs.setString('ui_clientName', ctrl.clientNameController.text);
    await prefs.setString('ui_location', ctrl.clientLocationController.text);
    await prefs.setString('ui_folder', ctrl.folderController.text);
    await prefs.setString('ui_phone', ctrl.clientPhoneController.text);
    await prefs.setString('ui_unit', ctrl.unit);
    await prefs.setString('ui_globalMaterialCost', ctrl.globalMaterialCostController.text);
    await prefs.setString('ui_globalMargin', ctrl.globalMarginController.text);
    await prefs.setString('ui_discount', ctrl.discountController.text);
    if (ctrl.selectedRoom != null && ctrl.selectedRoom != 'Bedroom 1' && ctrl.selectedRoom != 'Bedroom 2') {
      await prefs.setString('ui_room', ctrl.selectedRoom!);
    } else {
      await prefs.remove('ui_room');
    }
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
    final savedUnit = prefs.getString('ui_unitNumber');
    if (savedProjectId != null || (savedUnit != null && savedUnit.isNotEmpty)) {
      try {
        final q = await DatabaseService.instance.getQuotationByProjectIdOrUnit(
          savedProjectId?.toString() ?? savedUnit!,
          altUnit: savedUnit,
        );
        if (q != null) {
          ctrl.loadQuotationState(q, force: true);
          return; // loadQuotationState handles everything
        }
      } catch (_) {}
    }

    final savedPhone = prefs.getString('ui_phone');
    final savedName = prefs.getString('ui_clientName');
    if ((savedPhone != null && savedPhone.isNotEmpty) || (savedName != null && savedName.isNotEmpty)) {
      try {
        final existing = await DatabaseService.instance.findActiveProjectForClient(
          phone: savedPhone,
          name: savedName,
        );
        if (existing != null) {
          ctrl.loadQuotationState(existing, force: true);
          return;
        }
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
    final rawLocation = prefs.getString('ui_location') ?? '';
    final cleanLocation = LocationPickerHelper.sanitizePlaceString(rawLocation);
    ctrl.clientLocationController.text = cleanLocation;
    if (rawLocation != cleanLocation && rawLocation.isNotEmpty) {
      await prefs.setString('ui_location', cleanLocation);
    }
    ctrl.folderController.text = prefs.getString('ui_folder') ?? '';
    ctrl.clientPhoneController.text = prefs.getString('ui_phone') ?? '';
    final rawUnit = prefs.getString('ui_unitNumber');
    final cleanUnit = ClientService.normalizeUnitNumber(rawUnit ?? '');
    ctrl.unitNumberController.text = cleanUnit;
    if (rawUnit != cleanUnit) {
      await prefs.setString('ui_unitNumber', cleanUnit);
    }
    ctrl.globalMaterialCostController.text = prefs.getString('ui_globalMaterialCost') ?? '';
    ctrl.globalMarginController.text = prefs.getString('ui_globalMargin') ?? '';
    ctrl.discountController.text = prefs.getString('ui_discount') ?? '0';
    ctrl.unit = prefs.getString('ui_unit') ?? 'Meter';
    ctrl.selectedRoom = prefs.getString('ui_room');
    if (ctrl.selectedRoom == 'Bedroom 1' || ctrl.selectedRoom == 'Bedroom 2') {
      ctrl.selectedRoom = null;
      await prefs.remove('ui_room');
    }
    
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
    // Spark Plan Optimization: Only save UI state locally to SharedPreferences/memory.
    // Never write to Firestore/Realtime Database on keystrokes, sliders, or toggles.
    saveUiState(ctrl);
    ctrl.debounceTimer?.cancel();
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
      String rawUnit = ctrl.unitNumberController.text.trim();
      final rawName = ctrl.clientNameController.text.trim();
      final rawPhone = ctrl.clientPhoneController.text.trim();

      final cleanPhone = rawPhone.replaceAll(RegExp(r'[^\d+]'), '').trim();
      final extraName = rawPhone.replaceAll(RegExp(r'[\d+\s\-]'), '').trim();

      String finalName = rawName;
      if (finalName.isEmpty || finalName.toUpperCase() == 'SITE DRAFT') {
        if (extraName.isNotEmpty) {
          finalName = extraName;
        } else {
          finalName = 'SITE DRAFT';
        }
      }

      // Check if an active project or quotation already exists for the phone or name before generating a new timestamp ID
      if (rawUnit.isEmpty || ClientService.isGeneratedTimestampId(rawUnit)) {
        final existing = await DatabaseService.instance.findActiveProjectForClient(
          phone: cleanPhone.isNotEmpty ? cleanPhone : rawPhone,
          name: finalName != 'SITE DRAFT' ? finalName : null,
        );
        if (existing != null) {
          if (existing.unitNumber.isNotEmpty) {
            rawUnit = existing.unitNumber;
            ctrl.unitNumberController.text = rawUnit;
          }
          if (ctrl.activeProjectId == null && existing.id != null) {
            ctrl.activeProjectId = existing.id;
          }
        }
      }

      // Only generate a new timestamp ID if no active project exists for this client and ID is still empty
      if (rawUnit.isEmpty) {
        rawUnit = '# PCM-${DateFormat('yyyyMMdd-HHmm').format(DateTime.now())}';
        ctrl.unitNumberController.text = rawUnit;
      }
      final normalizedUnit = ClientService.normalizeUnitNumber(rawUnit).isNotEmpty
          ? ClientService.normalizeUnitNumber(rawUnit)
          : rawUnit;

      if (cleanPhone.isNotEmpty && ctrl.clientPhoneController.text != cleanPhone) {
        ctrl.clientPhoneController.text = cleanPhone;
      }
      if (finalName != 'SITE DRAFT' && rawName.isEmpty) {
        ctrl.clientNameController.text = finalName;
      }

      final quota = Quotation(
        id: ctrl.activeProjectId,
        unitNumber: normalizedUnit,
        clientName: finalName,
        clientPhone: cleanPhone,
        clientLocation: ctrl.clientLocationController.text.trim(),
        locationFolder: ctrl.folderController.text.trim().isNotEmpty ? ctrl.folderController.text.trim() : null,
        date: DateFormat('dd-MM-yyyy hh:mm a').format(DateTime.now()),
        totalAmount: ctrl.projectTotalAmount, paidAmount: ctrl.currentPayments.fold(0.0, (sum, item) => sum + item.amount), balanceAmount: ctrl.balanceAmount,
        items: ctrl.currentItems,
        materials: kIsWeb
            ? <MaterialAssignment>[]
            : await DatabaseService.instance.database.then((db) async {
                if (ctrl.activeProjectId == null) return <MaterialAssignment>[];
                final res = await db.query('quotation_materials', where: 'quotationId = ?', whereArgs: [ctrl.activeProjectId]);
                return res.map((m) => MaterialAssignment.fromMap(m)).toList();
              }),
        rentals: kIsWeb
            ? <RentalRecord>[]
            : await DatabaseService.instance.database.then((db) async {
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
        rateTiers: ctrl.rateTiers.map((t) => t.toMap()).toList(),
      );
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ui_unitNumber', normalizedUnit);

      if (ctrl.activeProjectId != null) {
        await DatabaseService.instance.updateQuotation(quota);
      } else { 
        ctrl.activeProjectId = await DatabaseService.instance.saveFullQuotation(quota); 
        ctrl.notifyUI();
      }

      // PRODUCTION-GRADE MIRRORING: Sync local data to Firebase in the background
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
