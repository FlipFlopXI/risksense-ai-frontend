import 'package:medguide/services/api_client.dart';

abstract class GlucoseDataSource {
  Future<Map<String, dynamic>> summary(String day);
  Future<void> addEntry(Map<String, dynamic> entry);
}

class ApiGlucoseDataSource implements GlucoseDataSource {
  const ApiGlucoseDataSource();

  @override
  Future<Map<String, dynamic>> summary(String day) async =>
      Map<String, dynamic>.from(await ApiClient.instance
          .get('/nutrition/metabolic/summary', query: {'day': day}) as Map);

  @override
  Future<void> addEntry(Map<String, dynamic> entry) async {
    await ApiClient.instance.post('/nutrition/metabolic/entries', data: entry);
  }
}
