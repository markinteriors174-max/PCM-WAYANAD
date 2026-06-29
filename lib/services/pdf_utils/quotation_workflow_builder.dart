import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'pdf_icons.dart';

/// Highly compact "OUR WORKFLOW" section to save vertical space.
class QuotationWorkflowBuilder {
  static pw.Widget buildWorkflowAndSocial(
    pw.Font font,
    pw.Font boldFont, {
    pw.MemoryImage? pcmImage,
    pw.MemoryImage? designImage,
    pw.MemoryImage? materialsImage,
    pw.MemoryImage? completionImage,
  }) {
    try {
      return pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // "OUR WORKFLOW" heading - Compressed
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 8),
            color: PdfColors.brown50,
            child: pw.Text(
              'OUR WORKFLOW',
              style: pw.TextStyle(font: boldFont, fontSize: 8, color: PdfColors.brown900, letterSpacing: 1),
            ),
          ),
          pw.SizedBox(height: 5),

          // 4-step horizontal roadmap cards - Compact with 3D Visuals
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildCompactCard('01', 'Measurement', 'Accurate site measurement using a PCM Distance Meter.', pcmImage, PdfColors.blue800, font, boldFont),
              pw.SizedBox(width: 4),
              _buildCompactCard('02', '3D Design', 'Photorealistic 3D false ceiling design visualizer.', designImage, PdfColors.orange800, font, boldFont),
              pw.SizedBox(width: 4),
              _buildCompactCard('03', 'Installation', 'Premium Gypsum Board, metal channels, and professional installation.', materialsImage, PdfColors.purple800, font, boldFont),
              pw.SizedBox(width: 4),
              _buildCompactCard('04', 'Completion', 'Completed false ceiling work within the committed timeline.', completionImage, PdfColors.green800, font, boldFont),
            ],
          ),

          pw.SizedBox(height: 6),

          // Testimonial row - Minimalist
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 8),
            decoration: const pw.BoxDecoration(
              border: pw.Border(left: pw.BorderSide(color: PdfColors.brown300, width: 2)),
            ),
            child: pw.Text(
              '"PCM Wayanad transforms spaces into luxury with unmatched craftsmanship and professionalism."',
              style: pw.TextStyle(font: font, fontSize: 7, fontStyle: pw.FontStyle.italic, color: PdfColors.grey800),
            ),
          ),

          pw.SizedBox(height: 5),

          // Social media footer - Single line compact
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 8),
            color: PdfColors.brown50,
            child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.center, children: [
              pw.Text('PROJECTS: ', style: pw.TextStyle(font: boldFont, fontSize: 6.5, color: PdfColors.brown900)),
              pw.SizedBox(width: 5),
              PdfIcons.buildContactItem(PdfIcons.instaIcon(), '@PREMIUMCEILINGMASTERS', 'https://instagram.com/PREMIUMCEILINGMASTERS', font),
              pw.SizedBox(width: 10),
              PdfIcons.buildContactItem(PdfIcons.fbIcon(boldFont), 'Premium Ceiling Masters', 'https://facebook.com', font),
            ]),
          ),
        ],
      );
    } catch (e) {
      return pw.Text('WORKFLOW: SITE VISIT -> PLANNING -> MATERIALS -> COMPLETION',
          style: pw.TextStyle(font: font, fontSize: 7, color: PdfColors.grey600));
    }
  }

  static pw.Widget _buildCompactCard(
    String step,
    String title,
    String desc,
    pw.MemoryImage? img,
    PdfColor accentColor,
    pw.Font font,
    pw.Font boldFont,
  ) {
    return pw.Expanded(
      child: pw.Container(
        height: 60, // height of 60 to fit 3D images beautifully
        padding: const pw.EdgeInsets.all(4),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          border: pw.Border.all(color: PdfColors.grey200, width: 0.5),
        ),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text('$step $title', style: pw.TextStyle(font: boldFont, fontSize: 6.5, color: accentColor)),
                  pw.SizedBox(height: 2),
                  pw.Text(desc, style: pw.TextStyle(font: font, fontSize: 5.5, color: PdfColors.grey800, lineSpacing: 1)),
                ],
              ),
            ),
            if (img != null) ...[
              pw.SizedBox(width: 4),
              pw.Container(
                width: 25,
                height: 25,
                child: pw.Image(img, fit: pw.BoxFit.contain),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
