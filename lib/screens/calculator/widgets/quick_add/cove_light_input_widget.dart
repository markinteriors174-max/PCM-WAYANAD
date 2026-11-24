import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../utils/calculator_utils.dart';
import '../../calculator_controller.dart';
import '../../helpers/cove_calculation_helper.dart';
import 'quick_add_unit_rate_selector.dart';

class CoveLightInputWidget extends StatefulWidget {
  final CalculatorController ctrl;
  final bool isActive;
  final ValueChanged<bool> onToggle;

  const CoveLightInputWidget({
    super.key,
    required this.ctrl,
    required this.isActive,
    required this.onToggle,
  });

  @override
  State<CoveLightInputWidget> createState() => _CoveLightInputWidgetState();
}

class _CoveLightInputWidgetState extends State<CoveLightInputWidget> {
  int _curveQty = 0;


  // Dynamic Cove Arch & Curve parameters
  late TextEditingController _radiusController;
  late TextEditingController _girthController;
  String _radiusUnit = 'Meter'; // 'Meter', 'Feet', 'CM', 'Inches'
  String _girthUnit = 'Meter';  // 'Meter', 'Feet', 'CM', 'Inches'
  String _archType = 'Corner (90°)'; // 'Corner (90°)', 'Semi Arch (180°)', 'Full Ring (360°)'

  bool _isUpdatingProgrammatically = false;
  double _userEnteredWidth = 0.0;

  @override
  void initState() {
    super.initState();
    _radiusController = TextEditingController(text: '2.0');

    _girthController = TextEditingController(text: '1.39');

    final initialW = double.tryParse(widget.ctrl.coveLength2Controller.text.replaceAll(',', '.')) ?? 0.0;
    _userEnteredWidth = initialW > 0 ? initialW : 0.0;

    if (widget.ctrl.coveRateController.text.trim().isEmpty) {
      final mainR = widget.ctrl.rateController.text.trim();
      widget.ctrl.coveRateController.text = mainR.isNotEmpty ? mainR : '105';
    }
  }

  @override
  void dispose() {
    _radiusController.dispose();
    _girthController.dispose();

    super.dispose();
  }

  double _toFeet(double val, String unit) {
    switch (unit.toLowerCase()) {
      case 'cm':
        return val / 30.48;
      case 'meters':
      case 'meter':
      case 'm':
        return val * 3.28084;
      case 'inches':
      case 'inch':
      case 'in':
        return val / 12.0;
      case 'feet':
      case 'ft':
      default:
        return val;
    }
  }

  double get _singleCurveSqft => CoveCalculationHelper.getSingleCurveSqft(_radiusController.text, _radiusUnit, _girthController.text, _girthUnit, _archType);
  double get _lengthRowSqft => CoveCalculationHelper.getLengthRowSqft(widget.ctrl);
  double get _effectiveWidth {
    final border1 = CoveCalculationHelper.parseNum(widget.ctrl.coveWidthController.text);
    final border2 = CoveCalculationHelper.parseNum(widget.ctrl.coveWidth2Controller.text);
    final deductionSum = border1 + border2;
    return (_userEnteredWidth - deductionSum) > 0 ? (_userEnteredWidth - deductionSum) : 0.0;
  }
  double get _widthRowSqft => CoveCalculationHelper.getWidthRowSqft(widget.ctrl);
  double _extraRowSqft(CoveLightRow row) => CoveCalculationHelper.getExtraRowSqft(row, widget.ctrl);
  double get _extraRowsTotalSqft => CoveCalculationHelper.getExtraRowsTotalSqft(widget.ctrl);
  double get _curveSqft => _curveQty * _singleCurveSqft;
  double get _totalCoveSqft => _lengthRowSqft + _widthRowSqft + _extraRowsTotalSqft + _curveSqft;
  double get _customRate => CoveCalculationHelper.getCustomRate(widget.ctrl);
  double get _grandTotal => _totalCoveSqft * _customRate;

  void _syncDeduction() {
    final border1 = CoveCalculationHelper.parseNum(widget.ctrl.coveWidthController.text);
    final border2 = CoveCalculationHelper.parseNum(widget.ctrl.coveWidth2Controller.text);
    final deductionSum = border1 + border2;
    final effW = (_userEnteredWidth - deductionSum) > 0 ? (_userEnteredWidth - deductionSum) : 0.0;

    if (_userEnteredWidth > 0) {
      _isUpdatingProgrammatically = true;
      final textVal = effW > 0 ? (effW == effW.roundToDouble() ? effW.toInt().toString() : effW.toString()) : '';
      if (widget.ctrl.coveLength2Controller.text.isEmpty) {
        widget.ctrl.coveLength2Controller.text = textVal;
      }
      _isUpdatingProgrammatically = false;
    }

    _syncValuesToController();
  }

  void _syncValuesToController() {
    widget.ctrl.coveRftController.text = _totalCoveSqft.toStringAsFixed(2);
    widget.ctrl.updateLivePreview();
    widget.ctrl.triggerAutoSave();
  }

  void _applyAndSave() {
    widget.ctrl.hasCove = true;
    widget.ctrl.isCeilingDesign = true;
    widget.onToggle(true);

    _syncDeduction();

    if (widget.ctrl.coveRateController.text.trim().isEmpty) {
      widget.ctrl.coveRateController.text = _customRate.toStringAsFixed(0);
    }

    widget.ctrl.updateLivePreview();
    widget.ctrl.triggerAutoSave();
    widget.ctrl.notifyUI();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✓ Cove details applied & widths deducted! Click ADD ENTRY below to save to sheet.'),
        backgroundColor: Color(0xFFD97706),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showArchCalculatorDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final currentSingleSqft = _singleCurveSqft;
            final rVal = double.tryParse(_radiusController.text.replaceAll(',', '.')) ?? 2.0;
            final rFt = _toFeet(rVal, _radiusUnit);
            double angleFactor = 3.1415926535 / 2.0;
            if (_archType.contains('180')) {
              angleFactor = 3.1415926535;
            } else if (_archType.contains('360')) {
              angleFactor = 2.0 * 3.1415926535;
            }
            final arcLenFt = angleFactor * rFt;

            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Dynamic Cove Arch / Curve Calculator',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFFD97706)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 8),
                    // Arch Type Selector
                    DropdownButtonFormField<String>(
                      initialValue: _archType,
                      decoration: AppStyles.inputDecoration('Arch / Curve Shape').copyWith(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Corner (90°)', child: Text('Corner (90° Arch)')),
                        DropdownMenuItem(value: 'Semi Arch (180°)', child: Text('Semi Arch (180°)')),
                        DropdownMenuItem(value: 'Full Ring (360°)', child: Text('Full Ring (360° Circular)')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => _archType = val);
                          setState(() {});
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    // Radius & Unit
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _radiusController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: AppStyles.inputDecoration('Radius (R)'),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            onChanged: (_) {
                              setModalState(() {});
                              setState(() {});
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            initialValue: _radiusUnit,
                            decoration: AppStyles.inputDecoration('Unit').copyWith(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'Meter', child: Text('Meter', style: TextStyle(fontSize: 12))),
                              DropdownMenuItem(value: 'Feet', child: Text('Feet', style: TextStyle(fontSize: 12))),
                              DropdownMenuItem(value: 'CM', child: Text('CM', style: TextStyle(fontSize: 12))),
                              DropdownMenuItem(value: 'Meters', child: Text('Meters', style: TextStyle(fontSize: 12))),
                              DropdownMenuItem(value: 'Inches', child: Text('Inches', style: TextStyle(fontSize: 12))),
                            ],
                            onChanged: (u) {
                              if (u != null) {
                                setModalState(() => _radiusUnit = u);
                                setState(() {});
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Height & Unit
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _girthController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: AppStyles.inputDecoration('Height (H)'),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            onChanged: (_) {
                              setModalState(() {});
                              setState(() {});
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            initialValue: _girthUnit,
                            decoration: AppStyles.inputDecoration('Unit').copyWith(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'Meter', child: Text('Meter', style: TextStyle(fontSize: 12))),
                              DropdownMenuItem(value: 'Feet', child: Text('Feet', style: TextStyle(fontSize: 12))),
                              DropdownMenuItem(value: 'CM', child: Text('CM', style: TextStyle(fontSize: 12))),
                              DropdownMenuItem(value: 'Meters', child: Text('Meters', style: TextStyle(fontSize: 12))),
                              DropdownMenuItem(value: 'Inches', child: Text('Inches', style: TextStyle(fontSize: 12))),
                            ],
                            onChanged: (u) {
                              if (u != null) {
                                setModalState(() => _girthUnit = u);
                                setState(() {});
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFCD34D)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Calculated Arc Length: ${arcLenFt.toStringAsFixed(2)} Feet',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF92400E)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Single Arch Area: ${currentSingleSqft.toStringAsFixed(2)} SQFT',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFFB45309)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD97706),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        setState(() {});
                        _syncValuesToController();
                        Navigator.pop(ctx);
                      },
                      child: const Text('APPLY ARCH / CURVE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
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
    const amberTheme = Color(0xFFD97706);
    final unitLabel = widget.ctrl.coveUnit.isNotEmpty ? widget.ctrl.coveUnit : widget.ctrl.unit;
    final border1 = double.tryParse(widget.ctrl.coveWidthController.text.replaceAll(',', '.')) ?? 0.0;
    final border2Text = widget.ctrl.coveWidth2Controller.text.trim();
    final border2 = border2Text.isEmpty ? 0.0 : (double.tryParse(border2Text.replaceAll(',', '.')) ?? 0.0);
    final totalBorders = border1 + border2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.isActive)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              QuickAddUnitRateSelector(
                ctrl: widget.ctrl,
                rateController: widget.ctrl.coveRateController,
                currentUnit: widget.ctrl.coveUnit,
                borderColor: amberTheme,
                onUnitChanged: (v) {
                  if (v != null) {
                    widget.ctrl.coveUnit = v;
                    setState(() {});
                    widget.ctrl.updateLivePreview();
                    widget.ctrl.triggerAutoSave();
                  }
                },
              ),
              const SizedBox(height: 12),

              // 2. Type Selection (Standard (Walls))
              Row(
                children: [
                  const Text(
                    'Type:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: amberTheme.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: amberTheme,
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.grid_view_outlined,
                          size: 14,
                          color: amberTheme,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Standard (Walls)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFB45309),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 3. Section 1: Opposite Walls (Length)
              const Text(
                'Opposite Walls (Length)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11.5,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 4),
              _buildRowOfBoxes(
                box1: _buildInputBox(
                  controller: widget.ctrl.coveLengthController,
                  label: 'LENGTH',
                  borderColor: amberTheme,
                  onChanged: (_) => _syncDeduction(),
                ),
                box2: _buildInputBox(
                  controller: widget.ctrl.coveWidthController,
                  label: 'BORDER',
                  borderColor: amberTheme,
                  onChanged: (_) => _syncDeduction(),
                ),
                box3: _buildInputBox(
                  controller: widget.ctrl.coveQuantityController,
                  label: 'QTY',
                  hintText: '1',
                  borderColor: amberTheme,
                  onChanged: (_) => _syncDeduction(),
                ),
                box4: _buildDisplayBox(
                  label: 'SQFT',
                  value: _lengthRowSqft > 0 ? _lengthRowSqft.toStringAsFixed(2) : '0.00',
                  borderColor: amberTheme,
                ),
                onDelete: () {
                  setState(() {
                    widget.ctrl.coveLengthController.clear();
                    widget.ctrl.coveWidthController.clear();
                    widget.ctrl.coveQuantityController.clear();
                  });
                  _syncValuesToController();
                },
              ),

              const SizedBox(height: 10),

              // 3. Section 2: Opposite Walls (Width)
              const Text(
                'Opposite Walls (Width)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11.5,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 4),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRowOfBoxes(
                    box1: _buildInputBox(
                      controller: widget.ctrl.coveLength2Controller,
                      label: 'WIDTH',
                      borderColor: amberTheme,
                      onChanged: (val) {
                        if (!_isUpdatingProgrammatically) {
                          _userEnteredWidth = double.tryParse(val.replaceAll(',', '.')) ?? 0.0;
                        }
                        _syncDeduction();
                      },
                    ),
                    box2: _buildInputBox(
                      controller: widget.ctrl.coveWidth2Controller,
                      label: 'BORDER',
                      borderColor: amberTheme,
                      onChanged: (_) => _syncDeduction(),
                    ),
                    box3: _buildInputBox(
                      controller: widget.ctrl.coveQuantity2Controller,
                      label: 'QTY',
                      hintText: '1',
                      borderColor: amberTheme,
                      onChanged: (_) => _syncDeduction(),
                    ),
                    box4: _buildDisplayBox(
                      label: 'SQFT',
                      value: _widthRowSqft > 0 ? _widthRowSqft.toStringAsFixed(2) : '0.00',
                      borderColor: amberTheme,
                    ),
                    onDelete: () {
                      setState(() {
                        widget.ctrl.coveLength2Controller.clear();
                        widget.ctrl.coveWidth2Controller.clear();
                        widget.ctrl.coveQuantity2Controller.clear();
                        _userEnteredWidth = 0.0;
                      });
                      _syncValuesToController();
                    },
                  ),
                  if (_userEnteredWidth > 0 && totalBorders > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 3, left: 4),
                      child: Text(
                        'Net Width: ${_effectiveWidth.toStringAsFixed(2)} $unitLabel (${_userEnteredWidth.toStringAsFixed(2)} - ${totalBorders.toStringAsFixed(2)})',
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF166534),
                        ),
                      ),
                    ),

                ],
              ),

              // Extra Rows if added by user
              for (int i = 0; i < widget.ctrl.extraCoveRows.length; i++) ...[
                const SizedBox(height: 10),
                Text(
                  'Opposite Walls (Extra Row ${i + 1})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11.5,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 4),
                _buildRowOfBoxes(
                  box1: _buildInputBox(
                    controller: widget.ctrl.extraCoveRows[i].lengthController,
                    label: 'LENGTH',
                    borderColor: amberTheme,
                    onChanged: (_) => _syncDeduction(),
                  ),
                  box2: _buildInputBox(
                    controller: widget.ctrl.extraCoveRows[i].widthController,
                    label: 'BORDER',
                    borderColor: amberTheme,
                    onChanged: (_) => _syncDeduction(),
                  ),
                  box3: _buildInputBox(
                    controller: widget.ctrl.extraCoveRows[i].quantityController,
                    label: 'QTY',
                    hintText: '1',
                    borderColor: amberTheme,
                    onChanged: (_) => _syncDeduction(),
                  ),
                  box4: _buildDisplayBox(
                    label: 'SQFT',
                    value: _extraRowSqft(widget.ctrl.extraCoveRows[i]) > 0
                        ? _extraRowSqft(widget.ctrl.extraCoveRows[i]).toStringAsFixed(2)
                        : '0.00',
                    borderColor: amberTheme,
                  ),
                  onDelete: () {
                    setState(() {
                      widget.ctrl.extraCoveRows.removeAt(i);
                    });
                    widget.ctrl.notifyUI();
                    _syncValuesToController();
                  },
                ),
              ],

              const SizedBox(height: 12),

              // Dynamic Curve, SQFT AUTO, and Custom Rate Row
              Row(
                children: [
                  // Dynamic Curve Box: 1 Curve = X.XX SQFT  QTY: 0 ▼
                  Expanded(
                    flex: 12,
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 52),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: amberTheme.withValues(alpha: 0.6), width: 1.2),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Tapping label opens the dynamic calculator dialog
                          Expanded(
                            child: InkWell(
                              onTap: _showArchCalculatorDialog,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            '1 Curve = ${_singleCurveSqft.toStringAsFixed(2)} SQFT',
                                            style: const TextStyle(
                                              fontSize: 8.5,
                                              fontWeight: FontWeight.w700,
                                              color: amberTheme,
                                            ),
                                            maxLines: 1,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      const Icon(Icons.tune, size: 10, color: amberTheme),
                                    ],
                                  ),
                                  Text(
                                    '${_radiusController.text} $_radiusUnit',
                                    style: const TextStyle(fontSize: 8.0, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Dropdown for QTY
                          PopupMenuButton<int>(
                            tooltip: 'Select Curve Quantity',
                            onSelected: (val) {
                              setState(() {
                                _curveQty = val;
                                _syncValuesToController();
                              });
                            },
                            itemBuilder: (context) => [0, 1, 2, 3, 4, 5, 6, 8, 10, 12]
                                .map((q) => PopupMenuItem<int>(
                                      value: q,
                                      child: Text('$q Curves (${(_singleCurveSqft * q).toStringAsFixed(2)} SQFT)'),
                                    ))
                                .toList(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'QTY: $_curveQty',
                                    style: const TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const Icon(Icons.arrow_drop_down, size: 16, color: Color(0xFF64748B)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // SQFT (AUTO)
                  Expanded(
                    flex: 8,
                    child: _buildDisplayBox(
                      label: 'SQFT (AUTO)',
                      value: _totalCoveSqft.toStringAsFixed(2),
                      borderColor: amberTheme,
                    ),
                  ),
                  const SizedBox(width: 4),
                  // CUSTOM RATE
                  Expanded(
                    flex: 8,
                    child: _buildInputBox(
                      controller: widget.ctrl.coveRateController,
                      label: 'RATE (₹)',
                      borderColor: amberTheme,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // 4. APPLY & SAVE COVE DETAILS Button
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: amberTheme,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: _applyAndSave,
                  icon: const Icon(Icons.save, size: 18, color: Colors.white),
                  label: const Text(
                    'APPLY & SAVE COVE DETAILS',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12.5,
                      letterSpacing: 0.6,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Specific Cove Design Total Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFCD34D), width: 1.2),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lightbulb_outline, size: 17, color: Color(0xFFB45309)),
                        const SizedBox(width: 6),
                        Text(
                          'COVE DESIGN TOTAL: ₹${CalculatorUtils.formatIndianCurrency(_grandTotal)}',
                          style: const TextStyle(
                            color: Color(0xFFB45309),
                            fontWeight: FontWeight.w900,
                            fontSize: 16.5,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'COVE AREA: ${CalculatorUtils.formatNumber(_totalCoveSqft)} SQFT  •  (ഈ കോവ് ഡിസൈൻ മാത്രമുള്ള തുക)',
                      style: const TextStyle(
                        color: Color(0xFF92400E),
                        fontWeight: FontWeight.bold,
                        fontSize: 11.5,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildRowOfBoxes({
    required Widget box1,
    required Widget box2,
    required Widget box3,
    required Widget box4,
    required VoidCallback onDelete,
  }) {
    return BoxRowHelper.buildRow(box1, box2, box3, box4, onDelete);
  }

  Widget _buildBox({
    required String label,
    required Widget child,
    bool isReadOnly = false,
    Color? borderColor,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 52),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: borderColor ?? (isReadOnly ? const Color(0xFFCBD5E1) : const Color(0xFFD97706)),
          width: isReadOnly ? 1.0 : 1.2,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 9.0,
                fontWeight: FontWeight.w700,
                color: borderColor ?? (isReadOnly ? const Color(0xFF64748B) : const Color(0xFFD97706)),
                letterSpacing: 0.2,
              ),
              maxLines: 1,
            ),
          ),
          SizedBox(
            height: 24,
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildInputBox({
    required TextEditingController controller,
    required String label,
    String? hintText,
    Color? borderColor,
    ValueChanged<String>? onChanged,
  }) {
    return _buildBox(
      label: label,
      isReadOnly: false,
      borderColor: borderColor,
      child: TextField(
        controller: controller,
        enabled: true,
        readOnly: false,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.start,
        style: const TextStyle(
          fontSize: 13.0,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.zero,
          border: InputBorder.none,
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 11, fontWeight: FontWeight.normal),
        ),
        onTap: () {
          if (controller.text == '1' || controller.text == '1.0' || controller.text == '2' || controller.text == '2.0') {
            controller.clear();
          } else {
            controller.selection = TextSelection(baseOffset: 0, extentOffset: controller.text.length);
          }
        },
        onChanged: (val) {
          final typed = val.trim();
          final mainR = widget.ctrl.rateController.text.trim();
          if (typed.isNotEmpty && typed != mainR) {
            widget.ctrl.isCoveRateCustomized = true;
          } else {
            widget.ctrl.isCoveRateCustomized = false;
          }
          setState(() {});
          if (onChanged != null) onChanged(val);
          _syncValuesToController();
        },
      ),
    );
  }

  Widget _buildDisplayBox({
    required String label,
    required String value,
    Color? borderColor,
  }) {
    return _buildBox(
      label: label,
      isReadOnly: true,
      borderColor: borderColor,
      child: Align(
        alignment: Alignment.centerLeft,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12.0,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            maxLines: 1,
          ),
        ),
      ),
    );
  }
}

class BoxRowHelper {
  static Widget buildRow(Widget b1, Widget b2, Widget b3, Widget b4, VoidCallback onDelete) {
    return Row(
      children: [
        Expanded(flex: 5, child: b1),
        const SizedBox(width: 4),
        Expanded(flex: 5, child: b2),
        const SizedBox(width: 4),
        Expanded(flex: 4, child: b3),
        const SizedBox(width: 4),
        Expanded(flex: 6, child: b4),
        const SizedBox(width: 2),
        SizedBox(
          width: 22,
          child: IconButton(
            icon: const Icon(Icons.delete_outline, color: Color(0xFFDC2626), size: 19),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Clear Row',
            onPressed: onDelete,
          ),
        ),
      ],
    );
  }
}
