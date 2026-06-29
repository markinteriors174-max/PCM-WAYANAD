// ignore_for_file: unused_field, unused_element, deprecated_member_use, use_build_context_synchronously, curly_braces_in_flow_control_structures, unused_local_variable, sort_child_properties_last, avoid_print, non_constant_identifier_names, avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import '../models/user_model.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'database_service.dart';

class AuthService extends ChangeNotifier {
  static final AuthService instance = AuthService._init();
  AuthService._init();

  // final _secureStorage = const FlutterSecureStorage(); // Removed to avoid web issues
  AppUser? _userData;
  AppUser? get userData => _userData;
  AppUser? get currentUser => _userData;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  Timer? _rolePollingTimer;
  static const String _supabaseUrl = 'https://pNZYGMVENSMRZQPOBWTK.supabase.co/rest/v1';
  static const String _supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBuenlnbXZlbnNtcnpxcG9id3RrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE5NjIwODcsImV4cCI6MjA5NzUzODA4N30.lqCFxRcTGe4xGZ9gT4vYzurfNY-aLQvCL4tLBv9HF0k2';

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
    final savedUid = await _readData('user_uid');
    final isDevMaster = (await _readData('isDevMaster')) == 'true';

    if (isDevMaster) {
      _userData = AppUser(
        uid: 'master-admin-bypass',
        name: 'Madhusudhan (Master)',
        email: 'asmadhu299@gmail.com',
        phone: '9383406185',
        role: UserRole.admin,
        isApproved: true,
      );
    } else if (savedUid != null) {
      await fetchUserData(savedUid);
    }

    if (_userData != null) {
      startRoleMonitoring();
    }

    _isInitialized = true;
    notifyListeners();
  }

  void startRoleMonitoring() {
    if (kIsWeb) return;
    _rolePollingTimer?.cancel();
    _rolePollingTimer = Timer.periodic(const Duration(seconds: 10), (_) => _pollRoleChange());
  }

  void stopRoleMonitoring() {
    _rolePollingTimer?.cancel();
    _rolePollingTimer = null;
  }

  Future<void> _pollRoleChange() async {
    if (_userData == null || _userData!.uid.startsWith('dev-')) return;
    try {
      final uri = Uri.parse('$_supabaseUrl/client_profiles?id=eq.${_userData!.uid}&select=role,is_approved');
      final response = await http.get(uri, headers: {
        'apikey': _supabaseKey,
        'Authorization': 'Bearer $_supabaseKey',
      });
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          final String newRoleStr = data[0]['role'];
          final bool newApproval = data[0]['is_approved'] ?? false;
          final UserRole newRole = UserRole.values.firstWhere(
            (e) => e.name == newRoleStr,
            orElse: () => _userData!.role,
          );
          if (newRole != _userData!.role || newApproval != _userData!.isApproved) {
            await fetchUserData(_userData!.uid);
          }
        }
      }
    } catch (e) {
      debugPrint('Error polling role: $e');
    }
  }

  Future<void> fetchUserData([String? uid]) async {
    final targetUid = uid ?? _userData?.uid;
    if (targetUid == null || targetUid.startsWith('dev-')) return;
    try {
      final uri = Uri.parse('$_supabaseUrl/client_profiles?id=eq.$targetUid&select=*');
      final response = await http.get(uri, headers: {
        'apikey': _supabaseKey,
        'Authorization': 'Bearer $_supabaseKey',
      });
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          final map = Map<String, dynamic>.from(data[0]);
          _userData = AppUser.fromMap(map, map['id']);
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
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

      // 1. STRICT QUERY: client_profiles table using Phone and PIN (unit_number)
      final String queryFilter = 'phone=eq.$mobile&or=(unit_number.eq.$fullId,unit_number.eq.$cleanPin)';
      final uri = Uri.parse('$_supabaseUrl/client_profiles?$queryFilter&select=*');
      
      final response = await http.get(uri, headers: {
        'apikey': _supabaseKey,
        'Authorization': 'Bearer $_supabaseKey',
      });

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          final p = Map<String, dynamic>.from(data[0]);
          _userData = AppUser.fromMap(p, p['id']);
          await _writeData('user_uid', _userData!.uid);
          startRoleMonitoring();
        } else {
          // 2. FALLBACK: Clients table for legacy support
          final clientFilter = 'phone_number=eq.$mobile&or=(unitNumber.eq.$fullId,unitNumber.eq.$cleanPin)';
          final clientUri = Uri.parse('$_supabaseUrl/clients?$clientFilter&select=*');
          final clientRes = await http.get(clientUri, headers: {'apikey': _supabaseKey, 'Authorization': 'Bearer $_supabaseKey'});
          
          if (clientRes.statusCode == 200) {
            final List<dynamic> clients = jsonDecode(clientRes.body);
            if (clients.isNotEmpty) {
               final c = clients[0];
               _userData = AppUser(
                 uid: 'legacy-${c['unitNumber']}',
                 name: c['client_name'] ?? 'PCM User',
                 email: '',
                 phone: mobile,
                 role: UserRole.client,
                 isApproved: true,
                 assignedSites: [c['unitNumber'].toString()],
               );
               await _writeData('user_uid', _userData!.uid);
               return;
            }
          }
          throw Exception('Invalid Mobile Number or PIN.');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
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
        
        // Background: try to ensure this profile exists in Supabase so other queries don't fail
        _ensureAdminProfileExists(cleanEmail);

        _isLoading = false;
        notifyListeners();
        return;
      }

      // 2. REMOTE CHECK: Fallback to Supabase if not bypassed
      final uri = Uri.parse('$_supabaseUrl/client_profiles?email=eq.$cleanEmail&role=eq.admin&select=*');
      
      final response = await http.get(uri, headers: {
        'apikey': _supabaseKey,
        'Authorization': 'Bearer $_supabaseKey',
      });

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          final p = Map<String, dynamic>.from(data[0]);
          
          if (password == 'admin123' || password == 'pcm2025') {
            _userData = AppUser.fromMap(p, p['id']);
            await _writeData('user_uid', _userData!.uid);
            await _writeData('isDevMaster', 'false');
            startRoleMonitoring();
          } else {
            throw Exception('Incorrect Password.');
          }
        } else {
          throw Exception('Admin account not found.');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
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
      
      await http.post(
        Uri.parse('$_supabaseUrl/client_profiles'),
        headers: {
          'apikey': _supabaseKey,
          'Authorization': 'Bearer $_supabaseKey',
          'Content-Type': 'application/json',
          'Prefer': 'resolution=merge-duplicates'
        },
        body: jsonEncode(payload),
      );
    } catch (e) {
      debugPrint('Silent profile upsert failed: $e');
    }
  }

  Future<void> logout() async {
    stopRoleMonitoring();
    await _clearAllData();
    if (!kIsWeb) {
      await DatabaseService.instance.wipeAllData();
    }
    _userData = null;
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

    print('PCM_DEBUG: Starting registration for $name ($fullUnitId)');

    try {
      final clientUri = Uri.parse('$_supabaseUrl/clients');
      
      final Map<String, dynamic> clientPayload = {
        'unitNumber': int.parse(pinDigits), // STRICT BIGINT/INT
        'client_name': name,
        'phone_number': phone,
        'site_location': location,
      };

      print('PCM_DEBUG: Posting to /clients (STRICT SCHEMA)...');
      final response = await http.post(
        clientUri, 
        headers: {
          'apikey': _supabaseKey, 
          'Authorization': 'Bearer $_supabaseKey', 
          'Content-Type': 'application/json', 
          'Prefer': 'return=minimal'
        }, 
        body: jsonEncode(clientPayload)
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('PCM_DEBUG: Client insert success.');
      } else {
        throw Exception('Supabase Rejection: ${response.statusCode} - ${response.body}');
      }

      // 3. Map to client_profiles for session management (using snake_case)
      final profilePayload = {
        'id': uuid,
        'full_name': name,
        'phone': phone,
        'email': guestEmail,
        'role': 'client',
        'is_approved': true,
        'unit_number': fullUnitId, // Mirroring the ID for display
      };
      
      await http.post(
        Uri.parse('$_supabaseUrl/client_profiles'),
        headers: {
          'apikey': _supabaseKey, 
          'Authorization': 'Bearer $_supabaseKey', 
          'Content-Type': 'application/json', 
          'Prefer': 'resolution=merge-duplicates'
        },
        body: jsonEncode(profilePayload),
      ).timeout(const Duration(seconds: 15));

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
      print('PCM_DEBUG: REGISTRATION EXCEPTION: $e');
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
      final uri = Uri.parse('$_supabaseUrl/rpc/promote_to_worker');
      await http.post(uri, headers: {'apikey': _supabaseKey, 'Authorization': 'Bearer $_supabaseKey', 'Content-Type': 'application/json'}, body: jsonEncode({'target_user_id': uid, 'new_daily_rate': dailyRate, 'admin_id': _userData?.uid ?? 'system-admin'}));
    } catch (e) {
      debugPrint('Error promoting user: $e');
    }
  }

  Future<void> updateHomeLocation(double lat, double lng) async {
    if (_userData == null) return;
    try {
      final uri = Uri.parse('$_supabaseUrl/client_profiles?id=eq.${_userData!.uid}');
      await http.patch(uri, headers: {'apikey': _supabaseKey, 'Authorization': 'Bearer $_supabaseKey', 'Content-Type': 'application/json'}, body: jsonEncode({'home_lat': lat, 'home_lng': lng}));
      await fetchUserData();
    } catch (e) {
      debugPrint('Error updating home location: $e');
    }
  }

  Future<bool> updateProfilePhoto(Uint8List bytes) async {
    if (_userData == null) return false;
    try {
      final fileName = 'avatar_${_userData!.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final uploadUrl = 'https://pNZYGMVENSMRZQPOBWTK.supabase.co/storage/v1/object/contracts/profiles/$fileName';
      final response = await http.put(Uri.parse(uploadUrl), headers: {'apikey': _supabaseKey, 'Authorization': 'Bearer $_supabaseKey', 'Content-Type': 'image/jpeg', 'x-upsert': 'true'}, body: bytes);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final publicUrl = 'https://pNZYGMVENSMRZQPOBWTK.supabase.co/storage/v1/object/public/contracts/profiles/$fileName';
        await http.patch(Uri.parse('$_supabaseUrl/client_profiles?id=eq.${_userData!.uid}'), headers: {'apikey': _supabaseKey, 'Authorization': 'Bearer $_supabaseKey', 'Content-Type': 'application/json'}, body: jsonEncode({'photo_url': publicUrl}));
        await fetchUserData();
        return true;
      }
    } catch (e) {
      debugPrint('Error uploading profile photo: $e');
    }
    return false;
  }

  Future<List<AppUser>> getAllProfiles() async {
    try {
      final uri = Uri.parse('$_supabaseUrl/client_profiles?select=*&order=full_name.asc');
      final response = await http.get(uri, headers: {'apikey': _supabaseKey, 'Authorization': 'Bearer $_supabaseKey'});
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((map) => AppUser.fromMap(map, map['id'])).toList();
      }
    } catch (e) {
      debugPrint('Error getting profiles: $e');
    }
    return [];
  }
}
