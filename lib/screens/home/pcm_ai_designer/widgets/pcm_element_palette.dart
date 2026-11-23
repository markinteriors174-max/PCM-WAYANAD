import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/ceiling_object.dart';
import '../utils/component_library.dart';

class PcmElementPalette extends StatelessWidget {
  final CeilingObject? selectedObject;
  final String activeTool;
  final ValueChanged<String> onToolSelected;
  final VoidCallback onDeleteSelected;
  final TextEditingController widthController;
  final TextEditingController heightController;
  final ValueChanged<String> onAddObject;

  // Added callbacks for lights and rotation properties
  final bool globalLedStrip;
  final bool globalCoveLight;
  final ValueChanged<bool> onGlobalLedStripChanged;
  final ValueChanged<bool> onGlobalCoveLightChanged;
  final ValueChanged<double> onRotationChanged;
  final ValueChanged<bool> onLedStripToggled;
  final ValueChanged<bool> onCoveLightToggled;

  final VoidCallback onOpenAssetLibrary;
  final bool isLibraryOpened;

  const PcmElementPalette({
    super.key,
    required this.selectedObject,
    required this.activeTool,
    required this.onToolSelected,
    required this.onDeleteSelected,
    required this.widthController,
    required this.heightController,
    required this.onAddObject,
    required this.globalLedStrip,
    required this.globalCoveLight,
    required this.onGlobalLedStripChanged,
    required this.onGlobalCoveLightChanged,
    required this.onRotationChanged,
    required this.onLedStripToggled,
    required this.onCoveLightToggled,
    required this.onOpenAssetLibrary,
    required this.isLibraryOpened,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: const Color(0xFF11141A),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Selected element details input fields
          if (selectedObject != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1D26),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.3), width: 1.0),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const Icon(Icons.settings_suggest, color: Color(0xFFD4AF37), size: 14),
                    const SizedBox(width: 6),
                    Text(
                      _objectLabel(selectedObject!.type),
                      style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 15),
                    if (selectedObject!.type != 'downlight' && selectedObject!.type != 'fan_box') ...[
                      SizedBox(
                        width: 55,
                        height: 22,
                        child: TextField(
                          controller: widthController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(color: Colors.white, fontSize: 10),
                          decoration: _miniInputDecoration(
                            selectedObject!.type == 'gypsum_circle' 
                                ? 'Diam' 
                                : (selectedObject!.type == 'gypsum_oval' ? 'Major' : 'Width')
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (selectedObject!.type != 'wall_line' &&
                          selectedObject!.type != 'main_channel' &&
                          selectedObject!.type != 'cross_channel' &&
                          selectedObject!.type != 'gypsum_circle' &&
                          selectedObject!.type != 'gypsum_arc') ...[
                        SizedBox(
                          width: 55,
                          height: 22,
                          child: TextField(
                            controller: heightController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(color: Colors.white, fontSize: 10),
                            decoration: _miniInputDecoration(
                              selectedObject!.type == 'gypsum_oval' ? 'Minor' : 'Length'
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
                    // Rotation Slider
                    const SizedBox(width: 8),
                    const Text('ROTATION: ', style: TextStyle(color: Colors.white70, fontSize: 8, fontWeight: FontWeight.bold)),
                    SizedBox(
                      width: 100,
                      height: 20,
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 1.5,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 8),
                        ),
                        child: Slider(
                          value: selectedObject!.rotation * 180 / math.pi,
                          min: 0.0,
                          max: 360.0,
                          activeColor: const Color(0xFFD4AF37),
                          inactiveColor: Colors.white12,
                          onChanged: (v) => onRotationChanged(v * math.pi / 180.0),
                        ),
                      ),
                    ),
                    Text('${(selectedObject!.rotation * 180 / math.pi).toStringAsFixed(0)}°', style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 8.5, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 12),
                    // LED strip toggle
                    const Text('LED STRIP: ', style: TextStyle(color: Colors.white70, fontSize: 8, fontWeight: FontWeight.bold)),
                    SizedBox(
                      height: 18,
                      width: 32,
                      child: FittedBox(
                        fit: BoxFit.fill,
                        child: Switch(
                          value: selectedObject!.hasLedStrip,
                          activeThumbColor: const Color(0xFF00FF87),
                          onChanged: onLedStripToggled,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Cove light toggle
                    const Text('COVE: ', style: TextStyle(color: Colors.white70, fontSize: 8, fontWeight: FontWeight.bold)),
                    SizedBox(
                      height: 18,
                      width: 32,
                      child: FittedBox(
                        fit: BoxFit.fill,
                        child: Switch(
                          value: selectedObject!.hasCoveLight,
                          activeThumbColor: const Color(0xFFFFD54F),
                          onChanged: onCoveLightToggled,
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    IconButton(
                      icon: const Icon(Icons.delete_forever, color: Colors.redAccent, size: 16),
                      onPressed: onDeleteSelected,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            // Global default light assignments
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF14151C),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white10, width: 0.8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt, color: Color(0xFFD4AF37), size: 12),
                  const SizedBox(width: 4),
                  const Text(
                    'AUTO LIGHT STRIP BINDING:',
                    style: TextStyle(color: Colors.white70, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                  const Spacer(),
                  const Text('LED STRIP', style: TextStyle(color: Colors.white54, fontSize: 7.5)),
                  const SizedBox(width: 4),
                  SizedBox(
                    height: 16,
                    width: 28,
                    child: FittedBox(
                      fit: BoxFit.fill,
                      child: Switch(
                        value: globalLedStrip,
                        activeThumbColor: const Color(0xFF00FF87),
                        onChanged: onGlobalLedStripChanged,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('COVE LIGHT', style: TextStyle(color: Colors.white54, fontSize: 7.5)),
                  const SizedBox(width: 4),
                  SizedBox(
                    height: 16,
                    width: 28,
                    child: FittedBox(
                      fit: BoxFit.fill,
                      child: Switch(
                        value: globalCoveLight,
                        activeThumbColor: const Color(0xFFFFD54F),
                        onChanged: onGlobalCoveLightChanged,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Toolbar Buttons Row
          Row(
            children: [
              _toolPaletteBtn('select', Icons.touch_app, 'Select'),
              _toolPaletteBtn('arc_modifier', Icons.gesture, 'Curve Modifier'),
              const SizedBox(width: 6, child: VerticalDivider(color: Colors.white24)),
              const Spacer(),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                onPressed: onOpenAssetLibrary,
                icon: const Icon(Icons.add_box_outlined, size: 13),
                label: const Text(
                  'ADD COMPONENT / ASSET',
                  style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _miniInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54, fontSize: 8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      border: const OutlineInputBorder(),
      enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFD4AF37))),
    );
  }

  Widget _toolPaletteBtn(String tool, IconData icon, String label) {
    final bool active = activeTool == tool;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: active ? Colors.black : const Color(0xFFD4AF37)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.black : Colors.white70,
                fontSize: 8.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        selected: active,
        selectedColor: const Color(0xFFD4AF37),
        backgroundColor: const Color(0xFF1E222D),
        onSelected: (sel) {
          if (sel) {
            onToolSelected(tool);
            if (tool != 'select' && tool != 'arc_modifier') {
              if (tool != 'gypsum_rect' && tool != 'gypsum_circle' && tool != 'wall_line' && tool != 'gypsum_arc' && tool != 'gypsum_oval') {
                onAddObject(tool);
              }
            }
          }
        },
      ),
    );
  }

  String _objectLabel(String type) {
    try {
      final comp = componentLibrary.firstWhere((c) => c.id == type);
      return comp.name.toUpperCase();
    } catch (_) {}

    const m = {
      'gypsum_rect': 'GYPSUM STEP (BOX)',
      'gypsum_circle': 'GYPSUM STEP (CIRCLE)',
      'gypsum_arc': 'GYPSUM STEP (ARC)',
      'gypsum_oval': 'CENTERPIECE (OVAL)',
      'main_channel': 'MAIN CHANNEL',
      'cross_channel': 'CROSS CHANNEL',
      'fan_box': 'FAN BOX',
      'ac_vent': 'AC VENT',
      'downlight': 'LED DOWNLIGHT',
      'wall_line': 'WALL / STRAIGHT LINE',
      'ceiling_grid': 'CEILING GRID',
      'border_profile': 'BORDER PROFILE',
      'profile_light': 'PROFILE LIGHT',
      'perimeter_cove': 'PERIMETER COVE',
    };
    return m[type] ?? type.toUpperCase();
  }
}
