import 'package:flutter/material.dart';
import '../../models/room_data.dart';
import '../../../../utils/calculator_utils.dart';

/// Center Design Group Section Widget
class SiteMeasurementCenterGroupWidget extends StatelessWidget {
  final List<RoomData> rooms;
  final VoidCallback onChanged;
  final VoidCallback onBulkCenterDialogRequested;

  const SiteMeasurementCenterGroupWidget({
    super.key,
    required this.rooms,
    required this.onChanged,
    required this.onBulkCenterDialogRequested,
  });

  @override
  Widget build(BuildContext context) {
    final centerRooms = rooms.where((r) => r.hasCenterDesign).toList();
    final double totalCenterSqFt = rooms.fold(0.0, (sum, r) => sum + r.centerSqFt);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF5FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDD6FE), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFEDE9FE),
              borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.center_focus_strong, color: Color(0xFF7C3AED), size: 17),
                      const SizedBox(width: 6),
                      const Flexible(
                        child: Text(
                          'സെന്റർ ഡിസൈൻ ഗ്രൂപ്പ് (Center Design)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFF5B21B6)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${centerRooms.length}/${rooms.length}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10.5, color: Color(0xFF5B21B6)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (totalCenterSqFt > 0)
                      Text(
                        '${CalculatorUtils.formatNumber(totalCenterSqFt)} SqFt  ',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11.5, color: Color(0xFF7C3AED)),
                      ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      icon: const Icon(Icons.tune, size: 12),
                      label: const Text('ബൾക്ക് സെറ്റിംഗ്സ്', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                      onPressed: onBulkCenterDialogRequested,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Action Toolbar for Center Design
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    centerRooms.isEmpty
                        ? 'റൂമുകളിലൊന്നും സെന്റർ ഡിസൈൻ മാർക്ക് ചെയ്തിട്ടില്ല'
                        : '${centerRooms.length} റൂമുകളിൽ സെന്റർ ഡിസൈൻ സജീവമാണ്:',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF6D28D9), fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  children: [
                    InkWell(
                      onTap: () {
                        for (var r in rooms) {
                          r.hasCenterDesign = true;
                          if (r.centerLengthController.text.isEmpty) {
                            r.centerLength = 0.0;
                            r.centerLengthController.text = '';
                            r.centerWidth = 0.0;
                            r.centerWidthController.text = '';
                          }
                        }
                        onChanged();
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Text('+ Mark All', style: TextStyle(fontSize: 11, color: Color(0xFF7C3AED), fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const Text(' | ', style: TextStyle(color: Color(0xFFDDD6FE))),
                    InkWell(
                      onTap: () {
                        for (var r in rooms) {
                          r.hasCenterDesign = false;
                        }
                        onChanged();
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Text('Clear', style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFDDD6FE)),

          // Rooms in Center Group
          if (centerRooms.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF7C3AED)),
                  foregroundColor: const Color(0xFF6D28D9),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                icon: const Icon(Icons.add_circle_outline, size: 16),
                label: const Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('എല്ലാ റൂമുകളിലും സെന്റർ ഡിസൈൻ മാർക്ക് ചെയ്യുക (Enable Center All)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
                onPressed: () {
                  for (var r in rooms) {
                    r.hasCenterDesign = true;
                    if (r.centerLengthController.text.isEmpty) {
                      r.centerLength = 0.0;
                      r.centerLengthController.text = '';
                      r.centerWidth = 0.0;
                      r.centerWidthController.text = '';
                    }
                  }
                  onChanged();
                },
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: centerRooms.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFEDE9FE)),
              itemBuilder: (ctx, i) {
                final r = centerRooms[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: Checkbox(
                          value: r.hasCenterDesign,
                          activeColor: const Color(0xFF7C3AED),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          onChanged: (v) {
                            r.hasCenterDesign = v ?? false;
                            onChanged();
                          },
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${r.roomName} #${r.roomNumber}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: Color(0xFF1E293B)),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${CalculatorUtils.formatNumber(r.centerSqFt)} SqFt',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Color(0xFF7C3AED)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        flex: 3,
                        child: Container(
                          height: 32,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFC4B5FD)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: ['Center Design', 'Center Steel Ceiling', 'Custom Center Design'].contains(r.centerType)
                                  ? r.centerType
                                  : 'Center Design',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF5B21B6)),
                              items: const [
                                DropdownMenuItem(value: 'Center Design', child: Text('Center Design', overflow: TextOverflow.ellipsis)),
                                DropdownMenuItem(value: 'Center Steel Ceiling', child: Text('Steel Ceiling', overflow: TextOverflow.ellipsis)),
                                DropdownMenuItem(value: 'Custom Center Design', child: Text('Custom Design', overflow: TextOverflow.ellipsis)),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  r.centerType = val;
                                  onChanged();
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: r.centerLengthController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'നീളം',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                            isDense: true,
                          ),
                          onChanged: (v) {
                            r.centerLength = double.tryParse(v) ?? 0.0;
                            onChanged();
                          },
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: r.centerWidthController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'വീതി',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                            isDense: true,
                          ),
                          onChanged: (v) {
                            r.centerWidth = double.tryParse(v) ?? 0.0;
                            onChanged();
                          },
                        ),
                      ),
                      const SizedBox(width: 4),
                      SizedBox(
                        width: 42,
                        child: TextField(
                          controller: r.centerQtyController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            labelText: 'Qty',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                            isDense: true,
                          ),
                          onChanged: (v) {
                            r.centerQty = int.tryParse(v) ?? 1;
                            onChanged();
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
