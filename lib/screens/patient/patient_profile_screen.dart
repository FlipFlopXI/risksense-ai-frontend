import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:medguide/services/api_client.dart';
import 'package:medguide/theme/app_theme.dart';
import 'package:medguide/widgets/shared_widgets.dart';
import 'package:medguide/screens/auth/login_screen.dart';

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
    final user = Map<String, dynamic>.from(await api.get('/auth/me'));
    final patient = Map<String, dynamic>.from(await api.get('/patients/me'));
    final clinician = await _optional('/patients/me/clinician');
    final subscription = await _optional('/subscriptions/');
    final insurance = await _optional('/insurance/');
    final entitlements = await api.get('/access/entitlements') as List;
    return {
      'user': user,
      'patient': patient,
      'clinician': clinician,
      'subscription': subscription,
      'insurance': insurance,
      'entitlements': entitlements,
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
                const Text('Your RiskSense patient reference',
                    style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 16),
                SelectableText(id,
                    style: const TextStyle(
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
    await ApiClient.instance.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: const MedAppBar(title: 'My Profile', showSecureBadge: false),
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
            final patient = snapshot.data!['patient'] as Map<String, dynamic>;
            final clinician =
                snapshot.data!['clinician'] as Map<String, dynamic>?;
            final subscription =
                snapshot.data!['subscription'] as Map<String, dynamic>?;
            final insurance =
                snapshot.data!['insurance'] as Map<String, dynamic>?;
            final entitlements = snapshot.data!['entitlements'] as List;
            final fullName = '${patient['first_name']} ${patient['last_name']}';
            final gender = patient['gender']?.toString().trim().toLowerCase();
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
                    _Section(title: 'Personal details', children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Patient ID',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary)),
                            InkWell(
                              onTap: () => _showId(patient['id'].toString()),
                              child: const Text(
                                'Tap to view ID',
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
                          label: 'Date of birth',
                          value: _date(patient['date_of_birth'])),
                      InfoRow(
                          label: 'Gender',
                          value:
                              patient['gender']?.toString() ?? 'Not recorded'),
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
                    _Section(title: 'Access and coverage', children: [
                      InfoRow(
                          label: 'Access entitlement',
                          value: active ? 'Active' : 'No active entitlement'),
                      InfoRow(
                          label: 'Subscription',
                          value: subscription?['status']?.toString() ??
                              'Not requested'),
                      if (subscription?['expires_at'] != null)
                        InfoRow(
                            label: 'Subscription expires',
                            value: _date(subscription!['expires_at'])),
                      InfoRow(
                          label: 'Insurance',
                          value: insurance?['provider_name']?.toString() ??
                              'Not provided'),
                      if (insurance != null)
                        InfoRow(
                            label: 'Verification',
                            value:
                                insurance['verification_status']?.toString() ??
                                    'Not verified'),
                    ]),
                    const SizedBox(height: 16),
                    _Section(title: 'My clinician', children: [
                      if (clinician == null)
                        const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text('No active clinician relationship.',
                                style:
                                    TextStyle(color: AppColors.textSecondary)))
                      else ...[
                        InfoRow(
                            label: 'Clinician',
                            value: clinician['display_name'].toString()),
                        InfoRow(
                            label: 'RiskSense ID',
                            value: clinician['risk_sense_id'].toString()),
                        InfoRow(
                            label: 'Institution',
                            value: clinician['institution']?.toString() ??
                                'Not recorded'),
                      ]
                    ]),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                        onPressed: _signOut,
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text('Sign out'),
                        style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.danger,
                            side: const BorderSide(color: AppColors.danger))),
                  ],
                ));
          },
        ),
      );

  String _date(dynamic value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    return parsed == null ? 'Not recorded' : DateFormat.yMMMMd().format(parsed);
  }
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
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: female
                  ? const [Color(0xFF6B42B8), Color(0xFFAA70D6)]
                  : const [AppColors.primaryBlue, AppColors.teal]),
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

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});
  @override
  Widget build(BuildContext context) => Container(
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

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback retry;
  const _ErrorState({required this.message, required this.retry});
  @override
  Widget build(BuildContext context) => Center(
      child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off_rounded,
                size: 42, color: AppColors.danger),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: retry, child: const Text('Try again'))
          ])));
}
