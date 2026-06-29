import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'database_service.dart';
import 'labor_service.dart';
import '../models/labor_models.dart';
import '../models/quotation.dart';

class GeofenceService {
  static final GeofenceService instance = GeofenceService._init();
  GeofenceService._init();


  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final LaborService _laborService = LaborService.instance;
  
  // Timer? _timer; // Removing unused field
  bool _isInitialized = false;

  // Shift Start Times (As provided by user example: Morning starts ~8:30 AM)
  final Map<ShiftType, int> _shiftStartHour = {
    ShiftType.morning: 8,
    ShiftType.afternoon: 13,
    ShiftType.evening: 18,
    ShiftType.night: 22,
  };
  final Map<ShiftType, int> _shiftStartMinute = {
    ShiftType.morning: 30,
    ShiftType.afternoon: 30,
    ShiftType.evening: 0,
    ShiftType.night: 0,
  };

  // Track initialization status to allow background calls
  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true; // Mark early to prevent concurrent calls

    try {
      // 1. Initialize Notifications
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings();
      await _notifications.initialize(
        settings: InitializationSettings(android: androidInit, iOS: iosInit),
      );

      // 2. Start Periodic Monitoring (Every 5 minutes)
      Timer.periodic(const Duration(minutes: 5), (timer) {
        _checkGeofences();
      });

      debugPrint('Geofence Service Initialized successfully');
    } catch (e) {
      debugPrint('Geofence Service Init Failed: $e (Likely due to missing permissions or Firebase)');
    }
  }

  Future<void> _checkGeofences() async {
    try {
      // 0. Permission & Service Check
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Geofence Check Error: Location services are disabled.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Geofence Check Error: User denied permissions.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Geofence Check Error: Permissions permanently denied.');
        return;
      }

      // 1. Get current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      // 2. Get all pinned sites
      final sites = await DatabaseService.instance.getQuotations();
      final pinnedSites = sites.where((s) => s.latitude != null && s.longitude != null).toList();

      // 3. Get active shifts (for current device user if possible)
      final activeShifts = await _laborService.getAllActiveShifts().first;

      for (var site in pinnedSites) {
        double distance = Geolocator.distanceBetween(
          position.latitude, position.longitude,
          site.latitude!, site.longitude!,
        );

        // -- RULE 1: ARRIVAL ALERT (Loud tune if at site +15 mins but not checked in) --
        if (distance < 150) { // Within 150m of site
          await _checkArrivalReminder(site, activeShifts);
        }

        // -- RULE 2: DEPARTURE ALERT (Loud tune if left site without checking out) --
        if (distance > 300) { // Left site boundary
          await _checkDepartureReminder(site, activeShifts);
        }
      }
    } catch (e) {
      debugPrint('Geofence Check Error: $e');
    }
  }

  Future<void> _checkArrivalReminder(Quotation site, List<LaborEntry> activeShifts) async {
    final now = DateTime.now();
    
    // Check which shift we are currently in based on User Times
    ShiftType currentShift;
    if (now.hour >= 8 && (now.hour < 13 || (now.hour == 13 && now.minute < 30))) {
      currentShift = ShiftType.morning;
    } else if ((now.hour > 13 || (now.hour == 13 && now.minute >= 30)) && now.hour < 18) {
      currentShift = ShiftType.afternoon;
    } else if (now.hour >= 18 && now.hour < 22) {
      currentShift = ShiftType.evening;
    } else {
      currentShift = ShiftType.night;
    }

    final startHour = _shiftStartHour[currentShift]!;
    final startMin = _shiftStartMinute[currentShift]!;
    final shiftStart = DateTime(now.year, now.month, now.day, startHour, startMin);

    // If more than 15 mins passed since shift start
    if (now.difference(shiftStart).inMinutes > 15) {
      // Is anyone checked in for this site?
      bool isCheckedIn = activeShifts.any((s) => s.siteName == site.unitNumber);
      
      if (!isCheckedIn) {
        _triggerLoudAlert(
          'MISSING CHECK-IN',
          'You are at SITE ${site.unitNumber} but have not Checked-in for the ${currentShift.name} shift!',
        );
      }
    }
  }

  Future<void> _checkDepartureReminder(Quotation site, List<LaborEntry> activeShifts) async {
    // Is any current user checked into this site but left the premises?
    final pendingCheckout = activeShifts.where((s) => s.siteName == site.unitNumber).toList();
    
    if (pendingCheckout.isNotEmpty) {
      _triggerLoudAlert(
        'FORGOT CHECK-OUT',
        'You have left SITE ${site.unitNumber}. Please Check-out immediately to finalize your hours!',
      );
    }
  }

  void _triggerLoudAlert(String title, String body) async {
    try {
      // Audio playback removed for silence requirement

      // 2. Show Notification with Max Priority (Loud)
      const androidDetails = AndroidNotificationDetails(
        'geofence_alerts_loud', 'Critical Geofence Alerts',
        channelDescription: 'High volume alerts for site arrivals and departures',
        importance: Importance.max, 
        priority: Priority.high,
        fullScreenIntent: true,
        playSound: true,
        audioAttributesUsage: AudioAttributesUsage.alarm,
      );
      const notificationDetails = NotificationDetails(android: androidDetails);
      
      await _notifications.show(
        id: 999,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
      );
    } catch (e) {
      debugPrint('Failed to trigger loud alert: $e');
    }
  }

  Future<bool> isWithinSiteRadius(double siteLat, double siteLng, {double radius = 300}) async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      double distance = Geolocator.distanceBetween(
        position.latitude, position.longitude,
        siteLat, siteLng,
      );
      return distance <= radius;
    } catch (e) {
      debugPrint('GPS Validation Error: $e');
      return false;
    }
  }

  Future<Quotation?> findCurrentSite({double radius = 500}) async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      
      final sites = await DatabaseService.instance.getQuotations();
      Quotation? closestSite;
      double minDistance = double.infinity;

      for (var site in sites) {
        if (site.latitude == null || site.longitude == null) continue;
        
        double distance = Geolocator.distanceBetween(
          position.latitude, position.longitude,
          site.latitude!, site.longitude!,
        );

        if (distance <= radius && distance < minDistance) {
          minDistance = distance;
          closestSite = site;
        }
      }
      return closestSite;
    } catch (e) {
      debugPrint('Error finding current site: $e');
      return null;
    }
  }

  void stopAlert() {
  }
}
