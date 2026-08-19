import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../providers/app_providers.dart';
import '../services/prefs_service.dart';

class SetupWizardScreen extends ConsumerStatefulWidget {
  final VoidCallback onDone;
  const SetupWizardScreen({super.key, required this.onDone});
  @override
  ConsumerState<SetupWizardScreen> createState() => _SetupWizardScreenState();
}

class _SetupWizardScreenState extends ConsumerState<SetupWizardScreen> {
  int step = 0;
  final userNameCtrl = TextEditingController();
  final accountNameCtrl = TextEditingController();
  final obCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: List.generate(3, (i) => Expanded(
                  child: Container(
                    height: 4, margin: const EdgeInsets.symmetric(horizontal: 3),
                    color: i <= step ? AppColors.gold : AppColors.border,
                  ),
                )),
              ),
              const SizedBox(height: 30),
              Expanded(child: _buildStep()),
              Row(
                children: [
                  if (step > 0)
                    Expanded(child: OutlinedButton(onPressed: () => setState(() => step--), child: const Text('← பின்'))),
                  if (step > 0) const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: step == 2 ? _finish : () => setState(() => step++),
                      child: Text(step == 2 ? '✅ App திறக்கு' : 'அடுத்தது →'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (step) {
      case 0:
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🪙', style: TextStyle(fontSize: 60)),
              SizedBox(height: 16),
              Text('கணக்கு தாள்-க்கு வரவேற்கிறோம்!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.gold)),
              SizedBox(height: 8),
              Text('உங்கள் வருமானம் மற்றும் செலவுகளை எளிதாக நிர்வகிக்கவும்',
                  textAlign: TextAlign.center, style: TextStyle(color: AppColors.text2)),
            ],
          ),
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('உங்களை பற்றி', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(controller: userNameCtrl, decoration: const InputDecoration(labelText: 'உங்கள் பெயர்')),
            const SizedBox(height: 14),
            TextField(controller: accountNameCtrl, decoration: const InputDecoration(labelText: 'கணக்கு பெயர் / ஊர்')),
          ],
        );
      default:
        final ob = double.tryParse(obCtrl.text) ?? 0;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('தொடக்க இருப்பு', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              controller: obCtrl, keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'தொடக்க இருப்பு (Optional)', prefixText: '₹ '),
              onChanged: (_) => setState(() {}),
            ),
            if (ob > 0) Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text('₹${ob.toStringAsFixed(0)} வருமானமாக சேர்க்கப்படும்', style: const TextStyle(color: AppColors.income)),
            ),
          ],
        );
    }
  }

  Future<void> _finish() async {
    await ref.read(settingsProvider.notifier).save(userNameCtrl.text.trim(), accountNameCtrl.text.trim());
    final ob = double.tryParse(obCtrl.text.trim()) ?? 0;
    if (ob > 0) {
      await ref.read(entriesProvider.notifier).add(
        date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        type: 'income', amount: ob,
        desc: 'தொடக்க இருப்பு (Opening Balance)', category: 'other_income',
      );
    }
    await PrefsService.instance.setSetupDone();
    widget.onDone();
  }
}
