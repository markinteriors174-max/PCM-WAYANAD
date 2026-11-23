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
        backgroundColor: AppColors.background,
        title: const Text('Add Payment', style: TextStyle(color: AppColors.labelColor, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: AppStyles.inputDecoration('Amount Received (₹)').copyWith(
                labelStyle: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                floatingLabelStyle: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.0),
              ),
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: noteCtrl,
              decoration: AppStyles.inputDecoration('Description (e.g. Advance)').copyWith(
                labelStyle: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                floatingLabelStyle: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.0),
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
              ),
              style: const TextStyle(color: Colors.black),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL', style: TextStyle(color: Colors.black54))),
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

        // ഹിസ്റ്ററി ലിസ്റ്റ് എംപ്റ്റി ആണെങ്കിൽ
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
                  return Container(
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
                          ],
                        ),
                        Text('₹ ${(payment['amount'] as double).toStringAsFixed(2)}', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                },
              ),
      ],
    );
  }
}
