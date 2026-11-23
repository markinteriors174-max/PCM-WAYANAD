import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Data model for unlimited promotional banners & ads
class PromoBannerModel {
  final String id;
  final String tag;
  final String title;
  final String subtitle;
  final String? actionText;
  final String? targetUrl;
  final String? imageUrl;
  final bool isActive;

  const PromoBannerModel({
    required this.id,
    required this.tag,
    required this.title,
    required this.subtitle,
    this.actionText,
    this.targetUrl,
    this.imageUrl,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'tag': tag,
        'title': title,
        'subtitle': subtitle,
        'actionText': actionText,
        'targetUrl': targetUrl,
        'imageUrl': imageUrl,
        'isActive': isActive,
      };

  factory PromoBannerModel.fromJson(Map<String, dynamic> json) {
    return PromoBannerModel(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      tag: json['tag']?.toString() ?? 'PCM WAYANAD SPECIAL',
      title: json['title']?.toString() ?? 'New Project Offer',
      subtitle: json['subtitle']?.toString() ?? 'Track your ceiling progress in real-time.',
      actionText: json['actionText']?.toString(),
      targetUrl: json['targetUrl']?.toString(),
      imageUrl: json['imageUrl']?.toString() ?? json['image_url']?.toString(),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  PromoBannerModel copyWith({
    String? id,
    String? tag,
    String? title,
    String? subtitle,
    String? actionText,
    String? targetUrl,
    String? imageUrl,
    bool? isActive,
  }) {
    return PromoBannerModel(
      id: id ?? this.id,
      tag: tag ?? this.tag,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      actionText: actionText ?? this.actionText,
      targetUrl: targetUrl ?? this.targetUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
    );
  }
}

/// Storage service for persisting unlimited promo banners
class PromoBannerService {
  static final PromoBannerService instance = PromoBannerService._internal();
  PromoBannerService._internal();

  static const String _storageKey = 'pcm_promotional_banners_v1';

  List<PromoBannerModel> _banners = [];

  List<PromoBannerModel> get banners => _banners;
  List<PromoBannerModel> get activeBanners => _banners.where((b) => b.isActive).toList();

  Future<List<PromoBannerModel>> loadBanners() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        _banners = decoded
            .map((e) => PromoBannerModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        if (_banners.isNotEmpty) return _banners;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading promo banners: $e');
    }

    // Default sample banners matching blue card style
    _banners = [
      const PromoBannerModel(
        id: 'banner_1',
        tag: 'PCM WAYANAD SPECIAL',
        title: 'New Residential Project Live Now',
        subtitle: 'Track your ceiling & gypsum progress in real-time.',
        actionText: 'EXPLORE NOW',
        isActive: true,
      ),
      const PromoBannerModel(
        id: 'banner_2',
        tag: 'DISCOUNT OFFER',
        title: 'Premium Gyproc Material Offer',
        subtitle: 'Get 10% off on Saint-Gobain Gyproc ceiling packages.',
        actionText: 'GET QUOTE',
        isActive: true,
      ),
    ];
    await saveBanners(_banners);
    return _banners;
  }

  Future<void> saveBanners(List<PromoBannerModel> newBanners) async {
    _banners = List.from(newBanners);
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_banners.map((b) => b.toJson()).toList());
      await prefs.setString(_storageKey, encoded);
    } catch (e) {
      if (kDebugMode) debugPrint('Error saving promo banners: $e');
    }
  }

  Future<void> addBanner(PromoBannerModel banner) async {
    _banners.add(banner);
    await saveBanners(_banners);
  }

  Future<void> updateBanner(PromoBannerModel updated) async {
    final idx = _banners.indexWhere((b) => b.id == updated.id);
    if (idx != -1) {
      _banners[idx] = updated;
      await saveBanners(_banners);
    }
  }

  Future<void> deleteBanner(String id) async {
    _banners.removeWhere((b) => b.id == id);
    await saveBanners(_banners);
  }

  Future<bool> syncBannersToFirestore() async {
    try {
      final db = FirebaseFirestore.instance;
      final batch = db.batch();
      final collection = db.collection('site_ads');

      for (final b in _banners) {
        batch.set(collection.doc(b.id), b.toJson(), SetOptions(merge: true));
      }

      await batch.commit();

      await db.collection('settings').doc('banners').set({
        'banners': _banners.map((b) => b.toJson()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedAtIso': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));

      if (kDebugMode) debugPrint('Site ads synced to Firestore site_ads & settings/banners.');
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('Error syncing site ads to Firestore: $e');
      return false;
    }
  }
}
