void main() {
  final testCases = [
    'Intermediate Channel (Main Channel) (Ceiling) - Room 1',
    'Gypsum Board (12 mm - 6x4 Ft) (Gypsum Board Ceiling) - Room 2',
    'C-Channel (Ceiling) - Room 1',
    'Plain Material (No Category)',
  ];

  final regex = RegExp(r'^(.+)\s*\(([^)]+)\)(?:\s*-\s*(.+))?$');

  for (var t in testCases) {
    final match = regex.firstMatch(t);
    if (match != null) {
      print('Input: $t');
      print('  Group 1 (Base Name): ${match.group(1)}');
      print('  Group 2 (Category): ${match.group(2)}');
      print('  Group 3 (Room): ${match.group(3)}');
    } else {
      print('Input: $t -> NO MATCH');
    }
  }
}
