import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
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
  static const ink = Color(0xFF111B34);
  static const muted = Color(0xFF67718A);
  static const faint = Color(0xFFF6F8FB);
  static const line = Color(0xFFE3E8EF);
  static const teal = Color(0xFF008F86);
  static const tealDark = Color(0xFF006B69);
  static const tealSoft = Color(0xFFEAF9F7);
  static const blue = Color(0xFF3767FF);
  static const violet = Color(0xFF6E56E8);
  static const orange = Color(0xFFF28B20);
  static const green = Color(0xFF0C9D61);
  static const red = Color(0xFFE24A4A);
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
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.teal, background: AppColors.white),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(fontSize: 31, fontWeight: FontWeight.w900, color: AppColors.ink, height: 1.05),
          headlineMedium: TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: AppColors.ink, height: 1.08),
          titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.ink),
          titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink),
          bodyLarge: TextStyle(fontSize: 15, color: AppColors.ink, height: 1.35),
          bodyMedium: TextStyle(fontSize: 13.5, color: AppColors.muted, height: 1.35),
          labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.white,
          hintStyle: const TextStyle(color: Color(0xFF9AA4B5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: AppColors.line)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: AppColors.line)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: AppColors.teal, width: 1.4)),
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

  static Future<List<Map<String, dynamic>>> events(String groupId) async {
    final res = await sb.from('events').select('*, event_attendance(status,user_id)').eq('group_id', groupId).order('starts_at');
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
    final current = user?.id;
    final expense = await sb.from('expenses').insert({
      'group_id': groupId,
      'concept': concept.trim(),
      'amount': amount,
      'paid_by': paidBy,
      'created_by': current,
      'note': note.trim().isEmpty ? null : note.trim(),
    }).select('id').single();
    final expenseId = expense['id'].toString();
    final share = participantIds.isEmpty ? amount : amount / participantIds.length;
    final rows = participantIds.map((id) => {
      'expense_id': expenseId,
      'user_id': id,
      'share_amount': double.parse(share.toStringAsFixed(2)),
      'paid': id == paidBy,
    }).toList();
    if (rows.isNotEmpty) await sb.from('expense_participants').insert(rows);
    return expenseId;
  }

  static Future<List<Map<String, dynamic>>> tournaments(String groupId) async {
    final res = await sb.from('tournaments').select('*, tournament_teams(id), matches(id,status)').eq('group_id', groupId).order('created_at', ascending: false);
    return asList(res);
  }

  static Future<String> createTournament(String groupId, String name) async {
    final row = await sb.from('tournaments').insert({
      'group_id': groupId,
      'name': name.trim(),
      'format': 'liga',
      'team_type': 'equipo',
      'created_by': user?.id,
    }).select('id').single();
    return row['id'].toString();
  }
}

String dateLabel(DateTime date) {
  return DateFormat('dd/MM · HH:mm').format(date.toLocal());
}

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

String myAttendanceStatus(Map<String, dynamic> event) {
  final uid = AppData.user?.id;
  final attendance = event['event_attendance'];
  if (uid == null || attendance is! List) return '';
  for (final item in attendance) {
    if (item is Map && item['user_id']?.toString() == uid) {
      return item['status']?.toString() ?? '';
    }
  }
  return '';
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
          GroupDashboardTab(group: group, refreshSeed: refreshKey),
          CalendarTab(group: group, refreshSeed: refreshKey),
          FinancesTab(group: group, refreshSeed: refreshKey),
          TournamentsTab(group: group, refreshSeed: refreshKey),
          GroupMoreTab(group: group, refresh: refresh),
        ];
        return Scaffold(
          backgroundColor: AppColors.white,
          body: pages[tab],
          bottomNavigationBar: GroupBottomNav(groupName: name, index: tab, onTap: (i) => setState(() => tab = i)),
        );
      },
    );
  }
}

class GroupDashboardTab extends StatefulWidget {
  final Map<String, dynamic> group;
  final int refreshSeed;
  const GroupDashboardTab({super.key, required this.group, required this.refreshSeed});

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

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    final groupId = group['id'].toString();
    final name = AppData.text(group['name'], 'Grupo');
    final code = AppData.text(group['invite_code'], '------');

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
              final confirmed = upcoming.fold<int>(0, (sum, e) => sum + attendanceCount(e, 'yes'));
              final pendingDecisions = upcoming.fold<int>(0, (sum, e) => sum + attendanceCount(e, 'maybe'));
              final expensesTotal = data?.expensesTotal ?? 0;
              final tournamentsActive = data?.activeTournaments ?? 0;

              return RefreshIndicator(
                color: AppColors.teal,
                onRefresh: () async => reload(),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 112),
                  children: [
                    Row(children: [
                      RoundBackButton(onTap: () => Navigator.of(context).pop()),
                      const Spacer(),
                      CircleIconButton(icon: Icons.more_horiz_rounded, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => GroupSettingsScreen(group: group)))),
                    ]),
                    const SizedBox(height: 12),
                    GroupHeroCard(name: name, code: code, onInvite: () => Share.share('Únete a $name en Grupli con el código $code'), onCode: () => showCodeSheet(context, code, name)),
                    const SizedBox(height: 14),
                    Row(children: [
                      Expanded(child: MiniAction(icon: Icons.person_add_alt_1_rounded, label: 'Invitar', onTap: () => Share.share('Únete a $name en Grupli con el código $code'))),
                      const SizedBox(width: 8),
                      Expanded(child: MiniAction(icon: Icons.qr_code_rounded, label: 'Código', onTap: () => showCodeSheet(context, code, name))),
                      const SizedBox(width: 8),
                      Expanded(child: MiniAction(icon: Icons.groups_rounded, label: 'Miembros', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => MembersScreen(group: group))))),
                      const SizedBox(width: 8),
                      Expanded(child: MiniAction(icon: Icons.settings_rounded, label: 'Ajustes', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => GroupSettingsScreen(group: group))))),
                    ]),
                    const SizedBox(height: 18),
                    if (snapshot.connectionState == ConnectionState.waiting)
                      const CenterLoader(label: 'Cargando resumen...')
                    else if (snapshot.hasError)
                      ErrorBlock(message: snapshot.error.toString(), onRetry: reload)
                    else ...[
                      Row(children: [
                        Expanded(child: StatCard(icon: Icons.event_available_rounded, value: upcoming.length.toString(), label: 'Próximos', color: AppColors.teal)),
                        const SizedBox(width: 10),
                        Expanded(child: StatCard(icon: Icons.check_circle_rounded, value: confirmed.toString(), label: 'Confirmados', color: AppColors.green)),
                        const SizedBox(width: 10),
                        Expanded(child: StatCard(icon: Icons.emoji_events_rounded, value: tournamentsActive.toString(), label: 'Torneos', color: AppColors.orange)),
                      ]),
                      const SizedBox(height: 18),
                      SectionHeader(title: 'Resumen del grupo', action: 'Actualizar', onTap: reload),
                      const SizedBox(height: 10),
                      if (nextEvent == null)
                        EmptyBlock(
                          icon: Icons.event_available_rounded,
                          title: 'No hay ninguna quedada creada',
                          body: 'Crea el primer evento para que el grupo pueda confirmar asistencia desde esta pantalla.',
                        )
                      else
                        DashboardEventCard(event: nextEvent, group: group, onChanged: reload),
                      const SizedBox(height: 18),
                      SectionHeader(title: 'Próximos eventos', action: 'Crear evento', onTap: () async {
                        final ok = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => CreateEventScreen(group: group)));
                        if (ok == true) reload();
                      }),
                      const SizedBox(height: 10),
                      if (upcoming.isEmpty)
                        EmptySlim(icon: Icons.calendar_month_rounded, title: 'Agenda vacía', body: 'El calendario del grupo aún no tiene eventos próximos.')
                      else
                        ...upcoming.take(4).map((e) => EventCard(event: e, onTap: () async {
                          await Navigator.of(context).push(MaterialPageRoute(builder: (_) => EventDetailScreen(event: e, group: group)));
                          reload();
                        })),
                      const SizedBox(height: 18),
                      Text('Estado rápido', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 10),
                      Grid2(children: [
                        FeatureTile(icon: Icons.calendar_month_rounded, title: 'Calendario', body: '${events.length} eventos totales', color: AppColors.blue, onTap: () {}),
                        FeatureTile(icon: Icons.account_balance_wallet_rounded, title: 'Finanzas', body: money(expensesTotal), color: AppColors.green, onTap: () {}),
                        FeatureTile(icon: Icons.help_outline_rounded, title: 'Por decidir', body: '$pendingDecisions respuestas en duda', color: AppColors.amber, onTap: () {}),
                        FeatureTile(icon: Icons.lock_rounded, title: 'Privado', body: 'Solo por invitación', color: AppColors.teal, onTap: () {}),
                      ]),
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
          PageHeader(title: 'Más', subtitle: name, leading: true),
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
  const CreateEventScreen({super.key, required this.group, this.initialDate});

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

  @override
  void initState() {
    super.initState();
    date = widget.initialDate ?? DateTime.now().add(const Duration(days: 1));
  }

  @override
  void dispose() {
    title.dispose(); location.dispose(); notes.dispose(); super.dispose();
  }

  Future<void> save() async {
    if (title.text.trim().isEmpty) { await showToast(context, 'Pon un título para el evento.', danger: true); return; }
    final start = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() => loading = true);
    try {
      await AppData.createEvent(widget.group['id'].toString(), title.text, start, location.text, notes.text, minPeople);
      if (mounted) Navigator.pop(context, true);
    } catch (e) { await showToast(context, e.toString(), danger: true); }
    finally { if (mounted) setState(() => loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return DirectPage(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeader(title: 'Nuevo evento', subtitle: AppData.text(widget.group['name']), leading: true),
      const SizedBox(height: 20),
      FieldLabel('Título del evento'),
      TextField(controller: title, decoration: const InputDecoration(hintText: 'Ej. Partido amistoso')),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(child: SmallPick(label: 'Fecha', value: DateFormat('dd/MM/yyyy').format(date), icon: Icons.calendar_month_rounded, onTap: () async { final d = await showDatePicker(context: context, initialDate: date, firstDate: DateTime.now().subtract(const Duration(days: 1)), lastDate: DateTime.now().add(const Duration(days: 730))); if (d != null) setState(() => date = d); })),
        const SizedBox(width: 10),
        Expanded(child: SmallPick(label: 'Hora', value: time.format(context), icon: Icons.schedule_rounded, onTap: () async { final t = await showTimePicker(context: context, initialTime: time); if (t != null) setState(() => time = t); })),
      ]),
      const SizedBox(height: 14),
      FieldLabel('Lugar'),
      TextField(controller: location, decoration: const InputDecoration(prefixIcon: Icon(Icons.place_outlined), hintText: 'Ej. Club de Pádel La Moraleja')),
      const SizedBox(height: 14),
      FieldLabel('Descripción opcional'),
      TextField(controller: notes, maxLines: 4, decoration: const InputDecoration(hintText: 'Añade detalles...')),
      const SizedBox(height: 14),
      FieldLabel('Mínimo de asistentes'),
      StepperRow(value: minPeople, onMinus: () => setState(() => minPeople = max(1, minPeople - 1)), onPlus: () => setState(() => minPeople++)),
      const SizedBox(height: 22),
      PrimaryButton(label: 'Guardar evento', loading: loading, onTap: save),
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
  String? myStatus;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final uid = AppData.user?.id;
    final att = widget.event['event_attendance'];
    if (att is List && uid != null) {
      for (final item in att) {
        final row = Map<String, dynamic>.from(item as Map);
        if (row['user_id'] == uid) myStatus = row['status']?.toString();
      }
    }
  }

  Future<void> setStatus(String status) async {
    setState(() { saving = true; myStatus = status; });
    try { await AppData.setAttendance(widget.event['id'].toString(), status); }
    catch (e) { await showToast(context, e.toString(), danger: true); }
    finally { if (mounted) setState(() => saving = false); }
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final date = DateTime.tryParse(event['starts_at']?.toString() ?? '') ?? DateTime.now();
    final att = event['event_attendance'];
    final yes = att is List ? att.where((x) => (x as Map)['status'] == 'yes').length : 0;
    final maybe = att is List ? att.where((x) => (x as Map)['status'] == 'maybe').length : 0;
    final no = att is List ? att.where((x) => (x as Map)['status'] == 'no').length : 0;
    final minPeople = AppData.intValue(event['min_people'], 2);
    return DirectPage(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeader(title: AppData.text(event['title'], 'Evento'), subtitle: dateLabel(date), leading: true),
      const SizedBox(height: 10),
      MetaLine(icon: Icons.place_outlined, text: AppData.text(event['location'], 'Sin ubicación')),
      const SizedBox(height: 14),
      if (AppData.text(event['notes']).isNotEmpty) AppCard(child: Text(AppData.text(event['notes']), style: Theme.of(context).textTheme.bodyMedium)),
      const SizedBox(height: 18),
      Text('Asistencia', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: AttendancePick(label: 'Voy', count: yes, selected: myStatus == 'yes', color: AppColors.green, onTap: () => setStatus('yes'))),
        const SizedBox(width: 8),
        Expanded(child: AttendancePick(label: 'Duda', count: maybe, selected: myStatus == 'maybe', color: AppColors.amber, onTap: () => setStatus('maybe'))),
        const SizedBox(width: 8),
        Expanded(child: AttendancePick(label: 'No voy', count: no, selected: myStatus == 'no', color: AppColors.red, onTap: () => setStatus('no'))),
      ]),
      const SizedBox(height: 12),
      StatusNotice(ok: yes >= minPeople, text: yes >= minPeople ? '¡Genial! Se alcanzó el mínimo de $minPeople asistentes.' : 'Faltan ${max(0, minPeople - yes)} confirmaciones para llegar al mínimo.'),
      if (saving) const Padding(padding: EdgeInsets.only(top: 12), child: LinearProgressIndicator()),
    ]));
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
              return ListView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 100), children: [ErrorBlock(message: snapshot.error.toString(), onRetry: reload)]);
            }
            final events = snapshot.data ?? [];
            final selectedEvents = events.where((e) {
              final d = DateTime.tryParse(e['starts_at']?.toString() ?? '')?.toLocal();
              return d != null && d.year == selected.year && d.month == selected.month && d.day == selected.day;
            }).toList();
            return ListView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 112), children: [
              PageHeader(title: 'Calendario', subtitle: AppData.text(widget.group['name']), leading: true),
              const SizedBox(height: 18),
              AppCard(child: Column(children: [
                Row(children: [
                  IconButton(onPressed: () => setState(() => month = DateTime(month.year, month.month - 1)), icon: const Icon(Icons.chevron_left_rounded)),
                  Expanded(child: Center(child: Text(DateFormat('MMMM yyyy').format(month), style: Theme.of(context).textTheme.titleMedium))),
                  IconButton(onPressed: () => setState(() => month = DateTime(month.year, month.month + 1)), icon: const Icon(Icons.chevron_right_rounded)),
                ]),
                const SizedBox(height: 10),
                MonthGrid(month: month, selected: selected, events: events, onSelect: (d) => setState(() => selected = d)),
              ])),
              const SizedBox(height: 22),
              SectionHeader(title: DateFormat('EEEE dd/MM').format(selected), action: 'Añadir', onTap: () async {
                final ok = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => CreateEventScreen(group: widget.group, initialDate: selected)));
                if (ok == true) reload();
              }),
              const SizedBox(height: 10),
              if (selectedEvents.isEmpty)
                EmptySlim(icon: Icons.calendar_month_rounded, title: 'Día sin eventos', body: 'Puedes crear una quedada para este día con el botón +.')
              else
                ...selectedEvents.map((e) => EventCard(event: e, onTap: () async {
                  await Navigator.of(context).push(MaterialPageRoute(builder: (_) => EventDetailScreen(event: e, group: widget.group)));
                  reload();
                })),
            ]);
          },
        ),
        Positioned(
          right: 20,
          bottom: 20,
          child: FloatingActionButton(
            heroTag: 'calendar-create-event-${widget.group['id']}',
            backgroundColor: AppColors.teal,
            foregroundColor: Colors.white,
            onPressed: () async {
              final ok = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => CreateEventScreen(group: widget.group, initialDate: selected)));
              if (ok == true) reload();
            },
            child: const Icon(Icons.add_rounded),
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
  @override State<FinancesTab> createState() => _FinancesTabState();
}

class _FinancesTabState extends State<FinancesTab> {
  late Future<List<Map<String, dynamic>>> expensesFuture;
  @override void initState() { super.initState(); load(); }
  @override void didUpdateWidget(covariant FinancesTab oldWidget) { super.didUpdateWidget(oldWidget); if (oldWidget.refreshSeed != widget.refreshSeed) load(); }
  void load() => expensesFuture = AppData.expenses(widget.group['id'].toString());
  void reload() => setState(load);

  @override
  Widget build(BuildContext context) {
    final groupId = widget.group['id'].toString();
    return SafeArea(bottom: false, child: Stack(children: [
      FutureBuilder<List<Map<String, dynamic>>>(future: expensesFuture, builder: (context, snapshot) {
        final expenses = snapshot.data ?? [];
        final total = expenses.fold<double>(0, (sum, e) => sum + AppData.doubleValue(e['amount']));
        final myId = AppData.user?.id;
        double paidByMe = 0;
        double myShare = 0;
        for (final e in expenses) {
          if (e['paid_by'] == myId) paidByMe += AppData.doubleValue(e['amount']);
          final participants = e['expense_participants'];
          if (participants is List) {
            for (final p in participants) {
              final row = Map<String, dynamic>.from(p as Map);
              if (row['user_id'] == myId) myShare += AppData.doubleValue(row['share_amount']);
            }
          }
        }
        return ListView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 100), children: [
          PageHeader(title: 'Finanzas', subtitle: AppData.text(widget.group['name']), leading: true),
          const SizedBox(height: 18),
          Row(children: [
            Expanded(child: MoneyStat(label: 'Saldo total', value: paidByMe - myShare, positiveMeansGood: true)),
            const SizedBox(width: 10),
            Expanded(child: MoneyStat(label: 'A pagar', value: -myShare, positiveMeansGood: false)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: StatCard(icon: Icons.receipt_long_rounded, value: money(total), label: 'Gastos totales', color: AppColors.teal)),
            const SizedBox(width: 10),
            Expanded(child: StatCard(icon: Icons.check_circle_outline_rounded, value: expenses.length.toString(), label: 'Pagos', color: AppColors.violet)),
          ]),
          const SizedBox(height: 24),
          Row(children: [Text('Gastos recientes', style: Theme.of(context).textTheme.titleLarge), const Spacer(), TextButton(onPressed: reload, child: const Text('Actualizar'))]),
          const SizedBox(height: 8),
          if (snapshot.connectionState == ConnectionState.waiting) const CenterLoader(label: 'Cargando gastos...') else if (snapshot.hasError) ErrorBlock(message: snapshot.error.toString(), onRetry: reload) else if (expenses.isEmpty) EmptyBlock(icon: Icons.account_balance_wallet_rounded, title: 'Sin gastos', body: 'Añade una cena, pista, gasolina o cualquier gasto compartido.') else ...expenses.map((e) => ExpenseCard(expense: e)),
        ]);
      }),
      Positioned(right: 20, bottom: 20, child: FloatingActionButton(backgroundColor: AppColors.teal, foregroundColor: Colors.white, onPressed: () async { final ok = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => CreateExpenseScreen(groupId: groupId))); if (ok == true) reload(); }, child: const Icon(Icons.add_rounded))),
    ]));
  }
}

class CreateExpenseScreen extends StatefulWidget {
  final String groupId;
  const CreateExpenseScreen({super.key, required this.groupId});
  @override State<CreateExpenseScreen> createState() => _CreateExpenseScreenState();
}

class _CreateExpenseScreenState extends State<CreateExpenseScreen> {
  final concept = TextEditingController();
  final amount = TextEditingController();
  final note = TextEditingController();
  bool loading = false;
  String? paidBy;
  final selected = <String>{};
  late Future<List<Map<String, dynamic>>> membersFuture;
  @override void initState() { super.initState(); membersFuture = AppData.members(widget.groupId); }
  @override void dispose() { concept.dispose(); amount.dispose(); note.dispose(); super.dispose(); }

  Future<void> save() async {
    final value = double.tryParse(amount.text.replaceAll(',', '.')) ?? 0;
    if (concept.text.trim().isEmpty || value <= 0 || paidBy == null || selected.isEmpty) { await showToast(context, 'Completa concepto, importe, pagador y participantes.', danger: true); return; }
    setState(() => loading = true);
    try { await AppData.createExpense(widget.groupId, concept.text, value, paidBy!, selected.toList(), note.text); if (mounted) Navigator.pop(context, true); }
    catch (e) { await showToast(context, e.toString(), danger: true); }
    finally { if (mounted) setState(() => loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return DirectPage(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeader(title: 'Nuevo gasto', subtitle: 'Reparto estilo Tricount', leading: true),
      const SizedBox(height: 18),
      FieldLabel('Concepto'), TextField(controller: concept, decoration: const InputDecoration(hintText: 'Cena después del partido')),
      const SizedBox(height: 12),
      FieldLabel('Importe'), TextField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(hintText: '0,00 €')),
      const SizedBox(height: 18),
      FutureBuilder<List<Map<String, dynamic>>>(future: membersFuture, builder: (context, snapshot) {
        final members = snapshot.data ?? [];
        if (paidBy == null && members.isNotEmpty) paidBy = members.first['user_id'].toString();
        if (selected.isEmpty && members.isNotEmpty) selected.addAll(members.map((m) => m['user_id'].toString()));
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          FieldLabel('Pagado por'),
          DropdownButtonFormField<String>(value: paidBy, items: members.map((m) => DropdownMenuItem(value: m['user_id'].toString(), child: Text(memberName(m)))).toList(), onChanged: (v) => setState(() => paidBy = v)),
          const SizedBox(height: 18),
          FieldLabel('Dividido entre'),
          Wrap(spacing: 9, runSpacing: 9, children: members.map((m) {
            final id = m['user_id'].toString();
            final active = selected.contains(id);
            return FilterChip(label: Text(memberName(m)), selected: active, onSelected: (v) => setState(() { if (v) selected.add(id); else selected.remove(id); }));
          }).toList()),
        ]);
      }),
      const SizedBox(height: 18), FieldLabel('Nota opcional'), TextField(controller: note, maxLines: 3, decoration: const InputDecoration(hintText: 'Añade notas...')),
      const SizedBox(height: 24), PrimaryButton(label: 'Guardar gasto', loading: loading, onTap: save),
    ]));
  }
}

class TournamentsTab extends StatefulWidget {
  final Map<String, dynamic> group;
  final int refreshSeed;
  const TournamentsTab({super.key, required this.group, required this.refreshSeed});
  @override State<TournamentsTab> createState() => _TournamentsTabState();
}

class _TournamentsTabState extends State<TournamentsTab> {
  late Future<List<Map<String, dynamic>>> future;
  @override void initState() { super.initState(); load(); }
  void load() => future = AppData.tournaments(widget.group['id'].toString());
  void reload() => setState(load);

  Future<void> createTournament() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(context: context, builder: (context) => AlertDialog(
      title: const Text('Crear torneo'),
      content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'Liga de Pádel')),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')), FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Crear'))],
    ));
    if (result == null || result.trim().isEmpty) return;
    try { await AppData.createTournament(widget.group['id'].toString(), result); reload(); }
    catch (e) { await showToast(context, e.toString(), danger: true); }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(bottom: false, child: Stack(children: [
      FutureBuilder<List<Map<String, dynamic>>>(future: future, builder: (context, snapshot) {
        final tournaments = snapshot.data ?? [];
        return ListView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 100), children: [
          PageHeader(title: 'Torneos / Ligas', subtitle: AppData.text(widget.group['name']), leading: true),
          const SizedBox(height: 18),
          if (snapshot.connectionState == ConnectionState.waiting) const CenterLoader(label: 'Cargando torneos...') else if (snapshot.hasError) ErrorBlock(message: snapshot.error.toString(), onRetry: reload) else if (tournaments.isEmpty) EmptyBlock(icon: Icons.emoji_events_rounded, title: 'Sin torneos todavía', body: 'Crea una liga, copa o torneo para organizar la competición del grupo.') else ...tournaments.map((t) => TournamentCard(tournament: t)),
        ]);
      }),
      Positioned(right: 20, bottom: 20, child: FloatingActionButton(backgroundColor: AppColors.teal, foregroundColor: Colors.white, onPressed: createTournament, child: const Icon(Icons.add_rounded))),
    ]));
  }
}

class MembersScreen extends StatefulWidget {
  final Map<String, dynamic> group;
  const MembersScreen({super.key, required this.group});
  @override State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  late Future<List<Map<String, dynamic>>> future;
  @override void initState() { super.initState(); future = AppData.members(widget.group['id'].toString()); }
  void reload() => setState(() => future = AppData.members(widget.group['id'].toString()));

  @override
  Widget build(BuildContext context) {
    return DirectPage(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeader(title: 'Miembros', subtitle: AppData.text(widget.group['name']), leading: true),
      const SizedBox(height: 18),
      FutureBuilder<List<Map<String, dynamic>>>(future: future, builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const CenterLoader(label: 'Cargando miembros...');
        if (snapshot.hasError) return ErrorBlock(message: snapshot.error.toString(), onRetry: reload);
        final members = snapshot.data ?? [];
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Expanded(child: StatCard(icon: Icons.groups_rounded, value: members.length.toString(), label: 'Total', color: AppColors.teal)), const SizedBox(width: 10), Expanded(child: StatCard(icon: Icons.admin_panel_settings_rounded, value: members.where((m) => ['owner','admin'].contains(m['role'])).length.toString(), label: 'Admins', color: AppColors.violet))]),
          const SizedBox(height: 16),
          ...members.map((m) => MemberCard(member: m)),
        ]);
      })
    ]));
  }
}

class GroupSettingsScreen extends StatelessWidget {
  final Map<String, dynamic> group;
  const GroupSettingsScreen({super.key, required this.group});
  @override Widget build(BuildContext context) {
    return DirectPage(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeader(title: 'Más', subtitle: AppData.text(group['name']), leading: true),
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

class ProfileScreen extends StatelessWidget {
  final VoidCallback onChanged;
  const ProfileScreen({super.key, required this.onChanged});
  @override Widget build(BuildContext context) {
    final user = AppData.user;
    final name = (user?.email ?? 'usuario@email.com').split('@').first;
    return DirectPage(child: Column(children: [
      const SizedBox(height: 10),
      const CircleAvatar(radius: 44, backgroundColor: AppColors.tealSoft, child: Icon(Icons.person_rounded, color: AppColors.teal, size: 50)),
      const SizedBox(height: 14),
      Text(name, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 2), Text(user?.email ?? '', style: Theme.of(context).textTheme.bodyMedium),
      const SizedBox(height: 22),
      SettingsRow(icon: Icons.edit_rounded, title: 'Editar perfil', subtitle: 'Nombre y foto', onTap: () => showToast(context, 'Edición de perfil preparada para la siguiente fase.')),
      SettingsRow(icon: Icons.admin_panel_settings_outlined, title: 'Administrar grupos', subtitle: 'Tus grupos y roles', onTap: () {}),
      SettingsRow(icon: Icons.notifications_none_rounded, title: 'Notificaciones', subtitle: 'Eventos, gastos y torneos', onTap: () {}),
      SettingsRow(icon: Icons.help_outline_rounded, title: 'Ayuda y soporte', subtitle: 'Centro de ayuda y contacto', onTap: () {}),
      const SizedBox(height: 18),
      DangerButton(label: 'Cerrar sesión', icon: Icons.logout_rounded, onTap: () => AppData.sb.auth.signOut()),
    ]));
  }
}

class GroupHeroCard extends StatelessWidget {
  final String name;
  final String code;
  final VoidCallback onInvite;
  final VoidCallback onCode;
  const GroupHeroCard({super.key, required this.name, required this.code, required this.onInvite, required this.onCode});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(colors: [Color(0xFF044D68), Color(0xFF008F86)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Stack(children: [
        Positioned.fill(child: Opacity(opacity: .13, child: PatternIcons())),
        Positioned(left: 18, right: 18, bottom: 18, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Expanded(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w900))), const Icon(Icons.lock_rounded, color: Colors.white, size: 17)]),
          const SizedBox(height: 5),
          const Text('Grupo privado · Resumen general', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: GestureDetector(onTap: onCode, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), decoration: BoxDecoration(color: Colors.white.withOpacity(.15), borderRadius: BorderRadius.circular(14)), child: Text('Código $code', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900))))),
            const SizedBox(width: 10),
            InkWell(onTap: onInvite, borderRadius: BorderRadius.circular(14), child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.ios_share_rounded, color: AppColors.teal, size: 20))),
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
          width: 62,
          height: 62,
          decoration: BoxDecoration(color: AppColors.tealSoft, borderRadius: BorderRadius.circular(16)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(DateFormat('EEE').format(date).replaceAll('.', '').toUpperCase(), style: const TextStyle(color: AppColors.teal, fontSize: 11, fontWeight: FontWeight.w900)),
            Text(date.day.toString(), style: const TextStyle(color: AppColors.ink, fontSize: 23, fontWeight: FontWeight.w900)),
          ]),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(AppData.text(event['title'], 'Evento'), style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 5),
          MetaLine(icon: Icons.schedule_rounded, text: DateFormat('HH:mm').format(date)),
          MetaLine(icon: Icons.place_outlined, text: AppData.text(event['location'], 'Sin ubicación')),
        ])),
        IconButton(onPressed: () async {
          await Navigator.of(context).push(MaterialPageRoute(builder: (_) => EventDetailScreen(event: event, group: widget.group)));
          widget.onChanged();
        }, icon: const Icon(Icons.chevron_right_rounded)),
      ]),
      const SizedBox(height: 12),
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
  @override Widget build(BuildContext context) => SizedBox(width: double.infinity, height: 54, child: FilledButton.icon(style: FilledButton.styleFrom(backgroundColor: AppColors.teal, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), onPressed: loading ? null : onTap, icon: loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Icon(icon ?? Icons.check_rounded), label: Text(label, style: const TextStyle(fontWeight: FontWeight.w900))));
}

class SecondaryButton extends StatelessWidget {
  final String label; final IconData icon; final VoidCallback onTap;
  const SecondaryButton({super.key, required this.label, required this.icon, required this.onTap});
  @override Widget build(BuildContext context) => SizedBox(width: double.infinity, height: 54, child: OutlinedButton.icon(style: OutlinedButton.styleFrom(foregroundColor: AppColors.teal, side: const BorderSide(color: AppColors.teal), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), onPressed: onTap, icon: Icon(icon), label: Text(label, style: const TextStyle(fontWeight: FontWeight.w900))));
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
  final Widget child; final EdgeInsets padding; final VoidCallback? onTap;
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(15), this.onTap});
  @override Widget build(BuildContext context) {
    final card = Container(padding: padding, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.line), boxShadow: [BoxShadow(color: Colors.black.withOpacity(.03), blurRadius: 16, offset: const Offset(0, 8))]), child: child);
    return onTap == null ? card : InkWell(borderRadius: BorderRadius.circular(18), onTap: onTap, child: card);
  }
}

class RoundBackButton extends StatelessWidget {
  final VoidCallback? onTap;
  const RoundBackButton({super.key, this.onTap});
  @override Widget build(BuildContext context) => Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.faint, borderRadius: BorderRadius.circular(15)), child: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: onTap ?? () => Navigator.of(context).maybePop()));
}

class CircleIconButton extends StatelessWidget {
  final IconData icon; final VoidCallback onTap; final bool filled;
  const CircleIconButton({super.key, required this.icon, required this.onTap, this.filled = false});
  @override Widget build(BuildContext context) => Container(width: 44, height: 44, decoration: BoxDecoration(color: filled ? AppColors.teal : AppColors.faint, shape: BoxShape.circle), child: IconButton(onPressed: onTap, icon: Icon(icon, color: filled ? Colors.white : AppColors.ink)));
}

class OrDivider extends StatelessWidget { const OrDivider({super.key}); @override Widget build(BuildContext context) => Row(children: const [Expanded(child: Divider()), Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('o', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700))), Expanded(child: Divider())]); }

class StatCard extends StatelessWidget {
  final IconData icon; final String value; final String label; final Color color;
  const StatCard({super.key, required this.icon, required this.value, required this.label, required this.color});
  @override Widget build(BuildContext context) => AppCard(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14), child: Column(children: [Icon(icon, color: color, size: 24), const SizedBox(height: 8), Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.ink)), const SizedBox(height: 2), Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w700))]));
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
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 10), child: AppCard(onTap: onTap, child: Row(children: [
    Container(width: 58, height: 58, decoration: BoxDecoration(color: AppColors.teal.withOpacity(.75), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.sports_soccer_rounded, color: Colors.white)),
    const SizedBox(width: 14),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(AppData.text(group['name'], 'Grupo'), style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 4), Text('${AppData.intValue(group['members_count'], 1)} miembros', style: Theme.of(context).textTheme.bodyMedium), const SizedBox(height: 6), const Icon(Icons.lock_rounded, color: AppColors.teal, size: 16)])),
    Container(padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7), decoration: BoxDecoration(color: AppColors.tealSoft, borderRadius: BorderRadius.circular(99)), child: Text('${AppData.intValue(group['events_count'], 0)} eventos', style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.w900, fontSize: 12))),
    const SizedBox(width: 8), const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
  ])));
}

class RootBottomNav extends StatelessWidget {
  final int index; final ValueChanged<int> onTap;
  const RootBottomNav({super.key, required this.index, required this.onTap});
  @override Widget build(BuildContext context) => BottomBar(items: const [NavSpec(Icons.home_rounded, 'Inicio'), NavSpec(Icons.notifications_none_rounded, 'Avisos'), NavSpec(Icons.person_outline_rounded, 'Perfil')], index: index, onTap: onTap);
}

class GroupBottomNav extends StatelessWidget {
  final String groupName; final int index; final ValueChanged<int> onTap;
  const GroupBottomNav({super.key, required this.groupName, required this.index, required this.onTap});
  @override Widget build(BuildContext context) => Container(color: Colors.white, child: Column(mainAxisSize: MainAxisSize.min, children: [
    Container(width: double.infinity, padding: const EdgeInsets.only(top: 9), child: Center(child: Text('Estás dentro de $groupName 🔒', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.ink)))),
    BottomBar(items: const [NavSpec(Icons.home_rounded, 'Inicio'), NavSpec(Icons.calendar_month_rounded, 'Calendario'), NavSpec(Icons.account_balance_wallet_rounded, 'Finanzas'), NavSpec(Icons.emoji_events_rounded, 'Torneos'), NavSpec(Icons.more_horiz_rounded, 'Más')], index: index, onTap: onTap),
  ]));
}

class NavSpec { final IconData icon; final String label; const NavSpec(this.icon, this.label); }

class BottomBar extends StatelessWidget {
  final List<NavSpec> items; final int index; final ValueChanged<int> onTap;
  const BottomBar({super.key, required this.items, required this.index, required this.onTap});
  @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.fromLTRB(12, 6, 12, 8), decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.line))), child: Row(children: List.generate(items.length, (i) {
    final active = i == index; final spec = items[i];
    return Expanded(child: InkWell(borderRadius: BorderRadius.circular(28), onTap: () => onTap(i), child: Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Column(mainAxisSize: MainAxisSize.min, children: [Container(height: 32, padding: const EdgeInsets.symmetric(horizontal: 13), decoration: BoxDecoration(color: active ? AppColors.tealSoft : Colors.transparent, borderRadius: BorderRadius.circular(99)), child: Icon(spec.icon, size: 22, color: active ? AppColors.teal : AppColors.muted)), const SizedBox(height: 2), Text(spec.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, fontWeight: active ? FontWeight.w900 : FontWeight.w700, color: active ? AppColors.ink : AppColors.muted))]))));
  })));
}

class PageHeader extends StatelessWidget {
  final String title; final String subtitle; final bool leading;
  const PageHeader({super.key, required this.title, this.subtitle = '', this.leading = false});
  @override Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [if (leading) ...[RoundBackButton(onTap: () => Navigator.of(context).maybePop()), const SizedBox(width: 12)], Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.headlineMedium), if (subtitle.isNotEmpty) ...[const SizedBox(height: 4), Row(children: [const Icon(Icons.lock_rounded, size: 14, color: AppColors.teal), const SizedBox(width: 5), Expanded(child: Text(subtitle, style: Theme.of(context).textTheme.bodyMedium))])]]))]);
}

class CenterLoader extends StatelessWidget { final String label; const CenterLoader({super.key, required this.label}); @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 40), child: Column(children: [const CircularProgressIndicator(color: AppColors.teal), const SizedBox(height: 12), Text(label, style: Theme.of(context).textTheme.bodyMedium)])); }

class ErrorBlock extends StatelessWidget { final String message; final VoidCallback onRetry; const ErrorBlock({super.key, required this.message, required this.onRetry}); @override Widget build(BuildContext context) => AppCard(child: Column(children: [const Icon(Icons.error_outline_rounded, color: AppColors.red, size: 34), const SizedBox(height: 10), const Text('Algo no ha cargado bien', style: TextStyle(fontWeight: FontWeight.w900)), const SizedBox(height: 7), Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium), const SizedBox(height: 14), SecondaryButton(label: 'Reintentar', icon: Icons.refresh_rounded, onTap: onRetry)])); }

class EmptyBlock extends StatelessWidget { final IconData icon; final String title; final String body; const EmptyBlock({super.key, required this.icon, required this.title, required this.body}); @override Widget build(BuildContext context) => AppCard(child: Column(children: [Container(width: 62, height: 62, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.tealSoft), child: Icon(icon, color: AppColors.teal, size: 30)), const SizedBox(height: 12), Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 6), Text(body, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium)])); }

class EmptySlim extends StatelessWidget { final IconData icon; final String title; final String body; const EmptySlim({super.key, required this.icon, required this.title, required this.body}); @override Widget build(BuildContext context) => AppCard(child: Row(children: [Icon(icon, color: AppColors.teal), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w900)), Text(body, style: Theme.of(context).textTheme.bodyMedium)]))])); }

class HomeLoading extends StatelessWidget { const HomeLoading({super.key}); @override Widget build(BuildContext context) => Column(children: [Row(children: const [Expanded(child: GhostBox(height: 90)), SizedBox(width: 10), Expanded(child: GhostBox(height: 90)), SizedBox(width: 10), Expanded(child: GhostBox(height: 90))]), const SizedBox(height: 24), const GhostBox(height: 100), const SizedBox(height: 10), const GhostBox(height: 100)]); }
class GhostBox extends StatelessWidget { final double height; const GhostBox({super.key, required this.height}); @override Widget build(BuildContext context) => Container(height: height, decoration: BoxDecoration(color: AppColors.faint, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.line))); }

class ChoiceBigCard extends StatelessWidget { final IconData icon; final String title; final String body; final VoidCallback onTap; const ChoiceBigCard({super.key, required this.icon, required this.title, required this.body, required this.onTap}); @override Widget build(BuildContext context) => AppCard(onTap: onTap, child: Row(children: [Container(width: 48, height: 48, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.tealSoft), child: Icon(icon, color: AppColors.teal)), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.titleMedium), Text(body, style: Theme.of(context).textTheme.bodyMedium)])), const Icon(Icons.chevron_right_rounded, color: AppColors.muted)])); }

class MiniAction extends StatelessWidget { final IconData icon; final String label; final VoidCallback onTap; const MiniAction({super.key, required this.icon, required this.label, required this.onTap}); @override Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: Container(padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line)), child: Column(children: [Icon(icon, color: AppColors.ink), const SizedBox(height: 5), Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900))]))); }

class Grid2 extends StatelessWidget { final List<Widget> children; const Grid2({super.key, required this.children}); @override Widget build(BuildContext context) => GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.55, children: children); }

class FeatureTile extends StatelessWidget { final IconData icon; final String title; final String body; final Color color; final VoidCallback onTap; const FeatureTile({super.key, required this.icon, required this.title, required this.body, required this.color, required this.onTap}); @override Widget build(BuildContext context) => AppCard(onTap: onTap, child: Row(children: [Icon(icon, color: color, size: 28), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w900)), Text(body, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontSize: 12))]))])); }

class ActivityRow extends StatelessWidget { final IconData icon; final String title; final String meta; const ActivityRow({super.key, required this.icon, required this.title, required this.meta}); @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Row(children: [CircleAvatar(radius: 16, backgroundColor: AppColors.tealSoft, child: Icon(icon, color: AppColors.teal, size: 17)), const SizedBox(width: 11), Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800))), Text(meta, style: const TextStyle(color: AppColors.muted, fontSize: 12))])); }

class EventCard extends StatelessWidget { final Map<String, dynamic> event; final VoidCallback onTap; const EventCard({super.key, required this.event, required this.onTap}); @override Widget build(BuildContext context) { final d = DateTime.tryParse(event['starts_at']?.toString() ?? '') ?? DateTime.now(); final att = event['event_attendance']; final yes = att is List ? att.where((x) => (x as Map)['status'] == 'yes').length : 0; return Padding(padding: const EdgeInsets.only(bottom: 10), child: AppCard(onTap: onTap, child: Row(children: [Container(width: 78, height: 70, decoration: BoxDecoration(color: AppColors.tealSoft, borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.event_available_rounded, color: AppColors.teal, size: 34)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(AppData.text(event['title'], 'Evento'), style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 5), MetaLine(icon: Icons.schedule_rounded, text: dateLabel(d)), MetaLine(icon: Icons.place_outlined, text: AppData.text(event['location'], 'Sin ubicación'))])), Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: AppColors.tealSoft, borderRadius: BorderRadius.circular(99)), child: Text('$yes van', style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.w900, fontSize: 12)))])) ); }}

class EventMiniCard extends StatelessWidget { final Map<String, dynamic> event; const EventMiniCard({super.key, required this.event}); @override Widget build(BuildContext context) { final d = DateTime.tryParse(event['starts_at']?.toString() ?? '') ?? DateTime.now(); return AppCard(child: Row(children: [Container(width: 56, height: 56, decoration: BoxDecoration(color: AppColors.tealSoft, borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.event_available_rounded, color: AppColors.teal)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(AppData.text(event['title'], 'Evento'), style: const TextStyle(fontWeight: FontWeight.w900)), Text(dateLabel(d), style: const TextStyle(color: AppColors.muted))]))])); }}

class ExpenseCard extends StatelessWidget { final Map<String, dynamic> expense; const ExpenseCard({super.key, required this.expense}); @override Widget build(BuildContext context) { final profile = AppData.asMap(expense['profiles']); return Padding(padding: const EdgeInsets.only(bottom: 8), child: AppCard(child: Row(children: [const CircleAvatar(backgroundColor: AppColors.teal, child: Icon(Icons.restaurant_rounded, color: Colors.white)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(AppData.text(expense['concept'], 'Gasto'), style: const TextStyle(fontWeight: FontWeight.w900)), Text('Pagado por ${AppData.text(profile['full_name'], AppData.text(profile['email'], 'Miembro'))}', style: const TextStyle(color: AppColors.muted, fontSize: 12))])), Text(money(AppData.doubleValue(expense['amount'])), style: const TextStyle(fontWeight: FontWeight.w900))]))); }}

class TournamentCard extends StatelessWidget { final Map<String, dynamic> tournament; const TournamentCard({super.key, required this.tournament}); @override Widget build(BuildContext context) { final teams = tournament['tournament_teams'] is List ? (tournament['tournament_teams'] as List).length : 0; final matches = tournament['matches'] is List ? (tournament['matches'] as List).length : 0; return Padding(padding: const EdgeInsets.only(bottom: 10), child: AppCard(child: Row(children: [Container(width: 64, height: 64, decoration: BoxDecoration(color: AppColors.tealSoft, borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.emoji_events_rounded, color: AppColors.orange, size: 34)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(AppData.text(tournament['name'], 'Torneo'), style: Theme.of(context).textTheme.titleMedium), Text('$teams equipos · $matches partidos', style: Theme.of(context).textTheme.bodyMedium), Text(AppData.text(tournament['status'], 'active') == 'finished' ? 'Finalizado' : 'En curso', style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.w900, fontSize: 12))])), const Icon(Icons.chevron_right_rounded, color: AppColors.muted)]))); }}

class MemberCard extends StatelessWidget { final Map<String, dynamic> member; const MemberCard({super.key, required this.member}); @override Widget build(BuildContext context) { final profile = AppData.asMap(member['profiles']); final role = AppData.text(member['role'], 'member'); return Padding(padding: const EdgeInsets.only(bottom: 8), child: AppCard(child: Row(children: [CircleAvatar(backgroundColor: AppColors.tealSoft, child: Text(memberName(member).substring(0, 1).toUpperCase(), style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.w900))), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(memberName(member), style: const TextStyle(fontWeight: FontWeight.w900)), Text(AppData.text(profile['email'], 'sin email'), style: const TextStyle(color: AppColors.muted, fontSize: 12))])), Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: role == 'member' ? AppColors.faint : AppColors.tealSoft, borderRadius: BorderRadius.circular(99)), child: Text(role == 'owner' ? 'OWNER' : role == 'admin' ? 'ADMIN' : 'MIEMBRO', style: TextStyle(color: role == 'member' ? AppColors.muted : AppColors.teal, fontWeight: FontWeight.w900, fontSize: 11)))]))); }}

String memberName(Map<String, dynamic> member) { final profile = AppData.asMap(member['profiles']); return AppData.text(profile['full_name'], AppData.text(profile['email'], 'Miembro')); }

class SettingsRow extends StatelessWidget { final IconData icon; final String title; final String subtitle; final VoidCallback onTap; final bool danger; const SettingsRow({super.key, required this.icon, required this.title, required this.subtitle, required this.onTap, this.danger = false}); @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 9), child: AppCard(onTap: onTap, child: Row(children: [Icon(icon, color: danger ? AppColors.red : AppColors.ink), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontWeight: FontWeight.w900, color: danger ? AppColors.red : AppColors.ink)), Text(subtitle, style: const TextStyle(color: AppColors.muted, fontSize: 12))])), const Icon(Icons.chevron_right_rounded, color: AppColors.muted)]))); }

class MetaLine extends StatelessWidget { final IconData icon; final String text; const MetaLine({super.key, required this.icon, required this.text}); @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 3), child: Row(children: [Icon(icon, size: 15, color: AppColors.muted), const SizedBox(width: 5), Expanded(child: Text(text, style: const TextStyle(color: AppColors.muted, fontSize: 12.5)))])); }

class AttendancePick extends StatelessWidget { final String label; final int count; final bool selected; final Color color; final VoidCallback onTap; const AttendancePick({super.key, required this.label, required this.count, required this.selected, required this.color, required this.onTap}); @override Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: Container(padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: selected ? color.withOpacity(.10) : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: selected ? color : AppColors.line)), child: Column(children: [Icon(selected ? Icons.check_circle_rounded : Icons.circle_outlined, color: color), const SizedBox(height: 4), Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w900)), Text(count.toString(), style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 18))]))); }

class StatusNotice extends StatelessWidget { final bool ok; final String text; const StatusNotice({super.key, required this.ok, required this.text}); @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: ok ? const Color(0xFFEAF8F0) : const Color(0xFFFFF6DF), borderRadius: BorderRadius.circular(14), border: Border.all(color: ok ? const Color(0xFFBFEBD2) : const Color(0xFFFFE3A6))), child: Row(children: [Icon(ok ? Icons.check_circle_rounded : Icons.info_rounded, color: ok ? AppColors.green : AppColors.amber), const SizedBox(width: 10), Expanded(child: Text(text, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink)))])); }

class SmallPick extends StatelessWidget { final String label; final String value; final IconData icon; final VoidCallback onTap; const SmallPick({super.key, required this.label, required this.value, required this.icon, required this.onTap}); @override Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [FieldLabel(label), InkWell(onTap: onTap, borderRadius: BorderRadius.circular(15), child: Container(height: 50, padding: const EdgeInsets.symmetric(horizontal: 12), decoration: BoxDecoration(border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(15)), child: Row(children: [Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w800))), Icon(icon, color: AppColors.muted, size: 20)])))]); }

class StepperRow extends StatelessWidget { final int value; final VoidCallback onMinus; final VoidCallback onPlus; const StepperRow({super.key, required this.value, required this.onMinus, required this.onPlus}); @override Widget build(BuildContext context) => AppCard(child: Row(children: [const Icon(Icons.groups_rounded, color: AppColors.muted), const SizedBox(width: 12), Text(value.toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)), const Spacer(), IconButton(onPressed: onMinus, icon: const Icon(Icons.remove_rounded)), IconButton(onPressed: onPlus, icon: const Icon(Icons.add_rounded))])); }

class MonthGrid extends StatelessWidget { final DateTime month; final DateTime selected; final List<Map<String, dynamic>> events; final ValueChanged<DateTime> onSelect; const MonthGrid({super.key, required this.month, required this.selected, required this.events, required this.onSelect}); @override Widget build(BuildContext context) { final first = DateTime(month.year, month.month, 1); final startOffset = (first.weekday + 6) % 7; final days = DateTime(month.year, month.month + 1, 0).day; final cells = <DateTime?>[]; for (int i = 0; i < startOffset; i++) cells.add(null); for (int d = 1; d <= days; d++) cells.add(DateTime(month.year, month.month, d)); while (cells.length % 7 != 0) cells.add(null); return Column(children: [Row(children: ['L','M','X','J','V','S','D'].map((d) => Expanded(child: Center(child: Text(d, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.muted, fontSize: 12))))).toList()), const SizedBox(height: 8), GridView.count(crossAxisCount: 7, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), childAspectRatio: 1.05, children: cells.map((day) { if (day == null) return const SizedBox(); final active = day.year == selected.year && day.month == selected.month && day.day == selected.day; final has = events.any((e) { final d = DateTime.tryParse(e['starts_at']?.toString() ?? '')?.toLocal(); return d != null && d.year == day.year && d.month == day.month && d.day == day.day; }); return InkWell(onTap: () => onSelect(day), borderRadius: BorderRadius.circular(20), child: Container(margin: const EdgeInsets.all(3), decoration: BoxDecoration(color: active ? AppColors.teal : Colors.transparent, shape: BoxShape.circle), child: Stack(alignment: Alignment.center, children: [Text(day.day.toString(), style: TextStyle(color: active ? Colors.white : AppColors.ink, fontWeight: FontWeight.w800)), if (has) Positioned(bottom: 6, child: Container(width: 5, height: 5, decoration: BoxDecoration(color: active ? Colors.white : AppColors.teal, shape: BoxShape.circle))) ]))); }).toList())]); }}

class PatternIcons extends StatelessWidget { @override Widget build(BuildContext context) => Wrap(spacing: 24, runSpacing: 20, children: List.generate(70, (i) => Icon([Icons.event_available_rounded, Icons.calendar_month_rounded, Icons.account_balance_wallet_rounded, Icons.emoji_events_rounded, Icons.lock_rounded, Icons.qr_code_rounded][i % 6], size: 17, color: Colors.white))); }

void showCodeSheet(BuildContext context, String code, String groupName) { showModalBottomSheet(context: context, showDragHandle: true, builder: (context) => Padding(padding: const EdgeInsets.fromLTRB(22, 10, 22, 30), child: Column(mainAxisSize: MainAxisSize.min, children: [Text('Código de invitación', style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 12), Container(width: double.infinity, padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: AppColors.tealSoft, borderRadius: BorderRadius.circular(18)), child: Center(child: Text(code, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: 3, color: AppColors.teal)))), const SizedBox(height: 16), PrimaryButton(label: 'Compartir código', icon: Icons.share_rounded, onTap: () => Share.share('Únete a $groupName en Grupli con el código $code'))]))); }
