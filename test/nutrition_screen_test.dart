import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medguide/features/wellness/nutrition_data_source.dart';
import 'package:medguide/features/wellness/glucose_data_source.dart';
import 'package:medguide/features/wellness/nutrition_screen.dart';
import 'package:medguide/services/api_client.dart';
import 'package:medguide/widgets/app_form_dialog.dart';

class _FakeNutritionDataSource implements NutritionDataSource {
  int? waterGoal;
  final waterEntries = <Map<String, dynamic>>[];
  int? goal;
  final entries = <Map<String, dynamic>>[];
  bool throwAfterWrite = false;
  int reads = 0;

  @override
  Future<Map<String, dynamic>> waterSummary(String day) async => {
        'date': day,
        'goal_ml': waterGoal,
        'total_ml': waterEntries.fold<int>(
            0, (total, item) => total + (item['amount_ml'] as int)),
        'entries': waterEntries
            .map((item) => Map<String, dynamic>.from(item))
            .toList(),
        'history': List.generate(
            7,
            (i) => {
                  'date': DateTime.now()
                      .subtract(Duration(days: 6 - i))
                      .toIso8601String(),
                  'amount_ml': i == 6 ? waterEntries.length * 250 : 0,
                }),
      };

  @override
  Future<void> saveWaterGoal(int millilitres) async {
    waterGoal = millilitres;
  }

  @override
  Future<void> addWater(String day, int millilitres) async {
    waterEntries.insert(0, {
      'id': 'water-${waterEntries.length}',
      'amount_ml': millilitres,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  @override
  Future<Map<String, dynamic>> summary(String day) async {
    reads++;
    final total = entries.fold<double>(
        0, (sum, item) => sum + (item['calories_kcal'] as num).toDouble());
    return {
      'date': day,
      'goal_kcal': goal,
      'calories_kcal': total,
      'carbs_g': 0,
      'fat_g': 0,
      'protein_g': 0,
      'entries':
          entries.map((entry) => Map<String, dynamic>.from(entry)).toList(),
      'history': List.generate(
          7,
          (index) => {
                'date': DateTime.now()
                    .subtract(Duration(days: 6 - index))
                    .toIso8601String(),
                'calories_kcal': index == 6 ? total : 0,
              }),
    };
  }

  @override
  Future<void> saveGoal(int calories) async {
    goal = calories;
    if (throwAfterWrite) throw ApiException('Response interrupted.');
  }

  @override
  Future<void> deleteEntry(String id) async {
    entries.removeWhere((entry) => entry['id'] == id);
    if (throwAfterWrite) throw ApiException('Response interrupted.');
  }

  @override
  Future<void> addEntry(Map<String, dynamic> entry) async {
    entries.add({
      'id': 'new-food',
      'meal_type': entry['meal_type'],
      'food_name': entry['food_name'],
      'amount_g': entry['amount_g'],
      'calories_kcal': entry['calories_per_100g'],
      'source': 'self_reported',
    });
  }

  @override
  Future<List<Map<String, dynamic>>> previousFoods(String query) async => [];

  @override
  Future<List<Map<String, dynamic>>> searchCatalog(String query) async => [];
}

class _FakeGlucoseDataSource implements GlucoseDataSource {
  @override
  Future<Map<String, dynamic>> summary(String day) async =>
      {'date': day, 'entries': <Map<String, dynamic>>[]};

  @override
  Future<void> addEntry(Map<String, dynamic> entry) async {}
}

void main() {
  final dashboard = <String, dynamic>{'latest_predictions': <dynamic>[]};

  testWidgets('Blood Glucose is reachable as the third tab on a narrow screen',
      (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        home: NutritionScreen(
            dashboard: dashboard,
            dataSource: _FakeNutritionDataSource(),
            glucoseDataSource: _FakeGlucoseDataSource())));
    await tester.pumpAndSettle();
    final tabs = find.byType(Tab);
    final foodX = tester.getCenter(tabs.at(0)).dx;
    final waterX = tester.getCenter(tabs.at(1)).dx;
    final glucoseX = tester.getCenter(tabs.at(2)).dx;
    expect(waterX - foodX, closeTo(glucoseX - waterX, 1));
    await tester.tap(find.text('Blood Glucose').first);
    await tester.pumpAndSettle();
    expect(find.text('Today’s Blood Glucose'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Water tab logs 250 ml and saves a daily goal', (tester) async {
    final api = _FakeNutritionDataSource();
    await tester.pumpWidget(MaterialApp(
        home: NutritionScreen(dashboard: dashboard, dataSource: api)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Water').first);
    await tester.pumpAndSettle();
    expect(find.text('0'), findsWidgets);
    await tester.tap(find.text('+250 ml'));
    await tester.pumpAndSettle();
    expect(api.waterEntries.single['amount_ml'], 250);
    expect(find.text('250'), findsWidgets);
    await tester.tap(find.byTooltip('Set daily water goal'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).last, '2000');
    await tester.tap(find.text('Save Goal'));
    await tester.pumpAndSettle();
    expect(api.waterGoal, 2000);
    expect(find.text('Daily goal: 2000 ml'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('250 ml'), 150,
        scrollable: find.byType(Scrollable).last);
    expect(find.text('250 ml'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Food tab scrolls away with its page header', (tester) async {
    final api = _FakeNutritionDataSource();
    await tester.pumpWidget(MaterialApp(
        home: NutritionScreen(dashboard: dashboard, dataSource: api)));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byType(TabBar)).dy, greaterThan(0));
    await tester.drag(find.byType(NestedScrollView), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.byType(TabBar), findsNothing);
  });

  testWidgets('goal saves and refreshes without a disposed-controller error',
      (tester) async {
    final api = _FakeNutritionDataSource()..throwAfterWrite = true;
    await tester.pumpWidget(MaterialApp(
        home: NutritionScreen(dashboard: dashboard, dataSource: api)));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Set daily calorie goal'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).last, '2200');
    await tester.tap(find.text('Save Goal'));
    await tester.pumpAndSettle();
    expect(api.goal, 2200);
    expect(find.text('Daily goal: 2200 kcal'), findsOneWidget);
    expect(find.text('Nutrition Unavailable'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('delete reconciles a committed change and refreshes immediately',
      (tester) async {
    final api = _FakeNutritionDataSource()
      ..throwAfterWrite = true
      ..entries.add({
        'id': 'saved-food',
        'meal_type': 'breakfast',
        'food_name': 'Oats',
        'amount_g': 100,
        'calories_kcal': 125,
        'source': 'self_reported',
      });
    await tester.pumpWidget(MaterialApp(
        home: NutritionScreen(dashboard: dashboard, dataSource: api)));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.textContaining('Oats'), 200,
        scrollable: find.byType(Scrollable).last);
    expect(find.textContaining('Oats'), findsOneWidget);
    await tester.ensureVisible(find.byTooltip('Remove food'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Remove food'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove').last);
    await tester.pumpAndSettle();
    expect(api.entries, isEmpty);
    expect(find.textContaining('Oats'), findsNothing);
    expect(find.text('Nutrition Unavailable'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('adding a food refreshes the current Food tab', (tester) async {
    final api = _FakeNutritionDataSource();
    await tester.pumpWidget(MaterialApp(
        home: NutritionScreen(dashboard: dashboard, dataSource: api)));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byTooltip('Add Breakfast'), 200,
        scrollable: find.byType(Scrollable).last);
    await tester.ensureVisible(find.byTooltip('Add Breakfast'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Add Breakfast'));
    await tester.pumpAndSettle();
    final fields = find.descendant(
        of: find.byType(AppFormDialog), matching: find.byType(TextFormField));
    for (final (index, value) in <(int, String)>[
      (0, 'Oats'),
      (1, '100'),
      (2, '125'),
      (3, '12'),
      (4, '3'),
      (5, '5'),
    ]) {
      await tester.enterText(fields.at(index), value);
    }
    await tester.tap(find.text('Add Food'));
    await tester.pumpAndSettle();
    expect(api.entries, hasLength(1));
    expect(api.reads, greaterThan(1));
    expect(find.textContaining('Oats'), findsOneWidget);
    expect(find.text('Nutrition Unavailable'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
