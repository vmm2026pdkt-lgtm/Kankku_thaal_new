import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../widgets/entry_form_sheet.dart';
import 'category_page.dart';
import 'home_page.dart';
import 'monthly_page.dart';
import 'settings_page.dart';
import 'transactions_page.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});
  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int index = 0;
  bool fabOpen = false;

  List<Widget> get pages => [
        HomePage(onSeeAllTransactions: () => setState(() { index = 1; fabOpen = false; })),
        const TransactionsPage(),
        const CategoryPage(),
        const MonthlyPage(),
        const SettingsPage(),
      ];

  final titles = const ['🪙 கணக்கு தாள்', 'பரிவர்த்தனைகள்', 'வகை வாரியாக', 'மாதாந்திரம்', 'அமைப்புகள்'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: Text(titles[index]),
        actions: index == 0
            ? [
                const Padding(
                  padding: EdgeInsets.only(right: 14),
                  child: Icon(Icons.notifications_none_rounded, color: AppColors.text2),
                ),
              ]
            : null,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero).animate(anim),
            child: child,
          ),
        ),
        child: KeyedSubtree(key: ValueKey(index), child: pages[index]),
      ),
      floatingActionButton: index != 4
          ? Padding(padding: const EdgeInsets.only(bottom: 78), child: _buildFab())
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: SafeArea(
        top: false,
        child: _GlassBottomNav(
          index: index,
          onTap: (i) => setState(() { index = i; fabOpen = false; }),
        ),
      ),
    );
  }

  Widget _buildFab() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSlide(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          offset: fabOpen ? Offset.zero : const Offset(0, 0.4),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 160),
            opacity: fabOpen ? 1 : 0,
            child: IgnorePointer(
              ignoring: !fabOpen,
              child: Column(
                children: [
                  _miniFab('⬆ வருமானம்', AppColors.income, () => _openEntry('income')),
                  const SizedBox(height: 10),
                  _miniFab('⬇ செலவு', AppColors.expense, () => _openEntry('expense')),
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ),
        ),
        FloatingActionButton(
          heroTag: 'main-fab',
          backgroundColor: AppColors.gold,
          onPressed: () => setState(() => fabOpen = !fabOpen),
          child: AnimatedRotation(
            duration: const Duration(milliseconds: 200),
            turns: fabOpen ? 0.125 : 0,
            child: const Icon(Icons.add, color: Colors.black, size: 28),
          ),
        ),
      ],
    );
  }

  Widget _miniFab(String label, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Text(label, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 13)),
        ),
      ),
    );
  }

  void _openEntry(String type) {
    setState(() => fabOpen = false);
    showEntryFormSheet(context, ref, defaultType: type);
  }
}

class _GlassBottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const _GlassBottomNav({required this.index, required this.onTap});

  static const _items = [
    (Icons.home_rounded, 'முகப்பு'),
    (Icons.receipt_long_rounded, 'பரிவர்த்தனை'),
    (Icons.pie_chart_rounded, 'வகை'),
    (Icons.bar_chart_rounded, 'மாதம்'),
    (Icons.settings_rounded, 'அமைப்பு'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.96),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_items.length, (i) {
          final selected = i == index;
          final (icon, label) = _items[i];
          return InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => onTap(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(horizontal: selected ? 16 : 10, vertical: 9),
              decoration: BoxDecoration(
                color: selected ? AppColors.gold.withOpacity(0.16) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 22, color: selected ? AppColors.gold : AppColors.muted),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    child: selected
                        ? Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: Text(label, style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700, fontSize: 12.5)),
                          )
                        : const SizedBox(width: 0),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
