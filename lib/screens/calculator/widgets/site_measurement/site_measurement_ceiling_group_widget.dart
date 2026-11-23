import 'package:flutter/material.dart';
import '../../models/room_data.dart';
import '../../../../utils/calculator_utils.dart';

/// Ceiling Design Group Section Widget
class SiteMeasurementCeilingGroupWidget extends StatelessWidget {
  final List<RoomData> rooms;
  final VoidCallback onChanged;
  final VoidCallback onBulkCeilingDialogRequested;

  const SiteMeasurementCeilingGroupWidget({
    super.key,
    required this.rooms,
    required this.onChanged,
    required this.onBulkCeilingDialogRequested,
  });

  @override
  Widget build(BuildContext context) {
    final plainRooms = rooms.where((r) => r.hasPlainCeiling).toList();
    final double totalPlainSqFt = rooms.fold(0.0, (sum, r) => sum + r.plainSqFt);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBAE6FD), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.05),
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFE0F2FE),
              borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.crop_landscape, color: Color(0xFF0284C7), size: 18),
                      const SizedBox(width: 8),
                      const Flexible(
                        child: Text(
                          'സീലിംഗ് ഡിസൈൻ ഗ്രൂപ്പ് (Ceiling Design)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0369A1)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${plainRooms.length} / ${rooms.length}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF0369A1)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (totalPlainSqFt > 0)
                      Text(
                        '${CalculatorUtils.formatNumber(totalPlainSqFt)} SqFt  ',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFF0284C7)),
                      ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      icon: const Icon(Icons.tune, size: 13),
                      label: const Text('ബൾക്ക് സെറ്റിംഗ്സ്', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      onPressed: onBulkCeilingDialogRequested,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Action Toolbar for Ceiling
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    plainRooms.isEmpty
                        ? 'പ്ലെയിൻ സീലിംഗ് ഡിസൈൻ ഒഴിവാക്കി'
                        : '${plainRooms.length} റൂമുകളിൽ പ്ലെയിൻ സീലിംഗ് സജീവമാണ്:',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF0369A1), fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () {
                        for (var r in rooms) {
                          r.hasPlainCeiling = true;
                        }
                        onChanged();
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Text('+ Mark All', style: TextStyle(fontSize: 11, color: Color(0xFF0284C7), fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const Text(' | ', style: TextStyle(color: Color(0xFFBAE6FD))),
                    InkWell(
                      onTap: () {
                        for (var r in rooms) {
                          r.hasPlainCeiling = false;
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
          const Divider(height: 1, color: Color(0xFFBAE6FD)),

          // Rooms in Plain Ceiling Group
          if (plainRooms.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF0284C7)),
                  foregroundColor: const Color(0xFF0369A1),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                icon: const Icon(Icons.add_circle_outline, size: 16),
                label: const Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('എല്ലാ റൂമുകളിലും പ്ലെയിൻ സീലിംഗ് മാർക്ക് ചെയ്യുക (Enable Ceiling All)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
                onPressed: () {
                  for (var r in rooms) {
                    r.hasPlainCeiling = true;
                  }
                  onChanged();
                },
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: plainRooms.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFE0F2FE)),
              itemBuilder: (ctx, i) {
                final r = plainRooms[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: Checkbox(
                          value: r.hasPlainCeiling,
                          activeColor: const Color(0xFF0284C7),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          onChanged: (v) {
                            r.hasPlainCeiling = v ?? false;
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
                              '${CalculatorUtils.formatNumber(r.plainSqFt)} SqFt',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Color(0xFF0284C7)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: r.widthController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'വീതി',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                            isDense: true,
                          ),
                          onChanged: (v) {
                            r.width = double.tryParse(v) ?? 0.0;
                            onChanged();
                          },
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: r.lengthController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'നീളം',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                            isDense: true,
                          ),
                          onChanged: (v) {
                            r.length = double.tryParse(v) ?? 0.0;
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
