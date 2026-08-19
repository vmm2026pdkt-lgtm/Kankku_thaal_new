import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../services/prefs_service.dart';

class PinLockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;
  const PinLockScreen({super.key, required this.onUnlocked});
  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  String buffer = '';
  String? error;

  void _press(String digit) {
    if (buffer.length >= 4) return;
    setState(() => buffer += digit);
    if (buffer.length == 4) {
      Future.delayed(const Duration(milliseconds: 150), _verify);
    }
  }

  void _backspace() => setState(() => buffer = buffer.isEmpty ? '' : buffer.substring(0, buffer.length - 1));

  Future<void> _verify() async {
    final saved = await PrefsService.instance.getPin();
    if (buffer == saved) {
      widget.onUnlocked();
    } else {
      setState(() { error = '❌ தவறான PIN'; });
      await Future.delayed(const Duration(milliseconds: 800));
      setState(() { buffer = ''; error = null; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🔒', style: TextStyle(fontSize: 50)),
              const SizedBox(height: 10),
              const Text('PIN உள்ளிடவும்', style: TextStyle(fontSize: 18, color: AppColors.text2)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  width: 16, height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < buffer.length ? AppColors.gold : AppColors.surface2,
                    border: Border.all(color: AppColors.border),
                  ),
                )),
              ),
              const SizedBox(height: 10),
              SizedBox(height: 20, child: Text(error ?? '', style: const TextStyle(color: AppColors.expense))),
              const SizedBox(height: 20),
              SizedBox(
                width: 260,
                child: GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 3,
                  children: [
                    for (var n in ['1','2','3','4','5','6','7','8','9'])
                      _padBtn(n, () => _press(n)),
                    const SizedBox(),
                    _padBtn('0', () => _press('0')),
                    _padBtn('⌫', _backspace),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _padBtn(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Material(
        color: AppColors.surface2,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Center(child: Text(label, style: const TextStyle(fontSize: 20, color: AppColors.text))),
        ),
      ),
    );
  }
}
