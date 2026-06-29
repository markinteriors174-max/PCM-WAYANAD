import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../../models/quotation.dart';
import '../../../utils/calculator_utils.dart';
import 'quotation_header_builder.dart';
import 'quotation_table_builder.dart';
import 'quotation_summary_builder.dart';
import 'quotation_terms_builder.dart';
import 'quotation_workflow_builder.dart';
import 'quotation_footer_builder.dart';
import 'package:http/http.dart' as http;
import '../../../utils/platform_utils.dart';

class LoadedFonts {
  final pw.Font regular;
  final pw.Font bold;
  final pw.Font malayalam;
  LoadedFonts({required this.regular, required this.bold, required this.malayalam});
}

class QuotationBuilder {
  static Future<Uint8List?> generate({
    required String clientName,
    required String clientLocation,
    required String clientPhone,
    required String unitNumber,
    required List<QuotationItem> items,
    required List<MaterialAssignment> materials,
    required List<PaymentRecord> payments,
    required double totalAmount,
    required double paidAmount,
    required double balanceAmount,
    double heightExtra = 0,
    bool includeWastage = false,
    bool includeDigitalSignature = false,
    bool includeBankDetails = false,
    String? revisionNote,
    double? originalAmount,
    String? approvalSignature,
    bool isMaterialList = false,
    String? contractorName,
    String? contractorPhone,
    bool isDispatchList = false,
    double discountPercent = 0,
  }) async {
    try {
      final pdf = pw.Document();
      final fonts = await _loadFonts();
      final logo = await _loadLogo();
      final emblem = await _loadAssetImage('assets/images/emblem_of_india.png');
      final assetSignature = await _loadAssetImage('assets/images/my_signature.png');

      final workflowPcm = await _loadAssetImage('assets/images/workflow_pcm.png');
      final workflowDesign = await _loadAssetImage('assets/images/workflow_design.png');
      final workflowMaterials = await _loadAssetImage('assets/images/workflow_materials.png');
      final workflowCompletion = await _loadAssetImage('assets/images/workflow_completion.png');
      
      final prefs = await SharedPreferences.getInstance();
      final companyName = prefs.getString('company_name') ?? 'PREMIUM CEILING MASTER | WAYANAD';
      final tagline = prefs.getString('company_tagline') ?? 'GYPSUM CEILING & INTERIOR WORKS';
      final upiId = prefs.getString('bank_upi_id') ?? '';
      final bankName = prefs.getString('bank_name');
      final accountName = prefs.getString('bank_account_name');
      final accountNumber = prefs.getString('bank_account_number');
      final ifsc = prefs.getString('bank_ifsc');
      
      final signaturePath = prefs.getString('signature_path');
      
      pw.MemoryImage? signatureImage;
      if (includeDigitalSignature) {
        signatureImage = assetSignature;
        if (!kIsWeb && signatureImage == null) {
          if (signaturePath != null && signaturePath.isNotEmpty) {
             final bytes = await PlatformUtilsImpl.readFileBytes(signaturePath);
             if (bytes != null) signatureImage = pw.MemoryImage(bytes);
          }
        }
      }

      pw.MemoryImage? clientApprovalImage;

      if (approvalSignature != null && approvalSignature.isNotEmpty) {
        try {
          final res = await http.get(Uri.parse(approvalSignature));
          if (res.statusCode == 200) {
            clientApprovalImage = pw.MemoryImage(res.bodyBytes);
          }
        } catch (e) {
          debugPrint('Error loading approval signature: $e');
        }
      }

      final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs. ', decimalDigits: 2);
      
      pdf.addPage(
        pw.MultiPage(
          pageTheme: pw.PageTheme(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(32),
            buildBackground: (context) => pw.FullPage(
              ignoreMargins: true,
              child: pw.Center(
                child: pw.Opacity(
                  opacity: 0.05,
                  child: pw.Image(logo, width: 400),
                ),
              ),
            ),
          ),
          header: (context) => QuotationHeaderBuilder.buildModernHeader(
            logo, emblem, companyName, tagline, 
            boldFont: fonts.bold, upiId: upiId, unitNumber: unitNumber, isDispatchList: isDispatchList
          ),
          build: (context) => [
            if (isDispatchList)
               QuotationHeaderBuilder.buildDispatchClientCard(
                 siteLocation: clientLocation, clientSite: clientName, contractor: contractorName ?? 'N/A', font: fonts.regular, boldFont: fonts.bold
               )
            else
               QuotationHeaderBuilder.buildClientCard(
                 clientName: clientName, clientLocation: clientLocation, clientPhone: clientPhone, 
                 unitNumber: unitNumber, totalArea: items.fold(0.0, (s, i) => s + CalculatorUtils.getNormalizedAreaSqFt(i)) * (includeWastage ? 1.05 : 1.0),
                 includeWastage: includeWastage, font: fonts.regular, boldFont: fonts.bold
               ),

            pw.SizedBox(height: 15),

            if (isMaterialList || isDispatchList)
               QuotationTableBuilder.buildMaterialsTable(materials: materials, font: fonts.regular, boldFont: fonts.bold, currencyFormat: currencyFormat)
            else
               QuotationTableBuilder.buildTable(items: items, font: fonts.regular, boldFont: fonts.bold, currencyFormat: currencyFormat),
            
            pw.SizedBox(height: 20),
            
            if (!isMaterialList && !isDispatchList)
              QuotationSummaryBuilder.buildSummary(
                items: items, payments: payments, totalAmount: totalAmount, paidAmount: paidAmount, 
                balanceAmount: balanceAmount, includeWastage: includeWastage, font: fonts.regular, 
                boldFont: fonts.bold, currencyFormat: currencyFormat,
                discountPercent: discountPercent,
              ),
            
            pw.SizedBox(height: 20),
            
            if (!isMaterialList && !isDispatchList) ...[
              QuotationTermsBuilder.buildTermsAndDetails(
                prefs: prefs, companyName: companyName, unitNumber: unitNumber, font: fonts.regular, boldFont: fonts.bold
              ),
              pw.SizedBox(height: 15),
              QuotationWorkflowBuilder.buildWorkflowAndSocial(
                fonts.regular, fonts.bold,
                pcmImage: workflowPcm,
                designImage: workflowDesign,
                materialsImage: workflowMaterials,
                completionImage: workflowCompletion,
              ),
            ],

            if (isDispatchList)
               pw.Text('DISPATCH AUTHORIZATION REQUIRED', style: pw.TextStyle(font: fonts.bold, fontSize: 10)),
            
            pw.SizedBox(height: 30),
            
            if (revisionNote != null)
              QuotationFooterBuilder.buildRevisionNote(revisionNote, originalAmount, totalAmount, fonts.regular, fonts.bold, currencyFormat),

            pw.SizedBox(height: 20),

            QuotationFooterBuilder.buildFinalSignatures(
              fonts.regular, fonts.bold, signatureImage: signatureImage, sealImage: null, clientSignatureImage: clientApprovalImage
            ),
          ],
          footer: (context) => QuotationFooterBuilder.buildRepeatingFooter(
            context, companyName, fonts.regular, fonts.bold, signatureImage: signatureImage,
            includeBankDetails: includeBankDetails, bankName: bankName, accountName: accountName,
            accountNumber: accountNumber, ifsc: ifsc, upiId: upiId,
          ),
        ),
      );

      return await pdf.save();
    } catch (e) {
      debugPrint('Quotation Generation Error: $e');
      return null;
    }
  }

  static Future<LoadedFonts> _loadFonts() async {
    final regular = await PdfGoogleFonts.notoSansRegular();
    final bold = await PdfGoogleFonts.notoSansBold();
    final malayalam = await PdfGoogleFonts.notoSansMalayalamRegular();
    return LoadedFonts(regular: regular, bold: bold, malayalam: malayalam);
  }

  static Future<pw.MemoryImage> _loadLogo() async {
    final bytes = await rootBundle.load('assets/images/logo.png');
    return pw.MemoryImage(bytes.buffer.asUint8List());
  }

  static Future<pw.MemoryImage?> _loadAssetImage(String path) async {
    try {
      final bytes = await rootBundle.load(path);
      return pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (e) {
      return null;
    }
  }
}
