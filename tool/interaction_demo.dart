// Offline interaction demo for recording the current patient UI. Never used
// by the production app and never writes to the backend.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medguide/features/wellness/nutrition_data_source.dart';
import 'package:medguide/features/wellness/glucose_data_source.dart';
import 'package:medguide/features/wellness/fitness_data_source.dart';
import 'package:medguide/features/wellness/mindfulness_data_source.dart';
import 'package:medguide/screens/patient/patient_dashboard.dart';
import 'package:medguide/services/app_preferences.dart';
import 'package:medguide/theme/app_theme.dart';

class DemoNutrition implements NutritionDataSource {
  int waterGoal = 2000;
  final water = <Map<String, dynamic>>[];
  @override
  Future<Map<String, dynamic>> summary(String day) async => {
    'date': day, 'goal_kcal': null, 'calories_kcal': 0,
    'carbs_g': 0, 'fat_g': 0, 'protein_g': 0,
    'entries': <Map<String, dynamic>>[],
    'history': List.generate(7, (i) => {
      'date': DateTime.now().subtract(Duration(days: 6 - i)).toIso8601String(),
      'calories_kcal': 0,
    }),
  };
  @override
  Future<Map<String, dynamic>> waterSummary(String day) async => {
    'date': day, 'goal_ml': waterGoal,
    'total_ml': water.fold<int>(0, (sum, row) => sum + (row['amount_ml'] as int)),
    'entries': water,
    'history': List.generate(7, (i) => {
      'date': DateTime.now().subtract(Duration(days: 6 - i)).toIso8601String(),
      'amount_ml': i == 6 ? water.fold<int>(0, (sum, row) => sum + (row['amount_ml'] as int)) : 0,
    }),
  };
  @override
  Future<void> addWater(String day, int millilitres) async {
    water.insert(0, {'id': 'demo-water-${water.length}', 'amount_ml': millilitres,
      'created_at': DateTime.now().toUtc().toIso8601String()});
  }
  @override
  Future<void> saveWaterGoal(int millilitres) async { waterGoal = millilitres; }
  @override
  Future<void> saveGoal(int calories) async {}
  @override
  Future<void> addEntry(Map<String, dynamic> entry) async {}
  @override
  Future<void> deleteEntry(String id) async {}
  @override
  Future<List<Map<String, dynamic>>> previousFoods(String query) async => [];
  @override
  Future<List<Map<String, dynamic>>> searchCatalog(String query) async => [];
}

class DemoGlucose implements GlucoseDataSource {
  @override
  Future<Map<String, dynamic>> summary(String day) async =>
      {'date': day, 'entries': <Map<String, dynamic>>[]};
  @override
  Future<void> addEntry(Map<String, dynamic> entry) async {}
}

class DemoFitness implements FitnessDataSource {
  @override
  Future<Map<String, dynamic>> activity(String day) async => {
    'date': day,
    'today': {'steps': 0, 'activity_minutes': 0,
      'activity_calories_kcal': 0, 'distance_km': 0},
    'history': List.generate(7, (i) => {
      'date': DateTime.now().subtract(Duration(days: 6 - i)).toIso8601String(),
      'steps': 0, 'activity_minutes': 0,
      'activity_calories_kcal': 0, 'distance_km': 0,
    }),
  };
  @override
  Future<Map<String, dynamic>> body() async =>
      {'weight_kg': null, 'height_cm': null, 'bmi': null,
       'adult_bmi_reference_applicable': false, 'composition': null};
  @override
  Future<List<Map<String, dynamic>>> bodyTrends() async => [];
  @override
  Future<void> addActivity(Map<String, dynamic> entry) async {}
  @override
  Future<void> saveWeight(double kg) async {}
  @override
  Future<void> saveComposition(double muscleKg, double fatPercent) async {}
}

class DemoMindfulness implements MindfulnessDataSource {
  @override
  Future<Map<String, dynamic>> moodSummary(String day) async => {
    'date': day, 'latest': null, 'today_entries': <Map<String, dynamic>>[],
    'history': List.generate(7, (i) => {
      'date': DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(Duration(days: 6 - i))),
      'count': 0, 'average_score': null, 'average_mood': null,
    }),
  };
  @override
  Future<Map<String, dynamic>> breathingSummary(String day) async => {
    'history': List.generate(7, (i) => {
      'date': DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(Duration(days: 6 - i))),
      'count': 0, 'duration_seconds': 0,
    }),
  };
  @override
  Future<Map<String, dynamic>> meditationSummary(String day) async => {
    'history': List.generate(7, (i) => {
      'date': DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(Duration(days: 6 - i))),
      'count': 0, 'duration_seconds': 0,
    }),
  };
  @override
  Future<void> logMood(Map<String, dynamic> entry) async {}
  @override
  Future<void> logBreathing(Map<String, dynamic> entry) async {}
  @override
  Future<void> logMeditation(Map<String, dynamic> entry) async {}
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppPreferences.instance.setDarkMode(true);
  final now = DateTime.now().toUtc().toIso8601String();
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.lightTheme,
    home: PatientDashboard(
      previewNutrition: DemoNutrition(),
      previewGlucose: DemoGlucose(),
      previewFitness: DemoFitness(),
      previewMindfulness: DemoMindfulness(),
      previewData: {
        'patient_first_name': 'Demo Patient',
        'last_updated_at': now,
        '_vital_recorded_at': now,
        '_seen_prediction': 'demo-heart',
        '_notice_key': 'demo-only',
        'latest_predictions': [
          {'id': 'demo-diabetes', 'prediction_target': 'diabetes_risk',
            'risk_score': 0.24, 'risk_classification': 'Low', 'predicted_at': now},
          {'id': 'demo-heart', 'prediction_target': 'heart_disease',
            'risk_score': 0.31, 'risk_classification': 'Low', 'predicted_at': now},
        ],
        'drug_response_enquiries_today': 3,
        'bmi': 24.3,
        'latest_systolic_bp': 118,
        'latest_diastolic_bp': 76,
        'latest_glucose': 5.2,
        'latest_glucose_unit': 'mmol/L',
        'prediction_count': 6,
      },
    ),
  ));
}
