import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase_client.dart';

class UserSettings {
  final bool notifyEvents;
  final bool notifyExpenses;
  final bool notifyTournaments;
  final String theme;

  const UserSettings({
    this.notifyEvents = true,
    this.notifyExpenses = true,
    this.notifyTournaments = true,
    this.theme = 'light',
  });

  UserSettings copyWith({
    bool? notifyEvents,
    bool? notifyExpenses,
    bool? notifyTournaments,
    String? theme,
  }) {
    return UserSettings(
      notifyEvents: notifyEvents ?? this.notifyEvents,
      notifyExpenses: notifyExpenses ?? this.notifyExpenses,
      notifyTournaments: notifyTournaments ?? this.notifyTournaments,
      theme: theme ?? this.theme,
    );
  }

  Map<String, dynamic> toDb(String userId) {
    return {
      'user_id': userId,
      'notify_events': notifyEvents,
      'notify_expenses': notifyExpenses,
      'notify_tournaments': notifyTournaments,
      'theme': theme,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  factory UserSettings.fromDb(Map<String, dynamic>? row) {
    if (row == null) return const UserSettings();
    return UserSettings(
      notifyEvents: row['notify_events'] == true,
      notifyExpenses: row['notify_expenses'] == true,
      notifyTournaments: row['notify_tournaments'] == true,
      theme: (row['theme'] ?? 'light').toString(),
    );
  }
}

class SettingsRepository {
  SupabaseClient get _db => SupabaseService.client;
  String get _userId => _db.auth.currentUser!.id;

  Future<UserSettings> load() async {
    try {
      final row = await _db
          .from('user_settings')
          .select()
          .eq('user_id', _userId)
          .maybeSingle();

      if (row == null) {
        const defaults = UserSettings();
        await save(defaults);
        return defaults;
      }

      return UserSettings.fromDb(Map<String, dynamic>.from(row));
    } catch (_) {
      // Si el SQL de settings aún no se ha ejecutado, la app sigue funcionando con defaults.
      return const UserSettings();
    }
  }

  Future<void> save(UserSettings settings) async {
    await _db.from('user_settings').upsert(settings.toDb(_userId));
  }
}
