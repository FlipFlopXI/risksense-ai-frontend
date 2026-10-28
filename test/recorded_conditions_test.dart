import 'package:flutter_test/flutter_test.dart';
import 'package:medguide/services/recorded_conditions.dart';

void main() {
  test('recognizes only exact patient-reported diagnosis entries', () {
    final conditions = RecordedConditions.fromText(
        'Diabetes (patient-reported diagnosis); Heart disease '
        '(patient-reported diagnosis); Asthma');
    expect(conditions.diabetes, isTrue);
    expect(conditions.heartDisease, isTrue);
    expect(conditions.other, 'Asthma');
    expect(conditions.hasDiagnosisFor('diabetes'), isTrue);
    expect(conditions.hasDiagnosisFor('heart_disease'), isTrue);
    expect(
        conditions.toProfileText(),
        'Diabetes (patient-reported diagnosis); Heart disease '
        '(patient-reported diagnosis); Asthma');
  });

  test('family history and hypothetical statements are not diagnoses', () {
    final conditions = RecordedConditions.fromText(
        'Family history of diabetes; worried about heart disease');
    expect(conditions.diabetes, isFalse);
    expect(conditions.heartDisease, isFalse);
    expect(conditions.other,
        'Family history of diabetes; worried about heart disease');
  });

  test('recognizes exact conditions in a legacy comma-separated list', () {
    final conditions = RecordedConditions.fromText('Type 2 Diabetes, Asthma');
    expect(conditions.diabetes, isTrue);
    expect(conditions.other, 'Asthma');
  });

  test('clearing all conditions produces a null profile value', () {
    expect(const RecordedConditions().toProfileText(), isNull);
  });
}
