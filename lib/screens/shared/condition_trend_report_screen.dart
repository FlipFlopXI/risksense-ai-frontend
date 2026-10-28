import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medguide/services/api_client.dart';
import 'package:medguide/services/condition_trend_report.dart';
import 'package:medguide/theme/app_theme.dart';
import 'package:medguide/widgets/pdf_report_preview.dart';
import 'package:medguide/widgets/shared_widgets.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ConditionTrendReportScreen extends StatefulWidget {
  const ConditionTrendReportScreen({super.key, required this.condition});

  final String condition;

  @override
  State<ConditionTrendReportScreen> createState() =>
      _ConditionTrendReportScreenState();
}

class _ConditionTrendReportScreenState
    extends State<ConditionTrendReportScreen> {
  late Future<ConditionTrendReport> _report = _load();

  Future<ConditionTrendReport> _load() async {
    final data = Map<String, dynamic>.from(await ApiClient.instance
        .get('/health/trends', query: {'limit': 200}) as Map);
    return ConditionTrendReport.fromApi(widget.condition, data, DateTime.now());
  }

  Future<void> _refresh() async {
    final next = _load();
    setState(() => _report = next);
    await next;
  }

  Future<void> _openPdf(ConditionTrendReport report) async {
    final now = DateTime.now();
    final document = pw.Document();
    final label = widget.condition == 'diabetes' ? 'Diabetes' : 'Heart Disease';
    document.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      build: (_) => [
        pw.Text('RiskSense AI',
            style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue900)),
        pw.SizedBox(height: 10),
        pw.Text('$label Health Trends',
            style: pw.TextStyle(fontSize: 21, fontWeight: pw.FontWeight.bold)),
        pw.Text('Generated ${DateFormat.yMMMd().add_jm().format(now)}'),
        pw.SizedBox(height: 14),
        pw.Text('Patient-reported diagnosis. This report summarizes recorded '
            'measurements from the last seven days. It is not a disease-risk '
            'prediction or a clinical assessment of disease progression.'),
        pw.SizedBox(height: 18),
        pw.Text('Recorded trends',
            style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
        for (final metric in report.metrics) ...[
          pw.SizedBox(height: 9),
          pw.Text(metric.name,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text(metric.latest == null
              ? 'No reading recorded in the last seven days.'
              : 'Latest: ${metric.latest!.value.toStringAsFixed(1)} ${metric.unit} '
                  'on ${DateFormat.yMMMd().format(metric.latest!.at.toLocal())}. '
                  '${metric.direction}${metric.delta == null ? '' : ' by ${metric.delta!.abs().toStringAsFixed(1)} ${metric.unit}'} '
                  'across ${metric.readings.length} recorded reading${metric.readings.length == 1 ? '' : 's'}.'),
        ],
        pw.SizedBox(height: 18),
        pw.Text('Readings to discuss',
            style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
        pw.Text(report.readingsToReview.isEmpty
            ? 'No net increase was identified among the available glucose, '
                'blood pressure or cholesterol readings. Missing or single '
                'measurements cannot establish a trend.'
            : report.readingsToReview
                .map((m) =>
                    '${m.name}: increased by ${m.delta!.toStringAsFixed(1)} ${m.unit} '
                    'between the first and latest saved reading in this period.')
                .join('\n')),
        pw.SizedBox(height: 18),
        pw.Text(
            'A measured increase does not prove that a condition is worsening '
            'or identify its cause. Discuss concerning readings with your clinician. '
            'RiskSense AI does not replace diagnosis or treatment.'),
      ],
    ));
    final bytes = await document.save();
    if (!mounted) return;
    await PdfReportPreview.open(context,
        title: '$label health trends',
        filename: 'risksense-${widget.condition}-health-trends.pdf',
        bytes: bytes);
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final label = widget.condition == 'diabetes' ? 'Diabetes' : 'Heart Disease';
    final color = widget.condition == 'diabetes'
        ? AppColors.primaryBlue
        : AppColors.danger;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: MedAppBar(
          title: '$label Health Trends',
          showBack: true,
          helpTopic: 'Health Trends',
          showSecureBadge: false),
      body: FutureBuilder<ConditionTrendReport>(
        future: _report,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
                child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('Health trends could not be loaded.'),
                const SizedBox(height: 10),
                OutlinedButton(
                    onPressed: _refresh, child: const Text('Try Again')),
              ]),
            ));
          }
          final report = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(padding: const EdgeInsets.all(20), children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    color.withValues(alpha: .22),
                    AppColors.teal.withValues(alpha: .12),
                  ]),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: .35)),
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.monitor_heart_outlined,
                          color: color, size: 30),
                      const SizedBox(height: 8),
                      Text('$label Monitoring Overview',
                          style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 6),
                      Text(
                          'Your recorded measurements from the last seven days. '
                          'This is a trends report, not a new disease-risk prediction.',
                          style: TextStyle(
                              color: AppColors.textSecondary, height: 1.4)),
                    ]),
              ),
              const SizedBox(height: 18),
              for (final metric in report.metrics) ...[
                _metricCard(metric, color),
                const SizedBox(height: 12),
              ],
              _reviewCard(report, color),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.amber.withValues(alpha: .11),
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: AppColors.amber.withValues(alpha: .35)),
                ),
                child: Text(
                    'An increase in a reading does not prove that your '
                    'condition is worsening or identify a cause. Review concerning '
                    'changes with your clinician.',
                    style:
                        TextStyle(color: AppColors.textPrimary, height: 1.4)),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () => _openPdf(report),
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('View or Save PDF Report'),
              ),
              const SizedBox(height: 22),
            ]),
          );
        },
      ),
    );
  }

  Widget _metricCard(TrendMetric metric, Color color) {
    final latest = metric.latest;
    final points = metric.readings;
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 7));
    final values = points.map((r) => r.value).toList();
    final minimum =
        values.isEmpty ? 0.0 : values.reduce((a, b) => a < b ? a : b);
    final maximum =
        values.isEmpty ? 1.0 : values.reduce((a, b) => a > b ? a : b);
    final padding = (maximum - minimum).abs() < .01
        ? (maximum.abs() * .1).clamp(1.0, 20.0).toDouble()
        : (maximum - minimum) * .2;
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: color.withValues(alpha: .25))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(metric.name,
            style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 5),
        Text(
            latest == null
                ? 'No reading in the last 7 days'
                : '${latest.value.toStringAsFixed(1)} ${metric.unit}  ·  ${metric.direction}',
            style: TextStyle(
                color: latest == null ? AppColors.textSecondary : color,
                fontWeight: FontWeight.w600)),
        if (latest != null) ...[
          const SizedBox(height: 3),
          Text(
              'Last recorded ${DateFormat.MMMd().add_jm().format(latest.at.toLocal())}',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        ],
        if (points.length >= 2) ...[
          const SizedBox(height: 14),
          SizedBox(
              height: 80,
              child: LineChart(LineChartData(
                minX: 0,
                maxX: 7,
                minY: (minimum - padding).clamp(0, double.infinity).toDouble(),
                maxY: maximum + padding,
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      for (final r in points)
                        FlSpot(
                            r.at.difference(start).inMinutes / 1440.0, r.value)
                    ],
                    isCurved: false,
                    color: color,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                  )
                ],
              ))),
          const SizedBox(height: 4),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('7 days ago',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
            Text('Today',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
          ]),
        ],
      ]),
    );
  }

  Widget _reviewCard(ConditionTrendReport report, Color color) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: AppColors.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.bar_chart_rounded, color: color),
            const SizedBox(width: 8),
            Expanded(
                child: Text('Readings To Review',
                    style: Theme.of(context).textTheme.headlineSmall)),
          ]),
          const SizedBox(height: 8),
          Text(
              'Changes in recorded measurements, not model feature '
              'contributions or evidence of disease progression.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          if (report.readingsToReview.isEmpty)
            Text(
                'No net increase was found in the available glucose, blood '
                'pressure or cholesterol readings. Missing or single readings '
                'cannot establish a trend.',
                style: TextStyle(color: AppColors.textSecondary))
          else
            for (final metric in report.readingsToReview) ...[
              Text(
                  '${metric.name} increased by '
                  '${metric.delta!.toStringAsFixed(1)} ${metric.unit}',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
            ],
        ]),
      );
}
