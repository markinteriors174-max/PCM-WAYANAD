import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/client_model.dart';
import '../models/quotation.dart';
import '../providers/language_provider.dart';
import '../providers/navigation_provider.dart';
import 'calculator/calculator_screen.dart';
import 'calculator/site_measurement_screen.dart';

/// Dedicated Calculator Editing & Site Measurement Sheet Page.
/// Serves as a clean, modular screen (under 150 lines) orchestrating
/// calculator editing, project edit controllers, and room measurement cards.
class CalculatorEditingPage extends StatefulWidget {
  final Client? client;
  final Quotation? quotation;
  final String? projectId;
  final bool isEditing;
  final dynamic siteData;

  const CalculatorEditingPage({
    super.key,
    this.client,
    this.quotation,
    this.projectId,
    this.isEditing = false,
    this.siteData,
  });

  @override
  State<CalculatorEditingPage> createState() => _CalculatorEditingPageState();
}

class _CalculatorEditingPageState extends State<CalculatorEditingPage> {
  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final nav = context.watch<NavigationProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          widget.isEditing
              ? '${lang.translate('CALCULATOR')} (EDIT)'
              : 'സൈറ്റ് എഡിറ്റർ & അളവുകൾ (Calculator & Sheet)',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: Colors.brown[800],
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.calculate_outlined, color: Colors.amber),
            tooltip: 'Full Estimator Mode',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CalculatorScreen(
                    client: widget.client,
                    quotation: widget.quotation,
                    projectId: widget.projectId,
                    isEditing: widget.isEditing,
                    siteData: widget.siteData,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.rule_folder_rounded, color: Color(0xFF38BDF8)),
            tooltip: 'Site Measurement Sheet',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SiteMeasurementScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height * 0.75,
                ),
                child: CalculatorScreen(
                  client: widget.client,
                  quotation: widget.quotation,
                  projectId: widget.projectId,
                  isEditing: widget.isEditing,
                  siteData: widget.siteData,
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: const Color(0xFFD4AF37),
            unselectedItemColor: Colors.white70,
            currentIndex: nav.selectedIndex.clamp(0, 3),
            onTap: (index) {
              nav.setTab(index);
            },
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.home_outlined),
                activeIcon: const Icon(Icons.home),
                label: lang.isMalayalam ? 'ഹോം' : 'HOME',
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.folder_shared_outlined),
                activeIcon: const Icon(Icons.folder_shared),
                label: 'SITE FOLDERS',
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.calculate_outlined),
                activeIcon: const Icon(Icons.calculate),
                label: 'ESTIMATOR',
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.more_horiz_outlined),
                activeIcon: const Icon(Icons.more_horiz),
                label: 'MORE',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
