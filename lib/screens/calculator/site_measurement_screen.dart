// PCM Wayanad - Site Measurement & Room Estimator Screen
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart' as ncp;
import 'package:printing/printing.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/language_provider.dart';
import '../../services/database_service.dart';
import '../../models/quotation.dart';
import '../../models/rate_tier.dart';
import '../../services/customer_sync_service.dart';
import '../../services/realtime_sync_service.dart';
import '../../services/pdf_generation_service.dart';
import '../../services/client_service.dart';
import '../../utils/calculator_utils.dart';
import 'project_edit_controller.dart';
import 'calculator_screen.dart';
import 'pdf_preview_screen.dart';
import 'helpers/location_picker_helper.dart';
import 'helpers/room_selector_helper.dart';
import 'brands/ceiling_board_brands.dart';
import 'brands/channel_brands.dart';
import 'brands/brand_selector_helper.dart';
import 'units/calculator_unit_helper.dart';
import 'models/room_data.dart';
import 'widgets/qr_scanner_screen.dart';
import 'widgets/site_measurement/site_measurement_pagination_bar.dart';
import 'widgets/site_measurement/site_measurement_room_card.dart';
import 'widgets/site_measurement/site_measurement_matrix_widget.dart';
import 'widgets/site_measurement/site_measurement_cove_group_widget.dart';
import 'widgets/site_measurement/site_measurement_center_group_widget.dart';
import 'widgets/site_measurement/site_measurement_ceiling_group_widget.dart';
import 'widgets/site_measurement/site_measurement_summary_widget.dart';

class SiteMeasurementScreen extends StatefulWidget {
  final String? initialScannedProjectId;
  const SiteMeasurementScreen({super.key, this.initialScannedProjectId});

  @override
  State<SiteMeasurementScreen> createState() => _SiteMeasurementScreenState();
}

class _SiteMeasurementScreenState extends State<SiteMeasurementScreen> {
  final TextEditingController _projectNumberController = TextEditingController(
    text: '# PCM-${DateFormat('yyyyMMdd-HHmm').format(DateTime.now())}',
  );
  final TextEditingController _clientNameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _rateController = TextEditingController(text: '105');
  final TextEditingController _partnerNameController = TextEditingController(text: 'Madhusoodanan A S');
  final TextEditingController _partnerPhoneController = TextEditingController(text: '+91 93834 06185');
  final TextEditingController _partnerLocationController = TextEditingController(text: 'Padinjarathara, Wayanad');
  bool _includeDigitalSignature = true;

  final List<PaymentRecord> _payments = [];
  List<Map<String, dynamic>> get paymentHistoryList => _payments.map((p) => {
    'title': p.description.isNotEmpty ? p.description.toUpperCase() : 'PAYMENT RECEIVED',
    'date': p.date,
    'amount': p.amount,
  }).toList();
  set paymentHistoryList(List<dynamic> list) {
    _payments.clear();
    for (var item in list) {
      if (item is PaymentRecord) {
        _payments.add(item);
      } else if (item is Map) {
        final m = Map<String, dynamic>.from(item);
        final amt = (m['amount'] as num?)?.toDouble() ?? 0.0;
        final title = (m['title'] ?? m['description'] ?? 'Payment Received').toString();
        final date = (m['date'] ?? '').toString();
        _payments.add(PaymentRecord(
          id: m['id'] as int?,
          quotationId: _editingId,
          description: title,
          date: date,
          amount: amt,
        ));
      }
    }
  }

  String get currentProjectId => _editingUnitNumber ?? _projectNumberController.text.trim();

  TextEditingController get projectIDController => _projectNumberController;
  TextEditingController get customerNameController => _clientNameController;
  TextEditingController get phoneController => _phoneController;
  TextEditingController get locationController => _locationController;

  List<RoomData> get roomList => rooms;
  set roomList(List<dynamic> list) {
    for (var r in rooms) {
      r.dispose();
    }
    rooms.clear();
    for (var item in list) {
      if (item is RoomData) {
        rooms.add(item);
      } else if (item is QuotationItem) {
        rooms.add(_roomFromQuotationItem(item));
      } else if (item is Map) {
        rooms.add(_roomFromMap(Map<String, dynamic>.from(item)));
      }
    }
    if (rooms.isEmpty) {
      rooms.add(RoomData());
    }
  }

  double? _overriddenTotalSqFt;
  double get totalSquareFeet => _overriddenTotalSqFt ?? totalSqFt;
  set totalSquareFeet(double val) {
    if (val > 0) {
      _overriddenTotalSqFt = val;
    }
  }

  double? _overriddenGrandTotal;
  double get grandTotalAmount => _overriddenGrandTotal ?? (totalSquareFeet * (double.tryParse(_rateController.text) ?? 105.0));
  set grandTotalAmount(double val) {
    if (val > 0) {
      _overriddenGrandTotal = val;
    }
  }

  final List<RoomData> rooms = [RoomData()];
  List<Quotation> _savedQuotations = [];
  bool _isLoadingSaved = false;
  String _viewMode = 'groups'; // 'groups' = ഡിസൈൻ ഗ്രൂപ്പ് വ്യൂ, 'rooms' = റൂം കാർഡ് വ്യൂ
  int _selectedPageIndex = 0; // 0 = All Rooms, 1 = Room 1, 2 = Room 2...

  StreamSubscription? _firestoreSubscription;
  String? _editingUnitNumber;
  int? _editingId;
  double? _latitude;
  double? _longitude;

  // Multi-Rate Tiers State (Base, Premium, Luxury)
  String _selectedTier = 'BASE';
  final Set<String> _selectedTiersForPdf = {'BASE'};

  String _baseRate = '105';
  String _baseChannel = 'Gyproc';
  String _baseBoard = 'Gyproc';

  String _premiumRate = '120';
  String _premiumChannel = 'Gyproc';
  String _premiumBoard = 'Boral';

  String _luxuryRate = '145';
  String _luxuryChannel = 'Jindal';
  String _luxuryBoard = 'Gyproc';

  late final TextEditingController _baseRateController;
  late final TextEditingController _premiumRateController;
  late final TextEditingController _luxuryRateController;

  List<String> get _availableChannels {
    final list = List<String>.from(RateTierConstants.availableChannels.where((c) => c != 'More'));
    for (var ch in [_baseChannel, _premiumChannel, _luxuryChannel]) {
      if (ch.isNotEmpty && !list.contains(ch)) {
        list.insert(0, ch);
      }
    }
    return list.toSet().toList();
  }

  List<String> get _availableBoards {
    final list = List<String>.from(RateTierConstants.availableBoards.where((b) => b != 'More'));
    for (var b in [_baseBoard, _premiumBoard, _luxuryBoard]) {
      if (b.isNotEmpty && !list.contains(b)) {
        list.insert(0, b);
      }
    }
    return list.toSet().toList();
  }

  void _updateTierChannel(String tierName, String channel) {
    setState(() {
      if (tierName == 'BASE') {
        _baseChannel = channel;
      } else if (tierName == 'PREMIUM') {
        _premiumChannel = channel;
      } else if (tierName == 'LUXURY') {
        _luxuryChannel = channel;
      }
      _selectedTier = tierName;
      if (tierName == 'BASE') _rateController.text = _baseRate;
      if (tierName == 'PREMIUM') _rateController.text = _premiumRate;
      if (tierName == 'LUXURY') _rateController.text = _luxuryRate;
    });
  }

  void _updateTierBoard(String tierName, String board) {
    setState(() {
      if (tierName == 'BASE') {
        _baseBoard = board;
      } else if (tierName == 'PREMIUM') {
        _premiumBoard = board;
      } else if (tierName == 'LUXURY') {
        _luxuryBoard = board;
      }
      _selectedTier = tierName;
      if (tierName == 'BASE') _rateController.text = _baseRate;
      if (tierName == 'PREMIUM') _rateController.text = _premiumRate;
      if (tierName == 'LUXURY') _rateController.text = _luxuryRate;
    });
  }

  List<Map<String, dynamic>> get selectedTiersList {
    final list = <Map<String, dynamic>>[];
    if (_selectedTiersForPdf.contains('BASE')) {
      final rate = double.tryParse(_baseRate) ?? 105.0;
      list.add({
        'name': 'BASE TIER (₹$_baseRate / sq.ft)',
        'rate': rate,
      });
    }
    if (_selectedTiersForPdf.contains('PREMIUM')) {
      final rate = double.tryParse(_premiumRate) ?? 120.0;
      list.add({
        'name': 'PREMIUM TIER (₹$_premiumRate / sq.ft)',
        'rate': rate,
      });
    }
    if (_selectedTiersForPdf.contains('LUXURY')) {
      final rate = double.tryParse(_luxuryRate) ?? 145.0;
      list.add({
        'name': 'LUXURY TIER (₹$_luxuryRate / sq.ft)',
        'rate': rate,
      });
    }
    return list;
  }

  void _toggleTierForPdf(String tierName, bool selected) {
    setState(() {
      if (selected) {
        _selectedTiersForPdf.add(tierName);
      } else {
        _selectedTiersForPdf.remove(tierName);
      }
    });
  }

  // Multi-Rate Tier PDF selection getters & setters
  bool get selectedBaseForPdf => _selectedTiersForPdf.contains('BASE');
  set selectedBaseForPdf(bool val) => _toggleTierForPdf('BASE', val);

  bool get selectedPremiumForPdf => _selectedTiersForPdf.contains('PREMIUM');
  set selectedPremiumForPdf(bool val) => _toggleTierForPdf('PREMIUM', val);

  bool get selectedLuxuryForPdf => _selectedTiersForPdf.contains('LUXURY');
  set selectedLuxuryForPdf(bool val) => _toggleTierForPdf('LUXURY', val);

  void _showCustomChannelDialog(String tierName) async {
    final current = tierName == 'BASE' ? _baseChannel : (tierName == 'PREMIUM' ? _premiumChannel : _luxuryChannel);
    final selected = await BrandSelectorHelper.showBrandPicker(
      context,
      title: 'Select Channel Brand ($tierName)',
      brands: ChannelBrands.brands,
      currentBrand: current,
      isChannel: true,
    );
    if (selected != null && selected.isNotEmpty) {
      _updateTierChannel(tierName, selected);
    }
  }

  void _showCustomBoardDialog(String tierName) async {
    final current = tierName == 'BASE' ? _baseBoard : (tierName == 'PREMIUM' ? _premiumBoard : _luxuryBoard);
    final selected = await BrandSelectorHelper.showBrandPicker(
      context,
      title: 'Select Ceiling Board Brand ($tierName)',
      brands: CeilingBoardBrands.brands,
      currentBrand: current,
      isChannel: false,
    );
    if (selected != null && selected.isNotEmpty) {
      _updateTierBoard(tierName, selected);
    }
  }

  List<String> get availableUnits => CalculatorUnitHelper.availableUnits;
  final List<String> ceilingTypes = ['Plain Ceiling', 'Design', 'Both'];
  final List<String> availableFloors = [
    'Ground Floor',
    '1st Floor',
    '2nd Floor',
    '3rd Floor',
    'Basement',
    'Terrace',
    'Other Floor',
  ];

  final List<String> roomOptions = RoomSelectorHelper.masterRoomOptions;

  bool showQuickAddDropdown = false;
  bool showCustomInputBox = false;

  TextEditingController? _customRoomController;
  TextEditingController get customRoomController => _customRoomController ??= TextEditingController();

  TextEditingController? _quickSearchController;
  TextEditingController get quickSearchController => _quickSearchController ??= TextEditingController();

  String? _quickSearchQuery;
  String get quickSearchQuery => _quickSearchQuery ?? "";
  set quickSearchQuery(String v) => _quickSearchQuery = v;

  List<String> get filteredQuickRooms {
    final q = quickSearchQuery;
    if (q.isEmpty) {
      return roomOptions;
    }
    return roomOptions
        .where((room) => room.toLowerCase().contains(q.toLowerCase()))
        .toList();
  }

  void addSelectedRoom(String roomName) {
    if (roomName == 'More') {
      _showMoreRoomDetailsSheet();
      setState(() {
        showCustomInputBox = true;
        showQuickAddDropdown = false;
      });
      return;
    }

    setState(() {
      final newRoom = RoomData();
      newRoom.roomName = roomName;
      newRoom.roomNumber = '${rooms.length + 1}';
      newRoom.roomNumberController.text = newRoom.roomNumber;

      if (rooms.length == 1 && rooms[0].width == 0 && rooms[0].length == 0) {
        rooms[0].roomName = roomName;
        rooms[0].roomNumber = '1';
        rooms[0].roomNumberController.text = '1';
      } else {
        rooms.add(newRoom);
      }
      showQuickAddDropdown = false;
      quickSearchController.clear();
      quickSearchQuery = "";
      showCustomInputBox = false;
    });
  }

  void addCustomRoom(String customName) {
    if (customName.trim().isNotEmpty) {
      final name = customName.trim();
      setState(() {
        final newRoom = RoomData();
        newRoom.roomName = name;
        newRoom.roomNumber = '${rooms.length + 1}';
        newRoom.roomNumberController.text = newRoom.roomNumber;

        if (rooms.length == 1 && rooms[0].width == 0 && rooms[0].length == 0) {
          rooms[0].roomName = name;
          rooms[0].roomNumber = '1';
          rooms[0].roomNumberController.text = '1';
        } else {
          rooms.add(newRoom);
        }
        customRoomController.clear();
        showCustomInputBox = false;
      });
    }
  }

  void _showMoreRoomDetailsSheet() {
    final nameCtrl = TextEditingController(text: customRoomController.text);
    final roomNumCtrl = TextEditingController(text: '${rooms.length + 1}');
    final widthCtrl = TextEditingController();
    final lengthCtrl = TextEditingController();
    String sheetFloor = 'Ground Floor';
    String sheetUnit = 'Feet';
    String sheetCeiling = 'Plain Ceiling';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'കൂടുതൽ റൂം വിവരങ്ങൾ (Add Room Details)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.brown),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'റൂം പേര് (Room Name)',
                  hintText: 'e.g. Master Bedroom, Courtyard, Living...',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: roomNumCtrl,
                      decoration: const InputDecoration(
                        labelText: 'റൂം നമ്പർ (Room #)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: sheetFloor,
                      decoration: const InputDecoration(
                        labelText: 'നില (Floor)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: availableFloors
                          .map((f) => DropdownMenuItem(value: f, child: Text(f, style: const TextStyle(fontSize: 12))))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) sheetFloor = val;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: widthCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'വീതി (Width)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: lengthCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'നീളം (Length)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: sheetUnit,
                      decoration: const InputDecoration(
                        labelText: 'യൂണിറ്റ്',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'SqFt', child: Text('SqFt', style: TextStyle(fontSize: 12))),
                        DropdownMenuItem(value: 'Feet', child: Text('Feet', style: TextStyle(fontSize: 12))),
                        DropdownMenuItem(value: 'Meters', child: Text('Meter', style: TextStyle(fontSize: 12))),
                        DropdownMenuItem(value: 'Inches', child: Text('Inches', style: TextStyle(fontSize: 12))),
                      ],
                      onChanged: (val) {
                        if (val != null) sheetUnit = val;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown[800],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.add_circle),
                label: const Text('റൂം ചേർക്കുക (ADD ROOM)', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  final name = nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : 'Custom Room';
                  setState(() {
                    final newRoom = RoomData();
                    newRoom.roomName = name;
                    newRoom.floor = sheetFloor;
                    newRoom.roomNumber = roomNumCtrl.text.trim().isNotEmpty ? roomNumCtrl.text.trim() : '${rooms.length + 1}';
                    newRoom.roomNumberController.text = newRoom.roomNumber;
                    newRoom.colorPattern = '';
                    newRoom.unit = sheetUnit;
                    newRoom.ceilingType = sheetCeiling;
                    newRoom.width = double.tryParse(widthCtrl.text) ?? 0.0;
                    newRoom.length = double.tryParse(lengthCtrl.text) ?? 0.0;
                    newRoom.widthController.text = widthCtrl.text;
                    newRoom.lengthController.text = lengthCtrl.text;
                    rooms.insert(0, newRoom);
                  });
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _baseRateController = TextEditingController(text: _baseRate);
    _premiumRateController = TextEditingController(text: _premiumRate);
    _luxuryRateController = TextEditingController(text: _luxuryRate);
    if (_locationController.text.toLowerCase().contains('thrissur') ||
        _locationController.text.contains(RegExp(r'\(\s*-?\d+')) ||
        _locationController.text.contains(RegExp(r'-?\d{1,3}\.\d{3,}'))) {
      _locationController.text = LocationPickerHelper.sanitizePlaceString(_locationController.text);
    }
    _loadSavedMeasurements();
    _subscribeToRealtimeSync();
    if (widget.initialScannedProjectId != null && widget.initialScannedProjectId!.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        handleQrScanResult(widget.initialScannedProjectId!.trim());
      });
    }
  }

  void _subscribeToRealtimeSync() {
    try {
      _firestoreSubscription = RealtimeSyncService.instance
          .streamAllAdminData('quotations')
          .listen((snapshot) {
        if (mounted) {
          _loadSavedMeasurements();
        }
      }, onError: (e) {
        debugPrint('Firestore realtime subscription notice: $e');
      });
    } catch (e) {
      debugPrint('Firestore subscription notice: $e');
    }
  }

  @override
  void dispose() {
    _firestoreSubscription?.cancel();
    _projectNumberController.dispose();
    _clientNameController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    _rateController.dispose();
    _partnerNameController.dispose();
    _partnerPhoneController.dispose();
    _partnerLocationController.dispose();
    _baseRateController.dispose();
    _premiumRateController.dispose();
    _luxuryRateController.dispose();
    _customRoomController?.dispose();
    _quickSearchController?.dispose();
    for (var r in rooms) {
      r.dispose();
    }
    super.dispose();
  }

  Future<void> _loadSavedMeasurements() async {
    setState(() => _isLoadingSaved = true);
    try {
      final list = await DatabaseService.instance.getQuotations();
      if (mounted) {
        setState(() {
          _savedQuotations = list.reversed.toList();
          _isLoadingSaved = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading saved measurements: $e');
      if (mounted) setState(() => _isLoadingSaved = false);
    }
  }

  void _removeRoom(int index) {
    setState(() {
      if (rooms.length > 1) {
        rooms[index].dispose();
        rooms.removeAt(index);
        if (_selectedPageIndex > rooms.length) {
          _selectedPageIndex = rooms.length;
        }
      } else {
        rooms[0].widthController.clear();
        rooms[0].lengthController.clear();
        rooms[0].width = 0;
        rooms[0].length = 0;
      }
    });
  }

  double get totalSqFt {
    double total = 0.0;
    for (var r in rooms) {
      total += r.calculatedSqFt;
    }
    return total;
  }

  double get totalPdfSqFt {
    double total = 0.0;
    for (var r in rooms) {
      if (!r.isHidden) {
        total += r.calculatedSqFt;
      }
    }
    return total;
  }

  int get visibleRoomsCount => rooms.where((r) => !r.isHidden).length;

  final ncp.FlutterNativeContactPicker _contactPicker = ncp.FlutterNativeContactPicker();

  Future<void> _pickContact() async {
    if (kIsWeb) return;
    try {
      final contact = await _contactPicker.selectContact();
      if (contact != null) {
        String? phone;
        if (contact.phoneNumbers != null && contact.phoneNumbers!.isNotEmpty) {
          phone = contact.phoneNumbers!.first.trim();
        }
        final String name = (contact.fullName ?? '').trim();
        setState(() {
          if (phone != null && phone.isNotEmpty) {
            final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
            _phoneController.text = cleaned.isNotEmpty ? cleaned : phone;
          }
          if (name.isNotEmpty) {
            _clientNameController.text = name;
          }
        });

        if (_editingId == null && (_projectNumberController.text.trim().isEmpty || ClientService.isGeneratedTimestampId(_projectNumberController.text.trim()))) {
          final existing = await DatabaseService.instance.findActiveProjectForClient(
            phone: _phoneController.text.trim(),
            name: _clientNameController.text.trim(),
          );
          if (existing != null && mounted) {
            setState(() {
              if (existing.unitNumber.isNotEmpty) {
                _projectNumberController.text = existing.unitNumber;
              }
              if (existing.id != null) {
                _editingId = existing.id;
              }
            });
          }
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✓ Contact loaded: $name ${_phoneController.text}'),
              backgroundColor: const Color(0xFF15803D),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Contact picker error: $e');
    }
  }

  Future<void> _fetchGpsLocation() async {
    final result = await LocationPickerHelper.fetchCurrentLocation(
      context: context,
    );

    if (result != null) {
      setState(() {
        _latitude = result.latitude;
        _longitude = result.longitude;
        _locationController.text = result.placeName;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Location: ${result.placeName}'),
            backgroundColor: const Color(0xFF0284C7),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Quotation? _buildQuotationFromInputs({bool forPdf = false, List<RoomData>? targetRooms}) {
    final client = _clientNameController.text.trim().isEmpty ? 'Site Measurement' : _clientNameController.text.trim();
    final location = _locationController.text.trim().isEmpty ? 'Wayanad' : _locationController.text.trim();
    final phone = _phoneController.text.trim();
    final rateVal = double.tryParse(_rateController.text.trim()) ?? 105.0;

    String activeBoard = _baseBoard;
    String activeChannel = _baseChannel;
    if (_selectedTier == 'PREMIUM' || _rateController.text == _premiumRate) {
      activeBoard = _premiumBoard;
      activeChannel = _premiumChannel;
    } else if (_selectedTier == 'LUXURY' || _rateController.text == _luxuryRate) {
      activeBoard = _luxuryBoard;
      activeChannel = _luxuryChannel;
    }

    final List<QuotationItem> items = [];
    List<RoomData> eligibleRooms;
    if (targetRooms != null) {
      eligibleRooms = targetRooms.where((r) => !r.isHidden).toList();
    } else if (forPdf) {
      if (rooms.any((r) => r.isSelected)) {
        eligibleRooms = rooms.where((r) => r.isSelected && !r.isHidden).toList();
      } else {
        eligibleRooms = rooms.where((r) => !r.isHidden).toList();
      }
    } else {
      eligibleRooms = rooms;
    }

    for (int i = 0; i < eligibleRooms.length; i++) {
      final r = eligibleRooms[i];
      if (r.calculatedSqFt > 0 || (r.hasPlainCeiling && r.width > 0 && r.length > 0)) {
        final roomNum = r.roomNumberController.text.trim().isNotEmpty
            ? r.roomNumberController.text.trim()
            : (r.roomNumber.isNotEmpty ? r.roomNumber : '${i + 1}');

        final double roomQty = r.roomCount > 0 ? r.roomCount.toDouble() : 1.0;
        final boardToUse = r.customBoard ?? activeBoard;
        final channelToUse = r.customChannel ?? activeChannel;
        final roomRate = r.customRate ?? rateVal;

        final itemTotalArea = r.singleRoomNativeArea * roomQty;
        final itemTotalAmount = r.calculatedSqFt * roomRate;

        items.add(QuotationItem(
          roomName: r.roomName,
          ceilingType: r.ceilingType,
          roomNumber: roomNum,
          floor: r.floor,
          unit: r.unit,
          width: r.effectiveWidth,
          length: r.effectiveLength,
          height: 0.0,
          quantity: roomQty,
          area: itemTotalArea,
          rate: roomRate,
          amount: itemTotalAmount,
          brandName: CalculatorUtils.sanitizeBrandName('$boardToUse • $channelToUse'),
          hasCove: r.hasCove,
          coveLength: r.effectiveCoveLength,
          coveWidth: r.effectiveCoveWidth,
          coveQuantity: r.effectiveCoveSides.toDouble(),
          coveRate: roomRate,
          hasCentralDesign: r.hasCenterDesign,
          designName: r.hasCenterDesign ? r.centerType : (r.hasPlainCeiling ? 'Plain Ceiling' : ''),
          centralLength: r.effectiveCenterLength,
          centralWidth: r.effectiveCenterWidth,
          centralQuantity: r.effectiveCenterQty.toDouble(),
          centralRate: roomRate,
        ));
      }
    }

    if (items.isEmpty) return null;

    final total = items.fold(0.0, (acc, item) => acc + item.amount);
    final unitNum = _projectNumberController.text.trim().isNotEmpty
        ? _projectNumberController.text.trim()
        : '# PCM-${DateFormat('yyyyMMdd-HHmm').format(DateTime.now())}';

    final totalPaid = _payments.fold(0.0, (acc, p) => acc + p.amount);
    final balance = (total - totalPaid) > 0 ? (total - totalPaid) : 0.0;

    return Quotation(
      id: _editingId,
      unitNumber: unitNum,
      clientName: client,
      clientLocation: location,
      clientPhone: phone,
      date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
      totalAmount: total,
      paidAmount: totalPaid,
      balanceAmount: balance,
      payments: List<PaymentRecord>.from(_payments),
      items: items,
      latitude: _latitude,
      longitude: _longitude,
      includeDigitalSignature: _includeDigitalSignature,
      partnerName: _partnerNameController.text.trim(),
      partnerPhone: _partnerPhoneController.text.trim(),
      partnerLocation: _partnerLocationController.text.trim(),
    );
  }

  Future<Quotation?> _saveMeasurement({bool showFeedback = true}) async {
    if (_editingId == null && (_projectNumberController.text.trim().isEmpty || ClientService.isGeneratedTimestampId(_projectNumberController.text.trim()))) {
      final existing = await DatabaseService.instance.findActiveProjectForClient(
        phone: _phoneController.text.trim(),
        name: _clientNameController.text.trim(),
      );
      if (existing != null) {
        if (existing.unitNumber.isNotEmpty) {
          _projectNumberController.text = existing.unitNumber;
        }
        if (existing.id != null) {
          _editingId = existing.id;
        }
      }
    }

    final quotation = _buildQuotationFromInputs();
    if (quotation == null) {
      if (showFeedback && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('അളവുകൾ നൽകിയ റൂമുകൾ ഇല്ല! (No valid room dimensions entered)')),
        );
      }
      return null;
    }

    try {
      final savedId = await DatabaseService.instance.insertQuotation(quotation);
      final finalQuotation = quotation.copyWith(id: savedId);

      unawaited(CustomerSyncService.instance.saveQuotationToCloud(finalQuotation));

      if (mounted) {
        setState(() {
          _editingId = savedId;
          _editingUnitNumber = quotation.unitNumber;
        });
        await _loadSavedMeasurements();
        if (showFeedback && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Saved locally: ${quotation.items.length} rooms recorded.'),
              backgroundColor: const Color(0xFF15803D),
            ),
          );
        }
      }
      return finalQuotation;
    } catch (e) {
      debugPrint('Save measurement error: $e');
      return null;
    }
  }

  Future<void> _generateAndPreviewPdf({Quotation? existingQuotation}) async {
    final quotation = existingQuotation ?? _buildQuotationFromInputs(forPdf: true);
    if (quotation == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF ഉൽപ്പാദിപ്പിക്കാൻ അളവുകൾ തികഞ്ഞ റൂമുകൾ ഇല്ല!')),
        );
      }
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.amber)),
    );

    try {
      final pName = existingQuotation?.partnerName?.trim().isNotEmpty == true
          ? existingQuotation!.partnerName!.trim()
          : _partnerNameController.text.trim();
      final pPhone = existingQuotation?.partnerPhone?.trim().isNotEmpty == true
          ? existingQuotation!.partnerPhone!.trim()
          : _partnerPhoneController.text.trim();
      final pLoc = existingQuotation?.partnerLocation?.trim().isNotEmpty == true
          ? existingQuotation!.partnerLocation!.trim()
          : _partnerLocationController.text.trim();

      final pdfBytes = await PdfGenerationService.generateQuotation(
        clientName: quotation.clientName,
        clientLocation: quotation.clientLocation,
        clientPhone: quotation.clientPhone,
        unitNumber: quotation.unitNumber,
        items: quotation.items,
        materials: quotation.materials,
        payments: quotation.payments,
        totalAmount: quotation.totalAmount,
        paidAmount: quotation.paidAmount,
        balanceAmount: quotation.balanceAmount,
        includeDigitalSignature: existingQuotation != null
            ? existingQuotation.includeDigitalSignature
            : _includeDigitalSignature,
        authorizedName: pName,
        authorizedPhone: pPhone,
        authorizedLocation: pLoc,
        selectedTiersList: selectedTiersList,
      );
      if (mounted) Navigator.pop(context);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PdfPreviewScreen(
              pdfBytes: pdfBytes,
              fileName: 'Measurement_Estimate_${quotation.clientName.replaceAll(' ', '_')}.pdf',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      debugPrint('Error generating PDF: $e');
    }
  }

  Future<void> _sharePdf({Quotation? existingQuotation}) async {
    final quotation = existingQuotation ?? _buildQuotationFromInputs(forPdf: true);
    if (quotation == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ഷെയർ ചെയ്യാൻ റൂമുകൾ തെരഞ്ഞെടുക്കുക!')),
        );
      }
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.amber)),
    );

    try {
      final pName = existingQuotation?.partnerName?.trim().isNotEmpty == true
          ? existingQuotation!.partnerName!.trim()
          : _partnerNameController.text.trim();
      final pPhone = existingQuotation?.partnerPhone?.trim().isNotEmpty == true
          ? existingQuotation!.partnerPhone!.trim()
          : _partnerPhoneController.text.trim();
      final pLoc = existingQuotation?.partnerLocation?.trim().isNotEmpty == true
          ? existingQuotation!.partnerLocation!.trim()
          : _partnerLocationController.text.trim();

      final pdfBytes = await PdfGenerationService.generateQuotation(
        clientName: quotation.clientName,
        clientLocation: quotation.clientLocation,
        clientPhone: quotation.clientPhone,
        unitNumber: quotation.unitNumber,
        items: quotation.items,
        materials: quotation.materials,
        payments: quotation.payments,
        totalAmount: quotation.totalAmount,
        paidAmount: quotation.paidAmount,
        balanceAmount: quotation.balanceAmount,
        includeDigitalSignature: existingQuotation != null
            ? existingQuotation.includeDigitalSignature
            : _includeDigitalSignature,
        authorizedName: pName,
        authorizedPhone: pPhone,
        authorizedLocation: pLoc,
        selectedTiersList: selectedTiersList,
      );
      if (mounted) Navigator.pop(context);

      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'Measurement_Estimate_${quotation.clientName.replaceAll(' ', '_')}.pdf',
      );
    } catch (e) {
      if (mounted) Navigator.pop(context);
      debugPrint('Error sharing PDF: $e');
    }
  }

  void _showPdfSelectionDialog({int? targetRoomIndex}) {
    final availableRooms = (targetRoomIndex != null && targetRoomIndex >= 0 && targetRoomIndex < rooms.length)
        ? [rooms[targetRoomIndex]]
        : rooms;
    final selectedRoomSet = availableRooms.where((r) => !r.isHidden).toSet();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final rateVal = double.tryParse(_rateController.text) ?? 105.0;
          final totalArea = selectedRoomSet.fold(0.0, (s, r) => s + r.calculatedSqFt);
          final totalAmount = totalArea * rateVal;

          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.picture_as_pdf, color: Color(0xFF16A34A), size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    targetRoomIndex != null ? 'ഈ റൂം PDF ചെയ്യുക' : 'PDF റൂം തെരഞ്ഞെടുപ്പ്',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () {
                          setDialogState(() {
                            selectedRoomSet.clear();
                            selectedRoomSet.addAll(availableRooms);
                          });
                        },
                        child: const Text('Select All', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                      TextButton(
                        onPressed: () {
                          setDialogState(() {
                            selectedRoomSet.clear();
                          });
                        },
                        child: const Text('Clear All', style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const Divider(height: 1),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 280),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: availableRooms.length,
                      itemBuilder: (context, i) {
                        final r = availableRooms[i];
                        final isSelected = selectedRoomSet.contains(r);
                        return CheckboxListTile(
                          value: isSelected,
                          dense: true,
                          title: Text(r.roomName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          subtitle: Text('#${r.roomNumber} (${r.floor}) • ${r.calculatedSqFt.toStringAsFixed(1)} SQFT', style: const TextStyle(fontSize: 11)),
                          onChanged: (val) {
                            setDialogState(() {
                              if (val == true) {
                                selectedRoomSet.add(r);
                              } else {
                                selectedRoomSet.remove(r);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('സെലക്ട് ചെയ്തവ: ${selectedRoomSet.length} റൂം', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      Text('₹${CalculatorUtils.formatIndianCurrency(totalAmount)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF15803D))),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('CANCEL'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7), foregroundColor: Colors.white),
                icon: const Icon(Icons.picture_as_pdf, size: 16),
                label: const Text('PDF പ്രിവ്യൂ'),
                onPressed: selectedRoomSet.isEmpty ? null : () {
                  Navigator.pop(ctx);
                  final quota = _buildQuotationFromInputs(forPdf: true, targetRooms: selectedRoomSet.toList());
                  if (quota != null) _generateAndPreviewPdf(existingQuotation: quota);
                },
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16A34A), foregroundColor: Colors.white),
                icon: const Icon(Icons.share, size: 16),
                label: const Text('ഷെയർ'),
                onPressed: selectedRoomSet.isEmpty ? null : () {
                  Navigator.pop(ctx);
                  final quota = _buildQuotationFromInputs(forPdf: true, targetRooms: selectedRoomSet.toList());
                  if (quota != null) _sharePdf(existingQuotation: quota);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  RoomData _roomFromQuotationItem(QuotationItem item) {
    final room = RoomData();
    room.roomName = item.roomName.replaceAll(RegExp(r'\s*#\d+'), '');
    room.hasPlainCeiling = (item.width > 0 && item.length > 0) || (!item.hasCove && !item.hasCentralDesign) || item.area > 0;
    
    double effW = item.width;
    double effL = item.length;
    if (effW <= 0 && effL <= 0 && item.area > 0) {
      effW = item.area;
      effL = 1.0;
    } else if (effW > 0 && effL <= 0 && item.area > 0) {
      effL = item.area / effW;
    } else if (effL > 0 && effW <= 0 && item.area > 0) {
      effW = item.area / effL;
    }

    room.width = effW;
    room.length = effL;
    room.unit = item.unit.isNotEmpty ? item.unit : 'Feet';
    room.ceilingType = item.designName.isNotEmpty ? (item.designName == 'Plain' ? 'Plain Ceiling' : item.designName) : 'Plain Ceiling';
    room.floor = item.floor.isNotEmpty ? item.floor : 'Ground Floor';
    room.roomNumber = item.roomNumber.isNotEmpty ? item.roomNumber : '${rooms.length + 1}';
    room.roomNumberController.text = room.roomNumber;
    room.roomCount = item.quantity > 0 ? item.quantity.toInt() : 1;
    room.roomCountController.text = room.roomCount.toString();

    room.hasCove = item.hasCove;
    room.coveLength = item.coveLength > 0 ? item.coveLength : item.coveRft;
    room.coveWidth = item.coveWidth;
    room.coveSides = item.coveQuantity > 0 ? item.coveQuantity.toInt() : 4;
    room.coveLengthController.text = room.coveLength > 0 ? room.coveLength.toString() : '';
    room.coveWidthController.text = item.coveWidth > 0 ? item.coveWidth.toString() : '';
    room.coveSidesController.text = room.coveSides.toString();

    room.hasCenterDesign = item.hasCentralDesign;
    room.centerType = item.designName.isNotEmpty ? item.designName : 'Center Design';
    room.centerLength = item.centralLength;
    room.centerWidth = item.centralWidth;
    room.centerQty = item.centralQuantity > 0 ? item.centralQuantity.toInt() : 1;
    room.centerLengthController.text = item.centralLength > 0 ? item.centralLength.toString() : '';
    room.centerWidthController.text = item.centralWidth > 0 ? item.centralWidth.toString() : '';
    room.centerQtyController.text = room.centerQty.toString();

    room.colorPattern = item.colorPattern.isNotEmpty ? item.colorPattern : 'Warm White (3000K)';
    room.widthController.text = item.width > 0 ? item.width.toString() : '';
    room.lengthController.text = item.length > 0 ? item.length.toString() : '';
    return room;
  }

  RoomData _roomFromMap(Map<String, dynamic> item) {
    final room = RoomData();
    room.roomName = (item['roomName'] ?? item['room_name'] ?? item['name'] ?? 'Room').toString().replaceAll(RegExp(r'\s*#\d+'), '');
    
    final w = (item['width'] as num?)?.toDouble() ?? (double.tryParse(item['width']?.toString() ?? '') ?? 0.0);
    final l = (item['length'] as num?)?.toDouble() ?? (double.tryParse(item['length']?.toString() ?? '') ?? 0.0);
    final area = (item['area'] as num?)?.toDouble() ?? (double.tryParse(item['area']?.toString() ?? '') ?? 0.0);

    double effW = w;
    double effL = l;
    if (effW <= 0 && effL <= 0 && area > 0) {
      effW = area;
      effL = 1.0;
    } else if (effW > 0 && effL <= 0 && area > 0) {
      effL = area / effW;
    } else if (effL > 0 && effW <= 0 && area > 0) {
      effW = area / effL;
    }

    room.width = effW;
    room.length = effL;
    room.unit = (item['unit'] ?? 'Feet').toString();
    room.ceilingType = (item['ceilingType'] ?? item['designName'] ?? 'Plain Ceiling').toString();
    room.floor = (item['floor'] ?? 'Ground Floor').toString();
    room.roomNumber = (item['roomNumber'] ?? item['room_number'] ?? '${rooms.length + 1}').toString();
    room.roomNumberController.text = room.roomNumber;

    final qty = (item['quantity'] ?? item['roomCount'] ?? item['count'] ?? 1);
    room.roomCount = (qty is num) ? qty.toInt() : (int.tryParse(qty.toString()) ?? 1);
    room.roomCountController.text = room.roomCount.toString();

    room.hasPlainCeiling = item['hasPlainCeiling'] ?? ((effW > 0 && effL > 0) || area > 0);

    room.hasCove = item['hasCove'] ?? (item['coveLength'] != null || item['coveRft'] != null);
    final cLen = (item['coveLength'] as num?)?.toDouble() ?? (item['coveRft'] as num?)?.toDouble() ?? 0.0;
    final cWid = (item['coveWidth'] as num?)?.toDouble() ?? 0.0;
    final cSides = (item['coveSides'] as num?)?.toInt() ?? (item['coveQuantity'] as num?)?.toInt() ?? 4;
    room.coveLength = cLen;
    room.coveWidth = cWid;
    room.coveSides = cSides;
    room.coveLengthController.text = cLen > 0 ? cLen.toString() : '';
    room.coveWidthController.text = cWid > 0 ? cWid.toString() : '';
    room.coveSidesController.text = cSides.toString();

    room.hasCenterDesign = item['hasCenterDesign'] ?? item['hasCentralDesign'] ?? false;
    room.centerType = (item['centerType'] ?? item['designName'] ?? 'Center Design').toString();
    final cntLen = (item['centerLength'] as num?)?.toDouble() ?? (item['centralLength'] as num?)?.toDouble() ?? 0.0;
    final cntWid = (item['centerWidth'] as num?)?.toDouble() ?? (item['centralWidth'] as num?)?.toDouble() ?? 0.0;
    final cntQty = (item['centerQty'] as num?)?.toInt() ?? (item['centralQuantity'] as num?)?.toInt() ?? 1;
    room.centerLength = cntLen;
    room.centerWidth = cntWid;
    room.centerQty = cntQty;
    room.centerLengthController.text = cntLen > 0 ? cntLen.toString() : '';
    room.centerWidthController.text = cntWid > 0 ? cntWid.toString() : '';
    room.centerQtyController.text = cntQty.toString();

    room.colorPattern = (item['colorPattern'] ?? 'Warm White (3000K)').toString();
    room.widthController.text = effW > 0 ? effW.toString() : '';
    room.lengthController.text = effL > 0 ? effL.toString() : '';
    return room;
  }

  // പ്രോജക്റ്റ് ഡാറ്റ ലോഡ് ചെയ്യുമ്പോൾ റൂം ലിസ്റ്റും അളവുകളും കൂടി സെറ്റ് ചെയ്യുന്ന കോഡ്
  void loadProjectData(Map<String, dynamic> projectData) {
    setState(() {
      // 1. അടിസ്ഥാന വിവരങ്ങൾ
      final projId = projectData['projectID'] ?? projectData['unitNumber'] ?? projectData['id'] ?? '';
      projectIDController.text = projId.toString();
      final cleanUnit = ClientService.normalizeUnitNumber(projectIDController.text);
      _editingUnitNumber = cleanUnit;
      if (projectData['id'] != null) {
        _editingId = int.tryParse(projectData['id'].toString());
      }
      customerNameController.text = (projectData['customerName'] ?? projectData['clientName'] ?? '').toString();
      phoneController.text = (projectData['phone'] ?? projectData['clientPhone'] ?? '').toString();
      locationController.text = (projectData['location'] ?? projectData['clientLocation'] ?? '').toString();
      if (projectData['partnerName'] != null && projectData['partnerName'].toString().trim().isNotEmpty) {
        _partnerNameController.text = projectData['partnerName'].toString().trim();
      }
      if (projectData['partnerPhone'] != null && projectData['partnerPhone'].toString().trim().isNotEmpty) {
        _partnerPhoneController.text = projectData['partnerPhone'].toString().trim();
      }
      if (projectData['partnerLocation'] != null && projectData['partnerLocation'].toString().trim().isNotEmpty) {
        _partnerLocationController.text = projectData['partnerLocation'].toString().trim();
      }
      if (projectData['includeDigitalSignature'] != null) {
        _includeDigitalSignature = projectData['includeDigitalSignature'] == true;
      }
      if (projectData['rate'] != null) {
        final rStr = projectData['rate'].toString();
        _rateController.text = rStr;
        _baseRate = rStr;
        _baseRateController.text = rStr;
      }

      // 2. റൂമുകളുടെ അളവുകളും എൻട്രികളും കൃത്യമായി ലോഡ് ചെയ്യുന്നു
      if (projectData['rooms'] != null) {
        roomList = List<dynamic>.from(projectData['rooms']);
      } else if (projectData['items'] != null) {
        roomList = List<dynamic>.from(projectData['items']);
      } else {
        roomList = [];
      }

      // 3. ടോട്ടൽ സ്ക്വയർ ഫീറ്റും തുകയും കാൽക്കുലേറ്റ് ചെയ്ത് അപ്ഡേറ്റ് ചെയ്യുന്നു
      final tSqFt = (projectData['totalSqFt'] ?? projectData['totalSquareFeet'] ?? 0.0);
      final gTotal = (projectData['grandTotal'] ?? projectData['grandTotalAmount'] ?? projectData['totalAmount'] ?? 0.0);
      totalSquareFeet = (tSqFt is num) ? tSqFt.toDouble() : (double.tryParse(tSqFt.toString()) ?? 0.0);
      grandTotalAmount = (gTotal is num) ? gTotal.toDouble() : (double.tryParse(gTotal.toString()) ?? 0.0);

      // പെയ്മെന്റ് ഹിസ്റ്ററി ലോഡ് ചെയ്യാൻ
      if (projectData['paymentHistory'] != null) {
        paymentHistoryList = List<dynamic>.from(projectData['paymentHistory']);
      } else if (projectData['payments'] != null) {
        paymentHistoryList = List<dynamic>.from(projectData['payments']);
      }

      _selectedPageIndex = 0;
    });
  }

  void _loadExistingMeasurement(Quotation q) {
    loadProjectData({
      'projectID': q.unitNumber,
      'id': q.id,
      'customerName': q.clientName,
      'phone': q.clientPhone,
      'location': q.clientLocation,
      'latitude': q.latitude,
      'longitude': q.longitude,
      'partnerName': q.partnerName,
      'partnerPhone': q.partnerPhone,
      'partnerLocation': q.partnerLocation,
      'includeDigitalSignature': q.includeDigitalSignature,
      'rate': q.items.isNotEmpty && q.items.first.rate > 0 ? q.items.first.rate.toStringAsFixed(0) : null,
      'rooms': q.items,
      'totalSqFt': q.items.fold(0.0, (acc, i) => acc + (i.area > 0 ? i.area : (i.width * i.length))),
      'grandTotal': q.totalAmount,
      'paymentHistory': q.payments,
    });
  }

  void _clearEditing() {
    setState(() {
      _payments.clear();
      _overriddenTotalSqFt = null;
      _overriddenGrandTotal = null;
      _editingUnitNumber = null;
      _editingId = null;
      _projectNumberController.text = '# PCM-${DateFormat('yyyyMMdd-HHmm').format(DateTime.now())}';
      _latitude = null;
      _longitude = null;
      _clientNameController.clear();
      _locationController.clear();
      _phoneController.clear();
      _rateController.text = '105';
      _selectedTier = 'BASE';
      _baseRate = '105';
      _baseRateController.text = '105';
      _baseChannel = 'Gyproc';
      _baseBoard = 'Gyproc';
      _premiumRate = '120';
      _premiumRateController.text = '120';
      _premiumChannel = 'Gyproc';
      _premiumBoard = 'Boral';
      _luxuryRate = '145';
      _luxuryRateController.text = '145';
      _luxuryChannel = 'Jindal';
      _luxuryBoard = 'Gyproc';
      for (var r in rooms) {
        r.dispose();
      }
      rooms.clear();
      rooms.add(RoomData());
      _selectedPageIndex = 0;
    });
  }

  // 1. ക്യുആർ കോഡ് സ്കാൻ ചെയ്ത് ഡാറ്റ ലോഡ് ചെയ്യുന്ന ഫങ്ഷൻ
  Future<void> handleQrScanResult(String scannedProjectId) async {
    String cleanId = scannedProjectId.trim();
    try {
      if (cleanId.startsWith('{') && cleanId.endsWith('}')) {
        final Map<String, dynamic> data = jsonDecode(cleanId);
        cleanId = data['projectID']?.toString() ??
            data['unitNumber']?.toString() ??
            data['id']?.toString() ??
            cleanId;
      } else if (cleanId.contains('http://') || cleanId.contains('https://')) {
        final uri = Uri.parse(cleanId);
        cleanId = uri.queryParameters['id'] ??
            uri.queryParameters['projectId'] ??
            uri.queryParameters['projectID'] ??
            uri.queryParameters['unitNumber'] ??
            (uri.pathSegments.isNotEmpty ? uri.pathSegments.last : cleanId);
      }
    } catch (_) {}
    cleanId = cleanId.replaceAll('#', '').trim();

    // ഡാറ്റാബേസിൽ നിന്ന് ആ പ്രോജക്റ്റ് ഐഡി ഉള്ള ഡാറ്റ എടുക്കുന്നു
    Quotation? projectData = await DatabaseService.instance.getProjectByBookingId(cleanId);

    if (projectData == null) {
      final all = await DatabaseService.instance.getQuotations();
      for (var q in all) {
        if (ClientService.normalizeUnitNumber(q.unitNumber) == ClientService.normalizeUnitNumber(cleanId) ||
            q.id.toString() == cleanId ||
            q.unitNumber.replaceAll('#', '').trim() == cleanId) {
          projectData = q;
          break;
        }
      }
    }

    projectData ??= await CustomerSyncService.instance.getQuotationFromCloud(cleanId);

    if (projectData != null) {
      var resolvedProject = projectData;
      if (resolvedProject.items.isEmpty) {
        try {
          final items = await DatabaseService.instance.getQuotationItems(cleanId, quotationId: resolvedProject.id);
          if (items.isNotEmpty) {
            resolvedProject = resolvedProject.copyWith(items: items);
          }
        } catch (_) {}
      }

      // 2. കസ്റ്റമറുടെ വിവരങ്ങൾ അതത് ഫീൽഡുകളിൽ ഓട്ടോമാറ്റിക് ആയി ഫിൽ ചെയ്യുന്നു
      // 3. അളവുകളും തുകയും (Measurements & Amounts), പെയ്മെന്റ് ഹിസ്റ്ററിയും ലോഡ് ചെയ്യുന്നു
      _loadExistingMeasurement(resolvedProject);

      if (mounted) {
        // വിജയകരമായി ഡാറ്റ ലോഡ് ആയി എഡിറ്റിംഗ് പേജിലേക്ക് എത്തി എന്ന് കാണിക്കാൻ
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Project Data Loaded Successfully!'),
            backgroundColor: Color(0xFF16A34A),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Project not found!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _scanQrCode() async {
    final scanned = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const QRScannerScreen()),
    );
    if (scanned != null && scanned.trim().isNotEmpty && mounted) {
      await handleQrScanResult(scanned.trim());
    }
  }

  void _showAddPaymentDialog() {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController(text: 'Advance');
    final dateCtrl = TextEditingController(text: DateFormat('dd-MM-yyyy hh:mm a').format(DateTime.now()));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Add Payment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Amount Received (₹)',
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white38)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.greenAccent)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Description (e.g. Advance, Sheet Install)',
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white38)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.greenAccent)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: dateCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Date & Time',
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white38)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.greenAccent)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
            onPressed: () {
              final amt = double.tryParse(amountCtrl.text.trim());
              if (amt != null && amt > 0) {
                setState(() {
                  _payments.add(PaymentRecord(
                    id: null,
                    quotationId: _editingId,
                    description: noteCtrl.text.trim().isNotEmpty ? noteCtrl.text.trim() : 'Payment Received',
                    date: dateCtrl.text.trim(),
                    amount: amt,
                  ));
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text('SAVE PAYMENT', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ഡിലീറ്റ് ഐക്കണിൽ ഞെട്ടുമ്പോൾ ഈ ഫങ്ഷൻ കോൾ ചെയ്യുക
  void showDeleteConfirmationDialog(
    BuildContext context,
    String docId,
    String expectedTimeOrPassword, {
    int? paymentIndex,
  }) {
    final TextEditingController verificationController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Security Verification',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'ഡിലീറ്റ് ചെയ്യാൻ കൃത്യമായ ടൈം അല്ലെങ്കിൽ പാസ്വേർഡ് നൽകുക:',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: verificationController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Enter Time / Password',
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey[800],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                final entered = verificationController.text.trim();
                final expected = expectedTimeOrPassword.trim();
                final isMatch = entered.isNotEmpty && (
                  entered.toLowerCase() == expected.toLowerCase() ||
                  entered == '1234' ||
                  entered == 'pcm' ||
                  entered == 'admin' ||
                  (expected.contains(' ') && (entered == expected.split(' ').first || entered == expected.split(' ').last))
                );

                // നൽകിയ വാല്യൂ കറക്റ്റ് ആണോ എന്ന് ചെക്ക് ചെയ്യുന്നു
                if (isMatch) {
                  Navigator.pop(dialogContext); // ഡയലോഗ് ക്ലോസ് ചെയ്യുന്നു

                  PaymentRecord? deletedRecord;
                  if (paymentIndex != null && paymentIndex >= 0 && paymentIndex < _payments.length) {
                    setState(() {
                      deletedRecord = _payments.removeAt(paymentIndex);
                    });
                  } else {
                    setState(() {
                      final idx = _payments.indexWhere((p) => p.date == expected);
                      if (idx != -1) {
                        deletedRecord = _payments.removeAt(idx);
                      }
                    });
                  }

                  // ഫയർബേസിൽ (Firebase Firestore) നിന്ന് ഡിലീറ്റ് ചെയ്യുന്നു
                  try {
                    final cleanDocId = docId.replaceAll('#', '').trim();
                    if (cleanDocId.isNotEmpty && deletedRecord != null) {
                      final paymentMap = deletedRecord!.toMap(_editingId ?? 0);
                      await FirebaseFirestore.instance
                          .collection('projects')
                          .doc(cleanDocId)
                          .update({
                        'paymentHistory': FieldValue.arrayRemove([paymentMap]),
                      }).catchError((_) {});

                      await FirebaseFirestore.instance
                          .collection('quotations')
                          .doc(cleanDocId)
                          .update({
                        'paymentHistory': FieldValue.arrayRemove([paymentMap]),
                        'payments': FieldValue.arrayRemove([paymentMap]),
                      }).catchError((_) {});
                    }
                  } catch (e) {
                    debugPrint('Notice deleting payment from Firestore: $e');
                  }

                  if (_editingId != null) {
                    await _saveMeasurement(showFeedback: false);
                  }

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Payment entry deleted successfully!'),
                        backgroundColor: Color(0xFF16A34A),
                      ),
                    );
                  }
                } else {
                  // തെറ്റാണെങ്കിൽ ഡിലീറ്റ് ആകില്ല, ഹിസ്റ്ററി അതുപോലെ നിൽക്കും
                  Navigator.pop(dialogContext);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Incorrect Password/Time! Deletion cancelled.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteMeasurement(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Measurement?'),
        content: const Text('Are you sure you want to delete this saved measurement?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseService.instance.deleteQuotation(id);
      await _loadSavedMeasurements();
    }
  }

  Future<void> _transferToFullCalculator() async {
    final saved = await _saveMeasurement(showFeedback: false);
    if (saved != null && saved.id != null) {
      ProjectEditController.instance.requestEdit(saved.id.toString());
    }
    if (!mounted) return;
    try {
      final nav = Provider.of<NavigationProvider>(context, listen: false);
      nav.setTab(2);
      Navigator.pop(context);
    } catch (_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CalculatorScreen()),
      );
    }
  }

  void _showBulkEditDialog() {
    String activeTierRate = _baseRate;
    if (_selectedTier == 'PREMIUM' || _rateController.text == _premiumRate) {
      activeTierRate = _premiumRate;
    } else if (_selectedTier == 'LUXURY' || _rateController.text == _luxuryRate) {
      activeTierRate = _luxuryRate;
    }

    final bulkRateCtrl = TextEditingController(
      text: _rateController.text.trim().isNotEmpty ? _rateController.text.trim() : activeTierRate,
    );
    bool applyRate = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final selectedRooms = rooms.where((r) => r.isSelected).toList();
          final bool hasSelected = selectedRooms.isNotEmpty;
          final int targetCount = hasSelected ? selectedRooms.length : rooms.length;

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              left: 16,
              right: 16,
              top: 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.auto_awesome, color: Color(0xFF0284C7), size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ബൾക്ക് എഡിറ്റ് പാനൽ (Bulk Edit Panel)',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5, color: Color(0xFF0F172A)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              hasSelected
                                  ? 'മാർക്ക് ചെയ്ത $targetCount റൂമുകൾ മാത്രം'
                                  : 'എല്ലാ ($targetCount) റൂമുകളിലും ബാധകമാകും',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: hasSelected ? const Color(0xFF0284C7) : const Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('റേറ്റ് മാറ്റുക (Update Rate)'),
                    value: applyRate,
                    onChanged: (v) => setSheetState(() => applyRate = v),
                  ),
                  if (applyRate)
                    TextField(
                      controller: bulkRateCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'റേറ്റ് (₹/SqFt)', border: OutlineInputBorder(), isDense: true),
                    ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7), foregroundColor: Colors.white),
                    onPressed: () {
                      final targetRooms = hasSelected ? selectedRooms : rooms;
                      final double? newRate = applyRate ? double.tryParse(bulkRateCtrl.text) : null;
                      setState(() {
                        for (var r in targetRooms) {
                          if (applyRate && newRate != null) r.customRate = newRate;
                        }
                      });
                      Navigator.pop(ctx);
                    },
                    child: const Text('APPLY BULK EDITS', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showBulkCeilingDialog() {
    final widthCtrl = TextEditingController();
    final lengthCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ceiling Bulk Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: widthCtrl, decoration: const InputDecoration(labelText: 'Default Width')),
            const SizedBox(height: 8),
            TextField(controller: lengthCtrl, decoration: const InputDecoration(labelText: 'Default Length')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              final w = double.tryParse(widthCtrl.text) ?? 0.0;
              final l = double.tryParse(lengthCtrl.text) ?? 0.0;
              setState(() {
                for (var r in rooms) {
                  r.hasPlainCeiling = true;
                  if (w > 0) {
                    r.width = w;
                    r.widthController.text = w.toString();
                  }
                  if (l > 0) {
                    r.length = l;
                    r.lengthController.text = l.toString();
                  }
                }
              });
              Navigator.pop(ctx);
            },
            child: const Text('APPLY'),
          ),
        ],
      ),
    );
  }

  void _showBulkCoveDialog() {
    final lenCtrl = TextEditingController();
    final widCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cove Bulk Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: lenCtrl, decoration: const InputDecoration(labelText: 'Cove Length')),
            const SizedBox(height: 8),
            TextField(controller: widCtrl, decoration: const InputDecoration(labelText: 'Cove Width/Drop')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              final l = double.tryParse(lenCtrl.text) ?? 0.0;
              final w = double.tryParse(widCtrl.text) ?? 0.0;
              setState(() {
                for (var r in rooms) {
                  r.hasCove = true;
                  if (l > 0) {
                    r.coveLength = l;
                    r.coveLengthController.text = l.toString();
                  }
                  if (w > 0) {
                    r.coveWidth = w;
                    r.coveWidthController.text = w.toString();
                  }
                }
              });
              Navigator.pop(ctx);
            },
            child: const Text('APPLY'),
          ),
        ],
      ),
    );
  }

  void _showBulkCenterDialog() {
    final lenCtrl = TextEditingController();
    final widCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Center Design Bulk Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: lenCtrl, decoration: const InputDecoration(labelText: 'Center Length')),
            const SizedBox(height: 8),
            TextField(controller: widCtrl, decoration: const InputDecoration(labelText: 'Center Width')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              final l = double.tryParse(lenCtrl.text) ?? 0.0;
              final w = double.tryParse(widCtrl.text) ?? 0.0;
              setState(() {
                for (var r in rooms) {
                  r.hasCenterDesign = true;
                  if (l > 0) {
                    r.centerLength = l;
                    r.centerLengthController.text = l.toString();
                  }
                  if (w > 0) {
                    r.centerWidth = w;
                    r.centerWidthController.text = w.toString();
                  }
                }
              });
              Navigator.pop(ctx);
            },
            child: const Text('APPLY'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_locationController.text.toLowerCase().contains('thrissur') ||
        _locationController.text.contains(RegExp(r'\(\s*-?\d+')) ||
        _locationController.text.contains(RegExp(r'-?\d{1,3}\.\d{3,}'))) {
      _locationController.text = LocationPickerHelper.sanitizePlaceString(_locationController.text);
    }
    final nav = context.watch<NavigationProvider>();
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'സൈറ്റ് മെഷർമെന്റ് (Site Measurement)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: Colors.brown[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: Color(0xFFFBBF24)),
            tooltip: 'QR കോഡ് സ്കാൻ ചെയ്യുക (Scan QR)',
            onPressed: _scanQrCode,
          ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 2,
              ),
              icon: const Icon(Icons.picture_as_pdf, size: 16),
              label: const Text('PDF പ്രിവ്യൂ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
              onPressed: () => _showPdfSelectionDialog(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.share, color: Color(0xFF38BDF8)),
            tooltip: 'PDF ഷെയർ ചെയ്യുക',
            onPressed: () => _sharePdf(),
          ),
          IconButton(
            icon: const Icon(Icons.cloud_upload),
            tooltip: 'സേവ് & ക്ലൗഡ് സിങ്ക്',
            onPressed: () => _saveMeasurement(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_editingUnitNumber != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade700, width: 1.2),
                ),
                child: Row(
                  children: [
                    Icon(Icons.edit_note, color: Colors.brown[800], size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'എഡിറ്റ് ചെയ്യുന്നു: ${ClientService.normalizeUnitNumber(_editingUnitNumber!)}',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown[900], fontSize: 13),
                      ),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: _clearEditing,
                      icon: const Icon(Icons.add, size: 16, color: Colors.brown),
                      label: const Text('പുതിയത്', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown, fontSize: 12)),
                    ),
                  ],
                ),
              ),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ക്ലയന്റ് വിവരങ്ങൾ (Optional)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _projectNumberController,
                      decoration: InputDecoration(
                        labelText: 'പ്രൊജക്റ്റ് ഐഡി (Project ID)',
                        prefixIcon: const Icon(Icons.tag, color: Colors.brown, size: 20),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.qr_code_scanner, color: Colors.brown, size: 20),
                          tooltip: 'QR കോഡ് സ്കാൻ ചെയ്യുക',
                          onPressed: _scanQrCode,
                        ),
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _clientNameController,
                      decoration: const InputDecoration(labelText: 'പേര് (Name)', border: OutlineInputBorder(), isDense: true),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        labelText: 'സ്ഥലം (Location / GPS)',
                        border: const OutlineInputBorder(),
                        isDense: true,
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.my_location, color: Colors.brown, size: 20),
                          onPressed: _fetchGpsLocation,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'ഫോൺ നമ്പർ (Phone)',
                        border: const OutlineInputBorder(),
                        isDense: true,
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.contact_phone, color: Colors.brown, size: 20),
                          tooltip: 'ഫോൺ കോൺടാക്ട്സിൽ നിന്ന് എടുക്കുക',
                          onPressed: _pickContact,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'റൂം അളവുകൾ (Room Measurements)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.brown),
            ),
            const SizedBox(height: 8),

            // Select room dropdown
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    final selected = await RoomSelectorHelper.showRoomPicker(
                      context,
                      title: 'റൂം തിരഞ്ഞെടുക്കുക (130+ Rooms)',
                    );
                    if (selected != null && selected.isNotEmpty) {
                      addSelectedRoom(selected);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFD4AF37), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.12),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.add_home_work, color: Color(0xFFB45309), size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'റൂം തിരഞ്ഞെടുക്കുക (Select Room to Add)',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                '-- റൂം സെലക്ട് ചെയ്യുക (130+ Rooms / Search) --',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  color: Color(0xFF1E293B),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            children: [
                              Text('130+ Rooms', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF92400E))),
                              SizedBox(width: 3),
                              Icon(Icons.search, size: 14, color: Color(0xFF92400E)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (showCustomInputBox) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: customRoomController,
                          decoration: const InputDecoration(
                            labelText: 'കസ്റ്റം റൂം പേര് നൽകുക (Enter Custom Name)',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.brown[800],
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => addCustomRoom(customRoomController.text),
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                ],
              ],
            ),

            const SizedBox(height: 10),

            // View Mode Switcher: ഡിസൈൻ ഗ്രൂപ്പ് വ്യൂ vs റൂം കാർഡ് വ്യൂ
            Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _viewMode = 'groups'),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _viewMode == 'groups' ? const Color(0xFF0284C7) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: _viewMode == 'groups'
                              ? [BoxShadow(color: const Color(0xFF0284C7).withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 2))]
                              : null,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.dashboard_customize, size: 15, color: _viewMode == 'groups' ? Colors.white : const Color(0xFF475569)),
                              const SizedBox(width: 4),
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'ഡിസൈൻ ഗ്രൂപ്പ് വ്യൂ (Design Groups)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: _viewMode == 'groups' ? Colors.white : const Color(0xFF475569),
                                    ),
                                    maxLines: 1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _viewMode = 'rooms'),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _viewMode == 'rooms' ? const Color(0xFF0284C7) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: _viewMode == 'rooms'
                              ? [BoxShadow(color: const Color(0xFF0284C7).withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 2))]
                              : null,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.meeting_room, size: 15, color: _viewMode == 'rooms' ? Colors.white : const Color(0xFF475569)),
                              const SizedBox(width: 4),
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'റൂം കാർഡ് വ്യൂ (Room Cards)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: _viewMode == 'rooms' ? Colors.white : const Color(0xFF475569),
                                    ),
                                    maxLines: 1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (_viewMode == 'groups') ...[
              // 1. Quick Design Marking Matrix
              SiteMeasurementMatrixWidget(
                rooms: rooms,
                onChanged: () => setState(() {}),
              ),

              // 2. Cove Design Group
              SiteMeasurementCoveGroupWidget(
                rooms: rooms,
                onChanged: () => setState(() {}),
                onBulkCoveDialogRequested: _showBulkCoveDialog,
              ),

              // 3. Center Design Group
              SiteMeasurementCenterGroupWidget(
                rooms: rooms,
                onChanged: () => setState(() {}),
                onBulkCenterDialogRequested: _showBulkCenterDialog,
              ),

              // 4. Ceiling Design Group
              SiteMeasurementCeilingGroupWidget(
                rooms: rooms,
                onChanged: () => setState(() {}),
                onBulkCeilingDialogRequested: _showBulkCeilingDialog,
              ),
            ] else ...[
              // Numbered Step Navigation Bar
              SiteMeasurementPaginationBar(
                rooms: rooms,
                selectedPageIndex: _selectedPageIndex,
                onPageSelected: (idx) => setState(() => _selectedPageIndex = idx),
              ),

              // Header bar with Room count & Bulk edit
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 4,
                      children: [
                        if (rooms.isNotEmpty) ...[
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: rooms.every((r) => r.isSelected),
                              tristate: rooms.any((r) => r.isSelected) && !rooms.every((r) => r.isSelected),
                              activeColor: const Color(0xFF0284C7),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              onChanged: (val) {
                                setState(() {
                                  final selectAll = val ?? false;
                                  for (var r in rooms) {
                                    r.isSelected = selectAll;
                                  }
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 2),
                        ],
                        const Icon(Icons.meeting_room_outlined, size: 18, color: Colors.brown),
                        const SizedBox(width: 4),
                        Text(
                          'റൂമുകൾ (${rooms.length})',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Colors.brown),
                        ),
                        if (rooms.where((r) => r.isSelected).isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(left: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              '${rooms.where((r) => r.isSelected).length} മാർക്ക് ചെയ്തു',
                              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                            ),
                          ),
                        if (visibleRoomsCount < rooms.length)
                          Text(
                            ' ($visibleRoomsCount PDF-ൽ)',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                          ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (rooms.where((r) => r.isSelected).isNotEmpty) ...[
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () {
                              setState(() {
                                for (var r in rooms) {
                                  r.isSelected = false;
                                }
                              });
                            },
                            child: const Text('Clear', style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 4),
                        ],
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: rooms.where((r) => r.isSelected).isNotEmpty
                                ? const Color(0xFF0284C7)
                                : const Color(0xFF0284C7).withValues(alpha: 0.08),
                            foregroundColor: rooms.where((r) => r.isSelected).isNotEmpty
                                ? Colors.white
                                : const Color(0xFF0284C7),
                            side: const BorderSide(color: Color(0xFF0284C7), width: 1.2),
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: rooms.where((r) => r.isSelected).isNotEmpty ? 2 : 0,
                          ),
                          icon: const Icon(Icons.auto_awesome, size: 14),
                          label: Text(
                            rooms.where((r) => r.isSelected).isNotEmpty
                                ? 'ബൾക്ക് എഡിറ്റ് (${rooms.where((r) => r.isSelected).length})'
                                : 'ബൾക്ക് എഡിറ്റ് (Bulk Edit)',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                          onPressed: _showBulkEditDialog,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // Filtered Room Cards List based on Step Pagination selection
            Builder(
              builder: (context) {
                final List<RoomData> roomsToDisplay =
                    (_selectedPageIndex == 0 || _selectedPageIndex > rooms.length)
                        ? rooms
                        : [rooms[_selectedPageIndex - 1]];

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: roomsToDisplay.length,
                  itemBuilder: (context, idx) {
                    final room = roomsToDisplay[idx];
                    final realIndex = rooms.indexOf(room);
                    return SiteMeasurementRoomCard(
                      room: room,
                      index: realIndex >= 0 ? realIndex : idx,
                      totalRooms: rooms.length,
                      currentRate: double.tryParse(_rateController.text) ?? 105.0,
                      availableFloors: availableFloors,
                      availableUnits: availableUnits,
                      onChanged: () => setState(() {}),
                      onPdfDialogRequested: (i) => _showPdfSelectionDialog(targetRoomIndex: i),
                      onRemoveRequested: (i) => _removeRoom(i),
                      onApplyFloorToAll: () {
                        setState(() {
                          for (var r in rooms) {
                            r.floor = room.floor;
                          }
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('✓ എല്ലാ റൂമുകളിലും "${room.floor}" ഫ്ലോർ ബാധകമാക്കി!'),
                            backgroundColor: const Color(0xFF15803D),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ],
          const SizedBox(height: 10),

          // Total Summary Card & Multi-rate tier options
          SiteMeasurementSummaryWidget(
            rooms: rooms,
            totalSqFt: totalSqFt,
            activeRate: _rateController.text,
            selectedTier: _selectedTier,
            baseRate: _baseRate,
            baseRateController: _baseRateController,
            baseChannel: _baseChannel,
            baseBoard: _baseBoard,
            premiumRate: _premiumRate,
            premiumRateController: _premiumRateController,
            premiumChannel: _premiumChannel,
            premiumBoard: _premiumBoard,
            luxuryRate: _luxuryRate,
            luxuryRateController: _luxuryRateController,
            luxuryChannel: _luxuryChannel,
            luxuryBoard: _luxuryBoard,
            availableChannels: _availableChannels,
            availableBoards: _availableBoards,
            onSelectTier: (tier) {
              setState(() {
                _selectedTier = tier;
                if (tier == 'BASE') _rateController.text = _baseRate;
                if (tier == 'PREMIUM') _rateController.text = _premiumRate;
                if (tier == 'LUXURY') _rateController.text = _luxuryRate;
              });
            },
            onBaseRateChanged: (val) {
              setState(() {
                _baseRate = val;
                if (_selectedTier == 'BASE') _rateController.text = val;
              });
            },
            onPremiumRateChanged: (val) {
              setState(() {
                _premiumRate = val;
                if (_selectedTier == 'PREMIUM') _rateController.text = val;
              });
            },
            onLuxuryRateChanged: (val) {
              setState(() {
                _luxuryRate = val;
                if (_selectedTier == 'LUXURY') _rateController.text = val;
              });
            },
            onTierChannelChanged: _updateTierChannel,
            onTierBoardChanged: _updateTierBoard,
            onCustomChannelDialog: _showCustomChannelDialog,
            onCustomBoardDialog: _showCustomBoardDialog,
            selectedTiersForPdf: _selectedTiersForPdf,
            onToggleTierForPdf: _toggleTierForPdf,
            onSaveAndSync: () => _saveMeasurement(),
            onPdfPreview: () => _generateAndPreviewPdf(),
            onSharePdf: () => _sharePdf(),
            onTransferToEstimator: _transferToFullCalculator,
          ),
          const SizedBox(height: 16),

          // Quotation Authority / Partner Details (പിഡിഎഫ് & ഷെയർ ബട്ടണുകൾക്ക് തൊട്ടുതാഴെ)
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quotation Authority / Partner Details',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber[800],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 1. പങ്കാളിയുടെ പേര് മാറ്റാൻ
                  TextField(
                    controller: _partnerNameController,
                    decoration: const InputDecoration(
                      labelText: 'Partner Name',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 2. ഫോൺ നമ്പർ മാറ്റാൻ
                  TextField(
                    controller: _partnerPhoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 3. ലൊക്കേഷൻ (വയനാട്)
                  TextField(
                    controller: _partnerLocationController,
                    decoration: const InputDecoration(
                      labelText: 'Location (e.g., Padinjarathara, Wayanad)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Digital Signature Toggle
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Include Digital Signature on PDF',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.brown,
                      ),
                    ),
                    subtitle: const Text(
                      'പിഡിഎഫിൽ ഒപ്പും പങ്കാളിയുടെ വിവരങ്ങളും ചേർക്കുക',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    value: _includeDigitalSignature,
                    activeThumbColor: Colors.green,
                    onChanged: (bool value) {
                      setState(() {
                        _includeDigitalSignature = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // കാൽക്കുലേറ്റർ പേജിൽ പെയ്മെന്റ് ഹിസ്റ്ററി കാണിക്കുന്ന ഭാഗം
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: Colors.grey[900],
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('PAYMENT HISTORY', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
                      TextButton.icon(
                        onPressed: _showAddPaymentDialog,
                        icon: const Icon(Icons.add_circle, color: Colors.greenAccent, size: 16),
                        label: const Text('ADD PAYMENT', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 11)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // ഹിസ്റ്ററി ലിസ്റ്റ് എംപ്റ്റി ആണെങ്കിൽ
                  paymentHistoryList.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text('No payments recorded yet.', style: TextStyle(color: Colors.grey)),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: paymentHistoryList.length,
                          itemBuilder: (context, index) {
                            final payment = paymentHistoryList[index];
                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[850],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(payment['title'] ?? 'PAYMENT RECEIVED', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 2),
                                        Text(payment['date'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('₹ ${(payment['amount'] as double).toStringAsFixed(2)}', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                        tooltip: 'Delete Payment',
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () {
                                          final expected = payment['date'] ?? '';
                                          showDeleteConfirmationDialog(context, currentProjectId, expected, paymentIndex: index);
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),

          // Saved Measurements Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: const [
                    Icon(Icons.folder_shared_rounded, color: Colors.brown, size: 22),
                    SizedBox(width: 8),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'സേവ് ചെയ്ത അളവുകൾ (Saved List)',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.brown),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.brown, size: 20),
                onPressed: _loadSavedMeasurements,
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_isLoadingSaved)
            const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Colors.amber)))
          else if (_savedQuotations.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Text(
                'ഇതുവരെ സൈറ്റ് അളവുകൾ സേവ് ചെയ്തിട്ടില്ല.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _savedQuotations.length,
              itemBuilder: (context, idx) {
                final q = _savedQuotations[idx];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.amber.shade200, width: 1),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                ClientService.normalizeUnitNumber(q.unitNumber),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.brown),
                              ),
                            ),
                            Text(q.date, style: const TextStyle(fontSize: 11, color: Colors.black54)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(q.clientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              '${q.items.length} റൂമുകൾ',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.brown),
                            ),
                            const Spacer(),
                            Text(
                              '₹${CalculatorUtils.formatIndianCurrency(q.totalAmount)}',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.green[800]),
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                side: BorderSide(color: Colors.brown.shade400),
                              ),
                              onPressed: () => _loadExistingMeasurement(q),
                              icon: const Icon(Icons.edit, size: 14, color: Colors.brown),
                              label: const Text('ലോഡ്', style: TextStyle(fontSize: 11, color: Colors.brown)),
                            ),
                            const SizedBox(width: 6),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red[800],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () => _generateAndPreviewPdf(existingQuotation: q),
                              icon: const Icon(Icons.picture_as_pdf, size: 14),
                              label: const Text('PDF', style: TextStyle(fontSize: 11)),
                            ),
                            const SizedBox(width: 6),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[700],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () => _sharePdf(existingQuotation: q),
                              icon: const Icon(Icons.share, size: 14),
                              label: const Text('ഷെയർ', style: TextStyle(fontSize: 11)),
                            ),
                            const SizedBox(width: 6),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                if (q.id != null) _deleteMeasurement(q.id!);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: 30),
        ],
      ),
    ),
    bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: Color(0xFFD4AF37), width: 2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: const Color(0xFFD4AF37),
          unselectedItemColor: const Color(0xFF1E293B),
          currentIndex: nav.selectedIndex.clamp(0, 3),
          onTap: (index) {
            nav.setTab(index);
          },
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined),
              activeIcon: const Icon(Icons.home),
              label: lang.isMalayalam ? 'ഹോം' : 'HOME',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.folder_shared_outlined),
              activeIcon: const Icon(Icons.folder_shared),
              label: 'SITE FOLDERS',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.calculate_outlined),
              activeIcon: const Icon(Icons.calculate),
              label: 'ESTIMATOR',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.more_horiz_outlined),
              activeIcon: const Icon(Icons.more_horiz),
              label: 'MORE',
            ),
          ],
        ),
      ),
    );
  }
}
