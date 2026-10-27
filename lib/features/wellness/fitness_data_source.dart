import 'package:medguide/services/api_client.dart';

abstract class FitnessDataSource {
  Future<Map<String, dynamic>> activity(String day);
  Future<void> addActivity(Map<String, dynamic> entry);
  Future<Map<String, dynamic>> body();
  Future<List<Map<String, dynamic>>> bodyTrends();
  Future<void> saveWeight(double kg);
  Future<void> saveComposition(double muscleKg, double fatPercent);
}

class ApiFitnessDataSource implements FitnessDataSource {
  const ApiFitnessDataSource();

  @override
  Future<Map<String, dynamic>> activity(String day) async =>
      Map<String, dynamic>.from(await ApiClient.instance
          .get('/fitness/activity/summary', query: {'day': day}) as Map);

  @override
  Future<void> addActivity(Map<String, dynamic> entry) async {
    await ApiClient.instance.post('/fitness/activity/entries', data: entry);
  }

  @override
  Future<Map<String, dynamic>> body() async => Map<String, dynamic>.from(
      await ApiClient.instance.get('/fitness/body') as Map);

  @override
  Future<List<Map<String, dynamic>>> bodyTrends() async {
    final response = Map<String, dynamic>.from(await ApiClient.instance
        .get('/health/trends', query: {'limit': 200}) as Map);
    return (response['body_measurements'] as List? ?? const [])
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  @override
  Future<void> saveWeight(double kg) async {
    await ApiClient.instance
        .put('/fitness/body/weight', data: {'weight_kg': kg});
  }

  @override
  Future<void> saveComposition(double muscleKg, double fatPercent) async {
    await ApiClient.instance.post('/fitness/body/composition', data: {
      'skeletal_muscle_kg': muscleKg,
      'body_fat_percent': fatPercent,
    });
  }
}
