import 'package:medguide/widgets/app_id_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:medguide/screens/clinician/clinician_prediction_screen.dart';
import 'package:medguide/services/api_client.dart';
import 'package:medguide/services/clinician_pdf.dart';
import 'package:medguide/theme/app_theme.dart';
import 'package:medguide/widgets/screen_help.dart';
import 'package:medguide/widgets/shared_widgets.dart';

class PatientDetailScreen extends StatefulWidget {
  final Map<String, dynamic> patient;
  const PatientDetailScreen({super.key, required this.patient});
  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  late Future<Map<String, dynamic>> _summary;
  Map<String, dynamic>? _cached;
  bool _updating = false;
  @override
  void initState() {
    super.initState();
    _summary = _load();
  }

  Future<Map<String, dynamic>> _load() async {
    final next = Map<String, dynamic>.from(await ApiClient.instance
        .get('/clinicians/patients/${widget.patient['id']}/summary') as Map);
    _cached = next;
    return next;
  }

  Future<void> _refresh() async {
    setState(() {
      _updating = true;
      _summary = _load();
    });
    try {
      await _summary;
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  Future<void> _showId(String id) =>
      showAppIdDialog(context, title: 'Patient ID', id: id);

  String _date(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '');
    return date == null
        ? 'Not recorded'
        : DateFormat.yMMMd().add_jm().format(date.toLocal());
  }

  String _value(dynamic value, [String unit = '']) =>
      value == null ? 'Not recorded' : '$value${unit.isEmpty ? '' : ' $unit'}';

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
          title: Text(widget.patient['name']?.toString() ?? 'Patient details',
              maxLines: 1, overflow: TextOverflow.ellipsis),
          actions: const [ScreenHelpButton(topic: 'Patient Detail')]),
      body: FutureBuilder<Map<String, dynamic>>(
          future: _summary,
          builder: (context, state) {
            if (state.hasError && _cached == null)
              return Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('Unable to load linked patient: ${state.error}',
                    textAlign: TextAlign.center),
                TextButton(onPressed: _refresh, child: const Text('Retry'))
              ]));
            if (!state.hasData && _cached == null)
              return const Center(child: CircularProgressIndicator());
            final summary = state.data ?? _cached!;
            final patient =
                Map<String, dynamic>.from(summary['patient'] as Map);
            final profile = summary['profile'] as Map? ?? {};
            final vital = summary['latest_vital'] as Map? ?? {};
            final labs = summary['latest_labs'] as Map? ?? {};
            final predictions = summary['latest_predictions'] as Map? ?? {};
            final name = '${patient['first_name']} ${patient['last_name']}';
            final gender = patient['gender']?.toString().toLowerCase();
            final female =
                gender == 'female' || gender == 'woman' || gender == 'f';
            final dob =
                DateTime.tryParse(patient['date_of_birth']?.toString() ?? '');
            final now = DateTime.now();
            final age = dob == null
                ? null
                : now.year -
                    dob.year -
                    ((now.month < dob.month ||
                            (now.month == dob.month && now.day < dob.day))
                        ? 1
                        : 0);
            final diabetes = predictions['diabetes_risk'] as Map?;
            final heart = predictions['heart_disease'] as Map?;
            final count = (summary['drug_enquiry_count'] as num?)?.toInt() ?? 0;
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(padding: const EdgeInsets.all(20), children: [
                Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                            colors: female
                                ? AppColors.femaleGradient
                                : [AppColors.heroStart, AppColors.heroEnd])),
                    child: Row(children: [
                      CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.white24,
                          child: Text(name.isEmpty ? '?' : name.substring(0, 1),
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 23))),
                      const SizedBox(width: 16),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700)),
                            Text(
                                'Age ${age ?? 'not recorded'} • ${patient['gender'] ?? 'Sex not recorded'}',
                                style: const TextStyle(color: Colors.white70)),
                            InkWell(
                                onTap: () => _showId('${patient['id']}'),
                                child: const Text('Tap to view ID',
                                    style: TextStyle(
                                        color: Color(0xFFD7E9FF),
                                        decoration: TextDecoration.underline))),
                          ])),
                    ])),
                const SizedBox(height: 16),
                _section(context, 'Patient Demographics',
                    Icons.person_outline_rounded, [
                  InfoRow(
                      label: 'Date of birth',
                      value: patient['date_of_birth'] ?? 'Not recorded'),
                  InfoRow(label: 'Gender', value: _value(patient['gender'])),
                  InfoRow(
                      label: 'Ethnicity', value: _value(patient['ethnicity'])),
                ]),
                const SizedBox(height: 14),
                _section(
                    context, 'Clinical Data', Icons.monitor_heart_outlined, [
                  Align(
                      alignment: Alignment.centerRight,
                      child: Chip(
                          avatar: Icon(
                              _updating
                                  ? Icons.sync_rounded
                                  : Icons.check_circle_outline,
                              size: 16,
                              color: AppColors.teal),
                          label: Text(_updating
                              ? 'Updating…'
                              : 'Updated ${_date(summary['clinical_data_updated_at'])}'))),
                  InfoRow(label: 'BMI', value: _value(profile['bmi'])),
                  InfoRow(
                      label: 'Blood pressure',
                      value: vital['blood_pressure_systolic'] == null ||
                              vital['blood_pressure_diastolic'] == null
                          ? 'Not recorded'
                          : '${vital['blood_pressure_systolic']}/${vital['blood_pressure_diastolic']} mmHg'),
                  InfoRow(
                      label: 'Heart rate',
                      value: _value(vital['heart_rate'], 'bpm')),
                  if (vital['blood_pressure_recorded_at'] != null)
                    InfoRow(
                        label: 'BP recorded',
                        value: _date(vital['blood_pressure_recorded_at'])),
                  if (vital['heart_rate_recorded_at'] != null)
                    InfoRow(
                        label: 'Heart rate recorded',
                        value: _date(vital['heart_rate_recorded_at'])),
                  for (final entry in labs.entries)
                    InfoRow(
                        label: entry.key.toString().replaceAll('_', ' '),
                        value:
                            '${(entry.value as Map)['value']} ${(entry.value as Map)['unit']}'),
                ]),
                const SizedBox(height: 14),
                _section(
                    context, 'Risk Predictions', Icons.analytics_outlined, [
                  Text(
                      'Open a prediction to see its interpretation, actual contributing factors and input snapshot.',
                      style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 12),
                  _predictionTile(
                      'Latest Diabetes', diabetes, patient['id'].toString()),
                  _predictionTile(
                      'Latest Heart Disease', heart, patient['id'].toString()),
                  const SizedBox(height: 8),
                  Row(children: [
                    const Expanded(
                        child: Text('Total Drug Assistant enquiries',
                            style: TextStyle(fontWeight: FontWeight.w600))),
                    CountMeterWidget(label: 'Enquiries', count: count),
                  ]),
                ]),
                const SizedBox(height: 16),
                const DisclaimerBanner(),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('PDF Patient Summary'),
                    onPressed: () => ClinicianPdf.export(context,
                            title: 'RiskSense AI patient summary — $name',
                            lines: [
                              'Patient ID: ${patient['id']}',
                              'Date of birth: ${patient['date_of_birth'] ?? 'Not recorded'}',
                              'Gender: ${_value(patient['gender'])}',
                              'Ethnicity: ${_value(patient['ethnicity'])}',
                              'Clinical data updated: ${_date(summary['clinical_data_updated_at'])}',
                              'BMI: ${_value(profile['bmi'])}',
                              'Blood pressure: ${_value(vital['blood_pressure_systolic'])}/${_value(vital['blood_pressure_diastolic'])} mmHg',
                              'Heart rate: ${_value(vital['heart_rate'], 'bpm')}',
                              ...labs.entries.map((entry) =>
                                  '${entry.key}: ${(entry.value as Map)['value']} ${(entry.value as Map)['unit']}'),
                              'Latest Diabetes: ${diabetes?['risk_score'] == null ? 'Not recorded' : '${((diabetes!['risk_score'] as num) * 100).toStringAsFixed(1)}%'}',
                              'Latest Heart Disease: ${heart?['risk_score'] == null ? 'Not recorded' : '${((heart!['risk_score'] as num) * 100).toStringAsFixed(1)}%'}',
                              'Drug Assistant enquiries: $count',
                            ])),
                const SizedBox(height: 20),
              ]),
            );
          }),
    );
  }

  Widget _predictionTile(String title, Map? prediction, String patientId) {
    if (prediction == null)
      return ListTile(
          title: Text(title), subtitle: const Text('No prediction recorded'));
    final score = (prediction['risk_score'] as num?)?.toDouble();
    return Card(
        color: AppColors.surfaceBlue,
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          title:
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(
              '${_date(prediction['predicted_at'])} • ${prediction['risk_classification']}'),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(score == null ? '—' : '${(score * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
            const Icon(Icons.chevron_right_rounded),
          ]),
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => ClinicianPredictionScreen(
                      patientId: patientId,
                      predictionId: prediction['id'].toString()))),
        ));
  }

  Widget _section(BuildContext context, String title, IconData icon,
          List<Widget> children) =>
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, size: 19, color: AppColors.primaryBlue),
            const SizedBox(width: 8),
            Expanded(
                child: Text(title,
                    style: Theme.of(context).textTheme.headlineSmall))
          ]),
          const Divider(height: 24),
          ...children,
        ]),
      );
}
