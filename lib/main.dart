import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:medguide/theme/app_theme.dart';
import 'package:medguide/screens/auth/splash_screen.dart';
import 'package:medguide/screens/auth/login_screen.dart';
import 'package:medguide/screens/admin/admin_dashboard.dart';
import 'package:medguide/screens/clinician/clinician_dashboard.dart';
import 'package:medguide/screens/patient/patient_access_gate.dart';
import 'package:medguide/services/api_client.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const MedSurrogateApp());
}

class MedSurrogateApp extends StatelessWidget {
  const MedSurrogateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RiskSense AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      onGenerateRoute: (settings) {
        if (settings.name == '/activation-return' || settings.name == 'risksense://activation-return') {
          return MaterialPageRoute(builder: (_) => const PatientAccessGate());
        }
        return null;
      },
      home: const AppEntry(),
    );
  }
}

class AppEntry extends StatefulWidget {
  const AppEntry({super.key});

  @override
  State<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<AppEntry> {
  bool _splashComplete = false;
  late final Future<Widget> _destination = _restoreDestination();

  Future<Widget> _restoreDestination() async {
    final user = await ApiClient.instance.restoreSession();
    return switch (user?['role']?.toString().toUpperCase()) {
      'PATIENT' => const PatientAccessGate(),
      'CLINICIAN' => const ClinicianDashboard(),
      'ADMIN' => const AdminDashboard(),
      _ => const LoginScreen(),
    };
  }

  @override
  Widget build(BuildContext context) {
    if (!_splashComplete) {
      return SplashScreen(
        onComplete: () => setState(() => _splashComplete = true),
      );
    }
    return FutureBuilder<Widget>(
      future: _destination,
      builder: (context, snapshot) => snapshot.connectionState ==
              ConnectionState.done
          ? snapshot.data ?? const LoginScreen()
          : const Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }
}
