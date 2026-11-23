// ignore_for_file: unused_field, unused_element, deprecated_member_use, use_build_context_synchronously, curly_braces_in_flow_control_structures, unused_local_variable, sort_child_properties_last, avoid_print, non_constant_identifier_names, avoid_web_libraries_in_flutter
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../calculator/calculator_controller.dart';
import '../../../providers/language_provider.dart';
import 'quick_add_bottom_sheet.dart';
import '../helpers/room_selector_helper.dart';
import '../../../../models/rate_tier.dart';
import '../brands/ceiling_board_brands.dart';
import '../brands/channel_brands.dart';
import '../brands/brand_selector_helper.dart';

class CalculatorInputsWidget extends StatefulWidget {
  final CalculatorController ctrl;
  final LanguageProvider lang;
  final VoidCallback onStateChanged;

  const CalculatorInputsWidget({
    super.key,
    required this.ctrl,
    required this.lang,
    required this.onStateChanged,
  });

  @override
  State<CalculatorInputsWidget> createState() => _CalculatorInputsWidgetState();
}

class _CalculatorInputsWidgetState extends State<CalculatorInputsWidget> {
  bool showCustomCeilingInput = false;
  bool showCustomBrandInput = false;
  bool showCustomChannelInput = false;
  bool showQuickAddDropdown = false;
  bool showCustomInputBox = false;

  TextEditingController? _customRoomController;
  TextEditingController get customRoomController => _customRoomController ??= TextEditingController();

  TextEditingController? _quickSearchController;
  TextEditingController get quickSearchController => _quickSearchController ??= TextEditingController();

  String? _quickSearchQuery;
  String get quickSearchQuery => _quickSearchQuery ?? "";
  set quickSearchQuery(String v) => _quickSearchQuery = v;

  CalculatorController get ctrl => widget.ctrl;
  LanguageProvider get lang => widget.lang;
  VoidCallback get onStateChanged => widget.onStateChanged;

  static final List<String> roomOptions = RoomSelectorHelper.masterRoomOptions;

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
      setState(() {
        showCustomInputBox = true;
        showQuickAddDropdown = false;
      });
      return;
    }

    // Auto-calculate the next room number based on existing items
    int nextRoomNumber = 1;
    if (ctrl.currentItems.isNotEmpty) {
      final existingNumbers = ctrl.currentItems
          .map((it) => int.tryParse(it.roomNumber) ?? 0)
          .where((n) => n > 0);
      if (existingNumbers.isNotEmpty) {
        nextRoomNumber = existingNumbers.reduce((a, b) => a > b ? a : b) + 1;
      } else {
        nextRoomNumber = ctrl.currentItems.length + 1;
      }
    }
    ctrl.roomNumberController.text = '$nextRoomNumber';

    setState(() {
      ctrl.selectedRoom = roomName;
      ctrl.roomController.text = roomName;
      quickSearchController.text = roomName;
      showQuickAddDropdown = false;
      quickSearchQuery = "";
      showCustomInputBox = false;
    });
    ctrl.triggerAutoSave();
    onStateChanged();
    QuickAddBottomSheet.show(context, ctrl, lang);
  }

  void addCustomRoom(String customName) {
    if (customName.trim().isNotEmpty) {
      final name = customName.trim();
      int nextRoomNumber = 1;
      if (ctrl.currentItems.isNotEmpty) {
        final existingNumbers = ctrl.currentItems
            .map((it) => int.tryParse(it.roomNumber) ?? 0)
            .where((n) => n > 0);
        if (existingNumbers.isNotEmpty) {
          nextRoomNumber = existingNumbers.reduce((a, b) => a > b ? a : b) + 1;
        } else {
          nextRoomNumber = ctrl.currentItems.length + 1;
        }
      }
      ctrl.roomNumberController.text = '$nextRoomNumber';

      setState(() {
        ctrl.selectedRoom = 'Other';
        ctrl.roomController.text = name;
        quickSearchController.text = name;
        customRoomController.clear();
        showCustomInputBox = false;
      });
      ctrl.triggerAutoSave();
      onStateChanged();
      QuickAddBottomSheet.show(context, ctrl, lang);
    }
  }

  @override
  void initState() {
    super.initState();
    if (ctrl.selectedCeilingType == 'Other' || ctrl.selectedCeilingType == 'More') {
      showCustomCeilingInput = true;
    }
    if (ctrl.selectedBrand == 'Other' || ctrl.selectedBrand == 'More') {
      showCustomBrandInput = true;
    }
    if (ctrl.selectedChannel == 'Other' || ctrl.selectedChannel == 'More') {
      showCustomChannelInput = true;
    }
    if (ctrl.selectedRoom == 'Bedroom 1' || ctrl.selectedRoom == 'Bedroom 2') {
      ctrl.selectedRoom = null;
      ctrl.roomController.clear();
      quickSearchController.clear();
    } else if (ctrl.selectedRoom != null && ctrl.selectedRoom!.isNotEmpty) {
      quickSearchController.text = ctrl.selectedRoom == 'Other' ? ctrl.roomController.text : ctrl.selectedRoom!;
    }
  }

  final Map<String, TextEditingController> _tierRateControllers = {};

  TextEditingController _getTierController(RateTier tier) {
    if (!_tierRateControllers.containsKey(tier.name)) {
      _tierRateControllers[tier.name] = TextEditingController(
        text: tier.rate > 0 ? (tier.rate % 1 == 0 ? tier.rate.toInt().toString() : tier.rate.toString()) : '105',
      );
    }
    return _tierRateControllers[tier.name]!;
  }

  @override
  void dispose() {
    for (var c in _tierRateControllers.values) {
      c.dispose();
    }
    _customRoomController?.dispose();
    _quickSearchController?.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Builder(
          builder: (context) {
            final ceilingItems = ctrl.ceilingTypes.keys.toSet().toList();
            if (!ceilingItems.contains('Other')) {
              ceilingItems.add('Other');
            }
            
            // Standardize value
            String? currentValue = ctrl.selectedCeilingType;
            if (currentValue?.toLowerCase() == 'gypsum' || currentValue?.toLowerCase() == 'gypsum board') {
              currentValue = 'Gypsum Board';
            }
            if (currentValue?.toLowerCase() == 'pvc ceiling' || currentValue?.toLowerCase() == 'pvc board') {
              currentValue = 'PVC Board';
            }

            // Safety: Ensure selected value exists in items to prevent Dropdown crash
            final initialCeiling = (currentValue != null && ceilingItems.contains(currentValue)) 
                ? currentValue
                : (showCustomCeilingInput ? 'Other' : null);

            return DropdownButtonFormField<String>(
              isExpanded: true,
              value: initialCeiling,
              decoration: AppStyles.inputDecoration(lang.translate('CEILING')).copyWith(
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              ),
              items: ceilingItems.map((val) => DropdownMenuItem(
                value: val, 
                child: Text(
                  val, 
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                )
              )).toList(),
              onChanged: (v) { 
                setState(() {
                  showCustomCeilingInput = (v == 'Other' || v == 'More');
                });
                ctrl.selectedCeilingType = v; 
                ctrl.selectedBrand = null; 
                if (v != null && v != 'Other' && v != 'More') {
                  final defRate = ctrl.getDefaultRate(v);
                  if (defRate > 0) {
                    ctrl.rateController.text = defRate.toString();
                  }
                }
                ctrl.updateLivePreview();
                onStateChanged();
              },
            );
          }
        ),
        // Ceiling ഫീൽഡിന് താഴെ:
        if (showCustomCeilingInput) ...[
          const SizedBox(height: 8),
          TextField(
            controller: ctrl.customCeilingController,
            decoration: const InputDecoration(
              labelText: 'Enter Custom Ceiling',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              ctrl.triggerAutoSave();
            },
          ),
        ],
        const SizedBox(height: 15),
        // Brand Selection (Ceiling Board)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'BRAND SELECTION',
              style: TextStyle(
                color: Colors.black,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: () async {
                final brandsList = CeilingBoardBrands.getBrandsForCeiling(ctrl.selectedCeilingType);
                final current = ctrl.selectedBrand ?? brandsList.first;
                final selected = await BrandSelectorHelper.showBrandPicker(
                  context,
                  title: 'Select Ceiling Board Brand',
                  brands: brandsList,
                  currentBrand: current,
                  isChannel: false,
                );
                if (selected != null) {
                  setState(() {
                    showCustomBrandInput = (selected == 'More' || selected == 'Other');
                  });
                  if (selected == 'More' || selected == 'Other') {
                    ctrl.selectedBrand = 'Other';
                  } else {
                    ctrl.updateActiveBrand(selected);
                  }
                  ctrl.triggerAutoSave();
                  onStateChanged();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.6), width: 1.2),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF16A34A), width: 1.0),
                      ),
                      child: const Icon(Icons.layers_outlined, size: 15, color: Color(0xFF16A34A)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        ctrl.selectedBrand ?? 'Select Brand',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF1E293B)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, color: Color(0xFF16A34A)),
                  ],
                ),
              ),
            ),
          ],
        ),
        // Brand Selection ഫീൽഡിന് താഴെ:
        if (showCustomBrandInput) ...[
          const SizedBox(height: 8),
          TextField(
            controller: ctrl.brandController,
            decoration: const InputDecoration(
              labelText: 'Enter Custom Brand',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              ctrl.updateActiveBrand(value.trim());
              ctrl.triggerAutoSave();
            },
          ),
        ],
        const SizedBox(height: 15),
        // Channel Selection (ചാനൽ)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CHANNEL SELECTION (ചാനൽ)',
              style: TextStyle(
                color: Colors.black,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: () async {
                final channelsList = ChannelBrands.getChannelsForCeiling(ctrl.selectedCeilingType);
                final current = ctrl.selectedChannel ?? channelsList.first;
                final selected = await BrandSelectorHelper.showBrandPicker(
                  context,
                  title: 'Select Channel Brand',
                  brands: channelsList,
                  currentBrand: current,
                  isChannel: true,
                );
                if (selected != null) {
                  setState(() {
                    showCustomChannelInput = (selected == 'More' || selected == 'Other');
                  });
                  if (selected == 'More' || selected == 'Other') {
                    ctrl.selectedChannel = 'Other';
                  } else {
                    ctrl.updateActiveChannel(selected);
                  }
                  ctrl.triggerAutoSave();
                  onStateChanged();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.6), width: 1.2),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF2563EB), width: 1.0),
                      ),
                      child: const Icon(Icons.architecture_outlined, size: 15, color: Color(0xFF2563EB)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        ctrl.selectedChannel ?? 'Select Channel',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF1E293B)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, color: Color(0xFF2563EB)),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (showCustomChannelInput) ...[
          const SizedBox(height: 8),
          TextField(
            controller: ctrl.channelController,
            decoration: const InputDecoration(
              labelText: 'Enter Custom Channel',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              ctrl.updateActiveChannel(value.trim());
              ctrl.triggerAutoSave();
            },
          ),
        ],
        const SizedBox(height: 16),

        const SizedBox(height: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () async {
                final selected = await RoomSelectorHelper.showRoomPicker(
                  context,
                  currentRoom: ctrl.selectedRoom,
                  title: lang.isMalayalam ? 'റൂം തിരഞ്ഞെടുക്കുക (130+ Rooms)' : 'Select Room (130+ Rooms)',
                );
                if (selected != null && selected.isNotEmpty) {
                  addSelectedRoom(selected);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.meeting_room, color: Colors.amber, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lang.isMalayalam ? 'റൂം തിരഞ്ഞെടുക്കുക (Select Room)' : 'Select Room',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            ctrl.selectedRoom?.isNotEmpty == true
                                ? ctrl.selectedRoom!
                                : (lang.isMalayalam ? '-- റൂം സെലക്ട് ചെയ്യുക (130+ Rooms / Search) --' : '-- Select Room (130+ Rooms) --'),
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: ctrl.selectedRoom?.isNotEmpty == true ? FontWeight.bold : FontWeight.w500,
                              color: ctrl.selectedRoom?.isNotEmpty == true ? Colors.black87 : Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        children: [
                          Text('130+ Rooms', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.brown)),
                          SizedBox(width: 3),
                          Icon(Icons.search, size: 13, color: Colors.brown),
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
                      decoration: InputDecoration(
                        labelText: lang.isMalayalam
                            ? 'കസ്റ്റം റൂം പേര് നൽകുക (Enter Custom Name)'
                            : 'Enter Custom Room Name',
                        border: const OutlineInputBorder(),
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
        const SizedBox(height: 15),
      ],
    );
  }
}
