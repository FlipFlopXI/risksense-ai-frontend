import 'package:medguide/widgets/app_numeric_input.dart';
import 'package:medguide/widgets/app_form_dialog.dart';
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medguide/features/wellness/wellness_screen.dart';
import 'package:medguide/features/wellness/nutrition_data_source.dart';
import 'package:medguide/features/wellness/water_tab.dart';
import 'package:medguide/features/wellness/glucose_tab.dart';
import 'package:medguide/features/wellness/glucose_data_source.dart';
import 'package:medguide/services/api_client.dart';
import 'package:medguide/services/weekly_report.dart';
import 'package:medguide/theme/app_theme.dart';
import 'package:medguide/widgets/screen_help.dart';
import 'package:medguide/widgets/weekly_report_button.dart';

class NutritionScreen extends StatefulWidget {
  final Map<String, dynamic> dashboard;
  final NutritionDataSource? dataSource;
  final GlucoseDataSource? glucoseDataSource;
  const NutritionScreen(
      {super.key,
      required this.dashboard,
      this.dataSource,
      this.glucoseDataSource});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  late Future<Map<String, dynamic>> _summary;
  late NutritionDataSource _api;
  final _day = DateFormat('yyyy-MM-dd').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _api = widget.dataSource ?? const ApiNutritionDataSource();
    _reload();
  }

  Future<Map<String, dynamic>> _loadSummary() => _api.summary(_day);

  void _reload() => _summary = _loadSummary();

  Future<Map<String, dynamic>?> _refresh() async {
    try {
      final data = await _loadSummary();
      if (mounted) {
        setState(() {
          _summary = Future.value(data);
        });
      }
      return data;
    } catch (error) {
      if (mounted) _showError(error);
      return null;
    }
  }

  Future<void> _editGoal(int? current) async {
    final value = await showDialog<int>(
        context: context, builder: (_) => _GoalDialog(initialGoal: current));
    if (value == null) return;
    try {
      await _api.saveGoal(value);
      if (mounted) await _refresh();
    } catch (error) {
      if (!mounted) return;
      final latest = await _refresh();
      if (latest != null && latest['goal_kcal'] != value && mounted) {
        _showError(error);
      }
    }
  }

  Future<void> _logMeal(String key, String label) async {
    final added = await showDialog<bool>(
        context: context,
        builder: (_) => _FoodEntryDialog(
            mealType: key, mealLabel: label, date: _day, api: _api));
    if (added == true && mounted) await _refresh();
  }

  Future<void> _remove(String id) async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
              title: const Text('Remove Food Entry?'),
              content: const Text(
                  'This entry will be removed from your nutrition log.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(dialog, false),
                    child: const Text('Cancel')),
                TextButton(
                    onPressed: () => Navigator.pop(dialog, true),
                    child: const Text('Remove')),
              ],
            ));
    if (confirmed != true) return;
    try {
      await _api.deleteEntry(id);
      if (mounted) await _refresh();
    } catch (error) {
      if (!mounted) return;
      final latest = await _refresh();
      final stillPresent = (latest?['entries'] as List? ?? const [])
          .whereType<Map>()
          .any((entry) => entry['id']?.toString() == id);
      if (latest != null && stillPresent && mounted) _showError(error);
    }
  }

  void _showError(Object error) => showDialog<void>(
      context: context,
      builder: (dialog) => AlertDialog(
            title: const Text('Nutrition Unavailable'),
            content: Text(
                error is ApiException ? error.message : 'Please try again.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(dialog),
                  child: const Text('Dismiss'))
            ],
          ));

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return DefaultTabController(
        length: 3,
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(title: const Text('Nutrition'), actions: [
            WeeklyReportButton(
                createReport: () => WeeklyReportService.nutrition(
                    nutrition: _api,
                    glucose: widget.glucoseDataSource ??
                        const ApiGlucoseDataSource(),
                    endDate: DateTime.now())),
            const ScreenHelpButton(topic: 'Nutrition'),
            const SizedBox(width: 8),
          ]),
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverToBoxAdapter(
                  child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
                      child: Column(children: [
                        Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [
                                  AppColors.heroStart,
                                  AppColors.heroEnd
                                ]),
                                borderRadius: BorderRadius.circular(20)),
                            child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.restaurant_menu_rounded,
                                      color: Colors.white, size: 34),
                                  SizedBox(height: 12),
                                  Text('Support your health, one day at a time',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w700)),
                                  SizedBox(height: 7),
                                  Text(
                                      'Track food, water and blood glucose alongside your risk assessments.',
                                      style: TextStyle(
                                          color: Colors.white, height: 1.45)),
                                ])),
                        const SizedBox(height: 14),
                        FilledButton.icon(
                            onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => MealPlanScreen(
                                        dashboard: widget.dashboard))),
                            icon: const Icon(Icons.restaurant_menu_rounded),
                            label: const Text('Generate Meal Plan')),
                      ]))),
              SliverToBoxAdapter(
                  child: TabBar(
                labelColor: AppColors.primaryBlue,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.teal,
                tabs: const [
                  Tab(text: 'Food', icon: Icon(Icons.restaurant_rounded)),
                  Tab(text: 'Water', icon: Icon(Icons.water_drop_outlined)),
                  Tab(
                      text: 'Blood Glucose',
                      icon: Icon(Icons.bloodtype_outlined))
                ],
              )),
            ],
            body: TabBarView(children: [
              FutureBuilder<Map<String, dynamic>>(
                future: _summary,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    if (snapshot.hasError) {
                      return Center(
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                        const Text('Unable to load your nutrition log.'),
                        TextButton(
                            onPressed: _refresh, child: const Text('Retry')),
                      ]));
                    }
                    return const Center(child: CircularProgressIndicator());
                  }
                  return RefreshIndicator(
                      onRefresh: () async {
                        await _refresh();
                      },
                      child: _foodContent(snapshot.data!));
                },
              ),
              WaterTab(api: _api, day: _day),
              GlucoseTab(
                  api: widget.glucoseDataSource ?? const ApiGlucoseDataSource(),
                  day: _day),
            ]),
          ),
        ));
  }

  Widget _foodContent(Map<String, dynamic> data) {
    final entries =
        (data['entries'] as List? ?? const []).whereType<Map>().toList();
    final history =
        (data['history'] as List? ?? const []).whereType<Map>().toList();
    final calories = _number(data['calories_kcal']);
    final carbs = _number(data['carbs_g']);
    final fat = _number(data['fat_g']);
    final protein = _number(data['protein_g']);
    final goal = (data['goal_kcal'] as num?)?.toInt();
    return ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        children: [
          _card(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(children: [
                  const Icon(Icons.local_fire_department_rounded,
                      color: Colors.deepOrange),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text('Today’s Calories',
                          style: Theme.of(context).textTheme.headlineSmall)),
                  IconButton(
                      tooltip: 'Set daily calorie goal',
                      onPressed: () => _editGoal(goal),
                      icon: Icon(Icons.track_changes_rounded,
                          color: AppColors.teal)),
                ]),
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(calories.toStringAsFixed(0),
                      style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary)),
                  Padding(
                      padding: const EdgeInsets.only(left: 5, bottom: 7),
                      child: Text('kcal consumed',
                          style: TextStyle(color: AppColors.textSecondary))),
                ]),
                Text(
                    goal == null
                        ? 'Set a goal to see your target on the scale.'
                        : 'Daily goal: $goal kcal',
                    style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 18),
                _CalorieScale(consumed: calories, goal: goal),
              ])),
          const SizedBox(height: 16),
          _card(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('Nutrition Overview',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 5),
                Text('From foods logged today',
                    style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 14),
                Row(children: [
                  _macroTile(
                      'Carbs', carbs, AppColors.amber, Icons.grain_rounded),
                  const SizedBox(width: 8),
                  _macroTile(
                      'Fat', fat, AppColors.primaryBlue, Icons.opacity_rounded),
                  const SizedBox(width: 8),
                  _macroTile('Protein', protein, AppColors.teal,
                      Icons.egg_alt_outlined),
                ]),
                const SizedBox(height: 18),
                _MacroBar(carbs: carbs, fat: fat, protein: protein),
                const SizedBox(height: 8),
                Text(
                    'General adult reference ranges (Health Canada DRIs; share of energy): carbs 45–65%, fat 20–35%, protein 10–35%. These are not personal targets.',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
              ])),
          const SizedBox(height: 16),
          _card(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('Log Meals',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text('Add foods or ingredients and their measured amounts.',
                    style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 9),
                for (final (key, label, icon) in _meals) ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(icon, color: AppColors.teal),
                    title: Text(label),
                    subtitle: Text(
                        '${entries.where((item) => item['meal_type'] == key).length} items',
                        style: TextStyle(color: AppColors.textSecondary)),
                    trailing: IconButton(
                        tooltip: 'Add $label',
                        icon: Icon(Icons.add_circle_rounded,
                            color: AppColors.primaryBlue),
                        onPressed: () => _logMeal(key, label)),
                  ),
                  for (final entry
                      in entries.where((item) => item['meal_type'] == key))
                    Padding(
                        padding: const EdgeInsets.only(left: 48),
                        child: ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                                '${entry['food_name']} • ${entry['amount_g']} g',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                            subtitle: Text(
                                '${_number(entry['calories_kcal']).toStringAsFixed(0)} kcal • ${entry['source'] == 'open_food_facts' ? 'Open Food Facts' : 'Self entered'}'),
                            trailing: IconButton(
                                tooltip: 'Remove food',
                                icon: Icon(Icons.delete_outline_rounded,
                                    color: AppColors.danger),
                                onPressed: () => _remove('${entry['id']}')))),
                ],
              ])),
          const SizedBox(height: 16),
          _card(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('Calorie Intake • Last 7 Days',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 5),
                Text('Based on foods you logged, including today.',
                    style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 18),
                _SevenDayChart(history: history),
              ])),
        ]);
  }

  Widget _card({required Widget child}) => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: AppColors.cardWhite,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(20)),
      child: child);

  Widget _macroTile(String label, double value, Color color, IconData icon) =>
      Expanded(
          child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: .11),
                  border: Border.all(color: color.withValues(alpha: .4)),
                  borderRadius: BorderRadius.circular(14)),
              child: Column(children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(height: 5),
                Text('${value.toStringAsFixed(1)} g',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700)),
                Text(label,
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 11)),
              ])));
}

const _meals = <(String, String, IconData)>[
  ('breakfast', 'Breakfast', Icons.free_breakfast_rounded),
  ('lunch', 'Lunch', Icons.lunch_dining_rounded),
  ('dinner', 'Dinner', Icons.dinner_dining_rounded),
  ('morning_snack', 'Morning Snack', Icons.wb_sunny_outlined),
  ('afternoon_snack', 'Afternoon Snack', Icons.light_mode_outlined),
  ('evening_snack', 'Evening Snack', Icons.nightlight_outlined),
];

double _number(dynamic value) => double.tryParse('$value') ?? 0;

class _CalorieScale extends StatelessWidget {
  final double consumed;
  final int? goal;
  const _CalorieScale({required this.consumed, required this.goal});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final maxValue =
        math.max(2200.0, math.max(consumed, (goal ?? 0).toDouble()));
    return Column(children: [
      LayoutBuilder(builder: (context, constraints) {
        final width = constraints.maxWidth;
        final progress = (consumed / maxValue).clamp(0.0, 1.0);
        final target = ((goal ?? 0) / maxValue).clamp(0.0, 1.0);
        return SizedBox(
            height: 31,
            child: Stack(children: [
              Positioned(
                  top: 13,
                  left: 0,
                  right: 0,
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 10,
                          backgroundColor: AppColors.border,
                          color: AppColors.teal))),
              if (goal != null)
                Positioned(
                    left: (width * target - 12).clamp(0, width - 24),
                    top: 1,
                    child: Icon(Icons.track_changes_rounded,
                        size: 24, color: AppColors.primaryBlue)),
            ]));
      }),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('0',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        Text(maxValue.toStringAsFixed(0),
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
      ]),
    ]);
  }
}

class _MacroBar extends StatelessWidget {
  final double carbs, fat, protein;
  const _MacroBar(
      {required this.carbs, required this.fat, required this.protein});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final energy = carbs * 4 + fat * 9 + protein * 4;
    if (energy <= 0) {
      return Text('Log food to see your macro balance.',
          style: TextStyle(color: AppColors.textSecondary));
    }
    final shares = [carbs * 4 / energy, fat * 9 / energy, protein * 4 / energy];
    final colors = [AppColors.amber, AppColors.primaryBlue, AppColors.teal];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        for (var i = 0; i < 3; i++)
          Text(
              '${['Carbs', 'Fat', 'Protein'][i]} ${(shares[i] * 100).round()}%',
              style: TextStyle(
                  color: colors[i], fontSize: 11, fontWeight: FontWeight.w700)),
      ]),
      const SizedBox(height: 6),
      ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: Row(children: [
            for (var i = 0; i < 3; i++)
              if (shares[i] > 0)
                Expanded(
                    flex: math.max(1, (shares[i] * 1000).round()),
                    child: Container(height: 12, color: colors[i])),
          ])),
    ]);
  }
}

class _SevenDayChart extends StatelessWidget {
  final List<Map> history;
  const _SevenDayChart({required this.history});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final highest = history.fold<double>(
        1, (value, item) => math.max(value, _number(item['calories_kcal'])));
    return SizedBox(
        height: 165,
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          for (final day in history)
            Expanded(
                child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(_number(day['calories_kcal']).toStringAsFixed(0),
                              style: TextStyle(
                                  fontSize: 9, color: AppColors.textSecondary)),
                          const SizedBox(height: 3),
                          Container(
                              height: 100 *
                                      _number(day['calories_kcal']) /
                                      highest +
                                  3,
                              decoration: BoxDecoration(
                                  color: AppColors.teal,
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(5)))),
                          const SizedBox(height: 5),
                          Text(
                              DateFormat.E().format(
                                  DateTime.tryParse('${day['date']}') ??
                                      DateTime.now()),
                              style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textSecondary)),
                        ]))),
        ]));
  }
}

class _GoalDialog extends StatefulWidget {
  final int? initialGoal;
  const _GoalDialog({required this.initialGoal});

  @override
  State<_GoalDialog> createState() => _GoalDialogState();
}

class _GoalDialogState extends State<_GoalDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        TextEditingController(text: widget.initialGoal?.toString() ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return AppFormDialog(
      icon: Icons.track_changes_rounded,
      title: const Text('Daily Calorie Goal'),
      content: Form(
        key: _form,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text(
              'Choose a personal tracking goal. Ask a clinician or dietitian for individual nutrition advice.'),
          const SizedBox(height: 14),
          TextFormField(
            controller: _controller,
            autofocus: true,
            inputFormatters: [AppNumericInput.digits],
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
                labelText: 'Goal', suffixText: 'kcal / day'),
            validator: (text) {
              final number = int.tryParse(text?.trim() ?? '');
              return number == null || number < 500 || number > 6000
                  ? 'Enter a value from 500 to 6000 kcal'
                  : null;
            },
          ),
        ]),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
            onPressed: () {
              if (_form.currentState!.validate()) {
                Navigator.pop(context, int.parse(_controller.text.trim()));
              }
            },
            child: const Text('Save Goal')),
      ],
    );
  }
}

class _FoodEntryDialog extends StatefulWidget {
  final String mealType, mealLabel, date;
  final NutritionDataSource api;
  const _FoodEntryDialog(
      {required this.mealType,
      required this.mealLabel,
      required this.date,
      required this.api});

  @override
  State<_FoodEntryDialog> createState() => _FoodEntryDialogState();
}

class _FoodEntryDialogState extends State<_FoodEntryDialog> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _amount = TextEditingController();
  final _calories = TextEditingController();
  final _carbs = TextEditingController();
  final _fat = TextEditingController();
  final _protein = TextEditingController();
  List<Map<String, dynamic>> _previous = [];
  List<Map<String, dynamic>> _catalog = [];
  bool _catalogSearching = false;
  Timer? _searchTimer;
  int _searchRevision = 0;
  String? _catalogError;
  String? _selectedBarcode;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchPrevious('');
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    for (final field in [_name, _amount, _calories, _carbs, _fat, _protein]) {
      field.dispose();
    }
    super.dispose();
  }

  Future<void> _searchPrevious(String query) async {
    try {
      final response = await widget.api.previousFoods(query);
      if (mounted && _name.text == query) {
        setState(() => _previous = response);
      }
    } catch (_) {
      if (mounted) setState(() => _previous = []);
    }
  }

  void _searchFoods(String query) {
    _selectedBarcode = null;
    _searchTimer?.cancel();
    final revision = ++_searchRevision;
    _searchPrevious(query);
    setState(() {
      _catalog = [];
      _catalogError = null;
      _catalogSearching = query.trim().length >= 2;
    });
    if (query.trim().length < 2) return;
    _searchTimer = Timer(const Duration(milliseconds: 400), () async {
      try {
        final response = await widget.api.searchCatalog(query.trim());
        if (!mounted || revision != _searchRevision) return;
        setState(() {
          _catalogSearching = false;
          _catalog = response;
        });
      } catch (_) {
        if (!mounted || revision != _searchRevision) return;
        setState(() {
          _catalogSearching = false;
          _catalogError =
              'Catalogue unavailable. You can enter label values manually.';
        });
      }
    });
  }

  void _choose(Map<String, dynamic> food) {
    _searchTimer?.cancel();
    _searchRevision++;
    _selectedBarcode = (food['code'] ??
            (food['source'] == 'open_food_facts' ? food['source_id'] : null))
        ?.toString();
    _name.text = '${food['name'] ?? food['food_name']}';
    _calories.text = '${food['calories_per_100g']}';
    _carbs.text = '${food['carbs_per_100g']}';
    _fat.text = '${food['fat_per_100g']}';
    _protein.text = '${food['protein_per_100g']}';
    setState(() {
      _previous = [];
      _catalog = [];
      _catalogError = null;
      _catalogSearching = false;
    });
  }

  void _switchToManual() => setState(() {
        _selectedBarcode = null;
        _calories.clear();
        _carbs.clear();
        _fat.clear();
        _protein.clear();
      });

  Future<void> _save() async {
    if (!_form.currentState!.validate() || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.api.addEntry({
        'log_date': widget.date,
        'meal_type': widget.mealType,
        'food_name': _name.text.trim(),
        'source':
            _selectedBarcode == null ? 'self_reported' : 'open_food_facts',
        if (_selectedBarcode != null) 'source_id': _selectedBarcode,
        'amount_g': double.parse(_amount.text.trim()),
        if (_selectedBarcode == null) ...{
          'calories_per_100g': double.parse(_calories.text.trim()),
          'carbs_per_100g': double.parse(_carbs.text.trim()),
          'fat_per_100g': double.parse(_fat.text.trim()),
          'protein_per_100g': double.parse(_protein.text.trim()),
        },
      });
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(() => _error = error is ApiException
            ? error.message
            : 'Unable to save this food.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _nutrient(
          TextEditingController controller, String label, double max) =>
      TextFormField(
          controller: controller,
          inputFormatters: [AppNumericInput.decimal],
          readOnly: _selectedBarcode != null,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
              labelText: label, suffixText: label == 'Energy' ? 'kcal' : 'g'),
          validator: (text) {
            final value = double.tryParse(text?.trim() ?? '');
            return value == null || !value.isFinite || value < 0 || value > max
                ? 'Enter 0–${max.toInt()}'
                : null;
          });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return AppFormDialog(
        icon: Icons.track_changes_rounded,
        title: Text('Add ${widget.mealLabel}'),
        content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
                child: Form(
                    key: _form,
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              'Search a food or ingredient in Open Food Facts, choose a previous entry, or enter nutrition from a label. Searches are sent to Open Food Facts.',
                              style: TextStyle(color: AppColors.textSecondary)),
                          const SizedBox(height: 14),
                          TextFormField(
                              controller: _name,
                              onChanged: _searchFoods,
                              decoration: const InputDecoration(
                                  labelText: 'Food or ingredient',
                                  prefixIcon: Icon(Icons.search_rounded)),
                              validator: (text) =>
                                  (text?.trim().length ?? 0) < 2
                                      ? 'Enter a food name'
                                      : null),
                          if (_previous.isNotEmpty)
                            Text('Previously Logged',
                                style: Theme.of(context).textTheme.titleSmall),
                          if (_previous.isNotEmpty)
                            SizedBox(
                                height: math.min(_previous.length * 48.0, 144),
                                child: ListView(children: [
                                  for (final food in _previous)
                                    ListTile(
                                        dense: true,
                                        title: Text('${food['food_name']}'),
                                        onTap: () => _choose(food))
                                ])),
                          if (_catalog.isNotEmpty)
                            Text('Open Food Facts contributors (ODbL)',
                                style: Theme.of(context).textTheme.titleSmall),
                          if (_catalogSearching)
                            const LinearProgressIndicator(minHeight: 2),
                          if (_catalog.isNotEmpty)
                            SizedBox(
                                height: math.min(_catalog.length * 62.0, 210),
                                child: ListView(children: [
                                  for (final food in _catalog)
                                    ListTile(
                                        dense: true,
                                        title: Text('${food['name']}'),
                                        subtitle: Text(
                                            '${food['brand'] ?? 'Product'} • ${food['calories_per_100g']} kcal/100 g'),
                                        onTap: () => _choose(food))
                                ])),
                          if (_catalogError != null)
                            Text(_catalogError!,
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12)),
                          if (_selectedBarcode != null) ...[
                            Text(
                                'Nutrition values verified from the selected Open Food Facts product.',
                                style: TextStyle(
                                    color: AppColors.teal, fontSize: 12)),
                            TextButton(
                                onPressed: _switchToManual,
                                child: const Text('Enter Values Manually')),
                          ],
                          const SizedBox(height: 10),
                          TextFormField(
                              controller: _amount,
                              inputFormatters: [AppNumericInput.decimal],
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration: const InputDecoration(
                                  labelText: 'Amount eaten', suffixText: 'g'),
                              validator: (text) {
                                final value =
                                    double.tryParse(text?.trim() ?? '');
                                return value == null ||
                                        !value.isFinite ||
                                        value <= 0 ||
                                        value > 5000
                                    ? 'Enter 0–5000 g'
                                    : null;
                              }),
                          const SizedBox(height: 12),
                          Text('Nutrition per 100 g',
                              style: Theme.of(context).textTheme.titleSmall),
                          const SizedBox(height: 6),
                          _nutrient(_calories, 'Energy', 1000),
                          const SizedBox(height: 8),
                          _nutrient(_carbs, 'Carbs', 100),
                          const SizedBox(height: 8),
                          _nutrient(_fat, 'Fat', 100),
                          const SizedBox(height: 8),
                          _nutrient(_protein, 'Protein', 100),
                          if (_error != null)
                            Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Text(_error!,
                                    style: TextStyle(color: AppColors.danger))),
                        ])))),
        actions: [
          TextButton(
              onPressed: _busy ? null : () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: _busy ? null : _save,
              child: Text(_busy ? 'Saving…' : 'Add Food')),
        ]);
  }
}
