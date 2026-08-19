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
    final ym = DateFormat('yyyy-MM').format(month);
    final monthEntries = entries.where((e) => e.date.startsWith(ym)).toList();
    final income = monthEntries.where((e) => e.type == 'income').fold(0.0, (s, e) => s + e.amount);
    final expense = monthEntries.where((e) => e.type == 'expense').fold(0.0, (s, e) => s + e.amount);
    final balance = income - expense;
    final recent = [...monthEntries]..sort((a, b) => b.date.compareTo(a.date));
    final catsById = {for (var c in ref.watch(categoriesProvider)) c.id: c};

    String fmt(double n) => '₹${NumberFormat('#,##0').format(n)}';

    return ListView(
      padding: const EdgeInsets.only(bottom: 100),
      children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface, borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => setState(() => month = DateTime(month.year, month.month - 1))),
                Text(DateFormat('MMMM yyyy').format(month), style: const TextStyle(fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => setState(() => month = DateTime(month.year, month.month + 1))),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Expanded(child: _summaryCard('வருமானம்', fmt(income), AppColors.income)),
              const SizedBox(width: 10),
              Expanded(child: _summaryCard('செலவு', fmt(expense), AppColors.expense)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
          child: _summaryCard('இருப்பு தொகை', fmt(balance), AppColors.gold, big: true),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 20, 14, 8),
          child: Text('சமீபத்திய பரிவர்த்தனைகள்', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text2, fontSize: 13)),
        ),
        if (recent.isEmpty)
          const Padding(
            padding: EdgeInsets.all(30),
            child: Center(child: Text('உள்ளீடுகள் இல்லை', style: TextStyle(color: AppColors.muted))),
          )
        else
          ...recent.take(10).map((e) {
            final cat = catsById[e.category];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: ListTile(
                tileColor: AppColors.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.border)),
                leading: CircleAvatar(backgroundColor: AppColors.surface2, child: Text(cat?.icon ?? '📌')),
                title: Text(e.desc, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text('${cat?.name ?? e.category} • ${DateFormat('dd/MM').format(DateTime.parse(e.date))}'),
                trailing: Text(
                  '${e.type == 'income' ? '+' : '-'}${fmt(e.amount)}',
                  style: TextStyle(color: e.type == 'income' ? AppColors.income : AppColors.expense, fontWeight: FontWeight.bold),
                ),
                onTap: () => showEntryFormSheet(context, ref, existing: e),
              ),
            );
          }),
      ],
    );
  }

  Widget _summaryCard(String label, String amount, Color color, {bool big = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: color.withOpacity(0.0))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          const SizedBox(height: 6),
          Text(amount, style: TextStyle(color: color, fontSize: big ? 26 : 22, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
