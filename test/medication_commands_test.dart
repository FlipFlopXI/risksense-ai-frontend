import 'package:flutter_test/flutter_test.dart';
import 'package:medguide/screens/shared/medication_commands.dart';

class MemoryMedicationStore implements MedicationStore {
  final records = <Map<String, dynamic>>[];
  @override
  Future<List<Map<String, dynamic>>> list() async => records;
  @override
  Future<void> add(Map<String, dynamic> details) async {
    records.add({'id': '${records.length + 1}', 'is_active': true, ...details});
  }
  @override
  Future<void> remove(String id) async {
    records.firstWhere((record) => record['id'] == id)['is_active'] = false;
  }
}

void main() {
  test('medication commands save, display and deactivate patient entries', () async {
    final store = MemoryMedicationStore();
    final commands = MedicationCommands(store);
    expect(await commands.handle('What are metformin side effects?'), isNull);
    expect(await commands.handle('add medication Metformin + every morning + 500 mg'), contains('was added'));
    expect(store.records.single['frequency'], 'every morning');
    expect(store.records.single['dose'], '500 mg');
    expect(await commands.handle('view medication'), contains('Metformin — every morning · 500 mg'));
    expect(await commands.handle('add medication Metformin + every morning + 500 mg'), contains('No duplicate was added'));
    expect(store.records.length, 1);
    expect(await commands.handle('remove medication metformin'), contains('was removed'));
    expect(store.records.single['is_active'], isFalse);
    expect(await commands.handle('view medications'), contains('no saved medications'));
  });

  test('dosage alone and quoted combination names are kept intact', () async {
    final store = MemoryMedicationStore();
    final commands = MedicationCommands(store);
    await commands.handle('add medication "amoxicillin + clavulanate" + 500 mg');
    expect(store.records.single['display_name'], 'amoxicillin + clavulanate');
    expect(store.records.single['dose'], '500 mg');
    expect(store.records.single.containsKey('frequency'), isFalse);
    expect(await commands.handle('remove medication + "amoxicillin + clavulanate"'),
        contains('was removed'));
  });

  test('commands reject empty names and avoid ambiguous deletion', () async {
    final store = MemoryMedicationStore();
    final commands = MedicationCommands(store);
    expect(await commands.handle('add medication '), contains('Use:'));
    await commands.handle('add medication metformin');
    await commands.handle('add medication metformin + evening');
    expect(await commands.handle('remove medication metformin'), contains('No entry was removed'));
    expect(store.records.where((row) => row['is_active'] == true).length, 2);
  });
}
