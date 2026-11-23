import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/labor_models.dart';
import '../../services/database_service.dart';

class WorkerListTab extends StatefulWidget {
  final bool isLoading;
  final List<SQLiteWorker> sqliteWorkersList;
  final VoidCallback onRefresh;

  const WorkerListTab({
    super.key,
    required this.isLoading,
    required this.sqliteWorkersList,
    required this.onRefresh,
  });

  @override
  State<WorkerListTab> createState() => _WorkerListTabState();
}

class _WorkerListTabState extends State<WorkerListTab> {
  void _showAddWorkerDialog() {
    final nameCtrl = TextEditingController();
    final wageCtrl = TextEditingController(text: '1000');
    final daysCtrl = TextEditingController(text: '0');
    final paidCtrl = TextEditingController(text: '0');
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.background,
            shape: RoundedRectangleBorder(
              side: const BorderSide(color: AppColors.border, width: 2), 
              borderRadius: BorderRadius.circular(15)
            ),
            title: const Text(
              'Add New Worker Profile', 
              style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.border)
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: AppStyles.inputDecoration('Worker Name (Required)*'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: wageCtrl,
                    keyboardType: TextInputType.number,
                    decoration: AppStyles.inputDecoration('Daily Wage (₹)'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: daysCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: AppStyles.inputDecoration('Initial Days Worked'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: paidCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: AppStyles.inputDecoration('Initial Paid Advances (₹)'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('CANCEL', style: TextStyle(color: Colors.black45, fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                onPressed: saving
                    ? null
                    : () async {
                        final name = nameCtrl.text.trim();
                        if (name.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Worker name is required'), backgroundColor: AppColors.alertRed),
                          );
                          return;
                        }
                        final wage = double.tryParse(wageCtrl.text.trim()) ?? 1000.0;
                        final days = double.tryParse(daysCtrl.text.trim()) ?? 0.0;
                        final paid = double.tryParse(paidCtrl.text.trim()) ?? 0.0;

                        setDialogState(() => saving = true);
                        await DatabaseService.instance.insertSQLiteWorker(name, wage, days, paid);
                        widget.onRefresh();
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryButton, 
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: saving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('SAVE WORKER', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) return const Center(child: CircularProgressIndicator(color: AppColors.border));
    
    if (widget.sqliteWorkersList.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.engineering_outlined, 
              size: 70, 
              color: Color(0x264A4A4A)
            ),
            const SizedBox(height: 20),
            const Text(
              'No Worker Data Available. Add a worker first.',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.labelColor),
            ),
            const SizedBox(height: 25),
            GestureDetector(
              onTap: _showAddWorkerDialog,
              child: Container(
                height: 50,
                width: 200,
                decoration: AppStyles.neumorphicDecoration(color: AppColors.primaryButton, hasThickBorder: true),
                alignment: Alignment.center,
                child: const Text(
                  'ADD WORKER',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(25, 20, 25, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'WORKER WAGE LEDGER',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.5, color: AppColors.border),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${widget.sqliteWorkersList.length} workers registered',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _showAddWorkerDialog,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('ADD WORKER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryButton,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            itemCount: widget.sqliteWorkersList.length,
            itemBuilder: (context, index) {
              final worker = widget.sqliteWorkersList[index];
              return WorkerAccordionCard(
                worker: worker,
                onRefresh: widget.onRefresh,
              );
            },
          ),
        ),
      ],
    );
  }
}

class WorkerAccordionCard extends StatefulWidget {
  final SQLiteWorker worker;
  final VoidCallback onRefresh;

  const WorkerAccordionCard({
    super.key,
    required this.worker,
    required this.onRefresh,
  });

  @override
  State<WorkerAccordionCard> createState() => _WorkerAccordionCardState();
}

class _WorkerAccordionCardState extends State<WorkerAccordionCard> {
  bool _isExpanded = false;
  late TextEditingController _daysController;
  final TextEditingController _paymentController = TextEditingController();
  bool _isSavingDays = false;
  bool _isSavingPayment = false;

  @override
  void initState() {
    super.initState();
    _daysController = TextEditingController(text: widget.worker.totalDays.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), ''));
  }

  @override
  void didUpdateWidget(WorkerAccordionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.worker.totalDays != widget.worker.totalDays) {
      _daysController.text = widget.worker.totalDays.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
    }
  }

  @override
  void dispose() {
    _daysController.dispose();
    _paymentController.dispose();
    super.dispose();
  }

  Future<void> _saveDays() async {
    final days = double.tryParse(_daysController.text.trim());
    if (days == null || days < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid number of days'), backgroundColor: AppColors.alertRed),
      );
      return;
    }
    setState(() => _isSavingDays = true);
    await DatabaseService.instance.updateWorkerDays(widget.worker.id, days);
    setState(() => _isSavingDays = false);
    widget.onRefresh();
  }

  Future<void> _recordPayment() async {
    final amount = double.tryParse(_paymentController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid payment amount'), backgroundColor: AppColors.alertRed),
      );
      return;
    }
    setState(() => _isSavingPayment = true);
    await DatabaseService.instance.recordWorkerPayment(widget.worker.id, amount);
    _paymentController.clear();
    setState(() => _isSavingPayment = false);
    widget.onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    final double netBalance = widget.worker.netBalance;
    final String statusText = widget.worker.statusText;
    
    Color balanceColor;
    if (netBalance < 0) {
      balanceColor = AppColors.alertRed;
    } else if (netBalance > 0) {
      balanceColor = AppColors.border;
    } else {
      balanceColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppStyles.neumorphicDecoration(color: Colors.white, hasThickBorder: true),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: balanceColor.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person,
                      color: balanceColor == Colors.grey ? AppColors.border : balanceColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.worker.name.toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppColors.labelColor),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'Balance: ₹${netBalance.abs().toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: balanceColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: balanceColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                statusText.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                  color: balanceColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: _isExpanded
                ? Container(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: AppColors.subtleGrey, width: 1),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildMetricItem('Days Worked', '${widget.worker.totalDays.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')} days'),
                            _buildMetricItem('Daily Wage', '₹${widget.worker.dailyWage.toStringAsFixed(0)}'),
                            _buildMetricItem('Total Paid', '₹${widget.worker.totalPaid.toStringAsFixed(2)}'),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'UPDATE DAYS WORKED',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppColors.border, letterSpacing: 1),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 40,
                                child: TextField(
                                  controller: _daysController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  decoration: InputDecoration(
                                    hintText: 'e.g. 10.5',
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              height: 40,
                              child: ElevatedButton.icon(
                                onPressed: _isSavingDays ? null : _saveDays,
                                icon: _isSavingDays
                                    ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Icon(Icons.check, size: 14),
                                label: const Text('SAVE DAYS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryButton,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'RECORD PAYMENT / ADVANCE',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppColors.border, letterSpacing: 1),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 40,
                                child: TextField(
                                  controller: _paymentController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  decoration: InputDecoration(
                                    hintText: 'Amount (₹)',
                                    prefixText: '₹',
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              height: 40,
                              child: ElevatedButton.icon(
                                onPressed: _isSavingPayment ? null : _recordPayment,
                                icon: _isSavingPayment
                                    ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Icon(Icons.add, size: 14),
                                label: const Text('RECORD', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.resultGreen,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 32, color: AppColors.subtleGrey),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () {
                              _showDeleteConfirmation(context);
                            },
                            icon: const Icon(Icons.delete_outline, color: AppColors.alertRed, size: 16),
                            label: const Text('DELETE WORKER PROFILE', style: TextStyle(color: AppColors.alertRed, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.5)),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.alertRed,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(fontSize: 8, color: Colors.black38, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14, color: AppColors.labelColor, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Worker Profile?'),
        content: Text('Are you sure you want to delete the worker profile for "${widget.worker.name.toUpperCase()}"? This action is irreversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await DatabaseService.instance.deleteSQLiteWorker(widget.worker.id);
              widget.onRefresh();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.alertRed),
            child: const Text('DELETE', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
