import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  ErrorWidget.builder = (details) {
    return Material(
      color: Colors.white,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Text(
              'Error visible en Grupli:\n\n${details.exceptionAsString()}',
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ),
    );
  };

  Intl.defaultLocale = 'es_ES';
  await initializeDateFormatting('es_ES');

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(authFlowType: AuthFlowType.pkce),
  );

  runApp(const GrupliApp());
}

class AppConfig {
  static const supabaseUrlDefine = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonDefine = String.fromEnvironment('SUPABASE_ANON_KEY');

  static const fallbackSupabaseUrl = 'https://izusbttdgtwbnuyzjrpw.supabase.co';
  static const fallbackSupabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml6dXNidHRkZ3R3Ym51eXpqcnB3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODAwNjI2MDAsImV4cCI6MjA5NTYzODYwMH0.S6GqpaZuPpQsM4ZPbvMC4nzbFVtT-r47fPdT59PdDxU';

  static String get supabaseUrl => supabaseUrlDefine.trim().isNotEmpty ? supabaseUrlDefine.trim() : fallbackSupabaseUrl;
  static String get supabaseAnonKey => supabaseAnonDefine.trim().isNotEmpty ? supabaseAnonDefine.trim() : fallbackSupabaseAnonKey;
}

class AppColors {
  static const bgShell = Color(0xFFEEF3F8);
  static const white = Color(0xFFFFFFFF);
  static const ink = Color(0xFF10172F);
  static const muted = Color(0xFF667085);
  static const faint = Color(0xFFF7F9FC);
  static const surface = Color(0xFFF9FBFD);
  static const line = Color(0xFFE4E9F1);
  static const teal = Color(0xFF008F86);
  static const tealDark = Color(0xFF006B69);
  static const tealSoft = Color(0xFFE7F8F6);
  static const blue = Color(0xFF3767FF);
  static const violet = Color(0xFF6E56E8);
  static const violetSoft = Color(0xFFF0EEFF);
  static const orange = Color(0xFFF28B20);
  static const orangeSoft = Color(0xFFFFF2E1);
  static const green = Color(0xFF0C9D61);
  static const greenSoft = Color(0xFFE9F8F0);
  static const red = Color(0xFFE24A4A);
  static const redSoft = Color(0xFFFFEEEE);
  static const amber = Color(0xFFE6A600);
}

class GrupliApp extends StatelessWidget {
  const GrupliApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Grupli',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.white,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.teal, surface: AppColors.white),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: AppColors.ink, height: 1.04, letterSpacing: -0.8),
          headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.ink, height: 1.08, letterSpacing: -0.45),
          titleLarge: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: AppColors.ink, letterSpacing: -0.25),
          titleMedium: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: AppColors.ink),
          bodyLarge: TextStyle(fontSize: 15, color: AppColors.ink, height: 1.35),
          bodyMedium: TextStyle(fontSize: 13.2, color: AppColors.muted, height: 1.35),
          labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          hintStyle: const TextStyle(color: Color(0xFF9AA4B5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.line)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.line)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.teal, width: 1.4)),
        ),
      ),
      locale: const Locale('es'),
      supportedLocales: const [Locale('es'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AppRoot(),
    );
  }
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  Session? _session;
  late final StreamSubscription<AuthState> _authSub;

  @override
  void initState() {
    super.initState();
    _session = Supabase.instance.client.auth.currentSession;
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      if (mounted) setState(() => _session = event.session);
    });
  }

  @override
  void dispose() {
    _authSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      child: _session == null ? const WelcomeScreen() : const AuthedShell(),
    );
  }
}

class AppSurface extends StatelessWidget {
  final Widget child;
  const AppSurface({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgShell,
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: Container(
          color: AppColors.white,
          child: child,
        ),
      ),
    );
  }
}

class DirectPage extends StatelessWidget {
  final Widget child;
  final Widget? bottomNavigationBar;
  final EdgeInsetsGeometry padding;
  final bool scroll;
  const DirectPage({super.key, required this.child, this.bottomNavigationBar, this.padding = const EdgeInsets.fromLTRB(22, 22, 22, 26), this.scroll = true});

  @override
  Widget build(BuildContext context) {
    Widget body = SafeArea(
      bottom: bottomNavigationBar == null,
      child: scroll
          ? ListView(
              padding: padding,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [child],
            )
          : Padding(padding: padding, child: child),
    );

    return Scaffold(
      backgroundColor: AppColors.white,
      body: body,
      bottomNavigationBar: bottomNavigationBar == null ? null : SafeArea(top: false, child: bottomNavigationBar!),
    );
  }
}

class AppData {
  static SupabaseClient get sb => Supabase.instance.client;
  static User? get user => sb.auth.currentUser;

  static List<Map<String, dynamic>> asList(dynamic value) {
    if (value is List) return value.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    return [];
  }

  static Map<String, dynamic> asMap(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  static String text(dynamic value, [String fallback = '']) {
    final s = value?.toString().trim() ?? '';
    return s.isEmpty ? fallback : s;
  }

  static int intValue(dynamic value, [int fallback = 0]) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static double doubleValue(dynamic value, [double fallback = 0]) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse((value?.toString() ?? '').replaceAll(',', '.')) ?? fallback;
  }

  static Future<void> ensureProfile() async {
    await sb.rpc('ensure_current_profile');
  }

  static Future<Map<String, dynamic>> profile() async {
    await ensureProfile();
    final uid = user?.id;
    if (uid == null) return <String, dynamic>{};
    final res = await sb.from('profiles').select().eq('id', uid).single();
    return asMap(res);
  }

  static Future<void> updateProfileName(String fullName) async {
    final uid = user?.id;
    if (uid == null) return;
    await ensureProfile();
    final clean = fullName.trim().isEmpty ? (user?.email?.split('@').first ?? 'Usuario') : fullName.trim();
    await sb.from('profiles').update({
      'full_name': clean,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', uid);
  }

  static Future<String> uploadAvatarBytes(Uint8List bytes, String filename) async {
    final uid = user?.id;
    if (uid == null) throw Exception('Inicia sesión para cambiar la foto.');
    await ensureProfile();
    final ext = filename.toLowerCase().endsWith('.png')
        ? 'png'
        : filename.toLowerCase().endsWith('.webp')
            ? 'webp'
            : 'jpg';
    final path = '$uid/avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';
    await sb.storage.from('avatars').uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(
        upsert: true,
        contentType: ext == 'png' ? 'image/png' : ext == 'webp' ? 'image/webp' : 'image/jpeg',
      ),
    );
    final publicUrl = sb.storage.from('avatars').getPublicUrl(path);
    final versionedUrl = '$publicUrl?v=${DateTime.now().millisecondsSinceEpoch}';
    await sb.from('profiles').update({
      'avatar_url': versionedUrl,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', uid);
    return versionedUrl;
  }

  static Future<void> removeAvatar() async {
    final uid = user?.id;
    if (uid == null) return;
    await ensureProfile();
    await sb.from('profiles').update({
      'avatar_url': null,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', uid);
  }

  static Future<List<Map<String, dynamic>>> myGroups() async {
    try {
      final res = await sb.rpc('get_my_groups');
      return asList(res);
    } catch (_) {
      final uid = user?.id;
      if (uid == null) return [];
      final res = await sb.from('group_members').select('role, groups(id,name,type,privacy,invite_code,created_at)').eq('user_id', uid);
      return asList(res).map((row) {
        final g = asMap(row['groups']);
        return {
          ...g,
          'role': row['role'],
          'members_count': 1,
          'events_count': 0,
          'balance': 0,
        };
      }).toList();
    }
  }

  static Future<String> createGroup(String name) async {
    final res = await sb.rpc('create_group_atomic', params: {'p_name': name.trim()});
    return res.toString();
  }

  static Future<String> joinGroup(String code) async {
    final res = await sb.rpc('join_group_with_code', params: {'code': code.trim().toUpperCase()});
    return res.toString();
  }

  static Future<Map<String, dynamic>> group(String groupId) async {
    final res = await sb.from('groups').select().eq('id', groupId).single();
    return asMap(res);
  }

  static Future<List<Map<String, dynamic>>> members(String groupId) async {
    final res = await sb.from('group_members').select('id, role, user_id, profiles(id,email,full_name,avatar_url)').eq('group_id', groupId).order('created_at');
    return asList(res);
  }

  static Future<void> updateMemberRole(String memberRowId, String role) async {
    if (!['admin', 'member'].contains(role)) {
      throw Exception('Rol no válido.');
    }
    await sb.from('group_members').update({'role': role}).eq('id', memberRowId);
  }

  static Future<void> removeMember(String memberRowId) async {
    await sb.from('group_members').delete().eq('id', memberRowId);
  }

  static Future<void> leaveGroup(String groupId) async {
    final uid = user?.id;
    if (uid == null) return;
    await sb.from('group_members').delete().eq('group_id', groupId).eq('user_id', uid);
  }

  static Future<List<Map<String, dynamic>>> events(String groupId) async {
    final res = await sb.from('events').select('*, event_attendance(status,user_id)').eq('group_id', groupId).neq('status', 'cancelled').order('starts_at');
    return asList(res);
  }

  static Future<String> createEvent(String groupId, String title, DateTime startsAt, String location, String notes, int minPeople) async {
    final row = await sb.from('events').insert({
      'group_id': groupId,
      'title': title.trim(),
      'starts_at': startsAt.toUtc().toIso8601String(),
      'location': location.trim().isEmpty ? null : location.trim(),
      'notes': notes.trim().isEmpty ? null : notes.trim(),
      'min_people': minPeople,
      'created_by': user?.id,
    }).select('id').single();
    return row['id'].toString();
  }

  static Future<Map<String, dynamic>> eventById(String eventId) async {
    final res = await sb.from('events').select('*, event_attendance(status,user_id)').eq('id', eventId).single();
    return asMap(res);
  }

  static Future<void> updateEvent(String eventId, String title, DateTime startsAt, String location, String notes, int minPeople) async {
    await sb.from('events').update({
      'title': title.trim(),
      'starts_at': startsAt.toUtc().toIso8601String(),
      'location': location.trim().isEmpty ? null : location.trim(),
      'notes': notes.trim().isEmpty ? null : notes.trim(),
      'min_people': minPeople,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', eventId);
  }

  static Future<void> cancelEvent(String eventId) async {
    await sb.from('events').update({
      'status': 'cancelled',
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', eventId);
  }

  static Future<void> setAttendance(String eventId, String status) async {
    final uid = user?.id;
    if (uid == null) return;
    await sb.from('event_attendance').upsert({
      'event_id': eventId,
      'user_id': uid,
      'status': status,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'event_id,user_id');
  }

  static Future<List<Map<String, dynamic>>> expenses(String groupId) async {
    final res = await sb.from('expenses').select('*, profiles!expenses_paid_by_fkey(id,email,full_name), expense_participants(user_id,share_amount,paid)').eq('group_id', groupId).order('created_at', ascending: false);
    return asList(res);
  }

  static Future<String> createExpense(String groupId, String concept, double amount, String paidBy, List<String> participantIds, String note) async {
    final participantSet = <String>{...participantIds, paidBy};
    final participants = participantSet.where((id) => id.trim().isNotEmpty).toList();
    final share = participants.isEmpty ? amount : amount / participants.length;
    return createExpenseWithShares(
      groupId,
      concept,
      amount,
      paidBy,
      {for (final id in participants) id: double.parse(share.toStringAsFixed(2))},
      note,
    );
  }

  static Future<String> createExpenseWithShares(String groupId, String concept, double amount, String paidBy, Map<String, double> shares, String note) async {
    final current = user?.id;
    final cleanShares = <String, double>{};
    shares.forEach((id, value) {
      if (id.trim().isEmpty) return;
      final cleanValue = double.parse(max(0, value).toStringAsFixed(2));
      if (cleanValue > 0 || id == paidBy) cleanShares[id] = cleanValue;
    });
    cleanShares.putIfAbsent(paidBy, () => 0);
    final expense = await sb.from('expenses').insert({
      'group_id': groupId,
      'concept': concept.trim(),
      'amount': double.parse(amount.toStringAsFixed(2)),
      'paid_by': paidBy,
      'created_by': current,
      'note': note.trim().isEmpty ? null : note.trim(),
      'status': 'pending',
    }).select('id').single();
    final expenseId = expense['id'].toString();
    final rows = cleanShares.entries.map((entry) => {
      'expense_id': expenseId,
      'user_id': entry.key,
      'share_amount': double.parse(entry.value.toStringAsFixed(2)),
      'paid': entry.key == paidBy,
    }).toList();
    if (rows.isNotEmpty) await sb.from('expense_participants').insert(rows);
    return expenseId;
  }

  static Future<void> setExpenseParticipantPaid(String expenseId, String userId, bool paid) async {
    await sb.from('expense_participants').update({'paid': paid}).eq('expense_id', expenseId).eq('user_id', userId);
    final rows = asList(await sb.from('expense_participants').select('paid').eq('expense_id', expenseId));
    final allPaid = rows.isNotEmpty && rows.every((row) => row['paid'] == true);
    await sb.from('expenses').update({
      'status': allPaid ? 'paid' : 'pending',
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', expenseId);
  }

  static Future<void> markExpenseSettled(String expenseId) async {
    await sb.from('expense_participants').update({'paid': true}).eq('expense_id', expenseId);
    await sb.from('expenses').update({'status': 'paid', 'updated_at': DateTime.now().toUtc().toIso8601String()}).eq('id', expenseId);
  }

  static Future<void> reopenExpense(String expenseId) async {
    final expense = await sb.from('expenses').select('paid_by').eq('id', expenseId).single();
    final paidBy = expense['paid_by']?.toString();
    await sb.from('expense_participants').update({'paid': false}).eq('expense_id', expenseId);
    if (paidBy != null && paidBy.isNotEmpty) {
      await sb.from('expense_participants').update({'paid': true}).eq('expense_id', expenseId).eq('user_id', paidBy);
    }
    await sb.from('expenses').update({'status': 'pending', 'updated_at': DateTime.now().toUtc().toIso8601String()}).eq('id', expenseId);
  }

  static Future<void> deleteExpense(String expenseId) async {
    await sb.from('expenses').delete().eq('id', expenseId);
  }

  static Future<List<Map<String, dynamic>>> tournaments(String groupId) async {
    final res = await sb
        .from('tournaments')
        .select('*, tournament_teams(id,name), matches(id,team_a,team_b,score_a,score_b,round,status,played_at)')
        .eq('group_id', groupId)
        .order('created_at', ascending: false);
    return asList(res);
  }

  static Future<Map<String, dynamic>> tournament(String tournamentId) async {
    final res = await sb
        .from('tournaments')
        .select('*, tournament_teams(id,name), matches(id,team_a,team_b,score_a,score_b,round,status,played_at,created_at)')
        .eq('id', tournamentId)
        .single();
    return asMap(res);
  }

  static Future<String> createTournament(
    String groupId,
    String name, {
    String format = 'liga',
    String teamType = 'equipo',
  }) async {
    final row = await sb.from('tournaments').insert({
      'group_id': groupId,
      'name': name.trim(),
      'format': format,
      'team_type': teamType,
      'created_by': user?.id,
    }).select('id').single();
    return row['id'].toString();
  }

  static Future<void> updateTournamentStatus(String tournamentId, String status) async {
    await sb.from('tournaments').update({'status': status, 'updated_at': DateTime.now().toUtc().toIso8601String()}).eq('id', tournamentId);
  }

  static Future<void> deleteTournament(String tournamentId) async {
    await sb.from('tournaments').delete().eq('id', tournamentId);
  }

  static Future<String> addTournamentTeam(String tournamentId, String name) async {
    final row = await sb.from('tournament_teams').insert({
      'tournament_id': tournamentId,
      'name': name.trim(),
    }).select('id').single();
    return row['id'].toString();
  }

  static Future<int> addTournamentTeams(String tournamentId, List<String> names) async {
    final clean = names.map((n) => n.trim()).where((n) => n.length >= 2).toSet().toList();
    if (clean.isEmpty) return 0;
    await sb.from('tournament_teams').insert(clean.map((name) => {
      'tournament_id': tournamentId,
      'name': name,
    }).toList());
    return clean.length;
  }

  static Future<void> deleteTournamentTeam(String teamId) async {
    await sb.from('tournament_teams').delete().eq('id', teamId);
  }

  static Future<void> clearTournamentMatches(String tournamentId) async {
    await sb.from('matches').delete().eq('tournament_id', tournamentId);
  }

  static Future<void> generateMatches(String tournamentId, String format, List<Map<String, dynamic>> teams) async {
    if (teams.length < 2) {
      throw Exception('Añade al menos 2 participantes.');
    }

    await clearTournamentMatches(tournamentId);

    final rows = <Map<String, dynamic>>[];
    if (format == 'eliminatoria') {
      if (teams.length < 2) throw Exception('Añade al menos 2 participantes.');
      if (!isPowerOfTwo(teams.length)) {
        throw Exception('Para una eliminatoria limpia usa 2, 4, 8 o 16 participantes. Así no hay rondas incompletas ni ganadores sueltos.');
      }
      for (var i = 0; i < teams.length; i += 2) {
        rows.add({
          'tournament_id': tournamentId,
          'team_a': teams[i]['id'],
          'team_b': teams[i + 1]['id'],
          'round': 1,
          'status': 'pending',
        });
      }
    } else {
      var round = 1;
      for (var i = 0; i < teams.length; i++) {
        for (var j = i + 1; j < teams.length; j++) {
          rows.add({
            'tournament_id': tournamentId,
            'team_a': teams[i]['id'],
            'team_b': teams[j]['id'],
            'round': round,
            'status': 'pending',
          });
          round++;
        }
      }
    }

    if (rows.isEmpty) throw Exception('No se han podido generar partidos.');
    await sb.from('matches').insert(rows);
  }

  static Future<void> generateNextEliminationRound(String tournamentId, List<Map<String, dynamic>> matches) async {
    final played = matches.where((m) => text(m['status']) == 'played').toList();
    final latestRound = matches.fold<int>(0, (maxRound, m) => max(maxRound, intValue(m['round'])));
    final latestMatches = played.where((m) => intValue(m['round']) == latestRound).toList();
    if (latestMatches.isEmpty) throw Exception('No hay resultados cerrados para generar la siguiente ronda.');
    if (latestMatches.length == 1) throw Exception('La eliminatoria ya tiene final registrada.');

    final winners = <String>[];
    for (final match in latestMatches) {
      final a = intValue(match['score_a']);
      final b = intValue(match['score_b']);
      if (a == b) throw Exception('No puede haber empates en eliminatoria.');
      winners.add((a > b ? match['team_a'] : match['team_b']).toString());
    }
    if (winners.length % 2 != 0) throw Exception('Número impar de ganadores. Revisa resultados.');
    final rows = <Map<String, dynamic>>[];
    for (var i = 0; i < winners.length; i += 2) {
      rows.add({
        'tournament_id': tournamentId,
        'team_a': winners[i],
        'team_b': winners[i + 1],
        'round': latestRound + 1,
        'status': 'pending',
      });
    }
    await sb.from('matches').insert(rows);
  }

  static Future<void> setMatchResult(String matchId, int scoreA, int scoreB) async {
    await sb.from('matches').update({
      'score_a': scoreA,
      'score_b': scoreB,
      'status': 'played',
      'played_at': DateTime.now().toUtc().toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', matchId);
  }

  static Future<void> reopenMatch(String matchId) async {
    await sb.from('matches').update({
      'score_a': null,
      'score_b': null,
      'status': 'pending',
      'played_at': null,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', matchId);
  }
}

String dateLabel(DateTime date) {
  return DateFormat('dd/MM · HH:mm', 'es_ES').format(date.toLocal());
}

String _cap(String value) {
  if (value.trim().isEmpty) return value;
  return value.substring(0, 1).toUpperCase() + value.substring(1);
}

String monthTitle(DateTime date) => _cap(DateFormat('MMMM yyyy', 'es_ES').format(date));
String longDay(DateTime date) => _cap(DateFormat('EEEE dd MMMM', 'es_ES').format(date));
String longDateTime(DateTime date) => _cap(DateFormat('EEEE dd MMMM · HH:mm', 'es_ES').format(date));
String shortWeekday(DateTime date) => _cap(DateFormat('EEE', 'es_ES').format(date).replaceAll('.', ''));

String money(double value) {
  final sign = value < 0 ? '-' : '';
  return '$sign€ ${value.abs().toStringAsFixed(2).replaceAll('.', ',')}';
}

int attendanceCount(Map<String, dynamic> event, String status) {
  final attendance = event['event_attendance'];
  if (attendance is! List) return 0;
  return attendance.where((item) {
    if (item is! Map) return false;
    return item['status']?.toString() == status;
  }).length;
}

String? myAttendanceStatus(Map<String, dynamic> event) {
  final uid = AppData.user?.id;
  final attendance = event['event_attendance'];
  if (uid == null || attendance is! List) return null;
  for (final item in attendance) {
    if (item is! Map) continue;
    if (item['user_id']?.toString() == uid) return item['status']?.toString();
  }
  return null;
}

String eventStatusForUser(Map<String, dynamic> event, String userId) {
  final attendance = event['event_attendance'];
  if (attendance is! List) return 'pending';
  for (final item in attendance) {
    if (item is! Map) continue;
    if (item['user_id']?.toString() == userId) return item['status']?.toString() ?? 'pending';
  }
  return 'pending';
}

bool sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

bool isPowerOfTwo(int value) => value > 0 && (value & (value - 1)) == 0;

int eventsInMonth(List<Map<String, dynamic>> events, DateTime month) {
  return events.where((e) {
    final d = DateTime.tryParse(e['starts_at']?.toString() ?? '')?.toLocal();
    return d != null && d.year == month.year && d.month == month.month;
  }).length;
}

String memberDisplayName(Map<String, dynamic> member) {
  final profile = AppData.asMap(member['profiles']);
  final fullName = AppData.text(profile['full_name']);
  if (fullName.isNotEmpty) return fullName;
  final email = AppData.text(profile['email']);
  if (email.contains('@')) return email.split('@').first;
  return 'Miembro';
}

String initialsFor(String name) {
  final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) return '?';
  if (words.length == 1) return words.first.substring(0, 1).toUpperCase();
  return '${words.first.substring(0, 1)}${words.last.substring(0, 1)}'.toUpperCase();
}

String attendanceLabel(String status) {
  switch (status) {
    case 'yes': return 'Va';
    case 'maybe': return 'Duda';
    case 'no': return 'No va';
    default: return 'Sin responder';
  }
}

Color attendanceColor(String status) {
  switch (status) {
    case 'yes': return AppColors.green;
    case 'maybe': return AppColors.amber;
    case 'no': return AppColors.red;
    default: return AppColors.muted;
  }
}


String tournamentFormatLabel(String format) {
  switch (format) {
    case 'eliminatoria':
      return 'Eliminatoria';
    case 'americano':
      return 'Americano';
    default:
      return 'Liga';
  }
}

String tournamentFormatSubtitle(String format) {
  switch (format) {
    case 'eliminatoria':
      return 'Cuadro directo: quien gana avanza y quien pierde queda fuera.';
    case 'americano':
      return 'Rondas rápidas para rotar participantes y mantener ranking.';
    default:
      return 'Todos contra todos con clasificación automática.';
  }
}

String teamTypeLabel(String type) {
  switch (type) {
    case 'individual':
      return 'Individual';
    case 'pareja':
      return 'Parejas';
    default:
      return 'Equipos';
  }
}

List<Map<String, dynamic>> tournamentTeams(Map<String, dynamic> tournament) {
  final value = tournament['tournament_teams'];
  if (value is! List) return [];
  final teams = value.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  teams.sort((a, b) => AppData.text(a['name']).toLowerCase().compareTo(AppData.text(b['name']).toLowerCase()));
  return teams;
}

List<Map<String, dynamic>> tournamentMatches(Map<String, dynamic> tournament) {
  final value = tournament['matches'];
  if (value is! List) return [];
  final matches = value.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  matches.sort((a, b) {
    final roundCompare = AppData.intValue(a['round']).compareTo(AppData.intValue(b['round']));
    if (roundCompare != 0) return roundCompare;
    return AppData.text(a['created_at']).compareTo(AppData.text(b['created_at']));
  });
  return matches;
}

String teamName(String? id, Map<String, String> names) {
  if (id == null || id.isEmpty || id == 'null') return 'Pendiente';
  return names[id] ?? 'Participante';
}

Map<String, String> teamNameMap(List<Map<String, dynamic>> teams) {
  return {for (final team in teams) team['id'].toString(): AppData.text(team['name'], 'Participante')};
}

List<TeamStanding> calculateStandings(List<Map<String, dynamic>> teams, List<Map<String, dynamic>> matches) {
  final table = <String, TeamStanding>{
    for (final team in teams)
      team['id'].toString(): TeamStanding(
        id: team['id'].toString(),
        name: AppData.text(team['name'], 'Participante'),
      ),
  };

  for (final match in matches) {
    if (AppData.text(match['status']) != 'played') continue;
    final aId = AppData.text(match['team_a']);
    final bId = AppData.text(match['team_b']);
    final a = table[aId];
    final b = table[bId];
    if (a == null || b == null) continue;
    final scoreA = AppData.intValue(match['score_a']);
    final scoreB = AppData.intValue(match['score_b']);

    a.played++;
    b.played++;
    a.goalsFor += scoreA;
    a.goalsAgainst += scoreB;
    b.goalsFor += scoreB;
    b.goalsAgainst += scoreA;

    if (scoreA > scoreB) {
      a.wins++;
      b.losses++;
      a.points += 3;
    } else if (scoreA < scoreB) {
      b.wins++;
      a.losses++;
      b.points += 3;
    } else {
      a.draws++;
      b.draws++;
      a.points += 1;
      b.points += 1;
    }
  }

  final rows = table.values.toList();
  rows.sort((a, b) {
    final points = b.points.compareTo(a.points);
    if (points != 0) return points;
    final diff = b.goalDifference.compareTo(a.goalDifference);
    if (diff != 0) return diff;
    final gf = b.goalsFor.compareTo(a.goalsFor);
    if (gf != 0) return gf;
    return a.name.compareTo(b.name);
  });
  return rows;
}

class TeamStanding {
  final String id;
  final String name;
  int played = 0;
  int wins = 0;
  int draws = 0;
  int losses = 0;
  int goalsFor = 0;
  int goalsAgainst = 0;
  int points = 0;

  TeamStanding({required this.id, required this.name});

  int get goalDifference => goalsFor - goalsAgainst;
}

Future<void> showToast(BuildContext context, String message, {bool danger = false}) async {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: danger ? AppColors.red : AppColors.teal,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DirectPage(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 30),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 46, 24, 38),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(31),
              gradient: const LinearGradient(colors: [Color(0xFF00A597), Color(0xFF005F66)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            ),
            child: Column(
              children: [
                Wrap(
                  spacing: 26,
                  runSpacing: 19,
                  alignment: WrapAlignment.center,
                  children: List.generate(32, (i) => Icon(_welcomeIcon(i), color: Colors.white.withOpacity(0.11), size: 18)),
                ),
                const SizedBox(height: 18),
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(29)),
                  child: const Icon(Icons.groups_rounded, color: AppColors.teal, size: 42),
                ),
                const SizedBox(height: 22),
                const Text('grupli', style: TextStyle(fontSize: 45, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1.5)),
                const SizedBox(height: 10),
                const Text('Organiza tu grupo.\nDisfruta más.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 18, height: 1.16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 28),
                SizedBox(width: double.infinity, child: WhiteButton(label: 'Comenzar', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AuthScreen(register: true))))),
                TextButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AuthScreen(register: false))), child: const Text('Iniciar sesión', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
              ],
            ),
          ),
          const SizedBox(height: 23),
          Text('La app privada para coordinar grupos sin caos.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          const Text('Eventos, calendario, finanzas y torneos en un único espacio cerrado.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted, fontSize: 15, height: 1.35)),
        ],
      ),
    );
  }

  IconData _welcomeIcon(int index) {
    const icons = [Icons.event_available_rounded, Icons.calendar_month_rounded, Icons.account_balance_wallet_rounded, Icons.emoji_events_rounded, Icons.lock_rounded, Icons.qr_code_rounded];
    return icons[index % icons.length];
  }
}

class AuthScreen extends StatefulWidget {
  final bool register;
  const AuthScreen({super.key, required this.register});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool loading = false;
  bool hidden = true;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (email.text.trim().isEmpty || password.text.length < 6) {
      await showToast(context, 'Introduce email y contraseña de al menos 6 caracteres.', danger: true);
      return;
    }
    setState(() => loading = true);
    try {
      if (widget.register) {
        await AppData.sb.auth.signUp(email: email.text.trim(), password: password.text.trim());
      } else {
        await AppData.sb.auth.signInWithPassword(email: email.text.trim(), password: password.text.trim());
      }
      await AppData.ensureProfile();
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      await showToast(context, e.toString(), danger: true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> oauth(OAuthProvider provider) async {
    try {
      await AppData.sb.auth.signInWithOAuth(provider, redirectTo: Uri.base.origin);
    } catch (e) {
      await showToast(context, e.toString(), danger: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DirectPage(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        RoundBackButton(onTap: () => Navigator.of(context).maybePop()),
        const SizedBox(height: 18),
        Text(widget.register ? 'Crear cuenta' : '¡Bienvenido de nuevo!', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 4),
        Text(widget.register ? 'Empieza a organizar tus grupos privados.' : 'Inicia sesión para continuar.', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 24),
        SocialButton(label: 'Continuar con Google', icon: 'G', onTap: () => oauth(OAuthProvider.google)),
        const SizedBox(height: 10),
        SocialButton(label: 'Continuar con Apple', icon: '', onTap: () => oauth(OAuthProvider.apple)),
        const SizedBox(height: 24),
        const OrDivider(),
        const SizedBox(height: 22),
        FieldLabel('Correo electrónico'),
        TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(prefixIcon: Icon(Icons.mail_outline_rounded), hintText: 'tu@email.com')),
        const SizedBox(height: 15),
        FieldLabel('Contraseña'),
        TextField(
          controller: password,
          obscureText: hidden,
          decoration: InputDecoration(prefixIcon: const Icon(Icons.lock_outline_rounded), hintText: '••••••••', suffixIcon: IconButton(icon: Icon(hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined), onPressed: () => setState(() => hidden = !hidden))),
        ),
        if (!widget.register) Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => showToast(context, 'Usa Supabase Auth para recuperar contraseña más adelante.'), child: const Text('¿Olvidaste tu contraseña?'))),
        const SizedBox(height: 16),
        PrimaryButton(label: widget.register ? 'Crear cuenta' : 'Iniciar sesión', icon: widget.register ? Icons.person_add_alt_1_rounded : Icons.login_rounded, loading: loading, onTap: submit),
        const SizedBox(height: 22),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(widget.register ? '¿Ya tienes cuenta?' : '¿No tienes cuenta?', style: Theme.of(context).textTheme.bodyMedium),
          TextButton(onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => AuthScreen(register: !widget.register))), child: Text(widget.register ? 'Inicia sesión' : 'Regístrate')),
        ]),
      ]),
    );
  }
}

class AuthedShell extends StatefulWidget {
  const AuthedShell({super.key});

  @override
  State<AuthedShell> createState() => _AuthedShellState();
}

class _AuthedShellState extends State<AuthedShell> {
  int tab = 0;
  int refreshKey = 0;

  void refresh() => setState(() => refreshKey++);

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(key: ValueKey('home-$refreshKey'), onChanged: refresh),
      NotificationsScreen(onChanged: refresh),
      ProfileScreen(onChanged: refresh),
    ];
    return Scaffold(
      backgroundColor: AppColors.white,
      body: pages[tab],
      bottomNavigationBar: RootBottomNav(index: tab, onTap: (i) => setState(() => tab = i)),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final VoidCallback onChanged;
  const HomeScreen({super.key, required this.onChanged});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Map<String, dynamic>>> future;

  @override
  void initState() {
    super.initState();
    future = AppData.myGroups();
  }

  void reload() => setState(() => future = AppData.myGroups());

  @override
  Widget build(BuildContext context) {
    final email = AppData.user?.email ?? 'usuario@email.com';
    final name = email.split('@').first;
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 28),
        children: [
          Row(children: [
            Text('Mis grupos', style: Theme.of(context).textTheme.headlineMedium),
            const Spacer(),
            CircleIconButton(icon: Icons.add_rounded, filled: true, onTap: () async {
              final ok = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const CreateJoinScreen()));
              if (ok == true) { reload(); widget.onChanged(); }
            }),
          ]),
          const SizedBox(height: 9),
          Text('Hola, $name 👋', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 20),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const HomeLoading();
              if (snapshot.hasError) return ErrorBlock(message: snapshot.error.toString(), onRetry: reload);
              final groups = snapshot.data ?? [];
              final members = groups.fold<int>(0, (sum, g) => sum + AppData.intValue(g['members_count'], 1));
              final events = groups.fold<int>(0, (sum, g) => sum + AppData.intValue(g['events_count'], 0));
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: StatCard(icon: Icons.lock_rounded, value: groups.length.toString(), label: 'Grupos', color: AppColors.teal)),
                  const SizedBox(width: 10),
                  Expanded(child: StatCard(icon: Icons.groups_rounded, value: members.toString(), label: 'Miembros', color: AppColors.violet)),
                  const SizedBox(width: 10),
                  Expanded(child: StatCard(icon: Icons.calendar_month_rounded, value: events.toString(), label: 'Eventos', color: AppColors.orange)),
                ]),
                const SizedBox(height: 26),
                Row(children: [
                  Text('Tus grupos', style: Theme.of(context).textTheme.titleLarge),
                  const Spacer(),
                  TextButton(onPressed: reload, child: const Text('Actualizar')),
                ]),
                const SizedBox(height: 10),
                if (groups.isEmpty)
                  EmptyBlock(icon: Icons.groups_rounded, title: 'Aún no tienes grupos', body: 'Crea un grupo privado o únete con un código de invitación.')
                else
                  ...groups.map((g) => GroupHomeCard(group: g, onTap: () async {
                    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => GroupShell(groupId: g['id'].toString())));
                    reload();
                  })),
                const SizedBox(height: 22),
                PrimaryButton(label: 'Crear grupo', icon: Icons.add_rounded, onTap: () async {
                  final ok = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const CreateGroupScreen()));
                  if (ok == true) reload();
                }),
                const SizedBox(height: 10),
                SecondaryButton(label: 'Unirme con código', icon: Icons.qr_code_rounded, onTap: () async {
                  final ok = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const JoinGroupScreen()));
                  if (ok == true) reload();
                }),
              ]);
            },
          ),
        ],
      ),
    );
  }
}

class CreateJoinScreen extends StatelessWidget {
  const CreateJoinScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DirectPage(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        RoundBackButton(onTap: () => Navigator.pop(context)),
        const SizedBox(height: 28),
        Center(child: Text('¿Qué quieres hacer?', style: Theme.of(context).textTheme.titleLarge)),
        const SizedBox(height: 22),
        ChoiceBigCard(icon: Icons.groups_rounded, title: 'Crear un grupo', body: 'Crea tu grupo privado y empieza a organizar.', onTap: () async {
          final ok = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const CreateGroupScreen()));
          if (context.mounted && ok == true) Navigator.pop(context, true);
        }),
        const SizedBox(height: 12),
        ChoiceBigCard(icon: Icons.group_add_rounded, title: 'Unirse a un grupo', body: 'Únete a un grupo con código o enlace.', onTap: () async {
          final ok = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const JoinGroupScreen()));
          if (context.mounted && ok == true) Navigator.pop(context, true);
        }),
      ]),
    );
  }
}

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final name = TextEditingController();
  bool loading = false;

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  Future<void> create() async {
    if (name.text.trim().length < 2) {
      await showToast(context, 'Pon un nombre de grupo.', danger: true);
      return;
    }
    setState(() => loading = true);
    try {
      await AppData.createGroup(name.text);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      await showToast(context, e.toString(), danger: true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DirectPage(
      child: Column(children: [
        Row(children: [RoundBackButton(onTap: () => Navigator.pop(context)), const Spacer()]),
        const SizedBox(height: 18),
        Container(
          width: 92,
          height: 92,
          decoration: const BoxDecoration(color: AppColors.tealSoft, shape: BoxShape.circle),
          child: const Icon(Icons.groups_rounded, color: AppColors.teal, size: 44),
        ),
        const SizedBox(height: 22),
        Text('Nuevo grupo', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 26),
        Align(alignment: Alignment.centerLeft, child: FieldLabel('Nombre del grupo')),
        TextField(controller: name, autofocus: true, decoration: const InputDecoration(hintText: 'Ej. Pádel los miércoles')),
        const SizedBox(height: 22),
        const Text('Todos los grupos son privados. El acceso es solo por invitación, código o enlace.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted, height: 1.35)),
        const SizedBox(height: 30),
        PrimaryButton(label: 'Crear grupo', loading: loading, onTap: create),
      ]),
    );
  }
}

class JoinGroupScreen extends StatefulWidget {
  const JoinGroupScreen({super.key});

  @override
  State<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends State<JoinGroupScreen> {
  final code = TextEditingController();
  bool loading = false;

  @override
  void dispose() {
    code.dispose();
    super.dispose();
  }

  Future<void> join() async {
    if (code.text.trim().length < 4) {
      await showToast(context, 'Introduce un código válido.', danger: true);
      return;
    }
    setState(() => loading = true);
    try {
      await AppData.joinGroup(code.text);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      await showToast(context, e.toString(), danger: true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DirectPage(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        RoundBackButton(onTap: () => Navigator.pop(context)),
        const SizedBox(height: 28),
        Text('Unirme a un grupo', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text('Introduce el código de invitación que te ha enviado tu grupo.', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 26),
        FieldLabel('Código de invitación'),
        TextField(controller: code, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(prefixIcon: Icon(Icons.qr_code_rounded), hintText: 'Ej. ABC123')),
        const SizedBox(height: 18),
        PrimaryButton(label: 'Unirme', icon: Icons.login_rounded, loading: loading, onTap: join),
      ]),
    );
  }
}

class GroupShell extends StatefulWidget {
  final String groupId;
  const GroupShell({super.key, required this.groupId});

  @override
  State<GroupShell> createState() => _GroupShellState();
}

class _GroupShellState extends State<GroupShell> {
  int tab = 0;
  int refreshKey = 0;
  late Future<Map<String, dynamic>> groupFuture;

  @override
  void initState() {
    super.initState();
    groupFuture = AppData.group(widget.groupId);
  }

  void refresh() => setState(() {
    refreshKey++;
    groupFuture = AppData.group(widget.groupId);
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: groupFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const DirectPage(child: CenterLoader(label: 'Cargando grupo...'));
        }
        if (snapshot.hasError) {
          return DirectPage(child: ErrorBlock(message: snapshot.error.toString(), onRetry: refresh));
        }
        final group = snapshot.data ?? {};
        final name = AppData.text(group['name'], 'Grupo');
        final pages = [
          GroupDashboardTab(group: group, refreshSeed: refreshKey, onNavigateTab: (i) => setState(() => tab = i)),
          CalendarTab(group: group, refreshSeed: refreshKey),
          FinancesTab(group: group, refreshSeed: refreshKey),
          TournamentsTab(group: group, refreshSeed: refreshKey),
          GroupMoreTab(group: group, refresh: refresh),
        ];
        return WillPopScope(
          onWillPop: () async {
            if (tab != 0) {
              setState(() => tab = 0);
              return false;
            }
            return true;
          },
          child: Scaffold(
            backgroundColor: AppColors.white,
            body: pages[tab],
            bottomNavigationBar: GroupBottomNav(groupName: name, index: tab, onTap: (i) => setState(() => tab = i)),
          ),
        );
      },
    );
  }
}

class GroupDashboardTab extends StatefulWidget {
  final Map<String, dynamic> group;
  final int refreshSeed;
  final ValueChanged<int>? onNavigateTab;
  const GroupDashboardTab({super.key, required this.group, required this.refreshSeed, this.onNavigateTab});

  @override
  State<GroupDashboardTab> createState() => _GroupDashboardTabState();
}

class _GroupDashboardTabState extends State<GroupDashboardTab> {
  late Future<_GroupDashboardData> future;

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void didUpdateWidget(covariant GroupDashboardTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshSeed != widget.refreshSeed) load();
  }

  void load() {
    final groupId = widget.group['id'].toString();
    future = _GroupDashboardData.load(groupId);
  }

  void reload() => setState(load);

  double _myOpenBalance(List<Map<String, dynamic>> expenses) {
    final uid = AppData.user?.id;
    if (uid == null) return 0;
    double total = 0;
    for (final expense in expenses) {
      if (AppData.text(expense['status'], 'pending') == 'paid') continue;
      final paidBy = expense['paid_by']?.toString();
      final participants = AppData.asList(expense['expense_participants']);
      for (final row in participants) {
        final item = AppData.asMap(row);
        final rowUserId = item['user_id']?.toString();
        final share = AppData.doubleValue(item['share_amount']);
        final paid = item['paid'] == true;
        if (paidBy == uid && rowUserId != uid && !paid) total += share;
        if (rowUserId == uid && paidBy != uid && !paid) total -= share;
      }
    }
    return double.parse(total.toStringAsFixed(2));
  }

  Map<String, dynamic>? _firstActiveTournament(List<Map<String, dynamic>> tournaments) {
    for (final tournament in tournaments) {
      if (AppData.text(tournament['status'], 'active') != 'finished') return tournament;
    }
    return null;
  }

  int _pendingMatches(Map<String, dynamic>? tournament) {
    if (tournament == null) return 0;
    return AppData.asList(tournament['matches']).where((m) => AppData.text(AppData.asMap(m)['status'], 'pending') != 'played').length;
  }

  int _teamCount(Map<String, dynamic>? tournament) {
    if (tournament == null) return 0;
    return AppData.asList(tournament['tournament_teams']).length;
  }

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    final groupId = group['id'].toString();
    final name = AppData.text(group['name'], 'Grupo');
    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          FutureBuilder<_GroupDashboardData>(
            future: future,
            builder: (context, snapshot) {
              final data = snapshot.data;
              final events = data?.events ?? <Map<String, dynamic>>[];
              final upcoming = data?.upcomingEvents ?? <Map<String, dynamic>>[];
              final nextEvent = upcoming.isNotEmpty ? upcoming.first : null;
              final myDecisionPending = upcoming.where((event) {
                final mine = myAttendanceStatus(event);
                return mine == null || mine == 'maybe';
              }).toList();
              final openExpenses = (data?.expenses ?? <Map<String, dynamic>>[])
                  .where((expense) => AppData.text(expense['status'], 'pending') != 'paid')
                  .toList();
              final openExpensesAmount = openExpenses.fold<double>(0, (sum, expense) => sum + AppData.doubleValue(expense['amount']));
              final expensesTotal = data?.expensesTotal ?? 0;
              final myBalance = _myOpenBalance(data?.expenses ?? const <Map<String, dynamic>>[]);
              final activeTournament = _firstActiveTournament(data?.tournaments ?? const <Map<String, dynamic>>[]);
              final tournamentsActive = data?.activeTournaments ?? 0;
              final upcomingThisWeek = upcoming.where((event) {
                final date = DateTime.tryParse(event['starts_at']?.toString() ?? '')?.toLocal();
                if (date == null) return false;
                final now = DateTime.now();
                return !date.isBefore(now.subtract(const Duration(hours: 2))) && date.isBefore(now.add(const Duration(days: 7)));
              }).length;

              Future<void> openCreateEvent() async {
                final ok = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => CreateEventScreen(group: group)));
                if (ok == true) reload();
              }

              Future<void> openEventDetail(Map<String, dynamic> event) async {
                await Navigator.of(context).push(MaterialPageRoute(builder: (_) => EventDetailScreen(event: event, group: group)));
                reload();
              }

              return RefreshIndicator(
                color: AppColors.teal,
                onRefresh: () async => reload(),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 112),
                  children: [
                    Row(children: [
                      RoundBackButton(onTap: () => Navigator.of(context).pop()),
                      const Spacer(),
                      CircleIconButton(
                        icon: Icons.more_horiz_rounded,
                        onTap: () => widget.onNavigateTab?.call(4),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    GroupHeroCard(name: name),
                    const SizedBox(height: 12),
                    if (snapshot.connectionState == ConnectionState.waiting)
                      const CenterLoader(label: 'Cargando resumen...')
                    else if (snapshot.hasError)
                      ErrorBlock(message: snapshot.error.toString(), onRetry: reload)
                    else ...[
                      SmartPromptCard(
                        icon: myDecisionPending.isNotEmpty
                            ? Icons.notification_important_rounded
                            : nextEvent != null
                                ? Icons.event_available_rounded
                                : Icons.waving_hand_rounded,
                        color: myDecisionPending.isNotEmpty
                            ? AppColors.amber
                            : nextEvent != null
                                ? AppColors.teal
                                : AppColors.teal,
                        title: myDecisionPending.isNotEmpty
                            ? (myDecisionPending.length == 1
                                ? 'Tienes 1 decisión pendiente'
                                : 'Tienes ${myDecisionPending.length} decisiones pendientes')
                            : nextEvent != null
                                ? 'Tu grupo ya tiene plan'
                                : 'Empieza a mover el grupo',
                        body: myDecisionPending.isNotEmpty
                            ? 'Responde a ${AppData.text(myDecisionPending.first['title'], 'la próxima quedada')} para dejar claro quién va y si se alcanza el mínimo.'
                            : nextEvent != null
                                ? 'La siguiente cita es ${AppData.text(nextEvent['title'], 'Evento')} y puedes revisarla o confirmar desde aquí sin salir del Inicio.'
                                : 'Crea la primera quedada del grupo para empezar a organizar asistencia, calendario y actividad real.',
                        actionLabel: myDecisionPending.isNotEmpty
                            ? 'Responder ahora'
                            : nextEvent != null
                                ? 'Ver detalle'
                                : 'Crear quedada',
                        onTap: () async {
                          if (myDecisionPending.isNotEmpty) {
                            await openEventDetail(myDecisionPending.first);
                          } else if (nextEvent != null) {
                            await openEventDetail(nextEvent);
                          } else {
                            await openCreateEvent();
                          }
                        },
                      ),
                      const SizedBox(height: 14),
                      Row(children: [
                        Expanded(child: StatCard(icon: Icons.event_rounded, value: upcoming.length.toString(), label: 'Próximos', color: AppColors.teal)),
                        const SizedBox(width: 10),
                        Expanded(child: StatCard(icon: Icons.hourglass_top_rounded, value: myDecisionPending.length.toString(), label: 'Pendientes', color: AppColors.amber)),
                        const SizedBox(width: 10),
                        Expanded(child: StatCard(icon: Icons.emoji_events_rounded, value: tournamentsActive.toString(), label: 'Activos', color: AppColors.orange)),
                      ]),
                      const SizedBox(height: 16),
                      SectionHeader(
                        title: 'Próxima quedada',
                        action: nextEvent == null ? 'Crear' : 'Calendario',
                        onTap: nextEvent == null ? openCreateEvent : () => widget.onNavigateTab?.call(1),
                      ),
                      const SizedBox(height: 8),
                      if (nextEvent == null)
                        EmptyBlock(
                          icon: Icons.event_available_rounded,
                          title: 'Todavía no hay quedadas',
                          body: 'Crea el primer plan del grupo y todos podrán responder Voy, Duda o No voy.',
                        )
                      else
                        DashboardEventCard(event: nextEvent, group: group, onChanged: reload),
                      const SizedBox(height: 16),
                      Row(children: [
                        Expanded(
                          child: DashboardSummaryCard(
                            icon: Icons.account_balance_wallet_rounded,
                            color: myBalance >= 0 ? AppColors.teal : AppColors.red,
                            eyebrow: 'Resumen económico',
                            title: openExpenses.isEmpty ? 'Todo está al día' : (myBalance > 0 ? 'Te deben ${money(myBalance)}' : myBalance < 0 ? 'Debes ${money(myBalance.abs())}' : 'Balance en cero'),
                            body: openExpenses.isEmpty
                                ? 'No hay deudas abiertas ni gastos pendientes en este momento.'
                                : '${openExpenses.length} ${openExpenses.length == 1 ? 'gasto abierto' : 'gastos abiertos'} · total del grupo ${money(openExpensesAmount)}',
                            footer: expensesTotal > 0 ? 'Histórico acumulado: ${money(expensesTotal)}' : 'Empieza registrando el primer gasto compartido.',
                            actionLabel: 'Abrir finanzas',
                            onTap: () => widget.onNavigateTab?.call(2),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DashboardSummaryCard(
                            icon: Icons.emoji_events_rounded,
                            color: activeTournament == null ? AppColors.violet : AppColors.orange,
                            eyebrow: 'Torneo activo',
                            title: activeTournament == null
                                ? 'Aún no hay competición'
                                : AppData.text(activeTournament['name'], 'Competición'),
                            body: activeTournament == null
                                ? 'Crea una liga o torneo cuando el grupo quiera competir.'
                                : '${_teamCount(activeTournament)} participantes · ${_pendingMatches(activeTournament)} partidos pendientes',
                            footer: activeTournament == null
                                ? 'Formato guiado para liga, copa o americano.'
                                : '${_cap(AppData.text(activeTournament['format'], 'liga'))} · ${AppData.text(activeTournament['status'], 'active') == 'finished' ? 'Finalizado' : 'En curso'}',
                            actionLabel: activeTournament == null ? 'Crear torneo' : 'Abrir torneo',
                            onTap: () => widget.onNavigateTab?.call(3),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 16),
                      AppCard(
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Expanded(child: Text('Acciones rápidas', style: Theme.of(context).textTheme.titleMedium)),
                              Text('${upcomingThisWeek} esta semana', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 12)),
                            ]),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                QuickActionButton(icon: Icons.add_task_rounded, label: 'Quedada', onTap: openCreateEvent),
                                QuickActionButton(icon: Icons.wallet_rounded, label: 'Gasto', onTap: () async {
                                  await Navigator.of(context).push(MaterialPageRoute(builder: (_) => CreateExpenseScreen(groupId: group['id'].toString())));
                                  reload();
                                }),
                                QuickActionButton(icon: Icons.emoji_events_rounded, label: 'Torneo', onTap: () => widget.onNavigateTab?.call(3)),
                                QuickActionButton(icon: Icons.groups_rounded, label: 'Miembros', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => MembersScreen(group: group)))),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SectionHeader(title: 'Actividad real', action: 'Actualizar', onTap: reload),
                      const SizedBox(height: 8),
                      DashboardActivityCard(
                        events: events,
                        expenses: data?.expenses ?? const <Map<String, dynamic>>[],
                        tournaments: data?.tournaments ?? const <Map<String, dynamic>>[],
                        onOpenCalendar: () => widget.onNavigateTab?.call(1),
                        onOpenFinances: () => widget.onNavigateTab?.call(2),
                        onOpenTournaments: () => widget.onNavigateTab?.call(3),
                      ),
                      if (upcoming.length > 1) ...[
                        const SizedBox(height: 16),
                        SectionHeader(title: 'Más adelante', action: 'Ver todo', onTap: () => widget.onNavigateTab?.call(1)),
                        const SizedBox(height: 8),
                        ...upcoming.skip(1).take(3).map((e) => EventCard(event: e, onTap: () async {
                          await openEventDetail(e);
                        })),
                      ],
                    ],
                  ],
                ),
              );
            },
          ),
          Positioned(
            right: 20,
            bottom: 20,
            child: FloatingActionButton(
              heroTag: 'create-event-$groupId',
              backgroundColor: AppColors.teal,
              foregroundColor: Colors.white,
              onPressed: () async {
                final ok = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => CreateEventScreen(group: group)));
                if (ok == true) reload();
              },
              child: const Icon(Icons.add_rounded),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupDashboardData {
  final List<Map<String, dynamic>> events;
  final List<Map<String, dynamic>> expenses;
  final List<Map<String, dynamic>> tournaments;

  const _GroupDashboardData({required this.events, required this.expenses, required this.tournaments});

  static Future<_GroupDashboardData> load(String groupId) async {
    final results = await Future.wait([
      AppData.events(groupId),
      AppData.expenses(groupId),
      AppData.tournaments(groupId),
    ]);
    return _GroupDashboardData(events: results[0], expenses: results[1], tournaments: results[2]);
  }

  List<Map<String, dynamic>> get upcomingEvents {
    final now = DateTime.now().subtract(const Duration(hours: 2));
    final list = events.where((event) {
      final date = DateTime.tryParse(event['starts_at']?.toString() ?? '')?.toLocal();
      return date != null && date.isAfter(now);
    }).toList();
    list.sort((a, b) {
      final da = DateTime.tryParse(a['starts_at']?.toString() ?? '') ?? DateTime.now();
      final db = DateTime.tryParse(b['starts_at']?.toString() ?? '') ?? DateTime.now();
      return da.compareTo(db);
    });
    return list;
  }

  double get expensesTotal => expenses.fold<double>(0, (sum, e) => sum + AppData.doubleValue(e['amount']));
  int get activeTournaments => tournaments.where((t) => AppData.text(t['status'], 'active') != 'finished').length;
}



class GroupMoreTab extends StatelessWidget {
  final Map<String, dynamic> group;
  final VoidCallback refresh;
  const GroupMoreTab({super.key, required this.group, required this.refresh});

  @override
  Widget build(BuildContext context) {
    final name = AppData.text(group['name'], 'Grupo');
    final code = AppData.text(group['invite_code'], '------');
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 112),
        children: [
          PageHeader(title: 'Más', subtitle: name, leading: false),
          const SizedBox(height: 18),
          SettingsRow(icon: Icons.person_add_alt_1_rounded, title: 'Invitar miembros', subtitle: 'Compartir el código del grupo', onTap: () => Share.share('Únete a $name en Grupli con el código $code')),
          SettingsRow(icon: Icons.qr_code_rounded, title: 'Código de invitación', subtitle: code, onTap: () => showCodeSheet(context, code, name)),
          SettingsRow(icon: Icons.groups_rounded, title: 'Miembros y admins', subtitle: 'Ver miembros, owner y administradores', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => MembersScreen(group: group)))),
          SettingsRow(icon: Icons.lock_rounded, title: 'Privacidad del grupo', subtitle: 'Todos los grupos son privados por invitación', onTap: () => showToast(context, 'Los grupos de Grupli son privados por diseño.')),
          SettingsRow(icon: Icons.settings_rounded, title: 'Ajustes del grupo', subtitle: 'Nombre, permisos y acciones de admin', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => GroupSettingsScreen(group: group)))),
          const SizedBox(height: 18),
          EmptySlim(
            icon: Icons.info_outline_rounded,
            title: 'Inicio es el resumen real del grupo',
            body: 'Las quedadas se ven en Inicio y Calendario. Aquí solo quedan utilidades, miembros y ajustes.',
          ),
        ],
      ),
    );
  }
}

class EventsTab extends StatefulWidget {
  final Map<String, dynamic> group;
  final int refreshSeed;
  const EventsTab({super.key, required this.group, required this.refreshSeed});

  @override
  State<EventsTab> createState() => _EventsTabState();
}

class _EventsTabState extends State<EventsTab> {
  late Future<List<Map<String, dynamic>>> future;

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void didUpdateWidget(covariant EventsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshSeed != widget.refreshSeed) load();
  }

  void load() => future = AppData.events(widget.group['id'].toString());
  void reload() => setState(load);

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    return SafeArea(
      bottom: false,
      child: Stack(children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          children: [
            PageHeader(title: 'Eventos', subtitle: AppData.text(group['name']), leading: true),
            const SizedBox(height: 16),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const CenterLoader(label: 'Cargando eventos...');
                if (snapshot.hasError) return ErrorBlock(message: snapshot.error.toString(), onRetry: reload);
                final events = snapshot.data ?? [];
                final upcoming = events.where((e) => DateTime.tryParse(e['starts_at']?.toString() ?? '')?.isAfter(DateTime.now().subtract(const Duration(hours: 2))) ?? false).toList();
                final past = events.length - upcoming.length;
                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: StatCard(icon: Icons.calendar_month_rounded, value: upcoming.length.toString(), label: 'Próximos', color: AppColors.teal)),
                    const SizedBox(width: 10),
                    Expanded(child: StatCard(icon: Icons.groups_rounded, value: _attendanceTotal(events, 'yes').toString(), label: 'Confirmados', color: AppColors.green)),
                    const SizedBox(width: 10),
                    Expanded(child: StatCard(icon: Icons.history_rounded, value: past.toString(), label: 'Pasados', color: AppColors.violet)),
                  ]),
                  const SizedBox(height: 24),
                  Row(children: [Text('Próximos', style: Theme.of(context).textTheme.titleLarge), const Spacer(), TextButton(onPressed: reload, child: const Text('Actualizar'))]),
                  const SizedBox(height: 8),
                  if (upcoming.isEmpty) EmptyBlock(icon: Icons.event_available_rounded, title: 'No hay próximos eventos', body: 'Crea una quedada para que los miembros confirmen asistencia.') else ...upcoming.map((e) => EventCard(event: e, onTap: () async { await Navigator.of(context).push(MaterialPageRoute(builder: (_) => EventDetailScreen(event: e, group: group))); reload(); })),
                ]);
              },
            ),
          ],
        ),
        Positioned(right: 20, bottom: 20, child: FloatingActionButton(backgroundColor: AppColors.teal, foregroundColor: Colors.white, onPressed: () async { final ok = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => CreateEventScreen(group: group))); if (ok == true) reload(); }, child: const Icon(Icons.add_rounded))),
      ]),
    );
  }

  int _attendanceTotal(List<Map<String, dynamic>> events, String status) {
    var total = 0;
    for (final e in events) {
      final att = e['event_attendance'];
      if (att is List) total += att.where((x) => (x as Map)['status'] == status).length;
    }
    return total;
  }
}



class CreateEventScreen extends StatefulWidget {
  final Map<String, dynamic> group;
  final DateTime? initialDate;
  final Map<String, dynamic>? event;
  const CreateEventScreen({super.key, required this.group, this.initialDate, this.event});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final title = TextEditingController();
  final location = TextEditingController();
  final notes = TextEditingController();
  late DateTime date;
  TimeOfDay time = const TimeOfDay(hour: 20, minute: 0);
  int minPeople = 2;
  bool loading = false;
  String template = 'Quedada';

  bool get editing => widget.event != null;

  @override
  void initState() {
    super.initState();
    final event = widget.event;
    final eventDate = DateTime.tryParse(event?['starts_at']?.toString() ?? '')?.toLocal();
    date = widget.initialDate ?? eventDate ?? DateTime.now().add(const Duration(days: 1));
    if (eventDate != null) time = TimeOfDay.fromDateTime(eventDate);
    title.text = AppData.text(event?['title']);
    location.text = AppData.text(event?['location']);
    notes.text = AppData.text(event?['notes']);
    minPeople = AppData.intValue(event?['min_people'], 2);
    if (title.text.toLowerCase().contains('partido')) template = 'Partido';
    if (title.text.toLowerCase().contains('entrenamiento')) template = 'Entrenamiento';
    if (title.text.toLowerCase().contains('cena')) template = 'Cena';
    if (title.text.toLowerCase().contains('reunión') || title.text.toLowerCase().contains('reunion')) template = 'Reunión';
  }

  @override
  void dispose() {
    title.dispose();
    location.dispose();
    notes.dispose();
    super.dispose();
  }

  void applyTemplate(String value) {
    setState(() {
      template = value;
      if (title.text.trim().isEmpty || ['Quedada', 'Partido', 'Entrenamiento', 'Cena del grupo', 'Reunión'].contains(title.text.trim())) {
        title.text = value == 'Cena' ? 'Cena del grupo' : value;
      }
      if (value == 'Partido' && minPeople < 4) minPeople = 4;
      if (value == 'Entrenamiento' && minPeople < 2) minPeople = 2;
      if (value == 'Cena' && minPeople < 2) minPeople = 2;
      if (value == 'Reunión' && minPeople < 2) minPeople = 2;
    });
  }

  Future<void> save() async {
    final cleanTitle = title.text.trim();
    if (cleanTitle.length < 2) {
      await showToast(context, 'Pon un título claro para el evento.', danger: true);
      return;
    }
    final start = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() => loading = true);
    try {
      if (editing) {
        await AppData.updateEvent(widget.event!['id'].toString(), cleanTitle, start, location.text, notes.text, minPeople);
      } else {
        await AppData.createEvent(widget.group['id'].toString(), cleanTitle, start, location.text, notes.text, minPeople);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      await showToast(context, e.toString(), danger: true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupName = AppData.text(widget.group['name'], 'Grupo');
    final previewDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    return DirectPage(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeader(title: editing ? 'Editar evento' : 'Nuevo evento', subtitle: groupName, leading: true),
      const SizedBox(height: 14),
      EventFormPreviewCard(
        title: title.text.trim().isEmpty ? (editing ? 'Evento del grupo' : 'Nueva quedada') : title.text.trim(),
        date: previewDate,
        location: location.text.trim(),
        minPeople: minPeople,
        template: template,
      ),
      const SizedBox(height: 16),
      SectionHeader(title: 'Tipo de plan'),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: [
        EventTemplateChoice(label: 'Quedada', icon: Icons.groups_rounded, selected: template == 'Quedada', onTap: () => applyTemplate('Quedada')),
        EventTemplateChoice(label: 'Partido', icon: Icons.sports_soccer_rounded, selected: template == 'Partido', onTap: () => applyTemplate('Partido')),
        EventTemplateChoice(label: 'Entrenamiento', icon: Icons.fitness_center_rounded, selected: template == 'Entrenamiento', onTap: () => applyTemplate('Entrenamiento')),
        EventTemplateChoice(label: 'Cena', icon: Icons.restaurant_rounded, selected: template == 'Cena', onTap: () => applyTemplate('Cena')),
        EventTemplateChoice(label: 'Reunión', icon: Icons.forum_rounded, selected: template == 'Reunión', onTap: () => applyTemplate('Reunión')),
      ]),
      const SizedBox(height: 16),
      AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        FieldLabel('Título'),
        TextField(controller: title, onChanged: (_) => setState(() {}), decoration: const InputDecoration(hintText: 'Ej. Partido semanal')),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: SmallPick(label: 'Fecha', value: DateFormat('dd/MM/yyyy', 'es_ES').format(date), icon: Icons.calendar_month_rounded, onTap: () async {
            final d = await showDatePicker(
              context: context,
              locale: const Locale('es'),
              initialDate: date,
              firstDate: DateTime.now().subtract(const Duration(days: 1)),
              lastDate: DateTime.now().add(const Duration(days: 730)),
            );
            if (d != null) setState(() => date = d);
          })),
          const SizedBox(width: 10),
          Expanded(child: SmallPick(label: 'Hora', value: time.format(context), icon: Icons.schedule_rounded, onTap: () async {
            final t = await showTimePicker(context: context, initialTime: time);
            if (t != null) setState(() => time = t);
          })),
        ]),
        const SizedBox(height: 14),
        FieldLabel('Lugar'),
        TextField(controller: location, onChanged: (_) => setState(() {}), decoration: const InputDecoration(prefixIcon: Icon(Icons.place_outlined), hintText: 'Ej. Pista 3, club, casa...')),
      ])),
      const SizedBox(height: 14),
      AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 38, height: 38, decoration: BoxDecoration(color: AppColors.tealSoft, borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.verified_rounded, color: AppColors.teal, size: 20)),
          const SizedBox(width: 11),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Mínimo para que el plan salga adelante', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 3),
            Text('Grupli avisará cuando haya suficientes personas confirmadas.', style: Theme.of(context).textTheme.bodyMedium),
          ])),
        ]),
        const SizedBox(height: 12),
        StepperRow(value: minPeople, onMinus: () => setState(() => minPeople = max(1, minPeople - 1)), onPlus: () => setState(() => minPeople++)),
      ])),
      const SizedBox(height: 14),
      FieldLabel('Notas opcionales'),
      TextField(controller: notes, maxLines: 4, decoration: const InputDecoration(hintText: 'Material, normas, instrucciones, coste aproximado...')),
      const SizedBox(height: 22),
      PrimaryButton(label: editing ? 'Guardar cambios' : 'Crear evento', icon: editing ? Icons.save_rounded : Icons.add_rounded, loading: loading, onTap: save),
    ]));
  }
}


class EventDetailScreen extends StatefulWidget {
  final Map<String, dynamic> event;
  final Map<String, dynamic> group;
  const EventDetailScreen({super.key, required this.event, required this.group});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  late Future<_EventDetailData> future;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    load();
  }

  void load() {
    future = _EventDetailData.load(widget.event['id'].toString(), widget.group['id'].toString());
  }

  void reload() => setState(load);

  Future<void> setStatus(String eventId, String status) async {
    setState(() => saving = true);
    try {
      await AppData.setAttendance(eventId, status);
      reload();
    } catch (e) {
      await showToast(context, e.toString(), danger: true);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> editEvent(Map<String, dynamic> event) async {
    final ok = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => CreateEventScreen(group: widget.group, event: event)));
    if (ok == true) reload();
  }

  Future<void> cancelEvent(Map<String, dynamic> event) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancelar evento'),
        content: const Text('El evento dejará de aparecer en el calendario del grupo. Esta acción no borra el grupo.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Cancelar evento')),
        ],
      ),
    );
    if (yes != true) return;
    try {
      await AppData.cancelEvent(event['id'].toString());
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      await showToast(context, e.toString(), danger: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_EventDetailData>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const DirectPage(child: CenterLoader(label: 'Cargando evento...'));
        }
        if (snapshot.hasError) {
          return DirectPage(child: ErrorBlock(message: snapshot.error.toString(), onRetry: reload));
        }
        final data = snapshot.data!;
        final event = data.event;
        final date = DateTime.tryParse(event['starts_at']?.toString() ?? '')?.toLocal() ?? DateTime.now();
        final yes = attendanceCount(event, 'yes');
        final maybe = attendanceCount(event, 'maybe');
        final no = attendanceCount(event, 'no');
        final minPeople = AppData.intValue(event['min_people'], 2);
        final mine = myAttendanceStatus(event);
        final pending = max(0, data.members.length - yes - maybe - no);

        return DirectPage(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          PageHeader(title: AppData.text(event['title'], 'Evento'), subtitle: AppData.text(widget.group['name'], 'Grupo'), leading: true),
          const SizedBox(height: 12),
          PremiumEventDetailHero(event: event, date: date, yes: yes, minPeople: minPeople),
          const SizedBox(height: 16),
          SectionHeader(title: 'Tu respuesta'),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: AttendancePick(label: 'Voy', count: yes, selected: mine == 'yes', color: AppColors.green, onTap: saving ? () {} : () => setStatus(event['id'].toString(), 'yes'))),
            const SizedBox(width: 8),
            Expanded(child: AttendancePick(label: 'Duda', count: maybe, selected: mine == 'maybe', color: AppColors.amber, onTap: saving ? () {} : () => setStatus(event['id'].toString(), 'maybe'))),
            const SizedBox(width: 8),
            Expanded(child: AttendancePick(label: 'No voy', count: no, selected: mine == 'no', color: AppColors.red, onTap: saving ? () {} : () => setStatus(event['id'].toString(), 'no'))),
          ]),
          if (saving) const Padding(padding: EdgeInsets.only(top: 10), child: LinearProgressIndicator()),
          const SizedBox(height: 12),
          AttendanceOverviewCard(yes: yes, maybe: maybe, no: no, pending: pending, minPeople: minPeople),
          const SizedBox(height: 18),
          SectionHeader(title: 'Asistencia del grupo', action: 'Actualizar', onTap: reload),
          const SizedBox(height: 10),
          EventMemberRoster(event: event, members: data.members),
          const SizedBox(height: 18),
          SecondaryButton(label: 'Editar evento', icon: Icons.edit_rounded, onTap: () => editEvent(event)),
          const SizedBox(height: 10),
          DangerButton(label: 'Cancelar evento', icon: Icons.event_busy_rounded, onTap: () => cancelEvent(event)),
        ]));
      },
    );
  }
}

class _EventDetailData {
  final Map<String, dynamic> event;
  final List<Map<String, dynamic>> members;
  const _EventDetailData({required this.event, required this.members});

  static Future<_EventDetailData> load(String eventId, String groupId) async {
    final results = await Future.wait([
      AppData.eventById(eventId),
      AppData.members(groupId),
    ]);
    return _EventDetailData(event: results[0] as Map<String, dynamic>, members: List<Map<String, dynamic>>.from(results[1] as List));
  }
}




class CalendarTab extends StatefulWidget {
  final Map<String, dynamic> group;
  final int refreshSeed;
  const CalendarTab({super.key, required this.group, required this.refreshSeed});
  @override State<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<CalendarTab> {
  DateTime month = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime selected = DateTime.now();
  late Future<List<Map<String, dynamic>>> future;

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void didUpdateWidget(covariant CalendarTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshSeed != widget.refreshSeed) load();
  }

  void load() => future = AppData.events(widget.group['id'].toString());
  void reload() => setState(load);

  Future<void> createFor(DateTime day) async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => CreateEventScreen(group: widget.group, initialDate: day)),
    );
    if (ok == true) reload();
  }

  Future<void> openEvent(Map<String, dynamic> event) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => EventDetailScreen(event: event, group: widget.group)));
    reload();
  }

  int _eventCountForDay(List<Map<String, dynamic>> events, DateTime day) {
    return events.where((event) {
      final date = DateTime.tryParse(event['starts_at']?.toString() ?? '')?.toLocal();
      return date != null && sameDay(date, day);
    }).length;
  }

  List<Map<String, dynamic>> _eventsForDay(List<Map<String, dynamic>> events, DateTime day) {
    final list = events.where((event) {
      final date = DateTime.tryParse(event['starts_at']?.toString() ?? '')?.toLocal();
      return date != null && sameDay(date, day);
    }).toList();
    list.sort((a, b) {
      final da = DateTime.tryParse(a['starts_at']?.toString() ?? '') ?? DateTime.now();
      final db = DateTime.tryParse(b['starts_at']?.toString() ?? '') ?? DateTime.now();
      return da.compareTo(db);
    });
    return list;
  }

  List<Map<String, dynamic>> _upcoming(List<Map<String, dynamic>> events) {
    final now = DateTime.now().subtract(const Duration(hours: 2));
    final list = events.where((event) {
      final date = DateTime.tryParse(event['starts_at']?.toString() ?? '')?.toLocal();
      return date != null && date.isAfter(now);
    }).toList();
    list.sort((a, b) {
      final da = DateTime.tryParse(a['starts_at']?.toString() ?? '') ?? DateTime.now();
      final db = DateTime.tryParse(b['starts_at']?.toString() ?? '') ?? DateTime.now();
      return da.compareTo(db);
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Stack(children: [
        FutureBuilder<List<Map<String, dynamic>>>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CenterLoader(label: 'Cargando calendario...');
            }
            if (snapshot.hasError) {
              return ListView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 112), children: [
                ErrorBlock(message: snapshot.error.toString(), onRetry: reload),
              ]);
            }

            final events = (snapshot.data ?? [])
                .where((e) => AppData.text(e['status'], 'active') != 'cancelled')
                .toList();
            final selectedEvents = _eventsForDay(events, selected);
            final upcoming = _upcoming(events);
            final todayEvents = _eventsForDay(events, DateTime.now());
            final thisWeek = upcoming.where((event) {
              final date = DateTime.tryParse(event['starts_at']?.toString() ?? '')?.toLocal();
              if (date == null) return false;
              return date.isBefore(DateTime.now().add(const Duration(days: 7)));
            }).length;
            final pendingResponse = upcoming.where((event) {
              final mine = myAttendanceStatus(event);
              return mine == null || mine == 'maybe';
            }).length;
            final selectedYes = selectedEvents.fold<int>(0, (sum, e) => sum + attendanceCount(e, 'yes'));
            final selectedMaybe = selectedEvents.fold<int>(0, (sum, e) => sum + attendanceCount(e, 'maybe'));

            final weekDays = List<DateTime>.generate(7, (i) {
              final start = DateTime.now();
              return DateTime(start.year, start.month, start.day).add(Duration(days: i));
            });

            return RefreshIndicator(
              color: AppColors.teal,
              onRefresh: () async => reload(),
              child: ListView(padding: const EdgeInsets.fromLTRB(16, 14, 16, 112), children: [
                PageHeader(title: 'Calendario', subtitle: AppData.text(widget.group['name']), leading: false),
                const SizedBox(height: 12),
                CalendarSmartHeader(
                  todayEvents: todayEvents.length,
                  weekEvents: thisWeek,
                  pendingResponses: pendingResponse,
                  onToday: () => setState(() {
                    selected = DateTime.now();
                    month = DateTime(DateTime.now().year, DateTime.now().month);
                  }),
                ),
                const SizedBox(height: 12),
                WeekStrip(
                  days: weekDays,
                  selected: selected,
                  events: events,
                  onSelect: (day) => setState(() {
                    selected = day;
                    month = DateTime(day.year, day.month);
                  }),
                ),
                const SizedBox(height: 14),
                AppCard(child: Column(children: [
                  Row(children: [
                    IconButton(onPressed: () => setState(() => month = DateTime(month.year, month.month - 1)), icon: const Icon(Icons.chevron_left_rounded)),
                    Expanded(child: Column(children: [
                      Text(monthTitle(month), style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text('${eventsInMonth(events, month)} eventos este mes', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 12)),
                    ])),
                    IconButton(onPressed: () => setState(() => month = DateTime(month.year, month.month + 1)), icon: const Icon(Icons.chevron_right_rounded)),
                  ]),
                  const SizedBox(height: 8),
                  MonthGrid(
                    month: month,
                    selected: selected,
                    events: events,
                    onSelect: (d) => setState(() {
                      selected = d;
                      month = DateTime(d.year, d.month);
                    }),
                  ),
                ])),
                const SizedBox(height: 14),
                CalendarDaySummary(
                  day: selected,
                  events: selectedEvents,
                  confirmed: selectedYes,
                  maybe: selectedMaybe,
                  onCreate: () => createFor(selected),
                ),
                const SizedBox(height: 18),
                SectionHeader(title: 'Agenda del día', action: 'Crear', onTap: () => createFor(selected)),
                const SizedBox(height: 10),
                if (selectedEvents.isEmpty)
                  EmptyBlock(icon: Icons.calendar_month_rounded, title: 'No hay nada este día', body: 'Crea una quedada, partido, cena o reunión para organizar al grupo.')
                else
                  ...selectedEvents.map((e) => EventAgendaCard(event: e, group: widget.group, onChanged: reload)),
                const SizedBox(height: 18),
                SectionHeader(title: 'Próximas decisiones', action: 'Ver hoy', onTap: () => setState(() {
                  selected = DateTime.now();
                  month = DateTime(DateTime.now().year, DateTime.now().month);
                })),
                const SizedBox(height: 10),
                if (upcoming.isEmpty)
                  EmptySlim(icon: Icons.event_available_rounded, title: 'Agenda vacía', body: 'Crea el primer evento desde el botón +.')
                else
                  ...upcoming.take(5).map((e) => EventCard(event: e, onTap: () => openEvent(e))),
              ]),
            );
          },
        ),
        Positioned(
          right: 20,
          bottom: 20,
          child: FloatingActionButton.extended(
            heroTag: 'calendar-create-event-${widget.group['id']}',
            backgroundColor: AppColors.teal,
            foregroundColor: Colors.white,
            onPressed: () => createFor(selected),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Evento', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ),
      ]),
    );
  }
}

class FinancesTab extends StatefulWidget {
  final Map<String, dynamic> group;
  final int refreshSeed;
  const FinancesTab({super.key, required this.group, required this.refreshSeed});
  @override
  State<FinancesTab> createState() => _FinancesTabState();
}

class _FinancesTabState extends State<FinancesTab> {
  late Future<_FinanceData> future;

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void didUpdateWidget(covariant FinancesTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshSeed != widget.refreshSeed) load();
  }

  void load() => future = _FinanceData.load(widget.group['id'].toString());
  void reload() => setState(load);

  Future<void> openCreate() async {
    final ok = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => CreateExpenseScreen(groupId: widget.group['id'].toString())));
    if (ok == true) reload();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Stack(children: [
        FutureBuilder<_FinanceData>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CenterLoader(label: 'Calculando balances...');
            }
            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
                children: [ErrorBlock(message: snapshot.error.toString(), onRetry: reload)],
              );
            }

            final data = snapshot.data ?? _FinanceData.empty();
            final summary = data.summary;
            final pendingExpenses = data.expenses.where((e) => AppData.text(e['status'], 'pending') != 'paid').toList();
            final settledExpenses = data.expenses.where((e) => AppData.text(e['status'], 'pending') == 'paid').toList();
            final pendingCount = pendingExpenses.length;
            final settledCount = settledExpenses.length;

            return RefreshIndicator(
              color: AppColors.teal,
              onRefresh: () async => reload(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 112),
                children: [
                  PageHeader(title: 'Finanzas', subtitle: 'Cuentas claras para ${AppData.text(widget.group['name'], 'el grupo')}', leading: false),
                  const SizedBox(height: 14),
                  FinanceHeroCard(summary: summary, onCreate: openCreate),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: FinanceMiniMetric(icon: Icons.receipt_long_rounded, label: 'Total', value: money(summary.totalExpenses), color: AppColors.teal)),
                    const SizedBox(width: 10),
                    Expanded(child: FinanceMiniMetric(icon: Icons.pending_actions_rounded, label: 'Abiertos', value: pendingCount.toString(), color: AppColors.amber)),
                    const SizedBox(width: 10),
                    Expanded(child: FinanceMiniMetric(icon: Icons.verified_rounded, label: 'Liquidados', value: settledCount.toString(), color: AppColors.green)),
                  ]),
                  const SizedBox(height: 20),
                  SectionHeader(title: 'Plan para dejarlo a cero', action: 'Actualizar', onTap: reload),
                  const SizedBox(height: 8),
                  if (summary.settlements.isEmpty)
                    EmptySlim(icon: Icons.verified_rounded, title: 'Todo está cuadrado', body: 'No hace falta mover dinero entre miembros ahora mismo.')
                  else
                    AppCard(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(children: [
                        for (int i = 0; i < summary.settlements.length; i++) ...[
                          SettlementPaymentRow(debt: summary.settlements[i]),
                          if (i != summary.settlements.length - 1) const Divider(height: 1, indent: 58, color: AppColors.line),
                        ],
                      ]),
                    ),
                  const SizedBox(height: 20),
                  SectionHeader(title: 'Balances individuales'),
                  const SizedBox(height: 8),
                  if (summary.balances.isEmpty)
                    EmptySlim(icon: Icons.people_alt_rounded, title: 'Sin miembros para calcular balances')
                  else
                    AppCard(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(children: summary.balances.entries.map((entry) {
                        final name = summary.names[entry.key] ?? 'Miembro';
                        return BalanceRow(name: name, value: entry.value);
                      }).toList()),
                    ),
                  const SizedBox(height: 20),
                  SectionHeader(title: 'Gastos abiertos', action: 'Añadir', onTap: openCreate),
                  const SizedBox(height: 8),
                  if (pendingExpenses.isEmpty)
                    EmptyBlock(icon: Icons.account_balance_wallet_rounded, title: 'No hay gastos pendientes', body: 'Cuando alguien pague una pista, cena o reserva, Grupli calculará automáticamente quién debe a quién.')
                  else
                    ...pendingExpenses.map((e) => ExpenseCard(
                      expense: e,
                      members: data.members,
                      onTap: () async {
                        final ok = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => ExpenseDetailScreen(expense: e, members: data.members)));
                        if (ok == true) reload();
                      },
                    )),
                  if (settledExpenses.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    SectionHeader(title: 'Historial liquidado', action: '${settledExpenses.length} gastos'),
                    const SizedBox(height: 8),
                    ...settledExpenses.take(5).map((e) => ExpenseCard(
                      expense: e,
                      members: data.members,
                      onTap: () async {
                        final ok = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => ExpenseDetailScreen(expense: e, members: data.members)));
                        if (ok == true) reload();
                      },
                    )),
                  ],
                ],
              ),
            );
          },
        ),
        Positioned(
          right: 20,
          bottom: 20,
          child: FloatingActionButton.extended(
            backgroundColor: AppColors.teal,
            foregroundColor: Colors.white,
            onPressed: openCreate,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Gasto', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ),
      ]),
    );
  }
}

class CreateExpenseScreen extends StatefulWidget {
  final String groupId;
  const CreateExpenseScreen({super.key, required this.groupId});
  @override
  State<CreateExpenseScreen> createState() => _CreateExpenseScreenState();
}

class _CreateExpenseScreenState extends State<CreateExpenseScreen> {
  final concept = TextEditingController();
  final amount = TextEditingController();
  final note = TextEditingController();
  bool loading = false;
  bool initialized = false;
  String? paidBy;
  String splitMode = 'all';
  final selected = <String>{};
  final customShares = <String, TextEditingController>{};
  late Future<List<Map<String, dynamic>>> membersFuture;

  @override
  void initState() {
    super.initState();
    membersFuture = AppData.members(widget.groupId);
    amount.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    concept.dispose();
    amount.dispose();
    note.dispose();
    for (final controller in customShares.values) {
      controller.dispose();
    }
    super.dispose();
  }

  double get amountValue => double.tryParse(amount.text.replaceAll(',', '.')) ?? 0;

  void initMembers(List<Map<String, dynamic>> members) {
    if (initialized || members.isEmpty) return;
    paidBy = members.any((m) => m['user_id']?.toString() == AppData.user?.id) ? AppData.user?.id : members.first['user_id'].toString();
    selected.addAll(members.map((m) => m['user_id'].toString()));
    for (final member in members) {
      final id = member['user_id'].toString();
      customShares[id] = TextEditingController();
    }
    initialized = true;
  }

  void setMode(String mode, List<Map<String, dynamic>> members) {
    setState(() {
      splitMode = mode;
      if (mode == 'all') {
        selected
          ..clear()
          ..addAll(members.map((m) => m['user_id'].toString()));
      }
      if (paidBy != null) selected.add(paidBy!);
      if (mode == 'custom') syncCustomShares(members);
    });
  }

  void syncCustomShares(List<Map<String, dynamic>> members) {
    final ids = selected.toList();
    final equal = ids.isEmpty ? 0.0 : amountValue / ids.length;
    for (final member in members) {
      final id = member['user_id'].toString();
      final controller = customShares.putIfAbsent(id, () => TextEditingController());
      if (selected.contains(id) && controller.text.trim().isEmpty) {
        controller.text = equal > 0 ? equal.toStringAsFixed(2).replaceAll('.', ',') : '';
      }
      if (!selected.contains(id)) controller.text = '';
    }
  }

  double customShareFor(String id) => double.tryParse((customShares[id]?.text ?? '').replaceAll(',', '.')) ?? 0;

  double customTotal() => selected.fold<double>(0, (sum, id) => sum + customShareFor(id));

  Map<String, double> sharesFor(List<Map<String, dynamic>> members) {
    if (splitMode == 'custom') {
      return {for (final id in selected) id: double.parse(customShareFor(id).toStringAsFixed(2))};
    }
    final share = selected.isEmpty ? 0.0 : amountValue / selected.length;
    return {for (final id in selected) id: double.parse(share.toStringAsFixed(2))};
  }

  Future<void> save(List<Map<String, dynamic>> members) async {
    final value = amountValue;
    if (concept.text.trim().isEmpty || value <= 0 || paidBy == null || selected.isEmpty) {
      await showToast(context, 'Completa concepto, importe, pagador y participantes.', danger: true);
      return;
    }
    if (splitMode == 'custom') {
      final total = customTotal();
      if ((total - value).abs() > .05) {
        await showToast(context, 'Los importes personalizados deben sumar ${money(value)}.', danger: true);
        return;
      }
    }
    setState(() => loading = true);
    try {
      await AppData.createExpenseWithShares(widget.groupId, concept.text, value, paidBy!, sharesFor(members), note.text);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      await showToast(context, e.toString(), danger: true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DirectPage(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeader(title: 'Nuevo gasto', subtitle: 'Como Tricount: claro, rápido y sin cuentas manuales', leading: true),
      const SizedBox(height: 18),
      AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 46, height: 46, decoration: BoxDecoration(color: AppColors.tealSoft, borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.receipt_long_rounded, color: AppColors.teal)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('¿Qué se ha pagado?', style: Theme.of(context).textTheme.titleMedium),
            Text('Elige quién pagó y cómo se reparte.', style: Theme.of(context).textTheme.bodyMedium),
          ])),
        ]),
        const SizedBox(height: 16),
        FieldLabel('Concepto'),
        TextField(controller: concept, decoration: const InputDecoration(hintText: 'Ej. Pista de pádel, cena, gasolina...')),
        const SizedBox(height: 12),
        FieldLabel('Importe total'),
        TextField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(hintText: '0,00 €')),
      ])),
      const SizedBox(height: 14),
      FutureBuilder<List<Map<String, dynamic>>>(
        future: membersFuture,
        builder: (context, snapshot) {
          final members = snapshot.data ?? [];
          initMembers(members);
          final value = amountValue;
          final equalShare = selected.isEmpty ? 0.0 : value / selected.length;
          final custom = customTotal();
          final diff = value - custom;
          if (snapshot.connectionState == ConnectionState.waiting) return const CenterLoader(label: 'Cargando miembros...');
          if (snapshot.hasError) return ErrorBlock(message: snapshot.error.toString(), onRetry: () => setState(() => membersFuture = AppData.members(widget.groupId)));
          if (members.isEmpty) return EmptyBlock(icon: Icons.groups_rounded, title: 'No hay miembros', body: 'Añade miembros al grupo para poder repartir gastos.');
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              FieldLabel('Pagado por'),
              DropdownButtonFormField<String>(
                value: paidBy,
                items: members.map((m) => DropdownMenuItem(value: m['user_id'].toString(), child: Text(memberName(m)))).toList(),
                onChanged: (v) => setState(() {
                  paidBy = v;
                  if (v != null) selected.add(v);
                  if (splitMode == 'custom') syncCustomShares(members);
                }),
              ),
            ])),
            const SizedBox(height: 14),
            AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              FieldLabel('Reparto'),
              Row(children: [
                Expanded(child: ChoicePill(label: 'Todos', active: splitMode == 'all', onTap: () => setMode('all', members))),
                const SizedBox(width: 8),
                Expanded(child: ChoicePill(label: 'Algunos', active: splitMode == 'some', onTap: () => setMode('some', members))),
                const SizedBox(width: 8),
                Expanded(child: ChoicePill(label: 'Manual', active: splitMode == 'custom', onTap: () => setMode('custom', members))),
              ]),
              const SizedBox(height: 12),
              Wrap(spacing: 9, runSpacing: 9, children: members.map((m) {
                final id = m['user_id'].toString();
                final active = selected.contains(id);
                return FilterChip(
                  label: Text(memberName(m)),
                  selected: active,
                  onSelected: (v) => setState(() {
                    if (splitMode == 'all') splitMode = 'some';
                    if (v) {
                      selected.add(id);
                    } else {
                      selected.remove(id);
                    }
                    if (paidBy != null) selected.add(paidBy!);
                    if (splitMode == 'custom') syncCustomShares(members);
                  }),
                );
              }).toList()),
              if (splitMode == 'custom') ...[
                const SizedBox(height: 14),
                FieldLabel('Importe por persona'),
                ...members.where((m) => selected.contains(m['user_id'].toString())).map((m) {
                  final id = m['user_id'].toString();
                  final controller = customShares.putIfAbsent(id, () => TextEditingController());
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(children: [
                      Expanded(child: Text(memberName(m), style: const TextStyle(fontWeight: FontWeight.w900))),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 108,
                        child: TextField(
                          controller: controller,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          textAlign: TextAlign.right,
                          decoration: const InputDecoration(hintText: '0,00'),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ]),
                  );
                }),
              ],
              const SizedBox(height: 12),
              FinanceSplitPreview(
                participants: selected.length,
                amount: value,
                equalShare: equalShare,
                customMode: splitMode == 'custom',
                customTotal: custom,
                diff: diff,
              ),
            ])),
          ]);
        },
      ),
      const SizedBox(height: 14),
      AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        FieldLabel('Nota opcional'),
        TextField(controller: note, maxLines: 3, decoration: const InputDecoration(hintText: 'Ej. Reserva incluida, se pagó con tarjeta...')),
      ])),
      const SizedBox(height: 24),
      FutureBuilder<List<Map<String, dynamic>>>(
        future: membersFuture,
        builder: (context, snapshot) {
          final members = snapshot.data ?? [];
          return PrimaryButton(label: 'Guardar gasto', loading: loading, onTap: () => save(members));
        },
      ),
    ]));
  }
}

class ExpenseDetailScreen extends StatefulWidget {
  final Map<String, dynamic> expense;
  final List<Map<String, dynamic>> members;
  const ExpenseDetailScreen({super.key, required this.expense, required this.members});

  @override
  State<ExpenseDetailScreen> createState() => _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends State<ExpenseDetailScreen> {
  bool loading = false;

  Future<void> run(Future<void> Function() action) async {
    setState(() => loading = true);
    try {
      await action();
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      await showToast(context, e.toString(), danger: true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final expense = widget.expense;
    final expenseId = expense['id'].toString();
    final paidBy = AppData.text(expense['paid_by']);
    final participants = expenseParticipants(expense);
    final total = AppData.doubleValue(expense['amount']);
    final unpaid = unpaidAmount(expense);
    final status = AppData.text(expense['status'], 'pending');
    return DirectPage(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeader(title: AppData.text(expense['concept'], 'Gasto'), subtitle: 'Detalle y pagos', leading: true),
      const SizedBox(height: 18),
      AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const CircleAvatar(backgroundColor: AppColors.teal, child: Icon(Icons.receipt_long_rounded, color: Colors.white)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(money(total), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: AppColors.ink)),
            Text('Pagado por ${financeMemberName(paidBy, widget.members)}', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700)),
          ])),
          _MiniChip(text: status == 'paid' || unpaid <= .01 ? 'Liquidado' : 'Pendiente', color: status == 'paid' || unpaid <= .01 ? AppColors.green : AppColors.orange),
        ]),
        if (AppData.text(expense['note']).isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(AppData.text(expense['note']), style: Theme.of(context).textTheme.bodyMedium),
        ],
      ])),
      const SizedBox(height: 18),
      SectionHeader(title: 'Participantes y pagos'),
      const SizedBox(height: 8),
      AppCard(child: Column(children: participants.map((p) {
        final userId = p['user_id'].toString();
        final paid = p['paid'] == true;
        final share = AppData.doubleValue(p['share_amount']);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(children: [
            CircleAvatar(radius: 17, backgroundColor: AppColors.tealSoft, child: Text(financeMemberName(userId, widget.members).substring(0, 1).toUpperCase(), style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.w900))),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(financeMemberName(userId, widget.members), style: const TextStyle(fontWeight: FontWeight.w900)),
              Text(userId == paidBy ? 'Pagó el gasto' : paid ? 'Pago registrado' : 'Pendiente de pagar', style: TextStyle(color: paid ? AppColors.green : AppColors.muted, fontSize: 12)),
            ])),
            Text(money(share.toDouble()), style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(width: 8),
            userId == paidBy
                ? const Icon(Icons.payments_rounded, color: AppColors.teal)
                : IconButton(
                    tooltip: paid ? 'Marcar pendiente' : 'Marcar pagado',
                    onPressed: loading ? null : () => run(() => AppData.setExpenseParticipantPaid(expenseId, userId, !paid)),
                    icon: Icon(paid ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, color: paid ? AppColors.green : AppColors.muted),
                  ),
          ]),
        );
      }).toList())),
      const SizedBox(height: 18),
      if (unpaid > .01) PrimaryButton(label: 'Marcar gasto liquidado', icon: Icons.verified_rounded, loading: loading, onTap: () => run(() => AppData.markExpenseSettled(expenseId))),
      if (unpaid <= .01 || status == 'paid') ...[
        SecondaryButton(label: 'Reabrir pagos', icon: Icons.restart_alt_rounded, onTap: () => run(() => AppData.reopenExpense(expenseId))),
      ],
      const SizedBox(height: 10),
      DangerButton(label: 'Eliminar gasto', icon: Icons.delete_outline_rounded, onTap: () => run(() => AppData.deleteExpense(expenseId))),
    ]));
  }
}

class FinanceHeroCard extends StatelessWidget {
  final FinanceSummary summary;
  final VoidCallback onCreate;
  const FinanceHeroCard({super.key, required this.summary, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final color = summary.pendingAmount <= .01 ? AppColors.green : summary.myNet < -0.01 ? AppColors.red : AppColors.teal;
    final icon = summary.pendingAmount <= .01
        ? Icons.verified_rounded
        : summary.myNet < -0.01
            ? Icons.outbound_rounded
            : Icons.savings_rounded;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(colors: [color, Color.lerp(color, AppColors.ink, .18)!], begin: Alignment.topLeft, end: Alignment.bottomRight),
        boxShadow: [BoxShadow(color: color.withOpacity(.18), blurRadius: 22, offset: const Offset(0, 12))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 48, height: 48, decoration: BoxDecoration(color: Colors.white.withOpacity(.18), borderRadius: BorderRadius.circular(17)), child: Icon(icon, color: Colors.white, size: 26)),
            const SizedBox(width: 13),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_financeMainTitle(summary), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, height: 1.05, letterSpacing: -0.5)),
              const SizedBox(height: 7),
              Text(_financeMainSubtitle(summary), style: const TextStyle(color: Color(0xEFFFFFFF), fontSize: 13, fontWeight: FontWeight.w700, height: 1.35)),
            ])),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _HeroFinanceMetric(label: 'Tu saldo', value: money(summary.myNet))),
            const SizedBox(width: 10),
            Expanded(child: _HeroFinanceMetric(label: 'Pendiente', value: money(summary.pendingAmount))),
          ]),
          const SizedBox(height: 14),
          WhiteButton(label: 'Añadir gasto', onTap: onCreate),
        ]),
      ),
    );
  }
}

class _HeroFinanceMetric extends StatelessWidget {
  final String label;
  final String value;
  const _HeroFinanceMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: Colors.white.withOpacity(.14), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(.14))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: Color(0xDFFFFFFF), fontSize: 11, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
      ]),
    );
  }
}

class FinanceMiniMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const FinanceMiniMetric({super.key, required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      color: AppColors.surface,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 30, height: 30, decoration: BoxDecoration(color: color.withOpacity(.12), shape: BoxShape.circle), child: Icon(icon, size: 17, color: color)),
        const SizedBox(height: 7),
        Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink, fontSize: 14)),
        const SizedBox(height: 2),
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.muted, fontSize: 10.5)),
      ]),
    );
  }
}

class SettlementPaymentRow extends StatelessWidget {
  final SettlementDebt debt;
  const SettlementPaymentRow({super.key, required this.debt});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(children: [
        Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.tealSoft, borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.swap_horiz_rounded, color: AppColors.teal, size: 20)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${debt.fromName} paga a ${debt.toName}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink)),
          const SizedBox(height: 2),
          const Text('Pago recomendado para cuadrar el grupo', style: TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w700)),
        ])),
        const SizedBox(width: 8),
        Text(money(debt.amount), style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.w900, fontSize: 15)),
      ]),
    );
  }
}

class FinanceSplitPreview extends StatelessWidget {
  final int participants;
  final double amount;
  final double equalShare;
  final bool customMode;
  final double customTotal;
  final double diff;
  const FinanceSplitPreview({super.key, required this.participants, required this.amount, required this.equalShare, required this.customMode, required this.customTotal, required this.diff});

  @override
  Widget build(BuildContext context) {
    final ok = !customMode || diff.abs() <= .05;
    final color = ok ? AppColors.teal : AppColors.red;
    final text = participants == 0
        ? 'Elige al menos un participante.'
        : customMode
            ? (ok ? 'Reparto manual equilibrado · total ${money(customTotal)}' : 'Faltan/sobran ${money(diff.abs())} para cuadrar el total')
            : '$participants participantes · cada uno debe ${money(equalShare)}';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color.withOpacity(.10), borderRadius: BorderRadius.circular(15), border: Border.all(color: color.withOpacity(.18))),
      child: Row(children: [
        Icon(ok ? Icons.calculate_rounded : Icons.warning_amber_rounded, color: color),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink))),
      ]),
    );
  }
}

class _FinanceData {
  final List<Map<String, dynamic>> expenses;
  final List<Map<String, dynamic>> members;
  late final FinanceSummary summary;

  _FinanceData({required this.expenses, required this.members}) {
    summary = FinanceSummary.from(expenses, members);
  }

  static _FinanceData empty() => _FinanceData(expenses: const [], members: const []);

  static Future<_FinanceData> load(String groupId) async {
    final results = await Future.wait([AppData.expenses(groupId), AppData.members(groupId)]);
    return _FinanceData(expenses: results[0], members: results[1]);
  }
}

class FinanceSummary {
  final Map<String, String> names;
  final Map<String, double> balances;
  final List<SettlementDebt> settlements;
  final double totalExpenses;
  final double pendingAmount;
  final double myNet;

  FinanceSummary({required this.names, required this.balances, required this.settlements, required this.totalExpenses, required this.pendingAmount, required this.myNet});

  factory FinanceSummary.from(List<Map<String, dynamic>> expenses, List<Map<String, dynamic>> members) {
    final names = <String, String>{};
    final balances = <String, double>{};
    for (final m in members) {
      final id = m['user_id']?.toString() ?? '';
      if (id.isEmpty) continue;
      names[id] = memberName(m);
      balances[id] = 0;
    }

    double total = 0;
    double pending = 0;
    for (final e in expenses) {
      if (AppData.text(e['status']) == 'cancelled') continue;
      total += AppData.doubleValue(e['amount']);
      final paidBy = e['paid_by']?.toString() ?? '';
      names.putIfAbsent(paidBy, () => financeMemberName(paidBy, members));
      balances.putIfAbsent(paidBy, () => 0);
      for (final p in expenseParticipants(e)) {
        final userId = p['user_id']?.toString() ?? '';
        if (userId.isEmpty || userId == paidBy) continue;
        final share = AppData.doubleValue(p['share_amount']);
        final alreadyPaid = p['paid'] == true;
        names.putIfAbsent(userId, () => financeMemberName(userId, members));
        balances.putIfAbsent(userId, () => 0);
        if (!alreadyPaid) {
          balances[paidBy] = (balances[paidBy] ?? 0) + share;
          balances[userId] = (balances[userId] ?? 0) - share;
          pending += share;
        }
      }
    }

    final settlements = buildSettlements(balances, names);
    final myId = AppData.user?.id ?? '';
    return FinanceSummary(names: names, balances: balances, settlements: settlements, totalExpenses: total, pendingAmount: pending, myNet: balances[myId] ?? 0);
  }
}

class SettlementDebt {
  final String fromId;
  final String toId;
  final String fromName;
  final String toName;
  final double amount;
  const SettlementDebt({required this.fromId, required this.toId, required this.fromName, required this.toName, required this.amount});
}

List<SettlementDebt> buildSettlements(Map<String, double> balances, Map<String, String> names) {
  final debtors = balances.entries.where((e) => e.value < -0.01).map((e) => MapEntry(e.key, -e.value)).toList();
  final creditors = balances.entries.where((e) => e.value > 0.01).map((e) => MapEntry(e.key, e.value)).toList();
  debtors.sort((a, b) => b.value.compareTo(a.value));
  creditors.sort((a, b) => b.value.compareTo(a.value));
  final result = <SettlementDebt>[];
  var i = 0;
  var j = 0;
  while (i < debtors.length && j < creditors.length) {
    final amount = min(debtors[i].value, creditors[j].value);
    if (amount > 0.01) {
      result.add(SettlementDebt(
        fromId: debtors[i].key,
        toId: creditors[j].key,
        fromName: names[debtors[i].key] ?? 'Miembro',
        toName: names[creditors[j].key] ?? 'Miembro',
        amount: double.parse(amount.toStringAsFixed(2)),
      ));
    }
    debtors[i] = MapEntry(debtors[i].key, debtors[i].value - amount);
    creditors[j] = MapEntry(creditors[j].key, creditors[j].value - amount);
    if (debtors[i].value <= 0.01) i++;
    if (creditors[j].value <= 0.01) j++;
  }
  return result;
}

List<Map<String, dynamic>> expenseParticipants(Map<String, dynamic> expense) {
  final raw = expense['expense_participants'];
  if (raw is! List) return [];
  return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
}

double unpaidAmount(Map<String, dynamic> expense) {
  final paidBy = expense['paid_by']?.toString();
  return expenseParticipants(expense).fold<double>(0, (sum, p) {
    if (p['user_id']?.toString() == paidBy) return sum;
    return p['paid'] == true ? sum : sum + AppData.doubleValue(p['share_amount']);
  });
}

String financeMemberName(String userId, List<Map<String, dynamic>> members) {
  for (final m in members) {
    if (m['user_id']?.toString() == userId) return memberName(m);
  }
  return userId == AppData.user?.id ? 'Tú' : 'Miembro';
}

String _financeMainTitle(FinanceSummary summary) {
  if (summary.pendingAmount <= 0.01) return 'Todo está cuadrado';
  if (summary.myNet > 0.01) return 'Te deben ${money(summary.myNet)}';
  if (summary.myNet < -0.01) return 'Debes ${money(-summary.myNet)}';
  return 'Hay pagos pendientes';
}

String _financeMainSubtitle(FinanceSummary summary) {
  if (summary.pendingAmount <= 0.01) return 'No hay deudas abiertas en este grupo.';
  return 'Con ${summary.settlements.length} pago${summary.settlements.length == 1 ? '' : 's'} se puede dejar el grupo a cero.';
}

class SettlementRow extends StatelessWidget {
  final SettlementDebt debt;
  const SettlementRow({super.key, required this.debt});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(children: [
      Expanded(child: Text('${debt.fromName} paga a ${debt.toName}', style: const TextStyle(fontWeight: FontWeight.w900))),
      Text(money(debt.amount), style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.w900)),
    ]),
  );
}

class BalanceRow extends StatelessWidget {
  final String name;
  final double value;
  const BalanceRow({super.key, required this.name, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(children: [
      CircleAvatar(radius: 15, backgroundColor: value >= 0 ? AppColors.tealSoft : const Color(0xFFFFECEC), child: Text(name.substring(0, 1).toUpperCase(), style: TextStyle(color: value >= 0 ? AppColors.teal : AppColors.red, fontWeight: FontWeight.w900))),
      const SizedBox(width: 10),
      Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w900))),
      Text(money(value), style: TextStyle(color: value >= 0 ? AppColors.green : AppColors.red, fontWeight: FontWeight.w900)),
    ]),
  );
}

class ChoicePill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const ChoicePill({super.key, required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: Container(
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: active ? AppColors.teal : Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: active ? AppColors.teal : AppColors.line)),
      child: Text(label, style: TextStyle(color: active ? Colors.white : AppColors.ink, fontWeight: FontWeight.w900)),
    ),
  );
}

class TournamentsTab extends StatefulWidget {
  final Map<String, dynamic> group;
  final int refreshSeed;
  const TournamentsTab({super.key, required this.group, required this.refreshSeed});

  @override
  State<TournamentsTab> createState() => _TournamentsTabState();
}

class _TournamentsTabState extends State<TournamentsTab> {
  late Future<List<Map<String, dynamic>>> future;

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void didUpdateWidget(covariant TournamentsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshSeed != widget.refreshSeed) load();
  }

  void load() => future = AppData.tournaments(widget.group['id'].toString());
  void reload() => setState(load);

  Future<void> openCreate() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => CreateTournamentScreen(group: widget.group)),
    );
    if (created == true) reload();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          FutureBuilder<List<Map<String, dynamic>>>(
            future: future,
            builder: (context, snapshot) {
              final tournaments = snapshot.data ?? [];
              final active = tournaments.where((t) => AppData.text(t['status']) != 'finished').length;
              final finished = tournaments.where((t) => AppData.text(t['status']) == 'finished').length;

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                children: [
                  PageHeader(
                    title: 'Torneos / Ligas',
                    subtitle: 'Competiciones de ${AppData.text(widget.group['name'], 'tu grupo')}',
                    leading: false,
                  ),
                  const SizedBox(height: 16),
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(color: AppColors.tealSoft, borderRadius: BorderRadius.circular(17)),
                          child: const Icon(Icons.emoji_events_rounded, color: AppColors.teal, size: 31),
                        ),
                        const SizedBox(width: 13),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Crea una competición sin líos', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 3),
                          Text('Elige formato, añade participantes, genera partidos y registra resultados con clasificación automática.', style: Theme.of(context).textTheme.bodyMedium),
                        ])),
                      ]),
                      const SizedBox(height: 14),
                      Row(children: [
                        Expanded(child: StatCard(icon: Icons.play_circle_outline_rounded, value: active.toString(), label: 'Activos', color: AppColors.teal)),
                        const SizedBox(width: 10),
                        Expanded(child: StatCard(icon: Icons.flag_circle_rounded, value: finished.toString(), label: 'Finalizados', color: AppColors.violet)),
                      ]),
                    ]),
                  ),
                  const SizedBox(height: 18),
                  Row(children: [
                    Text('Tus competiciones', style: Theme.of(context).textTheme.titleLarge),
                    const Spacer(),
                    TextButton.icon(onPressed: openCreate, icon: const Icon(Icons.add_rounded), label: const Text('Crear')),
                  ]),
                  const SizedBox(height: 8),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const CenterLoader(label: 'Cargando torneos...')
                  else if (snapshot.hasError)
                    ErrorBlock(message: snapshot.error.toString(), onRetry: reload)
                  else if (tournaments.isEmpty)
                    AppCard(
                      padding: const EdgeInsets.all(18),
                      child: Column(children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(color: AppColors.tealSoft, borderRadius: BorderRadius.circular(22)),
                          child: const Icon(Icons.emoji_events_rounded, color: AppColors.teal, size: 36),
                        ),
                        const SizedBox(height: 14),
                        Text('Aún no hay ligas ni torneos', style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
                        const SizedBox(height: 6),
                        Text('Empieza con una liga todos contra todos, una copa eliminatoria o un formato americano para pádel/tenis.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 16),
                        PrimaryButton(label: 'Crear competición', icon: Icons.add_rounded, onTap: openCreate),
                      ]),
                    )
                  else
                    ...tournaments.map((t) => TournamentCard(
                      tournament: t,
                      onTap: () async {
                        await Navigator.of(context).push(MaterialPageRoute(builder: (_) => TournamentDetailScreen(tournamentId: t['id'].toString(), group: widget.group)));
                        reload();
                      },
                    )),
                ],
              );
            },
          ),
          Positioned(
            right: 20,
            bottom: 20,
            child: FloatingActionButton(
              heroTag: 'create_tournament',
              backgroundColor: AppColors.teal,
              foregroundColor: Colors.white,
              onPressed: openCreate,
              child: const Icon(Icons.add_rounded),
            ),
          ),
        ],
      ),
    );
  }
}

class CreateTournamentScreen extends StatefulWidget {
  final Map<String, dynamic> group;
  const CreateTournamentScreen({super.key, required this.group});

  @override
  State<CreateTournamentScreen> createState() => _CreateTournamentScreenState();
}

class _CreateTournamentScreenState extends State<CreateTournamentScreen> {
  final name = TextEditingController();
  String format = 'liga';
  String teamType = 'pareja';
  bool loading = false;

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  Future<void> create() async {
    if (name.text.trim().length < 2) {
      await showToast(context, 'Pon un nombre para la competición.', danger: true);
      return;
    }

    setState(() => loading = true);
    try {
      final id = await AppData.createTournament(
        widget.group['id'].toString(),
        name.text,
        format: format,
        teamType: teamType,
      );
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => TournamentDetailScreen(tournamentId: id, group: widget.group),
      ));
    } catch (e) {
      await showToast(context, e.toString(), danger: true);
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DirectPage(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        PageHeader(title: 'Nueva competición', subtitle: AppData.text(widget.group['name']), leading: true),
        const SizedBox(height: 20),
        FieldLabel('Nombre'),
        TextField(controller: name, textInputAction: TextInputAction.next, decoration: const InputDecoration(hintText: 'Ej. Liga de pádel de los jueves')),
        const SizedBox(height: 22),
        Text('Formato', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        TournamentFormatOption(
          selected: format == 'liga',
          icon: Icons.table_chart_rounded,
          title: 'Liga todos contra todos',
          body: 'Ideal para grupos estables. Todos juegan contra todos y se calcula la clasificación.',
          onTap: () => setState(() => format = 'liga'),
        ),
        TournamentFormatOption(
          selected: format == 'eliminatoria',
          icon: Icons.account_tree_rounded,
          title: 'Eliminatoria / Copa',
          body: 'Rondas directas. Perfecta para torneos rápidos con semifinal y final.',
          onTap: () => setState(() => format = 'eliminatoria'),
        ),
        TournamentFormatOption(
          selected: format == 'americano',
          icon: Icons.sync_alt_rounded,
          title: 'Americano / Ranking',
          body: 'Pensado para rotaciones de pádel, tenis o juegos donde importa sumar resultados.',
          onTap: () => setState(() => format = 'americano'),
        ),
        const SizedBox(height: 18),
        Text('Participantes', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: PickPill(label: 'Individual', selected: teamType == 'individual', onTap: () => setState(() => teamType = 'individual'))),
          const SizedBox(width: 8),
          Expanded(child: PickPill(label: 'Parejas', selected: teamType == 'pareja', onTap: () => setState(() => teamType = 'pareja'))),
          const SizedBox(width: 8),
          Expanded(child: PickPill(label: 'Equipos', selected: teamType == 'equipo', onTap: () => setState(() => teamType = 'equipo'))),
        ]),
        const SizedBox(height: 16),
        StatusNotice(
          ok: true,
          text: 'Después añadirás participantes y la app generará el calendario de partidos automáticamente.',
        ),
        const SizedBox(height: 22),
        PrimaryButton(label: 'Crear competición', icon: Icons.emoji_events_rounded, loading: loading, onTap: create),
      ]),
    );
  }
}

class TournamentDetailScreen extends StatefulWidget {
  final String tournamentId;
  final Map<String, dynamic> group;
  const TournamentDetailScreen({super.key, required this.tournamentId, required this.group});

  @override
  State<TournamentDetailScreen> createState() => _TournamentDetailScreenState();
}

class _TournamentDetailScreenState extends State<TournamentDetailScreen> {
  late Future<Map<String, dynamic>> future;
  int section = 0;

  @override
  void initState() {
    super.initState();
    reload();
  }

  void reload() => setState(() => future = AppData.tournament(widget.tournamentId));

  Future<void> addParticipant() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Añadir participante'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'Ej. Ana y Javi / Equipo azul',
            helperText: 'Puede ser jugador, pareja o equipo.',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Añadir')),
        ],
      ),
    );
    controller.dispose();
    if (result == null || result.trim().length < 2) return;
    try {
      await AppData.addTournamentTeam(widget.tournamentId, result);
      reload();
    } catch (e) {
      await showToast(context, e.toString(), danger: true);
    }
  }

  Future<void> addGroupMembers(List<Map<String, dynamic>> currentTeams) async {
    try {
      final members = await AppData.members(widget.group['id'].toString());
      final existing = currentTeams
          .map((team) => AppData.text(team['name']).trim().toLowerCase())
          .where((name) => name.isNotEmpty)
          .toSet();
      final names = members
          .map(memberDisplayName)
          .where((name) => name.trim().length >= 2)
          .where((name) => !existing.contains(name.trim().toLowerCase()))
          .toList();

      if (names.isEmpty) {
        await showToast(context, 'No hay miembros nuevos para añadir.');
        return;
      }

      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Añadir miembros del grupo'),
          content: Text('Se añadirán ${names.length} miembros como participantes. Después podrás renombrarlos si quieres usar parejas o equipos.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Añadir')),
          ],
        ),
      );
      if (ok != true) return;

      final added = await AppData.addTournamentTeams(widget.tournamentId, names);
      reload();
      if (mounted) await showToast(context, '$added participantes añadidos.');
    } catch (e) {
      await showToast(context, e.toString(), danger: true);
    }
  }

  Future<void> generate(Map<String, dynamic> tournament) async {
    final teams = tournamentTeams(tournament);
    final existingMatches = tournamentMatches(tournament);

    if (existingMatches.isNotEmpty) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Regenerar partidos'),
          content: const Text('Se borrarán los partidos y resultados actuales para crear un calendario nuevo con los participantes actuales.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Regenerar')),
          ],
        ),
      );
      if (ok != true) return;
    }

    try {
      await AppData.generateMatches(widget.tournamentId, AppData.text(tournament['format'], 'liga'), teams);
      reload();
      if (mounted) await showToast(context, existingMatches.isEmpty ? 'Partidos generados.' : 'Partidos regenerados.');
    } catch (e) {
      await showToast(context, e.toString(), danger: true);
    }
  }

  Future<void> generateNext(Map<String, dynamic> tournament) async {
    try {
      await AppData.generateNextEliminationRound(widget.tournamentId, tournamentMatches(tournament));
      reload();
      if (mounted) await showToast(context, 'Siguiente ronda generada.');
    } catch (e) {
      await showToast(context, e.toString(), danger: true);
    }
  }

  Future<void> finish(String status) async {
    try {
      await AppData.updateTournamentStatus(widget.tournamentId, status);
      reload();
    } catch (e) {
      await showToast(context, e.toString(), danger: true);
    }
  }

  Future<void> removeTournament() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar competición'),
        content: const Text('Se borrarán participantes, partidos y resultados. Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await AppData.deleteTournament(widget.tournamentId);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      await showToast(context, e.toString(), danger: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DirectPage(
      padding: EdgeInsets.zero,
      child: FutureBuilder<Map<String, dynamic>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(padding: EdgeInsets.all(22), child: CenterLoader(label: 'Cargando competición...'));
          }
          if (snapshot.hasError) {
            return Padding(padding: const EdgeInsets.all(22), child: ErrorBlock(message: snapshot.error.toString(), onRetry: reload));
          }

          final tournament = snapshot.data ?? {};
          final teams = tournamentTeams(tournament);
          final matches = tournamentMatches(tournament);
          final format = AppData.text(tournament['format'], 'liga');
          final status = AppData.text(tournament['status'], 'active');
          final played = matches.where((m) => AppData.text(m['status']) == 'played').length;
          final pending = matches.length - played;
          final standings = calculateStandings(teams, matches);

          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF009E91), Color(0xFF006B69)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    RoundBackButton(onTap: () => Navigator.pop(context)),
                    const Spacer(),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_horiz_rounded, color: Colors.white),
                      onSelected: (value) {
                        if (value == 'regenerate') generate(tournament);
                        if (value == 'finish') finish('finished');
                        if (value == 'reopen') finish('active');
                        if (value == 'delete') removeTournament();
                      },
                      itemBuilder: (_) => [
                        if (teams.length >= 2) const PopupMenuItem(value: 'regenerate', child: Text('Regenerar partidos')),
                        if (status != 'finished') const PopupMenuItem(value: 'finish', child: Text('Marcar como finalizada')),
                        if (status == 'finished') const PopupMenuItem(value: 'reopen', child: Text('Reabrir competición')),
                        const PopupMenuItem(value: 'delete', child: Text('Eliminar competición')),
                      ],
                    ),
                  ]),
                  const SizedBox(height: 18),
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(.17), borderRadius: BorderRadius.circular(19)),
                    child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 36),
                  ),
                  const SizedBox(height: 14),
                  Text(AppData.text(tournament['name'], 'Competición'), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, height: 1.05)),
                  const SizedBox(height: 7),
                  Text('${tournamentFormatLabel(format)} · ${teamTypeLabel(AppData.text(tournament['team_type'], 'equipo'))} · ${status == 'finished' ? 'Finalizada' : 'En curso'}', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w800)),
                ]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _TournamentNextStepCard(
                  tournament: tournament,
                  teams: teams,
                  matches: matches,
                  onAddTeam: addParticipant,
                  onAddGroupMembers: () => addGroupMembers(teams),
                  onGenerate: () => generate(tournament),
                  onGenerateNext: () => generateNext(tournament),
                ),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: StatCard(icon: Icons.groups_rounded, value: teams.length.toString(), label: 'Participantes', color: AppColors.teal)),
                  const SizedBox(width: 10),
                  Expanded(child: StatCard(icon: Icons.sports_score_rounded, value: matches.length.toString(), label: 'Partidos', color: AppColors.violet)),
                  const SizedBox(width: 10),
                  Expanded(child: StatCard(icon: Icons.check_circle_rounded, value: '$played/$pending', label: 'Jug./Pend.', color: AppColors.orange)),
                ]),
                const SizedBox(height: 16),
                _TournamentSegment(index: section, onChanged: (i) => setState(() => section = i)),
                const SizedBox(height: 16),
                if (section == 0)
                  _TournamentSummarySection(
                    tournament: tournament,
                    standings: standings,
                    teams: teams,
                    matches: matches,
                    onAddTeam: addParticipant,
                    onAddGroupMembers: () => addGroupMembers(teams),
                    onGenerate: () => generate(tournament),
                  )
                else if (section == 1)
                  _TournamentStandingsSection(standings: standings, format: format)
                else if (section == 2)
                  _TournamentMatchesSection(
                    matches: matches,
                    teams: teams,
                    onResultChanged: reload,
                  )
                else
                  _TournamentTeamsSection(
                    teams: teams,
                    matches: matches,
                    onAddTeam: addParticipant,
                    onAddGroupMembers: () => addGroupMembers(teams),
                    onDeleted: reload,
                  ),
              ]),
            ),
          ]);
        },
      ),
    );
  }
}

class _TournamentNextStepCard extends StatelessWidget {
  final Map<String, dynamic> tournament;
  final List<Map<String, dynamic>> teams;
  final List<Map<String, dynamic>> matches;
  final VoidCallback onAddTeam;
  final VoidCallback onAddGroupMembers;
  final VoidCallback onGenerate;
  final VoidCallback onGenerateNext;

  const _TournamentNextStepCard({
    required this.tournament,
    required this.teams,
    required this.matches,
    required this.onAddTeam,
    required this.onAddGroupMembers,
    required this.onGenerate,
    required this.onGenerateNext,
  });

  @override
  Widget build(BuildContext context) {
    final format = AppData.text(tournament['format'], 'liga');
    final played = matches.where((m) => AppData.text(m['status']) == 'played').length;
    final pending = matches.where((m) => AppData.text(m['status']) != 'played').length;
    final latestRound = matches.fold<int>(0, (maxRound, m) => max(maxRound, AppData.intValue(m['round'])));
    final latestRoundMatches = matches.where((m) => AppData.intValue(m['round']) == latestRound).toList();
    final latestRoundPlayed = latestRoundMatches.isNotEmpty && latestRoundMatches.every((m) => AppData.text(m['status']) == 'played');

    IconData icon = Icons.checklist_rounded;
    String title = 'Siguiente paso';
    String body = 'Todo listo.';
    String action = '';
    VoidCallback? onTap;

    if (teams.length < 2) {
      icon = Icons.group_add_rounded;
      title = 'Añade participantes';
      body = 'Crea los jugadores, parejas o equipos que van a competir.';
      action = 'Añadir';
      onTap = onAddTeam;
    } else if (matches.isEmpty) {
      icon = Icons.auto_awesome_motion_rounded;
      title = 'Genera el calendario';
      body = format == 'eliminatoria'
          ? 'Crearemos el primer cuadro de eliminatoria con los participantes actuales.'
          : 'Crearemos todos los enfrentamientos automáticamente.';
      action = 'Generar partidos';
      onTap = onGenerate;
    } else if (pending > 0) {
      icon = Icons.edit_note_rounded;
      title = 'Registra resultados';
      body = 'Hay $pending partidos pendientes. Al guardar resultados se actualiza la clasificación.';
    } else if (format == 'eliminatoria' && latestRoundMatches.length > 1 && latestRoundPlayed) {
      icon = Icons.account_tree_rounded;
      title = 'Genera la siguiente ronda';
      body = 'La ronda $latestRound está completa. Crea la siguiente ronda con los ganadores.';
      action = 'Siguiente ronda';
      onTap = onGenerateNext;
    } else {
      icon = Icons.emoji_events_rounded;
      title = 'Competición completa';
      body = 'Todos los partidos están jugados. Puedes marcarla como finalizada desde el menú superior.';
    }

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 48, height: 48, decoration: BoxDecoration(color: AppColors.tealSoft, borderRadius: BorderRadius.circular(15)), child: Icon(icon, color: AppColors.teal)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(body, style: Theme.of(context).textTheme.bodyMedium),
          if (played > 0) ...[
            const SizedBox(height: 8),
            Text('$played resultados registrados', style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.w900, fontSize: 12)),
          ],
        ])),
        if (teams.length < 2)
          Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
            TextButton(onPressed: onAddTeam, child: const Text('Añadir', style: TextStyle(fontWeight: FontWeight.w900))),
            TextButton(onPressed: onAddGroupMembers, child: const Text('Usar miembros', style: TextStyle(fontWeight: FontWeight.w900))),
          ])
        else if (onTap != null && action.isNotEmpty)
          TextButton(onPressed: onTap, child: Text(action, style: const TextStyle(fontWeight: FontWeight.w900))),
      ]),
    );
  }
}

class _TournamentSegment extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  const _TournamentSegment({required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final labels = ['Resumen', 'Tabla', 'Partidos', 'Participantes'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.faint, borderRadius: BorderRadius.circular(15), border: Border.all(color: AppColors.line)),
      child: Row(children: List.generate(labels.length, (i) {
        final selected = index == i;
        return Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(13),
            onTap: () => onChanged(i),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(color: selected ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(13), boxShadow: selected ? [BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 12, offset: const Offset(0, 5))] : null),
              child: Text(labels[i], textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: selected ? AppColors.ink : AppColors.muted)),
            ),
          ),
        );
      })),
    );
  }
}

class _TournamentSummarySection extends StatelessWidget {
  final Map<String, dynamic> tournament;
  final List<TeamStanding> standings;
  final List<Map<String, dynamic>> teams;
  final List<Map<String, dynamic>> matches;
  final VoidCallback onAddTeam;
  final VoidCallback onAddGroupMembers;
  final VoidCallback onGenerate;

  const _TournamentSummarySection({
    required this.tournament,
    required this.standings,
    required this.teams,
    required this.matches,
    required this.onAddTeam,
    required this.onAddGroupMembers,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    final format = AppData.text(tournament['format'], 'liga');
    final names = teamNameMap(teams);
    final pending = matches.where((m) => AppData.text(m['status']) != 'played').take(3).toList();
    final top = standings.take(3).toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionHeader(title: 'Cómo funciona', action: tournamentFormatLabel(format)),
      AppCard(
        padding: const EdgeInsets.all(16),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.info_rounded, color: AppColors.teal),
          const SizedBox(width: 12),
          Expanded(child: Text(tournamentFormatSubtitle(format), style: Theme.of(context).textTheme.bodyMedium)),
        ]),
      ),
      const SizedBox(height: 16),
      SectionHeader(title: 'Próximos partidos', action: pending.isEmpty ? '' : '${pending.length} pendientes'),
      if (pending.isEmpty)
        EmptySlim(icon: Icons.sports_score_rounded, title: 'Sin partidos pendientes')
      else
        ...pending.map((m) => MatchCompactCard(match: m, names: names)),
      const SizedBox(height: 16),
      SectionHeader(title: 'Top clasificación'),
      if (top.isEmpty)
        EmptySlim(icon: Icons.leaderboard_rounded, title: 'Añade participantes para ver la tabla')
      else
        ...top.asMap().entries.map((entry) => StandingRow(position: entry.key + 1, standing: entry.value)),
      const SizedBox(height: 14),
      if (teams.length < 2) ...[
        PrimaryButton(label: 'Añadir participante', icon: Icons.group_add_rounded, onTap: onAddTeam),
        const SizedBox(height: 10),
        SecondaryButton(label: 'Añadir miembros del grupo', icon: Icons.groups_rounded, onTap: onAddGroupMembers),
      ] else if (matches.isEmpty)
        PrimaryButton(label: 'Generar partidos', icon: Icons.auto_awesome_motion_rounded, onTap: onGenerate),
    ]);
  }
}

class _TournamentStandingsSection extends StatelessWidget {
  final List<TeamStanding> standings;
  final String format;
  const _TournamentStandingsSection({required this.standings, required this.format});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionHeader(title: format == 'eliminatoria' ? 'Rendimiento' : 'Clasificación', action: 'PTS · DG · PJ'),
      if (standings.isEmpty)
        EmptyBlock(icon: Icons.leaderboard_rounded, title: 'Sin clasificación', body: 'Añade participantes y registra resultados para calcular la tabla.')
      else
        ...standings.asMap().entries.map((entry) => StandingRow(position: entry.key + 1, standing: entry.value, detailed: true)),
    ]);
  }
}

class _TournamentMatchesSection extends StatelessWidget {
  final List<Map<String, dynamic>> matches;
  final List<Map<String, dynamic>> teams;
  final VoidCallback onResultChanged;
  const _TournamentMatchesSection({required this.matches, required this.teams, required this.onResultChanged});

  @override
  Widget build(BuildContext context) {
    final names = teamNameMap(teams);
    if (matches.isEmpty) {
      return EmptyBlock(icon: Icons.sports_score_rounded, title: 'Sin partidos', body: 'Cuando generes partidos aparecerán aquí por rondas.');
    }

    final rounds = <int, List<Map<String, dynamic>>>{};
    for (final match in matches) {
      final round = AppData.intValue(match['round'], 1);
      rounds.putIfAbsent(round, () => []).add(match);
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ...rounds.entries.map((entry) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SectionHeader(title: 'Ronda ${entry.key}', action: '${entry.value.length} partidos'),
        ...entry.value.map((m) => MatchResultCard(match: m, names: names, onChanged: onResultChanged)),
        const SizedBox(height: 8),
      ])),
    ]);
  }
}

class _TournamentTeamsSection extends StatelessWidget {
  final List<Map<String, dynamic>> teams;
  final List<Map<String, dynamic>> matches;
  final VoidCallback onAddTeam;
  final VoidCallback onAddGroupMembers;
  final VoidCallback onDeleted;
  const _TournamentTeamsSection({required this.teams, required this.matches, required this.onAddTeam, required this.onAddGroupMembers, required this.onDeleted});

  Future<void> deleteTeam(BuildContext context, Map<String, dynamic> team) async {
    if (matches.isNotEmpty) {
      await showToast(context, 'No puedes borrar participantes cuando ya hay partidos generados. Borra/recrea la competición para empezar de cero.', danger: true);
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Quitar ${AppData.text(team['name'])}?'),
        content: const Text('Solo se puede quitar antes de generar partidos.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Quitar')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await AppData.deleteTournamentTeam(team['id'].toString());
      onDeleted();
    } catch (e) {
      await showToast(context, e.toString(), danger: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text('Participantes', style: Theme.of(context).textTheme.titleLarge)),
        TextButton.icon(onPressed: onAddGroupMembers, icon: const Icon(Icons.groups_rounded), label: const Text('Miembros')),
        TextButton.icon(onPressed: onAddTeam, icon: const Icon(Icons.add_rounded), label: const Text('Añadir')),
      ]),
      const SizedBox(height: 8),
      if (teams.isEmpty)
        EmptyBlock(icon: Icons.group_add_rounded, title: 'Añade participantes', body: 'Pueden ser jugadores, parejas o equipos según el formato.')
      else
        ...teams.asMap().entries.map((entry) {
          final team = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: AppCard(
              child: Row(children: [
                Container(width: 42, height: 42, decoration: BoxDecoration(color: AppColors.tealSoft, borderRadius: BorderRadius.circular(14)), child: Center(child: Text('${entry.key + 1}', style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.w900)))),
                const SizedBox(width: 12),
                Expanded(child: Text(AppData.text(team['name'], 'Participante'), style: const TextStyle(fontWeight: FontWeight.w900))),
                IconButton(onPressed: () => deleteTeam(context, team), icon: const Icon(Icons.delete_outline_rounded, color: AppColors.muted)),
              ]),
            ),
          );
        }),
    ]);
  }
}

class TournamentFormatOption extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title;
  final String body;
  final VoidCallback onTap;
  const TournamentFormatOption({super.key, required this.selected, required this.icon, required this.title, required this.body, required this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.tealSoft : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? AppColors.teal : AppColors.line),
        ),
        child: Row(children: [
          Container(width: 42, height: 42, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: selected ? AppColors.teal : AppColors.muted)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink)),
            const SizedBox(height: 3),
            Text(body, style: Theme.of(context).textTheme.bodyMedium),
          ])),
          Icon(selected ? Icons.check_circle_rounded : Icons.circle_outlined, color: selected ? AppColors.teal : AppColors.muted),
        ]),
      ),
    ),
  );
}

class PickPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const PickPill({super.key, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(color: selected ? AppColors.tealSoft : Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: selected ? AppColors.teal : AppColors.line)),
      child: Text(label, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900, color: selected ? AppColors.tealDark : AppColors.muted)),
    ),
  );
}

class MatchCompactCard extends StatelessWidget {
  final Map<String, dynamic> match;
  final Map<String, String> names;
  const MatchCompactCard({super.key, required this.match, required this.names});

  @override
  Widget build(BuildContext context) {
    final a = teamName(AppData.text(match['team_a']), names);
    final b = teamName(AppData.text(match['team_b']), names);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          Container(width: 38, height: 38, decoration: BoxDecoration(color: AppColors.faint, borderRadius: BorderRadius.circular(13)), child: Center(child: Text('R${AppData.intValue(match['round'], 1)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.muted)))),
          const SizedBox(width: 10),
          Expanded(child: Text('$a  vs  $b', style: const TextStyle(fontWeight: FontWeight.w900))),
          const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        ]),
      ),
    );
  }
}

class MatchResultCard extends StatelessWidget {
  final Map<String, dynamic> match;
  final Map<String, String> names;
  final VoidCallback onChanged;
  const MatchResultCard({super.key, required this.match, required this.names, required this.onChanged});

  Future<void> editResult(BuildContext context) async {
    final aController = TextEditingController(text: AppData.text(match['score_a']));
    final bController = TextEditingController(text: AppData.text(match['score_b']));
    final result = await showDialog<List<int>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resultado'),
        content: Row(children: [
          Expanded(child: TextField(controller: aController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Local'))),
          const SizedBox(width: 12),
          Expanded(child: TextField(controller: bController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Visitante'))),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(onPressed: () {
            final a = int.tryParse(aController.text.trim());
            final b = int.tryParse(bController.text.trim());
            if (a == null || b == null || a < 0 || b < 0) return;
            Navigator.pop(context, [a, b]);
          }, child: const Text('Guardar')),
        ],
      ),
    );
    aController.dispose();
    bController.dispose();
    if (result == null) return;
    try {
      await AppData.setMatchResult(match['id'].toString(), result[0], result[1]);
      onChanged();
    } catch (e) {
      await showToast(context, e.toString(), danger: true);
    }
  }

  Future<void> reopen(BuildContext context) async {
    try {
      await AppData.reopenMatch(match['id'].toString());
      onChanged();
    } catch (e) {
      await showToast(context, e.toString(), danger: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final played = AppData.text(match['status']) == 'played';
    final a = teamName(AppData.text(match['team_a']), names);
    final b = teamName(AppData.text(match['team_b']), names);
    final score = played ? '${AppData.intValue(match['score_a'])} - ${AppData.intValue(match['score_b'])}' : 'Pendiente';

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: AppCard(
        padding: const EdgeInsets.all(13),
        child: Column(children: [
          Row(children: [
            Expanded(child: Text(a, style: const TextStyle(fontWeight: FontWeight.w900))),
            Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7), decoration: BoxDecoration(color: played ? AppColors.tealSoft : AppColors.faint, borderRadius: BorderRadius.circular(99)), child: Text(score, style: TextStyle(fontWeight: FontWeight.w900, color: played ? AppColors.tealDark : AppColors.muted))),
            Expanded(child: Text(b, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w900))),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Text('Ronda ${AppData.intValue(match['round'], 1)}', style: Theme.of(context).textTheme.bodyMedium),
            const Spacer(),
            if (played)
              TextButton(onPressed: () => reopen(context), child: const Text('Reabrir'))
            else
              TextButton.icon(onPressed: () => editResult(context), icon: const Icon(Icons.edit_rounded, size: 18), label: const Text('Resultado')),
          ]),
        ]),
      ),
    );
  }
}

class StandingRow extends StatelessWidget {
  final int position;
  final TeamStanding standing;
  final bool detailed;
  const StandingRow({super.key, required this.position, required this.standing, this.detailed = false});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      child: Row(children: [
        Container(width: 32, height: 32, decoration: BoxDecoration(color: position == 1 ? AppColors.tealSoft : AppColors.faint, borderRadius: BorderRadius.circular(11)), child: Center(child: Text('$position', style: TextStyle(fontWeight: FontWeight.w900, color: position == 1 ? AppColors.teal : AppColors.muted)))),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(standing.name, style: const TextStyle(fontWeight: FontWeight.w900)),
          if (detailed) Text('${standing.wins}G · ${standing.draws}E · ${standing.losses}P · GF ${standing.goalsFor} · GC ${standing.goalsAgainst}', style: Theme.of(context).textTheme.bodyMedium),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${standing.points}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.teal)),
          Text('PTS · DG ${standing.goalDifference}', style: const TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w800)),
        ]),
      ]),
    ),
  );
}



class MembersScreen extends StatefulWidget {
  final Map<String, dynamic> group;
  const MembersScreen({super.key, required this.group});
  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  late Future<List<Map<String, dynamic>>> future;

  @override
  void initState() {
    super.initState();
    future = AppData.members(widget.group['id'].toString());
  }

  void reload() => setState(() => future = AppData.members(widget.group['id'].toString()));

  bool _canManage(List<Map<String, dynamic>> members) {
    final uid = AppData.user?.id;
    Map<String, dynamic>? me;
    for (final member in members) {
      if (member['user_id']?.toString() == uid) {
        me = member;
        break;
      }
    }
    final role = AppData.text(me?['role']);
    return role == 'owner' || role == 'admin';
  }

  Future<void> _changeRole(Map<String, dynamic> member, String role) async {
    final name = memberName(member);
    try {
      await AppData.updateMemberRole(member['id'].toString(), role);
      reload();
      if (mounted) await showToast(context, role == 'admin' ? '$name ahora es admin.' : '$name ahora es miembro.');
    } catch (e) {
      if (mounted) await showToast(context, e.toString(), danger: true);
    }
  }

  Future<void> _remove(Map<String, dynamic> member) async {
    final name = memberName(member);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Expulsar a $name'),
        content: const Text('Esta persona perderá acceso al grupo. Podrá volver si recibe una nueva invitación.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Expulsar')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await AppData.removeMember(member['id'].toString());
      reload();
      if (mounted) await showToast(context, '$name ya no está en el grupo.');
    } catch (e) {
      if (mounted) await showToast(context, e.toString(), danger: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupName = AppData.text(widget.group['name'], 'Grupo');
    final code = AppData.text(widget.group['invite_code'], '------');
    return DirectPage(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        PageHeader(title: 'Miembros', subtitle: groupName, leading: true),
        const SizedBox(height: 14),
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(width: 46, height: 46, decoration: const BoxDecoration(color: AppColors.tealSoft, shape: BoxShape.circle), child: const Icon(Icons.lock_rounded, color: AppColors.teal)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Grupo privado por invitación', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 3),
              Text('Comparte el código $code solo con quienes quieras dentro del grupo.', style: Theme.of(context).textTheme.bodyMedium),
            ])),
          ]),
        ),
        const SizedBox(height: 14),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const CenterLoader(label: 'Cargando miembros...');
            if (snapshot.hasError) return ErrorBlock(message: snapshot.error.toString(), onRetry: reload);
            final members = snapshot.data ?? [];
            final admins = members.where((m) => ['owner', 'admin'].contains(AppData.text(m['role']))).toList();
            final regular = members.where((m) => AppData.text(m['role']) == 'member').toList();
            final canManage = _canManage(members);
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: StatCard(icon: Icons.groups_rounded, value: members.length.toString(), label: 'Total', color: AppColors.teal)),
                const SizedBox(width: 10),
                Expanded(child: StatCard(icon: Icons.admin_panel_settings_rounded, value: admins.length.toString(), label: 'Admins', color: AppColors.violet)),
                const SizedBox(width: 10),
                Expanded(child: StatCard(icon: Icons.person_outline_rounded, value: regular.length.toString(), label: 'Miembros', color: AppColors.orange)),
              ]),
              const SizedBox(height: 18),
              SectionHeader(title: 'Administradores'),
              const SizedBox(height: 8),
              ...admins.map((m) => ManageMemberCard(member: m, canManage: canManage, onRole: _changeRole, onRemove: _remove)),
              const SizedBox(height: 16),
              SectionHeader(title: 'Miembros'),
              const SizedBox(height: 8),
              if (regular.isEmpty)
                EmptySlim(icon: Icons.person_add_alt_1_rounded, title: 'Aún no hay miembros normales', body: 'Invita a tu grupo con el código o enlace cuando esté listo.')
              else
                ...regular.map((m) => ManageMemberCard(member: m, canManage: canManage, onRole: _changeRole, onRemove: _remove)),
              const SizedBox(height: 16),
              if (!canManage)
                EmptySlim(icon: Icons.shield_outlined, title: 'Permisos de miembro', body: 'Puedes ver el grupo y participar. Solo owner/admins pueden gestionar miembros.'),
            ]);
          },
        ),
      ]),
    );
  }
}

class GroupSettingsScreen extends StatelessWidget {
  final Map<String, dynamic> group;
  const GroupSettingsScreen({super.key, required this.group});
  @override Widget build(BuildContext context) {
    return DirectPage(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeader(title: 'Ajustes del grupo', subtitle: AppData.text(group['name']), leading: true),
      const SizedBox(height: 18),
      SettingsRow(icon: Icons.groups_rounded, title: 'Miembros', subtitle: 'Gestiona el grupo', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => MembersScreen(group: group)))),
      SettingsRow(icon: Icons.qr_code_rounded, title: 'Código de invitación', subtitle: AppData.text(group['invite_code'], '------'), onTap: () => showCodeSheet(context, AppData.text(group['invite_code'], '------'), AppData.text(group['name']))),
      SettingsRow(icon: Icons.lock_rounded, title: 'Privacidad', subtitle: 'Grupo privado por invitación', onTap: () {}),
      SettingsRow(icon: Icons.delete_outline_rounded, title: 'Eliminar grupo', subtitle: 'Solo owner', danger: true, onTap: () => showToast(context, 'Acción pendiente de confirmación segura.')),
    ]));
  }
}

class NotificationsScreen extends StatelessWidget {
  final VoidCallback onChanged;
  const NotificationsScreen({super.key, required this.onChanged});
  @override Widget build(BuildContext context) {
    return DirectPage(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Avisos', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 8), Text('Notificaciones importantes de tus grupos.', style: Theme.of(context).textTheme.bodyMedium),
      const SizedBox(height: 22),
      EmptyBlock(icon: Icons.notifications_none_rounded, title: 'Sin avisos pendientes', body: 'Aquí verás cambios en eventos, gastos y torneos.'),
    ]));
  }
}


class ProfileScreen extends StatefulWidget {
  final VoidCallback onChanged;
  const ProfileScreen({super.key, required this.onChanged});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<_ProfileData> future;
  bool photoLoading = false;

  @override
  void initState() {
    super.initState();
    load();
  }

  void load() {
    future = _ProfileData.load();
  }

  void reload() {
    setState(load);
    widget.onChanged();
  }

  Future<void> editName(String currentName) async {
    final controller = TextEditingController(text: currentName);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar nombre'),
        content: TextField(
          controller: controller,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Nombre visible',
            hintText: 'Ej. José García',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Guardar')),
        ],
      ),
    );
    controller.dispose();
    if (newName == null) return;
    try {
      await AppData.updateProfileName(newName);
      reload();
      if (mounted) await showToast(context, 'Nombre actualizado.');
    } catch (e) {
      if (mounted) await showToast(context, e.toString(), danger: true);
    }
  }

  Future<void> changePhoto() async {
    if (photoLoading) return;
    setState(() => photoLoading = true);
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 900,
        imageQuality: 82,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      await AppData.uploadAvatarBytes(bytes, picked.name);
      reload();
      if (mounted) await showToast(context, 'Foto actualizada.');
    } catch (e) {
      if (mounted) {
        await showToast(
          context,
          'No se ha podido subir la foto. Ejecuta el SQL de avatares si aún no lo has hecho.',
          danger: true,
        );
      }
    } finally {
      if (mounted) setState(() => photoLoading = false);
    }
  }

  Future<void> removePhoto() async {
    try {
      await AppData.removeAvatar();
      reload();
      if (mounted) await showToast(context, 'Foto eliminada.');
    } catch (e) {
      if (mounted) await showToast(context, e.toString(), danger: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DirectPage(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 30),
      child: FutureBuilder<_ProfileData>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CenterLoader(label: 'Cargando perfil...');
          }
          if (snapshot.hasError) {
            return ErrorBlock(message: snapshot.error.toString(), onRetry: reload);
          }

          final data = snapshot.data ?? _ProfileData.empty();
          final name = data.name;
          final email = data.email;
          final avatarUrl = data.avatarUrl;

          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Text('Perfil', style: Theme.of(context).textTheme.headlineMedium),
              const Spacer(),
              IconButton(
                onPressed: reload,
                icon: const Icon(Icons.refresh_rounded),
                color: AppColors.muted,
              ),
            ]),
            const SizedBox(height: 18),
            AppCard(
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
              child: Column(children: [
                Stack(alignment: Alignment.bottomRight, children: [
                  ProfileAvatar(name: name, avatarUrl: avatarUrl, radius: 52),
                  Material(
                    color: AppColors.teal,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: changePhoto,
                      child: SizedBox(
                        width: 35,
                        height: 35,
                        child: photoLoading
                            ? const Padding(
                                padding: EdgeInsets.all(9),
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 14),
                Text(name, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 3),
                Text(email, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 18),
                Row(children: [
                  Expanded(child: TinyStat(icon: Icons.lock_rounded, value: '${data.groups.length}', label: 'Grupos')),
                  const SizedBox(width: 10),
                  Expanded(child: TinyStat(icon: Icons.admin_panel_settings_rounded, value: '${data.adminGroups}', label: 'Admin')),
                  const SizedBox(width: 10),
                  Expanded(child: TinyStat(icon: Icons.event_available_rounded, value: '${data.totalEvents}', label: 'Eventos')),
                ]),
              ]),
            ),
            const SizedBox(height: 16),
            SettingsRow(icon: Icons.edit_rounded, title: 'Nombre visible', subtitle: name, onTap: () => editName(name)),
            SettingsRow(icon: Icons.photo_camera_rounded, title: 'Cambiar foto', subtitle: 'Elige una imagen de tu dispositivo', onTap: changePhoto),
            if (avatarUrl.isNotEmpty)
              SettingsRow(icon: Icons.delete_outline_rounded, title: 'Quitar foto', subtitle: 'Volver al avatar con iniciales', danger: true, onTap: removePhoto),
            SettingsRow(icon: Icons.groups_rounded, title: 'Mis grupos', subtitle: '${data.groups.length} grupo${data.groups.length == 1 ? '' : 's'} privado${data.groups.length == 1 ? '' : 's'}', onTap: () {}),
            SettingsRow(icon: Icons.notifications_none_rounded, title: 'Notificaciones', subtitle: 'Eventos, gastos y torneos', onTap: () => showToast(context, 'Ajustes de notificaciones preparados para push.')),
            SettingsRow(icon: Icons.help_outline_rounded, title: 'Ayuda y soporte', subtitle: 'Centro de ayuda y contacto', onTap: () => showToast(context, 'Soporte preparado para la siguiente fase.')),
            const SizedBox(height: 18),
            DangerButton(label: 'Cerrar sesión', icon: Icons.logout_rounded, onTap: () => AppData.sb.auth.signOut()),
          ]);
        },
      ),
    );
  }
}

class _ProfileData {
  final Map<String, dynamic> profile;
  final List<Map<String, dynamic>> groups;

  const _ProfileData({required this.profile, required this.groups});

  static _ProfileData empty() => const _ProfileData(profile: {}, groups: []);

  static Future<_ProfileData> load() async {
    final results = await Future.wait([
      AppData.profile(),
      AppData.myGroups(),
    ]);
    return _ProfileData(
      profile: AppData.asMap(results[0]),
      groups: AppData.asList(results[1]),
    );
  }

  String get email => AppData.text(profile['email'], AppData.user?.email ?? '');
  String get name {
    final fromProfile = AppData.text(profile['full_name']);
    if (fromProfile.isNotEmpty && fromProfile != 'Usuario') return fromProfile;
    final e = email;
    if (e.contains('@')) return e.split('@').first;
    return 'Usuario';
  }

  String get avatarUrl => AppData.text(profile['avatar_url']);

  int get adminGroups => groups.where((g) => ['owner', 'admin'].contains(AppData.text(g['role']))).length;
  int get totalEvents => groups.fold<int>(0, (sum, g) => sum + AppData.intValue(g['events_count']));
}



class ProfileAvatar extends StatelessWidget {
  final String name;
  final String avatarUrl;
  final double radius;
  const ProfileAvatar({super.key, required this.name, required this.avatarUrl, this.radius = 24});

  @override
  Widget build(BuildContext context) {
    final initials = initialsFor(name);
    if (avatarUrl.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.tealSoft,
        backgroundImage: NetworkImage(avatarUrl),
        onBackgroundImageError: (_, __) {},
        child: const SizedBox.shrink(),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.tealSoft,
      child: Text(
        initials,
        style: TextStyle(
          color: AppColors.teal,
          fontWeight: FontWeight.w900,
          fontSize: radius * .58,
        ),
      ),
    );
  }
}

class TinyStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const TinyStat({super.key, required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.faint,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(children: [
        Icon(icon, color: AppColors.teal, size: 18),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(color: AppColors.ink, fontSize: 18, fontWeight: FontWeight.w900)),
        Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 11, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}


class GroupHeroCard extends StatelessWidget {
  final String name;
  const GroupHeroCard({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 104,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(colors: [Color(0xFF006B69), Color(0xFF00998E)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        boxShadow: const [BoxShadow(color: Color(0x1A008F86), blurRadius: 20, offset: Offset(0, 10))],
      ),
      child: Stack(children: [
        Positioned.fill(child: Opacity(opacity: .10, child: PatternIcons())),
        Positioned(left: 18, right: 16, bottom: 16, child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Expanded(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w900, height: 1.0, letterSpacing: -0.6))),
            Container(width: 34, height: 34, decoration: BoxDecoration(color: Colors.white.withOpacity(.18), shape: BoxShape.circle), child: const Icon(Icons.lock_rounded, color: Colors.white, size: 18)),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: Colors.white.withOpacity(.17), borderRadius: BorderRadius.circular(99)),
              child: const Text('Grupo privado', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
            ),
            const SizedBox(width: 8),
            const Expanded(child: Text('Resumen general', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Color(0xDFFFFFFF), fontSize: 12.5, fontWeight: FontWeight.w700))),
          ]),
        ])),
      ]),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onTap;
  const SectionHeader({super.key, required this.title, this.action, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
      if (action != null) TextButton(onPressed: onTap, child: Text(action!)),
    ]);
  }
}


class CompactInsightStrip extends StatelessWidget {
  final int events;
  final double expenses;
  final int pending;
  final int tournaments;
  const CompactInsightStrip({super.key, required this.events, required this.expenses, required this.pending, required this.tournaments});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(children: [
        Expanded(child: CompactInsight(icon: Icons.calendar_month_rounded, label: 'Agenda', value: '$events')),
        const _TinyDivider(),
        Expanded(child: CompactInsight(icon: Icons.account_balance_wallet_rounded, label: 'Gastos', value: money(expenses))),
        const _TinyDivider(),
        Expanded(child: CompactInsight(icon: Icons.help_outline_rounded, label: 'Dudas', value: '$pending')),
        const _TinyDivider(),
        Expanded(child: CompactInsight(icon: Icons.emoji_events_rounded, label: 'Torneos', value: '$tournaments')),
      ]),
    );
  }
}

class CompactInsight extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const CompactInsight({super.key, required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 18, color: AppColors.teal),
    const SizedBox(height: 5),
    Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.ink)),
    const SizedBox(height: 1),
    Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.muted)),
  ]);
}

class _TinyDivider extends StatelessWidget {
  const _TinyDivider();
  @override
  Widget build(BuildContext context) => Container(width: 1, height: 34, color: AppColors.line);
}

class DashboardEventCard extends StatefulWidget {
  final Map<String, dynamic> event;
  final Map<String, dynamic> group;
  final VoidCallback onChanged;
  const DashboardEventCard({super.key, required this.event, required this.group, required this.onChanged});

  @override
  State<DashboardEventCard> createState() => _DashboardEventCardState();
}

class _DashboardEventCardState extends State<DashboardEventCard> {
  bool saving = false;

  Future<void> setStatus(String status) async {
    setState(() => saving = true);
    try {
      await AppData.setAttendance(widget.event['id'].toString(), status);
      widget.onChanged();
    } catch (e) {
      await showToast(context, e.toString(), danger: true);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final date = DateTime.tryParse(event['starts_at']?.toString() ?? '')?.toLocal() ?? DateTime.now();
    final minPeople = AppData.intValue(event['min_people'], 1);
    final yes = attendanceCount(event, 'yes');
    final maybe = attendanceCount(event, 'maybe');
    final no = attendanceCount(event, 'no');
    final mine = myAttendanceStatus(event);

    return AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(color: AppColors.tealSoft, borderRadius: BorderRadius.circular(15)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(shortWeekday(date).toUpperCase(), style: const TextStyle(color: AppColors.teal, fontSize: 11, fontWeight: FontWeight.w900)),
            Text(date.day.toString(), style: const TextStyle(color: AppColors.ink, fontSize: 21, fontWeight: FontWeight.w900)),
          ]),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(AppData.text(event['title'], 'Evento'), style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 5),
          MetaLine(icon: Icons.schedule_rounded, text: DateFormat('HH:mm', 'es_ES').format(date)),
          MetaLine(icon: Icons.place_outlined, text: AppData.text(event['location'], 'Sin ubicación')),
        ])),
        IconButton(onPressed: () async {
          await Navigator.of(context).push(MaterialPageRoute(builder: (_) => EventDetailScreen(event: event, group: widget.group)));
          widget.onChanged();
        }, icon: const Icon(Icons.chevron_right_rounded)),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: AttendancePick(label: 'Voy', count: yes, selected: mine == 'yes', color: AppColors.green, onTap: saving ? () {} : () => setStatus('yes'))),
        const SizedBox(width: 8),
        Expanded(child: AttendancePick(label: 'Duda', count: maybe, selected: mine == 'maybe', color: AppColors.amber, onTap: saving ? () {} : () => setStatus('maybe'))),
        const SizedBox(width: 8),
        Expanded(child: AttendancePick(label: 'No voy', count: no, selected: mine == 'no', color: AppColors.red, onTap: saving ? () {} : () => setStatus('no'))),
      ]),
      const SizedBox(height: 12),
      StatusNotice(ok: yes >= minPeople, text: yes >= minPeople ? 'Mínimo alcanzado: $yes de $minPeople asistentes.' : 'Faltan ${max(0, minPeople - yes)} para alcanzar el mínimo.'),
    ]));
  }
}

class SmartPromptCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onTap;
  const SmartPromptCard({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.surface,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(color: color.withOpacity(.12), borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(body, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 10),
                InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(actionLabel, style: TextStyle(color: color, fontWeight: FontWeight.w900)),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded, size: 18, color: color),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardSummaryCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String eyebrow;
  final String title;
  final String body;
  final String footer;
  final String actionLabel;
  final VoidCallback onTap;
  const DashboardSummaryCard({
    super.key,
    required this.icon,
    required this.color,
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.footer,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: color.withOpacity(.12), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(height: 12),
          Text(eyebrow, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.muted)),
          const SizedBox(height: 6),
          Text(title, style: const TextStyle(fontSize: 18, height: 1.15, fontWeight: FontWeight.w900, color: AppColors.ink)),
          const SizedBox(height: 6),
          Text(body, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, height: 1.35, color: AppColors.muted, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(footer, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, height: 1.35, color: AppColors.ink, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(actionLabel, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12.5)),
              const SizedBox(width: 4),
              Icon(Icons.arrow_forward_rounded, size: 18, color: color),
            ],
          ),
        ],
      ),
    );
  }
}

class QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const QuickActionButton({super.key, required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 36 - 14 - 30) / 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(color: AppColors.tealSoft, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: AppColors.teal, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



class DashboardActivityCard extends StatelessWidget {
  final List<Map<String, dynamic>> events;
  final List<Map<String, dynamic>> expenses;
  final List<Map<String, dynamic>> tournaments;
  final VoidCallback? onOpenCalendar;
  final VoidCallback? onOpenFinances;
  final VoidCallback? onOpenTournaments;

  const DashboardActivityCard({
    super.key,
    required this.events,
    required this.expenses,
    required this.tournaments,
    this.onOpenCalendar,
    this.onOpenFinances,
    this.onOpenTournaments,
  });

  List<_DashboardActivityItem> _items() {
    final items = <_DashboardActivityItem>[];

    for (final event in events.take(6)) {
      final date = DateTime.tryParse(event['starts_at']?.toString() ?? '')?.toLocal();
      if (date == null) continue;
      final title = AppData.text(event['title'], 'Quedada');
      final yes = attendanceCount(event, 'yes');
      final minPeople = AppData.intValue(event['min_people'], 1);
      items.add(_DashboardActivityItem(
        date: date,
        icon: Icons.event_available_rounded,
        color: AppColors.teal,
        title: title,
        body: '${longDateTime(date)} · $yes/$minPeople confirmados',
        onTapKind: 'calendar',
      ));
    }

    for (final expense in expenses.take(6)) {
      final created = DateTime.tryParse(expense['created_at']?.toString() ?? '')?.toLocal() ?? DateTime.now();
      final concept = AppData.text(expense['concept'], 'Gasto');
      final amount = AppData.doubleValue(expense['amount']);
      final status = AppData.text(expense['status'], 'pending') == 'paid' ? 'liquidado' : 'pendiente';
      items.add(_DashboardActivityItem(
        date: created,
        icon: Icons.account_balance_wallet_rounded,
        color: AppData.text(expense['status'], 'pending') == 'paid' ? AppColors.green : AppColors.amber,
        title: concept,
        body: '${money(amount)} · $status',
        onTapKind: 'finances',
      ));
    }

    for (final tournament in tournaments.take(6)) {
      final created = DateTime.tryParse(tournament['created_at']?.toString() ?? '')?.toLocal() ?? DateTime.now();
      final name = AppData.text(tournament['name'], 'Competición');
      final teams = AppData.asList(tournament['tournament_teams']).length;
      final matches = AppData.asList(tournament['matches']).length;
      final finished = AppData.text(tournament['status'], 'active') == 'finished';
      items.add(_DashboardActivityItem(
        date: created,
        icon: Icons.emoji_events_rounded,
        color: finished ? AppColors.violet : AppColors.orange,
        title: name,
        body: '$teams participantes · $matches partidos · ${finished ? 'finalizado' : 'en curso'}',
        onTapKind: 'tournaments',
      ));
    }

    items.sort((a, b) => b.date.compareTo(a.date));
    return items.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = _items();

    if (items.isEmpty) {
      return EmptySlim(
        icon: Icons.bolt_rounded,
        title: 'Todavía no hay actividad real',
        body: 'Cuando el grupo cree quedadas, gastos o torneos, aparecerán aquí sin usar ejemplos falsos.',
      );
    }

    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            _DashboardActivityRow(
              item: items[i],
              onTap: () {
                if (items[i].onTapKind == 'calendar') onOpenCalendar?.call();
                if (items[i].onTapKind == 'finances') onOpenFinances?.call();
                if (items[i].onTapKind == 'tournaments') onOpenTournaments?.call();
              },
            ),
            if (i != items.length - 1)
              const Divider(height: 1, indent: 58, color: AppColors.line),
          ],
        ],
      ),
    );
  }
}

class _DashboardActivityItem {
  final DateTime date;
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  final String onTapKind;

  const _DashboardActivityItem({
    required this.date,
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
    required this.onTapKind,
  });
}

class _DashboardActivityRow extends StatelessWidget {
  final _DashboardActivityItem item;
  final VoidCallback onTap;

  const _DashboardActivityRow({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: item.color.withOpacity(.12), borderRadius: BorderRadius.circular(12)),
              child: Icon(item.icon, color: item.color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink)),
                const SizedBox(height: 2),
                Text(item.body, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w700)),
              ]),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: AppColors.muted, size: 22),
          ],
        ),
      ),
    );
  }
}




class CalendarSmartHeader extends StatelessWidget {
  final int todayEvents;
  final int weekEvents;
  final int pendingResponses;
  final VoidCallback onToday;

  const CalendarSmartHeader({
    super.key,
    required this.todayEvents,
    required this.weekEvents,
    required this.pendingResponses,
    required this.onToday,
  });

  @override
  Widget build(BuildContext context) {
    final hasPending = pendingResponses > 0;
    return AppCard(
      color: AppColors.surface,
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: hasPending ? AppColors.amber.withOpacity(.12) : AppColors.tealSoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              hasPending ? Icons.notification_important_rounded : Icons.calendar_month_rounded,
              color: hasPending ? AppColors.amber : AppColors.teal,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              hasPending ? 'Tienes respuestas pendientes' : 'Agenda del grupo',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              hasPending
                  ? '$pendingResponses ${pendingResponses == 1 ? 'evento necesita' : 'eventos necesitan'} tu respuesta para organizar mejor el grupo.'
                  : 'Mira qué hay hoy, qué viene esta semana y crea eventos desde cualquier día.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ])),
          TextButton(onPressed: onToday, child: const Text('Hoy')),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _CalendarMiniStat(label: 'Hoy', value: '$todayEvents', color: AppColors.teal)),
          const SizedBox(width: 8),
          Expanded(child: _CalendarMiniStat(label: '7 días', value: '$weekEvents', color: AppColors.violet)),
          const SizedBox(width: 8),
          Expanded(child: _CalendarMiniStat(label: 'Pendientes', value: '$pendingResponses', color: AppColors.amber)),
        ]),
      ]),
    );
  }
}

class _CalendarMiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _CalendarMiniStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.line),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800, fontSize: 11)),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 19)),
    ]),
  );
}

class WeekStrip extends StatelessWidget {
  final List<DateTime> days;
  final DateTime selected;
  final List<Map<String, dynamic>> events;
  final ValueChanged<DateTime> onSelect;

  const WeekStrip({
    super.key,
    required this.days,
    required this.selected,
    required this.events,
    required this.onSelect,
  });

  int countFor(DateTime day) {
    return events.where((event) {
      final date = DateTime.tryParse(event['starts_at']?.toString() ?? '')?.toLocal();
      return date != null && sameDay(date, day);
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 78,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final day = days[index];
          final active = sameDay(day, selected);
          final count = countFor(day);
          return InkWell(
            onTap: () => onSelect(day),
            borderRadius: BorderRadius.circular(18),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 62,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
              decoration: BoxDecoration(
                color: active ? AppColors.teal : AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: active ? AppColors.teal : AppColors.line),
                boxShadow: active ? const [BoxShadow(color: Color(0x16008F86), blurRadius: 14, offset: Offset(0, 7))] : null,
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(shortWeekday(day).toUpperCase(), style: TextStyle(color: active ? Colors.white : AppColors.muted, fontWeight: FontWeight.w900, fontSize: 11)),
                const SizedBox(height: 4),
                Text(day.day.toString(), style: TextStyle(color: active ? Colors.white : AppColors.ink, fontWeight: FontWeight.w900, fontSize: 20)),
                const SizedBox(height: 4),
                Container(
                  width: count > 0 ? 18 : 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: active ? Colors.white : (count > 0 ? AppColors.teal : AppColors.line),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }
}

class EventTemplateChoice extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const EventTemplateChoice({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: selected ? AppColors.teal : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: selected ? AppColors.teal : AppColors.line),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: selected ? Colors.white : AppColors.teal, size: 18),
        const SizedBox(width: 7),
        Text(label, style: TextStyle(color: selected ? Colors.white : AppColors.ink, fontWeight: FontWeight.w900)),
      ]),
    ),
  );
}

class EventFormPreviewCard extends StatelessWidget {
  final String title;
  final DateTime date;
  final String location;
  final int minPeople;
  final String template;

  const EventFormPreviewCard({
    super.key,
    required this.title,
    required this.date,
    required this.location,
    required this.minPeople,
    required this.template,
  });

  IconData get icon {
    final lower = template.toLowerCase();
    if (lower.contains('partido')) return Icons.sports_soccer_rounded;
    if (lower.contains('entrenamiento')) return Icons.fitness_center_rounded;
    if (lower.contains('cena')) return Icons.restaurant_rounded;
    if (lower.contains('reun')) return Icons.forum_rounded;
    return Icons.event_available_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(colors: [Color(0xFF006B69), Color(0xFF00998E)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        boxShadow: const [BoxShadow(color: Color(0x16008F86), blurRadius: 18, offset: Offset(0, 9))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(color: Colors.white.withOpacity(.18), borderRadius: BorderRadius.circular(18)),
            child: Icon(icon, color: Colors.white, size: 27),
          ),
          const SizedBox(width: 13),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900, height: 1.05)),
            const SizedBox(height: 8),
            Text(longDateTime(date), style: const TextStyle(color: Color(0xEFFFFFFF), fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(location.trim().isEmpty ? 'Lugar por definir' : location.trim(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xDFFFFFFF), fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: Colors.white.withOpacity(.16), borderRadius: BorderRadius.circular(99)),
              child: Text('Mínimo $minPeople asistentes', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
            ),
          ])),
        ]),
      ),
    );
  }
}

class PremiumEventDetailHero extends StatelessWidget {
  final Map<String, dynamic> event;
  final DateTime date;
  final int yes;
  final int minPeople;

  const PremiumEventDetailHero({
    super.key,
    required this.event,
    required this.date,
    required this.yes,
    required this.minPeople,
  });

  @override
  Widget build(BuildContext context) {
    final ok = yes >= minPeople;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: ok ? const [Color(0xFF0D8F72), Color(0xFF15B38C)] : const [Color(0xFF006B69), Color(0xFF00998E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [BoxShadow(color: Color(0x16008F86), blurRadius: 20, offset: Offset(0, 10))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 58,
              height: 62,
              decoration: BoxDecoration(color: Colors.white.withOpacity(.18), borderRadius: BorderRadius.circular(18)),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(shortWeekday(date).toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
                Text(date.day.toString(), style: const TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w900)),
              ]),
            ),
            const SizedBox(width: 13),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(AppData.text(event['title'], 'Evento'), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, height: 1.05, letterSpacing: -0.4)),
              const SizedBox(height: 8),
              Text(longDateTime(date), style: const TextStyle(color: Color(0xEFFFFFFF), fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(AppData.text(event['location'], 'Sin ubicación'), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xDFFFFFFF), fontWeight: FontWeight.w700)),
            ])),
          ]),
          if (AppData.text(event['notes']).isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white.withOpacity(.13), borderRadius: BorderRadius.circular(16)),
              child: Text(AppData.text(event['notes']), style: const TextStyle(color: Colors.white, height: 1.35, fontWeight: FontWeight.w700)),
            ),
          ],
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(.16), borderRadius: BorderRadius.circular(99)),
            child: Text(ok ? 'Mínimo alcanzado · $yes/$minPeople' : 'Faltan ${max(0, minPeople - yes)} · $yes/$minPeople confirmados', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
          ),
        ]),
      ),
    );
  }
}

class AttendanceOverviewCard extends StatelessWidget {
  final int yes;
  final int maybe;
  final int no;
  final int pending;
  final int minPeople;

  const AttendanceOverviewCard({
    super.key,
    required this.yes,
    required this.maybe,
    required this.no,
    required this.pending,
    required this.minPeople,
  });

  @override
  Widget build(BuildContext context) {
    final ok = yes >= minPeople;
    final total = max(1, yes + maybe + no + pending);
    final progress = (yes / max(1, minPeople)).clamp(0.0, 1.0).toDouble();
    return AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(ok ? Icons.check_circle_rounded : Icons.info_rounded, color: ok ? AppColors.green : AppColors.amber),
        const SizedBox(width: 9),
        Expanded(child: Text(ok ? 'El evento ya es viable' : 'Todavía falta gente', style: Theme.of(context).textTheme.titleMedium)),
        Text('$yes/$minPeople', style: TextStyle(color: ok ? AppColors.green : AppColors.amber, fontWeight: FontWeight.w900)),
      ]),
      const SizedBox(height: 10),
      ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: LinearProgressIndicator(
          value: progress,
          minHeight: 9,
          backgroundColor: AppColors.faint,
          color: ok ? AppColors.green : AppColors.amber,
        ),
      ),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _AttendanceMiniStat(label: 'Van', value: yes, color: AppColors.green)),
        Expanded(child: _AttendanceMiniStat(label: 'Duda', value: maybe, color: AppColors.amber)),
        Expanded(child: _AttendanceMiniStat(label: 'No', value: no, color: AppColors.red)),
        Expanded(child: _AttendanceMiniStat(label: 'Pend.', value: pending, color: AppColors.muted)),
      ]),
      const SizedBox(height: 8),
      Text('Total de miembros considerados: $total', style: const TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w700)),
    ]));
  }
}

class _AttendanceMiniStat extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _AttendanceMiniStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value.toString(), style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 18)),
    const SizedBox(height: 2),
    Text(label, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800, fontSize: 11)),
  ]);
}



// ---------- UI components ----------

class FieldLabel extends StatelessWidget {
  final String text;
  const FieldLabel(this.text, {super.key});
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 7), child: Text(text, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink)));
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final bool loading;
  const PrimaryButton({super.key, required this.label, required this.onTap, this.icon, this.loading = false});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 52,
    child: FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      onPressed: loading ? null : onTap,
      icon: loading
          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : Icon(icon ?? Icons.check_rounded, size: 20),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
    ),
  );
}

class SecondaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const SecondaryButton({super.key, required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 52,
    child: OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.teal,
        side: const BorderSide(color: AppColors.teal),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
    ),
  );
}

class DangerButton extends StatelessWidget {
  final String label; final IconData icon; final VoidCallback onTap;
  const DangerButton({super.key, required this.label, required this.icon, required this.onTap});
  @override Widget build(BuildContext context) => SizedBox(width: double.infinity, height: 54, child: OutlinedButton.icon(style: OutlinedButton.styleFrom(foregroundColor: AppColors.red, side: const BorderSide(color: Color(0xFFFFC7C7)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), onPressed: onTap, icon: Icon(icon), label: Text(label, style: const TextStyle(fontWeight: FontWeight.w900))));
}

class WhiteButton extends StatelessWidget {
  final String label; final VoidCallback onTap;
  const WhiteButton({super.key, required this.label, required this.onTap});
  @override Widget build(BuildContext context) => SizedBox(height: 48, child: FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.teal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), onPressed: onTap, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w900))));
}

class SocialButton extends StatelessWidget {
  final String label; final String icon; final VoidCallback onTap;
  const SocialButton({super.key, required this.label, required this.icon, required this.onTap});
  @override Widget build(BuildContext context) => SizedBox(width: double.infinity, height: 46, child: OutlinedButton(style: OutlinedButton.styleFrom(foregroundColor: AppColors.ink, side: const BorderSide(color: AppColors.line), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: onTap, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text(icon, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)), const SizedBox(width: 12), Text(label, style: const TextStyle(fontWeight: FontWeight.w800))])));
}

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color color;
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.onTap,
    this.color = AppColors.white,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(22);
    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: radius,
        border: Border.all(color: AppColors.line),
        boxShadow: const [
          BoxShadow(color: Color(0x06111B34), blurRadius: 18, offset: Offset(0, 8)),
          BoxShadow(color: Color(0x03111B34), blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: child,
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(borderRadius: radius, onTap: onTap, child: card),
    );
  }
}

class RoundBackButton extends StatelessWidget {
  final VoidCallback? onTap;
  const RoundBackButton({super.key, this.onTap});
  @override Widget build(BuildContext context) => Container(
    width: 42,
    height: 42,
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line)),
    child: IconButton(icon: const Icon(Icons.arrow_back_rounded, size: 20), onPressed: onTap ?? () => Navigator.of(context).maybePop()),
  );
}

class CircleIconButton extends StatelessWidget {
  final IconData icon; final VoidCallback onTap; final bool filled;
  const CircleIconButton({super.key, required this.icon, required this.onTap, this.filled = false});
  @override Widget build(BuildContext context) => Container(
    width: 42,
    height: 42,
    decoration: BoxDecoration(
      color: filled ? AppColors.teal : AppColors.surface,
      shape: BoxShape.circle,
      border: filled ? null : Border.all(color: AppColors.line),
      boxShadow: filled ? const [BoxShadow(color: Color(0x1A008F86), blurRadius: 14, offset: Offset(0, 6))] : null,
    ),
    child: IconButton(onPressed: onTap, icon: Icon(icon, size: 20, color: filled ? Colors.white : AppColors.ink)),
  );
}

class OrDivider extends StatelessWidget { const OrDivider({super.key}); @override Widget build(BuildContext context) => Row(children: const [Expanded(child: Divider()), Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('o', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700))), Expanded(child: Divider())]); }

class StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const StatCard({super.key, required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
    color: AppColors.surface,
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 27,
        height: 27,
        decoration: BoxDecoration(color: color.withOpacity(.10), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 17),
      ),
      const SizedBox(height: 6),
      Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.ink)),
      const SizedBox(height: 1),
      Text(label, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, color: AppColors.muted, fontWeight: FontWeight.w700)),
    ]),
  );
}

class MoneyStat extends StatelessWidget {
  final String label; final double value; final bool positiveMeansGood;
  const MoneyStat({super.key, required this.label, required this.value, required this.positiveMeansGood});
  @override Widget build(BuildContext context) {
    final color = value >= 0 ? AppColors.green : AppColors.red;
    return AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800, fontSize: 12)), const SizedBox(height: 8), Text(money(value), style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 19))]));
  }
}

class GroupHomeCard extends StatelessWidget {
  final Map<String, dynamic> group; final VoidCallback onTap;
  const GroupHomeCard({super.key, required this.group, required this.onTap});
  @override Widget build(BuildContext context) {
    final name = AppData.text(group['name'], 'Grupo');
    final members = AppData.intValue(group['members_count'], 1);
    final events = AppData.intValue(group['events_count'], 0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF00998E), Color(0xFF006B69)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.lock_rounded, color: Colors.white, size: 23),
          ),
          const SizedBox(width: 13),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('Grupo privado · $members ${members == 1 ? 'miembro' : 'miembros'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 7),
            Row(children: [
              _MiniChip(text: events == 0 ? 'sin eventos' : '$events eventos', color: AppColors.teal),
              const SizedBox(width: 6),
              const _MiniChip(text: 'cerrado', color: AppColors.violet),
            ]),
          ])),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        ]),
      ),
    );
  }
}

class RootBottomNav extends StatelessWidget {
  final int index; final ValueChanged<int> onTap;
  const RootBottomNav({super.key, required this.index, required this.onTap});
  @override Widget build(BuildContext context) => BottomBar(items: const [NavSpec(Icons.home_rounded, 'Inicio'), NavSpec(Icons.notifications_none_rounded, 'Avisos'), NavSpec(Icons.person_outline_rounded, 'Perfil')], index: index, onTap: onTap);
}

class GroupBottomNav extends StatelessWidget {
  final String groupName; final int index; final ValueChanged<int> onTap;
  const GroupBottomNav({super.key, required this.groupName, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: BottomBar(
        items: const [
          NavSpec(Icons.home_rounded, 'Inicio'),
          NavSpec(Icons.calendar_month_rounded, 'Calendario'),
          NavSpec(Icons.account_balance_wallet_rounded, 'Finanzas'),
          NavSpec(Icons.emoji_events_rounded, 'Torneos'),
          NavSpec(Icons.more_horiz_rounded, 'Más'),
        ],
        index: index,
        onTap: onTap,
      ),
    );
  }
}

class NavSpec { final IconData icon; final String label; const NavSpec(this.icon, this.label); }

class BottomBar extends StatelessWidget {
  final List<NavSpec> items;
  final int index;
  final ValueChanged<int> onTap;
  const BottomBar({super.key, required this.items, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(10, 6, 10, 7),
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(top: BorderSide(color: AppColors.line)),
      boxShadow: [BoxShadow(color: Color(0x0D111B34), blurRadius: 16, offset: Offset(0, -6))],
    ),
    child: Row(children: List.generate(items.length, (i) {
      final active = i == index;
      final spec = items[i];
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: () => onTap(i),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                height: 31,
                padding: EdgeInsets.symmetric(horizontal: active ? 14 : 10),
                decoration: BoxDecoration(color: active ? AppColors.tealSoft : Colors.transparent, borderRadius: BorderRadius.circular(99)),
                child: Icon(spec.icon, size: 21, color: active ? AppColors.teal : AppColors.muted),
              ),
              const SizedBox(height: 2),
              Text(spec.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10.5, fontWeight: active ? FontWeight.w900 : FontWeight.w700, color: active ? AppColors.ink : AppColors.muted)),
            ]),
          ),
        ),
      );
    })),
  );
}

class PageHeader extends StatelessWidget {
  final String title; final String subtitle; final bool leading;
  const PageHeader({super.key, required this.title, this.subtitle = '', this.leading = false});
  @override Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [if (leading) ...[RoundBackButton(onTap: () => Navigator.of(context).maybePop()), const SizedBox(width: 12)], Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.headlineMedium), if (subtitle.isNotEmpty) ...[const SizedBox(height: 4), Row(children: [const Icon(Icons.lock_rounded, size: 14, color: AppColors.teal), const SizedBox(width: 5), Expanded(child: Text(subtitle, style: Theme.of(context).textTheme.bodyMedium))])]]))]);
}

class CenterLoader extends StatelessWidget { final String label; const CenterLoader({super.key, required this.label}); @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 40), child: Column(children: [const CircularProgressIndicator(color: AppColors.teal), const SizedBox(height: 12), Text(label, style: Theme.of(context).textTheme.bodyMedium)])); }

class ErrorBlock extends StatelessWidget { final String message; final VoidCallback onRetry; const ErrorBlock({super.key, required this.message, required this.onRetry}); @override Widget build(BuildContext context) => AppCard(child: Column(children: [const Icon(Icons.error_outline_rounded, color: AppColors.red, size: 34), const SizedBox(height: 10), const Text('Algo no ha cargado bien', style: TextStyle(fontWeight: FontWeight.w900)), const SizedBox(height: 7), Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium), const SizedBox(height: 14), SecondaryButton(label: 'Reintentar', icon: Icons.refresh_rounded, onTap: onRetry)])); }

class EmptyBlock extends StatelessWidget { final IconData icon; final String title; final String body; const EmptyBlock({super.key, required this.icon, required this.title, required this.body}); @override Widget build(BuildContext context) => AppCard(child: Column(children: [Container(width: 62, height: 62, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.tealSoft), child: Icon(icon, color: AppColors.teal, size: 30)), const SizedBox(height: 12), Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 6), Text(body, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium)])); }

class EmptySlim extends StatelessWidget { final IconData icon; final String title; final String body; const EmptySlim({super.key, required this.icon, required this.title, this.body = ''}); @override Widget build(BuildContext context) => AppCard(child: Row(children: [Icon(icon, color: AppColors.teal), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w900)), if (body.trim().isNotEmpty) ...[const SizedBox(height: 4), Text(body, style: Theme.of(context).textTheme.bodyMedium)]]))])); }

class HomeLoading extends StatelessWidget { const HomeLoading({super.key}); @override Widget build(BuildContext context) => Column(children: [Row(children: const [Expanded(child: GhostBox(height: 90)), SizedBox(width: 10), Expanded(child: GhostBox(height: 90)), SizedBox(width: 10), Expanded(child: GhostBox(height: 90))]), const SizedBox(height: 24), const GhostBox(height: 100), const SizedBox(height: 10), const GhostBox(height: 100)]); }
class GhostBox extends StatelessWidget { final double height; const GhostBox({super.key, required this.height}); @override Widget build(BuildContext context) => Container(height: height, decoration: BoxDecoration(color: AppColors.faint, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.line))); }

class ChoiceBigCard extends StatelessWidget { final IconData icon; final String title; final String body; final VoidCallback onTap; const ChoiceBigCard({super.key, required this.icon, required this.title, required this.body, required this.onTap}); @override Widget build(BuildContext context) => AppCard(onTap: onTap, child: Row(children: [Container(width: 48, height: 48, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.tealSoft), child: Icon(icon, color: AppColors.teal)), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.titleMedium), Text(body, style: Theme.of(context).textTheme.bodyMedium)])), const Icon(Icons.chevron_right_rounded, color: AppColors.muted)])); }

class MiniAction extends StatelessWidget { final IconData icon; final String label; final VoidCallback onTap; const MiniAction({super.key, required this.icon, required this.label, required this.onTap}); @override Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(15), child: Container(padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: AppColors.line)), child: Column(children: [Icon(icon, color: AppColors.ink), const SizedBox(height: 5), Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900))]))); }

class Grid2 extends StatelessWidget { final List<Widget> children; const Grid2({super.key, required this.children}); @override Widget build(BuildContext context) => GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.55, children: children); }

class FeatureTile extends StatelessWidget { final IconData icon; final String title; final String body; final Color color; final VoidCallback onTap; const FeatureTile({super.key, required this.icon, required this.title, required this.body, required this.color, required this.onTap}); @override Widget build(BuildContext context) => AppCard(onTap: onTap, child: Row(children: [Icon(icon, color: color, size: 28), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w900)), Text(body, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontSize: 12))]))])); }

class ActivityRow extends StatelessWidget { final IconData icon; final String title; final String meta; const ActivityRow({super.key, required this.icon, required this.title, required this.meta}); @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Row(children: [CircleAvatar(radius: 16, backgroundColor: AppColors.tealSoft, child: Icon(icon, color: AppColors.teal, size: 17)), const SizedBox(width: 11), Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800))), Text(meta, style: const TextStyle(color: AppColors.muted, fontSize: 12))])); }


class QuickTemplateChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const QuickTemplateChip({super.key, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => ActionChip(
    label: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
    avatar: const Icon(Icons.add_rounded, size: 17),
    backgroundColor: AppColors.faint,
    side: const BorderSide(color: AppColors.line),
    onPressed: onTap,
  );
}

class DateBadge extends StatelessWidget {
  final DateTime date;
  const DateBadge({super.key, required this.date});
  @override
  Widget build(BuildContext context) => Container(
    width: 62,
    height: 66,
    decoration: BoxDecoration(color: AppColors.tealSoft, borderRadius: BorderRadius.circular(15)),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(shortWeekday(date).toUpperCase(), style: const TextStyle(color: AppColors.teal, fontSize: 11, fontWeight: FontWeight.w900)),
      Text(date.day.toString(), style: const TextStyle(color: AppColors.ink, fontSize: 24, fontWeight: FontWeight.w900)),
    ]),
  );
}

class CalendarDaySummary extends StatelessWidget {
  final DateTime day;
  final List<Map<String, dynamic>> events;
  final int confirmed;
  final int maybe;
  final VoidCallback onCreate;
  const CalendarDaySummary({super.key, required this.day, required this.events, required this.confirmed, required this.maybe, required this.onCreate});
  @override
  Widget build(BuildContext context) => AppCard(child: Row(children: [
    DateBadge(date: day),
    const SizedBox(width: 12),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(longDay(day), style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 5),
      Text(events.isEmpty ? 'No hay eventos creados para este día.' : '${events.length} evento${events.length == 1 ? '' : 's'} · $confirmed confirmados · $maybe en duda', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700)),
    ])),
    IconButton(onPressed: onCreate, icon: const Icon(Icons.add_circle_rounded, color: AppColors.teal, size: 30)),
  ]));
}

class EventAgendaCard extends StatefulWidget {
  final Map<String, dynamic> event;
  final Map<String, dynamic> group;
  final VoidCallback onChanged;
  const EventAgendaCard({super.key, required this.event, required this.group, required this.onChanged});
  @override
  State<EventAgendaCard> createState() => _EventAgendaCardState();
}

class _EventAgendaCardState extends State<EventAgendaCard> {
  bool saving = false;

  Future<void> setStatus(String status) async {
    setState(() => saving = true);
    try {
      await AppData.setAttendance(widget.event['id'].toString(), status);
      widget.onChanged();
    } catch (e) {
      await showToast(context, e.toString(), danger: true);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> open() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => EventDetailScreen(event: widget.event, group: widget.group)));
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final date = DateTime.tryParse(event['starts_at']?.toString() ?? '')?.toLocal() ?? DateTime.now();
    final yes = attendanceCount(event, 'yes');
    final maybe = attendanceCount(event, 'maybe');
    final no = attendanceCount(event, 'no');
    final minPeople = AppData.intValue(event['min_people'], 2);
    final mine = myAttendanceStatus(event);
    final viable = yes >= minPeople;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        InkWell(
          onTap: open,
          borderRadius: BorderRadius.circular(15),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            DateBadge(date: date),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(AppData.text(event['title'], 'Evento'), style: Theme.of(context).textTheme.titleMedium)),
                Icon(viable ? Icons.verified_rounded : Icons.info_rounded, color: viable ? AppColors.green : AppColors.amber, size: 20),
              ]),
              const SizedBox(height: 5),
              MetaLine(icon: Icons.schedule_rounded, text: DateFormat('HH:mm', 'es_ES').format(date)),
              MetaLine(icon: Icons.place_outlined, text: AppData.text(event['location'], 'Sin ubicación')),
              const SizedBox(height: 7),
              Text(viable ? 'Mínimo alcanzado: $yes/$minPeople' : 'Faltan ${max(0, minPeople - yes)} para llegar al mínimo', style: TextStyle(color: viable ? AppColors.green : AppColors.amber, fontWeight: FontWeight.w900, fontSize: 12)),
            ])),
            const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
          ]),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: CompactAttendanceButton(label: 'Voy', count: yes, selected: mine == 'yes', color: AppColors.green, onTap: saving ? () {} : () => setStatus('yes'))),
          const SizedBox(width: 7),
          Expanded(child: CompactAttendanceButton(label: 'Duda', count: maybe, selected: mine == 'maybe', color: AppColors.amber, onTap: saving ? () {} : () => setStatus('maybe'))),
          const SizedBox(width: 7),
          Expanded(child: CompactAttendanceButton(label: 'No', count: no, selected: mine == 'no', color: AppColors.red, onTap: saving ? () {} : () => setStatus('no'))),
        ]),
      ])),
    );
  }
}

class CompactAttendanceButton extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const CompactAttendanceButton({super.key, required this.label, required this.count, required this.selected, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(color: selected ? color.withOpacity(.11) : AppColors.faint, borderRadius: BorderRadius.circular(14), border: Border.all(color: selected ? color : AppColors.line)),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(selected ? Icons.check_circle_rounded : Icons.circle_outlined, size: 16, color: color),
        const SizedBox(width: 5),
        Text('$label · $count', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w900)),
      ]),
    ),
  );
}

class EventMemberRoster extends StatelessWidget {
  final Map<String, dynamic> event;
  final List<Map<String, dynamic>> members;
  const EventMemberRoster({super.key, required this.event, required this.members});
  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) return EmptySlim(icon: Icons.groups_rounded, title: 'Sin miembros cargados', body: 'Cuando haya miembros, aquí verás quién va y quién falta por responder.');
    return Column(children: members.map((m) {
      final userId = AppData.text(m['user_id']);
      final status = eventStatusForUser(event, userId);
      final name = memberDisplayName(m);
      final color = attendanceColor(status);
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: AppCard(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11), child: Row(children: [
          CircleAvatar(radius: 18, backgroundColor: color.withOpacity(.11), child: Text(initialsFor(name), style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12))),
          const SizedBox(width: 11),
          Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w900))),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: color.withOpacity(.10), borderRadius: BorderRadius.circular(99)), child: Text(attendanceLabel(status), style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12))),
        ])),
      );
    }).toList());
  }
}

class EventCard extends StatelessWidget {
  final Map<String, dynamic> event;
  final VoidCallback onTap;
  const EventCard({super.key, required this.event, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final d = DateTime.tryParse(event['starts_at']?.toString() ?? '')?.toLocal() ?? DateTime.now();
    final yes = attendanceCount(event, 'yes');
    final maybe = attendanceCount(event, 'maybe');
    final minPeople = AppData.intValue(event['min_people'], 2);
    final viable = yes >= minPeople;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(onTap: onTap, child: Row(children: [
        DateBadge(date: d),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(AppData.text(event['title'], 'Evento'), style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 5),
          MetaLine(icon: Icons.schedule_rounded, text: DateFormat('dd/MM · HH:mm', 'es_ES').format(d)),
          MetaLine(icon: Icons.place_outlined, text: AppData.text(event['location'], 'Sin ubicación')),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: viable ? const Color(0xFFEAF8F0) : const Color(0xFFFFF6DF), borderRadius: BorderRadius.circular(99)), child: Text(viable ? '$yes/$minPeople OK' : '$yes/$minPeople', style: TextStyle(color: viable ? AppColors.green : AppColors.amber, fontWeight: FontWeight.w900, fontSize: 12))),
          const SizedBox(height: 6),
          Text('$maybe en duda', style: const TextStyle(color: AppColors.muted, fontSize: 11, fontWeight: FontWeight.w700)),
        ]),
      ])),
    );
  }
}

class EventMiniCard extends StatelessWidget {
  final Map<String, dynamic> event;
  const EventMiniCard({super.key, required this.event});
  @override
  Widget build(BuildContext context) {
    final d = DateTime.tryParse(event['starts_at']?.toString() ?? '')?.toLocal() ?? DateTime.now();
    return AppCard(child: Row(children: [
      DateBadge(date: d),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(AppData.text(event['title'], 'Evento'), style: const TextStyle(fontWeight: FontWeight.w900)),
        Text(dateLabel(d), style: const TextStyle(color: AppColors.muted)),
      ])),
    ]));
  }
}

class ExpenseCard extends StatelessWidget {
  final Map<String, dynamic> expense;
  final List<Map<String, dynamic>> members;
  final VoidCallback? onTap;
  const ExpenseCard({super.key, required this.expense, required this.members, this.onTap});

  @override
  Widget build(BuildContext context) {
    final paidBy = expense['paid_by']?.toString() ?? '';
    final amount = AppData.doubleValue(expense['amount']);
    final unpaid = unpaidAmount(expense);
    final settled = unpaid <= 0.01 || AppData.text(expense['status']) == 'paid';
    final participants = expenseParticipants(expense).length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: AppCard(
        onTap: onTap,
        child: Row(children: [
          CircleAvatar(
            backgroundColor: settled ? AppColors.tealSoft : AppColors.teal,
            child: Icon(settled ? Icons.verified_rounded : Icons.receipt_long_rounded, color: settled ? AppColors.teal : Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(AppData.text(expense['concept'], 'Gasto'), style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text('Pagó ${financeMemberName(paidBy, members)} · $participants participantes', style: const TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 7),
            _MiniChip(text: settled ? 'Liquidado' : 'Pendiente ${money(unpaid)}', color: settled ? AppColors.green : AppColors.orange),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(money(amount), style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 3),
            const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
          ]),
        ]),
      ),
    );
  }
}

class TournamentCard extends StatelessWidget {
  final Map<String, dynamic> tournament;
  final VoidCallback? onTap;
  const TournamentCard({super.key, required this.tournament, this.onTap});

  @override
  Widget build(BuildContext context) {
    final teams = tournament['tournament_teams'] is List ? (tournament['tournament_teams'] as List).length : 0;
    final matches = tournament['matches'] is List ? (tournament['matches'] as List).length : 0;
    final played = tournament['matches'] is List ? (tournament['matches'] as List).where((m) => m is Map && m['status'] == 'played').length : 0;
    final format = AppData.text(tournament['format'], 'liga');
    final status = AppData.text(tournament['status'], 'active');
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        onTap: onTap,
        child: Row(children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: AppColors.tealSoft, borderRadius: BorderRadius.circular(14)),
            child: Icon(format == 'eliminatoria' ? Icons.account_tree_rounded : format == 'americano' ? Icons.sync_alt_rounded : Icons.emoji_events_rounded, color: AppColors.teal, size: 34),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(AppData.text(tournament['name'], 'Torneo'), style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 3),
            Text('${tournamentFormatLabel(format)} · ${teamTypeLabel(AppData.text(tournament['team_type'], 'equipo'))}', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 5),
            Wrap(spacing: 6, runSpacing: 6, children: [
              _MiniChip(text: '$teams participantes', color: AppColors.teal),
              _MiniChip(text: '$played/$matches jugados', color: AppColors.violet),
              _MiniChip(text: status == 'finished' ? 'Finalizado' : 'En curso', color: status == 'finished' ? AppColors.muted : AppColors.green),
            ]),
          ])),
          const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        ]),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String text;
  final Color color;
  const _MiniChip({required this.text, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: color.withOpacity(.10), borderRadius: BorderRadius.circular(99)),
    child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 11)),
  );
}

class MemberCard extends StatelessWidget {
  final Map<String, dynamic> member;
  const MemberCard({super.key, required this.member});

  @override
  Widget build(BuildContext context) {
    final profile = AppData.asMap(member['profiles']);
    final role = AppData.text(member['role'], 'member');
    final name = memberName(member);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        child: Row(children: [
          ProfileAvatar(name: name, avatarUrl: AppData.text(profile['avatar_url']), radius: 22),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.w900)),
            Text(AppData.text(profile['email'], 'sin email'), style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(color: role == 'member' ? AppColors.faint : AppColors.tealSoft, borderRadius: BorderRadius.circular(99)),
            child: Text(
              role == 'owner' ? 'OWNER' : role == 'admin' ? 'ADMIN' : 'MIEMBRO',
              style: TextStyle(color: role == 'member' ? AppColors.muted : AppColors.teal, fontWeight: FontWeight.w900, fontSize: 11),
            ),
          ),
        ]),
      ),
    );
  }
}

String memberName(Map<String, dynamic> member) {
  final profile = AppData.asMap(member['profiles']);
  final fullName = AppData.text(profile['full_name']);
  if (fullName.isNotEmpty && fullName != 'Usuario') return fullName;
  final email = AppData.text(profile['email']);
  if (email.contains('@')) return email.split('@').first;
  return 'Miembro';
}


class ManageMemberCard extends StatelessWidget {
  final Map<String, dynamic> member;
  final bool canManage;
  final Future<void> Function(Map<String, dynamic> member, String role) onRole;
  final Future<void> Function(Map<String, dynamic> member) onRemove;
  const ManageMemberCard({super.key, required this.member, required this.canManage, required this.onRole, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final profile = AppData.asMap(member['profiles']);
    final role = AppData.text(member['role'], 'member');
    final name = memberName(member);
    final isMe = member['user_id']?.toString() == AppData.user?.id;
    final canEditThis = canManage && role != 'owner' && !isMe;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        child: Row(children: [
          ProfileAvatar(name: name, avatarUrl: AppData.text(profile['avatar_url']), radius: 22),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(isMe ? '$name (Tú)' : name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900))),
              RoleBadge(role: role),
            ]),
            const SizedBox(height: 3),
            Text(AppData.text(profile['email'], 'sin email'), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          ])),
          if (canEditThis)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_horiz_rounded, color: AppColors.muted),
              onSelected: (value) {
                if (value == 'admin') onRole(member, 'admin');
                if (value == 'member') onRole(member, 'member');
                if (value == 'remove') onRemove(member);
              },
              itemBuilder: (context) => [
                if (role != 'admin') const PopupMenuItem(value: 'admin', child: Text('Hacer admin')),
                if (role == 'admin') const PopupMenuItem(value: 'member', child: Text('Quitar admin')),
                const PopupMenuDivider(),
                const PopupMenuItem(value: 'remove', child: Text('Expulsar del grupo')),
              ],
            ),
        ]),
      ),
    );
  }
}

class RoleBadge extends StatelessWidget {
  final String role;
  const RoleBadge({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final color = role == 'owner' ? AppColors.orange : role == 'admin' ? AppColors.teal : AppColors.muted;
    final text = role == 'owner' ? 'OWNER' : role == 'admin' ? 'ADMIN' : 'MIEMBRO';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(.10), borderRadius: BorderRadius.circular(99)),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 10.5)),
    );
  }
}

class SettingsRow extends StatelessWidget { final IconData icon; final String title; final String subtitle; final VoidCallback onTap; final bool danger; const SettingsRow({super.key, required this.icon, required this.title, required this.subtitle, required this.onTap, this.danger = false}); @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 9), child: AppCard(onTap: onTap, child: Row(children: [Icon(icon, color: danger ? AppColors.red : AppColors.ink), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontWeight: FontWeight.w900, color: danger ? AppColors.red : AppColors.ink)), Text(subtitle, style: const TextStyle(color: AppColors.muted, fontSize: 12))])), const Icon(Icons.chevron_right_rounded, color: AppColors.muted)]))); }

class MetaLine extends StatelessWidget { final IconData icon; final String text; const MetaLine({super.key, required this.icon, required this.text}); @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 3), child: Row(children: [Icon(icon, size: 15, color: AppColors.muted), const SizedBox(width: 5), Expanded(child: Text(text, style: const TextStyle(color: AppColors.muted, fontSize: 12.5)))])); }

class AttendancePick extends StatelessWidget { final String label; final int count; final bool selected; final Color color; final VoidCallback onTap; const AttendancePick({super.key, required this.label, required this.count, required this.selected, required this.color, required this.onTap}); @override Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(15), child: Container(padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: selected ? color.withOpacity(.10) : Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: selected ? color : AppColors.line)), child: Column(children: [Icon(selected ? Icons.check_circle_rounded : Icons.circle_outlined, color: color), const SizedBox(height: 4), Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w900)), Text(count.toString(), style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 18))]))); }

class StatusNotice extends StatelessWidget { final bool ok; final String text; const StatusNotice({super.key, required this.ok, required this.text}); @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: ok ? const Color(0xFFEAF8F0) : const Color(0xFFFFF6DF), borderRadius: BorderRadius.circular(14), border: Border.all(color: ok ? const Color(0xFFBFEBD2) : const Color(0xFFFFE3A6))), child: Row(children: [Icon(ok ? Icons.check_circle_rounded : Icons.info_rounded, color: ok ? AppColors.green : AppColors.amber), const SizedBox(width: 10), Expanded(child: Text(text, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink)))])); }

class SmallPick extends StatelessWidget { final String label; final String value; final IconData icon; final VoidCallback onTap; const SmallPick({super.key, required this.label, required this.value, required this.icon, required this.onTap}); @override Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [FieldLabel(label), InkWell(onTap: onTap, borderRadius: BorderRadius.circular(15), child: Container(height: 50, padding: const EdgeInsets.symmetric(horizontal: 12), decoration: BoxDecoration(border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(15)), child: Row(children: [Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w800))), Icon(icon, color: AppColors.muted, size: 20)])))]); }

class StepperRow extends StatelessWidget { final int value; final VoidCallback onMinus; final VoidCallback onPlus; const StepperRow({super.key, required this.value, required this.onMinus, required this.onPlus}); @override Widget build(BuildContext context) => AppCard(child: Row(children: [const Icon(Icons.groups_rounded, color: AppColors.muted), const SizedBox(width: 12), Text(value.toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)), const Spacer(), IconButton(onPressed: onMinus, icon: const Icon(Icons.remove_rounded)), IconButton(onPressed: onPlus, icon: const Icon(Icons.add_rounded))])); }

class MonthGrid extends StatelessWidget { final DateTime month; final DateTime selected; final List<Map<String, dynamic>> events; final ValueChanged<DateTime> onSelect; const MonthGrid({super.key, required this.month, required this.selected, required this.events, required this.onSelect}); @override Widget build(BuildContext context) { final first = DateTime(month.year, month.month, 1); final startOffset = (first.weekday + 6) % 7; final days = DateTime(month.year, month.month + 1, 0).day; final cells = <DateTime?>[]; for (int i = 0; i < startOffset; i++) cells.add(null); for (int d = 1; d <= days; d++) cells.add(DateTime(month.year, month.month, d)); while (cells.length % 7 != 0) cells.add(null); return Column(children: [Row(children: ['L','M','X','J','V','S','D'].map((d) => Expanded(child: Center(child: Text(d, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.muted, fontSize: 12))))).toList()), const SizedBox(height: 8), GridView.count(crossAxisCount: 7, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), childAspectRatio: 1.05, children: cells.map((day) { if (day == null) return const SizedBox(); final active = day.year == selected.year && day.month == selected.month && day.day == selected.day; final has = events.any((e) { final d = DateTime.tryParse(e['starts_at']?.toString() ?? '')?.toLocal(); return d != null && d.year == day.year && d.month == day.month && d.day == day.day; }); return InkWell(onTap: () => onSelect(day), borderRadius: BorderRadius.circular(20), child: Container(margin: const EdgeInsets.all(3), decoration: BoxDecoration(color: active ? AppColors.teal : Colors.transparent, shape: BoxShape.circle), child: Stack(alignment: Alignment.center, children: [Text(day.day.toString(), style: TextStyle(color: active ? Colors.white : AppColors.ink, fontWeight: FontWeight.w800)), if (has) Positioned(bottom: 6, child: Container(width: 5, height: 5, decoration: BoxDecoration(color: active ? Colors.white : AppColors.teal, shape: BoxShape.circle))) ]))); }).toList())]); }}

class PatternIcons extends StatelessWidget { @override Widget build(BuildContext context) => Wrap(spacing: 24, runSpacing: 20, children: List.generate(70, (i) => Icon([Icons.event_available_rounded, Icons.calendar_month_rounded, Icons.account_balance_wallet_rounded, Icons.emoji_events_rounded, Icons.lock_rounded, Icons.qr_code_rounded][i % 6], size: 17, color: Colors.white))); }

void showCodeSheet(BuildContext context, String code, String groupName) { showModalBottomSheet(context: context, showDragHandle: true, builder: (context) => Padding(padding: const EdgeInsets.fromLTRB(22, 10, 22, 30), child: Column(mainAxisSize: MainAxisSize.min, children: [Text('Código de invitación', style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 12), Container(width: double.infinity, padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: AppColors.tealSoft, borderRadius: BorderRadius.circular(18)), child: Center(child: Text(code, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: 3, color: AppColors.teal)))), const SizedBox(height: 16), PrimaryButton(label: 'Compartir código', icon: Icons.share_rounded, onTap: () => Share.share('Únete a $groupName en Grupli con el código $code'))]))); }
