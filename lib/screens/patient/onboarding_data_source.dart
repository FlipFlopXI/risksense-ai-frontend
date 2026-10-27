import 'package:medguide/services/api_client.dart';
import 'package:medguide/services/vital_sync.dart';

abstract class PatientOnboardingDataSource {
  Future<Map<String, dynamic>> load();
  Future<void> save(Map<String, dynamic> details);
  Future<void> finishSession();
}

class ApiPatientOnboardingDataSource implements PatientOnboardingDataSource {
  const ApiPatientOnboardingDataSource();

  @override
  Future<Map<String, dynamic>> load() async =>
      Map<String, dynamic>.from(await ApiClient.instance.get('/patients/onboarding') as Map);

  @override
  Future<void> save(Map<String, dynamic> details) async {
    await ApiClient.instance.post('/patients/onboarding', data: details);
  }

  @override
  Future<void> finishSession() async {
    VitalSync.instance.stop();
    try { await ApiClient.instance.logout(); } catch (_) { /* Local session is cleared by logout. */ }
  }
}
