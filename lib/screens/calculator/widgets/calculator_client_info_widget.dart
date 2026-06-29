import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../calculator/calculator_controller.dart';
import '../../../providers/language_provider.dart';
import '../project_edit_controller.dart';
import 'qr_scanner_screen.dart';

class CalculatorClientInfoWidget extends StatelessWidget {
  final CalculatorController ctrl;
  final LanguageProvider lang;

  const CalculatorClientInfoWidget({super.key, required this.ctrl, required this.lang});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(children: [
        Expanded(
          child: TextField(
            controller: ctrl.unitNumberController, 
            decoration: AppStyles.inputDecoration('Project ID'), 
            onChanged: (val) => ctrl.onClientInfoChanged(val, 'id')
          )
        ),
        const SizedBox(width: 10),
        IconButton(
          icon: const Icon(Icons.qr_code_scanner, color: AppColors.border),
          onPressed: () async {
            final String? scannedValue = await Navigator.push<String>(
              context,
              MaterialPageRoute(builder: (_) => const QRScannerScreen()),
            );
            if (scannedValue == null || scannedValue.isEmpty) return;

            if (context.mounted) {
              ProjectEditController.handleScannedQRCode(context, scannedValue);
            }
          },
        ),
      ]),
      const SizedBox(height: 15),
      TextField(
        controller: ctrl.clientNameController, 
        decoration: AppStyles.inputDecoration(lang.isMalayalam ? 'കസ്റ്റമർ പേര്' : 'Customer Name'), 
        onChanged: (val) => ctrl.onClientInfoChanged(val, 'name')
      ),
      const SizedBox(height: 15),
      Row(children: [
        Expanded(
          flex: 3, 
          child: TextField(
            controller: ctrl.clientLocationController, 
            decoration: AppStyles.inputDecoration(lang.isMalayalam ? 'സ്ഥലം' : 'Location'), 
            onChanged: (val) => ctrl.onClientInfoChanged(val, 'location')
          )
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2, 
          child: TextField(
            controller: ctrl.clientPhoneController, 
            keyboardType: TextInputType.phone, 
            decoration: AppStyles.inputDecoration('Phone'), 
            onChanged: (val) => ctrl.onClientInfoChanged(val, 'phone')
          )
        ),
      ]),
    ]);
  }
}
