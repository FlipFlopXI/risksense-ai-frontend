import 'package:intl/intl.dart';

/// Display only the persisted input snapshot of the selected prediction.
/// A null lab is missing, even if the trained model imputed it internally.
class PredictionInputDisplay {
  static List<(String, String)> rows(Map snapshot) {
    final features = snapshot['features'] is Map
        ? snapshot['features'] as Map
        : <String, dynamic>{};
    final sources = snapshot['sources'] is Map
        ? snapshot['sources'] as Map
        : <String, dynamic>{};
    Map source(String key) =>
        sources[key] is Map ? sources[key] as Map : <String, dynamic>{};
    String dated(String key) {
      final raw = source(key)['recorded_at'] ?? source(key)['updated_at'];
      final parsed = DateTime.tryParse(raw?.toString() ?? '');
      return parsed == null
          ? ''
          : ' · ${DateFormat.yMMMd().add_jm().format(parsed.toLocal())}';
    }

    String value(Object? raw, String unit) =>
        raw == null ? 'Not recorded' : '$raw $unit';
    final result = <(String, String)>[];
    if (features['age'] != null)
      result.add(('Age at analysis', value(features['age'], 'years')));
    if (features['sex'] != null)
      result
          .add(('Sex used by model', features['sex'] == 1 ? 'Male' : 'Female'));
    if (features['systolic_bp'] != null) {
      final diastolic = features['diastolic_bp'];
      result.add((
        'Blood pressure used',
        '${features['systolic_bp']}${diastolic == null ? '' : '/$diastolic'} mmHg${dated('systolic_bp')}'
      ));
    }
    if (features['bmi'] != null)
      result.add(('BMI used', '${features['bmi']} kg/m2${dated('bmi')}'));
    if (source('bmi')['height_cm'] != null)
      result.add(
          ('Height used for BMI', value(source('bmi')['height_cm'], 'cm')));
    if (source('bmi')['weight_kg'] != null)
      result.add(
          ('Weight used for BMI', value(source('bmi')['weight_kg'], 'kg')));
    if (features['waist_circumference'] != null)
      result.add((
        'Waist circumference used',
        '${features['waist_circumference']} cm${dated('waist_circumference')}'
      ));
    if (sources.containsKey('total_cholesterol')) {
      result.add((
        'Total cholesterol',
        source('total_cholesterol')['value'] == null
            ? 'Not entered for this analysis; model-imputed'
            : value(source('total_cholesterol')['value'], 'mg/dL')
      ));
    }
    if (sources.containsKey('fasting_glucose')) {
      result.add((
        'Fasting glucose',
        source('fasting_glucose')['value'] == null
            ? 'Not entered for this analysis; model-imputed'
            : value(source('fasting_glucose')['value'], 'mg/dL')
      ));
    }
    return result;
  }
}
