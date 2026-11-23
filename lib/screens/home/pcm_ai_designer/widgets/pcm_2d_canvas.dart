import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/ceiling_object.dart';
import 'cad_blueprint_painter.dart';
import 'pcm_material_list.dart';

class Pcm2dCanvas extends StatelessWidget {
  final double roomL;
  final double roomW;
  final List<CeilingObject> objects;
  final String? selectedId;
  final String activeTool;
  final double gridSpacing;
  final double angleSnapDeg;
  final bool panZoomMode;
  final double canvasZoom;
  final Offset canvasOffset;
  final List<Offset> sketchPoints;

  // Material calculations
  final double calculatedArea;
  final int qtyCross;
  final int qtyMain;
  final int qtyPeri;
  final int dlCount;
  final double profileRft;

  final Function(ScaleStartDetails details, double cw, double ch, double scale, Offset ctr) onScaleStart;
  final Function(ScaleUpdateDetails details, double cw, double ch, double scale, Offset ctr) onScaleUpdate;
  final Function(ScaleEndDetails details) onScaleEnd;
  final ValueChanged<double> onGridSpacingChanged;
  final ValueChanged<double> onAngleSnapChanged;
  final ValueChanged<bool> onPanZoomModeChanged;
  final VoidCallback onCopySelected;
  final VoidCallback onDeleteSelected;
  final Function(Offset localTap, double cw, double ch, double scale, Offset ctr) onCheckDimensionTap;

  const Pcm2dCanvas({
    super.key,
    required this.roomL,
    required this.roomW,
    required this.objects,
    required this.selectedId,
    required this.activeTool,
    required this.gridSpacing,
    required this.angleSnapDeg,
    required this.panZoomMode,
    required this.canvasZoom,
    required this.canvasOffset,
    required this.sketchPoints,
    required this.calculatedArea,
    required this.qtyCross,
    required this.qtyMain,
    required this.qtyPeri,
    required this.dlCount,
    required this.profileRft,
    required this.onScaleStart,
    required this.onScaleUpdate,
    required this.onScaleEnd,
    required this.onGridSpacingChanged,
    required this.onAngleSnapChanged,
    required this.onPanZoomModeChanged,
    required this.onCopySelected,
    required this.onDeleteSelected,
    required this.onCheckDimensionTap,
  });

  @override
  Widget build(BuildContext context) {
    CeilingObject? sel;
    if (selectedId != null) {
      try {
        sel = objects.firstWhere((o) => o.id == selectedId);
      } catch (_) {}
    }

    return Column(
      children: [
        // 2D Canvas toolbar header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          color: const Color(0xFF131722),
          child: Row(
            children: [
              const Icon(Icons.edit_road, color: Color(0xFFD4AF37), size: 16),
              const SizedBox(width: 6),
              const Text(
                '2D DRAFTING BLUEPRINT',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              // Pan & Zoom Lock switch
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('PAN/ZOOM MODE', style: TextStyle(color: Colors.white54, fontSize: 8, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 4),
                  Switch(
                    value: panZoomMode,
                    activeThumbColor: const Color(0xFFD4AF37),
                    onChanged: onPanZoomModeChanged,
                  ),
                ],
              ),
              const SizedBox(width: 10),
              // Snap spacing settings
              DropdownButton<double>(
                value: gridSpacing,
                dropdownColor: const Color(0xFF131722),
                underline: Container(),
                style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 9, fontWeight: FontWeight.bold),
                items: const [
                  DropdownMenuItem(value: 0.1, child: Text('GRID: 0.1 Ft')),
                  DropdownMenuItem(value: 0.25, child: Text('GRID: 0.25 Ft')),
                  DropdownMenuItem(value: 0.5, child: Text('GRID: 0.5 Ft')),
                  DropdownMenuItem(value: 1.0, child: Text('GRID: 1.0 Ft')),
                ],
                onChanged: (v) {
                  if (v != null) onGridSpacingChanged(v);
                },
              ),
              const SizedBox(width: 12),
              // Angle snap settings
              DropdownButton<double>(
                value: angleSnapDeg,
                dropdownColor: const Color(0xFF131722),
                underline: Container(),
                style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 9, fontWeight: FontWeight.bold),
                items: const [
                  DropdownMenuItem(value: 0.0, child: Text('ANGLE: FREE')),
                  DropdownMenuItem(value: 30.0, child: Text('ANGLE: 30°')),
                  DropdownMenuItem(value: 45.0, child: Text('ANGLE: 45°')),
                  DropdownMenuItem(value: 60.0, child: Text('ANGLE: 60°')),
                  DropdownMenuItem(value: 90.0, child: Text('ANGLE: 90°')),
                ],
                onChanged: (v) {
                  if (v != null) onAngleSnapChanged(v);
                },
              ),
            ],
          ),
        ),

        // Core Drawing Area
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double cw = constraints.maxWidth;
              final double ch = constraints.maxHeight;
              final double maxRoom = math.max(roomL, roomW);
              final double baseScale = (math.min(cw, ch) * 0.70) / (maxRoom <= 0 ? 1 : maxRoom);
              final double scale = baseScale * canvasZoom;
              final Offset ctr = Offset(cw / 2, ch / 2) + canvasOffset;

              return Stack(
                children: [
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onScaleStart: (details) => onScaleStart(details, cw, ch, scale, ctr),
                      onScaleUpdate: (details) => onScaleUpdate(details, cw, ch, scale, ctr),
                      onScaleEnd: onScaleEnd,
                      child: ClipRRect(
                        child: CustomPaint(
                          size: Size.infinite,
                          painter: CadBlueprintPainter(
                            objects: objects,
                            selectedId: selectedId,
                            roomL: roomL,
                            roomW: roomW,
                            gridSpacing: gridSpacing,
                            sketchPoints: sketchPoints,
                            canvasZoom: canvasZoom,
                            canvasOffset: canvasOffset,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return Dialog(
                                backgroundColor: Colors.transparent,
                                insetPadding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  alignment: Alignment.center,
                                  children: [
                                    PcmMaterialList(
                                      calculatedArea: calculatedArea,
                                      qtyCross: qtyCross,
                                      qtyMain: qtyMain,
                                      qtyPeri: qtyPeri,
                                      dlCount: dlCount,
                                      profileRft: profileRft,
                                    ),
                                    Positioned(
                                      right: -10,
                                      top: -10,
                                      child: GestureDetector(
                                        onTap: () => Navigator.of(context).pop(),
                                        child: const CircleAvatar(
                                          radius: 14,
                                          backgroundColor: Color(0xFFD4AF37),
                                          child: Icon(Icons.close, color: Colors.black, size: 16),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xEE1E293B),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFD4AF37), width: 1.0),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.receipt_long, color: Color(0xFFD4AF37), size: 14),
                              SizedBox(width: 4),
                              Text(
                                'View Materials',
                                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (sel != null && !panZoomMode)
                    _buildContextualMenu(sel, ctr, scale, cw, ch),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildContextualMenu(CeilingObject sel, Offset ctr, double scale, double cw, double ch) {
    final Offset centerFeet = sel.position;
    final Offset localPos = ctr + Offset(centerFeet.dx * scale, centerFeet.dy * scale);

    double objHeightOffset = 0.0;
    if (sel.type == 'gypsum_circle' || sel.type == 'downlight') {
      objHeightOffset = (sel.width / 2) * scale;
    } else if (sel.startPoint != null && sel.endPoint != null) {
      objHeightOffset = 15.0;
    } else {
      objHeightOffset = (sel.height / 2) * scale;
    }

    final double menuY = localPos.dy - objHeightOffset - 42;
    final double menuX = localPos.dx;

    const double menuWidth = 150;
    const double menuHeight = 32;

    final double left = (menuX - menuWidth / 2).clamp(10, cw - menuWidth - 10);
    final double top = menuY.clamp(10, ch - menuHeight - 10);

    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: menuWidth,
        height: menuHeight,
        decoration: BoxDecoration(
          color: const Color(0xEE11141A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFD4AF37), width: 1.2),
          boxShadow: const [
            BoxShadow(
              color: Colors.black87,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: onCopySelected,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(7)),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.copy, color: Color(0xFFD4AF37), size: 12),
                    SizedBox(width: 4),
                    Text('Copy', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            Container(width: 1, color: Colors.white10),
            Expanded(
              child: InkWell(
                onTap: onDeleteSelected,
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(7)),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.delete, color: Colors.redAccent, size: 12),
                    SizedBox(width: 4),
                    Text('Delete', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
