import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:medguide/features/wellness/mindfulness_data_source.dart';
import 'package:medguide/features/wellness/mindfulness_screen.dart';
import 'package:medguide/features/wellness/breathing_tab.dart';

class _FakeMindfulness implements MindfulnessDataSource {
  final entries = <Map<String, dynamic>>[];
  final breathing = <Map<String, dynamic>>[];
  final meditation = <Map<String, dynamic>>[];
  bool failBreathing = false;
  int reads = 0;

  @override
  Future<Map<String, dynamic>> moodSummary(String day) async {
    reads++;
    final today = entries.where((item) => item['log_date'] == day).toList();
    return {
      'date': day,
      'latest': today.isEmpty ? null : today.first,
      'today_entries': today,
      'history': List.generate(7, (index) {
        final date = DateFormat('yyyy-MM-dd')
            .format(DateTime.now().subtract(Duration(days: 6 - index)));
        final matches =
            entries.where((item) => item['log_date'] == date).toList();
        return {
          'date': date,
          'count': matches.length,
          'average_score': matches.isEmpty ? null : 5.0,
          'average_mood': matches.isEmpty ? null : 'amazing'
        };
      }),
    };
  }

  @override
  Future<void> logMood(Map<String, dynamic> entry) async {
    entries.insert(0, {
      'id': 'mood-${entries.length}',
      ...entry,
      'created_at': DateTime.now().toUtc().toIso8601String()
    });
  }

  @override
  Future<Map<String, dynamic>> breathingSummary(String day) async => {
        'history': List.generate(7, (index) {
          final date = DateFormat('yyyy-MM-dd')
              .format(DateTime.now().subtract(Duration(days: 6 - index)));
          final matches = breathing.where((entry) =>
              (entry['started_at'] as String).substring(0, 10) == date);
          return {
            'date': date,
            'count': matches.length,
            'duration_seconds': matches.fold<int>(
                0, (sum, entry) => sum + (entry['duration_seconds'] as int))
          };
        })
      };

  @override
  Future<void> logBreathing(Map<String, dynamic> entry) async {
    if (failBreathing) throw StateError('save failed');
    breathing.add(entry);
  }

  @override
  Future<Map<String, dynamic>> meditationSummary(String day) async => {
        'history': List.generate(7, (index) {
          final date = DateFormat('yyyy-MM-dd')
              .format(DateTime.now().subtract(Duration(days: 6 - index)));
          final matches = meditation.where((entry) =>
              (entry['started_at'] as String).substring(0, 10) == date);
          return {
            'date': date,
            'count': matches.length,
            'duration_seconds': matches.fold<int>(
                0, (sum, entry) => sum + (entry['duration_seconds'] as int)),
          };
        })
      };

  @override
  Future<void> logMeditation(Map<String, dynamic> entry) async {
    meditation.add(entry);
  }
}

void main() {
  testWidgets('A breathing save failure uses a dialog, not a toast',
      (tester) async {
    final api = _FakeMindfulness()..failBreathing = true;
    await tester
        .pumpWidget(MaterialApp(home: Scaffold(body: BreathingTab(api: api))));
    await tester.pump();
    await tester.tap(find.byKey(const Key('start-box')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 1100)));
    await tester.pump();
    await tester.tap(find.text('End session'));
    await tester.pumpAndSettle();
    expect(find.text('Session Not Saved'), findsOneWidget);
    expect(find.text('Dismiss'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('Breathing tab offers four exercises and custom rhythm settings',
      (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: BreathingTab(api: _FakeMindfulness()))));
    await tester.pump();
    for (final title in [
      'Box Breathing',
      '4-7-8 Breathing',
      'Belly Breathing',
      'Custom Breathing'
    ]) {
      await tester.scrollUntilVisible(find.text(title), 120,
          scrollable: find.byType(Scrollable).first);
      expect(find.text(title), findsOneWidget);
    }
    await tester.ensureVisible(find.byTooltip('Custom Breathing settings'));
    await tester.tap(find.byTooltip('Custom Breathing settings'));
    await tester.pumpAndSettle();
    expect(find.text('Inhale'), findsOneWidget);
    expect(find.text('Hold after exhale'), findsOneWidget);
    await tester.ensureVisible(find.text('Save settings'));
    await tester.tap(find.text('Save settings'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byKey(const Key('start-box')), -120,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.byKey(const Key('start-box')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(
        find.text('Time for you to focus on your breathing'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    expect(find.byKey(const Key('breathing-phase')), findsOneWidget);
    expect(find.byKey(const Key('breathing-timer')), findsOneWidget);
    final background =
        tester.getRect(find.byKey(const Key('breathing-background')));
    expect(background.left, 0);
    expect(background.right,
        tester.view.physicalSize.width / tester.view.devicePixelRatio);
    await tester.tap(find.text('End session'));
    await tester.pump();
    expect(find.byKey(const Key('start-box')), findsOneWidget);
  });

  testWidgets('Emotion suggestions follow the selected mood', (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: TickerMode(
                enabled: false, child: MoodTab(api: _FakeMindfulness())))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log Mood'));
    await tester.pumpAndSettle();

    for (final (mood, suggested, absent) in [
      ('Amazing', 'Joyful', 'Stressed'),
      ('Good', 'Optimistic', 'Joyful'),
      ('Fine', 'Reflective', 'Optimistic'),
      ('Bad', 'Frustrated', 'Reflective'),
      ('Horrible', 'Overwhelmed', 'Frustrated'),
    ]) {
      await tester.scrollUntilVisible(find.text(mood), 150,
          scrollable: find.byType(Scrollable).first);
      await tester.tap(find.text(mood));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ActionChip, suggested), findsOneWidget);
      expect(find.widgetWithText(ActionChip, absent), findsNothing);
    }
  });

  testWidgets('Mood suggestions save and update the overview', (tester) async {
    final api = _FakeMindfulness();
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: TickerMode(enabled: false, child: MoodTab(api: api)))));
    await tester.pumpAndSettle();
    expect(find.text('No mood logged today'), findsOneWidget);
    await tester.tap(find.text('Log Mood'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Amazing'), 150,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Amazing'));
    await tester.scrollUntilVisible(find.text('Happy'), 150,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Happy'));
    await tester.scrollUntilVisible(find.text('Family'), 150,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Family'));
    await tester.scrollUntilVisible(find.text('Save Mood'), 150,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save Mood'));
    await tester.pumpAndSettle();
    expect(api.entries.single['mood'], 'amazing');
    expect(api.entries.single['emotion'], 'Happy');
    expect(api.entries.single['reason'], 'Family');
    await tester.drag(find.byType(ListView).first, const Offset(0, 800));
    await tester.pumpAndSettle();
    expect(find.text('Amazing · Happy'), findsOneWidget);
    expect(find.text('Family'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Mindfulness has breathing exercises and meditation cards on a narrow phone',
      (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
        MaterialApp(home: MindfulnessScreen(dataSource: _FakeMindfulness())));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Mood'), findsOneWidget);
    await tester.tap(find.text('Breathing'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Choose a breathing exercise'), findsOneWidget);
    expect(find.text('Box Breathing'), findsOneWidget);
    await tester.tap(find.text('Meditation'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Choose a moment for yourself'), findsOneWidget);
    expect(find.text('Sleep'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
