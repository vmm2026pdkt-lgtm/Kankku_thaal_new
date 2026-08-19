import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme.dart';
import 'screens/app_gate.dart';
import 'services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.init();
  runApp(const ProviderScope(child: KanakkuApp()));
}

class KanakkuApp extends StatelessWidget {
  const KanakkuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'கணக்கு தாள்',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const AppGate(),
    );
  }
}
