import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'database_service.dart';
import '../models/quotation.dart';
import '../models/rental_model.dart';

class QuotationDbService {
  static final QuotationDbService instance = QuotationDbService._init();
  QuotationDbService._init();

  Future<Database> get _db => DatabaseService.instance.database;

  Future<int> saveFullQuotation(Quotation q) async {
    final db = await _db;
    return await db.transaction((txn) async {
      // DYNAMIC UPSERT LOGIC: Check if unitNumber already exists to prevent duplication
      final List<Map<String, dynamic>> existing = await txn.query(
        'quotations',
        where: 'unitNumber = ?',
        whereArgs: [q.unitNumber]
      );

      int id;
      if (existing.isNotEmpty) {
        id = existing.first['id'] as int;
        await txn.update('quotations', q.toMap(), where: 'id = ?', whereArgs: [id]);

        // Clear related tables for a clean overwrite (items, materials, rentals, payments)
        await txn.delete('quotation_items', where: 'quotationId = ?', whereArgs: [id]);
        await txn.delete('quotation_materials', where: 'quotationId = ?', whereArgs: [id]);
        await txn.delete('quotation_rentals', where: 'quotationId = ?', whereArgs: [id]);
        await txn.delete('quotation_payments', where: 'quotationId = ?', whereArgs: [id]);
      } else {
        id = await txn.insert('quotations', q.toMap());
      }

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
      return id;
    });
  }

  Future<List<Quotation>> getQuotations({String? query}) async {
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
    final db = await _db;
    return await db.transaction((txn) async {
      await txn.update('quotations', q.toMap(), where: 'id = ?', whereArgs: [q.id]);
      
      // CRITICAL FIX: Delete old items before inserting updated ones to prevent duplication
      await txn.delete('quotation_items', where: 'quotationId = ?', whereArgs: [q.id]);
      for (var item in q.items) {
        await txn.insert('quotation_items', item.toMap(q.id!));
      }
      await txn.delete('quotation_materials', where: 'quotationId = ?', whereArgs: [q.id]);
      for (var mat in q.materials) {
        await txn.insert('quotation_materials', mat.toMap(q.id!));
      }
      await txn.delete('quotation_rentals', where: 'quotationId = ?', whereArgs: [q.id]);
      for (var r in q.rentals) {
        await txn.insert('quotation_rentals', {
          'quotationId': q.id, 'itemName': r.itemName, 'siteName': r.siteName,
          'startDate': r.startDate.toIso8601String(), 'dailyRate': r.dailyRate,
          'quantity': r.quantity, 'status': r.status,
        });
      }
      await txn.delete('quotation_payments', where: 'quotationId = ?', whereArgs: [q.id]);
      for (var p in q.payments) {
        await txn.insert('quotation_payments', p.toMap(q.id!));
      }
      return q.id!;
    });
  }

  Future<int> deleteQuotation(int id) async => (await _db).delete('quotations', where: 'id = ?', whereArgs: [id]);
}
