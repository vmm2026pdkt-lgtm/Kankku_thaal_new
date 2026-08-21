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
            mainAxisSize: MainAxisSize.min,
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

/// Hand-built bar chart using a single CustomPainter (one canvas draw call,
/// no nested Row/Column/Container layers) — avoids any possible
/// compositing/layout edge case from a deeply nested widget tree.
/// Uses the exact same monthlyIncome/monthlyExpense arrays already
/// computed above — no calculation change.
class _CustomBarChart extends StatelessWidget {
  final List<double> income, expense;
  final double maxVal;
  const _CustomBarChart({required this.income, required this.expense, required this.maxVal});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 216,
      width: double.infinity,
      child: CustomPaint(
        painter: _BarChartPainter(income: income, expense: expense, maxVal: maxVal),
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<double> income, expense;
  final double maxVal;
  _BarChartPainter({required this.income, required this.expense, required this.maxVal});

  @override
  void paint(Canvas canvas, Size size) {
    const chartHeight = 190.0;
    final slotWidth = size.width / 12;
    final incomePaint = Paint()..color = AppColors.income;
    final expensePaint = Paint()..color = AppColors.expense;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i < 12; i++) {
      final slotCenter = slotWidth * i + slotWidth / 2;
      final safeMax = maxVal <= 0 ? 1.0 : maxVal;
      final incH = ((income[i] / safeMax) * chartHeight).clamp(0.0, chartHeight);
      final expH = ((expense[i] / safeMax) * chartHeight).clamp(0.0, chartHeight);
      final barW = (slotWidth * 0.22).clamp(4.0, 10.0);

      final incRect = RRect.fromRectAndCorners(
        Rect.fromLTWH(slotCenter - barW - 2, chartHeight - incH, barW, incH == 0 ? 2 : incH),
        topLeft: const Radius.circular(3), topRight: const Radius.circular(3),
      );
      canvas.drawRRect(incRect, incomePaint);

      final expRect = RRect.fromRectAndCorners(
        Rect.fromLTWH(slotCenter + 2, chartHeight - expH, barW, expH == 0 ? 2 : expH),
        topLeft: const Radius.circular(3), topRight: const Radius.circular(3),
      );
      canvas.drawRRect(expRect, expensePaint);

      textPainter.text = TextSpan(
        text: monthNamesTa[i].substring(0, monthNamesTa[i].length < 3 ? monthNamesTa[i].length : 3),
        style: const TextStyle(fontSize: 9, color: AppColors.muted),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(slotCenter - textPainter.width / 2, chartHeight + 8));
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) =>
      oldDelegate.income != income || oldDelegate.expense != expense || oldDelegate.maxVal != maxVal;
}
