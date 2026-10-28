import 'package:flutter_test/flutter_test.dart';
import 'package:medguide/services/condition_trend_report.dart';

void main() {
  final now = DateTime.utc(2026, 10, 27, 12);

  test('uses only saved readings from the last seven days', () {
    final report = ConditionTrendReport.fromApi(
        'diabetes',
        {
          'fasting_glucose': [
            {'measured_at': '2026-10-19T12:00:00Z', 'value': 200},
            {'measured_at': '2026-10-22T12:00:00Z', 'value': 110},
            {'measured_at': '2026-10-26T12:00:00Z', 'value': 125},
          ],
          'body_measurements': [
            {'measured_at': '2026-10-26T12:00:00Z', 'bmi': 25.2},
          ],
        },
        now);
    expect(report.metrics.first.readings.length, 2);
    expect(report.metrics.first.delta, 15);
    expect(report.readingsToReview.map((m) => m.name), ['Fasting glucose']);
    expect(report.metrics[1].direction, 'One reading only');
  });

  test('missing and single readings cannot establish a trend', () {
    final report = ConditionTrendReport.fromApi(
        'heart_disease',
        {
          'blood_pressure': [
            {'recorded_at': '2026-10-27T09:00:00Z', 'systolic': 132},
          ],
        },
        now);
    expect(report.readingsToReview, isEmpty);
    expect(report.metrics.first.direction, 'One reading only');
    expect(report.metrics[2].latest, isNull);
  });
}
