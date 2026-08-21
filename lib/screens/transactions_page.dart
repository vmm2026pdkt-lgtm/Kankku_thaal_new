import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/app_providers.dart';
import '../widgets/entry_form_sheet.dart';

class TransactionsPage extends ConsumerStatefulWidget {
  const TransactionsPage({super.key});
  @override
  ConsumerState<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends ConsumerState<TransactionsPage> {
  String typeFilter = 'all';
  String search = '';

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(entriesProvider);
    final catsById = {for (var c in ref.watch(categoriesProvider)) c.id: c};

    // Same filter/search logic as before — only presentation changed below.
    var filtered = entries.where((e) {
      if (typeFilter != 'all' && e.type != typeFilter) return false;
      if (search.isNotEmpty && !e.desc.toLowerCase().contains(search.toLowerCase())) return false;
      return true;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    // Group by date for cleaner scanning (display-only grouping, no data change).
    final grouped = <String, List<Entry>>{};
    for (final e in filtered) {
      grouped.putIfAbsent(e.date, () => []).add(e);
    }
    final dateKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: TextField(
            decoration: const InputDecoration(
              hintText: '🔍 பரிவர்த்தனையைத் தேடுங்கள்',
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            onChanged: (v) => setState(() => search = v),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              _filterChip('அனைத்தும்', 'all'),
              const SizedBox(width: 8),
              _filterChip('வரவு', 'income'),
              const SizedBox(width: 8),
              _filterChip('செலவு', 'expense'),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: filtered.isEmpty
              ? _emptyState()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 120),
                  itemCount: dateKeys.length,
                  itemBuilder: (context, gi) {
                    final dateKey = dateKeys[gi];
                    final dayEntries = grouped[dateKey]!;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(4, gi == 0 ? 0 : 14, 4, 8),
                          child: Text(_formatDateHeader(dateKey), style: AppText.label),
                        ),
                        ...dayEntries.map((e) => _TxTile(
                              entry: e,
                              icon: catsById[e.category]?.icon ?? '📌',
                              categoryName: catsById[e.category]?.name ?? e.category,
                              onTap: () => showEntryFormSheet(context, ref, existing: e),
                              onDeleteConfirm: () => _confirmDelete(context),
                              onDeleted: () => ref.read(entriesProvider.notifier).remove(e.id),
                            )),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }

  String _formatDateHeader(String isoDate) {
    final d = DateTime.parse(isoDate);
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    if (d.year == today.year && d.month == today.month && d.day == today.day) return 'இன்று';
    if (d.year == yesterday.year && d.month == yesterday.month && d.day == yesterday.day) return 'நேற்று';
    return DateFormat('dd MMMM yyyy').format(d);
  }

  Widget _filterChip(String label, String value) {
    return ChoiceChip(
      label: Text(label),
      selected: typeFilter == value,
      onSelected: (_) => setState(() => typeFilter = value),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🧾', style: TextStyle(fontSize: 44)),
          const SizedBox(height: 10),
          Text('பரிவர்த்தனைகள் இல்லை', style: AppText.body.copyWith(color: AppColors.text2)),
        ],
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('நீக்க வேண்டுமா?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ரத்து')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('நீக்கு', style: TextStyle(color: AppColors.expense))),
        ],
      ),
    );
    return result ?? false;
  }
}

class _TxTile extends StatelessWidget {
  final Entry entry;
  final String icon, categoryName;
  final VoidCallback onTap, onDeleted;
  final Future<bool> Function() onDeleteConfirm;
  const _TxTile({
    required this.entry, required this.icon, required this.categoryName,
    required this.onTap, required this.onDeleteConfirm, required this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = entry.type == 'income';
    final color = isIncome ? AppColors.income : AppColors.expense;
    String fmt(double n) => '₹${NumberFormat('#,##0').format(n)}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: ValueKey(entry.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(color: AppColors.expense, borderRadius: BorderRadius.circular(18)),
          child: const Icon(Icons.delete_outline, color: Colors.white),
        ),
        confirmDismiss: (_) => onDeleteConfirm(),
        onDismissed: (_) => onDeleted(),
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
                    width: 42, height: 42,
                    decoration: BoxDecoration(color: color.withOpacity(0.14), borderRadius: BorderRadius.circular(13)),
                    child: Center(child: Text(icon, style: const TextStyle(fontSize: 18))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entry.desc, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(categoryName, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${isIncome ? '+' : '-'}${fmt(entry.amount)}',
                      style: AppText.amount.copyWith(color: color, fontSize: 14.5)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
