import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medguide/screens/shared/prediction_result_screen.dart';
import 'package:medguide/services/api_client.dart';
import 'package:medguide/theme/app_theme.dart';
import 'package:medguide/widgets/shared_widgets.dart';

enum _RiskType { all, diabetes, heart }

enum _RiskLevel { all, low, moderate, high }

enum _Order { latest, oldest }

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<Map<String, dynamic>>> _future;
  _RiskType _type = _RiskType.all;
  _RiskLevel _level = _RiskLevel.all;
  _Order _order = _Order.latest;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final raw =
        await ApiClient.instance.get('/predictions', query: {'limit': 100});
    final values = (raw as List)
        .whereType<Map>()
        .map((value) => Map<String, dynamic>.from(value))
        .toList();
    values.sort((a, b) => _date(b).compareTo(_date(a)));
    return values;
  }

  Future<void> _refresh() async {
    final next = _load();
    setState(() => _future = next);
    await next;
  }

  static DateTime _date(Map<String, dynamic> value) =>
      DateTime.tryParse(value['predicted_at']?.toString() ?? '')?.toLocal() ??
      DateTime.fromMillisecondsSinceEpoch(0);
  static String _target(Map<String, dynamic> value) =>
      value['prediction_target']?.toString().toLowerCase() ?? '';
  static String _classification(Map<String, dynamic> value) =>
      value['risk_classification']?.toString().toLowerCase() ?? '';
  static double? _score(Map<String, dynamic> value) =>
      (value['risk_score'] as num?)?.toDouble();

  bool _matches(Map<String, dynamic> value) {
    final target = _target(value);
    final classification = _classification(value);
    final typeMatches = switch (_type) {
      _RiskType.all => true,
      _RiskType.diabetes => target.contains('diabetes'),
      _RiskType.heart => target.contains('heart'),
    };
    final levelMatches = switch (_level) {
      _RiskLevel.all => true,
      _RiskLevel.low => classification.contains('low'),
      _RiskLevel.moderate => classification.contains('moderate') ||
          classification.contains('medium'),
      _RiskLevel.high => classification.contains('high'),
    };
    return typeMatches && levelMatches;
  }

  List<Map<String, dynamic>> _filtered(List<Map<String, dynamic>> source) {
    final result = source.where(_matches).toList();
    result.sort((a, b) => _order == _Order.latest
        ? _date(b).compareTo(_date(a))
        : _date(a).compareTo(_date(b)));
    return result;
  }

  Color _color(String value) {
    final level = value.toLowerCase();
    if (level.contains('high')) return AppColors.riskHigh;
    if (level.contains('moderate') || level.contains('medium')) {
      return AppColors.riskMedium;
    }
    return AppColors.riskLow;
  }

  String _condition(Map<String, dynamic> value) =>
      _target(value).contains('heart') ? 'Heart Disease Risk' : 'Diabetes Risk';

  String _levelLabel(Map<String, dynamic> value) {
    final raw = value['risk_classification']?.toString().trim() ?? '';
    if (raw.isEmpty) return 'Not classified';
    return raw
        .split(RegExp(r'[_\s]+'))
        .map((word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
        .join(' ');
  }

  Widget _chip(String label, bool selected, VoidCallback select) => ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => select(),
      );

  Future<void> _showFilters() async {
    var type = _type;
    var level = _level;
    var order = _order;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, update) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text('Filter predictions',
                          style: Theme.of(context).textTheme.headlineSmall),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  const Text('Risk analysis',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    _chip('All analyses', type == _RiskType.all,
                        () => update(() => type = _RiskType.all)),
                    _chip('Diabetes only', type == _RiskType.diabetes,
                        () => update(() => type = _RiskType.diabetes)),
                    _chip('Heart disease only', type == _RiskType.heart,
                        () => update(() => type = _RiskType.heart)),
                  ]),
                  const SizedBox(height: 18),
                  const Text('Risk score',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    _chip('All scores', level == _RiskLevel.all,
                        () => update(() => level = _RiskLevel.all)),
                    _chip('Low risk', level == _RiskLevel.low,
                        () => update(() => level = _RiskLevel.low)),
                    _chip('Moderate risk', level == _RiskLevel.moderate,
                        () => update(() => level = _RiskLevel.moderate)),
                    _chip('High risk', level == _RiskLevel.high,
                        () => update(() => level = _RiskLevel.high)),
                  ]),
                  const SizedBox(height: 18),
                  const Text('Sort order',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  RadioListTile<_Order>(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Most recent first'),
                    value: _Order.latest,
                    groupValue: order,
                    onChanged: (value) => update(() => order = value!),
                  ),
                  RadioListTile<_Order>(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Oldest first'),
                    value: _Order.oldest,
                    groupValue: order,
                    onChanged: (value) => update(() => order = value!),
                  ),
                  Row(children: [
                    TextButton(
                      onPressed: () => update(() {
                        type = _RiskType.all;
                        level = _RiskLevel.all;
                        order = _Order.latest;
                      }),
                      child: const Text('Restore defaults'),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: () {
                        setState(() {
                          _type = type;
                          _level = level;
                          _order = order;
                        });
                        Navigator.pop(dialogContext);
                      },
                      child: const Text('Apply'),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: const MedAppBar(
            title: 'Prediction History', showSecureBadge: false),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(snapshot.error.toString(), textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  OutlinedButton(
                      onPressed: _refresh, child: const Text('Try again')),
                ]),
              );
            }
            final all = snapshot.data ?? const <Map<String, dynamic>>[];
            final shown = _filtered(all);
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  _RiskTrendCard(predictions: all),
                  const SizedBox(height: 20),
                  SectionHeader(
                    title: 'All Predictions',
                    actionLabel: 'Filter',
                    onAction: _showFilters,
                  ),
                  const SizedBox(height: 12),
                  if (shown.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 36),
                      child: Center(
                        child:
                            Text('No predictions match the selected filters.'),
                      ),
                    )
                  else
                    ...shown.map((prediction) {
                      final score = _score(prediction);
                      final level = _levelLabel(prediction);
                      return _HistoryCard(
                        condition: _condition(prediction),
                        date: DateFormat('MMM d, yyyy • HH:mm')
                            .format(_date(prediction)),
                        score: score,
                        level: level,
                        color: _color(level),
                        onTap: score == null
                            ? null
                            : () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PredictionResultScreen(
                                      condition: _condition(prediction)
                                          .replaceAll(' Risk', ''),
                                      riskScore: score,
                                    ),
                                  ),
                                ),
                      );
                    }),
                ],
              ),
            );
          },
        ),
      );
}

class _RiskTrendCard extends StatelessWidget {
  final List<Map<String, dynamic>> predictions;
  const _RiskTrendCard({required this.predictions});

  @override
  Widget build(BuildContext context) {
    final target = predictions.isEmpty
        ? ''
        : predictions.first['prediction_target']?.toString().toLowerCase() ??
            '';
    final values = predictions
        .where((value) =>
            value['prediction_target']?.toString().toLowerCase() == target &&
            value['risk_score'] is num)
        .take(5)
        .toList()
        .reversed
        .toList();
    final spots = [
      for (var i = 0; i < values.length; i++)
        FlSpot(i.toDouble(), (values[i]['risk_score'] as num).toDouble() * 100)
    ];
    final labels = values
        .map((value) => DateFormat('MMM d')
            .format(DateTime.parse(value['predicted_at'].toString()).toLocal()))
        .toList();
    final heart = target.contains('heart');
    final color = heart ? AppColors.danger : AppColors.primaryBlue;
    final title = target.isEmpty
        ? 'Risk Trend'
        : heart
            ? 'Heart Disease Risk Trend'
            : 'Diabetes Risk Trend';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(
          values.isEmpty
              ? 'No prediction history available'
              : 'Latest ${values.length} ${values.length == 1 ? 'prediction' : 'predictions'}',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 130,
          child: spots.isEmpty
              ? const Center(
                  child: Text('Run a risk analysis to see your trend.'))
              : LineChart(LineChartData(
                  minX: 0,
                  maxX: spots.length == 1 ? 1 : (spots.length - 1).toDouble(),
                  minY: 0,
                  maxY: 100,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 25,
                    getDrawingHorizontalLine: (_) =>
                        FlLine(color: AppColors.border, strokeWidth: 1),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        interval: 25,
                        getTitlesWidget: (value, _) => Text('${value.toInt()}%',
                            style: const TextStyle(
                                fontSize: 9, color: AppColors.textLight)),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, _) {
                          final i = value.toInt();
                          if (i < 0 || i >= labels.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(labels[i],
                                style: const TextStyle(
                                    fontSize: 8, color: AppColors.textLight)),
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: spots.length > 2,
                      color: color,
                      barWidth: 2.5,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                          radius: 3.5,
                          color: color,
                          strokeWidth: 1.5,
                          strokeColor: Colors.white,
                        ),
                      ),
                      belowBarData: BarAreaData(
                          show: true, color: color.withOpacity(0.07)),
                    ),
                  ],
                )),
        ),
      ]),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final String condition;
  final String date;
  final double? score;
  final String level;
  final Color color;
  final VoidCallback? onTap;
  const _HistoryCard({
    required this.condition,
    required this.date,
    required this.score,
    required this.level,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                condition.contains('Heart')
                    ? Icons.favorite_outline_rounded
                    : Icons.water_drop_outlined,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(condition,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(date,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(score == null ? '—' : '${(score! * 100).round()}%',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700, color: color)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Text(level,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: color)),
              ),
            ]),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textLight, size: 20),
          ]),
        ),
      );
}
