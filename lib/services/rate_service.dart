import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CeilingRateOption {
  final String id;
  final String name;
  final String subtitle;
  final double defaultRate;
  final IconData icon;

  const CeilingRateOption({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.defaultRate,
    required this.icon,
  });
}

class RateService {
  static final RateService instance = RateService._();
  RateService._();

  static const List<CeilingRateOption> standardOptions = [
    CeilingRateOption(
      id: 'gypsum_plain',
      name: 'Gypsum Plain Ceiling',
      subtitle: 'Saint-Gobain Gyproc / Knauf Flat False Ceiling',
      defaultRate: 95.0,
      icon: Icons.crop_square_rounded,
    ),
    CeilingRateOption(
      id: 'gypsum_cove',
      name: 'Gypsum Step / Cove Design',
      subtitle: 'Designer Step Ceiling with Indirect Cove Light Tray',
      defaultRate: 130.0,
      icon: Icons.layers_rounded,
    ),
    CeilingRateOption(
      id: 'pvc_ceiling',
      name: 'PVC False Ceiling',
      subtitle: '100% Moisture & Termite Proof Modern PVC Panels',
      defaultRate: 115.0,
      icon: Icons.view_quilt_rounded,
    ),
    CeilingRateOption(
      id: 'grid_ceiling',
      name: '2x2 Grid Acoustic Ceiling',
      subtitle: 'Armstrong / Mineral Fiber T-Grid Modular Tiles',
      defaultRate: 90.0,
      icon: Icons.grid_view_rounded,
    ),
    CeilingRateOption(
      id: 'wpc_louvers',
      name: 'Wooden / WPC Louvers Panel',
      subtitle: 'Premium Wood Plastic Composite / Fluted Accent Panels',
      defaultRate: 220.0,
      icon: Icons.line_style_rounded,
    ),
  ];

  static Map<String, double> get defaultRates {
    final map = <String, double>{};
    for (final opt in standardOptions) {
      map[opt.id] = opt.defaultRate;
    }
    return map;
  }

  // In-memory cache for immediate synchronous retrieval
  Map<String, double> _cachedRates = Map<String, double>.from(defaultRates);
  Map<String, double> get cachedRates => Map.unmodifiable(_cachedRates);

  /// Real-time stream of per-sq.ft rates from Cloud Firestore
  Stream<Map<String, double>> streamRates() {
    return FirebaseFirestore.instance
        .collection('settings')
        .doc('ceiling_rates')
        .snapshots()
        .map((snapshot) {
          final result = Map<String, double>.from(defaultRates);
          if (snapshot.exists && snapshot.data() != null) {
            final data = snapshot.data()!;
            for (final opt in standardOptions) {
              if (data.containsKey(opt.id) && data[opt.id] != null) {
                final val = (data[opt.id] as num).toDouble();
                if (val > 0) {
                  result[opt.id] = val;
                }
              }
            }
          }
          _cachedRates = Map<String, double>.from(result);
          return result;
        })
        .handleError((error) {
          debugPrint('RateService: Error streaming rates from Firestore: $error');
          return defaultRates;
        });
  }

  /// Update and save per-sq.ft rates to Firestore in real-time
  Future<bool> saveRates(Map<String, double> newRates) async {
    try {
      final payload = <String, dynamic>{
        ...newRates,
        'lastUpdated': FieldValue.serverTimestamp(),
        'updatedAtIso': DateTime.now().toIso8601String(),
        'updatedBy': 'admin',
      };

      // 1. Primary document
      await FirebaseFirestore.instance
          .collection('settings')
          .doc('ceiling_rates')
          .set(payload, SetOptions(merge: true));

      // 2. Dual backup documents to avoid rule/path mismatches
      FirebaseFirestore.instance
          .collection('settings')
          .doc('master_rates')
          .set(payload, SetOptions(merge: true))
          .catchError((e) {
            debugPrint('RateService backup settings/master_rates notice: $e');
          });

      FirebaseFirestore.instance
          .collection('rate_settings')
          .doc('ceiling_rates')
          .set(payload, SetOptions(merge: true))
          .catchError((e) {
            debugPrint('RateService backup rate_settings/ceiling_rates notice: $e');
          });

      _cachedRates = Map<String, double>.from(newRates);
      debugPrint('RateService: Rates saved successfully and streamed to all clients.');
      return true;
    } catch (e) {
      debugPrint('RateService: Error saving rates: $e');
      return false;
    }
  }

  /// Reset all rates back to defaults
  Future<bool> resetToDefaults() async {
    return await saveRates(defaultRates);
  }
}
