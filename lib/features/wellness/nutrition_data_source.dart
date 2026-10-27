import 'package:medguide/services/api_client.dart';

abstract class NutritionDataSource {
  Future<Map<String, dynamic>> waterSummary(String day);
  Future<void> saveWaterGoal(int millilitres);
  Future<void> addWater(String day, int millilitres);
  Future<Map<String, dynamic>> summary(String day);
  Future<void> saveGoal(int calories);
  Future<void> deleteEntry(String id);
  Future<void> addEntry(Map<String, dynamic> entry);
  Future<List<Map<String, dynamic>>> previousFoods(String query);
  Future<List<Map<String, dynamic>>> searchCatalog(String query);
}

class ApiNutritionDataSource implements NutritionDataSource {
  const ApiNutritionDataSource();

  @override
  Future<Map<String, dynamic>> waterSummary(String day) async =>
      Map<String, dynamic>.from(await ApiClient.instance
          .get('/nutrition/water/summary', query: {'day': day}) as Map);

  @override
  Future<void> saveWaterGoal(int millilitres) async {
    await ApiClient.instance
        .put('/nutrition/water/goal', data: {'goal_ml': millilitres});
  }

  @override
  Future<void> addWater(String day, int millilitres) async {
    await ApiClient.instance.post('/nutrition/water/entries',
        data: {'log_date': day, 'amount_ml': millilitres});
  }

  @override
  Future<Map<String, dynamic>> summary(String day) async =>
      Map<String, dynamic>.from(await ApiClient.instance
          .get('/nutrition/summary', query: {'day': day}) as Map);

  @override
  Future<void> saveGoal(int calories) async {
    await ApiClient.instance
        .put('/nutrition/goal', data: {'calories_kcal': calories});
  }

  @override
  Future<void> deleteEntry(String id) async {
    await ApiClient.instance.delete('/nutrition/entries/$id');
  }

  @override
  Future<void> addEntry(Map<String, dynamic> entry) async {
    await ApiClient.instance.post('/nutrition/entries', data: entry);
  }

  @override
  Future<List<Map<String, dynamic>>> previousFoods(String query) async =>
      (await ApiClient.instance.get('/nutrition/foods', query: {'query': query})
              as List)
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();

  @override
  Future<List<Map<String, dynamic>>> searchCatalog(String query) async =>
      (await ApiClient.instance
              .get('/nutrition/catalog', query: {'query': query}) as List)
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
}
