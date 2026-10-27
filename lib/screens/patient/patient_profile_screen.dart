import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:medguide/services/api_client.dart';
import 'package:medguide/services/app_preferences.dart';
import 'package:medguide/services/vital_sync.dart';
import 'package:medguide/theme/app_theme.dart';
import 'package:medguide/widgets/shared_widgets.dart';
import 'package:medguide/screens/auth/login_screen.dart';
import 'package:medguide/screens/shared/settings_screen.dart';

class PatientProfileScreen extends StatefulWidget {
  const PatientProfileScreen({super.key});
  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  late Future<Map<String, dynamic>> _profile;
  @override
  void initState() {
    super.initState();
    _profile = _load();
  }

  Future<Map<String, dynamic>> _load() async {
    final api = ApiClient.instance;
    final results = await Future.wait<dynamic>([
      api.get('/auth/me'),
      api.get('/patients/me'),
      _optional('/patients/me/clinician'),
      _optional('/subscriptions/'),
      _optional('/insurance/'),
      api.get('/access/entitlements'),
    ]);
    return {
      'user': Map<String, dynamic>.from(results[0] as Map),
      'patient': Map<String, dynamic>.from(results[1] as Map),
      'clinician': results[2],
      'subscription': results[3],
      'insurance': results[4],
      'entitlements': results[5] as List,
    };
  }

  Future<Map<String, dynamic>?> _optional(String path) async {
    try {
      return Map<String, dynamic>.from(await ApiClient.instance.get(path));
    } on ApiException catch (error) {
      if (error.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<void> _showId(String id) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 350),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Patient ID',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 6),
                Text('Your RiskSense patient reference',
                    style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 16),
                SelectableText(id,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 18),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Back'),
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: id));
                        if (!mounted || !dialogContext.mounted) return;
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Patient ID copied')),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 17),
                      label: const Text('Copy ID'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _signOut() async {
    VitalSync.instance.stop();
    await ApiClient.instance.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  Future<void> _showSubscriptionRenewal() async {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Subscription'),
        content: const Text('Open your website profile to review your subscription and choose whether to renew. This is a demonstration renewal; no payment is charged.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Exit')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Renew Subscription')),
        ],
      ),
    );
    if (proceed != true || !mounted) return;
    try {
      final url = await ApiClient.instance.issueSubscriptionRenewalUrl();
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw ApiException('Could not open the renewal website.');
      }
    } catch (error) {
      if (!mounted) return;
      await showDialog<void>(context: context, builder: (dialogContext) => AlertDialog(
        title: const Text('Website Unavailable'),
        content: Text(error.toString()),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Close'))],
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return AnimatedBuilder(
      animation: AppPreferences.instance,
      builder: (context, _) => Scaffold(
            backgroundColor: AppColors.background,
            appBar: MedAppBar(
                title: 'My Profile',
                showSecureBadge: false,
                actions: [
                  IconButton(
                      tooltip: 'Settings',
                      icon: Icon(Icons.settings_outlined,
                          color: AppColors.primaryBlue),
                      onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) =>
                                  const SettingsScreen(role: 'patient'))))
                ]),
            body: FutureBuilder<Map<String, dynamic>>(
              future: _profile,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done)
                  return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError)
                  return _ErrorState(
                      message: snapshot.error.toString(),
                      retry: () => setState(() => _profile = _load()));
                final user = snapshot.data!['user'] as Map<String, dynamic>;
                final patient =
                    snapshot.data!['patient'] as Map<String, dynamic>;
                final clinician =
                    snapshot.data!['clinician'] as Map<String, dynamic>?;
                final subscription =
                    snapshot.data!['subscription'] as Map<String, dynamic>?;
                final insurance =
                    snapshot.data!['insurance'] as Map<String, dynamic>?;
                final subscriptionExpiry = DateTime.tryParse(
                    subscription?['expires_at']?.toString() ?? '');
                final subscriptionActive =
                    subscription?['status']?.toString().toLowerCase() == 'active';
                final subscriptionExpired = subscriptionExpiry != null &&
                    !subscriptionExpiry.isAfter(DateTime.now());
                final expiringSoon = subscriptionActive &&
                    subscriptionExpiry != null &&
                    subscriptionExpiry.isAfter(DateTime.now()) &&
                    subscriptionExpiry.isBefore(DateTime.now().add(const Duration(days: 7)));
                final entitlements = snapshot.data!['entitlements'] as List;
                final fullName = _titleCase(
                    '${patient['first_name']} ${patient['last_name']}');
                final gender =
                    patient['gender']?.toString().trim().toLowerCase();
                final female =
                    gender == 'female' || gender == 'woman' || gender == 'f';
                final active = entitlements.whereType<Map>().where((item) {
                  if (item['status']?.toString().toUpperCase() != 'ACTIVE')
                    return false;
                  final expiry =
                      DateTime.tryParse(item['expires_at']?.toString() ?? '');
                  return expiry == null || expiry.isAfter(DateTime.now());
                }).isNotEmpty;
                return RefreshIndicator(
                    onRefresh: () async {
                      final next = _load();
                      setState(() => _profile = next);
                      await next;
                    },
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        _IdentityCard(
                            name: fullName,
                            email: user['email'].toString(),
                            female: female),
                        const SizedBox(height: 16),
                        _Section(title: 'Personal Details', children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Patient ID',
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary)),
                                InkWell(
                                  onTap: () =>
                                      _showId(patient['id'].toString()),
                                  child: Text(
                                    'Tap To View ID',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.primaryBlue,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          InfoRow(
                              label: 'Date Of Birth',
                              value: _date(patient['date_of_birth'])),
                          InfoRow(
                              label: 'Gender',
                              value: _titleCase(patient['gender']?.toString() ??
                                  'Not recorded')),
                          InfoRow(
                              label: 'Phone',
                              value: patient['phone_number']?.toString() ??
                                  'Not recorded'),
                          InfoRow(
                              label: 'Account',
                              value: user['is_active'] == true
                                  ? 'Active'
                                  : 'Inactive'),
                        ]),
                        const SizedBox(height: 16),
                        _Section(title: 'Access And Coverage', children: [
                          InfoRow(
                              label: 'Access Entitlement',
                              value:
                                  active ? 'Active' : 'No Active Entitlement'),
                          if (subscriptionActive)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(children: [
                                Text('Subscription', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                                const Spacer(),
                                ActionChip(
                                  tooltip: 'View subscription renewal options',
                                  avatar: Icon(Icons.autorenew_rounded, size: 18,
                                      color: subscriptionExpired || expiringSoon ? Colors.deepOrange : Colors.green),
                                  label: Text(subscriptionExpired ? 'Expired' : expiringSoon ? 'Expiring Soon' : 'Active'),
                                  onPressed: _showSubscriptionRenewal,
                                ),
                              ]),
                            )
                          else
                            InfoRow(label: 'Subscription', value: _titleCase(
                                subscription?['status']?.toString() ?? 'Not requested')),
                          if (subscription?['expires_at'] != null)
                            InfoRow(
                                label: 'Subscription Expires',
                                value: _date(subscription!['expires_at'])),
                          InfoRow(
                              label: 'Insurance',
                              value: _titleCase(
                                  insurance?['provider_name']?.toString() ??
                                      'Not provided')),
                          if (insurance != null)
                            InfoRow(
                                label: 'Verification',
                                value: _titleCase(
                                    insurance['verification_status']
                                            ?.toString() ??
                                        'Not verified')),
                        ]),
                        const SizedBox(height: 16),
                        _Section(title: 'My Clinician', children: [
                          if (clinician == null)
                            Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Text('No Active Clinician Relationship.',
                                    style: TextStyle(
                                        color: AppColors.textSecondary)))
                          else ...[
                            InfoRow(
                                label: 'Clinician',
                                value: _titleCase(
                                    clinician['display_name'].toString())),
                            InfoRow(
                                label: 'RiskSense ID',
                                value: clinician['risk_sense_id'].toString()),
                            InfoRow(
                                label: 'Institution',
                                value: _titleCase(
                                    clinician['institution']?.toString() ??
                                        'Not recorded')),
                          ]
                        ]),
                        const SizedBox(height: 24),
                        OutlinedButton.icon(
                            onPressed: _signOut,
                            icon: const Icon(Icons.logout_rounded),
                            label: const Text('Sign Out'),
                            style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.danger,
                                side: BorderSide(color: AppColors.danger))),
                      ],
                    ));
              },
            ),
          ));
  }

  String _date(dynamic value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    return parsed == null ? 'Not recorded' : DateFormat.yMMMMd().format(parsed);
  }

  String _titleCase(String value) => value
          .replaceAll('_', ' ')
          .replaceAllMapped(RegExp(r'[A-Za-z]+'), (match) {
        final word = match.group(0)!;
        return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
      });
}

class _IdentityCard extends StatelessWidget {
  final String name;
  final String email;
  final bool female;
  const _IdentityCard({
    required this.name,
    required this.email,
    required this.female,
  });
  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: female
                  ? AppColors.femaleGradient
                  : [AppColors.heroStart, AppColors.heroEnd]),
          borderRadius: BorderRadius.circular(20)),
      child: Row(children: [
        const CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white24,
            child: Icon(Icons.person_rounded, color: Colors.white, size: 30)),
        const SizedBox(width: 16),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700)),
          Text(email, style: const TextStyle(color: Colors.white70))
        ]))
      ]));
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});
  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const Divider(height: 24),
        ...children
      ]));
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback retry;
  const _ErrorState({required this.message, required this.retry});
  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Center(
      child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.cloud_off_rounded, size: 42, color: AppColors.danger),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: retry, child: const Text('Try again'))
          ])));
  }
}
