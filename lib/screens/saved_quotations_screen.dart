import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/quotation.dart';
import '../services/database_service.dart';
import '../widgets/custom_app_bar.dart';
import '../theme/app_theme.dart';
import '../utils/calculator_utils.dart';
import '../services/customer_sync_service.dart';

class SavedQuotationsScreen extends StatefulWidget {
  const SavedQuotationsScreen({super.key});

  @override
  State<SavedQuotationsScreen> createState() => _SavedQuotationsScreenState();
}

class _SavedQuotationsScreenState extends State<SavedQuotationsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Quotation> _quotations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuotations();
  }

  Future<void> _loadQuotations() async {
    setState(() => _isLoading = true);
    final data = await DatabaseService.instance.getQuotations(
      query: _searchController.text,
    );
    setState(() {
      _quotations = data;
      _isLoading = false;
    });
  }

  void _playClickSound() {}

  Future<void> _pinLocation(Quotation quotation) async {
    _playClickSound();
    
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enable location services.')));
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    final position = await Geolocator.getCurrentPosition();
    
    final updatedQuotation = Quotation(
      id: quotation.id,
      unitNumber: quotation.unitNumber,
      clientName: quotation.clientName,
      clientPhone: quotation.clientPhone,
      clientLocation: quotation.clientLocation,
      date: quotation.date,
      totalAmount: quotation.totalAmount,
      paidAmount: quotation.paidAmount,
      balanceAmount: quotation.balanceAmount,
      items: quotation.items,
      materials: quotation.materials,
      rentals: quotation.rentals,
      latitude: position.latitude,
      longitude: position.longitude,
    );

    await DatabaseService.instance.updateQuotation(updatedQuotation);
    _loadQuotations();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.border,
          content: Text('SITE LOCATION PINNED SUCCESSFULLY'),
        ),
      );
    }
  }

  void _deleteQuotation(int id) async {
    _playClickSound();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(side: BorderSide(color: AppColors.border, width: 2), borderRadius: BorderRadius.circular(15)),
        title: const Text('Delete Quotation?', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.border)),
        content: const Text('This action cannot be undone.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL', style: TextStyle(color: Colors.black45, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.alertRed, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DatabaseService.instance.deleteQuotation(id);
      _loadQuotations();
    }
  }

  void _showEditDetailsDialog(Quotation quotation) {
    final nameController = TextEditingController(text: quotation.clientName);
    final unitController = TextEditingController(text: quotation.unitNumber);
    String selectedStatus = quotation.projectStatus;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: AppColors.background,
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: AppColors.border, width: 2),
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            'Edit Details',
            style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.border),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: AppStyles.inputDecoration('Room / Project Name'),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 15),
              TextField(
                controller: unitController,
                decoration: AppStyles.inputDecoration('Room Number'),
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                initialValue: selectedStatus,
                decoration: AppStyles.inputDecoration('Project Status'),
                dropdownColor: Colors.white,
                items: ['Planning', 'Framing', 'Board Fixing', 'Finishing', 'Completed']
                    .map((status) => DropdownMenuItem<String>(
                          value: status,
                          child: Text(
                            status,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setStateDialog(() {
                      selectedStatus = val;
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'CANCEL',
                style: TextStyle(color: Colors.black45, fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryButton,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                final newName = nameController.text.trim();
                final newUnit = unitController.text.trim();

                if (newName.isEmpty || newUnit.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill in all fields'),
                      backgroundColor: AppColors.alertRed,
                    ),
                  );
                  return;
                }

                final updated = quotation.copyWith(
                  clientName: newName,
                  unitNumber: newUnit,
                  projectStatus: selectedStatus,
                );

                await DatabaseService.instance.updateQuotation(updated);
                
                // Sync to cloud so client dashboard sees immediate updates
                try {
                  await CustomerSyncService.instance.saveQuotationToCloud(updated);
                } catch (e) {
                  debugPrint('Error syncing updated quotation to cloud: $e');
                }

                if (context.mounted) Navigator.pop(context);
                _loadQuotations();
              },
              child: const Text('SAVE'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => _loadQuotations(),
              decoration: AppStyles.inputDecoration('Search by Unit No or Client...').copyWith(
                prefixIcon: const Icon(Icons.search, color: AppColors.border),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.border))
                : _quotations.isEmpty
                    ? const Center(child: Text('No quotations found.', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.labelColor)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                        itemCount: _quotations.length,
                        itemBuilder: (context, index) {
                          final q = _quotations[index];
                          return _buildQuotationCard(q);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Framing':
        return Colors.orange.shade700;
      case 'Board Fixing':
        return Colors.blue.shade700;
      case 'Finishing':
        return Colors.purple.shade700;
      case 'Completed':
        return Colors.green.shade700;
      case 'Planning':
      default:
        return Colors.grey.shade600;
    }
  }

  Widget _buildQuotationCard(Quotation quotation) {
    bool hasPin = quotation.latitude != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: AppStyles.neumorphicDecoration(color: Colors.white, hasThickBorder: true),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        'UNIT: ${quotation.unitNumber}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(quotation.projectStatus),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        quotation.projectStatus.toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.edit, color: AppColors.border, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _showEditDetailsDialog(quotation),
                    ),
                  ],
                ),
                Text(
                  quotation.date,
                  style: const TextStyle(color: Colors.black45, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Text(
              quotation.clientName.toUpperCase(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.border, letterSpacing: 0.5),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.location_on, size: 14, color: AppColors.labelColor),
                const SizedBox(width: 4),
                Text(quotation.clientLocation, style: const TextStyle(color: AppColors.labelColor, fontSize: 12, fontWeight: FontWeight.bold)),
                if (hasPin) ...[
                  const Spacer(),
                  const Icon(Icons.gps_fixed, size: 12, color: AppColors.resultGreen),
                  const SizedBox(width: 4),
                  const Text('PINNED', style: TextStyle(color: AppColors.resultGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ],
            ),
            const SizedBox(height: 15),
            const Divider(height: 1, thickness: 1, color: Colors.black12),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TOTAL AMOUNT', style: TextStyle(color: AppColors.labelColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    Text(
                      '₹${CalculatorUtils.formatIndianCurrency(quotation.totalAmount)}',
                      style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.border, fontSize: 18),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('BALANCE', style: TextStyle(color: AppColors.labelColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    Text(
                      '₹${CalculatorUtils.formatIndianCurrency(quotation.balanceAmount)}',
                      style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.alertRed, fontSize: 18),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _buildActionLabel(
                  icon: Icons.pin_drop, 
                  label: hasPin ? 'RE-PIN SITE' : 'PIN SITE', 
                  onTap: () => _pinLocation(quotation),
                  isAccent: !hasPin,
                ),
                const Spacer(),
                _buildSmallActionIcon(Icons.edit, () {
                  _playClickSound();
                  Navigator.pop(context, quotation);
                }),
                const SizedBox(width: 12),
                _buildSmallActionIcon(Icons.delete, () => _deleteQuotation(quotation.id!), isRed: true),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionLabel({required IconData icon, required String label, required VoidCallback onTap, bool isAccent = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          color: isAccent ? AppColors.border : Colors.transparent,
          border: Border.all(color: AppColors.border, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: isAccent ? Colors.white : AppColors.border),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: isAccent ? Colors.white : AppColors.border)),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallActionIcon(IconData icon, VoidCallback onTap, {bool isRed = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isRed ? AppColors.alertRed.withValues(alpha: 0.05) : AppColors.border.withValues(alpha: 0.05),
          border: Border.all(color: isRed ? AppColors.alertRed : AppColors.border, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: isRed ? AppColors.alertRed : AppColors.border, size: 22),
      ),
    );
  }
}
