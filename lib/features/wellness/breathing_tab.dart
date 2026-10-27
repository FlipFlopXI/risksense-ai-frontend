import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medguide/features/wellness/mindfulness_data_source.dart';
import 'package:medguide/theme/app_theme.dart';
import 'package:medguide/widgets/app_error_dialog.dart';

class BreathingExercise {
  final String id, title, subtitle;
  final IconData icon;
  final List<Color> colors;
  final int inhale, hold, exhale, holdAfter;
  const BreathingExercise(this.id, this.title, this.subtitle, this.icon,
      this.colors, this.inhale, this.hold, this.exhale, this.holdAfter);
  int get cycle => inhale + hold + exhale + holdAfter;
}

const breathingExercises = <BreathingExercise>[
  BreathingExercise(
      'box',
      'Box Breathing',
      '4 · 4 · 4 · 4',
      Icons.crop_square_rounded,
      [Color(0xff087e9a), Color(0xff2742a1)],
      4,
      4,
      4,
      4),
  BreathingExercise(
      '478',
      '4-7-8 Breathing',
      '4 · 7 · 8',
      Icons.nights_stay_rounded,
      [Color(0xff8352c4), Color(0xff3445a7)],
      4,
      7,
      8,
      0),
  BreathingExercise('belly', 'Belly Breathing', '4 · 6', Icons.spa_rounded,
      [Color(0xff159f89), Color(0xff086e91)], 4, 0, 6, 0),
  BreathingExercise('custom', 'Custom Breathing', 'Choose your own rhythm',
      Icons.tune_rounded, [Color(0xffd26d90), Color(0xff8754ad)], 4, 2, 6, 0),
];

class BreathingTab extends StatefulWidget {
  final MindfulnessDataSource api;
  const BreathingTab({super.key, required this.api});
  @override
  State<BreathingTab> createState() => _BreathingTabState();
}

class _BreathingTabState extends State<BreathingTab> {
  late Future<Map<String, dynamic>> history;
  final durations = <String, int>{
    for (final item in breathingExercises) item.id: 3
  };
  BreathingExercise custom = breathingExercises.last;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    history = widget.api
        .breathingSummary(DateFormat('yyyy-MM-dd').format(DateTime.now()));
  }

  Future<void> _settings(BreathingExercise exercise) async {
    var minutes = durations[exercise.id] ?? 3;
    var inhale = custom.inhale, hold = custom.hold;
    var exhale = custom.exhale, holdAfter = custom.holdAfter;
    final saved = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
            builder: (context, update) => Dialog(
                backgroundColor: AppColors.cardWhite,
                insetPadding: const EdgeInsets.symmetric(horizontal: 20),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26)),
                child: ConstrainedBox(
                    constraints: BoxConstraints(
                        maxWidth: 430,
                        maxHeight:
                            MediaQuery.sizeOf(dialogContext).height - 80),
                    child: SingleChildScrollView(
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                              gradient: LinearGradient(colors: exercise.colors),
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(26))),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(exercise.icon,
                                    color: Colors.white, size: 34),
                                const SizedBox(height: 10),
                                Text('${exercise.title} settings',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                const Text('Make this session your own',
                                    style: TextStyle(color: Colors.white70)),
                              ])),
                      Padding(
                          padding: const EdgeInsets.all(18),
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                            _stepper(
                                'Duration',
                                minutes,
                                'min',
                                1,
                                30,
                                exercise.colors.first,
                                (value) => update(() => minutes = value)),
                            if (exercise.id == 'custom') ...[
                              const SizedBox(height: 10),
                              _stepper(
                                  'Inhale',
                                  inhale,
                                  'counts',
                                  1,
                                  15,
                                  exercise.colors.first,
                                  (value) => update(() => inhale = value)),
                              const SizedBox(height: 10),
                              _stepper(
                                  'Hold',
                                  hold,
                                  'counts',
                                  0,
                                  15,
                                  exercise.colors.first,
                                  (value) => update(() => hold = value)),
                              const SizedBox(height: 10),
                              _stepper(
                                  'Exhale',
                                  exhale,
                                  'counts',
                                  1,
                                  15,
                                  exercise.colors.first,
                                  (value) => update(() => exhale = value)),
                              const SizedBox(height: 10),
                              _stepper(
                                  'Hold after exhale',
                                  holdAfter,
                                  'counts',
                                  0,
                                  15,
                                  exercise.colors.first,
                                  (value) => update(() => holdAfter = value)),
                            ],
                            const SizedBox(height: 18),
                            Row(children: [
                              Expanded(
                                  child: TextButton(
                                      onPressed: () =>
                                          Navigator.pop(dialogContext, false),
                                      child: const Text('Cancel'))),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: FilledButton(
                                      style: FilledButton.styleFrom(
                                          backgroundColor:
                                              exercise.colors.first),
                                      onPressed: () =>
                                          Navigator.pop(dialogContext, true),
                                      child: const Text('Save settings'))),
                            ])
                          ])),
                    ]))))));
    if (saved == true && mounted) {
      setState(() {
        durations[exercise.id] = minutes;
        if (exercise.id == 'custom') {
          custom = BreathingExercise(
              'custom',
              'Custom Breathing',
              '$inhale · $hold · $exhale${holdAfter > 0 ? ' · $holdAfter' : ''}',
              exercise.icon,
              exercise.colors,
              inhale,
              hold,
              exhale,
              holdAfter);
        }
      });
    }
  }

  Widget _stepper(String title, int value, String unit, int minimum,
          int maximum, Color accent, ValueChanged<int> change) =>
      Container(
          padding: const EdgeInsets.fromLTRB(12, 5, 6, 5),
          decoration: BoxDecoration(
              color: accent.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accent.withValues(alpha: .22))),
          child: Row(children: [
            Expanded(
                child: Text(title,
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600))),
            IconButton(
                visualDensity: VisualDensity.compact,
                color: accent,
                onPressed: value > minimum ? () => change(value - 1) : null,
                icon: const Icon(Icons.remove_circle_outline)),
            Text('$value $unit',
                style: TextStyle(
                    color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
            IconButton(
                visualDensity: VisualDensity.compact,
                color: accent,
                onPressed: value < maximum ? () => change(value + 1) : null,
                icon: const Icon(Icons.add_circle_outline)),
          ]));

  Future<void> _start(BreathingExercise exercise) async {
    final result = await Navigator.of(context).push<int>(MaterialPageRoute(
        builder: (_) => BreathingSessionScreen(
            exercise: exercise,
            duration: Duration(minutes: durations[exercise.id] ?? 3))));
    if (result == null || result <= 0 || !mounted) return;
    try {
      await widget.api.logBreathing({
        'exercise': exercise.id,
        'duration_seconds': result,
        'started_at': DateTime.now()
            .subtract(Duration(seconds: result))
            .toUtc()
            .toIso8601String(),
      });
      if (mounted) setState(_reload);
    } catch (_) {
      if (mounted) {
        await showAppErrorDialog(context,
            'Your breathing session could not be saved. Please try again.',
            title: 'Session Not Saved');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 32), children: [
        Text('Choose a breathing exercise',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 6),
        Text('Follow a comfortable rhythm. End the session any time.',
            style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 16),
        for (final item in breathingExercises) ...[
          _exerciseCard(item.id == 'custom' ? custom : item),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 12),
        Text('Your last 7 days',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        FutureBuilder<Map<String, dynamic>>(
            future: history,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Text('Breathing history is unavailable.');
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final days =
                  (snapshot.data!['history'] as List? ?? const []).cast<Map>();
              final maximum = days.fold<int>(
                  1,
                  (value, day) => math.max(
                      value, (day['duration_seconds'] as num?)?.toInt() ?? 0));
              return Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                      color: AppColors.cardWhite,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.teal.withValues(alpha: .2))),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Sessions and duration',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 6),
                        Text(
                            'Bar height shows duration; labels show session count.',
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 12)),
                        const SizedBox(height: 18),
                        SizedBox(
                            height: 130,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                for (final day in days)
                                  Expanded(
                                      child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                        Text('${day['count'] ?? 0}',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 4),
                                        Container(
                                            height: math.max(
                                                4,
                                                84 *
                                                    ((day['duration_seconds']
                                                                as num?)
                                                            ?.toInt() ??
                                                        0) /
                                                    maximum),
                                            margin: const EdgeInsets.symmetric(
                                                horizontal: 5),
                                            decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                    colors: [
                                                      AppColors.teal,
                                                      AppColors.primaryBlue
                                                    ],
                                                    begin:
                                                        Alignment.bottomCenter,
                                                    end: Alignment.topCenter),
                                                borderRadius:
                                                    BorderRadius.circular(6))),
                                        const SizedBox(height: 5),
                                        Text(
                                            DateFormat('EEE').format(
                                                DateTime.parse(
                                                    day['date'] as String)),
                                            style:
                                                const TextStyle(fontSize: 11)),
                                      ]))
                              ],
                            )),
                        const SizedBox(height: 10),
                        Text(
                            'Minutes by day: ${days.map((day) => ((day['duration_seconds'] as num?)?.toInt() ?? 0) ~/ 60).join(' · ')}',
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 12)),
                      ]));
            }),
      ]);
  }

  Widget _exerciseCard(BreathingExercise item) => Container(
      decoration: BoxDecoration(
          gradient: LinearGradient(colors: item.colors),
          borderRadius: BorderRadius.circular(22)),
      child: Row(children: [
        Expanded(
            child: InkWell(
                key: Key('start-${item.id}'),
                onTap: () => _start(item),
                borderRadius: BorderRadius.circular(22),
                child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(children: [
                      Icon(item.icon, color: Colors.white, size: 34),
                      const SizedBox(width: 15),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(item.title,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold)),
                            Text(
                                '${item.subtitle}  •  ${durations[item.id]} min',
                                style: const TextStyle(color: Colors.white)),
                          ])),
                    ])))),
        IconButton(
            tooltip: '${item.title} settings',
            onPressed: () => _settings(item),
            icon: const Icon(Icons.settings_rounded, color: Colors.white)),
        const SizedBox(width: 7),
      ]));
}

class BreathingSessionScreen extends StatefulWidget {
  final BreathingExercise exercise;
  final Duration duration;
  const BreathingSessionScreen(
      {super.key, required this.exercise, required this.duration});
  @override
  State<BreathingSessionScreen> createState() => _BreathingSessionScreenState();
}

class _BreathingSessionScreenState extends State<BreathingSessionScreen> {
  Timer? timer;
  final watch = Stopwatch();
  bool intro = true, fading = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => fading = true);
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => intro = false);
      watch.start();
      timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
        if (!mounted) return;
        if (watch.elapsed >= widget.duration) {
          _finish();
        } else {
          setState(() {});
        }
      });
    });
  }

  void _finish() {
    watch.stop();
    timer?.cancel();
    Navigator.of(context)
        .pop(math.min(widget.duration.inSeconds, watch.elapsed.inSeconds));
  }

  @override
  void dispose() {
    timer?.cancel();
    watch.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final item = widget.exercise;
    final cyclePosition = (watch.elapsedMilliseconds / 1000) % item.cycle;
    final inhaleEnd = item.inhale.toDouble(), holdEnd = inhaleEnd + item.hold;
    final exhaleEnd = holdEnd + item.exhale;
    final phase = cyclePosition < inhaleEnd
        ? 'Inhale'
        : cyclePosition < holdEnd
            ? 'Hold'
            : cyclePosition < exhaleEnd
                ? 'Exhale'
                : 'Hold';
    final end = phase == 'Inhale'
        ? inhaleEnd
        : cyclePosition < holdEnd
            ? holdEnd
            : cyclePosition < exhaleEnd
                ? exhaleEnd
                : item.cycle.toDouble();
    final fraction = cyclePosition < inhaleEnd
        ? cyclePosition / item.inhale
        : cyclePosition < holdEnd
            ? 1.0
            : cyclePosition < exhaleEnd
                ? 1 - (cyclePosition - holdEnd) / item.exhale
                : 0.0;
    final remaining =
        math.max(0, widget.duration.inSeconds - watch.elapsed.inSeconds);
    final shape = item.id == 'box' ? BoxShape.rectangle : BoxShape.circle;
    return PopScope(
        canPop: false,
        child: Scaffold(
            body: SizedBox.expand(
                key: const Key('breathing-background'),
                child: Container(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                          item.colors.last,
                          item.colors.first,
                          item.colors.last
                        ])),
                    child: SafeArea(
                        child: Stack(fit: StackFit.expand, children: [
                      if (intro)
                        Center(
                            child: TweenAnimationBuilder<double>(
                                tween: Tween(
                                    begin: fading ? 1 : 0, end: fading ? 0 : 1),
                                duration: const Duration(milliseconds: 1100),
                                builder: (_, opacity, child) =>
                                    Opacity(opacity: opacity, child: child),
                                child: const Padding(
                                    padding: EdgeInsets.all(30),
                                    child: Text(
                                        'Time for you to focus on your breathing',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 29,
                                            fontWeight: FontWeight.bold))))),
                      if (!intro)
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Spacer(),
                              Text(phase,
                                  key: const Key('breathing-phase'),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 34,
                                      fontWeight: FontWeight.bold)),
                              Text(
                                  '${math.max(1, (end - cyclePosition).ceil())}',
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 26)),
                              const Spacer(),
                              SizedBox(
                                height: 270,
                                width: 270,
                                child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      if (item.id == '478')
                                        AnimatedContainer(
                                            duration: const Duration(
                                                milliseconds: 100),
                                            width: 180 + 85 * fraction,
                                            height: 180 + 85 * fraction,
                                            decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                    color: Colors.white
                                                        .withValues(alpha: .5),
                                                    width: 3))),
                                      if (item.id == 'custom')
                                        Transform.translate(
                                            offset: Offset(
                                                105 *
                                                    math.cos(watch
                                                            .elapsedMilliseconds /
                                                        650),
                                                105 *
                                                    math.sin(watch
                                                            .elapsedMilliseconds /
                                                        650)),
                                            child: const Icon(Icons.circle,
                                                color: Colors.white70,
                                                size: 16)),
                                      AnimatedContainer(
                                          duration:
                                              const Duration(milliseconds: 100),
                                          width: 100 + 150 * fraction,
                                          height: item.id == 'belly'
                                              ? 85 + 115 * fraction
                                              : 100 + 150 * fraction,
                                          decoration: BoxDecoration(
                                              shape: shape,
                                              borderRadius: shape ==
                                                      BoxShape.rectangle
                                                  ? BorderRadius.circular(38)
                                                  : null,
                                              gradient: RadialGradient(colors: [
                                                Colors.white
                                                    .withValues(alpha: .9),
                                                item.colors.first
                                                    .withValues(alpha: .9),
                                                item.colors.last
                                                    .withValues(alpha: .4)
                                              ]),
                                              boxShadow: [
                                                BoxShadow(
                                                    color: Colors.white
                                                        .withValues(alpha: .3),
                                                    blurRadius:
                                                        35 + 35 * fraction,
                                                    spreadRadius:
                                                        5 + 18 * fraction)
                                              ]),
                                          child: Icon(item.icon,
                                              color: Colors.white, size: 46)),
                                    ]),
                              ),
                              const Spacer(),
                              Text(
                                  '${(remaining ~/ 60).toString().padLeft(2, '0')}:${(remaining % 60).toString().padLeft(2, '0')}',
                                  key: const Key('breathing-timer'),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 14),
                              TextButton.icon(
                                  onPressed: _finish,
                                  icon: const Icon(Icons.stop_circle_outlined),
                                  label: const Text('End session'),
                                  style: TextButton.styleFrom(
                                      foregroundColor: Colors.white)),
                              const SizedBox(height: 28),
                            ]),
                    ]))))));
  }
}
