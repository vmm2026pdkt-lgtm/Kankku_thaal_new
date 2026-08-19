import '../models/models.dart';

/// Returns the list of recurring rules that are "due" (i.e. haven't
/// generated an entry for the current period yet) along with the
/// entry that should be auto-created for each.
class RecurringDue {
  final RecurringRule rule;
  final Entry entry;
  RecurringDue(this.rule, this.entry);
}

List<RecurringDue> computeDueRecurring(List<RecurringRule> rules, String todayIso, String Function() genId) {
  final due = <RecurringDue>[];
  final today = DateTime.parse(todayIso);
  for (final r in rules) {
    final last = DateTime.tryParse(r.lastRun);
    bool isDue;
    if (last == null) {
      isDue = true;
    } else if (r.frequency == 'weekly') {
      isDue = today.difference(last).inDays >= 7;
    } else {
      // monthly: due if month changed
      isDue = last.year != today.year || last.month != today.month;
    }
    if (isDue) {
      due.add(RecurringDue(
        r,
        Entry(
          id: genId(),
          date: todayIso,
          type: r.type,
          amount: r.amount,
          desc: '${r.desc} (தானியங்கி)',
          category: r.category,
          createdAt: DateTime.now().toIso8601String(),
        ),
      ));
    }
  }
  return due;
}

/// Returns a Tamil warning message if the given month/category spend
/// crosses the configured budget, or null if within budget.
String? checkBudgetAlert({
  required List<Entry> entries,
  required Budgets budgets,
  required String month, // yyyy-MM
  required String category,
  required String categoryName,
  required String Function(double) fmt,
}) {
  final monthExpenses = entries.where((e) => e.type == 'expense' && e.date.startsWith(month)).toList();
  final monthTotal = monthExpenses.fold(0.0, (s, e) => s + e.amount);
  final catBudget = budgets.categories[category] ?? 0;
  final catTotal = monthExpenses.where((e) => e.category == category).fold(0.0, (s, e) => s + e.amount);

  if (catBudget > 0 && catTotal > catBudget) {
    return '⚠️ $categoryName பட்ஜெட் தாண்டிவிட்டது! (${fmt(catTotal)} / ${fmt(catBudget)})';
  }
  if (budgets.overall > 0 && monthTotal > budgets.overall) {
    return '⚠️ மாத பட்ஜெட் தாண்டிவிட்டது! (${fmt(monthTotal)} / ${fmt(budgets.overall)})';
  }
  return null;
}
