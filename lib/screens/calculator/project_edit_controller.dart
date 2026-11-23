import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/client_model.dart';
import '../../models/quotation.dart';
import '../../providers/navigation_provider.dart';
import '../../services/database_service.dart';
import '../../services/customer_sync_service.dart';
import '../../services/client_service.dart';
import 'calculator_screen.dart';

class ProjectEditController extends ChangeNotifier {
  static final ProjectEditController instance = ProjectEditController._internal();
  ProjectEditController._internal();

  String? _pendingProjectId;
  Client? _pendingClient;
  Quotation? _pendingQuotation;
  String? _pendingDispatchId;

  String? get pendingProjectId => _pendingProjectId;
  Client? get pendingClient => _pendingClient;
  Quotation? get pendingQuotation => _pendingQuotation;
  String? get pendingDispatchId => _pendingDispatchId;

  void requestEdit(String projectId, {Client? client, Quotation? quotation}) {
    _pendingProjectId = projectId;
    _pendingClient = client;
    _pendingQuotation = quotation;
    notifyListeners();
  }

  void requestDispatchEdit(String dispatchId) {
    _pendingDispatchId = dispatchId;
    notifyListeners();
  }

  void clearRequest() {
    _pendingProjectId = null;
    _pendingClient = null;
    _pendingQuotation = null;
  }

  void clearDispatchEdit() {
    _pendingDispatchId = null;
  }

  /// Opens the calculator editing view for a site model/quotation, restoring saved rooms, SQFT, and breakdown into state
  static Future<void> openCalculatorEditPageForSite(
    dynamic siteOrContext, {
    String? projectId,
    Client? client,
    Quotation? quotation,
    bool isEditing = true,
    dynamic siteData,
  }) async {
    BuildContext? context;
    dynamic effectiveSiteData = siteData;

    if (siteOrContext is BuildContext) {
      context = siteOrContext;
      effectiveSiteData ??= quotation ?? client;
    } else {
      effectiveSiteData ??= siteOrContext;
    }

    String effectiveProjectId = projectId ?? '';
    Quotation? effectiveQuotation = quotation;
    Client? effectiveClient = client;

    if (effectiveSiteData is Quotation) {
      effectiveQuotation = effectiveSiteData;
      effectiveProjectId = effectiveSiteData.unitNumber;
    } else if (effectiveSiteData is Client) {
      effectiveClient = effectiveSiteData;
      effectiveProjectId = effectiveSiteData.unitNumber;
    } else if (effectiveSiteData is String) {
      effectiveProjectId = effectiveSiteData;
    }

    // Check if quotation items are empty; if so, fetch saved rooms and entries from DatabaseService
    if (effectiveQuotation == null || effectiveQuotation.items.isEmpty) {
      final queryId = effectiveProjectId.isNotEmpty
          ? effectiveProjectId
          : (effectiveClient?.unitNumber ?? effectiveClient?.id ?? '');
      if (queryId.isNotEmpty) {
        try {
          final q = await DatabaseService.instance.getQuotationByProjectIdOrUnit(
            queryId,
            altUnit: effectiveClient?.unitNumber ?? effectiveClient?.id,
            clientPhone: effectiveClient?.phoneNumber,
          );
          if (q != null && q.items.isNotEmpty) {
            effectiveQuotation = q;
            effectiveSiteData = q;
            if (effectiveProjectId.isEmpty) {
              effectiveProjectId = q.unitNumber;
            }
          } else {
            final items = await DatabaseService.instance.getQuotationItems(
              queryId,
              altUnit: effectiveClient?.unitNumber ?? effectiveClient?.id,
              clientPhone: effectiveClient?.phoneNumber,
              clientName: effectiveClient?.clientName,
              quotationId: q?.id,
            );
            if (items.isNotEmpty) {
              effectiveQuotation = (q ?? effectiveQuotation)?.copyWith(items: items);
              effectiveSiteData = effectiveQuotation;
            }
          }
        } catch (e) {
          debugPrint('Notice fetching saved quotation items: $e');
        }
      }
    }

    if (effectiveProjectId.isNotEmpty) {
      ProjectEditController.instance.requestEdit(
        effectiveProjectId,
        client: effectiveClient,
        quotation: effectiveQuotation,
      );
    }

    if (context != null && context.mounted) {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        enableDrag: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withValues(alpha: 0.65),
        builder: (sheetContext) => SizedBox(
          height: MediaQuery.of(sheetContext).size.height * 0.94,
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: CalculatorScreen(
                      client: effectiveClient,
                      quotation: effectiveQuotation,
                      projectId: effectiveProjectId.isNotEmpty ? effectiveProjectId : null,
                      isEditing: isEditing,
                      siteData: effectiveSiteData,
                      isSheet: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  static Future<void> handleScannedQRCode(BuildContext context, String code) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.white)),
    );

    try {
      String scannedId = code;
      String type = 'quotation';
      Map<String, String> parsedKeyValFields = {};

      // 1. Try decoding JSON
      try {
        final Map<String, dynamic> data = jsonDecode(code);
        if (data.containsKey('type')) {
          type = data['type'];
        }
        if (data.containsKey('unitNumber')) {
          scannedId = data['unitNumber'];
        } else if (data.containsKey('id')) {
          scannedId = data['id'].toString();
        }
      } catch (_) {
        // 2. Try parsing as key-value plain text (e.g. invoice)
        final lines = code.split('\n');
        for (var line in lines) {
          final parts = line.split(':');
          if (parts.length >= 2) {
            final key = parts[0].trim().toLowerCase();
            final val = parts.sublist(1).join(':').trim();
            parsedKeyValFields[key] = val;
          }
        }

        if (parsedKeyValFields.containsKey('unit') || 
            parsedKeyValFields.containsKey('project') || 
            parsedKeyValFields.containsKey('name') || 
            parsedKeyValFields.containsKey('phone')) {
          scannedId = parsedKeyValFields['unit'] ?? 
                      parsedKeyValFields['project id'] ?? 
                      parsedKeyValFields['project'] ?? 
                      parsedKeyValFields['phone'] ?? 
                      'DRAFT-${DateFormat('yyyyMMdd-HHmmss').format(DateTime.now())}';
        } else {
          // 3. Try parsing URL
          try {
            final uri = Uri.parse(code);
            if (uri.queryParameters.containsKey('type')) {
              type = uri.queryParameters['type']!;
            }
            
            if (uri.queryParameters.containsKey('projectId')) {
              scannedId = uri.queryParameters['projectId']!;
            } else if (uri.queryParameters.containsKey('unitNumber')) {
              scannedId = uri.queryParameters['unitNumber']!;
            } else if (uri.queryParameters.containsKey('id')) {
              scannedId = uri.queryParameters['id']!;
            } else {
              // Check path segments
              final pathSegments = uri.pathSegments;
              if (pathSegments.isNotEmpty) {
                scannedId = pathSegments.last;
                if (uri.path.contains('/dispatch/')) {
                  type = 'dispatch';
                }
              }
            }
          } catch (_) {}
        }
      }

      // Check if it is a dispatch list
      if (type == 'dispatch' || scannedId.startsWith('DISPATCH-')) {
        ProjectEditController.instance.requestDispatchEdit(scannedId);
        if (context.mounted) {
          Navigator.pop(context); // Close loading dialog
          try {
            final nav = Provider.of<NavigationProvider>(context, listen: false);
            nav.setTab(3);
          } catch (_) {}
        }
      } else {
        // Resolve project/quotation (quotation / registration / local / cloud / key-value fallback)
        
        final cleanScannedUnit = ClientService.normalizeUnitNumber(scannedId);

        // A. Search local SQLite quotations
        final localQuotes = await DatabaseService.instance.getQuotations();
        Quotation? localMatch;
        for (var q in localQuotes) {
          if (q.unitNumber == scannedId ||
              q.id.toString() == scannedId ||
              ClientService.normalizeUnitNumber(q.unitNumber) == cleanScannedUnit) {
            localMatch = q;
            break;
          }
        }

        int? targetLocalId;
        Client? matchedClient;
        Quotation? resolvedQuote;

        if (localMatch != null) {
          targetLocalId = localMatch.id;
          resolvedQuote = localMatch;
        } else {
          // B. Query cloud database
          final cloudQuote = await CustomerSyncService.instance.getQuotationFromCloud(cleanScannedUnit) ??
                             await CustomerSyncService.instance.getQuotationFromCloud(scannedId);
          if (cloudQuote != null) {
            targetLocalId = await DatabaseService.instance.saveFullQuotation(cloudQuote);
            resolvedQuote = cloudQuote.copyWith(id: targetLocalId);
          } else {
            // C. Query clients database in Firestore
            final clientMatch = await ClientService.instance.getClientByUnitNumber(cleanScannedUnit) ??
                                await ClientService.instance.getClientByUnitNumber(scannedId);
            if (clientMatch != null) {
              matchedClient = clientMatch;
              final draftQuotation = Quotation(
                unitNumber: clientMatch.unitNumber,
                clientName: clientMatch.clientName,
                clientPhone: clientMatch.phoneNumber,
                clientLocation: clientMatch.siteLocation,
                locationFolder: clientMatch.siteLocation,
                date: DateFormat('dd-MM-yyyy hh:mm a').format(DateTime.now()),
                totalAmount: clientMatch.totalContractAmount,
                paidAmount: clientMatch.advanceReceived,
                balanceAmount: clientMatch.balanceDue,
                manualAmount: clientMatch.totalContractAmount,
                items: const [],
                materials: const [],
                rentals: const [],
                payments: clientMatch.advanceReceived > 0 
                    ? [PaymentRecord(description: 'Advance Received', amount: clientMatch.advanceReceived, date: DateFormat('dd-MM-yyyy hh:mm a').format(DateTime.now()))] 
                    : const [],
                projectStatus: clientMatch.status,
              );
              targetLocalId = await DatabaseService.instance.saveFullQuotation(draftQuotation);
              resolvedQuote = draftQuotation.copyWith(id: targetLocalId);
            } else {
              // D. Query registrations database via CustomerSyncService for live Vercel registrations
              final reg = await CustomerSyncService.instance.getRegistrationFromCloud(scannedId);
              if (reg != null) {
                final effectiveUnit = (reg.projectId != null && reg.projectId!.isNotEmpty)
                    ? ClientService.normalizeUnitNumber(reg.projectId!)
                    : cleanScannedUnit;
                final effectiveName = reg.name.trim().isNotEmpty ? reg.name.trim() : 'PCM CLIENT';

                matchedClient = Client(
                  id: effectiveUnit.replaceAll('#', '').trim(),
                  clientName: effectiveName,
                  phoneNumber: reg.phone,
                  siteLocation: reg.location,
                  unitNumber: effectiveUnit,
                  clientSelfie: '',
                  totalContractAmount: 0.0,
                  advanceReceived: 0.0,
                  totalLaborCost: 0.0,
                  latitude: reg.latitude,
                  longitude: reg.longitude,
                  createdAt: DateTime.now(),
                );
                
                final draftQuotation = Quotation(
                  unitNumber: effectiveUnit,
                  clientName: matchedClient.clientName,
                  clientPhone: matchedClient.phoneNumber,
                  clientLocation: matchedClient.siteLocation,
                  latitude: reg.latitude,
                  longitude: reg.longitude,
                  date: DateFormat('dd-MM-yyyy hh:mm a').format(DateTime.now()),
                  totalAmount: 0.0,
                  paidAmount: 0.0,
                  balanceAmount: 0.0,
                  items: const [],
                  materials: const [],
                  rentals: const [],
                  payments: const [],
                  projectStatus: 'Registered',
                );
                targetLocalId = await DatabaseService.instance.saveFullQuotation(draftQuotation);
                resolvedQuote = draftQuotation.copyWith(id: targetLocalId);
              } else {
                // E. Key-value parsing or default fallback
                final clientName = parsedKeyValFields['name'] ?? parsedKeyValFields['client'] ?? 'Site Draft';
                final clientPhone = parsedKeyValFields['phone'] ?? parsedKeyValFields['mobile'] ?? '';
                final clientLocation = parsedKeyValFields['location'] ?? parsedKeyValFields['address'] ?? '';

                final draftQuotation = Quotation(
                  unitNumber: cleanScannedUnit,
                  clientName: clientName,
                  clientPhone: clientPhone,
                  clientLocation: clientLocation,
                  date: DateFormat('dd-MM-yyyy hh:mm a').format(DateTime.now()),
                  totalAmount: 0.0,
                  paidAmount: 0.0,
                  balanceAmount: 0.0,
                  items: const [],
                  materials: const [],
                  rentals: const [],
                  payments: const [],
                  projectStatus: 'Draft',
                );
                targetLocalId = await DatabaseService.instance.saveFullQuotation(draftQuotation);
                resolvedQuote = draftQuotation.copyWith(id: targetLocalId);
              }
            }
          }
        }

        if (context.mounted) {
          Navigator.pop(context); // Close loading dialog
          
          ProjectEditController.instance.requestEdit(
            targetLocalId.toString(),
            client: matchedClient,
            quotation: resolvedQuote,
          );
          try {
            final nav = Provider.of<NavigationProvider>(context, listen: false);
            nav.setTab(2);
          } catch (_) {}

          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CalculatorScreen(
                client: matchedClient,
                quotation: resolvedQuote,
                projectId: targetLocalId.toString(),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      debugPrint('QR Code handle error: $e');
    }
  }
}
