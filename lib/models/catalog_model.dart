import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CatalogItemModel {
  final String id;
  final String category;
  final String name;
  final String description;
  final String unit;
  final double rate;
  final String? imageUrl;
  final String? sku;
  final bool isAvailable;
  final DateTime createdAt;

  const CatalogItemModel({
    required this.id,
    required this.category,
    required this.name,
    required this.description,
    this.unit = 'Sq.Ft',
    this.rate = 0.0,
    this.imageUrl,
    this.sku,
    this.isAvailable = true,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'name': name,
        'description': description,
        'unit': unit,
        'rate': rate,
        'imageUrl': imageUrl,
        'sku': sku,
        'isAvailable': isAvailable,
        'createdAt': createdAt.toIso8601String(),
      };

  factory CatalogItemModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      final rawDate = json['createdAt'];
      if (rawDate is String) {
        parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
      } else if (rawDate is Timestamp) {
        parsedDate = rawDate.toDate();
      } else {
        parsedDate = DateTime.now();
      }
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return CatalogItemModel(
      id: json['id']?.toString() ?? 'cat_${DateTime.now().millisecondsSinceEpoch}',
      category: json['category']?.toString() ?? 'Gypsum Board',
      name: json['name']?.toString() ?? 'Ceiling Material',
      description: json['description']?.toString() ?? 'Premium ceiling material from PCM Wayanad.',
      unit: json['unit']?.toString() ?? 'Sq.Ft',
      rate: (json['rate'] as num?)?.toDouble() ?? 0.0,
      imageUrl: json['imageUrl']?.toString() ?? json['image_url']?.toString(),
      sku: json['sku']?.toString(),
      isAvailable: json['isAvailable'] as bool? ?? true,
      createdAt: parsedDate,
    );
  }

  CatalogItemModel copyWith({
    String? id,
    String? category,
    String? name,
    String? description,
    String? unit,
    double? rate,
    String? imageUrl,
    String? sku,
    bool? isAvailable,
    DateTime? createdAt,
  }) {
    return CatalogItemModel(
      id: id ?? this.id,
      category: category ?? this.category,
      name: name ?? this.name,
      description: description ?? this.description,
      unit: unit ?? this.unit,
      rate: rate ?? this.rate,
      imageUrl: imageUrl ?? this.imageUrl,
      sku: sku ?? this.sku,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class CatalogService {
  static final CatalogService instance = CatalogService._internal();
  CatalogService._internal();

  static const String _storageKey = 'pcm_unlimited_catalog_items_v2';

  List<CatalogItemModel> _items = [];

  List<CatalogItemModel> get items => _items;
  List<CatalogItemModel> get availableItems => _items.where((i) => i.isAvailable).toList();

  List<String> get categories {
    final set = _items.map((i) => i.category.trim()).where((c) => c.isNotEmpty).toSet().toList();
    set.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return set.isEmpty ? ['Gypsum Board', 'PVC Panels', 'Louver Panels', 'Grid Ceiling'] : set;
  }

  Future<List<CatalogItemModel>> loadCatalog() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        _items = decoded
            .map((e) => CatalogItemModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        if (_items.isNotEmpty) return _items;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading local catalog: $e');
    }

    // Default sample catalog items with ceiling photos
    _items = [
      CatalogItemModel(
        id: 'cat_gypsum_1',
        category: 'Gypsum Board',
        name: 'Saint-Gobain Gyproc Moisture Resistant 12mm',
        description: 'Premium moisture-resistant gypsum ceiling board with Saint-Gobain warranty.',
        unit: 'Sq.Ft',
        rate: 95.0,
        imageUrl: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?q=80&w=800&auto=format&fit=crop',
        sku: 'SG-GYP-01',
        isAvailable: true,
        createdAt: DateTime.now(),
      ),
      CatalogItemModel(
        id: 'cat_louver_1',
        category: 'Louver Panels',
        name: 'WPC Exterior Wooden Texture Louver',
        description: 'Weather-proof WPC Louver panel for ceiling and accent wall features.',
        unit: 'Sq.Ft',
        rate: 220.0,
        imageUrl: 'https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?q=80&w=800&auto=format&fit=crop',
        sku: 'WPC-LV-02',
        isAvailable: true,
        createdAt: DateTime.now(),
      ),
      CatalogItemModel(
        id: 'cat_grid_1',
        category: 'Grid Ceiling',
        name: 'Acoustic Mineral Fiber Tile Ceiling 60x60',
        description: 'High sound-absorption commercial T-grid acoustic ceiling tile package.',
        unit: 'Sq.Ft',
        rate: 90.0,
        imageUrl: 'https://images.unsplash.com/photo-1600566753190-17f0baa2a6c3?q=80&w=800&auto=format&fit=crop',
        sku: 'GRD-AC-03',
        isAvailable: true,
        createdAt: DateTime.now(),
      ),
      CatalogItemModel(
        id: 'cat_lighting_1',
        category: 'Lighting & Cove',
        name: 'Warm White LED Cove Profile Channel',
        description: 'Concealed LED strip aluminum channel for perimeter cove ambient lighting.',
        unit: 'R.Ft',
        rate: 135.0,
        imageUrl: 'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?q=80&w=800&auto=format&fit=crop',
        sku: 'LED-COVE-04',
        isAvailable: true,
        createdAt: DateTime.now(),
      ),
    ];
    await saveCatalog(_items);
    return _items;
  }

  Future<void> saveCatalog(List<CatalogItemModel> newItems) async {
    _items = List.from(newItems);
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_items.map((i) => i.toJson()).toList());
      await prefs.setString(_storageKey, encoded);
    } catch (e) {
      if (kDebugMode) debugPrint('Error saving catalog: $e');
    }
  }

  Future<void> addItem(CatalogItemModel item) async {
    _items.insert(0, item);
    await saveCatalog(_items);
  }

  Future<void> updateItem(CatalogItemModel updated) async {
    final idx = _items.indexWhere((i) => i.id == updated.id);
    if (idx != -1) {
      _items[idx] = updated;
      await saveCatalog(_items);
    }
  }

  Future<void> deleteItem(String id) async {
    _items.removeWhere((i) => i.id == id);
    await saveCatalog(_items);
  }

  Future<bool> syncCatalogToFirestore() async {
    try {
      final db = FirebaseFirestore.instance;
      final batch = db.batch();
      final collection = db.collection('catalog');

      for (final item in _items) {
        batch.set(collection.doc(item.id), item.toJson(), SetOptions(merge: true));
      }

      await batch.commit();

      // Mirror to 'settings/catalog' for single doc stream on Web Portal
      await db.collection('settings').doc('catalog').set({
        'items': _items.map((i) => i.toJson()).toList(),
        'totalCount': _items.length,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedAtIso': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));

      if (kDebugMode) debugPrint('Catalog items synced to Firestore collection "catalog" & "settings/catalog".');
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('Error syncing catalog to Firestore: $e');
      return false;
    }
  }

  Stream<List<CatalogItemModel>> streamCatalog() {
    return FirebaseFirestore.instance.collection('catalog').snapshots().map((snap) {
      if (snap.docs.isEmpty) return _items;
      final list = snap.docs.map((doc) => CatalogItemModel.fromJson(doc.data())).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _items = list;
      return list;
    });
  }
}
