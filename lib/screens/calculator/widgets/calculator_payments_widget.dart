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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('PAYMENT HISTORY', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5, color: AppColors.labelColor)),
            TextButton.icon(
              onPressed: () => _showAddPaymentDialog(context),
              icon: const Icon(Icons.add_circle, color: AppColors.resultGreen, size: 16),
              label: const Text('ADD PAYMENT', style: TextStyle(color: AppColors.resultGreen, fontWeight: FontWeight.bold, fontSize: 10)),
            ),
          ],
        ),
        if (ctrl.currentPayments.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppStyles.neumorphicDecoration(color: AppColors.border),
            child: const Center(child: Text('No payments recorded yet.', style: TextStyle(color: Colors.white54))),
          )
        else
          Container(
            padding: const EdgeInsets.all(15),
            decoration: AppStyles.neumorphicDecoration(color: AppColors.border),
            child: Column(
              children: ctrl.currentPayments.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.description.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                          Text(p.date, style: const TextStyle(color: Colors.white54, fontSize: 10)),
                        ],
                      ),
                    ),
                    Text('₹${p.amount.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.resultGreen, fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
              )).toList(),
            ),
          ),
      ],
    );
  }
}
