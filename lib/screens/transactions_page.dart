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
    String fmt(double n) => '₹${NumberFormat('#,##0').format(n)}';

    var filtered = entries.where((e) {
      if (typeFilter != 'all' && e.type != typeFilter) return false;
      if (search.isNotEmpty && !e.desc.toLowerCase().contains(search.toLowerCase())) return false;
      return true;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
          child: TextField(
            decoration: const InputDecoration(hintText: '🔍 தேடு...', isDense: true),
            onChanged: (v) => setState(() => search = v),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              _filterChip('அனைத்தும்', 'all'),
              const SizedBox(width: 8),
              _filterChip('வருமானம்', 'income'),
              const SizedBox(width: 8),
              _filterChip('செலவு', 'expense'),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('உள்ளீடுகள் இல்லை', style: TextStyle(color: AppColors.muted)))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 100),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final e = filtered[i];
                    final cat = catsById[e.category];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Dismissible(
                        key: ValueKey(e.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(color: AppColors.expense, borderRadius: BorderRadius.circular(14)),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (_) => _confirmDelete(context),
                        onDismissed: (_) => ref.read(entriesProvider.notifier).remove(e.id),
                        child: ListTile(
                          tileColor: AppColors.surface,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.border)),
                          leading: CircleAvatar(backgroundColor: AppColors.surface2, child: Text(cat?.icon ?? '📌')),
                          title: Text(e.desc, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text('${cat?.name ?? e.category} • ${DateFormat('dd/MM/yyyy').format(DateTime.parse(e.date))}'),
                          trailing: Text(
                            '${e.type == 'income' ? '+' : '-'}${fmt(e.amount)}',
                            style: TextStyle(color: e.type == 'income' ? AppColors.income : AppColors.expense, fontWeight: FontWeight.bold),
                          ),
                          onTap: () => showEntryFormSheet(context, ref, existing: e),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _filterChip(String label, String value) {
    return ChoiceChip(
      label: Text(label),
      selected: typeFilter == value,
      onSelected: (_) => setState(() => typeFilter = value),
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
