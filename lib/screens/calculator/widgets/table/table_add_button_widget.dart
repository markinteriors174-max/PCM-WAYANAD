import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../theme/app_theme.dart';
import '../../../../providers/language_provider.dart';
import '../../calculator_controller.dart';
import '../quick_add_bottom_sheet.dart';

class TableAddButtonWidget extends StatelessWidget {
  final CalculatorController ctrl;

  const TableAddButtonWidget({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryButton,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
          ),
          icon: const Icon(Icons.add, size: 20),
          label: const Text('ADD MEASUREMENT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1)),
          onPressed: () {
            QuickAddBottomSheet.show(context, ctrl, lang);
          },
        ),
      ),
    );
  }
}
