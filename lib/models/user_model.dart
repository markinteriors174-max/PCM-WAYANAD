// Firebase Firestore scrubbed to prevent [core/no-app] crashes.
// Models updated to use fromMap instead of fromFirestore.

enum UserRole { admin, worker, agent, client }

class AppUser {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String? photoUrl;
  final UserRole role;
  final bool isApproved;
  
  // Role-specific fields
  final List<String> assignedSites;
  final double? commissionRate; // For Agents
  final double? dailyRate;      // For Workers
  final double? budget;         // For Clients
  final double? homeLat;        // For Travel Allowance
  final double? homeLng;
  final double? rating;         // For Workers
  final String? bonusInfo;      // For Workers

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    this.photoUrl,
    required this.role,
    this.isApproved = false,
    this.assignedSites = const [],
    this.commissionRate,
    this.dailyRate,
    this.budget,
    this.homeLat,
    this.homeLng,
    this.rating,
    this.bonusInfo,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'photo_url': photoUrl,
      'role': role.name,
      'isApproved': isApproved,
      'assignedSites': assignedSites,
      'commissionRate': commissionRate,
      'dailyRate': dailyRate,
      'budget': budget,
      'homeLat': homeLat,
      'homeLng': homeLng,
      'rating': rating,
      'bonus_info': bonusInfo,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> data, String uid) {
    return AppUser(
      uid: uid,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      photoUrl: data['photo_url'] ?? data['photoUrl'],
      role: UserRole.values.firstWhere(
        (e) => e.name == data['role'],
        orElse: () => UserRole.client,
      ),
      isApproved: data['isApproved'] ?? data['is_approved'] ?? false,
      assignedSites: List<String>.from(data['assignedSites'] ?? []),
      commissionRate: (data['commissionRate'] as num?)?.toDouble(),
      dailyRate: (data['dailyRate'] as num?)?.toDouble() ?? (data['daily_rate'] as num?)?.toDouble(),
      budget: (data['budget'] as num?)?.toDouble(),
      homeLat: (data['homeLat'] as num?)?.toDouble() ?? (data['home_lat'] as num?)?.toDouble(),
      homeLng: (data['homeLng'] as num?)?.toDouble() ?? (data['home_lng'] as num?)?.toDouble(),
      rating: (data['rating'] as num?)?.toDouble() ?? 5.0,
      bonusInfo: data['bonus_info'] ?? data['bonusInfo'],
    );
  }
}
