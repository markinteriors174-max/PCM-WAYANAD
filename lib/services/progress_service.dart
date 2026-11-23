import 'package:flutter/foundation.dart';

// Firebase Firestore & Storage scrubbed to prevent [core/no-app] crashes.
// Progress photos logic is now disabled or local-only.

class ProgressImage {
  final String id;
  final String url;
  final String uploaderId;
  final String uploaderName;
  final String siteId;
  final DateTime timestamp;

  ProgressImage({
    required this.id,
    required this.url,
    required this.uploaderId,
    required this.uploaderName,
    required this.siteId,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'uploaderId': uploaderId,
      'uploaderName': uploaderName,
      'siteId': siteId,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ProgressImage.fromMap(Map<String, dynamic> data, String id) {
    return ProgressImage(
      id: id,
      url: data['url'] ?? '',
      uploaderId: data['uploaderId'] ?? '',
      uploaderName: data['uploaderName'] ?? '',
      siteId: data['siteId'] ?? '',
      timestamp: DateTime.parse(data['timestamp']),
    );
  }
}

class ProgressService {
  static final ProgressService instance = ProgressService._init();
  ProgressService._init();

  Future<void> uploadSitePhoto({
    required dynamic imageFile, // Use dynamic to avoid dart:io dependency
    required String uploaderId,
    required String uploaderName,
    required String siteId,
  }) async {
    debugPrint('ProgressService: Local Mode (Stub) - Image would be saved to $siteId');
  }

  Stream<List<ProgressImage>> getSiteGallery(String siteId) {
    return Stream.value([]);
  }

  Stream<List<ProgressImage>> getAllRecentProgress() {
    return Stream.value([]);
  }
}
