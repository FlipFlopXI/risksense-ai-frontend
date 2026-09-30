import 'package:flutter/material.dart';
import 'package:medguide/screens/shared/prediction_result_screen.dart';
import 'package:medguide/services/api_client.dart';
import 'package:medguide/theme/app_theme.dart';
import 'package:medguide/widgets/shared_widgets.dart';

class DataInputScreen extends StatefulWidget {
  const DataInputScreen({super.key});
  @override
  State<DataInputScreen> createState() => _DataInputScreenState();
}

class _DataInputScreenState extends State<DataInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _height = TextEditingController(), _weight = TextEditingController();
  final _waist = TextEditingController(), _systolic = TextEditingController();
  final _diastolic = TextEditingController(),
      _heartRate = TextEditingController();
  final _oxygen = TextEditingController(),
      _temperature = TextEditingController();
  final _fastingGlucose = TextEditingController(),
      _cholesterol = TextEditingController();
  final _expanded = <String, bool>{
    'Demographics': false,
    'Lifestyle': false,
    'Vitals': false,
    'Model laboratory inputs': false
  };
  String _smoking = 'Not recorded',
      _activity = 'Not recorded',
      _alcohol = 'Not recorded';
  String _model = 'diabetes';
  Map<String, dynamic>? _patient;
  bool _profileExists = false, _loading = true, _submitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final patient = Map<String, dynamic>.from(
          await ApiClient.instance.get('/patients/me'));
      Map<String, dynamic>? profile;
      try {
        profile = Map<String, dynamic>.from(
            await ApiClient.instance.get('/health/profile'));
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _patient = patient;
        _profileExists = profile != null;
        _set(_height, profile?['height_cm']);
        _set(_weight, profile?['weight_kg']);
        _set(_waist, profile?['waist_circumference_cm']);
        _smoking = profile?['smoking_status']?.toString() ?? 'Not recorded';
        _activity = profile?['activity_level']?.toString() ?? 'Not recorded';
        _alcohol = profile?['alcohol_status']?.toString() ?? 'Not recorded';
        _loading = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() => _loading = false);
        _message(error.toString(), error: true);
      }
    }
  }

  void _set(TextEditingController controller, dynamic value) {
    if (value != null) controller.text = value.toString();
  }

  double? _number(TextEditingController controller) =>
      controller.text.trim().isEmpty
          ? null
          : double.tryParse(controller.text.trim());
  int? get _age {
    final dob = DateTime.tryParse(_patient?['date_of_birth']?.toString() ?? '');
    if (dob == null) return null;
    final now = DateTime.now();
    return now.year -
        dob.year -
        ((now.month < dob.month ||
                (now.month == dob.month && now.day < dob.day))
            ? 1
            : 0);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      final profile = <String, dynamic>{
        'height_cm': _number(_height),
        'weight_kg': _number(_weight),
        'waist_circumference_cm': _number(_waist),
        'smoking_status': _nullIfUnset(_smoking),
        'activity_level': _nullIfUnset(_activity),
        'alcohol_status': _nullIfUnset(_alcohol),
        'body_measurement_at': now,
      };
      if (_profileExists) {
        await ApiClient.instance.put('/health/profile', data: profile);
      } else {
        await ApiClient.instance.post('/health/profile', data: profile);
        _profileExists = true;
      }
      final vital = <String, dynamic>{
        'blood_pressure_systolic': _number(_systolic),
        'blood_pressure_diastolic': _number(_diastolic),
        'heart_rate': _number(_heartRate),
        'oxygen_saturation': _number(_oxygen),
        'temperature': _number(_temperature),
        'recorded_at': now,
      }..removeWhere((key, value) => value == null);
      if (vital.length > 1) {
        await ApiClient.instance.post('/health/vitals/', data: vital);
      }
      if (_number(_fastingGlucose) != null) {
        await _saveLab(
            'fasting_glucose', _number(_fastingGlucose)!, 'mg/dL', now);
      }
      if (_number(_cholesterol) != null) {
        await _saveLab(
            'total_cholesterol', _number(_cholesterol)!, 'mg/dL', now);
      }
      final result = Map<String, dynamic>.from(await ApiClient.instance
          .post('/risk-analysis', data: {'model': _model}));
      if (!mounted) return;
      setState(() => _submitting = false);
      await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => PredictionResultScreen(
              condition: _model == 'diabetes' ? 'Diabetes' : 'Heart Disease',
              riskScore: (result['risk_score'] as num).toDouble(),
              riskClassification: result['risk_classification']?.toString(),
              interpretation: result['interpretation']?.toString(),
              contributingFactors:
                  (result['contributing_factors'] as List<dynamic>? ?? const [])
                      .whereType<Map>()
                      .map((item) => Map<String, dynamic>.from(item))
                      .toList())));
      if (mounted) setState(() => _expanded.updateAll((key, value) => true));
    } on ApiException catch (error) {
      if (mounted) _message(error.message, error: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _saveLab(
          String type, double value, String unit, String measuredAt) =>
      ApiClient.instance.post('/health/labs/', data: {
        'test_type': type,
        'value': value,
        'unit': unit,
        'source': 'patient_entered',
        'measured_at': measuredAt,
      });
  String? _nullIfUnset(String value) => value == 'Not recorded' ? null : value;
  void _message(String value, {bool error = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(value),
          backgroundColor: error ? AppColors.danger : AppColors.success));

  @override
  void dispose() {
    for (final c in [
      _height,
      _weight,
      _waist,
      _systolic,
      _diastolic,
      _heartRate,
      _oxygen,
      _temperature,
      _fastingGlucose,
      _cholesterol
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: const MedAppBar(
            title: 'Health Data Input', showBack: true, showSecureBadge: false),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(padding: const EdgeInsets.all(20), children: [
                  Text('Clinical Profile',
                      style: Theme.of(context).textTheme.headlineLarge),
                  const Text(
                      'Record current measurements, then choose a risk model.'),
                  const SizedBox(height: 20),
                  _section('Demographics', Icons.person_rounded,
                      AppColors.primaryBlue, [
                    _readonly('Age', _age?.toString() ?? 'Not recorded',
                        Icons.cake_rounded, AppColors.amber),
                    _readonly(
                        'Sex',
                        _patient?['gender']?.toString() ?? 'Not recorded',
                        Icons.badge_rounded,
                        AppColors.teal),
                    _readonly(
                        'Ethnicity',
                        _patient?['ethnicity']?.toString() ?? 'Not recorded',
                        Icons.public_rounded,
                        AppColors.primaryBlue),
                    const Text(
                        'Demographics come from registration and cannot be changed here.',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ]),
                  _section('Lifestyle', Icons.directions_run_rounded,
                      AppColors.success, [
                    _dropdown(
                        'Smoking status',
                        _smoking,
                        ['Not recorded', 'Never', 'Former', 'Current'],
                        Icons.smoke_free_rounded,
                        AppColors.danger,
                        (v) => setState(() => _smoking = v!)),
                    _dropdown(
                        'Activity level',
                        _activity,
                        [
                          'Not recorded',
                          'Sedentary',
                          'Light',
                          'Moderate',
                          'Active'
                        ],
                        Icons.fitness_center_rounded,
                        AppColors.success,
                        (v) => setState(() => _activity = v!)),
                    _dropdown(
                        'Alcohol use',
                        _alcohol,
                        ['Not recorded', 'None', 'Occasional', 'Regular'],
                        Icons.local_bar_rounded,
                        AppColors.amber,
                        (v) => setState(() => _alcohol = v!)),
                  ]),
                  _section(
                      'Vitals', Icons.monitor_heart_rounded, AppColors.danger, [
                    _row([
                      _field('Height (cm)', _height, Icons.height_rounded,
                          AppColors.primaryBlue),
                      _field('Weight (kg)', _weight,
                          Icons.monitor_weight_rounded, AppColors.teal)
                    ]),
                    _field('Waist circumference (cm)', _waist,
                        Icons.straighten_rounded, AppColors.amber),
                    _row([
                      _field('Systolic BP', _systolic, Icons.favorite_rounded,
                          AppColors.danger),
                      _field('Diastolic BP', _diastolic,
                          Icons.favorite_border_rounded, AppColors.danger)
                    ]),
                    _row([
                      _field('Heart rate (bpm)', _heartRate,
                          Icons.monitor_heart_rounded, AppColors.teal),
                      _field('Oxygen saturation (%)', _oxygen,
                          Icons.air_rounded, AppColors.primaryBlue)
                    ]),
                    _field('Temperature (°C)', _temperature,
                        Icons.thermostat_rounded, AppColors.amber),
                  ]),
                  _section('Model laboratory inputs', Icons.science_rounded,
                      AppColors.primaryBlue, [
                    _field('Fasting glucose (mg/dL)', _fastingGlucose,
                        Icons.water_drop_rounded, AppColors.primaryBlue),
                    _field('Total cholesterol (mg/dL)', _cholesterol,
                        Icons.biotech_rounded, AppColors.teal),
                  ]),
                  const DisclaimerBanner(),
                  const SizedBox(height: 20),
                  Text('Choose risk analysis',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                        child: _modelCard('diabetes', 'Diabetes',
                            Icons.bloodtype_rounded, AppColors.primaryBlue)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _modelCard('heart_disease', 'Heart Disease',
                            Icons.favorite_rounded, AppColors.danger))
                  ]),
                  const SizedBox(height: 18),
                  SizedBox(
                      height: 54,
                      child: ElevatedButton.icon(
                          onPressed: _submitting ? null : _submit,
                          icon: _submitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.analytics_rounded),
                          label: Text(
                              'Run ${_model == 'diabetes' ? 'Diabetes' : 'Heart Disease'} Analysis'))),
                  const SizedBox(height: 24),
                ])),
      );

  Widget _section(
      String title, IconData icon, Color color, List<Widget> children) {
    final open = _expanded[title] ?? false;
    return Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border)),
        child: Column(children: [
          ListTile(
              onTap: () => setState(() => _expanded[title] = !open),
              leading: Icon(icon, size: 26, color: color),
              title: Text(title,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              trailing: Icon(open ? Icons.expand_less : Icons.expand_more)),
          if (open)
            Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(children: children))
        ]));
  }

  Widget _readonly(String label, String value, IconData icon, Color color) =>
      Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: TextFormField(
              initialValue: value,
              readOnly: true,
              decoration: InputDecoration(
                  labelText: label,
                  prefixIcon: Icon(icon, size: 25, color: color),
                  filled: true,
                  fillColor: AppColors.background)));
  Widget _field(
          String label, TextEditingController c, IconData icon, Color color) =>
      Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextFormField(
              controller: c,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                  labelText: label,
                  prefixIcon: Icon(icon, size: 25, color: color)),
              validator: (v) => v != null &&
                      v.trim().isNotEmpty &&
                      double.tryParse(v.trim()) == null
                  ? 'Enter a valid number'
                  : null));
  Widget _dropdown(String label, String value, List<String> values,
          IconData icon, Color color, ValueChanged<String?> changed) =>
      Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: DropdownButtonFormField<String>(
              initialValue: values.contains(value) ? value : values.first,
              decoration: InputDecoration(
                  labelText: label,
                  prefixIcon: Icon(icon, size: 25, color: color)),
              items: values
                  .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                  .toList(),
              onChanged: changed));
  Widget _row(List<Widget> values) =>
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (int i = 0; i < values.length; i++)
          Expanded(
              child: Padding(
                  padding:
                      EdgeInsets.only(right: i < values.length - 1 ? 10 : 0),
                  child: values[i]))
      ]);
  Widget _modelCard(String value, String label, IconData icon, Color color) {
    final selected = _model == value;
    return InkWell(
        onTap: () => setState(() => _model = value),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: selected ? color.withValues(alpha: .12) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: selected ? color : AppColors.border,
                    width: selected ? 2 : 1)),
            child: Column(children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: selected ? color : AppColors.textPrimary)),
              const SizedBox(height: 4),
              Icon(selected ? Icons.check_circle : Icons.circle_outlined,
                  color: selected ? color : AppColors.textLight)
            ])));
  }
}
