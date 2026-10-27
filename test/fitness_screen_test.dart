import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:medguide/features/wellness/fitness_data_source.dart';
import 'package:medguide/features/wellness/fitness_screen.dart';
import 'package:medguide/features/wellness/body_trend_chart.dart';

class FakeFitness implements FitnessDataSource {
  double weight = 80;
  int steps = 0;
  List<double>? composition;
  final measurements = <Map<String, dynamic>>[];

  @override
  Future<Map<String, dynamic>> activity(String day) async => {
        'date': day,
        'today': {
          'steps': steps,
          'activity_minutes': 20,
          'activity_calories_kcal': 90,
          'distance_km': 1.2
        },
        'history': List.generate(
            7,
            (i) => {
                  'date': DateTime.now()
                      .subtract(Duration(days: 6 - i))
                      .toIso8601String(),
                  'steps': i == 6 ? steps : 0,
                  'activity_minutes': i == 6 ? 20 : 0,
                  'activity_calories_kcal': i == 6 ? 90 : 0,
                  'distance_km': i == 6 ? 1.2 : 0,
                }),
      };

  @override
  Future<void> addActivity(Map<String, dynamic> entry) async {
    steps += entry['steps'] as int;
  }

  @override
  Future<Map<String, dynamic>> body() async => {
        'weight_kg': weight,
        'height_cm': 180,
        'bmi': weight / (1.8 * 1.8),
        'adult_bmi_reference_applicable': true,
        'composition': composition == null
            ? null
            : {
                'skeletal_muscle_kg': composition![0],
                'body_fat_percent': composition![1],
              },
      };

  @override
  Future<List<Map<String, dynamic>>> bodyTrends() async => measurements;

  @override
  Future<void> saveWeight(double kg) async {
    weight = kg;
    measurements.add({
      'measured_at': DateTime.now().toUtc().toIso8601String(),
      'weight_kg': kg,
      'bmi': kg / (1.8 * 1.8),
    });
  }

  @override
  Future<void> saveComposition(double muscleKg, double fatPercent) async {
    composition = [muscleKg, fatPercent];
  }
}

void main() {
  test('Weekly trends use latest readings and leave unrecorded weeks empty',
      () {
    final weeks = weeklyBodyTrend([
      {'measured_at': '2026-10-12T09:00:00', 'weight_kg': 81, 'bmi': 25.0},
      {'measured_at': '2026-10-14T09:00:00', 'weight_kg': 80, 'bmi': 24.7},
      {'measured_at': '2026-10-25T09:00:00', 'weight_kg': 79, 'bmi': 24.4},
    ], DateTime(2026, 10, 25, 12));
    expect(weeks.length, 7);
    expect(weeks[5].weightKg, 80);
    expect(weeks[5].bmi, 24.7);
    expect(weeks[6].weightKg, 79);
    expect(weeks[4].weightKg, isNull);
    expect(weeks[4].bmi, isNull);
  });

  testWidgets('Weekly charts fit a narrow Body Metrics tab', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = FakeFitness();
    api.measurements.addAll([
      {
        'measured_at':
            DateTime.now().subtract(const Duration(days: 7)).toIso8601String(),
        'weight_kg': 80.0,
        'bmi': 24.7,
      },
      {
        'measured_at': DateTime.now().toIso8601String(),
        'weight_kg': 79.0,
        'bmi': 24.4,
      },
    ]);
    await tester.pumpWidget(
        MaterialApp(home: FitnessScreen(dashboard: const {}, dataSource: api)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Body Metrics').first);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Weekly Body Trends'), 140,
        scrollable: find.byType(Scrollable).last);
    expect(find.text('Weight (kg)'), findsOneWidget);
    expect(find.byType(LineChart), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Fitness activity entry updates the current tab', (tester) async {
    final api = FakeFitness();
    await tester.pumpWidget(
        MaterialApp(home: FitnessScreen(dashboard: const {}, dataSource: api)));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Log activity'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '1200');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(api.steps, 1200);
    expect(find.text('1200'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Weight update recalculates BMI; composition stays separate',
      (tester) async {
    final api = FakeFitness();
    await tester.pumpWidget(
        MaterialApp(home: FitnessScreen(dashboard: const {}, dataSource: api)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Body Metrics').first);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byTooltip('Update weight'), 150,
        scrollable: find.byType(Scrollable).last);
    await tester.tap(find.byTooltip('Update weight'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).last, '81');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(api.weight, 81);
    expect(find.text('81.0 kg'), findsWidgets);
    await tester.scrollUntilVisible(find.text('Weekly Body Trends'), 150,
        scrollable: find.byType(Scrollable).last);
    expect(find.text('Weight (kg)'), findsOneWidget);
    expect(find.text('BMI'), findsWidgets);
    await tester.tap(find.byTooltip('Record body composition'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '30');
    await tester.enterText(fields.at(1), '25');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(api.composition, [30, 25]);
    expect(api.weight, 81);
    expect(tester.takeException(), isNull);
  });
}
