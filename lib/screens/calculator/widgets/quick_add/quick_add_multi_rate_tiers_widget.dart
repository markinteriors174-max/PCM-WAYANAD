import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../calculator_controller.dart';
import '../../../../models/rate_tier.dart';
import '../../brands/ceiling_board_brands.dart';
import '../../brands/channel_brands.dart';
import '../../brands/brand_selector_helper.dart';
import '../../../../utils/calculator_utils.dart';

class QuickAddMultiRateTiersWidget extends StatefulWidget {
  final CalculatorController ctrl;
  final String currentRoomName;

  const QuickAddMultiRateTiersWidget({
    super.key,
    required this.ctrl,
    required this.currentRoomName,
  });

  @override
  State<QuickAddMultiRateTiersWidget> createState() => _QuickAddMultiRateTiersWidgetState();
}

class _QuickAddMultiRateTiersWidgetState extends State<QuickAddMultiRateTiersWidget> {
  CalculatorController get ctrl => widget.ctrl;

  @override
  void initState() {
    super.initState();
    ctrl.addListener(_onCtrlChanged);
  }

  @override
  void dispose() {
    ctrl.removeListener(_onCtrlChanged);
    for (var c in _tierRateControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  final Map<String, TextEditingController> _tierRateControllers = {};

  TextEditingController _getRateController(RateTier tier) {
    if (!_tierRateControllers.containsKey(tier.id)) {
      _tierRateControllers[tier.id] = TextEditingController(
        text: tier.rate > 0 ? (tier.rate % 1 == 0 ? tier.rate.toInt().toString() : tier.rate.toString()) : '105',
      );
    } else {
      final currentText = _tierRateControllers[tier.id]!.text;
      final expectedText = tier.rate % 1 == 0 ? tier.rate.toInt().toString() : tier.rate.toString();
      if (currentText != expectedText && double.tryParse(currentText) != tier.rate) {
        _tierRateControllers[tier.id]!.text = expectedText;
      }
    }
    return _tierRateControllers[tier.id]!;
  }

  void _onCtrlChanged() {
    if (mounted) setState(() {});
  }

  Color _getTierColor(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('base') || lower.contains('economy')) {
      return const Color(0xFF2563EB); // Rich Blue
    } else if (lower.contains('premium') || lower.contains('gold')) {
      return const Color(0xFFD97706); // Warm Amber Gold
    } else if (lower.contains('luxury') || lower.contains('platinum')) {
      return const Color(0xFF9333EA); // Rich Purple
    }
    return const Color(0xFF0D9488); // Teal
  }

  void _showAddTierDialog() {
    final nameCtrl = TextEditingController();
    final rateCtrl = TextEditingController(text: '130');
    String selectedChannel = RateTierConstants.availableChannels.first;
    String selectedBoard = RateTierConstants.availableBoards.first;
    final customChannelCtrl = TextEditingController();
    final customBoardCtrl = TextEditingController();
    bool isCustomChannel = false;
    bool isCustomBoard = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.add_circle, color: Color(0xFFD97706)),
              SizedBox(width: 8),
              Text('Add New Rate Tier', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Tier Name (e.g. Executive, Diamond)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: rateCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Rate (₹ / Sq.Ft)',
                    prefixText: '₹ ',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedChannel,
                  decoration: const InputDecoration(
                    labelText: 'ചാനൽ സെലക്ഷൻ (Channel Selection)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: RateTierConstants.availableChannels
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(
                              c == 'More' ? '➕ More (Custom Channel)' : c,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: c == 'More' ? FontWeight.bold : FontWeight.normal,
                                color: c == 'More' ? const Color(0xFFD97706) : Colors.black87,
                              ),
                            ),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() {
                        selectedChannel = val;
                        isCustomChannel = (val == 'More');
                      });
                    }
                  },
                ),
                if (isCustomChannel) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: customChannelCtrl,
                    decoration: const InputDecoration(
                      labelText: 'കസ്റ്റം ചാനൽ നൽകുക (Custom Channel)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedBoard,
                  decoration: const InputDecoration(
                    labelText: 'ബോർഡ് സെലക്ഷൻ (Board Selection)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: RateTierConstants.availableBoards
                      .map((b) => DropdownMenuItem(
                            value: b,
                            child: Text(
                              b == 'More' ? '➕ More (Custom Board)' : b,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: b == 'More' ? FontWeight.bold : FontWeight.normal,
                                color: b == 'More' ? const Color(0xFFD97706) : Colors.black87,
                              ),
                            ),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() {
                        selectedBoard = val;
                        isCustomBoard = (val == 'More');
                      });
                    }
                  },
                ),
                if (isCustomBoard) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: customBoardCtrl,
                    decoration: const InputDecoration(
                      labelText: 'കസ്റ്റം ബോർഡ് നൽകുക (Custom Board)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryButton,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final name = nameCtrl.text.trim();
                final rate = double.tryParse(rateCtrl.text.trim()) ?? 0.0;
                final channel = isCustomChannel ? customChannelCtrl.text.trim() : selectedChannel;
                final board = isCustomBoard ? customBoardCtrl.text.trim() : selectedBoard;
                if (name.isNotEmpty && rate > 0) {
                  ctrl.addTier(
                    name,
                    rate,
                    channel.isNotEmpty ? channel : 'Standard G.I. (0.45mm)',
                    board.isNotEmpty ? board : 'Gyproc (Saint-Gobain)',
                  );
                  Navigator.pop(ctx);
                }
              },
              child: const Text('ADD TIER'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTierCard(RateTier tier, int index) {
    final isSelected = ctrl.selectedTierIds.contains(tier.id) || tier.isSelected;
    final isActiveRate = (ctrl.selectedTier == tier.name || ctrl.selectedTier == tier.id);
    final tierColor = _getTierColor(tier.name);
    final double totalSqFt = (ctrl.projectTotalAreaSqFt > 0)
        ? ctrl.projectTotalAreaSqFt
        : (ctrl.currentItems.isNotEmpty
            ? ctrl.currentItems.fold(0.0, (s, i) => s + (i.area > 0 ? i.area : (i.length * i.width)))
            : (ctrl.projectTotalAmount > 0 ? ctrl.projectTotalAmount / 95.0 : 1.0));
    
    double tierRate = tier.rate > 0 ? tier.rate : (tier.name.toLowerCase().contains('base') ? 70.0 : (tier.name.toLowerCase().contains('premium') ? 110.0 : (tier.name.toLowerCase().contains('luxury') ? 180.0 : 95.0)));
    double tierTotal = totalSqFt * tierRate;
    if (ctrl.projectTotalAmount > 0 && tierTotal < ctrl.projectTotalAmount) {
      tierTotal = ctrl.projectTotalAmount * (tierRate / 95.0);
      if (tierTotal < ctrl.projectTotalAmount) tierTotal = ctrl.projectTotalAmount;
    }

    final availableChannels = ChannelBrands.getChannelsForCeiling(ctrl.selectedCeilingType);
    final availableBoards = CeilingBoardBrands.getBrandsForCeiling(ctrl.selectedCeilingType);
    
    String currentChannel = tier.channel;
    if (!availableChannels.contains(currentChannel) && currentChannel != 'More' && currentChannel != 'Other' && availableChannels.isNotEmpty) {
      currentChannel = availableChannels.first;
    }
    
    String currentBoard = tier.board;
    if (!availableBoards.contains(currentBoard) && currentBoard != 'More' && currentBoard != 'Other' && availableBoards.isNotEmpty) {
      currentBoard = availableBoards.first;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActiveRate ? tierColor : (isSelected ? tierColor.withValues(alpha: 0.85) : Colors.grey.shade300),
          width: isActiveRate ? 2.2 : (isSelected ? 1.6 : 1.2),
        ),
        boxShadow: [
          BoxShadow(
            color: tierColor.withValues(alpha: isActiveRate ? 0.2 : 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tier Name & Active Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  tier.name,
                  style: TextStyle(color: tierColor, fontWeight: FontWeight.w900, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isActiveRate)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: tierColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'ACTIVE',
                    style: TextStyle(color: Colors.white, fontSize: 7.5, fontWeight: FontWeight.w900),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),

          // Rate Input Box (Modern styling, no leading zeros)
          Row(
            children: [
              const Text('Rate: ', style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.bold)),
              Expanded(
                child: SizedBox(
                  height: 32,
                  child: TextField(
                    controller: _getRateController(tier),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w900, fontSize: 12),
                    decoration: InputDecoration(
                      prefixText: '₹ ',
                      prefixStyle: TextStyle(color: tierColor, fontWeight: FontWeight.w900, fontSize: 11),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      isDense: true,
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: tierColor, width: 1.6),
                      ),
                    ),
                    onChanged: (val) {
                      final cleanVal = val.trim().replaceFirst(RegExp(r'^0+(?=\d)'), '');
                      final newRate = double.tryParse(cleanVal.isEmpty ? '0' : cleanVal) ?? 0.0;
                      setState(() {
                        tier.rate = newRate;
                        if (isActiveRate) {
                          ctrl.rateController.text = newRate.toString();
                        }
                        ctrl.updateLivePreview();
                        ctrl.notifyUI();
                        ctrl.triggerAutoSave();
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Channel Dropdown
          const Text('Channel', style: TextStyle(color: Color(0xFF64748B), fontSize: 9.5, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          DropdownButtonHideUnderline(
            child: Container(
              height: 30,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300, width: 1.1),
              ),
              child: DropdownButton<String>(
                value: currentChannel,
                isExpanded: true,
                dropdownColor: Colors.white,
                style: const TextStyle(color: Color(0xFF1E293B), fontSize: 9.5, fontWeight: FontWeight.bold),
                selectedItemBuilder: (context) {
                  return availableChannels.map((channel) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Ch: $channel', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF1E293B), fontSize: 9.5, fontWeight: FontWeight.bold)),
                    );
                  }).toList();
                },
                items: availableChannels.map((channel) {
                  return DropdownMenuItem(
                    value: channel,
                    child: Text('Ch: $channel', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF1E293B), fontSize: 9.5)),
                  );
                }).toList(),
                onChanged: (newChannel) async {
                  if (newChannel != null) {
                    if (newChannel == 'More' || newChannel == 'Other') {
                      final selected = await BrandSelectorHelper.showBrandPicker(
                        context,
                        title: 'Select Channel Brand (${tier.name})',
                        brands: availableChannels,
                        currentBrand: tier.channel,
                        isChannel: true,
                      );
                      if (selected != null && selected.isNotEmpty) {
                        setState(() {
                          tier.channel = selected;
                          ctrl.updateTierDetails(tier.id, tier.channel, tier.board);
                          ctrl.notifyUI();
                        });
                      }
                    } else {
                      setState(() {
                        tier.channel = newChannel;
                        ctrl.updateTierDetails(tier.id, tier.channel, tier.board);
                        ctrl.notifyUI();
                      });
                    }
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 6),

          // Board Dropdown
          const Text('Board', style: TextStyle(color: Color(0xFF64748B), fontSize: 9.5, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          DropdownButtonHideUnderline(
            child: Container(
              height: 30,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300, width: 1.1),
              ),
              child: DropdownButton<String>(
                value: currentBoard,
                isExpanded: true,
                dropdownColor: Colors.white,
                style: const TextStyle(color: Color(0xFF1E293B), fontSize: 9.5, fontWeight: FontWeight.bold),
                selectedItemBuilder: (context) {
                  return availableBoards.map((board) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Bd: $board', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF1E293B), fontSize: 9.5, fontWeight: FontWeight.bold)),
                    );
                  }).toList();
                },
                items: availableBoards.map((board) {
                  return DropdownMenuItem(
                    value: board,
                    child: Text('Bd: $board', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF1E293B), fontSize: 9.5)),
                  );
                }).toList(),
                onChanged: (newBoard) async {
                  if (newBoard != null) {
                    if (newBoard == 'More' || newBoard == 'Other') {
                      final selected = await BrandSelectorHelper.showBrandPicker(
                        context,
                        title: 'Select Board Brand (${tier.name})',
                        brands: availableBoards,
                        currentBrand: tier.board,
                        isChannel: false,
                      );
                      if (selected != null && selected.isNotEmpty) {
                        setState(() {
                          tier.board = selected;
                          ctrl.updateTierDetails(tier.id, tier.channel, tier.board);
                          ctrl.notifyUI();
                        });
                      }
                    } else {
                      setState(() {
                        tier.board = newBoard;
                        ctrl.updateTierDetails(tier.id, tier.channel, tier.board);
                        ctrl.notifyUI();
                      });
                    }
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 6),

          // Color-Coded Brand Chips
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF), // Light blue for Channel
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFBFDBFE), width: 0.8),
                ),
                child: Text(
                  'Ch: ${tier.channel}',
                  style: const TextStyle(color: Color(0xFF1D4ED8), fontSize: 8.5, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4), // Light green for Board
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFBBF7D0), width: 0.8),
                ),
                child: Text(
                  'Bd: ${tier.board}',
                  style: const TextStyle(color: Color(0xFF15803D), fontSize: 8.5, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          // Quick Rate Chips (70, 110, 180)
          const SizedBox(height: 4),
          Wrap(
            spacing: 3,
            runSpacing: 2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text('Quick:', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 8.5, fontWeight: FontWeight.bold)),
              for (final preset in [70, 110, 145, 180])
                InkWell(
                  onTap: () {
                    setState(() {
                      tier.rate = preset.toDouble();
                      _tierRateControllers[tier.id]?.text = preset.toString();
                      if (isActiveRate) {
                        ctrl.rateController.text = preset.toString();
                      }
                      ctrl.updateLivePreview();
                      ctrl.notifyUI();
                      ctrl.triggerAutoSave();
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text('$preset', style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),

          // Total amount
          Text(
            'Total: ₹ ${CalculatorUtils.formatIndianCurrency(tierTotal)}',
            style: TextStyle(color: tierColor, fontSize: 10.5, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),

          // SELECTED FOR PDF Button & Activate button
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 26,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        ctrl.toggleTierSelection(tier.id);
                        ctrl.selectTier(tier.name);
                        ctrl.notifyUI();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSelected ? const Color(0xFF16A34A) : Colors.white,
                      foregroundColor: isSelected ? Colors.white : tierColor,
                      elevation: 0,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                        side: BorderSide(color: isSelected ? const Color(0xFF16A34A) : tierColor, width: 1.2),
                      ),
                    ),
                    child: Text(
                      isSelected ? 'PDF ✓' : 'SELECT',
                      style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: isSelected ? Colors.white : tierColor),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              SizedBox(
                height: 26,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      ctrl.selectTier(tier.name);
                      ctrl.rateController.text = tier.rate.toString();
                      ctrl.updateLivePreview();
                      ctrl.notifyUI();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isActiveRate ? tierColor : const Color(0xFFF1F5F9),
                    foregroundColor: isActiveRate ? Colors.white : const Color(0xFF475569),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: Text(
                    isActiveRate ? 'ACTIVE' : 'USE',
                    style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: isActiveRate ? Colors.white : const Color(0xFF475569)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top Header Row with MULTI-RATE TIERS Title, Room Chip, Add, Sync, Close
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD97706).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.layers, color: Color(0xFFD97706), size: 16),
                  ),
                  const SizedBox(width: 6),
                  const Flexible(
                    child: Text(
                      'MULTI-RATE TIERS',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 0.8,
                        color: Color(0xFF2C1810),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF5EE),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.6)),
                      ),
                      child: Text(
                        widget.currentRoomName,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5D4037),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3E2723),
                    foregroundColor: const Color(0xFFFFD54F),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                      side: const BorderSide(color: Color(0xFFD4AF37), width: 1),
                    ),
                    elevation: 1,
                  ),
                  icon: const Icon(Icons.add, size: 12),
                  label: const Text('Add', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  onPressed: _showAddTierDialog,
                ),
                const SizedBox(width: 4),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF4E342E),
                    side: const BorderSide(color: Color(0xFFBCAAA4), width: 1),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  icon: const Icon(Icons.sync, size: 12),
                  label: const Text('Sync', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    ctrl.syncTiersWithMaster();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✓ Multi-Rate Tiers synced with Master Rates'),
                        duration: Duration(seconds: 2),
                        backgroundColor: Color(0xFF2E7D32),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),

        // 3-Column Responsive Side-by-Side (BASE, PREMIUM, LUXURY fit simultaneously without scroll)
        ListenableBuilder(
          listenable: widget.ctrl,
          builder: (context, child) {
            return LayoutBuilder(
              builder: (context, constraints) {
                if (ctrl.rateTiers.length <= 3) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: ctrl.rateTiers.asMap().entries.map((entry) {
                      final index = entry.key;
                      final tier = entry.value;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: index == 0 ? 0 : 3,
                            right: index == ctrl.rateTiers.length - 1 ? 0 : 3,
                          ),
                          child: _buildTierCard(tier, index),
                        ),
                      );
                    }).toList(),
                  );
                } else {
                  final double cardWidth = (constraints.maxWidth / 3.2).clamp(100.0, 150.0);
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: ctrl.rateTiers.asMap().entries.map((entry) {
                        final index = entry.key;
                        final tier = entry.value;
                        return Padding(
                          padding: EdgeInsets.only(
                            right: index == ctrl.rateTiers.length - 1 ? 0 : 6,
                          ),
                          child: SizedBox(
                            width: cardWidth,
                            child: _buildTierCard(tier, index),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                }
              },
            );
          },
        ),
      ],
    );
  }
}
