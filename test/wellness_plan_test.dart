import 'package:flutter_test/flutter_test.dart';
import 'package:medguide/features/wellness/wellness_plan.dart';

Map<String, dynamic> result(String target, double score, String classification,
        {List<Map<String, dynamic>> factors = const []}) =>
    {
      'prediction_target': target,
      'risk_score': score,
      'risk_classification': classification,
      'predicted_at': '2026-09-23T10:00:00Z',
      'contributing_factors': factors,
    };

void main() {
  test('50% diabetes and 20% heart score selects glucose-aware meal guidance',
      () {
    final plan = WellnessPlan.fromDashboard(WellnessKind.meal, {
      'latest_predictions': [
        result('diabetes_risk', .50, 'standard'),
        result('heart_disease', .20, 'not_elevated'),
      ],
    });
    expect(plan.focus, 'Glucose-aware');
    expect(plan.diabetesScore, .50);
    expect(plan.heartScore, .20);
    expect(plan.sections.length, 6);
    expect(plan.sections.first.guidance, contains('quality carbohydrate'));
  });

  test('both elevated results select combined guidance', () {
    final plan = WellnessPlan.fromDashboard(WellnessKind.fitness, {
      'latest_predictions': [
        result('diabetes_risk', .75, 'elevated'),
        result('heart_disease', .60, 'elevated'),
      ],
    });
    expect(plan.focus, 'Combined cardiometabolic');
    expect(plan.sections.first.guidance, contains('Ask a clinician'));
  });

  test('missing risk results are not invented', () {
    final plan = WellnessPlan.fromDashboard(WellnessKind.meal, {
      'latest_predictions': [result('heart_disease', .30, 'not_elevated')],
    });
    expect(plan.diabetesScore, isNull);
    expect(plan.scoreLabel(plan.diabetesScore, plan.diabetesAt),
        'No saved analysis');
    expect(plan.rationale, contains('Only one model result'));
  });

  test('only score-raising relevant factors add discussion context', () {
    final plan = WellnessPlan.fromDashboard(WellnessKind.meal, {
      'latest_predictions': [
        result('diabetes_risk', .55, 'elevated', factors: [
          {'feature': 'bmi', 'direction': 'raises', 'relative_magnitude': .6},
          {'feature': 'age', 'direction': 'lowers', 'relative_magnitude': .4},
        ]),
        result('heart_disease', .40, 'not_elevated', factors: [
          {
            'feature': 'total_cholesterol',
            'direction': 'raises',
            'relative_magnitude': .5
          },
        ]),
      ],
    });
    expect(plan.considerations.join(' '), contains('Body-size measures'));
    expect(plan.considerations.join(' '), contains('Total cholesterol'));
    expect(plan.considerations.join(' '), isNot(contains('Age')));
  });
}
