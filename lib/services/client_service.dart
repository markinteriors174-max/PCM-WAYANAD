// ignore_for_file: unused_field, unused_element, deprecated_member_use, use_build_context_synchronously, curly_braces_in_flow_control_structures, unused_local_variable, sort_child_properties_last, avoid_print, non_constant_identifier_names, avoid_web_libraries_in_flutter
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/client_model.dart';
import 'package:http/http.dart' as http;

class ClientService {
  static final ClientService instance = ClientService._init();
  ClientService._init();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Client>> getClients() {
    return _db
        .collection('clients')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Client.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getClientsPage({
    int limit = 20,
    DocumentSnapshot? startAfter,
    String? searchQuery,
  }) async {
    Query<Map<String, dynamic>> query = _db.collection('clients');

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final searchUpper = searchQuery.toUpperCase();
      query = query
          .orderBy('client_name')
          .startAt([searchUpper])
          .endAt(['$searchUpper\uf8ff']);
    } else {
      query = query.orderBy('createdAt', descending: true);
    }

    query = query.limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    return await query.get();
  }

  static String normalizeUnitNumber(String input) {
    final trimmed = input.trim().toLowerCase();
    if (trimmed.startsWith('pcm-ms-')) {
      return trimmed;
    }
    final cleanCode = trimmed
        .replaceAll('pcm-ms-', '')
        .replaceAll('unit-', '')
        .replaceAll('unit', '')
        .replaceAll('-', '')
        .trim();
    return 'pcm-ms-$cleanCode';
  }

  Future<void> addClient(Client client, {bool syncToSupabase = true}) async {
    try {
      final normalizedUnit = normalizeUnitNumber(client.unitNumber);
      final normalizedClient = client.copyWith(
        id: normalizedUnit,
        unitNumber: normalizedUnit,
      );

      // Use unitNumber as the document ID for simple 1-to-1 project mapping
      await _db.collection('clients').doc(normalizedClient.unitNumber).set(normalizedClient.toMap());
      debugPrint('Client ${normalizedClient.clientName} registered/updated successfully in Firestore.');
      
      if (syncToSupabase) {
        const String supabaseUrl = 'https://pNZYGMVENSMRZQPOBWTK.supabase.co/rest/v1/clients';
        const String supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBuenlnbXZlbnNtcnpxcG9id3RrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE5NjIwODcsImV4cCI6MjA5NzUzODA4N30.lqCFxRcTGe4xGZ9gT4vYzurfNY-aLQvCL4tLBv9HF0k2';
        
        final response = await http.post(
          Uri.parse(supabaseUrl),
          headers: {
            'apikey': supabaseKey,
            'Authorization': 'Bearer $supabaseKey',
            'Content-Type': 'application/json',
            'Prefer': 'resolution=merge-duplicates',
          },
          body: jsonEncode({
            'client_name': normalizedClient.clientName,
            'phone_number': normalizedClient.phoneNumber,
            'site_location': normalizedClient.siteLocation,
            'unitNumber': normalizedClient.unitNumber,
            'total_contract_amount': normalizedClient.totalContractAmount,
            'client_selfie': normalizedClient.clientSelfie,
            'status': normalizedClient.status,
            'assigned_workers': normalizedClient.assignedWorkers,
          }),
        );
        
        debugPrint('Synced manually created client back to Supabase. Status: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error adding client: $e');
      rethrow;
    }
  }

  Future<void> updateClient(Client client, {bool syncToSupabase = true}) async {
    try {
      final normalizedUnit = normalizeUnitNumber(client.unitNumber);
      final normalizedClient = client.copyWith(
        id: normalizedUnit,
        unitNumber: normalizedUnit,
      );
      await _db.collection('clients').doc(normalizedClient.id).set(normalizedClient.toMap(), SetOptions(merge: true));
      debugPrint('Client ${normalizedClient.clientName} updated successfully in Firestore.');

      if (syncToSupabase) {
        const String supabaseUrl = 'https://pNZYGMVENSMRZQPOBWTK.supabase.co/rest/v1/clients';
        const String supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBuenlnbXZlbnNtcnpxcG9id3RrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE5NjIwODcsImV4cCI6MjA5NzUzODA4N30.lqCFxRcTGe4xGZ9gT4vYzurfNY-aLQvCL4tLBv9HF0k2';
        
        final response = await http.patch(
          Uri.parse('$supabaseUrl?unitNumber=eq.${normalizedClient.unitNumber}'),
          headers: {
            'apikey': supabaseKey,
            'Authorization': 'Bearer $supabaseKey',
            'Content-Type': 'application/json',
            'Prefer': 'return=minimal',
          },
          body: jsonEncode({
            'client_name': normalizedClient.clientName,
            'phone_number': normalizedClient.phoneNumber,
            'site_location': normalizedClient.siteLocation,
            'client_selfie': normalizedClient.clientSelfie,
            'total_contract_amount': normalizedClient.totalContractAmount,
            'advance_received': normalizedClient.advanceReceived,
            'status': normalizedClient.status,
            'assigned_workers': normalizedClient.assignedWorkers,
            'latitude': normalizedClient.latitude,
            'longitude': normalizedClient.longitude,
          }),
        );
        
        debugPrint('Synced updated client back to Supabase. Status: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error updating client: $e');
      rethrow;
    }
  }

  Future<void> deleteClient(String clientId) async {
    try {
      await _db.collection('clients').doc(clientId).delete();
      debugPrint('Client document $clientId deleted successfully from Firestore.');
    } catch (e) {
      debugPrint('Error deleting client: $e');
      rethrow;
    }
  }

  Future<Client?> getAssignedClient(String workerName) async {
    try {
      final snapshot = await _db.collection('clients').get();
      for (var doc in snapshot.docs) {
        final assigned = doc.data()['assigned_workers'] as String? ?? '';
        if (assigned.toLowerCase().contains(workerName.toLowerCase())) {
          return Client.fromMap(doc.data(), doc.id);
        }
      }
    } catch (e) {
      debugPrint('Error getting assigned client: $e');
    }
    return null;
  }

  Future<Client?> getAssignedClientByPhone(String phone, String unitNumber) async {
    try {
      final doc = await _db.collection('clients').doc(unitNumber).get();
      if (doc.exists) {
        final client = Client.fromMap(doc.data()!, doc.id);
        final cleanDbPhone = client.phoneNumber.replaceAll(RegExp(r'\D'), '');
        final cleanInputPhone = phone.replaceAll(RegExp(r'\D'), '');
        if (cleanDbPhone == cleanInputPhone || cleanDbPhone.endsWith(cleanInputPhone) || cleanInputPhone.endsWith(cleanDbPhone)) {
          return client;
        }
      }
    } catch (e) {
      debugPrint('Error getting client by phone: $e');
    }
    return null;
  }

  Future<double> fetchTotalLaborCost(String siteId) async {
    if (siteId.isEmpty) return 0.0;
    const String supabaseUrl = 'https://pNZYGMVENSMRZQPOBWTK.supabase.co/rest/v1/attendance';
    const String supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBuenlnbXZlbnNtcnpxcG9id3RrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE5NjIwODcsImV4cCI6MjA5NzUzODA4N30.lqCFxRcTGe4xGZ9gT4vYzurfNY-aLQvCL4tLBv9HF0k2';

    try {
      final response = await http.get(
        Uri.parse('$supabaseUrl?site_id=eq.${Uri.encodeComponent(siteId)}&select=work_days,wages'),
        headers: {
          'apikey': supabaseKey,
          'Authorization': 'Bearer $supabaseKey',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        double total = 0.0;
        for (var item in list) {
          final double wages = (item['wages'] ?? 0.0).toDouble();
          final double workDays = (item['work_days'] ?? 0.0).toDouble();
          if (wages > 0) {
            total += wages;
          } else {
            total += workDays * 900.0; // fallback standard rate of ₹900 per day
          }
        }
        return total;
      }
    } catch (e) {
      debugPrint('Error fetching labor cost for $siteId: $e');
    }
    return 0.0;
  }

  Future<void> syncClientsFromSupabase() async {
    const String supabaseUrl = 'https://pNZYGMVENSMRZQPOBWTK.supabase.co/rest/v1/clients';
    const String supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBuenlnbXZlbnNtcnpxcG9id3RrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE5NjIwODcsImV4cCI6MjA5NzUzODA4N30.lqCFxRcTGe4xGZ9gT4vYzurfNY-aLQvCL4tLBv9HF0k2';

    try {
      final response = await http.get(
        Uri.parse(supabaseUrl),
        headers: {
          'apikey': supabaseKey,
          'Authorization': 'Bearer $supabaseKey',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        
        if (list.isNotEmpty) {
          for (var item in list) {
            final clientMap = Map<String, dynamic>.from(item);
            
            final String name = clientMap['client_name'] ?? clientMap['name'] ?? '';
            final String phone = clientMap['phone_number'] ?? clientMap['phone'] ?? '';
            final String location = clientMap['site_location'] ?? clientMap['location'] ?? '';
            final String unitNumber = clientMap['unitNumber'] ?? '';
            final String selfie = clientMap['client_selfie'] ?? clientMap['selfieUrl'] ?? '';
            final double totalAmount = (clientMap['total_contract_amount'] ?? clientMap['totalAmount'] ?? 0.0).toDouble();
            final double paidAmount = (clientMap['advance_received'] ?? clientMap['paidAmount'] ?? 0.0).toDouble();
            final double? latitude = (clientMap['latitude'] as num?)?.toDouble();
            final double? longitude = (clientMap['longitude'] as num?)?.toDouble();
            final String status = clientMap['status'] ?? 'Pending';
            final String assignedWorkers = clientMap['assigned_workers'] ?? '';
            
            if (unitNumber.isEmpty) continue;

            // Fetch aggregate labor cost for this client
            final double totalLaborCost = await fetchTotalLaborCost(unitNumber);

            final client = Client(
              id: unitNumber,
              clientName: name,
              phoneNumber: phone,
              siteLocation: location,
              unitNumber: unitNumber,
              clientSelfie: selfie,
              totalContractAmount: totalAmount,
              advanceReceived: paidAmount,
              totalLaborCost: totalLaborCost,
              latitude: latitude,
              longitude: longitude,
              status: status,
              assignedWorkers: assignedWorkers,
              createdAt: DateTime.now(),
            );
            
            // Check if the client already exists in local Firestore
            final existingDoc = await _db.collection('clients').doc(unitNumber).get();
            if (existingDoc.exists) {
              // Merge values so we keep details up to date (GPS, Selfie, Contract amount)
              await _db.collection('clients').doc(unitNumber).set(client.toMap(), SetOptions(merge: true));
            } else {
              await addClient(client, syncToSupabase: false);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error syncing clients from Supabase: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchChatMessages(String siteId) async {
    const String supabaseUrl = 'https://pNZYGMVENSMRZQPOBWTK.supabase.co/rest/v1/chat_messages';
    const String supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBuenlnbXZlbnNtcnpxcG9id3RrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE5NjIwODcsImV4cCI6MjA5NzUzODA4N30.lqCFxRcTGe4xGZ9gT4vYzurfNY-aLQvCL4tLBv9HF0k2';

    Future<List<Map<String, dynamic>>> tryFetch(String queryParam) async {
      final url = '$supabaseUrl?$queryParam=eq.$siteId&order=created_at.asc';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'apikey': supabaseKey,
          'Authorization': 'Bearer $supabaseKey',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((item) {
          final Map<String, dynamic> msg = Map<String, dynamic>.from(item);
          if (msg['message'] == null) {
            msg['message'] = msg['text'] ?? msg['message_text'] ?? '';
          }
          return msg;
        }).toList();
      }
      throw Exception('Fetch failed with ${response.statusCode}');
    }

    try {
      // 1. Try standard site_id
      return await tryFetch('site_id');
    } catch (_) {
      try {
        // 2. Fallback to unit_number (common PCM workflow naming)
        return await tryFetch('unit_number');
      } catch (e) {
        debugPrint('Error fetching chat messages: $e');
      }
    }
    return [];
  }

  Future<bool> sendChatMessage(String siteId, String sender, String message) async {
    const String supabaseUrl = 'https://pNZYGMVENSMRZQPOBWTK.supabase.co/rest/v1/chat_messages';
    const String supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBuenlnbXZlbnNtcnpxcG9id3RrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE5NjIwODcsImV4cCI6MjA5NzUzODA4N30.lqCFxRcTGe4xGZ9gT4vYzurfNY-aLQvCL4tLBv9HF0k2';

    try {
      // Robust payload to handle potential schema variations
      final Map<String, dynamic> payload = {
        'site_id': siteId,
        'sender': sender,
        'message': message,
        'message_type': 'text',
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'status': 'sent',
      };

      final response = await http.post(
        Uri.parse(supabaseUrl),
        headers: {
          'apikey': supabaseKey,
          'Authorization': 'Bearer $supabaseKey',
          'Content-Type': 'application/json',
          'Prefer': 'return=minimal',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      } else {
        debugPrint('Supabase Chat Error: ${response.statusCode} - ${response.body}');

        // If it failed with 400, it might be a column mismatch (e.g. status or site_id name)
        if (response.statusCode == 400) {
          debugPrint('Retrying chat insert with legacy/alternate schema...');

          // Try multiple combinations to bypass schema mismatch
          final retryCombinations = [
            // Option 1: Try unit_number instead of site_id
            {'unit_number': siteId, 'sender': sender, 'message': message, 'created_at': DateTime.now().toUtc().toIso8601String()},
            // Option 2: Try message_text instead of message
            {'site_id': siteId, 'sender': sender, 'message_text': message, 'created_at': DateTime.now().toUtc().toIso8601String()},
            // Option 3: Minimal set (no status, no message_type)
            {'site_id': siteId, 'sender': sender, 'message': message, 'created_at': DateTime.now().toUtc().toIso8601String()},
          ];

          for (var retryPayload in retryCombinations) {
            final retryRes = await http.post(
              Uri.parse(supabaseUrl),
              headers: {
                'apikey': supabaseKey,
                'Authorization': 'Bearer $supabaseKey',
                'Content-Type': 'application/json',
              },
              body: jsonEncode(retryPayload),
            );
            if (retryRes.statusCode >= 200 && retryRes.statusCode < 300) {
              debugPrint('Chat retry success with payload keys: ${retryPayload.keys}');
              return true;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error sending chat message: $e');
    }
    return false;
  }

  Future<bool> markMessagesAsRead(String siteId, String receiverRole) async {
    final String senderToUpdate = receiverRole == 'admin' ? 'client' : 'admin';
    const String supabaseUrl = 'https://pNZYGMVENSMRZQPOBWTK.supabase.co/rest/v1/chat_messages';
    const String supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBuenlnbXZlbnNtcnpxcG9id3RrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE5NjIwODcsImV4cCI6MjA5NzUzODA4N30.lqCFxRcTGe4xGZ9gT4vYzurfNY-aLQvCL4tLBv9HF0k2';

    try {
      final url = '$supabaseUrl?site_id=eq.$siteId&sender=eq.$senderToUpdate&status=neq.read';
      final response = await http.patch(
        Uri.parse(url),
        headers: {
          'apikey': supabaseKey,
          'Authorization': 'Bearer $supabaseKey',
          'Content-Type': 'application/json',
          'Prefer': 'return=minimal',
        },
        body: jsonEncode({'status': 'read'}),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      } else {
        debugPrint('Supabase Mark Read Error: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
    return false;
  }

  Future<bool> markMessagesAsDelivered(String siteId, String receiverRole) async {
    final String senderToUpdate = receiverRole == 'admin' ? 'client' : 'admin';
    const String supabaseUrl = 'https://pNZYGMVENSMRZQPOBWTK.supabase.co/rest/v1/chat_messages';
    const String supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBuenlnbXZlbnNtcnpxcG9id3RrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE5NjIwODcsImV4cCI6MjA5NzUzODA4N30.lqCFxRcTGe4xGZ9gT4vYzurfNY-aLQvCL4tLBv9HF0k2';

    try {
      final url = '$supabaseUrl?site_id=eq.$siteId&sender=eq.$senderToUpdate&status=eq.sent';
      final response = await http.patch(
        Uri.parse(url),
        headers: {
          'apikey': supabaseKey,
          'Authorization': 'Bearer $supabaseKey',
          'Content-Type': 'application/json',
          'Prefer': 'return=minimal',
        },
        body: jsonEncode({'status': 'delivered'}),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      } else {
        debugPrint('Supabase Mark Delivered Error: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Error marking messages as delivered: $e');
    }
    return false;
  }

  Future<List<String>> fetchProjectPhotos(String siteId) async {
    const String storageUrl = 'https://pNZYGMVENSMRZQPOBWTK.supabase.co/storage/v1/object/list/project-photos';
    const String supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBuenlnbXZlbnNtcnpxcG9id3RrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE5NjIwODcsImV4cCI6MjA5NzUzODA4N30.lqCFxRcTGe4xGZ9gT4vYzurfNY-aLQvCL4tLBv9HF0k2';

    try {
      // 1. Try listing files inside the folder named after siteId
      var response = await http.post(
        Uri.parse(storageUrl),
        headers: {
          'apikey': supabaseKey,
          'Authorization': 'Bearer $supabaseKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'prefix': siteId,
          'limit': 100,
          'sortBy': {'column': 'name', 'order': 'desc'}
        }),
      );

      if (response.statusCode == 200) {
        final List<dynamic> files = jsonDecode(response.body);
        final List<String> photoUrls = [];
        for (var file in files) {
          final String name = file['name'] ?? '';
          if (name != '.emptyFolderPlaceholder') {
            photoUrls.add('https://pNZYGMVENSMRZQPOBWTK.supabase.co/storage/v1/object/public/project-photos/$siteId/$name');
          }
        }
        
        if (photoUrls.isNotEmpty) {
          return photoUrls;
        }
      }

      // 2. Fallback: list root files and filter by siteId (backward compatibility)
      var fallbackRes = await http.post(
        Uri.parse(storageUrl),
        headers: {
          'apikey': supabaseKey,
          'Authorization': 'Bearer $supabaseKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'prefix': '',
          'limit': 100,
          'sortBy': {'column': 'name', 'order': 'desc'}
        }),
      );

      if (fallbackRes.statusCode == 200) {
        final List<dynamic> files = jsonDecode(fallbackRes.body);
        final lowerId = siteId.toLowerCase();
        final List<String> photoUrls = [];
        for (var file in files) {
          final String name = file['name'] ?? '';
          if (name.toLowerCase().contains(lowerId)) {
            photoUrls.add('https://pNZYGMVENSMRZQPOBWTK.supabase.co/storage/v1/object/public/project-photos/$name');
          }
        }
        return photoUrls;
      }
    } catch (e) {
      debugPrint('Error fetching project photos: $e');
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> fetchAttendanceLogs(String siteId) async {
    const String supabaseUrl = 'https://pNZYGMVENSMRZQPOBWTK.supabase.co/rest/v1/attendance';
    const String supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBuenlnbXZlbnNtcnpxcG9id3RrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE5NjIwODcsImV4cCI6MjA5NzUzODA4N30.lqCFxRcTGe4xGZ9gT4vYzurfNY-aLQvCL4tLBv9HF0k2';

    try {
      final response = await http.get(
        Uri.parse('$supabaseUrl?site_id=eq.$siteId&order=punch_in.desc'),
        headers: {
          'apikey': supabaseKey,
          'Authorization': 'Bearer $supabaseKey',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((item) => Map<String, dynamic>.from(item)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching attendance logs: $e');
    }
    return [];
  }

  Future<void> updateProjectStatus(String siteId, String stage) async {
    try {
      const String supabaseUrl = 'https://pNZYGMVENSMRZQPOBWTK.supabase.co/rest/v1/quotations';
      const String supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBuenlnbXZlbnNtcnpxcG9id3RrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE5NjIwODcsImV4cCI6MjA5NzUzODA4N30.lqCFxRcTGe4xGZ9gT4vYzurfNY-aLQvCL4tLBv9HF0k2';
      
      final response = await http.patch(
        Uri.parse('$supabaseUrl?unitNumber=eq.$siteId'),
        headers: {
          'apikey': supabaseKey,
          'Authorization': 'Bearer $supabaseKey',
          'Content-Type': 'application/json',
          'Prefer': 'return=minimal',
        },
        body: jsonEncode({'projectStatus': stage}),
      );
      
      debugPrint('Synced project status stage "$stage" to Supabase. Status: ${response.statusCode}');
    } catch (e) {
      debugPrint('Error syncing project status: $e');
    }
  }
}
