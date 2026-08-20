import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
        if (maxVal == 0)
          Container(
            height: 220,
            alignment: Alignment.center,
            decoration: glassCard(radius: 18),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('📈', style: TextStyle(fontSize: 44)),
              const SizedBox(height: 10),
              Text('இந்த வருடம் தரவு இல்லை', style: AppText.body.copyWith(color: AppColors.text2)),
            ]),
          )
        else
          Container(
            padding: const EdgeInsets.fromLTRB(10, 20, 10, 10),
            decoration: glassCard(radius: 18),
            child: _CustomBarChart(
              income: monthlyIncome, expense: monthlyExpense, maxVal: maxVal,
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

/// Hand-built bar chart using plain Flutter widgets (no charting package).
/// Avoids fl_chart's opaque default plot-area background that didn't
/// respect the app's dark theme. Uses the exact same monthlyIncome/
/// monthlyExpense arrays already computed above — no calculation change.
class _CustomBarChart extends StatelessWidget {
  final List<double> income, expense;
  final double maxVal;
  const _CustomBarChart({required this.income, required this.expense, required this.maxVal});

  static const _chartHeight = 190.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _chartHeight + 26,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(12, (i) {
          final incH = maxVal == 0 ? 0.0 : (income[i] / maxVal) * _chartHeight;
          final expH = maxVal == 0 ? 0.0 : (expense[i] / maxVal) * _chartHeight;
          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  height: _chartHeight,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _bar(incH, AppColors.income),
                      const SizedBox(width: 3),
                      _bar(expH, AppColors.expense),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(monthNamesTa[i].substring(0, 3), style: const TextStyle(fontSize: 9, color: AppColors.muted)),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _bar(double height, Color color) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: height),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Container(
        width: 7,
        height: v.clamp(v == 0 ? 0 : 3, double.infinity),
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
        ),
      ),
    );
  }
}
