import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:medguide/screens/shared/prediction_result_screen.dart';
import 'package:medguide/services/api_client.dart';
import 'package:medguide/theme/app_theme.dart';
import 'package:medguide/widgets/shared_widgets.dart';
import 'package:medguide/widgets/wearable_sync_button.dart';
import 'package:medguide/services/vital_sync.dart';

class DataInputScreen extends StatefulWidget {
  final bool clinicianMode;
  const DataInputScreen({super.key, this.clinicianMode = false});
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
  final _ageInput = TextEditingController(),
      _ethnicityInput = TextEditingController();
  String _sexInput = 'Female';
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
  Map<String, dynamic>? _fitnessBody;
  bool _profileExists = false, _loading = true, _submitting = false;
  bool _wasListening = false;
  final Map<TextEditingController, String> _manualVitals = {};

  @override
  void initState() {
    super.initState();
    if (!widget.clinicianMode) VitalSync.instance.addListener(_onVitalSync);
    _load();
  }

  void _onVitalSync() {
    final sync = VitalSync.instance;
    if (sync.listening && !_wasListening) {
      for (final c in [
        _systolic,
        _diastolic,
        _heartRate,
        _oxygen,
        _temperature
      ]) {
        _manualVitals[c] = c.text;
        c.clear();
      }
    }
    if (!sync.listening && _wasListening) {
      for (final entry in _manualVitals.entries) {
        entry.key.text = entry.value;
      }
      _manualVitals.clear();
    }
    _wasListening = sync.listening;
    if (sync.listening && sync.current != null) {
      final r = sync.current!;
      for (final item in <(TextEditingController, String)>[
        (_systolic, 'blood_pressure_systolic'),
        (_diastolic, 'blood_pressure_diastolic'),
        (_heartRate, 'heart_rate'),
        (_oxygen, 'oxygen_saturation'),
        (_temperature, 'temperature'),
      ]) {
        final value = r[item.$2];
        if (value != null) item.$1.text = value.toString();
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    if (widget.clinicianMode) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      Future<Map<String, dynamic>?> optional(String path) async {
        try {
          return Map<String, dynamic>.from(await ApiClient.instance.get(path));
        } catch (_) {
          return null;
        }
      }

      final results = await Future.wait<dynamic>([
        ApiClient.instance.get('/patients/me'),
        optional('/health/profile'),
        optional('/fitness/body'),
      ]);
      final patient = Map<String, dynamic>.from(results[0] as Map);
      final profile = results[1] as Map<String, dynamic>?;
      final fitnessBody = results[2] as Map<String, dynamic>?;
      if (!mounted) return;
      setState(() {
        _patient = patient;
        _fitnessBody = fitnessBody;
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
    setState(() => _expanded.updateAll((key, value) => true));
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    if (!_formKey.currentState!.validate()) return;
    final systolic = _number(_systolic), diastolic = _number(_diastolic);
    if (systolic != null && diastolic != null && diastolic >= systolic) {
      _message(
          'Diastolic blood pressure must be lower than systolic blood pressure.',
          error: true);
      setState(() => _expanded['Vitals'] = true);
      return;
    }
    setState(() => _submitting = true);
    try {
      if (widget.clinicianMode) {
        final result = Map<String, dynamic>.from(await ApiClient.instance.post(
          '/clinicians/assessment',
          data: {
            'model': _model,
            'age': int.tryParse(_ageInput.text.trim()),
            'sex': _sexInput.toLowerCase(),
            'ethnicity': _ethnicityInput.text.trim().isEmpty
                ? null
                : _ethnicityInput.text.trim(),
            'height_cm': _number(_height),
            'weight_kg': _number(_weight),
            'waist_circumference_cm': _number(_waist),
            'systolic_bp': _number(_systolic),
            'diastolic_bp': _number(_diastolic),
            'fasting_glucose': _number(_fastingGlucose),
            'total_cholesterol': _number(_cholesterol),
          },
        ));
        if (!mounted) return;
        await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => PredictionResultScreen(
            condition: _model == 'diabetes' ? 'Diabetes' : 'Heart Disease',
            riskScore: (result['risk_score'] as num).toDouble(),
            riskClassification: result['risk_classification']?.toString(),
            interpretation: result['interpretation']?.toString(),
            contributingFactors:
                (result['contributing_factors'] as List? ?? const [])
                    .whereType<Map>()
                    .map((item) => Map<String, dynamic>.from(item))
                    .toList(),
            clinicianMode: true,
          ),
        ));
        if (mounted) setState(() => _expanded.updateAll((key, value) => true));
        return;
      }
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
      if (vital.length > 1 && !VitalSync.instance.listening) {
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
              predictionId: result['id']?.toString(),
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
  void _message(String value, {bool error = false}) {
    if (error) {
      showDialog<void>(
          context: context,
          builder: (dialog) => AlertDialog(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  title: const Text('Unable To Save Health Data'),
                  content: Text(value),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(dialog),
                        child: const Text('Dismiss'))
                  ]));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(value), backgroundColor: AppColors.success));
    }
  }

  @override
  void dispose() {
    if (!widget.clinicianMode) VitalSync.instance.removeListener(_onVitalSync);
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
      _cholesterol,
      _ageInput,
      _ethnicityInput,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Scaffold(
        backgroundColor: AppColors.background,
        appBar: MedAppBar(
            title: widget.clinicianMode
                ? 'Demonstration Analysis'
                : 'Health Data Input',
            helpTopic: widget.clinicianMode
                ? 'Demonstration Analysis'
                : 'Health Data Input',
            actions: widget.clinicianMode ? null : [const WearableSyncButton()],
            showBack: !widget.clinicianMode,
            showSecureBadge: false),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(padding: const EdgeInsets.all(20), children: [
                  Text('Clinical Profile',
                      style: Theme.of(context).textTheme.headlineLarge),
                  Text(widget.clinicianMode
                      ? 'Enter demonstration measurements. Diabetes uses age, sex, height/weight, waist and blood pressure; Heart Disease uses age, sex, systolic BP, fasting glucose and total cholesterol. Nothing is saved.'
                      : 'Record current measurements, then choose a risk model.'),
                  const SizedBox(height: 20),
                  _section(
                      'Demographics',
                      Icons.person_rounded,
                      AppColors.primaryBlue,
                      widget.clinicianMode
                          ? [
                              _field('Age (years)', _ageInput,
                                  Icons.cake_rounded, AppColors.amber,
                                  required: true),
                              _dropdown(
                                  'Sex used by model',
                                  _sexInput,
                                  ['Female', 'Male'],
                                  Icons.badge_rounded,
                                  AppColors.teal,
                                  (v) => setState(() => _sexInput = v!)),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: TextFormField(
                                  controller: _ethnicityInput,
                                  decoration: InputDecoration(
                                    labelText:
                                        'Ethnicity (optional; not used by these models)',
                                    prefixIcon: Icon(Icons.public_rounded,
                                        color: AppColors.primaryBlue),
                                  ),
                                ),
                              ),
                              Text(
                                  'Demonstration inputs are used in memory for this analysis and are not saved to a patient record.',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary)),
                            ]
                          : [
                              _readonly(
                                  'Age',
                                  _age?.toString() ?? 'Not recorded',
                                  Icons.cake_rounded,
                                  AppColors.amber),
                              _readonly(
                                  'Sex',
                                  _patient?['gender']?.toString() ??
                                      'Not recorded',
                                  Icons.badge_rounded,
                                  AppColors.teal),
                              _readonly(
                                  'Ethnicity',
                                  _patient?['ethnicity']?.toString() ??
                                      'Not recorded',
                                  Icons.public_rounded,
                                  AppColors.primaryBlue),
                              Text(
                                  'Demographics come from registration and cannot be changed here.',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary)),
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
                        ['Not recorded', 'None', 'Occasional', 'Regular', 'Prefer not to say'],
                        Icons.local_bar_rounded,
                        AppColors.amber,
                        (v) => setState(() => _alcohol = v!)),
                  ]),
                  _section(
                      'Vitals', Icons.monitor_heart_rounded, AppColors.danger, [
                    if (!widget.clinicianMode)
                      Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(children: [
                            _syncBadge(
                                'Not Synced',
                                !VitalSync.instance.listening,
                                AppColors.textSecondary),
                            const SizedBox(width: 8),
                            _syncBadge(
                                VitalSync.instance.receiving
                                    ? 'Receiving'
                                    : VitalSync.instance.hasReceivedUpdate
                                        ? 'Synced'
                                        : 'Listening',
                                VitalSync.instance.listening,
                                AppColors.teal),
                          ])),
                    _field('Height', _height, Icons.height_rounded,
                        AppColors.primaryBlue),
                    _field('Weight', _weight, Icons.monitor_weight_rounded,
                        AppColors.teal),
                    _field('Waist circumference (cm)', _waist,
                        Icons.straighten_rounded, AppColors.amber),
                    if (!widget.clinicianMode && _fitnessBody != null) ...[
                      _readonly(
                          'BMI',
                          _fitnessBody!['bmi'] == null
                              ? 'Not available'
                              : (_fitnessBody!['bmi'] as num)
                                  .toStringAsFixed(1),
                          Icons.monitor_weight_outlined,
                          AppColors.primaryBlue),
                      if (_fitnessBody!['composition'] is Map) ...[
                        _readonly(
                            'Skeletal muscle',
                            '${(_fitnessBody!['composition'] as Map)['skeletal_muscle_kg']} kg',
                            Icons.fitness_center_rounded,
                            AppColors.teal),
                        _readonly(
                            'Body fat',
                            '${(_fitnessBody!['composition'] as Map)['body_fat_percent']} %',
                            Icons.pie_chart_outline_rounded,
                            AppColors.amber),
                      ],
                    ],
                    _field('Systolic BP', _systolic, Icons.favorite_rounded,
                        AppColors.danger),
                    _field('Diastolic BP', _diastolic,
                        Icons.favorite_border_rounded, AppColors.danger),
                    _field('Heart rate', _heartRate,
                        Icons.monitor_heart_rounded, AppColors.teal),
                    _field('Oxygen saturation', _oxygen, Icons.air_rounded,
                        AppColors.primaryBlue),
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
  }

  Widget _section(
      String title, IconData icon, Color color, List<Widget> children) {
    final open = _expanded[title] ?? false;
    return Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
            color: AppColors.cardWhite,
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
      String label, TextEditingController c, IconData icon, Color color,
      {bool required = false}) {
    final config = identical(c, _ageInput)
        ? ('years', 0.0, 120.0, true)
        : identical(c, _height)
            ? ('cm', 50.0, 250.0, false)
            : identical(c, _weight)
                ? ('kg', 2.0, 350.0, false)
                : identical(c, _waist)
                    ? ('cm', 30.0, 250.0, false)
                    : identical(c, _systolic)
                        ? ('mmHg', 50.0, 300.0, false)
                        : identical(c, _diastolic)
                            ? ('mmHg', 30.0, 200.0, false)
                            : identical(c, _heartRate)
                                ? ('bpm', 30.0, 250.0, false)
                                : identical(c, _oxygen)
                                    ? ('%', 50.0, 100.0, false)
                                    : identical(c, _temperature)
                                        ? ('°C', 30.0, 43.0, false)
                                        : identical(c, _fastingGlucose)
                                            ? ('mg/dL', 20.0, 600.0, false)
                                            : ('mg/dL', 50.0, 600.0, false);
    final neededForDemo = widget.clinicianMode &&
        (_model == 'diabetes' &&
                (identical(c, _height) ||
                    identical(c, _weight) ||
                    identical(c, _waist) ||
                    identical(c, _systolic) ||
                    identical(c, _diastolic)) ||
            _model == 'heart_disease' &&
                (identical(c, _systolic) ||
                    identical(c, _fastingGlucose) ||
                    identical(c, _cholesterol)));
    return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
            controller: c,
            readOnly: !widget.clinicianMode &&
                VitalSync.instance.listening &&
                (identical(c, _systolic) ||
                    identical(c, _diastolic) ||
                    identical(c, _heartRate) ||
                    identical(c, _oxygen) ||
                    identical(c, _temperature)),
            keyboardType: TextInputType.numberWithOptions(decimal: !config.$4),
            inputFormatters: [
              TextInputFormatter.withFunction((oldValue, newValue) {
                final pattern = config.$4
                    ? RegExp(r'^\d{0,3}$')
                    : RegExp(r'^\d{0,3}(\.\d{0,2})?$');
                return pattern.hasMatch(newValue.text) ? newValue : oldValue;
              })
            ],
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: InputDecoration(
                labelText: label.split(' (').first,
                prefixIcon: Icon(icon, size: 25, color: color),
                suffixText: config.$1,
                filled: true,
                fillColor: AppColors.cardWhite,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12))),
            validator: (v) {
              final value = v?.trim() ?? '';
              if (value.isEmpty) {
                return required || neededForDemo
                    ? 'Required for this analysis'
                    : null;
              }
              final number = double.tryParse(value);
              if (number == null ||
                  !number.isFinite ||
                  (config.$4 && int.tryParse(value) == null)) {
                return 'Enter a valid ${config.$4 ? 'whole number' : 'number'}';
              }
              if (number < config.$2 || number > config.$3) {
                return 'Enter ${config.$2.toStringAsFixed(0)}–${config.$3.toStringAsFixed(0)} ${config.$1}';
              }
              if (identical(c, _diastolic) &&
                  _number(_systolic) != null &&
                  number >= _number(_systolic)!) {
                return 'Must be lower than systolic BP';
              }
              return null;
            }));
  }

  Widget _syncBadge(String text, bool active, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: .12) : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: active ? color.withValues(alpha: .45) : AppColors.border),
        ),
        child: Text(text,
            style: TextStyle(
                fontSize: 11,
                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                color: active ? color : AppColors.textLight)),
      );
  Widget _dropdown(String label, String value, List<String> values,
          IconData icon, Color color, ValueChanged<String?> changed) =>
      Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: DropdownButtonFormField<String>(
              initialValue: values.contains(value) ? value : values.first,
              dropdownColor: AppColors.cardWhite,
              style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
              iconEnabledColor: AppColors.textSecondary,
              decoration: InputDecoration(
                  labelText: label,
                  prefixIcon: Icon(icon, size: 25, color: color)),
              items: values
                  .map((v) => DropdownMenuItem(
                      value: v,
                      child: Text(v,
                          style: TextStyle(color: AppColors.textPrimary))))
                  .toList(),
              onChanged: changed));
  Widget _modelCard(String value, String label, IconData icon, Color color) {
    final selected = _model == value;
    return InkWell(
        onTap: () => setState(() => _model = value),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: selected
                    ? color.withValues(alpha: .12)
                    : AppColors.cardWhite,
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
