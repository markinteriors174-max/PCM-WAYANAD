import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/quotation.dart';
import 'database_schema.dart';
import 'quotation_db_service.dart';
import 'material_db_service.dart';
import 'worker_db_service.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;
  DatabaseService._init();

  Future<Database> get database async {
    if (kIsWeb) {
       throw UnsupportedError('SQLite is not supported on Web. Use Cloud Sync or Mock data.');
    }
    if (_database != null) return _database!;
    _database = await _initDB('quotations.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final db = await openDatabase(
      join(dbPath, filePath),
      version: 31,
      onConfigure: (db) async => await db.execute('PRAGMA foreign_keys = ON'),
      onCreate: DatabaseSchema.createDB,
      onUpgrade: DatabaseSchema.onUpgrade,
    );
    try {
      await db.execute('''
        UPDATE quotations 
        SET unitNumber = '# PCM-' || TRIM(REPLACE(REPLACE(REPLACE(unitNumber, '#', ''), 'UNIT-', ''), 'UNIT', ''))
        WHERE unitNumber LIKE '%UNIT%';
      ''');
      await db.execute('''
        UPDATE quotations 
        SET clientLocation = 'Arichalil Tea Shop, Eranjanikunnu'
        WHERE clientLocation LIKE '%Thrissur%' OR clientLocation LIKE '%തൃശൂർ%';
      ''');
    } catch (_) {}
    return db;
  }

  // --- Quotation Service Delegation ---
  Future<int> saveFullQuotation(Quotation q) => QuotationDbService.instance.saveFullQuotation(q);
  Future<int> insertQuotation(Quotation q) => saveFullQuotation(q);
  Future<List<Quotation>> getQuotations({String? query}) => QuotationDbService.instance.getQuotations(query: query);
  Future<Quotation?> getQuotationByProjectIdOrUnit(String projectIdOrUnit, {String? altUnit, String? clientPhone}) =>
      QuotationDbService.instance.getQuotationByProjectIdOrUnit(projectIdOrUnit, altUnit: altUnit, clientPhone: clientPhone);
  Future<Quotation?> getProjectByBookingId(String bookingId) =>
      QuotationDbService.instance.getQuotationByProjectIdOrUnit(bookingId);
  Future<Quotation?> findActiveProjectForClient({String? phone, String? name, String? excludeUnit}) =>
      QuotationDbService.instance.findActiveProjectForClient(phone: phone, name: name, excludeUnit: excludeUnit);
  Future<List<QuotationItem>> getQuotationItems(
    String projectIdOrUnit, {
    String? altUnit,
    String? clientPhone,
    String? clientName,
    int? quotationId,
  }) => QuotationDbService.instance.getQuotationItems(
    projectIdOrUnit,
    altUnit: altUnit,
    clientPhone: clientPhone,
    clientName: clientName,
    quotationId: quotationId,
  );
  Future<int> updateQuotation(Quotation q) => QuotationDbService.instance.updateQuotation(q);
  Future<int> deleteQuotation(int id) => QuotationDbService.instance.deleteQuotation(id);
  Future close() async {
    if (kIsWeb) return;
    return (await database).close();
  }

  // --- Material Service Delegation ---
  Future<void> addMaterialCategory(String name) => MaterialDbService.instance.addMaterialCategory(name);
  Future<void> deleteMaterialCategory(String name) => MaterialDbService.instance.deleteMaterialCategory(name);
  Future<void> addSubMaterial(String cat, String name, String unit) => MaterialDbService.instance.addSubMaterial(cat, name, unit);
  Future<void> deleteSubMaterial(int id) => MaterialDbService.instance.deleteSubMaterial(id);
  Future<void> updateMaterialCategory(String old, String newName) => MaterialDbService.instance.updateMaterialCategory(old, newName);
  Future<void> updateSubMaterial(int id, String name, String unit, {String? sku}) => MaterialDbService.instance.updateSubMaterial(id, name, unit, sku: sku);
  Future<void> updateSubMaterialRate(int id, double rate) => MaterialDbService.instance.updateSubMaterialRate(id, rate);
  Future<void> updateSubMaterialMalayalam(int id, String mal) => MaterialDbService.instance.updateSubMaterialMalayalam(id, mal);
  Future<Map<String, List<Map<String, dynamic>>>> getMaterialDictionary() => MaterialDbService.instance.getMaterialDictionary();
  Future<void> restoreMasterRatesFromMaterials(List<MaterialAssignment> mats) => MaterialDbService.instance.restoreMasterRatesFromMaterials(mats);
  Future<void> syncSubMaterialsFromCloud() => MaterialDbService.instance.syncSubMaterialsFromCloud();
  Future<int> insertSubMaterialWithRate(String cat, String name, String unit, double rate, String mal, {String? sku}) => MaterialDbService.instance.insertSubMaterialWithRate(cat, name, unit, rate, mal, sku: sku);

  // --- Worker Service Delegation ---
  Future<List<Map<String, dynamic>>> getSQLiteWorkers() => WorkerDbService.instance.getSQLiteWorkers();
  Future<int> insertSQLiteWorker(String name, double wage, double days, double paid) => WorkerDbService.instance.insertSQLiteWorker(name, wage, days, paid);
  Future<int> updateWorkerDays(int id, double days) => WorkerDbService.instance.updateWorkerDays(id, days);
  Future<int> recordWorkerPayment(int id, double amount) => WorkerDbService.instance.recordWorkerPayment(id, amount);
  Future<int> deleteSQLiteWorker(int id) => WorkerDbService.instance.deleteSQLiteWorker(id);

  // --- Session Isolation: Wipe all local DB data ---
  Future<void> wipeAllData() async {
    if (kIsWeb) return;
    final db = await database;
    await db.transaction((txn) async {
      final tables = ['quotations', 'material_categories', 'sub_materials', 'workers', 'material_assignments'];
      for (var table in tables) {
        try {
          await txn.execute('DELETE FROM $table');
        } catch (e) {
          debugPrint('Table $table might not exist: $e');
        }
      }
    });
  }
}
