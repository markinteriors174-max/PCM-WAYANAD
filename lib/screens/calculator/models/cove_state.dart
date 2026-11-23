import 'package:flutter/material.dart';
import '../calculator_controller.dart';

enum ThreeCoveMode {
  plainCove,      // 1. Plain Inner Cove
  standaloneCove, // 2. Standalone Cove (Cove Design Ceiling)
  centerCove,     // 3. Center Cove (Inside Center Design)
}

class SingleCoveState {
  bool isActive = false;
  final TextEditingController lengthController = TextEditingController();
  final TextEditingController lengthHeightController = TextEditingController();
  final TextEditingController lengthQtyController = TextEditingController(text: '2');

  final TextEditingController widthController = TextEditingController();
  final TextEditingController widthHeightController = TextEditingController();
  final TextEditingController widthQtyController = TextEditingController(text: '2');

  final TextEditingController rateController = TextEditingController(text: '105');
  final List<CoveLightRow> extraRows = [];

  void dispose() {
    lengthController.dispose();
    lengthHeightController.dispose();
    lengthQtyController.dispose();
    widthController.dispose();
    widthHeightController.dispose();
    widthQtyController.dispose();
    rateController.dispose();
    for (var r in extraRows) {
      r.lengthController.dispose();
      r.widthController.dispose();
      r.quantityController.dispose();
    }
  }
}

class ThreeCovesManager {
  final SingleCoveState plainCove = SingleCoveState();
  final SingleCoveState standaloneCove = SingleCoveState();
  final SingleCoveState centerCove = SingleCoveState();

  SingleCoveState stateFor(ThreeCoveMode mode) {
    switch (mode) {
      case ThreeCoveMode.plainCove:
        return plainCove;
      case ThreeCoveMode.standaloneCove:
        return standaloneCove;
      case ThreeCoveMode.centerCove:
        return centerCove;
    }
  }

  bool appliesWidthDeduction(ThreeCoveMode mode) {
    return mode == ThreeCoveMode.plainCove || mode == ThreeCoveMode.standaloneCove;
  }

  bool copiesCenterDimensionsOnAdd(ThreeCoveMode mode) {
    return mode == ThreeCoveMode.centerCove;
  }

  void dispose() {
    plainCove.dispose();
    standaloneCove.dispose();
    centerCove.dispose();
  }
}
