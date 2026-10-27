import 'package:flutter/material.dart';
import 'package:medguide/widgets/screen_help.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:medguide/theme/app_theme.dart';
import 'package:medguide/widgets/shared_widgets.dart';
import 'package:medguide/services/clinician_pdf.dart';
import 'package:medguide/services/risk_report_pdf.dart';
import 'package:medguide/services/api_client.dart';

class PredictionResultScreen extends StatefulWidget {
  final String condition;
  final double riskScore;
  final String? riskClassification;
  final String? interpretation;
  final List<Map<String, dynamic>> contributingFactors;
  final bool clinicianMode;
  final String? predictionId;
  final Future<void> Function(BuildContext, String)? reportOpener;

  const PredictionResultScreen({
    super.key,
    required this.condition,
    required this.riskScore,
    this.riskClassification,
    this.interpretation,
    this.contributingFactors = const [],
    this.clinicianMode = false,
    this.predictionId,
    this.reportOpener,
  });

  @override
  State<PredictionResultScreen> createState() => _PredictionResultScreenState();
}

class _PredictionResultScreenState extends State<PredictionResultScreen>
    with SingleTickerProviderStateMixin {
  bool _isAnalyzing = true;
  bool _exporting = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(_pulseController);

    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => _isAnalyzing = false);
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Color get _riskColor => widget.riskClassification == 'elevated'
      ? AppColors.riskHigh
      : AppColors.riskLow;

  String get _riskLabel => widget.riskClassification == 'elevated'
      ? 'ELEVATED MODEL SCORE'
      : 'BELOW MODEL THRESHOLD';

  static const _featureLabels = <String, String>{
    'age': 'Age',
    'sex': 'Sex',
    'bmi': 'BMI',
    'waist_circumference': 'Waist circumference',
    'systolic_bp': 'Systolic blood pressure',
    'diastolic_bp': 'Diastolic blood pressure',
    'total_cholesterol': 'Total cholesterol',
    'fasting_blood_sugar_high': 'Fasting glucose category',
  };

  Future<void> _exportReport() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      if (widget.clinicianMode) {
        await ClinicianPdf.export(
          context,
          title: '${widget.condition} demonstration assessment',
          lines: [
            'Estimated model score: ${(widget.riskScore * 100).toStringAsFixed(1)}%',
            'Classification: ${widget.riskClassification ?? 'Unavailable'}',
            widget.interpretation ?? 'No interpretation available.',
            ...widget.contributingFactors.map((factor) =>
                '${factor['feature']}: ${factor['direction']} score'),
            'This assessment was not saved to a patient record.',
          ],
        );
      } else {
        final id = widget.predictionId;
        if (id == null || id.isEmpty) return;
        await (widget.reportOpener ?? RiskReportPdf.open)(context, id);
      }
    } catch (error) {
      if (!mounted) return;
      await showDialog<void>(
          context: context,
          builder: (dialog) => AlertDialog(
                title: const Text('PDF Unavailable'),
                content: Text(error is ApiException
                    ? error.message
                    : 'The report could not be opened. Please try again.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(dialog),
                      child: const Text('Dismiss')),
                ],
              ));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Widget _factorBar(Map<String, dynamic> factor) {
    final feature = factor['feature']?.toString() ?? '';
    final direction = factor['direction']?.toString() ?? 'neutral';
    final magnitude = (factor['relative_magnitude'] as num?)?.toDouble() ?? 0;
    final color = direction == 'raises'
        ? AppColors.amber
        : direction == 'lowers'
            ? AppColors.teal
            : AppColors.primaryBlue;
    return FeatureImpactBar(
      feature: _featureLabels[feature] ?? feature,
      impact: direction == 'raises'
          ? 'Raises score'
          : direction == 'lowers'
              ? 'Lowers score'
              : 'Neutral',
      percent: magnitude.clamp(0.0, 1.0),
      color: color,
    );
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardWhite,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: AppColors.primaryBlue),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('${widget.condition} Analysis',
            style: Theme.of(context).textTheme.headlineMedium),
        actions: const [
          ScreenHelpButton(topic: 'Prediction Result'),
          SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: _isAnalyzing ? _buildLoading() : _buildResult(context),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (context, child) =>
                Transform.scale(scale: _pulseAnim.value, child: child),
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.surfaceBlue,
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.primaryBlue.withValues(alpha: 0.3),
                    width: 2),
              ),
              child: Icon(Icons.shield_outlined,
                  size: 44, color: AppColors.primaryBlue),
            ),
          ),
          const SizedBox(height: 28),
          Text('Analyzing Clinical Profile…',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text('Processing your health data securely',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 32),
          SizedBox(
            width: 180,
            child: LinearProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
              backgroundColor: AppColors.border,
              minHeight: 3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResult(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Big risk score card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _riskColor.withValues(alpha: 0.08),
                  _riskColor.withValues(alpha: 0.03),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _riskColor.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                CircularPercentIndicator(
                  radius: 72,
                  lineWidth: 10,
                  animation: true,
                  animationDuration: 1500,
                  percent: widget.riskScore,
                  center: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${(widget.riskScore * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: _riskColor,
                        ),
                      ),
                      Text('Risk Score',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                  circularStrokeCap: CircularStrokeCap.round,
                  progressColor: _riskColor,
                  backgroundColor: _riskColor.withValues(alpha: 0.1),
                ),
                const SizedBox(height: 16),
                Text('${widget.condition} Risk',
                    style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: 12),
                RiskBadge(label: _riskLabel, color: _riskColor),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Contributing factors
          Container(
            padding: const EdgeInsets.all(20),
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
                    Icon(Icons.bar_chart_rounded,
                        size: 18, color: AppColors.primaryBlue),
                    const SizedBox(width: 8),
                    Text('Primary Contributing Factors',
                        style: Theme.of(context).textTheme.headlineSmall),
                  ],
                ),
                const SizedBox(height: 16),
                if (widget.contributingFactors.isEmpty)
                  Text(
                      'Feature contributions are unavailable for this analysis.',
                      style: TextStyle(color: AppColors.textSecondary))
                else ...[
                  Text(
                      'Relative contributions to this model score, not clinical effects.',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 10),
                  ...widget.contributingFactors.map(_factorBar),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Interpretation
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceBlue,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: AppColors.primaryBlue.withValues(alpha: 0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.psychology_outlined,
                        size: 18, color: AppColors.primaryBlue),
                    const SizedBox(width: 8),
                    Text('AI Interpretation',
                        style: Theme.of(context).textTheme.headlineSmall),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  widget.interpretation ??
                      'This analysis does not include a feature-level interpretation.',
                  style: TextStyle(
                    fontSize: 14,
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

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
              label:
                  Text(_exporting ? 'Preparing PDF...' : 'Generate PDF Report'),
              onPressed: _exporting ||
                      (!widget.clinicianMode &&
                          (widget.predictionId == null ||
                              widget.predictionId!.isEmpty))
                  ? null
                  : _exportReport,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
