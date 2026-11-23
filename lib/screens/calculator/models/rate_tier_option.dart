import 'package:flutter/material.dart';

class RateTierOption {
  final String label;
  final TextEditingController rateController;
  bool isOverridden;

  RateTierOption({
    required this.label,
    TextEditingController? rateController,
    this.isOverridden = false,
  }) : rateController = rateController ?? TextEditingController();

  double get rate => double.tryParse(rateController.text) ?? 0.0;
}

enum PdfPackageDisplayMode {
  all,
  standardOnly,
  premiumOnly,
  luxuryOnly,
  none,
}
