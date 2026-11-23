import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Top-level background message handler for Firebase Cloud Messaging.
/// Must be annotated with `@pragma('vm:entry-point')` so Flutter engine can invoke it.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    debugPrint('[FCM Background] Incoming message: ${message.messageId} - ${message.notification?.title}');
  } catch (e) {
    debugPrint('[FCM Background] Notice: $e');
  }
}

/// Firebase Cloud Messaging (FCM) and Real-time Alerting Service for Admin App.
/// 
/// Provides:
/// 1. Admin device registration with FCM & local notifications channel.
/// 2. Subscription to 'pcm_admin_updates' and 'pcm_site_folders' topics.
/// 3. Instant local heads-up notifications (banner, sound, vibration) in foreground & background.
/// 4. Real-time Firestore stream listener on `admin_alerts` to ensure zero-latency alerts.
/// 5. Global dispatch method `notifyAdminOfClientChange` triggered whenever a client
///    updates their profile or adds/updates information in Site Folders.
class FCMAdminNotificationService {
  static final FCMAdminNotificationService instance = FCMAdminNotificationService._internal();
  FCMAdminNotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static const String adminChannelId = 'pcm_admin_alerts_channel';
  static const String adminChannelName = 'PCM Admin Realtime Alerts';
  static const String adminChannelDesc = 'Instant notifications when clients update profile or site folders';

  bool _isInitialized = false;
  StreamSubscription<QuerySnapshot>? _alertsSubscription;
  DateTime? _sessionStartTime;
  Function(String unitNumber)? onSiteFolderTapped;

  /// Initializes FCM and Local Notifications on Admin Mobile Device.
  Future<void> initAdminNotifications({Function(String unitNumber)? onSiteFolderTap}) async {
    if (kIsWeb) return;
    if (_isInitialized) return;

    try {
      _sessionStartTime = DateTime.now().toUtc();
      if (onSiteFolderTap != null) {
        onSiteFolderTapped = onSiteFolderTap;
      }

      // 1. Initialize Flutter Local Notifications for Android & iOS
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);

      await _localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          final payload = response.payload;
          if (payload != null && payload.isNotEmpty) {
            onSiteFolderTapped?.call(payload);
          }
        },
      );

      // 2. Create High-Priority Notification Channel for Android
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        adminChannelId,
        adminChannelName,
        description: adminChannelDesc,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      // 3. Request FCM User Permissions
      final settings = await _fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        debugPrint('[FCM Admin] Permission granted: ${settings.authorizationStatus}');

        // 4. Subscribe to Admin Notification Topics
        try {
          await _fcm.subscribeToTopic('pcm_admin_updates');
          await _fcm.subscribeToTopic('pcm_site_folders');
          debugPrint('[FCM Admin] Subscribed to pcm_admin_updates & pcm_site_folders');
        } catch (subErr) {
          debugPrint('[FCM Admin] Topic subscription notice: $subErr');
        }

        // 5. Retrieve FCM Device Token and register to Firestore
        try {
          final token = await _fcm.getToken();
          if (token != null && token.isNotEmpty) {
            await _registerAdminDeviceToken(token);
          }
          _fcm.onTokenRefresh.listen((newToken) {
            _registerAdminDeviceToken(newToken);
          });
        } catch (tokenErr) {
          debugPrint('[FCM Admin] Token retrieval notice: $tokenErr');
        }

        // 6. Set up Foreground Message Listener
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          final notification = message.notification;
          final title = notification?.title ?? message.data['title'] ?? '🔔 PCM Client Update';
          final body = notification?.body ?? message.data['body'] ?? 'Client made updates in Site Folder';
          final unitNumber = message.data['unitNumber']?.toString() ?? '';

          showLocalNotification(
            title: title,
            body: body,
            payload: unitNumber,
          );
        });

        // 7. Handle Notification Click when App is in Background
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          final unitNumber = message.data['unitNumber']?.toString();
          if (unitNumber != null && unitNumber.isNotEmpty) {
            onSiteFolderTapped?.call(unitNumber);
          }
        });

        // 8. Handle Notification Click that Launched the App from Terminated State
        final initialMessage = await _fcm.getInitialMessage();
        if (initialMessage != null) {
          final unitNumber = initialMessage.data['unitNumber']?.toString();
          if (unitNumber != null && unitNumber.isNotEmpty) {
            Future.delayed(const Duration(milliseconds: 800), () {
              onSiteFolderTapped?.call(unitNumber);
            });
          }
        }
      }

      // 9. Start Real-time Firestore Alert Listener for Zero-Latency Admin Alerts
      _startFirestoreRealtimeAlertsListener();

      _isInitialized = true;
      debugPrint('[FCM Admin] Initialized successfully with high-priority channel and real-time listeners.');
    } catch (e) {
      debugPrint('[FCM Admin] Init error: $e');
    }
  }

  /// Registers or updates the Admin's device token in Firestore
  Future<void> _registerAdminDeviceToken(String token) async {
    try {
      await _firestore.collection('admin_fcm_tokens').doc(token).set({
        'token': token,
        'role': 'admin',
        'platform': defaultTargetPlatform.name,
        'lastActive': FieldValue.serverTimestamp(),
        'subscribedTopics': ['pcm_admin_updates', 'pcm_site_folders'],
      }, SetOptions(merge: true));
      debugPrint('[FCM Admin] Device token saved to Firestore: ${token.substring(0, 10)}...');
    } catch (e) {
      debugPrint('[FCM Admin] Firestore token save notice: $e');
    }
  }

  /// Real-time Firestore stream listener on `admin_alerts`.
  /// Pops an instant heads-up notification banner whenever any client updates data.
  void _startFirestoreRealtimeAlertsListener() {
    if (kIsWeb) return;
    final startTime = _sessionStartTime ?? DateTime.now().toUtc();

    _alertsSubscription?.cancel();
    _alertsSubscription = _firestore
        .collection('admin_alerts')
        .where('read', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data == null) continue;

          // Ignore old historical notifications created before this session
          final createdAtStr = data['createdAt'] as String?;
          if (createdAtStr != null) {
            final createdAt = DateTime.tryParse(createdAtStr);
            if (createdAt != null && createdAt.isBefore(startTime.subtract(const Duration(seconds: 5)))) {
              continue;
            }
          }

          final title = data['title']?.toString() ?? '🔔 PCM Client Update';
          final body = data['body']?.toString() ?? 'Client updated Site Folder';
          final unitNumber = data['unitNumber']?.toString() ?? '';

          showLocalNotification(
            title: title,
            body: body,
            payload: unitNumber,
          );
        }
      }
    }, onError: (err) {
      debugPrint('[FCM Admin] Realtime alerts stream notice: $err');
    });
  }

  /// Shows an instant local heads-up notification with sound & vibration on Android/iOS
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) return;

    try {
      const androidDetails = AndroidNotificationDetails(
        adminChannelId,
        adminChannelName,
        channelDescription: adminChannelDesc,
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'PCM Admin Notification',
        showWhen: true,
        enableVibration: true,
        playSound: true,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

      final int notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);
      await _localNotifications.show(
        id: notificationId,
        title: title,
        body: body,
        notificationDetails: details,
        payload: payload,
      );
    } catch (e) {
      debugPrint('[FCM Admin] showLocalNotification notice: $e');
    }
  }

  /// Triggers an immediate push alert and notification event for the Admin.
  /// 
  /// Can be called from any client interface (Web Portal or Mobile App):
  /// - Client updates profile (name, phone, address, requirements)
  /// - Client or worker updates Site Folders (progress, documents, photos, chat, receipts)
  Future<void> notifyAdminOfClientChange({
    required String clientName,
    required String unitNumber,
    required String updateType,
    required String details,
    Map<String, dynamic>? extraData,
  }) async {
    try {
      final String cleanUnit = unitNumber.trim();
      final String safeClientName = clientName.trim().isEmpty ? 'Client' : clientName.trim();
      final String title = '🔔 $safeClientName: $updateType';
      final String body = '$cleanUnit • $details';

      final Map<String, dynamic> alertDoc = {
        'channel': 'pcm_admin_updates',
        'title': title,
        'body': body,
        'clientName': safeClientName,
        'unitNumber': cleanUnit,
        'updateType': updateType,
        'details': details,
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'read': false,
        'source': kIsWeb ? 'web_portal' : 'mobile_app',
        'extraData': extraData ?? {},
      };

      // 1. Write to global `admin_alerts` collection (fires real-time Admin notification)
      await _firestore.collection('admin_alerts').add(alertDoc);

      // 2. Add to client's Site Folder activity log
      final String cleanDocId = cleanUnit.replaceAll('#', '').trim();
      if (cleanDocId.isNotEmpty) {
        try {
          await _firestore
              .collection('clients')
              .doc(cleanDocId)
              .collection('activity_log')
              .add({
            'action': updateType,
            'details': details,
            'timestamp': FieldValue.serverTimestamp(),
            'createdAt': DateTime.now().toUtc().toIso8601String(),
            'source': kIsWeb ? 'web_portal' : 'mobile_app',
          });
        } catch (_) {}

        // 3. Update client doc's lastClientActivity timestamp
        try {
          await _firestore.collection('clients').doc(cleanDocId).set({
            'lastClientActivity': FieldValue.serverTimestamp(),
            'lastActivityType': updateType,
          }, SetOptions(merge: true));
        } catch (_) {}
      }

      debugPrint('[FCM Admin Alert Dispatched] $title - $body');
    } catch (e) {
      debugPrint('[FCM Admin Alert] Failed to dispatch alert: $e');
    }
  }

  /// Cancels listeners upon logout / cleanup
  void dispose() {
    _alertsSubscription?.cancel();
    _alertsSubscription = null;
    _isInitialized = false;
  }
}
