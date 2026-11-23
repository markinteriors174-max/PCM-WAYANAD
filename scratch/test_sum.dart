import '../lib/models/quotation.dart';

void main() {
  final List<MaterialAssignment> materials = [
    MaterialAssignment(
      materialName: 'C-Channel (Ceiling) - Room 1',
      unit: 'Nos',
      rate: 10.0,
      quantity: 5.0,
      amount: 50.0,
    ),
    MaterialAssignment(
      materialName: 'C-Channel (Ceiling) - Room 2',
      unit: 'Nos',
      rate: 10.0,
      quantity: 5.0,
      amount: 50.0,
    ),
  ];

  final Map<String, MaterialAssignment> grouped = {};
  
  for (var mat in materials) {
    String baseName = mat.materialName;
    final dashIdx = mat.materialName.indexOf(' - ');
    if (dashIdx != -1) {
      baseName = mat.materialName.substring(0, dashIdx).trim();
    }
    
    final qty = mat.quantity.isFinite ? mat.quantity : 0.0;
    final amt = mat.amount.isFinite ? mat.amount : 0.0;
    
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

  for (var entry in grouped.entries) {
    print('Key: ${entry.key}, Qty: ${entry.value.quantity}, Amt: ${entry.value.amount}');
  }
}
