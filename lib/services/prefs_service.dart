import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants.dart';
import '../models/models.dart';

class PrefsService {
  static final PrefsService instance = PrefsService._internal();
  PrefsService._internal();

  final _secure = const FlutterSecureStorage();

  Future<AppSettings> getSettings() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(PrefsKeys.settings);
    if (raw == null) return AppSettings();
    return AppSettings.fromJson(jsonDecode(raw));
  }

  Future<void> saveSettings(AppSettings s) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(PrefsKeys.settings, jsonEncode(s.toJson()));
  }

  Future<Budgets> getBudgets() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(PrefsKeys.budgets);
    if (raw == null) return Budgets();
    return Budgets.fromJson(jsonDecode(raw));
  }

  Future<void> saveBudgets(Budgets b) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(PrefsKeys.budgets, jsonEncode(b.toJson()));
  }

  Future<List<RecurringRule>> getRecurring() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(PrefsKeys.recurring);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => RecurringRule.fromJson(e)).toList();
  }

  Future<void> saveRecurring(List<RecurringRule> rules) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(PrefsKeys.recurring, jsonEncode(rules.map((r) => r.toJson()).toList()));
  }

  Future<bool> isSetupDone() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(PrefsKeys.setupDone) ?? false;
  }

  Future<void> setSetupDone() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(PrefsKeys.setupDone, true);
  }

  // PIN stored in secure storage (upgrade vs. the web app's plaintext localStorage PIN)
  Future<String?> getPin() => _secure.read(key: PrefsKeys.pin);
  Future<void> setPin(String pin) => _secure.write(key: PrefsKeys.pin, value: pin);
  Future<void> removePin() => _secure.delete(key: PrefsKeys.pin);
}
