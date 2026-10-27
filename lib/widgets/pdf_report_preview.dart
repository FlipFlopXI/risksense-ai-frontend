import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

/// Opens the same PDF preview with print, save and share actions for every report.
class PdfReportPreview {
  static Future<void> open(
    BuildContext context, {
    required String title,
    required String filename,
    required Uint8List bytes,
  }) async {
    await Navigator.of(context).push<void>(MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: PdfPreview(
          build: (_) async => bytes,
          pdfFileName: filename,
          initialPageFormat: PdfPageFormat.a4,
          canChangePageFormat: false,
          canChangeOrientation: false,
          canDebug: false,
          allowPrinting: true,
          allowSharing: true,
        ),
      ),
    ));
  }
}
