import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BrandService {
  static final BrandService instance = BrandService._();
  BrandService._();

  static const List<String> defaultChannelBrands = [
    'Gyproc',
    'Expert',
    'JK',
    'Two Steel',
    'Jindal',
    'TATA Steel',
    'Boral',
    'Knauf',
    'Gypstar',
    'Gypdec',
    'Superfinish',
    'Frame Rock',
    'Armstrong',
    'Dexune',
    'Everest',
  ];

  static const List<String> defaultBoardBrands = [
    'Gyproc',
    'Gyproc MR',
    'Gyproc Fire',
    'JK',
    'Boral',
    'Knauf',
    'Insuboard',
    'V-Board',
    'Hilux',
    'Aerocon',
    'Shera',
    'Everest',
    'Hysil',
    'Armstrong',
    'Dexune',
    'Daiken',
    'Gypcore',
    'Sakarni',
    'VOX',
    'Bestwood',
    'Denwud',
    'Emax',
    'Alstone',
    'Eurobond',
  ];

  List<String> customChannelBrands = [];
  List<String> customBoardBrands = [];
  Map<String, Map<String, double>> brandRates = {}; // brandName -> {itemKey -> rate}

  List<String> get channelBrands => [...defaultChannelBrands, ...customChannelBrands];
  List<String> get boardBrands => [...defaultBoardBrands, ...customBoardBrands];

  bool isTargetCategory(String categoryName) {
    final lower = categoryName.toLowerCase();
    return lower.contains('gypsum board') ||
        lower.contains('v-board') ||
        lower.contains('partition') ||
        lower.contains('drywall') ||
        lower.contains('grid ceiling') ||
        lower.contains('insu board') ||
        lower.contains('ceiling') ||
        lower.contains('wall');
  }

  bool isChannelItem(String itemName) {
    final lower = itemName.toLowerCase();
    if (lower.contains('soffit') ||
        lower.contains('cleat') ||
        lower.contains('clamp') ||
        lower.contains('screw') ||
        lower.contains('fastener') ||
        lower.contains('plug') ||
        lower.contains('anchor') ||
        lower.contains('clip')) {
      return false;
    }
    return lower.contains('perimeter') ||
        lower.contains('intermediate') ||
        lower.contains('ceiling section') ||
        lower.contains('l angle') ||
        lower.contains('l-angle') ||
        lower.contains('stud') ||
        lower.contains('track') ||
        lower.contains('gi channel') ||
        lower.contains('channel') ||
        lower.contains('kj channel') ||
        lower.contains('expert') ||
        lower.contains('true steel');
  }

  bool isBoardItem(String itemName) {
    final lower = itemName.toLowerCase();
    if (lower.contains('screw') ||
        lower.contains('tape') ||
        lower.contains('powder') ||
        lower.contains('filler') ||
        lower.contains('plug') ||
        lower.contains('bolt') ||
        lower.contains('mesh') ||
        lower.contains('glue') ||
        lower.contains('clip')) {
      return false;
    }
    return lower.contains('gypsum board') ||
        lower.contains('v-board') ||
        lower.contains('board sheets') ||
        lower.contains('board (12 mm)') ||
        lower.contains('mr board') ||
        lower.contains('plain gypsum') ||
        lower.contains('fiber cement') ||
        lower.contains('insu board') ||
        lower.contains('tiles') ||
        lower.contains('panel') ||
        (lower.contains('board') && !lower.contains('cement board screw'));
  }

  Future<void> loadBrands() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final chJson = prefs.getString('custom_channel_brands');
      if (chJson != null && chJson.isNotEmpty) {
        customChannelBrands = List<String>.from(jsonDecode(chJson));
      }
      final bdJson = prefs.getString('custom_board_brands');
      if (bdJson != null && bdJson.isNotEmpty) {
        customBoardBrands = List<String>.from(jsonDecode(bdJson));
      }
      final ratesJson = prefs.getString('brand_custom_rates');
      if (ratesJson != null && ratesJson.isNotEmpty) {
        final decoded = jsonDecode(ratesJson) as Map<String, dynamic>;
        brandRates = decoded.map((k, v) => MapEntry(
            k,
            Map<String, double>.from((v as Map).map(
                (rk, rv) => MapEntry(rk.toString(), (rv as num).toDouble())))));
      }
    } catch (e) {
      debugPrint('Error loading local brands: $e');
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('master_brands')
          .get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data['customChannelBrands'] is List) {
          final list = List<String>.from(data['customChannelBrands']);
          for (var b in list) {
            if (!customChannelBrands.contains(b)) customChannelBrands.add(b);
          }
        }
        if (data['customBoardBrands'] is List) {
          final list = List<String>.from(data['customBoardBrands']);
          for (var b in list) {
            if (!customBoardBrands.contains(b)) customBoardBrands.add(b);
          }
        }
      }
    } catch (e) {
      debugPrint('Firestore brand sync notice: $e');
    }
  }

  Future<void> saveBrands() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'custom_channel_brands', jsonEncode(customChannelBrands));
      await prefs.setString(
          'custom_board_brands', jsonEncode(customBoardBrands));
      await prefs.setString('brand_custom_rates', jsonEncode(brandRates));
    } catch (e) {
      debugPrint('Error saving local brands: $e');
    }

    try {
      await FirebaseFirestore.instance
          .collection('settings')
          .doc('master_brands')
          .set({
        'customChannelBrands': customChannelBrands,
        'customBoardBrands': customBoardBrands,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving cloud brands: $e');
    }
  }

  Future<void> addBrand(
      {required String brandName,
      required bool isChannel,
      Map<String, double>? rates}) async {
    final clean = brandName.trim();
    if (clean.isEmpty) return;
    if (isChannel) {
      if (!channelBrands.contains(clean)) {
        customChannelBrands.add(clean);
      }
    } else {
      if (!boardBrands.contains(clean)) {
        customBoardBrands.add(clean);
      }
    }
    if (rates != null && rates.isNotEmpty) {
      brandRates[clean] = rates;
    }
    await saveBrands();
  }

  Future<void> editBrand({
    required String oldName,
    required String newName,
    required bool isChannel,
  }) async {
    final cleanOld = oldName.trim();
    final cleanNew = newName.trim();
    if (cleanNew.isEmpty || cleanOld == cleanNew) return;

    if (isChannel) {
      final idx = customChannelBrands.indexOf(cleanOld);
      if (idx != -1) {
        customChannelBrands[idx] = cleanNew;
      } else if (!channelBrands.contains(cleanNew)) {
        customChannelBrands.add(cleanNew);
      }
    } else {
      final idx = customBoardBrands.indexOf(cleanOld);
      if (idx != -1) {
        customBoardBrands[idx] = cleanNew;
      } else if (!boardBrands.contains(cleanNew)) {
        customBoardBrands.add(cleanNew);
      }
    }

    if (brandRates.containsKey(cleanOld)) {
      brandRates[cleanNew] = brandRates.remove(cleanOld)!;
    }

    await saveBrands();
  }

  Future<void> deleteBrand(String brandName, bool isChannel) async {
    final clean = brandName.trim();
    if (isChannel) {
      customChannelBrands.remove(clean);
    } else {
      customBoardBrands.remove(clean);
    }
    brandRates.remove(clean);
    await saveBrands();
  }
}
