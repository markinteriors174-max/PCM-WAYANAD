// ignore_for_file: unused_field, unused_element, deprecated_member_use, use_build_context_synchronously, curly_braces_in_flow_control_structures, unused_local_variable, sort_child_properties_last, avoid_print, non_constant_identifier_names, avoid_web_libraries_in_flutter
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../theme/app_theme.dart';
import '../../services/labor_service.dart';
import '../../models/labor_models.dart';
import '../../models/client_model.dart';
import '../../services/client_service.dart';
import 'widgets/worker_header_card.dart';
import 'widgets/worker_settings_form.dart';
import 'widgets/attendance_history_list.dart';
import 'widgets/worker_profile_header.dart';
import 'widgets/worker_home_location_card.dart';
import 'widgets/worker_client_hub_card.dart';

class WorkerDetailScreen extends StatefulWidget {
  final Worker worker;
  const WorkerDetailScreen({super.key, required this.worker});

  @override
  State<WorkerDetailScreen> createState() => _WorkerDetailScreenState();
}

class _WorkerDetailScreenState extends State<WorkerDetailScreen> {
  final LaborService _laborService = LaborService.instance;
  final TextEditingController _rateCtrl = TextEditingController();
  final TextEditingController _advanceCtrl = TextEditingController();
  
  bool _isSaving = false;
  bool _isSavingAdvance = false;
  bool _isSavingHome = false;

  List<LaborEntry> _history = [];
  List<AdvancePayment> _advances = [];
  Client? _assignedClient;
  bool _isInitialized = false;

  StreamSubscription? _historySub;
  StreamSubscription? _advanceSub;

  @override
  void initState() {
    super.initState();
    _rateCtrl.text = widget.worker.dailyRate.toStringAsFixed(0);
    _loadAssignedClient();

    _historySub = _laborService.getWorkerHistory(widget.worker.id).listen((data) {
      if (mounted) setState(() => _history = data);
    });
    
    _advanceSub = _laborService.getWorkerAdvances(widget.worker.id).listen((data) {
      if (mounted) {
        setState(() {
          _advances = data;
          _isInitialized = true;
        });
      }
    });
  }

  Future<void> _loadAssignedClient() async {
    final client = await ClientService.instance.getAssignedClient(widget.worker.name);
    if (mounted) {
      setState(() => _assignedClient = client);
    }
  }

  @override
  void dispose() {
    _historySub?.cancel();
    _advanceSub?.cancel();
    _rateCtrl.dispose();
    _advanceCtrl.dispose();
    super.dispose();
  }

  double get _starBonus => (widget.worker.rating * 10).toDouble();
  double get _totalEarned => _history.fold(0.0, (sum, item) => sum + item.totalWage) + _starBonus;
  double get _totalAdvanced => _advances.fold(0.0, (sum, item) => sum + item.amount);
  double get _balanceDue => _totalEarned - _totalAdvanced;

  Future<void> _updateWageRate() async {
    if (_rateCtrl.text.isEmpty) return;
    setState(() => _isSaving = true);
    await _laborService.updateWorkerRate(widget.worker.id, double.parse(_rateCtrl.text));
    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Wage rate updated!')));
    }
  }

  Future<void> _recordAdvancePayment() async {
    if (_advanceCtrl.text.isEmpty) return;
    setState(() => _isSavingAdvance = true);
    
    final amount = double.parse(_advanceCtrl.text);
    final advance = AdvancePayment(
      id: '',
      workerId: widget.worker.id,
      amount: amount,
      date: DateTime.now(),
      note: 'Advance payment issued via admin panel',
    );
    
    await _laborService.addWorkerAdvance(advance);
    
    if (mounted) {
      setState(() {
        _isSavingAdvance = false;
        _advanceCtrl.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Advance payment recorded!'), backgroundColor: AppColors.resultGreen));
    }
  }

  Future<void> _registerHomeLocation() async {
    setState(() => _isSavingHome = true);
    try {
      final pos = await Geolocator.getCurrentPosition();
      await _laborService.updateWorkerHomeLocation(widget.worker.id, pos.latitude, pos.longitude);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Home location updated to current GPS!'), backgroundColor: AppColors.resultGreen));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.alertRed));
    } finally {
      if (mounted) setState(() => _isSavingHome = false);
    }
  }

  Future<void> _deleteAdvance(AdvancePayment adv) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Record?'),
        content: Text('Remove this advance payment of ₹${adv.amount.toStringAsFixed(0)}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('DELETE', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _laborService.deleteWorkerAdvance(adv.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Record deleted'), backgroundColor: Colors.black87),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.border)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.border,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(widget.worker.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Worker?'),
                  content: Text('Are you sure you want to remove ${widget.worker.name}?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('DELETE', style: TextStyle(color: Colors.red))),
                  ],
                ),
              );
              if (confirm == true) {
                await _laborService.deleteWorker(widget.worker.id);
                if (mounted) Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            WorkerProfileHeader(worker: widget.worker, starBonus: _starBonus),
            const SizedBox(height: 25),
            
            WorkerHeaderCard(
              attendanceCount: _history.length,
              totalEarned: _totalEarned,
              totalAdvanced: _totalAdvanced,
              balanceDue: _balanceDue,
            ),
            const SizedBox(height: 25),

            WorkerHomeLocationCard(
              worker: widget.worker,
              isSavingHome: _isSavingHome,
              onRegisterHome: _registerHomeLocation,
            ),
            const SizedBox(height: 25),

            if (_assignedClient != null) ...[
              const Text('ACTIVE CLIENT & PROJECT HUB', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.border, letterSpacing: 1, fontSize: 12)),
              const SizedBox(height: 15),
              WorkerClientHubCard(client: _assignedClient!),
              const SizedBox(height: 30),
            ],

            const Text('WORKER SETTINGS & ADVANCES', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.border, letterSpacing: 1, fontSize: 12)),
            const SizedBox(height: 15),
            WorkerSettingsForm(
              rateController: _rateCtrl,
              advanceController: _advanceCtrl,
              isSavingRate: _isSaving,
              isSavingAdvance: _isSavingAdvance,
              onUpdateRate: _updateWageRate,
              onRecordAdvance: _recordAdvancePayment,
            ),
            const SizedBox(height: 30),

            AttendanceHistoryList(
              history: _history,
              advances: _advances,
              onLongPressAdvance: _deleteAdvance,
            ),
          ],
        ),
      ),
    );
  }
}
