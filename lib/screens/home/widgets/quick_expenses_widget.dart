// ignore_for_file: unused_field, unused_element, deprecated_member_use, use_build_context_synchronously, curly_braces_in_flow_control_structures, unused_local_variable, sort_child_properties_last, avoid_print, non_constant_identifier_names, avoid_web_libraries_in_flutter
import 'package:flutter/material.dart';
import '../../../services/workflow_service.dart';
import '../../../services/quotation_db_service.dart';
import '../../../models/quotation.dart';
import '../../../theme/app_theme.dart';

class QuickExpensesWidget extends StatefulWidget {
  final String? activeSiteName;
  const QuickExpensesWidget({super.key, this.activeSiteName});

  @override
  State<QuickExpensesWidget> createState() => _QuickExpensesWidgetState();
}

class _QuickExpensesWidgetState extends State<QuickExpensesWidget> {
  final _amountController = TextEditingController();
  final _remarksController = TextEditingController();
  final _otherExpenseController = TextEditingController();
  
  String? _selectedUnitNumber;
  String _selectedExpenseType = 'Labor Wages';
  List<Quotation> _projects = [];
  List<Map<String, dynamic>> _siteExpenses = [];
  bool _isLoading = false;
  bool _isFetching = false;

  final List<String> _expenseTypes = [
    'Labor Wages',
    'Vehicle / Transport Fare',
    'Tools Rental',
    'Other Expenses',
  ];

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    final projects = await QuotationDbService.instance.getQuotations();
    setState(() {
      _projects = projects;
      if (widget.activeSiteName != null) {
        _selectedUnitNumber = widget.activeSiteName;
      } else if (_projects.isNotEmpty && _selectedUnitNumber == null) {
        _selectedUnitNumber = _projects.first.unitNumber;
      }
    });
    _loadSiteExpenses();
  }

  Future<void> _loadSiteExpenses() async {
    if (_selectedUnitNumber == null) {
      setState(() => _siteExpenses = []);
      return;
    }
    setState(() => _isFetching = true);
    try {
      final expenses = await WorkflowService.instance.getSiteExpenses(_selectedUnitNumber!);
      setState(() {
        _siteExpenses = expenses;
      });
    } catch (e) {
      debugPrint('Error loading expenses: $e');
    } finally {
      setState(() => _isFetching = false);
    }
  }

  @override
  void didUpdateWidget(QuickExpensesWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activeSiteName != oldWidget.activeSiteName && widget.activeSiteName != null) {
      setState(() {
        _selectedUnitNumber = widget.activeSiteName;
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _remarksController.dispose();
    _otherExpenseController.dispose();
    super.dispose();
  }

  Future<void> _saveExpense() async {
    if (_selectedUnitNumber == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a project')),
      );
      return;
    }

    if (_selectedExpenseType == 'Other Expenses' && _otherExpenseController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please specify the expense category')),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final success = await WorkflowService.instance.addSiteExpense(
      unitNumber: _selectedUnitNumber!,
      expenseType: _selectedExpenseType,
      amount: amount,
      remarks: _remarksController.text,
      customCategory: _selectedExpenseType == 'Other Expenses' ? _otherExpenseController.text.trim() : null,
    );

    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense saved successfully')),
      );
      _amountController.clear();
      _remarksController.clear();
      _otherExpenseController.clear();
      _loadSiteExpenses();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save expense. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppStyles.neumorphicDecoration(color: Colors.white, hasThickBorder: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet_outlined, color: AppColors.border, size: 24),
              const SizedBox(width: 10),
              Text(
                'QUICK EXPENSES WIDGET',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: AppColors.border,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Project Selection
          const Text(
            'SELECT PROJECT (UNIT NUMBER)',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedUnitNumber,
                isExpanded: true,
                hint: const Text('Choose Project', style: TextStyle(fontSize: 13)),
                items: _projects.map((p) {
                  return DropdownMenuItem(
                    value: p.unitNumber,
                    child: Text('${p.unitNumber} - ${p.clientName}', style: const TextStyle(fontSize: 13)),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() => _selectedUnitNumber = val);
                  _loadSiteExpenses();
                },
              ),
            ),
          ),
          const SizedBox(height: 15),

          // Expense Type
          const Text(
            'EXPENSE TYPE',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedExpenseType,
                isExpanded: true,
                items: _expenseTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type, style: const TextStyle(fontSize: 13)),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedExpenseType = val!),
              ),
            ),
          ),
          if (_selectedExpenseType == 'Other Expenses') ...[
            const SizedBox(height: 10),
            TextField(
              controller: _otherExpenseController,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Specify Other Expense (e.g., Cement, Paint)',
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
              ),
            ),
          ],
          const SizedBox(height: 15),

          // Amount and Remarks Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AMOUNT (Rs.)',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: '0.00',
                        filled: true,
                        fillColor: Colors.grey[50],
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'REMARKS / NOTES',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _remarksController,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'e.g. Site transport',
                        filled: true,
                        fillColor: Colors.grey[50],
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Save Button
          SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveExpense,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.border,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _isLoading 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('SAVE EXPENSE', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
            ),
          ),

          const SizedBox(height: 25),
          const Divider(),
          const SizedBox(height: 15),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'RECENT SITE EXPENSES',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: AppColors.labelColor, letterSpacing: 1),
              ),
              if (_isFetching)
                const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.border)),
            ],
          ),
          const SizedBox(height: 15),
          
          if (_siteExpenses.isEmpty && !_isFetching)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('No expenses recorded for this project yet.', style: TextStyle(fontSize: 11, color: Colors.black38)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _siteExpenses.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final exp = _siteExpenses[index];
                final bool isOther = exp['expense_type'] == 'Other Expenses';
                final String displayType = isOther 
                    ? (exp['custom_category'] ?? 'OTHER') 
                    : (exp['expense_type'] ?? 'EXPENSE');

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayType.toString().toUpperCase(),
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: AppColors.border),
                            ),
                            if (exp['remarks'] != null && exp['remarks'].toString().isNotEmpty)
                              Text(
                                exp['remarks'],
                                style: const TextStyle(fontSize: 10, color: Colors.black45, fontWeight: FontWeight.bold),
                              ),
                            Text(
                              exp['created_at'] != null ? exp['created_at'].toString().split('T')[0] : '',
                              style: const TextStyle(fontSize: 9, color: Colors.black38),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'Rs. ${exp['amount']}',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppColors.resultGreen),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.alertRed, size: 20),
                        onPressed: () => _confirmDelete(exp),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(Map<String, dynamic> exp) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('DELETE EXPENSE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        content: Text('Are you sure you want to delete the expense: ${exp['expense_type']}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.alertRed),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final id = exp['id'];
      if (id != null) {
        final success = await WorkflowService.instance.deleteSiteExpense(id is int ? id : int.parse(id.toString()));
        if (success) {
          _loadSiteExpenses();
        }
      }
    }
  }
}
