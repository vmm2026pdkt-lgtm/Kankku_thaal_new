import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../providers/app_providers.dart';

class MonthlyPage extends ConsumerStatefulWidget {
  const MonthlyPage({super.key});
  @override
  ConsumerState<MonthlyPage> createState() => _MonthlyPageState();
}

class _MonthlyPageState extends ConsumerState<MonthlyPage> {
  int year = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(entriesProvider);
    String fmt(double n) => '₹${NumberFormat('#,##0').format(n)}';

    final monthlyIncome = List<double>.filled(12, 0);
    final monthlyExpense = List<double>.filled(12, 0);
    for (final e in entries) {
      final d = DateTime.tryParse(e.date);
      if (d == null || d.year != year) continue;
      if (e.type == 'income') monthlyIncome[d.month - 1] += e.amount;
      else monthlyExpense[d.month - 1] += e.amount;
    }
    final maxVal = [...monthlyIncome, ...monthlyExpense].fold(0.0, (m, v) => v > m ? v : m);

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 120),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: glassCard(radius: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(icon: const Icon(Icons.chevron_left, color: AppColors.text2), onPressed: () => setState(() => year--)),
              Text('$year', style: AppText.h2),
              IconButton(icon: const Icon(Icons.chevron_right, color: AppColors.text2), onPressed: () => setState(() => year++)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 260,
          child: maxVal == 0
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Text('📈', style: TextStyle(fontSize: 44)),
                    const SizedBox(height: 10),
                    Text('இந்த வருடம் தரவு இல்லை', style: AppText.body.copyWith(color: AppColors.text2)),
                  ]),
                )
              : Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding: const EdgeInsets.fromLTRB(4, 16, 12, 4),
                  child: BarChart(
                    BarChartData(
                      maxY: maxVal * 1.15,
                      barGroups: List.generate(12, (i) => BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(toY: monthlyIncome[i], color: AppColors.income, width: 6, borderRadius: BorderRadius.circular(3)),
                          BarChartRodData(toY: monthlyExpense[i], color: AppColors.expense, width: 6, borderRadius: BorderRadius.circular(3)),
                        ],
                      )),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(sideTitles: SideTitles(
                          showTitles: true, getTitlesWidget: (v, _) => Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(monthNamesTa[v.toInt()].substring(0, 3), style: const TextStyle(fontSize: 9, color: AppColors.muted)),
                          ),
                        )),
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _legendDot(AppColors.income, 'வருமானம்'),
            const SizedBox(width: 20),
            _legendDot(AppColors.expense, 'செலவு'),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: glassCard(radius: 18),
          child: Column(
            children: List.generate(12, (i) {
              final inc = monthlyIncome[i]; final exp = monthlyExpense[i];
              if (inc == 0 && exp == 0) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 9),
                child: Row(
                  children: [
                    Expanded(child: Text(monthNamesTa[i], style: AppText.body.copyWith(fontWeight: FontWeight.w600))),
                    Text(fmt(inc), style: const TextStyle(color: AppColors.income, fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(width: 12),
                    Text(fmt(exp), style: const TextStyle(color: AppColors.expense, fontWeight: FontWeight.w700, fontSize: 13)),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _legendDot(Color c, String label) => Row(
    children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
      const SizedBox(width: 6), Text(label, style: const TextStyle(fontSize: 12)),
    ],
  );
}
