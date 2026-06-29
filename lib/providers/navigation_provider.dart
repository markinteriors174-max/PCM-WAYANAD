import 'package:flutter/material.dart';

class NavigationProvider extends ChangeNotifier {
  int _selectedIndex = 0; // Default to Home
  int get selectedIndex => _selectedIndex;

  // v3.0 FIX: Removed global PageController to prevent framework conflicts
  // Each PageView should manage its own controller lifecycle.

  void setTab(int index) {
    _selectedIndex = index;
    notifyListeners();
  }

  void switchToCalculator() {
    setTab(2);
  }

  void switchToHistory() {
    setTab(1);
  }
}
