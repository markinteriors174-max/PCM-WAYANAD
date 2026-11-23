// ignore_for_file: unused_field, unused_element, deprecated_member_use, use_build_context_synchronously, curly_braces_in_flow_control_structures, unused_local_variable, sort_child_properties_last, avoid_print, non_constant_identifier_names, avoid_web_libraries_in_flutter
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class PhotoNotificationService {
  static final PhotoNotificationService instance = PhotoNotificationService._init();
  PhotoNotificationService._init();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  StreamSubscription? _subscription;
  DateTime? _lastCheckedTimestamp;

  bool _initialized = false;

  Future<void> init() async {
    if (kIsWeb) return;
    if (_initialized) return;

    try {
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings();
      const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);

      await _notifications.initialize(settings: initSettings);

      _lastCheckedTimestamp = DateTime.now().toUtc();
      _initialized = true;
    } catch (e) {
      debugPrint('Notification Init Error: $e');
    }
  }

  void startPolling() {
    if (kIsWeb) return;
    if (!_initialized) {
      init().then((_) => _startListening());
    } else {
      _startListening();
    }
  }

  void _startListening() {
    _subscription?.cancel();
    _subscription = FirebaseFirestore.instance
        .collection('project_photos')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        final name = (data['name'] ?? 'Project Photo').toString();
        final siteId = (data['siteId'] ?? 'General').toString();
        showTextNotification(
          title: 'New Site Photo Uploaded',
          body: 'Photo $name uploaded for site $siteId',
        );
      }
    }, onError: (e) {
      debugPrint('PhotoNotificationService Firestore listener notice: $e');
    });
  }

  void stopPolling() {
    _subscription?.cancel();
    _subscription = null;
  }

  Future<void> showTextNotification({required String title, required String body}) async {
    if (kIsWeb) return;
    try {
      if (!_initialized) {
        await init();
      }

      const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'general_notifications',
        'General Notifications',
        channelDescription: 'Notifications for work progress updates',
        importance: Importance.max,
        priority: Priority.high,
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);

      await _notifications.show(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title: title,
        body: body,
        notificationDetails: platformChannelSpecifics,
      );
    } catch (e) {
      debugPrint("Error showing text notification: $e");
    }
  }
}
