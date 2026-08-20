import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/app_providers.dart';
import '../services/db_service.dart';
import '../services/export_service.dart';
import '../services/prefs_service.dart';
import '../services/supabase_service.dart';
import '../services/sync_service.dart';
import 'login_screen.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});
  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final userNameCtrl = TextEditingController(text: settings.userName);
    final accountNameCtrl = TextEditingController(text: settings.accountName);
    final cloudStatus = ref.watch(cloudStatusProvider);
    final sb = SupabaseService.instance;

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 120),
      children: [
        _profileHeader(settings),
        const SizedBox(height: 20),
        _sectionCard(
          icon: '👤', title: 'கணக்கு',
          child: Column(children: [
            TextField(controller: userNameCtrl, decoration: const InputDecoration(labelText: 'பெயர்'),
              onSubmitted: (_) => ref.read(settingsProvider.notifier).save(userNameCtrl.text, accountNameCtrl.text)),
            const SizedBox(height: 10),
            TextField(controller: accountNameCtrl, decoration: const InputDecoration(labelText: 'கணக்கு பெயர்'),
              onSubmitted: (_) => ref.read(settingsProvider.notifier).save(userNameCtrl.text, accountNameCtrl.text)),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => ref.read(settingsProvider.notifier).save(userNameCtrl.text, accountNameCtrl.text),
                child: const Text('சேமி'),
              ),
            ),
          ]),
        ),

        _sectionCard(
          icon: '☁️', title: 'Cloud Sync',
          child: !sb.isLoggedIn
              ? _flatTile(
                  icon: Icons.cloud_off, iconColor: AppColors.muted, title: 'Login இல்லை',
                  trailing: ElevatedButton(
                    onPressed: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                      await ref.read(cloudStatusProvider.notifier).refresh();
                      if (ref.read(cloudStatusProvider) == CloudStatus.approved) {
                        await SyncService.instance.hydrateFromCloud();
                        ref.read(entriesProvider.notifier).load();
                        ref.read(categoriesProvider.notifier).load();
                        ref.read(settingsProvider.notifier).load();
                        ref.read(budgetsProvider.notifier).load();
                        ref.read(recurringProvider.notifier).load();
                      }
                    },
                    child: const Text('Login'),
                  ),
                )
              : _flatTile(
                  icon: cloudStatus == CloudStatus.approved ? Icons.cloud_done : Icons.cloud_queue,
                  iconColor: cloudStatus == CloudStatus.approved ? AppColors.income : AppColors.gold,
                  title: sb.currentUser?.email ?? '',
                  subtitle: _statusLabel(cloudStatus),
                  trailing: TextButton(
                    onPressed: () async {
                      await sb.signOut();
                      ref.read(cloudStatusProvider.notifier).refresh();
                    },
                    child: const Text('Logout', style: TextStyle(color: AppColors.expense)),
                  ),
                ),
        ),

        _sectionCard(icon: '💰', title: 'மாத பட்ஜெட்', child: _BudgetTile()),
        _sectionCard(icon: '🔁', title: 'தானியங்கி பரிவர்த்தனைகள்', child: _RecurringTile()),
        _sectionCard(icon: '🏷️', title: 'வகைகள்', child: _CategoryManageTile()),
        _sectionCard(icon: '🔐', title: 'பாதுகாப்பு', child: _PinTile()),

        _sectionCard(
          icon: '📤', title: 'Export & Backup',
          child: Wrap(spacing: 10, runSpacing: 10, children: [
            _actionChip('📄 PDF', () async {
              final entries = ref.read(entriesProvider);
              final cats = {for (var c in ref.read(categoriesProvider)) c.id: c};
              await ExportService.exportPdf(entries, cats, settings.userName, settings.accountName);
            }),
            _actionChip('📊 Excel', () async {
              final entries = ref.read(entriesProvider);
              final cats = {for (var c in ref.read(categoriesProvider)) c.id: c};
              await ExportService.exportExcel(entries, cats);
            }),
            _actionChip('💾 Backup JSON', () async {
              final payload = await SyncService.instance.buildPayload();
              await ExportService.backupJson(payload);
            }),
          ]),
        ),

        _sectionCard(
          icon: '⚠️', title: 'Danger Zone', accent: AppColors.expense,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.expense, side: const BorderSide(color: AppColors.expense)),
            onPressed: () async {
              final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
                backgroundColor: AppColors.surface,
                title: const Text('⚠️ எல்லா data-வையும் நீக்க வேண்டுமா?'),
                content: const Text('திரும்ப பெற முடியாது!'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ரத்து')),
                  TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('நீக்கு', style: TextStyle(color: AppColors.expense))),
                ],
              ));
              if (ok == true) await ref.read(entriesProvider.notifier).clearAll();
            },
            child: const Text('எல்லா Data நீக்கு'),
          ),
        ),
      ],
    );
  }

  Widget _profileHeader(AppSettings settings) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppColors.violetDeep.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Row(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              gradient: AppColors.goldGradient, shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: AppColors.gold.withOpacity(0.35), blurRadius: 14)],
            ),
            child: const Center(child: Text('🪙', style: TextStyle(fontSize: 26))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(settings.userName.isEmpty ? 'கணக்கு தாள்' : settings.userName,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                const SizedBox(height: 2),
                Text(settings.accountName.isEmpty ? 'உங்கள் கணக்கு' : settings.accountName,
                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({required String icon, required String title, required Widget child, Color? accent}) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: glassCard(radius: 20, borderColor: accent != null ? accent.withOpacity(0.4) : null),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Text(icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(title, style: AppText.label.copyWith(color: accent ?? AppColors.text2)),
            ]),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _flatTile({required IconData icon, required Color iconColor, required String title, String? subtitle, required Widget trailing}) {
    return Row(
      children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(color: iconColor.withOpacity(0.14), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppText.body.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
              if (subtitle != null) Text(subtitle, style: AppText.caption),
            ],
          ),
        ),
        trailing,
      ],
    );
  }

  String _statusLabel(CloudStatus s) {
    switch (s) {
      case CloudStatus.approved: return '☁️ Cloud sync ஆன்';
      case CloudStatus.pending: return '⏳ Admin approval-க்கு காத்திருக்கிறது';
      case CloudStatus.rejected: return '❌ அணுகல் நிராகரிக்கப்பட்டது';
      default: return '⚠️ Cloud இணைக்க முடியவில்லை';
    }
  }

  Widget _actionChip(String label, VoidCallback onTap) => ActionChip(label: Text(label), onPressed: onTap);
}

class _BudgetTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgets = ref.watch(budgetsProvider);
    return ListTile(
      tileColor: AppColors.surface2,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Text('மொத்த பட்ஜெட்: ₹${budgets.overall.toStringAsFixed(0)}'),
      trailing: const Icon(Icons.edit, size: 18),
      onTap: () async {
        final ctrl = TextEditingController(text: budgets.overall == 0 ? '' : budgets.overall.toString());
        final result = await showDialog<double>(context: context, builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('மாத பட்ஜெட் அமை'),
          content: TextField(controller: ctrl, keyboardType: TextInputType.number, decoration: const InputDecoration(prefixText: '₹ ')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ரத்து')),
            TextButton(onPressed: () => Navigator.pop(ctx, double.tryParse(ctrl.text) ?? 0), child: const Text('சேமி')),
          ],
        ));
        if (result != null) {
          await ref.read(budgetsProvider.notifier).save(result, budgets.categories);
        }
      },
    );
  }
}

class _RecurringTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rules = ref.watch(recurringProvider);
    return Column(
      children: [
        ...rules.map((r) => ListTile(
          tileColor: AppColors.surface2,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Text(r.desc),
          subtitle: Text('₹${r.amount.toStringAsFixed(0)} • ${r.frequency == 'monthly' ? 'மாதம்தோறும்' : 'வாரம்தோறும்'}'),
          trailing: IconButton(icon: const Icon(Icons.delete, color: AppColors.expense), onPressed: () => ref.read(recurringProvider.notifier).remove(r.id)),
        )),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            icon: const Icon(Icons.add), label: const Text('சேர்'),
            onPressed: () => _addRecurring(context, ref),
          ),
        ),
      ],
    );
  }

  void _addRecurring(BuildContext context, WidgetRef ref) {
    String type = 'expense';
    String frequency = 'monthly';
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String? category;
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) {
      final cats = type == 'income' ? ref.read(incomeCategoriesProvider) : ref.read(expenseCategoriesProvider);
      category ??= cats.isNotEmpty ? cats.first.id : null;
      return AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('தானியங்கி பரிவர்த்தனை'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: amountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'தொகை')),
          TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'விவரம்')),
          DropdownButton<String>(value: category, isExpanded: true,
            items: cats.map((c) => DropdownMenuItem(value: c.id, child: Text('${c.icon} ${c.name}'))).toList(),
            onChanged: (v) => setSt(() => category = v)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ரத்து')),
          TextButton(onPressed: () {
            final amount = double.tryParse(amountCtrl.text);
            if (amount == null || descCtrl.text.trim().isEmpty || category == null) return;
            ref.read(recurringProvider.notifier).add(RecurringRule(
              id: const Uuid().v4(), type: type, amount: amount, desc: descCtrl.text.trim(),
              category: category!, frequency: frequency, lastRun: '',
            ));
            Navigator.pop(ctx);
          }, child: const Text('சேர்')),
        ],
      );
    }));
  }
}

class _CategoryManageTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customCats = ref.watch(categoriesProvider).where((c) => c.custom).toList();
    return Column(
      children: [
        ...customCats.map((c) => ListTile(
          tileColor: AppColors.surface2,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          leading: Text(c.icon),
          title: Text(c.name),
          subtitle: Text(c.type == 'income' ? 'வருமானம்' : 'செலவு'),
          trailing: IconButton(icon: const Icon(Icons.delete, color: AppColors.expense), onPressed: () => ref.read(categoriesProvider.notifier).removeCustom(c.id)),
        )),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(icon: const Icon(Icons.add), label: const Text('புதிய வகை சேர்'), onPressed: () => _addCat(context, ref)),
        ),
      ],
    );
  }

  void _addCat(BuildContext context, WidgetRef ref) {
    String type = 'expense';
    final iconCtrl = TextEditingController(text: '📌');
    final nameCtrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('புதிய வகை'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          Expanded(child: ChoiceChip(label: const Text('வருமானம்'), selected: type == 'income', onSelected: (_) => setSt(() => type = 'income'))),
          const SizedBox(width: 8),
          Expanded(child: ChoiceChip(label: const Text('செலவு'), selected: type == 'expense', onSelected: (_) => setSt(() => type = 'expense'))),
        ]),
        TextField(controller: iconCtrl, decoration: const InputDecoration(labelText: 'ஐகான்')),
        TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'வகை பெயர்')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ரத்து')),
        TextButton(onPressed: () {
          if (nameCtrl.text.trim().isEmpty) return;
          ref.read(categoriesProvider.notifier).addCustom(type, iconCtrl.text.trim(), nameCtrl.text.trim());
          Navigator.pop(ctx);
        }, child: const Text('சேர்')),
      ],
    )));
  }
}

class _PinTile extends StatefulWidget {
  @override
  State<_PinTile> createState() => _PinTileState();
}

class _PinTileState extends State<_PinTile> {
  bool? hasPin;

  @override
  void initState() {
    super.initState();
    PrefsService.instance.getPin().then((p) => setState(() => hasPin = p != null));
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: AppColors.surface2,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Text(hasPin == true ? '🔐 PIN அமைக்கப்பட்டுள்ளது' : 'PIN இல்லை'),
      trailing: hasPin == true
          ? TextButton(onPressed: () async { await PrefsService.instance.removePin(); setState(() => hasPin = false); }, child: const Text('நீக்கு'))
          : TextButton(onPressed: () => _setupPin(context), child: const Text('Set')),
    );
  }

  void _setupPin(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('4 இலக்க PIN'),
      content: TextField(controller: ctrl, keyboardType: TextInputType.number, maxLength: 4, obscureText: true),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ரத்து')),
        TextButton(onPressed: () async {
          if (ctrl.text.length == 4) {
            await PrefsService.instance.setPin(ctrl.text);
            setState(() => hasPin = true);
            if (context.mounted) Navigator.pop(ctx);
          }
        }, child: const Text('சேமி')),
      ],
    ));
  }
}
