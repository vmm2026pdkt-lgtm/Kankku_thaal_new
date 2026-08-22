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
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 120),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          decoration: glassCard(radius: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(icon: const Icon(Icons.chevron_left, color: AppColors.text2), onPressed: () => setState(() => month = DateTime(month.year, month.month - 1))),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_month_rounded, size: 16, color: AppColors.gold),
                  const SizedBox(width: 6),
                  Text(DateFormat('MMMM yyyy').format(month), style: AppText.h2),
                ],
              ),
              IconButton(icon: const Icon(Icons.chevron_right, color: AppColors.text2), onPressed: () => setState(() => month = DateTime(month.year, month.month + 1))),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (total == 0)
          Padding(
            padding: const EdgeInsets.all(40),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('📊', style: TextStyle(fontSize: 44)),
              const SizedBox(height: 10),
              Text('இந்த மாதம் செலவு இல்லை', style: AppText.body.copyWith(color: AppColors.text2)),
            ]),
          )
        else ...[
          SizedBox(
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 64,
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
                // Center label — pure UI addition, uses the same `total`
                // value already computed above (no calculation change).
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(fmt(total), style: AppText.amount.copyWith(fontSize: 20)),
                    const SizedBox(height: 2),
                    Text('மொத்த செலவு', style: AppText.caption),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: glassCard(radius: 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(sortedEntries.length, (i) {
                final entry = sortedEntries[i];
                final cat = expCats.where((c) => c.id == entry.key).toList();
                final catName = cat.isNotEmpty ? cat.first.name : entry.key;
                final catIcon = cat.isNotEmpty ? cat.first.icon : '📌';
                final color = Color(DefaultCategories.catColors[i % DefaultCategories.catColors.length]);
                final pct = (entry.value / total * 100);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(catIcon, style: const TextStyle(fontSize: 15)), const SizedBox(width: 8),
                          Expanded(child: Text(catName, style: AppText.body.copyWith(fontWeight: FontWeight.w600))),
                          Text('${pct.toStringAsFixed(1)}%', style: AppText.caption),
                          const SizedBox(width: 10),
                          Text(fmt(entry.value), style: AppText.amount.copyWith(fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 7),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: (pct / 100).clamp(0.0, 1.0),
                          minHeight: 6,
                          backgroundColor: AppColors.surface2,
                          valueColor: AlwaysStoppedAnimation(color),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ],
    );
  }
}
