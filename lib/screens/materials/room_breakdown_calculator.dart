import 'package:flutter/material.dart';

class MaterialRoomBreakdown {
  final TextEditingController roomController;
  final TextEditingController qtyController;
  final TextEditingController rateController;

  MaterialRoomBreakdown({
    required String room,
    required String qty,
    required String rate,
  })  : roomController = TextEditingController(text: room),
        qtyController = TextEditingController(text: qty),
        rateController = TextEditingController(text: rate);

  void dispose() {
    roomController.dispose();
    qtyController.dispose();
    rateController.dispose();
  }
}

class RoomBreakdownWidget extends StatelessWidget {
  final List<MaterialRoomBreakdown> breakdowns;
  final VoidCallback onChanged;
  final VoidCallback onAdd;
  final Function(int) onDelete;

  const RoomBreakdownWidget({
    super.key,
    required this.breakdowns,
    required this.onChanged,
    required this.onAdd,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...breakdowns.asMap().entries.map((entry) {
            final idx = entry.key;
            final b = entry.value;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: SizedBox(
                      height: 30,
                      child: TextField(
                        controller: b.roomController,
                        style: const TextStyle(fontSize: 10),
                        decoration: InputDecoration(
                          hintText: 'Room Name',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        onChanged: (_) => onChanged(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 30,
                      child: TextField(
                        controller: b.qtyController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green),
                        decoration: InputDecoration(
                          hintText: 'Qty',
                          contentPadding: const EdgeInsets.all(4),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        onChanged: (_) => onChanged(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    flex: 1,
                    child: InkWell(
                      onTap: () => onDelete(idx),
                      borderRadius: BorderRadius.circular(4),
                      child: const SizedBox(
                        height: 30,
                        child: Center(
                          child: Icon(Icons.delete_outline, size: 16, color: Colors.red),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 4),
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 14),
            label: const Text('ADD ROOM BREAKDOWN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}
