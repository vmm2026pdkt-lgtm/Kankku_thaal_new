import 'dart:async';
import '../models/models.dart';
import 'db_service.dart';
import 'prefs_service.dart';
import 'supabase_service.dart';

class SyncService {
  static final SyncService instance = SyncService._internal();
  SyncService._internal();

  final _db = DbService.instance;
  final _prefs = PrefsService.instance;
  final _sb = SupabaseService.instance;

  Timer? _debounce;

  /// Builds the same payload shape used by the web app's user_data.payload
  Future<Map<String, dynamic>> buildPayload() async {
    final entries = await _db.getAllEntries();
    final settings = await _prefs.getSettings();
    final budgets = await _prefs.getBudgets();
    final recurring = await _prefs.getRecurring();
    final cats = await _db.getAllCategories();
    final customCats = cats.where((c) => c.custom).toList();

    return {
      'entries': entries.map((e) => e.toMap()).toList(),
      'settings': settings.toJson(),
      'budgets': budgets.toJson(),
      'recurring': recurring.map((r) => r.toJson()).toList(),
      'customCategories': customCats
          .map((c) => {'id': c.id, 'type': c.type, 'icon': c.icon, 'name': c.name, 'custom': true})
          .toList(),
    };
  }

  /// Pulls cloud data and overwrites local state (called after approved login)
  Future<void> hydrateFromCloud() async {
    final payload = await _sb.fetchUserData();
    if (payload == null) {
      // no cloud row yet — push current local state up
      await pushNow();
      return;
    }
    if (payload['entries'] is List) {
      final entries = (payload['entries'] as List)
          .map((e) => Entry.fromMap(Map<String, dynamic>.from(e)))
          .toList();
      await _db.replaceAllEntries(entries);
    }
    if (payload['settings'] != null) {
      await _prefs.saveSettings(AppSettings.fromJson(Map<String, dynamic>.from(payload['settings'])));
    }
    if (payload['budgets'] != null) {
      await _prefs.saveBudgets(Budgets.fromJson(Map<String, dynamic>.from(payload['budgets'])));
    }
    if (payload['recurring'] is List) {
      final rules = (payload['recurring'] as List)
          .map((r) => RecurringRule.fromJson(Map<String, dynamic>.from(r)))
          .toList();
      await _prefs.saveRecurring(rules);
    }
    if (payload['customCategories'] is List) {
      final cats = (payload['customCategories'] as List)
          .map((c) => Category(
                id: c['id'],
                type: c['type'],
                icon: c['icon'],
                name: c['name'],
                custom: true,
              ))
          .toList();
      await _db.replaceCustomCategories(cats);
    }
  }

  /// Debounced push — call after every local mutation when logged in + approved
  void schedulePush() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), pushNow);
  }

  Future<void> pushNow() async {
    if (!_sb.isLoggedIn) return;
    final payload = await buildPayload();
    await _sb.upsertUserData(payload);
  }
}
