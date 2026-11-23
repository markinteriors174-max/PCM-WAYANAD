import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Ring & Circular Cove calculation helper for PCM Wayanad
class RingCeilingCalculator {
  /// Circumference of a circle: 2 * pi * r
  static double circumferenceFt(double radiusFt) {
    if (radiusFt <= 0) return 0;
    return 2 * math.pi * radiusFt;
  }

  /// Flat ring area (outer circle minus inner empty gap): pi * (R_outer^2 - R_inner^2)
  static double ringAreaSqFt({
    required double outerRadiusFt,
    double innerRadiusFt = 0,
  }) {
    if (outerRadiusFt <= 0) return 0;
    final safeInner = innerRadiusFt.clamp(0.0, outerRadiusFt);
    return math.pi *
        ((outerRadiusFt * outerRadiusFt) - (safeInner * safeInner));
  }

  /// Cove / curve vertical drop area: circumference * heightInFt
  static double coveDropAreaSqFt({
    required double radiusFt,
    required double heightInFt,
  }) {
    if (radiusFt <= 0 || heightInFt <= 0) return 0;
    return circumferenceFt(radiusFt) * heightInFt;
  }
}

/// Drop-in widget showing Radius (R), Inner Gap, Height (4 in = 0.333 ft),
/// Total Circumference, and Ring / Cove SQFT cleanly.
class RingAndCoveCalcCard extends StatefulWidget {
  final double initialRadiusFt;
  final double initialInnerGapFt;
  final double initialHeightIn;
  final ValueChanged<double>? onAreaCalculatedSqFt;

  const RingAndCoveCalcCard({
    super.key,
    this.initialRadiusFt = 2.0,
    this.initialInnerGapFt = 1.0,
    this.initialHeightIn = 4.0,
    this.onAreaCalculatedSqFt,
  });

  @override
  State<RingAndCoveCalcCard> createState() => _RingAndCoveCalcCardState();
}

class _RingAndCoveCalcCardState extends State<RingAndCoveCalcCard> {
  late final TextEditingController _radiusCtrl;
  late final TextEditingController _innerGapCtrl;
  late final TextEditingController _heightInCtrl;
  bool _includeCoveHeight = false;

  @override
  void initState() {
    super.initState();
    _radiusCtrl = TextEditingController(
      text: widget.initialRadiusFt.toString(),
    );
    _innerGapCtrl = TextEditingController(
      text: widget.initialInnerGapFt.toString(),
    );
    _heightInCtrl = TextEditingController(
      text: widget.initialHeightIn.toString(),
    );
    _notifyArea();
  }

  void _notifyArea() {
    final r = double.tryParse(_radiusCtrl.text.trim()) ?? 0;
    final inner = double.tryParse(_innerGapCtrl.text.trim()) ?? 0;
    final hFt = (double.tryParse(_heightInCtrl.text.trim()) ?? 0) / 12.0;

    final ringArea = RingCeilingCalculator.ringAreaSqFt(
      outerRadiusFt: r,
      innerRadiusFt: inner,
    );
    final dropArea = _includeCoveHeight
        ? RingCeilingCalculator.coveDropAreaSqFt(radiusFt: r, heightInFt: hFt)
        : 0.0;

    widget.onAreaCalculatedSqFt?.call(ringArea + dropArea);
  }

  @override
  void dispose() {
    _radiusCtrl.dispose();
    _innerGapCtrl.dispose();
    _heightInCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = double.tryParse(_radiusCtrl.text.trim()) ?? 0;
    final inner = double.tryParse(_innerGapCtrl.text.trim()) ?? 0;
    final heightIn = double.tryParse(_heightInCtrl.text.trim()) ?? 0;
    final heightFt = heightIn / 12.0;

    final circum = RingCeilingCalculator.circumferenceFt(r);
    final ringSqFt = RingCeilingCalculator.ringAreaSqFt(
      outerRadiusFt: r,
      innerRadiusFt: inner,
    );
    final dropSqFt = _includeCoveHeight
        ? RingCeilingCalculator.coveDropAreaSqFt(radiusFt: r, heightInFt: heightFt)
        : 0.0;
    final totalSqFt = ringSqFt + dropSqFt;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ring / Circular Cove Calculator',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _radiusCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Radius (R) ft',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(_notifyArea),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _innerGapCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Inner Gap (ft)',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(_notifyArea),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _heightInCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Height (Inches)',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(_notifyArea),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SwitchListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Add Cove Height',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: _includeCoveHeight,
                    onChanged: (val) {
                      setState(() {
                        _includeCoveHeight = val;
                        _notifyArea();
                      });
                    },
                  ),
                ),
              ],
            ),
            const Divider(height: 18),
            Text('Circumference: ${circum.toStringAsFixed(2)} ft'),
            Text('Height in Feet: ${heightFt.toStringAsFixed(3)} ft'),
            Text('Ring Area (Outer - Inner): ${ringSqFt.toStringAsFixed(2)} SQFT'),
            if (_includeCoveHeight)
              Text('Cove Drop Area: ${dropSqFt.toStringAsFixed(2)} SQFT'),
            const SizedBox(height: 4),
            Text(
              'Total SQFT: ${totalSqFt.toStringAsFixed(2)} SQFT',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}

class CoveCircleGapTotalCard extends StatefulWidget {
  final ValueChanged<double>? onTotalSqFtChanged;

  const CoveCircleGapTotalCard({
    super.key,
    this.onTotalSqFtChanged,
  });

  @override
  State<CoveCircleGapTotalCard> createState() => _CoveCircleGapTotalCardState();
}

class _CoveCircleGapTotalCardState extends State<CoveCircleGapTotalCard> {
  final TextEditingController _innerCtrl = TextEditingController(text: '2.0');
  final TextEditingController _outerCtrl = TextEditingController();
  final TextEditingController _gapCtrl = TextEditingController();

  double _parseSafe(String? raw) {
    if (raw == null) return 0.0;
    final s = raw.trim();
    if (s.isEmpty || s == '.' || s == '-' || s == '+' || s == '-.') {
      return 0.0;
    }
    final v = double.tryParse(s);
    if (v == null || v.isNaN || v.isInfinite) return 0.0;
    return v;
  }

  double get _innerTotal {
    final r = _parseSafe(_innerCtrl.text);
    if (r <= 0) return 0.0;
    return math.pi * r * r;
  }

  double get _outerAndGapTotal {
    final outer = _parseSafe(_outerCtrl.text);
    final gap = _parseSafe(_gapCtrl.text);
    if (outer <= 0) return 0.0;
    final effectiveOuter = (outer - gap) > 0 ? (outer - gap) : outer;
    final inner = _parseSafe(_innerCtrl.text);
    final base = inner > 0 && effectiveOuter > inner
        ? math.pi * ((effectiveOuter * effectiveOuter) - (inner * inner))
        : math.pi * effectiveOuter * effectiveOuter;
    return base > 0 ? base : 0.0;
  }

  void _notify() {
    widget.onTotalSqFtChanged?.call(_innerTotal + _outerAndGapTotal);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _innerCtrl.dispose();
    _outerCtrl.dispose();
    _gapCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Inner circle + total display (green area)
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                controller: _innerCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'INNER CIRCLE',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => _notify(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF81C784)),
                ),
                child: Text(
                  'Total: ${_innerTotal.toStringAsFixed(2)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1B5E20),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Outer gypsum (red) + gap (yellow) + total (white box)
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: _outerCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'OUTER GYPSUM',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => _notify(),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              flex: 2,
              child: TextField(
                controller: _gapCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'GAP',
                  isDense: true,
                  fillColor: Color(0xFFFFFDE7),
                  filled: true,
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => _notify(),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: Text(
                  _outerAndGapTotal.toStringAsFixed(2),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
