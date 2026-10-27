import 'package:intl/intl.dart';
import 'package:medguide/services/api_client.dart';

abstract class HealthTrendSource {
  Future<Map<String, dynamic>> load();
}

class ApiHealthTrendSource implements HealthTrendSource {
  const ApiHealthTrendSource();
  @override
  Future<Map<String, dynamic>> load() async => Map<String, dynamic>.from(
      await ApiClient.instance.get('/health/trends', query: {'limit': 200}) as Map);
}

/// Describes recorded measurements only; it never diagnoses or interprets risk.
class HealthTrendCommands {
  final HealthTrendSource source;
  final DateTime Function() now;
  const HealthTrendCommands(this.source, {required this.now});

  Future<String?> handle(String input) async {
    final text = input.trim().toLowerCase();
    if (!RegExp(r'^(show|view|explain|summarize|what are|how (?:has|have))\b')
            .hasMatch(text) ||
        !text.contains('my') ||
        !RegExp(r'(trend|reading|changed|history)').hasMatch(text)) {
      return null;
    }
    final all = text.contains('health trend') ||
        RegExp(r'my trends?\b').hasMatch(text);
    final topics = <String, String>{
      'blood pressure': 'blood_pressure',
      'heart rate': 'heart_rate',
      'fasting glucose': 'fasting_glucose',
      'glucose': 'fasting_glucose',
      'cholesterol': 'total_cholesterol',
      'weight': 'weight',
      'bmi': 'bmi',
    };
    final selected = all
        ? {'blood_pressure', 'heart_rate', 'fasting_glucose', 'total_cholesterol', 'weight', 'bmi'}
        : topics.entries.where((item) => text.contains(item.key)).map((item) => item.value).toSet();
    if (selected.isEmpty) return null;
    final data = await source.load();
    final lines = <String>[];
    for (final key in selected) {
      final records = key == 'weight' || key == 'bmi'
          ? _points(data['body_measurements'], 'measured_at')
          : _points(data[key], key == 'blood_pressure' || key == 'heart_rate'
              ? 'recorded_at' : 'measured_at');
      final measurements = records
          .map((item) => _measurement(key, item))
          .where((item) => item != null)
          .cast<_Reading>()
          .toList();
      if (measurements.isEmpty) continue;
      final first = measurements.first;
      final last = measurements.last;
      final label = switch (key) {
        'blood_pressure' => 'Blood pressure',
        'heart_rate' => 'Heart rate',
        'fasting_glucose' => 'Fasting laboratory glucose',
        'total_cholesterol' => 'Total cholesterol',
        'weight' => 'Weight',
        _ => 'BMI',
      };
      final date = DateFormat('d MMM').format(last.at.toLocal());
      final change = measurements.length < 2
          ? 'Only one reading is available.'
          : key == 'blood_pressure'
              ? 'Systolic ${_direction(first.value, last.value)}; diastolic ${_direction(first.secondValue!, last.secondValue!)} compared with the first reading in this period.'
              : '${_direction(first.value, last.value)} compared with the first recorded value in this period.';
      lines.add('• $label: ${last.display} ($date). $change');
    }
    if (lines.isEmpty) {
      return 'I found no recorded readings for that topic in the last seven days. Missing data is not treated as zero.';
    }
    return 'Your recorded measurements from the last seven days:\n${lines.join('\n')}\n\nThese are your saved readings, not a diagnosis or a treatment recommendation. Discuss concerning values with a clinician.';
  }

  List<Map<String, dynamic>> _points(dynamic raw, String dateKey) {
    final cutoff = now().toUtc().subtract(const Duration(days: 7));
    final points = (raw is List ? raw : const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .where((item) {
          final at = DateTime.tryParse(item[dateKey]?.toString() ?? '')?.toUtc();
          return at != null && !at.isBefore(cutoff) && !at.isAfter(now().toUtc());
        }).toList();
    points.sort((a, b) => DateTime.parse(a[dateKey].toString())
        .compareTo(DateTime.parse(b[dateKey].toString())));
    return points;
  }

  _Reading? _measurement(String key, Map<String, dynamic> item) {
    final at = DateTime.tryParse((item['recorded_at'] ?? item['measured_at'])?.toString() ?? '');
    if (at == null) return null;
    if (key == 'blood_pressure') {
      final systolic = item['systolic'];
      final diastolic = item['diastolic'];
      if (systolic is! num || diastolic is! num) return null;
      return _Reading(at, systolic.toDouble(), '${systolic.toStringAsFixed(0)}/${diastolic.toStringAsFixed(0)} mmHg',
          secondValue: diastolic.toDouble());
    }
    final raw = key == 'weight' ? item['weight_kg'] : item[key == 'bmi' ? 'bmi' : 'value'];
    if (raw is! num) return null;
    final unit = switch (key) {
      'heart_rate' => 'bpm',
      'weight' => 'kg',
      'bmi' => 'kg/m²',
      _ => item['unit']?.toString() ?? '',
    };
    return _Reading(at, raw.toDouble(), '${raw.toStringAsFixed(key == 'heart_rate' ? 0 : 1)} $unit'.trim());
  }

  String _direction(double first, double last) => last > first
      ? 'higher'
      : last < first
          ? 'lower'
          : 'unchanged';
}

class _Reading {
  final DateTime at;
  final double value;
  final String display;
  final double? secondValue;
  const _Reading(this.at, this.value, this.display, {this.secondValue});
}
