import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../quotation_preview_controller.dart';
import '../../../utils/calculator_utils.dart';

class QuotationBodyWidget extends StatelessWidget {
  final QuotationPreviewController ctrl;
  final VoidCallback onStateChanged;

  const QuotationBodyWidget({super.key, required this.ctrl, required this.onStateChanged});

  void _showAddPaymentDialog(BuildContext context) {
    final descCtrl = TextEditingController(text: 'Payment');
    final amtCtrl = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Payment', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: descCtrl, 
              style: const TextStyle(color: Colors.black),
              decoration: const InputDecoration(
                labelText: 'Description (e.g. Advance)',
                labelStyle: TextStyle(color: Colors.black),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.black54)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.black)),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: amtCtrl, 
              style: const TextStyle(color: Colors.black),
              decoration: const InputDecoration(
                labelText: 'Amount',
                labelStyle: TextStyle(color: Colors.black),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.black54)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.black)),
              ), 
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              await ctrl.addPayment(descCtrl.text, amtCtrl.text);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('ADD'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (ctrl.currentQuotation == null) return const Center(child: Text('Please save a project first.'));

    final q = ctrl.currentQuotation!;
    final total = q.totalAmount;
    final advance = ctrl.payments.fold(0.0, (s, p) => s + p.amount);
    final balance = total - advance;

    return Container(
      padding: const EdgeInsets.all(25),
      decoration: AppStyles.neumorphicDecoration(color: Colors.white, hasThickBorder: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50.withValues(alpha: 0.3),
              border: Border.all(color: Colors.blue.shade100, width: 1.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(Icons.person, color: Color(0xFF1A365D), size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'CLIENT:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: ctrl.nameController,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Color(0xFF1A365D), // Premium Dark Blue
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Enter Client Name',
                          hintStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: Colors.black26),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 4),
                          border: InputBorder.none,
                        ),
                        onChanged: (_) => onStateChanged(),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20, color: Colors.black12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.square_foot, color: Color(0xFF1A365D), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          q.includeWastage ? 'GRAND TOTAL AREA:' : 'TOTAL AREA:',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.yellow.shade100.withValues(alpha: 0.8), // Soft yellow highlight box
                        border: Border.all(color: Colors.yellow.shade400, width: 1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${(q.items.fold(0.0, (sum, item) => sum + CalculatorUtils.getNormalizedAreaSqFt(item)) * (q.includeWastage ? 1.05 : 1.0)).toStringAsFixed(2)} SqFt',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF1A365D), // Match the Dark Blue theme color
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (q.discount > 3.0) ...[
            const SizedBox(height: 15),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200, width: 1),
              ),
              child: const Text(
                'ഡിസ്കൗണ്ട് 3% പരിധി കവിഞ്ഞു! ഷെയറിംഗ് പ്രവർത്തനരഹിതമാക്കി.',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          const SizedBox(height: 16),
          _buildEditableDetailRow('MOBILE NUMBER', ctrl.mobileController, 'Enter Mobile Number'),
          _buildEditableDetailRow('SITE / LOCATION', ctrl.locationController, 'Enter Site Details'),
          const Divider(height: 40),
          ...q.items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(item.roomName, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.labelColor))),
                Text('₹${CalculatorUtils.formatIndianCurrency(item.amount)}', style: const TextStyle(fontWeight: FontWeight.w900)),
              ],
            ),
          )),
          const Divider(height: 40),
          if (q.discount > 0) ...[
            _buildPriceRow('SUBTOTAL', total + (q.discount > 0 && q.discount < 100 ? total * q.discount / (100 - q.discount) : 0.0), color: AppColors.labelColor),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('DISCOUNT AMOUNT', style: TextStyle(fontWeight: FontWeight.w900, color: q.discount <= 3.0 ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F), fontSize: 12)),
                Text(
                  '-₹${CalculatorUtils.formatIndianCurrency(q.discount > 0 && q.discount < 100 ? total * q.discount / (100 - q.discount) : 0.0)}',
                  style: TextStyle(fontWeight: FontWeight.w900, color: q.discount <= 3.0 ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F), fontStyle: FontStyle.italic, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildPriceRow('TOTAL AMOUNT', total, color: AppColors.labelColor),
          ] else ...[
            _buildPriceRow('TOTAL AMOUNT', total, color: AppColors.labelColor),
          ],
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('PAYMENT HISTORY', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey, fontSize: 12)),
              TextButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('ADD PAYMENT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                onPressed: () => _showAddPaymentDialog(context),
              )
            ],
          ),
          ...ctrl.payments.map((p) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${p.date.split(' ').first} | ${p.description}', style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.bold)),
                Text('₹${CalculatorUtils.formatIndianCurrency(p.amount)}', style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.blueGrey)),
              ]
            ),
          )),
          const Divider(height: 30),
          _buildPriceRow('BALANCE DUE', balance, color: AppColors.resultGreen, isLarge: true),
        ],
      ),
    );
  }

  Widget _buildEditableDetailRow(String label, TextEditingController controller, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black45)),
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppColors.border),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Colors.black26),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
                border: InputBorder.none,
              ),
              onChanged: (_) => onStateChanged(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {required Color color, bool isLarge = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: isLarge ? 14 : 12)),
        Text('₹${CalculatorUtils.formatIndianCurrency(amount)}', style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: isLarge ? 24 : 18)),
      ],
    );
  }
}
