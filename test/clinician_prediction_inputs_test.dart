import 'package:flutter_test/flutter_test.dart';
import 'package:medguide/services/prediction_input_display.dart';

void main() {
  test('diabetes snapshot shows recorded BP and profile measurements', () {
    final rows = PredictionInputDisplay.rows({
      'features': {
        'age': 51,
        'sex': 0,
        'bmi': 25.2,
        'waist_circumference': 83,
        'systolic_bp': 126,
        'diastolic_bp': 78
      },
      'sources': {
        'bmi': {
          'height_cm': 170,
          'weight_kg': 73,
          'updated_at': '2026-10-28T10:00:00Z'
        },
        'systolic_bp': {'recorded_at': '2026-10-29T08:00:00Z'},
        'waist_circumference': {'updated_at': '2026-10-28T10:00:00Z'},
      },
    });
    expect(rows.first, ('Age at analysis', '51 years'));
    expect(
        rows.any((row) =>
            row.$1 == 'Blood pressure used' && row.$2.contains('126/78 mmHg')),
        isTrue);
    expect(
        rows.any(
            (row) => row.$1 == 'Height used for BMI' && row.$2 == '170 cm'),
        isTrue);
    expect(
        rows.any((row) => row.$1 == 'Weight used for BMI' && row.$2 == '73 kg'),
        isTrue);
  });

  test('heart snapshot distinguishes missing labs from measured values', () {
    final rows = PredictionInputDisplay.rows({
      'features': {
        'age': 60,
        'sex': 1,
        'systolic_bp': 141,
        'total_cholesterol': null,
        'fasting_blood_sugar_high': 1
      },
      'sources': {
        'systolic_bp': {'recorded_at': '2026-10-29T08:00:00Z'},
        'total_cholesterol': {'source': 'missing; training_median_imputed'},
        'fasting_glucose': {
          'source': 'analysis_request',
          'value': 132,
          'unit': 'mg/dL'
        },
      },
    });
    expect(
        rows.any((row) =>
            row.$1 == 'Blood pressure used' && row.$2.contains('141 mmHg')),
        isTrue);
    expect(rows.singleWhere((row) => row.$1 == 'Total cholesterol').$2,
        'Not entered for this analysis; model-imputed');
    expect(
        rows.singleWhere((row) => row.$1 == 'Fasting glucose').$2, '132 mg/dL');
  });
}
