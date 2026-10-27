import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:medguide/screens/auth/login_screen.dart';
import 'package:medguide/screens/clinician/linked_patient_detail_screen.dart';
import 'package:medguide/screens/clinician/clinician_prediction_screen.dart';
import 'package:medguide/screens/shared/data_input_screen.dart';
import 'package:medguide/screens/shared/settings_screen.dart';
import 'package:medguide/services/api_client.dart';
import 'package:medguide/services/app_preferences.dart';
import 'package:medguide/theme/app_theme.dart';
import 'package:medguide/widgets/screen_help.dart';
import 'package:medguide/widgets/shared_widgets.dart';

String _date(dynamic value) {
  final date = DateTime.tryParse(value?.toString() ?? '');
  return date == null
      ? 'Not recorded'
      : DateFormat.yMMMd().add_jm().format(date.toLocal());
}

Map<String, dynamic> _patientCard(Map source) {
  final patient = Map<String, dynamic>.from(source['patient'] as Map);
  final prediction = source['latest_prediction'] as Map?;
  return {
    ...patient,
    'name': '${patient['first_name']} ${patient['last_name']}',
    'latest_prediction': prediction,
    'latest_diabetes': source['latest_diabetes'],
    'latest_heart': source['latest_heart'],
    'high_alert': source['high_alert'] == true,
  };
}

class ClinicianDashboard extends StatefulWidget {
  const ClinicianDashboard({super.key});
  @override
  State<ClinicianDashboard> createState() => _ClinicianDashboardState();
}

class _ClinicianDashboardState extends State<ClinicianDashboard> {
  final _search = TextEditingController();
  late Future<List<Map<String, dynamic>>> _data;
  List<Map<String, dynamic>>? _lastData;
  int _tab = 0;
  String _filter = 'All patients', _sort = 'Name (A–Z)';

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _data = Future.wait([
      ApiClient.instance.get('/clinicians/dashboard'),
      ApiClient.instance.get('/clinicians/profile'),
    ]).then((rows) {
      final data =
          rows.map((row) => Map<String, dynamic>.from(row as Map)).toList();
      _lastData = data;
      return data;
    });
  }

  void _navigate(int tab, {bool highOnly = false}) => setState(() {
        _tab = tab;
        if (highOnly) _filter = 'High alerts';
        if (tab != 2) _reload();
      });
  Future<void> _signOut() async {
    await ApiClient.instance.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  Future<void> _showClinicianId(String id) => showDialog<void>(
      context: context,
      builder: (dialog) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('RiskSense Clinician ID',
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 12),
                    SelectableText(id),
                    const SizedBox(height: 16),
                    Row(children: [
                      TextButton(
                          onPressed: () => Navigator.pop(dialog),
                          child: const Text('Back')),
                      const Spacer(),
                      FilledButton.icon(
                          onPressed: () async {
                            await Clipboard.setData(ClipboardData(text: id));
                            if (dialog.mounted) Navigator.pop(dialog);
                          },
                          icon: const Icon(Icons.copy_rounded),
                          label: const Text('Copy ID'))
                    ]),
                  ]))));
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Scaffold(
        body: _tab == 2
            ? const DataInputScreen(clinicianMode: true)
            : FutureBuilder<List<Map<String, dynamic>>>(
                future: _data,
                builder: (context, state) {
                  if (state.hasError && _lastData == null)
                    return Center(
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                      Text('Unable to load clinician data: ${state.error}',
                          textAlign: TextAlign.center),
                      TextButton(
                          onPressed: () => setState(_reload),
                          child: const Text('Retry'))
                    ]));
                  if (!state.hasData && _lastData == null)
                    return const Center(child: CircularProgressIndicator());
                  final rows = state.data ?? _lastData!;
                  final dashboard = rows[0], profile = rows[1];
                  return switch (_tab) {
                    0 => _dashboard(dashboard, profile),
                    1 => _patients(dashboard),
                    _ => _profile(profile),
                  };
                }),
        bottomNavigationBar: AnimatedBuilder(
          animation: AppPreferences.instance,
          builder: (context, _) => BottomNavigationBar(
            currentIndex: _tab,
            onTap: _navigate,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppColors.primaryBlue,
            unselectedItemColor: AppColors.textLight,
            backgroundColor: AppColors.cardWhite,
            items: const [
              BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.people_outline_rounded), label: 'Patients'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.analytics_outlined), label: 'Analysis'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline_rounded), label: 'Profile'),
            ],
          ),
        ),
      );
  }

  Widget _dashboard(Map<String, dynamic> data, Map<String, dynamic> profile) {
    final alerts = (data['alerts'] as List? ?? []).whereType<Map>().toList();
    final cases =
        (data['recent_cases'] as List? ?? []).whereType<Map>().toList();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
          backgroundColor: AppColors.cardWhite,
          automaticallyImplyLeading: false,
          title: const Text('Clinician Dashboard'),
          actions: const [ScreenHelpButton(topic: 'Clinician Dashboard')]),
      body: RefreshIndicator(
          onRefresh: () async {
            setState(_reload);
            await _data;
          },
          child: ListView(padding: const EdgeInsets.all(20), children: [
            Text('Welcome, ${profile['first_name'] ?? 'Clinician'}',
                style: Theme.of(context).textTheme.headlineLarge),
            Text(DateFormat.yMMMMEEEEd().format(DateTime.now()),
                style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            GridView(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent: 138),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                StatCard(
                    title: 'High Risk Alerts',
                    value: '${data['high_risk_alerts'] ?? 0}',
                    icon: Icons.warning_amber_rounded,
                    color: AppColors.danger),
                StatCard(
                    title: 'Total Patients',
                    value: '${data['total_patients'] ?? 0}',
                    icon: Icons.people_rounded,
                    color: AppColors.primaryBlue),
                StatCard(
                    title: 'Predictions Today',
                    value: '${data['predictions_today'] ?? 0}',
                    icon: Icons.analytics_rounded,
                    color: AppColors.teal),
                StatCard(
                    title: 'Drug Enquiries',
                    value: '${data['drug_enquiries'] ?? 0}',
                    subtitle: 'Linked patients',
                    icon: Icons.medication_liquid_outlined,
                    color: AppColors.amber),
              ],
            ),
            const SizedBox(height: 24),
            SectionHeader(
                title: 'High Risk Alerts',
                actionLabel: 'View All',
                onAction: () => _navigate(1, highOnly: true)),
            const SizedBox(height: 12),
            if (alerts.isEmpty) const _Empty('No current high-risk alerts.'),
            for (final item in alerts.take(5)) _case(item, alert: true),
            const SizedBox(height: 20),
            const SectionHeader(title: 'Recent Cases'),
            const SizedBox(height: 12),
            if (cases.isEmpty) const _Empty('No linked-patient analyses yet.'),
            for (final item in cases) _case(item),
          ])),
    );
  }

  Widget _case(Map item, {bool alert = false}) {
    final patient = Map<String, dynamic>.from(item['patient'] as Map);
    final prediction = Map<String, dynamic>.from(item['prediction'] as Map);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: alert ? AppColors.danger.withOpacity(.05) : AppColors.cardWhite,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
              color: alert
                  ? AppColors.danger.withOpacity(.25)
                  : AppColors.border)),
      child: ListTile(
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => ClinicianPredictionScreen(
                    patientId: patient['id'].toString(),
                    predictionId: prediction['id'].toString()))),
        leading: CircleAvatar(
            backgroundColor: alert
                ? AppColors.danger.withOpacity(.1)
                : AppColors.surfaceBlue,
            child: Icon(
                alert ? Icons.warning_rounded : Icons.analytics_outlined,
                color: alert ? AppColors.danger : AppColors.primaryBlue)),
        title: Text('${patient['first_name']} ${patient['last_name']}',
            maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
            '${prediction['prediction_target'] == 'diabetes_risk' ? 'Diabetes' : 'Heart Disease'} • ${_date(prediction['predicted_at'])}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }

  static const _filters = [
    'All patients',
    'High alerts',
    'Diabetes analyses',
    'Heart Disease analyses',
    'No analyses'
  ];
  static const _sorts = [
    'Name (A–Z)',
    'Name (Z–A)',
    'Most recent analysis',
    'Oldest analysis'
  ];

  Future<void> _showFilters() async {
    var selected = _filter, ordering = _sort;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheet) => StatefulBuilder(
          builder: (context, update) => SafeArea(
                child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Filter patients',
                            style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 14),
                        Wrap(spacing: 8, runSpacing: 5, children: [
                          for (final option in _filters)
                            ChoiceChip(
                                label: Text(option),
                                selected: selected == option,
                                onSelected: (_) =>
                                    update(() => selected = option)),
                        ]),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                            initialValue: ordering,
                            decoration:
                                const InputDecoration(labelText: 'Sort order'),
                            items: [
                              for (final value in _sorts)
                                DropdownMenuItem(
                                    value: value, child: Text(value))
                            ],
                            onChanged: (value) =>
                                update(() => ordering = value!)),
                        const SizedBox(height: 18),
                        Row(children: [
                          TextButton(
                              onPressed: () {
                                setState(() {
                                  _filter = _filters.first;
                                  _sort = _sorts.first;
                                });
                                Navigator.pop(sheet);
                              },
                              child: const Text('Reset')),
                          const Spacer(),
                          FilledButton(
                              onPressed: () {
                                setState(() {
                                  _filter = selected;
                                  _sort = ordering;
                                });
                                Navigator.pop(sheet);
                              },
                              child: const Text('Apply filters')),
                        ]),
                      ],
                    )),
              )),
    );
  }

  Widget _patients(Map<String, dynamic> data) {
    final query = _search.text.trim().toLowerCase();
    final rows = (data['patients'] as List? ?? [])
        .whereType<Map>()
        .map(_patientCard)
        .where((p) => ('${p['name']} ${p['id']}').toLowerCase().contains(query))
        .where((p) => switch (_filter) {
              'High alerts' => p['high_alert'] == true,
              'Diabetes analyses' => p['latest_diabetes'] != null,
              'Heart Disease analyses' => p['latest_heart'] != null,
              'No analyses' => p['latest_prediction'] == null,
              _ => true,
            })
        .toList();
    rows.sort((a, b) {
      final byName = (a['name'] as String).compareTo(b['name'] as String);
      final aTime =
          (a['latest_prediction'] as Map?)?['predicted_at']?.toString() ?? '';
      final bTime =
          (b['latest_prediction'] as Map?)?['predicted_at']?.toString() ?? '';
      return switch (_sort) {
        'Name (Z–A)' => -byName,
        'Most recent analysis' => bTime.compareTo(aTime),
        'Oldest analysis' => aTime.compareTo(bTime),
        _ => byName,
      };
    });
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
          title: const Text('Patients'),
          backgroundColor: AppColors.cardWhite,
          actions: const [ScreenHelpButton(topic: 'Patients')]),
      body: Column(children: [
        Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Expanded(
                  child: TextField(
                      controller: _search,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                          hintText: 'Search by name or patient ID',
                          prefixIcon: Icon(Icons.search_rounded)))),
              IconButton.filledTonal(
                  tooltip: 'Filter and sort',
                  onPressed: _showFilters,
                  icon: const Icon(Icons.tune_rounded)),
            ])),
        if (_filter != _filters.first)
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                  alignment: Alignment.centerLeft,
                  child: Chip(
                      label: Text(_filter),
                      onDeleted: () =>
                          setState(() => _filter = _filters.first)))),
        Expanded(
            child: rows.isEmpty
                ? const Center(child: _Empty('No matching linked patients.'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: rows.length,
                    itemBuilder: (context, index) {
                      final patient = rows[index];
                      final high = patient['high_alert'] == true;
                      final prediction = patient['latest_prediction'] as Map?;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        color: AppColors.cardWhite,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(color: AppColors.border)),
                        child: ListTile(
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        PatientDetailScreen(patient: patient))),
                            leading: CircleAvatar(
                                backgroundColor: high
                                    ? AppColors.danger.withOpacity(.1)
                                    : AppColors.surfaceBlue,
                                child: Text(
                                    (patient['name'] as String).substring(0, 1),
                                    style: TextStyle(
                                        color: high
                                            ? AppColors.danger
                                            : AppColors.primaryBlue))),
                            title: Text(patient['name'],
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text(
                                '${prediction == null ? 'No analysis yet' : prediction['prediction_target'] == 'diabetes_risk' ? 'Diabetes' : 'Heart Disease'} • ${_date(prediction?['predicted_at'])}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                            trailing: Icon(
                                high
                                    ? Icons.warning_amber_rounded
                                    : Icons.chevron_right_rounded,
                                color: high
                                    ? AppColors.danger
                                    : AppColors.textLight)),
                      );
                    })),
      ]),
    );
  }

  Widget _profile(Map<String, dynamic> profile) => AnimatedBuilder(
      animation: AppPreferences.instance,
      builder: (context, _) => Scaffold(
            backgroundColor: AppColors.background,
            appBar: MedAppBar(
                title: 'My Profile',
                helpTopic: 'Clinician Profile',
                showSecureBadge: false,
                actions: [
                  IconButton(
                      tooltip: 'Settings',
                      icon: Icon(Icons.settings_outlined,
                          color: AppColors.primaryBlue),
                      onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) =>
                                  const SettingsScreen(role: 'clinician'))))
                ]),
            body: ListView(padding: const EdgeInsets.all(20), children: [
              Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: profile['gender'] == 'female'
                              ? AppColors.clinicianFemaleGradient
                              : [AppColors.heroStart, AppColors.heroEnd]),
                      borderRadius: BorderRadius.circular(16)),
                  child: Column(children: [
                    const Icon(Icons.person_rounded,
                        size: 62, color: Colors.white),
                    const SizedBox(height: 12),
                    Text('${profile['first_name']} ${profile['last_name']}',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(color: Colors.white),
                        textAlign: TextAlign.center),
                    Text(
                        '${profile['professional_title'] ?? 'Clinician'} • ${profile['specialization'] ?? 'Specialization not recorded'}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70)),
                  ])),
              const SizedBox(height: 14),
              Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: Icon(Icons.badge_outlined,
                        color: AppColors.primaryBlue),
                    title: Text('RiskSense Clinician ID',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                    subtitle: InkWell(
                        onTap: () => _showClinicianId(
                            '${profile['risk_sense_id'] ?? 'Not recorded'}'),
                        child: Text('Tap To View ID',
                            style: TextStyle(
                                color: AppColors.primaryBlue,
                                decoration: TextDecoration.underline))),
                  )),
              for (final item in <(IconData, String, String)>[
                (
                  Icons.verified_user_outlined,
                  'License Number',
                  '${profile['license_number'] ?? 'Not recorded'}'
                ),
                (
                  Icons.local_hospital_outlined,
                  'Institution',
                  '${profile['institution'] ?? 'Not recorded'}'
                ),
                (
                  Icons.email_outlined,
                  'Email',
                  '${profile['email'] ?? 'Not recorded'}'
                ),
                (
                  Icons.history_outlined,
                  'Last Login',
                  _date(profile['last_login_at'])
                ),
                (
                  Icons.person_outline_rounded,
                  'Gender',
                  switch (profile['gender']) {
                    'female' => 'Female',
                    'male' => 'Male',
                    _ => 'Unspecified',
                  }
                ),
              ])
                Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                        leading: Icon(item.$1, color: AppColors.primaryBlue),
                        title: Text(item.$2,
                            style: TextStyle(
                                fontSize: 12, color: AppColors.textSecondary)),
                        subtitle: Text(item.$3,
                            maxLines: 2, overflow: TextOverflow.ellipsis))),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                  onPressed: _signOut,
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Sign Out'),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: BorderSide(color: AppColors.danger))),
            ]),
          ));
}

class _Empty extends StatelessWidget {
  final String message;
  const _Empty(this.message);
  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Text(message,
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary)));
  }
}
