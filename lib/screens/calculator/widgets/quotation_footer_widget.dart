import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';
import '../../../providers/language_provider.dart';
import '../pdf_preview_screen.dart';
import '../../../services/pdf_service.dart';
import '../quotation_preview_controller.dart';

class QuotationFooterWidget extends StatelessWidget {
  final QuotationPreviewController ctrl;
  final LanguageProvider lang;

  const QuotationFooterWidget({super.key, required this.ctrl, required this.lang});

  @override
  Widget build(BuildContext context) {
    final q = ctrl.currentQuotation;
    if (q == null) return const SizedBox.shrink();

    final total = q.totalAmount;
    final advance = ctrl.payments.fold(0.0, (s, p) => s + p.amount);
    final balance = total - advance;

    return Column(
      children: [
        _buildLanguageControls(lang),
        const SizedBox(height: 30),
        _buildActionFooter(context, lang, advance, balance),
      ],
    );
  }

  Widget _buildLanguageControls(LanguageProvider lang) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _langBtn('EN', AppLanguage.english, lang),
        _langBtn('മലയാളം', AppLanguage.malayalam, lang),
        _langBtn('हिंदी', AppLanguage.hindi, lang),
      ],
    );
  }

  Widget _langBtn(String label, AppLanguage role, LanguageProvider lang) {
    bool active = lang.currentLanguage == role;
    return GestureDetector(
      onTap: () => lang.setLanguage(role),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: AppStyles.neumorphicDecoration(color: active ? AppColors.border : Colors.white, borderRadius: 8),
        child: Text(
          label,
          style: GoogleFonts.notoSansMalayalam(
            textStyle: TextStyle(color: active ? Colors.white : AppColors.border, fontWeight: FontWeight.w900, fontSize: 10),
          ),
        ),
      ),
    );
  }

  Future<void> _handlePdfGeneration(BuildContext context) async {
    final q = ctrl.currentQuotation!;
    final advance = ctrl.payments.fold(0.0, (s, p) => s + p.amount);
    final balance = q.totalAmount - advance;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.white)),
    );

    try {
      final bytes = await PdfService.generateQuotation(
        clientName: ctrl.nameController.text,
        clientLocation: ctrl.locationController.text,
        clientPhone: ctrl.mobileController.text,
        unitNumber: q.unitNumber,
        items: q.items,
        materials: q.materials,
        payments: ctrl.payments,
        totalAmount: q.totalAmount,
        paidAmount: advance,
        balanceAmount: balance,
        includeWastage: q.includeWastage,
        includeDigitalSignature: q.includeDigitalSignature,
        includeBankDetails: q.includeBankDetails,
        revisionNote: q.revisionNote,
        originalAmount: q.originalAmount,
        approvalSignature: q.approvalSignature,
        discountPercent: q.discount,
      );

      if (context.mounted) Navigator.pop(context);

      if (bytes != null && context.mounted) {
        final dateStr = DateFormat('dd-MM-yyyy').format(DateTime.now());
        final fileName = 'PCM_Quotation_${q.unitNumber}_$dateStr.pdf';

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PdfPreviewScreen(pdfBytes: bytes, fileName: fileName),
          ),
        );
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to generate PDF. Check your data.'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      debugPrint('PDF Generation Error: $e');
    }
  }

  Widget _buildActionFooter(BuildContext context, LanguageProvider lang, double advance, double balance) {
    final q = ctrl.currentQuotation!;
    final bool isBlocked = q.discount > 3.0;
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.black12))),
      child: Row(
        children: [
          Container(
            decoration: AppStyles.neumorphicDecoration(color: AppColors.primaryButton, borderRadius: 10),
            child: IconButton(
              icon: const Icon(Icons.volume_up, color: Colors.white, size: 28),
              onPressed: () => ctrl.speakQuotation(lang),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: isBlocked
                ? Container(
                    height: 55,
                    alignment: Alignment.center,
                    decoration: AppStyles.neumorphicDecoration(color: Colors.grey.shade400),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'PDF LOCKED',
                          style: GoogleFonts.notoSansMalayalam(
                            textStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 2),
                          ),
                        ),
                      ],
                    ),
                  )
                : GestureDetector(
                    onTap: () => _handlePdfGeneration(context),
                    child: Container(
                      height: 55,
                      alignment: Alignment.center,
                      decoration: AppStyles.neumorphicDecoration(color: AppColors.primaryButton),
                      child: Text(
                        'GENERATE PDF',
                        style: GoogleFonts.notoSansMalayalam(
                          textStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 2),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
