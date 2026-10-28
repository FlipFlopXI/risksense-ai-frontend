/// A descriptive report from actual saved measurements. It does not use the
/// disease-risk model or treat a measurement change as clinical progression.
class ConditionTrendReport {
  const ConditionTrendReport({required this.condition, required this.metrics});

  final String condition;
  final List<TrendMetric> metrics;

  static ConditionTrendReport fromApi(
      String condition, Map<String, dynamic> data, DateTime now) {
    final start = now.subtract(const Duration(days: 7));
    final definitions = condition == 'diabetes'
        ? <(String, String, String, String, String)>[
            (
              'Fasting glucose',
              'fasting_glucose',
              'measured_at',
              'value',
              'mg/dL'
            ),
            ('BMI', 'body_measurements', 'measured_at', 'bmi', 'kg/m²'),
            ('Weight', 'body_measurements', 'measured_at', 'weight_kg', 'kg'),
          ]
        : <(String, String, String, String, String)>[
            (
              'Systolic blood pressure',
              'blood_pressure',
              'recorded_at',
              'systolic',
              'mmHg'
            ),
            (
              'Diastolic blood pressure',
              'blood_pressure',
              'recorded_at',
              'diastolic',
              'mmHg'
            ),
            (
              'Total cholesterol',
              'total_cholesterol',
              'measured_at',
              'value',
              'mg/dL'
            ),
            ('Heart rate', 'heart_rate', 'recorded_at', 'value', 'bpm'),
          ];
    final metrics = <TrendMetric>[];
    for (final entry in definitions) {
      final raw = data[entry.$2];
      final readings = <TrendReading>[];
      if (raw is List) {
        for (final item in raw) {
          if (item is! Map) continue;
          final at = DateTime.tryParse(item[entry.$3]?.toString() ?? '');
          final value = item[entry.$4];
          if (at == null || value is! num || !value.isFinite) continue;
          if (at.isBefore(start) || at.isAfter(now)) continue;
          readings.add(TrendReading(at: at, value: value.toDouble()));
        }
      }
      readings.sort((a, b) => a.at.compareTo(b.at));
      metrics.add(TrendMetric(
        name: entry.$1,
        unit: entry.$5,
        readings: readings,
      ));
    }
    return ConditionTrendReport(condition: condition, metrics: metrics);
  }

  bool get hasReadings => metrics.any((metric) => metric.readings.isNotEmpty);

  List<TrendMetric> get readingsToReview => metrics
      .where((metric) =>
          metric.readings.length >= 2 &&
          metric.delta! > 0 &&
          (metric.name == 'Fasting glucose' ||
              metric.name == 'Systolic blood pressure' ||
              metric.name == 'Diastolic blood pressure' ||
              metric.name == 'Total cholesterol'))
      .toList();
}

class TrendReading {
  const TrendReading({required this.at, required this.value});
  final DateTime at;
  final double value;
}

class TrendMetric {
  const TrendMetric(
      {required this.name, required this.unit, required this.readings});
  final String name;
  final String unit;
  final List<TrendReading> readings;

  TrendReading? get latest => readings.isEmpty ? null : readings.last;
  TrendReading? get earliest => readings.isEmpty ? null : readings.first;
  double? get delta =>
      readings.length < 2 ? null : readings.last.value - readings.first.value;

  String get direction {
    final change = delta;
    if (change == null) return 'One reading only';
    if (change.abs() < .01) return 'No measured change';
    return change > 0 ? 'Increased' : 'Decreased';
  }
}
