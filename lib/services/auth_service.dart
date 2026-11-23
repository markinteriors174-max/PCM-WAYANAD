// ignore_for_file: unused_field, unused_element, deprecated_member_use, use_build_context_synchronously, curly_braces_in_flow_control_structures, unused_local_variable, sort_child_properties_last, avoid_print, non_constant_identifier_names, avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import '../models/user_model.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService extends ChangeNotifier {
  static final AuthService instance = AuthService._init();
  AuthService._init();

  static final AppUser _defaultAdmin = AppUser(
    uid: 'master-admin-bypass',
    name: 'Madhusudhan (Master)',
    email: 'asmadhu299@gmail.com',
    phone: '9383406185',
    role: UserRole.admin,
    isApproved: true,
  );

  AppUser? _userData = _defaultAdmin;
  AppUser? get userData => _userData ?? _defaultAdmin;
  AppUser? get currentUser => _userData ?? _defaultAdmin;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  Timer? _rolePollingTimer;
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  // --- PLATFORM SAFE STORAGE HELPERS ---
  
  Future<void> _writeData(String key, String value) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } else {
      const storage = FlutterSecureStorage();
      await storage.write(key: key, value: value);
    }
  }

  Future<String?> _readData(String key) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } else {
      const storage = FlutterSecureStorage();
      return await storage.read(key: key);
    }
  }

  Future<void> _clearAllData() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } else {
      const storage = FlutterSecureStorage();
      await storage.deleteAll();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    }
  }

  // --- INITIALIZATION ---

  Future<void> init() async {
    _userData = _defaultAdmin;
    _isInitialized = true;
    notifyListeners();
  }

  void startRoleMonitoring() {
    if (kIsWeb) return;
    _rolePollingTimer?.cancel();
    _rolePollingTimer = Timer.periodic(const Duration(seconds: 15), (_) => _pollRoleChange());
  }

  void stopRoleMonitoring() {
    _rolePollingTimer?.cancel();
    _rolePollingTimer = null;
  }

  Future<void> _pollRoleChange() async {
    if (_userData == null || _userData!.uid.startsWith('dev-') || _userData!.uid.startsWith('master-')) return;
    try {
      final doc = await _db.collection('client_profiles').doc(_userData!.uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final String newRoleStr = data['role']?.toString() ?? 'client';
        final bool newApproval = data['is_approved'] ?? false;
        final UserRole newRole = UserRole.values.firstWhere(
          (e) => e.name == newRoleStr,
          orElse: () => _userData!.role,
        );
        if (newRole != _userData!.role || newApproval != _userData!.isApproved) {
          await fetchUserData(_userData!.uid);
        }
      }
    } catch (e) {
      debugPrint('Error polling role from Firestore: $e');
    }
  }

  Future<void> fetchUserData([String? uid]) async {
    final targetUid = uid ?? _userData?.uid;
    if (targetUid == null || targetUid.startsWith('dev-')) return;
    try {
      final doc = await _db.collection('client_profiles').doc(targetUid).get();
      if (doc.exists && doc.data() != null) {
        _userData = AppUser.fromMap(doc.data()!, doc.id);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching user data from Firestore: $e');
    }
  }

  Future<void> login(String mobile, String pin) async {
    _isLoading = true;
    notifyListeners();

    // ADMIN BYPASS: Strictly for Mobile App debugging, disabled for Web Client Portal
    if (!kIsWeb && kDebugMode && mobile == '9383406185' && pin == '2990') {
      _userData = AppUser(
        uid: 'dev-master-admin',
        name: 'Madhusudhan',
        email: 'asmadhu299@gmail.com',
        phone: mobile,
        role: UserRole.admin,
        isApproved: true,
      );
      await _writeData('isDevMaster', 'true');
      await _writeData('user_uid', _userData!.uid);
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final String cleanPin = pin.trim().toLowerCase().replaceAll('pcm-ms-', '');
      final String fullId = 'pcm-ms-$cleanPin';

      // 1. Query client_profiles in Firestore
      final snap = await _db
          .collection('client_profiles')
          .where('phone', isEqualTo: mobile)
          .get();

      for (var doc in snap.docs) {
        final unit = (doc.data()['unit_number'] ?? '').toString().toLowerCase();
        if (unit == fullId || unit == cleanPin || unit.contains(cleanPin)) {
          _userData = AppUser.fromMap(doc.data(), doc.id);
          await _writeData('user_uid', _userData!.uid);
          startRoleMonitoring();
          _isLoading = false;
          notifyListeners();
          return;
        }
      }

      // 2. FALLBACK: Query clients collection in Firestore
      final clientSnap = await _db
          .collection('clients')
          .where('phone_number', isEqualTo: mobile)
          .get();

      for (var doc in clientSnap.docs) {
        final unit = (doc.data()['unitNumber'] ?? doc.id).toString().toLowerCase();
        if (unit == fullId || unit == cleanPin || unit.contains(cleanPin)) {
          final c = doc.data();
          _userData = AppUser(
            uid: 'client-${doc.id}',
            name: (c['client_name'] ?? 'PCM User').toString(),
            email: '',
            phone: mobile,
            role: UserRole.client,
            isApproved: true,
            assignedSites: [doc.id],
          );
          await _writeData('user_uid', _userData!.uid);
          _isLoading = false;
          notifyListeners();
          return;
        }
      }

      throw Exception('Invalid Mobile Number or PIN.');
    } catch (e) {
      debugPrint('Login Error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> adminLogin(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    final cleanEmail = email.trim().toLowerCase();

    try {
      // 1. MASTER BYPASS: Immediate local authentication for designated admin
      if (cleanEmail == 'asmadhu299@gmail.com' && (password == '123456' || password == 'pcm2025')) {
        _userData = AppUser(
          uid: 'master-admin-bypass',
          name: 'Madhusudhan (Master)',
          email: cleanEmail,
          phone: '9383406185',
          role: UserRole.admin,
          isApproved: true,
        );
        await _writeData('user_uid', _userData!.uid);
        await _writeData('isDevMaster', 'true');

        _ensureAdminProfileExists(cleanEmail);

        _isLoading = false;
        notifyListeners();
        return;
      }

      // 2. REMOTE CHECK: Firestore client_profiles
      final snap = await _db
          .collection('client_profiles')
          .where('email', isEqualTo: cleanEmail)
          .where('role', isEqualTo: 'admin')
          .get();

      if (snap.docs.isNotEmpty) {
        if (password == 'admin123' || password == 'pcm2025') {
          final p = snap.docs.first.data();
          _userData = AppUser.fromMap(p, snap.docs.first.id);
          await _writeData('user_uid', _userData!.uid);
          await _writeData('isDevMaster', 'false');
          startRoleMonitoring();
        } else {
          throw Exception('Incorrect Password.');
        }
      } else {
        throw Exception('Admin account not found.');
      }
    } catch (e) {
      debugPrint('Admin Login Error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _ensureAdminProfileExists(String email) async {
    try {
      final payload = {
        'id': 'master-admin-bypass',
        'full_name': 'Madhusudhan (Master)',
        'email': email,
        'phone': '9383406185',
        'role': 'admin',
        'is_approved': true,
      };

      await _db.collection('client_profiles').doc('master-admin-bypass').set(
        payload,
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('Silent profile upsert notice: $e');
    }
  }

  Future<void> logout() async {
    stopRoleMonitoring();
    _userData = _defaultAdmin;
    notifyListeners();
  }

  String _generateUuidV4() {
    final random = Random();
    final bytes = List<int>.generate(16, (i) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final chars = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).toList();
    return '${chars[0]}${chars[1]}${chars[2]}${chars[3]}-'
        '${chars[4]}$chars[5]-'
        '${chars[6]}$chars[7]-'
        '${chars[8]}$chars[9]-'
        '${chars[10]}$chars[11]}${chars[12]}${chars[13]}${chars[14]}${chars[15]}';
  }

  Future<String?> registerGuest({
    required String name,
    required String phone,
    required String location,
    String? manualPin,
  }) async {
    _isLoading = true;
    notifyListeners();

    final String pinDigits = manualPin ?? (1000 + Random().nextInt(9000)).toString();
    final String fullUnitId = 'pcm-ms-$pinDigits';
    final String uuid = _generateUuidV4();
    final String guestEmail = '$pinDigits@pcm.guest';

    debugPrint('PCM_DEBUG: Starting registration in Firestore for $name ($fullUnitId)');

    try {
      final Map<String, dynamic> clientPayload = {
        'unitNumber': fullUnitId,
        'client_name': name,
        'phone_number': phone,
        'site_location': location,
        'status': 'Pending',
        'created_at': FieldValue.serverTimestamp(),
      };

      await _db.collection('clients').doc(fullUnitId).set(clientPayload, SetOptions(merge: true));

      final profilePayload = {
        'id': uuid,
        'full_name': name,
        'phone': phone,
        'email': guestEmail,
        'role': 'client',
        'is_approved': true,
        'unit_number': fullUnitId,
        'created_at': FieldValue.serverTimestamp(),
      };

      await _db.collection('client_profiles').doc(uuid).set(profilePayload, SetOptions(merge: true));

      _userData = AppUser(
        uid: uuid,
        name: name,
        email: guestEmail,
        phone: phone,
        role: UserRole.client,
        isApproved: true,
        assignedSites: [fullUnitId],
      );

      await _writeData('user_uid', uuid);
      notifyListeners();
      return fullUnitId;
    } catch (e) {
      debugPrint('PCM_DEBUG: REGISTRATION EXCEPTION: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loginAsWorker(String id, String name) async {
    _userData = AppUser(
      uid: id,
      name: name,
      email: '$id@pcm.worker',
      phone: '',
      role: UserRole.worker,
      isApproved: true,
    );
    notifyListeners();
  }

  Future<void> promoteUserToWorker(String uid, double dailyRate) async {
    try {
      await _db.collection('client_profiles').doc(uid).update({
        'role': 'worker',
        'dailyRate': dailyRate,
      });
    } catch (e) {
      debugPrint('Error promoting user in Firestore: $e');
    }
  }

  Future<void> updateHomeLocation(double lat, double lng) async {
    if (_userData == null) return;
    try {
      await _db.collection('client_profiles').doc(_userData!.uid).update({
        'home_lat': lat,
        'home_lng': lng,
      });
      await fetchUserData();
    } catch (e) {
      debugPrint('Error updating home location in Firestore: $e');
    }
  }

  Future<bool> updateProfilePhoto(Uint8List bytes) async {
    if (_userData == null) return false;
    try {
      final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      await _db.collection('client_profiles').doc(_userData!.uid).update({
        'photo_url': base64Image,
      });
      await fetchUserData();
      return true;
    } catch (e) {
      debugPrint('Error uploading profile photo to Firestore: $e');
      return false;
    }
  }

  Future<List<AppUser>> getAllProfiles() async {
    try {
      final snap = await _db.collection('client_profiles').orderBy('full_name').get();
      return snap.docs.map((doc) => AppUser.fromMap(doc.data(), doc.id)).toList();
    } catch (e) {
      debugPrint('Error getting profiles from Firestore: $e');
      return [];
    }
  }
}
