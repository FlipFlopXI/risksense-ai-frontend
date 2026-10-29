import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:medguide/features/wellness/mindfulness_data_source.dart';
import 'package:medguide/features/wellness/breathing_tab.dart';
import 'package:medguide/features/wellness/meditation_tab.dart';
import 'package:medguide/services/weekly_report.dart';
import 'package:medguide/theme/app_theme.dart';
import 'package:medguide/widgets/screen_help.dart';
import 'package:medguide/widgets/weekly_report_button.dart';

class MindfulnessScreen extends StatelessWidget {
  final MindfulnessDataSource? dataSource;
  const MindfulnessScreen({super.key, this.dataSource});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return DefaultTabController(
        length: 3,
        child: Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(title: const Text('Mindfulness'), actions: [
              WeeklyReportButton(
                  createReport: () => WeeklyReportService.mindfulness(
                      mindfulness:
                          dataSource ?? const ApiMindfulnessDataSource(),
                      endDate: DateTime.now())),
              const ScreenHelpButton(topic: 'Mindfulness'),
              const SizedBox(width: 8)
            ]),
            body: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                      SliverToBoxAdapter(
                          child: Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 12, 20, 14),
                              child: Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                      gradient: LinearGradient(colors: [
                                        AppColors.heroStart,
                                        AppColors.heroEnd
                                      ]),
                                      borderRadius: BorderRadius.circular(20)),
                                  child: const Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(Icons.spa_rounded,
                                            color: Colors.white, size: 34),
                                        SizedBox(height: 12),
                                        Text('Make space for how you feel',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 22,
                                                fontWeight: FontWeight.w700)),
                                        SizedBox(height: 7),
                                        Text(
                                            'Track your mood and explore moments of calm at your own pace.',
                                            style: TextStyle(
                                                color: Colors.white,
                                                height: 1.45))
                                      ])))),
                      SliverToBoxAdapter(
                          child: TabBar(
                              labelColor: AppColors.primaryBlue,
                              unselectedLabelColor: AppColors.textSecondary,
                              indicatorColor: AppColors.teal,
                              tabs: const [
                            Tab(text: 'Mood', icon: Icon(Icons.mood_rounded)),
                            Tab(
                                text: 'Breathing',
                                icon: Icon(Icons.air_rounded)),
                            Tab(
                                text: 'Meditation',
                                icon: Icon(Icons.self_improvement_rounded))
                          ])),
                    ],
                body: TabBarView(children: [
                  MoodTab(api: dataSource ?? const ApiMindfulnessDataSource()),
                  BreathingTab(
                      api: dataSource ?? const ApiMindfulnessDataSource()),
                  MeditationTab(
                      api: dataSource ?? const ApiMindfulnessDataSource()),
                ]))));
  }
}

Widget _moodCard(Widget child) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.teal.withValues(alpha: .18))),
    child: child);

const moodOptions = <String>['amazing', 'good', 'fine', 'bad', 'horrible'];
const moodEmotionSuggestions = <String, List<String>>{
  'amazing': [
    'Happy',
    'Joyful',
    'Excited',
    'Grateful',
    'Inspired',
    'Proud',
    'Energized'
  ],
  'good': [
    'Calm',
    'Content',
    'Relaxed',
    'Hopeful',
    'Motivated',
    'Connected',
    'Optimistic'
  ],
  'fine': [
    'Neutral',
    'Steady',
    'Thoughtful',
    'Reflective',
    'Tired',
    'Unsure',
    'Settled'
  ],
  'bad': [
    'Stressed',
    'Frustrated',
    'Anxious',
    'Disappointed',
    'Lonely',
    'Drained',
    'Irritated'
  ],
  'horrible': [
    'Overwhelmed',
    'Distressed',
    'Exhausted',
    'Hurt',
    'Scared',
    'Numb',
    'Upset'
  ],
};

IconData moodIcon(String mood) => switch (mood) {
      'amazing' => Icons.sentiment_very_satisfied_rounded,
      'good' => Icons.sentiment_satisfied_rounded,
      'fine' => Icons.sentiment_neutral_rounded,
      'bad' => Icons.sentiment_dissatisfied_rounded,
      _ => Icons.sentiment_very_dissatisfied_rounded,
    };

Color moodColor(String mood) => switch (mood) {
      '' => AppColors.teal,
      'amazing' => AppColors.teal,
      'good' => AppColors.primaryBlue,
      'fine' => AppColors.amber,
      'bad' => Colors.deepOrange,
      _ => AppColors.danger,
    };

String moodLabel(String mood) => mood.isEmpty
    ? 'Not logged'
    : '${mood[0].toUpperCase()}${mood.substring(1)}';

class MoodTab extends StatefulWidget {
  final MindfulnessDataSource api;
  const MoodTab({super.key, required this.api});
  @override
  State<MoodTab> createState() => _MoodTabState();
}

class _MoodTabState extends State<MoodTab> with SingleTickerProviderStateMixin {
  late Future<Map<String, dynamic>> summary;
  late final AnimationController pulse;
  late final Animation<double> pulseScale;
  final form = GlobalKey<FormState>();
  final emotion = TextEditingController(), reason = TextEditingController();
  String selectedMood = 'fine';
  bool expanded = false, saving = false;
  String get day => DateFormat('yyyy-MM-dd').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    summary = widget.api.moodSummary(day);
    pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1700))
      ..repeat(reverse: true);
    pulseScale = pulse
        .drive(CurveTween(curve: Curves.easeInOut))
        .drive(Tween<double>(begin: .92, end: 1.08));
  }

  @override
  void dispose() {
    pulse.dispose();
    emotion.dispose();
    reason.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>?> refresh({bool reportError = true}) async {
    try {
      final data = await widget.api.moodSummary(day);
      if (mounted) {
        setState(() {
          summary = Future.value(data);
        });
      }
      return data;
    } catch (_) {
      if (reportError) {
        showMessage('Could not refresh your mood timeline. Please try again.');
      }
      return null;
    }
  }

  void showMessage(String message) {
    if (!mounted) return;
    showDialog<void>(
        context: context,
        builder: (dialog) => AlertDialog(
                title: const Text('Mood Log Unavailable'),
                content: Text(message),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(dialog),
                      child: const Text('Dismiss'))
                ]));
  }

  Future<void> save() async {
    if (!form.currentState!.validate() || saving) return;
    final existing = await summary;
    final previousCount =
        (existing['today_entries'] as List? ?? const []).length;
    setState(() {
      saving = true;
    });
    try {
      await widget.api.logMood({
        'log_date': day,
        'mood': selectedMood,
        'emotion': emotion.text.trim(),
        'reason': reason.text.trim()
      });
    } catch (_) {
      final latest = await refresh(reportError: false);
      if (latest == null ||
          (latest['today_entries'] as List? ?? const []).length <=
              previousCount) {
        showMessage(
            'Your entry was not confirmed. Check your timeline before retrying.');
        return;
      }
    } finally {
      if (mounted) {
        setState(() {
          saving = false;
        });
      }
    }
    if (!mounted) return;
    await refresh();
    if (mounted) {
      setState(() {
        expanded = false;
        emotion.clear();
        reason.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return FutureBuilder<Map<String, dynamic>>(
        future: summary,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            if (snapshot.hasError) {
              return Center(
                  child: TextButton(
                      onPressed: () => setState(() {
                            summary = widget.api.moodSummary(day);
                          }),
                      child: const Text('Unable to load moods · Retry')));
            }
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;
          final latest = data['latest'] is Map
              ? Map<String, dynamic>.from(data['latest'] as Map)
              : null;
          final today = (data['today_entries'] as List? ?? const [])
              .whereType<Map>()
              .toList();
          final history =
              (data['history'] as List? ?? const []).whereType<Map>().toList();
          final mood = latest?['mood']?.toString() ?? '';
          return RefreshIndicator(
              onRefresh: () async {
                await refresh();
              },
              child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                  children: [
                    _moodCard(Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                              child: ScaleTransition(
                                  scale: pulseScale,
                                  child: Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: moodColor(mood)
                                              .withValues(alpha: .12)),
                                      child: Icon(
                                          mood.isEmpty
                                              ? Icons.mood_rounded
                                              : moodIcon(mood),
                                          size: 60,
                                          color: moodColor(mood))))),
                          const SizedBox(height: 15),
                          Text('How do you feel?',
                              style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 4),
                          Text(
                              latest == null
                                  ? 'No mood logged today'
                                  : '${moodLabel(mood)} · ${latest['emotion']}',
                              style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: moodColor(mood))),
                          const SizedBox(height: 17),
                          Text('What is the reason for this feeling?',
                              style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 4),
                          Text(
                              latest?['reason']?.toString() ??
                                  'Add a mood to reflect on what is behind it.',
                              style: TextStyle(color: AppColors.textSecondary)),
                          const SizedBox(height: 20),
                          Text('Moods Today',
                              style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 10),
                          if (today.isEmpty)
                            Text('No entries yet.',
                                style:
                                    TextStyle(color: AppColors.textSecondary)),
                          if (today.isNotEmpty)
                            SizedBox(
                                height: 84,
                                child: ListView(
                                    scrollDirection: Axis.horizontal,
                                    children: [
                                      for (final item in today)
                                        Padding(
                                            padding: const EdgeInsets.only(
                                                right: 16),
                                            child: Column(children: [
                                              Icon(moodIcon('${item['mood']}'),
                                                  size: 37,
                                                  color: moodColor(
                                                      '${item['mood']}')),
                                              const SizedBox(height: 5),
                                              Text(_time(item['created_at']),
                                                  style: TextStyle(
                                                      fontSize: 11,
                                                      color: AppColors
                                                          .textSecondary)),
                                            ])),
                                    ])),
                        ])),
                    const SizedBox(height: 16),
                    _moodCard(Column(children: [
                      ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.add_reaction_outlined,
                              color: AppColors.teal),
                          title: Text('Log Mood',
                              style: Theme.of(context).textTheme.headlineSmall),
                          trailing: Icon(
                              expanded ? Icons.expand_less : Icons.expand_more),
                          onTap: () => setState(() {
                                expanded = !expanded;
                              })),
                      if (expanded)
                        Form(
                            key: form,
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Choose a mood',
                                      style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 7),
                                  Wrap(spacing: 7, runSpacing: 5, children: [
                                    for (final value in moodOptions)
                                      ChoiceChip(
                                          avatar: Icon(moodIcon(value),
                                              size: 18,
                                              color: moodColor(value)),
                                          label: Text(moodLabel(value)),
                                          selected: selectedMood == value,
                                          onSelected: (_) => setState(() {
                                                selectedMood = value;
                                              })),
                                  ]),
                                  const SizedBox(height: 17),
                                  Text('What emotion describes how you feel?',
                                      style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 7),
                                  Wrap(spacing: 6, runSpacing: 4, children: [
                                    for (final value in moodEmotionSuggestions[
                                            selectedMood] ??
                                        const <String>[])
                                      ActionChip(
                                          label: Text(value),
                                          onPressed: () => setState(() {
                                                emotion.text = value;
                                              })),
                                  ]),
                                  TextFormField(
                                      controller: emotion,
                                      maxLength: 32,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(
                                            RegExp(r"[A-Za-z'-]"))
                                      ],
                                      decoration: const InputDecoration(
                                          labelText: 'Emotion',
                                          hintText:
                                              'Choose above or enter your own'),
                                      validator: (value) {
                                        final text = value?.trim() ?? '';
                                        if (text.isEmpty)
                                          return 'Describe your emotion';
                                        if (!RegExp(
                                                r"^[A-Za-z]+(?:['-][A-Za-z]+)*$")
                                            .hasMatch(text)) {
                                          return 'Enter one emotion word';
                                        }
                                        return null;
                                      }),
                                  const SizedBox(height: 8),
                                  Text('What is the reason?',
                                      style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 7),
                                  Wrap(spacing: 6, runSpacing: 4, children: [
                                    for (final value in const [
                                      'Work or study',
                                      'Family',
                                      'Health',
                                      'Sleep',
                                      'Exercise',
                                      'Friends',
                                      'Finances',
                                      'Not sure'
                                    ])
                                      ActionChip(
                                          label: Text(value),
                                          onPressed: () => setState(() {
                                                reason.text = value;
                                              })),
                                  ]),
                                  TextFormField(
                                      controller: reason,
                                      maxLength: 120,
                                      decoration: const InputDecoration(
                                          labelText: 'Reason',
                                          hintText:
                                              'Choose above or describe it in your own words'),
                                      validator: (value) {
                                        final text = value?.trim() ?? '';
                                        if (text.isEmpty)
                                          return 'Add a reason or select Not sure';
                                        if (!RegExp(r'[A-Za-z]').hasMatch(text))
                                          return 'Describe the reason in words';
                                        return null;
                                      }),
                                  const SizedBox(height: 10),
                                  Align(
                                      alignment: Alignment.centerRight,
                                      child: FilledButton.icon(
                                          onPressed: saving ? null : save,
                                          icon: const Icon(Icons.check_rounded),
                                          label: const Text('Save Mood'))),
                                ])),
                    ])),
                    const SizedBox(height: 16),
                    _moodCard(Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Mood · Past 7 Days',
                              style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 5),
                          Text(
                              'The icon shows the average of moods logged that day. A gap means no entry.',
                              style: TextStyle(color: AppColors.textSecondary)),
                          const SizedBox(height: 16),
                          SizedBox(
                              height: 175,
                              child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    for (final item in history)
                                      Expanded(
                                          child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                            Icon(
                                                item['average_mood'] == null
                                                    ? Icons.remove_rounded
                                                    : moodIcon(
                                                        '${item['average_mood']}'),
                                                size: 24,
                                                color: item['average_mood'] ==
                                                        null
                                                    ? AppColors.textSecondary
                                                    : moodColor(
                                                        '${item['average_mood']}')),
                                            const SizedBox(height: 4),
                                            Container(
                                                height: item['average_score'] ==
                                                        null
                                                    ? 3
                                                    : 98 *
                                                        ((item['average_score']
                                                                    as num)
                                                                .toDouble() /
                                                            5),
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 3),
                                                decoration: BoxDecoration(
                                                    color: item['average_mood'] ==
                                                            null
                                                        ? AppColors.border
                                                        : moodColor(
                                                            '${item['average_mood']}'),
                                                    borderRadius:
                                                        const BorderRadius.vertical(
                                                            top:
                                                                Radius.circular(
                                                                    5)))),
                                            const SizedBox(height: 5),
                                            Text(
                                                DateFormat.E().format(
                                                    DateTime.tryParse(
                                                            '${item['date']}') ??
                                                        DateTime.now()),
                                                style: TextStyle(
                                                    fontSize: 10,
                                                    color: AppColors
                                                        .textSecondary)),
                                          ]))
                                  ])),
                        ])),
                    const SizedBox(height: 12),
                    Text(
                        'This is a reflection tool, not a mental health assessment.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ]));
        });
  }

  String _time(Object? value) {
    final date = DateTime.tryParse('$value');
    return date == null
        ? 'Time unavailable'
        : DateFormat.jm().format(date.toLocal());
  }
}
