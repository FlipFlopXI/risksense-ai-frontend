import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medguide/screens/auth/login_screen.dart';
import 'package:medguide/screens/shared/change_password_dialog.dart';
import 'package:medguide/screens/shared/health_conditions_dialog.dart';
import 'package:medguide/services/api_client.dart';
import 'package:medguide/services/app_preferences.dart';
import 'package:medguide/services/recorded_conditions.dart';
import 'package:medguide/services/vital_sync.dart';
import 'package:medguide/theme/app_theme.dart';
import 'package:medguide/widgets/shared_widgets.dart';
import 'package:medguide/widgets/wearable_sync_button.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  final String role;
  const SettingsScreen({super.key, required this.role});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Future<List<Map<String, dynamic>>> _sessions = _loadSessions();

  Future<List<Map<String, dynamic>>> _loadSessions() async =>
      (await ApiClient.instance.get('/auth/sessions') as List)
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList();

  void _refreshSessions() => setState(() => _sessions = _loadSessions());

  Future<void> _error(Object error) async {
    if (!mounted) return;
    await showDialog<void>(
        context: context,
        builder: (dialog) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: const Text('Unable To Complete Action'),
              content: Text(error is ApiException
                  ? error.message
                  : error is String
                      ? error
                      : 'Please try again.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(dialog),
                    child: const Text('Dismiss'))
              ],
            ));
  }

  Future<void> _changePassword() async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (_) => const ChangePasswordDialog(),
    );
    if (changed == true && mounted) {
      _refreshSessions();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Password changed. Other sessions were signed out.'),
      ));
    }
  }

  Future<void> _updateHealthConditions() async {
    try {
      final profile = Map<String, dynamic>.from(
          await ApiClient.instance.get('/health/profile') as Map);
      if (!mounted) return;
      final updated = await showDialog<RecordedConditions>(
        context: context,
        builder: (_) => HealthConditionsDialog(
          initial: RecordedConditions.fromText(
              profile['existing_conditions']?.toString()),
        ),
      );
      if (updated == null || !mounted) return;
      await ApiClient.instance.put('/health/profile', data: {
        'existing_conditions': updated.toProfileText(),
      });
      if (!mounted) return;
    } catch (error) {
      await _error(error);
    }
  }

  Future<void> _revoke(Map<String, dynamic> row) async {
    final approved = await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: const Text('Sign Out Other Session?'),
              content: const Text('That session will need to sign in again.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(dialog, false),
                    child: const Text('Keep Session')),
                FilledButton(
                    onPressed: () => Navigator.pop(dialog, true),
                    child: const Text('Sign Out')),
              ],
            ));
    if (approved != true) return;
    try {
      await ApiClient.instance.delete('/auth/sessions/${row['id']}');
      if (mounted) _refreshSessions();
    } catch (error) {
      await _error(error);
    }
  }

  Future<void> _showClinician() async {
    try {
      final data = Map<String, dynamic>.from(
          await ApiClient.instance.get('/patients/me/clinician'));
      if (!mounted) return;
      final name = (data['display_name']?.toString().trim().isNotEmpty ?? false)
          ? data['display_name'].toString().trim()
          : 'Linked clinician';
      final title = data['professional_title']?.toString().trim() ?? '';
      final specialization = data['specialization']?.toString().trim() ?? '';
      final institution = data['institution']?.toString().trim() ?? '';
      final id = data['risk_sense_id']?.toString().trim() ?? '';
      await _showSettingsInfo(
        title: 'Your Linked Clinician',
        icon: Icons.medical_services_outlined,
        intro: 'The clinician currently linked to your patient account.',
        sections: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [AppColors.heroStart, AppColors.heroEnd]),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: Colors.white.withValues(alpha: .18),
                child: Text(name.isEmpty ? 'C' : name[0].toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 14),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(title.isEmpty ? name : '$title $name',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    const Text('Connected to your care profile',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ])),
            ]),
          ),
          if (specialization.isNotEmpty)
            _settingsDetail(
                Icons.biotech_outlined, 'Specialization', specialization),
          if (institution.isNotEmpty)
            _settingsDetail(
                Icons.local_hospital_outlined, 'Institution', institution),
          if (id.isNotEmpty)
            _settingsDetail(Icons.badge_outlined, 'RiskSense Clinician ID', id),
          _settingsNote(Icons.shield_outlined,
              'This link allows your approved clinician to view permitted patient information. Access is checked by the backend for each protected request.'),
        ],
        disclaimer:
            'If this clinician does not look familiar, contact RiskSense AI support. A link does not replace direct clinical care.',
      );
    } on ApiException catch (error) {
      if (error.statusCode == 404) {
        if (!mounted) return;
        await _showSettingsInfo(
          title: 'Linked Clinician',
          icon: Icons.person_off_outlined,
          intro: 'No clinician is currently linked to your patient account.',
          sections: [
            _settingsNote(Icons.info_outline_rounded,
                'A clinician relationship is established through the approved access activation flow. If you expected a link, check your account activation or contact support.'),
          ],
          disclaimer:
              'Clinicians cannot view your patient record without an authorized link.',
        );
      } else {
        await _error(error);
      }
    }
  }

  Widget _settingsDetail(IconData icon, String label, String value) =>
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          Icon(icon, color: AppColors.teal, size: 23),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(label,
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 11)),
                const SizedBox(height: 3),
                Text(value,
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600)),
              ])),
        ]),
      );

  Widget _settingsNote(IconData icon, String text) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceTeal,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.teal.withValues(alpha: .25)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: AppColors.teal, size: 22),
          const SizedBox(width: 11),
          Expanded(
              child: Text(text,
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      height: 1.4,
                      fontSize: 12))),
        ]),
      );

  Future<void> _showAbout() => _showSettingsInfo(
        title: 'About RiskSense AI',
        icon: Icons.info_outline_rounded,
        intro:
            'A health decision-support companion built around risk awareness, useful habits and clinician-linked access.',
        sections: [
          _settingsDetail(Icons.favorite_outline_rounded, 'Risk analysis',
              'Diabetes and heart disease models estimate risk from recorded health measurements. Results include contributing factors and a history you can review.'),
          _settingsDetail(Icons.monitor_heart_outlined, 'Health information',
              'Record measurements and view trends over time. Nutrition, activity and mindfulness features help you track everyday habits.'),
          _settingsDetail(Icons.medication_outlined, 'Drug Assistant',
              'Ask about medications and save your medication list. Answers depend on available reviewed evidence and may say when evidence is insufficient.'),
          _settingsDetail(
              Icons.verified_user_outlined,
              'Your access and privacy',
              'A verified subscription or staged insurance benefit and an approved clinician link control access. The backend checks permissions for protected information.'),
          _settingsNote(Icons.lightbulb_outline_rounded,
              'Keep your measurements current and review results with your linked clinician. You can manage your password, sessions and display preferences here in Settings.'),
        ],
        disclaimer:
            'RiskSense AI provides estimates for decision support. It does not diagnose disease, guarantee outcomes, or replace professional medical advice, diagnosis or treatment.',
      );

  Future<void> _showLegalPrivacy() => _showSettingsInfo(
        title: 'Legal & Privacy',
        icon: Icons.gavel_rounded,
        intro: 'How this academic prototype uses your information and what its '
            'health features can and cannot tell you.',
        sections: [
          _settingsDetail(
              Icons.storage_outlined,
              'Information you provide',
              'Your account, reported conditions, medication list, measurements, '
                  'laboratory entries, wellness logs and analysis history are saved to '
                  'support the features you use. Enter only accurate information that '
                  'you are comfortable recording.'),
          _settingsDetail(
              Icons.medical_information_outlined,
              'Patient-reported diagnoses',
              'The conditions you set in Settings are self-reported. RiskSense AI '
                  'does not verify them or diagnose a condition. A recorded diagnosis '
                  'shows a health-trends option beside the relevant analysis.'),
          _settingsDetail(
              Icons.people_outline_rounded,
              'Clinician access',
              'An approved clinician must be actively linked to your account to '
                  'access permitted patient information. The backend checks that '
                  'relationship and your access entitlement for protected requests.'),
          _settingsDetail(
              Icons.security_rounded,
              'Account security',
              'Use a private password and sign out on shared devices. You can change '
                  'your password and review or revoke other sessions in Settings. '
                  'Sensitive account actions are recorded in audit logs.'),
          _settingsDetail(
              Icons.analytics_outlined,
              'Analysis and reports',
              'Risk scores and feature contributions are model estimates. Trend '
                  'reports summarize recorded measurements; they do not identify the '
                  'clinical cause of a change or establish that a disease is worsening.'),
          _settingsDetail(
              Icons.credit_card_off_outlined,
              'Access demonstrations',
              'Subscription payment and insurance verification are staged '
                  'demonstrations in this prototype. No real insurer verifies coverage '
                  'and the demo checkout does not process a real card payment.'),
          _settingsNote(
              Icons.open_in_new_rounded,
              'The full Privacy Notice and Terms of Service are available on the '
              'RiskSense AI website. Contact support if you need help understanding '
              'your account or the information shown here.'),
        ],
        disclaimer: 'RiskSense AI is for decision support and does not replace '
            'professional medical advice, diagnosis, treatment or emergency care.',
      );

  Future<void> _showSettingsInfo({
    required String title,
    required IconData icon,
    required String intro,
    required List<Widget> sections,
    required String disclaimer,
  }) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialog) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: AppColors.cardWhite,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxWidth: 460, maxHeight: MediaQuery.sizeOf(dialog).height * .82),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [AppColors.heroStart, AppColors.heroEnd]),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(children: [
                Icon(icon, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 19))),
                IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(dialog),
                    icon: const Icon(Icons.close_rounded, color: Colors.white)),
              ]),
            ),
            Flexible(
                child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(intro,
                        style: TextStyle(
                            color: AppColors.textSecondary, height: 1.45)),
                    const SizedBox(height: 18),
                    for (final section in sections) ...[
                      section,
                      const SizedBox(height: 10)
                    ],
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.amber.withValues(alpha: .11),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: AppColors.amber.withValues(alpha: .35)),
                      ),
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline_rounded,
                                color: AppColors.amber, size: 21),
                            const SizedBox(width: 10),
                            Expanded(
                                child: Text(disclaimer,
                                    style: TextStyle(
                                        color: AppColors.textPrimary,
                                        height: 1.4,
                                        fontSize: 12))),
                          ]),
                    ),
                  ]),
            )),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
              child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                      onPressed: () => Navigator.pop(dialog),
                      child: const Text('Done'))),
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _contact() async {
    final uri = Uri(
        scheme: 'mailto',
        path: 'shivenreddyxi@gmail.com',
        queryParameters: {'subject': 'RiskSense AI support'});
    if (!await launchUrl(uri)) await _error('No email app is available.');
  }

  Future<void> _signOut() async {
    VitalSync.instance.stop();
    try {
      await ApiClient.instance.logout();
    } catch (_) {}
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  String _date(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
    return date == null
        ? 'Unknown date'
        : DateFormat.yMMMd().add_jm().format(date);
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return AnimatedBuilder(
        animation: AppPreferences.instance,
        builder: (context, _) => Scaffold(
              backgroundColor: AppColors.background,
              appBar: const MedAppBar(
                  title: 'Settings',
                  showBack: true,
                  showSecureBadge: false,
                  helpTopic: 'Settings'),
              body: ListView(padding: const EdgeInsets.all(20), children: [
                Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                            colors: [AppColors.heroStart, AppColors.heroEnd]),
                        borderRadius: BorderRadius.circular(20)),
                    child: const Row(children: [
                      Icon(Icons.tune_rounded, color: Colors.white, size: 30),
                      SizedBox(width: 14),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text('Your Settings',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 19,
                                    fontWeight: FontWeight.w700)),
                            Text('Manage your account and app experience',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                          ]))
                    ])),
                _heading('Account & Security'),
                if (widget.role == 'patient')
                  _highlightTile(
                      Icons.medical_information_outlined,
                      'Update Health Conditions',
                      'Record diagnosed diabetes, heart disease or another chronic condition',
                      _updateHealthConditions,
                      AppColors.teal),
                _highlightTile(
                    Icons.lock_outline_rounded,
                    'Change Password',
                    'Verify your current password to update it',
                    _changePassword,
                    AppColors.teal),
                _sessionsCard(),
                if (widget.role == 'patient') ...[
                  _heading('Health & Privacy'),
                  _highlightTile(
                      Icons.person_search_rounded,
                      'Linked Clinician',
                      'See your connected clinician and how access works',
                      _showClinician,
                      AppColors.teal),
                  _highlightTile(
                      Icons.watch_rounded,
                      'Incoming Wearable Vitals',
                      VitalSync.instance.listening
                          ? 'Listening for new readings'
                          : 'Not listening',
                      () => showWearableSyncDialog(context),
                      AppColors.teal),
                  _heading('Notifications'),
                  _switch(
                      Icons.notifications_active_outlined,
                      'Risk Result Alerts',
                      'Show high and moderate result badges on your dashboard',
                      AppPreferences.instance.riskAlerts,
                      AppPreferences.instance.setRiskAlerts),
                ],
                _heading('Display'),
                _switch(
                    Icons.dark_mode_outlined,
                    'Dark Mode',
                    'Use the navy and teal night palette across the app',
                    AppPreferences.instance.darkMode,
                    AppPreferences.instance.setDarkMode),
                _textScale(),
                _switch(
                    Icons.motion_photos_off_outlined,
                    'Reduce Motion',
                    'Reduce supported in-app animations',
                    AppPreferences.instance.reduceMotion,
                    AppPreferences.instance.setReduceMotion),
                _heading('Help & Information'),
                _highlightTile(
                    Icons.gavel_rounded,
                    'Legal & Privacy',
                    'Understand health data, clinician access and clinical limits',
                    _showLegalPrivacy,
                    AppColors.teal),
                _highlightTile(
                    Icons.info_outline_rounded,
                    'About RiskSense AI',
                    'Explore features, access, privacy and clinical limits',
                    _showAbout,
                    AppColors.primaryBlue),
                _tile(Icons.email_outlined, 'Contact Developer',
                    'Open your email app with the support address', _contact),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                    onPressed: _signOut,
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Sign Out'),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: BorderSide(color: AppColors.danger))),
                const SizedBox(height: 24),
              ]),
            ));
  }

  Widget _heading(String title) => Padding(
      padding: const EdgeInsets.fromLTRB(2, 24, 0, 9),
      child: Text(title,
          style: TextStyle(
              color: AppColors.primaryBlue,
              fontWeight: FontWeight.w700,
              fontSize: 15)));

  Widget _tile(
          IconData icon, String title, String subtitle, VoidCallback onTap) =>
      _highlightTile(icon, title, subtitle, onTap, AppColors.teal);

  Widget _highlightTile(IconData icon, String title, String subtitle,
          VoidCallback onTap, Color accent) =>
      Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: AppColors.dark ? .13 : .07),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: accent.withValues(alpha: .35)),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(17),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: .13),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: accent, size: 23),
              ),
              const SizedBox(width: 13),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(title,
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(subtitle,
                        style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            height: 1.3)),
                  ])),
              const SizedBox(width: 5),
              Icon(Icons.arrow_forward_ios_rounded, size: 15, color: accent),
            ]),
          ),
        ),
      );

  Widget _switch(IconData icon, String title, String subtitle, bool value,
          Future<void> Function(bool) onChanged) =>
      Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppColors.teal.withValues(alpha: AppColors.dark ? .13 : .07),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: AppColors.teal.withValues(alpha: .35)),
          ),
          child: SwitchListTile(
              secondary: Icon(icon, color: AppColors.teal),
              title: Text(title,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(subtitle),
              value: value,
              onChanged: (next) async {
                try {
                  await onChanged(next);
                } catch (error) {
                  await _error(error);
                }
              }));

  Widget _textScale() => Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
          color: AppColors.teal.withValues(alpha: AppColors.dark ? .13 : .07),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: AppColors.teal.withValues(alpha: .35))),
      child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.text_fields_rounded, color: AppColors.teal),
              const SizedBox(width: 14),
              const Text('Text Size',
                  style: TextStyle(fontWeight: FontWeight.w600))
            ]),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: [
              for (final option in <(double, String)>[
                (1.0, 'Standard'),
                (1.15, 'Large'),
                (1.3, 'Extra Large')
              ])
                ChoiceChip(
                    label: Text(option.$2),
                    selected: AppPreferences.instance.textScale == option.$1,
                    onSelected: (_) async {
                      try {
                        await AppPreferences.instance.setTextScale(option.$1);
                      } catch (error) {
                        await _error(error);
                      }
                    }),
            ]),
          ])));

  Widget _sessionsCard() => Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
          color: AppColors.teal.withValues(alpha: AppColors.dark ? .13 : .07),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: AppColors.teal.withValues(alpha: .35))),
      child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.devices_rounded, color: AppColors.teal),
              const SizedBox(width: 14),
              const Expanded(
                  child: Text('Active Sessions',
                      style: TextStyle(fontWeight: FontWeight.w600))),
              IconButton(
                  tooltip: 'Refresh sessions',
                  onPressed: _refreshSessions,
                  icon: const Icon(Icons.refresh_rounded))
            ]),
            FutureBuilder<List<Map<String, dynamic>>>(
                future: _sessions,
                builder: (context, snapshot) {
                  if (!snapshot.hasData && !snapshot.hasError) {
                    return const Padding(
                        padding: EdgeInsets.all(12),
                        child: LinearProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return TextButton(
                        onPressed: _refreshSessions,
                        child: const Text('Unable to load sessions. Retry'));
                  }
                  final rows = snapshot.data!;
                  if (rows.isEmpty) {
                    return const Text('No active sessions recorded.');
                  }
                  return Column(children: [
                    for (final row in rows)
                      ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(row['is_current'] == true
                              ? 'This Session'
                              : 'Other Session'),
                          subtitle: Text(
                              'Started ${_date(row['created_at'])}\nExpires ${_date(row['expires_at'])}'),
                          isThreeLine: true,
                          trailing: row['is_current'] == true
                              ? Icon(Icons.check_circle_rounded,
                                  color: AppColors.success)
                              : IconButton(
                                  tooltip: 'Sign out this session',
                                  icon: Icon(Icons.logout_rounded,
                                      color: AppColors.danger),
                                  onPressed: () => _revoke(row))),
                  ]);
                }),
          ])));
}
