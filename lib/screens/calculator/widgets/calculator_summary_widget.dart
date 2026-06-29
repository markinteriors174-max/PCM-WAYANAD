import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../theme/app_theme.dart';
import '../../calculator/calculator_controller.dart';
import '../../../providers/language_provider.dart';
import '../../../models/quotation.dart';
import '../../../services/pdf_service.dart';
import '../../../services/material_engine.dart';
import '../../../utils/calculator_utils.dart';
import '../../../services/customer_sync_service.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../models/client_model.dart';
import '../../../services/client_service.dart';
import 'package:provider/provider.dart';
import '../../../providers/navigation_provider.dart';

class CalculatorSummaryWidget extends StatelessWidget {
  final CalculatorController ctrl;
  final LanguageProvider lang;
  final VoidCallback onStateChanged;

  const CalculatorSummaryWidget({super.key, required this.ctrl, required this.lang, required this.onStateChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: AppStyles.neumorphicDecoration(color: AppColors.border),
      child: Column(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Include 5% Wastage Buffer', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            Switch(
              value: ctrl.includeWastage,
              activeThumbColor: AppColors.resultGreen,
              onChanged: (val) {
                ctrl.includeWastage = val;
                ctrl.updateProjectTotals();
                ctrl.triggerAutoSave();
                onStateChanged();
              },
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Discount (%)', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            SizedBox(
              width: 100,
              height: 40,
              child: TextField(
                controller: ctrl.discountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.right,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                decoration: InputDecoration(
                  hintText: '0',
                  hintStyle: const TextStyle(color: Colors.white54),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.15),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (val) {
                  ctrl.updateProjectTotals();
                  ctrl.triggerAutoSave();
                  onStateChanged();
                },
              ),
            ),
          ],
        ),
        if (ctrl.discountPercent > 0) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Discount Amount', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
              Text(
                '-₹${CalculatorUtils.formatIndianCurrency(ctrl.projectDiscountAmount)}',
                style: TextStyle(
                  color: ctrl.discountPercent <= 3.0 ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F),
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
        if (ctrl.discountPercent > 3.0) ...[
          const SizedBox(height: 15),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.shade900.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.redAccent, width: 1),
            ),
            child: Text(
              'ഡിസ്കൗണ്ട് 3% പരിധി കവിഞ്ഞു! ഷെയറിംഗ് പ്രവർത്തനരഹിതമാക്കി.',
              style: GoogleFonts.notoSansMalayalam(
                textStyle: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 11),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Include Digital Signature on PDF', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            Switch(
              value: ctrl.includeDigitalSignature,
              activeThumbColor: AppColors.resultGreen,
              onChanged: (val) {
                if (val) {
                  _showPinVerificationDialog(context);
                } else {
                  ctrl.includeDigitalSignature = false;
                  ctrl.updateProjectTotals();
                  ctrl.triggerAutoSave();
                  onStateChanged();
                }
              },
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Include Bank Details on PDF', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            Switch(
              value: ctrl.includeBankDetails,
              activeThumbColor: AppColors.resultGreen,
              onChanged: (val) {
                ctrl.includeBankDetails = val;
                ctrl.updateProjectTotals();
                ctrl.triggerAutoSave();
                onStateChanged();
              },
            ),
          ],
        ),
        const SizedBox(height: 10),
        const Text('GRAND SQFT', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 10)),
        const SizedBox(height: 5),
        Text('${ctrl.projectTotalAreaSqFt.toStringAsFixed(2)} SQFT', style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        Text(
          lang.translate('GRAND TOTAL'),
          style: GoogleFonts.notoSansMalayalam(
            textStyle: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 10),
          ),
        ),
        const SizedBox(height: 5),
        Text('₹${CalculatorUtils.formatIndianCurrency(ctrl.projectTotalAmount)}', style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w900)),
        const Divider(color: Colors.white24, height: 35),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.account_balance_wallet_outlined, color: Colors.white70, size: 20),
          const SizedBox(width: 12),
          Text(
            'BALANCE: ₹${CalculatorUtils.formatIndianCurrency(ctrl.balanceAmount)}',
            style: GoogleFonts.notoSansMalayalam(
              textStyle: const TextStyle(color: AppColors.background, fontWeight: FontWeight.w900, fontSize: 20),
            ),
          ),
        ]),
      ]),
    );
  }

  void _showPinVerificationDialog(BuildContext context) {
    final pinController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppColors.border, width: 2),
          borderRadius: BorderRadius.circular(15),
        ),
        title: const Row(
          children: [
            Icon(Icons.security, color: AppColors.border),
            SizedBox(width: 10),
            Text('Security Verification', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.border)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Please enter your secure PIN to inject the Digital Signature into this PDF quotation.',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: pinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 10),
              decoration: AppStyles.inputDecoration('ENTER 4-DIGIT PIN'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.black45, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.border,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              final savedPin = prefs.getString('security_pin') ?? '2025';
              
              if (pinController.text == savedPin) {
                if (context.mounted) Navigator.pop(context);
                ctrl.includeDigitalSignature = true;
                ctrl.updateProjectTotals();
                ctrl.triggerAutoSave();
                onStateChanged();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('DIGITAL SIGNATURE VERIFIED & INJECTED'),
                      backgroundColor: AppColors.resultGreen,
                    ),
                  );
                }
              } else {
                if (context.mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('INVALID PIN! ACCESS DENIED.'),
                      backgroundColor: AppColors.alertRed,
                    ),
                  );
                }
              }
            },
            child: const Text('VERIFY & INJECT'),
          ),
        ],
      ),
    );
  }
}

class CalculatorStickyActionsWidget extends StatelessWidget {
  final CalculatorController ctrl;
  final LanguageProvider lang;

  const CalculatorStickyActionsWidget({super.key, required this.ctrl, required this.lang});

  @override
  Widget build(BuildContext context) {
    final bool isBlocked = ctrl.discountPercent > 3.0;

    return Column(children: [
      TextField(controller: ctrl.manualWeightController, keyboardType: TextInputType.number, decoration: AppStyles.inputDecoration('Manual Weight (Kg)'), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.border), onChanged: (_) => ctrl.triggerAutoSave()),
      if (!isBlocked) ...[
        const SizedBox(height: 25),
        Row(
          children: [
            Expanded(
              child: _buildActionBtn(
                text: lang.translate('GENERATE PDF'), 
                color: AppColors.primaryButton, 
                icon: Icons.picture_as_pdf,
                onTap: () => _generatePdf(context)
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildActionBtn(
                text: lang.translate('VIEW PDF'), 
                color: AppColors.border, 
                icon: Icons.visibility,
                onTap: () => _viewPdf(context)
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        _buildActionBtn(
          text: 'SAVE QUOTATION & PAYMENTS',
          color: AppColors.resultGreen,
          icon: Icons.cloud_upload,
          onTap: () => _saveQuotationAndPaymentsToCloud(context),
        ),
        const SizedBox(height: 15),
        _buildActionBtn(
          text: 'SHARE QUOTATION',
          color: const Color(0xFF1976D2),
          icon: Icons.share,
          onTap: () => _sharePdf(context),
        ),
      ] else ...[
        const SizedBox(height: 25),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, color: Colors.red),
              SizedBox(width: 10),
              Text(
                'SHARING LOCKED due to high discount',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    ]);
  }

  Future<void> _saveQuotationAndPaymentsToCloud(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.white)),
    );

    try {
      await ctrl.saveToDatabase(showSnackBar: false);
      
      final currentQuota = Quotation(
        id: ctrl.activeProjectId, 
        unitNumber: ctrl.unitNumberController.text.trim(),
        clientName: ctrl.clientNameController.text.trim().isEmpty ? 'SITE DRAFT' : ctrl.clientNameController.text.trim(),
        clientPhone: ctrl.clientPhoneController.text.trim(), 
        clientLocation: ctrl.clientLocationController.text.trim(),
        locationFolder: ctrl.folderController.text.trim().isNotEmpty ? ctrl.folderController.text.trim() : ctrl.clientLocationController.text.trim(),
        date: DateFormat('dd-MM-yyyy hh:mm a').format(DateTime.now()),
        totalAmount: ctrl.projectTotalAmount, 
        paidAmount: ctrl.currentPayments.fold(0.0, (s, p) => s + p.amount), 
        balanceAmount: ctrl.balanceAmount,
        items: List.from(ctrl.currentItems),
        materials: MaterialEngine.calculateBOM(ctrl.currentItems),
        payments: ctrl.currentPayments,
        manualAmount: double.tryParse(ctrl.manualAmountController.text) ?? 0,
        manualWeight: double.tryParse(ctrl.manualWeightController.text) ?? 0,
        originalAmount: double.tryParse(ctrl.originalAmountController.text),
        revisionNote: ctrl.revisionNoteController.text.trim().isNotEmpty ? ctrl.revisionNoteController.text.trim() : null,
        globalMaterialCost: double.tryParse(ctrl.globalMaterialCostController.text) ?? 0.0,
        globalMargin: double.tryParse(ctrl.globalMarginController.text) ?? 0.0,
        discount: ctrl.discountPercent,
        projectStatus: ctrl.projectStatus,
        approvalSignature: ctrl.approvalSignature,
        includeWastage: ctrl.includeWastage,
        includeDigitalSignature: ctrl.includeDigitalSignature,
        includeBankDetails: ctrl.includeBankDetails,
      );

      await CustomerSyncService.instance.saveQuotationToCloud(currentQuota);

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        
        // Reset the creation state to prevent stuck session / editing old project ID
        ctrl.startNewProject();
        
        // Force navigation to the newly generated project page/list
        final nav = Provider.of<NavigationProvider>(context, listen: false);
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          nav.setTab(1);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('QUOTATION & PAYMENTS SAVED TO CLOUD SUCCESSFULLY'),
            backgroundColor: AppColors.resultGreen,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('FAILED TO SAVE TO CLOUD: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sharePdf(BuildContext context) async {
    final String? selectedPhoneNumber = await showDialog<String>(
      context: context,
      builder: (context) {
        final phoneCtrl = TextEditingController(text: ctrl.clientPhoneController.text);
        Client? chosenClient;

        return AlertDialog(
          backgroundColor: AppColors.background,
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: AppColors.border, width: 2),
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            'Targeted PDF Delivery',
            style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.border),
            textAlign: TextAlign.center,
          ),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select a registered client or type the phone number below:',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54),
                  ),
                  const SizedBox(height: 15),
                  StreamBuilder<List<Client>>(
                    stream: ClientService.instance.getClients(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator(color: AppColors.border));
                      }
                      final clients = snapshot.data!;
                      return DropdownButtonFormField<Client>(
                        decoration: AppStyles.inputDecoration('Select Registered Client'),
                        dropdownColor: Colors.white,
                        initialValue: chosenClient,
                        items: clients.map((c) {
                          return DropdownMenuItem<Client>(
                            value: c,
                            child: Text(
                              '${c.clientName} (${c.unitNumber})',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              chosenClient = val;
                              phoneCtrl.text = val.phoneNumber;
                            });
                          }
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: AppStyles.inputDecoration('Deliver to Phone Number *'),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('CANCEL', style: TextStyle(color: Colors.black45, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.border,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                final target = phoneCtrl.text.trim();
                if (target.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a target phone number.'), backgroundColor: AppColors.alertRed),
                  );
                  return;
                }
                Navigator.pop(context, target);
              },
              child: const Text('DELIVER PDF'),
            ),
          ],
        );
      },
    );

    if (selectedPhoneNumber == null) return;

    try {
      await ctrl.saveToDatabase();
    } catch (e) {
      debugPrint('Database Save Error: $e');
    }

    ctrl.clientPhoneController.text = selectedPhoneNumber;

    final currentQuota = Quotation(
      id: ctrl.activeProjectId, 
      unitNumber: ctrl.unitNumberController.text,
      clientName: ctrl.clientNameController.text.isEmpty ? 'SITE DRAFT' : ctrl.clientNameController.text,
      clientPhone: selectedPhoneNumber, 
      clientLocation: ctrl.clientLocationController.text,
      locationFolder: ctrl.folderController.text.isNotEmpty ? ctrl.folderController.text : ctrl.clientLocationController.text,
      date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
      totalAmount: ctrl.projectTotalAmount, 
      paidAmount: ctrl.currentPayments.fold(0.0, (s, p) => s + p.amount), 
      balanceAmount: ctrl.balanceAmount,
      items: List.from(ctrl.currentItems),
      materials: MaterialEngine.calculateBOM(ctrl.currentItems),
      payments: ctrl.currentPayments,
      manualAmount: double.tryParse(ctrl.manualAmountController.text) ?? 0,
      manualWeight: double.tryParse(ctrl.manualWeightController.text) ?? 0,
      originalAmount: double.tryParse(ctrl.originalAmountController.text),
      revisionNote: ctrl.revisionNoteController.text.trim().isNotEmpty ? ctrl.revisionNoteController.text.trim() : null,
      discount: ctrl.discountPercent,
      projectStatus: ctrl.projectStatus,
      approvalSignature: ctrl.approvalSignature,
      includeWastage: ctrl.includeWastage,
      includeDigitalSignature: ctrl.includeDigitalSignature,
    );

    CustomerSyncService.instance.saveQuotationToCloud(currentQuota).catchError((e) {
      debugPrint('Auto-save to cloud failed during share action: $e');
    });

    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.white)),
    );

    try {
      final bytes = await PdfService.generateQuotation(
        clientName: currentQuota.clientName,
        clientLocation: currentQuota.clientLocation,
        clientPhone: currentQuota.clientPhone,
        unitNumber: currentQuota.unitNumber,
        items: currentQuota.items,
        materials: currentQuota.materials,
        totalAmount: currentQuota.totalAmount,
        paidAmount: currentQuota.paidAmount,
        balanceAmount: currentQuota.balanceAmount,
        payments: currentQuota.payments,
        includeWastage: ctrl.includeWastage,
        includeDigitalSignature: ctrl.includeDigitalSignature,
        includeBankDetails: ctrl.includeBankDetails,
        originalAmount: currentQuota.originalAmount,
        revisionNote: currentQuota.revisionNote,
        approvalSignature: currentQuota.approvalSignature,
        discountPercent: currentQuota.discount,
      );

      if (context.mounted) Navigator.pop(context);

      if (bytes != null) {
        final dateStr = DateFormat('dd-MM-yyyy').format(DateTime.now());
        final fileName = 'PCM_Quotation_${currentQuota.unitNumber}_$dateStr.pdf';
        
        await Share.shareXFiles(
          [XFile.fromData(bytes, mimeType: 'application/pdf', name: fileName)],
          text: 'Quotation details for ${currentQuota.clientName}',
        );

        String cleanPhone = selectedPhoneNumber.replaceAll(RegExp(r'\D'), '');
        if (cleanPhone.length == 10) {
          cleanPhone = '91$cleanPhone';
        }
        
        final textMsg = 'Hi ${currentQuota.clientName},\n\nHere is your finalized ceiling quotation from *PCM Wayanad*.\n\n*Site ID:* ${currentQuota.unitNumber}\n*Total Contract Amount:* ₹${CalculatorUtils.formatIndianCurrency(currentQuota.totalAmount)}\n*Advance Received:* ₹${CalculatorUtils.formatIndianCurrency(currentQuota.paidAmount)}\n*Balance Amount:* ₹${CalculatorUtils.formatIndianCurrency(currentQuota.balanceAmount)}\n\nYou can view your live account portal and track payments at:\nhttps://pcmwayanad.com/project/${currentQuota.unitNumber}\n\nThank you!';

        final waUrl = Uri.parse('whatsapp://send?phone=$cleanPhone&text=${Uri.encodeComponent(textMsg)}');
        final waWebUrl = Uri.parse('https://wa.me/$cleanPhone?text=${Uri.encodeComponent(textMsg)}');
        
        try {
          if (await canLaunchUrl(waUrl)) {
            await launchUrl(waUrl);
          } else if (await canLaunchUrl(waWebUrl)) {
            await launchUrl(waWebUrl, mode: LaunchMode.externalApplication);
          } else {
            await launchUrl(waWebUrl, mode: LaunchMode.externalApplication);
          }
        } catch (e) {
          debugPrint('Could not launch WhatsApp: $e');
        }
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      debugPrint('Share PDF Error: $e');
    }
  }

  Future<void> _generatePdf(BuildContext context) async {
    try {
      await ctrl.saveToDatabase();
    } catch (e) {
      debugPrint('Database Save Error: $e');
    }
    
    final currentQuota = Quotation(
      id: ctrl.activeProjectId, 
      unitNumber: ctrl.unitNumberController.text,
      clientName: ctrl.clientNameController.text.isEmpty ? 'SITE DRAFT' : ctrl.clientNameController.text,
      clientPhone: ctrl.clientPhoneController.text, 
      clientLocation: ctrl.clientLocationController.text,
      locationFolder: ctrl.folderController.text.isNotEmpty ? ctrl.folderController.text : ctrl.clientLocationController.text,
      date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
      totalAmount: ctrl.projectTotalAmount, 
      paidAmount: ctrl.currentPayments.fold(0.0, (s, p) => s + p.amount), 
      balanceAmount: ctrl.balanceAmount,
      items: List.from(ctrl.currentItems),
      materials: MaterialEngine.calculateBOM(ctrl.currentItems),
      payments: ctrl.currentPayments,
      manualAmount: double.tryParse(ctrl.manualAmountController.text) ?? 0,
      manualWeight: double.tryParse(ctrl.manualWeightController.text) ?? 0,
      originalAmount: double.tryParse(ctrl.originalAmountController.text),
      revisionNote: ctrl.revisionNoteController.text.trim().isNotEmpty ? ctrl.revisionNoteController.text.trim() : null,
      discount: ctrl.discountPercent,
      projectStatus: ctrl.projectStatus,
      approvalSignature: ctrl.approvalSignature,
      includeWastage: ctrl.includeWastage,
      includeDigitalSignature: ctrl.includeDigitalSignature,
    );

    // Auto-save/sync all calculations to Supabase & Firebase when generating PDF
    CustomerSyncService.instance.saveQuotationToCloud(currentQuota).catchError((e) {
      debugPrint('Auto-save to cloud failed during PDF generation: $e');
    });

    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.white)),
    );

    try {
      final bytes = await PdfService.generateQuotation(
        clientName: currentQuota.clientName,
        clientLocation: currentQuota.clientLocation,
        clientPhone: currentQuota.clientPhone,
        unitNumber: currentQuota.unitNumber,
        items: currentQuota.items,
        materials: currentQuota.materials,
        totalAmount: currentQuota.totalAmount,
        paidAmount: currentQuota.paidAmount,
        balanceAmount: currentQuota.balanceAmount,
        payments: currentQuota.payments,
        includeWastage: ctrl.includeWastage,
        includeDigitalSignature: ctrl.includeDigitalSignature,
        includeBankDetails: ctrl.includeBankDetails,
        originalAmount: currentQuota.originalAmount,
        revisionNote: currentQuota.revisionNote,
        approvalSignature: currentQuota.approvalSignature,
      );

      if (context.mounted) Navigator.pop(context);

      if (bytes != null && context.mounted) {
        final dateStr = DateFormat('dd-MM-yyyy').format(DateTime.now());
        final fileName = 'PCM_Quotation_${currentQuota.unitNumber}_$dateStr.pdf';
        
        final path = await PdfService.saveToSystem(bytes, fileName);
        if (path != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('PDF saved successfully to: $path'), backgroundColor: AppColors.resultGreen),
          );
        }
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to generate PDF. Check your data.'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      debugPrint('PDF Button Error: $e');
    }
  }

  Future<void> _viewPdf(BuildContext context) async {
    final navigator = Navigator.of(context);
    try {
      await ctrl.saveToDatabase();
    } catch (e) {
      debugPrint('Database Save Error: $e');
    }
    
    final currentQuota = Quotation(
      id: ctrl.activeProjectId, 
      unitNumber: ctrl.unitNumberController.text,
      clientName: ctrl.clientNameController.text.isEmpty ? 'SITE DRAFT' : ctrl.clientNameController.text,
      clientPhone: ctrl.clientPhoneController.text, 
      clientLocation: ctrl.clientLocationController.text,
      locationFolder: ctrl.folderController.text.isNotEmpty ? ctrl.folderController.text : ctrl.clientLocationController.text,
      date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
      totalAmount: ctrl.projectTotalAmount, 
      paidAmount: ctrl.currentPayments.fold(0.0, (s, p) => s + p.amount), 
      balanceAmount: ctrl.balanceAmount,
      items: List.from(ctrl.currentItems),
      materials: MaterialEngine.calculateBOM(ctrl.currentItems),
      payments: ctrl.currentPayments,
      manualAmount: double.tryParse(ctrl.manualAmountController.text) ?? 0,
      manualWeight: double.tryParse(ctrl.manualWeightController.text) ?? 0,
      originalAmount: double.tryParse(ctrl.originalAmountController.text),
      revisionNote: ctrl.revisionNoteController.text.trim().isNotEmpty ? ctrl.revisionNoteController.text.trim() : null,
      discount: ctrl.discountPercent,
      projectStatus: ctrl.projectStatus,
      approvalSignature: ctrl.approvalSignature,
      includeWastage: ctrl.includeWastage,
      includeDigitalSignature: ctrl.includeDigitalSignature,
    );

    // Auto-save/sync all calculations to Supabase & Firebase when viewing PDF
    CustomerSyncService.instance.saveQuotationToCloud(currentQuota).catchError((e) {
      debugPrint('Auto-save to cloud failed during PDF preview: $e');
    });

    final dateStr = DateFormat('dd-MM-yyyy').format(DateTime.now());
    final fileName = 'PCM_Quotation_${currentQuota.unitNumber}_$dateStr.pdf';

    navigator.push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('PDF PREVIEW'),
            backgroundColor: AppColors.border,
            foregroundColor: Colors.white,
          ),
          body: PdfPreview(
            build: (format) async {
              final bytes = await PdfService.generateQuotation(
                clientName: currentQuota.clientName,
                clientLocation: currentQuota.clientLocation,
                clientPhone: currentQuota.clientPhone,
                unitNumber: currentQuota.unitNumber,
                items: currentQuota.items,
                materials: currentQuota.materials,
                totalAmount: currentQuota.totalAmount,
                paidAmount: currentQuota.paidAmount,
                balanceAmount: currentQuota.balanceAmount,
                payments: currentQuota.payments,
                includeWastage: ctrl.includeWastage,
                includeDigitalSignature: ctrl.includeDigitalSignature,
        includeBankDetails: ctrl.includeBankDetails,
                originalAmount: currentQuota.originalAmount,
                revisionNote: currentQuota.revisionNote,
                approvalSignature: currentQuota.approvalSignature,
              );
              return bytes ?? Uint8List(0);
            },
            allowPrinting: true,
            allowSharing: true,
            canChangePageFormat: false,
            canChangeOrientation: false,
            canDebug: false,
            pdfFileName: fileName,
            loadingWidget: const Center(
              child: CircularProgressIndicator(color: AppColors.primaryButton),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionBtn({required String text, required Color color, IconData? icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 65,
        alignment: Alignment.center,
        decoration: AppStyles.neumorphicDecoration(color: color, hasThickBorder: true),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (icon != null) Icon(icon, color: Colors.white, size: 20),
          if (icon != null) const SizedBox(width: 12),
          Text(
            text,
            style: GoogleFonts.notoSansMalayalam(
              textStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.2),
            ),
          ),
        ]),
      ),
    );
  }
}
