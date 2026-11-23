import 'package:flutter/material.dart';

class MultiRateCardWidget extends StatefulWidget {
  final String cardTitle;
  final double initialRate;
  final double totalAmount;
  final bool isActiveTier;
  final bool isSelectedForPdf;
  final String? selectedBoard;
  final String? selectedChannel;
  final List<String> availableBoards;
  final List<String> availableChannels;
  final ValueChanged<double> onRateChanged;
  final VoidCallback onSetActiveTier;
  final ValueChanged<bool> onTogglePdfInclusion;
  final ValueChanged<String>? onBoardChanged;
  final ValueChanged<String>? onChannelChanged;
  final VoidCallback? onDeleteTier;

  const MultiRateCardWidget({
    super.key,
    required this.cardTitle,
    required this.initialRate,
    required this.totalAmount,
    this.isActiveTier = false,
    required this.isSelectedForPdf,
    this.selectedBoard,
    this.selectedChannel,
    this.availableBoards = const [],
    this.availableChannels = const [],
    required this.onRateChanged,
    required this.onSetActiveTier,
    required this.onTogglePdfInclusion,
    this.onBoardChanged,
    this.onChannelChanged,
    this.onDeleteTier,
  });

  @override
  State<MultiRateCardWidget> createState() => _MultiRateCardWidgetState();
}

class _MultiRateCardWidgetState extends State<MultiRateCardWidget> {
  late TextEditingController _rateController;

  @override
  void initState() {
    super.initState();
    _rateController = TextEditingController(text: widget.initialRate.toStringAsFixed(0));
  }

  @override
  void didUpdateWidget(covariant MultiRateCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialRate != widget.initialRate) {
      final currentVal = double.tryParse(_rateController.text);
      if (currentVal != widget.initialRate) {
        _rateController.text = widget.initialRate > 0
            ? (widget.initialRate % 1 == 0 ? widget.initialRate.toInt().toString() : widget.initialRate.toString())
            : '';
      }
    }
  }

  @override
  void dispose() {
    _rateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 175,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: widget.isActiveTier
            ? const Color(0xFF1E293B)
            : const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isActiveTier
              ? const Color(0xFFFFD54F)
              : (widget.isSelectedForPdf ? const Color(0xFF38BDF8) : Colors.white24),
          width: widget.isActiveTier ? 2.5 : (widget.isSelectedForPdf ? 1.8 : 1.0),
        ),
        boxShadow: widget.isActiveTier
            ? [
                BoxShadow(
                  color: const Color(0xFFFFD54F).withValues(alpha: 0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Badges & Delete Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (widget.isActiveTier)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD54F),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, size: 10, color: Colors.black),
                      SizedBox(width: 2),
                      Text(
                        'ACTIVE',
                        style: TextStyle(color: Colors.black, fontSize: 8.5, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                )
              else if (widget.isSelectedForPdf)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.picture_as_pdf, size: 10, color: Colors.white),
                      SizedBox(width: 2),
                      Text(
                        'IN PDF',
                        style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                )
              else
                const SizedBox.shrink(),
              const Spacer(),
              if (widget.onDeleteTier != null)
                InkWell(
                  onTap: widget.onDeleteTier,
                  child: const Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(Icons.delete_outline, color: Colors.redAccent, size: 16),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),

          // Title and Rate Input Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.cardTitle,
                  style: TextStyle(
                    color: widget.isActiveTier ? const Color(0xFFFFD54F) : Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              
              // Rate TextField
              Container(
                width: 72,
                height: 30,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: widget.isActiveTier ? const Color(0xFFFFD54F) : Colors.amber,
                    width: 1.2,
                  ),
                ),
                child: TextField(
                  controller: _rateController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(
                    color: widget.isActiveTier ? const Color(0xFFFFD54F) : Colors.amber,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    prefixText: '₹ ',
                    prefixStyle: TextStyle(
                      color: widget.isActiveTier ? const Color(0xFFFFD54F) : Colors.amber,
                      fontSize: 11,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 5),
                  ),
                  onChanged: (value) {
                    final double newRate = double.tryParse(value) ?? 0.0;
                    widget.onRateChanged(newRate);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Total Amount Display
          Text(
            "Total: ₹ ${widget.totalAmount.toStringAsFixed(2)}",
            style: const TextStyle(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),

          // Board Brand Selection
          const Text(
            "Board Brand",
            style: TextStyle(color: Colors.amberAccent, fontSize: 9, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Container(
            height: 26,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.white24, width: 0.8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                dropdownColor: const Color(0xFF1E293B),
                value: (widget.selectedBoard != null && widget.availableBoards.contains(widget.selectedBoard))
                    ? widget.selectedBoard
                    : (widget.availableBoards.isNotEmpty ? widget.availableBoards.first : null),
                style: const TextStyle(color: Colors.white, fontSize: 9.5),
                isDense: true,
                items: widget.availableBoards.map((b) => DropdownMenuItem(
                  value: b,
                  child: Text(b, style: const TextStyle(fontSize: 9.5), overflow: TextOverflow.ellipsis, maxLines: 1),
                )).toList(),
                onChanged: (val) {
                  if (val != null && widget.onBoardChanged != null) {
                    widget.onBoardChanged!(val);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 5),

          // Channel Brand Selection
          const Text(
            "Channel Brand",
            style: TextStyle(color: Colors.amberAccent, fontSize: 9, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Container(
            height: 26,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.white24, width: 0.8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                dropdownColor: const Color(0xFF1E293B),
                value: (widget.selectedChannel != null && widget.availableChannels.contains(widget.selectedChannel))
                    ? widget.selectedChannel
                    : (widget.availableChannels.isNotEmpty ? widget.availableChannels.first : null),
                style: const TextStyle(color: Colors.white, fontSize: 9.5),
                isDense: true,
                items: widget.availableChannels.map((c) => DropdownMenuItem(
                  value: c,
                  child: Text(c, style: const TextStyle(fontSize: 9.5), overflow: TextOverflow.ellipsis, maxLines: 1),
                )).toList(),
                onChanged: (val) {
                  if (val != null && widget.onChannelChanged != null) {
                    widget.onChannelChanged!(val);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Separate Controls: 1) Active Tier Selection Button & 2) PDF Inclusion Selection Checkbox
          Row(
            children: [
              // 1. Activate Button
              Expanded(
                child: SizedBox(
                  height: 26,
                  child: ElevatedButton(
                    onPressed: widget.onSetActiveTier,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.isActiveTier ? const Color(0xFFFFD54F) : Colors.amber.shade900,
                      foregroundColor: widget.isActiveTier ? Colors.black : Colors.white,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: Text(
                      widget.isActiveTier ? 'ACTIVE ★' : 'ACTIVATE',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: widget.isActiveTier ? Colors.black : Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // 2. Include in PDF Checkbox Toggle
              InkWell(
                onTap: () => widget.onTogglePdfInclusion(!widget.isSelectedForPdf),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  height: 26,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: widget.isSelectedForPdf ? const Color(0xFF0284C7) : Colors.black38,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: widget.isSelectedForPdf ? const Color(0xFF38BDF8) : Colors.white38,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.isSelectedForPdf ? Icons.check_box : Icons.check_box_outline_blank,
                        size: 13,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 3),
                      const Text(
                        'PDF',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
