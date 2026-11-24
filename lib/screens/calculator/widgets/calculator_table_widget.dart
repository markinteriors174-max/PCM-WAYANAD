import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../../../../theme/app_theme.dart';
import '../../../../models/quotation.dart';
import '../../../../models/rate_tier.dart';
import '../../../../utils/calculator_utils.dart';
import '../../../../providers/language_provider.dart';
import '../../../../services/pdf_service.dart';
import '../../../../services/pdf_utils/pdf_design_category_helper.dart';
import '../../../../services/material_engine.dart';
import '../calculator_controller.dart';
import 'quick_add_bottom_sheet.dart';

class CalculatorTableWidget extends StatefulWidget {
  final CalculatorController ctrl;
  final VoidCallback onStateChanged;

  const CalculatorTableWidget({
    super.key,
    required this.ctrl,
    required this.onStateChanged,
  });

  @override
  State<CalculatorTableWidget> createState() => _CalculatorTableWidgetState();
}

class _CalculatorTableWidgetState extends State<CalculatorTableWidget> {
  final Map<String, bool> _roomCheckboxes = {};
  final Map<int, bool> _itemCheckboxes = {};

  @override
  void initState() {
    super.initState();
    widget.ctrl.addListener(_onCtrlUpdated);
  }

  @override
  void didUpdateWidget(CalculatorTableWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ctrl != widget.ctrl) {
      oldWidget.ctrl.removeListener(_onCtrlUpdated);
      widget.ctrl.addListener(_onCtrlUpdated);
    }
  }

  @override
  void dispose() {
    widget.ctrl.removeListener(_onCtrlUpdated);
    super.dispose();
  }

  void _onCtrlUpdated() {
    if (mounted) setState(() {});
  }

  void _editRateDialog(BuildContext context, int itemIndex, QuotationItem item) {
    final rateCtrl = TextEditingController(text: item.rate > 0 ? item.rate.toStringAsFixed(2) : '');

    // Normalize initial unit
    String selectedUnit = item.unit.isNotEmpty ? item.unit : 'SqFt';
    if (selectedUnit == 'Meter') selectedUnit = 'Meters';

    const unitList = [
      {'val': 'SqFt', 'label': 'SqFt (ചതുരശ്ര അടി)'},
      {'val': 'Meters', 'label': 'Meter (മീറ്റർ)'},
      {'val': 'Feet', 'label': 'Feet (അടി)'},
      {'val': 'Inches', 'label': 'Inches (ഇഞ്ച്)'},
      {'val': 'CM', 'label': 'CM (സെ.മീ)'},
      {'val': 'mm', 'label': 'mm (മി.മീ)'},
    ];

    final supportedVals = unitList.map((e) => e['val']!).toSet();
    if (!supportedVals.contains(selectedUnit)) {
      selectedUnit = 'SqFt';
    }

    double calculateAreaForUnit(String u) {
      if (item.length <= 0 || item.width <= 0) return item.area;
      final rawArea = item.length * item.width * (item.quantity > 0 ? item.quantity : 1.0);
      switch (u) {
        case 'Meters':
        case 'SqM':
          return rawArea * 10.7639;
        case 'Inches':
          return rawArea / 144.0;
        case 'CM':
        case 'cm':
          return rawArea / 929.03;
        case 'mm':
          return rawArea * (10.7639 / 1000000.0);
        case 'Feet':
        case 'SqFt':
        default:
          return rawArea;
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final liveRate = double.tryParse(rateCtrl.text.trim()) ?? item.rate;
          final liveArea = calculateAreaForUnit(selectedUnit);
          final liveAmount = liveArea * liveRate;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.edit, color: Color(0xFF0284C7), size: 18),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'റേറ്റ് & യൂണിറ്റ് (${item.roomName})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 14, color: Color(0xFF64748B)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${item.designName.isNotEmpty ? item.designName : item.ceilingType} • ${item.length > 0 ? "${item.length} × ${item.width}" : ""}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 1. Unit Selector
                  DropdownButtonFormField<String>(
                    initialValue: selectedUnit,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'യൂണിറ്റ് സെലക്ഷൻ (Unit Selector)',
                      prefixIcon: const Icon(Icons.straighten, color: Color(0xFF0284C7), size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    items: unitList
                        .map((u) => DropdownMenuItem(
                              value: u['val'],
                              child: Text(
                                u['label']!,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ))
                        .toList(),
                    onChanged: (newU) {
                      if (newU != null) {
                        setDialogState(() {
                          selectedUnit = newU;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 14),

                  // 2. Rate Input Field
                  TextField(
                    controller: rateCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'റേറ്റ് (Rate: ₹ / $selectedUnit)',
                      prefixText: '₹ ',
                      prefixStyle: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A), fontSize: 16),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                    onChanged: (_) => setDialogState(() {}),
                  ),

                  // 3. Live Calculated Preview
                  Container(
                    margin: const EdgeInsets.only(top: 14),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF86EFAC)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('കണക്കാക്കിയ വിസ്തീർണ്ണം:', style: TextStyle(fontSize: 10, color: Color(0xFF166534))),
                              Text(
                                '${CalculatorUtils.formatNumber(liveArea)} SQFT',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF14532D)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('ആകെ തുക (Total):', style: TextStyle(fontSize: 10, color: Color(0xFF166534))),
                            Text(
                              '₹${CalculatorUtils.formatIndianCurrency(liveAmount)}',
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF15803D)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('CANCEL', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                icon: const Icon(Icons.check, size: 16),
                label: const Text('സേവ് ചെയ്യുക (SAVE)', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  final newRate = double.tryParse(rateCtrl.text.trim()) ?? item.rate;
                  final computedArea = calculateAreaForUnit(selectedUnit);
                  final newAmount = computedArea * newRate;
                  setState(() {
                    widget.ctrl.currentItems[itemIndex] = item.copyWith(
                      unit: selectedUnit,
                      area: computedArea,
                      rate: newRate,
                      amount: newAmount,
                    );
                  });
                  widget.ctrl.updateProjectTotals();
                  widget.ctrl.triggerAutoSave();
                  widget.onStateChanged();
                  Navigator.pop(ctx);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _showBulkEditForCheckedRooms(BuildContext context, List<String> checkedRooms) {
    double initialRate = 105.0;
    String initialBoard = 'Saint-Gobain Gyproc (Regular)';
    String initialChannel = 'Standard Medium G.I. (0.45mm)';

    if (widget.ctrl.currentItems.isNotEmpty) {
      final matching = widget.ctrl.currentItems.where((i) => checkedRooms.contains(i.roomName)).toList();
      final sample = matching.isNotEmpty ? matching.first : widget.ctrl.currentItems.first;
      initialRate = sample.rate;
      if (sample.ceilingType.isNotEmpty) initialBoard = sample.ceilingType;
      if (sample.brandName != null && sample.brandName!.isNotEmpty) {
        final parts = sample.brandName!.split('•');
        if (parts.length > 1) {
          initialChannel = parts[1].trim();
        } else {
          initialChannel = sample.brandName!;
        }
      }
    }

    final rateCtrl = TextEditingController(text: initialRate.toStringAsFixed(0));
    String bulkUnit = 'Feet';
    String bulkFloor = 'Ground Floor';
    String bulkBoard = initialBoard;
    String bulkChannel = initialChannel;
    String? selectedBulkTier;

    bool applyRate = true;
    bool applyUnit = false;
    bool applyFloor = false;
    bool applyBoard = false;
    bool applyChannel = false;
    bool applyCove = false;
    final bulkCoveHeightCtrl = TextEditingController(text: '0.3');
    final bulkCoveQtyCtrl = TextEditingController(text: '4');

    const availableFloors = [
      'Ground Floor',
      'First Floor',
      'Second Floor',
      'Third Floor',
      'Terrace / Roof',
    ];

    final availableBoards = List<String>.from(RateTierConstants.availableBoards.where((b) => b != 'More')).toSet().toList();
    if (!availableBoards.contains(bulkBoard)) availableBoards.insert(0, bulkBoard);

    final availableChannels = List<String>.from(RateTierConstants.availableChannels.where((c) => c != 'More')).toSet().toList();
    if (!availableChannels.contains(bulkChannel)) availableChannels.insert(0, bulkChannel);

    const unitList = [
      {'val': 'SqFt', 'label': 'SqFt (ചതുരശ്ര അടി)'},
      {'val': 'Feet', 'label': 'Feet (അടി)'},
      {'val': 'Meters', 'label': 'Meter (മീറ്റർ)'},
      {'val': 'Inches', 'label': 'Inches (ഇഞ്ച്)'},
      {'val': 'CM', 'label': 'CM (സെ.മീ)'},
      {'val': 'mm', 'label': 'mm (മി.മീ)'},
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          titlePadding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.auto_awesome, color: Color(0xFF0284C7), size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ബൾക്ക് എഡിറ്റ് (Bulk Edit)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${checkedRooms.length} മാർക്ക് ചെയ്ത റൂമുകൾ',
                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Quick Rate Tier Selection Card
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'റേറ്റ് ടയർ പ്രീസെറ്റ് (Rate Tiers):',
                          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            // Base
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  setDialogState(() {
                                    selectedBulkTier = 'BASE';
                                    rateCtrl.text = '105';
                                    bulkBoard = 'Saint-Gobain Gyproc (Regular)';
                                    bulkChannel = 'Standard Medium G.I. (0.45mm)';
                                    applyRate = true;
                                    applyBoard = true;
                                    applyChannel = true;
                                  });
                                },
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                                  decoration: BoxDecoration(
                                    color: selectedBulkTier == 'BASE' ? const Color(0xFF37474F) : Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: selectedBulkTier == 'BASE' ? const Color(0xFF263238) : const Color(0xFFCBD5E1)),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        'BASE',
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.bold,
                                          color: selectedBulkTier == 'BASE' ? Colors.white : const Color(0xFF37474F),
                                        ),
                                        maxLines: 1,
                                      ),
                                      Text(
                                        '₹105',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                          color: selectedBulkTier == 'BASE' ? const Color(0xFF81D4FA) : const Color(0xFF0284C7),
                                        ),
                                        maxLines: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            // Premium
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  setDialogState(() {
                                    selectedBulkTier = 'PREMIUM';
                                    rateCtrl.text = '120';
                                    bulkBoard = 'USG Boral / Knauf Sheetrock';
                                    bulkChannel = 'Saint-Gobain Gypsteel ULTRA';
                                    applyRate = true;
                                    applyBoard = true;
                                    applyChannel = true;
                                  });
                                },
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                                  decoration: BoxDecoration(
                                    color: selectedBulkTier == 'PREMIUM' ? const Color(0xFFB45309) : Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: selectedBulkTier == 'PREMIUM' ? const Color(0xFF92400E) : const Color(0xFFCBD5E1)),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        'PREMIUM',
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.bold,
                                          color: selectedBulkTier == 'PREMIUM' ? Colors.white : const Color(0xFFB45309),
                                        ),
                                        maxLines: 1,
                                      ),
                                      Text(
                                        '₹120',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                          color: selectedBulkTier == 'PREMIUM' ? const Color(0xFFFDE68A) : const Color(0xFFD97706),
                                        ),
                                        maxLines: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            // Luxury
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  setDialogState(() {
                                    selectedBulkTier = 'LUXURY';
                                    rateCtrl.text = '145';
                                    bulkBoard = 'Saint-Gobain Gyproc MR (Green Board)';
                                    bulkChannel = 'Jindal Heavy G.I. Channel';
                                    applyRate = true;
                                    applyBoard = true;
                                    applyChannel = true;
                                  });
                                },
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                                  decoration: BoxDecoration(
                                    color: selectedBulkTier == 'LUXURY' ? const Color(0xFF6B21A8) : Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: selectedBulkTier == 'LUXURY' ? const Color(0xFF581C87) : const Color(0xFFCBD5E1)),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        'LUXURY',
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.bold,
                                          color: selectedBulkTier == 'LUXURY' ? Colors.white : const Color(0xFF6B21A8),
                                        ),
                                        maxLines: 1,
                                      ),
                                      Text(
                                        '₹145',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                          color: selectedBulkTier == 'LUXURY' ? const Color(0xFFE9D5FF) : const Color(0xFF7C3AED),
                                        ),
                                        maxLines: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 1. Rate Option
                  Row(
                    children: [
                      Checkbox(
                        value: applyRate,
                        onChanged: (v) => setDialogState(() => applyRate = v ?? false),
                        activeColor: const Color(0xFF0284C7),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                      const SizedBox(width: 2),
                      const Expanded(
                        child: Text(
                          '1. റേറ്റ് (₹/SqFt):',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(
                        width: 90,
                        child: TextField(
                          controller: rateCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          enabled: applyRate,
                          style: const TextStyle(fontSize: 11.5),
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                            prefixText: '₹ ',
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),

                  // 2. Unit Option
                  Row(
                    children: [
                      Checkbox(
                        value: applyUnit,
                        onChanged: (v) => setDialogState(() => applyUnit = v ?? false),
                        activeColor: const Color(0xFF0284C7),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                      const SizedBox(width: 2),
                      const Expanded(
                        child: Text(
                          '2. യൂണിറ്റ് (Unit):',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(
                        width: 105,
                        child: DropdownButtonFormField<String>(
                          isDense: true,
                          isExpanded: true,
                          initialValue: bulkUnit,
                          selectedItemBuilder: (ctx) => unitList
                              .map((u) => Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      u['val']!,
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                      maxLines: 1,
                                      softWrap: false,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ))
                              .toList(),
                          items: unitList
                              .map((u) => DropdownMenuItem(
                                    value: u['val'],
                                    child: Text(u['val']!, style: const TextStyle(fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ))
                              .toList(),
                          onChanged: applyUnit ? (v) => setDialogState(() => bulkUnit = v!) : null,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),

                  // 3. Floor Option
                  Row(
                    children: [
                      Checkbox(
                        value: applyFloor,
                        onChanged: (v) => setDialogState(() => applyFloor = v ?? false),
                        activeColor: const Color(0xFF0284C7),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                      const SizedBox(width: 2),
                      const Expanded(
                        child: Text(
                          '3. ഫ്ലോർ (Floor):',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(
                        width: 105,
                        child: DropdownButtonFormField<String>(
                          isDense: true,
                          isExpanded: true,
                          initialValue: bulkFloor,
                          selectedItemBuilder: (ctx) => availableFloors
                              .map((f) => Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      f,
                                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600),
                                      maxLines: 1,
                                      softWrap: false,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ))
                              .toList(),
                          items: availableFloors
                              .map((f) => DropdownMenuItem(
                                    value: f,
                                    child: Text(f, style: const TextStyle(fontSize: 10.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ))
                              .toList(),
                          onChanged: applyFloor ? (v) => setDialogState(() => bulkFloor = v!) : null,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // 4. ബോർഡ് ബ്രാൻഡ് പ്രത്യേക ബോക്സ് (Board Brand Box)
                  Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: applyBoard ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: applyBoard ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0),
                        width: 1.1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: applyBoard,
                              onChanged: (v) => setDialogState(() => applyBoard = v ?? false),
                              activeColor: const Color(0xFF0284C7),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.layers_outlined, size: 15, color: Color(0xFF0284C7)),
                            const SizedBox(width: 5),
                            const Expanded(
                              child: Text(
                                'ബോർഡ് ബ്രാൻഡ് (Board Brand):',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        DropdownButtonFormField<String>(
                          isDense: true,
                          isExpanded: true,
                          initialValue: availableBoards.contains(bulkBoard) ? bulkBoard : availableBoards.first,
                          selectedItemBuilder: (context) {
                            return availableBoards.map((b) {
                              return Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  b,
                                  maxLines: 1,
                                  softWrap: false,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: applyBoard ? const Color(0xFF0F172A) : Colors.grey.shade600,
                                  ),
                                ),
                              );
                            }).toList();
                          },
                          items: availableBoards
                              .map((b) => DropdownMenuItem(
                                    value: b,
                                    child: Text(
                                      b,
                                      maxLines: 1,
                                      softWrap: false,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: applyBoard ? Colors.black87 : Colors.grey.shade600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ))
                              .toList(),
                          onChanged: applyBoard ? (v) => setDialogState(() => bulkBoard = v!) : null,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                            filled: true,
                            fillColor: applyBoard ? Colors.white : Colors.grey.shade100,
                            isDense: true,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 5. ചാനൽ ബ്രാൻഡ് പ്രത്യേക ബോക്സ് (Channel Brand Box)
                  Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: applyChannel ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: applyChannel ? const Color(0xFF16A34A) : const Color(0xFFE2E8F0),
                        width: 1.1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: applyChannel,
                              onChanged: (v) => setDialogState(() => applyChannel = v ?? false),
                              activeColor: const Color(0xFF16A34A),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.grid_view_outlined, size: 15, color: Color(0xFF16A34A)),
                            const SizedBox(width: 5),
                            const Expanded(
                              child: Text(
                                'ചാനൽ ബ്രാൻഡ് (Channel Brand):',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        DropdownButtonFormField<String>(
                          isDense: true,
                          isExpanded: true,
                          initialValue: availableChannels.contains(bulkChannel) ? bulkChannel : availableChannels.first,
                          selectedItemBuilder: (context) {
                            return availableChannels.map((c) {
                              return Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  c,
                                  maxLines: 1,
                                  softWrap: false,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: applyChannel ? const Color(0xFF0F172A) : Colors.grey.shade600,
                                  ),
                                ),
                              );
                            }).toList();
                          },
                          items: availableChannels
                              .map((c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(
                                      c,
                                      maxLines: 1,
                                      softWrap: false,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: applyChannel ? Colors.black87 : Colors.grey.shade600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ))
                              .toList(),
                          onChanged: applyChannel ? (v) => setDialogState(() => bulkChannel = v!) : null,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                            filled: true,
                            fillColor: applyChannel ? Colors.white : Colors.grey.shade100,
                            isDense: true,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 6. കോവ് ലൈറ്റ് പ്രത്യേക ബോക്സ് (Cove Light: Height & Quantity)
                  Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: applyCove ? const Color(0xFFFFFBEB) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: applyCove ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0),
                        width: 1.1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: applyCove,
                              onChanged: (v) => setDialogState(() => applyCove = v ?? false),
                              activeColor: const Color(0xFFD97706),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.lightbulb_outline, size: 15, color: Color(0xFFD97706)),
                            const SizedBox(width: 5),
                            const Expanded(
                              child: Text(
                                'കോവ് ലൈറ്റ് (Cove Light):',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (applyCove) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: bulkCoveHeightCtrl,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                  decoration: const InputDecoration(
                                    labelText: 'ഹൈറ്റ് (Height)',
                                    labelStyle: TextStyle(fontSize: 10, color: Color(0xFFB45309)),
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                                    isDense: true,
                                    fillColor: Colors.white,
                                    filled: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: TextField(
                                  controller: bulkCoveQtyCtrl,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                  decoration: const InputDecoration(
                                    labelText: 'ക്വാണ്ടിറ്റി (Qty)',
                                    labelStyle: TextStyle(fontSize: 10, color: Color(0xFFB45309)),
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                                    isDense: true,
                                    fillColor: Colors.white,
                                    filled: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '* ഓരോ റൂമിന്റെയും അളവുകൾക്കനുസരിച്ച് കോവ് കാൽക്കുലേറ്റ് ചെയ്യും',
                            style: TextStyle(fontSize: 9.5, fontStyle: FontStyle.italic, color: Color(0xFF92400E)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCEL', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold, fontSize: 12)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              icon: const Icon(Icons.check, size: 15),
              label: const Text('APPLY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              onPressed: () {
                final newRate = double.tryParse(rateCtrl.text.trim());
                setState(() {
                  for (int i = 0; i < widget.ctrl.currentItems.length; i++) {
                    final item = widget.ctrl.currentItems[i];
                    if (checkedRooms.contains(item.roomName)) {
                      double itemArea = item.area;
                      String itemUnit = item.unit;
                      if (applyUnit) {
                        itemUnit = bulkUnit;
                        if (item.length > 0 && item.width > 0) {
                          final raw = item.length * item.width * (item.quantity > 0 ? item.quantity : 1.0);
                          switch (bulkUnit) {
                            case 'Meters':
                            case 'SqM':
                              itemArea = raw * 10.7639;
                              break;
                            case 'Inches':
                              itemArea = raw / 144.0;
                              break;
                            case 'CM':
                            case 'cm':
                              itemArea = raw / 929.03;
                              break;
                            case 'mm':
                              itemArea = raw * (10.7639 / 1000000.0);
                              break;
                            default:
                              itemArea = raw;
                          }
                        }
                      }

                      final finalRate = (applyRate && newRate != null) ? newRate : item.rate;

                      String updatedCeilingType = item.ceilingType;
                      if (applyBoard) {
                        updatedCeilingType = bulkBoard;
                      }

                      String? updatedBrandName = item.brandName;
                      if (applyBoard || applyChannel) {
                        final parts = (item.brandName ?? '').split('•');
                        final curBoard = parts.isNotEmpty ? parts[0].trim() : item.ceilingType;
                        final curChan = parts.length > 1 ? parts[1].trim() : '';
                        final b = applyBoard ? bulkBoard : (curBoard.isNotEmpty ? curBoard : bulkBoard);
                        final c = applyChannel ? bulkChannel : (curChan.isNotEmpty ? curChan : bulkChannel);
                        updatedBrandName = CalculatorUtils.sanitizeBrandName('$b • $c');
                      }

                      bool updatedHasCove = item.hasCove;
                      double updatedCoveWidth = item.coveWidth;
                      double updatedCoveQty = item.coveQuantity;
                      double updatedCoveLength = item.coveLength;
                      double updatedCoveRft = item.coveRft;
                      double computedCoveSqFt = 0.0;

                      if (applyCove) {
                        final h = double.tryParse(bulkCoveHeightCtrl.text) ?? 0.3;
                        final q = double.tryParse(bulkCoveQtyCtrl.text) ?? 4.0;
                        final baseLen = item.length > 0 ? item.length : (item.coveLength > 0 ? item.coveLength : 10.0);
                        final rawCoveArea = baseLen * h * (q > 0 ? q : 1.0);
                        computedCoveSqFt = rawCoveArea;
                        switch (itemUnit) {
                          case 'Meters':
                          case 'SqM':
                            computedCoveSqFt = rawCoveArea * 10.7639;
                            break;
                          case 'Inches':
                            computedCoveSqFt = rawCoveArea / 144.0;
                            break;
                          case 'CM':
                          case 'cm':
                            computedCoveSqFt = rawCoveArea / 929.03;
                            break;
                          case 'mm':
                            computedCoveSqFt = rawCoveArea * (10.7639 / 1000000.0);
                            break;
                          default:
                            computedCoveSqFt = rawCoveArea;
                        }

                        updatedHasCove = true;
                        updatedCoveWidth = h;
                        updatedCoveQty = q;
                        updatedCoveLength = baseLen;
                        updatedCoveRft = rawCoveArea;

                        if (item.hasCove || item.designName == 'Cove Light') {
                          itemArea = rawCoveArea;
                        }
                      }

                      widget.ctrl.currentItems[i] = item.copyWith(
                        rate: finalRate,
                        unit: itemUnit,
                        area: itemArea,
                        amount: (applyCove && (item.hasCove || item.designName == 'Cove Light')) 
                            ? (computedCoveSqFt * finalRate) 
                            : (itemArea * finalRate),
                        floor: applyFloor ? bulkFloor : item.floor,
                        ceilingType: updatedCeilingType,
                        brandName: updatedBrandName,
                        hasCove: updatedHasCove,
                        coveWidth: updatedCoveWidth,
                        coveQuantity: updatedCoveQty,
                        coveLength: updatedCoveLength,
                        coveRft: updatedCoveRft,
                      );
                    }
                  }
                });

                widget.ctrl.updateProjectTotals();
                widget.ctrl.triggerAutoSave();
                widget.ctrl.notifyUI();
                widget.onStateChanged();
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✓ ${checkedRooms.length} റൂമുകളിൽ ബൾക്ക് മാറ്റങ്ങൾ വിജയകരമായി പ്രയോഗിച്ചു!'),
                    backgroundColor: const Color(0xFF15803D),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _customChannelDialog(BuildContext context, int itemIndex, QuotationItem item) {
    final textCtrl = TextEditingController(text: item.brandName ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Custom Channel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: TextField(
          controller: textCtrl,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Channel Name',
            hintText: 'e.g. Jindal Heavy, Ultra',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final val = textCtrl.text.trim();
              if (val.isNotEmpty) {
                setState(() {
                  widget.ctrl.currentItems[itemIndex] = item.copyWith(brandName: val);
                });
                widget.ctrl.updateProjectTotals();
                widget.ctrl.triggerAutoSave();
                widget.onStateChanged();
              }
              Navigator.pop(ctx);
            },
            child: const Text('APPLY'),
          ),
        ],
      ),
    );
  }

  void _customBoardDialog(BuildContext context, int itemIndex, QuotationItem item) {
    final textCtrl = TextEditingController(text: item.ceilingType);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Custom Board', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: TextField(
          controller: textCtrl,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Board Type / Name',
            hintText: 'e.g. Hilux 8mm, PVC Fluted',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final val = textCtrl.text.trim();
              if (val.isNotEmpty) {
                setState(() {
                  widget.ctrl.currentItems[itemIndex] = item.copyWith(ceilingType: val);
                });
                widget.ctrl.updateProjectTotals();
                widget.ctrl.triggerAutoSave();
                widget.onStateChanged();
              }
              Navigator.pop(ctx);
            },
            child: const Text('APPLY'),
          ),
        ],
      ),
    );
  }

  void _renameRoomDialog(BuildContext context, String currentRoomName, List<int> indices) {
    final nameCtrl = TextEditingController(text: currentRoomName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Rename Room', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Room Name',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E293B),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final newName = nameCtrl.text.trim();
              if (newName.isNotEmpty) {
                setState(() {
                  for (final idx in indices) {
                    final it = widget.ctrl.currentItems[idx];
                    widget.ctrl.currentItems[idx] = it.copyWith(roomName: newName);
                  }
                });
                widget.ctrl.triggerAutoSave();
                widget.onStateChanged();
              }
              Navigator.pop(ctx);
            },
            child: const Text('RENAME'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteRoom(BuildContext context, String roomName, List<int> indices) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text('Delete $roomName?', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to remove $roomName and all its ${indices.length} entries?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            onPressed: () {
              setState(() {
                final sortedIndices = List<int>.from(indices)..sort((a, b) => b.compareTo(a));
                for (final idx in sortedIndices) {
                  widget.ctrl.deleteQuotationItem(idx);
                }
              });
              widget.ctrl.updateProjectTotals();
              widget.ctrl.triggerAutoSave();
              widget.onStateChanged();
              Navigator.pop(ctx);
            },
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  Future<void> _generateSelectedPdf(BuildContext context, Set<int> selectedIndices, {required bool isShare}) async {
    final selectedItems = selectedIndices
        .where((idx) => idx >= 0 && idx < widget.ctrl.currentItems.length)
        .map((idx) => widget.ctrl.currentItems[idx])
        .where((it) => !it.isHidden)
        .toList();

    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('സെലക്ട് ചെയ്ത ഐറ്റങ്ങൾ ഒന്നുമില്ല (അളവുകൾ നൽകുകയോ ഹൈഡ് മാറ്റുകയോ ചെയ്യുക)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final totalAmt = selectedItems.fold(0.0, (s, it) => s + (it.amount > 0 ? it.amount : (it.area * it.rate)));
    final now = DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd').format(now);
    final displayDateStr = DateFormat('dd-MM-yyyy').format(now);
    final fileName = 'PCM_${widget.ctrl.unitNumberController.text}_$displayDateStr.pdf';

    final paidAmt = widget.ctrl.currentPayments.fold(0.0, (s, p) => s + p.amount);
    final quota = Quotation(
      id: widget.ctrl.activeProjectId,
      unitNumber: widget.ctrl.unitNumberController.text,
      clientName: widget.ctrl.clientNameController.text.isEmpty ? 'SITE DRAFT' : widget.ctrl.clientNameController.text,
      clientPhone: widget.ctrl.clientPhoneController.text,
      clientLocation: widget.ctrl.clientLocationController.text,
      locationFolder: widget.ctrl.folderController.text.isNotEmpty ? widget.ctrl.folderController.text : widget.ctrl.clientLocationController.text,
      date: dateStr,
      totalAmount: totalAmt,
      paidAmount: paidAmt,
      balanceAmount: (totalAmt - paidAmt).clamp(0, double.infinity),
      items: selectedItems,
      materials: MaterialEngine.calculateBOM(selectedItems),
      payments: widget.ctrl.currentPayments,
      manualAmount: double.tryParse(widget.ctrl.manualAmountController.text) ?? 0,
      manualWeight: double.tryParse(widget.ctrl.manualWeightController.text) ?? 0,
      originalAmount: double.tryParse(widget.ctrl.originalAmountController.text),
      revisionNote: widget.ctrl.revisionNoteController.text.trim().isNotEmpty ? widget.ctrl.revisionNoteController.text.trim() : null,
      discount: widget.ctrl.discountPercent,
      projectStatus: widget.ctrl.projectStatus,
      approvalSignature: widget.ctrl.approvalSignature,
      includeWastage: widget.ctrl.includeWastage,
      includeDigitalSignature: widget.ctrl.includeDigitalSignature,
      includeBankDetails: widget.ctrl.includeBankDetails,
      rateTiers: widget.ctrl.rateTiers.map((t) => t.toMap()).toList(),
      partnerName: widget.ctrl.headerNameController.text.trim(),
      partnerPhone: widget.ctrl.headerPhoneController.text.trim(),
      partnerLocation: widget.ctrl.headerLocationController.text.trim(),
    );

    if (isShare) {
      final pdfBytes = await PdfService.generateQuotation(
        clientName: quota.clientName,
        clientLocation: quota.clientLocation,
        clientPhone: quota.clientPhone,
        unitNumber: quota.unitNumber,
        items: selectedItems,
        materials: quota.materials,
        totalAmount: quota.totalAmount,
        paidAmount: quota.paidAmount,
        balanceAmount: quota.balanceAmount,
        payments: quota.payments,
        includeWastage: widget.ctrl.includeWastage,
        includeDigitalSignature: widget.ctrl.includeDigitalSignature,
        includeBankDetails: widget.ctrl.includeBankDetails,
        originalAmount: quota.originalAmount,
        revisionNote: quota.revisionNote,
        approvalSignature: quota.approvalSignature,
        authorizedName: widget.ctrl.headerNameController.text.trim(),
        authorizedPhone: widget.ctrl.headerPhoneController.text.trim(),
        authorizedLocation: widget.ctrl.headerLocationController.text.trim(),
        selectedTierIds: widget.ctrl.selectedTierIds,
        rateTiers: widget.ctrl.rateTiers.map((t) => t.toMap()).toList(),
        selectedTiersList: widget.ctrl.rateTiers.where((t) => widget.ctrl.selectedTierIds.contains(t.id) || widget.ctrl.selectedTierIds.contains(t.name) || t.isSelected).map((t) => t.toMap()).toList(),
      );
      await PdfService.sharePdf(pdfBytes, fileName);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: Text('ക്വട്ടേഷൻ പ്രിവ്യൂ (${quota.unitNumber})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              backgroundColor: Colors.brown[800],
              foregroundColor: Colors.white,
              actions: [
                IconButton(
                  icon: const Icon(Icons.share),
                  tooltip: 'PDF ഷെയർ ചെയ്യുക',
                  onPressed: () async {
                    final pdfBytes = await PdfService.generateQuotation(
                      clientName: quota.clientName,
                      clientLocation: quota.clientLocation,
                      clientPhone: quota.clientPhone,
                      unitNumber: quota.unitNumber,
                      items: selectedItems,
                      materials: quota.materials,
                      totalAmount: quota.totalAmount,
                      paidAmount: quota.paidAmount,
                      balanceAmount: quota.balanceAmount,
                      payments: quota.payments,
                      includeWastage: widget.ctrl.includeWastage,
                      includeDigitalSignature: widget.ctrl.includeDigitalSignature,
                      includeBankDetails: widget.ctrl.includeBankDetails,
                      originalAmount: quota.originalAmount,
                      revisionNote: quota.revisionNote,
                      approvalSignature: quota.approvalSignature,
                      authorizedName: widget.ctrl.headerNameController.text.trim(),
                      authorizedPhone: widget.ctrl.headerPhoneController.text.trim(),
                      authorizedLocation: widget.ctrl.headerLocationController.text.trim(),
                      selectedTierIds: widget.ctrl.selectedTierIds,
                      rateTiers: widget.ctrl.rateTiers.map((t) => t.toMap()).toList(),
                      selectedTiersList: widget.ctrl.rateTiers.where((t) => widget.ctrl.selectedTierIds.contains(t.id) || widget.ctrl.selectedTierIds.contains(t.name) || t.isSelected).map((t) => t.toMap()).toList(),
                    );
                    await PdfService.sharePdf(pdfBytes, fileName);
                  },
                ),
              ],
            ),
            body: PdfPreview(
              build: (format) => PdfService.generateQuotation(
                clientName: quota.clientName,
                clientLocation: quota.clientLocation,
                clientPhone: quota.clientPhone,
                unitNumber: quota.unitNumber,
                items: selectedItems,
                materials: quota.materials,
                totalAmount: quota.totalAmount,
                paidAmount: quota.paidAmount,
                balanceAmount: quota.balanceAmount,
                payments: quota.payments,
                includeWastage: widget.ctrl.includeWastage,
                includeDigitalSignature: widget.ctrl.includeDigitalSignature,
                includeBankDetails: widget.ctrl.includeBankDetails,
                originalAmount: quota.originalAmount,
                revisionNote: quota.revisionNote,
                approvalSignature: quota.approvalSignature,
                authorizedName: widget.ctrl.headerNameController.text.trim(),
                authorizedPhone: widget.ctrl.headerPhoneController.text.trim(),
                authorizedLocation: widget.ctrl.headerLocationController.text.trim(),
                selectedTierIds: widget.ctrl.selectedTierIds,
                rateTiers: widget.ctrl.rateTiers.map((t) => t.toMap()).toList(),
                selectedTiersList: widget.ctrl.rateTiers.where((t) => widget.ctrl.selectedTierIds.contains(t.id) || widget.ctrl.selectedTierIds.contains(t.name) || t.isSelected).map((t) => t.toMap()).toList(),
              ),
              pdfFileName: fileName,
              canChangeOrientation: false,
              canChangePageFormat: false,
              canDebug: false,
            ),
          ),
        ),
      );
    }
  }

  void _showPdfSelectionDialog(BuildContext context, {List<int>? targetIndices}) {
    final availableIndices = targetIndices ?? List.generate(widget.ctrl.currentItems.length, (i) => i);
    final selectedIndices = availableIndices.where((idx) => !widget.ctrl.currentItems[idx].isHidden).toSet();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          double totalSelectedArea = 0;
          double totalSelectedAmount = 0;
          for (final idx in selectedIndices) {
            final it = widget.ctrl.currentItems[idx];
            totalSelectedArea += it.area;
            totalSelectedAmount += it.amount > 0 ? it.amount : (it.area * it.rate);
          }

          return Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.picture_as_pdf, color: Color(0xFF16A34A), size: 24),
                        SizedBox(width: 8),
                        Text(
                          'PDF ഐറ്റം സെലക്ഷൻ (Print / Share)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'PDF-ൽ ഉൾപ്പെടുത്തേണ്ട ഐറ്റങ്ങൾ താഴെ മാർക്ക് ചെയ്യുക. മാർക്ക് ചെയ്യുന്നവ മാത്രമായിരിക്കും PDF-ൽ വരുന്നത്.',
                  style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.select_all, size: 16, color: Color(0xFF0284C7)),
                      label: const Text('എല്ലാം സെലക്ട് ചെയ്യുക', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
                      onPressed: () {
                        setModalState(() {
                          selectedIndices.clear();
                          selectedIndices.addAll(availableIndices);
                        });
                      },
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.deselect, size: 16, color: Colors.red),
                      label: const Text('Clear All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red)),
                      onPressed: () {
                        setModalState(() {
                          selectedIndices.clear();
                        });
                      },
                    ),
                  ],
                ),
                const Divider(height: 12),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: availableIndices.length,
                    itemBuilder: (context, i) {
                      final idx = availableIndices[i];
                      final it = widget.ctrl.currentItems[idx];
                      final isSelected = selectedIndices.contains(idx);
                      final amt = it.amount > 0 ? it.amount : (it.area * it.rate);

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 3),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: CheckboxListTile(
                          dense: true,
                          value: isSelected,
                          activeColor: const Color(0xFF16A34A),
                          title: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.brown.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(it.roomName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10.5, color: Colors.brown.shade900)),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  it.designName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (it.isHidden)
                                Container(
                                  margin: const EdgeInsets.only(left: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.red.shade200),
                                  ),
                                  child: const Text('Hidden', style: TextStyle(fontSize: 8.5, color: Colors.red, fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                          subtitle: Text(
                            '${it.length} × ${it.width} ${it.unit} (${CalculatorUtils.formatNumber(it.area)} SQFT) • ₹${CalculatorUtils.formatIndianCurrency(amt)}',
                            style: const TextStyle(fontSize: 10.5, color: Color(0xFF475569)),
                          ),
                          onChanged: (val) {
                            setModalState(() {
                              if (val == true) {
                                selectedIndices.add(idx);
                              } else {
                                selectedIndices.remove(idx);
                              }
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
                const Divider(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'സെലക്ട് ചെയ്തവ: ${selectedIndices.length} എണ്ണം (${CalculatorUtils.formatNumber(totalSelectedArea)} SQFT)',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF334155)),
                      ),
                      Text(
                        '₹${CalculatorUtils.formatIndianCurrency(totalSelectedAmount)}',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF16A34A)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.picture_as_pdf, size: 18),
                        label: const Text('PDF പ്രിവ്യൂ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        onPressed: selectedIndices.isEmpty ? null : () {
                          Navigator.pop(ctx);
                          _generateSelectedPdf(context, selectedIndices, isShare: false);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.share, size: 18),
                        label: const Text('PDF ഷെയർ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        onPressed: selectedIndices.isEmpty ? null : () {
                          Navigator.pop(ctx);
                          _generateSelectedPdf(context, selectedIndices, isShare: true);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.ctrl,
      builder: (context, _) {
        final hasItems = widget.ctrl.currentItems.isNotEmpty;

        // Group items by room name
        final Map<String, List<int>> roomMap = {};
        for (int i = 0; i < widget.ctrl.currentItems.length; i++) {
          final item = widget.ctrl.currentItems[i];
          final rName = item.roomName.trim().isEmpty ? 'Room 1' : item.roomName.trim();
          roomMap.putIfAbsent(rName, () => []).add(i);
        }

        final checkedRooms = _roomCheckboxes.entries.where((e) => e.value).map((e) => e.key).toList();
        final roomEntries = roomMap.entries.toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8, right: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'MEASUREMENT SHEET (CARD VIEW)',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      fontSize: 11.5,
                      color: AppColors.labelColor,
                    ),
                  ),
                  if (hasItems)
                    InkWell(
                      onTap: () => _showPdfSelectionDialog(context),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.picture_as_pdf, size: 14, color: Color(0xFF16A34A)),
                            SizedBox(width: 4),
                            Text(
                              'PDF സെലക്ഷൻ ലിസ്റ്റ്',
                              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Empty Placeholder Card when no measurement items exist
            if (widget.ctrl.currentItems.isEmpty) ...[
              Container(
                key: const ValueKey('empty_measurement_sheet_placeholder'),
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 15),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: const [
                    Icon(Icons.assignment_outlined, color: Color(0xFF94A3B8), size: 36),
                    SizedBox(height: 8),
                    Text(
                      'MEASUREMENT SHEET IS EMPTY',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.8, color: Color(0xFF475569)),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'അളവുകൾ നൽകാൻ മുകളിലെ "ADD TO SHEET" ബട്ടൺ അമർത്തുക\n(Enter dimensions above and tap ADD TO SHEET)',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B), height: 1.3),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Checked Rooms Bulk Edit Action Bar (Responsive)
              if (checkedRooms.isNotEmpty) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle, size: 16, color: Color(0xFF0284C7)),
                          const SizedBox(width: 6),
                          Text(
                            '${checkedRooms.length} റൂമുകൾ മാർക്ക് ചെയ്തു',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0369A1)),
                          ),
                        ],
                      ),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () {
                              setState(() {
                                _roomCheckboxes.clear();
                                _itemCheckboxes.clear();
                              });
                            },
                            child: const Text('Clear', style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold)),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0284C7),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.auto_awesome, size: 13),
                            label: const Text('ബൾക്ക് എഡിറ്റ്', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                            onPressed: () => _showBulkEditForCheckedRooms(context, checkedRooms),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF16A34A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.picture_as_pdf, size: 13),
                            label: const Text('PDF', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                            onPressed: () {
                              final targetIndices = <int>{};
                              for (final r in checkedRooms) {
                                if (roomMap.containsKey(r)) {
                                  targetIndices.addAll(roomMap[r]!);
                                }
                              }
                              for (final e in _itemCheckboxes.entries) {
                                if (e.value) targetIndices.add(e.key);
                              }
                              _showPdfSelectionDialog(context, targetIndices: targetIndices.toList());
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              // List of Room Master Cards with explicit shrinkWrap & NeverScrollableScrollPhysics for mobile
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: roomEntries.length,
                itemBuilder: (context, index) {
                  final entry = roomEntries[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _buildRoomMasterCard(context, entry.key, entry.value),
                  );
                },
              ),
            ],

            // START / CALCULATE (RE-PROCESS ALL) Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE2E8F0),
                  foregroundColor: const Color(0xFF334155),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  widget.ctrl.updateProjectTotals();
                  widget.ctrl.triggerAutoSave();
                  widget.ctrl.notifyUI();
                  widget.onStateChanged();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✓ Measurement sheet recalculated & synced successfully!'),
                      backgroundColor: Color(0xFF1E293B),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.bolt, color: Colors.amber, size: 22),
                label: const Text(
                  'START / CALCULATE (RE-PROCESS ALL)',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),
          ],
        );
      },
    );
  }


  Widget _buildRoomMasterCard(BuildContext context, String roomName, List<int> indices) {
    double roomTotalArea = 0.0;
    double roomTotalAmount = 0.0;
    for (final idx in indices) {
      final it = widget.ctrl.currentItems[idx];
      if (it.isHidden) continue;

      double factor = 1.0;
      if (it.unit == 'Meters' || it.unit == 'SqM') {
        factor = 10.764;
      } else if (it.unit == 'Inches') {
        factor = 1.0 / 144.0;
      } else if (it.unit == 'mm') {
        factor = 10.764 / 1000000.0;
      }
      roomTotalArea += it.area * factor;
      roomTotalAmount += it.amount > 0 ? it.amount : (it.area * factor * it.rate);
    }

    final firstItem = indices.isNotEmpty ? widget.ctrl.currentItems[indices.first] : null;
    final floorName = firstItem?.floor.isNotEmpty == true ? firstItem!.floor : 'Ground Floor';
    final roomNum = firstItem?.roomNumber.isNotEmpty == true ? 'Room #${firstItem!.roomNumber}' : '';

    final designTypesInRoom = <String>{};
    for (final idx in indices) {
      final it = widget.ctrl.currentItems[idx];
      designTypesInRoom.add(PdfDesignCategoryHelper.getDesignCategory(it));
    }
    final designsSummary = designTypesInRoom.join(' • ');

    final isChecked = (_roomCheckboxes[roomName] ?? false) || (indices.isNotEmpty && indices.every((i) => _itemCheckboxes[i] == true));
    final isRoomAllHidden = indices.isNotEmpty && indices.every((i) => widget.ctrl.currentItems[i].isHidden);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRoomAllHidden ? const Color(0xFFFCA5A5) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Room Header Row
          Row(
            children: [
              // Checkbox
              SizedBox(
                width: 28,
                height: 28,
                child: Checkbox(
                  value: isChecked,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  activeColor: const Color(0xFF1E293B),
                  onChanged: (val) {
                    setState(() {
                      final newVal = val ?? false;
                      _roomCheckboxes[roomName] = newVal;
                      for (final idx in indices) {
                        _itemCheckboxes[idx] = newVal;
                      }
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),

              // Camera Box
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('📷 Site photo capture for $roomName'),
                      backgroundColor: const Color(0xFF1E293B),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFCBD5E1), width: 0.8),
                  ),
                  child: const Icon(Icons.camera_alt_outlined, size: 19, color: Color(0xFF64748B)),
                ),
              ),
              const SizedBox(width: 10),

              // Room Title & Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            roomName.toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              letterSpacing: 0.5,
                              color: isRoomAllHidden ? const Color(0xFF94A3B8) : const Color(0xFF1E293B),
                              decoration: isRoomAllHidden ? TextDecoration.lineThrough : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () => _renameRoomDialog(context, roomName, indices),
                          child: const Icon(Icons.edit, size: 14, color: Color(0xFF64748B)),
                        ),
                        if (isRoomAllHidden) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFFFECACA)),
                            ),
                            child: const Text('PDF Excluded', style: TextStyle(fontSize: 8.5, color: Colors.red, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 2,
                      children: [
                        Text(
                          '$floorName${roomNum.isNotEmpty ? ' • $roomNum' : ''}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${indices.length} ${indices.length == 1 ? 'Entry' : 'Entries'}: $designsSummary',
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0284C7),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Action Icons on Top Right: Blue Eye Toggle, Green PDF Icon, Delete Room
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      isRoomAllHidden ? Icons.visibility_off : Icons.visibility,
                      color: isRoomAllHidden ? Colors.red.shade400 : const Color(0xFF0284C7),
                      size: 20,
                    ),
                    tooltip: isRoomAllHidden
                        ? 'റൂം PDF-ൽ ഉൾപ്പെടുത്തുക (Click to Show in PDF)'
                        : 'റൂം PDF-ൽ നിന്ന് ഒഴിവാക്കുക (Click to Hide from PDF)',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      setState(() {
                        final newHidden = !isRoomAllHidden;
                        for (final idx in indices) {
                          widget.ctrl.currentItems[idx] = widget.ctrl.currentItems[idx].copyWith(isHidden: newHidden);
                        }
                      });
                      widget.ctrl.updateProjectTotals();
                      widget.ctrl.triggerAutoSave();
                      widget.onStateChanged();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isRoomAllHidden
                              ? '✓ "$roomName" PDF-ൽ ഉൾപ്പെടുത്തി.'
                              : '🚫 "$roomName" PDF-ൽ നിന്ന് ഒഴിവാക്കി (ഹൈഡ് ചെയ്തു).'),
                          duration: const Duration(seconds: 1),
                          backgroundColor: isRoomAllHidden ? const Color(0xFF0284C7) : Colors.red.shade800,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.picture_as_pdf, color: Color(0xFF16A34A), size: 20),
                    tooltip: 'PDF ലിസ്റ്റ് (പ്രിന്റ് / ഷെയർ)',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _showPdfSelectionDialog(context, targetIndices: indices),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Color(0xFFDC2626), size: 20),
                    tooltip: 'Delete Room',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _confirmDeleteRoom(context, roomName, indices),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Sub-Cards for Each Entry (Explicit ListView builder with shrinkWrap & NeverScrollableScrollPhysics)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: indices.length,
            itemBuilder: (context, sIdx) {
              return _buildEntrySubCard(context, indices[sIdx], sIdx, roomName, indices);
            },
          ),

          const SizedBox(height: 12),

          // Room Total Footer Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFCBD5E1), width: 1.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '* ${roomName.toUpperCase()} TOTAL (${CalculatorUtils.formatNumber(roomTotalArea, decimalDigits: 1)} SQFT):',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Color(0xFF1E293B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '₹${CalculatorUtils.formatIndianCurrency(roomTotalAmount)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14.5,
                        color: Color(0xFF15803D),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntrySubCard(BuildContext context, int itemIndex, int stepIndex, String roomName, List<int> roomIndices) {
    final item = widget.ctrl.currentItems[itemIndex];

    final String cardRoomName = item.roomName.isNotEmpty ? item.roomName.toUpperCase() : roomName.toUpperCase();
    final String cardFloor = item.floor.isNotEmpty ? item.floor : 'Ground Floor';
    final String cardRoomNum = item.roomNumber.isNotEmpty ? 'Room #${item.roomNumber}' : '';
    final String roomInfoLabel = '$cardFloor${cardRoomNum.isNotEmpty ? ' • $cardRoomNum' : ''} • $cardRoomName';

    Color cardBorderColor;
    Color cardBgColor;
    Color badgeBgColor;
    Color badgeTextColor;

    if (item.isHidden) {
      cardBorderColor = Colors.red.shade300;
      cardBgColor = const Color(0xFFFFF5F5);
      badgeBgColor = const Color(0xFFFEE2E2);
      badgeTextColor = Colors.red.shade700;
    } else if (item.hasCove || item.designName.toLowerCase().contains('cove')) {
      // Cove / Cove Design -> Orange
      cardBorderColor = Colors.orange.shade300;
      cardBgColor = const Color(0xFFFFFBEB);
      badgeBgColor = Colors.orange.shade100;
      badgeTextColor = Colors.orange.shade900;
    } else if (item.hasCentralDesign) {
      final name = item.designName.toLowerCase();
      if (name.contains('round') || name.contains('curve') || name.contains('custom') || name.contains('circle') || name.contains('radius')) {
        // Center Round / Curve -> Purple
        cardBorderColor = Colors.purple.shade300;
        cardBgColor = const Color(0xFFFAF5FF);
        badgeBgColor = Colors.purple.shade100;
        badgeTextColor = Colors.purple.shade900;
      } else {
        // Center -> Green
        cardBorderColor = Colors.green.shade300;
        cardBgColor = const Color(0xFFF0FDF4);
        badgeBgColor = Colors.green.shade100;
        badgeTextColor = Colors.green.shade900;
      }
    } else {
      // Plain -> Red
      cardBorderColor = Colors.red.shade300;
      cardBgColor = const Color(0xFFFEF2F2);
      badgeBgColor = Colors.red.shade100;
      badgeTextColor = Colors.red.shade800;
    }

    String designBadgeText = item.designName.isNotEmpty ? item.designName : (item.ceilingType.isNotEmpty ? item.ceilingType : 'Plain Design');
    if (item.hasCentralDesign && !item.isCeilingDesign) {
      designBadgeText = 'Center Design';
    } else if (designBadgeText == 'Plain' || designBadgeText == 'Ceiling Design' || designBadgeText == 'Plain Design' || designBadgeText == 'Standard Design' || designBadgeText == 'Plain Ceiling' || (!item.hasCove && !item.hasCentralDesign)) {
      designBadgeText = 'Plain Design';
    }
    double factor = 1.0;
    if (item.unit == 'Meters' || item.unit == 'SqM') {
      factor = 10.764;
    } else if (item.unit == 'Inches') {
      factor = 1.0 / 144.0;
    } else if (item.unit == 'mm') {
      factor = 10.764 / 1000000.0;
    }
    final itemAmount = item.amount > 0 ? item.amount : (item.area * factor * item.rate);

    // Current Channel & Board with clean fallback
    final currentChannel = (item.brandName != null && item.brandName!.isNotEmpty)
        ? item.brandName!
        : RateTierConstants.availableChannels.first;

    final currentBoard = item.ceilingType.isNotEmpty
        ? item.ceilingType
        : RateTierConstants.availableBoards.first;

    final channelOptions = List<String>.from(RateTierConstants.availableChannels.where((c) => c != 'More')).toSet().toList();
    if (!channelOptions.contains(currentChannel)) {
      channelOptions.insert(0, currentChannel);
    }

    final boardOptions = List<String>.from(RateTierConstants.availableBoards.where((b) => b != 'More')).toSet().toList();
    if (!boardOptions.contains(currentBoard)) {
      boardOptions.insert(0, currentBoard);
    }

    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorderColor, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              children: [
                InkWell(
                  onTap: () => _showFloorSummaryDialog(context, cardFloor),
                  child: Text(
                    cardFloor,
                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF0284C7), decoration: TextDecoration.underline),
                  ),
                ),
                if (cardRoomNum.isNotEmpty) ...[
                  const Text('•', style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
                  InkWell(
                    onTap: () => _showRoomNumberSummaryDialog(context, item.roomNumber, cardFloor),
                    child: Text(
                      cardRoomNum,
                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFFD97706), decoration: TextDecoration.underline),
                    ),
                  ),
                ],
                const Text('•', style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
                InkWell(
                  onTap: () => _showRoomSummaryDialog(context, cardRoomName),
                  child: Text(
                    cardRoomName,
                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF16A34A), decoration: TextDecoration.underline),
                  ),
                ),
              ],
            ),
          ),
          if (isMobile) ...[
            // Mobile Top Row: Checkbox, Badge, Action Icons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _itemCheckboxes[itemIndex] ?? false,
                        activeColor: const Color(0xFF0284C7),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        onChanged: (val) {
                          setState(() {
                            _itemCheckboxes[itemIndex] = val ?? false;
                            final allChecked = roomIndices.isNotEmpty && roomIndices.every((idx) => _itemCheckboxes[idx] == true);
                            _roomCheckboxes[roomName] = allChecked;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: badgeBgColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        designBadgeText,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 10.5,
                          color: badgeTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () {
                        setState(() {
                          final newHidden = !item.isHidden;
                          widget.ctrl.currentItems[itemIndex] = item.copyWith(isHidden: newHidden);
                        });
                        widget.ctrl.updateProjectTotals();
                        widget.ctrl.triggerAutoSave();
                        widget.onStateChanged();
                      },
                      child: Icon(
                        item.isHidden ? Icons.visibility_off : Icons.visibility,
                        size: 18,
                        color: item.isHidden ? Colors.red.shade400 : const Color(0xFF0284C7),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        QuickAddBottomSheet.show(
                          context,
                          widget.ctrl,
                          Provider.of<LanguageProvider>(context, listen: false),
                          existingItem: item,
                          existingIndex: itemIndex,
                        );
                      },
                      child: const Icon(Icons.edit_outlined, size: 17, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        setState(() {
                          widget.ctrl.deleteQuotationItem(itemIndex);
                        });
                        widget.ctrl.updateProjectTotals();
                        widget.ctrl.triggerAutoSave();
                        widget.onStateChanged();
                      },
                      child: const Icon(Icons.delete_outline, size: 17, color: Color(0xFFDC2626)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 5),

            // Mobile Dimensions & SQFT + Amount Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${item.length > 0 ? "${item.length} × ${item.width} ${item.unit} • " : ""}${CalculatorUtils.formatNumber(item.area)} SQFT',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11.5,
                      color: item.isHidden ? const Color(0xFF94A3B8) : const Color(0xFF1E293B),
                      decoration: item.isHidden ? TextDecoration.lineThrough : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '₹${CalculatorUtils.formatIndianCurrency(itemAmount)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    color: item.isHidden ? const Color(0xFF94A3B8) : const Color(0xFF15803D),
                    decoration: item.isHidden ? TextDecoration.lineThrough : null,
                  ),
                ),
              ],
            ),
          ] else ...[
            // Desktop Layout
            Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _itemCheckboxes[itemIndex] ?? false,
                    activeColor: const Color(0xFF0284C7),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onChanged: (val) {
                      setState(() {
                        _itemCheckboxes[itemIndex] = val ?? false;
                        final allChecked = roomIndices.isNotEmpty && roomIndices.every((idx) => _itemCheckboxes[idx] == true);
                        _roomCheckboxes[roomName] = allChecked;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: badgeBgColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      designBadgeText,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        color: badgeTextColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  flex: 4,
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          '${item.length} × ${item.width} ${item.unit} • ${CalculatorUtils.formatNumber(item.area)} SQFT',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 10.5,
                            color: item.isHidden ? const Color(0xFF94A3B8) : const Color(0xFF1E293B),
                            decoration: item.isHidden ? TextDecoration.lineThrough : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (item.isHidden) ...[
                        const SizedBox(width: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(color: const Color(0xFFFCA5A5), width: 0.8),
                          ),
                          child: const Text('PDF Excluded', style: TextStyle(fontSize: 8, color: Colors.red, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  flex: 3,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      '₹${CalculatorUtils.formatIndianCurrency(itemAmount)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12.5,
                        color: item.isHidden ? const Color(0xFF94A3B8) : const Color(0xFF15803D),
                        decoration: item.isHidden ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () {
                        setState(() {
                          final newHidden = !item.isHidden;
                          widget.ctrl.currentItems[itemIndex] = item.copyWith(isHidden: newHidden);
                        });
                        widget.ctrl.updateProjectTotals();
                        widget.ctrl.triggerAutoSave();
                        widget.onStateChanged();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(item.isHidden
                                ? '✓ "${item.designName}" PDF-ൽ ഉൾപ്പെടുത്തി.'
                                : '🚫 "${item.designName}" PDF-ൽ നിന്ന് ഒഴിവാക്കി (ഹൈഡ് ചെയ്തു).'),
                            duration: const Duration(seconds: 1),
                            backgroundColor: item.isHidden ? const Color(0xFF0284C7) : Colors.red.shade800,
                          ),
                        );
                      },
                      child: Icon(
                        item.isHidden ? Icons.visibility_off : Icons.visibility,
                        size: 16,
                        color: item.isHidden ? Colors.red.shade400 : const Color(0xFF0284C7),
                      ),
                    ),
                    const SizedBox(width: 5),
                    InkWell(
                      onTap: () {
                        QuickAddBottomSheet.show(
                          context,
                          widget.ctrl,
                          Provider.of<LanguageProvider>(context, listen: false),
                          existingItem: item,
                          existingIndex: itemIndex,
                        );
                      },
                      child: const Icon(Icons.edit_outlined, size: 15, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(width: 5),
                    InkWell(
                      onTap: () {
                        setState(() {
                          widget.ctrl.deleteQuotationItem(itemIndex);
                        });
                        widget.ctrl.updateProjectTotals();
                        widget.ctrl.triggerAutoSave();
                        widget.onStateChanged();
                      },
                      child: const Icon(Icons.delete_outline, size: 15, color: Color(0xFFDC2626)),
                    ),
                  ],
                ),
              ],
            ),
          ],

          const SizedBox(height: 7),

          // Bottom Controls Row: Rate Pill, Channel (Ch) Pill, Board (Bd) Pill
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // 1. Rate Pill
                InkWell(
                  onTap: () => _editRateDialog(context, itemIndex, item),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF7DD3FC), width: 1.0),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Rate: ₹${CalculatorUtils.formatIndianCurrency(item.rate)} / ${item.unit}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 10.5,
                            color: Color(0xFF0369A1),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.edit, size: 11, color: Color(0xFF0284C7)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // 2. Channel (Ch) Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFBAE6FD), width: 1.0),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.view_column_outlined, size: 13, color: Color(0xFF0284C7)),
                      const SizedBox(width: 4),
                      DropdownButton<String>(
                        value: currentChannel,
                        underline: const SizedBox(),
                        isDense: true,
                        menuMaxHeight: 280,
                        icon: const Icon(Icons.arrow_drop_down, size: 16, color: Color(0xFF0284C7)),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10.5, color: Color(0xFF0369A1)),
                        items: [
                          ...channelOptions.map((c) => DropdownMenuItem(value: c, child: Text('Ch: $c'))),
                          const DropdownMenuItem(value: '__MORE__', child: Text('+ More...')),
                        ],
                        onChanged: (val) {
                          if (val == '__MORE__') {
                            _customChannelDialog(context, itemIndex, item);
                          } else if (val != null) {
                            setState(() {
                              widget.ctrl.currentItems[itemIndex] = item.copyWith(brandName: val);
                            });
                            widget.ctrl.updateProjectTotals();
                            widget.ctrl.triggerAutoSave();
                            widget.onStateChanged();
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),

                // 3. Board (Bd) Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFFDE68A), width: 1.0),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.diamond_outlined, size: 13, color: Color(0xFFD97706)),
                      const SizedBox(width: 4),
                      DropdownButton<String>(
                        value: currentBoard,
                        underline: const SizedBox(),
                        isDense: true,
                        menuMaxHeight: 280,
                        icon: const Icon(Icons.arrow_drop_down, size: 16, color: Color(0xFFD97706)),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10.5, color: Color(0xFFB45309)),
                        items: [
                          ...boardOptions.map((b) => DropdownMenuItem(value: b, child: Text('Bd: $b'))),
                          const DropdownMenuItem(value: '__MORE__', child: Text('+ More...')),
                        ],
                        onChanged: (val) {
                          if (val == '__MORE__') {
                            _customBoardDialog(context, itemIndex, item);
                          } else if (val != null) {
                            setState(() {
                              widget.ctrl.currentItems[itemIndex] = item.copyWith(ceilingType: val);
                            });
                            widget.ctrl.updateProjectTotals();
                            widget.ctrl.triggerAutoSave();
                            widget.onStateChanged();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showRoomSummaryDialog(BuildContext context, String roomName) {
    final itemsInRoom = widget.ctrl.currentItems.where((i) => i.roomName.toUpperCase() == roomName.toUpperCase()).toList();
    final counts = <String, int>{};
    for (var it in itemsInRoom) {
      final cat = PdfDesignCategoryHelper.getDesignCategory(it);
      counts[cat] = (counts[cat] ?? 0) + 1;
    }
    final breakdown = counts.entries.map((e) => '${e.key}: ${e.value}').join('\n• ');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.meeting_room, color: Color(0xFF0284C7)),
            const SizedBox(width: 8),
            Expanded(child: Text('Room Summary: $roomName', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Entries: ${itemsInRoom.length}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B))),
            const SizedBox(height: 8),
            const Text('Design Breakdown:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF64748B))),
            const SizedBox(height: 4),
            Text(counts.isEmpty ? 'No entries' : '• $breakdown', style: const TextStyle(fontSize: 12, color: Color(0xFF334155))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showFloorSummaryDialog(BuildContext context, String floorName) {
    final itemsOnFloor = widget.ctrl.currentItems.where((i) => (i.floor.isNotEmpty ? i.floor : 'Ground Floor').toUpperCase() == floorName.toUpperCase()).toList();
    final roomsOnFloor = itemsOnFloor.map((i) => i.roomName).toSet();
    final counts = <String, int>{};
    for (var it in itemsOnFloor) {
      final cat = PdfDesignCategoryHelper.getDesignCategory(it);
      counts[cat] = (counts[cat] ?? 0) + 1;
    }
    final breakdown = counts.entries.map((e) => '${e.key}: ${e.value}').join('\n• ');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.layers, color: Color(0xFF16A34A)),
            const SizedBox(width: 8),
            Expanded(child: Text('Floor Summary: $floorName', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rooms on Floor: ${roomsOnFloor.length} (${roomsOnFloor.join(', ')})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B))),
            const SizedBox(height: 6),
            Text('Total Entries: ${itemsOnFloor.length}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF64748B))),
            const SizedBox(height: 8),
            const Text('Design Breakdown:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF64748B))),
            const SizedBox(height: 4),
            Text(counts.isEmpty ? 'No entries' : '• $breakdown', style: const TextStyle(fontSize: 12, color: Color(0xFF334155))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showRoomNumberSummaryDialog(BuildContext context, String roomNum, String floorName) {
    final itemsWithNum = widget.ctrl.currentItems.where((i) => i.roomNumber == roomNum && (i.floor.isNotEmpty ? i.floor : 'Ground Floor').toUpperCase() == floorName.toUpperCase()).toList();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.tag, color: Color(0xFFD97706)),
            const SizedBox(width: 8),
            Expanded(child: Text('Room #$roomNum Summary ($floorName)', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Associated Entries: ${itemsWithNum.length}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B))),
            const SizedBox(height: 8),
            ...itemsWithNum.map((it) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('• ${it.roomName} (${PdfDesignCategoryHelper.getDesignCategory(it)}): ${it.area.toStringAsFixed(1)} SQFT', style: const TextStyle(fontSize: 12, color: Color(0xFF334155))),
            )),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }
}
