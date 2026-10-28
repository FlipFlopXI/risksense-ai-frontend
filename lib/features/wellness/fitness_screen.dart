import 'package:medguide/widgets/app_form_dialog.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medguide/features/wellness/fitness_data_source.dart';
import 'package:medguide/features/wellness/body_trend_chart.dart';
import 'package:medguide/features/wellness/wellness_screen.dart';
import 'package:medguide/services/api_client.dart';
import 'package:medguide/services/weekly_report.dart';
import 'package:medguide/theme/app_theme.dart';
import 'package:medguide/widgets/screen_help.dart';
import 'package:medguide/widgets/weekly_report_button.dart';

class FitnessScreen extends StatefulWidget {
  final Map<String, dynamic> dashboard;
  final FitnessDataSource? dataSource;
  const FitnessScreen({super.key, required this.dashboard, this.dataSource});
  @override
  State<FitnessScreen> createState() => _FitnessScreenState();
}

class _FitnessScreenState extends State<FitnessScreen> {
  late final FitnessDataSource api;
  late Future<Map<String, dynamic>> activity, body;
  late Future<List<Map<String, dynamic>>> bodyHistory;
  final day = DateFormat('yyyy-MM-dd').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    api = widget.dataSource ?? const ApiFitnessDataSource();
    activity = api.activity(day);
    body = api.body();
    bodyHistory = api.bodyTrends();
  }

  Future<void> reloadActivity() async {
    final value = await api.activity(day);
    if (mounted) {
      setState(() {
        activity = Future.value(value);
      });
    }
  }

  Future<void> reloadBody() async {
    final value = await api.body();
    if (mounted) {
      setState(() {
        body = Future.value(value);
        bodyHistory = api.bodyTrends();
      });
    }
  }

  void error(Object e) {
    if (!mounted) return;
    showDialog<void>(
        context: context,
        builder: (dialog) =>
            AlertDialog(
                title: const Text('Fitness Unavailable'),
                content:
                    Text(e is ApiException ? e.message : 'Please try again.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(dialog),
                      child: const Text('Dismiss'))
                ]));
  }

  Future<void> addActivity() async {
    final values = await showDialog<Map<String, dynamic>>(
        context: context, builder: (_) => const _FitnessEntryDialog());
    if (values == null) return;
    try {
      await api.addActivity({'log_date': day, ...values});
      await reloadActivity();
    } catch (e) {
      error(e);
    }
  }

  Future<void> editWeight() async {
    final current = await body;
    if (!mounted) return;
    final value = await showDialog<double>(
        context: context,
        builder: (_) => _FitnessNumbersDialog(
            title: 'Update Weight',
            labels: const ['Weight (kg)'],
            initial: [(current['weight_kg'] as num?)?.toDouble()],
            limits: const [500]));
    if (value == null) return;
    try {
      await api.saveWeight(value);
      await reloadBody();
    } catch (e) {
      error(e);
    }
  }

  Future<void> editComposition() async {
    final values = await showDialog<List<double>>(
        context: context, builder: (_) => const _CompositionDialog());
    if (values == null) return;
    try {
      await api.saveComposition(values[0], values[1]);
      await reloadBody();
    } catch (e) {
      error(e);
    }
  }

  Widget card(Widget child) => Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.teal.withValues(alpha: .18))),
      child: child);

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return DefaultTabController(
        length: 2,
        child: Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(title: const Text('Fitness'), actions: [
              WeeklyReportButton(
                  createReport: () => WeeklyReportService.fitness(
                      fitness: api, endDate: DateTime.now())),
              const ScreenHelpButton(topic: 'Fitness'),
              const SizedBox(width: 8)
            ]),
            body: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                      SliverToBoxAdapter(
                          child: Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 12, 20, 14),
                              child: Column(children: [
                                Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                        gradient: LinearGradient(colors: [
                                          AppColors.heroStart,
                                          AppColors.heroEnd
                                        ]),
                                        borderRadius:
                                            BorderRadius.circular(20)),
                                    child: const Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Icon(Icons.fitness_center_rounded,
                                              color: Colors.white, size: 34),
                                          SizedBox(height: 12),
                                          Text(
                                              'Build a routine that fits your goals',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.w700)),
                                          SizedBox(height: 7),
                                          Text(
                                              'Track activity and body measurements alongside your risk assessments.',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  height: 1.45))
                                        ])),
                                const SizedBox(height: 14),
                                FilledButton.icon(
                                    onPressed: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                FitnessRoutineScreen(
                                                    dashboard:
                                                        widget.dashboard))),
                                    icon: const Icon(
                                        Icons.directions_run_rounded),
                                    label:
                                        const Text('Generate Fitness Routine'))
                              ]))),
                      SliverToBoxAdapter(
                          child: TabBar(
                              labelColor: AppColors.primaryBlue,
                              unselectedLabelColor: AppColors.textSecondary,
                              indicatorColor: AppColors.teal,
                              tabs: const [
                            Tab(
                                text: 'Daily Activity',
                                icon: Icon(Icons.directions_run_rounded)),
                            Tab(
                                text: 'Body Metrics',
                                icon: Icon(Icons.monitor_weight_outlined))
                          ])),
                    ],
                body: TabBarView(children: [
                  FutureBuilder<Map<String, dynamic>>(
                      future: activity,
                      builder: (_, snap) => snap.hasData
                          ? activityTab(snap.data!)
                          : snap.hasError
                              ? Center(
                                  child: TextButton(
                                      onPressed: () => setState(() {
                                            activity = api.activity(day);
                                          }),
                                      child: const Text('Retry activity load')))
                              : const Center(
                                  child: CircularProgressIndicator())),
                  FutureBuilder<Map<String, dynamic>>(
                      future: body,
                      builder: (_, snap) => snap.hasData
                          ? bodyTab(snap.data!)
                          : snap.hasError
                              ? Center(
                                  child: TextButton(
                                      onPressed: () => setState(() {
                                            body = api.body();
                                          }),
                                      child: const Text(
                                          'Retry body metrics load')))
                              : const Center(
                                  child: CircularProgressIndicator())),
                ]))));
  }

  Widget activityTab(Map<String, dynamic> data) {
    final today = Map<String, dynamic>.from(data['today'] as Map);
    final history =
        (data['history'] as List? ?? const []).whereType<Map>().toList();
    final steps = (today['steps'] as num?)?.toInt() ?? 0;
    final minutes = (today['activity_minutes'] as num?)?.toInt() ?? 0;
    final kcal = (today['activity_calories_kcal'] as num?)?.toDouble() ?? 0;
    final km = (today['distance_km'] as num?)?.toDouble() ?? 0;
    return RefreshIndicator(
        onRefresh: reloadActivity,
        child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            children: [
              card(Column(children: [
                Row(children: [
                  Expanded(
                      child: Text('Daily Activity',
                          style: Theme.of(context).textTheme.headlineSmall)),
                  IconButton(
                      tooltip: 'Log activity',
                      onPressed: addActivity,
                      icon:
                          Icon(Icons.add_circle_outline, color: AppColors.teal))
                ]),
                Text('Enter measured activity; no values are estimated.',
                    style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 16),
                SizedBox(
                    width: 150,
                    height: 150,
                    child: Stack(alignment: Alignment.center, children: [
                      for (final ring in [
                        (150.0, steps / 10000, AppColors.primaryBlue),
                        (122.0, minutes / 60, AppColors.teal),
                        (94.0, kcal / 500, AppColors.amber)
                      ])
                        SizedBox(
                            width: ring.$1,
                            height: ring.$1,
                            child: CircularProgressIndicator(
                                value: ring.$2.clamp(0.0, 1.0),
                                strokeWidth: 7,
                                color: ring.$3,
                                backgroundColor:
                                    ring.$3.withValues(alpha: .12))),
                      Icon(Icons.directions_run_rounded,
                          size: 45, color: AppColors.textPrimary)
                    ])),
                const SizedBox(height: 18),
                Row(children: [
                  stat('Steps', '$steps', AppColors.primaryBlue),
                  stat('Activity time', '$minutes min', AppColors.teal),
                  stat('Activity calories', '${kcal.round()} kcal',
                      AppColors.amber)
                ]),
                const Divider(height: 30),
                Row(children: [
                  Expanded(
                      child: mini('Total logged burn', '${kcal.round()} kcal')),
                  Expanded(
                      child: mini('Distance while active',
                          '${km.toStringAsFixed(2)} km'))
                ]),
                const SizedBox(height: 10),
                Text('Ring display scales: 10,000 steps · 60 min · 500 kcal.',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
              ])),
              const SizedBox(height: 16),
              card(Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Past 7 Days',
                        style: Theme.of(context).textTheme.headlineSmall),
                    chart('Steps', history, 'steps', AppColors.primaryBlue),
                    chart('Activity time (min)', history, 'activity_minutes',
                        AppColors.teal),
                    chart('Activity calories (kcal)', history,
                        'activity_calories_kcal', AppColors.amber),
                  ])),
            ]));
  }

  Widget stat(String name, String value, Color color) => Expanded(
      child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
              color: color.withValues(alpha: .08),
              border: Border.all(color: color.withValues(alpha: .3)),
              borderRadius: BorderRadius.circular(12)),
          child: Column(children: [
            Text(value,
                textAlign: TextAlign.center,
                style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            Text(name,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textPrimary, fontSize: 11))
          ])));

  Widget mini(String name, String value) => Column(children: [
        Text(value,
            style: TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        Text(name,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11))
      ]);

  Widget chart(String name, List<Map> history, String field, Color color) {
    final peak = history.fold<double>(
        1, (n, row) => math.max(n, (row[field] as num?)?.toDouble() ?? 0));
    return Padding(
        padding: const EdgeInsets.only(top: 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name,
              style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 7),
          SizedBox(
              height: 110,
              child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                for (final row in history)
                  Expanded(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                        Text(
                            '${((row[field] as num?)?.toDouble() ?? 0).round()}',
                            style: TextStyle(
                                fontSize: 9, color: AppColors.textSecondary)),
                        Container(
                            height: 70 *
                                    ((row[field] as num?)?.toDouble() ?? 0) /
                                    peak +
                                3,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                                color: color,
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(4)))),
                        Text(
                            DateFormat.E().format(
                                DateTime.tryParse('${row['date']}') ??
                                    DateTime.now()),
                            style: TextStyle(
                                fontSize: 9, color: AppColors.textSecondary)),
                      ]))
              ])),
        ]));
  }

  Widget bodyTab(Map<String, dynamic> data) {
    final weight = (data['weight_kg'] as num?)?.toDouble();
    final height = (data['height_cm'] as num?)?.toDouble();
    final bmi = (data['bmi'] as num?)?.toDouble();
    final adultReference = data['adult_bmi_reference_applicable'] == true;
    final composition = data['composition'] is Map
        ? Map<String, dynamic>.from(data['composition'] as Map)
        : null;
    return RefreshIndicator(
        onRefresh: reloadBody,
        child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            children: [
              card(Column(children: [
                Icon(Icons.monitor_weight_rounded,
                    size: 48, color: AppColors.teal),
                Text(
                    weight == null
                        ? 'Not recorded'
                        : '${weight.toStringAsFixed(1)} kg',
                    style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary)),
                Chip(
                    label: Text(bmi == null
                        ? 'BMI unavailable'
                        : !adultReference
                            ? 'Personal interpretation needed'
                            : bmi < 18.5
                                ? 'Below general adult BMI range'
                                : bmi < 25
                                    ? 'Within general adult BMI range'
                                    : 'Above general adult BMI range')),
                Text(
                    'BMI is a screening measure, not a personal health verdict.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary))
              ])),
              const SizedBox(height: 16),
              card(Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                          child: Text('Weight',
                              style:
                                  Theme.of(context).textTheme.headlineSmall)),
                      IconButton(
                          tooltip: 'Update weight',
                          onPressed: editWeight,
                          icon: Icon(Icons.edit_rounded, color: AppColors.teal))
                    ]),
                    Text(weight == null
                        ? 'Add a measured weight'
                        : '${weight.toStringAsFixed(1)} kg'),
                    LinearProgressIndicator(
                        value:
                            weight == null ? 0 : (weight / 200).clamp(0.0, 1.0),
                        color: AppColors.teal,
                        minHeight: 10),
                    Text('Display scale 0–200 kg · not a target',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textSecondary)),
                    const SizedBox(height: 19),
                    Row(children: [
                      Expanded(
                          child: Text('BMI',
                              style:
                                  Theme.of(context).textTheme.headlineSmall)),
                      IconButton(
                          tooltip: 'Record body composition',
                          onPressed: editComposition,
                          icon: Icon(Icons.edit_rounded,
                              color: AppColors.primaryBlue))
                    ]),
                    Text(bmi == null
                        ? 'Height and weight needed'
                        : bmi.toStringAsFixed(1)),
                    LinearProgressIndicator(
                        value: bmi == null ? 0 : (bmi / 50).clamp(0.0, 1.0),
                        color: AppColors.primaryBlue,
                        minHeight: 10),
                    Text('Display scale 0–50 · not a target',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textSecondary)),
                    const SizedBox(height: 12),
                    Text(
                        height == null
                            ? 'Add height in Health Data Input to calculate BMI.'
                            : 'Calculated from height ${height.toStringAsFixed(1)} cm and weight.',
                        style: TextStyle(color: AppColors.textSecondary)),
                    if (composition != null)
                      Text(
                          'Skeletal muscle: ${composition['skeletal_muscle_kg']} kg · Body fat: ${composition['body_fat_percent']}%',
                          style: TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 9),
                    Text(
                        adultReference
                            ? 'General adult BMI reference: 18.5–24.9. Body composition and individual circumstances can change interpretation.'
                            : 'General adult BMI reference is not applied to this profile. Ask a clinician for an individual interpretation.',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textSecondary)),
                  ])),
              const SizedBox(height: 16),
              FutureBuilder<List<Map<String, dynamic>>>(
                  future: bodyHistory,
                  builder: (context, snapshot) => card(
                        snapshot.hasData
                            ? BodyTrendChart(measurements: snapshot.data!)
                            : snapshot.hasError
                                ? Column(children: [
                                    const Text(
                                        'Weekly body trend unavailable.'),
                                    TextButton(
                                        onPressed: () => setState(() {
                                              bodyHistory = api.bodyTrends();
                                            }),
                                        child: const Text('Retry trend load')),
                                  ])
                                : const Center(
                                    child: CircularProgressIndicator()),
                      )),
            ]));
  }
}

class _FitnessEntryDialog extends StatefulWidget {
  const _FitnessEntryDialog();
  @override
  State<_FitnessEntryDialog> createState() => _FitnessEntryDialogState();
}

class _FitnessEntryDialogState extends State<_FitnessEntryDialog> {
  final key = GlobalKey<FormState>();
  final inputs = List.generate(4, (_) => TextEditingController());
  @override
  void dispose() {
    for (final input in inputs) {
      input.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return AppFormDialog(
        icon: Icons.directions_run_rounded,
        title: const Text('Log Activity'),
        content: Form(
            key: key,
            child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text(
                  'Enter measured values only. Leave unavailable values blank.'),
              for (var i = 0; i < 4; i++)
                TextFormField(
                    controller: inputs[i],
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: i > 1),
                    decoration: InputDecoration(
                        labelText: const [
                          'Steps',
                          'Activity time',
                          'Activity calories',
                          'Distance'
                        ][i],
                        suffixText: const ['', 'min', 'kcal', 'km'][i]),
                    validator: (text) {
                      if ((text ?? '').isEmpty) return null;
                      final n = double.tryParse(text!);
                      return n == null ||
                              n < 0 ||
                              n > [100000, 1440, 10000, 500][i]
                          ? 'Invalid measurement'
                          : null;
                    }),
            ]))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () {
                if (!key.currentState!.validate()) return;
                final n = inputs
                    .map((input) => double.tryParse(input.text) ?? 0)
                    .toList();
                if (n.every((value) => value == 0)) return;
                Navigator.pop(context, {
                  'steps': n[0].toInt(),
                  'activity_minutes': n[1].toInt(),
                  'activity_calories_kcal': n[2],
                  'distance_km': n[3]
                });
              },
              child: const Text('Save'))
        ]);
  }
}

class _FitnessNumbersDialog extends StatefulWidget {
  final String title;
  final List<String> labels;
  final List<double?> initial;
  final List<double> limits;
  const _FitnessNumbersDialog(
      {required this.title,
      required this.labels,
      required this.initial,
      required this.limits});
  @override
  State<_FitnessNumbersDialog> createState() => _FitnessNumbersDialogState();
}

class _FitnessNumbersDialogState extends State<_FitnessNumbersDialog> {
  final key = GlobalKey<FormState>();
  late final List<TextEditingController> inputs;
  @override
  void initState() {
    super.initState();
    inputs = [
      for (final value in widget.initial)
        TextEditingController(text: value?.toString() ?? '')
    ];
  }

  @override
  void dispose() {
    for (final input in inputs) {
      input.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return AppFormDialog(
        icon: Icons.directions_run_rounded,
        title: Text(widget.title),
        content: Form(
            key: key,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              for (var i = 0; i < inputs.length; i++)
                TextFormField(
                    controller: inputs[i],
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: widget.labels[i]),
                    validator: (text) {
                      final n = double.tryParse(text ?? '');
                      return n == null || n <= 0 || n > widget.limits[i]
                          ? 'Enter a valid measurement'
                          : null;
                    })
            ])),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () {
                if (key.currentState!.validate()) {
                  Navigator.pop(context, double.parse(inputs.first.text));
                }
              },
              child: const Text('Save'))
        ]);
  }
}

class _CompositionDialog extends StatefulWidget {
  const _CompositionDialog();
  @override
  State<_CompositionDialog> createState() => _CompositionDialogState();
}

class _CompositionDialogState extends State<_CompositionDialog> {
  final key = GlobalKey<FormState>();
  final muscle = TextEditingController(), fat = TextEditingController();
  @override
  void dispose() {
    muscle.dispose();
    fat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return AppFormDialog(
        icon: Icons.directions_run_rounded,
        title: const Text('Body Composition'),
        content: Form(
            key: key,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text(
                  'Save measured values separately. BMI uses height and weight.'),
              TextFormField(
                  controller: muscle,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                      labelText: 'Skeletal muscle', suffixText: 'kg'),
                  validator: (text) {
                    final n = double.tryParse(text ?? '');
                    return n == null || n <= 0 || n > 250
                        ? 'Enter a valid value'
                        : null;
                  }),
              TextFormField(
                  controller: fat,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                      labelText: 'Body fat', suffixText: '%'),
                  validator: (text) {
                    final n = double.tryParse(text ?? '');
                    return n == null || n < 0 || n > 100
                        ? 'Enter 0–100%'
                        : null;
                  }),
            ])),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () {
                if (key.currentState!.validate()) {
                  Navigator.pop(context,
                      [double.parse(muscle.text), double.parse(fat.text)]);
                }
              },
              child: const Text('Save'))
        ]);
  }
}
