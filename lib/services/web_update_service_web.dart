// ignore_for_file: unused_field, unused_element, deprecated_member_use, use_build_context_synchronously, curly_braces_in_flow_control_structures, unused_local_variable, sort_child_properties_last, avoid_print, non_constant_identifier_names, avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:js' as js;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'web_update_service.dart';

class WebUpdateServiceImpl extends WebUpdateService {
   static const String currentVersion = '4.7'; // Bumped for authoritative build
  static const String _supabaseUrl = 'https://pNZYGMVENSMRZQPOBWTK.supabase.co/rest/v1';
  static const String _supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBuenlnbXZlbnNtcnpxcG9id3RrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE5NjIwODcsImV4cCI6MjA5NzUzODA4N30.lqCFxRcTGe4xGZ9gT4vYzurfNY-aLQvCL4tLBv9HF0k2';

  Timer? _updateTimer;
  bool _updateDetected = false;

  @override
  void init(BuildContext context) {
    if (!kIsWeb) return;

    // 1. Listen for Service Worker event from index.html
    html.window.addEventListener('pcm_web_update_available', (event) {
      _notifyUserOfUpdate(context);
    });

    // 2. Poll Supabase for Remote Version Change
    _startRemoteVersionPolling(context);
  }

  void _startRemoteVersionPolling(BuildContext context) {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(minutes: 2), (timer) async {
      if (_updateDetected) return;
      await _checkRemoteVersion(context);
    });
    
    // Initial check
    Future.delayed(const Duration(seconds: 5), () => _checkRemoteVersion(context));
  }

  Future<void> _checkRemoteVersion(BuildContext context) async {
    try {
      // Querying app_config table for web_version. 
      // Note: Admin should update this value in Supabase when deploying.
      final uri = Uri.parse('$_supabaseUrl/app_config?select=web_version&id=eq.1');
      final response = await http.get(uri, headers: {
        'apikey': _supabaseKey,
        'Authorization': 'Bearer $_supabaseKey',
      });

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          final String remoteVersion = data[0]['web_version']?.toString() ?? currentVersion;
          if (remoteVersion != currentVersion) {
            debugPrint('PCM Web: Remote update detected! $currentVersion -> $remoteVersion');
            _notifyUserOfUpdate(context);
          }
        }
      }
    } catch (e) {
      debugPrint('PCM Web: Version check failed: $e');
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

    // Auto-reload after 3 seconds as requested
    Future.delayed(const Duration(seconds: 3), () {
      js.context.callMethod('triggerForceReload');
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
  }
}
