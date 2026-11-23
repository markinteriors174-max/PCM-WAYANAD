import 'package:flutter/material.dart';
import '../../../services/rate_service.dart';
import '../../../theme/app_theme.dart';

class AdminRateControlCard extends StatefulWidget {
  const AdminRateControlCard({super.key});

  @override
  State<AdminRateControlCard> createState() => _AdminRateControlCardState();
}

class _AdminRateControlCardState extends State<AdminRateControlCard> {
  final Map<String, TextEditingController> _controllers = {};
  bool _isSaving = false;
  bool _isEditing = false;
  DateTime? _lastSavedTime;

  @override
  void initState() {
    super.initState();
    for (final opt in RateService.standardOptions) {
      _controllers[opt.id] = TextEditingController(
        text: opt.defaultRate.toStringAsFixed(0),
      );
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _syncControllersWithRates(Map<String, double> rates) {
    if (_isEditing) return; // Don't interrupt if user is currently typing
    for (final opt in RateService.standardOptions) {
      final rate = rates[opt.id] ?? opt.defaultRate;
      final currentText = _controllers[opt.id]?.text ?? '';
      final currentVal = double.tryParse(currentText);
      if (currentVal != rate) {
        _controllers[opt.id]?.text = rate.toStringAsFixed(0);
      }
    }
  }

  void _adjustRate(String id, double delta) {
    setState(() {
      _isEditing = true;
    });
    final c = _controllers[id];
    if (c == null) return;
    final current = double.tryParse(c.text) ?? 0.0;
    final next = (current + delta).clamp(10.0, 5000.0);
    c.text = next.toStringAsFixed(0);
  }

  Future<void> _handleSave() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _isSaving = true;
      _isEditing = false;
    });

    final newRates = <String, double>{};
    for (final opt in RateService.standardOptions) {
      final text = _controllers[opt.id]?.text.trim() ?? '';
      final val = double.tryParse(text) ?? opt.defaultRate;
      newRates[opt.id] = val > 0 ? val : opt.defaultRate;
    }

    final success = await RateService.instance.saveRates(newRates);

    if (mounted) {
      setState(() {
        _isSaving = false;
        if (success) _lastSavedTime = DateTime.now();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                success ? Icons.check_circle : Icons.error_outline,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  success
                      ? 'Live rates saved & pushed to Client Portal estimator instantly!'
                      : 'Failed to update rates. Please check your connection.',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: success ? const Color(0xFF2E7D32) : Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _handleReset() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Rates to Default?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          'This will restore all 5 ceiling options to their standard PCM base rates and update the live Client Portal.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade800,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('RESET DEFAULTS'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isSaving = true;
        _isEditing = false;
      });
      await RateService.instance.resetToDefaults();
      for (final opt in RateService.standardOptions) {
        _controllers[opt.id]?.text = opt.defaultRate.toStringAsFixed(0);
      }
      if (mounted) {
        setState(() {
          _isSaving = false;
          _lastSavedTime = DateTime.now();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rates reset to default and synced with Client Portal.'),
            backgroundColor: Colors.brown,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, double>>(
      stream: RateService.instance.streamRates(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          _syncControllersWithRates(snapshot.data!);
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.amber.shade300, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.border.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      color: AppColors.border,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LIVE CLIENT RATE CONTROL',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF3E2723),
                            letterSpacing: 0.8,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Per-Sq.Ft Rates for Client Portal Estimator',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.black54,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Real-time Pulse Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade300),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          'LIVE SYNC',
                          style: TextStyle(
                            fontSize: 9,
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
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 14),

              // 5 Ceiling Rate Options
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: RateService.standardOptions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final opt = RateService.standardOptions[index];
                  final controller = _controllers[opt.id]!;

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAFAFA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Option Icon
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100.withAlpha(120),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(opt.icon, color: const Color(0xFF3E2723), size: 18),
                        ),
                        const SizedBox(width: 8),

                        // Title & Subtitle (Expanded with flex 3)
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                opt.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Color(0xFF2D1E18),
                                ),
                                softWrap: true,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                opt.subtitle,
                                style: TextStyle(
                                  fontSize: 9.5,
                                  color: Colors.grey.shade600,
                                ),
                                softWrap: true,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),

                        // Decrement Button
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                          icon: const Icon(Icons.remove_circle_outline, size: 18, color: Colors.grey),
                          tooltip: 'Decrease by ₹5',
                          onPressed: () => _adjustRate(opt.id, -5.0),
                        ),

                        // Input field
                        Container(
                          width: 72,
                          height: 36,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          child: TextField(
                            controller: controller,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Color(0xFF2E7D32),
                            ),
                            onChanged: (_) {
                              _isEditing = true;
                            },
                            decoration: InputDecoration(
                              prefixText: '₹',
                              prefixStyle: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Color(0xFF2E7D32),
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey.shade400),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: AppColors.border, width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                        ),

                        // Increment Button
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                          icon: const Icon(Icons.add_circle_outline, size: 18, color: Colors.green),
                          tooltip: 'Increase by ₹5',
                          onPressed: () => _adjustRate(opt.id, 5.0),
                        ),

                        const SizedBox(width: 4),
                        const Text(
                          '/sq.ft',
                          style: TextStyle(fontSize: 10, color: Colors.black54, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              // Action Buttons
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _isSaving ? null : _handleReset,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('DEFAULTS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.brown,
                      side: BorderSide(color: Colors.brown.shade300),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _handleSave,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.cloud_upload_rounded, size: 18),
                      label: Text(
                        _isSaving ? 'SAVING TO CLOUD...' : 'SAVE & SYNC TO PORTAL',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.border,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 2,
                      ),
                    ),
                  ),
                ],
              ),

              if (_lastSavedTime != null) ...[
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Last saved: ${_lastSavedTime!.hour.toString().padLeft(2, '0')}:${_lastSavedTime!.minute.toString().padLeft(2, '0')}:${_lastSavedTime!.second.toString().padLeft(2, '0')} • Rates are active live on web',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
