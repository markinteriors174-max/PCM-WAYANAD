import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';
import '../../calculator/calculator_controller.dart';
import '../../../providers/language_provider.dart';
import '../../../models/quotation.dart';

class CalculatorPaymentsWidget extends StatelessWidget {
  final CalculatorController ctrl;
  final LanguageProvider lang;

  const CalculatorPaymentsWidget({super.key, required this.ctrl, required this.lang});

  void _showAddPaymentDialog(BuildContext context) {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController(text: 'Installment');
    final dateCtrl = TextEditingController(text: DateFormat('dd-MM-yyyy hh:mm a').format(DateTime.now()));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Add Payment', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: AppStyles.inputDecoration('Amount Received (₹)').copyWith(
                labelStyle: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                floatingLabelStyle: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                fillColor: Colors.grey.shade100,
                filled: true,
              ),
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: noteCtrl,
              decoration: AppStyles.inputDecoration('Description (e.g. Advance)').copyWith(
                labelStyle: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                floatingLabelStyle: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                fillColor: Colors.grey.shade100,
                filled: true,
              ),
              style: const TextStyle(color: Colors.black),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: dateCtrl,
              decoration: AppStyles.inputDecoration('Date & Time').copyWith(
                suffixIcon: const Icon(Icons.calendar_today, size: 16, color: Colors.black54),
                labelStyle: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                floatingLabelStyle: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                fillColor: Colors.grey.shade100,
                filled: true,
              ),
              style: const TextStyle(color: Colors.black),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold))),
          ElevatedButton(
            onPressed: () {
              final amt = double.tryParse(amountCtrl.text);
              if (amt == null || amt <= 0) return;
              ctrl.addPayment(PaymentRecord(
                id: null,
                quotationId: ctrl.activeProjectId,
                description: noteCtrl.text.trim(),
                date: dateCtrl.text.trim(),
                amount: amt,
              ));
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryButton,
              foregroundColor: Colors.white,
            ),
            child: const Text('SAVE PAYMENT'),
          ),
        ],
      ),
    );
  }

  void _showDeletePaymentDialog(BuildContext context, int index, PaymentRecord payment) {
    final clientIdCtrl = TextEditingController();
    final expectedClientId = ctrl.unitNumberController.text.trim();
    final cleanExpected = expectedClientId.replaceAll('#', '').trim().toLowerCase();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateModal) {
          clientIdCtrl.addListener(() {
            if (context.mounted) setStateModal(() {});
          });

          final typedVal = clientIdCtrl.text.trim().toLowerCase();
          final cleanTyped = typedVal.replaceAll('#', '').trim();
          final bool matches = typedVal.isNotEmpty && (
            typedVal == expectedClientId.toLowerCase() ||
            cleanTyped == cleanExpected ||
            (ctrl.activeProjectId != null && typedVal == ctrl.activeProjectId.toString().toLowerCase())
          );

          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 22),
                const SizedBox(width: 8),
                const Text('Confirm Payment Deletion', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w900, fontSize: 16)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'To securely delete payment of ₹ ${payment.amount.toStringAsFixed(2)} (${payment.description}), please type or paste Client ID ($expectedClientId):',
                  style: const TextStyle(color: Color(0xFF1E293B), fontSize: 12.5, fontWeight: FontWeight.bold, height: 1.4),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: clientIdCtrl,
                  autofocus: true,
                  decoration: AppStyles.inputDecoration('Enter Client ID (e.g. $expectedClientId)').copyWith(
                    labelStyle: const TextStyle(color: Colors.black87, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                    floatingLabelStyle: const TextStyle(color: Colors.black87, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                    fillColor: Colors.grey.shade100,
                    filled: true,
                  ),
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
                  onChanged: (_) => setStateModal(() {}),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCEL', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                onPressed: matches
                    ? () {
                        if (index >= 0 && index < ctrl.currentPayments.length) {
                          ctrl.currentPayments.removeAt(index);
                          ctrl.updateProjectTotals();
                          ctrl.triggerAutoSave();
                        }
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Payment record deleted and balances recalculated.'), backgroundColor: AppColors.resultGreen),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  disabledForegroundColor: Colors.grey.shade600,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('CONFIRM DELETE', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final paymentHistoryList = ctrl.currentPayments.map((p) => {
      'title': p.description.isNotEmpty ? p.description.toUpperCase() : 'PAYMENT RECEIVED',
      'date': p.date,
      'amount': p.amount,
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('PAYMENT HISTORY', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            TextButton.icon(
              onPressed: () => _showAddPaymentDialog(context),
              icon: const Icon(Icons.add_circle, color: Colors.greenAccent, size: 16),
              label: const Text('ADD PAYMENT', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 11)),
            ),
          ],
        ),
        const SizedBox(height: 8),

        paymentHistoryList.isEmpty
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text('No payments recorded yet.', style: TextStyle(color: Colors.grey)),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: paymentHistoryList.length,
                itemBuilder: (context, index) {
                  final payment = paymentHistoryList[index];
                  return InkWell(
                    onLongPress: () => _showDeletePaymentDialog(context, index, ctrl.currentPayments[index]),
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[850],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(payment['title'] as String? ?? 'PAYMENT RECEIVED', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text(payment['date'] as String? ?? '', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                              const SizedBox(height: 2),
                              const Text('(Long-press to delete securely)', style: TextStyle(color: Colors.white30, fontSize: 9, fontStyle: FontStyle.italic)),
                            ],
                          ),
                          Text('₹ ${(payment['amount'] as double).toStringAsFixed(2)}', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ],
    );
  }
}
