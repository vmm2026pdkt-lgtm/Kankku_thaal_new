import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../providers/app_providers.dart';
import '../services/business_logic.dart';
import '../services/db_service.dart';
import '../services/prefs_service.dart';
import '../services/supabase_service.dart';
import '../services/sync_service.dart';
import 'home_shell.dart';
import 'pin_lock_screen.dart';
import 'setup_wizard_screen.dart';

class AppGate extends ConsumerStatefulWidget {
  const AppGate({super.key});
  @override
  ConsumerState<AppGate> createState() => _AppGateState();
}

enum _Stage { loading, pinLock, setupWizard, ready }

class _AppGateState extends ConsumerState<AppGate> {
  _Stage stage = _Stage.loading;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    final prefs = PrefsService.instance;
    final pin = await prefs.getPin();

    if (pin != null) {
      setState(() => stage = _Stage.pinLock);
      return;
    }
    await _afterUnlock();
  }

  Future<void> _afterUnlock() async {
    await _processRecurring();

    final setupDone = await PrefsService.instance.isSetupDone();
    if (!setupDone) {
      setState(() => stage = _Stage.setupWizard);
      return;
    }

    await _checkCloud();
    setState(() => stage = _Stage.ready);
  }

  Future<void> _processRecurring() async {
    final rules = await PrefsService.instance.getRecurring();
    if (rules.isEmpty) return;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final due = computeDueRecurring(rules, today, () => const Uuid().v4());
    if (due.isEmpty) return;

    for (final d in due) {
      await DbService.instance.upsertEntry(d.entry);
    }
    final updatedRules = rules.map((r) {
      final match = due.where((d) => d.rule.id == r.id).toList();
      return match.isEmpty ? r : r.copyWith(lastRun: today);
    }).toList();
    await PrefsService.instance.saveRecurring(updatedRules);
  }

  Future<void> _checkCloud() async {
    final sb = SupabaseService.instance;
    if (!sb.isLoggedIn) return;
    await ref.read(cloudStatusProvider.notifier).refresh();
    if (ref.read(cloudStatusProvider) == CloudStatus.approved) {
      await SyncService.instance.hydrateFromCloud();
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (stage) {
      case _Stage.loading:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case _Stage.pinLock:
        return PinLockScreen(onUnlocked: _afterUnlock);
      case _Stage.setupWizard:
        return SetupWizardScreen(onDone: () async {
          await _checkCloud();
          setState(() => stage = _Stage.ready);
        });
      case _Stage.ready:
        // refresh all providers now that boot-time mutations are done
        ref.read(entriesProvider.notifier).load();
        ref.read(categoriesProvider.notifier).load();
        ref.read(recurringProvider.notifier).load();
        return const HomeShell();
    }
  }
}
