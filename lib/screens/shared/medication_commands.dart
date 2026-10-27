import 'package:medguide/services/api_client.dart';

/// Patient-reported medication commands. These manage records, not prescriptions.
abstract class MedicationStore {
  Future<List<Map<String, dynamic>>> list();
  Future<void> add(Map<String, dynamic> details);
  Future<void> remove(String id);
}

class ApiMedicationStore implements MedicationStore {
  const ApiMedicationStore();

  @override
  Future<List<Map<String, dynamic>>> list() async {
    final records = <Map<String, dynamic>>[];
    for (var offset = 0;; offset += 100) {
      final page = (await ApiClient.instance.get('/patient-medications',
              query: {'limit': 100, 'offset': offset}) as List)
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
      records.addAll(page);
      if (page.length < 100) return records;
    }
  }

  @override
  Future<void> add(Map<String, dynamic> details) async {
    await ApiClient.instance.post('/patient-medications', data: details);
  }

  @override
  Future<void> remove(String id) async {
    await ApiClient.instance.delete('/patient-medications/$id');
  }
}

class MedicationCommands {
  final MedicationStore store;
  const MedicationCommands(this.store);

  /// Returns null when the message is an ordinary Drug Assistant question.
  Future<String?> handle(String input) async {
    final text = input.trim();
    final view = RegExp(r'^view medications?\s*[.!?]?$', caseSensitive: false);
    if (view.hasMatch(text)) {
      final active = (await store.list())
          .where((row) => row['is_active'] == true)
          .toList();
      if (active.isEmpty) return 'You have no saved medications. Type "add medication name + routine + dosage" to add one.';
      final lines = active.map((row) {
        final name = row['display_name']?.toString() ?? 'Unnamed medication';
        final routine = row['frequency']?.toString().trim() ?? '';
        final dose = row['dose']?.toString().trim() ?? '';
        final details = [if (routine.isNotEmpty) routine, if (dose.isNotEmpty) dose];
        return '• $name${details.isEmpty ? '' : ' — ${details.join(' · ')}'}';
      }).join('\n');
      return 'Your saved, patient-reported medications:\n$lines\n\nCheck this list against your prescriptions. Do not change a dose without your prescriber.';
    }

    final add = RegExp(r'^add medication(?:\s+|$)', caseSensitive: false).firstMatch(text);
    if (add != null) {
      final parts = _parts(text.substring(add.end).trim().replaceFirst(
          RegExp(r'^\+\s*'), ''));
      if (parts.isEmpty || parts.length > 3 || parts.first.isEmpty ||
          parts.any((part) => part.length > 200) ||
          (parts.length > 1 && parts[1].length > 100) ||
          (parts.length > 2 && parts[2].length > 100)) {
        return 'Use: add medication name + optional routine + optional dosage. Example: add medication metformin + every morning + 500 mg.';
      }
      final dosageOnly = parts.length == 2 &&
          RegExp(r'^\d+(?:[.,]\d+)?\s*(?:mg|mcg|µg|g|ml|units?|iu|tablets?|capsules?)\b',
                  caseSensitive: false)
              .hasMatch(parts[1]);
      final details = <String, dynamic>{
        'display_name': parts[0],
        if (parts.length > 1 && parts[1].isNotEmpty && !dosageOnly)
          'frequency': parts[1],
        if (dosageOnly) 'dose': parts[1],
        if (parts.length > 2 && parts[2].isNotEmpty) 'dose': parts[2],
      };
      final duplicate = (await store.list()).any((row) =>
          row['is_active'] == true &&
          row['display_name']?.toString().trim().toLowerCase() ==
              parts[0].toLowerCase() &&
          (row['frequency']?.toString().trim() ?? '') ==
              (details['frequency'] ?? '') &&
          (row['dose']?.toString().trim() ?? '') == (details['dose'] ?? ''));
      if (duplicate) {
        return '${parts[0]} is already in your medication list with those details. No duplicate was added.';
      }
      await store.add(details);
      return '${parts[0]} was added to your patient-reported medication list. Type "view medication" to review it. This does not verify or prescribe the medicine or dose.';
    }

    final remove = RegExp(r'^remove medication(?:\s+|$)', caseSensitive: false).firstMatch(text);
    if (remove != null) {
      final name = _unquote(text.substring(remove.end).trim().replaceFirst(
          RegExp(r'^\+\s*'), ''));
      if (name.isEmpty) return 'Use: remove medication name.';
      final matches = (await store.list()).where((row) =>
          row['is_active'] == true &&
          row['display_name']?.toString().trim().toLowerCase() == name.toLowerCase()).toList();
      if (matches.isEmpty) return 'No active saved medication named "$name" was found.';
      if (matches.length > 1) {
        return 'More than one active entry is named "$name". No entry was removed. Please review duplicate records before deleting one.';
      }
      await store.remove(matches.single['id'].toString());
      return '$name was removed from your saved medication list. This does not advise you to stop taking it; follow your prescriber’s instructions.';
    }
    return null;
  }

  List<String> _parts(String value) {
    final parts = <String>[];
    var quoted = false;
    var start = 0;
    for (var index = 0; index < value.length - 2; index++) {
      if (value[index] == '"') quoted = !quoted;
      if (!quoted && value.substring(index, index + 3) == ' + ') {
        parts.add(_unquote(value.substring(start, index)));
        start = index + 3;
        index += 2;
      }
    }
    parts.add(_unquote(value.substring(start)));
    return parts;
  }

  String _unquote(String value) {
    final trimmed = value.trim();
    return trimmed.length >= 2 && trimmed.startsWith('"') &&
            trimmed.endsWith('"')
        ? trimmed.substring(1, trimmed.length - 1).trim()
        : trimmed;
  }
}
