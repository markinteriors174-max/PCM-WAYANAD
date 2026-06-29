import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/database_service.dart';
import '../../models/quotation.dart';
import 'project_edit_controller.dart';
import '../../providers/navigation_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('SITE FOLDERS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.white)),
        backgroundColor: AppColors.border,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync, color: Colors.white),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(() {}),
        color: AppColors.border,
        child: FutureBuilder<List<Quotation>>(
          future: DatabaseService.instance.getQuotations(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator(color: AppColors.border));
            }
            final items = snapshot.data ?? [];
            if (items.isEmpty) {
              return ListView( // ListView for RefreshIndicator to work
                children: const [
                  SizedBox(height: 100),
                  Center(child: Text('No projects saved yet.', style: TextStyle(color: Colors.black45, fontWeight: FontWeight.bold))),
                ],
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final q = items[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  decoration: AppStyles.neumorphicDecoration(color: Colors.white, hasThickBorder: true),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(q.clientName.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.labelColor, fontSize: 13, letterSpacing: 0.5))),
                        Text('₹${q.totalAmount.toInt()}', style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.resultGreen, fontSize: 16)),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 5),
                        Text('ID: ${q.unitNumber}', style: const TextStyle(fontSize: 10, color: Colors.black45, fontWeight: FontWeight.bold)),
                        Text('SITE: ${q.clientLocation}', style: const TextStyle(fontSize: 10, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            _buildMiniBadge(Icons.straighten, '${q.items.length} ITEMS', Colors.blue),
                            _buildMiniBadge(Icons.payments, '${q.payments.length} PAID', Colors.orange),
                            if (q.projectStatus != 'Planning') 
                               _buildMiniBadge(Icons.check_circle, q.projectStatus.toUpperCase(), Colors.green),
                          ],
                        ),
                      ],
                    ),
                    onTap: () {
                      ProjectEditController.instance.requestEdit(q.id.toString());
                      context.read<NavigationProvider>().setTab(2);
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildMiniBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }
}
