// ignore_for_file: unused_field, unused_element, deprecated_member_use, use_build_context_synchronously, curly_braces_in_flow_control_structures, unused_local_variable, sort_child_properties_last, avoid_print, non_constant_identifier_names, avoid_web_libraries_in_flutter
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/auth_service.dart';
import '../../services/labor_service.dart';
import '../../models/labor_models.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import 'material_request_form.dart';
import 'widgets/quick_expenses_widget.dart';
import '../calculator/calculator_screen.dart';
import '../../services/geofence_service.dart';
import '../../services/client_service.dart';
import '../clients/project_hub_page.dart';
import '../main_navigation.dart';

class WorkerHomeScreen extends StatefulWidget {
  const WorkerHomeScreen({super.key});

  @override
  State<WorkerHomeScreen> createState() => _WorkerHomeScreenState();
}

class _WorkerHomeScreenState extends State<WorkerHomeScreen> {
  bool _isPunching = false;

  Future<void> _handlePunch(LaborEntry? activeShift) async {
    final user = AuthService.instance.userData;
    if (user == null) return;

    if (activeShift == null && (user.homeLat == null || user.homeLng == null)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('PLEASE REGISTER HOME LOCATION IN YOUR PROFILE TO PUNCH IN'),
          backgroundColor: AppColors.alertRed,
        ));
      }
      return;
    }

    setState(() => _isPunching = true);

    try {
      if (activeShift == null) {
        final site = await GeofenceService.instance.findCurrentSite();
        if (site == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('PUNCH-IN CANCELLED: No site found via GPS.'),
              backgroundColor: AppColors.alertRed,
            ));
          }
          return;
        }

        await LaborService.instance.checkInWorker(
          workerId: user.uid,
          workerName: user.name,
          siteId: site.id?.toString() ?? '0',
          siteName: site.unitNumber,
          shiftType: _determineShiftType(),
          lat: site.latitude,
          lng: site.longitude,
          workerHomeLat: user.homeLat,
          workerHomeLng: user.homeLng,
        );
      } else {
        await LaborService.instance.checkOutWorker(entryId: activeShift.id);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isPunching = false);
    }
  }

  ShiftType _determineShiftType() {
    final hour = DateTime.now().hour;
    if (hour >= 8 && hour < 13) return ShiftType.morning;
    if (hour >= 13 && hour < 18) return ShiftType.afternoon;
    if (hour >= 18 && hour < 22) return ShiftType.evening;
    return ShiftType.night;
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.userData;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => RoleNavigationShell.scaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text('WORKER PORTAL', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
        backgroundColor: AppColors.border,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: () => AuthService.instance.logout()),
        ],
      ),
      body: StreamBuilder<List<LaborEntry>>(
        stream: LaborService.instance.getWorkerHistory(user.uid),
        builder: (context, historySnapshot) {
          final history = historySnapshot.data ?? [];
          final totalEarned = history.fold(0.0, (sum, item) => sum + item.totalWage);
          final totalDays = history.length;

          return StreamBuilder<List<AdvancePayment>>(
            stream: LaborService.instance.getWorkerAdvances(user.uid),
            builder: (context, advanceSnapshot) {
              final advances = advanceSnapshot.data ?? [];
              final totalAdvanced = advances.fold(0.0, (sum, item) => sum + item.amount);
              
              return StreamBuilder<List<LaborEntry>>(
                stream: LaborService.instance.getActiveShifts(user.uid),
                builder: (context, activeSnapshot) {
                  final activeShift = activeSnapshot.hasData && activeSnapshot.data!.isNotEmpty ? activeSnapshot.data!.first : null;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildWorkerProfileHeader(user),
                        const SizedBox(height: 25),
                        
                        // Summary Cards
                        Row(
                          children: [
                            Expanded(child: _buildSummaryCard('ATTENDANCE', '$totalDays d', 'DAYS', Colors.blue)),
                            const SizedBox(width: 8),
                            Expanded(child: _buildSummaryCard('EARNED', '₹${totalEarned.toStringAsFixed(0)}', 'TOTAL', Colors.green)),
                            const SizedBox(width: 8),
                            Expanded(child: _buildSummaryCard('ADVANCED', '₹${totalAdvanced.toStringAsFixed(0)}', 'TAKEN', Colors.orange)),
                          ],
                        ),
                        const SizedBox(height: 25),

                        if (user.homeLat == null || user.homeLng == null) _buildMissingHomeWarning()
                        else _buildHomeRegisteredStatus(),

                        const SizedBox(height: 25),
                        _buildPunchCard(activeShift),
                        
                        const SizedBox(height: 30),
                        _buildSectionHeader('WAGE & TRANSACTION LOGS'),
                        _buildReadOnlyField('DAILY WAGE RATE', '₹${(user.dailyRate ?? 0).toStringAsFixed(0)}', Icons.payments_outlined),
                        
                        const SizedBox(height: 15),
                        _buildAdvancePaymentLog(advances),
                        
                        const SizedBox(height: 30),
                        _buildSectionHeader('QUICK ACTIONS'),
                        if (activeShift != null) ...[
                          _buildActionCard(
                            title: 'SITE PROGRESS HUB',
                            subtitle: 'Updates for ${activeShift.siteName}',
                            icon: Icons.hub,
                            onTap: () {
                              ClientService.instance.getAssignedClient(user.name).then((client) {
                                if (client != null && mounted) {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => ProjectHubPage(client: client)));
                                }
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                        ],
                        _buildActionCard(
                          title: 'REQUEST STOCK',
                          subtitle: 'Notify Admin for Materials',
                          icon: Icons.inventory_2,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MaterialRequestForm(activeSiteName: activeShift?.siteName))),
                        ),
                        const SizedBox(height: 12),
                        _buildActionCard(
                          title: 'CALCULATOR / PDF',
                          subtitle: 'Calculate & view PDF',
                          icon: Icons.calculate,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CalculatorScreen())),
                        ),
                        
                        const SizedBox(height: 30),
                        QuickExpensesWidget(activeSiteName: activeShift?.siteName),
                        
                        const SizedBox(height: 30),
                        _buildSectionHeader('ATTENDANCE HISTORY'),
                        _buildHistoryList(history),
                      ],
                    ),
                  );
                }
              );
            },
          );
        }
      ),
    );
  }

  Widget _buildWorkerProfileHeader(AppUser user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppStyles.neumorphicDecoration(color: Colors.white, hasThickBorder: true),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.border,
            child: Icon(Icons.person, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name.toUpperCase(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.border, letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    ...List.generate(5, (index) => Icon(
                      Icons.star,
                      size: 14,
                      color: index < (user.rating ?? 5.0).floor() ? Colors.orange : Colors.grey.shade300,
                    )),
                    const SizedBox(width: 6),
                    Text('${user.rating ?? 5.0}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54)),
                  ],
                ),
                if (user.bonusInfo != null && user.bonusInfo!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text('BONUS: ${user.bonusInfo}', style: const TextStyle(fontSize: 9, color: AppColors.resultGreen, fontWeight: FontWeight.w900)),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.contact_phone_outlined, color: AppColors.border, size: 22),
            onPressed: () => _showContactSheet(user),
          ),
        ],
      ),
    );
  }

  void _showContactSheet(AppUser user) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('WORKER CONTACT INFO', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 14)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.phone, color: AppColors.border),
              title: Text(user.phone, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text('Registered Mobile', style: TextStyle(fontSize: 11)),
            ),
            if (user.email.isNotEmpty) ListTile(
              leading: const Icon(Icons.email, color: AppColors.border),
              title: Text(user.email, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text('Registered Email', style: TextStyle(fontSize: 11)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, String sub, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: AppStyles.neumorphicDecoration(color: Colors.white, hasThickBorder: true),
      child: Column(
        children: [
          Text(title, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.8)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.border)),
          const SizedBox(height: 2),
          Text(sub, style: const TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildMissingHomeWarning() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppStyles.neumorphicDecoration(color: Colors.white, hasThickBorder: true),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.alertRed, size: 20),
              SizedBox(width: 10),
              Text('HOME LOCATION NOT REGISTERED', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.alertRed, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Travel allowance cannot be calculated without home coordinates.', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: Colors.black54, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final pos = await Geolocator.getCurrentPosition();
                await AuthService.instance.updateHomeLocation(pos.latitude, pos.longitude);
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Home registered!'), backgroundColor: AppColors.resultGreen));
              },
              icon: const Icon(Icons.my_location, size: 14),
              label: const Text('REGISTER CURRENT LOCATION AS HOME', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.alertRed, foregroundColor: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeRegisteredStatus() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: AppStyles.neumorphicDecoration(color: Colors.green.shade50),
      child: const Row(
        children: [
          Icon(Icons.check_circle, color: AppColors.resultGreen, size: 20),
          SizedBox(width: 12),
          Text('REGISTERED HOME LOCATION ACTIVE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.resultGreen)),
        ],
      ),
    );
  }

  Widget _buildPunchCard(LaborEntry? activeShift) {
    bool isWorking = activeShift != null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppStyles.neumorphicDecoration(color: Colors.white, hasThickBorder: true),
      child: Column(
        children: [
          Text(
            isWorking ? 'SHIFT ACTIVE @ ${activeShift.siteName.toUpperCase()}' : 'SYSTEM READY FOR PUNCH-IN',
            style: TextStyle(fontWeight: FontWeight.w900, color: isWorking ? AppColors.resultGreen : AppColors.border, fontSize: 11, letterSpacing: 1),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 55,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isPunching ? null : () => _handlePunch(activeShift),
              style: ElevatedButton.styleFrom(
                backgroundColor: isWorking ? AppColors.alertRed : AppColors.primaryButton,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isPunching 
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(isWorking ? 'PUNCH OUT NOW' : 'PUNCH IN (AUTO-DETECT SITE)', style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: AppColors.labelColor, letterSpacing: 1.2)),
    );
  }

  Widget _buildReadOnlyField(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      decoration: AppStyles.neumorphicDecoration(color: Colors.white),
      child: Row(
        children: [
          Icon(icon, color: AppColors.border, size: 18),
          const SizedBox(width: 15),
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black54))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.border)),
        ],
      ),
    );
  }

  Widget _buildAdvancePaymentLog(List<AdvancePayment> advances) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppStyles.neumorphicDecoration(color: Colors.white, hasThickBorder: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ADVANCE PAYMENT LOG', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: AppColors.border)),
          const Divider(height: 25),
          if (advances.isEmpty) 
            const Center(child: Text('No advance payments recorded.', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)))
          else
            ...advances.take(5).map((adv) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('advance given', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      Text(DateFormat('dd MMM yyyy').format(adv.date), style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Text('- ${adv.amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.alertRed, fontSize: 13)),
                ],
              ),
            )),
        ],
      ),
    );
  }

  Widget _buildActionCard({required String title, required String subtitle, required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: AppStyles.neumorphicDecoration(color: Colors.white, hasThickBorder: true),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: AppColors.primaryButton, size: 24),
            ),
            const SizedBox(width: 15),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: AppColors.border)),
              Text(subtitle, style: const TextStyle(fontSize: 9, color: Colors.black45, fontWeight: FontWeight.bold)),
            ])),
            const Icon(Icons.chevron_right, size: 16, color: Colors.black26),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList(List<LaborEntry> history) {
    if (history.isEmpty) {
      return const Center(child: Text('No attendance history found.', style: TextStyle(fontSize: 11, color: Colors.black38, fontWeight: FontWeight.bold)));
    }
    return Column(
      children: history.map((e) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(15),
        decoration: AppStyles.neumorphicDecoration(color: Colors.white),
        child: Row(
          children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(e.siteName.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: AppColors.border)),
              Text('${DateFormat('dd MMM yyyy').format(e.checkInTime)} | Shift Started: ${DateFormat('hh:mm a').format(e.checkInTime)}', style: const TextStyle(fontSize: 9, color: Colors.black54, fontWeight: FontWeight.bold)),
            ])),
            Text('₹${e.totalWage.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.resultGreen, fontSize: 12)),
          ],
        ),
      )).toList(),
    );
  }
}
