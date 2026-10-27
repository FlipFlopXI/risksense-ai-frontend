import 'package:flutter_test/flutter_test.dart';
import 'package:medguide/features/wellness/fitness_data_source.dart';
import 'package:medguide/features/wellness/glucose_data_source.dart';
import 'package:medguide/features/wellness/mindfulness_data_source.dart';
import 'package:medguide/features/wellness/nutrition_data_source.dart';
import 'package:medguide/services/weekly_report.dart';

class _Nutrition implements NutritionDataSource {
  @override
  Future<Map<String, dynamic>> summary(String day) async => {
        'calories_kcal': day == '2026-10-25' ? 450 : 0,
        'carbs_g': 12,
        'protein_g': 20,
        'fat_g': 4,
        'entries': day == '2026-10-25'
            ? [
                {
                  'meal_type': 'lunch',
                  'food_name': 'Rice',
                  'amount_g': 150,
                  'calories_kcal': 450
                }
              ]
            : [],
      };

  @override
  Future<Map<String, dynamic>> waterSummary(String day) async => {
        'total_ml': day == '2026-10-25' ? 500 : 0,
        'entries': day == '2026-10-25'
            ? [
                {'amount_ml': 250},
                {'amount_ml': 250},
              ]
            : [],
      };

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Glucose implements GlucoseDataSource {
  @override
  Future<Map<String, dynamic>> summary(String day) async => {
        'entries': [
          {
            'log_date': '2026-10-25',
            'category': 'fasting',
            'value': 95,
            'unit': 'mg/dL'
          },
          {
            'log_date': '2026-10-18',
            'category': 'fasting',
            'value': 99,
            'unit': 'mg/dL'
          },
        ]
      };

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Fitness implements FitnessDataSource {
  @override
  Future<Map<String, dynamic>> activity(String day) async => {
        'history': [
          {
            'date': '2026-10-25',
            'steps': 3000,
            'activity_minutes': 35,
            'activity_calories_kcal': 120,
            'distance_km': 2.1,
          }
        ],
      };

  @override
  Future<List<Map<String, dynamic>>> bodyTrends() async => [
        {'measured_at': '2026-10-25T12:00:00', 'weight_kg': 71, 'bmi': 24},
        {'measured_at': '2026-10-18T12:00:00', 'weight_kg': 72, 'bmi': 25},
      ];

  @override
  Future<Map<String, dynamic>> body() async => {
        'composition': {
          'created_at': '2026-10-25T12:00:00',
          'skeletal_muscle_kg': 30,
          'body_fat_percent': 18,
        }
      };

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Mindfulness implements MindfulnessDataSource {
  @override
  Future<Map<String, dynamic>> moodSummary(String day) async => {
        'today_entries': day == '2026-10-25'
            ? [
                {'mood': 'good', 'emotion': 'Calm', 'reason': 'Rested'}
              ]
            : [],
      };

  @override
  Future<Map<String, dynamic>> breathingSummary(String day) async => {
        'history': [
          {'date': '2026-10-25', 'count': 2, 'duration_seconds': 240}
        ],
      };

  @override
  Future<Map<String, dynamic>> meditationSummary(String day) async => {
        'history': [
          {'date': '2026-10-25', 'count': 1, 'duration_seconds': 300}
        ],
      };

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final end = DateTime(2026, 10, 25);

  test('Nutrition report covers exactly seven days and all three tabs',
      () async {
    final report = await WeeklyReportService.nutrition(
        nutrition: _Nutrition(), glucose: _Glucose(), endDate: end);
    expect(report.days.length, 7);
    expect(report.days.first.date, DateTime(2026, 10, 19));
    expect(report.days.last.date, end);
    expect(report.days.last.lines.join(' '), contains('Rice'));
    expect(report.days.last.lines.join(' '), contains('500 ml'));
    expect(report.days.last.lines.join(' '), contains('Water entry: 250 ml'));
    expect(report.days.last.lines.join(' '), contains('95.0 mg/dL'));
    expect(report.days.expand((day) => day.lines).join(' '),
        isNot(contains('99.0 mg/dL')));
  });

  test('Fitness report excludes older body measurements', () async {
    final report =
        await WeeklyReportService.fitness(fitness: _Fitness(), endDate: end);
    expect(report.days.last.lines.join(' '), contains('3000 steps'));
    expect(report.days.last.lines.join(' '), contains('71.0 kg'));
    expect(report.days.last.lines.join(' '), contains('18.0% body fat'));
    expect(report.days.expand((day) => day.lines).join(' '),
        isNot(contains('72.0 kg')));
  });

  test('Mindfulness report includes moods, breathing and meditation', () async {
    final report = await WeeklyReportService.mindfulness(
        mindfulness: _Mindfulness(), endDate: end);
    expect(report.days.last.lines.join(' '), contains('reason: Rested'));
    expect(report.days.last.lines.join(' '), contains('Breathing: 2 sessions'));
    expect(
        report.days.last.lines.join(' '), contains('Meditation: 1 sessions'));
  });

  test('Weekly report generates a valid PDF for preview', () async {
    final report = await WeeklyReportService.mindfulness(
        mindfulness: _Mindfulness(), endDate: end);
    expect(report.filename, 'risksense_mindfulness_2026-10-25.pdf');
    final bytes = await WeeklyReportService.buildPdf(report);
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });
}
