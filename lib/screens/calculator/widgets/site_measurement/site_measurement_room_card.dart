import 'package:flutter/material.dart';
import '../../../../utils/calculator_utils.dart';
import '../../models/room_data.dart';
import '../../helpers/room_selector_helper.dart';
import '../../units/calculator_unit_helper.dart';

/// Card widget representing an individual room in Site Measurement.
class SiteMeasurementRoomCard extends StatelessWidget {
  final RoomData room;
  final int index;
  final int totalRooms;
  final double currentRate;
  final List<String> availableFloors;
  final List<String> availableUnits;
  final VoidCallback onChanged;
  final ValueChanged<int> onPdfDialogRequested;
  final ValueChanged<int> onRemoveRequested;
  final VoidCallback onApplyFloorToAll;

  const SiteMeasurementRoomCard({
    super.key,
    required this.room,
    required this.index,
    required this.totalRooms,
    required this.currentRate,
    required this.availableFloors,
    required this.availableUnits,
    required this.onChanged,
    required this.onPdfDialogRequested,
    required this.onRemoveRequested,
    required this.onApplyFloorToAll,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRate = room.customRate ?? currentRate;
    final totalRoomAmount = room.calculatedSqFt * effectiveRate;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: room.isHidden ? 1 : (room.isSelected ? 3 : 2),
      color: room.isHidden
          ? const Color(0xFFFBFBFB)
          : (room.isSelected ? const Color(0xFFF0F9FF) : Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: room.isHidden
              ? const Color(0xFFFCA5A5)
              : (room.isSelected ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0)),
          width: (room.isHidden || room.isSelected) ? 1.4 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Room Header (Room Selection Checkbox, Name, Number, PDF Eye Toggle, Delete)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      SizedBox(
                        width: 26,
                        height: 26,
                        child: Checkbox(
                          value: room.isSelected,
                          activeColor: const Color(0xFF0284C7),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          onChanged: (val) {
                            room.isSelected = val ?? false;
                            onChanged();
                          },
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () async {
                            final selected = await RoomSelectorHelper.showRoomPicker(
                              context,
                              currentRoom: room.roomName,
                              title: 'റൂം പേര് മാറ്റുക (Change Room)',
                            );
                            if (selected != null && selected.isNotEmpty) {
                              room.roomName = selected;
                              onChanged();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.brown.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.brown.shade200),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.meeting_room, size: 15, color: Colors.brown),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    room.roomName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.brown,
                                      fontSize: 13,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const Icon(Icons.arrow_drop_down, color: Colors.brown, size: 18),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Text(
                          '#${room.roomNumber}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF0F172A)),
                        ),
                      ),
                      if (room.roomCount > 1) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F2FE),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFBAE6FD)),
                          ),
                          child: Text(
                            '${room.roomCount} റൂമുകൾ',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10.5, color: Color(0xFF0369A1)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.picture_as_pdf, color: Color(0xFF16A34A), size: 20),
                      tooltip: 'ഈ റൂം PDF ചെയ്യുക (Print/Share)',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => onPdfDialogRequested(index),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(
                        room.isHidden ? Icons.visibility_off : Icons.visibility,
                        color: room.isHidden ? Colors.red.shade400 : const Color(0xFF0284C7),
                        size: 21,
                      ),
                      tooltip: room.isHidden
                          ? 'PDF-ൽ നിന്ന് ഒഴിവാക്കി'
                          : 'PDF-ൽ ഉൾപ്പെടുത്തിയിട്ടുണ്ട്',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        room.isHidden = !room.isHidden;
                        onChanged();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(room.isHidden
                                ? '🚫 "${room.roomName}" ഫൈനൽ PDF-ൽ നിന്ന് ഒഴിവാക്കി.'
                                : '✓ "${room.roomName}" ഫൈനൽ PDF-ൽ ഉൾപ്പെടുത്തി.'),
                            duration: const Duration(seconds: 1),
                            backgroundColor: room.isHidden ? Colors.red.shade800 : const Color(0xFF0284C7),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: Icon(
                        room.showMoreDetails ? Icons.expand_less : Icons.more_horiz,
                        size: 16,
                        color: const Color(0xFF0284C7),
                      ),
                      label: Text(
                        room.showMoreDetails ? 'കുറയ്ക്കുക' : 'More',
                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                      ),
                      onPressed: () {
                        room.showMoreDetails = !room.showMoreDetails;
                        onChanged();
                      },
                    ),
                    if (totalRooms > 1) ...[
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => onRemoveRequested(index),
                      ),
                    ],
                  ],
                ),
              ],
            ),

            if (room.isHidden) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.visibility_off, size: 13, color: Colors.red),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'ഈ റൂം ഫൈനൽ PDF പ്രിന്റിൽ ഉൾപ്പെടില്ല (Excluded from Final PDF)',
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // 2. Floor Selection Buttons & Room Count Row
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 4,
                        runSpacing: 2,
                        children: [
                          const Text(
                            'നില (Floor Selection):',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                          ),
                          InkWell(
                            onTap: onApplyFloorToAll,
                            child: const Text(
                              'എല്ലാറ്റിലും ബാധകമാക്കുക ⇲',
                              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: availableFloors.map((f) {
                            final isFlr = room.floor == f;
                            return Padding(
                              padding: const EdgeInsets.only(right: 4.0),
                              child: ChoiceChip(
                                label: Text(
                                  f == 'Ground Floor' ? 'Ground' : f.replaceAll(' Floor', ''),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isFlr ? Colors.white : const Color(0xFF334155),
                                  ),
                                ),
                                selected: isFlr,
                                selectedColor: Colors.brown[700],
                                backgroundColor: const Color(0xFFF1F5F9),
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                onSelected: (val) {
                                  if (val) {
                                    room.floor = f;
                                    onChanged();
                                  }
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 65,
                  child: TextField(
                    controller: room.roomNumberController,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      labelText: 'റൂം #',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 7),
                    ),
                    onChanged: (val) {
                      room.roomNumber = val.trim();
                      onChanged();
                    },
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 75,
                  child: TextField(
                    controller: room.roomCountController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      labelText: 'റൂം എണ്ണം',
                      hintText: '1',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 7),
                    ),
                    onChanged: (val) {
                      final count = int.tryParse(val) ?? 1;
                      room.roomCount = count > 0 ? count : 1;
                      onChanged();
                    },
                  ),
                ),
              ],
            ),

            if (room.showMoreDetails) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: room.customRoomController
                        ..text = (room.customRoomController.text.isEmpty
                            ? room.roomName
                            : room.customRoomController.text),
                      decoration: const InputDecoration(
                        labelText: 'റൂം പേര് മാറ്റുക (Rename Room)',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                      ),
                      onChanged: (v) {
                        room.roomName = v.trim().isNotEmpty ? v.trim() : room.roomName;
                        onChanged();
                      },
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: room.notesController,
                      decoration: const InputDecoration(
                        labelText: 'പ്രത്യേക നിർദ്ദേശങ്ങൾ / നോട്ട്സ് (Notes)',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                      ),
                      onChanged: (v) {
                        room.customNotes = v.trim();
                      },
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 10),

            // [1. Plain Ceiling]
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: room.hasPlainCeiling ? const Color(0xFFF0F9FF) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: room.hasPlainCeiling ? const Color(0xFFBAE6FD) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            SizedBox(
                              height: 24,
                              width: 24,
                              child: Checkbox(
                                value: room.hasPlainCeiling,
                                activeColor: const Color(0xFF0284C7),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                onChanged: (v) {
                                  room.hasPlainCeiling = v ?? false;
                                  onChanged();
                                },
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.crop_landscape, size: 15, color: Color(0xFF0284C7)),
                            const SizedBox(width: 4),
                            const Flexible(
                              child: Text(
                                '1. Plain Ceiling (പ്ലെയ്ൻ ഡിസൈൻ)',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0369A1),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (room.hasPlainCeiling)
                            Text(
                              '${CalculatorUtils.formatNumber(room.plainSqFt)} Sq.Ft  ',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0284C7),
                              ),
                            ),
                          SizedBox(
                            height: 22,
                            width: 38,
                            child: Switch(
                              value: room.hasPlainCeiling,
                              activeTrackColor: const Color(0xFF0284C7),
                              onChanged: (v) {
                                room.hasPlainCeiling = v;
                                onChanged();
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (room.hasPlainCeiling) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: room.widthController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'വീതി (Width)',
                              border: OutlineInputBorder(),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            ),
                            onChanged: (val) {
                              room.width = double.tryParse(val) ?? 0.0;
                              onChanged();
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: room.lengthController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'നീളം (Length)',
                              border: OutlineInputBorder(),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            ),
                            onChanged: (val) {
                              room.length = double.tryParse(val) ?? 0.0;
                              onChanged();
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          height: 36,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: availableUnits.contains(room.unit) ? room.unit : 'Feet',
                              isDense: true,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                              items: CalculatorUnitHelper.availableUnits.asMap().entries.map((entry) {
                                final idx = entry.key;
                                final u = entry.value;
                                final uColor = CalculatorUnitHelper.getUnitColor(u, idx);
                                return DropdownMenuItem(
                                  value: u,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: uColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: uColor, width: 1.6),
                                    ),
                                    child: Text(
                                      u,
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: uColor),
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  room.unit = val;
                                  onChanged();
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    const SizedBox(height: 4),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                      child: Text(
                        'Plain Ceiling ഒഴിവാക്കി (മാർക്ക് ചെയ്തിട്ടില്ല)',
                        style: TextStyle(fontSize: 10.5, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8)),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // [2. Cove Light]
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: room.hasCove ? const Color(0xFFFFFBEB) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: room.hasCove ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            SizedBox(
                              height: 24,
                              width: 24,
                              child: Checkbox(
                                value: room.hasCove,
                                activeColor: const Color(0xFFD97706),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                onChanged: (v) {
                                  room.hasCove = v ?? false;
                                  if (room.hasCove && room.coveLengthController.text.isEmpty) {
                                    room.coveLength = room.effectiveLength;
                                    room.coveLengthController.text =
                                        room.coveLength > 0 ? room.coveLength.toString() : '';
                                    room.coveWidth = 0.0;
                                    room.coveWidthController.text = '';
                                  }
                                  onChanged();
                                },
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.lightbulb_outline, size: 15, color: Color(0xFFD97706)),
                            const SizedBox(width: 4),
                            const Flexible(
                              child: Text(
                                '2. കോവ് ലൈറ്റ് (Cove Light)',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFB45309),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (room.hasCove)
                            Text(
                              '${CalculatorUtils.formatNumber(room.coveSqFt)} Sq.Ft  ',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFD97706),
                              ),
                            ),
                          SizedBox(
                            height: 22,
                            width: 38,
                            child: Switch(
                              value: room.hasCove,
                              activeTrackColor: const Color(0xFFD97706),
                              onChanged: (v) {
                                room.hasCove = v;
                                if (v && room.coveLengthController.text.isEmpty) {
                                  room.coveLength = room.effectiveLength;
                                  room.coveLengthController.text =
                                      room.coveLength > 0 ? room.coveLength.toString() : '';
                                  room.coveWidth = 0.0;
                                  room.coveWidthController.text = '';
                                }
                                onChanged();
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (room.hasCove) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: room.coveLengthController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'നീളം (Length)',
                              border: OutlineInputBorder(),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            ),
                            onChanged: (val) {
                              room.coveLength = double.tryParse(val) ?? 0.0;
                              onChanged();
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: room.coveWidthController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'വീതി/ഡ്രോപ്പ്',
                              border: OutlineInputBorder(),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            ),
                            onChanged: (val) {
                              room.coveWidth = double.tryParse(val) ?? 0.0;
                              onChanged();
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 75,
                          child: TextField(
                            controller: room.coveSidesController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(
                              labelText: 'സൈഡ്/എണ്ണം',
                              border: OutlineInputBorder(),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                            ),
                            onChanged: (val) {
                              room.coveSides = int.tryParse(val) ?? 4;
                              onChanged();
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // [3. Center Design]
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: room.hasCenterDesign ? const Color(0xFFF5F3FF) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: room.hasCenterDesign ? const Color(0xFFDDD6FE) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            SizedBox(
                              height: 24,
                              width: 24,
                              child: Checkbox(
                                value: room.hasCenterDesign,
                                activeColor: const Color(0xFF7C3AED),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                onChanged: (v) {
                                  room.hasCenterDesign = v ?? false;
                                  if (room.hasCenterDesign && room.centerLengthController.text.isEmpty) {
                                    room.centerLength = 0.0;
                                    room.centerLengthController.text = '';
                                    room.centerWidth = 0.0;
                                    room.centerWidthController.text = '';
                                  }
                                  onChanged();
                                },
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.center_focus_strong, size: 15, color: Color(0xFF7C3AED)),
                            const SizedBox(width: 4),
                            const Flexible(
                              child: Text(
                                '3. Center Design (സെന്റർ ഡിസൈൻ)',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF6D28D9),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (room.hasCenterDesign)
                            Text(
                              '${CalculatorUtils.formatNumber(room.centerSqFt)} Sq.Ft  ',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF7C3AED),
                              ),
                            ),
                          SizedBox(
                            height: 22,
                            width: 38,
                            child: Switch(
                              value: room.hasCenterDesign,
                              activeTrackColor: const Color(0xFF7C3AED),
                              onChanged: (v) {
                                room.hasCenterDesign = v;
                                if (v && room.centerLengthController.text.isEmpty) {
                                  room.centerLength = 0.0;
                                  room.centerLengthController.text = '';
                                  room.centerWidth = 0.0;
                                  room.centerWidthController.text = '';
                                }
                                onChanged();
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (room.hasCenterDesign) ...[
                    const SizedBox(height: 6),
                    Container(
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFC4B5FD)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: ['Center Design', 'Center Steel Ceiling', 'Custom Center Design']
                                  .contains(room.centerType)
                              ? room.centerType
                              : 'Center Design',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF5B21B6)),
                          items: const [
                            DropdownMenuItem(value: 'Center Design', child: Text('Center Design (വുഡൻ / ജിപ്സം)')),
                            DropdownMenuItem(value: 'Center Steel Ceiling', child: Text('Center Steel Ceiling (സ്റ്റീൽ സീലിംഗ്)')),
                            DropdownMenuItem(value: 'Custom Center Design', child: Text('Custom Design (കസ്റ്റം)')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              room.centerType = val;
                              onChanged();
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: room.centerLengthController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'നീളം (Length)',
                              border: OutlineInputBorder(),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            ),
                            onChanged: (val) {
                              room.centerLength = double.tryParse(val) ?? 0.0;
                              onChanged();
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: room.centerWidthController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'വീതി (Width)',
                              border: OutlineInputBorder(),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            ),
                            onChanged: (val) {
                              room.centerWidth = double.tryParse(val) ?? 0.0;
                              onChanged();
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 70,
                          child: TextField(
                            controller: room.centerQtyController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(
                              labelText: 'എണ്ണം (Qty)',
                              border: OutlineInputBorder(),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                            ),
                            onChanged: (val) {
                              room.centerQty = int.tryParse(val) ?? 1;
                              onChanged();
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // 4. Room Total Footer Bar
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              'Total: ${CalculatorUtils.formatNumber(room.calculatedSqFt)} Sq.Ft',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF15803D)),
                            ),
                            if (room.roomCount > 1)
                              Text(
                                ' (${room.roomCount} റൂമുകൾ)',
                                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                              ),
                          ],
                        ),
                        if (room.hasPlainCeiling || room.hasCove || room.hasCenterDesign)
                          Text(
                            '${room.hasPlainCeiling ? 'Plain: ${CalculatorUtils.formatNumber(room.plainSqFt)}' : ''}${room.hasCove ? '${room.hasPlainCeiling ? ' • ' : ''}Cove: ${CalculatorUtils.formatNumber(room.coveSqFt)}' : ''}${room.hasCenterDesign ? '${(room.hasPlainCeiling || room.hasCove) ? ' • ' : ''}Center: ${CalculatorUtils.formatNumber(room.centerSqFt)}' : ''}',
                            style: const TextStyle(fontSize: 9.5, color: Color(0xFF166534)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '₹${CalculatorUtils.formatIndianCurrency(totalRoomAmount)}',
                          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: Color(0xFF15803D)),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: room.isHidden ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          room.isHidden ? 'PDF Hidden' : 'In PDF',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: room.isHidden ? Colors.red.shade700 : const Color(0xFF166534),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
