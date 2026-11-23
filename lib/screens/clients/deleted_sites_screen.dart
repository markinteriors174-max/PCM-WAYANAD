import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/client_model.dart';
import '../../services/client_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/calculator_utils.dart';
import '../../widgets/custom_app_bar.dart';

class DeletedSitesScreen extends StatefulWidget {
  const DeletedSitesScreen({super.key});

  @override
  State<DeletedSitesScreen> createState() => _DeletedSitesScreenState();
}

class _DeletedSitesScreenState extends State<DeletedSitesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _restoreSite(Client client) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.white)),
    );

    try {
      await ClientService.instance.restoreClient(client);
      if (mounted) {
        Navigator.pop(context); // Close progress dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Site folder ${client.unitNumber} restored to active Site Folders!'),
            backgroundColor: AppColors.resultGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      debugPrint('Error restoring client: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error restoring site: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _permanentlyDeleteSite(Client client) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Colors.red, width: 2),
          borderRadius: BorderRadius.circular(15),
        ),
        title: const Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.red, size: 28),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Permanently Delete?',
                style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.border, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete site folder ${client.unitNumber} (${client.clientName})? This cannot be undone.',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL', style: TextStyle(color: Colors.black45, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('PERMANENT DELETE', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ClientService.instance.permanentlyDeleteClient(client.id, unitNumber: client.unitNumber);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Site folder ${client.unitNumber} permanently deleted.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        debugPrint('Error permanently deleting client: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(
        title: 'TRASH BIN / DELETED SITES',
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('deleted_projects').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppColors.border));
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading deleted sites: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          final clients = docs.map((doc) => Client.fromMap(doc.data(), doc.id)).toList();

          // Sort by createdAt descending
          clients.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          // Search filter
          List<Client> filteredList = clients;
          if (_searchQuery.isNotEmpty) {
            final q = _searchQuery.toLowerCase();
            filteredList = filteredList.where((c) {
              return c.clientName.toLowerCase().contains(q) ||
                  c.phoneNumber.toLowerCase().contains(q) ||
                  c.siteLocation.toLowerCase().contains(q) ||
                  c.unitNumber.toLowerCase().contains(q);
            }).toList();
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(25, 20, 25, 10),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TRASH BIN',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.labelColor,
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'DELETED SITES',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: AppColors.border,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.trim();
                    });
                  },
                  decoration: AppStyles.inputDecoration('Search deleted sites...').copyWith(
                    prefixIcon: const Icon(Icons.search, color: AppColors.border),
                  ),
                ),
              ),
              Expanded(
                child: filteredList.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.delete_sweep_outlined, size: 60, color: Colors.grey),
                            SizedBox(height: 15),
                            Text(
                              'Trash is Empty',
                              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.labelColor, fontSize: 16),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'No deleted site folders found.',
                              style: TextStyle(color: Colors.black45, fontSize: 12),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) {
                          final item = filteredList[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 15),
                            padding: const EdgeInsets.all(16),
                            decoration: AppStyles.neumorphicDecoration(color: Colors.white, hasThickBorder: true),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.clientName.toUpperCase(),
                                        style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.labelColor, fontSize: 14),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: Colors.red.shade200),
                                      ),
                                      child: const Text(
                                        'DELETED',
                                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.w900, fontSize: 9),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text('SITE ID: ${item.unitNumber}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.border)),
                                if (item.siteLocation.isNotEmpty)
                                  Text('LOCATION: ${item.siteLocation}', style: const TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Text(
                                      'Amount: ₹${CalculatorUtils.formatIndianCurrency(item.totalContractAmount)}',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.resultGreen),
                                    ),
                                    const SizedBox(width: 15),
                                    Text(
                                      'Paid: ₹${CalculatorUtils.formatIndianCurrency(item.advanceReceived)}',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Divider(height: 1),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.resultGreen,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        icon: const Icon(Icons.restore, size: 16),
                                        label: const Text('RESTORE SITE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                        onPressed: () => _restoreSite(item),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.red,
                                          side: const BorderSide(color: Colors.red, width: 1.5),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        icon: const Icon(Icons.delete_forever, size: 16),
                                        label: const Text('PERMANENT DELETE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                                        onPressed: () => _permanentlyDeleteSite(item),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
