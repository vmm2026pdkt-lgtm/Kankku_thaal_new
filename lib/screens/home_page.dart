import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../providers/app_providers.dart';
import '../widgets/entry_form_sheet.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});
  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  DateTime month = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(entriesProvider);
    final settings = ref.watch(settingsProvider);
    final ym = DateFormat('yyyy-MM').format(month);
    final monthEntries = entries.where((e) => e.date.startsWith(ym)).toList();
    final income = monthEntries.where((e) => e.type == 'income').fold(0.0, (s, e) => s + e.amount);
    final expense = monthEntries.where((e) => e.type == 'expense').fold(0.0, (s, e) => s + e.amount);
    final balance = income - expense;
    final recent = [...monthEntries]..sort((a, b) => b.date.compareTo(a.date));
    final catsById = {for (var c in ref.watch(categoriesProvider)) c.id: c};

    return ListView(
      padding: const EdgeInsets.only(bottom: 120),
      children: [
        _HeroWalletCard(
          month: month,
          balance: balance,
          income: income,
          expense: expense,
          greeting: settings.userName.isEmpty ? 'கணக்கு தாள்' : 'வணக்கம், ${settings.userName}',
          onPrev: () => setState(() => month = DateTime(month.year, month.month - 1)),
          onNext: () => setState(() => month = DateTime(month.year, month.month + 1)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 0),
          child: Row(
            children: [
              Expanded(child: _quickAction('➕', 'வரவு', AppColors.income,
                  () => showEntryFormSheet(context, ref, defaultType: 'income'))),
              const SizedBox(width: 10),
              Expanded(child: _quickAction('➖', 'செலவு', AppColors.expense,
                  () => showEntryFormSheet(context, ref, defaultType: 'expense'))),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 24, 18, 10),
          child: Row(
            children: [
              Text('சமீபத்திய பரிவர்த்தனைகள்', style: AppText.label),
              const Spacer(),
              if (recent.isNotEmpty)
                Text('${recent.length} உள்ளீடுகள்', style: AppText.caption),
            ],
          ),
        ),
        if (recent.isEmpty)
          _EmptyState(onAdd: () => showEntryFormSheet(context, ref, defaultType: 'expense'))
        else
          ...List.generate(recent.take(12).length, (i) {
            final e = recent[i];
            final cat = catsById[e.category];
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: Duration(milliseconds: 220 + i * 30),
              curve: Curves.easeOutCubic,
              builder: (context, v, child) => Opacity(
                opacity: v,
                child: Transform.translate(offset: Offset(0, (1 - v) * 12), child: child),
              ),
              child: _EntryTile(
                icon: cat?.icon ?? '📌',
                title: e.desc,
                subtitle: '${cat?.name ?? e.category} • ${DateFormat('dd MMM').format(DateTime.parse(e.date))}',
                amount: e.amount,
                isIncome: e.type == 'income',
                onTap: () => showEntryFormSheet(context, ref, existing: e),
              ),
            );
          }),
      ],
    );
  }

  Widget _quickAction(String icon, String label, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: glassCard(radius: 18, borderColor: color.withOpacity(0.35)),
          child: Column(
            children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(color: color.withOpacity(0.16), shape: BoxShape.circle),
                child: Center(child: Text(icon, style: TextStyle(fontSize: 15, color: color))),
              ),
              const SizedBox(height: 8),
              Text(label, style: AppText.body.copyWith(fontWeight: FontWeight.w700, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroWalletCard extends StatelessWidget {
  final DateTime month;
  final double balance, income, expense;
  final String greeting;
  final VoidCallback onPrev, onNext;
  const _HeroWalletCard({
    required this.month, required this.balance, required this.income,
    required this.expense, required this.greeting, required this.onPrev, required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    String fmt(double n) => '₹${NumberFormat('#,##0').format(n)}';

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: AppColors.violetDeep.withOpacity(0.35), blurRadius: 28, offset: const Offset(0, 14)),
        ],
      ),
      child: Stack(
        children: [
          // decorative glow circles — signature touch
          Positioned(top: -30, right: -20, child: _glowCircle(90, AppColors.gold.withOpacity(0.16))),
          Positioned(bottom: -40, left: -30, child: _glowCircle(120, AppColors.violet.withOpacity(0.18))),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(greeting,
                        style: AppText.body.copyWith(color: Colors.white.withOpacity(0.85)),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  _monthSwitcher(),
                ],
              ),
              const SizedBox(height: 18),
              Text('மொத்த இருப்பு', style: AppText.label.copyWith(color: Colors.white.withOpacity(0.6))),
              const SizedBox(height: 4),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: balance),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (context, v, _) => Text(fmt(v), style: AppText.hero.copyWith(color: Colors.white)),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _pill('⬆', 'வருமானம்', fmt(income), AppColors.income)),
                  const SizedBox(width: 10),
                  Expanded(child: _pill('⬇', 'செலவு', fmt(expense), AppColors.expense)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _glowCircle(double size, Color color) => Container(
        width: size, height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );

  Widget _monthSwitcher() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.10),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _navBtn(Icons.chevron_left, onPrev),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(DateFormat('MMM yyyy').format(month),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5)),
            ),
            _navBtn(Icons.chevron_right, onNext),
          ],
        ),
      );

  Widget _navBtn(IconData icon, VoidCallback onTap) => InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(4), child: Icon(icon, size: 18, color: Colors.white)),
      );

  Widget _pill(String arrow, String label, String amount, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 20, height: 20,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Center(child: Text(arrow, style: const TextStyle(fontSize: 10, color: Colors.black))),
              ),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11.5, fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 6),
            Text(amount, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
          ],
        ),
      );
}

class _EntryTile extends StatelessWidget {
  final String icon, title, subtitle;
  final double amount;
  final bool isIncome;
  final VoidCallback onTap;
  const _EntryTile({
    required this.icon, required this.title, required this.subtitle,
    required this.amount, required this.isIncome, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isIncome ? AppColors.income : AppColors.expense;
    String fmt(double n) => '₹${NumberFormat('#,##0').format(n)}';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: glassCard(radius: 18),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(child: Text(icon, style: const TextStyle(fontSize: 20))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: AppText.caption),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text('${isIncome ? '+' : '-'}${fmt(amount)}',
                    style: AppText.amount.copyWith(color: color, fontSize: 15)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 10),
      child: Column(
        children: [
          const Text('🧾', style: TextStyle(fontSize: 44)),
          const SizedBox(height: 10),
          Text('இந்த மாதம் உள்ளீடுகள் இல்லை', style: AppText.body.copyWith(color: AppColors.text2)),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('முதல் உள்ளீடு சேர்'),
          ),
        ],
      ),
    );
  }
}
