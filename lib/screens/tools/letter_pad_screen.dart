import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../services/pdf_service.dart';

class LetterPadScreen extends StatefulWidget {
  const LetterPadScreen({super.key});

  @override
  State<LetterPadScreen> createState() => _LetterPadScreenState();
}

class _LetterPadScreenState extends State<LetterPadScreen> {
  final _titleController = TextEditingController(text: 'FORMAL QUOTATION APPLICATION');
  final _contentController = TextEditingController();
  final _clientNameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'PCM LETTER PAD',
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: AppColors.border),
            onPressed: _exportToPdf,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('FORMAL LETTER GENERATOR', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 2, color: AppColors.border)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(25),
              decoration: AppStyles.neumorphicDecoration(color: Colors.white, hasThickBorder: true),
              child: Column(
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: AppStyles.inputDecoration('Subject / Title'),
                    style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.border),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _clientNameController,
                    decoration: AppStyles.inputDecoration('Recipient Name'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _contentController,
                    maxLines: 15,
                    decoration: AppStyles.inputDecoration('Letter Content').copyWith(
                      hintText: 'Type your formal application or detailed quotation notes here...',
                    ),
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            GestureDetector(
              onTap: _exportToPdf,
              child: Container(
                height: 60,
                width: double.infinity,
                decoration: AppStyles.neumorphicDecoration(color: AppColors.primaryButton, hasThickBorder: true),
                alignment: Alignment.center,
                child: const Text('GENERATE FORMAL PDF', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _exportToPdf() {
    if (_contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter letter content first.')));
      return;
    }
    // Logic to call PdfService for generic text/letterpad
    PdfService.generateLetterPad(
      title: _titleController.text,
      recipient: _clientNameController.text,
      content: _contentController.text,
    );
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Letter Exported to PDF Successfully'), backgroundColor: AppColors.primaryButton));
  }
}
