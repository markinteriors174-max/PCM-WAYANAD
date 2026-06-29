import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../widgets/custom_app_bar.dart';
import '../../theme/app_theme.dart';
import '../../models/rental_model.dart';
import '../../services/rental_service.dart';

class RentalModuleScreen extends StatefulWidget {
  const RentalModuleScreen({super.key});

  @override
  State<RentalModuleScreen> createState() => _RentalModuleScreenState();
}

class _RentalModuleScreenState extends State<RentalModuleScreen> {
  final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
  final dateFormat = DateFormat('dd MMM yyyy');

  void _playClickSound() {}

  Future<void> _showAddRentalDialog() async {
    final itemNameController = TextEditingController();
    final siteNameController = TextEditingController();
    final rateController = TextEditingController();
    final qtyController = TextEditingController(text: '1');
    DateTime selectedDate = DateTime.now();

    return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final rate = double.tryParse(rateController.text) ?? 0;
            final qty = double.tryParse(qtyController.text) ?? 0;
            final days = DateTime.now().difference(selectedDate).inDays + 1;
            final runningTotal = days * rate * qty;

            return AlertDialog(
              backgroundColor: AppColors.background,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: AppColors.border, width: 2)),
              title: const Text('NEW RENTAL RECORD', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, color: AppColors.border)),
              content: SingleChildScrollView(
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTextField(itemNameController, 'Item Name (e.g. Scaffolding)', Icons.inventory),
                    const SizedBox(height: 12),
                    _buildTextField(siteNameController, 'Site / Project Name', Icons.location_on),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildTextField(rateController, 'Daily Rate', Icons.currency_rupee, isNumber: true, onChanged: (v) => setDialogState(() {}))),
                        const SizedBox(width: 10),
                        Expanded(child: _buildTextField(qtyController, 'Quantity', Icons.numbers, isNumber: true, onChanged: (v) => setDialogState(() {}))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      enableFeedback: false,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setDialogState(() => selectedDate = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.border, width: 1.5),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 20, color: AppColors.border),
                            const SizedBox(width: 10),
                            Text('START DATE: ${dateFormat.format(selectedDate)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      width: double.infinity,
                      decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(8)),
                      child: Column(
                        children: [
                          const Text('LIVE ESTIMATE', style: TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 5),
                          Text(
                            '${currencyFormat.format(runningTotal)} ($days Days)',
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCEL', style: TextStyle(color: Colors.black45, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (itemNameController.text.isEmpty || rateController.text.isEmpty) return;
                    _playClickSound();
                    
                    final newRental = RentalRecord(
                      id: '',
                      itemName: itemNameController.text,
                      siteName: siteNameController.text,
                      startDate: selectedDate,
                      dailyRate: rate,
                      quantity: qty,
                    );
                    
                    await RentalService.instance.addRental(newRental);
                    if (context.mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryButton, foregroundColor: Colors.white),
                  child: const Text('SAVE RECORD'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isNumber = false, Function(String)? onChanged}) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: AppStyles.inputDecoration(label).copyWith(
        prefixIcon: Icon(icon, size: 20, color: AppColors.border),
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
          Container(
            padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Premium Accounting', style: TextStyle(fontSize: 12, color: AppColors.labelColor, letterSpacing: 2, fontWeight: FontWeight.bold)),
                Text('RENTAL CALCULATOR', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.border, letterSpacing: 1)),
                const SizedBox(height: 5),
                const Divider(color: AppColors.border, thickness: 3),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<RentalRecord>>(
              stream: RentalService.instance.getRentals(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.border));
                }
                
                final rentals = snapshot.data ?? [];
                
                if (rentals.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long, size: 64, color: AppColors.border.withValues(alpha: 0.3)),
                        const SizedBox(height: 10),
                        const Text('No rental records found', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  itemCount: rentals.length,
                  itemBuilder: (context, index) {
                    final rental = rentals[index];
                    return Container(
                      padding: const EdgeInsets.all(18),
                      margin: const EdgeInsets.only(bottom: 15),
                      decoration: AppStyles.neumorphicDecoration(color: Colors.white, hasThickBorder: true),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: const BoxDecoration(color: AppColors.border, shape: BoxShape.circle),
                                child: const Icon(Icons.handyman, color: Colors.white, size: 24),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${rental.itemName.toUpperCase()} (${rental.quantity.toInt()} QTY)',
                                      style: const TextStyle(color: AppColors.border, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.5),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'SITE: ${rental.siteName}',
                                      style: const TextStyle(color: AppColors.labelColor, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      'TAKEN: ${dateFormat.format(rental.startDate)}',
                                      style: TextStyle(color: AppColors.labelColor.withValues(alpha: 0.6), fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${rental.totalDays} DAYS',
                                    style: const TextStyle(color: AppColors.border, fontWeight: FontWeight.w900, fontSize: 12),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: AppColors.primaryButton, borderRadius: BorderRadius.circular(4)),
                                    child: const Text('ACTIVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 9)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Divider(height: 25, color: Colors.black12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('RUNNING TOTAL RENT:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1, color: AppColors.labelColor)),
                              Text(
                                currencyFormat.format(rental.runningTotalCost),
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppColors.resultGreen),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _playClickSound();
          _showAddRentalDialog();
        },
        backgroundColor: AppColors.border,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        icon: const Icon(Icons.add, color: Colors.white, size: 28),
        label: const Text('NEW RENTAL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1)),
      ),
    );
  }
}
