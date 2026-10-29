import 'package:medguide/widgets/app_form_dialog.dart';
import 'package:medguide/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:medguide/widgets/pdf_report_preview.dart';

/// Exports only the data explicitly supplied by the current authorized screen.
class ClinicianPdf {
  static Future<void> export(
    BuildContext context, {
    required String title,
    required List<String> lines,
  }) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AppFormDialog(
        icon: Icons.privacy_tip_outlined,
        title: const Text('Protect Patient Information'),
        content: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border)),
          child: const Text(
              'This PDF may contain personal health information protected by South Africa’s POPIA. Only generate, store or share it for an authorized clinical purpose. Check the recipient and use a secure location before continuing.'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Continue to PDF')),
        ],
      ),
    );
    if (approved != true || !context.mounted) return;
    final document = pw.Document();
    document.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (_) => [
        pw.Text(title,
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 14),
        ...lines.map((line) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 7),
              child: pw.Text(line, style: const pw.TextStyle(fontSize: 11)),
            )),
        pw.SizedBox(height: 16),
        pw.Text(
            'RiskSense AI provides decision support, not a diagnosis or treatment recommendation.',
            style: const pw.TextStyle(fontSize: 9)),
      ],
    ));
    final bytes = await document.save();
    if (!context.mounted) return;
    await PdfReportPreview.open(context,
        title: title, filename: 'risksense-clinical-report.pdf', bytes: bytes);
  }
}
