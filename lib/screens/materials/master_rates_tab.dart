import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

String getBaseName(String name) {
  int pIdx = name.indexOf(' (');
  if (pIdx != -1) return name.substring(0, pIdx).trim();
  int hIdx = name.indexOf(' - ');
  if (hIdx != -1) return name.substring(0, hIdx).trim();
  return name.trim();
}

class MaterialVariantRow {
  int? id;
  String unit;
  final TextEditingController skuController;
  final TextEditingController rateController;

  MaterialVariantRow({
    this.id,
    required this.unit,
    required String sku,
    required double rate,
  })  : skuController = TextEditingController(text: sku),
        rateController = TextEditingController(text: rate > 0 ? rate.toStringAsFixed(2) : '');

  void dispose() {
    skuController.dispose();
    rateController.dispose();
  }
}

class MasterRatesTab extends StatefulWidget {
  final List<String> ceilingTypes;
  final Map<String, TextEditingController> controllers;
  final List<String> categoriesList;
  final Map<String, List<MaterialVariantRow>> uiVariants;
  final List<int> deletedSubMaterialIds;
  final VoidCallback onSaveRates;

  const MasterRatesTab({
    super.key,
    required this.ceilingTypes,
    required this.controllers,
    required this.categoriesList,
    required this.uiVariants,
    required this.deletedSubMaterialIds,
    required this.onSaveRates,
  });

  @override
  State<MasterRatesTab> createState() => _MasterRatesTabState();
}

class _MasterRatesTabState extends State<MasterRatesTab> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 25, 
        right: 25, 
        top: 25, 
        bottom: MediaQuery.of(context).viewInsets.bottom + 120,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('MASTER RATE MANAGEMENT', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 2, color: AppColors.border)),
          const SizedBox(height: 25),
          ...widget.ceilingTypes.map((type) => Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(20),
            decoration: AppStyles.neumorphicDecoration(color: Colors.white, hasThickBorder: true),
            child: Row(
              children: [
                Expanded(flex: 2, child: Text(type.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.labelColor, fontSize: 13))),
                const SizedBox(width: 20),
                Expanded(flex: 1, child: TextField(
                  controller: widget.controllers[type],
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.resultGreen, fontSize: 18),
                  decoration: AppStyles.inputDecoration('Rate (₹)').copyWith(contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
                )),
              ],
            ),
          )),
          const SizedBox(height: 25),
          const Text(
            'SUB-MATERIALS MASTER RATES',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 2, color: AppColors.border),
          ),
          const SizedBox(height: 15),
          if (widget.uiVariants.isEmpty)
            const Center(child: Text('No categories available.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)))
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.categoriesList.length,
              itemBuilder: (context, catIdx) {
                final categoryName = widget.categoriesList[catIdx];
                final categoryKeys = widget.uiVariants.keys.where((k) => k.startsWith('$categoryName||')).toList();
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.subtleGrey)),
                  color: Colors.white,
                  child: ExpansionTile(
                    title: Text(
                      categoryName.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: AppColors.labelColor, letterSpacing: 0.5),
                    ),
                    childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (categoryKeys.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text('No materials in this category.', style: TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic)),
                        )
                      else
                        ...categoryKeys.map((key) {
                          final baseName = key.split('||')[1];
                          final rows = widget.uiVariants[key] ?? [];
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        baseName.toUpperCase(),
                                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: AppColors.labelColor, letterSpacing: 0.5),
                                      ),
                                    ),
                                    Text(
                                      'Unit: ${rows.isNotEmpty ? rows.first.unit : "Nos"}',
                                      style: const TextStyle(fontSize: 9, color: Colors.black38, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                
                                ...rows.map((row) {
                                  final idx = rows.indexOf(row);
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey.shade100),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Variant #${idx + 1}',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.grey),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline, color: AppColors.alertRed, size: 18),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                              onPressed: () {
                                                setState(() {
                                                  if (row.id != null) {
                                                    widget.deletedSubMaterialIds.add(row.id!);
                                                  }
                                                  rows.remove(row);
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            Expanded(
                                              flex: 2,
                                              child: SizedBox(
                                                height: 35,
                                                child: TextField(
                                                  controller: row.skuController,
                                                  decoration: const InputDecoration(
                                                    labelText: 'Material SKU / Code',
                                                    labelStyle: TextStyle(fontSize: 9),
                                                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                                    border: OutlineInputBorder(),
                                                  ),
                                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              flex: 1,
                                              child: SizedBox(
                                                height: 35,
                                                child: TextField(
                                                  controller: row.rateController,
                                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                  decoration: const InputDecoration(
                                                    labelText: 'Price',
                                                    labelStyle: TextStyle(fontSize: 9),
                                                    prefixText: '₹',
                                                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                                    border: OutlineInputBorder(),
                                                  ),
                                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.resultGreen),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                                
                                TextButton.icon(
                                  icon: const Icon(Icons.add, size: 14, color: AppColors.border),
                                  label: const Text(
                                    'Add Another Variant Layout',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.border),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      rows.add(MaterialVariantRow(
                                        unit: rows.isNotEmpty ? rows.first.unit : 'Nos',
                                        sku: '',
                                        rate: 0.0,
                                      ));
                                    });
                                  },
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                );
              },
            ),
          const SizedBox(height: 25),
          GestureDetector(
            onTap: widget.onSaveRates,
            child: Container(
              height: 60,
              width: double.infinity,
              decoration: AppStyles.neumorphicDecoration(color: AppColors.primaryButton, hasThickBorder: true),
              alignment: Alignment.center,
              child: const Text('UPDATE ALL RATES', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2)),
            ),
          ),
        ],
      ),
    );
  }
}
