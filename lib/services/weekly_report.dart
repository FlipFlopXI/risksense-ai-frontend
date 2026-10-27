import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:medguide/features/wellness/fitness_data_source.dart';
import 'package:medguide/features/wellness/glucose_data_source.dart';
import 'package:medguide/features/wellness/mindfulness_data_source.dart';
import 'package:medguide/features/wellness/nutrition_data_source.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:medguide/widgets/pdf_report_preview.dart';

class WeeklyReportDay {
  final DateTime date;
  final List<String> lines;
  const WeeklyReportDay(this.date, this.lines);
}

class WeeklyReport {
  final String category;
  final DateTime endDate;
  final List<WeeklyReportDay> days;
  const WeeklyReport(this.category, this.endDate, this.days);

  String get filename =>
      'risksense_${category.toLowerCase()}_${DateFormat('yyyy-MM-dd').format(endDate)}.pdf';
}

class WeeklyReportService {
  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static List<DateTime> _dates(DateTime endDate) {
    final end = _dateOnly(endDate);
    return List.generate(
        7, (index) => DateTime(end.year, end.month, end.day - (6 - index)));
  }

  static String _key(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  static String _number(Object? value, {int decimals = 0}) {
    final number = value is num ? value : num.tryParse('$value');
    if (number == null) return '-';
    return number.toStringAsFixed(decimals);
  }

  static String _text(Object? value) =>
      (value?.toString().trim().isNotEmpty ?? false)
          ? value.toString().trim().replaceAll(RegExp(r'\s+'), ' ')
          : '-';

  static List<Map> _maps(Object? value) =>
      (value as List? ?? const []).whereType<Map>().toList();

  static Future<WeeklyReport> nutrition({
    required NutritionDataSource nutrition,
    required GlucoseDataSource glucose,
    required DateTime endDate,
  }) async {
    final dates = _dates(endDate);
    final food =
        await Future.wait(dates.map((date) => nutrition.summary(_key(date))));
    final water = await Future.wait(
        dates.map((date) => nutrition.waterSummary(_key(date))));
    final metabolic = await glucose.summary(_key(dates.last));
    final metabolicEntries = _maps(metabolic['entries']);

    return WeeklyReport('Nutrition', _dateOnly(endDate), [
      for (var index = 0; index < 7; index++)
        WeeklyReportDay(dates[index], [
          'Food: ${_number(food[index]['calories_kcal'], decimals: 1)} kcal, '
              '${_number(food[index]['carbs_g'], decimals: 1)} g carbs, '
              '${_number(food[index]['protein_g'], decimals: 1)} g protein, '
              '${_number(food[index]['fat_g'], decimals: 1)} g fat',
          'Water: ${_number(water[index]['total_ml'])} ml',
          ..._maps(water[index]['entries'])
              .map((entry) => 'Water entry: ${_number(entry['amount_ml'])} ml'),
          ..._maps(food[index]['entries']).map((entry) =>
              'Meal - ${_text(entry['meal_type'])}: ${_text(entry['food_name'])}, '
              '${_number(entry['amount_g'], decimals: 1)} g, '
              '${_number(entry['calories_kcal'], decimals: 1)} kcal'),
          ...metabolicEntries
              .where((entry) =>
                  entry['log_date']?.toString() == _key(dates[index]))
              .map((entry) =>
                  '${entry['category'] == 'insulin_dose' ? 'Insulin dose' : 'Blood glucose'} '
                  '(${_text(entry['category'])}): ${_number(entry['value'], decimals: 1)} '
                  '${_text(entry['unit'])}'),
        ]),
    ]);
  }

  static Future<WeeklyReport> fitness({
    required FitnessDataSource fitness,
    required DateTime endDate,
  }) async {
    final dates = _dates(endDate);
    final results = await Future.wait<dynamic>([
      fitness.activity(_key(dates.last)),
      fitness.bodyTrends(),
      fitness.body(),
    ]);
    final activity = results[0] as Map<String, dynamic>;
    final measurements = results[1] as List<Map<String, dynamic>>;
    final body = results[2] as Map<String, dynamic>;
    final history = _maps(activity['history']);
    final composition =
        body['composition'] is Map ? body['composition'] as Map : null;

    return WeeklyReport('Fitness', _dateOnly(endDate), [
      for (final date in dates)
        WeeklyReportDay(date, [
          for (final row in history.where(
              (row) => row['date']?.toString().startsWith(_key(date)) ?? false))
            'Activity: ${_number(row['steps'])} steps, '
                '${_number(row['activity_minutes'])} minutes, '
                '${_number(row['activity_calories_kcal'], decimals: 1)} kcal, '
                '${_number(row['distance_km'], decimals: 2)} km',
          for (final row in measurements
              .where((row) => _localDateKey(row['measured_at']) == _key(date)))
            'Body measurement: ${_number(row['weight_kg'], decimals: 1)} kg, '
                'BMI ${_number(row['bmi'], decimals: 1)}',
          if (composition != null &&
              _localDateKey(composition['created_at']) == _key(date))
            'Body composition: ${_number(composition['skeletal_muscle_kg'], decimals: 1)} kg skeletal muscle, '
                '${_number(composition['body_fat_percent'], decimals: 1)}% body fat',
        ]),
    ]);
  }

  static Future<WeeklyReport> mindfulness({
    required MindfulnessDataSource mindfulness,
    required DateTime endDate,
  }) async {
    final dates = _dates(endDate);
    final results = await Future.wait<dynamic>([
      Future.wait(dates.map((date) => mindfulness.moodSummary(_key(date)))),
      mindfulness.breathingSummary(_key(dates.last)),
      mindfulness.meditationSummary(_key(dates.last)),
    ]);
    final moods = results[0] as List<Map<String, dynamic>>;
    final breathing = _maps((results[1] as Map)['history']);
    final meditation = _maps((results[2] as Map)['history']);

    return WeeklyReport('Mindfulness', _dateOnly(endDate), [
      for (var index = 0; index < 7; index++)
        WeeklyReportDay(dates[index], [
          for (final entry in _maps(moods[index]['today_entries']))
            'Mood: ${_text(entry['mood'])}; emotion: ${_text(entry['emotion'])}; '
                'reason: ${_text(entry['reason'])}',
          for (final row in breathing.where((row) =>
              row['date']?.toString().startsWith(_key(dates[index])) ?? false))
            'Breathing: ${_number(row['count'])} sessions, '
                '${_number(row['duration_seconds'])} seconds',
          for (final row in meditation.where((row) =>
              row['date']?.toString().startsWith(_key(dates[index])) ?? false))
            'Meditation: ${_number(row['count'])} sessions, '
                '${_number(row['duration_seconds'])} seconds',
        ]),
    ]);
  }

  static String? _localDateKey(Object? value) {
    final parsed = DateTime.tryParse('$value');
    return parsed == null ? null : _key(parsed.toLocal());
  }

  static Future<Uint8List> buildPdf(WeeklyReport report) async {
    final document = pw.Document();
    final regular =
        pw.Font.ttf(await rootBundle.load('assets/fonts/Rubik-Regular.ttf'));
    final medium =
        pw.Font.ttf(await rootBundle.load('assets/fonts/Rubik-Medium.ttf'));
    final start = report.days.first.date;
    final dateFormat = DateFormat('d MMM yyyy');
    document.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      theme: pw.ThemeData.withFont(base: regular, bold: medium),
      build: (_) => [
        pw.Text('RiskSense AI',
            style: pw.TextStyle(
                fontSize: 11,
                color: PdfColors.blueGrey700,
                fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.Text('${report.category} weekly report',
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        pw.Text(
            '${dateFormat.format(start)} - ${dateFormat.format(report.endDate)}',
            style:
                const pw.TextStyle(fontSize: 10, color: PdfColors.blueGrey700)),
        pw.SizedBox(height: 16),
        for (final day in report.days) ...[
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            color: PdfColors.blueGrey100,
            child: pw.Text(dateFormat.format(day.date),
                style:
                    pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          ),
          pw.SizedBox(height: 5),
          ...((day.lines.isEmpty
                  ? const ['No information captured.']
                  : day.lines)
              .map((line) => pw.Padding(
                  padding: const pw.EdgeInsets.only(left: 9, bottom: 4),
                  child:
                      pw.Text(line, style: const pw.TextStyle(fontSize: 9))))),
          pw.SizedBox(height: 10),
        ],
        pw.Text(
            'This report contains patient-entered information and is not a diagnosis.',
            style:
                const pw.TextStyle(fontSize: 8, color: PdfColors.blueGrey700)),
      ],
    ));
    return document.save();
  }

  static Future<void> open(BuildContext context, WeeklyReport report) async {
    final bytes = await buildPdf(report);
    if (!context.mounted) return;
    await PdfReportPreview.open(context,
        title: '${report.category} weekly report',
        filename: report.filename,
        bytes: bytes);
  }
}
