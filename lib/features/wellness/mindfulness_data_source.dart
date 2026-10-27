import 'package:medguide/services/api_client.dart';

abstract class MindfulnessDataSource {
  Future<Map<String, dynamic>> moodSummary(String day);
  Future<void> logMood(Map<String, dynamic> entry);
  Future<Map<String, dynamic>> breathingSummary(String day);
  Future<void> logBreathing(Map<String, dynamic> entry);
  Future<Map<String, dynamic>> meditationSummary(String day);
  Future<void> logMeditation(Map<String, dynamic> entry);
}

class ApiMindfulnessDataSource implements MindfulnessDataSource {
  const ApiMindfulnessDataSource();

  @override
  Future<Map<String, dynamic>> moodSummary(String day) async =>
      Map<String, dynamic>.from(await ApiClient.instance
          .get('/mindfulness/moods/summary', query: {'day': day}) as Map);

  @override
  Future<void> logMood(Map<String, dynamic> entry) async {
    await ApiClient.instance.post('/mindfulness/moods', data: entry);
  }

  @override
  Future<Map<String, dynamic>> breathingSummary(String day) async =>
      Map<String, dynamic>.from(await ApiClient.instance
          .get('/mindfulness/breathing/summary', query: {
        'day': day,
        'timezone_offset_minutes': DateTime.now().timeZoneOffset.inMinutes
      }) as Map);

  @override
  Future<void> logBreathing(Map<String, dynamic> entry) async {
    await ApiClient.instance
        .post('/mindfulness/breathing/sessions', data: entry);
  }

  @override
  Future<Map<String, dynamic>> meditationSummary(String day) async =>
      Map<String, dynamic>.from(await ApiClient.instance
          .get('/mindfulness/meditation/summary', query: {
        'day': day,
        'timezone_offset_minutes': DateTime.now().timeZoneOffset.inMinutes,
      }) as Map);

  @override
  Future<void> logMeditation(Map<String, dynamic> entry) async {
    await ApiClient.instance
        .post('/mindfulness/meditation/sessions', data: entry);
  }
}
