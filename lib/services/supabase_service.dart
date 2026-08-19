import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants.dart';

/// Reuses the existing Supabase backend used by the web app:
/// - profiles(user_id, email, status, is_admin, created_at)
/// - user_data(user_id, payload jsonb, updated_at)
class SupabaseService {
  static final SupabaseService instance = SupabaseService._internal();
  SupabaseService._internal();

  SupabaseClient get client => Supabase.instance.client;

  static Future<void> init() async {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
  }

  User? get currentUser => client.auth.currentUser;
  bool get isLoggedIn => currentUser != null;

  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  Future<AuthResponse> signUp(String email, String password) {
    return client.auth.signUp(email: email, password: password);
  }

  Future<AuthResponse> signIn(String email, String password) {
    return client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() => client.auth.signOut();

  /// Returns 'none' | 'pending' | 'approved' | 'rejected' | 'error'
  Future<String> checkProfileStatus() async {
    final user = currentUser;
    if (user == null) return 'none';
    try {
      final row = await client
          .from('profiles')
          .select('status,is_admin')
          .eq('user_id', user.id)
          .maybeSingle();
      if (row == null) return 'pending';
      return row['status'] as String? ?? 'pending';
    } catch (_) {
      return 'error';
    }
  }

  Future<Map<String, dynamic>?> fetchUserData() async {
    final user = currentUser;
    if (user == null) return null;
    final row = await client
        .from('user_data')
        .select('*')
        .eq('user_id', user.id)
        .maybeSingle();
    if (row == null) return null;
    return row['payload'] as Map<String, dynamic>?;
  }

  Future<void> upsertUserData(Map<String, dynamic> payload) async {
    final user = currentUser;
    if (user == null) return;
    await client.from('user_data').upsert({
      'user_id': user.id,
      'payload': payload,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
}
