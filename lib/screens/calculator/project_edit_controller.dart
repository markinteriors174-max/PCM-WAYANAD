import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/client_model.dart';
import '../../models/quotation.dart';
import '../../providers/navigation_provider.dart';
import '../../services/database_service.dart';
import '../../services/customer_sync_service.dart';

class ProjectEditController extends ChangeNotifier {
  static final ProjectEditController instance = ProjectEditController._internal();
  ProjectEditController._internal();

  String? _pendingProjectId;
  Client? _pendingClient;
  String? _pendingDispatchId;

  String? get pendingProjectId => _pendingProjectId;
  Client? get pendingClient => _pendingClient;
  String? get pendingDispatchId => _pendingDispatchId;

  void requestEdit(String projectId, {Client? client}) {
    _pendingProjectId = projectId;
    _pendingClient = client;
    notifyListeners();
  }

  void requestDispatchEdit(String dispatchId) {
    _pendingDispatchId = dispatchId;
    notifyListeners();
  }

  void clearRequest() {
    _pendingProjectId = null;
    _pendingClient = null;
  }

  void clearDispatchEdit() {
    _pendingDispatchId = null;
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
        
        // A. Search local SQLite quotations
        final localQuotes = await DatabaseService.instance.getQuotations();
        Quotation? localMatch;
        for (var q in localQuotes) {
          if (q.unitNumber == scannedId || q.id.toString() == scannedId) {
            localMatch = q;
            break;
          }
        }

        int? targetLocalId;
        Client? matchedClient;

        if (localMatch != null) {
          targetLocalId = localMatch.id;
        } else {
          // B. Query cloud database
          final cloudQuote = await CustomerSyncService.instance.getQuotationFromCloud(scannedId);
          if (cloudQuote != null) {
            targetLocalId = await DatabaseService.instance.saveFullQuotation(cloudQuote);
          } else {
            // C. Query registrations database
            final regSnap = await FirebaseFirestore.instance.collection('registrations')
                .where('projectId', isEqualTo: scannedId)
                .limit(1)
                .get();
            if (regSnap.docs.isNotEmpty) {
              final reg = regSnap.docs.first.data();
              matchedClient = Client(
                id: regSnap.docs.first.id,
                clientName: reg['name'] ?? '',
                phoneNumber: reg['phone'] ?? '',
                siteLocation: reg['location'] ?? '',
                unitNumber: scannedId,
                clientSelfie: '',
                totalContractAmount: 0.0,
                advanceReceived: 0.0,
                totalLaborCost: 0.0,
                createdAt: DateTime.now(),
              );
              
              final draftQuotation = Quotation(
                unitNumber: scannedId,
                clientName: matchedClient.clientName,
                clientPhone: matchedClient.phoneNumber,
                clientLocation: matchedClient.siteLocation,
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
            } else {
              // D. Key-value parsing or default fallback
              final clientName = parsedKeyValFields['name'] ?? parsedKeyValFields['client'] ?? 'Site Draft';
              final clientPhone = parsedKeyValFields['phone'] ?? parsedKeyValFields['mobile'] ?? '';
              final clientLocation = parsedKeyValFields['location'] ?? parsedKeyValFields['address'] ?? '';

              final draftQuotation = Quotation(
                unitNumber: scannedId,
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
            }
          }
        }

        if (context.mounted) {
          Navigator.pop(context); // Close loading dialog
          
          ProjectEditController.instance.requestEdit(targetLocalId.toString(), client: matchedClient);
          try {
            final nav = Provider.of<NavigationProvider>(context, listen: false);
            nav.setTab(2);
          } catch (_) {}
        }
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      debugPrint('QR Code handle error: $e');
    }
  }
}
