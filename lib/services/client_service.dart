// ignore_for_file: unused_field, unused_element, deprecated_member_use, use_build_context_synchronously, curly_braces_in_flow_control_structures, unused_local_variable, sort_child_properties_last, avoid_print, non_constant_identifier_names, avoid_web_libraries_in_flutter
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/client_model.dart';

class ClientService {
  static final ClientService instance = ClientService._init();
  ClientService._init();

  FirebaseFirestore get _db => FirebaseFirestore.instance;

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
    if (input.trim().isEmpty) {
      return '';
    }
    var clean = input.trim();
    if (RegExp(r'^\d+$').hasMatch(clean)) {
      return '# PCM-$clean';
    }
    if (clean.toUpperCase().startsWith('PCM-')) {
      return '# ${clean.toUpperCase()}';
    }
    if (clean.toUpperCase().startsWith('# PCM-')) {
      return clean;
    }
    return clean;
  }

  /// Returns true if the given ID is an auto-generated timestamp string
  /// (e.g. '# PCM-20261117-1305', 'PCM-20261117-130545', 'DRAFT-20261117-130545').
  static bool isGeneratedTimestampId(String? id) {
    if (id == null) return true;
    final clean = id.trim();
    if (clean.isEmpty) return true;
    final pattern = RegExp(
      r'^(#\s*)?(PCM|DRAFT|UNIT|SITE|DISPATCH)[-_]\d{8}[-_]\d{4,6}$',
      caseSensitive: false,
    );
    return pattern.hasMatch(clean);
  }

  Future<void> addClient(Client client) async {
    try {
      final normalizedUnit = normalizeUnitNumber(client.unitNumber);
      final docId = normalizedUnit.replaceAll('#', '').trim();
      final normalizedClient = client.copyWith(
        id: docId,
        unitNumber: normalizedUnit,
      );

      final map = normalizedClient.toMap();
      // Synchronize across clients, projects, and quotations collections for live web portal parity
      await _db.collection('clients').doc(docId).set(map, SetOptions(merge: true));
      await _db.collection('projects').doc(docId).set(map, SetOptions(merge: true));
      await _db.collection('quotations').doc(docId).set(map, SetOptions(merge: true));

      if (docId != normalizedUnit) {
        await _db.collection('clients').doc(normalizedUnit).set(map, SetOptions(merge: true)).catchError((_) {});
        await _db.collection('projects').doc(normalizedUnit).set(map, SetOptions(merge: true)).catchError((_) {});
        await _db.collection('quotations').doc(normalizedUnit).set(map, SetOptions(merge: true)).catchError((_) {});
      }
      debugPrint('Client ${normalizedClient.clientName} registered/updated successfully in Firestore.');
    } catch (e) {
      debugPrint('Error adding client: $e');
      rethrow;
    }
  }

  Future<void> updateClient(Client client) async {
    try {
      final normalizedUnit = normalizeUnitNumber(client.unitNumber);
      final docId = normalizedUnit.replaceAll('#', '').trim();
      final normalizedClient = client.copyWith(
        id: docId,
        unitNumber: normalizedUnit,
      );
      final map = normalizedClient.toMap();
      await _db.collection('clients').doc(docId).set(map, SetOptions(merge: true));
      await _db.collection('projects').doc(docId).set(map, SetOptions(merge: true));
      await _db.collection('quotations').doc(docId).set(map, SetOptions(merge: true));
      if (docId != normalizedUnit) {
        await _db.collection('clients').doc(normalizedUnit).set(map, SetOptions(merge: true)).catchError((_) {});
        await _db.collection('projects').doc(normalizedUnit).set(map, SetOptions(merge: true)).catchError((_) {});
        await _db.collection('quotations').doc(normalizedUnit).set(map, SetOptions(merge: true)).catchError((_) {});
      }
      debugPrint('Client ${normalizedClient.clientName} updated successfully in Firestore.');
    } catch (e) {
      debugPrint('Error updating client: $e');
      rethrow;
    }
  }

  Future<void> softDeleteClient(String clientId, {String? unitNumber, Client? client}) async {
    try {
      final String effectiveUnit = unitNumber ?? (client?.unitNumber ?? clientId);
      final String cleanUnit = normalizeUnitNumber(effectiveUnit);

      Map<String, dynamic> payload = client?.toMap() ?? {};
      payload['id'] = cleanUnit;
      payload['unitNumber'] = cleanUnit;
      payload['isDeleted'] = true;
      payload['deletedAt'] = DateTime.now().toIso8601String();

      // Write to 'deleted_projects' collection in Firestore
      await _db.collection('deleted_projects').doc(cleanUnit).set(payload, SetOptions(merge: true));

      // Remove from active collections
      await deleteClient(clientId, unitNumber: unitNumber);
      debugPrint('Client $cleanUnit soft-deleted / moved to trash in Firestore.');
    } catch (e) {
      debugPrint('Error soft-deleting client: $e');
      rethrow;
    }
  }

  Future<void> restoreClient(Client client) async {
    try {
      final cleanUnit = normalizeUnitNumber(client.unitNumber);
      Map<String, dynamic> payload = client.toMap();
      payload['isDeleted'] = false;

      // Restore to active collections
      await _db.collection('clients').doc(cleanUnit).set(payload, SetOptions(merge: true));
      await _db.collection('quotations').doc(cleanUnit).set(payload, SetOptions(merge: true));
      await _db.collection('projects').doc(cleanUnit).set(payload, SetOptions(merge: true));

      // Delete from trash
      await _db.collection('deleted_projects').doc(cleanUnit).delete();
      await _db.collection('deleted_projects').doc(client.id).delete();

      debugPrint('Client $cleanUnit restored from trash successfully.');
    } catch (e) {
      debugPrint('Error restoring client: $e');
      rethrow;
    }
  }

  Future<void> permanentlyDeleteClient(String clientId, {String? unitNumber}) async {
    try {
      final Set<String> targetIds = {
        clientId,
        if (unitNumber != null && unitNumber.isNotEmpty) unitNumber,
        normalizeUnitNumber(clientId),
        if (unitNumber != null && unitNumber.isNotEmpty) normalizeUnitNumber(unitNumber),
        clientId.replaceAll('#', '').trim(),
      };

      for (final id in targetIds) {
        if (id.trim().isEmpty) continue;
        try {
          await _db.collection('deleted_projects').doc(id).delete();
        } catch (_) {}
      }

      await deleteClient(clientId, unitNumber: unitNumber);
      debugPrint('Client $clientId permanently deleted from trash.');
    } catch (e) {
      debugPrint('Error permanently deleting client: $e');
      rethrow;
    }
  }

  Future<void> deleteClient(String clientId, {String? unitNumber}) async {
    try {
      final Set<String> targetIds = {
        clientId,
        if (unitNumber != null && unitNumber.isNotEmpty) unitNumber,
        normalizeUnitNumber(clientId),
        if (unitNumber != null && unitNumber.isNotEmpty) normalizeUnitNumber(unitNumber),
        clientId.replaceAll('#', '').trim(),
        if (unitNumber != null && unitNumber.isNotEmpty) unitNumber.replaceAll('#', '').trim(),
      };

      const collections = [
        'clients',
        'projects',
        'quotations',
        'contracts',
        'registrations',
        'client_profiles',
        'submissions'
      ];

      for (final col in collections) {
        for (final targetId in targetIds) {
          if (targetId.trim().isEmpty) continue;
          try {
            await _db.collection(col).doc(targetId).delete();
            if (col == 'registrations') {
              await _db.collection(col).doc('reg_$targetId').delete();
            }
          } catch (e) {
            debugPrint('Error deleting $targetId from $col: $e');
          }
        }
      }

      // Query and delete any matching documents by unitNumber, unit_number, rawProjectId, or projectId field
      for (final col in collections) {
        for (final targetId in targetIds) {
          if (targetId.trim().isEmpty) continue;
          try {
            final snap1 = await _db.collection(col).where('unitNumber', isEqualTo: targetId).get();
            for (var doc in snap1.docs) {
              await doc.reference.delete();
            }
            final snap2 = await _db.collection(col).where('unit_number', isEqualTo: targetId).get();
            for (var doc in snap2.docs) {
              await doc.reference.delete();
            }
            final snap3 = await _db.collection(col).where('rawProjectId', isEqualTo: targetId).get();
            for (var doc in snap3.docs) {
              await doc.reference.delete();
            }
            final snap4 = await _db.collection(col).where('projectId', isEqualTo: targetId).get();
            for (var doc in snap4.docs) {
              await doc.reference.delete();
            }
          } catch (e) {
            debugPrint('Error querying $col for $targetId: $e');
          }
        }
      }

      debugPrint('Client document $clientId / $unitNumber deleted successfully from all Firestore collections.');
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

  Future<Client?> getClientByUnitNumber(String queryStr) async {
    final raw = queryStr.trim();
    if (raw.isEmpty) return null;

    try {
      final normalized = normalizeUnitNumber(raw);
      
      // 1. Direct doc lookup by normalized ID
      final doc = await _db.collection('clients').doc(normalized).get();
      if (doc.exists && doc.data() != null) {
        return Client.fromMap(doc.data()!, doc.id);
      }

      // 2. Direct doc lookup by raw string
      final docRaw = await _db.collection('clients').doc(raw).get();
      if (docRaw.exists && docRaw.data() != null) {
        return Client.fromMap(docRaw.data()!, docRaw.id);
      }

      // 3. Search collection for matching unitNumber, phone, or name
      final snapshot = await _db.collection('clients').get();
      final cleanQuery = raw.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();

      for (var d in snapshot.docs) {
        final client = Client.fromMap(d.data(), d.id);
        final cleanUnit = client.unitNumber.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
        final cleanPhone = client.phoneNumber.replaceAll(RegExp(r'\D'), '');
        final cleanName = client.clientName.toLowerCase();

        if (cleanUnit.contains(cleanQuery) ||
            cleanQuery.contains(cleanUnit) ||
            (cleanQuery.length >= 4 && cleanPhone.endsWith(cleanQuery)) ||
            cleanName.contains(cleanQuery)) {
          return client;
        }
      }
    } catch (e) {
      debugPrint('Error fetching client by unit number ($queryStr): $e');
    }
    return null;
  }

  Future<double> fetchTotalLaborCost(String siteId) async {
    if (siteId.isEmpty) return 0.0;
    try {
      final snap = await _db.collection('attendance').where('site_id', isEqualTo: siteId).get();
      double total = 0.0;
      for (var doc in snap.docs) {
        final data = doc.data();
        final double wages = (data['wages'] as num?)?.toDouble() ?? 0.0;
        final double workDays = (data['work_days'] as num?)?.toDouble() ?? 0.0;
        if (wages > 0) {
          total += wages;
        } else {
          total += workDays * 900.0; // fallback standard rate
        }
      }
      return total;
    } catch (e) {
      debugPrint('Error fetching labor cost for $siteId: $e');
      return 0.0;
    }
  }

  Future<void> syncClients() async {
    // Firestore handles real-time streams automatically.
    debugPrint('Firestore real-time client sync active.');
  }

  Future<List<Map<String, dynamic>>> fetchChatMessages(String siteId) async {
    try {
      final snap = await _db
          .collection('chat_messages')
          .where('site_id', isEqualTo: siteId)
          .orderBy('created_at', descending: false)
          .get();
      return snap.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
    } catch (e) {
      debugPrint('Error fetching chat messages from Firestore: $e');
      return [];
    }
  }

  Future<bool> sendChatMessage(String siteId, String sender, String message) async {
    try {
      await _db.collection('chat_messages').add({
        'site_id': siteId,
        'sender': sender,
        'message': message,
        'message_type': 'text',
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'status': 'sent',
      });
      return true;
    } catch (e) {
      debugPrint('Error sending chat message: $e');
      return false;
    }
  }

  Future<bool> markMessagesAsRead(String siteId, String receiverRole) async {
    final String senderToUpdate = receiverRole == 'admin' ? 'client' : 'admin';
    try {
      final snap = await _db
          .collection('chat_messages')
          .where('site_id', isEqualTo: siteId)
          .where('sender', isEqualTo: senderToUpdate)
          .where('status', isNotEqualTo: 'read')
          .get();
      for (var doc in snap.docs) {
        await doc.reference.update({'status': 'read'});
      }
      return true;
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
      return false;
    }
  }

  Future<bool> markMessagesAsDelivered(String siteId, String receiverRole) async {
    final String senderToUpdate = receiverRole == 'admin' ? 'client' : 'admin';
    try {
      final snap = await _db
          .collection('chat_messages')
          .where('site_id', isEqualTo: siteId)
          .where('sender', isEqualTo: senderToUpdate)
          .where('status', isEqualTo: 'sent')
          .get();
      for (var doc in snap.docs) {
        await doc.reference.update({'status': 'delivered'});
      }
      return true;
    } catch (e) {
      debugPrint('Error marking messages as delivered: $e');
      return false;
    }
  }

  Future<List<String>> fetchProjectPhotos(String siteId) async {
    try {
      final snap = await _db
          .collection('project_photos')
          .where('siteId', isEqualTo: siteId)
          .get();
      final List<String> photoUrls = [];
      for (var doc in snap.docs) {
        final url = doc.data()['url']?.toString();
        if (url != null && url.isNotEmpty) {
          photoUrls.add(url);
        }
      }
      return photoUrls;
    } catch (e) {
      debugPrint('Error fetching project photos from Firestore: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchAttendanceLogs(String siteId) async {
    try {
      final snap = await _db
          .collection('attendance')
          .where('site_id', isEqualTo: siteId)
          .orderBy('punch_in', descending: true)
          .get();
      return snap.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
    } catch (e) {
      debugPrint('Error fetching attendance logs from Firestore: $e');
      return [];
    }
  }

  Future<void> updateProjectStatus(String siteId, String stage) async {
    try {
      await _db.collection('quotations').doc(siteId).set({'projectStatus': stage}, SetOptions(merge: true));
      await _db.collection('clients').doc(siteId).set({'status': stage}, SetOptions(merge: true));
      debugPrint('Synced project status stage "$stage" to Firestore.');
    } catch (e) {
      debugPrint('Error syncing project status: $e');
    }
  }

  Stream<Client?> getClientStream(String queryStr) {
    final raw = queryStr.trim();
    if (raw.isEmpty) return Stream.value(null);

    final normalized = normalizeUnitNumber(raw);

    return _db.collection('clients').doc(normalized).snapshots().asyncMap((doc) async {
      if (doc.exists && doc.data() != null) {
        return Client.fromMap(doc.data()!, doc.id);
      }

      final docRaw = await _db.collection('clients').doc(raw).get();
      if (docRaw.exists && docRaw.data() != null) {
        return Client.fromMap(docRaw.data()!, docRaw.id);
      }

      return await getClientByUnitNumber(raw);
    });
  }

  Stream<List<String>> streamProjectPhotos(String siteId) {
    if (siteId.isEmpty) return Stream.value([]);
    return _db
        .collection('project_photos')
        .where('siteId', isEqualTo: siteId)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => doc.data()['url']?.toString() ?? '')
            .where((url) => url.isNotEmpty)
            .toList());
  }
}
