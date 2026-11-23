import 'package:flutter/material.dart';
import 'package:pcm_wayanad/theme/app_theme.dart';
import 'package:pcm_wayanad/screens/calculator/calculator_controller.dart';

class StandardCenterRowsWidget extends StatefulWidget {
  final CalculatorController ctrl;
  final Color themeColor;
  final VoidCallback onChanged;

  const StandardCenterRowsWidget({
    super.key,
    required this.ctrl,
    required this.themeColor,
    required this.onChanged,
  });

  @override
  State<StandardCenterRowsWidget> createState() => _StandardCenterRowsWidgetState();
}

class _StandardCenterRowsWidgetState extends State<StandardCenterRowsWidget> {
  final FocusNode _centralLenNode = FocusNode();
  final FocusNode _centralWidNode = FocusNode();
  final FocusNode _extra0LenNode = FocusNode();
  final FocusNode _extra1LenNode = FocusNode();

  @override
  void dispose() {
    _centralLenNode.dispose();
    _centralWidNode.dispose();
    _extra0LenNode.dispose();
    _extra1LenNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Primary Center (Length / Width)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(child: _field(widget.ctrl.centralLengthController, 'LENGTH', focusNode: _centralLenNode, onSubmitted: (_) => _extra0LenNode.requestFocus(), cardColor: widget.themeColor)),
            const SizedBox(width: 6),
            Expanded(child: _field(widget.ctrl.centralWidthController, 'WIDTH', focusNode: _centralWidNode, onSubmitted: (_) => _extra1LenNode.requestFocus(), cardColor: widget.themeColor)),
            const SizedBox(width: 6),
            Expanded(child: _field(widget.ctrl.centralQuantityController, 'QTY', cardColor: widget.themeColor, hintText: '1')),
            const SizedBox(width: 6),
            Expanded(child: _field(widget.ctrl.centralAreaController, 'SQFT', readOnly: true, cardColor: widget.themeColor)),
          ],
        ),
        for (int i = 0; i < widget.ctrl.extraCentralRows.length; i++) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _field(widget.ctrl.extraCentralRows[i].lengthController, i == 1 ? 'WIDTH' : 'LENGTH', focusNode: i == 0 ? _extra0LenNode : (i == 1 ? _extra1LenNode : null), cardColor: widget.themeColor)),
              const SizedBox(width: 6),
              Expanded(child: _field(widget.ctrl.extraCentralRows[i].widthController, 'BORDER', cardColor: widget.themeColor)),
              const SizedBox(width: 6),
              Expanded(child: _field(widget.ctrl.extraCentralRows[i].quantityController, 'QTY', cardColor: widget.themeColor, hintText: '1')),
              const SizedBox(width: 6),
              Expanded(child: _field(widget.ctrl.extraCentralRows[i].areaController, 'SQFT', readOnly: true, cardColor: widget.themeColor)),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                onPressed: () {
                  widget.ctrl.extraCentralRows.removeAt(i);
                  widget.onChanged();
                  widget.ctrl.updateLivePreview();
                  widget.ctrl.triggerAutoSave();
                },
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _field(TextEditingController c, String l, {bool readOnly = false, bool enabled = true, String? hintText, Color? cardColor, FocusNode? focusNode, ValueChanged<String>? onSubmitted}) {
    return TextField(
      controller: c,
      readOnly: readOnly,
      enabled: enabled,
      focusNode: focusNode,
      onSubmitted: onSubmitted,
      textInputAction: onSubmitted != null ? TextInputAction.next : TextInputAction.done,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: AppStyles.inputDecoration(l).copyWith(
        fillColor: readOnly ? Colors.grey.shade100 : Colors.white,
        filled: true,
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: cardColor ?? Colors.grey.shade400, width: 1.8)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: cardColor ?? Colors.blue, width: 2.2)),
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 11),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      ),
      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: readOnly ? Colors.grey.shade700 : Colors.black),
      onTap: readOnly ? null : () {
        if (c.text == '1' || c.text == '1.0' || c.text == '1.00' || l == 'QTY') {
          c.clear();
        } else {
          c.selection = TextSelection(baseOffset: 0, extentOffset: c.text.length);
        }
      },
      onChanged: readOnly ? null : (val) {
        if (c == widget.ctrl.centralLengthController && widget.ctrl.extraCentralRows.isNotEmpty) {
          widget.ctrl.extraCentralRows[0].lengthController.text = val;
        } else if (c == widget.ctrl.centralWidthController && widget.ctrl.extraCentralRows.length > 1) {
          widget.ctrl.extraCentralRows[1].lengthController.text = val;
        }
        widget.onChanged();
        widget.ctrl.updateLivePreview();
        widget.ctrl.triggerAutoSave();
      },
    );
  }
}
