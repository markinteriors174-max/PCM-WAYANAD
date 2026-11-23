import 'package:flutter/material.dart';
import '../../models/room_data.dart';

/// Explicit numbered pagination and step-by-step navigation bar widget
/// for jumping between rooms or viewing all rooms simultaneously.
class SiteMeasurementPaginationBar extends StatelessWidget {
  final List<RoomData> rooms;
  final int selectedPageIndex; // 0 = All Rooms, 1 = Room 1 (index 0), 2 = Room 2 (index 1), ...
  final ValueChanged<int> onPageSelected;

  const SiteMeasurementPaginationBar({
    super.key,
    required this.rooms,
    required this.selectedPageIndex,
    required this.onPageSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (rooms.isEmpty) return const SizedBox.shrink();

    final totalPages = rooms.length; // 1-based index 1..totalPages for individual rooms
    final isAllRooms = selectedPageIndex == 0;
    final currentRoomIndex = isAllRooms ? 0 : (selectedPageIndex - 1).clamp(0, totalPages - 1);
    final currentRoom = rooms[currentRoomIndex];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.5), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Step navigation header with Prev / Next controls
          Row(
            children: [
              // Previous Step Button
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded, size: 16),
                color: selectedPageIndex > 0 ? const Color(0xFF0284C7) : Colors.grey.shade400,
                tooltip: 'മുൻപത്തെ റൂം (Previous)',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: selectedPageIndex > 0
                    ? () => onPageSelected(selectedPageIndex - 1)
                    : null,
              ),

              // Title and Page Info
              Expanded(
                child: Column(
                  children: [
                    Text(
                      isAllRooms
                          ? 'എല്ലാ റൂമുകളും (All ${rooms.length} Rooms)'
                          : 'STEP $selectedPageIndex of $totalPages • ${currentRoom.roomName}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                        color: Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isAllRooms
                          ? 'റൂം അളവുകൾ താഴെ തന്നിരിക്കുന്നു'
                          : '#${currentRoom.roomNumber} (${currentRoom.floor}) • ${currentRoom.calculatedSqFt.toStringAsFixed(1)} SQFT',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0284C7),
                      ),
                    ),
                  ],
                ),
              ),

              // Next Step Button
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                color: selectedPageIndex < totalPages ? const Color(0xFF0284C7) : Colors.grey.shade400,
                tooltip: 'അടുത്ത റൂം (Next)',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: selectedPageIndex < totalPages
                    ? () => onPageSelected(selectedPageIndex + 1)
                    : null,
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Explicit Numbered Step Buttons / Navigation Bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                // 'ALL' button
                Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: InkWell(
                    onTap: () => onPageSelected(0),
                    borderRadius: BorderRadius.circular(8),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isAllRooms ? const Color(0xFF0284C7) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isAllRooms ? const Color(0xFF0284C7) : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.view_headline_rounded,
                            size: 13,
                            color: isAllRooms ? Colors.white : const Color(0xFF334155),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'ALL (${rooms.length})',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: isAllRooms ? Colors.white : const Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Numbered Room Step Buttons
                ...List.generate(totalPages, (i) {
                  final pageNum = i + 1;
                  final isCurrent = selectedPageIndex == pageNum;
                  final r = rooms[i];
                  return Padding(
                    padding: const EdgeInsets.only(right: 5.0),
                    child: InkWell(
                      onTap: () => onPageSelected(pageNum),
                      borderRadius: BorderRadius.circular(8),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isCurrent ? const Color(0xFF0284C7) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isCurrent ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0),
                            width: isCurrent ? 1.5 : 1.0,
                          ),
                          boxShadow: isCurrent
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF0284C7).withValues(alpha: 0.25),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: isCurrent ? Colors.white.withValues(alpha: 0.25) : const Color(0xFFE2E8F0),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '$pageNum',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: isCurrent ? Colors.white : const Color(0xFF475569),
                                ),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              r.roomName,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: isCurrent ? Colors.white : const Color(0xFF1E293B),
                              ),
                            ),
                            if (r.calculatedSqFt > 0) ...[
                              const SizedBox(width: 4),
                              Text(
                                '${r.calculatedSqFt.toStringAsFixed(0)} SQFT',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: isCurrent ? Colors.white.withValues(alpha: 0.85) : const Color(0xFF16A34A),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
