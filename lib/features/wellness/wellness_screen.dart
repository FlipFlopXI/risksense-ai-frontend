import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medguide/features/wellness/wellness_plan.dart';
import 'package:medguide/theme/app_theme.dart';
import 'package:medguide/widgets/screen_help.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class MealPlanScreen extends StatelessWidget {
  final Map<String, dynamic> dashboard;
  const MealPlanScreen({super.key, required this.dashboard});

  @override
  Widget build(BuildContext context) => _WellnessScreen(
        plan: WellnessPlan.fromDashboard(WellnessKind.meal, dashboard),
      );
}

class FitnessRoutineScreen extends StatelessWidget {
  final Map<String, dynamic> dashboard;
  const FitnessRoutineScreen({super.key, required this.dashboard});

  @override
  Widget build(BuildContext context) => _WellnessScreen(
        plan: WellnessPlan.fromDashboard(WellnessKind.fitness, dashboard),
      );
}

class _WellnessScreen extends StatefulWidget {
  final WellnessPlan plan;
  const _WellnessScreen({required this.plan});

  @override
  State<_WellnessScreen> createState() => _WellnessScreenState();
}

class _WellnessScreenState extends State<_WellnessScreen> {
  bool _exporting = false;

  Future<void> _sharePdf() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      final plan = widget.plan;
      final pdf = pw.Document();
      final navy = PdfColor.fromHex('#0A3D62');
      final blue = PdfColor.fromHex('#E9F5FC');
      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (_) => [
          pw.Container(
            padding: const pw.EdgeInsets.all(18),
            color: blue,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('RiskSense AI',
                    style: pw.TextStyle(
                        color: navy,
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.Text(plan.title,
                    style: pw.TextStyle(
                        fontSize: 17, fontWeight: pw.FontWeight.bold)),
                pw.Text(
                    '${plan.focus} | Generated ${DateFormat.yMMMd().format(DateTime.now())}'),
              ],
            ),
          ),
          pw.SizedBox(height: 18),
          pw.Text(plan.rationale),
          pw.SizedBox(height: 8),
          pw.Text(
              'Latest diabetes analysis: ${plan.scoreLabel(plan.diabetesScore, plan.diabetesAt)}'),
          pw.Text(
              'Latest heart analysis: ${plan.scoreLabel(plan.heartScore, plan.heartAt)}'),
          pw.SizedBox(height: 18),
          for (final section in plan.sections) ...[
            pw.Text(section.title,
                style: pw.TextStyle(
                    color: navy, fontSize: 13, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text(section.guidance),
            pw.SizedBox(height: 12),
          ],
          pw.Text('Factors to discuss',
              style: pw.TextStyle(
                  color: navy, fontSize: 13, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 5),
          for (final item in plan.considerations)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 5),
              child: pw.Text('• $item'),
            ),
          pw.SizedBox(height: 14),
          pw.Text(plan.sourceSummary, style: const pw.TextStyle(fontSize: 9)),
          pw.SizedBox(height: 10),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            color: PdfColor.fromHex('#FFF2DD'),
            child: pw.Text(plan.disclaimer,
                style: const pw.TextStyle(fontSize: 9)),
          ),
        ],
      ));
      await Printing.sharePdf(bytes: await pdf.save(), filename: plan.fileName);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('The PDF could not be generated. Please try again.'),
        ));
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    final isMeal = plan.kind == WellnessKind.meal;
    final accent = isMeal ? AppColors.teal : AppColors.primaryBlue;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(plan.title),
        actions: [
          ScreenHelpButton(topic: isMeal ? 'Meal Plan' : 'Fitness Routine'),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [accent, AppColors.primaryBlue],
                        ),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                              isMeal
                                  ? Icons.restaurant_menu_rounded
                                  : Icons.directions_run_rounded,
                              color: Colors.white,
                              size: 30),
                          const SizedBox(height: 14),
                          Text(plan.focus,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 7),
                          Text(plan.rationale,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  height: 1.5)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(children: [
                      Expanded(
                          child: _scoreTile(
                              'Diabetes',
                              plan.scoreLabel(
                                  plan.diabetesScore, plan.diabetesAt),
                              Icons.bloodtype_outlined,
                              AppColors.teal)),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _scoreTile(
                              'Heart disease',
                              plan.scoreLabel(plan.heartScore, plan.heartAt),
                              Icons.favorite_outline_rounded,
                              AppColors.danger)),
                    ]),
                    const SizedBox(height: 20),
                    Text(
                        isMeal
                            ? 'Your meal framework'
                            : 'Your activity framework',
                        style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 5),
                    Text(
                        isMeal
                            ? 'Flexible food-group guidance. No fixed ingredients, calories, or medicine changes.'
                            : 'A gradual routine to discuss with your care team. No exercise intensity is inferred from a risk score.',
                        style: const TextStyle(
                            color: AppColors.textSecondary, height: 1.45)),
                    const SizedBox(height: 14),
                    for (var i = 0; i < plan.sections.length; i++) ...[
                      _sectionCard(plan.sections[i], i, accent, isMeal),
                      const SizedBox(height: 10),
                    ],
                    const SizedBox(height: 12),
                    Text('Factors to discuss',
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 5),
                    const Text(
                        'Model contributions guide which topics appear here; they are not clinical causes.',
                        style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            height: 1.4)),
                    const SizedBox(height: 10),
                    for (final item in plan.considerations)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.info_outline_rounded,
                                  size: 18, color: accent),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: Text(item,
                                      style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          height: 1.45))),
                            ]),
                      ),
                    const SizedBox(height: 10),
                    Text(plan.sourceSummary,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 11)),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.amber.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: AppColors.amber.withValues(alpha: 0.22)),
                      ),
                      child: Text(plan.disclaimer,
                          style: const TextStyle(
                              color: AppColors.textSecondary, height: 1.45)),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
              decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: AppColors.border))),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _exporting ? null : _sharePdf,
                  icon: _exporting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.picture_as_pdf_outlined),
                  label: Text(_exporting ? 'Preparing PDF...' : 'Generate PDF'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scoreTile(String label, String value, IconData icon, Color color) =>
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 7),
          Text(label,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 3),
          Text(value,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
        ]),
      );

  Widget _sectionCard(
      PlanSection section, int index, Color accent, bool isMeal) {
    final icons = isMeal
        ? [
            Icons.dining_rounded,
            Icons.breakfast_dining_rounded,
            Icons.lunch_dining_rounded,
            Icons.dinner_dining_rounded,
            Icons.schedule_rounded,
            Icons.local_drink_outlined
          ]
        : [
            Icons.health_and_safety_outlined,
            Icons.directions_walk_rounded,
            Icons.fitness_center_rounded,
            Icons.calendar_month_rounded,
            Icons.self_improvement_rounded
          ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
              color: accent.withValues(alpha: .11),
              borderRadius: BorderRadius.circular(11)),
          child: Icon(icons[index], color: accent, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(section.title,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(section.guidance,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13, height: 1.5)),
        ])),
      ]),
    );
  }
}
