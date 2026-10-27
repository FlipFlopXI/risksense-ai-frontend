import 'package:flutter/material.dart';
import 'package:medguide/screens/patient/patient_dashboard.dart';
import 'package:medguide/services/app_preferences.dart';
import 'package:medguide/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppPreferences.instance.setDarkMode(true);
  final now = DateTime.now().toUtc().toIso8601String();
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.lightTheme,
    home: PatientDashboard(previewData: <String, dynamic>{
      'patient_first_name': 'Demo Patient',
      'last_updated_at': now,
      '_vital_recorded_at': now,
      '_seen_prediction': 'demo-heart',
      '_notice_key': 'demo-only',
      'latest_predictions': [
        {'id': 'demo-diabetes', 'prediction_target': 'diabetes_risk', 'risk_score': 0.24, 'risk_classification': 'Low', 'predicted_at': now},
        {'id': 'demo-heart', 'prediction_target': 'heart_disease', 'risk_score': 0.31, 'risk_classification': 'Low', 'predicted_at': now},
      ],
      'drug_response_enquiries_today': 3,
      'bmi': 24.3,
      'latest_systolic_bp': 118,
      'latest_diastolic_bp': 76,
      'latest_glucose': 5.2,
      'latest_glucose_unit': 'mmol/L',
      'prediction_count': 6,
    }),
  ));
}
