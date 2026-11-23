import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'database_service.dart';
import 'customer_sync_service.dart';
import 'client_service.dart';
import '../models/quotation.dart';
import '../models/rental_model.dart';

class QuotationDbService {
  static final QuotationDbService instance = QuotationDbService._init();
  QuotationDbService._init();

  Future<Database> get _db => DatabaseService.instance.database;

  Future<int> saveFullQuotation(Quotation q) async {
    if (kIsWeb) {
      try {
        await CustomerSyncService.instance.saveQuotationToCloud(q);
      } catch (e) {
        debugPrint('Web saveFullQuotation notice: $e');
      }
      return q.id ?? 1;
    }
    final db = await _db;
    return await db.transaction((txn) async {
      List<Map<String, dynamic>> existing = [];
      if (q.id != null) {
        existing = await txn.query('quotations', where: 'id = ?', whereArgs: [q.id]);
      }
      if (existing.isEmpty && q.unitNumber.isNotEmpty) {
        existing = await txn.query(
          'quotations',
          where: 'unitNumber = ?',
          whereArgs: [q.unitNumber],
        );
      }

      int id;
      if (existing.isNotEmpty) {
        id = existing.first['id'] as int;
        await txn.update('quotations', q.toMap(), where: 'id = ?', whereArgs: [id]);

        final existingItemCount = Sqflite.firstIntValue(await txn.rawQuery(
          'SELECT COUNT(*) FROM quotation_items WHERE quotationId = ?', [id]
        )) ?? 0;

        if (q.items.isNotEmpty || existingItemCount == 0) {
          await txn.delete('quotation_items', where: 'quotationId = ?', whereArgs: [id]);
          for (var item in q.items) {
            await txn.insert('quotation_items', item.toMap(id));
          }
        }
        if (q.materials.isNotEmpty) {
          await txn.delete('quotation_materials', where: 'quotationId = ?', whereArgs: [id]);
          for (var mat in q.materials) {
            await txn.insert('quotation_materials', mat.toMap(id));
          }
        }
        if (q.rentals.isNotEmpty) {
          await txn.delete('quotation_rentals', where: 'quotationId = ?', whereArgs: [id]);
          for (var rental in q.rentals) {
            await txn.insert('quotation_rentals', {
              'quotationId': id, 'itemName': rental.itemName, 'siteName': rental.siteName,
              'startDate': rental.startDate.toIso8601String(), 'dailyRate': rental.dailyRate,
              'quantity': rental.quantity, 'status': rental.status,
            });
          }
        }
        if (q.payments.isNotEmpty) {
          await txn.delete('quotation_payments', where: 'quotationId = ?', whereArgs: [id]);
          for (var payment in q.payments) {
            await txn.insert('quotation_payments', payment.toMap(id));
          }
        }
      } else {
        id = await txn.insert('quotations', q.toMap());
        for (var item in q.items) {
          await txn.insert('quotation_items', item.toMap(id));
        }
        for (var mat in q.materials) {
          await txn.insert('quotation_materials', mat.toMap(id));
        }
        for (var rental in q.rentals) {
          await txn.insert('quotation_rentals', {
            'quotationId': id, 'itemName': rental.itemName, 'siteName': rental.siteName,
            'startDate': rental.startDate.toIso8601String(), 'dailyRate': rental.dailyRate,
            'quantity': rental.quantity, 'status': rental.status,
          });
        }
        for (var payment in q.payments) {
          await txn.insert('quotation_payments', payment.toMap(id));
        }
      }
      return id;
    });
  }

  Future<List<Quotation>> getQuotations({String? query}) async {
    if (kIsWeb) {
      try {
        final snap = await FirebaseFirestore.instance.collection('quotations').get();
        final list = snap.docs.map((doc) => Quotation.fromCloudMap(doc.data())).toList();
        if (query != null && query.isNotEmpty) {
          final qLower = query.toLowerCase();
          return list.where((item) =>
            item.unitNumber.toLowerCase().contains(qLower) ||
            item.clientName.toLowerCase().contains(qLower)
          ).toList();
        }
        return list;
      } catch (e) {
        debugPrint('Web getQuotations notice: $e');
        return [];
      }
    }

    final db = await _db;
    String? where; List<dynamic>? args;
    if (query != null && query.isNotEmpty) {
      where = 'unitNumber LIKE ? OR clientName LIKE ?';
      args = ['%$query%', '%$query%'];
    }
    final result = await db.query('quotations', where: where, whereArgs: args, orderBy: 'date DESC');
    List<Quotation> list = [];
    for (var map in result) {
      final id = map['id'];
      final items = (await db.query('quotation_items', where: 'quotationId = ?', whereArgs: [id])).map((i) => QuotationItem.fromMap(i)).toList();
      final mats = (await db.query('quotation_materials', where: 'quotationId = ?', whereArgs: [id])).map((m) => MaterialAssignment.fromMap(m)).toList();
      List<RentalRecord> rentals = [];
      try {
        final rentalMaps = await db.query('quotation_rentals', where: 'quotationId = ?', whereArgs: [id]);
        rentals = rentalMaps.map((r) => RentalRecord(
          id: r['id'].toString(), 
          itemName: r['itemName'] as String, 
          siteName: r['siteName'] as String,
          siteId: r['quotationId']?.toString(), 
          startDate: DateTime.tryParse(r['startDate'] as String? ?? '') ?? DateTime.now(),
          dailyRate: (r['dailyRate'] as num?)?.toDouble() ?? 0.0, 
          quantity: (r['quantity'] as num?)?.toDouble() ?? 1.0, 
          status: r['status'] as String? ?? 'Out',
        )).toList();
      } catch (e) {
        debugPrint('Error parsing rentals for quotation $id: $e');
      }

      final payments = (await db.query('quotation_payments', where: 'quotationId = ?', whereArgs: [id])).map((p) => PaymentRecord.fromMap(p)).toList();
      list.add(Quotation.fromMap(map, items, materials: mats, rentals: rentals, payments: payments));
    }
    return list;
  }

  Future<int> updateQuotation(Quotation q) async {
    if (kIsWeb) {
      try {
        await CustomerSyncService.instance.saveQuotationToCloud(q);
      } catch (e) {
        debugPrint('Web updateQuotation notice: $e');
      }
      return q.id ?? 1;
    }

    final db = await _db;
    return await db.transaction((txn) async {
      await txn.update('quotations', q.toMap(), where: 'id = ?', whereArgs: [q.id]);
      
      final existingItemCount = Sqflite.firstIntValue(await txn.rawQuery(
        'SELECT COUNT(*) FROM quotation_items WHERE quotationId = ?', [q.id]
      )) ?? 0;

      if (q.items.isNotEmpty || existingItemCount == 0) {
        await txn.delete('quotation_items', where: 'quotationId = ?', whereArgs: [q.id]);
        for (var item in q.items) {
          await txn.insert('quotation_items', item.toMap(q.id!));
        }
      }
      if (q.materials.isNotEmpty) {
        await txn.delete('quotation_materials', where: 'quotationId = ?', whereArgs: [q.id]);
        for (var mat in q.materials) {
          await txn.insert('quotation_materials', mat.toMap(q.id!));
        }
      }
      if (q.rentals.isNotEmpty) {
        await txn.delete('quotation_rentals', where: 'quotationId = ?', whereArgs: [q.id]);
        for (var r in q.rentals) {
          await txn.insert('quotation_rentals', {
            'quotationId': q.id, 'itemName': r.itemName, 'siteName': r.siteName,
            'startDate': r.startDate.toIso8601String(), 'dailyRate': r.dailyRate,
            'quantity': r.quantity, 'status': r.status,
          });
        }
      }
      if (q.payments.isNotEmpty) {
        await txn.delete('quotation_payments', where: 'quotationId = ?', whereArgs: [q.id]);
        for (var p in q.payments) {
          await txn.insert('quotation_payments', p.toMap(q.id!));
        }
      }
      return q.id!;
    });
  }

  /// Fetches a quotation and all its saved room measurement items/entries by projectId or unitNumber.
  /// Prioritizes quotations that have items populated so that measurement cards and total SQFT render correctly.
  Future<Quotation?> getQuotationByProjectIdOrUnit(
    String projectIdOrUnit, {
    String? altUnit,
    String? clientPhone,
  }) async {
    final cleanQuery = projectIdOrUnit.trim();
    if (cleanQuery.isEmpty) return null;

    final normQuery = ClientService.normalizeUnitNumber(cleanQuery);
    final rawCleanQuery = cleanQuery.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
    final digitsQuery = cleanQuery.replaceAll(RegExp(r'\D'), '');
    final intId = int.tryParse(cleanQuery);

    final cleanAlt = altUnit != null ? altUnit.trim() : '';
    final normAlt = cleanAlt.isNotEmpty ? ClientService.normalizeUnitNumber(cleanAlt) : '';
    final rawCleanAlt = cleanAlt.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
    final digitsAlt = cleanAlt.replaceAll(RegExp(r'\D'), '');

    final cleanPhone = clientPhone?.replaceAll(RegExp(r'\D'), '') ?? '';

    // 1. Fetch all local quotations
    final all = await getQuotations();

    bool matches(Quotation q) {
      if (intId != null && q.id == intId) return true;
      final qUnit = q.unitNumber.trim();
      if (qUnit.isEmpty) return false;

      final normQ = ClientService.normalizeUnitNumber(qUnit);
      final rawQ = qUnit.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
      final digitsQ = qUnit.replaceAll(RegExp(r'\D'), '');

      // Direct & normalized checks
      if (qUnit == cleanQuery || normQ == normQuery) return true;
      if (cleanAlt.isNotEmpty && (qUnit == cleanAlt || normQ == normAlt)) return true;

      // Alphanumeric checks (e.g. PCM-101 vs # PCM-101 vs pcm101)
      if (rawCleanQuery.isNotEmpty && rawQ.isNotEmpty && (rawQ == rawCleanQuery || rawQ.contains(rawCleanQuery) || rawCleanQuery.contains(rawQ))) return true;
      if (rawCleanAlt.isNotEmpty && rawQ.isNotEmpty && (rawQ == rawCleanAlt || rawQ.contains(rawCleanAlt) || rawCleanAlt.contains(rawQ))) return true;

      // Digits check (e.g. 101 matching PCM-101 or 20260608-2203)
      if (digitsQuery.isNotEmpty && digitsQuery.length >= 3 && digitsQ == digitsQuery) return true;
      if (digitsAlt.isNotEmpty && digitsAlt.length >= 3 && digitsQ == digitsAlt) return true;

      // Phone check
      if (cleanPhone.isNotEmpty && cleanPhone.length >= 6) {
        final qPhone = q.clientPhone.replaceAll(RegExp(r'\D'), '');
        if (qPhone.isNotEmpty && (qPhone.contains(cleanPhone) || cleanPhone.contains(qPhone))) return true;
      }

      return false;
    }

    final matched = all.where(matches).toList();

    // 2. Check if any matched quotation has items
    Quotation? bestMatch;
    for (var q in matched) {
      if (q.items.isNotEmpty) {
        if (bestMatch == null || q.items.length > bestMatch.items.length) {
          bestMatch = q;
        }
      }
    }
    if (bestMatch != null) {
      return bestMatch;
    }

    // 3. Direct SQLite query on quotation_items table
    if (!kIsWeb) {
      try {
        final db = await _db;
        final Set<int> candidateQuotationIds = {};
        if (intId != null) candidateQuotationIds.add(intId);
        for (var q in matched) {
          if (q.id != null) candidateQuotationIds.add(q.id!);
        }

        // Broad search in quotations table to identify any matching IDs
        final rawCleanPatterns = [
          cleanQuery,
          normQuery,
          cleanQuery.replaceAll('#', '').trim(),
          if (cleanAlt.isNotEmpty) cleanAlt,
          if (normAlt.isNotEmpty) normAlt,
          if (cleanAlt.isNotEmpty) cleanAlt.replaceAll('#', '').trim(),
        ].where((s) => s.isNotEmpty).toSet();

        for (var pat in rawCleanPatterns) {
          final dbRows = await db.query(
            'quotations',
            columns: ['id'],
            where: 'unitNumber = ? OR unitNumber LIKE ?',
            whereArgs: [pat, '%$pat%'],
          );
          for (var r in dbRows) {
            final id = r['id'] as int?;
            if (id != null) candidateQuotationIds.add(id);
          }
        }

        if (candidateQuotationIds.isNotEmpty) {
          final placeholders = List.filled(candidateQuotationIds.length, '?').join(',');
          final itemMaps = await db.query(
            'quotation_items',
            where: 'quotationId IN ($placeholders)',
            whereArgs: candidateQuotationIds.toList(),
            orderBy: 'id ASC',
          );
          if (itemMaps.isNotEmpty) {
            final items = itemMaps.map((m) => QuotationItem.fromMap(m)).toList();
            if (matched.isNotEmpty) {
              return matched.first.copyWith(items: items);
            } else {
              final qId = candidateQuotationIds.first;
              final qRows = await db.query('quotations', where: 'id = ?', whereArgs: [qId]);
              if (qRows.isNotEmpty) {
                return Quotation.fromMap(qRows.first, items);
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Direct quotation_items query notice: $e');
      }
    }

    // 4. Query Cloud Firestore if items still empty
    try {
      final cloudTargets = [
        normQuery,
        cleanQuery,
        if (cleanAlt.isNotEmpty) normAlt,
        if (cleanAlt.isNotEmpty) cleanAlt,
        if (digitsQuery.isNotEmpty) digitsQuery,
      ].where((s) => s.isNotEmpty).toSet();

      for (var target in cloudTargets) {
        final cloudQ = await CustomerSyncService.instance.getQuotationFromCloud(target);
        if (cloudQ != null && cloudQ.items.isNotEmpty) {
          final newId = await saveFullQuotation(cloudQ);
          return cloudQ.copyWith(id: newId);
        }
      }
    } catch (e) {
      debugPrint('Cloud quotation query notice: $e');
    }

    // 5. Fallback: if matched has at least one quotation (even if items empty), return it
    if (matched.isNotEmpty) {
      return matched.first;
    }

    return null;
  }

  /// Fetches saved room measurement items/entries for a project or quotation.
  /// Queries SQLite quotation_items by quotationId and matching unit numbers / phone numbers / names,
  /// with Cloud Firestore fallback to guarantee room measurements are never left empty.
  Future<List<QuotationItem>> getQuotationItems(
    String projectIdOrUnit, {
    String? altUnit,
    String? clientPhone,
    String? clientName,
    int? quotationId,
  }) async {
    final cleanQuery = projectIdOrUnit.trim();
    final intId = quotationId ?? int.tryParse(cleanQuery);

    // 1. Direct SQLite query on quotation_items table if quotationId is available
    if (!kIsWeb && intId != null && intId > 0) {
      try {
        final db = await _db;
        final itemMaps = await db.query(
          'quotation_items',
          where: 'quotationId = ?',
          whereArgs: [intId],
          orderBy: 'id ASC',
        );
        if (itemMaps.isNotEmpty) {
          return itemMaps.map((m) => QuotationItem.fromMap(m)).toList();
        }
      } catch (e) {
        debugPrint('Direct quotation_items query by quotationId error: $e');
      }
    }

    // 2. Query quotation by projectIdOrUnit
    final q = await getQuotationByProjectIdOrUnit(
      cleanQuery,
      altUnit: altUnit,
      clientPhone: clientPhone,
    );
    if (q != null && q.items.isNotEmpty) {
      return q.items;
    }

    // 3. Search across all matching quotation IDs in SQLite
    if (!kIsWeb) {
      try {
        final db = await _db;
        final Set<int> candidateQuotationIds = {};
        if (intId != null && intId > 0) candidateQuotationIds.add(intId);
        if (q?.id != null) candidateQuotationIds.add(q!.id!);

        final normQuery = ClientService.normalizeUnitNumber(cleanQuery);
        final digitsQuery = cleanQuery.replaceAll(RegExp(r'\D'), '');
        final cleanAlt = altUnit != null ? altUnit.trim() : '';
        final normAlt = cleanAlt.isNotEmpty ? ClientService.normalizeUnitNumber(cleanAlt) : '';
        final phoneDigits = clientPhone?.replaceAll(RegExp(r'\D'), '') ?? '';
        final rawName = clientName?.trim().toLowerCase() ?? '';

        final rawPatterns = [
          if (cleanQuery.isNotEmpty) cleanQuery,
          if (normQuery.isNotEmpty) normQuery,
          if (cleanQuery.isNotEmpty) cleanQuery.replaceAll('#', '').trim(),
          if (cleanAlt.isNotEmpty) cleanAlt,
          if (normAlt.isNotEmpty) normAlt,
          if (cleanAlt.isNotEmpty) cleanAlt.replaceAll('#', '').trim(),
          if (digitsQuery.isNotEmpty && digitsQuery.length >= 3) digitsQuery,
        ].where((s) => s.isNotEmpty).toSet();

        for (var pat in rawPatterns) {
          final dbRows = await db.query(
            'quotations',
            columns: ['id'],
            where: 'unitNumber = ? OR unitNumber LIKE ?',
            whereArgs: [pat, '%$pat%'],
          );
          for (var r in dbRows) {
            final id = r['id'] as int?;
            if (id != null) candidateQuotationIds.add(id);
          }
        }

        if (phoneDigits.length >= 5) {
          final dbRows = await db.query(
            'quotations',
            columns: ['id', 'clientPhone'],
          );
          for (var r in dbRows) {
            final p = (r['clientPhone'] as String?)?.replaceAll(RegExp(r'\D'), '') ?? '';
            if (p.isNotEmpty && (p.endsWith(phoneDigits) || phoneDigits.endsWith(p) || p.contains(phoneDigits))) {
              final id = r['id'] as int?;
              if (id != null) candidateQuotationIds.add(id);
            }
          }
        }

        if (rawName.length >= 3 && rawName != 'site draft' && rawName != 'draft') {
          final dbRows = await db.query(
            'quotations',
            columns: ['id'],
            where: 'LOWER(clientName) = ? OR LOWER(clientName) LIKE ?',
            whereArgs: [rawName, '%$rawName%'],
          );
          for (var r in dbRows) {
            final id = r['id'] as int?;
            if (id != null) candidateQuotationIds.add(id);
          }
        }

        if (candidateQuotationIds.isNotEmpty) {
          final placeholders = List.filled(candidateQuotationIds.length, '?').join(',');
          final itemMaps = await db.query(
            'quotation_items',
            where: 'quotationId IN ($placeholders)',
            whereArgs: candidateQuotationIds.toList(),
            orderBy: 'id ASC',
          );
          if (itemMaps.isNotEmpty) {
            return itemMaps.map((m) => QuotationItem.fromMap(m)).toList();
          }
        }
      } catch (e) {
        debugPrint('Direct SQLite search in getQuotationItems error: $e');
      }
    }

    // 4. Cloud Firestore fallback
    try {
      final cloudTargets = [
        if (cleanQuery.isNotEmpty) cleanQuery,
        if (cleanQuery.isNotEmpty) ClientService.normalizeUnitNumber(cleanQuery),
        if (cleanQuery.isNotEmpty) cleanQuery.replaceAll('#', '').trim(),
        if (altUnit != null && altUnit.isNotEmpty) altUnit,
        if (clientPhone != null && clientPhone.isNotEmpty) clientPhone,
      ].where((s) => s.isNotEmpty).toSet();

      for (var target in cloudTargets) {
        final cloudQ = await CustomerSyncService.instance.getQuotationFromCloud(target);
        if (cloudQ != null && cloudQ.items.isNotEmpty) {
          return cloudQ.items;
        }
      }
    } catch (e) {
      debugPrint('Cloud fallback in getQuotationItems error: $e');
    }

    return const [];
  }

  Future<int> deleteQuotation(int id, {String? unitNumber}) async {
    String? targetUnit = unitNumber;
    if (!kIsWeb) {
      final db = await _db;
      if (targetUnit == null || targetUnit.isEmpty) {
        final maps = await db.query('quotations', columns: ['unitNumber'], where: 'id = ?', whereArgs: [id]);
        if (maps.isNotEmpty) {
          targetUnit = maps.first['unitNumber'] as String?;
        }
      }
      await db.delete('quotations', where: 'id = ?', whereArgs: [id]);
    }
    if (targetUnit != null && targetUnit.isNotEmpty) {
      try {
        await ClientService.instance.softDeleteClient(targetUnit, unitNumber: targetUnit);
      } catch (e) {
        debugPrint('Error soft-deleting from cloud in deleteQuotation: $e');
      }
    }
    return 1;
  }

  /// Checks if an active project or quotation already exists for the given phone number or client name in the database.
  /// Prioritizes existing quotations that have items populated or established Project IDs,
  /// ensuring consistency for the same client without generating duplicate timestamp IDs.
  Future<Quotation?> findActiveProjectForClient({
    String? phone,
    String? name,
    String? excludeUnit,
  }) async {
    final cleanPhone = phone?.replaceAll(RegExp(r'\D'), '').trim() ?? '';
    final matchPhone = cleanPhone.length > 10 ? cleanPhone.substring(cleanPhone.length - 10) : cleanPhone;

    final rawName = name?.trim().toLowerCase() ?? '';
    final isValidName = rawName.isNotEmpty &&
        rawName != 'site draft' &&
        rawName != 'draft' &&
        rawName != 'unknown' &&
        rawName != 'customer' &&
        rawName != 'client' &&
        rawName.length >= 3;

    if (matchPhone.length < 5 && !isValidName) {
      return null;
    }

    // 1. Check local quotations
    final all = await getQuotations();
    final List<Quotation> candidates = [];

    for (var q in all) {
      if (excludeUnit != null && q.unitNumber.trim() == excludeUnit.trim()) continue;

      bool matches = false;
      if (matchPhone.length >= 5) {
        final qPhone = q.clientPhone.replaceAll(RegExp(r'\D'), '');
        if (qPhone.isNotEmpty &&
            (qPhone.endsWith(matchPhone) || matchPhone.endsWith(qPhone) || qPhone.contains(matchPhone))) {
          matches = true;
        }
      }

      if (!matches && isValidName) {
        final qName = q.clientName.trim().toLowerCase();
        if (qName == rawName ||
            (qName.length >= 4 && (qName.contains(rawName) || rawName.contains(qName)))) {
          matches = true;
        }
      }

      if (matches) {
        candidates.add(q);
      }
    }

    if (candidates.isNotEmpty) {
      // Priority 1: Candidate with items populated
      final withItems = candidates.where((q) => q.items.isNotEmpty).toList();
      if (withItems.isNotEmpty) {
        withItems.sort((a, b) {
          final countCmp = b.items.length.compareTo(a.items.length);
          if (countCmp != 0) return countCmp;
          return (b.id ?? 0).compareTo(a.id ?? 0);
        });
        return withItems.first;
      }

      // Priority 2: Candidate with established (non-timestamp) project ID
      final established = candidates.where((q) => !ClientService.isGeneratedTimestampId(q.unitNumber)).toList();
      if (established.isNotEmpty) {
        established.sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
        return established.first;
      }

      // Priority 3: Most recent candidate
      candidates.sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
      return candidates.first;
    }

    // 2. Check ClientService (Cloud Firestore clients)
    try {
      final clientQuery = matchPhone.length >= 5 ? matchPhone : rawName;
      final client = await ClientService.instance.getClientByUnitNumber(clientQuery);
      if (client != null && client.unitNumber.isNotEmpty) {
        final q = await getQuotationByProjectIdOrUnit(client.unitNumber, clientPhone: client.phoneNumber);
        if (q != null) return q;

        return Quotation(
          unitNumber: client.unitNumber,
          clientName: client.clientName,
          clientPhone: client.phoneNumber,
          clientLocation: client.siteLocation,
          locationFolder: client.siteLocation,
          date: DateFormat('dd-MM-yyyy hh:mm a').format(client.createdAt),
          totalAmount: client.totalContractAmount,
          paidAmount: client.advanceReceived,
          balanceAmount: client.balanceDue,
          manualAmount: client.totalContractAmount,
          items: const [],
        );
      }
    } catch (e) {
      debugPrint('ClientService lookup notice in findActiveProjectForClient: $e');
    }

    // 3. Check CustomerSyncService (Cloud Firestore quotations)
    try {
      final cloudTargets = [
        if (matchPhone.length >= 5) matchPhone,
        if (isValidName) rawName,
      ];
      for (var target in cloudTargets) {
        final cloudQ = await CustomerSyncService.instance.getQuotationFromCloud(target);
        if (cloudQ != null) {
          final newId = await saveFullQuotation(cloudQ);
          return cloudQ.copyWith(id: newId);
        }
      }
    } catch (e) {
      debugPrint('Cloud sync notice in findActiveProjectForClient: $e');
    }

    return null;
  }
}
