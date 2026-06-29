import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'database_service.dart';
import '../models/quotation.dart';
import 'package:http/http.dart' as http;

class MaterialDbService {
  static final MaterialDbService instance = MaterialDbService._init();
  MaterialDbService._init();

  Future<Database> get _db => DatabaseService.instance.database;

  Future<void> addMaterialCategory(String name) async => (await _db).insert('custom_material_categories', {'name': name}, conflictAlgorithm: ConflictAlgorithm.ignore);
  Future<void> deleteMaterialCategory(String name) async => (await _db).delete('custom_material_categories', where: 'name = ?', whereArgs: [name]);
  Future<void> addSubMaterial(String cat, String name, String unit) async => (await _db).insert('custom_sub_materials', {'categoryName': cat, 'name': name, 'unit': unit}, conflictAlgorithm: ConflictAlgorithm.ignore);
  Future<void> deleteSubMaterial(int id) async => (await _db).delete('custom_sub_materials', where: 'id = ?', whereArgs: [id]);

  Future<void> updateMaterialCategory(String old, String newName) async {
    final db = await _db;
    await db.update('custom_material_categories', {'name': newName}, where: 'name = ?', whereArgs: [old]);
    await db.update('custom_sub_materials', {'categoryName': newName}, where: 'categoryName = ?', whereArgs: [old]);
  }

  Future<void> updateSubMaterial(int id, String name, String unit, {String? sku}) async => (await _db).update('custom_sub_materials', {'name': name, 'unit': unit, 'sku': sku ?? ''}, where: 'id = ?', whereArgs: [id]);
  Future<void> updateSubMaterialRate(int id, double rate) async => (await _db).update('custom_sub_materials', {'rate': rate}, where: 'id = ?', whereArgs: [id]);
  Future<void> updateSubMaterialMalayalam(int id, String mal) async => (await _db).update('custom_sub_materials', {'material_name_malayalam': mal}, where: 'id = ?', whereArgs: [id]);

  Future<int> insertSubMaterialWithRate(String cat, String name, String unit, double rate, String mal, {String? sku}) async {
    return await (await _db).insert('custom_sub_materials', {
      'categoryName': cat, 'name': name, 'unit': unit, 'material_name_malayalam': mal, 'rate': rate, 'sku': sku ?? ''
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, List<Map<String, dynamic>>>> getMaterialDictionary() async {
    final db = await _db;
    final cats = await db.query('custom_material_categories');
    final subs = await db.query('custom_sub_materials');
    final Map<String, List<Map<String, dynamic>>> map = { for (var c in cats) c['name'] as String: [] };
    for (var s in subs) {
      map.putIfAbsent(s['categoryName'] as String, () => []).add({
        'id': s['id'], 'name': s['name'], 'unit': s['unit'],
        'material_name_malayalam': s['material_name_malayalam'] ?? s['name'],
        'rate': (s['rate'] as num?)?.toDouble() ?? 0.0,
        'sku': s['sku'] as String? ?? '',
      });
    }
    return map;
  }

  Future<void> restoreMasterRatesFromMaterials(List<MaterialAssignment> materials) async {
    final db = await _db;
    for (var mat in materials) {
      final match = RegExp(r"^(.*?)\s*\((.*?)\)$").firstMatch(mat.materialName);
      if (match == null) continue;
      await db.update('custom_sub_materials', {'rate': mat.rate}, where: 'categoryName = ? AND name = ?', whereArgs: [match.group(2)!.trim(), match.group(1)!.trim()]);
    }
  }

  Future<void> syncSubMaterialsFromSupabase() async {
    if (kIsWeb) return;
    const key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBuenlnbXZlbnNtcnpxcG9id3RrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE5NjIwODcsImV4cCI6MjA5NzUzODA4N30.lqCFxRcTGe4xGZ9gT4vYzurfNY-aLQvCL4tLBv9HF0k2';
    
    try {
      final catUri = Uri.parse('https://pNZYGMVENSMRZQPOBWTK.supabase.co/rest/v1/main_categories?select=id,category_name');
      final catRes = await http.get(catUri, headers: {
        'apikey': key,
        'Authorization': 'Bearer $key',
      });

      Map<int, String> categoryMap = {};
      if (catRes.statusCode == 200) {
        final data = jsonDecode(catRes.body) as List;
        for (var row in data) {
          categoryMap[row['id'] as int] = row['category_name'];
          await addMaterialCategory(row['category_name']);
        }
      }

      final subUri = Uri.parse('https://pNZYGMVENSMRZQPOBWTK.supabase.co/rest/v1/sub_materials?select=id,main_category_id,material_name_malayalam,unit');
      final subRes = await http.get(subUri, headers: {
        'apikey': key,
        'Authorization': 'Bearer $key',
      });

      if (subRes.statusCode == 200) {
        final data = jsonDecode(subRes.body) as List;
        final db = await _db;
        for (var row in data) {
          final catId = row['main_category_id'] as int?;
          if (catId == null || !categoryMap.containsKey(catId)) continue;
          final catName = categoryMap[catId]!;
          final malName = row['material_name_malayalam'] as String? ?? '';
          final existing = await db.query('custom_sub_materials', where: 'categoryName = ? AND name = ?', whereArgs: [catName, malName]);
          if (existing.isEmpty) {
            await db.insert('custom_sub_materials', {'categoryName': catName, 'name': malName, 'unit': row['unit'] ?? 'Nos', 'material_name_malayalam': malName, 'rate': 0.0});
          } else {
            await db.update('custom_sub_materials', {'unit': row['unit'] ?? 'Nos', 'material_name_malayalam': malName}, where: 'id = ?', whereArgs: [existing.first['id']]);
          }
        }
      }
    } catch (e) {
      debugPrint('Sync error: $e');
    }
  }
}
