import '../../../models/quotation.dart';

class PdfDesignCategoryHelper {
  static String getDesignCategory(QuotationItem item) {
    if (item.hasCove || item.designName.toLowerCase().contains('cove')) {
      return 'Cove Design';
    } else if (item.hasCentralDesign) {
      final name = item.designName.toLowerCase();
      if (name.contains('round') || name.contains('curve') || name.contains('custom') || name.contains('circle') || name.contains('radius')) {
        return 'Round Design';
      } else {
        return 'Center Design';
      }
    } else {
      return 'Plain Design';
    }
  }
}
