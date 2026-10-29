import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:medguide/features/wellness/nutrition_data_source.dart';
import 'package:medguide/services/api_client.dart';
import 'package:medguide/theme/app_theme.dart';
import 'package:medguide/widgets/app_form_dialog.dart';

class WaterTab extends StatefulWidget {
  final NutritionDataSource api;
  final String day;
  const WaterTab({super.key, required this.api, required this.day});

  @override
  State<WaterTab> createState() => _WaterTabState();
}

class _WaterTabState extends State<WaterTab> {
  late Future<Map<String, dynamic>> _summary;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _summary = widget.api.waterSummary(widget.day);
  }

  Future<Map<String, dynamic>?> _refresh() async {
    try {
      final data = await widget.api.waterSummary(widget.day);
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

  Future<void> _addWater() async {
    if (_saving) return;
    setState(() {
      _saving = true;
    });
    try {
      await widget.api.addWater(widget.day, 250);
      if (mounted) await _refresh();
    } catch (error) {
      if (mounted) {
        final refreshed = await _refresh();
        if (refreshed == null && mounted) _showError(error);
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _editGoal(int? current) async {
    final goal = await showDialog<int>(
        context: context,
        builder: (_) => _WaterGoalDialog(initialGoal: current));
    if (goal == null || !mounted) return;
    try {
      await widget.api.saveWaterGoal(goal);
      if (mounted) await _refresh();
    } catch (error) {
      if (!mounted) return;
      final latest = await _refresh();
      if (latest != null && latest['goal_ml'] != goal && mounted) {
        _showError(error);
      }
    }
  }

  void _showError(Object error) {
    showDialog<void>(
        context: context,
        builder: (dialog) => AlertDialog(
              title: const Text('Water Log Unavailable'),
              content: Text(
                  error is ApiException ? error.message : 'Please try again.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(dialog),
                    child: const Text('Dismiss'))
              ],
            ));
  }

  Widget _card(Widget child) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.teal.withValues(alpha: .16)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: .04),
                  blurRadius: 14,
                  offset: const Offset(0, 5))
            ]),
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return FutureBuilder<Map<String, dynamic>>(
      future: _summary,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          if (snapshot.hasError) {
            return Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('Unable to load your water log.'),
              TextButton(onPressed: _refresh, child: const Text('Retry'))
            ]));
          }
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data!;
        final total = (data['total_ml'] as num?)?.toInt() ?? 0;
        final goal = (data['goal_ml'] as num?)?.toInt();
        final entries = (data['entries'] as List? ?? const []).whereType<Map>();
        final history = (data['history'] as List? ?? const []).whereType<Map>();
        return RefreshIndicator(
            onRefresh: () async {
              await _refresh();
            },
            child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                children: [
                  _card(Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(Icons.water_drop_rounded,
                              color: AppColors.primaryBlue),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text('Today’s Water',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall))
                        ]),
                        const SizedBox(height: 10),
                        Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    Text('$total',
                                        style: TextStyle(
                                            fontSize: 42,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.textPrimary)),
                                    Text('ml consumed',
                                        style: TextStyle(
                                            color: AppColors.textSecondary))
                                  ])),
                              Column(children: [
                                FilledButton.icon(
                                    onPressed: _saving ? null : _addWater,
                                    icon: const Icon(Icons.add_rounded),
                                    label: const Text('+250 ml')),
                                IconButton(
                                    tooltip: 'Set daily water goal',
                                    onPressed: () => _editGoal(goal),
                                    icon: Icon(Icons.track_changes_rounded,
                                        color: AppColors.teal)),
                              ]),
                            ]),
                        Text(
                            goal == null
                                ? 'Set a daily goal with the bullseye.'
                                : 'Daily goal: $goal ml',
                            style: TextStyle(color: AppColors.textSecondary)),
                        const SizedBox(height: 16),
                        LayoutBuilder(
                            builder: (context, constraints) => Stack(children: [
                                  ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: LinearProgressIndicator(
                                          value: (total / 4000).clamp(0.0, 1.0),
                                          minHeight: 14,
                                          backgroundColor: AppColors.primaryBlue
                                              .withValues(alpha: .13),
                                          color: AppColors.primaryBlue)),
                                  if (goal != null)
                                    Positioned(
                                        left: math.max(
                                            0,
                                            constraints.maxWidth * goal / 4000 -
                                                8),
                                        top: 0,
                                        child: Icon(Icons.adjust_rounded,
                                            size: 15, color: AppColors.teal)),
                                ])),
                        const SizedBox(height: 5),
                        const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [Text('0 ml'), Text('4,000 ml')]),
                      ])),
                  const SizedBox(height: 16),
                  _card(Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Water Added Today',
                            style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 5),
                        Text('Each addition is saved with its time.',
                            style: TextStyle(color: AppColors.textSecondary)),
                        const SizedBox(height: 12),
                        if (entries.isEmpty)
                          Text('No water logged today.',
                              style: TextStyle(color: AppColors.textSecondary)),
                        for (final entry in entries)
                          Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(children: [
                                Icon(Icons.water_drop_outlined,
                                    color: AppColors.primaryBlue),
                                const SizedBox(width: 9),
                                Expanded(
                                    child: Text('${entry['amount_ml']} ml',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700))),
                                Text(_time(entry['created_at']),
                                    style: TextStyle(
                                        color: AppColors.textSecondary)),
                              ])),
                      ])),
                  const SizedBox(height: 16),
                  _card(Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Water Intake · Last 7 Days',
                            style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 5),
                        Text('Daily totals from your saved water log.',
                            style: TextStyle(color: AppColors.textSecondary)),
                        const SizedBox(height: 16),
                        _WaterChart(history: history.toList()),
                      ])),
                ]));
      },
    );
  }

  String _time(Object? value) {
    final date = DateTime.tryParse('$value');
    return date == null
        ? 'Time unavailable'
        : DateFormat.jm().format(date.toLocal());
  }
}

class _WaterChart extends StatelessWidget {
  final List<Map> history;
  const _WaterChart({required this.history});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final highest = history.fold<int>(
        4000,
        (maxValue, day) =>
            math.max(maxValue, (day['amount_ml'] as num?)?.toInt() ?? 0));
    return SizedBox(
        height: 166,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final day in history)
              Expanded(
                  child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text('${day['amount_ml'] ?? 0}',
                                style: TextStyle(
                                    fontSize: 9,
                                    color: AppColors.textSecondary)),
                            const SizedBox(height: 3),
                            Container(
                                height: 100 *
                                        ((day['amount_ml'] as num?)?.toInt() ??
                                            0) /
                                        highest +
                                    3,
                                decoration: BoxDecoration(
                                    color: AppColors.primaryBlue,
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
                          ])))
          ],
        ));
  }
}

class _WaterGoalDialog extends StatefulWidget {
  final int? initialGoal;
  const _WaterGoalDialog({required this.initialGoal});

  @override
  State<_WaterGoalDialog> createState() => _WaterGoalDialogState();
}

class _WaterGoalDialogState extends State<_WaterGoalDialog> {
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
      icon: Icons.water_drop_rounded,
      title: const Text('Daily Water Goal'),
      content: Form(
          key: _form,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text(
                'Choose a personal tracking goal. Ask your clinician about a suitable amount if you have a fluid restriction.'),
            const SizedBox(height: 14),
            TextFormField(
                controller: _controller,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                    labelText: 'Goal', suffixText: 'ml / day'),
                validator: (text) {
                  final value = int.tryParse(text?.trim() ?? '');
                  return value == null || value < 250 || value > 4000
                      ? 'Enter 250 to 4,000 ml'
                      : null;
                }),
          ])),
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
            child: const Text('Save Goal'))
      ],
    );
  }
}
