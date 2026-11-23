import 'package:flutter/material.dart';
import '../../models/room_data.dart';
import '../../../../utils/calculator_utils.dart';

/// Cove Design Group Section Widget
class SiteMeasurementCoveGroupWidget extends StatelessWidget {
  final List<RoomData> rooms;
  final VoidCallback onChanged;
  final VoidCallback onBulkCoveDialogRequested;

  const SiteMeasurementCoveGroupWidget({
    super.key,
    required this.rooms,
    required this.onChanged,
    required this.onBulkCoveDialogRequested,
  });

  @override
  Widget build(BuildContext context) {
    final coveRooms = rooms.where((r) => r.hasCove).toList();
    final double totalCoveSqFt = rooms.fold(0.0, (sum, r) => sum + r.coveSqFt);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.05),
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
              color: Color(0xFFFEF3C7),
              borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.lightbulb, color: Color(0xFFD97706), size: 17),
                      const SizedBox(width: 6),
                      const Flexible(
                        child: Text(
                          'കോവ് ഡിസൈൻ ഗ്രൂപ്പ് (Cove Design)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFF92400E)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD97706).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${coveRooms.length}/${rooms.length}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10.5, color: Color(0xFF92400E)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (totalCoveSqFt > 0)
                      Text(
                        '${CalculatorUtils.formatNumber(totalCoveSqFt)} SqFt  ',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11.5, color: Color(0xFFB45309)),
                      ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD97706),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      icon: const Icon(Icons.tune, size: 12),
                      label: const Text('ബൾക്ക് സെറ്റിംഗ്സ്', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                      onPressed: onBulkCoveDialogRequested,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Action Toolbar for Cove
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    coveRooms.isEmpty
                        ? 'റൂമുകളിലൊന്നും കോവ് മാർക്ക് ചെയ്തിട്ടില്ല'
                        : '${coveRooms.length} റൂമുകളിൽ കോവ് ലൈറ്റ് സജീവമാണ്:',
                    style: TextStyle(fontSize: 11, color: Colors.amber.shade900, fontWeight: FontWeight.w600),
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
                          r.hasCove = true;
                          if (r.coveLengthController.text.isEmpty) {
                            r.coveLength = r.effectiveLength;
                            r.coveLengthController.text = r.coveLength > 0 ? r.coveLength.toString() : '';
                            r.coveWidth = 1.0;
                            r.coveWidthController.text = '1.0';
                          }
                        }
                        onChanged();
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Text('+ Mark All', style: TextStyle(fontSize: 11, color: Color(0xFFD97706), fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const Text(' | ', style: TextStyle(color: Color(0xFFFDE68A))),
                    InkWell(
                      onTap: () {
                        for (var r in rooms) {
                          r.hasCove = false;
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
          const Divider(height: 1, color: Color(0xFFFDE68A)),

          // Rooms in Cove Group
          if (coveRooms.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFD97706)),
                  foregroundColor: const Color(0xFFB45309),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                icon: const Icon(Icons.add_circle_outline, size: 16),
                label: const Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('എല്ലാ റൂമുകളിലും കോവ് ലൈറ്റ് മാർക്ക് ചെയ്യുക (Enable Cove All)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
                onPressed: () {
                  for (var r in rooms) {
                    r.hasCove = true;
                    if (r.coveLengthController.text.isEmpty) {
                      r.coveLength = r.effectiveLength;
                      r.coveLengthController.text = r.coveLength > 0 ? r.coveLength.toString() : '';
                      r.coveWidth = 1.0;
                      r.coveWidthController.text = '1.0';
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
              itemCount: coveRooms.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFFEF3C7)),
              itemBuilder: (ctx, i) {
                final r = coveRooms[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: Checkbox(
                          value: r.hasCove,
                          activeColor: const Color(0xFFD97706),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          onChanged: (v) {
                            r.hasCove = v ?? false;
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
                              '${CalculatorUtils.formatNumber(r.coveSqFt)} SqFt',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Color(0xFFD97706)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: r.coveLengthController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'നീളം',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                            isDense: true,
                          ),
                          onChanged: (v) {
                            r.coveLength = double.tryParse(v) ?? 0.0;
                            onChanged();
                          },
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: r.coveWidthController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'ഡ്രോപ്പ്',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                            isDense: true,
                          ),
                          onChanged: (v) {
                            r.coveWidth = double.tryParse(v) ?? 0.0;
                            onChanged();
                          },
                        ),
                      ),
                      const SizedBox(width: 4),
                      SizedBox(
                        width: 46,
                        child: TextField(
                          controller: r.coveSidesController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            labelText: 'സൈഡ്',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                            isDense: true,
                          ),
                          onChanged: (v) {
                            r.coveSides = int.tryParse(v) ?? 4;
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
