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

  final pages = const [
    HomePage(),
    TransactionsPage(),
    CategoryPage(),
    MonthlyPage(),
    SettingsPage(),
  ];

  final titles = const ['🪙 கணக்கு தாள்', 'பரிவர்த்தனைகள்', 'வகை வாரியாக', 'மாதாந்திரம்', 'அமைப்புகள்'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(titles[index])),
      body: IndexedStack(index: index, children: pages),
      floatingActionButton: index != 4
          ? Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton.small(
                  heroTag: 'inc', backgroundColor: AppColors.income,
                  onPressed: () => showEntryFormSheet(context, ref, defaultType: 'income'),
                  child: const Icon(Icons.arrow_upward, color: Colors.black),
                ),
                const SizedBox(width: 10),
                FloatingActionButton(
                  heroTag: 'exp', backgroundColor: AppColors.expense,
                  onPressed: () => showEntryFormSheet(context, ref, defaultType: 'expense'),
                  child: const Icon(Icons.arrow_downward, color: Colors.black),
                ),
              ],
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (i) => setState(() => index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'முகப்பு'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'பரிவர்த்தனை'),
          BottomNavigationBarItem(icon: Icon(Icons.pie_chart), label: 'வகை'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'மாதம்'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'அமைப்பு'),
        ],
      ),
    );
  }
}
