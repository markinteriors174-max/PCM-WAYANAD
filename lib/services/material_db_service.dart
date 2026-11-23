import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'database_service.dart';
import 'database_schema.dart';
import '../models/quotation.dart';

class MaterialDbService {
  static final MaterialDbService instance = MaterialDbService._init();
  MaterialDbService._init();

  Future<Database> get _db => DatabaseService.instance.database;

  Future<void> addMaterialCategory(String name) async {
    if (kIsWeb) {
      try {
        await FirebaseFirestore.instance.collection('material_categories').doc(name).set({
          'category_name': name,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Firestore addMaterialCategory notice: $e');
      }
      return;
    }
    await (await _db).insert('custom_material_categories', {'name': name}, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> deleteMaterialCategory(String name) async {
    if (kIsWeb) {
      try {
        await FirebaseFirestore.instance.collection('material_categories').doc(name).delete();
      } catch (e) {
        debugPrint('Firestore deleteMaterialCategory notice: $e');
      }
      return;
    }
    await (await _db).delete('custom_material_categories', where: 'name = ?', whereArgs: [name]);
  }

  Future<void> addSubMaterial(String cat, String name, String unit) async {
    if (kIsWeb) {
      try {
        final docId = '${cat}_$name'.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
        await FirebaseFirestore.instance.collection('sub_materials').doc(docId).set({
          'category_name': cat,
          'name': name,
          'unit': unit,
          'material_name_malayalam': DatabaseSchema.getMalayalamTranslation(name),
          'rate': 0.0,
          'sku': '',
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Firestore addSubMaterial notice: $e');
      }
      return;
    }
    await (await _db).insert('custom_sub_materials', {'categoryName': cat, 'name': name, 'unit': unit}, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> deleteSubMaterial(int id) async {
    if (kIsWeb) return;
    await (await _db).delete('custom_sub_materials', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateMaterialCategory(String old, String newName) async {
    if (kIsWeb) {
      try {
        await FirebaseFirestore.instance.collection('material_categories').doc(newName).set({
          'category_name': newName,
        }, SetOptions(merge: true));
        await FirebaseFirestore.instance.collection('material_categories').doc(old).delete();
      } catch (e) {
        debugPrint('Firestore updateMaterialCategory notice: $e');
      }
      return;
    }
    final db = await _db;
    await db.update('custom_material_categories', {'name': newName}, where: 'name = ?', whereArgs: [old]);
    await db.update('custom_sub_materials', {'categoryName': newName}, where: 'categoryName = ?', whereArgs: [old]);
  }

  Future<void> updateSubMaterial(int id, String name, String unit, {String? sku}) async {
    if (kIsWeb) return;
    await (await _db).update('custom_sub_materials', {'name': name, 'unit': unit, 'sku': sku ?? ''}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateSubMaterialRate(int id, double rate) async {
    if (kIsWeb) return;
    await (await _db).update('custom_sub_materials', {'rate': rate}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateSubMaterialMalayalam(int id, String mal) async {
    if (kIsWeb) return;
    await (await _db).update('custom_sub_materials', {'material_name_malayalam': mal}, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertSubMaterialWithRate(String cat, String name, String unit, double rate, String mal, {String? sku}) async {
    if (kIsWeb) {
      try {
        final docId = '${cat}_$name'.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
        await FirebaseFirestore.instance.collection('sub_materials').doc(docId).set({
          'category_name': cat,
          'name': name,
          'unit': unit,
          'material_name_malayalam': mal,
          'rate': rate,
          'sku': sku ?? '',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Firestore insertSubMaterialWithRate notice: $e');
      }
      return 1;
    }
    return await (await _db).insert('custom_sub_materials', {
      'categoryName': cat, 'name': name, 'unit': unit, 'material_name_malayalam': mal, 'rate': rate, 'sku': sku ?? ''
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, List<Map<String, dynamic>>>> getMaterialDictionary() async {
    if (kIsWeb) {
      try {
        final catSnap = await FirebaseFirestore.instance.collection('material_categories').get();
        final subSnap = await FirebaseFirestore.instance.collection('sub_materials').get();

        if (catSnap.docs.isNotEmpty || subSnap.docs.isNotEmpty) {
          final Map<String, List<Map<String, dynamic>>> map = {};
          final Map<String, String> categoryMap = {};

          for (var c in catSnap.docs) {
            final catName = (c.data()['category_name'] ?? c.id).toString();
            categoryMap[c.id] = catName;
            map[catName] = [];
          }

          int autoId = 1;
          for (var s in subSnap.docs) {
            final data = s.data();
            final catName = (data['category_name'] ?? categoryMap[data['category_id']?.toString()] ?? 'General').toString();
            final name = (data['name'] ?? s.id).toString();
            final mal = (data['material_name_malayalam'] ?? name).toString();
            final unit = (data['unit'] ?? 'Nos').toString();
            final rate = (data['rate'] as num?)?.toDouble() ?? 0.0;
            final sku = (data['sku'] ?? '').toString();

            map.putIfAbsent(catName, () => []).add({
              'id': autoId++,
              'name': name,
              'unit': unit,
              'material_name_malayalam': mal,
              'rate': rate,
              'sku': sku,
            });
          }

          if (map.isNotEmpty) {
            return map;
          }
        }
      } catch (e) {
        debugPrint('Firestore getMaterialDictionary notice: $e');
      }

      // Safe fallback for Web:
      return DatabaseSchema.getDefaultMaterialDictionary();
    }

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
    if (kIsWeb) return;
    final db = await _db;
    for (var mat in materials) {
      final match = RegExp(r"^(.*?)\s*\((.*?)\)$").firstMatch(mat.materialName);
      if (match == null) continue;
      await db.update('custom_sub_materials', {'rate': mat.rate}, where: 'categoryName = ? AND name = ?', whereArgs: [match.group(2)!.trim(), match.group(1)!.trim()]);
    }
  }

  Future<void> syncSubMaterialsFromCloud() async {
    if (kIsWeb) return;
    try {
      final catSnap = await FirebaseFirestore.instance.collection('material_categories').get();
      final Map<String, String> categoryMap = {};
      for (var doc in catSnap.docs) {
        final data = doc.data();
        final catName = (data['category_name'] ?? doc.id).toString();
        categoryMap[doc.id] = catName;
        await addMaterialCategory(catName);
      }

      final subSnap = await FirebaseFirestore.instance.collection('sub_materials').get();
      final db = await _db;
      for (var doc in subSnap.docs) {
        final data = doc.data();
        final catName = data['category_name'] ?? categoryMap[data['category_id']?.toString()] ?? 'General';
        final malName = (data['material_name_malayalam'] ?? data['name'] ?? '').toString();
        if (malName.isEmpty) continue;
        final existing = await db.query('custom_sub_materials', where: 'categoryName = ? AND name = ?', whereArgs: [catName, malName]);
        if (existing.isEmpty) {
          await db.insert('custom_sub_materials', {
            'categoryName': catName,
            'name': malName,
            'unit': (data['unit'] ?? 'Nos').toString(),
            'material_name_malayalam': malName,
            'rate': (data['rate'] as num?)?.toDouble() ?? 0.0,
          });
        } else {
          await db.update('custom_sub_materials', {
            'unit': (data['unit'] ?? 'Nos').toString(),
            'material_name_malayalam': malName,
          }, where: 'id = ?', whereArgs: [existing.first['id']]);
        }
      }
    } catch (e) {
      debugPrint('Firestore material sync notice: $e');
    }
  }
}
