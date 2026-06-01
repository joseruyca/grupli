import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase_client.dart';

class AuthService {
  SupabaseClient get _db => SupabaseService.client;

  User? get currentUser => SupabaseService.currentUser;

  Future<void> signIn(String email, String password) async {
    await _db.auth.signInWithPassword(email: email.trim(), password: password);
  }

  Future<void> signUp({required String name, required String email, required String password}) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanName = name.trim();

    final response = await _db.auth.signUp(
      email: cleanEmail,
      password: password,
      data: {'full_name': cleanName, 'name': cleanName},
      emailRedirectTo: 'https://grupli.vercel.app/login',
    );

    final user = response.user;
    if (user == null) return;

    // El trigger handle_new_user() crea el perfil automáticamente.
    // Este upsert solo corrige/asegura nombre y email cuando la sesión ya está activa
    // (por ejemplo, con Confirm email desactivado durante desarrollo).
    if (_db.auth.currentSession != null) {
      await _db.from('profiles').upsert({
        'id': user.id,
        'email': cleanEmail,
        'full_name': cleanName,
        'updated_at': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> sendRecovery(String email) async {
    await _db.auth.resetPasswordForEmail(
      email.trim().toLowerCase(),
      redirectTo: 'https://grupli.vercel.app/reset-password',
    );
  }

  Future<void> updatePassword(String password) async {
    await _db.auth.updateUser(UserAttributes(password: password));
  }

  Future<void> signOut() => _db.auth.signOut();
}
