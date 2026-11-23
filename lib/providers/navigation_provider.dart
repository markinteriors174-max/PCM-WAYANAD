import 'package:flutter/material.dart';

class NavigationProvider extends ChangeNotifier {
  int _selectedIndex = 0; // Default to Home
  int get selectedIndex => _selectedIndex;

  bool _showAdminDashboard = false;
  bool get showAdminDashboard => _showAdminDashboard;

  void setTab(int index) {
    if (index != 0) {
      _showAdminDashboard = false;
    } else if (_showAdminDashboard) {
      _showAdminDashboard = false;
    }
    _selectedIndex = index;
    notifyListeners();
  }

  void openAdminDashboard() {
    _selectedIndex = 0;
    _showAdminDashboard = true;
    notifyListeners();
  }

  void closeAdminDashboard() {
    _showAdminDashboard = false;
    notifyListeners();
  }

  void toggleAdminDashboard() {
    _selectedIndex = 0;
    _showAdminDashboard = !_showAdminDashboard;
    notifyListeners();
  }

  void switchToCalculator() {
    setTab(2);
  }

  void switchToHistory() {
    setTab(1);
  }
}
