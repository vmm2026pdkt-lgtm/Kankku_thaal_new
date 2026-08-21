import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../providers/app_providers.dart';
import '../widgets/entry_form_sheet.dart';

class HomePage extends ConsumerStatefulWidget {
  final VoidCallback? onSeeAllTransactions;
  const HomePage({super.key, this.onSeeAllTransactions});
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

    // Previous-month comparison — pure UI-derived display value from the
    // same existing entries data, doesn't change any stored data/logic.
    final prevMonth = DateTime(month.year, month.month - 1);
    final prevYm = DateFormat('yyyy-MM').format(prevMonth);
    final prevEntries = entries.where((e) => e.date.startsWith(prevYm)).toList();
    final prevIncome = prevEntries.where((e) => e.type == 'income').fold(0.0, (s, e) => s + e.amount);
    final prevExpense = prevEntries.where((e) => e.type == 'expense').fold(0.0, (s, e) => s + e.amount);
    final incomeChange = prevIncome == 0 ? null : ((income - prevIncome) / prevIncome * 100);
    final expenseChange = prevExpense == 0 ? null : ((expense - prevExpense) / prevExpense * 100);

    return ListView(
      padding: const EdgeInsets.only(bottom: 120),
      children: [
        _BalanceCard(
          month: month,
          balance: balance,
          onPrev: () => setState(() => month = DateTime(month.year, month.month - 1)),
          onNext: () => setState(() => month = DateTime(month.year, month.month + 1)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
          child: Row(
            children: [
              Expanded(child: _SummaryCard(label: 'வருமானம்', amount: income, isIncome: true, change: incomeChange)),
              const SizedBox(width: 10),
              Expanded(child: _SummaryCard(label: 'செலவு', amount: expense, isIncome: false, change: expenseChange)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
          child: Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.add, label: 'வரவு', subtitle: 'புதிய வருமானம் சேர்க்க', color: AppColors.income,
                  onTap: () => showEntryFormSheet(context, ref, defaultType: 'income'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.remove, label: 'செலவு', subtitle: 'செலவினத்தை பதிவு செய்ய', color: AppColors.expense,
                  onTap: () => showEntryFormSheet(context, ref, defaultType: 'expense'),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
          child: Row(
            children: [
              const Icon(Icons.receipt_long_rounded, size: 17, color: AppColors.gold),
              const SizedBox(width: 8),
              Text('சமீபத்திய பரிவர்த்தனைகள்', style: AppText.h2),
              const Spacer(),
              if (recent.isNotEmpty)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: widget.onSeeAllTransactions,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surface2,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('மேலும்', style: TextStyle(color: AppColors.gold, fontSize: 12.5, fontWeight: FontWeight.w700)),
                          const SizedBox(width: 2),
                          const Icon(Icons.chevron_right, size: 16, color: AppColors.gold),
                        ],
                      ),
                    ),
                  ),
                ),
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
                date: DateFormat('dd MMM yyyy').format(DateTime.parse(e.date)),
                amount: e.amount,
                isIncome: e.type == 'income',
                onTap: () => showEntryFormSheet(context, ref, existing: e),
              ),
            );
          }),
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final DateTime month;
  final double balance;
  final VoidCallback onPrev, onNext;
  const _BalanceCard({required this.month, required this.balance, required this.onPrev, required this.onNext});

  @override
  Widget build(BuildContext context) {
    String fmt(double n) => '₹${NumberFormat('#,##0').format(n)}';

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.gold.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(color: AppColors.violetDeep.withOpacity(0.35), blurRadius: 28, offset: const Offset(0, 14)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(top: -30, right: -20, child: _glowCircle(90, AppColors.gold.withOpacity(0.14))),
          Positioned(bottom: -40, left: -30, child: _glowCircle(120, AppColors.violet.withOpacity(0.16))),
          // decorative money-bag motif, reference-inspired accent
          Positioned(
            right: 4, bottom: 6,
            child: Opacity(opacity: 0.9, child: Text('💰', style: TextStyle(fontSize: 54))),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_month_rounded, size: 16, color: Colors.white70),
                      const SizedBox(width: 6),
                      Text('கணக்கு தாள்',
                          style: AppText.body.copyWith(color: Colors.white.withOpacity(0.85)),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                  _monthSwitcher(),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.account_balance_wallet_rounded, size: 15, color: Colors.white54),
                  const SizedBox(width: 6),
                  Text('மொத்த இருப்பு', style: AppText.label.copyWith(color: Colors.white.withOpacity(0.6))),
                ],
              ),
              const SizedBox(height: 6),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: balance),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (context, v, _) => Text(fmt(v), style: AppText.hero.copyWith(color: Colors.white)),
              ),
              const SizedBox(height: 8),
              Container(
                height: 3, width: 90,
                decoration: BoxDecoration(
                  gradient: AppColors.goldGradient,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [BoxShadow(color: AppColors.gold.withOpacity(0.5), blurRadius: 8)],
                ),
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
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final bool isIncome;
  final double? change;
  const _SummaryCard({required this.label, required this.amount, required this.isIncome, this.change});

  @override
  Widget build(BuildContext context) {
    final color = isIncome ? AppColors.income : AppColors.expense;
    String fmt(double n) => '₹${NumberFormat('#,##0').format(n)}';
    final up = (change ?? 0) >= 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Icon(isIncome ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, size: 15, color: Colors.black),
              ),
              const SizedBox(width: 8),
              Text(label, style: AppText.body.copyWith(fontWeight: FontWeight.w700, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 10),
          Text(fmt(amount), style: AppText.amount.copyWith(fontSize: 19, color: color)),
          if (change != null) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(up ? Icons.arrow_drop_up : Icons.arrow_drop_down, size: 16, color: color),
                Text('${change!.abs().toStringAsFixed(0)}% ${up ? 'அதிகரிப்பு' : 'குறைவு'}',
                    style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label, subtitle;
  final Color color;
  final VoidCallback onTap;
  const _QuickActionCard({required this.icon, required this.label, required this.subtitle, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withOpacity(0.35)),
          ),
          child: Row(
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Icon(icon, color: Colors.black, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppText.body.copyWith(fontWeight: FontWeight.w700, fontSize: 13.5)),
                    Text(subtitle, style: AppText.caption.copyWith(fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 18, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  final String icon, title, date;
  final double amount;
  final bool isIncome;
  final VoidCallback onTap;
  const _EntryTile({
    required this.icon, required this.title, required this.date,
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
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 3),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 10, color: AppColors.muted),
                          const SizedBox(width: 4),
                          Text(date, style: AppText.caption),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${isIncome ? '+' : '-'}${fmt(amount)}',
                        style: AppText.amount.copyWith(color: color, fontSize: 14.5)),
                    const SizedBox(height: 2),
                    const Icon(Icons.chevron_right, size: 16, color: AppColors.muted),
                  ],
                ),
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
        mainAxisSize: MainAxisSize.min,
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
