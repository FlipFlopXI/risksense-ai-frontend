import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medguide/theme/app_theme.dart';

class BodyWeek {
  final DateTime startsOn;
  double? weightKg, bmi;
  DateTime? weightRecordedAt, bmiRecordedAt;
  BodyWeek(this.startsOn);
}

/// The latest recorded value per calendar week. Missing weeks remain empty.
List<BodyWeek> weeklyBodyTrend(
    List<Map<String, dynamic>> measurements, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final currentMonday = today.subtract(Duration(days: today.weekday - 1));
  final firstMonday = currentMonday.subtract(const Duration(days: 42));
  final weeks = List.generate(
      7, (index) => BodyWeek(firstMonday.add(Duration(days: index * 7))));
  for (final row in measurements) {
    final recorded = DateTime.tryParse('${row['measured_at']}')?.toLocal();
    if (recorded == null || recorded.isAfter(now)) continue;
    final recordedDay = DateTime(recorded.year, recorded.month, recorded.day);
    final monday =
        recordedDay.subtract(Duration(days: recordedDay.weekday - 1));
    final index = DateTime.utc(monday.year, monday.month, monday.day)
            .difference(DateTime.utc(
                firstMonday.year, firstMonday.month, firstMonday.day))
            .inDays ~/
        7;
    if (index < 0 || index >= weeks.length) continue;
    final week = weeks[index];
    final weight = (row['weight_kg'] as num?)?.toDouble();
    if (weight != null &&
        weight.isFinite &&
        weight > 0 &&
        (week.weightRecordedAt == null ||
            recorded.isAfter(week.weightRecordedAt!))) {
      week.weightKg = weight;
      week.weightRecordedAt = recorded;
    }
    final bmi = (row['bmi'] as num?)?.toDouble();
    if (bmi != null &&
        bmi.isFinite &&
        bmi > 0 &&
        (week.bmiRecordedAt == null || recorded.isAfter(week.bmiRecordedAt!))) {
      week.bmi = bmi;
      week.bmiRecordedAt = recorded;
    }
  }
  return weeks;
}

class BodyTrendChart extends StatelessWidget {
  final List<Map<String, dynamic>> measurements;
  const BodyTrendChart({super.key, required this.measurements});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final weeks = weeklyBodyTrend(measurements, DateTime.now());
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(Icons.show_chart_rounded, color: AppColors.teal),
        const SizedBox(width: 8),
        Expanded(
            child: Text('Weekly Body Trends',
                style: Theme.of(context).textTheme.headlineSmall)),
      ]),
      const SizedBox(height: 6),
      Text('Latest recorded measurement in each of the past 7 calendar weeks.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      const SizedBox(height: 16),
      _metricChart(
          'Weight', 'kg', weeks, (week) => week.weightKg, AppColors.teal),
      const SizedBox(height: 20),
      _metricChart('BMI', '', weeks, (week) => week.bmi, AppColors.primaryBlue),
      const SizedBox(height: 8),
      Text(
          'Gaps mean no measurement was recorded that week. BMI uses the height recorded at or before the weight measurement.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
    ]);
  }

  Widget _metricChart(String title, String unit, List<BodyWeek> weeks,
      double? Function(BodyWeek) valueFor, Color color) {
    final values = weeks.map(valueFor).whereType<double>().toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('$title${unit.isEmpty ? '' : ' ($unit)'}',
          style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      if (values.isEmpty)
        SizedBox(
            height: 76,
            child: Center(
                child: Text(
                    'No ${title.toLowerCase()} measurements in the last 7 weeks.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary))))
      else
        SizedBox(
            height: 165,
            child: LineChart(_chartData(weeks, valueFor, values, color))),
    ]);
  }

  LineChartData _chartData(List<BodyWeek> weeks,
      double? Function(BodyWeek) valueFor, List<double> values, Color color) {
    final lower = values.reduce(math.min), upper = values.reduce(math.max);
    final margin =
        math.max((upper - lower) * .2, color == AppColors.teal ? 1.0 : .5);
    final bars = <LineChartBarData>[];
    var current = <FlSpot>[];
    void addSegment() {
      if (current.isEmpty) return;
      bars.add(LineChartBarData(
          spots: current,
          isCurved: false,
          color: color,
          barWidth: 2.5,
          dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                  radius: 3.5,
                  color: color,
                  strokeColor: Colors.white,
                  strokeWidth: 1.5))));
      current = <FlSpot>[];
    }

    for (var index = 0; index < weeks.length; index++) {
      final value = valueFor(weeks[index]);
      if (value == null) {
        addSegment();
      } else {
        current.add(FlSpot(index.toDouble(), value));
      }
    }
    addSegment();
    return LineChartData(
      minX: 0,
      maxX: 6,
      minY: lower - margin,
      maxY: upper + margin,
      lineBarsData: bars,
      borderData: FlBorderData(show: false),
      gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: AppColors.border, strokeWidth: 1)),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
            sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 38,
                getTitlesWidget: (value, _) => Text(value.toStringAsFixed(1),
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 9)))),
        bottomTitles: AxisTitles(
            sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 28,
                getTitlesWidget: (value, _) {
                  final index = value.toInt();
                  if (index < 0 || index >= weeks.length || value != index) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(
                          DateFormat('d/M').format(weeks[index].startsOn),
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 9),
                          textAlign: TextAlign.center));
                })),
      ),
    );
  }
}
