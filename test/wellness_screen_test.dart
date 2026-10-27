import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medguide/features/wellness/wellness_screen.dart';
import 'package:medguide/features/wellness/fitness_screen.dart';
import 'package:medguide/features/wellness/nutrition_screen.dart';

void main() {
  final dashboard = <String, dynamic>{
    'latest_predictions': [
      {
        'prediction_target': 'diabetes_risk',
        'risk_score': .50,
        'risk_classification': 'standard',
        'predicted_at': '2026-09-23T10:00:00Z',
        'contributing_factors': <Map<String, dynamic>>[],
      },
      {
        'prediction_target': 'heart_disease',
        'risk_score': .20,
        'risk_classification': 'not_elevated',
        'predicted_at': '2026-09-23T10:00:00Z',
        'contributing_factors': <Map<String, dynamic>>[],
      },
    ],
  };

  for (final screen in [
    MealPlanScreen(dashboard: dashboard),
    FitnessRoutineScreen(dashboard: dashboard),
  ]) {
    testWidgets(
        '${screen.runtimeType} renders on narrow devices with PDF action',
        (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => screen)),
          child: const Text('Open'),
        ),
      ))));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Glucose-aware'), findsOneWidget);
      expect(find.text('Generate PDF'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Nutrition and Fitness landing screens keep plan actions',
      (tester) async {
    await tester
        .pumpWidget(MaterialApp(home: FitnessScreen(dashboard: dashboard)));
    expect(find.text('Generate Fitness Routine'), findsOneWidget);
    await tester
        .pumpWidget(MaterialApp(home: NutritionScreen(dashboard: dashboard)));
    await tester.pump();
    expect(find.text('Generate Meal Plan'), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);
    expect(find.text('Water'), findsOneWidget);
  });
}
