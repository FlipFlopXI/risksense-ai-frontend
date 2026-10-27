import 'package:flutter_test/flutter_test.dart';
import 'package:medguide/screens/shared/health_trend_commands.dart';

class SampleTrends implements HealthTrendSource {
  @override
  Future<Map<String, dynamic>> load() async => {
    'blood_pressure': [
      {'recorded_at': '2026-10-23T12:00:00Z', 'systolic': 120, 'diastolic': 80},
      {'recorded_at': '2026-10-25T12:00:00Z', 'systolic': 118, 'diastolic': 76},
    ],
    'heart_rate': [], 'fasting_glucose': [], 'total_cholesterol': [],
    'body_measurements': [],
  };
}

void main() {
  final commands = HealthTrendCommands(SampleTrends(),
      now: () => DateTime.utc(2026, 10, 26));
  test('summarizes only actual recent readings with dates', () async {
    final answer = await commands.handle('Show my blood pressure trend');
    expect(answer, contains('118/76 mmHg'));
    expect(answer, contains('25 Oct'));
    expect(answer, contains('Systolic lower; diastolic lower'));
    expect(answer, contains('not a diagnosis'));
  });
  test('missing measurements stay missing and medication questions pass through', () async {
    expect(await commands.handle('Show my glucose trend'), contains('no recorded readings'));
    expect(await commands.handle('What are the side effects of metformin?'), isNull);
  });
}
