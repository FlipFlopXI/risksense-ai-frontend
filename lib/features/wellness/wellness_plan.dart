import 'package:intl/intl.dart';

enum WellnessKind { meal, fitness }

class PlanSection {
  final String title;
  final String guidance;
  const PlanSection(this.title, this.guidance);
}

class WellnessPlan {
  final WellnessKind kind;
  final String title;
  final String focus;
  final String rationale;
  final List<PlanSection> sections;
  final List<String> considerations;
  final double? diabetesScore;
  final double? heartScore;
  final DateTime? diabetesAt;
  final DateTime? heartAt;
  final String sourceSummary;

  const WellnessPlan({
    required this.kind,
    required this.title,
    required this.focus,
    required this.rationale,
    required this.sections,
    required this.considerations,
    required this.diabetesScore,
    required this.heartScore,
    required this.diabetesAt,
    required this.heartAt,
    required this.sourceSummary,
  });

  String get disclaimer => kind == WellnessKind.meal
      ? 'Educational food guidance only. This is not an individualized diet or treatment plan. Ask a clinician or registered dietitian about allergies, medicines, pregnancy, kidney disease, and other needs.'
      : 'Educational activity guidance only. A model score cannot establish exercise safety. Ask a clinician before increasing activity if you have symptoms, known disease, or medical restrictions. Stop if you develop chest pain, dizziness, or unusual breathlessness.';

  String get fileName => kind == WellnessKind.meal
      ? 'risksense-meal-guidance.pdf'
      : 'risksense-fitness-guidance.pdf';

  static WellnessPlan fromDashboard(
    WellnessKind kind,
    Map<String, dynamic> dashboard,
  ) {
    final predictions = (dashboard['latest_predictions'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    Map<String, dynamic>? find(String target) {
      for (final item in predictions) {
        if (item['prediction_target'] == target) return item;
      }
      return null;
    }

    final diabetes = find('diabetes_risk');
    final heart = find('heart_disease');
    final d = (diabetes?['risk_score'] as num?)?.toDouble();
    final h = (heart?['risk_score'] as num?)?.toDouble();
    final dElevated = diabetes?['risk_classification'] == 'elevated';
    final hElevated = heart?['risk_classification'] == 'elevated';
    final dAt = DateTime.tryParse(diabetes?['predicted_at']?.toString() ?? '')
        ?.toLocal();
    final hAt =
        DateTime.tryParse(heart?['predicted_at']?.toString() ?? '')?.toLocal();
    final diabetesFactors = _raisingFactors(diabetes);
    final heartFactors = _raisingFactors(heart);
    final focus = _focus(d, h, dElevated, hElevated);
    final hasBoth = d != null && h != null;
    final summary = hasBoth
        ? 'Uses your latest diabetes and heart-disease model results.'
        : d != null || h != null
            ? 'Only one model result is available; the other is not assumed.'
            : 'No saved risk analysis is available; this is general wellness information.';
    final considerations = <String>[];
    if (diabetesFactors.contains('bmi') ||
        diabetesFactors.contains('waist_circumference')) {
      considerations.add(
        'Body-size measures contributed to the diabetes model score. Balanced portions and regular activity are general options; the model does not prescribe a weight target.',
      );
    }
    if (diabetesFactors.contains('systolic_bp') ||
        diabetesFactors.contains('diastolic_bp') ||
        heartFactors.contains('systolic_bp')) {
      considerations.add(
        'Blood pressure contributed to a model score. Check packaged-food sodium and discuss recorded pressure readings with your clinician.',
      );
    }
    if (heartFactors.contains('total_cholesterol')) {
      considerations.add(
        'Total cholesterol contributed to the heart model score. Favour unsaturated fats and fibre-rich food categories; review actual lipid results with a clinician.',
      );
    }
    if (heartFactors.contains('fasting_blood_sugar_high')) {
      considerations.add(
        'The fasting-glucose category contributed to the heart model score. Spread quality carbohydrate foods across meals and review the measured result with a clinician.',
      );
    }
    if (considerations.isEmpty) {
      considerations.add(
        'No directly actionable score-raising contributor was available. Model contributions are statistical and do not establish clinical causes.',
      );
    }
    final sections = kind == WellnessKind.meal
        ? _mealSections(focus, dElevated, hElevated)
        : _fitnessSections(focus, dElevated, hElevated);
    return WellnessPlan(
      kind: kind,
      title: kind == WellnessKind.meal ? 'Meal Plan' : 'Fitness Routine',
      focus: focus,
      rationale: summary,
      sections: sections,
      considerations: considerations,
      diabetesScore: d,
      heartScore: h,
      diabetesAt: dAt,
      heartAt: hAt,
      sourceSummary: kind == WellnessKind.meal
          ? 'Framework: American Diabetes Association Diabetes Plate; American Heart Association healthy eating guidance.'
          : 'Framework: World Health Organization adult physical activity guidance.',
    );
  }

  String scoreLabel(double? score, DateTime? at) => score == null
      ? 'No saved analysis'
      : '${(score * 100).toStringAsFixed(1)}% · ${at == null ? 'Date unavailable' : DateFormat.yMMMd().format(at)}';

  static Set<String> _raisingFactors(Map<String, dynamic>? prediction) {
    final factors = (prediction?['contributing_factors'] as List? ?? const [])
        .whereType<Map>()
        .where((factor) => factor['direction'] == 'raises')
        .toList()
      ..sort((a, b) => ((b['relative_magnitude'] as num?)?.toDouble() ?? 0)
          .compareTo((a['relative_magnitude'] as num?)?.toDouble() ?? 0));
    return factors
        .take(3)
        .map((factor) => factor['feature'].toString())
        .toSet();
  }

  static String _focus(double? d, double? h, bool dElevated, bool hElevated) {
    if (d == null && h == null) return 'General wellness';
    if (d == null) return 'Heart-aware';
    if (h == null) return 'Glucose-aware';
    if (dElevated && hElevated) return 'Combined cardiometabolic';
    if (dElevated) return 'Glucose-aware';
    if (hElevated) return 'Heart-aware';
    if (d > h + 0.15) return 'Glucose-aware';
    if (h > d + 0.15) return 'Heart-aware';
    return 'Balanced prevention';
  }

  static List<PlanSection> _mealSections(
    String focus,
    bool dElevated,
    bool hElevated,
  ) {
    final plate = switch (focus) {
      'Glucose-aware' =>
        'Use a simple plate pattern: about half non-starchy vegetables, one quarter lean protein, and one quarter quality carbohydrate foods. Keep carbohydrate portions consistent rather than eliminating them.',
      'Heart-aware' =>
        'Build meals around vegetables, fruit, whole grains and lean protein categories. Choose unsaturated fats more often and compare packaged foods for sodium and saturated fat.',
      'Combined cardiometabolic' =>
        'Use the balanced plate pattern: about half non-starchy vegetables, one quarter lean protein, and one quarter quality carbohydrate foods. Also favour unsaturated fats and lower-sodium choices.',
      _ =>
        'Build a varied plate from vegetables or fruit, whole grains or other quality carbohydrates, and a lean protein category. Adjust portions with a qualified professional if needed.',
    };
    final rhythm = dElevated
        ? 'Aim for regular meals with a consistent balance of carbohydrate, protein and fibre. Avoid making large changes if you use glucose-lowering medication without clinical advice.'
        : 'Plan a regular eating pattern that fits your appetite, schedule and preferences. Avoid rigid calorie targets based on a model score.';
    final heartNote = hElevated
        ? 'For snacks and drinks, favour minimally processed options and water or unsweetened drinks. Check sodium and saturated fat when choosing packaged foods.'
        : 'For snacks and drinks, favour minimally processed options and water or unsweetened drinks when practical.';
    return [
      PlanSection('Everyday plate', plate),
      const PlanSection('Breakfast approach',
          'Combine a fibre-rich carbohydrate category with a protein source and fruit or vegetables. Choose portions that suit your appetite and clinical advice.'),
      const PlanSection('Midday meal approach',
          'Start with vegetables, add a lean or plant protein category, and include a quality carbohydrate portion. Use an unsaturated-fat option where suitable.'),
      const PlanSection('Evening meal approach',
          'Repeat the balanced plate structure and vary food groups across the day. Choose cooking methods that use less added salt and saturated fat.'),
      PlanSection('Meal rhythm', rhythm),
      PlanSection('Snacks and drinks', heartNote),
    ];
  }

  static List<PlanSection> _fitnessSections(
    String focus,
    bool dElevated,
    bool hElevated,
  ) {
    final start = hElevated
        ? 'Start with comfortable, low-impact movement only if it is safe for you. Ask a clinician before vigorous exercise or a substantial increase in activity, especially with symptoms or known heart disease.'
        : 'Begin with comfortable walking or another accessible low-impact activity. Increase time gradually according to tolerance.';
    final weekly = dElevated
        ? 'Across the week, spread moderate movement over multiple days and break up long sitting periods. A short walk after a meal may be an approachable option if safe for you.'
        : 'Across the week, spread moderate movement over multiple days and break up long sitting periods.';
    return [
      PlanSection('Start safely', start),
      PlanSection('Aerobic activity', weekly),
      const PlanSection('Strength and balance',
          'On two or more days each week, include comfortable muscle-strengthening activity for major muscle groups. Add balance work if appropriate to your mobility.'),
      const PlanSection('Weekly progression',
          'Build gradually toward the general adult guideline of 150–300 minutes of moderate activity per week if your clinician agrees it is suitable. Any safe activity is a useful starting point.'),
      PlanSection('Recovery and check-in',
          'Include easier days and notice how you feel. ${focus == 'Combined cardiometabolic' ? 'Discuss both model results and your exercise plans with your clinician.' : 'Review new symptoms or medical restrictions with a clinician.'}'),
    ];
  }
}
