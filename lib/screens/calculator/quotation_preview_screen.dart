import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/quotation.dart';
import '../../theme/app_theme.dart';
import '../../providers/language_provider.dart';
import 'quotation_preview_controller.dart';
import 'widgets/quotation_header_widget.dart';
import 'widgets/quotation_body_widget.dart';
import 'widgets/quotation_footer_widget.dart';

class QuotationPreviewScreen extends StatefulWidget {
  final Quotation? quotation;
  const QuotationPreviewScreen({super.key, this.quotation});

  @override
  State<QuotationPreviewScreen> createState() => _QuotationPreviewScreenState();
}

class _QuotationPreviewScreenState extends State<QuotationPreviewScreen> {
  late QuotationPreviewController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = QuotationPreviewController()..initLoad(widget.quotation);
    _ctrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ctrl.disposeAll();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(lang.translate('QUOTATION'), style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
        backgroundColor: AppColors.border,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _ctrl.loadLatestData),
        ],
      ),
      body: _buildBody(lang),
    );
  }

  Widget _buildBody(LanguageProvider lang) {
    if (_ctrl.isLoading) return const Center(child: CircularProgressIndicator());
    if (_ctrl.currentQuotation == null) return const Center(child: Text('Please save a project first.'));

    return Column(
      children: [
        QuotationHeaderWidget(unitId: _ctrl.currentQuotation!.unitNumber),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(25),
            child: Column(
              children: [
                QuotationBodyWidget(ctrl: _ctrl, onStateChanged: () => setState(() {})),
                const SizedBox(height: 30),
                QuotationFooterWidget(ctrl: _ctrl, lang: lang),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
