import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../services/db_service.dart';
import '../services/prefs_service.dart';
import '../services/sync_service.dart';
import '../services/supabase_service.dart';

final _db = DbService.instance;
final _prefs = PrefsService.instance;
final _sync = SyncService.instance;
final _sb = SupabaseService.instance;
const _uuid = Uuid();

// ---------------- ENTRIES ----------------

class EntriesNotifier extends StateNotifier<List<Entry>> {
  EntriesNotifier() : super([]) {
    load();
  }

  Future<void> load() async {
    state = await _db.getAllEntries();
  }

  Future<void> add({
    required String date,
    required String type,
    required double amount,
    required String desc,
    required String category,
  }) async {
    final e = Entry(
      id: _uuid.v4(),
      date: date,
      type: type,
      amount: amount,
      desc: desc,
      category: category,
      createdAt: DateTime.now().toIso8601String(),
    );
    await _db.upsertEntry(e);
    await load();
    _sync.schedulePush();
  }

  Future<void> update(Entry e) async {
    await _db.upsertEntry(e);
    await load();
    _sync.schedulePush();
  }

  Future<void> remove(String id) async {
    await _db.deleteEntry(id);
    await load();
    _sync.schedulePush();
  }

  Future<void> clearAll() async {
    await _db.clearEntries();
    await load();
    _sync.schedulePush();
  }
}

final entriesProvider = StateNotifierProvider<EntriesNotifier, List<Entry>>(
  (ref) => EntriesNotifier(),
);

// ---------------- CATEGORIES ----------------

class CategoriesNotifier extends StateNotifier<List<Category>> {
  CategoriesNotifier() : super([]) {
    load();
  }

  Future<void> load() async {
    state = await _db.getAllCategories();
  }

  Future<void> addCustom(String type, String icon, String name) async {
    final c = Category(id: _uuid.v4(), type: type, icon: icon, name: name, custom: true);
    await _db.addCategory(c);
    await load();
    _sync.schedulePush();
  }

  Future<void> removeCustom(String id) async {
    await _db.deleteCategory(id);
    await load();
    _sync.schedulePush();
  }
}

final categoriesProvider = StateNotifierProvider<CategoriesNotifier, List<Category>>(
  (ref) => CategoriesNotifier(),
);

final incomeCategoriesProvider = Provider<List<Category>>(
  (ref) => ref.watch(categoriesProvider).where((c) => c.type == 'income').toList(),
);
final expenseCategoriesProvider = Provider<List<Category>>(
  (ref) => ref.watch(categoriesProvider).where((c) => c.type == 'expense').toList(),
);

// ---------------- SETTINGS ----------------

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(AppSettings()) {
    load();
  }

  Future<void> load() async {
    state = await _prefs.getSettings();
  }

  Future<void> save(String userName, String accountName) async {
    state = AppSettings(userName: userName, accountName: accountName);
    await _prefs.saveSettings(state);
    _sync.schedulePush();
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>(
  (ref) => SettingsNotifier(),
);

// ---------------- BUDGETS ----------------

class BudgetsNotifier extends StateNotifier<Budgets> {
  BudgetsNotifier() : super(Budgets()) {
    load();
  }

  Future<void> load() async {
    state = await _prefs.getBudgets();
  }

  Future<void> save(double overall, Map<String, double> categories) async {
    state = Budgets(overall: overall, categories: categories);
    await _prefs.saveBudgets(state);
    _sync.schedulePush();
  }
}

final budgetsProvider = StateNotifierProvider<BudgetsNotifier, Budgets>(
  (ref) => BudgetsNotifier(),
);

// ---------------- RECURRING ----------------

class RecurringNotifier extends StateNotifier<List<RecurringRule>> {
  RecurringNotifier() : super([]) {
    load();
  }

  Future<void> load() async {
    state = await _prefs.getRecurring();
  }

  Future<void> add(RecurringRule r) async {
    state = [...state, r];
    await _prefs.saveRecurring(state);
    _sync.schedulePush();
  }

  Future<void> remove(String id) async {
    state = state.where((r) => r.id != id).toList();
    await _prefs.saveRecurring(state);
    _sync.schedulePush();
  }

  Future<void> replaceAll(List<RecurringRule> rules) async {
    state = rules;
    await _prefs.saveRecurring(state);
  }
}

final recurringProvider = StateNotifierProvider<RecurringNotifier, List<RecurringRule>>(
  (ref) => RecurringNotifier(),
);

// ---------------- CLOUD / AUTH ----------------

enum CloudStatus { none, pending, approved, rejected, error }

class CloudStatusNotifier extends StateNotifier<CloudStatus> {
  CloudStatusNotifier() : super(CloudStatus.none);

  Future<void> refresh() async {
    if (!_sb.isLoggedIn) {
      state = CloudStatus.none;
      return;
    }
    final s = await _sb.checkProfileStatus();
    state = CloudStatus.values.firstWhere((e) => e.name == s, orElse: () => CloudStatus.error);
  }
}

final cloudStatusProvider = StateNotifierProvider<CloudStatusNotifier, CloudStatus>(
  (ref) => CloudStatusNotifier(),
);
