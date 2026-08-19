import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../providers/app_providers.dart';

class CategoryPage extends ConsumerStatefulWidget {
  const CategoryPage({super.key});
  @override
  ConsumerState<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends ConsumerState<CategoryPage> {
  DateTime month = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(entriesProvider);
    final expCats = ref.watch(expenseCategoriesProvider);
    final ym = DateFormat('yyyy-MM').format(month);
    final monthExp = entries.where((e) => e.type == 'expense' && e.date.startsWith(ym)).toList();
    final total = monthExp.fold(0.0, (s, e) => s + e.amount);

    final byCat = <String, double>{};
    for (final e in monthExp) {
      byCat[e.category] = (byCat[e.category] ?? 0) + e.amount;
    }
    final sortedEntries = byCat.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    String fmt(double n) => '₹${NumberFormat('#,##0').format(n)}';

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 100),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => setState(() => month = DateTime(month.year, month.month - 1))),
            Text(DateFormat('MMMM yyyy').format(month), style: const TextStyle(fontWeight: FontWeight.bold)),
            IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => setState(() => month = DateTime(month.year, month.month + 1))),
          ],
        ),
        const SizedBox(height: 10),
        if (total == 0)
          const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: Text('இந்த மாதம் செலவு இல்லை', style: TextStyle(color: AppColors.muted))),
          )
        else ...[
          SizedBox(
            height: 220,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 60,
                sections: List.generate(sortedEntries.length, (i) {
                  final entry = sortedEntries[i];
                  final color = Color(DefaultCategories.catColors[i % DefaultCategories.catColors.length]);
                  final pct = (entry.value / total * 100);
                  return PieChartSectionData(
                    value: entry.value, color: color,
                    title: pct >= 5 ? '${pct.toStringAsFixed(0)}%' : '',
                    radius: 50,
                    titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                  );
                }),
              ),
            ),
          ),
          Center(
            child: Text('மொத்த செலவு: ${fmt(total)}', style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const SizedBox(height: 20),
          ...List.generate(sortedEntries.length, (i) {
            final entry = sortedEntries[i];
            final cat = expCats.where((c) => c.id == entry.key).toList();
            final catName = cat.isNotEmpty ? cat.first.name : entry.key;
            final catIcon = cat.isNotEmpty ? cat.first.icon : '📌';
            final color = Color(DefaultCategories.catColors[i % DefaultCategories.catColors.length]);
            final pct = (entry.value / total * 100);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text(catIcon), const SizedBox(width: 6),
                  Expanded(child: Text(catName)),
                  Text('${pct.toStringAsFixed(1)}%', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                  const SizedBox(width: 10),
                  Text(fmt(entry.value), style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }
}
