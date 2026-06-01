import 'package:supabase_flutter/supabase_flutter.dart';
import 'env.dart';
import 'errors.dart';

class SupabaseService {
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized || !AppEnv.hasSupabase) return;
    await Supabase.initialize(
      url: AppEnv.supabaseUrl,
      anonKey: AppEnv.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
    _initialized = true;
  }

  static bool get isReady => _initialized && AppEnv.hasSupabase;

  static SupabaseClient get client {
    if (!isReady) {
      throw const AppFailure('Supabase no está configurado. Crea .env o añade variables en Vercel.');
    }
    return Supabase.instance.client;
  }

  static User? get currentUser {
    if (!isReady) return null;
    return Supabase.instance.client.auth.currentUser;
  }
}
