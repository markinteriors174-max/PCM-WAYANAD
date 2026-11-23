import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../services/rate_service.dart';
import '../../../theme/app_theme.dart';

enum CalculatorUnit { feet, meters }

class ClientEstimateCalculatorCard extends StatefulWidget {
  const ClientEstimateCalculatorCard({super.key});

  @override
  State<ClientEstimateCalculatorCard> createState() => _ClientEstimateCalculatorCardState();
}

class _ClientEstimateCalculatorCardState extends State<ClientEstimateCalculatorCard> {
  CalculatorUnit _selectedUnit = CalculatorUnit.feet;
  String _selectedOptionId = 'gypsum_plain';

  final TextEditingController _lengthController = TextEditingController(text: '12');
  final TextEditingController _widthController = TextEditingController(text: '10');

  @override
  void dispose() {
    _lengthController.dispose();
    _widthController.dispose();
    super.dispose();
  }

  double get _length => double.tryParse(_lengthController.text.trim()) ?? 0.0;
  double get _width => double.tryParse(_widthController.text.trim()) ?? 0.0;

  double _calculateAreaSqFt() {
    if (_length <= 0 || _width <= 0) return 0.0;
    if (_selectedUnit == CalculatorUnit.feet) {
      return _length * _width;
    } else {
      // 1 Square Meter = 10.76391 Square Feet
      final areaSqM = _length * _width;
      return areaSqM * 10.76391;
    }
  }

  void _contactWhatsApp(String optionName, double areaSqFt, double rate, double total) async {
    final unitLabel = _selectedUnit == CalculatorUnit.feet ? 'ft' : 'm';
    final msg = Uri.encodeComponent(
      'Hello PCM Wayanad,\n\n'
      'I calculated an instant ceiling estimate on your website portal:\n'
      '• Option: $optionName\n'
      '• Dimensions: ${_length.toStringAsFixed(1)} $unitLabel × ${_width.toStringAsFixed(1)} $unitLabel\n'
      '• Area: ${areaSqFt.toStringAsFixed(1)} sq.ft\n'
      '• Rate: ₹${rate.toStringAsFixed(0)}/sq.ft\n'
      '• Estimated Cost: ₹${total.toStringAsFixed(2)}\n\n'
      'Please let me know when you can arrange a free site inspection.',
    );
    final url = Uri.parse('https://wa.me/919383406185?text=$msg');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _makePhoneCall() async {
    final url = Uri.parse('tel:+919383406185');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, double>>(
      stream: RateService.instance.streamRates(),
      builder: (context, snapshot) {
        final rates = snapshot.data ?? RateService.instance.cachedRates;
        final selectedOption = RateService.standardOptions.firstWhere(
          (opt) => opt.id == _selectedOptionId,
          orElse: () => RateService.standardOptions.first,
        );

        // Read-only rate dynamically fetched from Firestore stream
        final currentRate = rates[_selectedOptionId] ?? selectedOption.defaultRate;
        final areaSqFt = _calculateAreaSqFt();
        final totalEstimate = areaSqFt * currentRate;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.amber.shade300, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(12),
                blurRadius: 22,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.border.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.calculate_rounded,
                      color: AppColors.border,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'INSTANT CEILING COST ESTIMATOR',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF3E2723),
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Select your ceiling design & enter room dimensions for a live instant estimate.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Real-time Cloud Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green.shade300),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'LIVE PCM RATES',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Step 1: Select Unit (Feet / Meters)
              Row(
                children: [
                  const Text(
                    '1. Choose Measurement Unit:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF3E2723)),
                  ),
                  const Spacer(),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    padding: const EdgeInsets.all(3),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildUnitButton('Feet (ft)', CalculatorUnit.feet),
                        _buildUnitButton('Meters (m)', CalculatorUnit.meters),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Step 2: Select Ceiling / Interior Option
              const Text(
                '2. Choose Ceiling / Interior Option:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF3E2723)),
              ),
              const SizedBox(height: 10),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 600;
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: RateService.standardOptions.map((opt) {
                      final isSelected = opt.id == _selectedOptionId;
                      final optRate = rates[opt.id] ?? opt.defaultRate;
                      final cardWidth = isWide ? (constraints.maxWidth - 20) / 2 : constraints.maxWidth;

                      return SizedBox(
                        width: cardWidth,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedOptionId = opt.id;
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.amber.shade50 : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? Colors.amber.shade700 : Colors.grey.shade300,
                                width: isSelected ? 2.0 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.amber.shade200 : Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(opt.icon, color: const Color(0xFF3E2723), size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        opt.name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: isSelected ? const Color(0xFF3E2723) : Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        opt.subtitle,
                                        style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Read-only Rate Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.green.shade700 : Colors.grey.shade800,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '₹${optRate.toStringAsFixed(0)}/sq.ft',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Step 3: Enter Dimensions
              Row(
                children: [
                  const Text(
                    '3. Room Dimensions:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF3E2723)),
                  ),
                  const Spacer(),
                  // Read-Only Live Rate Indicator for Selected Option
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade300),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock, size: 12, color: Colors.green),
                        const SizedBox(width: 4),
                        Text(
                          'Verified Rate: ₹${currentRate.toStringAsFixed(0)} / sq.ft (Read-Only)',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _lengthController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: _selectedUnit == CalculatorUnit.feet ? 'Length (Feet)' : 'Length (Meters)',
                        hintText: 'e.g. 12',
                        prefixIcon: const Icon(Icons.straighten, color: AppColors.border),
                        suffixText: _selectedUnit == CalculatorUnit.feet ? 'ft' : 'm',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.border, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: TextField(
                      controller: _widthController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: _selectedUnit == CalculatorUnit.feet ? 'Width (Feet)' : 'Width (Meters)',
                        hintText: 'e.g. 10',
                        prefixIcon: const Icon(Icons.square_foot, color: AppColors.border),
                        suffixText: _selectedUnit == CalculatorUnit.feet ? 'ft' : 'm',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.border, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // Live Calculated Result Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2E1C14), Color(0xFF4E342E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.brown.withAlpha(50),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selectedOption.name.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.amber,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _selectedUnit == CalculatorUnit.feet
                                    ? '${_length.toStringAsFixed(1)} ft × ${_width.toStringAsFixed(1)} ft  =  ${areaSqFt.toStringAsFixed(1)} sq.ft'
                                    : '${_length.toStringAsFixed(2)} m × ${_width.toStringAsFixed(2)} m  =  ${(_length * _width).toStringAsFixed(2)} sq.m (~${areaSqFt.toStringAsFixed(1)} sq.ft)',
                                style: const TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Rate: ₹${currentRate.toStringAsFixed(0)} / sq.ft (Live Firestore Synchronized)',
                                style: const TextStyle(color: Colors.white54, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'APPROX. ESTIMATE',
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₹${totalEstimate.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Color(0xFF00E676),
                                fontWeight: FontWeight.w900,
                                fontSize: 24,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(color: Colors.white24, height: 1),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.amber, size: 15),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '*Approximate cost for ceiling installation based on current live PCM rates. Electrical, cove LED profile & custom painting quoted separately.',
                            style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Call to Action Buttons
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _contactWhatsApp(
                            selectedOption.name,
                            areaSqFt,
                            currentRate,
                            totalEstimate,
                          ),
                          icon: const Icon(Icons.chat, size: 18, color: Colors.white),
                          label: const Text(
                            'BOOK FREE SITE INSPECTION (WHATSAPP)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF25D366), // WhatsApp Green
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: _makePhoneCall,
                          icon: const Icon(Icons.call, size: 18, color: Colors.amber),
                          label: const Text(
                            'CALL 93 83 40 61 85',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.amber),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.amber),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUnitButton(String label, CalculatorUnit unit) {
    final isSelected = _selectedUnit == unit;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedUnit = unit;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.border : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
