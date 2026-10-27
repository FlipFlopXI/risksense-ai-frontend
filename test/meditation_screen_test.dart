import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:medguide/features/wellness/meditation_audio.dart';
import 'package:medguide/features/wellness/meditation_catalog.dart';
import 'package:medguide/features/wellness/meditation_tab.dart';
import 'package:medguide/features/wellness/mindfulness_data_source.dart';

class _MeditationApi implements MindfulnessDataSource {
  final entries = <Map<String, dynamic>>[];
  @override
  Future<Map<String, dynamic>> meditationSummary(String day) async => {
        'history': List.generate(7, (index) {
          final date = DateFormat('yyyy-MM-dd')
              .format(DateTime.now().subtract(Duration(days: 6 - index)));
          final matches = index == 6 ? entries : <Map<String, dynamic>>[];
          return {
            'date': date,
            'count': matches.length,
            'duration_seconds': matches.fold<int>(
                0, (total, row) => total + (row['duration_seconds'] as int))
          };
        })
      };
  @override
  Future<void> logMeditation(Map<String, dynamic> entry) async =>
      entries.add(entry);
  @override
  Future<Map<String, dynamic>> moodSummary(String day) =>
      throw UnimplementedError();
  @override
  Future<void> logMood(Map<String, dynamic> entry) =>
      throw UnimplementedError();
  @override
  Future<Map<String, dynamic>> breathingSummary(String day) =>
      throw UnimplementedError();
  @override
  Future<void> logBreathing(Map<String, dynamic> entry) =>
      throw UnimplementedError();
}

class _MeditationAudio implements MeditationAudio {
  final _positions = StreamController<Duration>.broadcast(sync: true);
  final _durations = StreamController<Duration?>.broadcast(sync: true);
  final _playing = StreamController<bool>.broadcast(sync: true);
  final _completed = StreamController<void>.broadcast(sync: true);
  String? loadedAsset;
  int pauses = 0;
  @override
  Stream<Duration> get positions => _positions.stream;
  @override
  Stream<Duration?> get durations => _durations.stream;
  @override
  Stream<bool> get playing => _playing.stream;
  @override
  Stream<void> get completed => _completed.stream;
  @override
  Future<void> load(String asset) async {
    loadedAsset = asset;
    _durations.add(const Duration(minutes: 5));
    _positions.add(Duration.zero);
  }

  @override
  Future<void> play() async => _playing.add(true);
  @override
  Future<void> pause() async {
    pauses++;
    _playing.add(false);
  }

  @override
  Future<void> seek(Duration position) async => _positions.add(position);
  @override
  Future<void> stop() async => _playing.add(false);
  @override
  Future<void> dispose() async {
    await _positions.close();
    await _durations.close();
    await _playing.close();
    await _completed.close();
  }
}

void main() {
  testWidgets('All supplied meditation images and audio are declared as assets',
      (tester) async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final assets = manifest.listAssets().toSet();
    expect(meditationTracks.length, 24);
    for (final category in meditationCategories) {
      expect(
          meditationTracks
              .where((track) => track.category == category.toLowerCase())
              .length,
          6);
    }
    for (final track in meditationTracks) {
      expect(assets, contains(track.imageAsset));
      expect(assets, contains(track.audioAsset));
    }
  });

  testWidgets('Meditation player controls audio and records listening time',
      (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = _MeditationApi();
    final audio = _MeditationAudio();
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: MeditationTab(api: api, audioFactory: () => audio))));
    await tester.pump();
    expect(find.text('Sleep'), findsOneWidget);
    await tester.tap(find.byKey(const Key('meditation-sleep_01')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Relax your mind and breathe.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(audio.loadedAsset, meditationTracks.first.audioAsset);
    expect(find.byTooltip('Pause'), findsOneWidget);
    await tester.tap(find.byTooltip('Pause'));
    await tester.pump();
    expect(audio.pauses, 1);
    await tester.tap(find.byTooltip('Play'));
    await tester.pump();
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 1100)));
    await tester.pump();
    await tester.tap(find.text('End session'));
    await tester.pumpAndSettle();
    expect(api.entries.length, 1);
    expect(api.entries.single['track_id'], 'sleep_01');
    expect((api.entries.single['duration_seconds'] as int), greaterThan(0));
    await tester.scrollUntilVisible(find.text('Last 7 Days'), 180,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Sessions'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
