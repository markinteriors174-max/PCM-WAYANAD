// ignore_for_file: unused_field, unused_element, deprecated_member_use, use_build_context_synchronously, curly_braces_in_flow_control_structures, unused_local_variable, sort_child_properties_last, avoid_print, non_constant_identifier_names, avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'web_update_service.dart';

class WebUpdateServiceImpl extends WebUpdateService {
  static const String currentVersion = '4.7';

  Timer? _updateTimer;
  bool _updateDetected = false;

  @override
  void init(BuildContext context) {
    if (!kIsWeb) return;

    // 1. Listen for Service Worker event from index.html
    html.window.addEventListener('pcm_web_update_available', (event) {
      _notifyUserOfUpdate(context);
    });

    // 2. Check Firestore for Remote Version Change
    _startRemoteVersionPolling(context);
  }

  void _startRemoteVersionPolling(BuildContext context) {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      if (_updateDetected) return;
      await _checkRemoteVersion(context);
    });

    // Initial check
    Future.delayed(const Duration(seconds: 5), () => _checkRemoteVersion(context));
  }

  Future<void> _checkRemoteVersion(BuildContext context) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('app_config').doc('web_version').get();
      if (doc.exists && doc.data() != null) {
        final String remoteVersion = doc.data()!['version']?.toString() ?? currentVersion;
        if (remoteVersion != currentVersion) {
          debugPrint('PCM Web: Remote update detected via Firestore! $currentVersion -> $remoteVersion');
          _notifyUserOfUpdate(context);
        }
      }
    } catch (e) {
      // Gracefully ignore expected offline/unavailable network blips
      final str = e.toString().toLowerCase();
      if (!str.contains('offline') && !str.contains('unavailable') && !str.contains('network')) {
        debugPrint('PCM Web: Version check notice: $e');
      }
    }
  }

  void _notifyUserOfUpdate(BuildContext context) {
    if (_updateDetected) return;
    _updateDetected = true;

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        backgroundColor: const Color(0xFF1976D2),
        content: const Text(
          'ADMIN HAS DEPLOYED A NEW UPDATE. RELOADING TO APPLY CHANGES...',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
        ),
        leading: const Icon(Icons.system_update, color: Colors.white),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        actions: [
          TextButton(
            onPressed: () => js.context.callMethod('triggerForceReload'),
            child: const Text('REFRESH NOW', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, decoration: TextDecoration.underline)),
          ),
        ],
      ),
    );

    // Auto-reload after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      js.context.callMethod('triggerForceReload');
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
  }
}
