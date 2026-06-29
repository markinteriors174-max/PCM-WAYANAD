// ignore_for_file: unused_field, unused_element, deprecated_member_use, use_build_context_synchronously, curly_braces_in_flow_control_structures, unused_local_variable, sort_child_properties_last, avoid_print, non_constant_identifier_names, avoid_web_libraries_in_flutter
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../calculator/calculator_controller.dart';
import '../../../providers/language_provider.dart';
import 'quick_add_bottom_sheet.dart';

class CalculatorInputsWidget extends StatelessWidget {
  final CalculatorController ctrl;
  final LanguageProvider lang;
  final VoidCallback onStateChanged;

  const CalculatorInputsWidget({
    super.key,
    required this.ctrl,
    required this.lang,
    required this.onStateChanged,
  });

  void _showAddDialog(BuildContext context, String title, Function(String) onAdd) {
    final tCtrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text('Add New $title', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      content: TextField(controller: tCtrl, decoration: AppStyles.inputDecoration('Enter $title name'), autofocus: true),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryButton),
          onPressed: () {
            final val = tCtrl.text.trim();
            if (val.isNotEmpty) {
              onAdd(val);
            }
            Navigator.pop(ctx);
          },
          child: const Text('ADD', style: TextStyle(color: Colors.white)),
        ),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(child: Builder(
            builder: (context) {
              final ceilingItems = ctrl.ceilingTypes.keys.toSet().toList();
              
              // Standardize value
              String? currentValue = ctrl.selectedCeilingType;
              if (currentValue?.toLowerCase() == 'gypsum' || currentValue?.toLowerCase() == 'gypsum board') {
                currentValue = 'Gypsum Board';
              }
              if (currentValue?.toLowerCase() == 'pvc ceiling' || currentValue?.toLowerCase() == 'pvc board') {
                currentValue = 'PVC Board';
              }

              // Safety: Ensure selected value exists in items to prevent Dropdown crash
              final initialCeiling = (currentValue != null && ceilingItems.contains(currentValue)) 
                  ? currentValue
                  : null;

              return DropdownButtonFormField<String>(
                isExpanded: true,
                value: initialCeiling,
                decoration: AppStyles.inputDecoration(lang.translate('CEILING')).copyWith(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                ),
                items: ceilingItems.map((val) => DropdownMenuItem(
                  value: val, 
                  child: Text(
                    val, 
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  )
                )).toList(),
                onChanged: (v) { 
                  ctrl.selectedCeilingType = v; 
                  ctrl.selectedBrand = null; 
                  if (v != null) {
                    final defRate = ctrl.getDefaultRate(v);
                    if (defRate > 0) {
                      ctrl.rateController.text = defRate.toString();
                    }
                  }
                  if (v == 'Gypsum Board') {
                    ctrl.unit = 'SqFt';
                    ctrl.lengthController.text = '4';
                    ctrl.widthController.text = '6';
                  }
                  ctrl.updateLivePreview();
                  onStateChanged();
                },
              );
            }
          )),
          IconButton(
            icon: const Icon(Icons.add_circle, color: AppColors.primaryButton),
            onPressed: () => _showAddDialog(context, 'Ceiling Type', (val) {
              ctrl.addNewCeilingType(val);
              onStateChanged();
            }),
          ),
        ]),
        const SizedBox(height: 15),
        Row(children: [
          Expanded(child: Builder(
            builder: (context) {
              final brands = (ctrl.brandsMap[ctrl.selectedCeilingType] ?? ctrl.brandsMap['Gypsum Board']!).toSet().toList();
              // Safety: Ensure selected value exists in items
              final initialBrand = (ctrl.selectedBrand != null && brands.contains(ctrl.selectedBrand)) 
                  ? ctrl.selectedBrand 
                  : null;

              return DropdownButtonFormField<String>(
                key: ValueKey(ctrl.selectedCeilingType),
                isExpanded: true,
                value: initialBrand,
                decoration: AppStyles.inputDecoration('Brand Selection').copyWith(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                ),
                items: brands.map((val) => DropdownMenuItem(
                  value: val, 
                  child: Text(
                    val, 
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  )
                )).toList(),
                onChanged: (v) { ctrl.selectedBrand = v; ctrl.triggerAutoSave(); onStateChanged(); },
              );
            }
          )),
          IconButton(
            icon: const Icon(Icons.add_circle, color: AppColors.primaryButton),
            onPressed: () {
              if (ctrl.selectedCeilingType == null) return;
              _showAddDialog(context, 'Brand', (val) {
                ctrl.addNewBrand(ctrl.selectedCeilingType!, val);
                onStateChanged();
              });
            },
          ),
        ]),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: ctrl.selectedBrand == 'Other' 
              ? Column(
                  children: [
                    const SizedBox(height: 15),
                    TextField(controller: ctrl.brandController, decoration: AppStyles.inputDecoration('Custom Brand'), style: const TextStyle(fontWeight: FontWeight.bold), onChanged: (_) => ctrl.triggerAutoSave()),
                  ],
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('QUICK ADD DESIGN', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.border, fontSize: 13, letterSpacing: 1.2)),
            IconButton(
              icon: const Icon(Icons.add_circle, color: AppColors.primaryButton, size: 28),
              onPressed: () => _showAddDialog(context, 'Design', (val) {
                ctrl.addNewDesign(val);
                onStateChanged();
              }),
            ),
          ],
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.5,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: ctrl.designTypes.length,
          itemBuilder: (context, index) {
            final design = ctrl.designTypes.elementAt(index);
            // FIX: Count items globally across all rooms so indicators don't "disappear" when room context changes during Edit
            final existingCount = ctrl.currentItems.where((item) => item.designName == design).length;
            final isAdded = existingCount > 0;

            return GestureDetector(
              onLongPress: () {
                showDialog(context: context, builder: (ctx) => AlertDialog(
                  title: const Text('Remove Design?'),
                  content: Text('Remove $design from quick add list?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.alertRed),
                      onPressed: () { ctrl.removeDesign(design); Navigator.pop(ctx); },
                      child: const Text('REMOVE', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ));
              },
              onTap: () {
                QuickAddBottomSheet.show(context, ctrl, lang, newDesignType: design);
              },
              child: Container(
                decoration: AppStyles.neumorphicDecoration(color: AppColors.pureWhite, hasThickBorder: false, borderRadius: 8),
                padding: const EdgeInsets.only(left: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              design,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: AppColors.labelColor,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isAdded) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.resultGreen.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$existingCount',
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.resultGreen,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: AppColors.primaryButton, size: 24),
                      onPressed: () {
                        QuickAddBottomSheet.show(context, ctrl, lang, newDesignType: design);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 15),
      ],
    );
  }
}
