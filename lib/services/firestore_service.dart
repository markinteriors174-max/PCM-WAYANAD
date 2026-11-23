import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirestoreService {
  static final FirestoreService instance = FirestoreService._();
  FirestoreService._();

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  Future<void> saveQuotationToDatabase({
    required String quoteId,
    required String clientName,
    required double totalAmount,
    required List<Map<String, dynamic>> items,
    required String partnerName,
    required String partnerPhone,
    required String partnerLocation,
  }) async {
    try {
      final payload = {
        'quoteId': quoteId,
        'clientName': clientName,
        'totalAmount': totalAmount,
        'items': items,
        'createdAt': FieldValue.serverTimestamp(),
        'partnerInfo': {
          'name': partnerName,
          'phone': partnerPhone,
          'location': partnerLocation,
        },
        'partnerName': partnerName,
        'partnerPhone': partnerPhone,
        'partnerLocation': partnerLocation,
      };

      await _db.collection('quotations').doc(quoteId).set(payload, SetOptions(merge: true));

      final cleanDocId = quoteId.replaceAll('#', '').trim();
      if (cleanDocId.isNotEmpty && cleanDocId != quoteId) {
        await _db.collection('quotations').doc(cleanDocId).set(payload, SetOptions(merge: true)).catchError((e) {
          debugPrint('Notice syncing clean doc ID to cloud: $e');
        });
      }

      debugPrint('Quotation successfully saved and bound with partner: $partnerName');
    } catch (e) {
      debugPrint('Error saving quotation: $e');
    }
  }

  Future<Map<String, dynamic>?> fetchQuotationDetails(String quoteId) async {
    try {
      final cleanId = quoteId.trim();
      DocumentSnapshot doc = await _db.collection('quotations').doc(cleanId).get();

      if (!doc.exists) {
        final altId = cleanId.startsWith('#')
            ? cleanId.replaceFirst('#', '').trim()
            : '# $cleanId';
        doc = await _db.collection('quotations').doc(altId).get();
      }

      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?;
      } else {
        debugPrint('No quotation found for ID: $quoteId');
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching quotation: $e');
      return null;
    }
  }

  Future<void> saveProjectToCloud(Map<String, dynamic> payload) async {
    try {
      final unitNumber = payload['unitNumber'] ?? payload['unit_number'];
      if (unitNumber != null && unitNumber.toString().isNotEmpty) {
        await _db.collection('quotations').doc(unitNumber.toString()).set(payload, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Firestore save error: $e');
    }
  }

  Future<void> saveOrUpdateUserData(Map<String, dynamic> payload) async {
    try {
      final email = payload['email'] ?? payload['phone'];
      if (email != null && email.toString().isNotEmpty) {
        await _db.collection('contacts').doc(email.toString()).set(payload, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Firestore contact save error: $e');
    }
  }
}

Future<void> saveQuotationToDatabase({
  required String quoteId,
  required String clientName,
  required double totalAmount,
  required List<Map<String, dynamic>> items,
  required String partnerName,
  required String partnerPhone,
  required String partnerLocation,
}) => FirestoreService.instance.saveQuotationToDatabase(
  quoteId: quoteId,
  clientName: clientName,
  totalAmount: totalAmount,
  items: items,
  partnerName: partnerName,
  partnerPhone: partnerPhone,
  partnerLocation: partnerLocation,
);

Future<Map<String, dynamic>?> fetchQuotationDetails(String quoteId) =>
    FirestoreService.instance.fetchQuotationDetails(quoteId);

Future<void> saveOrUpdateUserData({
  required String phoneNumber,
  required String fullName,
  String? siteDetails,
  Map<String, dynamic>? additionalData,
}) async {
  try {
    final payload = {
      'phone': phoneNumber,
      'name': fullName,
      'siteDetails': siteDetails,
      ...?additionalData,
    };
    await FirebaseFirestore.instance.collection('contacts').doc(phoneNumber).set(payload, SetOptions(merge: true));
  } catch (e) {
    debugPrint('saveOrUpdateUserData error: $e');
  }
}
