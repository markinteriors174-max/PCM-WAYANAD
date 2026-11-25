import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../models/quotation.dart';
import '../models/client_model.dart';
import 'client_service.dart';
import 'sync_status_service.dart';

class CustomerRegistration {
  final String name;
  final String phone;
  final String location;
  final double? latitude;
  final double? longitude;
  final String? projectId;

  CustomerRegistration({
    required this.name,
    required this.phone,
    required this.location,
    this.latitude,
    this.longitude,
    this.projectId,
  });

  factory CustomerRegistration.fromMap(Map<String, dynamic> map) {
    return CustomerRegistration(
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      location: map['location'] ?? '',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      projectId: map['projectId'],
    );
  }
}

class CustomerSyncService {
  static final CustomerSyncService instance = CustomerSyncService._init();

  FirebaseFirestore get _firestore {
    try {
      Firebase.app(); // Throws if not initialized
      return FirebaseFirestore.instance;
    } catch (_) {
      throw Exception('Firebase not initialized. Cannot access Sync Service.');
    }
  }

  CustomerSyncService._init();

  // Upload photo to Firebase Firestore project_photos collection
  Future<String?> uploadProjectPhoto(Uint8List bytes, String fileName, {String? folder}) async {
    try {
      final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      final path = folder != null ? '$folder/$fileName' : fileName;
      final docId = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');

      await _firestore.collection('project_photos').doc(docId).set({
        'name': fileName,
        'path': path,
        'siteId': folder ?? 'general',
        'url': base64Image,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('Photo uploaded to Firestore successfully: $path');
      return base64Image;
    } catch (e) {
      debugPrint('Error uploading photo to Firestore: $e');
      return null;
    }
  }

  // Save full Quotation to Firebase Firestore
  Future<void> saveQuotationToCloud(Quotation quotation) async {
    var rawUnit = quotation.unitNumber.trim();
    if (rawUnit.isEmpty) {
      rawUnit = ClientService.normalizeUnitNumber('');
    }

    final normalizedUnit = ClientService.normalizeUnitNumber(rawUnit);
    final normalizedQuotation = quotation.copyWith(unitNumber: normalizedUnit);

    // Sync exclusively to Firebase Firestore with try-catch and timeout protection
    try {
      final cloudPayload = {
        ...normalizedQuotation.toCloudMap(),
        'createdAt': FieldValue.serverTimestamp(),
      };
      final docRef = _firestore.collection('quotations').doc(normalizedQuotation.unitNumber);
      await docRef.set(cloudPayload, SetOptions(merge: true)).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('Firestore saveQuotationToCloud set timed out for ${normalizedQuotation.unitNumber}.');
        },
      );

      final cleanDocId = normalizedQuotation.unitNumber.replaceAll('#', '').trim();
      if (cleanDocId != normalizedQuotation.unitNumber) {
        final docRef2 = _firestore.collection('quotations').doc(cleanDocId);
        await docRef2.set(cloudPayload, SetOptions(merge: true)).catchError((e) {
          debugPrint('Notice syncing raw doc ID to cloud: $e');
        });
      }
      debugPrint('Quotation synced to Firebase successfully and bound with partner: ${normalizedQuotation.partnerName}');

      try {
        // Also register/update the client in the Firestore 'clients' collection
        final double totalLaborCost = await ClientService.instance
            .fetchTotalLaborCost(normalizedQuotation.unitNumber)
            .timeout(const Duration(seconds: 5), onTimeout: () => 0.0);

        final client = Client(
          id: normalizedQuotation.unitNumber,
          clientName: normalizedQuotation.clientName.trim().isEmpty ? 'PCM SITE DRAFT' : normalizedQuotation.clientName.trim(),
          phoneNumber: normalizedQuotation.clientPhone,
          siteLocation: normalizedQuotation.clientLocation,
          unitNumber: normalizedQuotation.unitNumber,
          clientSelfie: '', // No selfie from quotation sync flow
          totalContractAmount: normalizedQuotation.totalAmount,
          advanceReceived: normalizedQuotation.paidAmount,
          totalLaborCost: totalLaborCost,
          latitude: normalizedQuotation.latitude,
          longitude: normalizedQuotation.longitude,
          createdAt: DateTime.now(),
        );
        await ClientService.instance.addClient(client).timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            debugPrint('Firestore addClient timed out.');
          },
        );
        debugPrint('Quotation client synced to clients collection successfully.');
        SyncStatusService.setSynced(true);
      } catch (clientErr) {
        debugPrint('Error syncing client details for quotation: $clientErr');
      }
      SyncStatusService.setSynced(true);
    } catch (e) {
      debugPrint('Firebase Sync Error: $e');
      SyncStatusService.setSynced(false);
      rethrow;
    }
  }

  // Fetch registration details directly from Firebase Firestore registrations collection
  Future<CustomerRegistration?> getRegistrationFromCloud(String projectId) async {
    if (projectId.trim().isEmpty) return null;
    try {
      final cleanUnit = ClientService.normalizeUnitNumber(projectId);
      final rawUnit = projectId.replaceAll('#', '').trim();
      final rawDigits = projectId.replaceAll(RegExp(r'\D'), '');

      final Set<String> targetIds = {
        cleanUnit,
        projectId,
        rawUnit,
        if (rawDigits.isNotEmpty) rawDigits,
        if (rawDigits.isNotEmpty) 'PCM-$rawDigits',
        if (rawDigits.isNotEmpty) '# PCM-$rawDigits',
      };

      // 1. Direct doc ID lookup
      for (final id in targetIds) {
        if (id.isEmpty) continue;
        final doc = await _firestore.collection('registrations').doc(id).get();
        if (doc.exists && doc.data() != null) {
          return CustomerRegistration.fromMap(doc.data()!);
        }
        final regDoc = await _firestore.collection('registrations').doc('reg_$id').get();
        if (regDoc.exists && regDoc.data() != null) {
          return CustomerRegistration.fromMap(regDoc.data()!);
        }
      }

      // 2. Query registrations collection by fields
      final snap = await _firestore.collection('registrations').get();
      for (final doc in snap.docs) {
        final data = doc.data();
        final docProj = (data['projectId'] ?? data['rawProjectId'] ?? data['unitNumber'] ?? data['siteId'] ?? data['unit_number'])?.toString() ?? '';
        if (docProj.isNotEmpty) {
          final norm = ClientService.normalizeUnitNumber(docProj);
          final normRaw = docProj.replaceAll('#', '').trim();
          if (targetIds.contains(docProj) || targetIds.contains(norm) || targetIds.contains(normRaw)) {
            return CustomerRegistration.fromMap(data);
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching registration from cloud: $e');
    }
    return null;
  }

  // Get full Quotation from Firebase Firestore or synthesize from live Vercel registration
  Future<Quotation?> getQuotationFromCloud(String projectId) async {
    if (projectId.trim().isEmpty) {
      debugPrint('Skipping cloud fetch: Project ID is empty.');
      return null;
    }

    try {
      if (!kIsWeb) {
        await _firestore.enableNetwork().catchError((_) {});
      }
      final cleanUnit = ClientService.normalizeUnitNumber(projectId);
      final rawUnit = projectId.replaceAll('#', '').trim();
      final rawDigits = projectId.replaceAll(RegExp(r'\D'), '');

      final Set<String> targetIds = {
        cleanUnit,
        projectId,
        rawUnit,
        if (rawDigits.isNotEmpty) rawDigits,
        if (rawDigits.isNotEmpty) 'PCM-$rawDigits',
        if (rawDigits.isNotEmpty) '# PCM-$rawDigits',
      };

      for (final id in targetIds) {
        if (id.trim().isEmpty) continue;
        final doc = await _firestore.collection('quotations').doc(id).get();
        if (doc.exists && doc.data() != null) {
          debugPrint('Quotation loaded from Firebase successfully for $id.');
          return Quotation.fromCloudMap(doc.data()!);
        }
      }

      // Query by unitNumber or unit_number field in quotations
      for (final id in targetIds) {
        if (id.trim().isEmpty) continue;
        final snap1 = await _firestore.collection('quotations').where('unitNumber', isEqualTo: id).limit(1).get();
        if (snap1.docs.isNotEmpty) {
          return Quotation.fromCloudMap(snap1.docs.first.data());
        }
        final snap2 = await _firestore.collection('quotations').where('unit_number', isEqualTo: id).limit(1).get();
        if (snap2.docs.isNotEmpty) {
          return Quotation.fromCloudMap(snap2.docs.first.data());
        }
      }

      // If no quotation doc exists yet, check registrations collection for live Vercel portal registration
      final reg = await getRegistrationFromCloud(projectId);
      if (reg != null) {
        final liveUnit = (reg.projectId != null && reg.projectId!.isNotEmpty)
            ? ClientService.normalizeUnitNumber(reg.projectId!)
            : cleanUnit;
        final liveName = reg.name.trim().isNotEmpty ? reg.name.trim() : 'PCM CLIENT';

        debugPrint('Quotation synthesized from live Vercel portal registration for $liveUnit ($liveName)');
        return Quotation(
          unitNumber: liveUnit,
          clientName: liveName,
          clientPhone: reg.phone,
          clientLocation: reg.location,
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
      }

      // Also check clients collection
      for (final id in targetIds) {
        if (id.trim().isEmpty) continue;
        final cDoc = await _firestore.collection('clients').doc(id).get();
        if (cDoc.exists && cDoc.data() != null) {
          final cData = cDoc.data()!;
          final cName = (cData['clientName'] ?? cData['client_name'] ?? cData['name'])?.toString() ?? 'PCM CLIENT';
          final cPhone = (cData['phoneNumber'] ?? cData['phone_number'] ?? cData['phone'])?.toString() ?? '';
          final cLoc = (cData['siteLocation'] ?? cData['site_location'] ?? cData['location'])?.toString() ?? '';
          return Quotation(
            unitNumber: cleanUnit,
            clientName: cName,
            clientPhone: cPhone,
            clientLocation: cLoc,
            date: DateFormat('dd-MM-yyyy hh:mm a').format(DateTime.now()),
            totalAmount: (cData['totalContractAmount'] ?? cData['total_contract_amount'] ?? 0.0).toDouble(),
            paidAmount: (cData['advanceReceived'] ?? cData['advance_received'] ?? 0.0).toDouble(),
            balanceAmount: 0.0,
            items: const [],
            materials: const [],
            rentals: const [],
            payments: const [],
            projectStatus: 'Registered',
          );
        }
      }

      return null;
    } catch (e) {
      if (e.toString().contains('offline') || e.toString().contains('unavailable')) {
        debugPrint('Firebase Sync: Device is currently offline. Proceeding with local data.');
      } else {
        debugPrint('Firebase Fetch Error: $e');
      }
      return null;
    }
  }

  // Save customer registration to registrations, clients, and projects collections synchronously
  Future<void> saveRegistration(CustomerRegistration reg) async {
    try {
      final rawProject = reg.projectId ?? '';
      final normalizedUnit = ClientService.normalizeUnitNumber(rawProject);
      final cleanDocId = normalizedUnit.replaceAll('#', '').trim();
      final nowIso = DateTime.now().toIso8601String();

      final regMap = {
        'name': reg.name,
        'phone': reg.phone,
        'location': reg.location,
        'projectId': normalizedUnit,
        'rawProjectId': cleanDocId,
        'timestamp': nowIso,
        if (reg.latitude != null) 'latitude': reg.latitude,
        if (reg.longitude != null) 'longitude': reg.longitude,
      };

      final regDocId = 'reg_$cleanDocId';
      await _firestore.collection('registrations').doc(regDocId).set(regMap, SetOptions(merge: true));

      final client = Client(
        id: cleanDocId,
        clientName: reg.name,
        phoneNumber: reg.phone,
        siteLocation: reg.location,
        unitNumber: normalizedUnit,
        clientSelfie: '',
        totalContractAmount: 0.0,
        advanceReceived: 0.0,
        totalLaborCost: 0.0,
        latitude: reg.latitude,
        longitude: reg.longitude,
        createdAt: DateTime.now(),
      );

      await ClientService.instance.addClient(client);
      debugPrint('Registration saved across registrations, clients, and projects for $cleanDocId');
    } catch (e) {
      debugPrint('Error saving registration: $e');
      rethrow;
    }
  }

  // Stream of registrations filtered by Project ID
  Stream<List<CustomerRegistration>> getRegistrations(String projectId) {
    if (projectId.trim().isEmpty) {
      return Stream.value([]);
    }
    try {
      final cleanUnit = ClientService.normalizeUnitNumber(projectId);
      final rawUnit = projectId.replaceAll('#', '').trim();
      final rawDigits = projectId.replaceAll(RegExp(r'\D'), '');

      final Set<String> targetIds = {
        cleanUnit,
        projectId,
        rawUnit,
        if (rawDigits.isNotEmpty) rawDigits,
        if (rawDigits.isNotEmpty) 'PCM-$rawDigits',
        if (rawDigits.isNotEmpty) '# PCM-$rawDigits',
      };

      return _firestore
          .collection('registrations')
          .snapshots()
          .handleError((error) {
            debugPrint('Registration stream notice (offline/retry): $error');
          })
          .map((snapshot) {
            final matches = <CustomerRegistration>[];
            for (final doc in snapshot.docs) {
              final data = doc.data();
              final docProj = (data['projectId'] ?? data['rawProjectId'] ?? data['unitNumber'] ?? data['siteId'] ?? data['unit_number'])?.toString() ?? '';
              final docId = doc.id;
              final normalizedDocProj = docProj.isNotEmpty ? ClientService.normalizeUnitNumber(docProj) : '';
              final normRaw = docProj.replaceAll('#', '').trim();

              if (targetIds.contains(docProj) ||
                  targetIds.contains(docId) ||
                  targetIds.contains('reg_$docId') ||
                  targetIds.contains(normalizedDocProj) ||
                  targetIds.contains(normRaw)) {
                matches.add(CustomerRegistration.fromMap(data));
              }
            }
            return matches;
          });
    } catch (e) {
      debugPrint('Sync Error: $e');
      return Stream.value([]); // Return empty stream on error
    }
  }

  // General stream for any recent registration (Site ID unknown)
  Stream<List<CustomerRegistration>> getRecentRegistrations() {
    try {
      return _firestore
          .collection('registrations')
          .orderBy('timestamp', descending: true)
          .limit(5)
          .snapshots()
          .handleError((error) {
            debugPrint('Recent registration stream notice (offline/retry): $error');
          })
          .map((snapshot) => snapshot.docs
              .map((doc) => CustomerRegistration.fromMap(doc.data()))
              .toList());
    } catch (e) {
      debugPrint('Sync Error: $e');
      return Stream.value([]);
    }
  }
}
