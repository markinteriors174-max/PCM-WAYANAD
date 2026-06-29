import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:convert';
import '../models/quotation.dart';
import '../models/client_model.dart';
import 'client_service.dart';
import 'package:http/http.dart' as http;

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
  
  static const String _supabaseUrl = 'https://pNZYGMVENSMRZQPOBWTK.supabase.co/rest/v1/quotations';
  static const String _supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBuenlnbXZlbnNtcnpxcG9id3RrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE5NjIwODcsImV4cCI6MjA5NzUzODA4N30.lqCFxRcTGe4xGZ9gT4vYzurfNY-aLQvCL4tLBv9HF0k2';

  FirebaseFirestore get _firestore {
    try {
      Firebase.app(); // Throws if not initialized
      return FirebaseFirestore.instance;
    } catch (_) {
      throw Exception('Firebase not initialized. Cannot access Sync Service.');
    }
  }

  CustomerSyncService._init();

  // Upload bytes to Supabase Storage bucket
  Future<String?> uploadProjectPhoto(Uint8List bytes, String fileName, {String? folder}) async {
    final String supabaseId = 'pNZYGMVENSMRZQPOBWTK';
    final String path = folder != null ? '$folder/$fileName' : fileName;
    final String uploadUrl = 'https://$supabaseId.supabase.co/storage/v1/object/project-photos/$path';

    try {
      final response = await http.post(
        Uri.parse(uploadUrl),
        headers: {
          'apikey': _supabaseKey,
          'Authorization': 'Bearer $_supabaseKey',
          'Content-Type': 'image/jpeg',
        },
        body: bytes,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final publicUrl = 'https://$supabaseId.supabase.co/storage/v1/object/public/project-photos/$path';
        debugPrint('Photo uploaded successfully: $publicUrl');
        return publicUrl;
      } else {
        debugPrint('Photo upload failed with status ${response.statusCode}: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Error uploading photo: $e');
      return null;
    }
  }

  // Save full Quotation to Firestore cloud & Supabase
  Future<void> saveQuotationToCloud(Quotation quotation) async {
    if (quotation.unitNumber.trim().isEmpty) {
      debugPrint('Skipping cloud sync: Unit number/Site ID is empty.');
      return;
    }
    
    final normalizedUnit = ClientService.normalizeUnitNumber(quotation.unitNumber);
    final normalizedQuotation = quotation.copyWith(unitNumber: normalizedUnit);

    // 1. Sync to Firebase
    try {
      final docRef = _firestore.collection('quotations').doc(normalizedQuotation.unitNumber);
      await docRef.set(normalizedQuotation.toCloudMap());
      debugPrint('Quotation synced to Firebase successfully.');

      // Also register/update the client in the Firestore 'clients' collection
      final double totalLaborCost = await ClientService.instance.fetchTotalLaborCost(normalizedQuotation.unitNumber);
      final client = Client(
        id: normalizedQuotation.unitNumber,
        clientName: normalizedQuotation.clientName,
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
      await ClientService.instance.addClient(client);
      debugPrint('Quotation client synced to clients collection successfully.');
    } catch (e) {
      debugPrint('Firebase Sync Error: $e');
      rethrow;
    }

    // 2. Sync to Supabase
    try {
      final response = await http.post(
        Uri.parse(_supabaseUrl),
        headers: {
          'content-type': 'application/json',
          'apikey': _supabaseKey,
          'Authorization': 'Bearer $_supabaseKey',
          'Prefer': 'resolution=merge-duplicates',
        },
        body: jsonEncode(normalizedQuotation.toCloudMap()),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('Quotation synced to Supabase successfully.');
      } else {
        debugPrint('Supabase HTTP Sync Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('Supabase Sync Exception: $e');
    }
  }

  // Get full Quotation from Firestore cloud or Supabase
  Future<Quotation?> getQuotationFromCloud(String projectId) async {
    if (projectId.trim().isEmpty) {
      debugPrint('Skipping cloud fetch: Project ID is empty.');
      return null;
    }

    // 1. Try Supabase
    try {
      final queryUrl = '$_supabaseUrl?unitNumber=eq.$projectId';
      final response = await http.get(
        Uri.parse(queryUrl),
        headers: {
          'apikey': _supabaseKey,
          'Authorization': 'Bearer $_supabaseKey',
        },
      );
      if (response.statusCode == 200) {
        final List<dynamic> dataList = jsonDecode(response.body);
        if (dataList.isNotEmpty) {
          debugPrint('Quotation loaded from Supabase successfully.');
          return Quotation.fromCloudMap(Map<String, dynamic>.from(dataList.first));
        }
      }
    } catch (e) {
      debugPrint('Supabase Fetch Exception: $e');
    }

    // 2. Fallback to Firebase
    try {
      final doc = await _firestore.collection('quotations').doc(projectId).get();
      if (doc.exists && doc.data() != null) {
        debugPrint('Quotation loaded from Firebase successfully.');
        return Quotation.fromCloudMap(doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('Firebase Fetch Error: $e');
      return null;
    }
  }

  // Stream of registrations filtered by Project ID
  Stream<List<CustomerRegistration>> getRegistrations(String projectId) {
    if (projectId.trim().isEmpty) {
      return Stream.value([]);
    }
    try {
      return _firestore
          .collection('registrations')
          .where('projectId', isEqualTo: projectId)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => CustomerRegistration.fromMap(doc.data()))
              .toList());
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
          .map((snapshot) => snapshot.docs
              .map((doc) => CustomerRegistration.fromMap(doc.data()))
              .toList());
    } catch (e) {
      debugPrint('Sync Error: $e');
      return Stream.value([]);
    }
  }
}
