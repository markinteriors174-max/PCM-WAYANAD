import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/navigation_provider.dart';
import 'widgets/admin_home_screen.dart';
import 'widgets/home_screen_admin_hub.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavigationProvider>();

    if (nav.showAdminDashboard) {
      return const AdminDashboardScreen();
    }
    return const AdminHomeScreen();
  }
}
