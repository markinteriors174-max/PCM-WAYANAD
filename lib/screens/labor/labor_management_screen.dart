// ignore_for_file: unused_field, unused_element, deprecated_member_use, use_build_context_synchronously, curly_braces_in_flow_control_structures, unused_local_variable, sort_child_properties_last, avoid_print, non_constant_identifier_names, avoid_web_libraries_in_flutter
import 'package:flutter/material.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart' as ncp;
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/labor_service.dart';
import '../../services/auth_service.dart';
import '../../models/labor_models.dart';
import '../../models/user_model.dart';
import '../../widgets/custom_app_bar.dart';
import 'worker_detail_screen.dart';

class LaborManagementScreen extends StatefulWidget {
  const LaborManagementScreen({super.key});

  @override
  State<LaborManagementScreen> createState() => _LaborManagementScreenState();
}

class _LaborManagementScreenState extends State<LaborManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final LaborService _laborService = LaborService.instance;
  final ncp.FlutterNativeContactPicker _contactPicker = ncp.FlutterNativeContactPicker();

  final Set<String> _expandedWorkerIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _playClickSound() {}

  Future<Position?> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    
    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.userData;
    final isAdmin = user?.role == UserRole.admin;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(25, 20, 25, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('PCM Labor Hub', style: TextStyle(fontSize: 10, color: AppColors.labelColor, letterSpacing: 2, fontWeight: FontWeight.bold)),
                Text(isAdmin ? 'TEAM & ATTENDANCE' : 'MY PUNCH HUB', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.border, letterSpacing: 1)),
                const SizedBox(height: 20),
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicatorColor: AppColors.resultGreen,
                  labelColor: AppColors.border,
                  unselectedLabelColor: Colors.grey,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
                  tabs: isAdmin
                    ? const [Tab(text: 'WORKERS'), Tab(text: 'PUNCHING HUB'), Tab(text: 'USER PROMOTION')]
                    : const [Tab(text: 'PUNCHING HUB'), Tab(text: 'ATTENDANCE LOG'), Tab(text: 'PROFILE')],
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: isAdmin
                ? [
                    _buildWorkerProfilesTab(),
                    _buildPunchingHubTab(null), // Admin sees all
                    _buildUserPromotionTab(auth),
                  ]
                : [
                    _buildPunchingHubTab(user?.uid), // Worker sees only theirs
                    _buildWorkerHistoryTab(user?.uid),
                    _buildWorkerProfileCard(user),
                  ],
            ),
          ),
        ],
      ),
      floatingActionButton: isAdmin ? FloatingActionButton(
        backgroundColor: AppColors.border,
        onPressed: () {
          _playClickSound();
          if (_tabController.index == 0) {
            _showAddWorkerDialog();
          } else if (_tabController.index == 1) {
            _showCheckInDialog(null);
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ) : ( _tabController.index == 0 ? FloatingActionButton(
          backgroundColor: AppColors.border,
          onPressed: () => _showCheckInDialog(user),
          child: const Icon(Icons.touch_app, color: Colors.white),
      ) : null),
    );
  }

  Widget _buildUserPromotionTab(AuthService auth) {
    return FutureBuilder<List<AppUser>>(
      future: auth.getAllProfiles(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final users = snapshot.data!.where((u) => u.role != UserRole.worker && u.role != UserRole.admin).toList();

        if (users.isEmpty) return _buildEmptyState('No Promotion Candidates', 'All users are already promoted or admins.');

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final u = users[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 15),
              padding: const EdgeInsets.all(15),
              decoration: AppStyles.neumorphicDecoration(color: Colors.white, hasThickBorder: true),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(u.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.border)),
                        Text('Role: ${u.role.name.toUpperCase()} | ${u.phone}', style: const TextStyle(fontSize: 10, color: Colors.blueGrey)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _showPromotionDialog(auth, u),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.resultGreen, foregroundColor: Colors.white),
                    child: const Text('PROMOTE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showPromotionDialog(AuthService auth, AppUser user) {
    final rateCtrl = TextEditingController(text: '900');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Promote ${user.name}'),
        content: TextField(
          controller: rateCtrl,
          decoration: AppStyles.inputDecoration('Daily Rate (₹)'),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              await auth.promoteUserToWorker(user.uid, double.parse(rateCtrl.text));
              if (mounted) {
                Navigator.pop(context);
                setState(() {});
              }
            },
            child: const Text('CONFIRM'),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkerProfilesTab() {
    return StreamBuilder<List<Worker>>(
      stream: _laborService.getWorkers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AppColors.border));
        if (!snapshot.hasData || snapshot.data!.isEmpty) return _buildEmptyState('No Workers Found', 'Add workers to enable site check-ins.');
        
        return LayoutBuilder(
          builder: (context, constraints) {
            final bool isWide = constraints.maxWidth > 700;
            if (isWide) {
              return GridView.builder(
                padding: const EdgeInsets.all(25),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 450,
                  mainAxisExtent: 200,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                ),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) => _buildWorkerGridCard(snapshot.data![index]),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) => _buildWorkerCard(snapshot.data![index]),
            );
          },
        );
      },
    );
  }

  Widget _buildWorkerGridCard(Worker worker) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => WorkerDetailScreen(worker: worker)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: AppStyles.neumorphicDecoration(color: Colors.white, hasThickBorder: true),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: AppColors.border.withValues(alpha: 0.1),
                  child: Text(worker.name[0].toUpperCase(), style: const TextStyle(color: AppColors.border, fontWeight: FontWeight.w900, fontSize: 20)),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(worker.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.border, letterSpacing: 0.5)),
                      Text('${worker.place.toUpperCase()} • ${worker.phoneNumber}', style: const TextStyle(fontSize: 10, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: AppColors.border, size: 16),
              ],
            ),
            const Divider(height: 30, color: Colors.black12),
            StreamBuilder<List<LaborEntry>>(
              stream: _laborService.getWorkerHistory(worker.id),
              builder: (context, snapshot) {
                final history = snapshot.data ?? [];
                final totalEarned = history.fold(0.0, (sum, item) => sum + item.totalWage);
                final totalDays = history.length;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMiniStat('TOTAL DAYS', '$totalDays d'),
                    _buildMiniStat('TOTAL EARNINGS', '₹${totalEarned.toStringAsFixed(0)}'),
                    _buildMiniStat('LAST SITE', history.isNotEmpty ? history.first.siteName.toUpperCase() : 'NONE'),
                  ],
                );
              },
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => WorkerDetailScreen(worker: worker)),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.border,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                ),
                child: const Text('VIEW FULL PROFILE & HISTORY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.labelColor)),
      ],
    );
  }

  Widget _buildWorkerCard(Worker worker) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => WorkerDetailScreen(worker: worker)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(15),
        decoration: AppStyles.neumorphicDecoration(color: Colors.white, hasThickBorder: true),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(color: AppColors.border, shape: BoxShape.circle),
              child: const Icon(Icons.person, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(worker.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.border)),
                  Text('${worker.place} | ${worker.phoneNumber}', style: const TextStyle(fontSize: 11, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.border),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailStat(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.resultGreen)),
      ],
    );
  }

  Widget _buildPunchingHubTab(String? workerId) {
    final stream = workerId != null ? _laborService.getActiveShifts(workerId) : _laborService.getAllActiveShifts();
    return StreamBuilder<List<LaborEntry>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AppColors.border));
        if (!snapshot.hasData || snapshot.data!.isEmpty) return _buildEmptyState('No Active Shifts', 'A worker can check-in to start their shift here.');
        
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) => _buildActiveShiftCard(snapshot.data![index]),
        );
      },
    );
  }

  Widget _buildActiveShiftCard(LaborEntry entry) {
    final now = DateTime.now();
    final duration = now.difference(entry.checkInTime).inMinutes;
    final hours = duration ~/ 60;
    final minutes = duration % 60;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(18),
      decoration: AppStyles.neumorphicDecoration(color: Colors.white, hasThickBorder: true),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 10, height: 10,
                decoration: const BoxDecoration(color: AppColors.resultGreen, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Text('ACTIVE: ${entry.shiftType.name.toUpperCase()} SHIFT', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.resultGreen, letterSpacing: 1)),
              const Spacer(),
              Text(DateFormat('hh:mm a').format(entry.checkInTime), style: const TextStyle(fontSize: 10, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.workerName.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.border)),
                  Text('SITE: ${entry.siteName.toUpperCase()}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.labelColor)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('TIME ELAPSED', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey)),
                  Text('${hours}h ${minutes}m', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.border)),
                ],
              ),
            ],
          ),
          const Divider(height: 30, color: Colors.black12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showCheckOutDialog(entry),
              icon: const Icon(Icons.outbox, size: 18),
              label: const Text('PUNCH-OUT FOR SHIFT', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.border, foregroundColor: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkerHistoryTab(String? workerId) {
    if (workerId == null) return const SizedBox();
    return StreamBuilder<List<LaborEntry>>(
      stream: _laborService.getWorkerHistory(workerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AppColors.border));
        if (!snapshot.hasData || snapshot.data!.isEmpty) return _buildEmptyState('No History Found', 'Your completed shifts will appear here.');

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final entry = snapshot.data![index];
            return _buildHistoryItem(entry);
          },
        );
      },
    );
  }

  Widget _buildHistoryItem(LaborEntry entry) {
    final timeIn = DateFormat('dd MMM, hh:mm a').format(entry.checkInTime);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: AppStyles.neumorphicDecoration(color: Colors.white, hasThickBorder: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(entry.siteName.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.border)),
              Text('₹${entry.totalWage}', style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.resultGreen)),
            ],
          ),
          Text(timeIn, style: const TextStyle(fontSize: 10, color: Colors.blueGrey)),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Duration: ${entry.totalDurationMinutes ~/ 60}h ${entry.totalDurationMinutes % 60}m | Mode: ${entry.mode.name.toUpperCase()}', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.labelColor)),
              if (entry.travelAllowance > 0) Text('Incl. ₹${entry.travelAllowance.toStringAsFixed(0)} Travel', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.blue)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWorkerProfileCard(AppUser? user) {
    if (user == null) return const SizedBox();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // 1. Summary Cards
          StreamBuilder<List<LaborEntry>>(
            stream: _laborService.getWorkerHistory(user.uid),
            builder: (context, historySnapshot) {
              final history = historySnapshot.data ?? [];
              final totalEarned = history.fold(0.0, (sum, item) => sum + item.totalWage);
              final totalDays = history.length;

              return StreamBuilder<List<AdvancePayment>>(
                stream: _laborService.getWorkerAdvances(user.uid),
                builder: (context, advanceSnapshot) {
                  final advances = advanceSnapshot.data ?? [];
                  final totalAdvanced = advances.fold(0.0, (sum, item) => sum + item.amount);

                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildSummaryCard('ATTENDANCE', '$totalDays', 'DAYS', Colors.blue)),
                          const SizedBox(width: 10),
                          Expanded(child: _buildSummaryCard('EARNED', '₹${totalEarned.toStringAsFixed(0)}', 'TOTAL', Colors.green)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildSummaryCard('ADVANCED', '₹${totalAdvanced.toStringAsFixed(0)}', 'TOTAL ADVANCE TAKEN', Colors.orange),
                      
                      if (advances.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        const Align(alignment: Alignment.centerLeft, child: Text('ADVANCE PAYMENT LOG', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1))),
                        const SizedBox(height: 10),
                        Container(
                          decoration: AppStyles.neumorphicDecoration(color: Colors.white, hasThickBorder: true),
                          child: Table(
                            columnWidths: const {
                              0: FlexColumnWidth(2),
                              1: FlexColumnWidth(1),
                            },
                            children: [
                              TableRow(
                                decoration: BoxDecoration(color: AppColors.border.withValues(alpha: 0.05)),
                                children: const [
                                  Padding(padding: EdgeInsets.all(10), child: Text('DATE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10))),
                                  Padding(padding: EdgeInsets.all(10), child: Text('AMOUNT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10))),
                                ],
                              ),
                              ...advances.map((adv) => TableRow(
                                children: [
                                  Padding(padding: const EdgeInsets.all(10), child: Text(DateFormat('dd MMM yyyy').format(adv.date), style: const TextStyle(fontSize: 10))),
                                  Padding(padding: const EdgeInsets.all(10), child: Text('₹${adv.amount}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10))),
                                ],
                              )),
                            ],
                          ),
                        ),
                      ],
                    ],
                  );
                },
              );
            },
          ),
          const SizedBox(height: 30),
          // 2. Profile Card
          Container(
            padding: const EdgeInsets.all(25),
            decoration: AppStyles.neumorphicDecoration(color: Colors.white, hasThickBorder: true),
            child: Column(
              children: [
                const CircleAvatar(radius: 40, backgroundColor: AppColors.border, child: Icon(Icons.person, size: 40, color: Colors.white)),
                const SizedBox(height: 15),
                Text(user.name.toUpperCase(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.border)),
                Text(user.phone, style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold, fontSize: 12)),
                const Divider(height: 30),
                _buildProfileStat('DAILY RATE', '₹${user.dailyRate ?? 0}'),
                _buildProfileStat('HOME LOCATION', user.homeLat != null ? 'REGISTERED' : 'NOT SET'),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final pos = await _getCurrentLocation();
                      if (pos != null) {
                        await AuthService.instance.updateHomeLocation(pos.latitude, pos.longitude);
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Home location updated successfully!'), backgroundColor: AppColors.resultGreen));
                      }
                    },
                    icon: const Icon(Icons.my_location, size: 16),
                    label: const Text('REGISTER CURRENT LOCATION AS HOME', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.border, foregroundColor: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, String sub, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: AppStyles.neumorphicDecoration(color: Colors.white, hasThickBorder: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color, letterSpacing: 1)),
          const SizedBox(height: 5),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.border)),
          Text(sub, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildProfileStat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.border)),
        ],
      ),
    );
  }

  Widget _buildAdminReportsTab() {
    return StreamBuilder<List<LaborEntry>>(
      stream: _laborService.getAllCompletedReports(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AppColors.border));
        if (!snapshot.hasData || snapshot.data!.isEmpty) return _buildEmptyState('No Completed Reports', 'Worker shifts will appear here once checked-out.');
        
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final entry = snapshot.data![index];
            final timeIn = DateFormat('hh:mm a').format(entry.checkInTime);
            final timeOut = entry.checkOutTime != null ? DateFormat('hh:mm a').format(entry.checkOutTime!) : '--:--';
            
            return Container(
              margin: const EdgeInsets.only(bottom: 15),
              padding: const EdgeInsets.all(15),
              decoration: AppStyles.neumorphicDecoration(color: Colors.white, hasThickBorder: true),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(color: AppColors.border, fontSize: 14),
                      children: [
                        TextSpan(text: '${entry.workerName}: ', style: const TextStyle(fontWeight: FontWeight.w900)),
                        TextSpan(text: '${entry.shiftType.name.toUpperCase()} SHIFT ', style: const TextStyle(color: AppColors.resultGreen, fontWeight: FontWeight.bold)),
                        TextSpan(text: '($timeIn to $timeOut) - ', style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                        const TextSpan(text: 'Completed', style: TextStyle(color: AppColors.resultGreen, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Duration: ${entry.totalDurationMinutes ~/ 60}h ${entry.totalDurationMinutes % 60}m | Site: ${entry.siteName}', style: const TextStyle(fontSize: 10, color: AppColors.labelColor, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showCheckInDialog(AppUser? currentUser) {
    final siteCtrl = TextEditingController();
    Worker? selectedWorker;
    ShiftType selectedShift = ShiftType.morning;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.background,
            shape: RoundedRectangleBorder(side: BorderSide(color: AppColors.border, width: 2), borderRadius: BorderRadius.circular(15)),
            title: const Text('Worker Check-in', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.border)),
            content: SingleChildScrollView(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (currentUser == null) StreamBuilder<List<Worker>>(
                    stream: _laborService.getWorkers(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const CircularProgressIndicator(color: AppColors.border);
                      return DropdownButtonFormField<Worker>(
                        decoration: AppStyles.inputDecoration('Select Worker'),
                        items: snapshot.data!.map((w) => DropdownMenuItem(value: w, child: Text(w.name, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
                        onChanged: (val) => setDialogState(() => selectedWorker = val),
                      );
                    },
                  ) else Text('Checking in as: ${currentUser.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  TextField(controller: siteCtrl, decoration: AppStyles.inputDecoration('Site Name / Unit #')),
                  const SizedBox(height: 20),
                  const Align(alignment: Alignment.centerLeft, child: Text('SELECT SHIFT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1, color: AppColors.labelColor))),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: ShiftType.values.map((s) {
                      final isSelected = selectedShift == s;
                      return ChoiceChip(
                        label: Text(s.name.toUpperCase()),
                        selected: isSelected,
                        onSelected: (val) => setDialogState(() => selectedShift = s),
                        selectedColor: AppColors.border,
                        labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.border, fontSize: 10, fontWeight: FontWeight.bold),
                        backgroundColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: AppColors.border)),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL', style: TextStyle(color: Colors.black45))),
              ElevatedButton(
                onPressed: () async {
                  if ((selectedWorker != null || currentUser != null) && siteCtrl.text.isNotEmpty) {
                    final pos = await _getCurrentLocation();
                    await _laborService.checkInWorker(
                      workerId: currentUser?.uid ?? selectedWorker!.id,
                      workerName: currentUser?.name ?? selectedWorker!.name,
                      siteId: siteCtrl.text,
                      siteName: siteCtrl.text,
                      shiftType: selectedShift,
                      lat: pos?.latitude,
                      lng: pos?.longitude,
                      workerHomeLat: currentUser?.homeLat ?? selectedWorker?.homeLat,
                      workerHomeLng: currentUser?.homeLng ?? selectedWorker?.homeLng,
                    );
                    if (context.mounted) Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryButton, foregroundColor: Colors.white),
                child: const Text('CHECK-IN'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showCheckOutDialog(LaborEntry entry) {
    final paidCtrl = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(side: BorderSide(color: AppColors.border, width: 2), borderRadius: BorderRadius.circular(15)),
        title: const Text('Confirm Check-out', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.border)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Ending ${entry.shiftType.name} shift for ${entry.workerName}.', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(controller: paidCtrl, decoration: AppStyles.inputDecoration('Advance Paid (Optional)'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL', style: TextStyle(color: Colors.black45))),
          ElevatedButton(
            onPressed: () async {
              await _laborService.checkOutWorker(
                entryId: entry.id,
                paidAmount: double.tryParse(paidCtrl.text) ?? 0,
              );
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.alertRed, foregroundColor: Colors.white),
            child: const Text('PUNCH-OUT'),
          ),
        ],
      ),
    );
  }

  void _showAddWorkerDialog() {
    final nameCtrl = TextEditingController();
    final placeCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(side: BorderSide(color: AppColors.border, width: 2), borderRadius: BorderRadius.circular(15)),
        title: const Text('Add Worker Profile', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.border)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: AppStyles.inputDecoration('Name').copyWith(
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.contact_phone, color: AppColors.border),
                    onPressed: () async {
                      final contact = await _contactPicker.selectContact();
                      if (contact != null) {
                        nameCtrl.text = contact.fullName ?? '';
                        if (contact.phoneNumbers != null && contact.phoneNumbers!.isNotEmpty) {
                          phoneCtrl.text = contact.phoneNumbers!.first;
                        }
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(controller: placeCtrl, decoration: AppStyles.inputDecoration('Place')),
              const SizedBox(height: 10),
              TextField(controller: phoneCtrl, decoration: AppStyles.inputDecoration('Phone Number'), keyboardType: TextInputType.phone),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL', style: TextStyle(color: Colors.black45))),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                _laborService.addWorker(Worker(id: '', name: nameCtrl.text, place: placeCtrl.text, phoneNumber: phoneCtrl.text));
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryButton, foregroundColor: Colors.white),
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String sub) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 60, color: AppColors.border.withValues(alpha: 0.1)),
          const SizedBox(height: 15),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.labelColor)),
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(sub, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
