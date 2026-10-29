import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:medguide/features/wellness/glucose_data_source.dart';
import 'package:medguide/features/wellness/glucose_tab.dart';

class _FakeGlucose implements GlucoseDataSource {
  final entries = <Map<String, dynamic>>[];

  @override
  Future<Map<String, dynamic>> summary(String day) async => {
        'date': day,
        'entries':
            entries.map((item) => Map<String, dynamic>.from(item)).toList(),
      };

  @override
  Future<void> addEntry(Map<String, dynamic> entry) async {
    entries.insert(0, {
      'id': 'entry-${entries.length}',
      'log_date': entry['log_date'],
      'category': entry['category'],
      'value': (entry['value'] as num).toStringAsFixed(2),
      'unit': entry['category'] == 'insulin_dose' ? 'U' : 'mg/dL',
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }
}

void main() {
  testWidgets('glucose and insulin popups reject out-of-range entries', (tester) async {
    final api = _FakeGlucose();
    final day = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: GlucoseTab(api: api, day: day))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add Glucose Reading'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).last, '601');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a meter reading from 20 to 600 mg/dL.'), findsOneWidget);
    expect(api.entries, isEmpty);
    await tester.enterText(find.byType(TextFormField).last, '140');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(api.entries.length, 1);
    await tester.tap(find.text('Log Insulin Dose'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).last, '501');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a recorded dose greater than 0 and up to 500 U.'), findsOneWidget);
    expect(api.entries.length, 1);
  });
  testWidgets('glucose type and insulin dose are saved and refresh immediately',
      (tester) async {
    final api = _FakeGlucose();
    final day = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: GlucoseTab(api: api, day: day))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add Glucose Reading'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fasting').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Post-meal').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).last, '140');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(api.entries.single['category'], 'post_meal');
    expect(find.text('140.00'), findsWidgets);
    await tester.tap(find.text('Log Insulin Dose'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).last, '8');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(api.entries.first['category'], 'insulin_dose');
    expect(find.text('8 U logged today'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
