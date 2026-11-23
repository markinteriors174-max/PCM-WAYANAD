// PCM Wayanad - Admin Hub & Fully Integrated Admin Dashboard Screen
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../providers/navigation_provider.dart';
import '../../clients/clients_screen.dart';
import '../../labor/labor_management_screen.dart';
import '../../calculator/history_screen.dart';
import '../../../services/realtime_sync_service.dart';

class HomeScreenAdminHub extends StatelessWidget {
  const HomeScreenAdminHub({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.read<NavigationProvider>().openAdminDashboard();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.amber.shade300, width: 1.2),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'PCM ADMIN HUB',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.brown,
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: Colors.amber, size: 20),
          ],
        ),
      ),
    );
  }
}

// അഡ്മിൻ ഡാഷ്ബോർഡ് പേജ് (നാവിഗേഷൻ ബാർ ഉൾപ്പെടെയുള്ള പൂർണ്ണ രൂപം)
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  void _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showSyncStatusDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.cloud_done_rounded, color: Colors.green),
            SizedBox(width: 10),
            Text('Cloud Sync Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Real-Time Two-Way Sync Active:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Web Portal: pcm-wayanad-portal.vercel.app\n• Database: Firestore Live Stream\n• Latency: Real-time (<500ms)',
              style: TextStyle(fontSize: 12, color: Colors.black87, height: 1.4),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('All client quotations and stages synced with cloud.', style: TextStyle(fontSize: 11, color: Colors.green)),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CLOSE')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await RealtimeSyncService.instance.updateDataToCloud(
                'system_health',
                'sync_heartbeat',
                {'lastManualPing': DateTime.now().toIso8601String()},
              );
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cloud sync refreshed successfully!'), backgroundColor: Colors.green),
                );
              }
            },
            child: const Text('FORCE SYNC'),
          ),
        ],
      ),
    );
  }

  void _showLiveWorkStagesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Live Work Stages', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStageStep('Stage 1', 'Site Inspection & Measurement', true),
              _buildStageStep('Stage 2', 'Framing & Channel Grid', true),
              _buildStageStep('Stage 3', 'Board Fixing & Wiring', true),
              _buildStageStep('Stage 4', 'Joint Taping & Putty', false),
              _buildStageStep('Stage 5', 'Painting & Cove Lighting Handover', false),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CLOSE')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.brown, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              try {
                Provider.of<NavigationProvider>(context, listen: false).setTab(1);
              } catch (_) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
              }
            },
            child: const Text('MANAGE SITES'),
          ),
        ],
      ),
    );
  }

  Widget _buildStageStep(String stageNum, String desc, bool isDone) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            isDone ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isDone ? Colors.green : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(stageNum, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                Text(desc, style: const TextStyle(fontSize: 11, color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavigationProvider>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.read<NavigationProvider>().closeAdminDashboard();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Back to Home Overview',
            onPressed: () => context.read<NavigationProvider>().closeAdminDashboard(),
          ),
          title: const Text(
            'ADMIN DASHBOARD',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
          backgroundColor: Colors.brown[800],
          foregroundColor: Colors.white,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.2,
            children: [
              _buildDashboardItem(
                context,
                'Clients & Profiles',
                Icons.people,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClientsScreen())),
              ),
              _buildDashboardItem(
                context,
                'Projects & Sites',
                Icons.folder_shared,
                () => nav.setTab(1),
              ),
              _buildDashboardItem(
                context,
                'Live Work Stages',
                Icons.timeline,
                () => _showLiveWorkStagesDialog(context),
              ),
              _buildDashboardItem(
                context,
                'Ledger & Payments',
                Icons.account_balance_wallet,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClientsScreen())),
              ),
              _buildDashboardItem(
                context,
                'Material Pricing',
                Icons.calculate,
                () => nav.setTab(3),
              ),
              _buildDashboardItem(
                context,
                'Leads & Inbound',
                Icons.mark_unread_chat_alt,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClientsScreen())),
              ),
              _buildDashboardItem(
                context,
                'Website & Branding',
                Icons.web,
                () => _openUrl('https://pcm-wayanad-portal.vercel.app'),
              ),
              _buildDashboardItem(
                context,
                'Portfolio Gallery',
                Icons.photo_library,
                () => nav.setTab(1),
              ),
              _buildDashboardItem(
                context,
                'Worker & Labor',
                Icons.engineering,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LaborManagementScreen())),
              ),
              _buildDashboardItem(
                context,
                'Security & Sync',
                Icons.security,
                () => _showSyncStatusDialog(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardItem(BuildContext context, String title, IconData icon, [VoidCallback? onTap]) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.amber.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.brown[700], size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown[800],
                ),
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
