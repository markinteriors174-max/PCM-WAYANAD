import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'models/ceiling_object.dart';
import 'utils/snap_utils.dart';
import '../../services/database_service.dart';
import '../../models/quotation.dart';
import '../../theme/app_theme.dart';

// Modular Sub-components & Helpers
import 'pcm_ai_designer/utils/rdp_utils.dart';
import 'pcm_ai_designer/utils/component_library.dart';
import 'pcm_ai_designer/widgets/asset_drawer.dart';
import 'pcm_ai_designer/widgets/pcm_element_palette.dart';
import 'pcm_ai_designer/widgets/pcm_2d_canvas.dart';
import 'pcm_ai_designer/widgets/pcm_3d_viewer.dart';
import 'pcm_ai_designer/widgets/photo_overlay_painter.dart';
import 'pcm_ai_designer/widgets/cross_section_painter.dart';
import 'pcm_ai_designer/widgets/simulated_ar_feed.dart';
import 'pcm_ai_designer/widgets/simulated_ar_hud.dart';
import 'pcm_ai_designer/widgets/ar_layout_painter.dart';

class PcmAiDesignerScreen extends StatefulWidget {
  const PcmAiDesignerScreen({super.key});

  @override
  State<PcmAiDesignerScreen> createState() => _PcmAiDesignerScreenState();
}

class _PcmAiDesignerScreenState extends State<PcmAiDesignerScreen> with TickerProviderStateMixin {
  // View mode states
  int _rightViewportView = 0; // 0 = 3D Solid Orbit, 1 = Cross-Section, 2 = Photo Warp, 3 = AR Live View
  bool _panZoomMode = false;  // False = Edit/Draw Mode, True = Pan & Zoom viewport
  bool _showFramework = false; // False = Solid Gypsum view, True = Interlocking steel framework view
  bool _isLibraryOpened = false;

  // Room dimensions
  final _roomLengthController = TextEditingController(text: '12');
  final _roomWidthController  = TextEditingController(text: '10');
  double _gridSpacing         = 0.5;

  // CAD database objects list
  final List<CeilingObject> _objects = [];
  String? _selectedId;
  String? _dragMode; // 'move' | 'resize' | 'drag_start' | 'drag_end' | 'bend'
  Offset? _dragStartFeet;
  Offset? _dragStartPos;
  double? _dragStartW;
  double? _dragStartH;
  Offset? _dragStartStartPoint;
  Offset? _dragStartEndPoint;
  double? _dragStartCurvature;

  // Active sketch coordinates for rough drawing
  final List<Offset> _sketchPoints = [];

  // Pan/Zoom variables for the 2D CAD canvas
  double _canvasZoom = 1.0;
  Offset _canvasOffset = Offset.zero;
  Offset? _lastFocalPoint;

  // Object dimension adjustments controllers
  final _objWidthCtrl  = TextEditingController();
  final _objHeightCtrl = TextEditingController();
  bool _syncingProps   = false;

  // 3D parameters
  double _rotationX = 0.35;
  double _rotationY = 0.5;
  double _zoomScale = 1.0;
  bool _downlightsOn = true;
  bool _coveLightOn = true;
  late AnimationController _fanAnimController;

  // Photo & Perspective warp handles
  String? _uploadedImagePath;
  final int _selectedPreset = 0;
  List<Offset> _perspHandles = const [
    Offset(0.1, 0.1), Offset(0.9, 0.1),
    Offset(0.9, 0.9), Offset(0.1, 0.9),
  ];

  // AR Camera variables
  CameraController? _cameraController;
  bool _cameraInitialized = false;
  bool _cameraPermissionDenied = false;
  bool _arPlaneDetected = false;
  bool _arLayoutAnchored = false;

  // AR Alignment Offsets
  double _arCeilingHeight = 0.0;
  double _arRotationYaw = 0.0;
  double _arOffsetX = 0.0;
  double _arOffsetY = 0.0;
  double _arScale = 1.0;
  double _ambientBrightness = 1.0;
  Color _ambientColorTemp = Colors.white;
  String _arCoachingText = "Slowly move your phone upwards to scan the ceiling edges.";

  bool _depthApiEnabled = true;
  bool _globalLedStrip = false;
  bool _globalCoveLight = false;
  double _angleSnapDeg = 0.0;

  // Material calculations variables
  double _calculatedArea = 120.0;
  int _qtyCross  = 9;
  int _qtyMain   = 3;
  int _qtyPeri   = 4;
  int _dlCount   = 0;
  double _profileRft = 0.0;

  // Selected tool inside palette
  String _activeTool = 'select'; // 'select' | 'arc_modifier' | 'wall_line' | 'ceiling_grid' | 'gypsum_rect' | ...

  @override
  void initState() {
    super.initState();
    _fanAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    // Enforce Landscape Mode and Immersive mode on entry
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _roomLengthController.addListener(_onRoomChanged);
    _roomWidthController.addListener(_onRoomChanged);
    _objWidthCtrl.addListener(_onObjDimChanged);
    _objHeightCtrl.addListener(_onObjDimChanged);
    _onRoomChanged();
  }

  @override
  void dispose() {
    _fanAnimController.dispose();
    _disposeCamera();
    // Restore orientations on exit
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    _roomLengthController.removeListener(_onRoomChanged);
    _roomWidthController.removeListener(_onRoomChanged);
    _objWidthCtrl.removeListener(_onObjDimChanged);
    _objHeightCtrl.removeListener(_onObjDimChanged);
    _roomLengthController.dispose();
    _roomWidthController.dispose();
    _objWidthCtrl.dispose();
    _objHeightCtrl.dispose();
    super.dispose();
  }

  void _disposeCamera() {
    if (_cameraController != null) {
      _cameraController!.dispose();
      _cameraController = null;
      _cameraInitialized = false;
    }
  }

  void _initCamera() async {
    if (_cameraInitialized) return;
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _cameraPermissionDenied = true;
        });
        return;
      }
      
      final backCam = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      
      _cameraController = CameraController(
        backCam,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      
      await _cameraController!.initialize();
      
      int frameCount = 0;
      _cameraController!.startImageStream((CameraImage image) {
        frameCount++;
        if (frameCount % 30 == 0) {
          try {
            int sum = 0;
            final planes = image.planes;
            if (planes.isNotEmpty) {
              final bytes = planes[0].bytes;
              final int step = (bytes.length / 100).floor().clamp(1, 1000);
              int count = 0;
              for (int i = 0; i < bytes.length; i += step) {
                sum += bytes[i];
                count++;
              }
              final avg = count > 0 ? sum / count : 128.0;
              final bright = (avg / 255.0).clamp(0.2, 1.0);
              
              if (mounted) {
                setState(() {
                  _ambientBrightness = bright;
                  if (bright < 0.45) {
                    _ambientColorTemp = const Color(0xFFFFE57F);
                  } else if (bright > 0.75) {
                    _ambientColorTemp = const Color(0xFFE0F7FA);
                  } else {
                    _ambientColorTemp = Colors.white;
                  }
                });
              }
            }
          } catch (_) {}
        }
      });
      
      if (mounted) {
        setState(() {
          _cameraInitialized = true;
          _cameraPermissionDenied = false;
        });
      }
      
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _rightViewportView == 3) {
          setState(() {
            _arPlaneDetected = true;
            _arCoachingText = "Ceiling plane detected! Tap screen to anchor layout.";
          });
        }
      });
      
    } catch (_) {
      if (mounted) {
        setState(() {
          _cameraPermissionDenied = true;
        });
      }
    }
  }

  Widget _buildArControlsCard() {
    return Positioned(
      bottom: 12,
      left: 12,
      right: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xEE0C0E14),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD4AF37), width: 1.2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.tune, color: Color(0xFFD4AF37), size: 14),
                const SizedBox(width: 6),
                const Text('AR SNAP ALIGNMENT CONTROLS', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.restart_alt, color: Colors.white54, size: 14),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    setState(() {
                      _arCeilingHeight = 0.0;
                      _arRotationYaw = 0.0;
                      _arOffsetX = 0.0;
                      _arOffsetY = 0.0;
                      _arLayoutAnchored = false;
                      _arPlaneDetected = false;
                      _arCoachingText = "Slowly move your phone upwards to scan the ceiling edges.";
                      _initCamera();
                    });
                  },
                ),
              ],
            ),
            const Divider(color: Colors.white10, height: 8),
            Row(
              children: [
                const Expanded(flex: 4, child: Text('Ceiling Height (Z-offset)', style: TextStyle(color: Colors.white70, fontSize: 8))),
                Expanded(
                  flex: 6,
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(trackHeight: 2, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6)),
                    child: Slider(
                      value: _arCeilingHeight,
                      min: -15.0,
                      max: 15.0,
                      activeColor: const Color(0xFFD4AF37),
                      inactiveColor: Colors.white12,
                      onChanged: (v) => setState(() => _arCeilingHeight = v),
                    ),
                  ),
                ),
                SizedBox(width: 32, child: Text('${_arCeilingHeight.toStringAsFixed(1)}ft', style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 8, fontWeight: FontWeight.bold))),
              ],
            ),
            Row(
              children: [
                const Expanded(flex: 4, child: Text('Ceiling Rotation (Yaw)', style: TextStyle(color: Colors.white70, fontSize: 8))),
                Expanded(
                  flex: 6,
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(trackHeight: 2, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6)),
                    child: Slider(
                      value: _arRotationYaw,
                      min: -math.pi,
                      max: math.pi,
                      activeColor: const Color(0xFFD4AF37),
                      inactiveColor: Colors.white12,
                      onChanged: (v) => setState(() => _arRotationYaw = v),
                    ),
                  ),
                ),
                SizedBox(width: 32, child: Text('${(_arRotationYaw * 180 / math.pi).toStringAsFixed(0)}Â°', style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 8, fontWeight: FontWeight.bold))),
              ],
            ),
            Row(
              children: [
                const Expanded(flex: 4, child: Text('X-Axis Alignment', style: TextStyle(color: Colors.white70, fontSize: 8))),
                Expanded(
                  flex: 6,
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(trackHeight: 2, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6)),
                    child: Slider(
                      value: _arOffsetX,
                      min: -20.0,
                      max: 20.0,
                      activeColor: const Color(0xFFD4AF37),
                      inactiveColor: Colors.white12,
                      onChanged: (v) => setState(() => _arOffsetX = v),
                    ),
                  ),
                ),
                SizedBox(width: 32, child: Text('${_arOffsetX.toStringAsFixed(1)}ft', style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 8, fontWeight: FontWeight.bold))),
              ],
            ),
            Row(
              children: [
                const Expanded(flex: 4, child: Text('Y-Axis Alignment', style: TextStyle(color: Colors.white70, fontSize: 8))),
                Expanded(
                  flex: 6,
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(trackHeight: 2, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6)),
                    child: Slider(
                      value: _arOffsetY,
                      min: -20.0,
                      max: 20.0,
                      activeColor: const Color(0xFFD4AF37),
                      inactiveColor: Colors.white12,
                      onChanged: (v) => setState(() => _arOffsetY = v),
                    ),
                  ),
                ),
                SizedBox(width: 32, child: Text('${_arOffsetY.toStringAsFixed(1)}ft', style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 8, fontWeight: FontWeight.bold))),
              ],
            ),
            const Divider(color: Colors.white10, height: 8),
            Row(
              children: [
                const Expanded(flex: 7, child: Text('Environment Depth API (Real-time Occlusion)', style: TextStyle(color: Colors.white70, fontSize: 8))),
                Expanded(
                  flex: 3,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(
                      height: 20,
                      child: Switch(
                        value: _depthApiEnabled,
                        activeThumbColor: const Color(0xFF00FF87),
                        onChanged: (v) {
                          setState(() {
                            _depthApiEnabled = v;
                            if (v) {
                              _arCoachingText = "Depth API active: Real-time occlusion enabled.";
                            } else {
                              _arCoachingText = "Depth API off: Gypsum mesh overlays environment.";
                            }
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _onRoomChanged() {
    final double l = double.tryParse(_roomLengthController.text) ?? 12.0;
    final double w = double.tryParse(_roomWidthController.text) ?? 10.0;

    final int mainRuns = (w / 4.0).ceil() + 1;
    final double totalMainFt = mainRuns * l;
    int mainPcs = (totalMainFt / 12.0).ceil();

    final int crossRuns = (l / 2.0).ceil() + 1;
    final double totalCrossFt = crossRuns * w;
    int crossPcs = (totalCrossFt / 12.0).ceil();

    final double perimeterFt = 2 * (l + w);
    int periPcs = (perimeterFt / 12.0).ceil();

    double extraPerim = 0;
    int dl = 0;
    double profileRft = 0.0;
    for (final o in _objects) {
      if (o.type == 'downlight') {
        dl++;
      } else if (o.type == 'profile_light') {
        profileRft += o.perimeter;
      } else if (o.type == 'ceiling_grid') {
        final double gArea = o.width * o.height;
        crossPcs += (gArea / 10.0).ceil();
        mainPcs += (gArea / 30.0).ceil();
      } else {
        extraPerim += o.perimeter;
      }
    }

    crossPcs += (extraPerim / 12.0).ceil();
    mainPcs += (extraPerim / 24.0).ceil();
    periPcs += (extraPerim / 12.0).ceil();

    final double area = l * w;
    setState(() {
      _calculatedArea = area;
      _qtyCross = crossPcs;
      _qtyMain = mainPcs;
      _qtyPeri = periPcs;
      _dlCount = dl;
      _profileRft = profileRft;
    });
  }

  void _onObjDimChanged() {
    if (_syncingProps) return;
    final obj = _getSelected();
    if (obj == null) return;
    final nw = double.tryParse(_objWidthCtrl.text);
    final nh = double.tryParse(_objHeightCtrl.text);
    if (nw != null && nw > 0) {
      setState(() {
        obj.width = snapDim(nw, _gridSpacing);
        if (obj.startPoint != null && obj.endPoint != null) {
          final Offset dir = obj.endPoint! - obj.startPoint!;
          final double dist = dir.distance;
          if (dist > 0) {
            obj.endPoint = obj.startPoint! + (dir / dist) * obj.width;
            obj.position = (obj.startPoint! + obj.endPoint!) / 2;
          }
        }
      });
    }
    if (nh != null && nh > 0) {
      setState(() {
        obj.height = snapDim(nh, _gridSpacing);
      });
    }
    _onRoomChanged();
  }

  CeilingObject? _getSelected() {
    if (_selectedId == null) return null;
    try {
      return _objects.firstWhere((o) => o.id == _selectedId);
    } catch (_) {
      return null;
    }
  }

  void _syncPropFields() {
    final obj = _getSelected();
    if (obj == null) return;
    _syncingProps = true;
    _objWidthCtrl.text = obj.width.toStringAsFixed(1);
    _objHeightCtrl.text = obj.height.toStringAsFixed(1);
    _syncingProps = false;
  }

  void _addObject(String type) {
    final double l = double.tryParse(_roomLengthController.text) ?? 12.0;
    final double w = double.tryParse(_roomWidthController.text) ?? 10.0;
    double ow = 4.0, oh = 4.0;
    Offset? start;
    Offset? end;

    if (type == 'main_channel') {
      final double len = (l * 0.6).clamp(1.0, l);
      ow = len; oh = 0.2;
      start = Offset(-len / 2, 0.0);
      end = Offset(len / 2, 0.0);
    } else if (type == 'cross_channel') {
      final double len = (w * 0.6).clamp(1.0, w);
      ow = 0.2; oh = len;
      start = Offset(0.0, -len / 2);
      end = Offset(0.0, len / 2);
    } else if (type == 'wall_line') {
      ow = 6.0; oh = 0.3;
      start = const Offset(-3.0, 0.0);
      end = const Offset(3.0, 0.0);
    } else if (type == 'ceiling_grid') {
      ow = 6.0; oh = 6.0;
    } else if (type == 'border_profile') {
      ow = 8.0; oh = 8.0;
    } else if (type == 'ac_vent') {
      ow = 3.0; oh = 1.5;
    } else if (type == 'fan_box') {
      ow = 2.0; oh = 2.0;
    } else if (type == 'downlight') {
      ow = 0.5; oh = 0.5;
    } else if (type == 'profile_light') {
      ow = 4.0; oh = 0.15;
      start = const Offset(-2.0, 0.0);
      end = const Offset(2.0, 0.0);
    } else if (type == 'gypsum_arc') {
      ow = 6.0; oh = 1.0;
      start = const Offset(-3.0, 0.0);
      end = const Offset(3.0, 0.0);
    } else if (type == 'gypsum_oval') {
      ow = 6.0; oh = 4.0;
    }

    final id = '${type}_${DateTime.now().millisecondsSinceEpoch}';
    final obj = CeilingObject(
      id: id,
      type: type,
      position: Offset.zero,
      width: ow,
      height: oh,
      startPoint: start,
      endPoint: end,
      arcCurvature: type == 'gypsum_arc' ? 1.5 : 0.0,
      hasLedStrip: _globalLedStrip,
      hasCoveLight: _globalCoveLight,
    );
    setState(() {
      _objects.add(obj);
      _selectedId = id;
      _syncPropFields();
      _activeTool = 'select'; // auto restore to select tool
    });
    _onRoomChanged();
  }

  void _addLibraryComponent(ComponentItem item, Offset position) {
    double ow = item.defaultWidth;
    double oh = item.defaultHeight;
    Offset? start;
    Offset? end;

    if (item.shapeFamily == 'line' || item.shapeFamily == 'arc') {
      start = position + Offset(-ow / 2, 0.0);
      end = position + Offset(ow / 2, 0.0);
    }

    double initialRotation = 0.0;
    Offset finalPos = position;

    if (item.shapeFamily == 'sticker' || item.id.contains('wall_fan')) {
      final snapResult = snapToWall(position, _objects, 1.5);
      if (snapResult['snapped'] == true) {
        finalPos = snapResult['position'] as Offset;
        initialRotation = snapResult['rotation'] as double;
      }
    } else if (item.shapeFamily == 'louver' || item.shapeFamily == 'fan') {
      final double l = double.tryParse(_roomLengthController.text) ?? 12.0;
      final double w = double.tryParse(_roomWidthController.text) ?? 10.0;
      final double halfL = l / 2;
      final double halfW = w / 2;
      finalPos = Offset(
        position.dx.clamp(-halfL, halfL),
        position.dy.clamp(-halfW, halfW),
      );
    }

    final id = '${item.id}_${DateTime.now().millisecondsSinceEpoch}';
    final obj = CeilingObject(
      id: id,
      type: item.id,
      position: finalPos,
      width: ow,
      height: oh,
      startPoint: start,
      endPoint: end,
      arcCurvature: item.shapeFamily == 'arc' ? 1.5 : 0.0,
      rotation: initialRotation,
      hasLedStrip: _globalLedStrip,
      hasCoveLight: _globalCoveLight,
    );

    setState(() {
      _objects.add(obj);
      _selectedId = id;
      _syncPropFields();
      _activeTool = 'select';
    });
    _onRoomChanged();
  }


  void _deleteSelected() {
    if (_selectedId == null) return;
    setState(() {
      _objects.removeWhere((o) => o.id == _selectedId);
      _selectedId = null;
      _objWidthCtrl.clear();
      _objHeightCtrl.clear();
    });
    _onRoomChanged();
  }

  void _copySelected() {
    final obj = _getSelected();
    if (obj == null) return;
    final newId = '${obj.type}_${DateTime.now().millisecondsSinceEpoch}';
    final Offset offset = const Offset(0.5, 0.5); // +0.5 Ft diagonal offset
    final duplicate = CeilingObject(
      id: newId,
      type: obj.type,
      position: obj.position + offset,
      width: obj.width,
      height: obj.height,
      startPoint: obj.startPoint != null ? obj.startPoint! + offset : null,
      endPoint: obj.endPoint != null ? obj.endPoint! + offset : null,
      arcCurvature: obj.arcCurvature,
      rotation: obj.rotation,
      hasLedStrip: obj.hasLedStrip,
      hasCoveLight: obj.hasCoveLight,
    );
    setState(() {
      _objects.add(duplicate);
      _selectedId = newId;
      _dragMode = 'move';
      _dragStartFeet = duplicate.position;
      _dragStartPos = duplicate.position;
      if (duplicate.startPoint != null && duplicate.endPoint != null) {
        _dragStartStartPoint = duplicate.startPoint;
        _dragStartEndPoint = duplicate.endPoint;
      }
      _syncPropFields();
    });
    _onRoomChanged();
  }

  bool _isInResizeHandle(Offset touchFt, CeilingObject obj) {
    if (obj.startPoint != null && obj.endPoint != null) {
      final bool nearStart = (touchFt - obj.startPoint!).distance < 0.9;
      final bool nearEnd = (touchFt - obj.endPoint!).distance < 0.9;
      return nearStart || nearEnd;
    }
    final handle = obj.position + Offset(obj.width / 2, obj.height / 2);
    return (touchFt - handle).distance < 0.9;
  }

  String? _hitTest(Offset touchFt) {
    for (int i = _objects.length - 1; i >= 0; i--) {
      final o = _objects[i];
      if (o.startPoint != null && o.endPoint != null) {
        if (o.arcCurvature != null && o.arcCurvature != 0) {
          // Check proximity to Bezier curve midpoint handle
          final Offset mid = (o.startPoint! + o.endPoint!) / 2;
          final Offset dir = o.endPoint! - o.startPoint!;
          final double dLen = dir.distance;
          if (dLen > 0) {
            final Offset norm = Offset(-dir.dy, dir.dx) / dLen;
            final Offset curveCenter = mid + norm * o.arcCurvature!;
            if ((touchFt - curveCenter).distance <= 0.8) return o.id;
          }
        }
        if (distanceToSegment(touchFt, o.startPoint!, o.endPoint!) <= 0.6) return o.id;
      } else if (o.type == 'gypsum_circle' || o.type == 'downlight') {
        if ((touchFt - o.position).distance <= o.width / 2 + 0.3) return o.id;
      } else {
        final r = Rect.fromCenter(center: Offset(o.position.dx, o.position.dy), width: o.width, height: o.height);
        if (r.inflate(0.3).contains(touchFt)) return o.id;
      }
    }
    return null;
  }

  void _checkDimensionTap(Offset localTap, double cw, double ch, double scale, Offset ctr, double roomL, double roomW, CeilingObject? sel) {
    final double tlDy = ctr.dy - (roomW / 2) * scale;
    final Offset roomLPos = Offset(ctr.dx, tlDy - 24);
    if ((localTap - roomLPos).distance < 25) {
      _showEditDimensionDialog('Room Length', _roomLengthController);
      return;
    }

    final double brDx = ctr.dx + (roomL / 2) * scale;
    final Offset roomWPos = Offset(brDx + 31, ctr.dy);
    if ((localTap - roomWPos).distance < 25) {
      _showEditDimensionDialog('Room Width', _roomWidthController);
      return;
    }

    if (sel != null) {
      final double objX = ctr.dx + sel.position.dx * scale;
      final double objY = ctr.dy + sel.position.dy * scale;

      if (sel.type == 'gypsum_circle' || sel.type == 'downlight') {
        final double r = (sel.width / 2) * scale;
        final Offset objWPos = Offset(objX, objY - r - 14);
        if ((localTap - objWPos).distance < 25) {
          _showEditDimensionDialog('Diameter', _objWidthCtrl);
          return;
        }
      } else if (sel.startPoint != null && sel.endPoint != null) {
        final Offset pStart = ctr + Offset(sel.startPoint!.dx * scale, sel.startPoint!.dy * scale);
        final Offset pEnd = ctr + Offset(sel.endPoint!.dx * scale, sel.endPoint!.dy * scale);
        final Offset midPos = (pStart + pEnd) / 2;
        final Offset labelPos = midPos - const Offset(0, 12);
        if ((localTap - labelPos).distance < 25) {
          _showEditDimensionDialog('Length', _objWidthCtrl);
          return;
        }
      } else {
        final double objTlY = objY - (sel.height / 2) * scale;
        final Offset objWPos = Offset(objX, objTlY - 12);
        if ((localTap - objWPos).distance < 25) {
          _showEditDimensionDialog('Width', _objWidthCtrl);
          return;
        }

        final double objBrX = objX + (sel.width / 2) * scale;
        final Offset objHPos = Offset(objBrX + 18, objY);
        if ((localTap - objHPos).distance < 25) {
          _showEditDimensionDialog('Height / Depth', _objHeightCtrl);
          return;
        }
      }
    }
  }

  void _showEditDimensionDialog(String title, TextEditingController controller) {
    showDialog(
      context: context,
      builder: (ctx) {
        final textCtrl = TextEditingController(text: controller.text);
        return AlertDialog(
          backgroundColor: const Color(0xFF16130F),
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text('Edit $title (Ft)', style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 14)),
          content: TextField(
            controller: textCtrl,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            decoration: _darkDecoration('Value in Feet'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCEL', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37)),
              onPressed: () {
                final val = double.tryParse(textCtrl.text);
                if (val != null && val > 0) {
                  setState(() {
                    controller.text = val.toStringAsFixed(1);
                  });
                  _onRoomChanged();
                }
                Navigator.pop(ctx);
              },
              child: const Text('SAVE', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _regularizeSketch(List<Offset> points, double roomL, double roomW) {
    if (points.length < 5) return;
    double minX = double.infinity;
    double maxX = -double.infinity;
    double minY = double.infinity;
    double maxY = -double.infinity;

    for (final pt in points) {
      if (pt.dx < minX) minX = pt.dx;
      if (pt.dx > maxX) maxX = pt.dx;
      if (pt.dy < minY) minY = pt.dy;
      if (pt.dy > maxY) maxY = pt.dy;
    }

    final double width = snapDim(maxX - minX, _gridSpacing);
    final double height = snapDim(maxY - minY, _gridSpacing);
    final Offset center = snapToGrid(Offset((minX + maxX) / 2, (minY + maxY) / 2), roomL, roomW, _gridSpacing);

    if (width <= 0.2 || height <= 0.2) return;

    if (_activeTool == 'gypsum_circle') {
      final double diameter = snapDim((width + height) / 2, _gridSpacing);
      final id = 'gypsum_circle_${DateTime.now().millisecondsSinceEpoch}';
      setState(() {
        _objects.add(CeilingObject(
          id: id,
          type: 'gypsum_circle',
          position: Offset.zero, // snapped centerpiece
          width: diameter,
          height: diameter,
          arcCurvature: 0.0,
          hasLedStrip: _globalLedStrip,
          hasCoveLight: _globalCoveLight,
        ));
        _selectedId = id;
        _syncPropFields();
      });
    } else if (_activeTool == 'gypsum_oval') {
      final id = 'gypsum_oval_${DateTime.now().millisecondsSinceEpoch}';
      setState(() {
        _objects.add(CeilingObject(
          id: id,
          type: 'gypsum_oval',
          position: Offset.zero, // snapped centerpiece
          width: width,
          height: height,
          arcCurvature: 0.0,
          hasLedStrip: _globalLedStrip,
          hasCoveLight: _globalCoveLight,
        ));
        _selectedId = id;
        _syncPropFields();
      });
    } else if (_activeTool == 'gypsum_rect') {
      final id = 'gypsum_rect_${DateTime.now().millisecondsSinceEpoch}';
      setState(() {
        _objects.add(CeilingObject(
          id: id,
          type: 'gypsum_rect',
          position: center,
          width: width,
          height: height,
          arcCurvature: 0.0,
          hasLedStrip: _globalLedStrip,
          hasCoveLight: _globalCoveLight,
        ));
        _selectedId = id;
        _syncPropFields();
      });
    } else if (_activeTool == 'gypsum_arc') {
      final id = 'gypsum_arc_${DateTime.now().millisecondsSinceEpoch}';
      final start = snapToGrid(points.first, roomL, roomW, _gridSpacing);
      final end = snapToGrid(points.last, roomL, roomW, _gridSpacing);
      setState(() {
        _objects.add(CeilingObject(
          id: id,
          type: 'gypsum_arc',
          position: (start + end) / 2,
          width: (end - start).distance,
          height: 1.0,
          startPoint: start,
          endPoint: end,
          arcCurvature: 1.5,
          hasLedStrip: _globalLedStrip,
          hasCoveLight: _globalCoveLight,
        ));
        _selectedId = id;
        _syncPropFields();
      });
    } else if (_activeTool == 'wall_line') {
      final id = 'wall_line_${DateTime.now().millisecondsSinceEpoch}';
      final start = snapToGrid(points.first, roomL, roomW, _gridSpacing);
      final end = snapToGrid(points.last, roomL, roomW, _gridSpacing);
      setState(() {
        _objects.add(CeilingObject(
          id: id,
          type: 'wall_line',
          position: (start + end) / 2,
          width: (end - start).distance,
          height: 0.3,
          startPoint: start,
          endPoint: end,
          arcCurvature: 0.0,
          hasLedStrip: _globalLedStrip,
          hasCoveLight: _globalCoveLight,
        ));
        _selectedId = id;
        _syncPropFields();
      });
    } else if (_activeTool == 'profile_light') {
      final List<Offset> vertices = findVertices(points, roomL, roomW, _gridSpacing);
      for (int i = 0; i < vertices.length - 1; i++) {
        final start = vertices[i];
        final end = vertices[i+1];
        if ((end - start).distance < 0.2) continue;
        final id = 'profile_light_${DateTime.now().millisecondsSinceEpoch}_$i';
        setState(() {
          _objects.add(CeilingObject(
            id: id,
            type: 'profile_light',
            position: (start + end) / 2,
            width: (end - start).distance,
            height: 0.15,
            startPoint: start,
            endPoint: end,
            arcCurvature: 0.0,
            hasLedStrip: _globalLedStrip,
            hasCoveLight: _globalCoveLight,
          ));
        });
      }
    }
    _onRoomChanged();
  }

  void _exportToDispatchList() {
    final locationCtrl = TextEditingController(text: 'CAD Landscape Site');
    final clientCtrl = TextEditingController(text: 'Client Plan');
    final contractorCtrl = TextEditingController(text: 'PCM Designer');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16130F),
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text('Export to Material Dispatch', style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 14)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Create a new Material Dispatch entry in the local database with these calculated quantities.', style: TextStyle(color: Colors.white70, fontSize: 11)),
              const SizedBox(height: 15),
              TextField(controller: locationCtrl, style: const TextStyle(color: Colors.white, fontSize: 13), decoration: _darkDecoration('Site Location')),
              const SizedBox(height: 12),
              TextField(controller: clientCtrl, style: const TextStyle(color: Colors.white, fontSize: 13), decoration: _darkDecoration('Client Name / Phone')),
              const SizedBox(height: 12),
              TextField(controller: contractorCtrl, style: const TextStyle(color: Colors.white, fontSize: 13), decoration: _darkDecoration('Contractor / Revision')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37)),
            onPressed: () async {
              Navigator.pop(ctx);
              final List<MaterialAssignment> mats = [
                MaterialAssignment(materialName: 'Ceiling Sheets (Gypsum)', unit: 'SqFt', rate: 0.0, quantity: _calculatedArea, amount: 0.0),
                MaterialAssignment(materialName: 'Cross Channel (12 ft)', unit: 'Pcs', rate: 0.0, quantity: _qtyCross.toDouble(), amount: 0.0),
                MaterialAssignment(materialName: 'Main Channel (12 ft)', unit: 'Pcs', rate: 0.0, quantity: _qtyMain.toDouble(), amount: 0.0),
                MaterialAssignment(materialName: 'Wall Perimeter (12 ft)', unit: 'Pcs', rate: 0.0, quantity: _qtyPeri.toDouble(), amount: 0.0),
                if (_dlCount > 0) MaterialAssignment(materialName: 'LED Downlight (Spot)', unit: 'Pcs', rate: 0.0, quantity: _dlCount.toDouble(), amount: 0.0),
                if (_profileRft > 0) ...[
                  MaterialAssignment(materialName: 'Aluminum Profile Channel', unit: 'Rft', rate: 0.0, quantity: double.parse(_profileRft.toStringAsFixed(1)), amount: 0.0),
                  MaterialAssignment(materialName: 'LED Strip & Diffuser', unit: 'Rft', rate: 0.0, quantity: double.parse(_profileRft.toStringAsFixed(1)), amount: 0.0),
                ],
              ];
              final String unitNumber = 'DISPATCH-${DateFormat('yyyyMMdd-HHmmss').format(DateTime.now())}';
              final String currentDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

              final newQuotation = Quotation(
                unitNumber: unitNumber,
                clientName: clientCtrl.text.trim(),
                clientPhone: '',
                clientLocation: locationCtrl.text.trim(),
                date: currentDate,
                totalAmount: 0.0,
                paidAmount: 0.0,
                balanceAmount: 0.0,
                items: const [],
                materials: mats,
                revisionNote: contractorCtrl.text.trim(),
                projectStatus: 'Dispatch',
              );
              await DatabaseService.instance.saveFullQuotation(newQuotation);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Successfully exported to $unitNumber!'), backgroundColor: AppColors.resultGreen));
              }
            },
            child: const Text('SAVE DISPATCH', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: const Color(0xFF0F1524),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(15))),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.blue),
              title: const Text('Photo Gallery', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: const Text('Camera', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source != null) {
      final img = await picker.pickImage(source: source);
      if (img != null) {
        setState(() {
          _uploadedImagePath = img.path;
          _rightViewportView = 2; // Jump to perspective photo warp
        });
      }
    }
  }

  InputDecoration _darkDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white24, fontSize: 11),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      border: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFD4AF37))),
      enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFD4AF37))),
    );
  }

  void _onCanvasDown(Offset local, double cw, double ch, double scale, Offset ctr, double roomL, double roomW, CeilingObject? sel) {
    if (_panZoomMode) return;
    Offset localToFt(Offset l) => (l - ctr) / scale;
    final ft = localToFt(local);

    if (_activeTool == 'arc_modifier') {
      final hitId = _hitTest(ft);
      if (hitId != null) {
        final obj = _objects.firstWhere((o) => o.id == hitId);
        if (obj.startPoint != null && obj.endPoint != null) {
          setState(() {
            _selectedId = hitId;
            _dragMode = 'bend';
            _dragStartFeet = ft;
            _dragStartCurvature = obj.arcCurvature ?? 0.0;
          });
          return;
        }
      }
    }

    if (_selectedId != null) {
      final obj = _getSelected();
      if (obj != null) {
        if (obj.startPoint != null && obj.endPoint != null) {
          final bool nearStart = (ft - obj.startPoint!).distance < 0.9;
          final bool nearEnd = (ft - obj.endPoint!).distance < 0.9;
          if (nearStart) {
            setState(() {
              _dragMode = 'drag_start';
              _dragStartFeet = ft;
              _dragStartStartPoint = obj.startPoint;
              _dragStartEndPoint = obj.endPoint;
            });
            return;
          } else if (nearEnd) {
            setState(() {
              _dragMode = 'drag_end';
              _dragStartFeet = ft;
              _dragStartStartPoint = obj.startPoint;
              _dragStartEndPoint = obj.endPoint;
            });
            return;
          }
        } else if (_isInResizeHandle(ft, obj)) {
          setState(() {
            _dragMode = 'resize';
            _dragStartFeet = ft;
            _dragStartW = obj.width;
            _dragStartH = obj.height;
          });
          return;
        }
      }
    }

    if (_activeTool == 'select') {
      bool hitSelected = false;
      if (_selectedId != null) {
        final obj = _getSelected();
        if (obj != null) {
          if (obj.startPoint != null && obj.endPoint != null) {
            if (distanceToSegment(ft, obj.startPoint!, obj.endPoint!) <= 1.0) {
              hitSelected = true;
            }
          } else if (obj.type == 'gypsum_circle' || obj.type == 'downlight') {
            if ((ft - obj.position).distance <= obj.width / 2 + 0.8) {
              hitSelected = true;
            }
          } else {
            final r = Rect.fromCenter(center: obj.position, width: obj.width, height: obj.height);
            if (r.inflate(0.8).contains(ft)) {
              hitSelected = true;
            }
          }
        }
      }

      final hitId = hitSelected ? _selectedId : _hitTest(ft);
      if (hitId != null) {
        final obj = _objects.firstWhere((o) => o.id == hitId);
        setState(() {
          _selectedId = hitId;
          _dragMode = 'move';
          _dragStartFeet = ft;
          _dragStartPos = obj.position;
          if (obj.startPoint != null && obj.endPoint != null) {
            _dragStartStartPoint = obj.startPoint;
            _dragStartEndPoint = obj.endPoint;
          }
          _syncPropFields();
        });
      } else {
        _checkDimensionTap(local, cw, ch, scale, ctr, roomL, roomW, sel);
        setState(() {
          _selectedId = null;
          _dragMode = null;
        });
      }
    } else {
      setState(() {
        _sketchPoints.clear();
        _sketchPoints.add(ft);
      });
    }
  }

  void _onCanvasMove(Offset local, double cw, double ch, double scale, Offset ctr, double roomL, double roomW) {
    if (_panZoomMode) return;
    Offset localToFt(Offset l) => (l - ctr) / scale;
    final ft = localToFt(local);

    if (_activeTool != 'select' && _activeTool != 'arc_modifier') {
      setState(() {
        _sketchPoints.add(ft);
      });
      return;
    }

    if (_dragMode == null || _selectedId == null) return;
    final obj = _getSelected();
    if (obj == null) return;
    final delta = ft - _dragStartFeet!;

    setState(() {
      if (_dragMode == 'bend') {
        final Offset dir = obj.endPoint! - obj.startPoint!;
        final double dLen = dir.distance;
        if (dLen > 0) {
          final Offset norm = Offset(-dir.dy, dir.dx) / dLen;
          final double perpDist = delta.dx * norm.dx + delta.dy * norm.dy;
          obj.arcCurvature = _dragStartCurvature! + snapFt(perpDist, _gridSpacing);
        }
      } else if (_dragMode == 'move') {
        if (obj.startPoint != null && obj.endPoint != null) {
          final Offset newStart = _dragStartStartPoint! + delta;
          final Offset newEnd = _dragStartEndPoint! + delta;
          Offset sGrid = snapToGrid(newStart, roomL, roomW, _gridSpacing);
          Offset eGrid = snapToGrid(newEnd, roomL, roomW, _gridSpacing);
          
          sGrid = snapToVertices(sGrid, _objects, obj.id, 0.6);
          eGrid = snapToVertices(eGrid, _objects, obj.id, 0.6);

          obj.startPoint = sGrid;
          obj.endPoint = eGrid;
          obj.position = (obj.startPoint! + obj.endPoint!) / 2;
          obj.width = (obj.endPoint! - obj.startPoint!).distance;
        } else {
          Offset newPos = snapToGrid(_dragStartPos! + delta, roomL, roomW, _gridSpacing);
          if (obj.type == 'gypsum_circle' || obj.type == 'gypsum_oval') {
            if (newPos.distance < 0.8) {
              newPos = Offset.zero;
            }
          }

          ComponentItem? comp;
          try {
            comp = componentLibrary.firstWhere((c) => c.id == obj.type);
          } catch (_) {}
          final String family = comp?.shapeFamily ?? obj.type;

          if (family == 'sticker' || obj.type.contains('wall_fan')) {
            final snapResult = snapToWall(newPos, _objects.where((o) => o.id != obj.id).toList(), 1.5);
            if (snapResult['snapped'] == true) {
              newPos = snapResult['position'] as Offset;
              obj.rotation = snapResult['rotation'] as double;
            }
          } else if (family == 'louver' || family == 'fan') {
            final double halfL = roomL / 2;
            final double halfW = roomW / 2;
            newPos = Offset(
              newPos.dx.clamp(-halfL, halfL),
              newPos.dy.clamp(-halfW, halfW),
            );
          }
          obj.position = newPos;
        }
      } else if (_dragMode == 'resize') {
        obj.width  = snapDim(_dragStartW! + delta.dx, _gridSpacing);
        obj.height = snapDim(_dragStartH! + delta.dy, _gridSpacing);
        _syncPropFields();
      } else if (_dragMode == 'drag_start') {
        Offset sGrid = snapToGrid(_dragStartStartPoint! + delta, roomL, roomW, _gridSpacing);
        sGrid = snapToVertices(sGrid, _objects, obj.id, 0.6);
        if (obj.endPoint != null) {
          sGrid = snapToAngle(sGrid, obj.endPoint!, _angleSnapDeg);
        }
        obj.startPoint = sGrid;
        obj.width = (obj.endPoint! - obj.startPoint!).distance;
        obj.position = (obj.startPoint! + obj.endPoint!) / 2;
        _syncPropFields();
      } else if (_dragMode == 'drag_end') {
        Offset eGrid = snapToGrid(_dragStartEndPoint! + delta, roomL, roomW, _gridSpacing);
        eGrid = snapToVertices(eGrid, _objects, obj.id, 0.6);
        if (obj.startPoint != null) {
          eGrid = snapToAngle(eGrid, obj.startPoint!, _angleSnapDeg);
        }
        obj.endPoint = eGrid;
        obj.width = (obj.endPoint! - obj.startPoint!).distance;
        obj.position = (obj.startPoint! + obj.endPoint!) / 2;
        _syncPropFields();
      }
    });
    _onRoomChanged();
  }

  void _onCanvasUp(double roomL, double roomW) {
    if (_panZoomMode) return;
    if (_sketchPoints.isNotEmpty) {
      _regularizeSketch(List.from(_sketchPoints), roomL, roomW);
      setState(() {
        _sketchPoints.clear();
      });
    }
    setState(() => _dragMode = null);
  }

  @override
  Widget build(BuildContext context) {
    final double roomL = double.tryParse(_roomLengthController.text) ?? 12.0;
    final double roomW = double.tryParse(_roomWidthController.text) ?? 10.0;
    final CeilingObject? sel = _getSelected();

    return Scaffold(
      backgroundColor: const Color(0xFF0C0E14),
      appBar: AppBar(
        title: const Text(
          'PCM AI DESIGNER â€¢ DEDICATED CANVAS',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 13, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Visualizer modes dropdown
          DropdownButton<int>(
            value: _rightViewportView,
            dropdownColor: const Color(0xFF1E293B),
            underline: Container(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
            items: const [
              DropdownMenuItem(value: 0, child: Text('3D SOLID ORBIT')),
              DropdownMenuItem(value: 1, child: Text('CROSS-SECTION')),
              DropdownMenuItem(value: 2, child: Text('PHOTO PREVIEW')),
              DropdownMenuItem(value: 3, child: Text('AR SCAN VIEW')),
            ],
            onChanged: (v) {
              if (v != null) {
                setState(() => _rightViewportView = v);
                if (v == 3) {
                  _initCamera();
                } else {
                  _disposeCamera();
                }
              }
            },
          ),
          const SizedBox(width: 15),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            tooltip: 'Clear Objects',
            onPressed: () {
              setState(() {
                _objects.clear();
                _selectedId = null;
              });
              _onRoomChanged();
            },
          ),
          IconButton(
            icon: const Icon(Icons.upload_file, color: Colors.white70),
            tooltip: 'Upload Backplate Photo',
            onPressed: _pickPhoto,
          ),
          IconButton(
            icon: const Icon(Icons.save_alt, color: Color(0xFFD4AF37)),
            tooltip: 'Export Dispatch',
            onPressed: _exportToDispatchList,
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Row( // Horizontal Split Screen
        children: [
          // Left Half Workspace
          Expanded(
            flex: 5,
            child: Column(
              children: [
                PcmElementPalette(
                  selectedObject: sel,
                  activeTool: _activeTool,
                  onToolSelected: (tool) => setState(() => _activeTool = tool),
                  onDeleteSelected: _deleteSelected,
                  widthController: _objWidthCtrl,
                  heightController: _objHeightCtrl,
                  onAddObject: _addObject,
                  globalLedStrip: _globalLedStrip,
                  globalCoveLight: _globalCoveLight,
                  onGlobalLedStripChanged: (v) => setState(() => _globalLedStrip = v),
                  onGlobalCoveLightChanged: (v) => setState(() => _globalCoveLight = v),
                  onRotationChanged: (rot) {
                    final o = _getSelected();
                    if (o != null) {
                      setState(() {
                        o.rotation = rot;
                      });
                    }
                  },
                  onLedStripToggled: (v) {
                    final o = _getSelected();
                    if (o != null) {
                      setState(() {
                        o.hasLedStrip = v;
                      });
                    }
                  },
                  onCoveLightToggled: (v) {
                    final o = _getSelected();
                    if (o != null) {
                      setState(() {
                        o.hasCoveLight = v;
                      });
                    }
                  },
                  onOpenAssetLibrary: () {
                    setState(() {
                      _isLibraryOpened = !_isLibraryOpened;
                    });
                  },
                  isLibraryOpened: _isLibraryOpened,
                ),
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final double cw = constraints.maxWidth;
                            final double ch = constraints.maxHeight;
                            return DragTarget<ComponentItem>(
                              onAcceptWithDetails: (details) {
                                final RenderBox renderBox = context.findRenderObject() as RenderBox;
                                final Offset localOffset = renderBox.globalToLocal(details.offset);
                                
                                final double maxRoom = math.max(roomL, roomW);
                                final double baseScale = (math.min(cw, ch) * 0.70) / (maxRoom <= 0 ? 1 : maxRoom);
                                final double scale = baseScale * _canvasZoom;
                                final Offset ctr = Offset(cw / 2, ch / 2) + _canvasOffset;
                                
                                final Offset ptFeet = (localOffset - ctr) / scale;
                                final double snapX = (ptFeet.dx / _gridSpacing).round() * _gridSpacing;
                                final double snapY = (ptFeet.dy / _gridSpacing).round() * _gridSpacing;
                                _addLibraryComponent(details.data, Offset(snapX, snapY));
                              },
                              builder: (context, candidateData, rejectedData) {
                                return Pcm2dCanvas(
                                  roomL: roomL,
                                  roomW: roomW,
                                  objects: _objects,
                                  selectedId: _selectedId,
                                  activeTool: _activeTool,
                                  gridSpacing: _gridSpacing,
                                  angleSnapDeg: _angleSnapDeg,
                                  panZoomMode: _panZoomMode,
                                  canvasZoom: _canvasZoom,
                                  canvasOffset: _canvasOffset,
                                  sketchPoints: _sketchPoints,
                                  calculatedArea: _calculatedArea,
                                  qtyCross: _qtyCross,
                                  qtyMain: _qtyMain,
                                  qtyPeri: _qtyPeri,
                                  dlCount: _dlCount,
                                  profileRft: _profileRft,
                                  onAngleSnapChanged: (v) => setState(() => _angleSnapDeg = v),
                                  onScaleStart: (details, cw, ch, scale, ctr) {
                                    if (_panZoomMode) {
                                      _lastFocalPoint = details.localFocalPoint;
                                    } else {
                                      _onCanvasDown(details.localFocalPoint, cw, ch, scale, ctr, roomL, roomW, sel);
                                    }
                                  },
                                  onScaleUpdate: (details, cw, ch, scale, ctr) {
                                    if (_panZoomMode) {
                                      setState(() {
                                        _canvasZoom = (_canvasZoom * details.scale).clamp(0.4, 4.0);
                                        if (_lastFocalPoint != null) {
                                          _canvasOffset += details.localFocalPoint - _lastFocalPoint!;
                                        }
                                        _lastFocalPoint = details.localFocalPoint;
                                      });
                                    } else {
                                      _onCanvasMove(details.localFocalPoint, cw, ch, scale, ctr, roomL, roomW);
                                    }
                                  },
                                  onScaleEnd: (details) {
                                    if (_panZoomMode) {
                                      _lastFocalPoint = null;
                                    } else {
                                      _onCanvasUp(roomL, roomW);
                                    }
                                  },
                                  onGridSpacingChanged: (v) => setState(() => _gridSpacing = v),
                                  onPanZoomModeChanged: (v) => setState(() {
                                    _panZoomMode = v;
                                    _selectedId = null;
                                  }),
                                  onCopySelected: _copySelected,
                                  onDeleteSelected: _deleteSelected,
                                  onCheckDimensionTap: (localTap, cw, ch, scale, ctr) {
                                    _checkDimensionTap(localTap, cw, ch, scale, ctr, roomL, roomW, sel);
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: AssetDrawer(
                          isOpened: _isLibraryOpened,
                          onToggle: () {
                            setState(() {
                              _isLibraryOpened = !_isLibraryOpened;
                            });
                          },
                          onTapAsset: (item) {
                            _addLibraryComponent(item, Offset.zero);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(width: 2, color: Colors.white10),
          // Right Half Workspace
          Expanded(
            flex: 5,
            child: _buildRightViewport(roomL, roomW),
          ),
        ],
      ),
    );
  }

  Widget _buildRightViewport(double roomL, double roomW) {
    switch (_rightViewportView) {
      case 0:
        return _build3dOrbitPreview();
      case 1:
        return _buildCrossSectionView(roomL, roomW);
      case 2:
        return _buildPhotoWarpView();
      case 3:
        return _buildArScanView();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildCrossSectionView(double roomL, double roomW) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          color: const Color(0xFF131722),
          child: const Row(
            children: [
              Icon(Icons.layers, color: Color(0xFFD4AF37), size: 16),
              SizedBox(width: 6),
              Text(
                'PCM STANDARDIZED CROSS-SECTION PROFILE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: CustomPaint(
            painter: CrossSectionPainter(roomL: roomL, roomW: roomW),
            size: Size.infinite,
          ),
        ),
      ],
    );
  }

  Widget _build3dOrbitPreview() {
    return Pcm3dViewer(
      objects: _objects,
      rotationX: _rotationX,
      rotationY: _rotationY,
      zoomScale: _zoomScale,
      roomL: double.tryParse(_roomLengthController.text) ?? 12.0,
      roomW: double.tryParse(_roomWidthController.text) ?? 10.0,
      fanAngle: _fanAnimController.value * 2 * math.pi,
      downlightsOn: _downlightsOn,
      coveLightOn: _coveLightOn,
      showFramework: _showFramework,
      fanAnimController: _fanAnimController,
      onRotationXChanged: (v) => setState(() => _rotationX = v),
      onRotationYChanged: (v) => setState(() => _rotationY = v),
      onZoomScaleChanged: (v) => setState(() => _zoomScale = v),
      onDownlightsToggled: () => setState(() => _downlightsOn = !_downlightsOn),
      onCoveLightToggled: () => setState(() => _coveLightOn = !_coveLightOn),
      onFrameworkToggled: () => setState(() => _showFramework = !_showFramework),
      onSetCameraPreset: (rx, ry) => setState(() { _rotationX = rx; _rotationY = ry; }),
    );
  }

  Widget _buildPhotoWarpView() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          color: const Color(0xFF131722),
          child: const Row(
            children: [
              Icon(Icons.photo_filter, color: Colors.blueAccent, size: 16),
              SizedBox(width: 6),
              Text('PERSPECTIVE PHOTO ALIGNMENT WARP', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            ],
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double cw = constraints.maxWidth;
              final double ch = constraints.maxHeight;

              void onMoveHandle(int idx, Offset delta) {
                setState(() {
                  final double nx = (_perspHandles[idx].dx + delta.dx / cw).clamp(0.0, 1.0);
                  final double ny = (_perspHandles[idx].dy + delta.dy / ch).clamp(0.0, 1.0);
                  final List<Offset> nw = List.from(_perspHandles);
                  nw[idx] = Offset(nx, ny);
                  _perspHandles = nw;
                });
              }

              return Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: PhotoOverlayPainter(
                        imagePath: _uploadedImagePath,
                        presetIndex: _selectedPreset,
                        handles: _perspHandles,
                        objects: _objects,
                        roomL: double.tryParse(_roomLengthController.text) ?? 12.0,
                        roomW: double.tryParse(_roomWidthController.text) ?? 10.0,
                      ),
                    ),
                  ),
                  for (int i = 0; i < 4; i++) ...[
                    Positioned(
                      left: _perspHandles[i].dx * cw - 12,
                      top: _perspHandles[i].dy * ch - 12,
                      child: GestureDetector(
                        onPanUpdate: (d) => onMoveHandle(i, d.delta),
                        child: const CircleAvatar(
                          radius: 12,
                          backgroundColor: Color(0xFFD4AF37),
                          child: CircleAvatar(radius: 4, backgroundColor: Colors.black),
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildArScanView() {
    final double roomL = double.tryParse(_roomLengthController.text) ?? 12.0;
    final double roomW = double.tryParse(_roomWidthController.text) ?? 10.0;
    
    Widget cameraFeed;
    if (_cameraInitialized && _cameraController != null && _cameraController!.value.isInitialized) {
      cameraFeed = ClipRect(
        child: OverflowBox(
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _cameraController!.value.previewSize!.height,
              height: _cameraController!.value.previewSize!.width,
              child: CameraPreview(_cameraController!),
            ),
          ),
        ),
      );
    } else {
      cameraFeed = const SimulatedArCameraFeed();
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          color: const Color(0xFF131722),
          child: Row(
            children: [
              const Icon(Icons.camera_alt, color: Colors.purpleAccent, size: 16),
              const SizedBox(width: 6),
              Text(
                _cameraInitialized ? 'ARCORE LIVE ENVIRONMENT' : 'ARCORE SIMULATED SCENE SCANNERS', 
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)
              ),
              const Spacer(),
              if (_cameraPermissionDenied)
                const Text('FEED FALLBACK ACTIVE', style: TextStyle(color: Colors.amber, fontSize: 8, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    if (_arPlaneDetected && !_arLayoutAnchored) {
                      setState(() {
                        _arLayoutAnchored = true;
                        _arCoachingText = "Ceiling plane locked. Fine-tune layout.";
                      });
                    }
                  },
                  onScaleUpdate: (d) {
                    if (_arLayoutAnchored) {
                      setState(() {
                        _arScale = (_arScale * d.scale).clamp(0.5, 2.0);
                        if (d.pointerCount == 1) {
                          final double yawCos = math.cos(_arRotationYaw);
                          final double yawSin = math.sin(_arRotationYaw);
                          final double dx = d.focalPointDelta.dx * 0.05;
                          final double dy = d.focalPointDelta.dy * 0.05;
                          _arOffsetX += dx * yawCos + dy * yawSin;
                          _arOffsetY += -dx * yawSin + dy * yawCos;
                        } else if (d.pointerCount == 2) {
                          _arRotationYaw += d.rotation * 0.05;
                        }
                      });
                    }
                  },
                  child: cameraFeed,
                ),
              ),
              if (_arLayoutAnchored)
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _fanAnimController,
                      builder: (context, _) {
                        return CustomPaint(
                          painter: ArLayoutPainter(
                            objects: _objects,
                            roomL: roomL,
                            roomW: roomW,
                            arCeilingHeight: _arCeilingHeight,
                            arRotationYaw: _arRotationYaw,
                            arOffsetX: _arOffsetX,
                            arOffsetY: _arOffsetY,
                            arScale: _arScale,
                            ambientBrightness: _ambientBrightness,
                            ambientColor: _ambientColorTemp,
                            fanAngle: _fanAnimController.value * 2 * math.pi,
                            downlightsOn: _downlightsOn,
                            coveLightOn: _coveLightOn,
                            depthApiEnabled: _depthApiEnabled,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              if (!_arLayoutAnchored)
                Center(
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _arPlaneDetected ? const Color(0xFF00FF87) : const Color(0xFFFFD54F),
                          ),
                        ),
                        CustomPaint(
                          size: const Size(40, 40),
                          painter: CrosshairPainter(isLocked: _arPlaneDetected),
                        ),
                      ],
                    ),
                  ),
                ),
              if (!_arLayoutAnchored)
                Positioned.fill(
                  child: IgnorePointer(
                    child: SimulatedArHudOverlay(
                      scanProgress: _arPlaneDetected ? 1.0 : 0.5,
                      coachingText: _arCoachingText,
                      isLocked: _arLayoutAnchored,
                      depthApiEnabled: _depthApiEnabled,
                    ),
                  ),
                ),
              Positioned(
                top: 10,
                left: 12,
                right: 12,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _arLayoutAnchored 
                            ? const Color(0xFF00FF87) 
                            : (_arPlaneDetected ? const Color(0xFF00E5FF) : const Color(0xFFFFD54F)),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _arLayoutAnchored 
                              ? Icons.lock 
                              : (_arPlaneDetected ? Icons.check_circle_outline : Icons.center_focus_weak),
                          color: _arLayoutAnchored 
                              ? const Color(0xFF00FF87) 
                              : (_arPlaneDetected ? const Color(0xFF00E5FF) : const Color(0xFFFFD54F)),
                          size: 12,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _arCoachingText,
                          style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_arLayoutAnchored)
                _buildArControlsCard(),
            ],
          ),
        ),
      ],
    );
  }
}
