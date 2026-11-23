// ignore_for_file: use_build_context_synchronously, avoid_print
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';
import 'subscription_service.dart';

class CashfreePaymentService {
  static final CashfreePaymentService instance = CashfreePaymentService._init();
  CashfreePaymentService._init();

  static const String appId = 'YOUR_CASHFREE_APP_ID';
  static const String secretKey = 'YOUR_CASHFREE_SECRET_KEY';
  static const String baseUrl = 'https://sandbox.cashfree.com/pg';

  /// Creates a Cashfree Order for ₹2,500 (365-day subscription)
  Future<Map<String, dynamic>?> createSubscriptionOrder({
    required String customerId,
    required String customerEmail,
    required String customerPhone,
  }) async {
    try {
      final orderId = 'pcm_sub_${DateTime.now().millisecondsSinceEpoch}';
      final url = Uri.parse('$baseUrl/orders');

      final body = jsonEncode({
        'order_id': orderId,
        'order_amount': 2500.00,
        'order_currency': 'INR',
        'customer_details': {
          'customer_id': customerId.isNotEmpty ? customerId : 'cust_${DateTime.now().millisecondsSinceEpoch}',
          'customer_email': customerEmail.isNotEmpty ? customerEmail : 'client@pcm.wayanad',
          'customer_phone': customerPhone.isNotEmpty ? customerPhone : '9383406185',
        },
        'order_meta': {
          'return_url': 'https://premier-ceiling-master-381b0.web.app/payment-success?order_id=$orderId',
        },
      });

      final response = await http.post(
        url,
        headers: {
          'x-client-id': appId,
          'x-client-secret': secretKey,
          'x-api-version': '2022-09-01',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data as Map<String, dynamic>;
      } else {
        debugPrint('Cashfree Order Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Cashfree Exception: $e');
      return null;
    }
  }

  /// Verifies order status and unlocks 1-year (365 days) subscription on success
  Future<bool> verifyAndUnlockSubscription(String orderId) async {
    try {
      final url = Uri.parse('$baseUrl/orders/$orderId');
      final response = await http.get(
        url,
        headers: {
          'x-client-id': appId,
          'x-client-secret': secretKey,
          'x-api-version': '2022-09-01',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final status = data['order_status']?.toString() ?? '';
        if (status.toUpperCase() == 'PAID') {
          await grantOneYearSubscription();
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Cashfree Verify Exception: $e');
      return false;
    }
  }

  /// Grants 1 year (365 days) of access to the currently signed-in user in Firestore
  Future<void> grantOneYearSubscription() async {
    final user = AuthService.instance.currentUser;
    if (user == null || user.uid.isEmpty) return;

    final paidUntilDate = DateTime.now().add(const Duration(days: 365));

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'paidUntil': Timestamp.fromDate(paidUntilDate),
        'subscriptionStatus': 'active_paid_year',
        'lastPaymentAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await FirebaseFirestore.instance.collection('client_profiles').doc(user.uid).set({
        'paidUntil': Timestamp.fromDate(paidUntilDate),
        'subscriptionStatus': 'active_paid_year',
      }, SetOptions(merge: true));

      debugPrint('PCM Subscription: Successfully unlocked 1-year access until $paidUntilDate');
    } catch (e) {
      debugPrint('Error granting subscription in Firestore: $e');
    }
  }

  /// Helper to check subscription status for current user with safe offline fallbacks
  Future<SubscriptionStatusResult> checkCurrentUserSubscription() async {
    final user = AuthService.instance.currentUser;
    if (user == null) {
      return const SubscriptionStatusResult(
        state: SubscriptionAccessState.lockedNeedPayment,
        daysRemainingInPhase: 0,
      );
    }

    if (user.email.trim().toLowerCase() == 'asmadhu299@gmail.com' || user.role.name == 'admin') {
      return const SubscriptionStatusResult(
        state: SubscriptionAccessState.adminUnrestricted,
        daysRemainingInPhase: 9999,
      );
    }

    DateTime accountStarted = DateTime.now().subtract(const Duration(days: 10));
    DateTime? paidUntil;

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get().timeout(const Duration(seconds: 4));
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data['createdAt'] != null && data['createdAt'] is Timestamp) {
          accountStarted = (data['createdAt'] as Timestamp).toDate();
        }
        if (data['paidUntil'] != null && data['paidUntil'] is Timestamp) {
          paidUntil = (data['paidUntil'] as Timestamp).toDate();
        }
      }

      final clientDoc = await FirebaseFirestore.instance.collection('client_profiles').doc(user.uid).get().timeout(const Duration(seconds: 4));
      if (clientDoc.exists && clientDoc.data() != null) {
        final data = clientDoc.data()!;
        if (data['paidUntil'] != null && data['paidUntil'] is Timestamp) {
          paidUntil ??= (data['paidUntil'] as Timestamp).toDate();
        }
      }
    } catch (e) {
      debugPrint('Error loading subscription status from Firestore: $e');
      // Safe fallback to free trial active so offline or timeout never blanks or locks out valid users
      return const SubscriptionStatusResult(
        state: SubscriptionAccessState.freeTrialActive,
        daysRemainingInPhase: 30,
      );
    }

    return evaluateSubscriptionStatus(
      userEmail: user.email,
      adminEmail: 'asmadhu299@gmail.com',
      accountStartedAt: accountStarted,
      paidUntil: paidUntil,
    );
  }
}
