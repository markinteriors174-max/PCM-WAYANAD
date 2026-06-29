import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../providers/language_provider.dart';
import 'calculator_controller.dart';
import 'project_edit_controller.dart';
import 'widgets/calculator_client_info_widget.dart';
import 'widgets/calculator_inputs_widget.dart';
import 'widgets/calculator_table_widget.dart';
import 'widgets/calculator_summary_widget.dart';
import 'widgets/calculator_payments_widget.dart';
import 'widgets/calculator_revision_widget.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => CalculatorScreenState();
}

class CalculatorScreenState extends State<CalculatorScreen> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late CalculatorController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = CalculatorController();
    _ctrl.initLoad(() {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Customer Data Synced!'), backgroundColor: AppColors.primaryButton),
        );
      }
    });
    _ctrl.addListener(() => setState(() {}));
    ProjectEditController.instance.addListener(_handleProjectEditRequest);
  }

  void _handleProjectEditRequest() {
    final pendingId = ProjectEditController.instance.pendingProjectId;
    final pendingClient = ProjectEditController.instance.pendingClient;

    if (pendingId != null && mounted) {
      if (pendingClient != null) {
        _ctrl.clientNameController.text = pendingClient.clientName;
        _ctrl.clientPhoneController.text = pendingClient.phoneNumber;
        _ctrl.clientLocationController.text = pendingClient.siteLocation;
        _ctrl.unitNumberController.text = pendingClient.unitNumber;
      }

      _ctrl.loadProject(pendingId, () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Project Loaded!'), backgroundColor: AppColors.primaryButton),
          );
        }
      });
      ProjectEditController.instance.clearRequest();
    }
  }

  @override
  void dispose() {
    ProjectEditController.instance.removeListener(_handleProjectEditRequest);
    _ctrl.disposeAll();
    _ctrl.dispose();
    super.dispose();
  }

  void _showClearConfirmation() {
    showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text('Reset Everything?'),
      content: const Text('This will clear the current site progress.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
        ElevatedButton(onPressed: () { 
          _ctrl.startNewProject(); 
          Navigator.pop(context); 
        }, style: ElevatedButton.styleFrom(backgroundColor: AppColors.alertRed), child: const Text('RESET')),
      ],
    ));
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5, color: AppColors.labelColor)),
        ),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: AppStyles.neumorphicDecoration(color: Colors.white, hasThickBorder: true),
          child: child,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final lang = context.watch<LanguageProvider>();
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final bool? shouldPop = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
          backgroundColor: AppColors.background,
          title: Text(lang.translate('CALCULATOR'), style: const TextStyle(fontWeight: FontWeight.bold)),
          content: const Text('Exit current session? All work is auto-saved locally.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('STAY')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryButton, foregroundColor: Colors.white), child: const Text('EXIT')),
          ],
        ));
        if (shouldPop == true && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        resizeToAvoidBottomInset: true, 
        appBar: CustomAppBar(
          title: lang.translate('REGISTER'),
          actions: [
            if (_ctrl.showSavedIndicator) 
              const Center(child: Padding(padding: EdgeInsets.only(right: 8), child: Row(children: [
                Icon(Icons.check_circle, color: AppColors.resultGreen, size: 16),
                SizedBox(width: 4),
                Text('SAVED', style: TextStyle(color: AppColors.resultGreen, fontSize: 10, fontWeight: FontWeight.bold)),
              ]))),
            IconButton(icon: const Icon(Icons.language, color: Colors.white), onPressed: () => lang.toggleLanguage()),
            IconButton(icon: const Icon(Icons.cleaning_services, color: Colors.white), onPressed: _showClearConfirmation),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(
              left: 20, right: 20, top: 20, 
              bottom: 120, // FIX: Removed MediaQuery.of(context).viewInsets.bottom to prevent double-pushing content when keyboard is open
            ), 
            child: Column(
              children: [
                _buildSection(title: 'SITE & CLIENT', child: CalculatorClientInfoWidget(ctrl: _ctrl, lang: lang)),
                const SizedBox(height: 20),
                _buildSection(title: 'DIMENSIONS & RATES', child: CalculatorInputsWidget(ctrl: _ctrl, lang: lang, onStateChanged: () {})),
                const SizedBox(height: 30),
                CalculatorTableWidget(ctrl: _ctrl, onStateChanged: () {}),
                const SizedBox(height: 30),
                CalculatorSummaryWidget(ctrl: _ctrl, lang: lang, onStateChanged: () {}),
                const SizedBox(height: 30),
                CalculatorPaymentsWidget(ctrl: _ctrl, lang: lang),
                const SizedBox(height: 30),
                CalculatorRevisionWidget(ctrl: _ctrl, lang: lang),
                const SizedBox(height: 30),
                CalculatorStickyActionsWidget(ctrl: _ctrl, lang: lang),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
