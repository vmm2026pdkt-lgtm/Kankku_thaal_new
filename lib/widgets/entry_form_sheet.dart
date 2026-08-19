import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/app_providers.dart';
import '../services/business_logic.dart';

Future<void> showEntryFormSheet(BuildContext context, WidgetRef ref, {Entry? existing, String? defaultType}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _EntryFormSheet(existing: existing, defaultType: defaultType),
  );
}

class _EntryFormSheet extends ConsumerStatefulWidget {
  final Entry? existing;
  final String? defaultType;
  const _EntryFormSheet({this.existing, this.defaultType});

  @override
  ConsumerState<_EntryFormSheet> createState() => _EntryFormSheetState();
}

class _EntryFormSheetState extends ConsumerState<_EntryFormSheet> {
  late String type;
  late DateTime date;
  final amountCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  String? category;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    type = e?.type ?? widget.defaultType ?? 'income';
    date = e != null ? DateTime.parse(e.date) : DateTime.now();
    amountCtrl.text = e != null ? e.amount.toString() : '';
    descCtrl.text = e?.desc ?? '';
    category = e?.category;
  }

  @override
  Widget build(BuildContext context) {
    final cats = type == 'income' ? ref.watch(incomeCategoriesProvider) : ref.watch(expenseCategoriesProvider);
    category ??= cats.isNotEmpty ? cats.first.id : null;
    if (category != null && !cats.any((c) => c.id == category)) {
      category = cats.isNotEmpty ? cats.first.id : null;
    }

    return Padding(
      padding: EdgeInsets.only(
        left: 18, right: 18, top: 18,
        bottom: MediaQuery.of(context).viewInsets.bottom + 18,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.existing != null ? 'உள்ளீடு திருத்து' : 'புதிய உள்ளீடு',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.gold)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Text('⬆ வருமானம்'),
                  selected: type == 'income',
                  onSelected: (_) => setState(() { type = 'income'; category = null; }),
                  selectedColor: AppColors.income,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ChoiceChip(
                  label: const Text('⬇ செலவு'),
                  selected: type == 'expense',
                  onSelected: (_) => setState(() { type = 'expense'; category = null; }),
                  selectedColor: AppColors.expense,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ListTile(
            tileColor: AppColors.surface2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: Text(DateFormat('dd/MM/yyyy').format(date)),
            trailing: const Icon(Icons.calendar_today, size: 18),
            onTap: () async {
              final picked = await showDatePicker(
                context: context, initialDate: date,
                firstDate: DateTime(2000), lastDate: DateTime(2100),
              );
              if (picked != null) setState(() => date = picked);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'தொகை', prefixText: '₹ '),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: descCtrl,
            decoration: const InputDecoration(labelText: 'விவரம்'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: category,
            decoration: const InputDecoration(labelText: 'வகை'),
            items: cats.map((c) => DropdownMenuItem(value: c.id, child: Text('${c.icon} ${c.name}'))).toList(),
            onChanged: (v) => setState(() => category = v),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('ரத்து'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: _save,
                  child: const Text('சேமி'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _save() async {
    final amount = double.tryParse(amountCtrl.text.trim());
    final desc = descCtrl.text.trim();
    if (amount == null || amount <= 0 || desc.isEmpty || category == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('தேதி, தொகை மற்றும் விவரம் அவசியம்!'), backgroundColor: AppColors.expense),
      );
      return;
    }
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final entriesNotifier = ref.read(entriesProvider.notifier);

    if (widget.existing != null) {
      await entriesNotifier.update(widget.existing!.copyWith(
        date: dateStr, type: type, amount: amount, desc: desc, category: category,
      ));
    } else {
      await entriesNotifier.add(date: dateStr, type: type, amount: amount, desc: desc, category: category!);
    }

    if (type == 'expense' && mounted) {
      final entries = ref.read(entriesProvider);
      final budgets = ref.read(budgetsProvider);
      final catName = ref.read(expenseCategoriesProvider).firstWhere((c) => c.id == category).name;
      final msg = checkBudgetAlert(
        entries: entries, budgets: budgets, month: dateStr.substring(0, 7),
        category: category!, categoryName: catName,
        fmt: (n) => '₹${n.toStringAsFixed(0)}',
      );
      if (msg != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.expense),
        );
      }
    }

    if (mounted) Navigator.pop(context);
  }
}
