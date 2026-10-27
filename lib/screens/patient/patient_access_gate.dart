import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:medguide/services/api_client.dart';
import 'package:medguide/services/vital_sync.dart';
import 'package:medguide/screens/patient/patient_dashboard.dart';
import 'package:medguide/screens/auth/login_screen.dart';
import 'package:medguide/screens/patient/patient_onboarding_screen.dart';

/// Checks FastAPI whenever the app returns from the activation website.
class PatientAccessGate extends StatefulWidget {
  const PatientAccessGate({super.key});

  @override
  State<PatientAccessGate> createState() => _PatientAccessGateState();
}

class _PatientAccessGateState extends State<PatientAccessGate>
    with WidgetsBindingObserver {
  bool _loading = true;
  bool _opening = false;
  bool _active = false;
  bool _onboardingComplete = false;
  String? _onboardingError;
  String? _error;
  int _refreshGeneration = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    final generation = ++_refreshGeneration;
    setState(() { _loading = true; _error = null; _onboardingError = null; });
    try {
      final result = await ApiClient.instance.accessStatus();
      if (!mounted || generation != _refreshGeneration) return;
      final active = result['active'] == true && result['clinician_linked'] == true;
      if (active) {
        try {
          final onboarding = Map<String, dynamic>.from(await ApiClient.instance.get('/patients/onboarding') as Map);
          if (!mounted || generation != _refreshGeneration) return;
          setState(() { _active = true; _onboardingComplete = onboarding['completed'] == true; });
        } on ApiException catch (error) {
          if (!mounted || generation != _refreshGeneration) return;
          setState(() { _active = true; _onboardingError = error.message; });
        }
      } else {
        setState(() { _active = false; _onboardingComplete = false; });
      }
    } on ApiException catch (error) {
      if (!mounted || generation != _refreshGeneration) return;
      setState(() { _active = false; _error = error.message; });
    } finally {
      if (mounted && generation == _refreshGeneration) setState(() => _loading = false);
    }
  }

  Future<void> _openActivation() async {
    if (_opening) return;
    setState(() { _opening = true; _error = null; });
    try {
      final uri = await ApiClient.instance.issueActivationUrl();
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw ApiException('Could not open the activation website.');
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_active && _onboardingError != null) {
      return Scaffold(body: Center(child: Padding(
      padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(_onboardingError!, textAlign: TextAlign.center),
        const SizedBox(height: 16), FilledButton(onPressed: _refresh, child: const Text('Retry')),
      ]),
      )));
    }
    if (_active && !_onboardingComplete) return const PatientOnboardingScreen();
    if (_active) return const PatientDashboard();
    return Scaffold(
      appBar: AppBar(title: const Text('Complete Registration')),
      body: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.verified_user_outlined, size: 52),
            const SizedBox(height: 18),
            Text('Activate RiskSense access', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            const Text('Choose a demo subscription or simulated insurance route and link an approved clinician on the website. Access is granted only after FastAPI confirms activation.', textAlign: TextAlign.center),
            if (_error != null) Padding(padding: const EdgeInsets.only(top: 16), child: Text(_error!, textAlign: TextAlign.center)),
            const SizedBox(height: 24),
            FilledButton(onPressed: _opening ? null : _openActivation, child: Text(_opening ? 'Opening…' : 'Complete Registration')),
            TextButton(onPressed: _refresh, child: const Text('Refresh access status')),
            TextButton(onPressed: () async {
              VitalSync.instance.stop();
              try { await ApiClient.instance.logout(); } catch (_) { /* Secure storage is cleared in logout's finally block. */ }
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
            }, child: const Text('Sign out')),
          ]),
        ),
      )),
    );
  }
}
