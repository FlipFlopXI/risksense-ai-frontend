import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:medguide/theme/app_theme.dart';
import 'package:medguide/widgets/shared_widgets.dart';
import 'package:medguide/widgets/screen_help.dart';
import 'package:medguide/services/api_client.dart';
import 'package:intl/intl.dart';
import 'package:medguide/screens/shared/prediction_result_screen.dart';
import 'package:medguide/screens/shared/data_input_screen.dart';
import 'package:medguide/screens/shared/history_screen.dart';
import 'package:medguide/screens/shared/ai_assistant_screen.dart';
import 'package:medguide/screens/patient/patient_profile_screen.dart';
import 'package:medguide/features/wellness/wellness_screen.dart';

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({super.key});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  int _currentIndex = 0;
  int _dashboardEpoch = 0;
  int _healthEpoch = 0;
  int _historyEpoch = 0;
  int _profileEpoch = 0;
  RiskLevelFilter _historyInitialLevel = RiskLevelFilter.all;

  void _openRiskHistory(RiskLevelFilter level) => setState(() {
        _historyInitialLevel = level;
        _historyEpoch++;
        _currentIndex = 2;
      });

  @override
  Widget build(BuildContext context) {
    final pages = [
      _HomeTab(key: ValueKey(_dashboardEpoch), onRiskNotice: _openRiskHistory),
      _HealthTab(key: ValueKey(_healthEpoch)),
      HistoryScreen(
          key: ValueKey(_historyEpoch), initialLevel: _historyInitialLevel),
      const AiAssistantScreen(),
      PatientProfileScreen(key: ValueKey(_profileEpoch)),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.cardWhite,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() {
            _currentIndex = i;
            _historyInitialLevel = RiskLevelFilter.all;
            if (i == 0) _dashboardEpoch++;
            if (i == 1) _healthEpoch++;
            if (i == 2) _historyEpoch++;
            if (i == 4) _profileEpoch++;
          }),
          selectedItemColor: AppColors.primaryBlue,
          unselectedItemColor: AppColors.textLight,
          backgroundColor: AppColors.cardWhite,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle:
              const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.monitor_heart_outlined),
              activeIcon: Icon(Icons.monitor_heart_rounded),
              label: 'Health',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_outlined),
              activeIcon: Icon(Icons.history_rounded),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline_rounded),
              activeIcon: Icon(Icons.chat_bubble_rounded),
              label: 'Assistant',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Home Tab ─────────────────────────────────────────────────────────────────
class _HomeTab extends StatefulWidget {
  final ValueChanged<RiskLevelFilter> onRiskNotice;
  const _HomeTab({super.key, required this.onRiskNotice});

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  static const _noticeStorage = FlutterSecureStorage();
  late Future<Map<String, dynamic>> _dashboard = _load();

  Future<Map<String, dynamic>> _load() async {
    final data = Map<String, dynamic>.from(
        await ApiClient.instance.get('/dashboard'));
    final user = Map<String, dynamic>.from(
        await ApiClient.instance.get('/auth/me'));
    final noticeKey = 'risk_notice_seen_${user['id']}';
    data['_notice_key'] = noticeKey;
    data['_seen_prediction'] = await _noticeStorage.read(key: noticeKey);
    return data;
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _dashboard,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return Scaffold(
              body: Center(
                  child: ElevatedButton(
                      onPressed: () => setState(() {
                            _dashboard = _load();
                          }),
                      child: const Text('Retry dashboard'))));
        }
        return _content(context, snapshot.data!);
      },
    );
  }

  Widget _content(BuildContext context, Map<String, dynamic> data) {
    final predictions = (data['latest_predictions'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    Map<String, dynamic>? prediction(String target) {
      for (final item in predictions) {
        if (item['prediction_target'] == target) return item;
      }
      return null;
    }

    final diabetes = prediction('diabetes_risk');
    final heart = prediction('heart_disease');
    final newest = [...predictions]..sort((a, b) =>
        (DateTime.tryParse(b['predicted_at']?.toString() ?? '') ?? DateTime(1970))
            .compareTo(DateTime.tryParse(a['predicted_at']?.toString() ?? '') ?? DateTime(1970)));
    final latest = newest.isEmpty ? null : newest.first;
    final latestScore = (latest?['risk_score'] as num?)?.toDouble();
    final noticeLevel = latestScore == null || latestScore < .35
        ? null
        : latestScore >= .65 ? RiskLevelFilter.high : RiskLevelFilter.moderate;
    final noticeId = latest?['id']?.toString();
    final showNotice = noticeLevel != null && noticeId != null &&
        noticeId != data['_seen_prediction'];
    final diabetesScore = (diabetes?['risk_score'] as num?)?.toDouble();
    final heartScore = (heart?['risk_score'] as num?)?.toDouble();
    final updated =
        DateTime.tryParse(data['last_updated_at']?.toString() ?? '')?.toLocal();
    final updatedLabel = updated == null
        ? 'Not updated yet'
        : DateUtils.isSameDay(updated, DateTime.now())
            ? 'Updated today'
            : 'Updated ${DateFormat.yMMMd().format(updated)}';
    String number(dynamic value, {int decimals = 0}) =>
        value == null ? '—' : (value as num).toStringAsFixed(decimals);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardWhite,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('RiskSense AI'),
        actions: [
          IconButton(
            tooltip: showNotice ? 'New risk analysis result' : 'Prediction history',
            icon: Badge(
              isLabelVisible: showNotice,
              backgroundColor: noticeLevel == RiskLevelFilter.high
                  ? AppColors.riskHigh : AppColors.riskMedium,
              child: const Icon(Icons.notifications_outlined,
                  color: AppColors.primaryBlue, size: 22),
            ),
            onPressed: () async {
              if (showNotice) {
                await _noticeStorage.write(
                    key: data['_notice_key'].toString(), value: noticeId);
                if (!mounted) return;
                setState(() => data['_seen_prediction'] = noticeId);
              }
              widget.onRiskNotice(noticeLevel ?? RiskLevelFilter.all);
            },
          ),
          const ScreenHelpButton(topic: 'Dashboard'),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '${_greeting()},\n',
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                      fontFamily: 'DMSans',
                    ),
                  ),
                  TextSpan(
                    text: data['patient_first_name']?.toString() ?? 'Patient',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontFamily: 'DMSans',
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "Here's your current health risk overview",
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),

            // Risk Overview Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withValues(alpha: 0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Risk Overview',
                          style: Theme.of(context).textTheme.headlineSmall),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.amber.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          updatedLabel,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.amber,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      GestureDetector(
                        onTap: diabetesScore == null
                            ? null
                            : () =>
                                Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => PredictionResultScreen(
                                      condition: 'Diabetes',
                                      riskScore: diabetesScore),
                                )),
                        child: RiskMeterWidget(
                            label: 'Diabetes', percent: diabetesScore ?? 0),
                      ),
                      Container(width: 1, height: 80, color: AppColors.border),
                      GestureDetector(
                        onTap: heartScore == null
                            ? null
                            : () =>
                                Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => PredictionResultScreen(
                                      condition: 'Heart Disease',
                                      riskScore: heartScore),
                                )),
                        child: RiskMeterWidget(
                            label: 'Heart Disease', percent: heartScore ?? 0),
                      ),
                      Container(width: 1, height: 80, color: AppColors.border),
                      CountMeterWidget(
                          label: 'Drug Enquiries',
                          count:
                              data['drug_response_enquiries_today'] as int? ??
                                  0),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Update CTA
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.analytics_outlined, size: 20),
                label: const Text('Update Health Metrics'),
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const DataInputScreen()),
                  );
                  if (mounted) {
                    setState(() {
                      _dashboard = _load();
                    });
                  }
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => MealPlanScreen(dashboard: data),
                    )),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 11),
                      foregroundColor: AppColors.teal,
                      side: const BorderSide(color: AppColors.teal),
                    ),
                    child:
                        const Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.restaurant_menu_rounded, size: 20),
                      SizedBox(height: 5),
                      Text('Generate Meal Plan',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => FitnessRoutineScreen(dashboard: data),
                    )),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 11),
                    ),
                    child:
                        const Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.fitness_center_rounded, size: 20),
                      SizedBox(height: 5),
                      Text('Generate Fitness Routine',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            const SectionHeader(title: 'Quick Stats'),
            const SizedBox(height: 12),
            GridView(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: 174,
              ),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                StatCard(
                  compact: true,
                  title: 'BMI',
                  value: number(data['bmi'], decimals: 1),
                  icon: Icons.monitor_weight_outlined,
                  color: AppColors.amber,
                  subtitle: 'Latest recorded BMI',
                ),
                StatCard(
                  compact: true,
                  title: 'Blood Pressure',
                  value:
                      '${number(data['latest_systolic_bp'])}/${number(data['latest_diastolic_bp'])}',
                  icon: Icons.favorite_border_rounded,
                  color: AppColors.danger,
                  subtitle: 'Latest recorded BP',
                ),
                StatCard(
                  compact: true,
                  title: 'Glucose',
                  value:
                      '${number(data['latest_glucose'], decimals: 1)} ${data['latest_glucose_unit'] ?? ''}'
                          .trim(),
                  icon: Icons.water_drop_outlined,
                  color: AppColors.primaryBlue,
                  subtitle: 'Latest lab result',
                ),
                StatCard(
                  compact: true,
                  title: 'Predictions',
                  value: '${data['prediction_count'] ?? 0}',
                  icon: Icons.history_rounded,
                  color: AppColors.success,
                  subtitle: 'This month',
                ),
              ],
            ),
            const SizedBox(height: 30),
            const DisclaimerBanner(),
            const SizedBox(height: 16),
            const _SessionExpiryBadge(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _SessionExpiryBadge extends StatelessWidget {
  const _SessionExpiryBadge();

  @override
  Widget build(BuildContext context) => StreamBuilder<DateTime>(
        stream: Stream<DateTime>.periodic(
            const Duration(seconds: 30), (_) => DateTime.now()),
        initialData: DateTime.now(),
        builder: (context, snapshot) {
          final expires = ApiClient.instance.accessTokenExpiresAt;
          final remaining =
              expires?.difference(snapshot.data ?? DateTime.now());
          final label = remaining == null
              ? 'Session expiry unavailable'
              : remaining.isNegative
                  ? 'Session access token expired'
                  : 'Session access token expires in: ${remaining.inMinutes + 1} minutes';
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              const Icon(Icons.timer_outlined,
                  size: 16, color: AppColors.primaryBlue),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(label,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w500,
                      ))),
            ]),
          );
        },
      );
}

// ─── Health Tab ───────────────────────────────────────────────────────────────
class _HealthTab extends StatefulWidget {
  const _HealthTab({super.key});

  @override
  State<_HealthTab> createState() => _HealthTabState();
}

class _HealthTabState extends State<_HealthTab> {
  late Future<Map<String, dynamic>> _trends;

  @override
  void initState() {
    super.initState();
    _trends = _loadTrends();
  }

  Future<Map<String, dynamic>> _loadTrends() async =>
      Map<String, dynamic>.from(await ApiClient.instance.get('/health/trends'));

  Future<void> _refresh() async {
    final next = _loadTrends();
    setState(() => _trends = next);
    await next;
  }

  List<DateTime> get _days {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));
  }

  List<FlSpot> _dailySpots(
    dynamic raw,
    String timestampKey,
    String valueKey,
  ) {
    final records = raw is List ? raw : const [];
    final newestByDay = <DateTime, ({DateTime time, double value})>{};
    for (final item in records) {
      if (item is! Map) continue;
      final measuredAt =
          DateTime.tryParse(item[timestampKey]?.toString() ?? '');
      final value = (item[valueKey] as num?)?.toDouble();
      if (measuredAt == null || value == null) continue;
      final local = measuredAt.toLocal();
      final day = DateTime(local.year, local.month, local.day);
      final existing = newestByDay[day];
      if (existing == null || measuredAt.isAfter(existing.time)) {
        newestByDay[day] = (time: measuredAt, value: value);
      }
    }
    return [
      for (var i = 0; i < _days.length; i++)
        if (newestByDay[_days[i]] case final reading?)
          FlSpot(i.toDouble(), reading.value),
    ];
  }

  ({double min, double max}) _bounds(List<FlSpot> spots) {
    if (spots.isEmpty) return (min: 0, max: 100);
    final values = spots.map((spot) => spot.y);
    var low = values.reduce((a, b) => a < b ? a : b);
    var high = values.reduce((a, b) => a > b ? a : b);
    final spread = high - low;
    final padding = spread == 0 ? (high.abs() * .1).clamp(1, 20) : spread * .25;
    low = (low - padding).clamp(0, double.infinity);
    high += padding;
    return (min: low, max: high);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MedAppBar(
        title: 'Health Trends',
        showSecureBadge: false,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _trends,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _refresh,
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            );
          }
          final data = snapshot.data ?? const <String, dynamic>{};
          final glucose =
              _dailySpots(data['fasting_glucose'], 'measured_at', 'value');
          final bmi =
              _dailySpots(data['body_measurements'], 'measured_at', 'bmi');
          final systolic =
              _dailySpots(data['blood_pressure'], 'recorded_at', 'systolic');
          final glucoseBounds = _bounds(glucose);
          final bmiBounds = _bounds(bmi);
          final systolicBounds = _bounds(systolic);
          final labels =
              _days.map((day) => DateFormat('EEE\nd').format(day)).toList();
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                Text('Monitoring Overview',
                    style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: 4),
                Text('Your tracked metrics over the last 7 days',
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 20),
                _TrendCard(
                  title: 'Blood Glucose',
                  unit: 'mg/dL',
                  color: AppColors.primaryBlue,
                  spots: glucose,
                  dayLabels: labels,
                  minY: glucoseBounds.min,
                  maxY: glucoseBounds.max,
                ),
                const SizedBox(height: 14),
                _TrendCard(
                  title: 'BMI Trend',
                  unit: 'BMI',
                  color: AppColors.amber,
                  spots: bmi,
                  dayLabels: labels,
                  minY: bmiBounds.min,
                  maxY: bmiBounds.max,
                ),
                const SizedBox(height: 14),
                _TrendCard(
                  title: 'Systolic Blood Pressure',
                  unit: 'mmHg',
                  color: AppColors.danger,
                  spots: systolic,
                  dayLabels: labels,
                  minY: systolicBounds.min,
                  maxY: systolicBounds.max,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  final String title;
  final String unit;
  final Color color;
  final List<FlSpot> spots;
  final List<String> dayLabels;
  final double minY;
  final double maxY;

  const _TrendCard({
    required this.title,
    required this.unit,
    required this.color,
    required this.spots,
    required this.dayLabels,
    required this.minY,
    required this.maxY,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  )),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(unit,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: color)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: spots.isEmpty
                ? const Center(
                    child: Text(
                      'No readings recorded in the last 7 days',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      minX: 0,
                      maxX: 6,
                      minY: minY,
                      maxY: maxY,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: (maxY - minY) / 4,
                        getDrawingHorizontalLine: (v) => const FlLine(
                            color: AppColors.border, strokeWidth: 1),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 38,
                            interval: (maxY - minY) / 2,
                            getTitlesWidget: (v, _) => Text(
                              v.toInt().toString(),
                              style: const TextStyle(
                                  fontSize: 10, color: AppColors.textLight),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            getTitlesWidget: (v, _) {
                              final i = v.toInt();
                              if (i >= 0 && i < dayLabels.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(dayLabels[i],
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          fontSize: 9,
                                          color: AppColors.textLight)),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: color,
                          barWidth: 2.5,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, bar, index) =>
                                FlDotCirclePainter(
                              radius: 3,
                              color: color,
                              strokeWidth: 1.5,
                              strokeColor: Colors.white,
                            ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: color.withValues(alpha: 0.06),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
