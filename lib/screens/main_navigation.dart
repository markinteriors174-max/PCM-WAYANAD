import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'home/home_screen.dart';
import 'calculator/calculator_screen.dart';
import 'calculator/history_screen.dart';
import 'calculator/project_edit_controller.dart';
import 'calculator/widgets/qr_scanner_screen.dart';
import 'materials/material_list_screen.dart';
import '../theme/app_theme.dart';
import '../providers/language_provider.dart';
import '../providers/navigation_provider.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'settings/company_settings_screen.dart';
import 'clients/clients_screen.dart';
import 'labor/labor_management_screen.dart';
import 'auth/guest_welcome_screen.dart';
import 'auth/admin_login_screen.dart';

import '../services/web_update_service.dart';

class RoleNavigationShell extends StatefulWidget {
  static final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  const RoleNavigationShell({super.key});

  @override
  State<RoleNavigationShell> createState() => _RoleNavigationShellState();
}

class _RoleNavigationShellState extends State<RoleNavigationShell> {
  late PageController _pageController;
  late NavigationProvider _navigationProvider;

  @override
  void initState() {
    super.initState();
    _navigationProvider = Provider.of<NavigationProvider>(context, listen: false);
    _pageController = PageController(initialPage: _navigationProvider.selectedIndex);
    
    _navigationProvider.addListener(_handleNavChange);
    ProjectEditController.instance.addListener(_handleProjectEditRequest);
    
    _initDeepLinkingChannel();

    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        WebUpdateService.instance.init(context);
      });
    }
  }

  List<Widget> _getScreens(UserRole role) {
    if (kIsWeb) {
      // WEB APP: Strictly for Client Portal
      return [
        const HomeScreen(), // Switches to ClientProjectHubScreen inside
      ];
    }

    if (role == UserRole.admin) {
      return [
        const HomeScreen(),
        const HistoryScreen(),
        const CalculatorScreen(),
        const MaterialListScreen(),
      ];
    } else if (role == UserRole.worker) {
      return [
        const HomeScreen(),
        const LaborManagementScreen(), // Dynamic: Worker sees their hub here
        const MaterialListScreen(),
      ];
    } else {
      return [
        const HomeScreen(),
        const CalculatorScreen(),
      ];
    }
  }

  void _handleProjectEditRequest() {
    final pendingDispatchId = ProjectEditController.instance.pendingDispatchId;
    if (pendingDispatchId != null && mounted) {
      _navigationProvider.setTab(3); // Switch to materials tab
    }
  }

  void _initDeepLinkingChannel() {
    const platform = MethodChannel('com.example.pcm_wayanad/deeplink');
    platform.setMethodCallHandler((call) async {
      if (call.method == 'onDeepLinkReceived') {
        final Map<dynamic, dynamic>? data = call.arguments as Map<dynamic, dynamic>?;
        if (data != null) {
          _handleDeepLinkAction(data);
        }
      } else if (call.method == 'onProjectIdReceived') {
        final String? projectId = call.arguments as String?;
        if (projectId != null && projectId.isNotEmpty) {
          _handleDeepLinkAction({'action': 'project', 'projectId': projectId});
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final Map<dynamic, dynamic>? initialData = await platform.invokeMethod('getPendingAction');
        if (initialData != null) {
          _handleDeepLinkAction(initialData);
        }
      } catch (e) {
        debugPrint('Failed to get initial pending action: $e');
      }
    });
  }

  void _handleDeepLinkAction(Map<dynamic, dynamic> data) {
    final String? action = data['action'] as String?;
    final String? projectId = data['projectId'] as String?;

    if (action == 'project' && projectId != null) {
      _navigateToProject(projectId);
    } else if (action == 'calculator') {
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CalculatorScreen()),
        );
      }
    }
  }

  void _navigateToProject(String projectId) {
    ProjectEditController.instance.requestEdit(projectId);
    if (mounted) {
      Provider.of<NavigationProvider>(context, listen: false).setTab(2);
    }
  }

  void _handleNavChange() {
    final nav = _navigationProvider;
    final auth = context.read<AuthService>();
    final role = auth.userData?.role ?? UserRole.client;
    final screenCount = _getScreens(role).length;

    if (_pageController.hasClients) {
      int targetIndex = nav.selectedIndex;
      if (targetIndex >= screenCount) {
        targetIndex = 0;
      }

      if (_pageController.page?.round() != targetIndex) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_pageController.hasClients) {
            _pageController.jumpToPage(targetIndex);
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _navigationProvider.removeListener(_handleNavChange);
    ProjectEditController.instance.removeListener(_handleProjectEditRequest);
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final nav = context.watch<NavigationProvider>();
    final auth = context.watch<AuthService>();
    
    // v3.2 HOTFIX: Handle authentication routing
    if (auth.userData == null) {
      if (kIsWeb) {
        // Web: Show registration/portal options for clients
        return const GuestWelcomeScreen();
      } else {
        // Mobile: Show internal staff login directly
        return const AdminLoginScreen();
      }
    }

    final role = auth.userData!.role;
    final screens = _getScreens(role);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
      },
      child: Scaffold(
        key: RoleNavigationShell.scaffoldKey,
        backgroundColor: AppColors.background,
        drawer: _buildDrawer(lang, nav, auth),
        drawerEnableOpenDragGesture: false,
        drawerEdgeDragWidth: 0,
        body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: screens,
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.premiumGold, width: 2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: AppColors.premiumGold,
            unselectedItemColor: const Color(0xFF1E293B),
            currentIndex: nav.selectedIndex >= screens.length ? 0 : nav.selectedIndex,
            onTap: (index) => nav.setTab(index),
            items: _buildNavItems(role, lang),
          ),
        ),
      ),
    );
  }

  List<BottomNavigationBarItem> _buildNavItems(UserRole role, LanguageProvider lang) {
    if (kIsWeb) {
      return [
        const BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'HOME'),
        const BottomNavigationBarItem(icon: Icon(Icons.info_outline), activeIcon: Icon(Icons.info), label: 'PROJECTS'),
      ];
    }

    if (role == UserRole.admin) {
      return [
        const BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'HOME'),
        BottomNavigationBarItem(icon: const Icon(Icons.folder_shared_outlined), activeIcon: const Icon(Icons.folder_shared), label: lang.translate('FOLDERS')),
        BottomNavigationBarItem(icon: const Icon(Icons.calculate_outlined), activeIcon: const Icon(Icons.calculate), label: 'CALC'),
        BottomNavigationBarItem(icon: const Icon(Icons.inventory_2_outlined), activeIcon: const Icon(Icons.inventory_2), label: lang.isMalayalam ? 'മെറ്റീരിയൽസ്' : 'MATERIALS'),
      ];
    } else if (role == UserRole.worker) {
      return [
        const BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'HOME'),
        const BottomNavigationBarItem(icon: Icon(Icons.punch_clock_outlined), activeIcon: Icon(Icons.punch_clock), label: 'PUNCH HUB'),
        BottomNavigationBarItem(icon: const Icon(Icons.inventory_2_outlined), activeIcon: const Icon(Icons.inventory_2), label: 'MATERIALS'),
      ];
    } else {
      return [
        const BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'HOME'),
        const BottomNavigationBarItem(icon: Icon(Icons.calculate_outlined), activeIcon: Icon(Icons.calculate), label: 'CALC'),
      ];
    }
  }

  Widget _buildDrawer(LanguageProvider lang, NavigationProvider nav, AuthService auth) {
    final user = auth.userData;
    final role = user?.role ?? UserRole.client;

    return Drawer(
      backgroundColor: AppColors.background,
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: AppColors.border),
            currentAccountPicture: CircleAvatar(
              backgroundColor: AppColors.background,
              child: Icon(Icons.person, color: AppColors.border, size: 40),
            ),
            accountName: Text(user?.name ?? 'PCM USER', style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
            accountEmail: Text(user?.email ?? 'No email', style: const TextStyle(color: Colors.white70)),
          ),

          if (!kIsWeb && role == UserRole.admin) ...[
            _buildDrawerItem(Icons.calculate_outlined, lang.translate('CALCULATOR'), () { Navigator.pop(context); nav.setTab(2); }),
            _buildDrawerItem(Icons.inventory_2_outlined, lang.isMalayalam ? 'മെറ്റീരിയൽസ്' : 'MATERIALS', () { Navigator.pop(context); nav.setTab(3); }),
            _buildDrawerItem(Icons.history_outlined, lang.translate('FOLDERS'), () { Navigator.pop(context); nav.setTab(1); }),
            _buildDrawerItem(Icons.people_alt_outlined, lang.isMalayalam ? 'ക്ലയന്റുകൾ' : 'CLIENTS', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ClientsScreen()));
            }),
            _buildDrawerItem(Icons.engineering_outlined, lang.isMalayalam ? 'തൊഴിലാളികൾ' : 'WORKERS', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const LaborManagementScreen()));
            }),
          ],

          if (!kIsWeb && role == UserRole.worker) ...[
            _buildDrawerItem(Icons.punch_clock_outlined, 'PUNCHING HUB', () { Navigator.pop(context); nav.setTab(1); }),
            _buildDrawerItem(Icons.history, 'ATTENDANCE LOG', () {
               Navigator.pop(context);
               Navigator.push(context, MaterialPageRoute(builder: (_) => const LaborManagementScreen()));
            }),
          ],

          if (!kIsWeb)
            _buildDrawerItem(Icons.qr_code_scanner, 'Scan QR Code', () async {
              Navigator.pop(context);
              final scanned = await Navigator.push<String>(
                context,
                MaterialPageRoute(builder: (_) => const QRScannerScreen()),
              );
              if (scanned != null && scanned.isNotEmpty && mounted) {
                ProjectEditController.handleScannedQRCode(context, scanned);
              }
            }),

          const Divider(),
          if (!kIsWeb)
            _buildDrawerItem(Icons.settings, 'Company Settings', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CompanySettingsScreen()));
            }),
          _buildDrawerItem(Icons.language, lang.isMalayalam ? 'English-ലേക്ക് മാറുക' : 'Switch to Malayalam', () {
            lang.setLanguage(lang.isMalayalam ? AppLanguage.english : AppLanguage.malayalam);
            Navigator.pop(context);
          }),
          _buildDrawerItem(Icons.logout, 'Logout', () {
            auth.logout();
            Navigator.pop(context);
          }),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(kIsWeb ? 'PCM CLIENT PORTAL v4.8' : 'PCM ADMIN TOOLS v4.8', style: const TextStyle(color: Colors.grey, fontSize: 10)),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.border),
      title: Text(title, style: TextStyle(color: AppColors.labelColor, fontWeight: FontWeight.bold)),
      onTap: onTap,
    );
  }
}
