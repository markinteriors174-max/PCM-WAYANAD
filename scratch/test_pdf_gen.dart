import 'dart:async';
import '../lib/models/quotation.dart';

class MockItem {
  final String name;
  final String unit;
  final double rate;
  MockItem(this.name, this.unit, this.rate);
}

void main() {
  // Mock dictionary
  final Map<String, List<MockItem>> materialDictionary = {
    'Ceiling': [
      MockItem('Intermediate Channel (Main Channel)', 'Nos', 90.0),
      MockItem('Perimeter Channel (Wall Channel)', 'Nos', 80.0),
    ]
  };

  // Mock controllers/breakdowns
  final Map<String, List<Map<String, String>>> roomBreakdownsInput = {
    'Ceiling||Intermediate Channel (Main Channel)': [
      {'room': 'Room 1', 'qty': '5.0', 'rate': '90.0'},
      {'room': 'Room 2', 'qty': '5.0', 'rate': '90.0'},
    ]
  };

  // Build activeMaterials like in _generateDispatchPdf
  final List<MaterialAssignment> activeMaterials = [];

  materialDictionary.forEach((categoryName, items) {
    for (var item in items) {
      final key = '$categoryName||${item.name}';
      final breakdowns = roomBreakdownsInput[key];
      
      if (breakdowns != null && breakdowns.isNotEmpty) {
        print('Simulating key: $key, found ${breakdowns.length} breakdowns.');
        for (var b in breakdowns) {
          final qty = double.tryParse(b['qty'] ?? '0.0') ?? 0.0;
          print('Breakdown room: ${b['room']}, qty: $qty');
          if (qty > 0) {
            final rate = double.tryParse(b['rate'] ?? '0.0') ?? item.rate;
            final roomName = b['room'] ?? '';
            final matName = roomName.isNotEmpty
                ? '${item.name} ($categoryName) - $roomName'
                : '${item.name} ($categoryName)';
                
            activeMaterials.add(MaterialAssignment(
              materialName: matName,
              unit: item.unit,
              rate: rate,
              quantity: qty,
              amount: qty * rate,
            ));
          }
        }
      }
    }
  });

  print('\nActive Materials built:');
  for (var mat in activeMaterials) {
    print('  Material: ${mat.materialName}, Qty: ${mat.quantity}');
  }

  // Now run the grouping logic from buildMaterialsTable
  final Map<String, MaterialAssignment> grouped = {};
  
  for (var mat in activeMaterials) {
    String baseName = mat.materialName;
    final dashIdx = mat.materialName.lastIndexOf(' - '); // Let's test lastIndexOf
    if (dashIdx != -1) {
      baseName = mat.materialName.substring(0, dashIdx).trim();
    }
    
    final qty = mat.quantity;
    final amt = mat.amount;
    
    if (grouped.containsKey(baseName)) {
      final existing = grouped[baseName]!;
      grouped[baseName] = MaterialAssignment(
        materialName: baseName,
        unit: mat.unit,
        rate: mat.rate,
        quantity: existing.quantity + qty,
        amount: existing.amount + amt,
      );
    } else {
      grouped[baseName] = MaterialAssignment(
        materialName: baseName,
        unit: mat.unit,
        rate: mat.rate,
        quantity: qty,
        amount: amt,
      );
    }
  }

  print('\nConsolidated Grouped Materials:');
  grouped.forEach((key, val) {
    print('  Base Material: $key, Total Qty: ${val.quantity}');
  });
}
