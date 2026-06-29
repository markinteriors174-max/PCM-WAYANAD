// ignore_for_file: unused_field, unused_element, deprecated_member_use, use_build_context_synchronously, curly_braces_in_flow_control_structures, unused_local_variable, sort_child_properties_last, avoid_print, non_constant_identifier_names, avoid_web_libraries_in_flutter
import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../calculator_controller.dart';

class QuickAddBrandSelector extends StatelessWidget {
  final CalculatorController ctrl;
  final bool isCeilingDesign;

  const QuickAddBrandSelector({
    super.key,
    required this.ctrl,
    required this.isCeilingDesign,
  });

  @override
  Widget build(BuildContext context) {
    if (!isCeilingDesign) return const SizedBox.shrink();
    final brands = (ctrl.brandsMap[ctrl.selectedCeilingType] ?? ctrl.brandsMap['Gypsum Board']!).toSet().toList();
    
    // Safety: Ensure initial value exists in items to prevent Dropdown crash
    final initialBrand = (ctrl.selectedBrand != null && brands.contains(ctrl.selectedBrand)) 
        ? ctrl.selectedBrand 
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                key: ValueKey(ctrl.selectedCeilingType),
                isExpanded: true,
                value: initialBrand,
                decoration: AppStyles.inputDecoration('Brand Selection').copyWith(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                ),
                items: brands
                    .map((val) => DropdownMenuItem(
                          value: val,
                          child: Text(val, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis, maxLines: 1),
                        ))
                    .toList(),
                onChanged: (v) {
                  ctrl.selectedBrand = v;
                  ctrl.notifyUI();
                  ctrl.triggerAutoSave();
                },
              ),
            ),
          ],
        ),
        if (ctrl.selectedBrand == 'Other') ...[
          const SizedBox(height: 15),
          TextField(
            controller: ctrl.brandController,
            decoration: AppStyles.inputDecoration('Custom Brand'),
            style: const TextStyle(fontWeight: FontWeight.bold),
            onChanged: (_) => ctrl.triggerAutoSave(),
          ),
        ],
        const SizedBox(height: 15),
      ],
    );
  }
}
