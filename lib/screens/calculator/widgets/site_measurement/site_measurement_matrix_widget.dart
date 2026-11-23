import 'package:flutter/material.dart';
import '../../models/room_data.dart';
import '../../../../utils/calculator_utils.dart';

/// Design Marking Matrix Widget to quickly toggle ceiling designs across rooms in bulk.
class SiteMeasurementMatrixWidget extends StatelessWidget {
  final List<RoomData> rooms;
  final VoidCallback onChanged;

  const SiteMeasurementMatrixWidget({
    super.key,
    required this.rooms,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final allPlain = rooms.isNotEmpty && rooms.every((r) => r.hasPlainCeiling);
    final allCove = rooms.isNotEmpty && rooms.every((r) => r.hasCove);
    final allCenter = rooms.isNotEmpty && rooms.every((r) => r.hasCenterDesign);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: const [
                      Icon(Icons.grid_view_rounded, color: Colors.amber, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'ഡിസൈൻ മാർക്കിംഗ് മാട്രിക്സ് (Design Marking Matrix)',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${rooms.length} റൂമുകൾ',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // Sub-bar with instructions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: const Color(0xFFF8FAFC),
            child: const Text(
              '💡 ഓരോ റൂമിലും വെവ്വേറെ പോകാതെ ഇവിടെനിന്ന് ഒറ്റ ക്ലിക്കിൽ ഡിസൈനുകൾ ഗ്രൂപ്പായി മാർക്ക് ചെയ്യാം:',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Column Titles with Master Checkboxes
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            color: const Color(0xFFF1F5F9),
            child: Row(
              children: [
                const Expanded(
                  flex: 4,
                  child: Text(
                    'റൂം (Room)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: Color(0xFF334155)),
                  ),
                ),
                // Plain Ceiling Column Master
                Expanded(
                  flex: 3,
                  child: InkWell(
                    onTap: () {
                      final newVal = !allPlain;
                      for (var r in rooms) {
                        r.hasPlainCeiling = newVal;
                      }
                      onChanged();
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: Checkbox(
                            value: allPlain,
                            tristate: rooms.any((r) => r.hasPlainCeiling) && !allPlain,
                            activeColor: const Color(0xFF0284C7),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            onChanged: (v) {
                              final newVal = v ?? false;
                              for (var r in rooms) {
                                r.hasPlainCeiling = newVal;
                              }
                              onChanged();
                            },
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'പ്ലെയ്ൻ (Plain)',
                              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Cove Light Column Master
                Expanded(
                  flex: 3,
                  child: InkWell(
                    onTap: () {
                      final newVal = !allCove;
                      for (var r in rooms) {
                        r.hasCove = newVal;
                        if (newVal && r.coveLengthController.text.isEmpty) {
                          r.coveLength = r.effectiveLength;
                          r.coveLengthController.text = r.coveLength > 0 ? r.coveLength.toString() : '';
                          r.coveWidth = 0.0;
                          r.coveWidthController.text = '';
                        }
                      }
                      onChanged();
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: Checkbox(
                            value: allCove,
                            tristate: rooms.any((r) => r.hasCove) && !allCove,
                            activeColor: const Color(0xFFD97706),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            onChanged: (v) {
                              final newVal = v ?? false;
                              for (var r in rooms) {
                                r.hasCove = newVal;
                                if (newVal && r.coveLengthController.text.isEmpty) {
                                  r.coveLength = r.effectiveLength;
                                  r.coveLengthController.text = r.coveLength > 0 ? r.coveLength.toString() : '';
                                  r.coveWidth = 0.0;
                                  r.coveWidthController.text = '';
                                }
                              }
                              onChanged();
                            },
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'കോവ് (Cove)',
                              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Center Design Column Master
                Expanded(
                  flex: 3,
                  child: InkWell(
                    onTap: () {
                      final newVal = !allCenter;
                      for (var r in rooms) {
                        r.hasCenterDesign = newVal;
                        if (newVal && r.centerLengthController.text.isEmpty) {
                          r.centerLength = 0.0;
                          r.centerLengthController.text = '';
                          r.centerWidth = 0.0;
                          r.centerWidthController.text = '';
                        }
                      }
                      onChanged();
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: Checkbox(
                            value: allCenter,
                            tristate: rooms.any((r) => r.hasCenterDesign) && !allCenter,
                            activeColor: const Color(0xFF7C3AED),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            onChanged: (v) {
                              final newVal = v ?? false;
                              for (var r in rooms) {
                                r.hasCenterDesign = newVal;
                                if (newVal && r.centerLengthController.text.isEmpty) {
                                  r.centerLength = 0.0;
                                  r.centerLengthController.text = '';
                                  r.centerWidth = 0.0;
                                  r.centerWidthController.text = '';
                                }
                              }
                              onChanged();
                            },
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'സെന്റർ (Center)',
                              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFCBD5E1)),

          // Rows for each room
          for (int i = 0; i < rooms.length; i++) ...[
            _buildMatrixRow(rooms[i], i),
            if (i < rooms.length - 1)
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
          ],
        ],
      ),
    );
  }

  Widget _buildMatrixRow(RoomData room, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      color: index % 2 == 0 ? Colors.white : const Color(0xFFFAFAFA),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        room.roomName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: Color(0xFF0F172A)),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${CalculatorUtils.formatNumber(room.calculatedSqFt)} Sq.Ft',
                        style: const TextStyle(fontSize: 9.5, color: Color(0xFF16A34A), fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // 1. Plain Toggle Box
          Expanded(
            flex: 3,
            child: InkWell(
              onTap: () {
                room.hasPlainCeiling = !room.hasPlainCeiling;
                onChanged();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: room.hasPlainCeiling ? const Color(0xFFF0F9FF) : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: room.hasPlainCeiling ? const Color(0xFFBAE6FD) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
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
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        room.hasPlainCeiling ? '${CalculatorUtils.formatNumber(room.plainSqFt)}' : 'Off',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: room.hasPlainCeiling ? FontWeight.bold : FontWeight.normal,
                          color: room.hasPlainCeiling ? const Color(0xFF0369A1) : const Color(0xFF94A3B8),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          // 2. Cove Toggle Box
          Expanded(
            flex: 3,
            child: InkWell(
              onTap: () {
                room.hasCove = !room.hasCove;
                if (room.hasCove && room.coveLengthController.text.isEmpty) {
                  room.coveLength = room.effectiveLength;
                  room.coveLengthController.text = room.coveLength > 0 ? room.coveLength.toString() : '';
                  room.coveWidth = 0.0;
                  room.coveWidthController.text = '';
                }
                onChanged();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: room.hasCove ? const Color(0xFFFFFBEB) : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: room.hasCove ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: Checkbox(
                        value: room.hasCove,
                        activeColor: const Color(0xFFD97706),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        onChanged: (v) {
                          room.hasCove = v ?? false;
                          if (room.hasCove && room.coveLengthController.text.isEmpty) {
                            room.coveLength = room.effectiveLength;
                            room.coveLengthController.text = room.coveLength > 0 ? room.coveLength.toString() : '';
                            room.coveWidth = 0.0;
                            room.coveWidthController.text = '';
                          }
                          onChanged();
                        },
                      ),
                    ),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        room.hasCove ? '${CalculatorUtils.formatNumber(room.coveSqFt)}' : 'Off',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: room.hasCove ? FontWeight.bold : FontWeight.normal,
                          color: room.hasCove ? const Color(0xFFB45309) : const Color(0xFF94A3B8),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          // 3. Center Toggle Box
          Expanded(
            flex: 3,
            child: InkWell(
              onTap: () {
                room.hasCenterDesign = !room.hasCenterDesign;
                if (room.hasCenterDesign && room.centerLengthController.text.isEmpty) {
                  room.centerLength = 0.0;
                  room.centerLengthController.text = '';
                  room.centerWidth = 0.0;
                  room.centerWidthController.text = '';
                }
                onChanged();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: room.hasCenterDesign ? const Color(0xFFF5F3FF) : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: room.hasCenterDesign ? const Color(0xFFDDD6FE) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
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
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        room.hasCenterDesign ? '${CalculatorUtils.formatNumber(room.centerSqFt)}' : 'Off',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: room.hasCenterDesign ? FontWeight.bold : FontWeight.normal,
                          color: room.hasCenterDesign ? const Color(0xFF6D28D9) : const Color(0xFF94A3B8),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
