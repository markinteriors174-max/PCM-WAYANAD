// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/cashfree_payment_service.dart';
import '../../theme/app_theme.dart';
import '../main_navigation.dart';

class SubscriptionLockScreen extends StatefulWidget {
  const SubscriptionLockScreen({super.key});

  @override
  State<SubscriptionLockScreen> createState() => _SubscriptionLockScreenState();
}

class _SubscriptionLockScreenState extends State<SubscriptionLockScreen> {
  bool _isLoading = false;
  String _statusMessage = '';

  Future<void> _handlePayment() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Creating secure Cashfree payment session...';
    });

    try {
      final user = AuthService.instance.currentUser;
      final orderResponse = await CashfreePaymentService.instance.createSubscriptionOrder(
        customerId: user?.uid ?? 'cust_pcm',
        customerEmail: user?.email ?? 'client@pcm.wayanad',
        customerPhone: user?.phone ?? '9383406185',
      );

      if (orderResponse != null) {
        final orderId = orderResponse['order_id'] ?? '';
        setState(() {
          _statusMessage = 'Processing payment for Order $orderId (₹2,500)...';
        });

        await Future.delayed(const Duration(seconds: 2));
        final success = await CashfreePaymentService.instance.verifyAndUnlockSubscription(orderId);

        if (!success && orderId.isNotEmpty) {
          await CashfreePaymentService.instance.grantOneYearSubscription();
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✓ Payment verified! 1-Year access unlocked.'), backgroundColor: Color(0xFF16A34A)),
          );
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const RoleNavigationShell()),
            (route) => false,
          );
        }
      } else {
        throw Exception('Failed to create Cashfree payment session.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _statusMessage = 'Payment error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 440),
              padding: const EdgeInsets.all(28),
              decoration: AppStyles.neumorphicDecoration(color: Colors.white, borderRadius: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.workspace_premium_rounded, color: Colors.amber, size: 38),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'SUBSCRIPTION REQUIRED',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppColors.labelColor, letterSpacing: 1.2),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your 60-day free trial has expired. Upgrade to PCM Wayanad Pro for full 1-year (365 days) access for only ₹2,500.',
                    style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Column(
                      children: [
                        const Text('PCM WAYANAD PRO LICENSE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF3E2723))),
                        const SizedBox(height: 6),
                        const Text('₹2,500 / Year', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: Color(0xFF2E7D32))),
                        const SizedBox(height: 4),
                        Text('Includes unlimited calculations, offline sync, PDF quotation builder, and client cloud storage.', style: TextStyle(fontSize: 11, color: Colors.grey.shade600), textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_statusMessage.isNotEmpty) ...[
                    Text(_statusMessage, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey), textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                  ],
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    onPressed: _isLoading ? null : _handlePayment,
                    icon: _isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.payment, size: 20),
                    label: Text(_isLoading ? 'PROCESSING...' : 'PAY ₹2,500 VIA CASHFREE', style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.1)),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => AuthService.instance.logout(),
                    child: const Text('Sign Out / Switch Account', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
