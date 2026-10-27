import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences extends ChangeNotifier {
  AppPreferences._();
  static final instance = AppPreferences._();

  bool riskAlerts = true;
  bool reduceMotion = false;
  bool darkMode = false;
  double textScale = 1.0;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    riskAlerts = prefs.getBool('risk_alerts') ?? true;
    reduceMotion = prefs.getBool('reduce_motion') ?? false;
    darkMode = prefs.getBool('dark_mode') ?? false;
    textScale = prefs.getDouble('text_scale') ?? 1.0;
    notifyListeners();
  }

  Future<void> setRiskAlerts(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('risk_alerts', value);
    riskAlerts = value;
    notifyListeners();
  }

  Future<void> setReduceMotion(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reduce_motion', value);
    reduceMotion = value;
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', value);
    darkMode = value;
    notifyListeners();
  }

  Future<void> setTextScale(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('text_scale', value);
    textScale = value;
    notifyListeners();
  }
}
