import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:medguide/screens/auth/login_screen.dart';
import 'package:medguide/services/api_client.dart';
import 'package:medguide/services/recorded_conditions.dart';
import 'package:medguide/theme/app_theme.dart';
import 'package:medguide/widgets/screen_help.dart';
import 'package:medguide/widgets/app_numeric_input.dart';
import 'package:medguide/screens/patient/onboarding_data_source.dart';

class PatientOnboardingScreen extends StatefulWidget {
  const PatientOnboardingScreen(
      {super.key, this.dataSource = const ApiPatientOnboardingDataSource()});

  final PatientOnboardingDataSource dataSource;

  @override
  State<PatientOnboardingScreen> createState() =>
      _PatientOnboardingScreenState();
}

class _PatientOnboardingScreenState extends State<PatientOnboardingScreen> {
  static const _slides = [
    'assets/onboarding/slide-1.png',
    'assets/onboarding/slide-2.png',
    'assets/onboarding/slide-3.png',
    'assets/onboarding/slide-4.png',
    'assets/onboarding/slide-5.png',
  ];
  static const _titles = [
    'Understand Your Risk',
    'Explore Nutrition',
    'Build Healthy Habits',
    'Care for Your Mind',
    'Follow Your Progress',
    'Your Health Profile',
  ];

  final _formKey = GlobalKey<FormState>();
  final _height = TextEditingController();
  final _weight = TextEditingController();
  final _waist = TextEditingController();
  final _ethnicity = TextEditingController();
  final _conditions = TextEditingController();
  final _medications = TextEditingController();
  int _step = 0;
  bool _loading = true;
  bool _saving = false;
  bool _ethnicityRecorded = false;
  bool _chronic = false;
  bool _diabetesDiagnosis = false;
  bool _heartDiagnosis = false;
  String? _smoking;
  String? _activity;
  String? _alcohol;
  bool? _diabetesFamily;
  bool? _heartFamily;
  bool? _hypertensionFamily;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final controller in [
      _height,
      _weight,
      _waist,
      _ethnicity,
      _conditions,
      _medications
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final context = await widget.dataSource.load();
      final existing =
          Map<String, dynamic>.from(context['existing'] as Map? ?? {});
      if (!mounted) return;
      setState(() {
        _height.text = existing['height_cm']?.toString() ?? '';
        _weight.text = existing['weight_kg']?.toString() ?? '';
        _waist.text = existing['waist_circumference_cm']?.toString() ?? '';
        _ethnicity.text = existing['ethnicity']?.toString() ?? '';
        _ethnicityRecorded = _ethnicity.text.trim().isNotEmpty;
        final diagnosed = RecordedConditions.fromText(
            existing['chronic_conditions']?.toString());
        _diabetesDiagnosis = diagnosed.diabetes;
        _heartDiagnosis = diagnosed.heartDisease;
        _conditions.text = diagnosed.other;
        _medications.text = existing['chronic_medications']?.toString() ?? '';
        _chronic = existing['has_chronic_condition'] == true;
        _smoking =
            _choice(existing['smoking_status'], ['Never', 'Former', 'Current']);
        _activity = _choice(existing['activity_level'],
            ['Sedentary', 'Light', 'Moderate', 'Active']);
        _alcohol = _choice(existing['alcohol_status'],
            ['None', 'Occasional', 'Regular', 'Prefer not to say']);
        _diabetesFamily = existing['family_history_diabetes'] as bool?;
        _heartFamily = existing['family_history_heart_disease'] as bool?;
        _hypertensionFamily = existing['family_history_hypertension'] as bool?;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      await _showError(error.message);
    }
  }

  String? _choice(dynamic value, List<String> options) {
    final text = value?.toString().toLowerCase();
    for (final option in options) {
      if (option.toLowerCase() == text) return option;
    }
    return null;
  }

  Future<void> _showError(String message) async {
    if (!mounted) return;
    await showDialog<void>(
        context: context,
        builder: (dialog) => AlertDialog(
              title: const Text('Onboarding Unavailable'),
              content: Text(message),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(dialog),
                    child: const Text('Dismiss'))
              ],
            ));
  }

  String? _measurement(String? value, double min, double max, String unit) {
    final parsed = double.tryParse(value?.trim() ?? '');
    if (parsed == null || !parsed.isFinite || parsed < min || parsed > max) {
      return 'Enter $min–$max $unit.';
    }
    return null;
  }

  Future<void> _save() async {
    if (_saving || _loading) return;
    if (!_formKey.currentState!.validate()) return;
    if (_smoking == null || _activity == null || _alcohol == null) {
      await _showError(
          'Choose your smoking, activity, and alcohol information.');
      return;
    }
    if (_chronic &&
        !_diabetesDiagnosis &&
        !_heartDiagnosis &&
        _conditions.text.trim().isEmpty) {
      await _showError(
          'Select a diagnosed condition or describe another chronic condition.');
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.dataSource.save({
        'ethnicity':
            _ethnicity.text.trim().isEmpty ? null : _ethnicity.text.trim(),
        'height_cm': double.parse(_height.text.trim()),
        'weight_kg': double.parse(_weight.text.trim()),
        'waist_circumference_cm': _waist.text.trim().isEmpty
            ? null
            : double.parse(_waist.text.trim()),
        'smoking_status': _smoking,
        'activity_level': _activity,
        'alcohol_status': _alcohol,
        'family_history_diabetes': _diabetesFamily,
        'family_history_heart_disease': _heartFamily,
        'family_history_hypertension': _hypertensionFamily,
        'has_chronic_condition': _chronic,
        'chronic_conditions': _chronic
            ? RecordedConditions(
                diabetes: _diabetesDiagnosis,
                heartDisease: _heartDiagnosis,
                other: _conditions.text.trim(),
              ).toProfileText()
            : null,
        'chronic_medications': _chronic && _medications.text.trim().isNotEmpty
            ? _medications.text.trim()
            : null,
      });
      await widget.dataSource.finishSession();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
    } on ApiException catch (error) {
      await _showError(error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _numberField(String label, TextEditingController controller,
      double min, double max, String unit,
      {bool optional = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [AppNumericInput.decimal],
      decoration: InputDecoration(
          labelText: label,
          suffixText: unit,
          border: const OutlineInputBorder()),
      validator: (value) => optional && (value?.trim().isEmpty ?? true)
          ? null
          : _measurement(value, min, max, unit),
    );
  }

  Widget _select(String label, String? value, List<(String, String)> options,
      ValueChanged<String?> changed) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      dropdownColor: AppColors.cardWhite,
      style: TextStyle(color: AppColors.textPrimary),
      iconEnabledColor: AppColors.textSecondary,
      decoration:
          InputDecoration(labelText: label, border: const OutlineInputBorder()),
      items: options
          .map((entry) => DropdownMenuItem(
              value: entry.$1,
              child: Text(entry.$2,
                  style: TextStyle(color: AppColors.textPrimary))))
          .toList(),
      onChanged: changed,
      validator: (value) => value == null ? 'Choose $label.' : null,
    );
  }

  Widget _family(String label, bool? value, ValueChanged<bool?> changed) =>
      DropdownButtonFormField<bool?>(
        initialValue: value,
        isExpanded: true,
        dropdownColor: AppColors.cardWhite,
        style: TextStyle(color: AppColors.textPrimary),
        iconEnabledColor: AppColors.textSecondary,
        decoration: InputDecoration(
            labelText: label, border: const OutlineInputBorder()),
        items: const [
          DropdownMenuItem<bool?>(
              value: null, child: Text('Unknown / not sure')),
          DropdownMenuItem<bool?>(value: true, child: Text('Yes')),
          DropdownMenuItem<bool?>(value: false, child: Text('No')),
        ],
        onChanged: changed,
      );

  Widget _healthForm() => Theme(
      data: Theme.of(context).copyWith(canvasColor: AppColors.cardWhite),
      child: Form(
        key: _formKey,
        child: ListView(padding: const EdgeInsets.all(18), children: [
          Text('Complete Your Health Profile',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
              'Your name, date of birth and gender were collected during registration. Add only details you know.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 18),
          TextFormField(
              controller: _ethnicity,
              enabled: !_ethnicityRecorded,
              maxLength: 100,
              style: TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                  labelText: 'Ethnicity (optional)',
                  helperText: _ethnicityRecorded ? 'Already recorded' : null,
                  border: const OutlineInputBorder())),
          const SizedBox(height: 10),
          _numberField('Height', _height, 100, 250, 'cm'),
          const SizedBox(height: 14),
          _numberField('Weight', _weight, 25, 350, 'kg'),
          const SizedBox(height: 14),
          _numberField('Waist circumference (optional)', _waist, 40, 250, 'cm',
              optional: true),
          const SizedBox(height: 18),
          _select(
              'Smoking status',
              _smoking,
              const [
                ('Never', 'Never'),
                ('Former', 'Former'),
                ('Current', 'Current')
              ],
              (value) => setState(() => _smoking = value)),
          const SizedBox(height: 14),
          _select(
              'Activity level',
              _activity,
              const [
                ('Sedentary', 'Sedentary'),
                ('Light', 'Light'),
                ('Moderate', 'Moderate'),
                ('Active', 'Active')
              ],
              (value) => setState(() => _activity = value)),
          const SizedBox(height: 14),
          _select(
              'Alcohol use',
              _alcohol,
              const [
                ('None', 'None'),
                ('Occasional', 'Occasional'),
                ('Regular', 'Regular'),
                ('Prefer not to say', 'Prefer not to say')
              ],
              (value) => setState(() => _alcohol = value)),
          const SizedBox(height: 18),
          Text('Family History',
              style: TextStyle(
                  color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          _family('Diabetes', _diabetesFamily,
              (value) => setState(() => _diabetesFamily = value)),
          const SizedBox(height: 12),
          _family('Heart disease', _heartFamily,
              (value) => setState(() => _heartFamily = value)),
          const SizedBox(height: 12),
          _family('High blood pressure', _hypertensionFamily,
              (value) => setState(() => _hypertensionFamily = value)),
          const SizedBox(height: 18),
          CheckboxListTile(
              value: _chronic,
              contentPadding: EdgeInsets.zero,
              title: Text('I have a chronic condition',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 13)),
              onChanged: (value) => setState(() => _chronic = value ?? false)),
          if (_chronic) ...[
            Text(
                'Select conditions diagnosed by a clinician. Leave unconfirmed conditions unselected.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            CheckboxListTile(
                value: _diabetesDiagnosis,
                contentPadding: EdgeInsets.zero,
                title: Text('Diagnosed with diabetes',
                    style: TextStyle(color: AppColors.textPrimary)),
                onChanged: (value) =>
                    setState(() => _diabetesDiagnosis = value ?? false)),
            CheckboxListTile(
                value: _heartDiagnosis,
                contentPadding: EdgeInsets.zero,
                title: Text('Diagnosed with heart disease',
                    style: TextStyle(color: AppColors.textPrimary)),
                onChanged: (value) =>
                    setState(() => _heartDiagnosis = value ?? false)),
            TextFormField(
                controller: _conditions,
                maxLength: 800,
                minLines: 2,
                maxLines: 3,
                style: TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                    labelText: 'Other chronic conditions (optional)',
                    border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextFormField(
                controller: _medications,
                maxLength: 1000,
                minLines: 2,
                maxLines: 3,
                style: TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                    labelText: 'Chronic medication (optional)',
                    hintText: 'Name and dose, if known',
                    border: OutlineInputBorder())),
          ],
          const SizedBox(height: 12),
          Text(
              'BMI will be calculated from your height and weight. Leave unknown medical details as unknown; do not guess.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 18),
          FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving…' : 'Save and Continue to Login')),
        ]),
      ));

  Widget _progressDots({bool light = false}) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
            6,
            (index) => Semantics(
                  label: 'Onboarding step ${index + 1} of 6',
                  selected: _step == index,
                  child: InkWell(
                    onTap: _saving ? null : () => setState(() => _step = index),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 240),
                        width: _step == index ? 24 : 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: _step == index
                              ? AppColors.teal
                              : light
                                  ? Colors.white38
                                  : AppColors.border,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                )),
      );

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    if (_step == 5) {
      return PopScope(
          canPop: false,
          child: Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.cardWhite,
              foregroundColor: AppColors.textPrimary,
              title: const Text('Your Health Profile'),
              actions: const [
                ScreenHelpButton(topic: 'Onboarding Health Profile')
              ],
              leading: IconButton(
                tooltip: 'Back to onboarding',
                onPressed: _saving ? null : () => setState(() => _step = 4),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            ),
            body: SafeArea(
                child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.surfaceBlue, AppColors.background],
              )),
              child: Column(children: [
                const SizedBox(height: 8),
                Text('Step 6 of 6 · Add your health details',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 7),
                _progressDots(),
                const SizedBox(height: 4),
                Expanded(
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : _healthForm()),
              ]),
            )),
          ));
    }
    return PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
              child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
            child: Column(children: [
              Text('Welcome to RiskSense AI',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(_titles[_step],
                  style: TextStyle(color: AppColors.textSecondary),
                  textAlign: TextAlign.center),
              const SizedBox(height: 14),
              Expanded(
                  child: Row(children: [
                Column(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(
                      tooltip: 'Previous',
                      onPressed: _step == 0 || _saving
                          ? null
                          : () => setState(() => _step--),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded)),
                  Text('Back',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                ]),
                Expanded(
                    child: Center(
                        child: AspectRatio(
                  aspectRatio: 9 / 16,
                  child: Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        color: const Color(0xFF102744),
                        border:
                            Border.all(color: AppColors.primaryBlue, width: 6),
                        boxShadow: [
                          BoxShadow(
                              color:
                                  AppColors.primaryBlue.withValues(alpha: .18),
                              blurRadius: 24,
                              offset: const Offset(0, 12))
                        ]),
                    child: ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: Image.asset(_slides[_step], fit: BoxFit.cover)),
                  ),
                ))),
                Column(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(
                      tooltip: 'Next',
                      onPressed: _step == 5 || _saving
                          ? null
                          : () => setState(() => _step++),
                      icon: const Icon(Icons.arrow_forward_ios_rounded)),
                  Text('Next',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                ]),
              ])),
              const SizedBox(height: 16),
              _progressDots(),
              const SizedBox(height: 5),
              Text('${_step + 1} of 6',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ]),
          )),
        ));
  }
}
