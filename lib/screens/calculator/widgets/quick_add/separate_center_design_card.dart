import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../utils/calculator_utils.dart';
import '../../calculator_controller.dart';

class SeparateCenterDesignSection extends StatefulWidget {
  final String title;
  final ValueChanged<double>? onAreaChanged;
  final ValueChanged<double>? onAmountChanged;

  const SeparateCenterDesignSection({
    super.key,
    this.title = 'Separate Center Design',
    this.onAreaChanged,
    this.onAmountChanged,
  });

  @override
  State<SeparateCenterDesignSection> createState() =>
      _SeparateCenterDesignSectionState();
}

class _SeparateCenterDesignSectionState
    extends State<SeparateCenterDesignSection> {
  bool _enabled = false;
  final TextEditingController _lengthCtrl = TextEditingController();
  final TextEditingController _widthCtrl = TextEditingController();
  final TextEditingController _qtyCtrl = TextEditingController(text: '1');
  final TextEditingController _rateCtrl = TextEditingController();

  double _parseNum(String? raw, [double fallback = 0.0]) {
    if (raw == null) return fallback;
    final s = raw.trim();
    if (s.isEmpty || s == '.' || s == '-' || s == '+' || s == '-.') {
      return fallback;
    }
    final v = double.tryParse(s);
    if (v == null || v.isNaN || v.isInfinite) return fallback;
    return v;
  }

  double get _area {
    if (!_enabled) return 0.0;
    final l = _parseNum(_lengthCtrl.text);
    final w = _parseNum(_widthCtrl.text);
    final q = _parseNum(_qtyCtrl.text, 1.0);
    final a = l * w * (q > 0 ? q : 1.0);
    return a > 0 ? a : 0.0;
  }

  double get _amount {
    if (!_enabled) return 0.0;
    final r = _parseNum(_rateCtrl.text);
    final amt = _area * r;
    return amt > 0 ? amt : 0.0;
  }

  void _notify() {
    widget.onAreaChanged?.call(_area);
    widget.onAmountChanged?.call(_amount);
    setState(() {});
  }

  @override
  void dispose() {
    _lengthCtrl.dispose();
    _widthCtrl.dispose();
    _qtyCtrl.dispose();
    _rateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Switch(
                  value: _enabled,
                  onChanged: (val) {
                    _enabled = val;
                    _notify();
                  },
                ),
              ],
            ),
            if (_enabled) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _lengthCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(labelText: 'Length'),
                      onChanged: (_) => _notify(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _widthCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(labelText: 'Width'),
                      onChanged: (_) => _notify(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _qtyCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(labelText: 'Qty'),
                      onChanged: (_) => _notify(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _rateCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Rate (₹)'),
                onChanged: (_) => _notify(),
              ),
              const SizedBox(height: 8),
              Text(
                'Area: ${_area.toStringAsFixed(2)} | Total: ₹${_amount.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Standalone, isolated Separate Center Design section for PCM Wayanad.
/// Keeps its controllers, state, and calculations completely independent
/// without toggling or overwriting top Center Design Ceiling switches or fields.
class SeparateCenterDesignCard extends StatefulWidget {
  final CalculatorController? ctrl;
  final bool isInitiallyEnabled;
  final ValueChanged<bool>? onToggleChanged;
  final Function({required double sqFt, required double amount})? onChanged;

  const SeparateCenterDesignCard({
    super.key,
    this.ctrl,
    this.isInitiallyEnabled = false,
    this.onToggleChanged,
    this.onChanged,
  });

  @override
  State<SeparateCenterDesignCard> createState() => _SeparateCenterDesignCardState();
}

class _SeparateCenterDesignCardState extends State<SeparateCenterDesignCard> {
  bool _sepCenterEnabled = false;
  late final TextEditingController _sepCenterLengthCtrl;
  late final TextEditingController _sepCenterWidthCtrl;
  late final TextEditingController _sepCenterQtyCtrl;
  late final TextEditingController _sepCenterRateCtrl;

  @override
  void initState() {
    super.initState();
    _sepCenterEnabled = widget.isInitiallyEnabled;
    _sepCenterLengthCtrl = TextEditingController();
    _sepCenterWidthCtrl = TextEditingController();
    _sepCenterQtyCtrl = TextEditingController(text: '1');
    _sepCenterRateCtrl = TextEditingController(text: '70');
  }

  @override
  void dispose() {
    _sepCenterLengthCtrl.dispose();
    _sepCenterWidthCtrl.dispose();
    _sepCenterQtyCtrl.dispose();
    _sepCenterRateCtrl.dispose();
    super.dispose();
  }

  double _safeParse(String? raw, [double fallback = 0.0]) {
    if (raw == null) return fallback;
    final s = raw.trim();
    if (s.isEmpty || s == '.' || s == '-' || s == '+' || s == '-.') return fallback;
    final v = double.tryParse(s);
    if (v == null || v.isNaN || v.isInfinite) return fallback;
    return v;
  }

  double get _areaSqFt {
    if (!_sepCenterEnabled) return 0.0;
    final l = _safeParse(_sepCenterLengthCtrl.text);
    final w = _safeParse(_sepCenterWidthCtrl.text);
    final q = _safeParse(_sepCenterQtyCtrl.text, 1.0);
    final res = l * w * q;
    return (res.isNaN || res.isInfinite) ? 0.0 : res;
  }

  double get _rate => _safeParse(_sepCenterRateCtrl.text, 70.0);

  double get _totalAmount {
    final res = _areaSqFt * _rate;
    return (res.isNaN || res.isInfinite) ? 0.0 : res;
  }

  void _notifyChanges() {
    if (!mounted) return;
    setState(() {});
    widget.onChanged?.call(sqFt: _areaSqFt, amount: _totalAmount);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _sepCenterEnabled ? const Color(0xFFF0FDF4) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _sepCenterEnabled ? const Color(0xFF22C55E) : Colors.grey.shade300,
          width: _sepCenterEnabled ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        children: [
          SwitchListTile(
            dense: true,
            title: Row(
              children: [
                const Icon(Icons.center_focus_strong, size: 16, color: Color(0xFF16A34A)),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Separate Center Design',
                    style: TextStyle(color: Color(0xFF15803D), fontSize: 12.5, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_sepCenterEnabled) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFF16A34A), borderRadius: BorderRadius.circular(4)),
                    child: const Text('ACTIVE', style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold)),
                  ),
                ],
              ],
            ),
            value: _sepCenterEnabled,
            activeThumbColor: const Color(0xFF16A34A),
            onChanged: (val) {
              setState(() {
                _sepCenterEnabled = val;
              });
              widget.onToggleChanged?.call(val);
              _notifyChanges();
            },
          ),
          if (_sepCenterEnabled) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _sepCenterLengthCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 12),
                          decoration: const InputDecoration(
                            labelText: 'Length',
                            labelStyle: TextStyle(color: Colors.grey, fontSize: 11),
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (_) => _notifyChanges(),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: TextField(
                          controller: _sepCenterWidthCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 12),
                          decoration: const InputDecoration(
                            labelText: 'Width',
                            labelStyle: TextStyle(color: Colors.grey, fontSize: 11),
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (_) => _notifyChanges(),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: TextField(
                          controller: _sepCenterQtyCtrl,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 12),
                          decoration: const InputDecoration(
                            labelText: 'Qty',
                            labelStyle: TextStyle(color: Colors.grey, fontSize: 11),
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (_) => _notifyChanges(),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: TextField(
                          controller: _sepCenterRateCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12),
                          decoration: const InputDecoration(
                            labelText: 'Rate (₹)',
                            labelStyle: TextStyle(color: Colors.amber, fontSize: 11),
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (_) => _notifyChanges(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF86EFAC)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'AREA: ${CalculatorUtils.formatNumber(_areaSqFt)} SQFT',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                        ),
                        Text(
                          'TOTAL: ₹${CalculatorUtils.formatIndianCurrency(_totalAmount)}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF15803D)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Circular '+' Button placed directly above THIS ENTRY TOTAL (below COVE LIGHT)
/// ALWAYS visible without requiring top Center Design Ceiling switch to be ON.
class SeparateCenterCoveAddButton extends StatelessWidget {
  final VoidCallback onTap;

  const SeparateCenterCoveAddButton({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: InkWell(
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();
            onTap();
          },
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF16A34A),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF16A34A).withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.add,
              color: Colors.white,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }
}

class CircledPlusActionBar extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;

  const CircledPlusActionBar({
    super.key,
    required this.onPressed,
    this.label = 'Add Center Design Cove',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: () {
              FocusManager.instance.primaryFocus?.unfocus();
              onPressed();
            },
            customBorder: const CircleBorder(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green.shade600,
              ),
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
