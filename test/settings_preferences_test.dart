import 'package:flutter_test/flutter_test.dart';
import 'package:medguide/services/app_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:medguide/theme/app_theme.dart';
import 'package:medguide/screens/shared/ai_assistant_screen.dart';
import 'package:medguide/widgets/shared_widgets.dart';
import 'package:medguide/screens/patient/patient_dashboard.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('settings persist device display and risk-alert preferences', () async {
    SharedPreferences.setMockInitialValues({});
    final settings = AppPreferences.instance;
    await settings.load();
    await settings.setRiskAlerts(false);
    await settings.setReduceMotion(true);
    await settings.setDarkMode(true);
    await settings.setTextScale(1.15);
    final stored = await SharedPreferences.getInstance();
    expect(stored.getBool('risk_alerts'), isFalse);
    expect(stored.getBool('reduce_motion'), isTrue);
    expect(stored.getBool('dark_mode'), isTrue);
    expect(stored.getDouble('text_scale'), 1.15);
    await settings.setRiskAlerts(true);
    await settings.setReduceMotion(false);
    await settings.setDarkMode(false);
    await settings.setTextScale(1.0);
  });

  testWidgets('dark palette keeps stat cards readable on a narrow screen',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await AppPreferences.instance.setDarkMode(true);
    addTearDown(() => AppPreferences.instance.setDarkMode(false));
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
            body: Center(
                child: SizedBox(
                    width: 138,
                    height: 174,
                    child: StatCard(
                        compact: true,
                        title: 'Blood Pressure',
                        value: '120/80',
                        subtitle: 'Latest recorded BP',
                        icon: Icons.favorite_border_rounded,
                        color: AppColors.danger))))));
    expect(Theme.of(tester.element(find.byType(StatCard))).brightness,
        Brightness.dark);
    expect(AppColors.cardWhite, const Color(0xFF172436));
    expect(tester.takeException(), isNull);
  });

  test('dark text and accent colours contrast with their surfaces', () async {
    SharedPreferences.setMockInitialValues({});
    await AppPreferences.instance.setDarkMode(true);
    addTearDown(() => AppPreferences.instance.setDarkMode(false));
    double contrast(Color first, Color second) {
      final a = first.computeLuminance();
      final b = second.computeLuminance();
      return ((a > b ? a : b) + .05) / ((a > b ? b : a) + .05);
    }

    expect(
        contrast(AppColors.textPrimary, AppColors.cardWhite), greaterThan(4.5));
    expect(contrast(AppColors.textSecondary, AppColors.cardWhite),
        greaterThan(4.5));
    expect(contrast(AppColors.primaryBlue, AppColors.background),
        greaterThan(4.5));
    expect(contrast(Colors.white, AppColors.brandSolid), greaterThan(4.5));
    for (final risk in [
      AppColors.riskLow,
      AppColors.riskMedium,
      AppColors.riskHigh
    ]) {
      expect(contrast(risk, AppColors.cardWhite), greaterThan(3));
    }
    final theme = AppTheme.lightTheme;
    expect(theme.inputDecorationTheme.fillColor, AppColors.cardWhite);
    expect(theme.scaffoldBackgroundColor, AppColors.background);
  });

  testWidgets('switching palette preserves the card contents', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await AppPreferences.instance.setDarkMode(false);
    await tester.pumpWidget(AnimatedBuilder(
        animation: AppPreferences.instance,
        builder: (context, _) => MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
                body: StatCard(
                    title: 'Predictions',
                    value: '12',
                    icon: Icons.history_rounded,
                    color: AppColors.success)))));
    expect(Theme.of(tester.element(find.byType(StatCard))).brightness,
        Brightness.light);
    await AppPreferences.instance.setDarkMode(true);
    await tester.pumpAndSettle();
    expect(Theme.of(tester.element(find.byType(StatCard))).brightness,
        Brightness.dark);
    expect(find.text('Predictions'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await AppPreferences.instance.setDarkMode(false);
  });

  testWidgets('assistant updates its open screen when dark mode changes',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await AppPreferences.instance.setDarkMode(false);
    await tester.pumpWidget(const MaterialApp(home: AiAssistantScreen()));
    final lightBackground = AppColors.background;
    expect(tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
        lightBackground);
    await AppPreferences.instance.setDarkMode(true);
    await tester.pump();
    expect(AppColors.background, isNot(lightBackground));
    expect(tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
        AppColors.background);
    expect(find.textContaining('RiskSense AI Assistant'), findsWidgets);
    await AppPreferences.instance.setDarkMode(false);
  });

  test('all inherited text styles follow the selected palette', () async {
    SharedPreferences.setMockInitialValues({});
    for (final dark in [false, true, false]) {
      await AppPreferences.instance.setDarkMode(dark);
      final theme = AppTheme.lightTheme;
      final expected = AppColors.textPrimary;
      expect(theme.textTheme.titleMedium?.color, expected);
      expect(theme.textTheme.labelMedium?.color, expected);
      expect(theme.textTheme.bodyLarge?.color, expected);
      expect(theme.inputDecorationTheme.fillColor, AppColors.cardWhite);
      expect(theme.inputDecorationTheme.prefixIconColor, AppColors.textSecondary);
    }
  });

  test('light palette text and accents remain readable on cards', () async {
    SharedPreferences.setMockInitialValues({});
    await AppPreferences.instance.setDarkMode(false);
    double contrast(Color first, Color second) {
      final a = first.computeLuminance();
      final b = second.computeLuminance();
      return ((a > b ? a : b) + .05) / ((a > b ? b : a) + .05);
    }
    for (final color in [
      AppColors.textPrimary,
      AppColors.textSecondary,
      AppColors.textLight,
      AppColors.teal,
      AppColors.amber,
      AppColors.danger,
      AppColors.success,
    ]) {
      expect(contrast(color, AppColors.cardWhite), greaterThan(4.5));
    }
  });

  testWidgets('open dashboard updates cards in both theme directions',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await AppPreferences.instance.setDarkMode(false);
    final demo = <String, dynamic>{
      'patient_first_name': 'Demo',
      'latest_predictions': <Map<String, dynamic>>[],
      'drug_response_enquiries_today': 0,
    };
    await tester.pumpWidget(AnimatedBuilder(
        animation: AppPreferences.instance,
        builder: (context, _) => MaterialApp(
            theme: AppTheme.lightTheme,
            home: PatientDashboard(previewData: demo))));
    await tester.pump();

    bool hasCardColor(Color color) => tester.widgetList<Container>(find.byType(Container)).any(
        (widget) => widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).color == color);

    expect(hasCardColor(const Color(0xFFFFFFFF)), isTrue);
    await AppPreferences.instance.setDarkMode(true);
    await tester.pump();
    expect(hasCardColor(const Color(0xFF172436)), isTrue);
    await AppPreferences.instance.setDarkMode(false);
    await tester.pump();
    expect(hasCardColor(const Color(0xFFFFFFFF)), isTrue);
    expect(tester.takeException(), isNull);
  });
}
