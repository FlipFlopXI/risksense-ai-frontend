import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medguide/features/wellness/meditation_audio.dart';
import 'package:medguide/features/wellness/meditation_catalog.dart';
import 'package:medguide/features/wellness/mindfulness_data_source.dart';
import 'package:medguide/theme/app_theme.dart';
import 'package:medguide/widgets/app_error_dialog.dart';

class MeditationResult {
  final DateTime startedAt;
  final int durationSeconds;
  const MeditationResult(this.startedAt, this.durationSeconds);
}

class MeditationTab extends StatefulWidget {
  final MindfulnessDataSource api;
  final MeditationAudio Function() audioFactory;
  const MeditationTab(
      {super.key, required this.api, this.audioFactory = _defaultAudio});

  static MeditationAudio _defaultAudio() => AssetMeditationAudio();

  @override
  State<MeditationTab> createState() => _MeditationTabState();
}

class _MeditationTabState extends State<MeditationTab> {
  late Future<Map<String, dynamic>> history;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    history = widget.api
        .meditationSummary(DateFormat('yyyy-MM-dd').format(DateTime.now()));
  }

  Future<void> _open(MeditationTrack track) async {
    final result = await Navigator.of(context).push<MeditationResult>(
        MaterialPageRoute(
            builder: (_) => MeditationSessionScreen(
                track: track, audio: widget.audioFactory())));
    if (result == null || !mounted) return;
    try {
      await widget.api.logMeditation({
        'category': track.category,
        'track_id': track.id,
        'duration_seconds': result.durationSeconds,
        'started_at': result.startedAt.toIso8601String(),
      });
      if (mounted) setState(_reload);
    } catch (_) {
      if (mounted) {
        await showAppErrorDialog(context,
            'Your meditation session could not be saved. Please try again.',
            title: 'Session Not Saved');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return ListView(padding: const EdgeInsets.fromLTRB(20, 18, 20, 30), children: [
        Text('Choose a moment for yourself',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 5),
        Text('Explore a soundscape. You can pause or end whenever you like.',
            style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 18),
        for (final category in meditationCategories) ...[
          _categorySection(category),
          const SizedBox(height: 18),
        ],
        _historyTable(),
      ]);
  }

  Widget _categorySection(String category) {
    final tracks = meditationTracks
        .where((track) => track.category == category.toLowerCase())
        .toList();
    final icon = switch (category) {
      'Sleep' => Icons.nights_stay_rounded,
      'Ambient' => Icons.graphic_eq_rounded,
      'Nature' => Icons.forest_rounded,
      _ => Icons.piano_rounded,
    };
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, color: AppColors.teal, size: 23),
        const SizedBox(width: 8),
        Expanded(
            child: Text(category,
                maxLines: 2, style: Theme.of(context).textTheme.headlineSmall)),
      ]),
      const SizedBox(height: 10),
      SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: tracks.length,
            separatorBuilder: (_, __) => const SizedBox(width: 11),
            itemBuilder: (context, index) {
              final track = tracks[index];
              return SizedBox(
                  width: 215,
                  child: Material(
                    borderRadius: BorderRadius.circular(18),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                        key: Key('meditation-${track.id}'),
                        onTap: () => _open(track),
                        child: Stack(fit: StackFit.expand, children: [
                          Image.asset(track.imageAsset, fit: BoxFit.cover),
                          const DecoratedBox(
                              decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                Colors.transparent,
                                Color(0xcc071d38)
                              ]))),
                          Positioned(
                              left: 14,
                              right: 55,
                              bottom: 16,
                              child: Text(track.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold))),
                          Positioned(
                              right: 11,
                              bottom: 11,
                              child: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                      color: AppColors.teal,
                                      shape: BoxShape.circle),
                                  child: const Icon(Icons.play_arrow_rounded,
                                      color: Colors.white, size: 26))),
                        ])),
                  ));
            },
          )),
    ]);
  }

  Widget _historyTable() => Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.teal.withValues(alpha: .2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.table_chart_rounded, color: AppColors.teal),
          const SizedBox(width: 8),
          Expanded(
              child: Text('Last 7 Days',
                  style: Theme.of(context).textTheme.headlineSmall)),
        ]),
        const SizedBox(height: 5),
        Text('Completed listening time across all meditation types.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        const SizedBox(height: 12),
        FutureBuilder<Map<String, dynamic>>(
            future: history,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return TextButton(
                    onPressed: () => setState(_reload),
                    child: const Text('Retry meditation history'));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final days =
                  (snapshot.data!['history'] as List? ?? const []).cast<Map>();
              return Table(
                  columnWidths: const {
                    0: FlexColumnWidth(2),
                    1: FlexColumnWidth(1),
                    2: FlexColumnWidth(1.3)
                  },
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  children: [
                    TableRow(
                        decoration: BoxDecoration(
                            color: AppColors.teal.withValues(alpha: .1)),
                        children: [
                          _cell('Day', header: true),
                          _cell('Sessions', header: true),
                          _cell('Duration', header: true),
                        ]),
                    for (final day in days)
                      TableRow(children: [
                        _cell(DateFormat('EEE d MMM')
                            .format(DateTime.parse(day['date'] as String))),
                        _cell('${day['count'] ?? 0}'),
                        _cell(_time(Duration(
                            seconds:
                                (day['duration_seconds'] as num?)?.toInt() ??
                                    0))),
                      ]),
                  ]);
            }),
      ]));

  Widget _cell(String value, {bool header = false}) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 9),
      child: Text(value,
          style: TextStyle(
              fontSize: 11,
              fontWeight: header ? FontWeight.bold : FontWeight.normal,
              color: AppColors.textPrimary)));
}

String _time(Duration duration) =>
    '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';

class MeditationSessionScreen extends StatefulWidget {
  final MeditationTrack track;
  final MeditationAudio audio;
  const MeditationSessionScreen(
      {super.key, required this.track, required this.audio});
  @override
  State<MeditationSessionScreen> createState() =>
      _MeditationSessionScreenState();
}

class _MeditationSessionScreenState extends State<MeditationSessionScreen> {
  final listened = Stopwatch();
  final subscriptions = <StreamSubscription<dynamic>>[];
  DateTime? startedAt;
  Duration position = Duration.zero, duration = Duration.zero;
  bool intro = true, fading = false, ready = false;
  bool playing = false, ending = false;

  @override
  void initState() {
    super.initState();
    subscriptions.add(widget.audio.positions.listen((value) {
      if (mounted) setState(() => position = value);
    }));
    subscriptions.add(widget.audio.durations.listen((value) {
      if (mounted && value != null) setState(() => duration = value);
    }));
    subscriptions.add(widget.audio.playing.listen((value) {
      if (value) {
        startedAt ??= DateTime.now().toUtc();
        listened.start();
      } else {
        listened.stop();
      }
      if (mounted) setState(() => playing = value);
    }));
    subscriptions.add(widget.audio.completed.listen((_) => _finish()));
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => fading = true);
    });
    Future.delayed(const Duration(seconds: 3), () async {
      if (!mounted) return;
      setState(() => intro = false);
      try {
        await widget.audio.load(widget.track.audioAsset);
        if (!mounted) return;
        setState(() => ready = true);
        unawaited(_toggle());
      } catch (_) {
        if (!mounted) return;
        await showAppErrorDialog(
            context, 'This meditation track could not be played.',
            title: 'Playback Unavailable');
        if (mounted) Navigator.of(context).pop();
      }
    });
  }

  Future<void> _finish() async {
    if (ending || !mounted) return;
    ending = true;
    listened.stop();
    final seconds = math.min(listened.elapsed.inSeconds, 14400);
    try {
      await widget.audio.stop();
    } catch (_) {/* The session can still close if audio has stopped. */}
    if (!mounted) return;
    Navigator.of(context).pop(seconds > 0 && startedAt != null
        ? MeditationResult(startedAt!, seconds)
        : null);
  }

  Future<void> _toggle() async {
    if (!ready) return;
    try {
      if (playing) {
        await widget.audio.pause();
      } else {
        await widget.audio.play();
      }
    } catch (_) {
      if (mounted) {
        await showAppErrorDialog(
            context, 'Playback controls are unavailable. Please try again.',
            title: 'Playback Unavailable');
      }
    }
  }

  Future<void> _seek(Duration target) async {
    if (!ready) return;
    final end = duration.inMilliseconds;
    final bounded = Duration(milliseconds: target.inMilliseconds.clamp(0, end));
    try {
      await widget.audio.seek(bounded);
    } catch (_) {
      if (mounted) {
        await showAppErrorDialog(
            context, 'The playback position could not be changed.',
            title: 'Playback Unavailable');
      }
    }
  }

  @override
  void dispose() {
    listened.stop();
    for (final subscription in subscriptions) {
      unawaited(subscription.cancel());
    }
    unawaited(widget.audio.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return PopScope(
      canPop: false,
      child: Scaffold(
          body: SizedBox.expand(
              child: Stack(fit: StackFit.expand, children: [
        Image.asset(widget.track.imageAsset, fit: BoxFit.cover),
        const DecoratedBox(
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
              Color(0xb80a1e37),
              Color(0xa008253c),
              Color(0xe6081731)
            ]))),
        SafeArea(
            child: intro
                ? Center(
                    child: TweenAnimationBuilder<double>(
                        tween:
                            Tween(begin: fading ? 1 : 0, end: fading ? 0 : 1),
                        duration: const Duration(milliseconds: 1100),
                        builder: (_, value, child) =>
                            Opacity(opacity: value, child: child),
                        child: const Padding(
                            padding: EdgeInsets.all(28),
                            child: Text('Relax your mind and breathe.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 29,
                                    fontWeight: FontWeight.bold)))))
                : Padding(
                    padding: const EdgeInsets.fromLTRB(24, 22, 24, 30),
                    child: Column(children: [
                      const Spacer(),
                      Icon(Icons.self_improvement_rounded,
                          color: Colors.white.withValues(alpha: .9), size: 68),
                      const SizedBox(height: 16),
                      Text(widget.track.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      Text(widget.track.category.toUpperCase(),
                          style: const TextStyle(
                              color: Colors.white70, letterSpacing: 2)),
                      const Spacer(),
                      if (!ready)
                        const CircularProgressIndicator(color: Colors.white)
                      else ...[
                        Slider(
                            value: position.inMilliseconds
                                .clamp(0, math.max(1, duration.inMilliseconds))
                                .toDouble(),
                            max:
                                math.max(1, duration.inMilliseconds).toDouble(),
                            activeColor: Colors.white,
                            inactiveColor: Colors.white38,
                            onChanged: (value) =>
                                _seek(Duration(milliseconds: value.round()))),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_time(position),
                                  style: const TextStyle(color: Colors.white)),
                              Text(_time(duration),
                                  style: const TextStyle(color: Colors.white)),
                            ]),
                        const SizedBox(height: 18),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                  tooltip: 'Back 10 seconds',
                                  onPressed: () => _seek(
                                      position - const Duration(seconds: 10)),
                                  icon: const Icon(Icons.replay_10_rounded,
                                      color: Colors.white, size: 35)),
                              const SizedBox(width: 24),
                              IconButton(
                                  tooltip: playing ? 'Pause' : 'Play',
                                  onPressed: _toggle,
                                  icon: Icon(
                                      playing
                                          ? Icons.pause_circle_filled_rounded
                                          : Icons.play_circle_fill_rounded,
                                      color: Colors.white,
                                      size: 70)),
                              const SizedBox(width: 24),
                              IconButton(
                                  tooltip: 'Forward 10 seconds',
                                  onPressed: () => _seek(
                                      position + const Duration(seconds: 10)),
                                  icon: const Icon(Icons.forward_10_rounded,
                                      color: Colors.white, size: 35)),
                            ]),
                      ],
                      const SizedBox(height: 22),
                      OutlinedButton.icon(
                          onPressed: _finish,
                          style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(
                                  color: Colors.white, width: 1.5)),
                          icon: const Icon(Icons.stop_circle_outlined),
                          label: const Text('End session')),
                    ]))),
      ]))));
  }
}
