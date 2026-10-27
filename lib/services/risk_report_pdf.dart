import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:medguide/services/api_client.dart';
import 'package:medguide/widgets/pdf_report_preview.dart';

class RiskReportPdf {
  static Future<Uint8List> fetchForPrediction(String predictionId) async {
    final report = Map<String, dynamic>.from(await ApiClient.instance
        .post('/reports', data: {'prediction_id': predictionId}) as Map);
    final reportId = report['id']?.toString();
    if (reportId == null || reportId.isEmpty) {
      throw ApiException('The risk report could not be created.');
    }
    return ApiClient.instance.getBytes('/reports/$reportId/pdf');
  }

  static Future<void> open(BuildContext context, String predictionId) async {
    final bytes = await fetchForPrediction(predictionId);
    if (!context.mounted) return;
    await PdfReportPreview.open(context,
        title: 'Risk analysis report',
        filename: 'risksense-risk-report-$predictionId.pdf',
        bytes: bytes);
  }
}
