import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/database_service.dart';

class ConfigHubTab extends StatefulWidget {
  final bool isLoading;
  final List<String> categoriesList;
  final Map<String, List<Map<String, dynamic>>> materialDictionary;
  final TextEditingController newCategoryController;
  final TextEditingController newMaterialNameController;
  final String selectedUnitForNewItem;
  final String? selectedCategoryForNewItem;
  final List<String> units;
  final VoidCallback onRefresh;
  final ValueChanged<String?> onSelectedCategoryChanged;
  final ValueChanged<String?> onSelectedUnitChanged;

  const ConfigHubTab({
    super.key,
    required this.isLoading,
    required this.categoriesList,
    required this.materialDictionary,
    required this.newCategoryController,
    required this.newMaterialNameController,
    required this.selectedUnitForNewItem,
    required this.selectedCategoryForNewItem,
    required this.units,
    required this.onRefresh,
    required this.onSelectedCategoryChanged,
    required this.onSelectedUnitChanged,
  });

  @override
  State<ConfigHubTab> createState() => _ConfigHubTabState();
}

class _ConfigHubTabState extends State<ConfigHubTab> {
  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(width: 4, height: 16, color: AppColors.primaryButton),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5, color: AppColors.border)),
      ],
    );
  }

  void _showEditCategorySheet(String currentName) {
    final ctrl = TextEditingController(text: currentName);
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40, height: 4,
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        const Icon(Icons.category_outlined, color: AppColors.border, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'EDIT CATEGORY NAME',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5, color: AppColors.border),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: ctrl,
                      autofocus: true,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      decoration: AppStyles.inputDecoration('Category Name'),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        icon: saving
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.check_rounded),
                        label: Text(saving ? 'SAVING...' : 'UPDATE', style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryButton,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: saving
                            ? null
                            : () async {
                                final newName = ctrl.text.trim();
                                if (newName.isEmpty || newName == currentName) {
                                  Navigator.pop(ctx);
                                  return;
                                }
                                final navigator = Navigator.of(ctx);
                                setSheet(() => saving = true);
                                await DatabaseService.instance.updateMaterialCategory(currentName, newName);
                                widget.onRefresh();
                                navigator.pop();
                              },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditSubMaterialSheet(Map<String, dynamic> item) {
    final ctrl = TextEditingController(text: item['name'] as String? ?? '');
    String selectedUnit = item['unit'] as String? ?? widget.units.first;
    if (!widget.units.contains(selectedUnit)) selectedUnit = widget.units.first;
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40, height: 4,
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        const Icon(Icons.construction_outlined, color: AppColors.border, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'EDIT SUB-MATERIAL',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5, color: AppColors.border),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: ctrl,
                      autofocus: true,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      decoration: AppStyles.inputDecoration('Material Name'),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'UNIT',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: AppColors.labelColor),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: selectedUnit,
                      items: widget.units.map((u) => DropdownMenuItem(value: u, child: Text(u, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))).toList(),
                      onChanged: (v) => setSheet(() => selectedUnit = v ?? selectedUnit),
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        icon: saving
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.check_rounded),
                        label: Text(saving ? 'SAVING...' : 'UPDATE', style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryButton,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: saving
                            ? null
                            : () async {
                                final newName = ctrl.text.trim();
                                if (newName.isEmpty) return;
                                final navigator = Navigator.of(ctx);
                                setSheet(() => saving = true);
                                await DatabaseService.instance.updateSubMaterial(
                                  item['id'] as int,
                                  newName,
                                  selectedUnit,
                                );
                                widget.onRefresh();
                                navigator.pop();
                              },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) return const Center(child: CircularProgressIndicator(color: AppColors.border));
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('ADD NEW MAIN CATEGORY'),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppStyles.neumorphicDecoration(color: Colors.white),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: widget.newCategoryController,
                    decoration: AppStyles.inputDecoration('Category Name (e.g. V-Board)'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                const SizedBox(width: 15),
                ElevatedButton(
                  onPressed: () async {
                    final name = widget.newCategoryController.text.trim();
                    if (name.isNotEmpty) {
                      await DatabaseService.instance.addMaterialCategory(name);
                      widget.newCategoryController.clear();
                      widget.onRefresh();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryButton,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('ADD'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),
          _buildSectionHeader('ADD SUB-MATERIAL'),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppStyles.neumorphicDecoration(color: Colors.white),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SELECT MAIN CATEGORY',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: AppColors.labelColor),
                ),
                const SizedBox(height: 5),
                if (widget.categoriesList.isEmpty)
                  const Text('Please add a category first.', style: TextStyle(color: Colors.red, fontSize: 11))
                else
                  DropdownButtonFormField<String>(
                    initialValue: widget.selectedCategoryForNewItem,
                    items: widget.categoriesList.map((cat) {
                      return DropdownMenuItem<String>(
                        value: cat,
                        child: Text(cat, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      );
                    }).toList(),
                    onChanged: widget.onSelectedCategoryChanged,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                  ),
                const SizedBox(height: 15),
                TextField(
                  controller: widget.newMaterialNameController,
                  decoration: AppStyles.inputDecoration('Material Name (e.g. XPS Sheets)'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 15),
                const Text(
                  'SELECT UNIT',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: AppColors.labelColor),
                ),
                const SizedBox(height: 5),
                DropdownButtonFormField<String>(
                  initialValue: widget.selectedUnitForNewItem,
                  items: widget.units.map((unit) {
                    return DropdownMenuItem<String>(
                      value: unit,
                      child: Text(unit, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    );
                  }).toList(),
                  onChanged: widget.onSelectedUnitChanged,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () async {
                    final name = widget.newMaterialNameController.text.trim();
                    final cat = widget.selectedCategoryForNewItem;
                    if (name.isNotEmpty && cat != null) {
                      await DatabaseService.instance.addSubMaterial(cat, name, widget.selectedUnitForNewItem);
                      widget.newMaterialNameController.clear();
                      widget.onRefresh();
                    }
                  },
                  child: Container(
                    height: 50,
                    width: double.infinity,
                    decoration: AppStyles.neumorphicDecoration(color: AppColors.primaryButton),
                    alignment: Alignment.center,
                    child: const Text(
                      'ADD SUB-MATERIAL',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),
          _buildSectionHeader('MANAGE MATERIAL DICTIONARY'),
          const SizedBox(height: 15),
          if (widget.materialDictionary.isEmpty)
            const Center(child: Text('Dictionary is empty.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)))
          else
            ...widget.categoriesList.map((categoryName) {
              final subMaterials = widget.materialDictionary[categoryName] ?? [];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: AppStyles.neumorphicDecoration(color: Colors.white),
                child: ExpansionTile(
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          categoryName.toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: AppColors.labelColor, letterSpacing: 0.5),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Edit category name',
                        icon: const Icon(Icons.edit_outlined, color: AppColors.border, size: 20),
                        onPressed: () => _showEditCategorySheet(categoryName),
                      ),
                      IconButton(
                        tooltip: 'Delete category',
                        icon: const Icon(Icons.delete_outline, color: AppColors.alertRed, size: 20),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete Category?'),
                              content: Text('Are you sure you want to delete "$categoryName" and all its sub-materials?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  style: TextButton.styleFrom(foregroundColor: AppColors.alertRed),
                                  child: const Text('DELETE'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await DatabaseService.instance.deleteMaterialCategory(categoryName);
                            widget.onRefresh();
                          }
                        },
                      ),
                    ],
                  ),
                  childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: [
                    if (subMaterials.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text('No materials added.', style: TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic)),
                      )
                    else
                      ...subMaterials.map((item) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${item['name']} (${item['unit']})',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.labelColor),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Edit material',
                                icon: const Icon(Icons.edit_outlined, color: AppColors.border, size: 18),
                                onPressed: () => _showEditSubMaterialSheet(item),
                              ),
                              IconButton(
                                tooltip: 'Delete material',
                                icon: const Icon(Icons.delete_outline, color: AppColors.alertRed, size: 18),
                                onPressed: () async {
                                  await DatabaseService.instance.deleteSubMaterial(item['id'] as int);
                                  widget.onRefresh();
                                },
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              );
            }),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
