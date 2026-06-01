class AppEnv {
  static const supabaseUrlFromDefine = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonFromDefine = String.fromEnvironment('SUPABASE_ANON_KEY');

  // Fallback público de cliente. La anon key de Supabase está pensada para usarse
  // en apps cliente siempre que RLS esté activado. Nunca usar service_role aquí.
  static const embeddedSupabaseUrl = 'https://izusbttdgtwbnuyzjrpw.supabase.co';
  static const embeddedSupabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml6dXNidHRkZ3R3Ym51eXpqcnB3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODAwNjI2MDAsImV4cCI6MjA5NTYzODYwMH0.S6GqpaZuPpQsM4ZPbvMC4nzbFVtT-r47fPdT59PdDxU';

  static Future<void> load() async {
    // Flutter Web no lee variables de Vercel en runtime.
    // Las lee si entran por --dart-define durante build.
    // Si no entran, usa el fallback público de arriba.
  }

  static String get supabaseUrl {
    final defined = supabaseUrlFromDefine.trim();
    if (defined.isNotEmpty) return defined;
    return embeddedSupabaseUrl.trim();
  }

  static String get supabaseAnonKey {
    final defined = supabaseAnonFromDefine.trim();
    if (defined.isNotEmpty) return defined;
    return embeddedSupabaseAnonKey.trim();
  }

  static bool get hasSupabase {
    final url = supabaseUrl;
    final key = supabaseAnonKey;
    return url.startsWith('https://') && url.contains('.supabase.co') && key.length > 20;
  }
}
