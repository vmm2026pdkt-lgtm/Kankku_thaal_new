import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../services/supabase_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isLogin = true;
  bool loading = false;
  String? error;
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  Future<void> _submit() async {
    final email = emailCtrl.text.trim();
    final password = passCtrl.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => error = 'Email மற்றும் Password தேவை');
      return;
    }
    if (password.length < 6) {
      setState(() => error = 'Password குறைந்தது 6 எழுத்துகள் வேண்டும்');
      return;
    }
    setState(() { loading = true; error = null; });
    try {
      final sb = SupabaseService.instance;
      if (isLogin) {
        await sb.signIn(email, password);
        if (mounted) Navigator.pop(context);
      } else {
        final res = await sb.signUp(email, password);
        if (res.session == null) {
          setState(() {
            error = null;
            isLogin = true;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('✅ பதிவு முடிந்தது! Email-ஐ சரிபார்த்து confirm பண்ணிட்டு login பண்ணுங்க.'),
            ));
          }
        } else if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _contactWhatsApp() {
    final msg = Uri.encodeComponent('வணக்கம்! கணக்கு தாள் app-ல் Cloud Storage Subscription வேணும். தயவுசெய்து விவரம் தெரிவிக்கவும்.');
    launchUrl(Uri.parse('https://wa.me/$whatsappNumber?text=$msg'), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('☁️ Cloud Login')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('🔐 உள்நுழை'),
                    selected: isLogin,
                    onSelected: (_) => setState(() => isLogin = true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('✅ பதிவு செய்'),
                    selected: !isLogin,
                    onSelected: (_) => setState(() => isLogin = false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 12),
            TextField(controller: passCtrl, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
            if (error != null) Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(error!, style: const TextStyle(color: AppColors.expense)),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: loading ? null : _submit,
              child: loading
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(isLogin ? '🔐 உள்நுழை' : '✅ பதிவு செய்'),
            ),
            const SizedBox(height: 24),
            const Text('Cloud sync ஒரு paid feature. Payment/approval-க்கு WhatsApp தொடர்பு கொள்ளுங்கள்.',
                style: TextStyle(color: AppColors.muted, fontSize: 12.5)),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _contactWhatsApp,
              icon: const Icon(Icons.chat),
              label: const Text('WhatsApp தொடர்பு'),
            ),
          ],
        ),
      ),
    );
  }
}
