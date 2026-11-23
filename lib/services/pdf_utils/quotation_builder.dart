import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../models/quotation.dart';
import 'pdf_image_helper.dart';

class QuotationBuilder {
  static Future<Uint8List> generate({
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
    bool includeDigitalSignature = true,
    bool includeBankDetails = false,
    String? revisionNote,
    double? originalAmount,
    String? approvalSignature,
    bool isMaterialList = false,
    String? contractorName,
    String? contractorPhone,
    bool isDispatchList = false,
    double discountPercent = 0,
    String? authorizedName,
    String? authorizedPhone,
    String? authorizedLocation,
    List<Map<String, dynamic>>? selectedTiersList,
    List<Map<String, dynamic>>? rateTiers,
    List<String>? selectedTierIds,
    double? totalSqFt,
  }) async {
    final pdf = pw.Document();

    final safeAuthorizedName = (authorizedName != null && authorizedName.trim().isNotEmpty)
        ? authorizedName.trim()
        : 'Madhusudhan A S';
    final hasCustomPhone = (authorizedPhone != null && authorizedPhone.trim().isNotEmpty);
    final safeAuthorizedPhone = hasCustomPhone ? authorizedPhone.trim() : '+91 93834 06185';
    final safeAuthorizedLocation = (authorizedLocation != null && authorizedLocation.trim().isNotEmpty)
        ? authorizedLocation.trim()
        : 'Padinjarathara, Wayanad';

    // Load fonts (including Malayalam support)
    final fonts = await PdfImageHelper.loadFonts();
    final isHelvetica = fonts.regular.fontName.toLowerCase().contains('helvetica');
    final currencySymbol = isHelvetica ? 'Rs. ' : '₹ ';

    // Load assets safely (with fallbacks if specific asset is missing)
    final logoImage = await _loadMemoryImage('assets/images/logo.png', 'assets/images/pcm_logo.png');
    final roomThumb = await _loadMemoryImage('assets/images/room_thumb.jpg', 'assets/images/living.jpg');
    final sealImage = await _loadMemoryImage('assets/images/seal.png');
    final signatureImage = await _loadMemoryImage('assets/images/signature.png');

    // Color Palette (Gold, Black, Cream)
    const primaryBlack = PdfColor.fromInt(0xFF111111);
    const goldColor = PdfColor.fromInt(0xFFD4AF37);
    const greyBackground = PdfColor.fromInt(0xFFF5F5F5);

    // Calculate Payment Stages (55% Advance, 30% Installation, 15% Final)
    final double grandTotal = totalAmount;
    final double totalPaidAmount = paidAmount > 0
        ? paidAmount
        : payments.fold(0.0, (sum, p) => sum + p.amount);
    final double remainingTotal = (grandTotal - totalPaidAmount) > 0
        ? (grandTotal - totalPaidAmount)
        : 0.0;

    // ഓരോ സ്റ്റേജിന്റെയും തുക
    final double advanceStageAmt = grandTotal * 0.55;
    final double installationStageAmt = grandTotal * 0.30;
    final double finalStageAmt = grandTotal * 0.15;

    // Payment stage status & amounts calculation
    final int paymentCount = payments.length;
    final bool isAdvancePaid = paymentCount >= 1 || (totalPaidAmount >= advanceStageAmt - 0.01 && advanceStageAmt > 0);
    final bool isInstallationPaid = paymentCount >= 2 || (totalPaidAmount >= (advanceStageAmt + installationStageAmt - 0.01) && installationStageAmt > 0);
    final bool isFinalPaid = paymentCount >= 3 || remainingTotal <= 0.01;

    final double advanceDue = isAdvancePaid
        ? 0.0
        : ((advanceStageAmt - totalPaidAmount) > 0 ? (advanceStageAmt - totalPaidAmount) : 0.0);
    final double advancePayable = advanceDue > 0 ? advanceDue : advanceStageAmt;
    final double advanceUpiAmt = advancePayable > remainingTotal ? remainingTotal : advancePayable;

    final double paidTowardsInstall = (totalPaidAmount - advanceStageAmt) > 0
        ? (totalPaidAmount - advanceStageAmt)
        : 0.0;
    final double installDue = isInstallationPaid
        ? 0.0
        : ((installationStageAmt - paidTowardsInstall) > 0 ? (installationStageAmt - paidTowardsInstall) : 0.0);
    final double installPayable = installDue > 0 ? installDue : installationStageAmt;
    final double installUpiAmt = installPayable > remainingTotal ? remainingTotal : installPayable;

    final double finalPayable = remainingTotal > 0 ? remainingTotal : finalStageAmt;
    final double finalUpiAmt = finalPayable;

    final bool showAdvanceQr = !isAdvancePaid && remainingTotal > 0.01;
    final bool showInstallQr = isAdvancePaid && !isInstallationPaid && remainingTotal > 0.01;
    final bool showFinalQr = isAdvancePaid && isInstallationPaid && !isFinalPaid && remainingTotal > 0.01;

    // Calculate total area from items
    final totalArea = (totalSqFt != null && totalSqFt > 0)
        ? totalSqFt
        : items.fold(0.0, (sum, i) => sum + (i.area > 0 ? i.area : (i.length * i.width))) * (includeWastage ? 1.05 : 1.0);

    final List<Map<String, dynamic>> activeTiersList = selectedTiersList ??
        ((rateTiers != null && selectedTierIds != null && selectedTierIds.isNotEmpty)
            ? rateTiers.where((t) => selectedTierIds.contains(t['id']) || selectedTierIds.contains(t['name'])).toList()
            : (rateTiers ?? []));

    // Format current date
    final dateStr = '${DateTime.now().day.toString().padLeft(2, '0')}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().year}';

    // Unified Header builder for both pages
    pw.Widget buildHeader() {
      return pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: primaryBlack,
          border: pw.Border.all(color: goldColor, width: 1.8),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          children: [
            // പിഡിഎഫ് ഹെഡറിന്റെ ഏറ്റവും മുകളിൽ വരുന്ന ഉദ്യം രജിസ്ട്രേഷൻ നമ്പർ
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 2.5),
              margin: const pw.EdgeInsets.only(bottom: 6),
              decoration: pw.BoxDecoration(
                color: const PdfColor.fromInt(0xFF333333),
                borderRadius: pw.BorderRadius.circular(3),
                border: pw.Border.all(color: const PdfColor.fromInt(0xFFD4AF37), width: 0.6),
              ),
              child: pw.Text(
                'UDYAM REGISTRATION: UDYAM-KL-14-0031878',
                style: pw.TextStyle(
                  fontSize: 7.5,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  letterSpacing: 1.0,
                  font: fonts.bold,
                ),
              ),
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // Left Logo
                pw.Container(
                  width: 70,
                  height: 55,
                  child: logoImage != null
                      ? pw.Image(logoImage, fit: pw.BoxFit.contain)
                      : pw.Center(
                          child: pw.Text(
                            'PCM',
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: goldColor,
                              font: fonts.bold,
                            ),
                          ),
                        ),
                ),
                // Center Hierarchy
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    // 1. പ്രീമിയം സീലിംഗ് മാസ്റ്റർ
                    pw.Text(
                      'PREMIUM CEILING MASTER',
                      style: pw.TextStyle(
                        fontSize: 15,
                        fontWeight: pw.FontWeight.bold,
                        color: const PdfColor.fromInt(0xFFFFD700),
                        letterSpacing: 1.5,
                        font: fonts.bold,
                      ),
                    ),
                    pw.SizedBox(height: 3),

                    // 2. പിസിഎം വയനാട്
                    pw.Text(
                      'PCM WAYANAD',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                        letterSpacing: 1.0,
                        font: fonts.bold,
                      ),
                    ),
                    pw.SizedBox(height: 3),

                    // 3. ടാഗ്ലൈൻ
                    pw.Text(
                      'The Magic of Interiors',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontStyle: pw.FontStyle.italic,
                        color: const PdfColor.fromInt(0xFFF3E5AB),
                        letterSpacing: 0.5,
                        font: fonts.regular,
                      ),
                    ),
                    pw.SizedBox(height: 5),

                    // 4. അഡ്രസ്സും ഫോൺ നമ്പറും (ഹൈലൈറ്റ് ചെയ്ത ബോക്സ്)
                    pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.black,
                        borderRadius: pw.BorderRadius.circular(6),
                        border: pw.Border.all(color: goldColor, width: 1),
                      ),
                      child: pw.Center(
                        child: pw.Text(
                          '$safeAuthorizedLocation | Name: $safeAuthorizedName | Ph: $safeAuthorizedPhone',
                          style: pw.TextStyle(
                            fontSize: 9,
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                            font: fonts.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                // Right Logo
                pw.Container(
                  width: 70,
                  height: 55,
                  child: logoImage != null
                      ? pw.Image(logoImage, fit: pw.BoxFit.contain)
                      : pw.Center(
                          child: pw.Text(
                            'PCM',
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: goldColor,
                              font: fonts.bold,
                            ),
                          ),
                        ),
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Divider(color: goldColor, thickness: 1.2),
          ],
        ),
      );
    }

    // ഓരോ പെയ്മെന്റ് റോയുടെയും ഉള്ളിൽ കൃത്യമായി ക്യുആർ കോഡ് കാണിക്കുന്ന ഫംഗ്ഷൻ
    pw.Widget buildPaymentRowWithQR({
      required String title,
      required String percentage,
      required double amount,
      required bool showQrCode,
      required String upiData,
      bool isPaid = false,
      double? payableAmount,
    }) {
      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        margin: const pw.EdgeInsets.symmetric(vertical: 2.5),
        decoration: pw.BoxDecoration(
          color: showQrCode
              ? const PdfColor.fromInt(0xFFFFF9E6)
              : (isPaid ? const PdfColor.fromInt(0xFFE8F5E9) : greyBackground),
          borderRadius: pw.BorderRadius.circular(6),
          border: pw.Border.all(
            color: showQrCode
                ? goldColor
                : (isPaid ? PdfColors.green700 : PdfColors.grey300),
            width: showQrCode ? 1.0 : 0.8,
          ),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            // ഇടത് വശത്ത് ടൈറ്റിലും ശതമാനവും
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    children: [
                      pw.Text(
                        title,
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: showQrCode ? primaryBlack : (isPaid ? PdfColors.green900 : PdfColors.grey800),
                          font: fonts.bold,
                        ),
                      ),
                      if (isPaid) ...[
                        pw.SizedBox(width: 4),
                        pw.Text('(Paid)', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.green800, font: fonts.bold)),
                      ],
                    ],
                  ),
                  pw.SizedBox(height: 1),
                  pw.Text('Percentage: $percentage', style: pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700, font: fonts.regular)),
                ],
              ),
            ),

            // വലതുവശത്ത് തുകയും, ആ സ്റ്റേജിലുള്ള ക്യുആർ കോഡും
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      '$currencySymbol${amount.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                        fontSize: 10.5,
                        fontWeight: pw.FontWeight.bold,
                        color: showQrCode ? const PdfColor.fromInt(0xFFB8860B) : (isPaid ? PdfColors.green900 : primaryBlack),
                        font: fonts.bold,
                      ),
                    ),
                    if (showQrCode && payableAmount != null && (payableAmount - amount).abs() > 0.01)
                      pw.Text(
                        'Due: $currencySymbol${payableAmount.toStringAsFixed(2)}',
                        style: pw.TextStyle(
                          fontSize: 7.5,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.red800,
                          font: fonts.bold,
                        ),
                      ),
                  ],
                ),

                // ഈ സ്റ്റേജ് ആണെങ്കിൽ മാത്രം ഇവിടെ ക്യുആർ കോഡ് കാണിക്കും
                if (showQrCode) ...[
                  pw.SizedBox(width: 10),
                  pw.Container(
                    width: 42,
                    height: 42,
                    child: pw.BarcodeWidget(
                      barcode: pw.Barcode.qrCode(),
                      data: upiData,
                      color: PdfColors.black,
                      backgroundColor: PdfColors.white,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      );
    }

    // ================= PAGE 1: QUOTATION & MEASUREMENTS =================
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              // 1. Background Watermark Logo (10% Opacity)
              if (logoImage != null)
                pw.Positioned(
                  top: 250, // മുകളിൽ നിന്നുള്ള അകലം
                  left: 100, // ഇടത്തു നിന്നുള്ള അകലം
                  right: 100,
                  child: pw.Opacity(
                    opacity: 0.1, // നല്ല മങ്ങിയ നിറം ലഭിക്കാൻ
                    child: pw.Image(
                      logoImage,
                      width: 200,
                      height: 200,
                      fit: pw.BoxFit.contain,
                    ),
                  ),
                ),

              // 2. Foreground Main Content
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  buildHeader(),
                  pw.SizedBox(height: 12),

              // Quotation Title Bar
              pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.symmetric(vertical: 6),
                decoration: pw.BoxDecoration(
                  color: goldColor,
                  borderRadius: pw.BorderRadius.circular(15),
                ),
                child: pw.Text(
                  'QUOTATION',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: primaryBlack,
                    font: fonts.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 10),

              // Client Details & Info
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: greyBackground,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('QUOTATION ISSUED TO:', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700, fontWeight: pw.FontWeight.bold, font: fonts.bold)),
                        pw.Text(clientName.isNotEmpty ? clientName : 'Customer', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, font: fonts.bold)),
                        pw.Text('Phone: $clientPhone', style: pw.TextStyle(fontSize: 10, font: fonts.regular)),
                        pw.Text('Location: $clientLocation', style: pw.TextStyle(fontSize: 10, font: fonts.regular)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Quote ID: $unitNumber', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, font: fonts.bold)),
                        pw.Text('Date: $dateStr', style: pw.TextStyle(fontSize: 10, font: fonts.regular)),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),

              // Room Specifications Table Header
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: const pw.BoxDecoration(color: goldColor),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('ROOM / SPECIFICATION & MEASUREMENTS', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: primaryBlack, font: fonts.bold)),
                    pw.Text('LINE TOTAL', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: primaryBlack, font: fonts.bold)),
                  ],
                ),
              ),

              // Room Items List with Thumbnails
              ...items.map((item) {
                final itemArea = item.area > 0 ? item.area : (item.length * item.width);
                final spec = [
                  if (item.ceilingType.isNotEmpty) 'Ch: ${item.ceilingType}',
                  if (item.designName.isNotEmpty) 'Bd: ${item.designName}',
                ].join(' | ');
                final specText = spec.isNotEmpty ? spec : 'Standard Gypsum';

                return pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Container(
                        width: 45,
                        height: 35,
                        margin: const pw.EdgeInsets.only(right: 8),
                        child: roomThumb != null
                            ? pw.ClipRRect(
                                horizontalRadius: 4,
                                verticalRadius: 4,
                                child: pw.Image(roomThumb, fit: pw.BoxFit.cover),
                              )
                            : pw.Container(
                                decoration: pw.BoxDecoration(
                                  color: primaryBlack,
                                  borderRadius: pw.BorderRadius.circular(4),
                                  border: pw.Border.all(color: goldColor, width: 0.5),
                                ),
                                alignment: pw.Alignment.center,
                                child: pw.Text('ROOM', style: pw.TextStyle(color: goldColor, fontSize: 8, font: fonts.bold)),
                              ),
                      ),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(item.roomName, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, font: fonts.bold)),
                            pw.Text('${item.length.toStringAsFixed(1)} x ${item.width.toStringAsFixed(1)} FT | ${itemArea.toStringAsFixed(2)} SQFT', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700, font: fonts.regular)),
                            pw.Text(specText, style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600, font: fonts.regular)),
                          ],
                        ),
                      ),
                      pw.Text('$currencySymbol${item.amount.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, font: fonts.bold)),
                    ],
                  ),
                );
              }),

              pw.Spacer(),

              // Summary Box at Bottom of Page 1
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: greyBackground,
                  border: pw.Border.all(color: goldColor),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  children: [
                    _buildSummaryRow('TOTAL ITEMS:', '${items.length}', font: fonts.regular, boldFont: fonts.bold),
                    _buildSummaryRow('TOTAL ROOMS:', '${items.length}', font: fonts.regular, boldFont: fonts.bold),
                    _buildSummaryRow('TOTAL AREA:', '${totalArea.toStringAsFixed(2)} SqFt', font: fonts.regular, boldFont: fonts.bold),
                    pw.Divider(color: goldColor),
                    _buildSummaryRow('TOTAL WAGES / AMOUNT:', 'Rs. ${grandTotal.toStringAsFixed(2)}', isBold: true, font: fonts.regular, boldFont: fonts.bold),
                    _buildSummaryRow('TOTAL PAID AMOUNT:', 'Rs. ${totalPaidAmount.toStringAsFixed(2)}', color: PdfColors.green800, font: fonts.regular, boldFont: fonts.bold),
                    _buildSummaryRow('BALANCE DUE:', 'Rs. ${remainingTotal.toStringAsFixed(2)}', color: PdfColors.red800, isBold: true, font: fonts.regular, boldFont: fonts.bold),
                  ],
                ),
              ),
            ],
          ),
        ],
      );
    },
  ),
);

    // ================= PAGE 2: TERMS, WORKFLOW & SIGNATURES =================
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              // 1. Background Watermark Logo (10% Opacity)
              if (logoImage != null)
                pw.Positioned(
                  top: 250, // മുകളിൽ നിന്നുള്ള അകലം
                  left: 100, // ഇടത്തു നിന്നുള്ള അകലം
                  right: 100,
                  child: pw.Opacity(
                    opacity: 0.1, // നല്ല മങ്ങിയ നിറം ലഭിക്കാൻ
                    child: pw.Image(
                      logoImage,
                      width: 200,
                      height: 200,
                      fit: pw.BoxFit.contain,
                    ),
                  ),
                ),

              // 2. Foreground Main Content
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  buildHeader(), // Same unified header on Page 2
                  pw.SizedBox(height: 10),

              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(6),
                      decoration: pw.BoxDecoration(color: greyBackground, borderRadius: pw.BorderRadius.circular(4)),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('VISION', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: goldColor, font: fonts.bold)),
                          pw.Text('PCM Wayanad: Elevating interior elegance with premium materials and precision.', style: pw.TextStyle(fontSize: 8, font: fonts.regular)),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(6),
                      decoration: pw.BoxDecoration(color: greyBackground, borderRadius: pw.BorderRadius.circular(4)),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('DISCLAIMER', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.red800, font: fonts.bold)),
                          pw.Text('Measurements are provisional. Final measurements after work completion.', style: pw.TextStyle(fontSize: 8, font: fonts.regular)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),

              // SELECTED RATE TIERS & ESTIMATE COMPARISON
              if (activeTiersList.isNotEmpty) ...[
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'SELECTED RATE TIERS & ESTIMATE COMPARISON',
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFFB45309), font: fonts.bold),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Row(
                      children: activeTiersList.map((tier) {
                        final double tierPrice = (tier['rate'] as num?)?.toDouble() ??
                            (tier['price'] as num?)?.toDouble() ?? 0.0;
                        final double tierTotal = totalArea * tierPrice;
                        final rawName = tier['name'] as String? ?? '';
                        final displayName = isHelvetica ? rawName.replaceAll('₹', 'Rs.') : rawName;
                        final channelName = tier['channelName'] as String? ?? tier['channel'] as String? ?? '';
                        final boardName = tier['boardName'] as String? ?? tier['board'] as String? ?? '';

                        return pw.Expanded(
                          child: pw.Container(
                            margin: const pw.EdgeInsets.symmetric(horizontal: 2),
                            padding: const pw.EdgeInsets.all(6),
                            decoration: pw.BoxDecoration(
                              border: pw.Border.all(color: goldColor, width: 1),
                              borderRadius: pw.BorderRadius.circular(4),
                              color: PdfColors.grey100,
                            ),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  displayName,
                                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, font: fonts.bold),
                                ),
                                pw.SizedBox(height: 2),
                                pw.Text(
                                  'Rate: $currencySymbol$tierPrice / sqft',
                                  style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700, font: fonts.regular),
                                ),
                                pw.Text(
                                  'Total: $currencySymbol${tierTotal.toStringAsFixed(2)}',
                                  style: pw.TextStyle(
                                    fontSize: 10,
                                    fontWeight: pw.FontWeight.bold,
                                    color: const PdfColor.fromInt(0xFFB45309),
                                    font: fonts.bold,
                                  ),
                                ),
                                pw.SizedBox(height: 4),
                                pw.Text('Ch: $channelName', style: pw.TextStyle(fontSize: 7, font: fonts.regular)),
                                pw.Text('Bd: $boardName', style: pw.TextStyle(fontSize: 7, font: fonts.regular)),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                pw.SizedBox(height: 15),
              ],

              // Payment Terms Header
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                decoration: const pw.BoxDecoration(color: goldColor),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('PAYMENT TERMS & BREAKDOWN', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: primaryBlack, font: fonts.bold)),
                    pw.Text('UPI: asmadhu298@okaxis', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: primaryBlack, font: fonts.bold)),
                  ],
                ),
              ),
              pw.SizedBox(height: 4),

              // 1. Advance Payment (55%)
              buildPaymentRowWithQR(
                title: '1. Advance Payment (Required at start / dispatch)',
                percentage: '55%',
                amount: advanceStageAmt,
                payableAmount: advanceUpiAmt,
                showQrCode: showAdvanceQr,
                isPaid: isAdvancePaid,
                upiData: 'upi://pay?pa=asmadhu298@okaxis&pn=PCM%20Wayanad&cu=INR&am=${advanceUpiAmt.toStringAsFixed(2)}&tn=Advance%20Payment',
              ),

              // 2. Sheet Installation Payment (30%)
              buildPaymentRowWithQR(
                title: '2. Sheet Installation (When work is underway)',
                percentage: '30%',
                amount: installationStageAmt,
                payableAmount: installUpiAmt,
                showQrCode: showInstallQr,
                isPaid: isInstallationPaid,
                upiData: 'upi://pay?pa=asmadhu298@okaxis&pn=PCM%20Wayanad&cu=INR&am=${installUpiAmt.toStringAsFixed(2)}&tn=Installation%20Payment',
              ),

              // 3. Final Payment (15%)
              buildPaymentRowWithQR(
                title: '3. Final Balance (Upon project completion)',
                percentage: '15%',
                amount: finalStageAmt,
                payableAmount: finalUpiAmt,
                showQrCode: showFinalQr,
                isPaid: isFinalPaid,
                upiData: 'upi://pay?pa=asmadhu298@okaxis&pn=PCM%20Wayanad&cu=INR&am=${finalUpiAmt.toStringAsFixed(2)}&tn=Final%20Balance',
              ),

              // പിഡിഎഫിൽ പെയ്മെന്റ് ഹിസ്റ്ററി സെക്ഷൻ (PAYMENT HISTORY LOG)
              if (payments.isNotEmpty) ...[
                pw.SizedBox(height: 6),
                pw.Text(
                  'PAYMENT HISTORY LOG',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: goldColor,
                    font: fonts.bold,
                  ),
                ),
                pw.SizedBox(height: 3),
                ...payments.map((payment) {
                  final String title = payment.description.isNotEmpty ? payment.description : 'PAYMENT RECEIVED';
                  final String dateStr = payment.date;
                  final double amt = payment.amount;
                  return pw.Container(
                    margin: const pw.EdgeInsets.symmetric(vertical: 2),
                    padding: const pw.EdgeInsets.all(6),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey200,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              title,
                              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, font: fonts.bold),
                            ),
                            if (dateStr.isNotEmpty)
                              pw.Text(
                                dateStr,
                                style: pw.TextStyle(fontSize: 7, color: PdfColors.grey700, font: fonts.regular),
                              ),
                          ],
                        ),
                        pw.Text(
                          '$currencySymbol${amt.toStringAsFixed(2)}',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.green800,
                            font: fonts.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
              pw.SizedBox(height: 6),

              // 12 Terms & Conditions in English 2-Column Grid
              _buildTermsSection(fonts),
              pw.SizedBox(height: 8),

              pw.Container(
                padding: const pw.EdgeInsets.all(6),
                decoration: pw.BoxDecoration(border: pw.Border.all(color: goldColor), borderRadius: pw.BorderRadius.circular(4)),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    _buildWorkflowStep('01', 'Measurement', fonts),
                    _buildWorkflowStep('02', '3D Design', fonts),
                    _buildWorkflowStep('03', 'Installation', fonts),
                    _buildWorkflowStep('04', 'Completion', fonts),
                  ],
                ),
              ),

              pw.Spacer(),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  // ഇടത് വശത്ത് ക്യുആർ കോഡ് (ഐഡി ലിങ്ക് ചെയ്തത്)
                  pw.Container(
                    width: 60,
                    height: 60,
                    child: pw.BarcodeWidget(
                      barcode: pw.Barcode.qrCode(),
                      data: 'https://pcm-wayanad-portal.vercel.app/quote?id=${Uri.encodeComponent(unitNumber.replaceAll('#', '').trim())}',
                      color: PdfColors.black,
                    ),
                  ),

                  // വലതുവശത്ത് ഒപ്പും പങ്കാളിയുടെ വിവരങ്ങളും (Digital Signature Toggle)
                  if (includeDigitalSignature)
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Authorized Signatory', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, font: fonts.bold)),
                        pw.SizedBox(height: 5),
                        if (sealImage != null || signatureImage != null)
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.end,
                            crossAxisAlignment: pw.CrossAxisAlignment.center,
                            children: [
                              if (sealImage != null) ...[
                                pw.Container(
                                  height: 45,
                                  width: 45,
                                  child: pw.Image(sealImage, fit: pw.BoxFit.contain),
                                ),
                                if (signatureImage != null) pw.SizedBox(width: 8),
                              ],
                              if (signatureImage != null)
                                pw.Container(
                                  height: 35,
                                  child: pw.Image(signatureImage, fit: pw.BoxFit.contain),
                                ),
                            ],
                          ),
                        pw.SizedBox(height: 5),
                        pw.Text(safeAuthorizedName, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFFB45309), font: fonts.bold)),
                        pw.Text(safeAuthorizedLocation, style: pw.TextStyle(fontSize: 8, font: fonts.regular)),
                        if (authorizedName != null && authorizedName.trim().isNotEmpty) ...[
                          pw.SizedBox(height: 2),
                          pw.Text('Ph: $safeAuthorizedPhone', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900, font: fonts.bold)),
                        ],
                        pw.SizedBox(height: 2),
                        pw.Text('PCM WAYANAD', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, font: fonts.bold)),
                      ],
                    )
                  else
                    pw.SizedBox(width: 1),
                ],
              ),
            ],
          ),
        ],
      );
    },
  ),
);

    return pdf.save();
  }

  static Future<Uint8List> generateQuotation({
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
    bool includeDigitalSignature = true,
    bool includeBankDetails = false,
    String? revisionNote,
    double? originalAmount,
    String? approvalSignature,
    bool isMaterialList = false,
    String? contractorName,
    String? contractorPhone,
    bool isDispatchList = false,
    double discountPercent = 0,
    String? authorizedName,
    String? authorizedPhone,
    String? authorizedLocation,
    List<Map<String, dynamic>>? selectedTiersList,
    List<Map<String, dynamic>>? rateTiers,
    List<String>? selectedTierIds,
    double? totalSqFt,
  }) => generate(
    clientName: clientName,
    clientLocation: clientLocation,
    clientPhone: clientPhone,
    unitNumber: unitNumber,
    items: items,
    materials: materials,
    payments: payments,
    totalAmount: totalAmount,
    paidAmount: paidAmount,
    balanceAmount: balanceAmount,
    heightExtra: heightExtra,
    includeWastage: includeWastage,
    includeDigitalSignature: includeDigitalSignature,
    includeBankDetails: includeBankDetails,
    revisionNote: revisionNote,
    originalAmount: originalAmount,
    approvalSignature: approvalSignature,
    isMaterialList: isMaterialList,
    contractorName: contractorName,
    contractorPhone: contractorPhone,
    isDispatchList: isDispatchList,
    discountPercent: discountPercent,
    authorizedName: authorizedName,
    authorizedPhone: authorizedPhone,
    authorizedLocation: authorizedLocation,
    selectedTiersList: selectedTiersList,
    rateTiers: rateTiers,
    selectedTierIds: selectedTierIds,
    totalSqFt: totalSqFt,
  );

  static Future<pw.MemoryImage?> _loadMemoryImage(String path, [String? fallbackPath]) async {
    try {
      final data = await rootBundle.load(path);
      if (data.lengthInBytes > 0) {
        return pw.MemoryImage(data.buffer.asUint8List());
      }
    } catch (_) {}
    if (fallbackPath != null) {
      try {
        final data = await rootBundle.load(fallbackPath);
        if (data.lengthInBytes > 0) {
          return pw.MemoryImage(data.buffer.asUint8List());
        }
      } catch (_) {}
    }
    return null;
  }

  static pw.Widget _buildSummaryRow(
    String label,
    String value, {
    PdfColor? color,
    bool isBold = false,
    required pw.Font font,
    required pw.Font boldFont,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 9, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal, font: isBold ? boldFont : font)),
          pw.Text(value, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: color ?? PdfColors.black, font: boldFont)),
        ],
      ),
    );
  }

  static pw.Widget _buildWorkflowStep(String number, String title, LoadedFonts fonts) {
    return pw.Column(
      children: [
        pw.Text(number, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFFD4AF37), font: fonts.bold)),
        pw.Text(title, style: pw.TextStyle(fontSize: 7, font: fonts.regular)),
      ],
    );
  }

  // 12 Professional Terms & Conditions in English for PCM Wayanad PDF
  static const List<Map<String, String>> termsAndConditionsEn = [
    {
      "title": "1. Wiring & Electrical Delay",
      "desc": "Once our channel framework is completed, electrical wiring must follow. PCM Wayanad shall not be held responsible if the project timeline is exceeded due to delays from the electrical wiring team."
    },
    {
      "title": "2. Quotation Validity",
      "desc": "This quotation is strictly valid for 30 days from the date of issue. Any price fluctuations in materials after this period will be charged accordingly."
    },
    {
      "title": "3. Transportation & Site Access",
      "desc": "If transport vehicles cannot reach the exact work site due to restricted access, additional loading and manual handling charges will apply."
    },
    {
      "title": "4. High Ceiling / Height Charges",
      "desc": "For sites or halls with an unusually high ceiling requiring extra scaffolding and risk management, additional charges will be levied after site inspection."
    },
    {
      "title": "5. Pricing Policy",
      "desc": "We always offer our most competitive and reasonable pricing upfront. Requests for further price reductions on the provided quotation will not be entertained."
    },
    {
      "title": "6. Execution & Timeline",
      "desc": "The client must ensure proper site readiness and uninterrupted working conditions to complete the project within the stipulated timeframe."
    },
    {
      "title": "7. Site Readiness & Access",
      "desc": "The work site must be fully cleared, accessible, and ready for installation before our team arrives to commence work."
    },
    {
      "title": "8. Utilities - Water & Electricity",
      "desc": "Necessary electricity and water supply at the site for tools and installation must be provided free of cost by the client."
    },
    {
      "title": "9. Material Storage & Safety",
      "desc": "A safe, dry, and locked space must be provided at the site by the client to securely store gypsum boards, channels, and tools."
    },
    {
      "title": "10. Design & Material Alterations",
      "desc": "Any mid-way modifications or changes in ceiling design or material specs requested by the client will incur extra charges based on actual execution."
    },
    {
      "title": "11. Waste Management",
      "desc": "Gypsum scraps and cut-offs generated during work will be neatly stacked by our team at a designated spot within the site premises."
    },
    {
      "title": "12. Payment Milestones",
      "desc": "Clients must strictly adhere to the payment milestones outlined in the quotation: Advance (55%), Installation (30%), and Final Balance (15%)."
    }
  ];

  static pw.Widget _buildTermsSection(LoadedFonts fonts) {
    const goldColor = PdfColor.fromInt(0xFFD4AF37);
    const primaryBlack = PdfColor.fromInt(0xFF111111);

    final leftCol = termsAndConditionsEn.sublist(0, 6);
    final rightCol = termsAndConditionsEn.sublist(6, 12);

    pw.Widget buildItem(Map<String, String> item) {
      final title = item['title'] ?? '';
      final desc = item['desc'] ?? '';

      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 3.5),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 6.8,
                fontWeight: pw.FontWeight.bold,
                color: primaryBlack,
                font: fonts.bold,
              ),
            ),
            pw.SizedBox(height: 1),
            pw.Text(
              desc,
              style: pw.TextStyle(
                fontSize: 5.6,
                color: PdfColors.grey800,
                font: fonts.regular,
                lineSpacing: 1.05,
              ),
            ),
          ],
        ),
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3.5),
          decoration: const pw.BoxDecoration(color: goldColor),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'TERMS & CONDITIONS (12 Key Points)',
                style: pw.TextStyle(
                  fontSize: 8.5,
                  fontWeight: pw.FontWeight.bold,
                  color: primaryBlack,
                  font: fonts.bold,
                ),
              ),
              pw.Text(
                'PCM WAYANAD STANDARD POLICY',
                style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold, color: primaryBlack, font: fonts.bold),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Container(
          padding: const pw.EdgeInsets.all(6),
          decoration: pw.BoxDecoration(
            color: const PdfColor.fromInt(0xFFFAFAFA),
            border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: leftCol.map(buildItem).toList(),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Container(width: 0.5, color: PdfColors.grey300),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: rightCol.map(buildItem).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
