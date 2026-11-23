import '../models/quotation.dart';

class MaterialEngine {
  static List<MaterialAssignment> calculateBOM(List<QuotationItem> items) {
    double totalArea = 0;
    double totalPerimeter = 0;
    
    for (var item in items) {
      totalArea += item.area;
      // Approximate perimeter for channel calculation: 2 * (L+W)
      totalPerimeter += (item.length + item.width) * 2;
    }

    // Formulas based on PCM standard (Approximate)
    // 1 Board = 24 SqFt (4x6)
    double boards = (totalArea / 24).ceilToDouble();
    
    // Channels: Standard multipliers
    double mainC = (totalArea / 12).ceilToDouble(); // Estimated
    double perimeter = (totalPerimeter / 10).ceilToDouble(); // 10ft length
    
    // Screws: ~30 per board
    double screws = (boards * 30).ceilToDouble();
    
    // Putty: ~0.5kg per board
    double putty = (boards * 0.5).ceilToDouble();

    return [
      MaterialAssignment(
        materialName: 'Gypsum Board (4x6)',
        unit: 'Nos',
        rate: 0, // Rate is managed in Master Rates
        quantity: boards,
        amount: 0,
      ),
      MaterialAssignment(
        materialName: 'Main C Channel',
        unit: 'Nos',
        rate: 0,
        quantity: mainC,
        amount: 0,
      ),
      MaterialAssignment(
        materialName: 'Perimeter Channel',
        unit: 'Nos',
        rate: 0,
        quantity: perimeter,
        amount: 0,
      ),
      MaterialAssignment(
        materialName: 'Drywall Screws',
        unit: 'Pkt',
        rate: 0,
        quantity: (screws / 100).ceilToDouble(),
        amount: 0,
      ),
      MaterialAssignment(
        materialName: 'Joint Filler / Putty',
        unit: 'Kg',
        rate: 0,
        quantity: putty,
        amount: 0,
      ),
    ];
  }
}
