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
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 100),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => setState(() => year--)),
            Text('$year', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => setState(() => year++)),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 260,
          child: maxVal == 0
              ? const Center(child: Text('இந்த வருடம் தரவு இல்லை', style: TextStyle(color: AppColors.muted)))
              : BarChart(
                  BarChartData(
                    maxY: maxVal * 1.15,
                    barGroups: List.generate(12, (i) => BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(toY: monthlyIncome[i], color: AppColors.income, width: 6),
                        BarChartRodData(toY: monthlyExpense[i], color: AppColors.expense, width: 6),
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
        ...List.generate(12, (i) {
          final inc = monthlyIncome[i]; final exp = monthlyExpense[i];
          if (inc == 0 && exp == 0) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                Expanded(child: Text(monthNamesTa[i])),
                Text(fmt(inc), style: const TextStyle(color: AppColors.income)),
                const SizedBox(width: 10),
                Text(fmt(exp), style: const TextStyle(color: AppColors.expense)),
              ],
            ),
          );
        }),
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
