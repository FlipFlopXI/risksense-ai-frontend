import 'package:flutter/material.dart';
import 'package:medguide/theme/app_theme.dart';
import 'package:medguide/widgets/shared_widgets.dart';
import 'package:medguide/widgets/screen_help.dart';
import 'package:medguide/screens/shared/prediction_result_screen.dart';

class PatientDetailScreen extends StatelessWidget {
  final Map<String, dynamic> patient;

  const PatientDetailScreen({super.key, required this.patient});

  Color get _levelColor {
    switch (patient['riskLevel']) {
      case 'High':
        return AppColors.riskHigh;
      case 'Moderate':
        return AppColors.riskMedium;
      default:
        return AppColors.riskLow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: AppColors.primaryBlue),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(patient['name'],
            style: Theme.of(context).textTheme.headlineMedium),
        actions: const [
          SecureBadge(),
          ScreenHelpButton(topic: 'Patient Detail'),
          SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryBlue,
                    AppColors.primaryBlue.withBlue(130),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        (patient['name'] as String).substring(0, 1),
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          patient['name'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Age ${patient['age']} • ${patient['id']}',
                          style: const TextStyle(
                              fontSize: 13, color: Colors.white70),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _levelColor.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(20),
                            border:
                                Border.all(color: _levelColor.withOpacity(0.5)),
                          ),
                          child: Text(
                            '${patient['riskLevel']} Risk',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            _section(
                context, 'Patient Demographics', Icons.person_outline_rounded, [
              const InfoRow(label: 'Patient ID', value: 'PT-00421'),
              const InfoRow(label: 'Date of Birth', value: 'Mar 14, 1983'),
              const InfoRow(label: 'Gender', value: 'Female'),
              const InfoRow(label: 'Last Visit', value: 'Feb 19, 2026'),
              const InfoRow(label: 'Attending Clinician', value: 'Dr. J. Osei'),
            ]),
            const SizedBox(height: 14),

            _section(context, 'Clinical Data', Icons.monitor_heart_outlined, [
              const InfoRow(label: 'Blood Glucose', value: '142 mg/dL'),
              const InfoRow(label: 'HbA1c', value: '6.4%'),
              const InfoRow(label: 'BMI', value: '27.4'),
              const InfoRow(label: 'Blood Pressure', value: '128/82 mmHg'),
              const InfoRow(label: 'Heart Rate', value: '74 bpm'),
              const InfoRow(label: 'LDL Cholesterol', value: '110 mg/dL'),
              const InfoRow(label: 'HDL Cholesterol', value: '48 mg/dL'),
              const InfoRow(label: 'Creatinine', value: '0.9 mg/dL'),
            ]),
            const SizedBox(height: 14),

            _section(context, 'Risk Predictions', Icons.analytics_outlined, [
              _riskRow('Diabetes Risk', 0.72, 'High'),
              const SizedBox(height: 8),
              _riskRow('Heart Disease Risk', 0.41, 'Moderate'),
              const SizedBox(height: 8),
              _riskRow('Drug Response Risk', 0.18, 'Low'),
            ]),
            const SizedBox(height: 14),

            // SHAP Chart
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.bar_chart_rounded,
                          size: 18, color: AppColors.primaryBlue),
                      const SizedBox(width: 8),
                      Text('SHAP Feature Importance',
                          style: Theme.of(context).textTheme.headlineSmall),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text('Top 5 contributing factors — Diabetes Risk',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 16),
                  const FeatureImpactBar(
                    feature: 'Blood Glucose Level',
                    impact: 'High',
                    percent: 0.87,
                    color: AppColors.danger,
                  ),
                  const FeatureImpactBar(
                    feature: 'BMI',
                    impact: 'Moderate',
                    percent: 0.58,
                    color: AppColors.amber,
                  ),
                  const FeatureImpactBar(
                    feature: 'Age',
                    impact: 'Low',
                    percent: 0.31,
                    color: AppColors.primaryBlue,
                  ),
                  const FeatureImpactBar(
                    feature: 'Family History',
                    impact: 'Low',
                    percent: 0.24,
                    color: AppColors.teal,
                  ),
                  const FeatureImpactBar(
                    feature: 'Physical Activity',
                    impact: 'Low',
                    percent: 0.17,
                    color: AppColors.success,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Recommendation
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surfaceTeal,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.teal.withOpacity(0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.recommend_outlined,
                          size: 18, color: AppColors.teal),
                      const SizedBox(width: 8),
                      Text('Clinical Recommendation',
                          style: Theme.of(context).textTheme.headlineSmall),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Patient presents with pre-diabetic indicators. Recommend:\n\n'
                    '• Fasting plasma glucose test to confirm status\n'
                    '• HbA1c monitoring every 3 months\n'
                    '• Dietary counselling and lifestyle modification\n'
                    '• Consider Metformin if lifestyle changes insufficient\n'
                    '• Blood pressure management protocol',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            const DisclaimerBanner(),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                      label: const Text('PDF Report'),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Generating report...'),
                            backgroundColor: AppColors.primaryBlue,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Re-analyse'),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const PredictionResultScreen(
                              condition: 'Diabetes', riskScore: 0.72),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _section(BuildContext context, String title, IconData icon,
      List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primaryBlue),
              const SizedBox(width: 8),
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _riskRow(String label, double score, String level) {
    Color c;
    switch (level) {
      case 'High':
        c = AppColors.riskHigh;
        break;
      case 'Moderate':
        c = AppColors.riskMedium;
        break;
      default:
        c = AppColors.riskLow;
    }
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  )),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: score,
                  minHeight: 7,
                  backgroundColor: c.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(c),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Text('${(score * 100).toInt()}%',
            style:
                TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: c.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(level,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: c)),
        ),
      ],
    );
  }
}
