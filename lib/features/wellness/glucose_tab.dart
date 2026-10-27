import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:medguide/features/wellness/glucose_data_source.dart';
import 'package:medguide/services/api_client.dart';
import 'package:medguide/theme/app_theme.dart';

class GlucoseTab extends StatefulWidget {
  final GlucoseDataSource api;
  final String day;
  const GlucoseTab({super.key, required this.api, required this.day});

  @override
  State<GlucoseTab> createState() => _GlucoseTabState();
}

class _GlucoseTabState extends State<GlucoseTab> {
  late Future<Map<String, dynamic>> summary;

  @override
  void initState() {
    super.initState();
    summary = widget.api.summary(widget.day);
  }

  Future<Map<String, dynamic>?> refresh() async {
    try {
      final data = await widget.api.summary(widget.day);
      if (mounted) {
        setState(() {
          summary = Future.value(data);
        });
      }
      return data;
    } catch (error) {
      if (mounted) showError(error);
      return null;
    }
  }

  void showError(Object error) {
    showDialog<void>(
        context: context,
        builder: (dialog) => AlertDialog(
                title: const Text('Blood Glucose Log Unavailable'),
                content: Text(error is ApiException
                    ? error.message
                    : 'Please try again.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(dialog),
                      child: const Text('Dismiss'))
                ]));
  }

  Future<void> add(String initialCategory) async {
    final entry = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (_) =>
            _MetabolicEntryDialog(initialCategory: initialCategory));
    if (entry == null) return;
    int matchingCount(Map<String, dynamic>? data) =>
        (data?['entries'] as List? ?? const [])
            .whereType<Map>()
            .where((item) =>
                item['log_date'] == widget.day &&
                item['category'] == entry['category'] &&
                readValue(item['value']) == entry['value'])
            .length;
    final before = await summary;
    try {
      await widget.api.addEntry({'log_date': widget.day, ...entry});
      if (mounted) await refresh();
    } catch (error) {
      if (!mounted) return;
      final latest = await refresh();
      if (latest != null &&
          matchingCount(latest) <= matchingCount(before) &&
          mounted) {
        showError(error);
      }
    }
  }

  Widget card(Widget child) => Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: AppColors.primaryBlue.withValues(alpha: .18)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: .04),
                blurRadius: 14,
                offset: const Offset(0, 5))
          ]),
      child: child);

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return FutureBuilder<Map<String, dynamic>>(
      future: summary,
      builder: (_, snapshot) {
        if (!snapshot.hasData) {
          if (snapshot.hasError) {
            return Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('Unable to load your blood glucose log.'),
              TextButton(onPressed: refresh, child: const Text('Retry'))
            ]));
          }
          return const Center(child: CircularProgressIndicator());
        }
        final entries = (snapshot.data!['entries'] as List? ?? const [])
            .whereType<Map>()
            .toList();
        final today =
            entries.where((item) => item['log_date'] == widget.day).toList();
        final glucose =
            today.where((item) => item['category'] != 'insulin_dose').toList();
        final doses =
            today.where((item) => item['category'] == 'insulin_dose').toList();
        final doseTotal = doses.fold<double>(
            0, (sum, item) => sum + (readValue(item['value']) ?? 0));
        return RefreshIndicator(
            onRefresh: () async {
              await refresh();
            },
            child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                children: [
                  card(Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(Icons.bloodtype_rounded,
                              color: AppColors.danger),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text('Today’s Blood Glucose',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall))
                        ]),
                        const SizedBox(height: 5),
                        Text(
                            'Most recent patient-entered reading for each type.',
                            style: TextStyle(color: AppColors.textSecondary)),
                        const SizedBox(height: 15),
                        Row(children: [
                          snapshotTile('Fasting', glucose, 'fasting',
                              Icons.wb_twilight_rounded, AppColors.primaryBlue),
                          snapshotTile('Post-meal', glucose, 'post_meal',
                              Icons.restaurant_rounded, AppColors.amber),
                          snapshotTile('General', glucose, 'general',
                              Icons.bloodtype_outlined, AppColors.teal),
                        ]),
                        const SizedBox(height: 13),
                        Center(
                            child: FilledButton.icon(
                                onPressed: () => add('fasting'),
                                icon: const Icon(Icons.add_rounded),
                                label: const Text('Add Glucose Reading'))),
                      ])),
                  const SizedBox(height: 16),
                  card(Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(Icons.vaccines_rounded,
                              color: AppColors.primaryBlue),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text('Insulin Doses',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall))
                        ]),
                        const SizedBox(height: 8),
                        Text(
                            doses.isEmpty
                                ? 'No doses logged today'
                                : '${doseTotal.toStringAsFixed(doseTotal.truncateToDouble() == doseTotal ? 0 : 2)} U logged today',
                            style: TextStyle(
                                fontSize: 23,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary)),
                        Text(
                            'Entries record doses taken, not blood insulin levels.',
                            style: TextStyle(color: AppColors.textSecondary)),
                        const SizedBox(height: 10),
                        FilledButton.tonalIcon(
                            onPressed: () => add('insulin_dose'),
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Log Insulin Dose')),
                      ])),
                  const SizedBox(height: 16),
                  card(Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Today’s Entries',
                            style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 5),
                        Text(
                            'Patient-entered readings and doses are saved with timestamps.',
                            style: TextStyle(color: AppColors.textSecondary)),
                        if (today.isEmpty)
                          Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text('No readings or doses logged today.',
                                  style: TextStyle(
                                      color: AppColors.textSecondary))),
                        for (final item in today)
                          ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                  item['category'] == 'insulin_dose'
                                      ? Icons.vaccines_rounded
                                      : Icons.bloodtype_outlined,
                                  color: item['category'] == 'insulin_dose'
                                      ? AppColors.primaryBlue
                                      : AppColors.danger),
                              title: Text(label('${item['category']}')),
                              subtitle:
                                  Text('${item['value']} ${item['unit']}'),
                              trailing: Text(time(item['created_at']),
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary))),
                      ])),
                  const SizedBox(height: 16),
                  card(Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Past 7 Days',
                            style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 4),
                        Text(
                            'Latest reading of each type per day; insulin shows the daily logged dose total. Gaps mean no entry.',
                            style: TextStyle(color: AppColors.textSecondary)),
                        const SizedBox(height: 12),
                        trend('Fasting glucose', entries, 'fasting',
                            AppColors.primaryBlue),
                        trend('Post-meal glucose', entries, 'post_meal',
                            AppColors.amber),
                        trend('General glucose', entries, 'general',
                            AppColors.teal),
                        trend('Insulin doses', entries, 'insulin_dose',
                            AppColors.primaryBlue),
                      ])),
                  const SizedBox(height: 12),
                  Text(
                      'Tracking only. These entries do not adjust insulin treatment or verify laboratory results.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ]));
      });
  }

  Widget snapshotTile(String name, List<Map> entries, String category,
      IconData icon, Color color) {
    final matches = entries.where((item) => item['category'] == category);
    final value = matches.isEmpty ? null : matches.first['value'];
    return Expanded(
        child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color.withValues(alpha: .08),
                border: Border.all(color: color.withValues(alpha: .3)),
                borderRadius: BorderRadius.circular(12)),
            child: Column(children: [
              Icon(icon, color: color, size: 25),
              const SizedBox(height: 5),
              Text(name,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: AppColors.textPrimary)),
              Text(value == null ? '—' : '$value',
                  style: TextStyle(fontWeight: FontWeight.bold, color: color)),
              Text('mg/dL',
                  style:
                      TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            ])));
  }

  Widget trend(String title, List<Map> entries, String category, Color color) {
    final days = List.generate(
        7,
        (index) =>
            DateTime.parse(widget.day).subtract(Duration(days: 6 - index)));
    final values = <double?>[];
    for (final date in days) {
      final key = DateFormat('yyyy-MM-dd').format(date);
      final matching = entries
          .where(
              (item) => item['log_date'] == key && item['category'] == category)
          .toList();
      if (matching.isEmpty) {
        values.add(null);
      } else if (category == 'insulin_dose') {
        values.add(matching.fold<double>(
            0, (sum, item) => sum + (readValue(item['value']) ?? 0)));
      } else {
        values.add(readValue(matching.first['value']));
      }
    }
    final highest = values.whereType<double>().fold<double>(1, math.max);
    final unit = category == 'insulin_dose' ? 'U' : 'mg/dL';
    return Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$title ($unit)',
              style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SizedBox(
              height: 112,
              child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                for (var i = 0; i < 7; i++)
                  Expanded(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                        Text(
                            values[i] == null
                                ? '—'
                                : values[i]!.toStringAsFixed(0),
                            style: TextStyle(
                                fontSize: 9, color: AppColors.textSecondary)),
                        const SizedBox(height: 2),
                        Container(
                            height: values[i] == null
                                ? 3
                                : 70 * values[i]! / highest + 3,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                                color: values[i] == null
                                    ? color.withValues(alpha: .18)
                                    : color,
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(4)))),
                        const SizedBox(height: 3),
                        Text(DateFormat.E().format(days[i]),
                            style: TextStyle(
                                fontSize: 9, color: AppColors.textSecondary)),
                      ]))
              ])),
        ]));
  }

  String time(Object? value) {
    final date = DateTime.tryParse('$value');
    return date == null ? '—' : DateFormat.jm().format(date.toLocal());
  }

  double? readValue(Object? value) => double.tryParse('$value');

  String label(String category) => switch (category) {
        'fasting' => 'Fasting glucose',
        'post_meal' => 'Post-meal glucose',
        'general' => 'General glucose',
        _ => 'Insulin dose',
      };
}

class _MetabolicEntryDialog extends StatefulWidget {
  final String initialCategory;
  const _MetabolicEntryDialog({required this.initialCategory});
  @override
  State<_MetabolicEntryDialog> createState() => _MetabolicEntryDialogState();
}

class _MetabolicEntryDialogState extends State<_MetabolicEntryDialog> {
  final form = GlobalKey<FormState>();
  final value = TextEditingController();
  late String category;

  @override
  void initState() {
    super.initState();
    category = widget.initialCategory;
  }

  @override
  void dispose() {
    value.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final dose = category == 'insulin_dose';
    return AlertDialog(
        title: Text(dose ? 'Log Insulin Dose' : 'Add Glucose Reading'),
        content: Form(
            key: form,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              if (!dose)
                DropdownButtonFormField<String>(
                    initialValue: category,
                    decoration:
                        const InputDecoration(labelText: 'Reading type'),
                    items: const [
                      DropdownMenuItem(
                          value: 'fasting', child: Text('Fasting')),
                      DropdownMenuItem(
                          value: 'post_meal', child: Text('Post-meal')),
                      DropdownMenuItem(
                          value: 'general', child: Text('General')),
                    ],
                    onChanged: (next) {
                      if (next != null) {
                        setState(() {
                          category = next;
                        });
                      }
                    }),
              const SizedBox(height: 10),
              TextFormField(
                  controller: value,
                  autofocus: true,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                  ],
                  decoration: InputDecoration(
                      labelText: dose ? 'Dose taken' : 'Blood glucose',
                      suffixText: dose ? 'U' : 'mg/dL'),
                  validator: (text) {
                    final n = double.tryParse(text?.trim() ?? '');
                    return n == null || n <= 0 || n > 1000
                        ? 'Enter a value greater than 0 and up to 1000'
                        : null;
                  }),
              const SizedBox(height: 10),
              Text(
                  dose
                      ? 'Record a dose already taken. This does not provide dosing advice.'
                      : 'Enter a meter reading. This is patient-reported, not a verified lab result.',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ])),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () {
                if (form.currentState!.validate()) {
                  Navigator.pop(context, {
                    'category': category,
                    'value': double.parse(value.text.trim())
                  });
                }
              },
              child: const Text('Save'))
        ]);
  }
}
