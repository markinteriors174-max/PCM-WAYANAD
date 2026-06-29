import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../theme/app_theme.dart';

class MaterialPricingRow {
  final String id;
  final TextEditingController nameController;
  final TextEditingController priceController;
  final TextEditingController lengthController;
  final TextEditingController widthController;
  final TextEditingController costSqftController;
  final double? customMargin;
  final bool isCustom;

  MaterialPricingRow({
    required this.id,
    required String defaultName,
    required double defaultPrice,
    required double defaultLength,
    required double defaultWidth,
    double? defaultCostSqft,
    this.customMargin,
    this.isCustom = false,
  })  : nameController = TextEditingController(text: defaultName),
        priceController = TextEditingController(text: defaultPrice.toStringAsFixed(0)),
        lengthController = TextEditingController(text: defaultLength.toStringAsFixed(0)),
        widthController = TextEditingController(text: defaultWidth.toStringAsFixed(0)),
        costSqftController = TextEditingController() {
    final area = defaultLength * defaultWidth;
    final calculated = area > 0 ? defaultPrice / area : 0.0;
    costSqftController.text = (defaultCostSqft ?? calculated).toStringAsFixed(2);
  }

  double get price => double.tryParse(priceController.text) ?? 0.0;
  double get length => double.tryParse(lengthController.text) ?? 1.0;
  double get width => double.tryParse(widthController.text) ?? 1.0;
  double get sqftRate => double.tryParse(costSqftController.text) ?? 0.0;
  String get displayName => nameController.text;

  double suggestedSellingPrice(double margin) {
    if (sqftRate <= 0) return 0.0;
    return sqftRate + (customMargin ?? margin);
  }

  void dispose() {
    nameController.dispose();
    priceController.dispose();
    lengthController.dispose();
    widthController.dispose();
    costSqftController.dispose();
  }
}

class HomeMaterialListSection extends StatefulWidget {
  const HomeMaterialListSection({super.key});

  @override
  State<HomeMaterialListSection> createState() => _HomeMaterialListSectionState();
}

class _HomeMaterialListSectionState extends State<HomeMaterialListSection> {
  bool _isLoading = true;
  final List<MaterialPricingRow> _rows = [];
  double _profitMargin = 42.09;

  @override
  void initState() {
    super.initState();
    _rows.addAll([
      MaterialPricingRow(id: 'gypsum_board_4x6', defaultName: 'Gypsum Board (4x6)', defaultPrice: 550, defaultLength: 4, defaultWidth: 6),
    ]);
    _loadPricingData();
  }

  @override
  void dispose() {
    for (var row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  Future<void> _loadPricingData() async {
    final prefs = await SharedPreferences.getInstance();
    _profitMargin = prefs.getDouble('profit_margin') ?? 42.09;
    
    // Load custom material IDs
    final customIds = prefs.getStringList('custom_material_ids') ?? [];
    final List<MaterialPricingRow> customRows = [];
    for (var id in customIds) {
      final name = prefs.getString('pricing_${id}_name') ?? 'Custom Material';
      final price = prefs.getDouble('pricing_${id}_price') ?? 0.0;
      final length = prefs.getDouble('pricing_${id}_length') ?? 1.0;
      final width = prefs.getDouble('pricing_${id}_width') ?? 1.0;
      final customMargin = prefs.getDouble('pricing_${id}_margin');
      final costSqft = prefs.getDouble('pricing_${id}_cost_sqft');
      
      customRows.add(MaterialPricingRow(
        id: id,
        defaultName: name,
        defaultPrice: price,
        defaultLength: length,
        defaultWidth: width,
        defaultCostSqft: costSqft,
        customMargin: customMargin,
        isCustom: true,
      ));
    }
    
    setState(() {
      _rows.addAll(customRows);
      for (var row in _rows) {
        final savedName = prefs.getString('pricing_${row.id}_name');
        final savedPrice = prefs.getDouble('pricing_${row.id}_price');
        final savedLength = prefs.getDouble('pricing_${row.id}_length');
        final savedWidth = prefs.getDouble('pricing_${row.id}_width');
        final savedCostSqft = prefs.getDouble('pricing_${row.id}_cost_sqft');
        
        if (savedName != null) row.nameController.text = savedName;
        if (savedPrice != null) row.priceController.text = savedPrice.toStringAsFixed(0);
        if (savedLength != null) row.lengthController.text = savedLength.toStringAsFixed(0);
        if (savedWidth != null) row.widthController.text = savedWidth.toStringAsFixed(0);
        if (savedCostSqft != null) row.costSqftController.text = savedCostSqft.toStringAsFixed(2);
      }
      _isLoading = false;
    });
  }

  Future<void> _savePricingData(MaterialPricingRow row) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pricing_${row.id}_name', row.displayName);
    await prefs.setDouble('pricing_${row.id}_price', row.price);
    await prefs.setDouble('pricing_${row.id}_length', row.length);
    await prefs.setDouble('pricing_${row.id}_width', row.width);
    await prefs.setDouble('pricing_${row.id}_cost_sqft', row.sqftRate);
    if (row.customMargin != null) {
      await prefs.setDouble('pricing_${row.id}_margin', row.customMargin!);
    }
  }

  Future<void> _deleteCustomMaterial(MaterialPricingRow row) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Material?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete "${row.displayName}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.alertRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('DELETE', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      final customIds = prefs.getStringList('custom_material_ids') ?? [];
      customIds.remove(row.id);
      await prefs.setStringList('custom_material_ids', customIds);
      
      await prefs.remove('pricing_${row.id}_name');
      await prefs.remove('pricing_${row.id}_price');
      await prefs.remove('pricing_${row.id}_length');
      await prefs.remove('pricing_${row.id}_width');
      await prefs.remove('pricing_${row.id}_isCustom');
      
      setState(() {
        _rows.remove(row);
      });
      row.dispose();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Material deleted'), backgroundColor: AppColors.primaryButton),
        );
      }
    }
  }

  void _showAddMaterialDialog() {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final lengthCtrl = TextEditingController();
    final widthCtrl = TextEditingController();
    final marginCtrl = TextEditingController(text: _profitMargin.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Material', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: AppStyles.inputDecoration('Material Name (e.g. Gypsum Board (4x6))'),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceCtrl,
                decoration: AppStyles.inputDecoration('Sheet Price (₹)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: lengthCtrl,
                      decoration: AppStyles.inputDecoration('Length (ft)'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: widthCtrl,
                      decoration: AppStyles.inputDecoration('Width (ft)'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: marginCtrl,
                decoration: AppStyles.inputDecoration('My Margin/Profit (per SqFt)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryButton),
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final price = double.tryParse(priceCtrl.text) ?? 0.0;
              final length = double.tryParse(lengthCtrl.text) ?? 0.0;
              final width = double.tryParse(widthCtrl.text) ?? 0.0;
              final margin = double.tryParse(marginCtrl.text.trim()) ?? _profitMargin;

              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter material name'), backgroundColor: AppColors.alertRed),
                );
                return;
              }
              if (price <= 0 || length <= 0 || width <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter valid price and dimensions'), backgroundColor: AppColors.alertRed),
                );
                return;
              }

              final id = 'custom_material_${DateTime.now().millisecondsSinceEpoch}';
              final prefs = await SharedPreferences.getInstance();
              
              final customIds = prefs.getStringList('custom_material_ids') ?? [];
              customIds.add(id);
              await prefs.setStringList('custom_material_ids', customIds);

              await prefs.setString('pricing_${id}_name', name);
              await prefs.setDouble('pricing_${id}_price', price);
              await prefs.setDouble('pricing_${id}_length', length);
              await prefs.setDouble('pricing_${id}_width', width);
              await prefs.setDouble('pricing_${id}_margin', margin);
              await prefs.setBool('pricing_${id}_isCustom', true);

              final newRow = MaterialPricingRow(
                id: id,
                defaultName: name,
                defaultPrice: price,
                defaultLength: length,
                defaultWidth: width,
                defaultCostSqft: price / (length * width > 0 ? length * width : 1.0),
                customMargin: margin,
                isCustom: true,
              );

              setState(() {
                _rows.add(newRow);
              });

              if (ctx.mounted) {
                Navigator.pop(ctx);
              }

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Material added successfully'), backgroundColor: AppColors.primaryButton),
                );
              }
            },
            child: const Text('ADD', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(20.0),
        child: CircularProgressIndicator(color: AppColors.border),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'MATERIAL PRICING LIST',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: 1.5,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Input the sheet price and size in feet to dynamically calculate the rate per square foot.',
          style: TextStyle(
            fontSize: 11,
            color: Colors.black54,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 15),
          decoration: AppStyles.neumorphicDecoration(color: Colors.white, hasThickBorder: true),
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(2.0), // Material Name + Delete btn
              1: FlexColumnWidth(1.2), // Sheet Price
              2: FlexColumnWidth(1.6), // Size (L x W)
              3: FlexColumnWidth(1.2), // Cost/SqFt
              4: FlexColumnWidth(1.4), // Suggested Price
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              const TableRow(
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.black26, width: 1.5)),
                ),
                children: [
                  TableCell(child: Padding(padding: EdgeInsets.symmetric(vertical: 8, horizontal: 2), child: Text('MATERIAL', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 8.5, letterSpacing: 0.3)))),
                  TableCell(child: Padding(padding: EdgeInsets.symmetric(vertical: 8, horizontal: 2), child: Text('PRICE (₹)', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 8.5, letterSpacing: 0.3)))),
                  TableCell(child: Padding(padding: EdgeInsets.symmetric(vertical: 8, horizontal: 2), child: Text('SIZE (L x W)', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 8.5, letterSpacing: 0.3)))),
                  TableCell(child: Padding(padding: EdgeInsets.symmetric(vertical: 8, horizontal: 2), child: Text('COST/SQFT', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 8.5, letterSpacing: 0.3)))),
                  TableCell(child: Padding(padding: EdgeInsets.symmetric(vertical: 8, horizontal: 2), child: Text('SUGG. PRICE', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 8.5, letterSpacing: 0.3)))),
                ],
              ),
              ..._rows.map((row) {
                return TableRow(
                  children: [
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: row.nameController,
                                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11),
                                decoration: const InputDecoration(
                                  hintText: "Enter Material Name",
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onChanged: (val) {
                                  _savePricingData(row);
                                },
                              ),
                            ),
                            if (row.isCustom)
                              IconButton(
                                icon: const Icon(Icons.delete, color: AppColors.alertRed, size: 16),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => _deleteCustomMaterial(row),
                              ),
                          ],
                        ),
                      ),
                    ),
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                        child: TextFormField(
                          controller: row.priceController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                          decoration: const InputDecoration(
                            prefixText: '₹',
                            prefixStyle: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold),
                            contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                            isDense: true,
                            border: OutlineInputBorder(),
                            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.black38)),
                            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.black)),
                          ),
                          onChanged: (val) {
                            final price = double.tryParse(val) ?? 0.0;
                            final area = row.length * row.width;
                            if (area > 0) {
                              row.costSqftController.text = (price / area).toStringAsFixed(2);
                            }
                            setState(() {});
                            _savePricingData(row);
                          },
                        ),
                      ),
                    ),
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: row.lengthController,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.black, fontSize: 12),
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(horizontal: 2, vertical: 8),
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.black38)),
                                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.black)),
                                ),
                                onChanged: (val) {
                                  final length = double.tryParse(val) ?? 1.0;
                                  final area = length * row.width;
                                  if (area > 0) {
                                    row.costSqftController.text = (row.price / area).toStringAsFixed(2);
                                  }
                                  setState(() {});
                                  _savePricingData(row);
                                },
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 1),
                              child: Text('x', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                            Expanded(
                              child: TextFormField(
                                controller: row.widthController,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.black, fontSize: 12),
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(horizontal: 2, vertical: 8),
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.black38)),
                                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.black)),
                                ),
                                onChanged: (val) {
                                  final width = double.tryParse(val) ?? 1.0;
                                  final area = row.length * width;
                                  if (area > 0) {
                                    row.costSqftController.text = (row.price / area).toStringAsFixed(2);
                                  }
                                  setState(() {});
                                  _savePricingData(row);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                        child: TextFormField(
                          controller: row.costSqftController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                          decoration: const InputDecoration(
                            prefixText: '₹',
                            prefixStyle: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold),
                            contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                            isDense: true,
                            border: OutlineInputBorder(),
                            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.black38)),
                            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.black)),
                          ),
                          onChanged: (val) {
                            final rate = double.tryParse(val) ?? 0.0;
                            final area = row.length * row.width;
                            if (area > 0) {
                              row.priceController.text = (rate * area).toStringAsFixed(0);
                            }
                            setState(() {});
                            _savePricingData(row);
                          },
                        ),
                      ),
                    ),
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
                        child: Text(
                          '₹${row.suggestedSellingPrice(_profitMargin).toStringAsFixed(2)}',
                          style: const TextStyle(color: AppColors.resultGreen, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 25),
        GestureDetector(
          onTap: _showAddMaterialDialog,
          child: Container(
            height: 55,
            width: double.infinity,
            decoration: AppStyles.neumorphicDecoration(color: AppColors.primaryButton, hasThickBorder: true),
            alignment: Alignment.center,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Text('ADD NEW MATERIAL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 13)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
