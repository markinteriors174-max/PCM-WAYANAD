import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import 'worker_home_screen.dart';
import 'widgets/admin_home_screen.dart';
import 'widgets/generic_placeholder_dashboard.dart';
import '../clients/client_project_hub_screen.dart';

import '../auth/portal_login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AuthService.instance,
      builder: (context, _) {
        final userData = AuthService.instance.userData;
        
        if (userData == null) {
          return const PortalLoginScreen();
        }

        if (kIsWeb) {
          // Force Client View on Web Portal, even if Admin logs in (Staff must use Mobile App)
          return const ClientProjectHubScreen();
        }

        switch (userData.role) {
          case UserRole.admin:
            return const AdminHomeScreen();
          case UserRole.worker:
            return const WorkerHomeScreen();
          case UserRole.agent:
            return const GenericPlaceholderDashboard(title: 'AGENT DASHBOARD');
          case UserRole.client:
            return const ClientProjectHubScreen();
        }
      },
    );
  }
}
