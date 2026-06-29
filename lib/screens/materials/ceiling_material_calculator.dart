/// Calculates ceiling material requirements based on room dimensions and ceiling type.
/// Supported types: 'Gypsum Ceiling', 'PVC Ceiling'
/// Returns null if ceilingType is unrecognised.
Map<String, dynamic>? calculateCeilingMaterials(
  double roomLength,
  double roomWidth,
  String ceilingType,
) {
  final double area = roomLength * roomWidth;
  final double perimeter = 2 * (roomLength + roomWidth);
  List<Map<String, dynamic>> items = [];

  if (ceilingType == 'Gypsum Ceiling') {
    final int sheets       = ((area / 24) * 1.12).ceil();
    final int lAngle       = (((perimeter * 5) / 12) * 1.15).ceil();
    final int intermediate = ((area * 0.52) / 12).ceil();
    final int section      = ((area * 0.75) / 12).ceil();
    final int bolts        = (area / 6.25).ceil();
    final int screws       = ((area * 2) / 500).ceil();
    final int putty        = ((area / 100) * 5.5).ceil();
    final int tape         = (area / 180).ceil();
    items = [
      {'name': 'Gypsum Board (12 MM - 6x4 Ft)',       'qty': sheets,       'unit': 'Nos'},
      {'name': 'L Angle (Cove 5-Line System)',          'qty': lAngle,       'unit': 'Nos'},
      {'name': 'Intermediate Channel (12 Ft)',          'qty': intermediate, 'unit': 'Nos'},
      {'name': 'Ceiling Section (Cross Channel)',       'qty': section,      'unit': 'Nos'},
      {'name': 'Anchor Bolts / Fasteners',             'qty': bolts,        'unit': 'Nos'},
      {'name': 'Drywall Screws (25 mm)',               'qty': screws,       'unit': 'Box'},
      {'name': 'Gypsum Jointing Powder (Putty)',       'qty': putty,        'unit': 'Kg'},
      {'name': 'Fiber Joint Tape',                     'qty': tape,         'unit': 'Rolls'},
    ];
  } else if (ceilingType == 'PVC Ceiling') {
    final int panels       = ((area / 8.33) * 1.12).ceil();
    final int pvcPerimeter = ((perimeter / 10) * 1.10).ceil();
    final double gridLength =
        (roomLength * (roomWidth / 2).ceil()) +
        (roomWidth * (roomLength / 2).ceil());
    final int framework = ((gridLength / 12) * 1.10).ceil();
    final int pvcScrews = ((area * 2.5) / 500).ceil();
    items = [
      {'name': 'PVC Ceiling Panels (10 Ft x 10 Inch)', 'qty': panels,       'unit': 'Nos'},
      {'name': 'PVC Perimeter / Border Profile',        'qty': pvcPerimeter, 'unit': 'Nos'},
      {'name': 'Heavy Framework Section (12 Ft)',       'qty': framework,    'unit': 'Nos'},
      {'name': 'PVC Star Screws & Fasteners',           'qty': pvcScrews,   'unit': 'Box'},
    ];
  } else {
    return null;
  }

  return {
    'ceiling_type':  ceilingType,
    'calculated_at': DateTime.now().toString(),
    'materials':     items,
  };
}
