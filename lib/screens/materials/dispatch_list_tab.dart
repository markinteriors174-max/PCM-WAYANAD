import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import 'room_breakdown_calculator.dart';

class DispatchListTab extends StatefulWidget {
  final bool isLoading;
  final List<String> categoriesList;
  final Map<String, List<Map<String, dynamic>>> materialDictionary;
  final Map<String, TextEditingController> dispatchQtyControllers;
  final Map<String, TextEditingController> dispatchRateControllers;
  final Map<String, List<MaterialRoomBreakdown>> roomBreakdowns;
  final TextEditingController dispatchLocationController;
  final TextEditingController dispatchClientController;
  final TextEditingController dispatchContractorController;
  final double totalEstimatedCost;
  final String? editingDispatchUnitNumber;
  final bool includeBankDetails;
  final VoidCallback onCalculateTotal;
  final VoidCallback onNewDispatch;
  final VoidCallback onGeneratePdf;
  final ValueChanged<bool> onIncludeBankDetailsChanged;
  final Function(String key, MaterialRoomBreakdown breakdown) onAddListener;

  const DispatchListTab({
    super.key,
    required this.isLoading,
    required this.categoriesList,
    required this.materialDictionary,
    required this.dispatchQtyControllers,
    required this.dispatchRateControllers,
    required this.roomBreakdowns,
    required this.dispatchLocationController,
    required this.dispatchClientController,
    required this.dispatchContractorController,
    required this.totalEstimatedCost,
    required this.editingDispatchUnitNumber,
    required this.includeBankDetails,
    required this.onCalculateTotal,
    required this.onNewDispatch,
    required this.onGeneratePdf,
    required this.onIncludeBankDetailsChanged,
    required this.onAddListener,
  });

  @override
  State<DispatchListTab> createState() => _DispatchListTabState();
}

class _DispatchListTabState extends State<DispatchListTab> {
  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(width: 4, height: 16, color: AppColors.primaryButton),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5, color: AppColors.border)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) return const Center(child: CircularProgressIndicator(color: AppColors.border));
    
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.editingDispatchUnitNumber != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: AppStyles.neumorphicDecoration(color: Colors.white, hasThickBorder: true),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'EDITING DISPATCH LIST',
                                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1, color: AppColors.border),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.editingDispatchUnitNumber!,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.labelColor),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('NEW LIST', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.alertRed,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              onPressed: widget.onNewDispatch,
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: QrImageView(
                              data: 'https://pcmwayanad.com/dispatch/${widget.editingDispatchUnitNumber}',
                              version: QrVersions.auto,
                              size: 150.0,
                              gapless: false,
                              eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppColors.border),
                              dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: AppColors.border),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Scan this QR code to edit this dispatch list on any device',
                          style: TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                _buildSectionHeader('TOP INFO METADATA'),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: AppStyles.neumorphicDecoration(color: Colors.white, hasThickBorder: true),
                  child: Column(
                    children: [
                      TextField(
                        controller: widget.dispatchLocationController,
                        decoration: AppStyles.inputDecoration('Site Location (Mandatory)*'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 15),
                      TextField(
                        controller: widget.dispatchClientController,
                        decoration: AppStyles.inputDecoration('Client / Site Name & Phone'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 15),
                      TextField(
                        controller: widget.dispatchContractorController,
                        decoration: AppStyles.inputDecoration('Worker / Contractor Name & Phone'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                _buildSectionHeader('CEILING & WALL CATEGORIES'),
                const SizedBox(height: 15),
                if (widget.categoriesList.isEmpty)
                  const Center(child: Text('No categories available. Please add them in Config Hub.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)))
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.categoriesList.length,
                    itemBuilder: (context, catIdx) {
                      final categoryName = widget.categoriesList[catIdx];
                      final subMaterials = widget.materialDictionary[categoryName] ?? [];
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
                            if (subMaterials.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.0),
                                child: Text('No materials added to this category yet.', style: TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic)),
                              )
                            else
                              ...subMaterials.map((item) {
                                final key = '$categoryName||${item['name']}';
                                final controller = widget.dispatchQtyControllers[key];
                                final qtyStr = controller?.text.trim() ?? '';
                                final qty = double.tryParse(qtyStr) ?? 0.0;

                                final englishName = item['name'];
                                final malName = item['material_name_malayalam'] ?? '';
                                
                                final breakdowns = widget.roomBreakdowns[key] ?? [];
                                final hasBreakdowns = breakdowns.isNotEmpty;

                                double displayQty = qty;
                                double displayAmount = 0.0;

                                if (hasBreakdowns) {
                                  displayQty = 0.0;
                                  final rateStr = widget.dispatchRateControllers[key]?.text.trim() ?? '';
                                  final rate = double.tryParse(rateStr) ?? (item['rate'] as num?)?.toDouble() ?? 0.0;
                                  for (var b in breakdowns) {
                                    final q = double.tryParse(b.qtyController.text.trim()) ?? 0.0;
                                    displayQty += q;
                                  }
                                  displayAmount = displayQty * rate;
                                } else {
                                  if (qty > 0) {
                                    final rateStr = widget.dispatchRateControllers[key]?.text.trim() ?? '';
                                    final rate = double.tryParse(rateStr) ?? (item['rate'] as num?)?.toDouble() ?? 0.0;
                                    displayAmount = qty * rate;
                                  }
                                }

                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        englishName,
                                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.labelColor),
                                                      ),
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(Icons.add_box_outlined, size: 18, color: AppColors.primaryButton),
                                                      tooltip: 'Add Room Breakdown',
                                                      padding: EdgeInsets.zero,
                                                      constraints: const BoxConstraints(),
                                                      onPressed: () {
                                                        setState(() {
                                                          widget.roomBreakdowns.putIfAbsent(key, () => []);
                                                          final newB = MaterialRoomBreakdown(room: '', qty: '', rate: '');
                                                          widget.roomBreakdowns[key]!.add(newB);
                                                          widget.onAddListener(key, newB);
                                                          widget.dispatchQtyControllers[key]?.clear();
                                                          widget.onCalculateTotal();
                                                        });
                                                      },
                                                    ),
                                                  ],
                                                ),
                                                if (malName.isNotEmpty && malName != englishName)
                                                  Padding(
                                                    padding: const EdgeInsets.only(top: 2.0),
                                                    child: Text(
                                                      malName,
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        color: Colors.black54,
                                                        fontFamily: GoogleFonts.inder().fontFamily,
                                                      ),
                                                    ),
                                                  ),
                                                const SizedBox(height: 2),
                                                Row(
                                                  children: [
                                                    Text(
                                                      'Unit: ${item['unit']}',
                                                      style: const TextStyle(fontSize: 9, color: Colors.black38, fontWeight: FontWeight.bold),
                                                    ),
                                                    if (item['sku'] != null && (item['sku'] as String).isNotEmpty) ...[
                                                      const SizedBox(width: 8),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                                        decoration: BoxDecoration(
                                                          color: AppColors.primaryButton.withValues(alpha: 0.1),
                                                          borderRadius: BorderRadius.circular(4),
                                                        ),
                                                        child: Text(
                                                          'SKU: ${item['sku']}',
                                                          style: const TextStyle(fontSize: 8, color: AppColors.primaryButton, fontWeight: FontWeight.bold),
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          if (hasBreakdowns)
                                            Container(
                                              width: 55,
                                              height: 35,
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade100,
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: Colors.grey.shade300),
                                              ),
                                              child: Text(
                                                displayQty.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), ''),
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54),
                                              ),
                                            )
                                          else
                                            SizedBox(
                                              width: 55,
                                              height: 35,
                                              child: TextField(
                                                controller: controller,
                                                keyboardType: TextInputType.number,
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.resultGreen),
                                                decoration: InputDecoration(
                                                  hintText: '0',
                                                  contentPadding: const EdgeInsets.all(5),
                                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                                ),
                                                onChanged: (_) => widget.onCalculateTotal(),
                                              ),
                                            ),
                                          Padding(
                                            padding: const EdgeInsets.only(left: 10),
                                            child: SizedBox(
                                              width: 75,
                                              height: 35,
                                              child: TextField(
                                                controller: widget.dispatchRateControllers[key],
                                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primaryButton),
                                                decoration: InputDecoration(
                                                  hintText: 'Rate',
                                                  prefixText: '₹',
                                                  prefixStyle: const TextStyle(fontSize: 10, color: Colors.grey),
                                                  contentPadding: const EdgeInsets.all(5),
                                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                                ),
                                                onChanged: (_) => widget.onCalculateTotal(),
                                              ),
                                            ),
                                          ),
                                          if (displayQty > 0)
                                            Padding(
                                              padding: const EdgeInsets.only(left: 10),
                                              child: SizedBox(
                                                width: 70,
                                                child: Text(
                                                  '₹${displayAmount.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}',
                                                  textAlign: TextAlign.right,
                                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppColors.resultGreen),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      if (hasBreakdowns) ...[
                                        Padding(
                                          padding: const EdgeInsets.only(left: 10, top: 8),
                                          child: SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: SizedBox(
                                              width: MediaQuery.of(context).size.width - 62 > 320
                                                  ? MediaQuery.of(context).size.width - 62
                                                  : 320,
                                              child: RoomBreakdownWidget(
                                                breakdowns: breakdowns,
                                                onChanged: widget.onCalculateTotal,
                                                onAdd: () {
                                                  setState(() {
                                                    final newB = MaterialRoomBreakdown(room: '', qty: '', rate: '');
                                                    breakdowns.add(newB);
                                                    widget.onAddListener(key, newB);
                                                    widget.onCalculateTotal();
                                                  });
                                                },
                                                onDelete: (idx) {
                                                  setState(() {
                                                    breakdowns[idx].dispose();
                                                    breakdowns.removeAt(idx);
                                                    widget.onCalculateTotal();
                                                  });
                                                },
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                      const Divider(height: 16, color: AppColors.subtleGrey),
                                    ],
                                  ),
                                );
                              }),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 15,
                offset: const Offset(0, -4),
              ),
            ],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.1), width: 1),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // REQUIREMENT: Light silver background card for Bank Details toggle
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9), // Light silver/grey background
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Include Bank Details on PDF',
                        style: TextStyle(
                          color: AppColors.labelColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      Switch(
                        value: widget.includeBankDetails,
                        activeThumbColor: AppColors.resultGreen,
                        onChanged: widget.onIncludeBankDetailsChanged,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.border, Color(0xFF2A5298)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.border.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'GRAND TOTAL MATERIAL COST',
                              style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Grand Total Material Cost:',
                              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '₹${widget.totalEstimatedCost.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: widget.onGeneratePdf,
                  child: Container(
                    height: 54,
                    width: double.infinity,
                    decoration: AppStyles.neumorphicDecoration(color: AppColors.primaryButton, hasThickBorder: true),
                    alignment: Alignment.center,
                    child: const Text(
                      'GENERATE MATERIAL LIST PDF',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
