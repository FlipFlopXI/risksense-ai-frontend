import 'package:medguide/services/prediction_input_display.dart';
import 'package:medguide/widgets/app_id_dialog.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medguide/services/api_client.dart';
import 'package:medguide/services/clinician_pdf.dart';
import 'package:medguide/theme/app_theme.dart';
import 'package:medguide/widgets/screen_help.dart';
import 'package:medguide/widgets/shared_widgets.dart';

class ClinicianPredictionScreen extends StatefulWidget {
  final String patientId, predictionId;
  const ClinicianPredictionScreen(
      {super.key, required this.patientId, required this.predictionId});
  @override
  State<ClinicianPredictionScreen> createState() =>
      _ClinicianPredictionScreenState();
}

class _ClinicianPredictionScreenState extends State<ClinicianPredictionScreen> {
  late Future<Map<String, dynamic>> _details;
  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _details = Future.wait([
      ApiClient.instance.get(
          '/clinicians/patients/${widget.patientId}/predictions/${widget.predictionId}'),
      ApiClient.instance.get('/clinicians/patients/${widget.patientId}'),
    ]).then((items) => {
          'detail': Map<String, dynamic>.from(items[0] as Map),
          'patient': Map<String, dynamic>.from(items[1] as Map)
        });
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
          title: const Text('Risk Prediction'),
          actions: const [ScreenHelpButton(topic: 'Prediction Result')]),
      body: FutureBuilder<Map<String, dynamic>>(
          future: _details,
          builder: (context, state) {
            if (state.hasError)
              return Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('Unable to load prediction: ${state.error}',
                    textAlign: TextAlign.center),
                TextButton(
                    onPressed: () => setState(_reload),
                    child: const Text('Retry'))
              ]));
            if (!state.hasData)
              return const Center(child: CircularProgressIndicator());
            final detail = state.data!['detail'] as Map<String, dynamic>;
            final prediction =
                Map<String, dynamic>.from(detail['prediction'] as Map);
            final patient = state.data!['patient'] as Map<String, dynamic>;
            final snapshot = detail['input_snapshot'] as Map? ?? {};
            final inputRows = PredictionInputDisplay.rows(snapshot);
            final factors = (prediction['contributing_factors'] as List? ?? [])
                .whereType<Map>()
                .toList();
            final score = (prediction['risk_score'] as num?)?.toDouble();
            final condition = prediction['prediction_target'] == 'diabetes_risk'
                ? 'Diabetes'
                : 'Heart Disease';
            final at =
                DateTime.tryParse(prediction['predicted_at']?.toString() ?? '');
            final name = '${patient['first_name']} ${patient['last_name']}';
            return ListView(padding: const EdgeInsets.all(20), children: [
              Text(name, style: Theme.of(context).textTheme.headlineLarge),
              Text(
                  '$condition analysis • ${at == null ? 'Date unavailable' : DateFormat.yMMMd().add_jm().format(at.toLocal())}',
                  style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 18),
              Card(
                  color: AppColors.cardWhite,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(children: [
                      Icon(
                          condition == 'Diabetes'
                              ? Icons.bloodtype_rounded
                              : Icons.favorite_rounded,
                          color: AppColors.primaryBlue,
                          size: 34),
                      const SizedBox(height: 10),
                      Text(
                          score == null
                              ? 'Score unavailable'
                              : '${(score * 100).toStringAsFixed(1)}%',
                          style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryBlue)),
                      Text(
                          '${prediction['risk_classification'] ?? 'Unknown'} model classification',
                          textAlign: TextAlign.center),
                      const SizedBox(height: 8),
                      InkWell(
                          onTap: () => showAppIdDialog(context,
                              title: 'Prediction ID', id: widget.predictionId),
                          child: Text('Tap to View ID',
                              style: TextStyle(
                                  color: AppColors.primaryBlue,
                                  decoration: TextDecoration.underline,
                                  fontWeight: FontWeight.w600))),
                    ]),
                  )),
              const SizedBox(height: 12),
              _panel(context, 'AI Interpretation', Icons.psychology_outlined, [
                Text(
                    '${prediction['interpretation'] ?? prediction['explanation'] ?? 'Interpretation unavailable.'}'),
              ]),
              const SizedBox(height: 12),
              _panel(context, 'Contributing factors', Icons.bar_chart_rounded, [
                if (factors.isEmpty)
                  const Text('Feature contributions unavailable.'),
                for (final factor in factors)
                  FeatureImpactBar(
                      feature: '${factor['feature']}'.replaceAll('_', ' '),
                      impact: '${factor['direction']} score',
                      percent:
                          ((factor['relative_magnitude'] as num?)?.toDouble() ??
                                  0)
                              .clamp(0.0, 1.0),
                      color: factor['direction'] == 'raises'
                          ? AppColors.amber
                          : AppColors.teal),
              ]),
              const SizedBox(height: 12),
              _panel(context, 'Inputs used by this prediction',
                  Icons.fact_check_outlined, [
                if (inputRows.isEmpty)
                  const Text('Input snapshot unavailable.'),
                for (final row in inputRows)
                  InfoRow(label: row.$1, value: row.$2),
              ]),
              const SizedBox(height: 14),
              const DisclaimerBanner(),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('Generate PDF Report'),
                onPressed: () => ClinicianPdf.export(context,
                    title: '$condition risk analysis — $name',
                    lines: [
                      'Patient ID: ${widget.patientId}',
                      'Prediction ID: ${widget.predictionId}',
                      'Date: ${at?.toLocal() ?? 'Unavailable'}',
                      'Model version: ${prediction['model_version'] ?? 'Unavailable'}',
                      'Estimated score: ${score == null ? 'Unavailable' : '${(score * 100).toStringAsFixed(1)}%'}',
                      'Classification: ${prediction['risk_classification'] ?? 'Unavailable'}',
                      '${prediction['interpretation'] ?? prediction['explanation'] ?? ''}',
                      'Inputs used by this prediction:',
                      ...inputRows.map((row) => '${row.$1}: ${row.$2}'),
                      ...factors.map((factor) =>
                          '${factor['feature']}: ${factor['direction']} score'),
                    ]),
              ),
            ]);
          }),
    );
  }

  Widget _panel(BuildContext context, String title, IconData icon,
          List<Widget> children) =>
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, color: AppColors.primaryBlue, size: 18),
            const SizedBox(width: 8),
            Expanded(
                child: Text(title,
                    style: Theme.of(context).textTheme.headlineSmall))
          ]),
          const SizedBox(height: 12),
          ...children,
        ]),
      );
}
