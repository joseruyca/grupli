import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:app_links/app_links.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';


final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> grupliFirebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      if (AppConfig.firebaseConfigured) {
        await Firebase.initializeApp(options: PushNotificationService.firebaseOptions);
      } else {
        await Firebase.initializeApp();
      }
    }
  } catch (_) {
    // El handler de background nunca debe bloquear la recepción del mensaje.
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(grupliFirebaseMessagingBackgroundHandler);
  }


  // Android 15+ activa el modo edge-to-edge por defecto.
  // Mantenemos las barras del sistema limpias y usamos SafeArea global abajo
  // para que los botones nativos del móvil no tapen la navegación de Grupli.
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarDividerColor: Colors.transparent,
  ));

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
  static const appVersion = 'v15.34.1';
  static const enableRealtimeSubscriptions = false;
  static const supabaseUrlDefine = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonDefine = String.fromEnvironment('SUPABASE_ANON_KEY');

  static const fallbackSupabaseUrl = 'https://izusbttdgtwbnuyzjrpw.supabase.co';
  static const fallbackSupabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml6dXNidHRkZ3R3Ym51eXpqcnB3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODAwNjI2MDAsImV4cCI6MjA5NTYzODYwMH0.S6GqpaZuPpQsM4ZPbvMC4nzbFVtT-r47fPdT59PdDxU';

  static const appBaseUrlDefine = String.fromEnvironment('APP_BASE_URL');
  static const fallbackAppBaseUrl = 'https://grupli.vercel.app';

  static const firebaseApiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const firebaseAppId = String.fromEnvironment('FIREBASE_APP_ID');
  static const firebaseMessagingSenderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  static const firebaseProjectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const firebaseVapidKey = String.fromEnvironment('FIREBASE_VAPID_KEY');
  static const osmGeocoderEndpointDefine = String.fromEnvironment('OSM_GEOCODER_ENDPOINT');
  static const fallbackOsmGeocoderEndpoint = 'https://photon.komoot.io/api/';

  static String get supabaseUrl => supabaseUrlDefine.trim().isNotEmpty ? supabaseUrlDefine.trim() : fallbackSupabaseUrl;
  static String get supabaseAnonKey => supabaseAnonDefine.trim().isNotEmpty ? supabaseAnonDefine.trim() : fallbackSupabaseAnonKey;
  static String get appBaseUrl => appBaseUrlDefine.trim().isNotEmpty ? appBaseUrlDefine.trim().replaceFirst(RegExp(r'/+$'), '') : fallbackAppBaseUrl;

  static String get osmGeocoderEndpoint => osmGeocoderEndpointDefine.trim().isNotEmpty ? osmGeocoderEndpointDefine.trim() : fallbackOsmGeocoderEndpoint;

  static bool get firebaseConfigured =>
      firebaseApiKey.trim().isNotEmpty &&
      firebaseAppId.trim().isNotEmpty &&
      firebaseMessagingSenderId.trim().isNotEmpty &&
      firebaseProjectId.trim().isNotEmpty;
}


class PlaceSuggestion {
  final String description;
  final String source;
  final double? lat;
  final double? lon;
  const PlaceSuggestion({required this.description, this.source = 'OpenStreetMap', this.lat, this.lon});
}

class AddressSearchService {
  AddressSearchService._();

  static Future<List<PlaceSuggestion>> autocomplete(String input) async {
    final query = input.trim();
    if (query.length < 3) return const [];

    final endpoint = Uri.parse(AppConfig.osmGeocoderEndpoint);
    final params = <String, String>{
      'q': query,
      'limit': '7',
      'lang': 'es',
    };
    final uri = endpoint.replace(queryParameters: {
      ...endpoint.queryParameters,
      ...params,
    });

    final response = await http
        .get(uri, headers: const {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 8));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('No se pudo buscar la dirección ahora mismo.');
    }

    final data = jsonDecode(response.body);
    if (data is! Map<String, dynamic>) return const [];
    final features = data['features'];
    if (features is! List) return const [];

    final seen = <String>{};
    final result = <PlaceSuggestion>[];
    for (final raw in features) {
      final feature = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
      final props = feature['properties'] is Map ? Map<String, dynamic>.from(feature['properties']) : <String, dynamic>{};
      final geometry = feature['geometry'] is Map ? Map<String, dynamic>.from(feature['geometry']) : <String, dynamic>{};
      final coordinates = geometry['coordinates'];
      final description = _photonDescription(props);
      if (description.isEmpty || seen.contains(description.toLowerCase())) continue;
      seen.add(description.toLowerCase());
      double? lon;
      double? lat;
      if (coordinates is List && coordinates.length >= 2) {
        lon = AppData.doubleValue(coordinates[0]);
        lat = AppData.doubleValue(coordinates[1]);
      }
      result.add(PlaceSuggestion(description: description, lat: lat, lon: lon));
      if (result.length >= 6) break;
    }
    return result;
  }

  static String _photonDescription(Map<String, dynamic> props) {
    final name = AppData.text(props['name']);
    final street = AppData.text(props['street']);
    final houseNumber = AppData.text(props['housenumber']);
    final postcode = AppData.text(props['postcode']);
    final city = AppData.text(props['city']).isNotEmpty
        ? AppData.text(props['city'])
        : AppData.text(props['town']).isNotEmpty
            ? AppData.text(props['town'])
            : AppData.text(props['village']);
    final state = AppData.text(props['state']);
    final country = AppData.text(props['country']);

    final firstLine = <String>[
      if (name.isNotEmpty) name,
      if (street.isNotEmpty && street != name) [street, houseNumber].where((x) => x.isNotEmpty).join(' '),
    ].where((x) => x.trim().isNotEmpty).join(' · ');

    final secondLine = <String>[postcode, city, state, country]
        .where((x) => x.trim().isNotEmpty)
        .toList();

    final parts = <String>[
      if (firstLine.isNotEmpty) firstLine,
      ...secondLine,
    ];
    final unique = <String>[];
    for (final part in parts) {
      if (!unique.any((x) => x.toLowerCase() == part.toLowerCase())) unique.add(part);
    }
    return unique.join(', ');
  }
}

String mapsLaunchUrl(String address) {
  final clean = address.trim();
  if (clean.isEmpty) return '';
  final parsed = Uri.tryParse(clean);
  if (parsed != null && (parsed.scheme == 'http' || parsed.scheme == 'https')) return clean;
  return Uri.https('www.google.com', '/maps/search/', {'api': '1', 'query': clean}).toString();
}

Future<void> openAddressInGoogleMaps(BuildContext context, String address) async {
  final url = mapsLaunchUrl(address);
  if (url.isEmpty) {
    await showToast(context, 'Este evento no tiene dirección.', danger: true);
    return;
  }
  final uri = Uri.parse(url);
  try {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      await showToast(context, 'No se pudo abrir Google Maps.', danger: true);
    }
  } catch (e) {
    if (context.mounted) await showToast(context, 'No se pudo abrir Google Maps.', danger: true);
  }
}

class AppColors {
  static const bgShell = Color(0xFFF6F9FC);
  static const white = Color(0xFFFFFFFF);
  static const ink = Color(0xFF111B2D);
  static const muted = Color(0xFF64748B);
  static const faint = Color(0xFFF7FAFE);
  static const surface = Color(0xFFFCFEFF);
  static const line = Color(0xFFE2EAF3);
  static const lineSoft = Color(0xFFF0F5FA);
  static const teal = Color(0xFF0E6B73);
  static const tealDark = Color(0xFF073A4A);
  static const tealSoft = Color(0xFFE8F4F2);
  static const navy = Color(0xFF062C3B);
  static const navyDeep = Color(0xFF051E2A);
  static const blue = Color(0xFF315F8C);
  static const blueSoft = Color(0xFFEAF2F8);
  static const violet = Color(0xFF6D5A86);
  static const violetSoft = Color(0xFFF1EEF6);
  static const orange = Color(0xFFD69027);
  static const orangeSoft = Color(0xFFFFF3DF);
  static const green = Color(0xFF2F8B57);
  static const greenDark = Color(0xFF276E48);
  static const greenSoft = Color(0xFFEAF5EE);
  static const red = Color(0xFFC75B4C);
  static const redSoft = Color(0xFFFBEDEA);
  static const amber = Color(0xFFD69A28);
  static const amberSoft = Color(0xFFFFF4DC);
  static const navHome = Color(0xFF073A4A);
  static const navAgenda = Color(0xFFDFA22E);
  static const navFinance = Color(0xFF2F8B57);
  static const navTournaments = Color(0xFFC75B4C);
  static const navMore = Color(0xFF6D5578);
}

class GrupliApp extends StatelessWidget {
  const GrupliApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: appNavigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Grupli',
      builder: (context, child) {
        return SafeArea(
          top: false,
          left: false,
          right: false,
          bottom: true,
          child: child ?? const SizedBox.shrink(),
        );
      },
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.white,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.teal, surface: AppColors.white),
        visualDensity: VisualDensity.compact,
        dividerTheme: const DividerThemeData(color: AppColors.line, thickness: 1, space: 1),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.surface,
          selectedColor: AppColors.tealSoft,
          side: const BorderSide(color: AppColors.line),
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: AppColors.ink, height: 1.02, letterSpacing: -0.9),
          headlineMedium: TextStyle(fontSize: 23.5, fontWeight: FontWeight.w900, color: AppColors.ink, height: 1.06, letterSpacing: -0.55),
          titleLarge: TextStyle(fontSize: 18.5, fontWeight: FontWeight.w900, color: AppColors.ink, letterSpacing: -0.25),
          titleMedium: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900, color: AppColors.ink, height: 1.18),
          bodyLarge: TextStyle(fontSize: 15, color: AppColors.ink, height: 1.35),
          bodyMedium: TextStyle(fontSize: 13.2, color: AppColors.muted, height: 1.36, fontWeight: FontWeight.w600),
          labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
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
  StreamSubscription<AuthState>? _authSub;
  StreamSubscription<Uri>? _appLinksSub;
  AppLinks? _appLinks;
  String? _lastHandledInviteCode;
  DateTime? _lastHandledInviteAt;
  bool _ready = false;
  bool _showOnboarding = false;

  @override
  void initState() {
    super.initState();
    _session = Supabase.instance.client.auth.currentSession;
    _loadFirstRunState();
    unawaited(_startAppLinkListener());
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      if (!mounted) return;
      setState(() {
        _session = event.session;
        if (_session != null) _showOnboarding = false;
      });
      if (event.session != null) {
        PushNotificationService.tryRegisterSilently();
      }
    });
  }

  Future<void> _startAppLinkListener() async {
    if (kIsWeb) return;
    final links = AppLinks();
    _appLinks = links;

    try {
      final initial = await links.getInitialLink();
      if (initial != null) {
        await _handleIncomingInviteLink(initial, source: 'initial');
      }
    } catch (_) {
      // Los enlaces externos nunca deben impedir que la app arranque.
    }

    _appLinksSub = links.uriLinkStream.listen(
      (uri) => _handleIncomingInviteLink(uri, source: 'stream'),
      onError: (_) {},
    );
  }

  Future<void> _handleIncomingInviteLink(Uri uri, {required String source}) async {
    final code = InviteLinks.codeFromUri(uri);
    if (code == null || code.length < 4) return;

    final now = DateTime.now();
    if (_lastHandledInviteCode == code && _lastHandledInviteAt != null && now.difference(_lastHandledInviteAt!).inSeconds < 3) {
      return;
    }
    _lastHandledInviteCode = code;
    _lastHandledInviteAt = now;

    await PendingInviteStore.save(code);
    if (!mounted) return;

    setState(() => _showOnboarding = false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final nav = appNavigatorKey.currentState;
      if (nav == null) return;

      if (_session == null) {
        nav.push(MaterialPageRoute(builder: (_) => AuthScreen(register: false, inviteCode: code)));
      } else {
        nav.push(MaterialPageRoute(builder: (_) => JoinInviteScreen(inviteCode: code)));
      }
    });
  }

  Future<void> _loadFirstRunState() async {
    final prefs = await SharedPreferences.getInstance();
    final introSeen = prefs.getBool(OnboardingStore.seenKey) ?? false;
    final hasInvite = InviteLinks.currentCode != null;
    final validSession = await AppData.recoverStoredSession();
    if (!mounted) return;
    setState(() {
      _session = validSession;
      _showOnboarding = _session == null && !introSeen && !hasInvite;
      _ready = true;
    });
    if (_session != null) {
      PushNotificationService.tryRegisterSilently();
    }
  }

  Future<void> _finishOnboarding() async {
    await OnboardingStore.markSeen();
    if (mounted) setState(() => _showOnboarding = false);
  }

  Future<void> _restartOnboarding() async {
    await OnboardingStore.reset();
    if (mounted) setState(() => _showOnboarding = true);
  }

  @override
  void dispose() {
    _appLinksSub?.cancel();
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = !_ready
        ? const Scaffold(backgroundColor: AppColors.white, body: CenterLoader(label: 'Preparando Grupli...'))
        : _session == null
            ? (_showOnboarding ? OnboardingScreen(onFinish: _finishOnboarding) : WelcomeScreen(onShowIntro: _restartOnboarding))
            : const AuthedShell();
    return AppSurface(child: child);
  }
}

class AppSurface extends StatelessWidget {
  final Widget child;
  const AppSurface({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF8FAFC), Color(0xFFEEF6F5)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            boxShadow: [BoxShadow(color: Color(0x10111B34), blurRadius: 32, offset: Offset(0, 10))],
          ),
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

  static Future<void> clearLocalSession() async {
    try {
      await sb.auth.signOut(scope: SignOutScope.local);
    } catch (_) {
      try {
        await sb.auth.signOut();
      } catch (_) {}
    }
  }

  static Future<Session?> recoverStoredSession() async {
    final current = sb.auth.currentSession;
    if (current == null) return null;
    try {
      final refreshed = await sb.auth.refreshSession();
      return refreshed.session ?? sb.auth.currentSession;
    } catch (e) {
      final raw = e.toString();
      if (looksLikeNetworkError(raw)) {
        return current;
      }
      if (looksLikeSessionProblem(raw) || raw.toLowerCase().contains('refresh')) {
        await clearLocalSession();
        return null;
      }
      await clearLocalSession();
      return null;
    }
  }

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

  static Future<void> deleteMyAccount(String confirmation) async {
    final clean = confirmation.trim().toUpperCase();
    if (clean != 'ELIMINAR') {
      throw Exception('confirmation_required');
    }
    await sb.rpc('delete_my_account', params: {'confirm_text': clean});
    try {
      await sb.auth.signOut();
    } catch (_) {}
  }

  static Future<List<Map<String, dynamic>>> myGroups() async {
    try {
      final res = await sb.rpc('get_my_groups');
      return asList(res);
    } catch (_) {
      final uid = user?.id;
      if (uid == null) return [];
      final res = await sb.from('group_members').select('role, groups(id,name,type,privacy,invite_code,cover_url,created_at)').eq('user_id', uid);
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

  static Future<String> createGroup(
    String name, {
    String type = 'otro',
    String description = '',
    String currency = 'EUR',
    String timezone = 'Europe/Madrid',
    String language = 'es',
  }) async {
    final cleanName = name.trim();
    final cleanType = groupTypeValue(type);
    final cleanDescription = description.trim();
    try {
      final res = await sb.rpc('create_group_atomic_v2', params: {
        'p_name': cleanName,
        'p_type': cleanType,
        'p_description': cleanDescription.isEmpty ? null : cleanDescription,
        'p_currency': currency.trim().isEmpty ? 'EUR' : currency.trim().toUpperCase(),
        'p_timezone': timezone.trim().isEmpty ? 'Europe/Madrid' : timezone.trim(),
        'p_language': language.trim().isEmpty ? 'es' : language.trim().toLowerCase(),
      });
      return res.toString();
    } catch (_) {
      final res = await sb.rpc('create_group_atomic', params: {'p_name': cleanName});
      final groupId = res.toString();
      final payload = <String, dynamic>{
        'type': cleanType,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };
      if (cleanDescription.isNotEmpty) payload['description'] = cleanDescription;
      try {
        await sb.from('groups').update(payload).eq('id', groupId);
      } catch (_) {}
      return groupId;
    }
  }

  static Future<String> joinGroup(String code) async {
    final res = await sb.rpc('join_group_with_code', params: {'code': code.trim().toUpperCase()});
    return res.toString();
  }

  static Future<Map<String, dynamic>> group(String groupId) async {
    final res = await sb.from('groups').select().eq('id', groupId).single();
    return asMap(res);
  }

  static Future<void> updateGroupInfo(
    String groupId, {
    required String name,
    String? type,
    String? description,
    String? currency,
    String? timezone,
    String? language,
    String? rules,
  }) async {
    final cleanName = name.trim();
    if (cleanName.length < 2) throw Exception('El nombre del grupo es demasiado corto.');
    final payload = <String, dynamic>{
      'name': cleanName,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    if (type != null) payload['type'] = groupTypeValue(type);
    if (description != null) payload['description'] = description.trim().isEmpty ? null : description.trim();
    if (currency != null) payload['currency'] = currency.trim().isEmpty ? 'EUR' : currency.trim().toUpperCase();
    if (timezone != null) payload['timezone'] = timezone.trim().isEmpty ? 'Europe/Madrid' : timezone.trim();
    if (language != null) payload['language'] = language.trim().isEmpty ? 'es' : language.trim().toLowerCase();
    if (rules != null) payload['rules'] = rules.trim().isEmpty ? null : rules.trim();
    await sb.from('groups').update(payload).eq('id', groupId);
  }

  static Future<String> regenerateGroupInviteCode(String groupId) async {
    try {
      final res = await sb.rpc('regenerate_group_invite_code', params: {'p_group_id': groupId});
      return res.toString();
    } catch (_) {
      final code = randomInviteCodeLocal();
      await sb.from('groups').update({
        'invite_code': code,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', groupId);
      return code;
    }
  }

  static Future<String> uploadGroupCoverBytes(String groupId, Uint8List bytes, String filename) async {
    final uid = user?.id;
    if (uid == null) throw Exception('Inicia sesión para cambiar la foto del grupo.');
    final ext = filename.toLowerCase().endsWith('.png')
        ? 'png'
        : filename.toLowerCase().endsWith('.webp')
            ? 'webp'
            : 'jpg';
    final path = '$groupId/${uid}_cover_${DateTime.now().millisecondsSinceEpoch}.$ext';
    await sb.storage.from('group-covers').uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(
        upsert: true,
        contentType: ext == 'png' ? 'image/png' : ext == 'webp' ? 'image/webp' : 'image/jpeg',
      ),
    );
    final publicUrl = sb.storage.from('group-covers').getPublicUrl(path);
    final versionedUrl = '$publicUrl?v=${DateTime.now().millisecondsSinceEpoch}';
    await sb.from('groups').update({
      'cover_url': versionedUrl,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', groupId);
    return versionedUrl;
  }

  static Future<void> removeGroupCover(String groupId) async {
    await sb.from('groups').update({
      'cover_url': null,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', groupId);
  }

  static Future<List<Map<String, dynamic>>> members(String groupId) async {
    final res = await sb.from('group_members').select('id, role, user_id, profiles(id,email,full_name,avatar_url)').eq('group_id', groupId).order('created_at');
    return asList(res);
  }

  static Future<void> updateMemberRole(String memberRowId, String role) async {
    if (!['admin', 'member'].contains(role)) {
      throw Exception('Rol no válido.');
    }
    try {
      await sb.rpc('set_group_member_role', params: {'p_member_row_id': memberRowId, 'p_role': role});
    } catch (_) {
      await sb.from('group_members').update({'role': role}).eq('id', memberRowId);
    }
  }

  static Future<void> removeMember(String memberRowId) async {
    try {
      await sb.rpc('remove_group_member', params: {'p_member_row_id': memberRowId});
    } catch (_) {
      await sb.from('group_members').delete().eq('id', memberRowId);
    }
  }

  static Future<void> leaveGroup(String groupId) async {
    final uid = user?.id;
    if (uid == null) return;
    try {
      await sb.rpc('leave_group_safe', params: {'p_group_id': groupId});
    } catch (_) {
      await sb.from('group_members').delete().eq('group_id', groupId).eq('user_id', uid);
    }
  }

  static Future<void> deleteGroup(String groupId, String confirmation) async {
    final clean = confirmation.trim().toUpperCase();
    if (clean != 'ELIMINAR GRUPO') {
      throw Exception('Para eliminar el grupo escribe ELIMINAR GRUPO exactamente.');
    }
    try {
      await sb.rpc('delete_group_safe', params: {
        'p_group_id': groupId,
        'p_confirm': clean,
      });
      return;
    } catch (e) {
      final message = e.toString().toLowerCase();
      if (message.contains('function') || message.contains('delete_group_safe')) {
        throw Exception('Falta ejecutar el SQL v15.25.5 para poder eliminar grupos de forma segura.');
      }
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> events(String groupId) async {
    final cleanGroupId = groupId.trim();
    if (cleanGroupId.isEmpty) return [];

    try {
      final res = await sb.rpc('group_events_with_attendance', params: {'p_group_id': cleanGroupId});
      final rows = asList(res);
      rows.sort((a, b) {
        final da = DateTime.tryParse(a['starts_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        final db = DateTime.tryParse(b['starts_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        return da.compareTo(db);
      });
      return rows;
    } catch (_) {
      // Si el SQL de v15.29.4 aún no está ejecutado, seguimos con la consulta directa.
    }

    try {
      final res = await sb
          .from('events')
          .select('*, event_attendance(status,user_id)')
          .eq('group_id', cleanGroupId)
          .order('starts_at');
      final rows = asList(res);
      rows.sort((a, b) {
        final da = DateTime.tryParse(a['starts_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        final db = DateTime.tryParse(b['starts_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        return da.compareTo(db);
      });
      return rows;
    } catch (_) {
      // Fallback defensivo: si Supabase no puede resolver el embed de asistencia
      // por una relación/política temporal, la agenda debe seguir mostrando eventos.
      final res = await sb.from('events').select('*').eq('group_id', cleanGroupId).order('starts_at');
      final rows = asList(res);
      rows.sort((a, b) {
        final da = DateTime.tryParse(a['starts_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        final db = DateTime.tryParse(b['starts_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        return da.compareTo(db);
      });
      return rows;
    }
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

  static Future<int> createEventSeries(
    String groupId,
    String title,
    DateTime firstStartsAt,
    String location,
    String notes,
    int minPeople,
    String frequency,
    int occurrences,
  ) async {
    final total = max(2, min(52, occurrences));
    final seriesId = newLocalUuid();
    final cleanTitle = title.trim();
    final cleanLocation = location.trim();
    final frequencyLabel = switch (frequency) {
      'biweekly' => 'cada 2 semanas',
      'monthly' => 'cada mes',
      _ => 'cada semana',
    };
    final routineLine = 'Rutina: $frequencyLabel · $total eventos generados';
    final cleanNotes = notes.trim().isEmpty ? routineLine : '${notes.trim()}\n\n$routineLine';

    DateTime occurrenceDate(int index) {
      if (frequency == 'biweekly') return firstStartsAt.add(Duration(days: 14 * index));
      if (frequency == 'monthly') {
        final monthIndex = firstStartsAt.month + index;
        final year = firstStartsAt.year + ((monthIndex - 1) ~/ 12);
        final month = ((monthIndex - 1) % 12) + 1;
        final lastDay = DateTime(year, month + 1, 0).day;
        final day = min(firstStartsAt.day, lastDay);
        return DateTime(year, month, day, firstStartsAt.hour, firstStartsAt.minute);
      }
      return firstStartsAt.add(Duration(days: 7 * index));
    }

    final rows = List.generate(total, (index) {
      final startsAt = occurrenceDate(index);
      return {
        'group_id': groupId,
        'title': cleanTitle,
        'starts_at': startsAt.toUtc().toIso8601String(),
        'location': cleanLocation.isEmpty ? null : cleanLocation,
        'notes': cleanNotes,
        'min_people': minPeople,
        'event_series_id': seriesId,
        'recurrence_frequency': frequency,
        'recurrence_index': index,
        'recurrence_count': total,
        'created_by': user?.id,
      };
    });

    await sb.from('events').insert(rows);
    return total;
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

  static Future<void> updateEventWithScope(String eventId, String scope, String title, DateTime startsAt, String location, String notes, int minPeople) async {
    final current = asMap(await sb.from('events').select('id,group_id,starts_at,event_series_id').eq('id', eventId).single());
    final seriesId = text(current['event_series_id']);
    if (seriesId.isEmpty || scope == 'single') {
      await updateEvent(eventId, title, startsAt, location, notes, minPeople);
      return;
    }

    final currentStart = DateTime.tryParse(text(current['starts_at']))?.toLocal() ?? startsAt;
    final rows = asList(await sb
        .from('events')
        .select('id,starts_at')
        .eq('event_series_id', seriesId)
        .eq('group_id', current['group_id'])
        .neq('status', 'cancelled')
        .order('starts_at'));

    final cleanTitle = title.trim();
    final cleanLocation = location.trim();
    final cleanNotes = notes.trim();
    for (final row in rows) {
      final rowId = text(row['id']);
      final rowDate = DateTime.tryParse(text(row['starts_at']))?.toLocal();
      if (rowId.isEmpty || rowDate == null) continue;
      if (scope == 'future' && rowDate.isBefore(currentStart.subtract(const Duration(minutes: 1)))) continue;
      final nextStart = rowId == eventId
          ? startsAt
          : DateTime(rowDate.year, rowDate.month, rowDate.day, startsAt.hour, startsAt.minute);
      await sb.from('events').update({
        'title': cleanTitle,
        'starts_at': nextStart.toUtc().toIso8601String(),
        'location': cleanLocation.isEmpty ? null : cleanLocation,
        'notes': cleanNotes.isEmpty ? null : cleanNotes,
        'min_people': minPeople,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', rowId);
    }
  }

  static Future<void> cancelEvent(String eventId) async {
    await sb.from('events').update({
      'status': 'cancelled',
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', eventId);
  }

  static Future<void> cancelEventWithScope(String eventId, String scope) async {
    final current = asMap(await sb.from('events').select('id,group_id,starts_at,event_series_id').eq('id', eventId).single());
    final seriesId = text(current['event_series_id']);
    if (seriesId.isEmpty || scope == 'single') {
      await cancelEvent(eventId);
      return;
    }
    dynamic query = sb
        .from('events')
        .update({'status': 'cancelled', 'updated_at': DateTime.now().toUtc().toIso8601String()})
        .eq('event_series_id', seriesId)
        .eq('group_id', current['group_id']);
    if (scope == 'future') {
      query = query.gte('starts_at', text(current['starts_at']));
    }
    await query;
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
    final res = await sb.from('expenses').select('*, profiles!expenses_paid_by_fkey(id,email,full_name,avatar_url), expense_participants(user_id,share_amount,paid)').eq('group_id', groupId).order('created_at', ascending: false);
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

  static Future<void> updateExpenseWithShares(
    String expenseId,
    String concept,
    double amount,
    String paidBy,
    Map<String, double> shares,
    String note,
  ) async {
    final cleanShares = <String, double>{};
    shares.forEach((id, value) {
      if (id.trim().isEmpty) return;
      final cleanValue = double.parse(max(0, value).toStringAsFixed(2));
      if (cleanValue > 0 || id == paidBy) cleanShares[id] = cleanValue;
    });
    cleanShares.putIfAbsent(paidBy, () => 0);

    await sb.from('expenses').update({
      'concept': concept.trim(),
      'amount': double.parse(amount.toStringAsFixed(2)),
      'paid_by': paidBy,
      'note': note.trim().isEmpty ? null : note.trim(),
      'status': 'pending',
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', expenseId);

    await sb.from('expense_participants').delete().eq('expense_id', expenseId);

    final rows = cleanShares.entries.map((entry) => {
      'expense_id': expenseId,
      'user_id': entry.key,
      'share_amount': double.parse(entry.value.toStringAsFixed(2)),
      'paid': entry.key == paidBy,
    }).toList();

    if (rows.isNotEmpty) {
      await sb.from('expense_participants').insert(rows);
    }
  }

  static Future<List<Map<String, dynamic>>> settlementPayments(String groupId) async {
    try {
      final res = await sb
          .from('settlement_payments')
          .select()
          .eq('group_id', groupId)
          .eq('status', 'paid')
          .order('paid_at', ascending: false);
      return asList(res);
    } catch (_) {
      return [];
    }
  }

  static Future<String> createSettlementPayment(
    String groupId,
    String fromUser,
    String toUser,
    double amount,
  ) async {
    final cleanAmount = double.parse(amount.toStringAsFixed(2));
    if (cleanAmount <= 0) throw Exception('El importe debe ser mayor que cero.');

    // Preferimos RPC para evitar fallos de RLS/SQL al registrar una liquidación.
    // Si la base aún no tiene la función del parche, usamos el insert directo como respaldo.
    try {
      final rpcId = await sb.rpc('create_settlement_payment_atomic', params: {
        'p_group_id': groupId,
        'p_from_user': fromUser,
        'p_to_user': toUser,
        'p_amount': cleanAmount,
      });
      final id = rpcId?.toString() ?? '';
      if (id.isNotEmpty) return id;
    } catch (_) {
      // Compatibilidad con instalaciones que todavía no han ejecutado el parche.
    }

    final currentUser = user?.id;
    if (currentUser == null || currentUser.isEmpty) {
      throw Exception('Tu sesión no está activa. Cierra sesión y vuelve a entrar.');
    }

    final row = await sb.from('settlement_payments').insert({
      'group_id': groupId,
      'from_user': fromUser,
      'to_user': toUser,
      'amount': cleanAmount,
      'status': 'paid',
      'created_by': currentUser,
      'paid_at': DateTime.now().toUtc().toIso8601String(),
    }).select('id').single();
    return row['id'].toString();
  }

  static Future<void> cancelSettlementPayment(String paymentId) async {
    if (paymentId.trim().isEmpty) throw Exception('No se ha podido identificar el pago.');

    // Preferimos RPC para validar permisos y evitar inconsistencias.
    try {
      await sb.rpc('cancel_settlement_payment_atomic', params: {
        'p_payment_id': paymentId,
      });
      return;
    } catch (_) {
      // Compatibilidad con instalaciones que todavía no han ejecutado el parche.
    }

    await sb.from('settlement_payments').update({
      'status': 'cancelled',
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', paymentId);
  }

  static Future<List<Map<String, dynamic>>> tournaments(String groupId) async {
    final rows = asList(await sb
        .from('tournaments')
        .select()
        .eq('group_id', groupId)
        .order('created_at', ascending: false));

    final output = <Map<String, dynamic>>[];
    for (final row in rows) {
      final id = row['id'].toString();
      try {
        final teams = asList(await sb
            .from('tournament_teams')
            .select('id,name,avatar_url,color,seed,status,captain_id,created_at')
            .eq('tournament_id', id)
            .order('seed', ascending: true)
            .order('created_at', ascending: true));
        final matches = asList(await sb
            .from('matches')
            .select('id,team_a,team_b,score_a,score_b,result_details,round,round_name,order_index,status,scheduled_at,duration_minutes,location,court_name,event_id,winner_team_id,result_status,notes,played_at,created_at,updated_at')
            .eq('tournament_id', id)
            .order('round', ascending: true)
            .order('order_index', ascending: true)
            .order('created_at', ascending: true));
        output.add({...row, 'tournament_teams': teams, 'matches': matches});
      } catch (_) {
        output.add({...row, 'tournament_teams': <Map<String, dynamic>>[], 'matches': <Map<String, dynamic>>[]});
      }
    }
    return output;
  }

  static Future<Map<String, dynamic>> tournament(String tournamentId) async {
    final row = asMap(await sb
        .from('tournaments')
        .select()
        .eq('id', tournamentId)
        .single());
    final teams = asList(await sb
        .from('tournament_teams')
        .select('id,name,avatar_url,color,seed,status,captain_id,created_at')
        .eq('tournament_id', tournamentId)
        .order('seed', ascending: true)
        .order('created_at', ascending: true));
    final matches = asList(await sb
        .from('matches')
        .select('id,team_a,team_b,score_a,score_b,result_details,round,round_name,order_index,status,scheduled_at,duration_minutes,location,court_name,event_id,winner_team_id,result_status,notes,played_at,created_at,updated_at')
        .eq('tournament_id', tournamentId)
        .order('round', ascending: true)
        .order('order_index', ascending: true)
        .order('created_at', ascending: true));
    return {...row, 'tournament_teams': teams, 'matches': matches};
  }

  static Future<String> createTournament(
    String groupId,
    String name, {
    String format = 'liga',
    String teamType = 'equipo',
    String scoringType = 'general',
    Map<String, dynamic>? scoringConfig,
    Map<String, dynamic>? formatConfig,
    Map<String, dynamic>? scheduleConfig,
    List<String>? tieBreakers,
    Map<String, dynamic>? permissionsConfig,
    String status = 'scheduled',
    DateTime? startsAt,
  }) async {
    final payload = {
      'group_id': groupId,
      'name': name.trim(),
      'format': format,
      'team_type': teamType,
      'scoring_type': scoringType,
      'scoring_config': scoringConfig ?? scoringConfigForType(scoringType),
      'format_config': formatConfig ?? <String, dynamic>{},
      'schedule_config': scheduleConfig ?? <String, dynamic>{},
      'tie_breakers': tieBreakers ?? defaultTieBreakers(scoringType),
      'permissions_config': permissionsConfig ?? {'admin_edit': true, 'members_results': false, 'rival_confirmation': false},
      'status': status,
      'starts_at': startsAt?.toUtc().toIso8601String(),
      'created_by': user?.id,
    };

    try {
      final row = await sb.from('tournaments').insert(payload).select('id').single();
      return row['id'].toString();
    } catch (e) {
      final text = e.toString().toLowerCase();
      if (!text.contains('format_config') && !text.contains('schedule_config') && !text.contains('tie_breakers') && !text.contains('permissions_config') && !text.contains('scoring_type') && !text.contains('scoring_config')) rethrow;
      final fallback = Map<String, dynamic>.from(payload)
        ..remove('scoring_type')
        ..remove('scoring_config')
        ..remove('format_config')
        ..remove('schedule_config')
        ..remove('tie_breakers')
        ..remove('permissions_config')
        ..remove('starts_at');
      final row = await sb.from('tournaments').insert(fallback).select('id').single();
      return row['id'].toString();
    }
  }

  static Future<void> updateTournamentStatus(String tournamentId, String status) async {
    await sb.from('tournaments').update({
      'status': status,
      'finished_at': status == 'finished' ? DateTime.now().toUtc().toIso8601String() : null,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', tournamentId);
  }

  static Future<void> deleteTournament(String tournamentId) async {
    await sb.from('tournaments').delete().eq('id', tournamentId);
  }

  static Future<String> addTournamentTeam(String tournamentId, String name, {int? seed}) async {
    final row = await sb.from('tournament_teams').insert({
      'tournament_id': tournamentId,
      'name': name.trim(),
      'seed': seed,
      'status': 'active',
    }).select('id').single();
    return row['id'].toString();
  }

  static Future<int> addTournamentTeams(String tournamentId, List<String> names) async {
    final clean = parseTournamentParticipantNames(names.join('\n'));
    if (clean.isEmpty) return 0;
    await sb.from('tournament_teams').insert(List.generate(clean.length, (index) => {
      'tournament_id': tournamentId,
      'name': clean[index],
      'seed': index + 1,
      'status': 'active',
    }));
    return clean.length;
  }

  static Future<int> addTournamentTeamsFromMembers(String tournamentId, List<Map<String, dynamic>> members) async {
    if (members.isEmpty) return 0;
    final existing = asList(await sb.from('tournament_teams').select('seed,name,captain_id,status').eq('tournament_id', tournamentId));
    final startSeed = existing.fold<int>(0, (value, row) => max(value, intValue(row['seed']))) + 1;
    final existingCaptains = existing.map((row) => text(row['captain_id'])).where((id) => id.isNotEmpty).toSet();
    final existingNames = existing.map((row) => text(row['name']).trim().toLowerCase()).where((name) => name.isNotEmpty).toSet();
    final payload = <Map<String, dynamic>>[];
    final sourceByUserId = <String, Map<String, dynamic>>{};

    for (final member in members) {
      final profile = asMap(member['profiles']);
      final userId = text(member['user_id'], text(profile['id']));
      final name = memberDisplayName(member).trim();
      if (name.length < 2) continue;
      if (userId.isNotEmpty && existingCaptains.contains(userId)) continue;
      if (existingNames.contains(name.toLowerCase())) continue;
      final avatar = memberAvatarUrl(member);
      sourceByUserId[userId] = member;
      payload.add({
        'tournament_id': tournamentId,
        'name': name,
        'avatar_url': avatar.trim().isEmpty ? null : avatar.trim(),
        'seed': startSeed + payload.length,
        'status': 'active',
        'captain_id': userId.trim().isEmpty ? null : userId,
      });
      if (userId.isNotEmpty) existingCaptains.add(userId);
      existingNames.add(name.toLowerCase());
    }

    if (payload.isEmpty) return 0;
    final inserted = asList(await sb.from('tournament_teams').insert(payload).select('id,name,captain_id'));
    final memberRows = <Map<String, dynamic>>[];
    for (final row in inserted) {
      final userId = text(row['captain_id']);
      memberRows.add({
        'tournament_team_id': row['id'],
        'user_id': userId.trim().isEmpty ? null : userId,
        'display_name': text(row['name']),
        'role': 'player',
      });
    }
    if (memberRows.isNotEmpty) {
      try { await sb.from('tournament_team_members').insert(memberRows); } catch (_) {}
    }
    return inserted.length;
  }

  static Future<String> addTournamentPairFromMembers(String tournamentId, Map<String, dynamic> first, Map<String, dynamic> second, {String? customName}) async {
    final existing = asList(await sb.from('tournament_teams').select('seed,name').eq('tournament_id', tournamentId));
    final seed = existing.fold<int>(0, (value, row) => max(value, intValue(row['seed']))) + 1;
    final existingNames = existing.map((row) => text(row['name']).trim().toLowerCase()).toSet();
    final firstProfile = asMap(first['profiles']);
    final secondProfile = asMap(second['profiles']);
    final firstId = text(first['user_id'], text(firstProfile['id']));
    final secondId = text(second['user_id'], text(secondProfile['id']));
    if (firstId.isNotEmpty && secondId.isNotEmpty && firstId == secondId) throw Exception('Elige dos miembros distintos.');
    final firstName = memberDisplayName(first);
    final secondName = memberDisplayName(second);
    final pairName = (customName ?? '').trim().isNotEmpty ? customName!.trim() : '$firstName / $secondName';
    if (existingNames.contains(pairName.toLowerCase())) throw Exception('Ya existe un participante con ese nombre.');
    final avatar = memberAvatarUrl(first).trim().isNotEmpty ? memberAvatarUrl(first) : memberAvatarUrl(second);

    final row = asMap(await sb.from('tournament_teams').insert({
      'tournament_id': tournamentId,
      'name': pairName,
      'avatar_url': avatar.trim().isEmpty ? null : avatar.trim(),
      'seed': seed,
      'status': 'active',
      'captain_id': firstId.trim().isEmpty ? null : firstId,
    }).select('id').single());

    final teamId = text(row['id']);
    try {
      await sb.from('tournament_team_members').insert([
        {
          'tournament_team_id': teamId,
          'user_id': firstId.trim().isEmpty ? null : firstId,
          'display_name': firstName,
          'role': 'player',
        },
        {
          'tournament_team_id': teamId,
          'user_id': secondId.trim().isEmpty ? null : secondId,
          'display_name': secondName,
          'role': 'player',
        },
      ]);
    } catch (_) {}
    return teamId;
  }

  static Future<void> updateTournamentEditor(
    String tournamentId, {
    required String name,
    required String scoringType,
    required Map<String, dynamic> scoringConfig,
    required Map<String, dynamic> formatConfig,
    required List<String> tieBreakers,
  }) async {
    final clean = name.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (clean.length < 2) throw Exception('El nombre debe tener al menos 2 caracteres.');
    await sb.from('tournaments').update({
      'name': clean,
      'scoring_type': scoringType,
      'scoring_config': scoringConfig,
      'format_config': formatConfig,
      'tie_breakers': tieBreakers,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', tournamentId);
  }

  static Future<void> renameTournamentTeam(String teamId, String name) async {
    final clean = name.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (clean.length < 2) throw Exception('El nombre debe tener al menos 2 caracteres.');
    await sb.from('tournament_teams').update({
      'name': clean,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', teamId);
  }

  static Future<void> updateTournamentTeamSeed(String teamId, int seed) async {
    await sb.from('tournament_teams').update({
      'seed': max(1, seed),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', teamId);
  }

  static Future<void> retireTournamentTeam(String teamId) async {
    await sb.from('tournament_teams').update({
      'status': 'retired',
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', teamId);
  }

  static Future<void> deleteTournamentTeam(String teamId) async {
    await sb.from('tournament_teams').delete().eq('id', teamId);
  }

  static Future<String> safeRemoveTournamentTeam(String teamId) async {
    final asA = asList(await sb.from('matches').select('id,status,result_details,score_a,score_b').eq('team_a', teamId));
    final asB = asList(await sb.from('matches').select('id,status,result_details,score_a,score_b').eq('team_b', teamId));
    final linked = [...asA, ...asB];
    if (linked.isEmpty) {
      await deleteTournamentTeam(teamId);
      return 'deleted';
    }
    await retireTournamentTeam(teamId);
    return 'retired';
  }

  static Future<void> clearTournamentMatches(String tournamentId) async {
    await sb.from('matches').delete().eq('tournament_id', tournamentId);
  }

  static Future<void> createManualMatches(
    String tournamentId,
    List<Map<String, dynamic>> teams,
    List<TournamentDraftMatch> pairings, {
    Map<String, dynamic>? scheduleConfig,
  }) async {
    if (pairings.isEmpty) throw Exception('Añade al menos un emparejamiento manual.');
    await clearTournamentMatches(tournamentId);
    await addManualMatches(tournamentId, teams, pairings, scheduleConfig: scheduleConfig);
  }

  static Future<void> addManualMatches(
    String tournamentId,
    List<Map<String, dynamic>> teams,
    List<TournamentDraftMatch> pairings, {
    Map<String, dynamic>? scheduleConfig,
  }) async {
    if (pairings.isEmpty) throw Exception('Añade al menos un emparejamiento manual.');
    final byName = <String, String>{
      for (final team in teams) AppData.text(team['name']).trim().toLowerCase(): team['id'].toString(),
    };
    final rows = <Map<String, dynamic>>[];
    final roundCounters = <int, int>{};
    for (var i = 0; i < pairings.length; i++) {
      final pair = pairings[i];
      final aId = byName[pair.teamAName.trim().toLowerCase()];
      final bId = byName[pair.teamBName.trim().toLowerCase()];
      if (aId == null || bId == null) {
        throw Exception('No encuentro en participantes: ${aId == null ? pair.teamAName : pair.teamBName}.');
      }
      if (aId == bId) throw Exception('Un equipo no puede jugar contra sí mismo.');
      final round = max(1, pair.round);
      final orderInsideRound = roundCounters[round] ?? 0;
      roundCounters[round] = orderInsideRound + 1;
      final scheduledAt = tournamentScheduledAtForIndex(scheduleConfig, round, orderInsideRound);
      final court = tournamentCourtNameForIndex(scheduleConfig, orderInsideRound);
      rows.add({
        'tournament_id': tournamentId,
        'team_a': aId,
        'team_b': bId,
        'round': round,
        'round_name': 'Jornada $round',
        'order_index': i,
        'status': scheduledAt == null ? 'pending' : 'scheduled',
        'scheduled_at': scheduledAt?.toUtc().toIso8601String(),
        'duration_minutes': max(15, intValue(scheduleConfig?['duration_minutes'], 60)),
        'location': text(scheduleConfig?['location']).trim().isEmpty ? null : text(scheduleConfig?['location']).trim(),
        'court_name': court.isEmpty ? null : court,
      });
    }
    await sb.from('matches').insert(rows);
  }

  static Future<void> createManualMatchRows(
    String tournamentId,
    List<Map<String, dynamic>> teams,
    List<TournamentManualDraftRow> rows, {
    Map<String, dynamic>? scheduleConfig,
  }) async {
    final cleanRows = rows.where((r) => r.teamAName.trim().isNotEmpty && r.teamBName.trim().isNotEmpty).toList();
    if (cleanRows.isEmpty) throw Exception('Añade al menos un partido manual.');
    await clearTournamentMatches(tournamentId);
    final byName = <String, String>{
      for (final team in teams) AppData.text(team['name']).trim().toLowerCase(): team['id'].toString(),
    };
    final payload = <Map<String, dynamic>>[];
    final roundCounters = <int, int>{};
    for (var i = 0; i < cleanRows.length; i++) {
      final row = cleanRows[i];
      final aId = byName[row.teamAName.trim().toLowerCase()];
      final bId = byName[row.teamBName.trim().toLowerCase()];
      if (aId == null || bId == null) {
        throw Exception('No encuentro en participantes: ${aId == null ? row.teamAName : row.teamBName}.');
      }
      if (aId == bId) throw Exception('Un equipo no puede jugar contra sí mismo.');
      final round = max(1, row.round);
      final orderInsideRound = roundCounters[round] ?? 0;
      roundCounters[round] = orderInsideRound + 1;
      final fallbackDate = tournamentScheduledAtForIndex(scheduleConfig, round, orderInsideRound);
      final scheduledAt = row.scheduledAt ?? fallbackDate;
      final court = row.courtName.trim().isNotEmpty ? row.courtName.trim() : tournamentCourtNameForIndex(scheduleConfig, orderInsideRound);
      payload.add({
        'tournament_id': tournamentId,
        'team_a': aId,
        'team_b': bId,
        'round': round,
        'round_name': 'Jornada $round',
        'order_index': i,
        'status': scheduledAt == null ? 'pending' : 'scheduled',
        'scheduled_at': scheduledAt?.toUtc().toIso8601String(),
        'duration_minutes': max(15, row.durationMinutes),
        'location': row.location.trim().isEmpty ? (text(scheduleConfig?['location']).trim().isEmpty ? null : text(scheduleConfig?['location']).trim()) : row.location.trim(),
        'court_name': court.isEmpty ? null : court,
        'notes': row.notes.trim().isEmpty ? null : row.notes.trim(),
      });
    }
    await sb.from('matches').insert(payload);
  }

  static Future<Map<String, dynamic>> addTournamentMatch({
    required String tournamentId,
    required String teamAId,
    required String teamBId,
    required int round,
    DateTime? scheduledAt,
    int durationMinutes = 60,
    String location = '',
    String courtName = '',
    String notes = '',
  }) async {
    if (teamAId.trim().isEmpty || teamBId.trim().isEmpty) throw Exception('Elige dos participantes.');
    if (teamAId == teamBId) throw Exception('Un participante no puede jugar contra sí mismo.');
    final existing = asList(await sb
        .from('matches')
        .select('order_index')
        .eq('tournament_id', tournamentId)
        .eq('round', max(1, round))
        .order('order_index', ascending: false)
        .limit(1));
    final nextOrder = existing.isEmpty ? 0 : intValue(existing.first['order_index']) + 1;
    final row = asMap(await sb.from('matches').insert({
      'tournament_id': tournamentId,
      'team_a': teamAId,
      'team_b': teamBId,
      'round': max(1, round),
      'round_name': 'Jornada ${max(1, round)}',
      'order_index': nextOrder,
      'status': scheduledAt == null ? 'pending' : 'scheduled',
      'scheduled_at': scheduledAt?.toUtc().toIso8601String(),
      'duration_minutes': max(15, durationMinutes),
      'location': location.trim().isEmpty ? null : location.trim(),
      'court_name': courtName.trim().isEmpty ? null : courtName.trim(),
      'notes': notes.trim().isEmpty ? null : notes.trim(),
      'updated_by': user?.id,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).select().single());
    return row;
  }

  static Future<void> duplicateTournamentRound(String tournamentId, int sourceRound) async {
    final source = asList(await sb
        .from('matches')
        .select('team_a,team_b,duration_minutes,location,court_name,notes')
        .eq('tournament_id', tournamentId)
        .eq('round', max(1, sourceRound))
        .order('order_index', ascending: true)
        .order('created_at', ascending: true));
    if (source.isEmpty) throw Exception('No hay partidos en esa jornada.');
    final rounds = asList(await sb.from('matches').select('round').eq('tournament_id', tournamentId));
    final nextRound = rounds.fold<int>(0, (value, row) => max(value, intValue(row['round']))) + 1;
    final rows = <Map<String, dynamic>>[];
    for (var i = 0; i < source.length; i++) {
      final match = source[i];
      rows.add({
        'tournament_id': tournamentId,
        'team_a': match['team_a'],
        'team_b': match['team_b'],
        'round': nextRound,
        'round_name': 'Jornada $nextRound',
        'order_index': i,
        'status': 'pending',
        'duration_minutes': max(15, intValue(match['duration_minutes'], 60)),
        'location': text(match['location']).trim().isEmpty ? null : text(match['location']).trim(),
        'court_name': text(match['court_name']).trim().isEmpty ? null : text(match['court_name']).trim(),
        'notes': text(match['notes']).trim().isEmpty ? null : text(match['notes']).trim(),
      });
    }
    await sb.from('matches').insert(rows);
  }

  static Future<void> shiftTournamentMatchOrder(String matchId, List<Map<String, dynamic>> matches, int delta) async {
    Map<String, dynamic>? current;
    for (final match in matches) {
      if (text(match['id']) == matchId) {
        current = match;
        break;
      }
    }
    if (current == null) return;
    final round = intValue(current['round'], 1);
    final sameRound = matches.where((m) => intValue(m['round'], 1) == round).toList()
      ..sort((a, b) {
        final order = intValue(a['order_index']).compareTo(intValue(b['order_index']));
        if (order != 0) return order;
        return text(a['created_at']).compareTo(text(b['created_at']));
      });
    final index = sameRound.indexWhere((m) => text(m['id']) == matchId);
    final targetIndex = index + delta;
    if (index < 0 || targetIndex < 0 || targetIndex >= sameRound.length) return;
    final other = sameRound[targetIndex];
    final currentOrder = intValue(current['order_index']);
    final otherOrder = intValue(other['order_index']);
    await sb.from('matches').update({'order_index': otherOrder, 'updated_at': DateTime.now().toUtc().toIso8601String()}).eq('id', matchId);
    await sb.from('matches').update({'order_index': currentOrder, 'updated_at': DateTime.now().toUtc().toIso8601String()}).eq('id', other['id']);
  }

  static Future<void> createTournamentAgendaEvents(String groupId, String tournamentName, List<TournamentDraftMatch> pairings, DateTime firstStart) async {
    if (pairings.isEmpty) return;
    var index = 0;
    for (final pair in pairings.take(60)) {
      final start = firstStart.add(Duration(minutes: 60 * index));
      await createEvent(
        groupId,
        '$tournamentName: ${pair.teamAName} vs ${pair.teamBName}',
        start,
        '',
        'Partido de torneo · Jornada ${pair.round}',
        2,
      );
      index++;
    }
  }

  static Future<void> createAgendaEventsForTournament(String groupId, String tournamentId, String tournamentName) async {
    final data = await tournament(tournamentId);
    final teams = tournamentTeams(data);
    final names = teamNameMap(teams);
    final matches = tournamentMatches(data).where((m) => AppData.text(m['scheduled_at']).isNotEmpty && AppData.text(m['event_id']).isEmpty).take(80).toList();
    for (final match in matches) {
      final start = DateTime.tryParse(AppData.text(match['scheduled_at']))?.toLocal();
      if (start == null) continue;
      final eventId = await createEvent(
        groupId,
        tournamentMatchAgendaTitle(tournamentName, match, names),
        start,
        AppData.text(match['location']),
        tournamentMatchAgendaNotes(match),
        2,
      );
      await sb.from('matches').update({'event_id': eventId, 'updated_at': DateTime.now().toUtc().toIso8601String()}).eq('id', match['id']);
    }
  }

  static Future<void> generateMatches(
    String tournamentId,
    String format,
    List<Map<String, dynamic>> teams, {
    Map<String, dynamic>? formatConfig,
    Map<String, dynamic>? scheduleConfig,
  }) async {
    if (teams.length < 2) {
      throw Exception('Añade al menos 2 participantes.');
    }
    if (format == 'manual') {
      throw Exception('Este torneo usa emparejamientos manuales. Añade los partidos desde el panel del torneo.');
    }

    await clearTournamentMatches(tournamentId);

    final rows = <Map<String, dynamic>>[];
    final ordered = teams.map((t) => Map<String, dynamic>.from(t)).toList();
    final randomizePairings = text(formatConfig?['randomize_pairings'], 'true') != 'false';
    if (randomizePairings && format != 'manual') {
      ordered.shuffle(Random.secure());
    }
    var orderIndex = 0;

    final roundCounters = <int, int>{};

    Map<String, dynamic> rowFor(Map<String, dynamic>? a, Map<String, dynamic>? b, int round, {String? status, int? scoreA, int? scoreB, Map<String, dynamic>? details}) {
      final orderInsideRound = roundCounters[round] ?? 0;
      roundCounters[round] = orderInsideRound + 1;
      final scheduledAt = tournamentScheduledAtForIndex(scheduleConfig, round, orderInsideRound);
      final court = tournamentCourtNameForIndex(scheduleConfig, orderInsideRound);
      final row = {
        'tournament_id': tournamentId,
        'team_a': a?['id'],
        'team_b': b?['id'],
        'score_a': scoreA,
        'score_b': scoreB,
        'round': round,
        'round_name': format == 'eliminatoria' ? eliminationRoundName(round, ordered.length) : format == 'americano' ? 'Ronda $round' : 'Jornada $round',
        'order_index': orderIndex,
        'status': status ?? (scheduledAt == null ? 'pending' : 'scheduled'),
        'scheduled_at': scheduledAt?.toUtc().toIso8601String(),
        'duration_minutes': max(15, intValue(scheduleConfig?['duration_minutes'], 60)),
        'location': text(scheduleConfig?['location']).trim().isEmpty ? null : text(scheduleConfig?['location']).trim(),
        'court_name': court.isEmpty ? null : court,
        'result_details': details,
      };
      orderIndex++;
      return row;
    }

    if (format == 'americano') {
      if (ordered.length < 4) {
        throw Exception('El americano necesita al menos 4 jugadores.');
      }
      final rounds = max(1, min(40, intValue(formatConfig?['americano_rounds'], intValue(formatConfig?['rounds'], 5))));
      final courts = max(1, min(12, intValue(formatConfig?['courts_count'], intValue(scheduleConfig?['courts_count'], 1))));
      final generated = generateAmericanoRoundsIds(ordered.map((e) => e['id'].toString()).toList(), rounds: rounds, courts: courts);
      if (generated.isEmpty) {
        throw Exception('No se han podido generar rondas de americano.');
      }
      final teamById = {for (final team in ordered) team['id'].toString(): team};
      for (final item in generated) {
        final a1 = teamById[item.sideA.first];
        final b1 = teamById[item.sideB.first];
        rows.add(rowFor(
          a1,
          b1,
          item.round,
          details: {
            'americano': true,
            'side_a_ids': item.sideA,
            'side_b_ids': item.sideB,
            'rest_ids': item.resting,
            'court_index': item.courtIndex + 1,
            'ranking_mode': 'individual',
          },
        ));
      }
    } else if (format == 'eliminatoria') {
      final targetBracket = nextPowerOfTwoAtLeast(ordered.length);
      final byes = max(0, targetBracket - ordered.length);
      final byeRows = <Map<String, dynamic>>[];
      final playRows = <Map<String, dynamic>>[];

      for (final team in ordered.take(byes)) {
        byeRows.add(rowFor(
          team,
          null,
          1,
          status: 'bye',
          scoreA: 1,
          scoreB: 0,
          details: {'bye': true, 'stage': 'bye', 'seed': intValue(team['seed'])},
        ));
      }

      final playTeams = ordered.skip(byes).toList();
      var left = 0;
      var right = playTeams.length - 1;
      while (left < right) {
        playRows.add(rowFor(
          playTeams[left],
          playTeams[right],
          1,
          details: {
            'stage': 'knockout',
            'seed_a': intValue(playTeams[left]['seed']),
            'seed_b': intValue(playTeams[right]['seed']),
          },
        ));
        left++;
        right--;
      }

      final maxRows = max(byeRows.length, playRows.length);
      for (var i = 0; i < maxRows; i++) {
        if (i < byeRows.length) rows.add(byeRows[i]);
        if (i < playRows.length) rows.add(playRows[i]);
      }
    } else {
      final legs = max(1, min(4, intValue(formatConfig?['legs'], 1)));
      final maxRounds = intValue(formatConfig?['max_rounds']);
      final base = generateRoundRobinIds(ordered.map((e) => e['id'].toString()).toList());
      final limited = maxRounds > 0 ? base.take(maxRounds).toList() : base;
      for (var leg = 1; leg <= legs; leg++) {
        for (var r = 0; r < limited.length; r++) {
          final round = r + 1 + ((leg - 1) * limited.length);
          for (final pair in limited[r]) {
            final a = ordered.firstWhere((t) => t['id'].toString() == pair.$1);
            final b = ordered.firstWhere((t) => t['id'].toString() == pair.$2);
            rows.add(leg.isOdd ? rowFor(a, b, round) : rowFor(b, a, round));
          }
        }
      }
    }

    if (rows.isEmpty) throw Exception('No se han podido generar partidos.');
    await sb.from('matches').insert(rows);
  }

  static Future<void> generateNextEliminationRound(String tournamentId, List<Map<String, dynamic>> matches) async {
    final normalMatches = matches.where((m) => AppData.text(AppData.asMap(m['result_details'])['stage']) != 'third_place').toList();
    final latestRound = normalMatches.fold<int>(0, (maxRound, m) => max(maxRound, intValue(m['round'])));
    final latestMatches = normalMatches.where((m) => intValue(m['round']) == latestRound).toList()
      ..sort((a, b) => intValue(a['order_index']).compareTo(intValue(b['order_index'])));
    if (latestMatches.isEmpty) throw Exception('No hay partidos para generar la siguiente ronda.');
    if (latestMatches.any((m) => text(m['status']) != 'played' && text(m['status']) != 'bye' && text(m['status']) != 'walkover' && text(m['status']) != 'no_show')) {
      throw Exception('Cierra todos los resultados de la ronda actual antes de avanzar.');
    }
    if (latestMatches.length == 1) throw Exception('La eliminatoria ya tiene final registrada.');

    final winners = <String>[];
    for (final match in latestMatches) {
      final winner = tournamentMatchWinnerId(match);
      if (winner.isEmpty) throw Exception('Hay un partido sin ganador válido.');
      winners.add(winner);
    }
    if (winners.length % 2 != 0) throw Exception('Número impar de ganadores. Revisa resultados.');
    final rows = <Map<String, dynamic>>[];
    for (var i = 0; i < winners.length; i += 2) {
      rows.add({
        'tournament_id': tournamentId,
        'team_a': winners[i],
        'team_b': winners[i + 1],
        'round': latestRound + 1,
        'round_name': eliminationRoundNameForRemaining(winners.length),
        'order_index': i ~/ 2,
        'status': 'pending',
        'result_details': {'stage': winners.length == 2 ? 'final' : 'knockout'},
      });
    }
    await sb.from('matches').insert(rows);
  }

  static Future<void> generateThirdPlaceMatch(String tournamentId, List<Map<String, dynamic>> matches) async {
    if (matches.any((m) => text(asMap(m['result_details'])['stage']) == 'third_place' || text(m['round_name']).toLowerCase().contains('tercer'))) {
      throw Exception('El partido por el tercer puesto ya existe.');
    }

    final normalMatches = matches.where((m) => text(asMap(m['result_details'])['stage']) != 'third_place').toList();
    final rounds = normalMatches.map((m) => intValue(m['round'])).toSet().toList()..sort();
    if (rounds.length < 2) {
      throw Exception('Necesitas tener semifinales cerradas para crear el tercer puesto.');
    }

    List<Map<String, dynamic>> semis = [];
    for (final round in rounds.reversed) {
      final roundMatches = normalMatches.where((m) => intValue(m['round']) == round).toList()
        ..sort((a, b) => intValue(a['order_index']).compareTo(intValue(b['order_index'])));
      if (roundMatches.length == 2) {
        semis = roundMatches;
        break;
      }
    }
    if (semis.length != 2) throw Exception('No encuentro dos semifinales para sacar el tercer puesto.');
    if (semis.any((m) => text(m['status']) != 'played' && text(m['status']) != 'walkover' && text(m['status']) != 'no_show')) {
      throw Exception('Cierra las dos semifinales antes de crear el tercer puesto.');
    }

    final losers = semis.map(tournamentMatchLoserId).where((id) => id.isNotEmpty).toList();
    if (losers.length != 2) throw Exception('No se han podido detectar los dos perdedores de semifinales.');

    final targetRound = normalMatches.fold<int>(0, (value, m) => max(value, intValue(m['round'])));
    await sb.from('matches').insert({
      'tournament_id': tournamentId,
      'team_a': losers[0],
      'team_b': losers[1],
      'round': targetRound,
      'round_name': 'Tercer puesto',
      'order_index': 999,
      'status': 'pending',
      'result_details': {'stage': 'third_place'},
    });
  }

  static Future<void> setMatchResult(String matchId, int scoreA, int scoreB, {Map<String, dynamic>? details}) async {
    final current = asMap(await sb
        .from('matches')
        .select('team_a,team_b,score_a,score_b,status,result_details,winner_team_id')
        .eq('id', matchId)
        .single());
    final winner = scoreA == scoreB ? null : (scoreA > scoreB ? current['team_a'] : current['team_b']);
    final nextDetails = <String, dynamic>{...?details}
      ..remove('special_result')
      ..remove('loser_team_id')
      ..remove('no_show_team_id');
    nextDetails['history'] = matchHistoryWithEntry(current, 'Marcador guardado', '$scoreA - $scoreB');
    await sb.from('matches').update({
      'score_a': scoreA,
      'score_b': scoreB,
      'result_details': nextDetails,
      'winner_team_id': winner,
      'status': 'played',
      'result_status': 'confirmed',
      'played_at': DateTime.now().toUtc().toIso8601String(),
      'updated_by': user?.id,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', matchId);
  }

  static Future<void> setSpecialMatchResult(
    String matchId, {
    required String winnerTeamId,
    required String loserTeamId,
    required String specialResult,
    String note = '',
  }) async {
    final current = asMap(await sb
        .from('matches')
        .select('team_a,team_b,score_a,score_b,status,result_details,winner_team_id')
        .eq('id', matchId)
        .single());
    final aId = text(current['team_a']);
    final bId = text(current['team_b']);
    if (aId.isEmpty || bId.isEmpty) throw Exception('Este partido no tiene dos participantes.');
    if (winnerTeamId != aId && winnerTeamId != bId) throw Exception('Ganador no válido.');
    final winnerIsA = winnerTeamId == aId;
    final scoreA = winnerIsA ? 3 : 0;
    final scoreB = winnerIsA ? 0 : 3;
    final status = specialResult == 'no_show' ? 'no_show' : 'walkover';
    final label = specialResult == 'no_show' ? 'No presentado' : 'Victoria administrativa';
    final details = <String, dynamic>{
      'special_result': specialResult,
      'label': label,
      'loser_team_id': loserTeamId,
      if (specialResult == 'no_show') 'no_show_team_id': loserTeamId,
      if (note.trim().isNotEmpty) 'note': note.trim(),
      'history': matchHistoryWithEntry(current, label, note.trim().isEmpty ? '$scoreA - $scoreB' : note.trim()),
    };
    await sb.from('matches').update({
      'score_a': scoreA,
      'score_b': scoreB,
      'result_details': details,
      'winner_team_id': winnerTeamId,
      'status': status,
      'result_status': 'confirmed',
      'played_at': DateTime.now().toUtc().toIso8601String(),
      'updated_by': user?.id,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', matchId);
  }

  static Future<void> reopenMatch(String matchId) async {
    final current = asMap(await sb
        .from('matches')
        .select('team_a,team_b,score_a,score_b,status,result_details,winner_team_id')
        .eq('id', matchId)
        .single());
    final details = <String, dynamic>{
      'history': matchHistoryWithEntry(current, 'Resultado borrado', 'El partido vuelve a pendiente.'),
    };
    await sb.from('matches').update({
      'score_a': null,
      'score_b': null,
      'result_details': details,
      'winner_team_id': null,
      'status': 'pending',
      'result_status': 'pending',
      'played_at': null,
      'updated_by': user?.id,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', matchId);
  }

  static Future<void> updateMatchSchedule(String matchId, DateTime? scheduledAt, int durationMinutes, String location, String courtName, String notes) async {
    final current = asMap(await sb.from('matches').select('id,event_id,team_a,team_b,tournament_id,round,round_name,status,score_a,score_b,result_details').eq('id', matchId).single());
    final eventId = text(current['event_id']);
    final nextDetails = Map<String, dynamic>.from(asMap(current['result_details']));
    final action = scheduledAt == null ? 'Fecha eliminada' : 'Fecha actualizada';
    final dateNote = scheduledAt == null
        ? 'El partido queda sin fecha.'
        : '${DateFormat('d MMM yyyy · HH:mm', 'es_ES').format(scheduledAt.toLocal())}${courtName.trim().isEmpty ? '' : ' · ${courtName.trim()}'}';
    nextDetails['history'] = matchHistoryWithEntry(current, action, dateNote);
    await sb.from('matches').update({
      'scheduled_at': scheduledAt?.toUtc().toIso8601String(),
      'duration_minutes': max(15, durationMinutes),
      'location': location.trim().isEmpty ? null : location.trim(),
      'court_name': courtName.trim().isEmpty ? null : courtName.trim(),
      'notes': notes.trim().isEmpty ? null : notes.trim(),
      'event_id': scheduledAt == null ? null : eventId.isEmpty ? null : eventId,
      'status': scheduledAt == null ? 'pending' : 'scheduled',
      'result_details': nextDetails,
      'updated_by': user?.id,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', matchId);

    if (eventId.isNotEmpty && scheduledAt == null) {
      try { await cancelEvent(eventId); } catch (_) {}
      return;
    }

    if (eventId.isNotEmpty && scheduledAt != null) {
      try {
        final tournamentData = await tournament(text(current['tournament_id']));
        final names = teamNameMap(tournamentTeams(tournamentData));
        final updatedMatch = Map<String, dynamic>.from(current)
          ..['scheduled_at'] = scheduledAt.toUtc().toIso8601String()
          ..['duration_minutes'] = max(15, durationMinutes)
          ..['location'] = location.trim()
          ..['court_name'] = courtName.trim()
          ..['notes'] = notes.trim();
        final title = tournamentMatchAgendaTitle(text(tournamentData['name'], 'Torneo'), updatedMatch, names);
        await updateEvent(eventId, title, scheduledAt, location, tournamentMatchAgendaNotes(updatedMatch), 2);
      } catch (_) {}
    }
  }

  static Future<void> updateMatchStatus(String matchId, String status) async {
    final current = asMap(await sb.from('matches').select('id,event_id,status,score_a,score_b,result_details').eq('id', matchId).single());
    final nextDetails = Map<String, dynamic>.from(asMap(current['result_details']));
    nextDetails['history'] = matchHistoryWithEntry(current, 'Estado cambiado', matchStatusLabel(status));
    final payload = {
      'status': status,
      'result_details': nextDetails,
      'updated_by': user?.id,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    if (status == 'cancelled') {
      final eventId = text(current['event_id']);
      if (eventId.isNotEmpty) {
        try { await cancelEvent(eventId); } catch (_) {}
      }
      payload['event_id'] = null;
    }
    await sb.from('matches').update(payload).eq('id', matchId);
  }

  static Future<void> syncMatchAgendaEvent({
    required String groupId,
    required String tournamentName,
    required Map<String, dynamic> match,
    required Map<String, String> teamNames,
  }) async {
    final start = DateTime.tryParse(text(match['scheduled_at']))?.toLocal();
    if (start == null) return;
    final title = tournamentMatchAgendaTitle(tournamentName, match, teamNames);
    final eventId = text(match['event_id']);
    if (eventId.isEmpty) {
      final created = await createEvent(groupId, title, start, text(match['location']), tournamentMatchAgendaNotes(match), 2);
      await sb.from('matches').update({'event_id': created, 'updated_at': DateTime.now().toUtc().toIso8601String()}).eq('id', match['id']);
    } else {
      await updateEvent(eventId, title, start, text(match['location']), tournamentMatchAgendaNotes(match), 2);
    }
  }

  static Future<void> openTournamentMatchEvent(BuildContext context, String eventId, Map<String, dynamic> group) async {
    final event = await eventById(eventId);
    if (!context.mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => EventDetailScreen(event: event, group: group)));
  }

  static Future<void> bulkScheduleTournamentMatches({
    required String groupId,
    required String tournamentName,
    required List<Map<String, dynamic>> matches,
    required List<Map<String, dynamic>> teams,
    required DateTime firstStart,
    required int durationMinutes,
    required int intervalMinutes,
    required int courtsCount,
    required String location,
    required String courtName,
    required bool syncAgenda,
  }) async {
    if (matches.isEmpty) throw Exception('No hay partidos para reprogramar.');
    final names = teamNameMap(teams);
    final ordered = [...matches]..sort((a, b) {
      final round = intValue(a['round']).compareTo(intValue(b['round']));
      if (round != 0) return round;
      return intValue(a['order_index']).compareTo(intValue(b['order_index']));
    });
    final courts = max(1, courtsCount);
    final interval = max(15, intervalMinutes);
    for (var i = 0; i < ordered.length; i++) {
      final match = ordered[i];
      final wave = i ~/ courts;
      final start = firstStart.add(Duration(minutes: wave * interval));
      final court = courts <= 1
          ? courtName.trim()
          : (courtName.trim().isEmpty ? 'Pista ${(i % courts) + 1}' : '${courtName.trim()} ${(i % courts) + 1}');
      final updated = Map<String, dynamic>.from(match)
        ..['scheduled_at'] = start.toUtc().toIso8601String()
        ..['duration_minutes'] = max(15, durationMinutes)
        ..['location'] = location.trim()
        ..['court_name'] = court
        ..['status'] = 'scheduled';
      final nextDetails = Map<String, dynamic>.from(asMap(match['result_details']));
      nextDetails['history'] = matchHistoryWithEntry(match, 'Fecha actualizada en lote', '${DateFormat('d MMM yyyy · HH:mm', 'es_ES').format(start.toLocal())}${court.trim().isEmpty ? '' : ' · ${court.trim()}'}');
      await sb.from('matches').update({
        'scheduled_at': start.toUtc().toIso8601String(),
        'duration_minutes': max(15, durationMinutes),
        'location': location.trim().isEmpty ? null : location.trim(),
        'court_name': court.trim().isEmpty ? null : court.trim(),
        'status': 'scheduled',
        'result_details': nextDetails,
        'updated_by': user?.id,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', match['id']);
      if (syncAgenda) {
        await syncMatchAgendaEvent(groupId: groupId, tournamentName: tournamentName, match: updated, teamNames: names);
      }
    }
  }

  static Future<void> moveTournamentRound({
    required String groupId,
    required String tournamentName,
    required List<Map<String, dynamic>> matches,
    required List<Map<String, dynamic>> teams,
    required int round,
    required DateTime firstStart,
    required int durationMinutes,
    required int intervalMinutes,
    required int courtsCount,
    required String location,
    required String courtName,
    required bool syncAgenda,
  }) async {
    final selected = matches.where((m) => intValue(m['round'], 1) == round && text(m['status']) != 'played' && text(m['status']) != 'cancelled' && text(m['status']) != 'bye').toList();
    if (selected.isEmpty) throw Exception('No hay partidos movibles en esta jornada.');
    await bulkScheduleTournamentMatches(
      groupId: groupId,
      tournamentName: tournamentName,
      matches: selected,
      teams: teams,
      firstStart: firstStart,
      durationMinutes: durationMinutes,
      intervalMinutes: intervalMinutes,
      courtsCount: courtsCount,
      location: location,
      courtName: courtName,
      syncAgenda: syncAgenda,
    );
  }

  static Future<List<Map<String, dynamic>>> notifications() async {
    await ensureProfile();
    try {
      final res = await sb.from('notifications').select().order('created_at', ascending: false).limit(80);
      return asList(res);
    } catch (_) {
      return [];
    }
  }

  static Future<int> unreadNotificationCount() async {
    await ensureProfile();
    try {
      final res = await sb.from('notifications').select('id').filter('read_at', 'is', null);
      return asList(res).length;
    } catch (_) {
      return 0;
    }
  }

  static Future<void> markNotificationRead(String notificationId) async {
    await sb.from('notifications').update({'read_at': DateTime.now().toUtc().toIso8601String()}).eq('id', notificationId);
  }

  static Future<void> markAllNotificationsRead() async {
    await sb.from('notifications').update({'read_at': DateTime.now().toUtc().toIso8601String()}).filter('read_at', 'is', null);
  }

  static Future<Map<String, dynamic>> notificationSettings() async {
    await ensureProfile();
    final uid = user?.id;
    if (uid == null) return <String, dynamic>{};
    try {
      final res = await sb.from('user_settings').select().eq('user_id', uid).maybeSingle();
      return asMap(res);
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  static Future<void> updateNotificationSettings(Map<String, bool> values) async {
    await ensureProfile();
    final uid = user?.id;
    if (uid == null) return;
    await sb.from('user_settings').upsert({
      'user_id': uid,
      ...values,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'user_id');
  }

  static Future<void> registerDeviceToken(String token, String platform) async {
    final uid = user?.id;
    if (uid == null || token.trim().isEmpty) return;
    await ensureProfile();
    await sb.from('user_devices').upsert({
      'user_id': uid,
      'fcm_token': token.trim(),
      'platform': platform,
      'device_label': kIsWeb ? 'Web' : platform,
      'app_version': AppConfig.appVersion,
      'enabled': true,
      'last_seen_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'fcm_token');
    await updateNotificationSettings({'push_enabled': true});
  }


  static Future<void> createTestNotification() async {
    await ensureProfile();
    await sb.rpc('create_test_notification');
  }

  static Future<void> disableCurrentDeviceToken(String token) async {
    final uid = user?.id;
    if (uid == null || token.trim().isEmpty) return;
    try {
      await sb.from('user_devices').update({
        'enabled': false,
        'disabled_at': DateTime.now().toUtc().toIso8601String(),
        'last_seen_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('user_id', uid).eq('fcm_token', token.trim());
    } catch (_) {}
  }


  static Future<void> ensureAdminClaim() async {
    await ensureProfile();
    try {
      await sb.rpc('ensure_owner_admin');
    } catch (_) {
      // El panel admin queda oculto si el SQL de v15.21 aún no está ejecutado.
    }
  }

  static Future<String> currentAppAdminRole() async {
    await ensureAdminClaim();
    try {
      final res = await sb.rpc('app_admin_role');
      final role = res?.toString() ?? '';
      return ['owner', 'support', 'viewer'].contains(role) ? role : '';
    } catch (_) {
      try {
        final legacy = await sb.rpc('is_app_admin');
        return legacy == true ? 'owner' : '';
      } catch (_) {
        return '';
      }
    }
  }

  static Future<bool> isSuperAdmin() async {
    final role = await currentAppAdminRole();
    return role.isNotEmpty;
  }

  static Future<String> createSupportTicket({
    String? groupId,
    required String type,
    required String title,
    required String description,
    String priority = 'normal',
    String screen = 'app',
  }) async {
    final uid = user?.id;
    if (uid == null) throw Exception('Inicia sesión para enviar el reporte.');
    await ensureProfile();
    final cleanTitle = title.trim();
    final cleanDescription = description.trim();
    if (cleanTitle.length < 3 || cleanDescription.length < 8) {
      throw Exception('Describe el problema con un poco más de detalle.');
    }
    final row = await sb.from('support_tickets').insert({
      'user_id': uid,
      'group_id': groupId,
      'type': type,
      'title': cleanTitle,
      'description': cleanDescription,
      'priority': priority,
      'screen': screen,
      'app_version': AppConfig.appVersion,
      'device_info': kIsWeb ? 'web' : defaultTargetPlatform.name,
      'status': 'open',
    }).select('id').single();
    await logQualityEvent('support_ticket_created', screen: screen, groupId: groupId, message: cleanTitle);
    return row['id'].toString();
  }

  static Future<List<Map<String, dynamic>>> mySupportTickets() async {
    final uid = user?.id;
    if (uid == null) return [];
    try {
      final res = await sb
          .from('support_tickets')
          .select('*, groups(id,name)')
          .eq('user_id', uid)
          .order('created_at', ascending: false)
          .limit(20);
      return asList(res);
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> adminOverview() async {
    await ensureAdminClaim();
    try {
      return asMap(await sb.rpc('admin_overview'));
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  static Future<List<Map<String, dynamic>>> adminSupportTickets({String status = 'open'}) async {
    await ensureAdminClaim();
    try {
      dynamic query = sb
          .from('support_tickets')
          .select('*, profiles(id,email,full_name,avatar_url), groups(id,name)');
      if (status != 'all') query = query.eq('status', status);
      final res = await query.order('created_at', ascending: false).limit(80);
      return asList(res);
    } catch (_) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> adminQualityEvents() async {
    await ensureAdminClaim();
    try {
      final res = await sb
          .from('app_quality_events')
          .select('*, profiles(id,email,full_name,avatar_url), groups(id,name)')
          .order('created_at', ascending: false)
          .limit(40);
      return asList(res);
    } catch (_) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> adminUsersOverview() async {
    await ensureAdminClaim();
    try {
      final res = await sb.rpc('admin_users_overview');
      return asList(res);
    } catch (_) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> adminGroupsOverview() async {
    await ensureAdminClaim();
    try {
      final res = await sb.rpc('admin_groups_overview');
      return asList(res);
    } catch (_) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> adminDevicesOverview() async {
    await ensureAdminClaim();
    try {
      final res = await sb.rpc('admin_devices_overview');
      return asList(res);
    } catch (_) {
      return [];
    }
  }

  static Future<void> adminSetUserStatus(String email, String status, {String note = ''}) async {
    await ensureAdminClaim();
    await sb.rpc('admin_set_user_status_by_email', params: {
      'target_email': email.trim().toLowerCase(),
      'new_status': status,
      'note': note.trim(),
    });
  }

  static Future<void> updateSupportTicketStatus(String ticketId, String status, {String? note}) async {
    await ensureAdminClaim();
    final payload = <String, dynamic>{
      'status': status,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
      if (status == 'resolved' || status == 'closed') 'resolved_at': DateTime.now().toUtc().toIso8601String(),
      if (note != null) 'admin_note': note.trim().isEmpty ? null : note.trim(),
    };
    await sb.from('support_tickets').update(payload).eq('id', ticketId);
  }

  static Future<void> logQualityEvent(String type, {String? groupId, String screen = 'app', String message = '', Map<String, dynamic>? metadata}) async {
    final uid = user?.id;
    if (uid == null) return;
    try {
      await sb.from('app_quality_events').insert({
        'user_id': uid,
        'group_id': groupId,
        'event_type': type,
        'screen': screen,
        'message': message,
        'app_version': AppConfig.appVersion,
        'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
        'metadata': metadata ?? <String, dynamic>{},
      });
    } catch (_) {
      // Nunca bloquear al usuario por telemetría interna.
    }
  }
}

class PushNotificationService {
  static bool _initializing = false;
  static bool _configured = false;
  static bool _listenersReady = false;

  static FirebaseOptions get firebaseOptions => const FirebaseOptions(
    apiKey: AppConfig.firebaseApiKey,
    appId: AppConfig.firebaseAppId,
    messagingSenderId: AppConfig.firebaseMessagingSenderId,
    projectId: AppConfig.firebaseProjectId,
  );

  static String get platformLabel {
    if (kIsWeb) return 'web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      TargetPlatform.macOS => 'macos',
      TargetPlatform.windows => 'windows',
      TargetPlatform.linux => 'linux',
      _ => 'unknown',
    };
  }

  static Future<bool> configureIfPossible() async {
    if (_configured) return true;
    if (_initializing) return false;
    if (kIsWeb && !AppConfig.firebaseConfigured) return false;
    _initializing = true;
    try {
      if (Firebase.apps.isEmpty) {
        if (AppConfig.firebaseConfigured) {
          await Firebase.initializeApp(options: firebaseOptions);
        } else {
          await Firebase.initializeApp();
        }
      }
      _configured = true;
      _wireListenersOnce();
      return true;
    } catch (_) {
      _configured = false;
      return false;
    } finally {
      _initializing = false;
    }
  }

  static void _wireListenersOnce() {
    if (_listenersReady) return;
    _listenersReady = true;

    FirebaseMessaging.onMessage.listen((message) async {
      // En foreground no duplicamos banners: la campana de Avisos lee las filas de Supabase.
      // Android/iOS mostrarán la notificación automáticamente cuando llegue en background/killed.
      await AppData.logQualityEvent(
        'push_foreground_received',
        screen: 'push',
        message: message.notification?.title ?? AppData.text(message.data['title'], 'Push recibido'),
        metadata: message.data,
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen(handleMessageTap);
    FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      await AppData.registerDeviceToken(token, platformLabel);
      await AppData.logQualityEvent('push_token_refresh', screen: 'push', message: 'Token actualizado');
    });

    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) handleMessageTap(message);
    });
  }

  static Future<void> handleMessageTap(RemoteMessage message) async {
    final notificationId = AppData.text(message.data['notification_id']);
    final groupId = AppData.text(message.data['group_id']);
    if (notificationId.isNotEmpty) {
      try {
        await AppData.markNotificationRead(notificationId);
      } catch (_) {}
    }
    final nav = appNavigatorKey.currentState;
    if (nav == null) return;
    if (groupId.isNotEmpty) {
      final tab = notificationGroupTabFromValues(
        AppData.text(message.data['route_type']),
        AppData.text(message.data['type']),
      );
      await nav.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => GroupShell(groupId: groupId, initialTab: tab)),
        (route) => route.isFirst,
      );
    } else {
      await nav.push(MaterialPageRoute(builder: (_) => NotificationsScreen(onChanged: () {})));
    }
  }

  static Future<String?> enableForCurrentDevice() async {
    final ready = await configureIfPossible();
    if (!ready) return null;
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(alert: true, badge: true, sound: true);
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      await AppData.logQualityEvent('push_permission_denied', screen: 'push', message: 'Permiso denegado');
      return null;
    }
    final token = await messaging.getToken(vapidKey: kIsWeb && AppConfig.firebaseVapidKey.trim().isNotEmpty ? AppConfig.firebaseVapidKey.trim() : null);
    if (token != null && token.trim().isNotEmpty) {
      await AppData.registerDeviceToken(token, platformLabel);
      await AppData.logQualityEvent('push_token_registered', screen: 'push', message: 'Token registrado', metadata: {'platform': platformLabel});
    }
    return token;
  }

  static Future<void> tryRegisterSilently() async {
    try {
      final ready = await configureIfPossible();
      if (!ready) return;
      final settings = await FirebaseMessaging.instance.getNotificationSettings();
      if (settings.authorizationStatus == AuthorizationStatus.denied || settings.authorizationStatus == AuthorizationStatus.notDetermined) return;
      final token = await FirebaseMessaging.instance.getToken(vapidKey: kIsWeb && AppConfig.firebaseVapidKey.trim().isNotEmpty ? AppConfig.firebaseVapidKey.trim() : null);
      if (token != null && token.trim().isNotEmpty) {
        await AppData.registerDeviceToken(token, platformLabel);
      }
    } catch (_) {
      // No bloquear la app si Firebase todavía no está configurado.
    }
  }

  static Future<void> disableForCurrentDevice() async {
    try {
      final ready = await configureIfPossible();
      if (!ready) return;
      final token = await FirebaseMessaging.instance.getToken(vapidKey: kIsWeb && AppConfig.firebaseVapidKey.trim().isNotEmpty ? AppConfig.firebaseVapidKey.trim() : null);
      if (token != null && token.trim().isNotEmpty) {
        await AppData.disableCurrentDeviceToken(token);
      }
    } catch (_) {}
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


String newLocalUuid() {
  final random = Random.secure();
  String hex(int length) => List.generate(length, (_) => random.nextInt(16).toRadixString(16)).join();
  return '${hex(8)}-${hex(4)}-4${hex(3)}-${(8 + random.nextInt(4)).toRadixString(16)}${hex(3)}-${hex(12)}';
}

String eventKind(Map<String, dynamic> event) {
  final explicit = AppData.text(event['kind']).toLowerCase();
  final title = AppData.text(event['title']).toLowerCase();
  final notes = AppData.text(event['notes']).toLowerCase();
  final joined = '$explicit $title $notes';

  // Importante: los partidos creados desde Torneos/Ligas deben verse como evento especial,
  // no como una quedada normal ni como un partido genérico de fútbol/pádel.
  if (
    joined.contains('partido de torneo') ||
    joined.contains('partido de liga') ||
    joined.contains('torneo') ||
    joined.contains('liga') ||
    joined.contains('copa') ||
    joined.contains('americano') ||
    joined.contains('eliminatoria')
  ) {
    return 'torneo';
  }

  if (joined.contains('partido') || joined.contains('fútbol') || joined.contains('futbol') || joined.contains('pádel') || joined.contains('padel') || joined.contains('tenis')) return 'partido';
  if (joined.contains('entrenamiento') || joined.contains('entreno') || joined.contains('gym')) return 'entrenamiento';
  if (joined.contains('cena') || joined.contains('comida') || joined.contains('bar') || joined.contains('restaurante')) return 'cena';
  if (joined.contains('reunión') || joined.contains('reunion') || joined.contains('meeting')) return 'reunion';
  return 'quedada';
}

bool eventIsTournamentEvent(Map<String, dynamic> event) => eventKind(event) == 'torneo';

Color agendaDayAccentColor(List<Map<String, dynamic>> events) {
  // Para días con torneos usamos teal como color estructural. El dorado queda solo
  // para puntos, chips e iconos pequeños, evitando una Agenda demasiado amarilla.
  if (events.any(eventIsTournamentEvent)) return AppColors.teal;
  return events.isNotEmpty ? eventKindColor(events.first) : AppColors.teal;
}

Color agendaDaySoftColor(List<Map<String, dynamic>> events) {
  if (events.any(eventIsTournamentEvent)) return AppColors.surface;
  return events.isNotEmpty ? eventKindSoftColor(events.first) : AppColors.tealSoft;
}

List<Map<String, dynamic>> eventsOnSameDay(List<Map<String, dynamic>> events, Map<String, dynamic>? anchor) {
  if (anchor == null) return const <Map<String, dynamic>>[];
  final anchorDate = DateTime.tryParse(AppData.text(anchor['starts_at']))?.toLocal();
  if (anchorDate == null) return [anchor];
  final result = events.where((event) {
    final date = DateTime.tryParse(AppData.text(event['starts_at']))?.toLocal();
    return date != null && sameDay(date, anchorDate);
  }).toList();
  result.sort((a, b) {
    final da = DateTime.tryParse(AppData.text(a['starts_at'])) ?? DateTime.fromMillisecondsSinceEpoch(0);
    final db = DateTime.tryParse(AppData.text(b['starts_at'])) ?? DateTime.fromMillisecondsSinceEpoch(0);
    return da.compareTo(db);
  });
  return result;
}

bool eventIsRoutine(Map<String, dynamic> event) {
  if (AppData.text(event['event_series_id']).isNotEmpty) return true;
  final notes = AppData.text(event['notes']).toLowerCase();
  final title = AppData.text(event['title']).toLowerCase();
  return notes.contains('rutina:') || title.contains('semanal') || title.contains('mensual');
}

String eventRoutineBadge(Map<String, dynamic> event) {
  final frequency = AppData.text(event['recurrence_frequency']);
  if (frequency == 'weekly') return 'Cada semana';
  if (frequency == 'biweekly') return 'Cada 2 semanas';
  if (frequency == 'monthly') return 'Cada mes';
  final notes = AppData.text(event['notes']);
  final match = RegExp(r'Rutina:\s*([^·\\n]+)', caseSensitive: false).firstMatch(notes);
  if (match != null) return _cap(match.group(1)?.trim() ?? 'rutina');
  return 'Rutina';
}

String eventKindLabel(Map<String, dynamic> event) {
  switch (eventKind(event)) {
    case 'partido': return 'Partido';
    case 'entrenamiento': return 'Entrenamiento';
    case 'cena': return 'Cena';
    case 'reunion': return 'Reunión';
    case 'torneo': return 'Torneo';
    default: return 'Quedada';
  }
}

IconData eventKindIcon(Map<String, dynamic> event) {
  switch (eventKind(event)) {
    case 'partido': return Icons.sports_soccer_rounded;
    case 'entrenamiento': return Icons.fitness_center_rounded;
    case 'cena': return Icons.restaurant_rounded;
    case 'reunion': return Icons.forum_rounded;
    case 'torneo': return Icons.emoji_events_rounded;
    default: return Icons.groups_rounded;
  }
}

Color eventKindColor(Map<String, dynamic> event) {
  switch (eventKind(event)) {
    case 'partido': return AppColors.blue;
    case 'entrenamiento': return AppColors.violet;
    case 'cena': return AppColors.orange;
    case 'reunion': return AppColors.green;
    case 'torneo': return AppColors.amber;
    default: return AppColors.teal;
  }
}

Color eventKindSoftColor(Map<String, dynamic> event) {
  switch (eventKind(event)) {
    case 'partido': return const Color(0xFFEAF0FF);
    case 'entrenamiento': return AppColors.violetSoft;
    case 'cena': return AppColors.orangeSoft;
    case 'reunion': return AppColors.greenSoft;
    case 'torneo': return AppColors.faint;
    default: return AppColors.tealSoft;
  }
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
String calendarDayKey(DateTime day) => '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

bool isPowerOfTwo(int value) => value > 0 && (value & (value - 1)) == 0;

int highestPowerOfTwoAtMost(int value) {
  var power = 1;
  while (power * 2 <= value) {
    power *= 2;
  }
  return power;
}

int nextPowerOfTwoAtLeast(int value) {
  var power = 1;
  while (power < max(1, value)) {
    power *= 2;
  }
  return power;
}

String eliminationRoundNameForRemaining(int remaining) {
  if (remaining <= 2) return 'Final';
  if (remaining <= 4) return 'Semifinal';
  if (remaining <= 8) return 'Cuartos';
  if (remaining <= 16) return 'Octavos';
  return 'Ronda de $remaining';
}

List<String> parseTournamentParticipantNames(String raw) {
  final seen = <String>{};
  final names = <String>[];
  for (final part in raw.split(RegExp(r'[\n;,]+'))) {
    final name = part.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (name.length < 2) continue;
    final key = name.toLowerCase();
    if (seen.add(key)) names.add(name);
  }
  return names;
}

int eventsInMonth(List<Map<String, dynamic>> events, DateTime month) {
  return events.where((e) {
    final d = DateTime.tryParse(e['starts_at']?.toString() ?? '')?.toLocal();
    return d != null && d.year == month.year && d.month == month.month;
  }).length;
}


String groupTypeValue(String value) {
  final clean = value.trim().toLowerCase();
  if (clean == 'deporte' || clean == 'amigos' || clean == 'viaje' || clean == 'cartas' || clean == 'otro') return clean;
  return 'otro';
}

String groupTypeLabel(String value) {
  switch (groupTypeValue(value)) {
    case 'deporte': return 'Deporte';
    case 'amigos': return 'Amigos';
    case 'viaje': return 'Viaje';
    case 'cartas': return 'Cartas';
    default: return 'Otro';
  }
}

IconData groupTypeIcon(String value) {
  switch (groupTypeValue(value)) {
    case 'deporte': return Icons.sports_tennis_rounded;
    case 'amigos': return Icons.groups_2_rounded;
    case 'viaje': return Icons.flight_takeoff_rounded;
    case 'cartas': return Icons.style_rounded;
    default: return Icons.auto_awesome_rounded;
  }
}

String groupTypeDefaultDescription(String value) {
  switch (groupTypeValue(value)) {
    case 'deporte': return 'Partidos, asistencia, gastos y torneos del grupo.';
    case 'amigos': return 'Planes, quedadas y gastos compartidos entre amigos.';
    case 'viaje': return 'Gastos, planes y organización del viaje.';
    case 'cartas': return 'Partidas, gastos y ligas para el grupo.';
    default: return 'Planes, gastos y torneos del grupo.';
  }
}

String randomInviteCodeLocal() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  final rnd = Random.secure();
  return List.generate(6, (_) => chars[rnd.nextInt(chars.length)]).join();
}

String memberDisplayName(Map<String, dynamic> member) {
  final profile = AppData.asMap(member['profiles']);
  final fullName = AppData.text(profile['full_name']);
  if (fullName.isNotEmpty) return fullName;
  final email = AppData.text(profile['email']);
  if (email.contains('@')) return email.split('@').first;
  return 'Miembro';
}

String memberAvatarUrl(Map<String, dynamic> member) {
  final profile = AppData.asMap(member['profiles']);
  return AppData.text(profile['avatar_url']);
}

Map<String, dynamic>? memberByUserId(List<Map<String, dynamic>> members, String userId) {
  for (final member in members) {
    if (member['user_id']?.toString() == userId) return member;
  }
  return null;
}

String financeMemberAvatarUrl(String userId, List<Map<String, dynamic>> members) {
  final member = memberByUserId(members, userId);
  if (member == null) return '';
  return memberAvatarUrl(member);
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



List<String> defaultTieBreakers(String scoringType) {
  if (scoringUsesSetMode(scoringType)) {
    return ['points', 'wins', 'set_difference', 'game_difference', 'games_for', 'manual'];
  }
  return ['points', 'wins', 'direct', 'difference', 'for', 'manual'];
}

Map<String, dynamic> tournamentFormatConfig(Map<String, dynamic> tournament) {
  final raw = tournament['format_config'];
  if (raw is Map) return Map<String, dynamic>.from(raw);
  return <String, dynamic>{};
}

Map<String, dynamic> tournamentScheduleConfig(Map<String, dynamic> tournament) {
  final raw = tournament['schedule_config'];
  if (raw is Map) return Map<String, dynamic>.from(raw);
  return <String, dynamic>{};
}

String tournamentStatusLabel(String status) {
  switch (status) {
    case 'draft': return 'Borrador';
    case 'scheduled': return 'Programado';
    case 'active': return 'En curso';
    case 'paused': return 'Pausado';
    case 'finished': return 'Finalizado';
    case 'cancelled': return 'Cancelado';
    default: return 'En curso';
  }
}

Color tournamentStatusColor(String status) {
  switch (status) {
    case 'finished': return AppColors.green;
    case 'paused': return AppColors.amber;
    case 'cancelled': return AppColors.red;
    case 'draft': return AppColors.muted;
    case 'scheduled': return AppColors.blue;
    default: return AppColors.green;
  }
}

String matchStatusLabel(String status) {
  switch (status) {
    case 'scheduled': return 'Programado';
    case 'played': return 'Jugado';
    case 'postponed': return 'Aplazado';
    case 'cancelled': return 'Cancelado';
    case 'no_show': return 'No presentado';
    case 'walkover': return 'Victoria admin.';
    case 'bye': return 'Descanso';
    default: return 'Pendiente';
  }
}

Color matchStatusColor(String status) {
  switch (status) {
    case 'played': return AppColors.green;
    case 'scheduled': return AppColors.blue;
    case 'postponed': return AppColors.amber;
    case 'cancelled': return AppColors.red;
    case 'no_show': return AppColors.red;
    case 'walkover': return AppColors.orange;
    case 'bye': return AppColors.violet;
    default: return AppColors.muted;
  }
}

String tournamentMatchDateText(Map<String, dynamic> match) {
  final raw = AppData.text(match['scheduled_at']);
  if (raw.isEmpty) return 'Sin fecha';
  final dt = DateTime.tryParse(raw)?.toLocal();
  if (dt == null) return 'Sin fecha';
  return DateFormat('EEE d MMM · HH:mm', 'es_ES').format(dt);
}

DateTime? tournamentScheduledAtForIndex(Map<String, dynamic>? cfg, int round, int orderInsideRound) {
  if (cfg == null || cfg['enabled'] != true) return null;
  final raw = AppData.text(cfg['first_start_at']);
  final first = DateTime.tryParse(raw)?.toLocal();
  if (first == null) return null;
  final daysBetweenRounds = max(0, AppData.intValue(cfg['days_between_rounds'], 7));
  final interval = max(15, AppData.intValue(cfg['interval_minutes'], 60));
  final courts = max(1, AppData.intValue(cfg['courts_count'], AppData.intValue(cfg['matches_per_round'], 1)));
  final wave = max(0, orderInsideRound) ~/ courts;
  return first.add(Duration(days: max(0, round - 1) * daysBetweenRounds, minutes: wave * interval));
}

String tournamentCourtNameForIndex(Map<String, dynamic>? cfg, int orderInsideRound) {
  if (cfg == null) return '';
  final base = AppData.text(cfg['court_name']).trim();
  final courts = max(1, AppData.intValue(cfg['courts_count'], AppData.intValue(cfg['matches_per_round'], 1)));
  if (courts <= 1) return base;
  final number = (max(0, orderInsideRound) % courts) + 1;
  if (base.isEmpty) return 'Pista $number';
  if (RegExp(r'\d+$').hasMatch(base)) return base;
  return '$base $number';
}

String tournamentMatchAgendaNotes(Map<String, dynamic> match) {
  final roundName = AppData.text(match['round_name'], 'Jornada ${AppData.intValue(match['round'], 1)}');
  final courtLine = AppData.text(match['court_name']).isEmpty ? '' : '\nPista/Mesa: ${AppData.text(match['court_name'])}';
  final notes = AppData.text(match['notes']);
  final notesLine = notes.isEmpty ? '' : '\n\n$notes';
  return 'Partido de torneo · $roundName$courtLine$notesLine';
}

String tournamentMatchAgendaTitle(String tournamentName, Map<String, dynamic> match, Map<String, String> names) {
  final a = tournamentMatchSideName(match, names, true);
  final b = tournamentMatchSideName(match, names, false);
  return '$tournamentName: $a vs $b';
}

String eliminationRoundName(int round, int size) {
  if (size <= 2) return 'Final';
  if (size <= 4) return round <= 1 ? 'Semifinal' : 'Final';
  if (size <= 8) {
    if (round <= 1) return 'Cuartos';
    if (round == 2) return 'Semifinal';
    return 'Final';
  }
  return 'Ronda $round';
}

List<List<(String, String)>> generateRoundRobinIds(List<String> ids) {
  if (ids.length < 2) return const <List<(String, String)>>[];
  final rotation = <String?>[...ids];
  if (rotation.length.isOdd) rotation.add(null);
  final n = rotation.length;
  final rounds = <List<(String, String)>>[];
  for (var round = 1; round < n; round++) {
    final pairs = <(String, String)>[];
    for (var i = 0; i < n ~/ 2; i++) {
      final a = rotation[i];
      final b = rotation[n - 1 - i];
      if (a == null || b == null) continue;
      final swap = round.isEven;
      pairs.add((swap ? b : a, swap ? a : b));
    }
    rounds.add(pairs);
    final fixed = rotation.first;
    final rest = rotation.sublist(1);
    rest.insert(0, rest.removeLast());
    rotation
      ..clear()
      ..add(fixed)
      ..addAll(rest);
  }
  return rounds;
}


class AmericanoGeneratedMatch {
  final int round;
  final int courtIndex;
  final List<String> sideA;
  final List<String> sideB;
  final List<String> resting;
  const AmericanoGeneratedMatch({
    required this.round,
    required this.courtIndex,
    required this.sideA,
    required this.sideB,
    required this.resting,
  });
}

int recommendedAmericanoRounds(int players, int courts) {
  if (players < 4) return 1;
  final activeCourts = max(1, min(courts, players ~/ 4));
  final allPartnerPairs = players * (players - 1) ~/ 2;
  final partnerPairsPerRound = activeCourts * 2;
  return max(1, min(40, (allPartnerPairs / max(1, partnerPairsPerRound)).ceil()));
}

String americanoRulesText(int players, int courts, int rounds) {
  final recommended = recommendedAmericanoRounds(players, courts);
  if (players < 4) return 'El americano necesita al menos 4 jugadores.';
  final roundText = rounds >= recommended
      ? 'Con $rounds rondas hay margen para rotar bien las parejas.'
      : 'Con $rounds rondas quizá no todos jueguen con todas las parejas; recomendado: $recommended.';
  return 'Ranking individual: cada jugador suma los puntos que consigue en cada partido, aunque juegue con parejas distintas. $roundText';
}

String americanoPairKey(String a, String b) {
  final pair = [a, b]..sort();
  return pair.join('|');
}

int americanoPairCount(Map<String, int> map, String a, String b) {
  return map[americanoPairKey(a, b)] ?? 0;
}

void americanoIncrementPair(Map<String, int> map, String a, String b) {
  final key = americanoPairKey(a, b);
  map[key] = (map[key] ?? 0) + 1;
}

List<List<String>> americanoSideSplits(List<String> group) {
  if (group.length < 4) return const [];
  final a = group[0];
  final b = group[1];
  final c = group[2];
  final d = group[3];
  return [
    [a, b, c, d],
    [a, c, b, d],
    [a, d, b, c],
  ];
}

List<AmericanoGeneratedMatch> generateAmericanoRoundsIds(List<String> ids, {required int rounds, required int courts}) {
  final clean = ids.where((id) => id.trim().isNotEmpty).toList();
  if (clean.length < 4) return const [];

  final maxCourts = max(1, min(courts, clean.length ~/ 4));
  final targetRounds = max(1, rounds);
  final partnerCounts = <String, int>{};
  final opponentCounts = <String, int>{};
  final restCounts = <String, int>{for (final id in clean) id: 0};
  final playedCounts = <String, int>{for (final id in clean) id: 0};
  final output = <AmericanoGeneratedMatch>[];

  for (var round = 1; round <= targetRounds; round++) {
    final rotated = [...clean];
    final shift = (round - 1) % rotated.length;
    final shifted = [...rotated.skip(shift), ...rotated.take(shift)];
    final orderRank = {for (var i = 0; i < shifted.length; i++) shifted[i]: i};

    shifted.sort((a, b) {
      final playedCompare = (playedCounts[a] ?? 0).compareTo(playedCounts[b] ?? 0);
      if (playedCompare != 0) return playedCompare;
      final restCompare = (restCounts[b] ?? 0).compareTo(restCounts[a] ?? 0);
      if (restCompare != 0) return restCompare;
      return (orderRank[a] ?? 0).compareTo(orderRank[b] ?? 0);
    });

    final activeSlots = maxCourts * 4;
    final active = shifted.take(activeSlots).toList();
    final resting = shifted.skip(activeSlots).toList();
    for (final id in resting) {
      restCounts[id] = (restCounts[id] ?? 0) + 1;
    }

    final remaining = [...active];
    var court = 0;
    while (remaining.length >= 4 && court < maxCourts) {
      List<String>? best;
      var bestScore = 1 << 30;

      for (var a = 0; a < remaining.length - 3; a++) {
        for (var b = a + 1; b < remaining.length - 2; b++) {
          for (var c = b + 1; c < remaining.length - 1; c++) {
            for (var d = c + 1; d < remaining.length; d++) {
              final group = [remaining[a], remaining[b], remaining[c], remaining[d]];
              for (final split in americanoSideSplits(group)) {
                final p1 = split[0];
                final p2 = split[1];
                final q1 = split[2];
                final q2 = split[3];

                final partnerPenalty = americanoPairCount(partnerCounts, p1, p2) + americanoPairCount(partnerCounts, q1, q2);
                final opponentPenalty =
                    americanoPairCount(opponentCounts, p1, q1) +
                    americanoPairCount(opponentCounts, p1, q2) +
                    americanoPairCount(opponentCounts, p2, q1) +
                    americanoPairCount(opponentCounts, p2, q2);

                final groupPlayed = group.fold<int>(0, (value, id) => value + (playedCounts[id] ?? 0));
                final groupRested = group.fold<int>(0, (value, id) => value + (restCounts[id] ?? 0));

                final score = (partnerPenalty * 10000) + (opponentPenalty * 80) + (groupPlayed * 12) - (groupRested * 6);

                if (score < bestScore) {
                  bestScore = score;
                  best = split;
                }
              }
            }
          }
        }
      }

      if (best == null) break;
      final sideA = [best[0], best[1]];
      final sideB = [best[2], best[3]];
      output.add(AmericanoGeneratedMatch(round: round, courtIndex: court, sideA: sideA, sideB: sideB, resting: resting));

      americanoIncrementPair(partnerCounts, sideA[0], sideA[1]);
      americanoIncrementPair(partnerCounts, sideB[0], sideB[1]);
      for (final a in sideA) {
        for (final b in sideB) {
          americanoIncrementPair(opponentCounts, a, b);
        }
      }
      for (final id in best) {
        playedCounts[id] = (playedCounts[id] ?? 0) + 1;
      }
      remaining.removeWhere((id) => best!.contains(id));
      court++;
    }
  }

  return output;
}

List<String> americanoSideIds(Map<String, dynamic> match, String key) {
  final details = matchResultDetails(match);
  final raw = details[key];
  if (raw is List) {
    return raw.map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty && e != 'null').toList();
  }
  final fallback = key == 'side_a_ids' ? AppData.text(match['team_a']) : AppData.text(match['team_b']);
  if (fallback.isEmpty || fallback == 'null') return const [];
  return [fallback];
}

List<String> americanoRestIds(Map<String, dynamic> match) {
  final details = matchResultDetails(match);
  final raw = details['rest_ids'];
  if (raw is List) return raw.map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty && e != 'null').toList();
  return const [];
}

bool isAmericanoMatch(Map<String, dynamic> match) {
  final details = matchResultDetails(match);
  return details['americano'] == true;
}

String tournamentMatchSideName(Map<String, dynamic> match, Map<String, String> names, bool sideA) {
  final ids = isAmericanoMatch(match)
      ? americanoSideIds(match, sideA ? 'side_a_ids' : 'side_b_ids')
      : [AppData.text(match[sideA ? 'team_a' : 'team_b'])];
  if (ids.isEmpty || ids.first == 'null') return sideA ? 'Pendiente' : 'Pase directo';
  return ids.map((id) => names[id] ?? 'Pendiente').join(' / ');
}

String americanoRestText(Map<String, dynamic> match, Map<String, String> names) {
  final rest = americanoRestIds(match);
  if (rest.isEmpty) return '';
  return rest.map((id) => names[id] ?? 'Participante').join(', ');
}

String tournamentFormatLabel(String format) {
  switch (format) {
    case 'eliminatoria':
      return 'Eliminatoria';
    case 'americano':
      return 'Americano';
    case 'manual':
      return 'Manual';
    default:
      return 'Liga';
  }
}

String tournamentFormatSubtitle(String format) {
  switch (format) {
    case 'eliminatoria':
      return 'Cuadro directo: quien gana avanza y quien pierde queda fuera.';
    case 'americano':
      return 'Rondas por pista con parejas rotativas, descansos y ranking individual.';
    case 'manual':
      return 'Emparejamientos decididos a mano, con máximo control.';
    default:
      return 'Todos contra todos con clasificación automática.';
  }
}

String scoringTypeLabel(String type) {
  switch (type) {
    case 'football':
      return 'Fútbol';
    case 'tennis_padel':
      return 'Tenis / Pádel';
    case 'basketball':
      return 'Baloncesto';
    case 'volleyball':
      return 'Voleibol';
    case 'ping_pong':
      return 'Ping pong';
    case 'cards_mus':
      return 'Mus / Cartas';
    case 'darts':
      return 'Dardos';
    case 'billiards':
      return 'Billar';
    case 'esports':
      return 'Videojuegos';
    case 'custom':
      return 'Personalizado';
    default:
      return 'General';
  }
}

String scoringTypeSubtitle(String type) {
  switch (type) {
    case 'football':
      return 'Victoria 3 puntos, empate 1. Desempate por diferencia de goles.';
    case 'tennis_padel':
      return 'Resultado por sets: registra cada set y calcula sets/juegos para desempatar.';
    case 'basketball':
      return 'Victoria 2 puntos. El marcador representa puntos anotados.';
    case 'volleyball':
      return 'Sets a 25 y quinto set corto. Ideal para mejor de 3 o 5.';
    case 'ping_pong':
      return 'Sets rápidos a 11. La app calcula sets y puntos.';
    case 'cards_mus':
      return 'Victoria 1 punto. Sirve para juegos, piedras, manos o rondas.';
    case 'darts':
      return 'Puntuación directa para partidas a 301/501 o rondas.';
    case 'billiards':
      return 'Partidas o bolas ganadas con marcador simple.';
    case 'esports':
      return 'Mapas, rondas o puntos. Flexible para videojuegos.';
    case 'custom':
      return 'Flexible: marcador directo o por sets/rondas, con puntos y unidades editables.';
    default:
      return 'Sistema simple: victoria 3, empate 1, derrota 0.';
  }
}

Map<String, dynamic> scoringConfigForType(String type) {
  switch (type) {
    case 'football':
      return {
        'win': 3,
        'draw': 1,
        'loss': 0,
        'unit': 'goles',
        'allowDraw': true,
        'result_mode': 'simple',
        'score_label': 'goles',
        'ranking_label': 'DG',
      };
    case 'tennis_padel':
      return {
        'win': 2,
        'draw': 0,
        'loss': 0,
        'unit': 'sets',
        'allowDraw': false,
        'result_mode': 'sets',
        'best_of': 3,
        'set_label': 'juegos',
        'ranking_label': 'DS',
      };
    case 'basketball':
      return {
        'win': 2,
        'draw': 0,
        'loss': 1,
        'unit': 'puntos',
        'allowDraw': false,
        'result_mode': 'simple',
        'score_label': 'puntos',
        'ranking_label': 'DP',
      };
    case 'volleyball':
      return {
        'win': 2,
        'draw': 0,
        'loss': 0,
        'unit': 'sets',
        'allowDraw': false,
        'result_mode': 'sets',
        'best_of': 5,
        'set_label': 'puntos',
        'target_score': 25,
        'ranking_label': 'DS',
      };
    case 'ping_pong':
      return {
        'win': 2,
        'draw': 0,
        'loss': 0,
        'unit': 'sets',
        'allowDraw': false,
        'result_mode': 'sets',
        'best_of': 5,
        'set_label': 'puntos',
        'target_score': 11,
        'ranking_label': 'DS',
      };
    case 'cards_mus':
      return {
        'win': 1,
        'draw': 0,
        'loss': 0,
        'unit': 'juegos',
        'allowDraw': false,
        'result_mode': 'simple',
        'score_label': 'juegos',
        'ranking_label': 'DIF',
      };
    case 'darts':
      return {
        'win': 2,
        'draw': 0,
        'loss': 0,
        'unit': 'puntos',
        'allowDraw': false,
        'result_mode': 'simple',
        'score_label': 'puntos',
        'target_score': 501,
        'ranking_label': 'DIF',
      };
    case 'billiards':
      return {
        'win': 1,
        'draw': 0,
        'loss': 0,
        'unit': 'partidas',
        'allowDraw': false,
        'result_mode': 'simple',
        'score_label': 'partidas',
        'ranking_label': 'DIF',
      };
    case 'esports':
      return {
        'win': 3,
        'draw': 1,
        'loss': 0,
        'unit': 'mapas',
        'allowDraw': true,
        'result_mode': 'simple',
        'score_label': 'mapas',
        'ranking_label': 'DIF',
      };
    case 'custom':
      return {
        'win': 3,
        'draw': 1,
        'loss': 0,
        'unit': 'puntos',
        'allowDraw': true,
        'result_mode': 'simple',
        'score_label': 'puntos',
        'ranking_label': 'DIF',
      };
    default:
      return {
        'win': 3,
        'draw': 1,
        'loss': 0,
        'unit': 'puntos',
        'allowDraw': true,
        'result_mode': 'simple',
        'score_label': 'puntos',
        'ranking_label': 'DIF',
      };
  }
}

Map<String, dynamic> resolvedScoringConfig(String type, [dynamic raw]) {
  final base = Map<String, dynamic>.from(scoringConfigForType(type));
  if (raw is Map) {
    for (final entry in raw.entries) {
      base[entry.key.toString()] = entry.value;
    }
  }
  return base;
}

int scoringWinPoints(String type, [dynamic raw]) => AppData.intValue(resolvedScoringConfig(type, raw)['win'], 3);
int scoringDrawPoints(String type, [dynamic raw]) => AppData.intValue(resolvedScoringConfig(type, raw)['draw'], 1);
int scoringLossPoints(String type, [dynamic raw]) => AppData.intValue(resolvedScoringConfig(type, raw)['loss'], 0);
String scoringMetricUnit(String type, [dynamic raw]) => AppData.text(resolvedScoringConfig(type, raw)['unit'], 'puntos');
bool scoringAllowDraw(String type, [dynamic raw]) => resolvedScoringConfig(type, raw)['allowDraw'] == true;
bool scoringUsesSetMode(String type, [dynamic raw]) => AppData.text(resolvedScoringConfig(type, raw)['result_mode'], 'simple') == 'sets';
int scoringBestOf(String type, [dynamic raw]) => max(1, AppData.intValue(resolvedScoringConfig(type, raw)['best_of'], 3));
String scoringScoreLabel(String type, [dynamic raw]) => AppData.text(resolvedScoringConfig(type, raw)['score_label'], scoringMetricUnit(type, raw));
String scoringSetLabel(String type, [dynamic raw]) => AppData.text(resolvedScoringConfig(type, raw)['set_label'], 'juegos');
String scoringRankingLabel(String type, [dynamic raw]) => AppData.text(resolvedScoringConfig(type, raw)['ranking_label'], 'DIF');

String scoringEmoji(String type) {
  switch (type) {
    case 'football': return '⚽';
    case 'tennis_padel': return '🎾';
    case 'basketball': return '🏀';
    case 'volleyball': return '🏐';
    case 'ping_pong': return '🏓';
    case 'cards_mus': return '🃏';
    case 'darts': return '🎯';
    case 'billiards': return '🎱';
    case 'esports': return '🎮';
    case 'custom': return '✨';
    default: return '⭐';
  }
}

String scoringValidationText(String type, [dynamic raw]) {
  final cfg = resolvedScoringConfig(type, raw);
  if (scoringUsesSetMode(type, cfg)) {
    final target = AppData.intValue(cfg['target_score']);
    return target > 0
        ? 'Validación: sets sin empate · objetivo orientativo $target · mejor de ${scoringBestOf(type, cfg)}.'
        : 'Validación: sets sin empate · mejor de ${scoringBestOf(type, cfg)}.';
  }
  if (!scoringAllowDraw(type, cfg)) {
    return 'Validación: el marcador no puede quedar empatado.';
  }
  return 'Validación: permite empate y calcula puntos/diferencia automáticamente.';
}

class GrupliPremium {
  static const bool enabled = false;
  static const int freeActiveTournamentsPerGroup = 1;
  static const int freePlayersPerTournament = 16;
  static const int freeRoundsPerTournament = 8;
}

bool tournamentFeatureIsPremium(String feature) {
  return const {
    'advanced_stats',
    'groups_playoff',
    'double_elimination',
    'swiss',
    'exports',
    'public_page',
    'smart_reminders',
    'saved_templates',
    'advanced_americano',
    'result_confirmation',
  }.contains(feature);
}

String scoringConfigShortText(String type, [dynamic raw]) {
  final cfg = resolvedScoringConfig(type, raw);
  if (scoringUsesSetMode(type, cfg)) {
    return 'Resultado por sets/rondas · mejor de ${scoringBestOf(type, cfg)}';
  }
  return 'Victoria ${scoringWinPoints(type, cfg)} · empate ${scoringDrawPoints(type, cfg)} · derrota ${scoringLossPoints(type, cfg)}';
}


String tieBreakerLabel(String value) {
  switch (value) {
    case 'points': return 'puntos';
    case 'wins': return 'victorias';
    case 'direct': return 'directo';
    case 'difference': return 'diferencia';
    case 'for': return 'a favor';
    case 'set_difference': return 'sets';
    case 'game_difference': return 'juegos';
    case 'games_for': return 'juegos a favor';
    case 'manual': return 'manual';
    default: return value;
  }
}

String scoringConfigFullText(String type, [dynamic raw]) {
  final cfg = resolvedScoringConfig(type, raw);
  if (scoringUsesSetMode(type, cfg)) {
    return 'Se registra cada set/ronda (${scoringSetLabel(type, cfg)} por parcial) y la app calcula ganador, parciales y desempates.';
  }
  return 'Marcador directo en ${scoringScoreLabel(type, cfg)}. La clasificación usa victoria ${scoringWinPoints(type, cfg)}, empate ${scoringDrawPoints(type, cfg)} y derrota ${scoringLossPoints(type, cfg)}.';
}

String standingsHeaderForScoring(String type, [dynamic raw]) {
  if (scoringUsesSetMode(type, raw)) return 'PTS · DP · ${scoringSetLabel(type, raw).toUpperCase()}';
  return 'PTS · ${scoringRankingLabel(type, raw)} · PJ';
}

String standingDetailText(TeamStanding standing, String scoringType, [dynamic scoringConfig]) {
  if (scoringUsesSetMode(scoringType, scoringConfig)) {
    return '${standing.wins}G · ${standing.losses}P · parciales ${standing.goalsFor}-${standing.goalsAgainst} · ${scoringSetLabel(scoringType, scoringConfig)} ${standing.secondaryFor}-${standing.secondaryAgainst}';
  }
  return '${standing.wins}G · ${standing.draws}E · ${standing.losses}P · ${scoringMetricUnit(scoringType, scoringConfig)} ${standing.goalsFor}-${standing.goalsAgainst}';
}

String standingMetricText(TeamStanding standing, String scoringType, [dynamic scoringConfig]) {
  if (scoringUsesSetMode(scoringType, scoringConfig)) {
    return 'DP ${standing.goalDifference} · DIF ${standing.secondaryDifference}';
  }
  return 'PTS · ${scoringRankingLabel(scoringType, scoringConfig)} ${standing.goalDifference}';
}

String matchInputLabel(String type, bool local, [dynamic raw]) {
  final side = local ? 'Local' : 'Visitante';
  if (scoringUsesSetMode(type, raw)) {
    return '$side sets';
  }
  return '$side ${scoringScoreLabel(type, raw)}';
}

List<Map<String, int>> matchDetailSets(Map<String, dynamic> match) {
  final details = AppData.asMap(match['result_details']);
  final rawSets = details['sets'];
  if (rawSets is! List) return const [];
  return rawSets
      .whereType<Map>()
      .map((e) => {'a': AppData.intValue(e['a']), 'b': AppData.intValue(e['b'])})
      .toList();
}

String? matchDetailScoreText(Map<String, dynamic> match, String type, [dynamic raw]) {
  if (!scoringUsesSetMode(type, raw)) return null;
  final sets = matchDetailSets(match);
  if (sets.isEmpty) return null;
  return sets.map((set) => '${set['a']}-${set['b']}').join(' · ');
}

String tournamentMatchWinnerId(Map<String, dynamic> match) {
  final direct = AppData.text(match['winner_team_id']);
  if (direct.isNotEmpty) return direct;
  final status = AppData.text(match['status']);
  final aId = AppData.text(match['team_a']);
  final bId = AppData.text(match['team_b']);
  if (status == 'bye') return aId;
  if (aId.isEmpty || aId == 'null') return bId;
  if (bId.isEmpty || bId == 'null') return aId;
  final a = AppData.intValue(match['score_a']);
  final b = AppData.intValue(match['score_b']);
  if (a > b) return aId;
  if (b > a) return bId;
  return '';
}

String tournamentMatchLoserId(Map<String, dynamic> match) {
  final winner = tournamentMatchWinnerId(match);
  final aId = AppData.text(match['team_a']);
  final bId = AppData.text(match['team_b']);
  if (winner.isEmpty) return '';
  if (winner == aId) return bId == 'null' ? '' : bId;
  if (winner == bId) return aId == 'null' ? '' : aId;
  return '';
}

bool eliminationMatchClosed(Map<String, dynamic> match) {
  final status = AppData.text(match['status']);
  return status == 'played' || status == 'bye' || status == 'walkover' || status == 'no_show';
}

bool eliminationHasThirdPlace(List<Map<String, dynamic>> matches) {
  return matches.any((m) {
    final details = AppData.asMap(m['result_details']);
    return AppData.text(details['stage']) == 'third_place' || AppData.text(m['round_name']).toLowerCase().contains('tercer');
  });
}

bool canGenerateEliminationNextRound(List<Map<String, dynamic>> matches) {
  final normal = matches.where((m) => AppData.text(AppData.asMap(m['result_details'])['stage']) != 'third_place').toList();
  if (normal.isEmpty) return false;
  final latestRound = normal.fold<int>(0, (value, m) => max(value, AppData.intValue(m['round'])));
  final latest = normal.where((m) => AppData.intValue(m['round']) == latestRound).toList();
  if (latest.length <= 1) return false;
  return latest.every(eliminationMatchClosed);
}

bool canCreateEliminationThirdPlace(List<Map<String, dynamic>> matches) {
  if (eliminationHasThirdPlace(matches)) return false;
  final normal = matches.where((m) => AppData.text(AppData.asMap(m['result_details'])['stage']) != 'third_place').toList();
  final rounds = normal.map((m) => AppData.intValue(m['round'])).toSet().toList()..sort();
  for (final round in rounds.reversed) {
    final roundMatches = normal.where((m) => AppData.intValue(m['round']) == round).toList();
    if (roundMatches.length == 2) return roundMatches.every(eliminationMatchClosed);
  }
  return false;
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
  teams.sort((a, b) {
    final seedCompare = AppData.intValue(a['seed'], 999999).compareTo(AppData.intValue(b['seed'], 999999));
    if (seedCompare != 0) return seedCompare;
    return AppData.text(a['name']).toLowerCase().compareTo(AppData.text(b['name']).toLowerCase());
  });
  return teams;
}

List<Map<String, dynamic>> tournamentMatches(Map<String, dynamic> tournament) {
  final value = tournament['matches'];
  if (value is! List) return [];
  final matches = value.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  matches.sort((a, b) {
    final roundCompare = AppData.intValue(a['round']).compareTo(AppData.intValue(b['round']));
    if (roundCompare != 0) return roundCompare;
    final orderCompare = AppData.intValue(a['order_index']).compareTo(AppData.intValue(b['order_index']));
    if (orderCompare != 0) return orderCompare;
    final dateCompare = AppData.text(a['scheduled_at']).compareTo(AppData.text(b['scheduled_at']));
    if (dateCompare != 0) return dateCompare;
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


Map<String, dynamic> matchResultDetails(Map<String, dynamic> match) {
  final raw = match['result_details'];
  if (raw is Map) return Map<String, dynamic>.from(raw);
  return <String, dynamic>{};
}

List<Map<String, dynamic>> matchResultHistory(Map<String, dynamic> match) {
  final history = matchResultDetails(match)['history'];
  if (history is List) {
    return history.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
  }
  return <Map<String, dynamic>>[];
}

List<Map<String, dynamic>> matchHistoryWithEntry(Map<String, dynamic> current, String action, String note) {
  final history = matchResultHistory(current);
  history.add({
    'at': DateTime.now().toUtc().toIso8601String(),
    'by': AppData.user?.id,
    'action': action,
    'note': note,
    'previous_status': AppData.text(current['status']),
    'previous_score_a': current['score_a'],
    'previous_score_b': current['score_b'],
  });
  return history.take(30).toList();
}

bool matchCountsForStandings(Map<String, dynamic> match) {
  final status = AppData.text(match['status'], 'pending');
  if (status == 'played' || status == 'no_show' || status == 'walkover') return true;
  return AppData.text(match['winner_team_id']).isNotEmpty &&
      AppData.text(match['team_a']).isNotEmpty &&
      AppData.text(match['team_b']).isNotEmpty &&
      status != 'cancelled' &&
      status != 'postponed' &&
      status != 'bye';
}

String matchSpecialResultText(Map<String, dynamic> match, Map<String, String> names) {
  final details = matchResultDetails(match);
  final special = AppData.text(details['special_result']);
  if (special.isEmpty) return '';
  final winner = names[AppData.text(match['winner_team_id'])] ?? 'Ganador';
  final loser = names[AppData.text(details['loser_team_id'])] ?? names[AppData.text(details['no_show_team_id'])] ?? 'Rival';
  if (special == 'no_show') return '$loser no se presentó · gana $winner';
  if (special == 'walkover') return 'Victoria administrativa para $winner';
  return AppData.text(details['label'], special);
}

List<String> tournamentTieBreakers(Map<String, dynamic> tournament, String scoringType) {
  final raw = tournament['tie_breakers'];
  if (raw is List) {
    final values = raw.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList();
    if (values.isNotEmpty) return values;
  }
  return defaultTieBreakers(scoringType);
}

int _compareDesc(int a, int b) => b.compareTo(a);

int _directTieBreakerCompare(TeamStanding a, TeamStanding b, List<Map<String, dynamic>> matches, String scoringType, Map<String, dynamic>? scoringConfig) {
  var aPoints = 0;
  var bPoints = 0;
  var aDiff = 0;
  var bDiff = 0;
  var aFor = 0;
  var bFor = 0;
  for (final match in matches) {
    if (!matchCountsForStandings(match)) continue;
    final teamA = AppData.text(match['team_a']);
    final teamB = AppData.text(match['team_b']);
    final sameDuel = (teamA == a.id && teamB == b.id) || (teamA == b.id && teamB == a.id);
    if (!sameDuel) continue;
    final rawA = AppData.intValue(match['score_a']);
    final rawB = AppData.intValue(match['score_b']);
    final aScore = teamA == a.id ? rawA : rawB;
    final bScore = teamA == a.id ? rawB : rawA;
    aFor += aScore;
    bFor += bScore;
    aDiff += aScore - bScore;
    bDiff += bScore - aScore;
    if (aScore > bScore) {
      aPoints += scoringWinPoints(scoringType, scoringConfig);
      bPoints += scoringLossPoints(scoringType, scoringConfig);
    } else if (aScore < bScore) {
      bPoints += scoringWinPoints(scoringType, scoringConfig);
      aPoints += scoringLossPoints(scoringType, scoringConfig);
    } else {
      aPoints += scoringDrawPoints(scoringType, scoringConfig);
      bPoints += scoringDrawPoints(scoringType, scoringConfig);
    }
  }
  var c = _compareDesc(aPoints, bPoints);
  if (c != 0) return c;
  c = _compareDesc(aDiff, bDiff);
  if (c != 0) return c;
  return _compareDesc(aFor, bFor);
}

int compareTeamStandings(
  TeamStanding a,
  TeamStanding b,
  List<Map<String, dynamic>> matches,
  List<String> tieBreakers,
  String scoringType,
  Map<String, dynamic>? scoringConfig,
) {
  for (final breaker in tieBreakers) {
    int c = 0;
    switch (breaker) {
      case 'points':
        c = _compareDesc(a.points, b.points);
        break;
      case 'wins':
        c = _compareDesc(a.wins, b.wins);
        break;
      case 'direct':
        c = _directTieBreakerCompare(a, b, matches, scoringType, scoringConfig);
        break;
      case 'difference':
        c = _compareDesc(a.goalDifference, b.goalDifference);
        break;
      case 'for':
        c = _compareDesc(a.goalsFor, b.goalsFor);
        break;
      case 'set_difference':
      case 'game_difference':
        c = _compareDesc(a.secondaryDifference, b.secondaryDifference);
        break;
      case 'games_for':
        c = _compareDesc(a.secondaryFor, b.secondaryFor);
        break;
      case 'no_shows':
        c = a.noShows.compareTo(b.noShows);
        break;
    }
    if (c != 0) return c;
  }
  return a.name.compareTo(b.name);
}

String standingsOrderText(List<String> tieBreakers) {
  return tieBreakers.map(tieBreakerLabel).join(' → ');
}

String standingRankReason(int index, List<TeamStanding> standings, List<String> tieBreakers, String scoringType, Map<String, dynamic>? scoringConfig) {
  final current = standings[index];
  if (index == 0) {
    return 'Lidera con ${current.points} pts · ${current.wins} victorias · ${current.goalDifference >= 0 ? '+' : ''}${current.goalDifference} de diferencia.';
  }
  final previous = standings[index - 1];
  if (current.points != previous.points) {
    return '${previous.name} está por delante por puntos (${previous.points} vs ${current.points}).';
  }
  for (final breaker in tieBreakers) {
    if (breaker == 'points') continue;
    if (breaker == 'wins' && current.wins != previous.wins) return 'Desempate por victorias: ${previous.wins} vs ${current.wins}.';
    if ((breaker == 'difference') && current.goalDifference != previous.goalDifference) return 'Desempate por diferencia: ${previous.goalDifference} vs ${current.goalDifference}.';
    if (breaker == 'for' && current.goalsFor != previous.goalsFor) return 'Desempate por puntos a favor: ${previous.goalsFor} vs ${current.goalsFor}.';
    if ((breaker == 'set_difference' || breaker == 'game_difference') && current.secondaryDifference != previous.secondaryDifference) return 'Desempate por ${tieBreakerLabel(breaker)}: ${previous.secondaryDifference} vs ${current.secondaryDifference}.';
    if (breaker == 'games_for' && current.secondaryFor != previous.secondaryFor) return 'Desempate por juegos a favor: ${previous.secondaryFor} vs ${current.secondaryFor}.';
    if (breaker == 'direct') return 'Mismo puntaje: se revisa enfrentamiento directo antes de seguir con la diferencia.';
  }
  return 'Mismo puntaje. Se aplica el siguiente criterio configurado o el orden manual.';
}

String matchHistoryEntryText(Map<String, dynamic> item) {
  final action = AppData.text(item['action'], 'Cambio');
  final note = AppData.text(item['note']);
  final raw = AppData.text(item['at']);
  final dt = DateTime.tryParse(raw)?.toLocal();
  final date = dt == null ? '' : DateFormat('d MMM HH:mm', 'es_ES').format(dt);
  return [if (date.isNotEmpty) date, action, if (note.isNotEmpty) note].join(' · ');
}

List<TeamStanding> calculateStandings(
  List<Map<String, dynamic>> teams,
  List<Map<String, dynamic>> matches, {
  String scoringType = 'general',
  Map<String, dynamic>? scoringConfig,
  List<String> tieBreakers = const [],
}) {
  final table = <String, TeamStanding>{
    for (final team in teams)
      team['id'].toString(): TeamStanding(
        id: team['id'].toString(),
        name: AppData.text(team['name'], 'Participante'),
      ),
  };
  final setMode = scoringUsesSetMode(scoringType, scoringConfig);
  final breakers = tieBreakers.isEmpty ? defaultTieBreakers(scoringType) : tieBreakers;

  for (final match in matches) {
    if (!matchCountsForStandings(match)) continue;
    final aId = AppData.text(match['team_a']);
    final bId = AppData.text(match['team_b']);
    final scoreA = AppData.intValue(match['score_a']);
    final scoreB = AppData.intValue(match['score_b']);
    final details = matchResultDetails(match);
    final special = AppData.text(details['special_result']);

    if (isAmericanoMatch(match)) {
      final sideA = americanoSideIds(match, 'side_a_ids');
      final sideB = americanoSideIds(match, 'side_b_ids');
      final aRows = sideA.map((id) => table[id]).whereType<TeamStanding>().toList();
      final bRows = sideB.map((id) => table[id]).whereType<TeamStanding>().toList();
      if (aRows.isEmpty || bRows.isEmpty) continue;

      for (final row in aRows) {
        row.played++;
        row.goalsFor += scoreA;
        row.goalsAgainst += scoreB;
      }
      for (final row in bRows) {
        row.played++;
        row.goalsFor += scoreB;
        row.goalsAgainst += scoreA;
      }

      if (setMode) {
        for (final set in matchDetailSets(match)) {
          final setA = AppData.intValue(set['a']);
          final setB = AppData.intValue(set['b']);
          for (final row in aRows) {
            row.secondaryFor += setA;
            row.secondaryAgainst += setB;
          }
          for (final row in bRows) {
            row.secondaryFor += setB;
            row.secondaryAgainst += setA;
          }
        }
      }

      if (scoreA > scoreB) {
        for (final row in aRows) {
          row.wins++;
          row.points += scoreA;
        }
        for (final row in bRows) {
          row.losses++;
          row.points += scoreB;
        }
      } else if (scoreA < scoreB) {
        for (final row in bRows) {
          row.wins++;
          row.points += scoreB;
        }
        for (final row in aRows) {
          row.losses++;
          row.points += scoreA;
        }
      } else {
        for (final row in [...aRows, ...bRows]) {
          row.draws++;
          row.points += scoreA;
        }
      }
      continue;
    }

    final a = table[aId];
    final b = table[bId];
    if (a == null || b == null) continue;

    a.played++;
    b.played++;
    a.goalsFor += scoreA;
    a.goalsAgainst += scoreB;
    b.goalsFor += scoreB;
    b.goalsAgainst += scoreA;

    if (setMode) {
      for (final set in matchDetailSets(match)) {
        final setA = AppData.intValue(set['a']);
        final setB = AppData.intValue(set['b']);
        a.secondaryFor += setA;
        a.secondaryAgainst += setB;
        b.secondaryFor += setB;
        b.secondaryAgainst += setA;
      }
    }

    if (special == 'no_show') {
      final loserId = AppData.text(details['loser_team_id'], AppData.text(details['no_show_team_id']));
      if (loserId == aId) {
        a.noShows++;
      } else if (loserId == bId) {
        b.noShows++;
      }
    }
    if (special == 'walkover') {
      final winnerId = AppData.text(match['winner_team_id']);
      if (winnerId == aId) a.adminWins++;
      if (winnerId == bId) b.adminWins++;
    }

    if (scoreA > scoreB) {
      a.wins++;
      b.losses++;
      a.points += scoringWinPoints(scoringType, scoringConfig);
      b.points += scoringLossPoints(scoringType, scoringConfig);
    } else if (scoreA < scoreB) {
      b.wins++;
      a.losses++;
      b.points += scoringWinPoints(scoringType, scoringConfig);
      a.points += scoringLossPoints(scoringType, scoringConfig);
    } else {
      a.draws++;
      b.draws++;
      a.points += scoringDrawPoints(scoringType, scoringConfig);
      b.points += scoringDrawPoints(scoringType, scoringConfig);
    }
  }

  final rows = table.values.toList();
  rows.sort((a, b) => compareTeamStandings(a, b, matches, breakers, scoringType, scoringConfig));
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
  int secondaryFor = 0;
  int secondaryAgainst = 0;
  int points = 0;
  int noShows = 0;
  int adminWins = 0;

  TeamStanding({required this.id, required this.name});

  int get goalDifference => goalsFor - goalsAgainst;
  int get secondaryDifference => secondaryFor - secondaryAgainst;
}

Future<void> showToast(BuildContext context, String message, {bool danger = false}) async {
  if (!context.mounted) return;
  final cleanMessage = danger ? humanizeError(message) : message;
  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(cleanMessage),
      backgroundColor: danger ? AppColors.red : AppColors.teal,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}

Future<bool?> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirm = 'Aceptar',
  bool danger = false,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: danger ? AppColors.red : AppColors.teal),
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirm),
        ),
      ],
    ),
  );
}


class InviteLinks {
  static String normalizeCode(String value) {
    final clean = value.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    return clean.length > 24 ? clean.substring(0, 24) : clean;
  }

  static String joinUrl(String code) => '${AppConfig.appBaseUrl}/join/${normalizeCode(code)}';
  static String appSchemeUrl(String code) => 'grupli://join/${normalizeCode(code)}';

  static String? codeFromUri(Uri uri) {
    final segments = uri.pathSegments.where((s) => s.trim().isNotEmpty).toList();

    if (uri.scheme.toLowerCase() == 'grupli' && uri.host.toLowerCase() == 'join' && segments.isNotEmpty) {
      final code = normalizeCode(segments.first);
      return code.length >= 4 ? code : null;
    }

    if (segments.length >= 2 && segments.first.toLowerCase() == 'join') {
      final code = normalizeCode(segments[1]);
      return code.length >= 4 ? code : null;
    }

    for (final key in ['join', 'code', 'invite']) {
      final value = uri.queryParameters[key];
      if (value != null) {
        final code = normalizeCode(value);
        if (code.length >= 4) return code;
      }
    }
    return null;
  }

  static String? codeFromText(String value) {
    final raw = value.trim();
    if (raw.isEmpty) return null;

    final parsed = Uri.tryParse(raw);
    if (parsed != null && (parsed.hasScheme || raw.contains('/join/'))) {
      final fromUri = codeFromUri(parsed);
      if (fromUri != null) return fromUri;
    }

    final clean = normalizeCode(raw);
    return clean.length >= 4 ? clean : null;
  }

  static String? get currentCode => codeFromUri(Uri.base);
}

class PendingInviteStore {
  static const _key = 'grupli_pending_invite_code';

  static Future<void> save(String? code) async {
    final clean = code == null ? null : InviteLinks.normalizeCode(code);
    if (clean == null || clean.length < 4) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, clean);
  }

  static Future<String?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    final clean = raw == null ? null : InviteLinks.normalizeCode(raw);
    return clean != null && clean.length >= 4 ? clean : null;
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}


class OnboardingStore {
  static const seenKey = 'grupli_onboarding_seen_v1';

  static Future<void> markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(seenKey, true);
  }

  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(seenKey);
  }
}

class OnboardingScreen extends StatefulWidget {
  final Future<void> Function() onFinish;
  const OnboardingScreen({super.key, required this.onFinish});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final controller = PageController();
  int index = 0;

  static const slides = [
    _OnboardingSlideData(
      icon: Icons.groups_rounded,
      title: 'Tu grupo,\nsiempre ordenado',
      body: 'Crea espacios privados para coordinar planes, asistencia, gastos y competiciones sin perder información en chats.',
      accent: AppColors.teal,
      soft: AppColors.tealSoft,
    ),
    _OnboardingSlideData(
      icon: Icons.event_available_rounded,
      title: 'Planes claros\ny asistencia rápida',
      body: 'Cada evento muestra fecha, ubicación, quién va, quién duda y si falta gente. Confirmar solo lleva un toque.',
      accent: AppColors.violet,
      soft: AppColors.violetSoft,
    ),
    _OnboardingSlideData(
      icon: Icons.emoji_events_rounded,
      title: 'Gastos, ligas\ny torneos',
      body: 'Registra gastos, liquida pagos pendientes y organiza ligas o torneos con calendario, resultados y clasificación.',
      accent: AppColors.orange,
      soft: AppColors.orangeSoft,
    ),
  ];

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> next() async {
    if (index >= slides.length - 1) {
      await widget.onFinish();
      return;
    }
    await controller.nextPage(duration: const Duration(milliseconds: 260), curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    final last = index == slides.length - 1;
    return DirectPage(
      scroll: false,
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: AppColors.tealDark, borderRadius: BorderRadius.circular(15)),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 10),
          const Expanded(child: Text('Grupli', style: TextStyle(fontSize: 24, color: AppColors.ink, fontWeight: FontWeight.w900, letterSpacing: -.7))),
          TextButton(onPressed: () => widget.onFinish(), child: const Text('Saltar', style: TextStyle(fontWeight: FontWeight.w900))),
        ]),
        const SizedBox(height: 18),
        Expanded(
          child: PageView.builder(
            controller: controller,
            itemCount: slides.length,
            onPageChanged: (value) => setState(() => index = value),
            itemBuilder: (context, i) => OnboardingSlide(data: slides[i], index: i),
          ),
        ),
        const SizedBox(height: 16),
        Row(children: [
          ...List.generate(slides.length, (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: i == index ? 28 : 8,
                height: 8,
                margin: const EdgeInsets.only(right: 7),
                decoration: BoxDecoration(
                  color: i == index ? AppColors.tealDark : AppColors.line,
                  borderRadius: BorderRadius.circular(99),
                ),
              )),
          const Spacer(),
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: next,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.tealDark,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              icon: Icon(last ? Icons.check_rounded : Icons.arrow_forward_rounded),
              label: Text(last ? 'Empezar' : 'Siguiente', style: const TextStyle(fontWeight: FontWeight.w900)),
            ),
          ),
        ]),
      ]),
    );
  }
}

class _OnboardingSlideData {
  final IconData icon;
  final String title;
  final String body;
  final Color accent;
  final Color soft;
  const _OnboardingSlideData({required this.icon, required this.title, required this.body, required this.accent, required this.soft});
}


class OnboardingSlide extends StatefulWidget {
  final _OnboardingSlideData data;
  final int index;
  const OnboardingSlide({super.key, required this.data, required this.index});

  @override
  State<OnboardingSlide> createState() => _OnboardingSlideState();
}

class _OnboardingSlideState extends State<OnboardingSlide> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 5200))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => _IntroSceneFrame(
            index: widget.index,
            data: widget.data,
            progress: _controller.value,
          ),
        ),
      ),
      const SizedBox(height: 28),
      TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) => Opacity(
          opacity: value,
          child: Transform.translate(offset: Offset(0, 16 * (1 - value)), child: child),
        ),
        child: Text(widget.data.title, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: AppColors.ink, height: 1.02, letterSpacing: -1.1)),
      ),
      const SizedBox(height: 12),
      TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 620),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) => Opacity(
          opacity: value,
          child: Transform.translate(offset: Offset(0, 18 * (1 - value)), child: child),
        ),
        child: Text(widget.data.body, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.muted, height: 1.42)),
      ),
      const SizedBox(height: 4),
    ]);
  }
}

class _IntroSceneFrame extends StatelessWidget {
  final int index;
  final _OnboardingSlideData data;
  final double progress;
  const _IntroSceneFrame({required this.index, required this.data, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: LinearGradient(
          colors: index == 0
              ? const [Color(0xFF073A57), Color(0xFF0B6B8F)]
              : index == 1
                  ? const [Color(0xFF123D72), Color(0xFF0C8A8A)]
                  : const [Color(0xFF063346), Color(0xFF0F766E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [BoxShadow(color: Color(0x22073A57), blurRadius: 28, offset: Offset(0, 16))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(27),
        child: Stack(children: [
          Positioned.fill(child: _IntroAnimatedBackground(progress: progress, index: index)),
          if (index == 0)
            _GroupPrivateScene(progress: progress)
          else if (index == 1)
            _AgendaScene(progress: progress)
          else
            _FinanceTournamentScene(progress: progress),
        ]),
      ),
    );
  }
}

class _IntroAnimatedBackground extends StatelessWidget {
  final double progress;
  final int index;
  const _IntroAnimatedBackground({required this.progress, required this.index});

  @override
  Widget build(BuildContext context) {
    final icons = <IconData>[
      Icons.calendar_month_rounded,
      Icons.payments_rounded,
      Icons.emoji_events_rounded,
      Icons.check_circle_rounded,
      Icons.lock_rounded,
      Icons.people_alt_rounded,
    ];
    return Stack(children: [
      Positioned(
        right: -34 + sin(progress * pi * 2) * 10,
        top: -24 + cos(progress * pi * 2) * 8,
        child: _GlowCircle(size: 138, color: Colors.white.withOpacity(.12)),
      ),
      Positioned(
        left: -42 + cos(progress * pi * 2) * 8,
        bottom: -34 + sin(progress * pi * 2) * 10,
        child: _GlowCircle(size: 122, color: Colors.white.withOpacity(.10)),
      ),
      Positioned.fill(
        child: Wrap(
          spacing: 23,
          runSpacing: 22,
          children: List.generate(48, (i) {
            final wave = sin((progress * pi * 2) + i * .55);
            return Transform.translate(
              offset: Offset(0, wave * 2.2),
              child: Icon(icons[(i + index) % icons.length], color: Colors.white.withOpacity(.055 + (wave + 1) * .012), size: 18),
            );
          }),
        ),
      ),
    ]);
  }
}

class _GlowCircle extends StatelessWidget {
  final double size;
  final Color color;
  const _GlowCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

class _GroupPrivateScene extends StatelessWidget {
  final double progress;
  const _GroupPrivateScene({required this.progress});

  double _pop(double start, double end) => Curves.easeOutBack.transform(((progress - start) / (end - start)).clamp(0.0, 1.0).toDouble());

  @override
  Widget build(BuildContext context) {
    final invitePulse = .5 + .5 * sin(progress * pi * 2);
    return Center(
      child: Transform.translate(
        offset: Offset(0, sin(progress * pi * 2) * 4),
        child: Container(
          width: 250,
          constraints: const BoxConstraints(maxHeight: 330),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.96),
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 24, offset: Offset(0, 14))],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              height: 66,
              decoration: BoxDecoration(
                color: AppColors.tealSoft,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(children: [
                Positioned(left: 14, top: 14, child: _MiniAvatar(label: 'J', color: AppColors.teal)),
                Positioned(left: 42, top: 14, child: Transform.scale(scale: _pop(.05, .32), child: _MiniAvatar(label: 'M', color: AppColors.orange))),
                Positioned(left: 70, top: 14, child: Transform.scale(scale: _pop(.15, .42), child: _MiniAvatar(label: 'A', color: AppColors.violet))),
                Positioned(
                  right: 12,
                  top: 14,
                  child: Transform.scale(
                    scale: 1 + invitePulse * .05,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(99)),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.lock_rounded, color: AppColors.teal, size: 14),
                        SizedBox(width: 5),
                        Text('Privado', style: TextStyle(color: AppColors.teal, fontWeight: FontWeight.w900, fontSize: 11)),
                      ]),
                    ),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 12),
            const Text('Los pingüino', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.ink, fontSize: 20, fontWeight: FontWeight.w900, height: 1)),
            const SizedBox(height: 5),
            const Text('Agenda, gastos y torneos del grupo', style: TextStyle(color: AppColors.muted, fontSize: 12.5, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            _SceneMiniTile(icon: Icons.calendar_month_rounded, color: AppColors.teal, title: 'Plan del viernes', subtitle: '4 van · 1 duda', progress: _pop(.25, .55)),
            const SizedBox(height: 8),
            _SceneMiniTile(icon: Icons.account_balance_wallet_rounded, color: AppColors.green, title: 'Pago pendiente', subtitle: 'Liquidar € 2,50', progress: _pop(.35, .68)),
            const SizedBox(height: 8),
            _SceneMiniTile(icon: Icons.emoji_events_rounded, color: AppColors.red, title: 'Liga activa', subtitle: 'Jornada 2 lista', progress: _pop(.45, .78)),
          ]),
        ),
      ),
    );
  }
}

class _AgendaScene extends StatelessWidget {
  final double progress;
  const _AgendaScene({required this.progress});

  double _ease(double start, double end) => Curves.easeOutCubic.transform(((progress - start) / (end - start)).clamp(0.0, 1.0).toDouble());

  @override
  Widget build(BuildContext context) {
    final selected = progress > .34;
    final confirmed = progress > .62;
    final pulse = .5 + .5 * sin(progress * pi * 2);
    return Center(
      child: Container(
        width: 258,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.97),
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 24, offset: Offset(0, 14))],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Icon(Icons.calendar_month_rounded, color: AppColors.teal, size: 19),
            SizedBox(width: 7),
            Text('Agenda', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 17)),
          ]),
          const SizedBox(height: 12),
          Row(children: List.generate(5, (i) {
            final active = i == 2;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: active ? 58 : 50,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: active ? AppColors.teal : AppColors.surface,
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(color: active ? AppColors.teal : AppColors.line),
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(['L','M','X','J','V'][i], style: TextStyle(color: active ? Colors.white : AppColors.muted, fontWeight: FontWeight.w900, fontSize: 10)),
                  const SizedBox(height: 4),
                  Text('${10 + i}', style: TextStyle(color: active ? Colors.white : AppColors.ink, fontWeight: FontWeight.w900, fontSize: active ? 19 : 16)),
                  const SizedBox(height: 4),
                  Container(width: active ? 18 : 6, height: 5, decoration: BoxDecoration(color: active ? Colors.white : AppColors.line, borderRadius: BorderRadius.circular(99))),
                ]),
              ),
            );
          })),
          const SizedBox(height: 14),
          Transform.translate(
            offset: Offset(0, (1 - _ease(.18, .45)) * 18),
            child: Opacity(
              opacity: _ease(.18, .45),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.tealSoft, borderRadius: BorderRadius.circular(21)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(width: 38, height: 38, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.location_on_outlined, color: AppColors.teal, size: 20)),
                    const SizedBox(width: 9),
                    const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Partido del grupo', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
                      SizedBox(height: 2),
                      Text('Vie 12 · 20:00', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 12)),
                    ])),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      width: confirmed ? 48 : 42,
                      height: 26,
                      decoration: BoxDecoration(color: confirmed ? AppColors.green : AppColors.white, borderRadius: BorderRadius.circular(99)),
                      child: Center(child: Text(confirmed ? '4/4' : '3/4', style: TextStyle(color: confirmed ? Colors.white : AppColors.teal, fontWeight: FontWeight.w900, fontSize: 11))),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _IntroAttendanceButton(label: 'Voy', color: AppColors.green, selected: confirmed || selected, pulse: pulse)),
                    const SizedBox(width: 7),
                    Expanded(child: _IntroAttendanceButton(label: 'Duda', color: AppColors.amber, selected: !confirmed && selected, pulse: 0)),
                    const SizedBox(width: 7),
                    Expanded(child: _IntroAttendanceButton(label: 'No', color: AppColors.red, selected: false, pulse: 0)),
                  ]),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _FinanceTournamentScene extends StatelessWidget {
  final double progress;
  const _FinanceTournamentScene({required this.progress});

  double _ease(double start, double end) => Curves.easeOutCubic.transform(((progress - start) / (end - start)).clamp(0.0, 1.0).toDouble());

  @override
  Widget build(BuildContext context) {
    final paid = progress > .46;
    final tableStep = progress > .66;
    return Center(
      child: Container(
        width: 260,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.97),
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 24, offset: Offset(0, 14))],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Transform.translate(
            offset: Offset(0, (1 - _ease(.05, .32)) * 18),
            child: Opacity(
              opacity: _ease(.05, .32),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.greenSoft, borderRadius: BorderRadius.circular(21)),
                child: Row(children: [
                  Container(width: 39, height: 39, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)), child: Icon(paid ? Icons.verified_rounded : Icons.account_balance_wallet_rounded, color: AppColors.green)),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(paid ? 'Pago liquidado' : 'Pago recomendado', style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 2),
                    Text(paid ? 'Balance del grupo a cero' : 'Marta liquida € 2,50 a Javi', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 12)),
                  ])),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(color: paid ? AppColors.green : AppColors.teal, borderRadius: BorderRadius.circular(99)),
                    child: Text(paid ? 'Listo' : 'Liquidar', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11)),
                  ),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Transform.translate(
            offset: Offset(0, (1 - _ease(.28, .55)) * 20),
            child: Opacity(
              opacity: _ease(.28, .55),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.orangeSoft, borderRadius: BorderRadius.circular(21)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Row(children: [
                    Icon(Icons.emoji_events_rounded, color: AppColors.orange, size: 20),
                    SizedBox(width: 7),
                    Text('Liga del grupo', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
                    Spacer(),
                    Text('J2', style: TextStyle(color: AppColors.orange, fontWeight: FontWeight.w900)),
                  ]),
                  const SizedBox(height: 10),
                  _MiniRankingRow(position: 1, name: tableStep ? 'Cuatro' : 'Dos', points: tableStep ? '6 pts' : '3 pts', active: true),
                  const SizedBox(height: 7),
                  _MiniRankingRow(position: 2, name: tableStep ? 'Dos' : 'Cuatro', points: tableStep ? '3 pts' : '3 pts', active: false),
                  const SizedBox(height: 7),
                  _MiniRankingRow(position: 3, name: 'Tres', points: '0 pts', active: false),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _MiniAvatar extends StatelessWidget {
  final String label;
  final Color color;
  const _MiniAvatar({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    width: 34,
    height: 34,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
    child: Center(child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13))),
  );
}

class _SceneMiniTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final double progress;
  const _SceneMiniTile({required this.icon, required this.color, required this.title, required this.subtitle, required this.progress});

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: progress.clamp(0.0, 1.0).toDouble(),
    child: Transform.translate(
      offset: Offset(0, 14 * (1 - progress)),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(17), border: Border.all(color: AppColors.lineSoft)),
        child: Row(children: [
          Container(width: 34, height: 34, decoration: BoxDecoration(color: color.withOpacity(.10), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 18)),
          const SizedBox(width: 9),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 12.5)),
            const SizedBox(height: 2),
            Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 11)),
          ])),
        ]),
      ),
    ),
  );
}

class _IntroAttendanceButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final double pulse;
  const _IntroAttendanceButton({required this.label, required this.color, required this.selected, required this.pulse});

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 300),
    height: 34,
    decoration: BoxDecoration(
      color: selected ? color.withOpacity(.14 + pulse * .05) : Colors.white,
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: selected ? color : AppColors.line),
    ),
    child: Center(child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 11.5))),
  );
}

class _MiniRankingRow extends StatelessWidget {
  final int position;
  final String name;
  final String points;
  final bool active;
  const _MiniRankingRow({required this.position, required this.name, required this.points, required this.active});

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 360),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(color: active ? Colors.white : Colors.white.withOpacity(.64), borderRadius: BorderRadius.circular(14)),
    child: Row(children: [
      Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(color: active ? AppColors.orange : AppColors.lineSoft, shape: BoxShape.circle),
        child: Center(child: Text('$position', style: TextStyle(color: active ? Colors.white : AppColors.muted, fontWeight: FontWeight.w900, fontSize: 11))),
      ),
      const SizedBox(width: 8),
      Expanded(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 12))),
      Text(points, style: TextStyle(color: active ? AppColors.green : AppColors.muted, fontWeight: FontWeight.w900, fontSize: 11)),
    ]),
  );
}


class WelcomeScreen extends StatelessWidget {
  final VoidCallback? onShowIntro;
  const WelcomeScreen({super.key, this.onShowIntro});

  Future<void> _openAuth(BuildContext context, {required bool register}) async {
    await PendingInviteStore.save(InviteLinks.currentCode);
    if (!context.mounted) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => AuthScreen(register: register, inviteCode: InviteLinks.currentCode)));
  }

  @override
  Widget build(BuildContext context) {
    final inviteCode = InviteLinks.currentCode;
    return DirectPage(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 30),
      child: Column(
        children: [
          if (inviteCode != null) ...[
            InviteLandingBanner(code: inviteCode),
            const SizedBox(height: 14),
          ],
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
                SizedBox(width: double.infinity, child: WhiteButton(label: inviteCode == null ? 'Comenzar' : 'Crear cuenta y unirme', onTap: () => _openAuth(context, register: true))),
                TextButton(onPressed: () => _openAuth(context, register: false), child: Text(inviteCode == null ? 'Iniciar sesión' : 'Ya tengo cuenta', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
              ],
            ),
          ),
          const SizedBox(height: 23),
          Text('La app privada para coordinar grupos sin caos.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          const Text('Eventos, calendario, finanzas y torneos en un único espacio cerrado.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted, fontSize: 15, height: 1.35)),
          if (inviteCode == null && onShowIntro != null) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onShowIntro,
              icon: const Icon(Icons.play_circle_outline_rounded, size: 18),
              label: const Text('Ver introducción', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        ],
      ),
    );
  }

  IconData _welcomeIcon(int index) {
    const icons = [Icons.event_available_rounded, Icons.calendar_month_rounded, Icons.account_balance_wallet_rounded, Icons.emoji_events_rounded, Icons.lock_rounded, Icons.qr_code_rounded];
    return icons[index % icons.length];
  }
}

class InviteLandingBanner extends StatelessWidget {
  final String code;
  const InviteLandingBanner({super.key, required this.code});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.tealSoft,
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        Container(width: 42, height: 42, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Icon(Icons.mark_email_unread_rounded, color: AppColors.teal)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Te han invitado a un grupo', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 3),
          Text('Código $code · inicia sesión y entraremos automáticamente.', style: Theme.of(context).textTheme.bodyMedium),
        ])),
      ]),
    );
  }
}

class AuthScreen extends StatefulWidget {
  final bool register;
  final String? inviteCode;
  const AuthScreen({super.key, required this.register, this.inviteCode});

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
      await PendingInviteStore.save(widget.inviteCode ?? InviteLinks.currentCode);
      if (widget.register) {
        await AppData.sb.auth.signUp(email: email.text.trim(), password: password.text.trim());
      } else {
        // En APK puede quedar una sesión local vieja de otra instalación o de una prueba anterior.
        // La limpiamos solo en el dispositivo antes de iniciar sesión para evitar bucles de sesión caducada.
        await AppData.clearLocalSession();
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
      await PendingInviteStore.save(widget.inviteCode ?? InviteLinks.currentCode);
      await AppData.clearLocalSession();
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
        if (!widget.register)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: loading ? null : () async {
                await AppData.clearLocalSession();
                if (context.mounted) await showToast(context, 'Sesión local limpiada. Vuelve a iniciar sesión.');
              },
              icon: const Icon(Icons.restart_alt_rounded, size: 18),
              label: const Text('Limpiar sesión de este móvil'),
            ),
          ),
        const SizedBox(height: 16),
        PrimaryButton(label: widget.register ? 'Crear cuenta' : 'Iniciar sesión', icon: widget.register ? Icons.person_add_alt_1_rounded : Icons.login_rounded, loading: loading, onTap: submit),
        const SizedBox(height: 22),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(widget.register ? '¿Ya tienes cuenta?' : '¿No tienes cuenta?', style: Theme.of(context).textTheme.bodyMedium),
          TextButton(onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => AuthScreen(register: !widget.register, inviteCode: widget.inviteCode))), child: Text(widget.register ? 'Inicia sesión' : 'Regístrate')),
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
  bool handledInitialInvite = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleInitialInvite();
      PushNotificationService.tryRegisterSilently();
    });
  }

  Future<void> _handleInitialInvite() async {
    if (handledInitialInvite || !mounted) return;
    handledInitialInvite = true;
    final code = InviteLinks.currentCode ?? await PendingInviteStore.read();
    if (code == null || code.length < 4) return;
    await PendingInviteStore.clear();
    if (!mounted) return;
    final result = await Navigator.of(context).push<dynamic>(
      MaterialPageRoute(builder: (_) => JoinInviteScreen(inviteCode: code)),
    );
    if (!mounted) return;
    await _handleGroupNavigationResult(result);
  }

  void refresh() => setState(() => refreshKey++);

  Future<void> _handleGroupNavigationResult(dynamic result) async {
    if (!mounted || result == null) return;
    final shouldRefresh = result == true || result is Map;
    if (shouldRefresh) {
      setState(() {
        tab = 0;
        refreshKey++;
      });
    }
    if (result is Map && result['action'] == 'open' && result['groupId'] != null) {
      final groupId = result['groupId'].toString();
      await Future<void>.delayed(const Duration(milliseconds: 80));
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => GroupShell(groupId: groupId)));
      if (mounted) refresh();
    }
  }


  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(key: ValueKey('home-$refreshKey'), onChanged: refresh),
      NotificationsScreen(onChanged: refresh),
      ProfileScreen(onChanged: refresh, onNavigateRoot: (i) => setState(() => tab = i)),
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
  RealtimeChannel? _homeRealtimeChannel;
  Timer? _homeRealtimeDebounce;

  @override
  void initState() {
    super.initState();
    future = AppData.myGroups();
    _subscribeHomeRealtime();
  }

  @override
  void dispose() {
    _homeRealtimeDebounce?.cancel();
    final channel = _homeRealtimeChannel;
    if (channel != null) {
      AppData.sb.removeChannel(channel);
    }
    super.dispose();
  }

  void reload() {
    if (!mounted) return;
    setState(() { future = AppData.myGroups(); });
  }

  Future<void> _handleGroupNavigationResult(dynamic result) async {
    if (!mounted || result == null) return;
    if (result is Map && result['action'] == 'open' && result['groupId'] != null) {
      final groupId = result['groupId'].toString();
      reload();
      await Future<void>.delayed(const Duration(milliseconds: 80));
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => GroupShell(groupId: groupId)));
      if (mounted) {
        reload();
        widget.onChanged();
      }
      return;
    }
    if (result == true || result is Map) {
      reload();
      widget.onChanged();
    }
  }

  Future<void> _openCreateJoin() async {
    final result = await Navigator.of(context).push<dynamic>(MaterialPageRoute(builder: (_) => const CreateJoinScreen()));
    await _handleGroupNavigationResult(result);
  }

  Future<void> _openCreateGroup() async {
    final result = await Navigator.of(context).push<dynamic>(MaterialPageRoute(builder: (_) => const CreateGroupScreen()));
    await _handleGroupNavigationResult(result);
  }

  Future<void> _openJoinGroup() async {
    final result = await Navigator.of(context).push<dynamic>(MaterialPageRoute(builder: (_) => const JoinGroupScreen()));
    await _handleGroupNavigationResult(result);
  }

  void _scheduleHomeRealtimeReload() {
    _homeRealtimeDebounce?.cancel();
    _homeRealtimeDebounce = Timer(const Duration(milliseconds: 600), () {
      if (mounted) reload();
    });
  }

  void _subscribeHomeRealtime() {
    // v15.32: Realtime automático desactivado temporalmente.
    // Motivo: varios listeners reconstruían pantallas completas y podían crear bucles de refresco/parpadeo en web/APK.
    // La app refresca de forma explícita tras crear/editar/borrar. Reactivarlo solo con streams por pantalla y QA.
    if (!AppConfig.enableRealtimeSubscriptions) return;
    final userId = AppData.user?.id ?? 'anon';
    final channel = AppData.sb.channel('grupli-home-$userId-live')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'group_members',
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'user_id', value: userId),
        callback: (_) => _scheduleHomeRealtimeReload(),
      )
      ..subscribe();
    _homeRealtimeChannel = channel;
  }

  @override
  Widget build(BuildContext context) {
    final email = AppData.user?.email ?? 'usuario@email.com';
    final name = email.split('@').first;
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 28),
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Expanded(child: PageHeader(title: 'Mis grupos 👋', subtitle: 'Hola, $name. Organiza planes, gastos y torneos en un solo lugar.')),
            const SizedBox(width: 12),
            CircleIconButton(icon: Icons.add_rounded, filled: true, onTap: _openCreateJoin),
          ]),
          const SizedBox(height: 20),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const HomeLoading();
              if (snapshot.hasError) return ErrorBlock(message: snapshot.error.toString(), onRetry: reload);
              final groups = snapshot.data ?? [];
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text('Tus grupos', style: Theme.of(context).textTheme.titleLarge),
                  const Spacer(),
                  TextButton(onPressed: reload, child: const Text('Actualizar')),
                ]),
                const SizedBox(height: 10),
                if (groups.isEmpty) ...[
                  EmptyBlock(icon: Icons.groups_rounded, title: 'Aún no tienes grupos', body: 'Crea un grupo privado o únete con un código de invitación.'),
                  const SizedBox(height: 14),
                  PrimaryButton(label: 'Crear grupo', icon: Icons.add_rounded, onTap: _openCreateGroup),
                  const SizedBox(height: 10),
                  SecondaryButton(label: 'Unirme con código', icon: Icons.qr_code_rounded, onTap: _openJoinGroup),
                ] else ...[
                  ...groups.map((g) => GroupHomeCard(group: g, onTap: () async {
                    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => GroupShell(groupId: g['id'].toString())));
                    reload();
                  })),
                  const SizedBox(height: 14),
                  ChoiceBigCard(
                    icon: Icons.add_circle_outline_rounded,
                    title: 'Crear o unirte a otro grupo',
                    body: 'Añade otro grupo privado o entra con un código de invitación.',
                    onTap: _openCreateJoin,
                  ),
                ],
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
        PageHeader(title: 'Añadir grupo', subtitle: 'Crea un grupo nuevo o entra con invitación.', leading: true),
        const SizedBox(height: 20),
        ChoiceBigCard(icon: Icons.groups_rounded, title: 'Crear un grupo', body: 'Crea tu grupo privado y empieza a organizar.', onTap: () async {
          final result = await Navigator.push<dynamic>(context, MaterialPageRoute(builder: (_) => const CreateGroupScreen()));
          if (context.mounted && result != null) Navigator.pop(context, result);
        }),
        const SizedBox(height: 12),
        ChoiceBigCard(icon: Icons.group_add_rounded, title: 'Unirse a un grupo', body: 'Únete a un grupo con código o enlace.', onTap: () async {
          final result = await Navigator.push<dynamic>(context, MaterialPageRoute(builder: (_) => const JoinGroupScreen()));
          if (context.mounted && result != null) Navigator.pop(context, result);
        }),
      ]),
    );
  }
}



Future<ui.Image> _decodeUiImage(Uint8List bytes) async {
  final completer = Completer<ui.Image>();
  ui.decodeImageFromList(bytes, (image) => completer.complete(image));
  return completer.future;
}

ui.Rect cropSourceRect({
  required ui.Image image,
  required double aspectRatio,
  required double zoom,
  required double offsetX,
  required double offsetY,
}) {
  final iw = image.width.toDouble();
  final ih = image.height.toDouble();
  final imageAspect = iw / ih;
  final baseW = imageAspect > aspectRatio ? ih * aspectRatio : iw;
  final baseH = imageAspect > aspectRatio ? ih : iw / aspectRatio;
  final safeZoom = zoom.clamp(1.0, 5.0).toDouble();
  final minW = min(64.0, iw);
  final minH = min(64.0, ih);
  final cropW = (baseW / safeZoom).clamp(minW, iw).toDouble();
  final cropH = (baseH / safeZoom).clamp(minH, ih).toDouble();
  final centerX = (iw / 2) + offsetX.clamp(-1.0, 1.0) * ((iw - cropW) / 2);
  final centerY = (ih / 2) + offsetY.clamp(-1.0, 1.0) * ((ih - cropH) / 2);
  final left = (centerX - cropW / 2).clamp(0.0, iw - cropW).toDouble();
  final top = (centerY - cropH / 2).clamp(0.0, ih - cropH).toDouble();
  return ui.Rect.fromLTWH(left, top, cropW, cropH);
}

Future<Uint8List> cropImageBytes({
  required Uint8List bytes,
  required double aspectRatio,
  required double zoom,
  required double offsetX,
  required double offsetY,
  required int outputWidth,
}) async {
  final image = await _decodeUiImage(bytes);
  final src = cropSourceRect(
    image: image,
    aspectRatio: aspectRatio,
    zoom: zoom,
    offsetX: offsetX,
    offsetY: offsetY,
  );
  final outputHeight = max(1, (outputWidth / aspectRatio).round());

  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  final paint = ui.Paint()..filterQuality = ui.FilterQuality.high;
  canvas.drawImageRect(
    image,
    src,
    ui.Rect.fromLTWH(0, 0, outputWidth.toDouble(), outputHeight.toDouble()),
    paint,
  );
  final picture = recorder.endRecording();
  final cropped = await picture.toImage(outputWidth, outputHeight);
  final data = await cropped.toByteData(format: ui.ImageByteFormat.png);
  if (data == null) throw Exception('No se pudo preparar la imagen.');
  return data.buffer.asUint8List();
}



class ImageFrameEditorScreen extends StatefulWidget {
  final Uint8List bytes;
  final String title;
  final String helper;
  final double aspectRatio;
  final int outputWidth;
  final bool circularPreview;
  const ImageFrameEditorScreen({
    super.key,
    required this.bytes,
    required this.title,
    required this.helper,
    required this.aspectRatio,
    required this.outputWidth,
    this.circularPreview = false,
  });

  @override
  State<ImageFrameEditorScreen> createState() => _ImageFrameEditorScreenState();
}

class _ImageFrameEditorScreenState extends State<ImageFrameEditorScreen> {
  double zoom = 1;
  double offsetX = 0;
  double offsetY = 0;
  double _gestureStartZoom = 1;
  bool saving = false;
  late Future<ui.Image> imageFuture;

  @override
  void initState() {
    super.initState();
    imageFuture = _decodeUiImage(widget.bytes);
  }

  Future<void> save() async {
    setState(() => saving = true);
    try {
      final cropped = await cropImageBytes(
        bytes: widget.bytes,
        aspectRatio: widget.aspectRatio,
        zoom: zoom,
        offsetX: offsetX,
        offsetY: offsetY,
        outputWidth: widget.outputWidth,
      );
      if (mounted) Navigator.pop(context, cropped);
    } catch (e) {
      if (mounted) await showToast(context, humanError(e), danger: true);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  void _onScaleStart(ScaleStartDetails details) {
    _gestureStartZoom = zoom;
  }

  void _onScaleUpdate(ScaleUpdateDetails details, double frameWidth, double frameHeight, ui.Image image) {
    final nextZoom = (_gestureStartZoom * details.scale).clamp(1.0, 5.0).toDouble();
    final src = cropSourceRect(
      image: image,
      aspectRatio: widget.aspectRatio,
      zoom: nextZoom,
      offsetX: offsetX,
      offsetY: offsetY,
    );

    final rangeX = (image.width.toDouble() - src.width) / 2;
    final rangeY = (image.height.toDouble() - src.height) / 2;

    final deltaSrcX = frameWidth <= 0 ? 0.0 : -details.focalPointDelta.dx / frameWidth * src.width;
    final deltaSrcY = frameHeight <= 0 ? 0.0 : -details.focalPointDelta.dy / frameHeight * src.height;

    setState(() {
      zoom = nextZoom;
      if (rangeX > .5) {
        offsetX = (offsetX + deltaSrcX / rangeX).clamp(-1.0, 1.0).toDouble();
      } else {
        offsetX = 0;
      }
      if (rangeY > .5) {
        offsetY = (offsetY + deltaSrcY / rangeY).clamp(-1.0, 1.0).toDouble();
      } else {
        offsetY = 0;
      }
    });
  }

  void _focusAt(TapUpDetails details, double frameWidth, double frameHeight, ui.Image image) {
    final src = cropSourceRect(
      image: image,
      aspectRatio: widget.aspectRatio,
      zoom: zoom,
      offsetX: offsetX,
      offsetY: offsetY,
    );
    final local = details.localPosition;
    final targetX = src.left + (local.dx / max(1.0, frameWidth)).clamp(0.0, 1.0) * src.width;
    final targetY = src.top + (local.dy / max(1.0, frameHeight)).clamp(0.0, 1.0) * src.height;
    final rangeX = (image.width.toDouble() - src.width) / 2;
    final rangeY = (image.height.toDouble() - src.height) / 2;
    setState(() {
      if (rangeX > .5) {
        offsetX = ((targetX - image.width / 2) / rangeX).clamp(-1.0, 1.0).toDouble();
      }
      if (rangeY > .5) {
        offsetY = ((targetY - image.height / 2) / rangeY).clamp(-1.0, 1.0).toDouble();
      }
    });
  }

  void reset() => setState(() {
    zoom = 1;
    offsetX = 0;
    offsetY = 0;
  });

  void quickFocus(String value) => setState(() {
    switch (value) {
      case 'top':
        offsetY = -1;
        break;
      case 'bottom':
        offsetY = 1;
        break;
      case 'left':
        offsetX = -1;
        break;
      case 'right':
        offsetX = 1;
        break;
      default:
        offsetX = 0;
        offsetY = 0;
    }
  });

  @override
  Widget build(BuildContext context) {
    return DirectPage(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        RoundBackButton(),
        const Spacer(),
        TextButton(onPressed: saving ? null : save, child: const Text('Guardar', style: TextStyle(fontWeight: FontWeight.w900))),
      ]),
      const SizedBox(height: 18),
      Text(widget.title, style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 6),
      Text(widget.helper, style: Theme.of(context).textTheme.bodyMedium),
      const SizedBox(height: 14),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: AppColors.tealSoft, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0x240B6B8F))),
        child: const Row(children: [
          Icon(Icons.center_focus_strong_rounded, color: AppColors.teal, size: 19),
          SizedBox(width: 8),
          Expanded(child: Text('Nuevo método: toca la cara o zona importante para centrarla. También puedes arrastrar y pellizcar con precisión real.', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800, fontSize: 12.5))),
        ]),
      ),
      const SizedBox(height: 14),
      AppCard(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          FutureBuilder<ui.Image>(
            future: imageFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return AspectRatio(
                  aspectRatio: widget.aspectRatio,
                  child: const CenterLoader(label: 'Preparando imagen...'),
                );
              }
              final image = snapshot.data!;
              return LayoutBuilder(builder: (context, constraints) {
                final frameWidth = constraints.maxWidth;
                final frameHeight = frameWidth / widget.aspectRatio;
                return AspectRatio(
                  aspectRatio: widget.aspectRatio,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (details) => _focusAt(details, frameWidth, frameHeight, image),
                    onScaleStart: _onScaleStart,
                    onScaleUpdate: (details) => _onScaleUpdate(details, frameWidth, frameHeight, image),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(widget.circularPreview ? 999 : 22),
                      child: Container(
                        color: AppColors.navHome,
                        child: Stack(children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: CropFramePainter(
                                image: image,
                                aspectRatio: widget.aspectRatio,
                                zoom: zoom,
                                offsetX: offsetX,
                                offsetY: offsetY,
                              ),
                              child: const SizedBox.expand(),
                            ),
                          ),
                          Positioned.fill(
                            child: IgnorePointer(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.white.withOpacity(.80), width: widget.circularPreview ? 3 : 2),
                                  borderRadius: BorderRadius.circular(widget.circularPreview ? 999 : 22),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 12,
                            right: 12,
                            bottom: 12,
                            child: IgnorePointer(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                decoration: BoxDecoration(color: const Color(0x99000000), borderRadius: BorderRadius.circular(999)),
                                child: const Text('Toca una zona para centrarla · arrastra para ajustar', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
                              ),
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ),
                );
              });
            },
          ),
          const SizedBox(height: 14),
          Wrap(spacing: 8, runSpacing: 8, children: [
            ActionChip(label: const Text('Arriba'), avatar: const Icon(Icons.keyboard_arrow_up_rounded, size: 18), onPressed: () => quickFocus('top')),
            ActionChip(label: const Text('Centro'), avatar: const Icon(Icons.filter_center_focus_rounded, size: 18), onPressed: () => quickFocus('center')),
            ActionChip(label: const Text('Abajo'), avatar: const Icon(Icons.keyboard_arrow_down_rounded, size: 18), onPressed: () => quickFocus('bottom')),
            ActionChip(label: const Text('Izquierda'), avatar: const Icon(Icons.keyboard_arrow_left_rounded, size: 18), onPressed: () => quickFocus('left')),
            ActionChip(label: const Text('Derecha'), avatar: const Icon(Icons.keyboard_arrow_right_rounded, size: 18), onPressed: () => quickFocus('right')),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            const Icon(Icons.zoom_in_rounded, color: AppColors.teal),
            Expanded(
              child: Slider(
                value: zoom.clamp(1.0, 5.0).toDouble(),
                min: 1,
                max: 5,
                onChanged: (v) => setState(() => zoom = v),
                activeColor: AppColors.teal,
              ),
            ),
            const SizedBox(width: 8),
            Text('${zoom.toStringAsFixed(1)}x', style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
          ]),
          Row(children: [
            const Icon(Icons.swap_vert_rounded, color: AppColors.violet),
            Expanded(
              child: Slider(
                value: offsetY.clamp(-1.0, 1.0).toDouble(),
                min: -1,
                max: 1,
                onChanged: (v) => setState(() => offsetY = v),
                activeColor: AppColors.violet,
              ),
            ),
            const SizedBox(width: 8),
            const Text('alto', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w900, fontSize: 12)),
          ]),
        ]),
      ),
      const SizedBox(height: 16),
      PrimaryButton(label: 'Guardar encuadre', icon: Icons.check_rounded, loading: saving, onTap: save),
      const SizedBox(height: 10),
      SecondaryButton(label: 'Restablecer encuadre', icon: Icons.restart_alt_rounded, onTap: reset),
    ]));
  }
}

class CropFramePainter extends CustomPainter {
  final ui.Image image;
  final double aspectRatio;
  final double zoom;
  final double offsetX;
  final double offsetY;

  CropFramePainter({
    required this.image,
    required this.aspectRatio,
    required this.zoom,
    required this.offsetX,
    required this.offsetY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final src = cropSourceRect(
      image: image,
      aspectRatio: aspectRatio,
      zoom: zoom,
      offsetX: offsetX,
      offsetY: offsetY,
    );
    final dst = Offset.zero & size;
    final paint = Paint()..filterQuality = FilterQuality.high;
    canvas.drawImageRect(image, src, dst, paint);
  }

  @override
  bool shouldRepaint(covariant CropFramePainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.aspectRatio != aspectRatio ||
        oldDelegate.zoom != zoom ||
        oldDelegate.offsetX != offsetX ||
        oldDelegate.offsetY != offsetY;
  }
}

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final name = TextEditingController();
  final description = TextEditingController();
  String type = 'deporte';
  String currency = 'EUR';
  bool loading = false;
  Uint8List? coverBytes;
  String? coverFileName;
  int step = 0;

  static const groupTypes = [
    ('deporte', 'Deporte', Icons.sports_tennis_rounded, 'Pádel, fútbol, running...'),
    ('amigos', 'Amigos', Icons.groups_2_rounded, 'Quedadas, cenas y planes'),
    ('viaje', 'Viaje', Icons.flight_takeoff_rounded, 'Gastos y planes del viaje'),
    ('cartas', 'Cartas', Icons.style_rounded, 'Mus, poker, juegos de mesa'),
    ('otro', 'Otro', Icons.auto_awesome_rounded, 'Cualquier grupo privado'),
  ];

  @override
  void initState() {
    super.initState();
    description.text = groupTypeDefaultDescription(type);
  }

  @override
  void dispose() {
    name.dispose();
    description.dispose();
    super.dispose();
  }

  Future<void> pickCover() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 88, maxWidth: 2400);
    if (picked == null) return;
    final raw = await picked.readAsBytes();
    if (!mounted) return;
    final framed = await Navigator.of(context).push<Uint8List>(MaterialPageRoute(
      builder: (_) => ImageFrameEditorScreen(
        bytes: raw,
        title: 'Ajustar portada',
        helper: 'Arrastra y pellizca la imagen para encajar la portada como en una app real.',
        aspectRatio: 16 / 7,
        outputWidth: 1600,
      ),
    ));
    if (framed == null) return;
    setState(() {
      coverBytes = framed;
      coverFileName = 'group-cover.png';
    });
  }

  void selectType(String value) {
    setState(() {
      type = value;
      if (description.text.trim().isEmpty || description.text == groupTypeDefaultDescription('deporte') || description.text == groupTypeDefaultDescription('amigos') || description.text == groupTypeDefaultDescription('viaje') || description.text == groupTypeDefaultDescription('cartas') || description.text == groupTypeDefaultDescription('otro')) {
        description.text = groupTypeDefaultDescription(type);
      }
    });
  }

  bool validateStep() {
    if (step == 0 && name.text.trim().length < 2) {
      showToast(context, 'Pon un nombre de grupo.', danger: true);
      return false;
    }
    return true;
  }

  Future<void> create() async {
    if (!validateStep()) return;
    setState(() => loading = true);
    try {
      final groupId = await AppData.createGroup(
        name.text,
        type: type,
        description: description.text,
        currency: currency,
      );
      if (coverBytes != null) {
        await AppData.uploadGroupCoverBytes(groupId, coverBytes!, coverFileName ?? 'group-cover.png');
      }
      if (!mounted) return;
      final action = await Navigator.of(context).push<String>(MaterialPageRoute(
        builder: (_) => GroupCreatedScreen(groupId: groupId, groupName: name.text.trim(), groupType: type),
      ));
      if (!mounted) return;
      Navigator.pop(context, {
        'action': action == 'open' ? 'open' : 'home',
        'groupId': groupId,
      });
    } catch (e) {
      await showToast(context, humanError(e), danger: true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = step == 0 ? 'Crea tu grupo' : step == 1 ? 'Dale identidad' : 'Primeros pasos';
    final subtitle = step == 0
        ? 'Nombre, tipo y privacidad. Todo privado por defecto.'
        : step == 1
            ? 'Añade una portada y una descripción clara.'
            : 'Después de crearlo podrás invitar, crear el primer plan y añadir gastos.';
    return DirectPage(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          RoundBackButton(onTap: () => step == 0 ? Navigator.pop(context) : setState(() => step--)),
          const Spacer(),
          _MiniChip(text: '${step + 1}/3', color: AppColors.teal),
        ]),
        const SizedBox(height: 18),
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 6),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 18),
        _CreateGroupStepper(step: step),
        const SizedBox(height: 18),
        if (step == 0) ...[
          AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            FieldLabel('Nombre del grupo'),
            TextField(controller: name, autofocus: true, textInputAction: TextInputAction.next, decoration: const InputDecoration(hintText: 'Ej. Pádel los miércoles')),
            const SizedBox(height: 16),
            FieldLabel('Tipo de grupo'),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: groupTypes.map((item) {
              final active = type == item.$1;
              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => selectType(item.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: MediaQuery.sizeOf(context).width > 460 ? 150 : 152,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: active ? AppColors.tealDark : AppColors.faint,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: active ? AppColors.tealDark : AppColors.line),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(item.$3, color: active ? Colors.white : AppColors.teal),
                    const SizedBox(height: 8),
                    Text(item.$2, style: TextStyle(color: active ? Colors.white : AppColors.ink, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 2),
                    Text(item.$4, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: active ? Colors.white70 : AppColors.muted, fontSize: 11, fontWeight: FontWeight.w700)),
                  ]),
                ),
              );
            }).toList()),
          ])),
        ] else if (step == 1) ...[
          AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: pickCover,
              child: Container(
                height: 138,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: const LinearGradient(colors: [Color(0xFF041F33), Color(0xFF087A78)]),
                ),
                child: coverBytes == null
                    ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: const [
                        Icon(Icons.add_photo_alternate_rounded, color: Colors.white, size: 34),
                        SizedBox(height: 8),
                        Text('Añadir portada', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                        SizedBox(height: 4),
                        Text('Después podrás encuadrarla', style: TextStyle(color: Color(0xCCFFFFFF), fontWeight: FontWeight.w700, fontSize: 12)),
                      ]))
                    : Stack(children: [
                        Positioned.fill(child: ClipRRect(borderRadius: BorderRadius.circular(22), child: Image.memory(coverBytes!, fit: BoxFit.cover))),
                        Positioned(right: 12, bottom: 12, child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(color: Colors.black.withOpacity(.38), borderRadius: BorderRadius.circular(99)),
                          child: const Text('Cambiar encuadre', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
                        )),
                      ]),
              ),
            ),
            const SizedBox(height: 16),
            FieldLabel('Descripción'),
            TextField(controller: description, minLines: 2, maxLines: 4, decoration: const InputDecoration(hintText: '¿Para qué usará el grupo Grupli?')),
            const SizedBox(height: 12),
            FieldLabel('Moneda'),
            DropdownButtonFormField<String>(
              value: currency,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.payments_rounded)),
              items: const [
                DropdownMenuItem(value: 'EUR', child: Text('EUR · Euro')),
                DropdownMenuItem(value: 'USD', child: Text('USD · Dólar')),
                DropdownMenuItem(value: 'GBP', child: Text('GBP · Libra')),
              ],
              onChanged: (v) => setState(() => currency = v ?? 'EUR'),
            ),
          ])),
        ] else ...[
          AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _SetupTodoRow(icon: Icons.link_rounded, title: 'Invitar miembros', body: 'Comparte código o enlace por WhatsApp al terminar.'),
            const Divider(height: 20, color: AppColors.line),
            _SetupTodoRow(icon: Icons.event_available_rounded, title: 'Crear primer plan', body: 'Una quedada rápida para que todos confirmen asistencia.'),
            const Divider(height: 20, color: AppColors.line),
            _SetupTodoRow(icon: Icons.account_balance_wallet_rounded, title: 'Primer gasto', body: 'Si el grupo ya tiene gastos, Grupli calculará saldos.'),
            if (type == 'deporte' || type == 'cartas') ...[
              const Divider(height: 20, color: AppColors.line),
              _SetupTodoRow(icon: Icons.emoji_events_rounded, title: 'Torneo opcional', body: 'Al entrar al grupo podrás crear liga, eliminatoria o americano.'),
            ],
          ])),
        ],
        const SizedBox(height: 22),
        if (step < 2)
          PrimaryButton(label: 'Continuar', icon: Icons.arrow_forward_rounded, onTap: () { if (validateStep()) setState(() => step++); })
        else
          PrimaryButton(label: 'Crear grupo', icon: Icons.check_rounded, loading: loading, onTap: create),
        const SizedBox(height: 10),
        if (step < 2) SecondaryButton(label: 'Crear rápido', icon: Icons.bolt_rounded, onTap: create),
      ]),
    );
  }
}

class _CreateGroupStepper extends StatelessWidget {
  final int step;
  const _CreateGroupStepper({required this.step});
  @override
  Widget build(BuildContext context) => Row(children: List.generate(3, (i) {
    final active = i <= step;
    return Expanded(child: Container(
      height: 6,
      margin: EdgeInsets.only(right: i == 2 ? 0 : 8),
      decoration: BoxDecoration(color: active ? AppColors.teal : AppColors.line, borderRadius: BorderRadius.circular(99)),
    ));
  }));
}

class _SetupTodoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const _SetupTodoRow({required this.icon, required this.title, required this.body});
  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Container(width: 42, height: 42, decoration: BoxDecoration(color: AppColors.tealSoft, borderRadius: BorderRadius.circular(15)), child: Icon(icon, color: AppColors.teal)),
    const SizedBox(width: 12),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
      const SizedBox(height: 3),
      Text(body, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, height: 1.28)),
    ])),
  ]);
}

class GroupCreatedScreen extends StatelessWidget {
  final String groupId;
  final String groupName;
  final String groupType;
  const GroupCreatedScreen({super.key, required this.groupId, required this.groupName, required this.groupType});

  @override
  Widget build(BuildContext context) => DirectPage(
    scroll: false,
    child: Center(child: AppCard(padding: const EdgeInsets.all(22), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 82, height: 82, decoration: const BoxDecoration(color: AppColors.greenSoft, shape: BoxShape.circle), child: const Icon(Icons.check_rounded, color: AppColors.green, size: 42)),
      const SizedBox(height: 18),
      Text('Grupo creado', style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
      const SizedBox(height: 8),
      Text('$groupName ya está listo. Ahora invita gente o crea el primer plan.', style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
      const SizedBox(height: 18),
      PrimaryButton(label: 'Entrar al grupo', icon: Icons.arrow_forward_rounded, onTap: () => Navigator.pop(context, 'open')),
      const SizedBox(height: 10),
      SecondaryButton(label: 'Volver a mis grupos', icon: Icons.home_rounded, onTap: () => Navigator.pop(context, 'home')),
    ]))),
  );
}

class JoinGroupScreen extends StatefulWidget {
  final String? initialCode;
  const JoinGroupScreen({super.key, this.initialCode});

  @override
  State<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends State<JoinGroupScreen> {
  final code = TextEditingController();
  bool loading = false;

  @override
  void initState() {
    super.initState();
    code.text = InviteLinks.normalizeCode(widget.initialCode ?? '');
  }

  @override
  void dispose() {
    code.dispose();
    super.dispose();
  }

  Future<void> join() async {
    final clean = InviteLinks.codeFromText(code.text);
    if (clean == null || clean.length < 4) {
      await showToast(context, 'Introduce un código o enlace válido.', danger: true);
      return;
    }
    setState(() => loading = true);
    try {
      final groupId = await AppData.joinGroup(clean);
      if (!mounted) return;
      Navigator.pop(context, {
        'action': 'open',
        'groupId': groupId,
      });
    } catch (e) {
      await showToast(context, humanError(e), danger: true);
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
        Text('Pega un código o un enlace de invitación. Si vienes desde un enlace, lo rellenamos automáticamente.', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 26),
        FieldLabel('Código o enlace de invitación'),
        TextField(
          controller: code,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(prefixIcon: Icon(Icons.link_rounded), hintText: 'ABC123 o https://grupli.vercel.app/join/ABC123'),
        ),
        const SizedBox(height: 18),
        PrimaryButton(label: 'Unirme', icon: Icons.login_rounded, loading: loading, onTap: join),
      ]),
    );
  }
}

class JoinInviteScreen extends StatefulWidget {
  final String inviteCode;
  const JoinInviteScreen({super.key, required this.inviteCode});

  @override
  State<JoinInviteScreen> createState() => _JoinInviteScreenState();
}

class _JoinInviteScreenState extends State<JoinInviteScreen> {
  bool loading = true;
  bool joined = false;
  String? groupId;
  String? groupName;
  String? error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _joinFromLink());
  }

  Future<void> _joinFromLink() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final joinedGroupId = await AppData.joinGroup(widget.inviteCode);
      final group = await AppData.group(joinedGroupId);
      if (!mounted) return;
      setState(() {
        groupId = joinedGroupId;
        groupName = AppData.text(group['name'], 'Grupo');
        joined = true;
        loading = false;
      });
      await Future.delayed(const Duration(milliseconds: 650));
      if (!mounted || groupId == null) return;
      Navigator.pop(context, {
        'action': 'open',
        'groupId': groupId!,
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = humanError(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DirectPage(
      scroll: false,
      child: Center(
        child: AppCard(
          padding: const EdgeInsets.all(22),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(color: joined ? AppColors.greenSoft : AppColors.tealSoft, shape: BoxShape.circle),
              child: Icon(joined ? Icons.check_rounded : Icons.group_add_rounded, color: joined ? AppColors.green : AppColors.teal, size: 40),
            ),
            const SizedBox(height: 18),
            Text(
              loading ? 'Entrando al grupo...' : joined ? 'Ya estás dentro' : 'No se pudo abrir la invitación',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              loading
                  ? 'Estamos usando el enlace privado ${widget.inviteCode}.'
                  : joined
                      ? 'Te llevamos a ${groupName ?? 'tu grupo'} automáticamente.'
                      : (error ?? 'El enlace puede haber caducado o el código no es válido.'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            if (loading)
              const CircularProgressIndicator(color: AppColors.teal)
            else if (joined && groupId != null)
              PrimaryButton(label: 'Entrar al grupo', icon: Icons.arrow_forward_rounded, onTap: () => Navigator.pop(context, {
                'action': 'open',
                'groupId': groupId!,
              }))
            else ...[
              PrimaryButton(label: 'Intentar otra vez', icon: Icons.refresh_rounded, onTap: _joinFromLink),
              const SizedBox(height: 10),
              SecondaryButton(label: 'Escribir código', icon: Icons.qr_code_rounded, onTap: () async {
                final result = await Navigator.of(context).push<dynamic>(MaterialPageRoute(builder: (_) => JoinGroupScreen(initialCode: widget.inviteCode)));
                if (result != null && mounted) Navigator.pop(context, result);
              }),
            ],
          ]),
        ),
      ),
    );
  }
}

class GroupShell extends StatefulWidget {
  final String groupId;
  final int initialTab;
  const GroupShell({super.key, required this.groupId, this.initialTab = 0});

  @override
  State<GroupShell> createState() => _GroupShellState();
}

class _GroupShellState extends State<GroupShell> {
  int tab = 0;
  int refreshKey = 0;
  int dashboardRefreshKey = 0;
  int calendarRefreshKey = 0;
  int financeRefreshKey = 0;
  int tournamentsRefreshKey = 0;
  late Future<Map<String, dynamic>> groupFuture;
  Map<String, dynamic>? _cachedGroup;
  RealtimeChannel? _groupRealtimeChannel;
  Timer? _realtimeDebounce;
  final Set<String> _pendingRealtimeScopes = <String>{};

  @override
  void initState() {
    super.initState();
    tab = widget.initialTab.clamp(0, 4).toInt();
    groupFuture = AppData.group(widget.groupId);
    _subscribeGroupRealtime();
  }

  @override
  void dispose() {
    _realtimeDebounce?.cancel();
    final channel = _groupRealtimeChannel;
    if (channel != null) {
      AppData.sb.removeChannel(channel);
    }
    super.dispose();
  }

  void refresh() => _refreshGroupAndAll();

  void _refreshGroupAndAll() {
    if (!mounted) return;
    setState(() {
      refreshKey++;
      dashboardRefreshKey++;
      calendarRefreshKey++;
      financeRefreshKey++;
      tournamentsRefreshKey++;
      groupFuture = AppData.group(widget.groupId);
    });
  }

  void _refreshRealtimeScopes(Set<String> scopes) {
    if (!mounted || scopes.isEmpty) return;
    setState(() {
      if (scopes.contains('group') || scopes.contains('all')) {
        refreshKey++;
        dashboardRefreshKey++;
        calendarRefreshKey++;
        financeRefreshKey++;
        tournamentsRefreshKey++;
        groupFuture = AppData.group(widget.groupId);
        return;
      }
      final touchesDashboard = scopes.contains('dashboard') || scopes.contains('calendar') || scopes.contains('finance') || scopes.contains('tournaments');
      if (touchesDashboard) dashboardRefreshKey++;
      if (scopes.contains('calendar')) calendarRefreshKey++;
      if (scopes.contains('finance')) financeRefreshKey++;
      if (scopes.contains('tournaments')) tournamentsRefreshKey++;
    });
  }

  void _scheduleRealtimeRefresh([String scope = 'all']) {
    _pendingRealtimeScopes.add(scope);
    _realtimeDebounce?.cancel();
    _realtimeDebounce = Timer(const Duration(milliseconds: 700), () {
      final scopes = Set<String>.from(_pendingRealtimeScopes);
      _pendingRealtimeScopes.clear();
      _refreshRealtimeScopes(scopes);
    });
  }

  void _subscribeGroupRealtime() {
    // v15.32: Realtime automático desactivado temporalmente.
    // Evita parpadeos por setState global + refreshKey + FutureBuilder mientras estabilizamos navegación/estado.
    if (!AppConfig.enableRealtimeSubscriptions) return;
    final groupId = widget.groupId;
    final channel = AppData.sb.channel('grupli-group-$groupId-live')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'groups',
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'id', value: groupId),
        callback: (_) => _scheduleRealtimeRefresh('group'),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'group_members',
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'group_id', value: groupId),
        callback: (_) => _scheduleRealtimeRefresh('group'),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'events',
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'group_id', value: groupId),
        callback: (_) => _scheduleRealtimeRefresh('calendar'),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'expenses',
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'group_id', value: groupId),
        callback: (_) => _scheduleRealtimeRefresh('finance'),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'settlement_payments',
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'group_id', value: groupId),
        callback: (_) => _scheduleRealtimeRefresh('finance'),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'tournaments',
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'group_id', value: groupId),
        callback: (_) => _scheduleRealtimeRefresh('tournaments'),
      )
      // Tablas hijas con group_id directo para evitar refrescos globales.
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'event_attendance',
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'group_id', value: groupId),
        callback: (_) => _scheduleRealtimeRefresh('calendar'),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'expense_participants',
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'group_id', value: groupId),
        callback: (_) => _scheduleRealtimeRefresh('finance'),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'tournament_teams',
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'group_id', value: groupId),
        callback: (_) => _scheduleRealtimeRefresh('tournaments'),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'matches',
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'group_id', value: groupId),
        callback: (_) => _scheduleRealtimeRefresh('tournaments'),
      )
      ..subscribe();
    _groupRealtimeChannel = channel;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: groupFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null && snapshot.data!.isNotEmpty) {
          _cachedGroup = snapshot.data;
        }
        if (snapshot.connectionState == ConnectionState.waiting && _cachedGroup == null) {
          return const DirectPage(child: CenterLoader(label: 'Cargando grupo...'));
        }
        if (snapshot.hasError && _cachedGroup == null) {
          return DirectPage(child: ErrorBlock(message: snapshot.error.toString(), onRetry: refresh));
        }
        final group = snapshot.data ?? _cachedGroup ?? <String, dynamic>{'id': widget.groupId, 'name': 'Grupo'};
        final name = AppData.text(group['name'], 'Grupo');
        final pages = [
          GroupDashboardTab(group: group, refreshSeed: dashboardRefreshKey, onNavigateTab: (i) => setState(() => tab = i), onGroupChanged: refresh),
          CalendarTab(groupId: widget.groupId, group: group, refreshSeed: calendarRefreshKey),
          FinancesTab(group: group, refreshSeed: financeRefreshKey),
          TournamentsTab(group: group, refreshSeed: tournamentsRefreshKey),
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
  final VoidCallback? onGroupChanged;
  const GroupDashboardTab({super.key, required this.group, required this.refreshSeed, this.onNavigateTab, this.onGroupChanged});

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
              final nextDayEvents = eventsOnSameDay(upcoming, nextEvent);
              final myDecisionPending = upcoming.where((event) {
                final mine = myAttendanceStatus(event);
                return mine == null || mine == 'maybe';
              }).toList();
              Future<void> openCreateEvent() async {
                final ok = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => CreateEventScreen(group: group)));
                if (ok == true) reload();
              }

              Future<void> openEventDetail(Map<String, dynamic> event) async {
                await Navigator.of(context).push(MaterialPageRoute(builder: (_) => EventDetailScreen(event: event, group: group)));
                reload();
              }

              Future<void> openGroupSettings() async {
                final result = await Navigator.of(context).push<dynamic>(MaterialPageRoute(
                  builder: (_) => GroupSettingsScreen(
                    group: group,
                    onChanged: () {
                      widget.onGroupChanged?.call();
                      reload();
                    },
                  ),
                ));
                if (result == 'deleted') {
                  widget.onGroupChanged?.call();
                  if (context.mounted) Navigator.of(context).pop(true);
                  return;
                }
                widget.onGroupChanged?.call();
                reload();
              }

              void openGroupActions() {
                showGroupQuickActionsSheet(
                  context,
                  group: group,
                  onSettings: openGroupSettings,
                  onMembers: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => MembersScreen(group: group))),
                  onMore: () => widget.onNavigateTab?.call(4),
                  onReport: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SupportTicketScreen(group: group, screen: 'grupo'))),
                );
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
                      GroupAlertBell(
                        group: group,
                        pendingEvents: myDecisionPending,
                        onEventOpen: openEventDetail,
                        onChanged: reload,
                      ),
                      const SizedBox(width: 8),
                      OwnProfileButton(
                        onTap: () async {
                          await Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => ProfileScreen(onChanged: () {
                              widget.onGroupChanged?.call();
                              reload();
                            }),
                          ));
                          widget.onGroupChanged?.call();
                          reload();
                        },
                      ),
                    ]),
                    const SizedBox(height: 12),
                    GroupHeroCard(
                      name: name,
                      coverUrl: AppData.text(group['cover_url']),
                      onEdit: openGroupSettings,
                      onMore: openGroupActions,
                    ),
                    const SizedBox(height: 12),
                    if (snapshot.connectionState == ConnectionState.waiting)
                      const CenterLoader(label: 'Cargando resumen...')
                    else if (snapshot.hasError)
                      ErrorBlock(message: snapshot.error.toString(), onRetry: reload)
                    else ...[
                      SectionHeader(
                        title: 'Próximo plan',
                        action: nextEvent == null ? 'Crear' : 'Calendario',
                        onTap: nextEvent == null ? openCreateEvent : () => widget.onNavigateTab?.call(1),
                      ),
                      const SizedBox(height: 8),
                      if (nextEvent == null)
                        EmptySlim(
                          icon: Icons.event_available_rounded,
                          title: 'Sin quedadas',
                          body: 'Crea un plan para que el grupo pueda confirmar asistencia.',
                        )
                      else if (nextDayEvents.length > 1)
                        DashboardUpcomingEventsCard(events: nextDayEvents, group: group, onChanged: reload)
                      else
                        DashboardEventCard(event: nextEvent, group: group, onChanged: reload),
                      const SizedBox(height: 16),
                      SectionHeader(title: 'Actividad reciente', action: 'Calendario', onTap: () => widget.onNavigateTab?.call(1)),
                      const SizedBox(height: 8),
                      DashboardActivityCard(
                        events: events,
                        expenses: data?.expenses ?? const <Map<String, dynamic>>[],
                        tournaments: data?.tournaments ?? const <Map<String, dynamic>>[],
                        onOpenCalendar: () => widget.onNavigateTab?.call(1),
                        onOpenFinances: () => widget.onNavigateTab?.call(2),
                        onOpenTournaments: () => widget.onNavigateTab?.call(3),
                      ),
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
          PageHeader(title: 'Más', subtitle: 'Invitaciones, miembros y ajustes de $name', leading: false),
          const SizedBox(height: 14),
          InviteAccessCard(groupName: name, code: code),
          const SizedBox(height: 14),
          SectionHeader(title: 'Grupo'),
          const SizedBox(height: 8),
          SettingsRow(
            icon: Icons.groups_rounded,
            title: 'Miembros y admins',
            subtitle: 'Roles, admins y expulsiones seguras',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => MembersScreen(group: group))),
          ),
          SettingsRow(
            icon: Icons.verified_user_rounded,
            title: 'Permisos',
            subtitle: 'Qué puede hacer cada rol',
            onTap: () => showPermissionSheet(context),
          ),
          SettingsRow(
            icon: Icons.settings_rounded,
            title: 'Ajustes del grupo',
            subtitle: 'Nombre, portada y acciones importantes',
            onTap: () async {
              final result = await Navigator.of(context).push<dynamic>(MaterialPageRoute(builder: (_) => GroupSettingsScreen(group: group, onChanged: refresh)));
              if (result == 'deleted') {
                refresh();
                if (context.mounted) Navigator.of(context).pop(true);
              } else {
                refresh();
              }
            },
          ),
          SettingsRow(
            icon: Icons.support_agent_rounded,
            title: 'Reportar problema',
            subtitle: 'Enviar una incidencia sobre este grupo',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SupportTicketScreen(group: group, screen: 'grupo'))),
          ),
          const SizedBox(height: 16),
          PermissionMatrixCard(compact: true),
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




class AddressAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final String hintText;
  const AddressAutocompleteField({
    super.key,
    required this.controller,
    this.onChanged,
    this.hintText = 'Busca una calle, local, pabellón, bar...',
  });

  @override
  State<AddressAutocompleteField> createState() => _AddressAutocompleteFieldState();
}

class _AddressAutocompleteFieldState extends State<AddressAutocompleteField> {
  Timer? _debounce;
  bool loading = false;
  String error = '';
  List<PlaceSuggestion> suggestions = const [];

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onTextChanged(String value) {
    widget.onChanged?.call(value);
    _debounce?.cancel();
    final query = value.trim();
    if (query.length < 3) {
      setState(() {
        suggestions = const [];
        loading = false;
        error = '';
      });
      return;
    }
    setState(() {
      loading = true;
      error = '';
    });
    _debounce = Timer(const Duration(milliseconds: 420), () async {
      try {
        final result = await AddressSearchService.autocomplete(query);
        if (!mounted) return;
        if (widget.controller.text.trim() != query) return;
        setState(() {
          suggestions = result.take(6).toList();
          loading = false;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          suggestions = const [];
          loading = false;
          error = 'No se pudo buscar. Puedes escribir la dirección manualmente.';
        });
      }
    });
  }

  void _select(PlaceSuggestion suggestion) {
    widget.controller.text = suggestion.description;
    widget.controller.selection = TextSelection.collapsed(offset: widget.controller.text.length);
    widget.onChanged?.call(suggestion.description);
    setState(() {
      suggestions = const [];
      loading = false;
      error = '';
    });
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextField(
        controller: widget.controller,
        onChanged: _onTextChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.place_outlined),
          suffixIcon: loading
              ? const Padding(
                  padding: EdgeInsets.all(13),
                  child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : widget.controller.text.trim().isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Borrar dirección',
                      onPressed: () {
                        widget.controller.clear();
                        widget.onChanged?.call('');
                        setState(() {
                          suggestions = const [];
                          error = '';
                        });
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
          hintText: widget.hintText,
          helperText: 'Autocompleta con OpenStreetMap. También puedes escribirlo a mano o pegar un enlace de Maps.',
          helperMaxLines: 2,
        ),
      ),
      if (suggestions.isNotEmpty) ...[
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.line),
            boxShadow: const [BoxShadow(color: Color(0x0F102033), blurRadius: 18, offset: Offset(0, 8))],
          ),
          child: Column(children: [
            for (int i = 0; i < suggestions.length; i++) ...[
              InkWell(
                borderRadius: BorderRadius.vertical(
                  top: i == 0 ? const Radius.circular(18) : Radius.zero,
                  bottom: i == suggestions.length - 1 ? const Radius.circular(18) : Radius.zero,
                ),
                onTap: () => _select(suggestions[i]),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: Row(children: [
                    Container(width: 34, height: 34, decoration: BoxDecoration(color: AppColors.tealSoft, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.location_on_rounded, color: AppColors.teal, size: 18)),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(suggestions[i].description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(suggestions[i].source, style: const TextStyle(color: AppColors.muted, fontSize: 11, fontWeight: FontWeight.w700)),
                    ])),
                  ]),
                ),
              ),
              if (i != suggestions.length - 1) const Divider(height: 1, indent: 56, color: AppColors.line),
            ],
          ]),
        ),
      ],
      if (error.isNotEmpty) ...[
        const SizedBox(height: 7),
        Text(error, style: const TextStyle(color: AppColors.orange, fontWeight: FontWeight.w800, fontSize: 12)),
      ],
    ]);
  }
}

class EventLocationMapCard extends StatelessWidget {
  final String address;
  const EventLocationMapCard({super.key, required this.address});

  @override
  Widget build(BuildContext context) {
    final clean = address.trim();
    if (clean.isEmpty) return const SizedBox.shrink();
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.tealSoft, borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.map_rounded, color: AppColors.teal)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Dirección', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 3),
          Text(clean, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800)),
        ])),
        const SizedBox(width: 10),
        TextButton.icon(
          onPressed: () { openAddressInGoogleMaps(context, clean); },
          icon: const Icon(Icons.navigation_rounded, size: 17),
          label: const Text('Maps', style: TextStyle(fontWeight: FontWeight.w900)),
          style: TextButton.styleFrom(backgroundColor: AppColors.teal, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        ),
      ]),
    );
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
  bool repeatEnabled = false;
  String repeatFrequency = 'weekly';
  int repeatOccurrences = 8;
  String editScope = 'single';

  bool get editing => widget.event != null;
  bool get editingRoutine => editing && eventIsRoutine(widget.event!);

  String get frequencyLabel {
    switch (repeatFrequency) {
      case 'biweekly':
        return 'cada 2 semanas';
      case 'monthly':
        return 'cada mes';
      default:
        return 'cada semana';
    }
  }

  String get routinePreview {
    if (!repeatEnabled) return 'Evento único';
    final first = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    return '${_cap(frequencyLabel)} · $repeatOccurrences eventos · empieza ${longDateTime(first)}';
  }

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
    if (!editing && repeatEnabled && repeatOccurrences < 2) {
      await showToast(context, 'Una rutina necesita al menos 2 eventos.', danger: true);
      return;
    }

    final start = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() => loading = true);
    try {
      if (editing) {
        await AppData.updateEventWithScope(widget.event!['id'].toString(), editScope, cleanTitle, start, location.text, notes.text, minPeople);
      } else if (repeatEnabled) {
        final created = await AppData.createEventSeries(
          widget.group['id'].toString(),
          cleanTitle,
          start,
          location.text,
          notes.text,
          minPeople,
          repeatFrequency,
          repeatOccurrences,
        );
        if (mounted) await showToast(context, 'Rutina creada: $created eventos generados.');
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
        repeatLabel: repeatEnabled ? routinePreview : (editingRoutine ? eventRoutineBadge(widget.event!) : null),
      ),
      if (editingRoutine) ...[
        const SizedBox(height: 14),
        EventScopeCard(
          title: 'Editar rutina',
          value: editScope,
          onChanged: (value) => setState(() => editScope = value),
        ),
      ],
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
        FieldLabel('Dirección o lugar'),
        AddressAutocompleteField(
          controller: location,
          onChanged: (_) => setState(() {}),
          hintText: 'Busca una calle, local, pabellón, bar...',
        ),
      ])),
      if (!editing) ...[
        const SizedBox(height: 14),
        AppCard(
          color: repeatEnabled ? AppColors.tealSoft : AppColors.white,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: repeatEnabled ? AppColors.teal : AppColors.surface, borderRadius: BorderRadius.circular(15), border: Border.all(color: AppColors.line)),
                child: Icon(Icons.repeat_rounded, color: repeatEnabled ? Colors.white : AppColors.teal, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Convertir en rutina', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 3),
                Text('Ideal para partido todos los jueves, entreno semanal o quedadas fijas.', style: Theme.of(context).textTheme.bodyMedium),
              ])),
              Switch.adaptive(value: repeatEnabled, activeColor: AppColors.teal, onChanged: (v) => setState(() => repeatEnabled = v)),
            ]),
            if (repeatEnabled) ...[
              const SizedBox(height: 14),
              FieldLabel('Frecuencia'),
              Wrap(spacing: 8, runSpacing: 8, children: [
                RoutineChoice(label: 'Cada semana', selected: repeatFrequency == 'weekly', onTap: () => setState(() => repeatFrequency = 'weekly')),
                RoutineChoice(label: 'Cada 2 semanas', selected: repeatFrequency == 'biweekly', onTap: () => setState(() => repeatFrequency = 'biweekly')),
                RoutineChoice(label: 'Cada mes', selected: repeatFrequency == 'monthly', onTap: () => setState(() => repeatFrequency = 'monthly')),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Eventos a generar', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 3),
                  Text(routinePreview, style: Theme.of(context).textTheme.bodyMedium),
                ])),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(onPressed: () => setState(() => repeatOccurrences = max(2, repeatOccurrences - 1)), icon: const Icon(Icons.remove_rounded)),
                    Text(repeatOccurrences.toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.ink)),
                    IconButton(onPressed: () => setState(() => repeatOccurrences = min(52, repeatOccurrences + 1)), icon: const Icon(Icons.add_rounded)),
                  ]),
                ),
              ]),
              const SizedBox(height: 12),
              RoutineInfoBox(text: 'Se crearán $repeatOccurrences fechas conectadas en una misma rutina. Después podrás editar solo una fecha, esta y futuras, o toda la rutina.'),
            ],
          ]),
        ),
      ],
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
      PrimaryButton(
        label: editing ? 'Guardar cambios' : (repeatEnabled ? 'Crear rutina' : 'Crear evento'),
        icon: editing ? Icons.save_rounded : (repeatEnabled ? Icons.repeat_rounded : Icons.add_rounded),
        loading: loading,
        onTap: save,
      ),
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
    String scope = 'single';
    final isRoutine = eventIsRoutine(event);
    if (isRoutine) {
      final selectedScope = await showRoutineScopeDialog(context, title: 'Cancelar rutina', actionLabel: 'Cancelar');
      if (selectedScope == null) return;
      scope = selectedScope;
    } else {
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
    }
    try {
      await AppData.cancelEventWithScope(event['id'].toString(), scope);
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
        final canManageEvent = AppData.text(event['created_by']).isNotEmpty && AppData.text(event['created_by']) == (AppData.user?.id ?? '');

        return DirectPage(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          PageHeader(title: AppData.text(event['title'], 'Evento'), subtitle: AppData.text(widget.group['name'], 'Grupo'), leading: true),
          const SizedBox(height: 12),
          PremiumEventDetailHero(event: event, date: date, yes: yes, minPeople: minPeople),
          if (AppData.text(event['location']).isNotEmpty) ...[
            const SizedBox(height: 12),
            EventLocationMapCard(address: AppData.text(event['location'])),
          ],
          if (eventIsRoutine(event)) ...[
            const SizedBox(height: 12),
            RoutineInfoBox(text: '${eventRoutineBadge(event)} · al editar o cancelar podrás aplicar el cambio a una fecha, a futuras fechas o a toda la rutina.'),
          ],
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
          if (AppData.text(event['location']).isNotEmpty) ...[
            const SizedBox(height: 18),
            PrimaryButton(label: 'Ir a Google Maps', icon: Icons.navigation_rounded, onTap: () { openAddressInGoogleMaps(context, AppData.text(event['location'])); }),
          ],
          if (canManageEvent) ...[
            const SizedBox(height: 18),
            SecondaryButton(label: 'Editar evento', icon: Icons.edit_rounded, onTap: () => editEvent(event)),
            const SizedBox(height: 10),
            DangerButton(label: 'Cancelar evento', icon: Icons.event_busy_rounded, onTap: () => cancelEvent(event)),
          ],
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
  final String groupId;
  final Map<String, dynamic> group;
  final int refreshSeed;
  const CalendarTab({super.key, required this.groupId, required this.group, required this.refreshSeed});
  @override State<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<CalendarTab> {
  DateTime month = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime selected = DateTime.now();
  int viewMode = 0; // 0 semana, 1 mes
  bool loading = true;
  bool refreshing = false;
  String? errorMessage;
  List<Map<String, dynamic>> events = <Map<String, dynamic>>[];
  int _loadToken = 0;
  Timer? _reloadDebounce;

  String get groupId => widget.groupId.trim().isNotEmpty ? widget.groupId.trim() : AppData.text(widget.group['id']);

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    _reloadDebounce?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CalendarTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshSeed != widget.refreshSeed || oldWidget.groupId != widget.groupId) {
      _scheduleSoftReload();
    }
  }

  void _scheduleSoftReload() {
    _reloadDebounce?.cancel();
    _reloadDebounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) load(silent: true);
    });
  }

  Map<String, List<Map<String, dynamic>>> _eventsByDay(List<Map<String, dynamic>> source) {
    final map = <String, List<Map<String, dynamic>>>{};
    for (final event in source) {
      final date = DateTime.tryParse(event['starts_at']?.toString() ?? '')?.toLocal();
      if (date == null) continue;
      final key = calendarDayKey(date);
      (map[key] ??= <Map<String, dynamic>>[]).add(event);
    }
    for (final list in map.values) {
      list.sort((a, b) {
        final da = DateTime.tryParse(a['starts_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        final db = DateTime.tryParse(b['starts_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        return da.compareTo(db);
      });
    }
    return map;
  }

  List<Map<String, dynamic>> _eventsForDay(Map<String, List<Map<String, dynamic>>> index, DateTime day) {
    return List<Map<String, dynamic>>.from(index[calendarDayKey(day)] ?? const <Map<String, dynamic>>[]);
  }

  int _eventsInMonthFromIndex(Map<String, List<Map<String, dynamic>>> index, DateTime targetMonth) {
    var count = 0;
    for (final entry in index.entries) {
      final date = DateTime.tryParse(entry.key);
      if (date != null && date.year == targetMonth.year && date.month == targetMonth.month) {
        count += entry.value.length;
      }
    }
    return count;
  }

  Future<void> load({bool silent = false}) async {
    final id = groupId;
    final token = ++_loadToken;
    if (id.isEmpty) {
      if (!mounted) return;
      setState(() {
        loading = false;
        refreshing = false;
        errorMessage = 'No se ha podido identificar este grupo. Vuelve a Mis grupos y entra otra vez.';
        events = <Map<String, dynamic>>[];
      });
      return;
    }

    if (mounted) {
      setState(() {
        if (!silent && events.isEmpty) {
          loading = true;
        } else {
          refreshing = true;
        }
        errorMessage = null;
      });
    }

    try {
      final rows = await AppData.events(id).timeout(const Duration(seconds: 12));
      if (!mounted || token != _loadToken) return;
      setState(() {
        events = rows;
        loading = false;
        refreshing = false;
        errorMessage = null;
      });
    } catch (e) {
      if (!mounted || token != _loadToken) return;
      setState(() {
        loading = false;
        refreshing = false;
        errorMessage = humanError(e);
      });
    }
  }

  Future<void> reload() async => load(silent: events.isNotEmpty);

  Future<void> createFor(DateTime day) async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => CreateEventScreen(group: widget.group, initialDate: day)),
    );
    if (ok == true) await load(silent: true);
  }

  Future<void> openEvent(Map<String, dynamic> event) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => EventDetailScreen(event: event, group: widget.group)));
    await load(silent: true);
  }

  @override
  Widget build(BuildContext context) {
    final visibleEvents = events
        .where((e) => AppData.text(e['status'], 'active') != 'cancelled')
        .toList();
    visibleEvents.sort((a, b) {
      final da = DateTime.tryParse(a['starts_at']?.toString() ?? '') ?? DateTime.now();
      final db = DateTime.tryParse(b['starts_at']?.toString() ?? '') ?? DateTime.now();
      return da.compareTo(db);
    });

    final byDay = _eventsByDay(visibleEvents);
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final upcomingEvents = visibleEvents.where((event) {
      final date = DateTime.tryParse(event['starts_at']?.toString() ?? '')?.toLocal();
      if (date == null) return false;
      final eventDay = DateTime(date.year, date.month, date.day);
      return !eventDay.isBefore(today);
    }).toList();

    final selectedEvents = _eventsForDay(byDay, selected);
    final weekStart = today;
    final weekDays = List<DateTime>.generate(7, (i) => DateTime(weekStart.year, weekStart.month, weekStart.day).add(Duration(days: i)));
    final weekEventsCount = weekDays.fold<int>(0, (sum, day) => sum + _eventsForDay(byDay, day).length);

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: AppColors.navAgenda,
        onRefresh: reload,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 112),
          children: [
            PageHeader(title: 'Agenda', subtitle: 'Planes, rutinas y asistencia del grupo.', leading: false),
            const SizedBox(height: 12),
            if (loading && events.isEmpty) ...[
              const CenterLoader(label: 'Cargando agenda...'),
              const SizedBox(height: 12),
            ],
            if (errorMessage != null) ...[
              ErrorBlock(message: errorMessage!, onRetry: () { reload(); }),
              const SizedBox(height: 12),
            ],
            if (refreshing) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: const LinearProgressIndicator(minHeight: 3, color: AppColors.navAgenda, backgroundColor: AppColors.line),
              ),
              const SizedBox(height: 10),
            ],
            AgendaViewSwitch(
              index: viewMode,
              onChanged: (i) => setState(() => viewMode = i),
            ),
            const SizedBox(height: 12),
            if (viewMode == 0) ...[
              AgendaWeekHeader(
                selected: selected,
                weekEvents: weekEventsCount,
                onPrevious: () {
                  final next = selected.subtract(const Duration(days: 7));
                  setState(() {
                    selected = next;
                    month = DateTime(next.year, next.month);
                  });
                },
                onNext: () {
                  final next = selected.add(const Duration(days: 7));
                  setState(() {
                    selected = next;
                    month = DateTime(next.year, next.month);
                  });
                },
                onToday: () {
                  final now = DateTime.now();
                  setState(() {
                    selected = DateTime(now.year, now.month, now.day);
                    month = DateTime(now.year, now.month);
                  });
                },
              ),
              const SizedBox(height: 10),
              PremiumWeekStrip(
                days: weekDays,
                selected: selected,
                eventsByDay: byDay,
                onSelect: (day) => setState(() {
                  selected = day;
                  month = DateTime(day.year, day.month);
                }),
              ),
            ] else ...[
              AgendaMonthHeader(
                month: month,
                eventsCount: _eventsInMonthFromIndex(byDay, month),
                onPrevious: () => setState(() => month = DateTime(month.year, month.month - 1)),
                onNext: () => setState(() => month = DateTime(month.year, month.month + 1)),
                onToday: () {
                  final now = DateTime.now();
                  setState(() {
                    selected = DateTime(now.year, now.month, now.day);
                    month = DateTime(now.year, now.month);
                  });
                },
              ),
              const SizedBox(height: 10),
              RepaintBoundary(
                child: PremiumMonthCalendar(
                  month: month,
                  selected: selected,
                  eventsByDay: byDay,
                  onSelect: (d) => setState(() {
                    selected = d;
                    month = DateTime(d.year, d.month);
                  }),
                ),
              ),
            ],
            const SizedBox(height: 10),
            EventTypeLegend(events: visibleEvents),
            const SizedBox(height: 16),
            if (selectedEvents.isNotEmpty) ...[
              SectionHeader(title: 'Planes del día', action: '${selectedEvents.length}'),
              const SizedBox(height: 10),
              AgendaSameDayCompactCard(events: selectedEvents, group: widget.group, onChanged: reload, title: agendaSelectedDayTitle(selected)),
              const SizedBox(height: 18),
            ],
            SectionHeader(title: selectedEvents.isEmpty ? 'Próximos planes' : 'Siguientes planes', action: '${upcomingEvents.length}'),
            const SizedBox(height: 10),
            if (upcomingEvents.isEmpty)
              PremiumAgendaEmptyState(
                hasAnyEvents: visibleEvents.isNotEmpty,
                selected: selected,
                onCreate: () => createFor(selected),
              )
            else
              AgendaGroupedUpcomingList(
                events: upcomingEvents,
                group: widget.group,
                onChanged: reload,
                excludeDay: selectedEvents.isNotEmpty ? selected : null,
                onCreate: () => createFor(selected),
              ),
          ],
        ),
      ),
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
  int financeSection = 0;
  bool savingSettlement = false;
  bool cancellingSettlement = false;

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

  Future<void> markSettlementPaid(SettlementDebt debt) async {
    final confirmed = await confirmAction(
      context,
      title: 'Liquidar pago',
      body: '${debt.fromName} pagó a ${debt.toName} ${money(debt.amount)}. Esto actualizará el balance neto del grupo.',
      confirmLabel: 'Liquidar',
    );
    if (confirmed != true) return;

    setState(() => savingSettlement = true);
    try {
      await AppData.createSettlementPayment(widget.group['id'].toString(), debt.fromId, debt.toId, debt.amount);
      reload();
      if (mounted) await showToast(context, 'Liquidación registrada.');
    } catch (e) {
      if (mounted) await showToast(context, humanError(e), danger: true);
    } finally {
      if (mounted) setState(() => savingSettlement = false);
    }
  }

  Future<void> undoSettlementPayment(Map<String, dynamic> payment) async {
    final amount = AppData.doubleValue(payment['amount']);
    final confirmed = await confirmAction(
      context,
      title: 'Deshacer liquidación',
      body: 'El pago de ${money(amount)} volverá a contarse como pendiente en el balance del grupo.',
      confirmLabel: 'Deshacer',
      danger: true,
    );
    if (confirmed != true) return;

    setState(() => cancellingSettlement = true);
    try {
      await AppData.cancelSettlementPayment(AppData.text(payment['id']));
      reload();
      if (mounted) await showToast(context, 'Liquidación deshecha.');
    } catch (e) {
      if (mounted) await showToast(context, humanError(e), danger: true);
    } finally {
      if (mounted) setState(() => cancellingSettlement = false);
    }
  }


  void openBalanceDetail(String userId, _FinanceData data) {
    final summary = data.summary;
    final name = summary.names[userId] ?? financeMemberName(userId, data.members);
    final avatar = summary.avatars[userId] ?? financeMemberAvatarUrl(userId, data.members);
    final balance = summary.balances[userId] ?? 0;
    final toPay = summary.settlements.where((d) => d.fromId == userId).toList();
    final toReceive = summary.settlements.where((d) => d.toId == userId).toList();
    final relatedExpenses = data.expenses.where((expense) {
      final paidBy = AppData.text(expense['paid_by']);
      if (paidBy == userId) return true;
      return expenseParticipants(expense).any((p) => AppData.text(p['user_id']) == userId);
    }).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .82,
        minChildSize: .45,
        maxChildSize: .94,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          children: [
            Row(children: [
              ProfileAvatar(name: name, avatarUrl: avatar, radius: 25),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 3),
                Text(
                  balance > .01 ? 'Le deben ${money(balance)}' : balance < -.01 ? 'Debe ${money(balance.abs())}' : 'Está a cero',
                  style: TextStyle(color: balance > .01 ? AppColors.green : balance < -.01 ? AppColors.red : AppColors.muted, fontWeight: FontWeight.w900),
                ),
              ])),
            ]),
            const SizedBox(height: 18),
            if (toPay.isEmpty && toReceive.isEmpty)
              EmptySlim(icon: Icons.verified_rounded, title: 'Sin pagos pendientes', body: 'Esta persona no tiene que mover dinero ahora mismo.')
            else ...[
              if (toPay.isNotEmpty) ...[
                SectionHeader(title: 'Tiene que pagar', action: '${toPay.length}'),
                const SizedBox(height: 8),
                AppCard(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(children: [
                    for (int i = 0; i < toPay.length; i++) ...[
                      SettlementPaymentRow(debt: toPay[i], onPaid: savingSettlement ? null : () {
                        Navigator.pop(context);
                        markSettlementPaid(toPay[i]);
                      }),
                      if (i != toPay.length - 1) const Divider(height: 1, indent: 76, color: AppColors.line),
                    ],
                  ]),
                ),
                const SizedBox(height: 14),
              ],
              if (toReceive.isNotEmpty) ...[
                SectionHeader(title: 'Tiene que recibir', action: '${toReceive.length}'),
                const SizedBox(height: 8),
                AppCard(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(children: [
                    for (int i = 0; i < toReceive.length; i++) ...[
                      SettlementPaymentRow(debt: toReceive[i], onPaid: savingSettlement ? null : () {
                        Navigator.pop(context);
                        markSettlementPaid(toReceive[i]);
                      }),
                      if (i != toReceive.length - 1) const Divider(height: 1, indent: 76, color: AppColors.line),
                    ],
                  ]),
                ),
                const SizedBox(height: 14),
              ],
            ],
            SectionHeader(title: 'Movimientos relacionados', action: '${relatedExpenses.length}'),
            const SizedBox(height: 8),
            if (relatedExpenses.isEmpty)
              EmptySlim(icon: Icons.receipt_long_rounded, title: 'Sin gastos relacionados', body: 'No aparece en ningún gasto del grupo.')
            else
              ...relatedExpenses.take(8).map((expense) => ExpenseCard(
                expense: expense,
                members: data.members,
                onTap: () async {
                  Navigator.pop(context);
                  final ok = await Navigator.of(this.context).push<bool>(MaterialPageRoute(builder: (_) => ExpenseDetailScreen(expense: expense, members: data.members)));
                  if (ok == true) reload();
                },
              )),
          ],
        ),
      ),
    );
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
            final hasMovements = data.expenses.isNotEmpty || data.settlementPayments.isNotEmpty;
            final balanceEntries = summary.sortedBalances;

            return RefreshIndicator(
              color: AppColors.green,
              onRefresh: () async => reload(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 112),
                children: [
                  PageHeader(title: 'Finanzas', subtitle: 'Movimientos y saldos claros, sin pestañas de más.', leading: false),
                  const SizedBox(height: 14),
                  FinanceHeroCard(summary: summary, onCreate: openCreate),
                  const SizedBox(height: 12),
                  FinanceSegmentedTabs(index: financeSection, onChanged: (i) => setState(() => financeSection = i > 1 ? 1 : i)),
                  const SizedBox(height: 14),
                  if (financeSection == 0) ...[
                    SectionHeader(title: 'Movimientos', action: hasMovements ? '${data.expenses.length + data.settlementPayments.length}' : '0'),
                    const SizedBox(height: 8),
                    if (!hasMovements)
                      EmptyBlock(icon: Icons.receipt_long_rounded, title: 'Aún no hay movimientos', body: 'Añade el primer gasto. Aquí verás gastos y pagos registrados, como en reparto de gastos.')
                    else ...[
                      if (data.expenses.isNotEmpty) ...[
                        SectionHeader(title: 'Gastos pagados', action: 'Total ${money(summary.totalExpenses)}'),
                        const SizedBox(height: 8),
                        ...data.expenses.map((e) => ExpenseCard(
                          expense: e,
                          members: data.members,
                          onTap: () async {
                            final ok = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => ExpenseDetailScreen(expense: e, members: data.members)));
                            if (ok == true) reload();
                          },
                        )),
                      ],
                      if (data.settlementPayments.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        SectionHeader(title: 'Pagos registrados', action: '${data.settlementPayments.length}'),
                        const SizedBox(height: 8),
                        AppCard(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(children: [
                            for (int i = 0; i < data.settlementPayments.length; i++) ...[
                              SettlementHistoryRow(
                                payment: data.settlementPayments[i],
                                members: data.members,
                                onCancel: cancellingSettlement ? null : () => undoSettlementPayment(data.settlementPayments[i]),
                              ),
                              if (i != data.settlementPayments.length - 1) const Divider(height: 1, indent: 76, color: AppColors.line),
                            ],
                          ]),
                        ),
                      ],
                    ],
                  ] else ...[
                    FinanceAutoBalanceCard(summary: summary, openCount: data.expenses.length, settledCount: data.settlementPayments.length),
                    const SizedBox(height: 12),
                    FinanceBalanceBarsCard(summary: summary),
                    const SizedBox(height: 16),
                    SectionHeader(title: 'Saldos', action: balanceEntries.isEmpty ? 'Todo a cero' : '${balanceEntries.length} personas'),
                    const SizedBox(height: 8),
                    if (balanceEntries.isEmpty)
                      EmptyBlock(icon: Icons.verified_rounded, title: 'Todo queda a cero', body: 'No hay deudas pendientes entre miembros.')
                    else
                      AppCard(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(children: [
                          for (int i = 0; i < balanceEntries.length; i++) ...[
                            FinanceBalanceMemberRow(
                              userId: balanceEntries[i].key,
                              name: summary.names[balanceEntries[i].key] ?? 'Miembro',
                              avatarUrl: summary.avatars[balanceEntries[i].key] ?? '',
                              balance: balanceEntries[i].value,
                              onTap: () => openBalanceDetail(balanceEntries[i].key, data),
                            ),
                            if (i != balanceEntries.length - 1) const Divider(height: 1, indent: 76, color: AppColors.line),
                          ],
                        ]),
                      ),
                    const SizedBox(height: 14),
                    SectionHeader(title: 'Pagos recomendados', action: summary.settlements.isEmpty ? '0' : '${summary.settlements.length}'),
                    const SizedBox(height: 8),
                    if (summary.settlements.isEmpty)
                      EmptySlim(icon: Icons.verified_rounded, title: 'No hay nada que pagar', body: 'Los saldos del grupo están compensados.')
                    else
                      AppCard(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(children: [
                          for (int i = 0; i < summary.settlements.length; i++) ...[
                            SettlementPaymentRow(
                              debt: summary.settlements[i],
                              onPaid: savingSettlement ? null : () => markSettlementPaid(summary.settlements[i]),
                            ),
                            if (i != summary.settlements.length - 1) const Divider(height: 1, indent: 76, color: AppColors.line),
                          ],
                        ]),
                      ),
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
            backgroundColor: AppColors.green,
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
  final Map<String, dynamic>? expense;
  const CreateExpenseScreen({super.key, required this.groupId, this.expense});
  bool get editing => expense != null;
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
    final editingExpense = widget.expense;
    if (editingExpense != null) {
      concept.text = AppData.text(editingExpense['concept']);
      final value = AppData.doubleValue(editingExpense['amount']);
      amount.text = value > 0 ? value.toStringAsFixed(2).replaceAll('.', ',') : '';
      note.text = AppData.text(editingExpense['note']);
      splitMode = 'custom';
    }
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
    final editingExpense = widget.expense;
    if (editingExpense != null) {
      paidBy = AppData.text(editingExpense['paid_by']);
      final participants = expenseParticipants(editingExpense);
      selected
        ..clear()
        ..addAll(participants.map((p) => p['user_id'].toString()));
      if (paidBy != null && paidBy!.isNotEmpty) selected.add(paidBy!);
      for (final member in members) {
        final id = member['user_id'].toString();
        final participant = participants.where((p) => p['user_id']?.toString() == id).toList();
        final controller = TextEditingController();
        if (participant.isNotEmpty) {
          final share = AppData.doubleValue(participant.first['share_amount']);
          controller.text = share > 0 ? share.toStringAsFixed(2).replaceAll('.', ',') : '';
        }
        customShares[id] = controller;
      }
    } else {
      paidBy = members.any((m) => m['user_id']?.toString() == AppData.user?.id) ? AppData.user?.id : members.first['user_id'].toString();
      selected.addAll(members.map((m) => m['user_id'].toString()));
      for (final member in members) {
        final id = member['user_id'].toString();
        customShares[id] = TextEditingController();
      }
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
    final ids = selected.toList();
    if (ids.isEmpty) return {};
    final totalCents = (amountValue * 100).round();
    final base = totalCents ~/ ids.length;
    var remainder = totalCents - (base * ids.length);
    final result = <String, double>{};
    for (final id in ids) {
      final cents = base + (remainder > 0 ? 1 : 0);
      if (remainder > 0) remainder--;
      result[id] = double.parse((cents / 100).toStringAsFixed(2));
    }
    return result;
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
      if (widget.editing) {
        await AppData.updateExpenseWithShares(widget.expense!['id'].toString(), concept.text, value, paidBy!, sharesFor(members), note.text);
      } else {
        await AppData.createExpenseWithShares(widget.groupId, concept.text, value, paidBy!, sharesFor(members), note.text);
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
    return DirectPage(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeader(title: widget.editing ? 'Editar gasto' : 'Nuevo gasto', subtitle: widget.editing ? 'Ajusta importe, pagador o reparto.' : 'Importe, pagador y reparto en pocos pasos.', leading: true),
      const SizedBox(height: 18),
      AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 46, height: 46, decoration: BoxDecoration(color: AppColors.tealSoft, borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.receipt_long_rounded, color: AppColors.teal)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.editing ? 'Actualizar gasto' : '¿Qué se ha pagado?', style: Theme.of(context).textTheme.titleMedium),
            Text(widget.editing ? 'Los cambios recalculan los saldos al guardar.' : 'Elige quién pagó y cómo se reparte.', style: Theme.of(context).textTheme.bodyMedium),
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
          if (snapshot.hasError) return ErrorBlock(message: snapshot.error.toString(), onRetry: () => setState(() { membersFuture = AppData.members(widget.groupId); }));
          if (members.isEmpty) return EmptyBlock(icon: Icons.groups_rounded, title: 'No hay miembros', body: 'Añade miembros al grupo para poder repartir gastos.');
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              FieldLabel('Pagado por'),
              DropdownButtonFormField<String>(
                value: paidBy,
                items: members.map((m) => DropdownMenuItem(
                  value: m['user_id'].toString(),
                  child: Row(children: [
                    ProfileAvatar(name: memberName(m), avatarUrl: memberAvatarUrl(m), radius: 14),
                    const SizedBox(width: 8),
                    Text(memberName(m)),
                  ]),
                )).toList(),
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
                  avatar: ProfileAvatar(name: memberName(m), avatarUrl: memberAvatarUrl(m), radius: 12),
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
                      Expanded(child: Row(children: [
                        ProfileAvatar(name: memberName(m), avatarUrl: memberAvatarUrl(m), radius: 15),
                        const SizedBox(width: 8),
                        Expanded(child: Text(memberName(m), overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900))),
                      ])),
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
          return PrimaryButton(label: widget.editing ? 'Guardar cambios' : 'Guardar gasto', loading: loading, onTap: () => save(members));
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

  Future<void> editExpense(Map<String, dynamic> expense) async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CreateExpenseScreen(
          groupId: AppData.text(expense['group_id']),
          expense: expense,
        ),
      ),
    );
    if (ok == true && mounted) Navigator.pop(context, true);
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
          ProfileAvatar(name: financeMemberName(paidBy, widget.members), avatarUrl: financeMemberAvatarUrl(paidBy, widget.members), radius: 22),
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
            ProfileAvatar(name: financeMemberName(userId, widget.members), avatarUrl: financeMemberAvatarUrl(userId, widget.members), radius: 17),
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
      SecondaryButton(label: 'Editar gasto', icon: Icons.edit_rounded, onTap: loading ? () {} : () => editExpense(expense)),
      const SizedBox(height: 10),
      if (unpaid > .01) PrimaryButton(label: 'Marcar gasto liquidado', icon: Icons.verified_rounded, loading: loading, onTap: () => run(() => AppData.markExpenseSettled(expenseId))),
      if (unpaid <= .01 || status == 'paid') ...[
        SecondaryButton(label: 'Reabrir pagos', icon: Icons.restart_alt_rounded, onTap: () => run(() => AppData.reopenExpense(expenseId))),
      ],
      const SizedBox(height: 10),
      DangerButton(label: 'Eliminar gasto', icon: Icons.delete_outline_rounded, onTap: () => run(() => AppData.deleteExpense(expenseId))),
    ]));
  }
}


class FinanceSegmentedTabs extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  const FinanceSegmentedTabs({super.key, required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const icons = [Icons.receipt_long_rounded, Icons.account_balance_wallet_rounded];
    const labels = ['Movimientos', 'Saldos'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.faint, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.line)),
      child: Row(children: List.generate(labels.length, (i) {
        final selected = index == i;
        return Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(15),
            onTap: () => onChanged(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: selected ? AppColors.green : Colors.transparent,
                borderRadius: BorderRadius.circular(15),
                boxShadow: selected ? const [BoxShadow(color: Color(0x1A073A57), blurRadius: 14, offset: Offset(0, 6))] : null,
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(icons[i], color: selected ? Colors.white : AppColors.muted, size: 17),
                const SizedBox(width: 6),
                Text(labels[i], style: TextStyle(color: selected ? Colors.white : AppColors.ink, fontWeight: FontWeight.w900, fontSize: 12)),
              ]),
            ),
          ),
        );
      })),
    );
  }
}

class FinanceHeroCard extends StatelessWidget {
  final FinanceSummary summary;
  final VoidCallback onCreate;
  const FinanceHeroCard({super.key, required this.summary, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final clean = summary.pendingAmount <= .01;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      color: AppColors.greenDark,
      child: Stack(children: [
        Positioned(right: -6, top: -4, child: Icon(Icons.stacked_line_chart_rounded, size: 92, color: Colors.white.withOpacity(.06))),
        Positioned(right: 22, top: 18, child: Icon(Icons.savings_rounded, size: 54, color: Colors.white.withOpacity(.18))),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(color: Colors.white.withOpacity(.12), borderRadius: BorderRadius.circular(15)),
            child: Icon(clean ? Icons.verified_rounded : Icons.account_balance_wallet_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_financeMainTitle(summary), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900, letterSpacing: -.25)),
            const SizedBox(height: 4),
            Text(clean ? 'Nadie debe dinero.' : '${summary.settlements.length} pago${summary.settlements.length == 1 ? '' : 's'} mínimo${summary.settlements.length == 1 ? '' : 's'} para dejar todo a cero', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xDFFFFFFF), fontSize: 12.5, fontWeight: FontWeight.w700)),
          ])),
          const SizedBox(width: 10),
          SizedBox(
            height: 40,
            child: TextButton.icon(
              onPressed: onCreate,
              style: TextButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.greenDark, padding: const EdgeInsets.symmetric(horizontal: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Gasto', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _HeroFinanceMetric(label: 'Gastado', value: money(summary.totalExpenses))),
          const SizedBox(width: 8),
          Expanded(child: _HeroFinanceMetric(label: 'Pendiente', value: money(summary.pendingAmount))),
          const SizedBox(width: 8),
          Expanded(child: _HeroFinanceMetric(label: 'A mover', value: money(summary.settlementAmount))),
        ]),
        ]),
      ]),
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

class FinanceMyStatusCard extends StatelessWidget {
  final FinanceSummary summary;
  final List<SettlementDebt> settlements;
  final VoidCallback onCreate;
  const FinanceMyStatusCard({super.key, required this.summary, required this.settlements, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final color = summary.myNet > 0.01 ? AppColors.green : summary.myNet < -0.01 ? AppColors.red : AppColors.teal;
    final title = summary.myNet > 0.01
        ? 'Te deben ${money(summary.myNet)}'
        : summary.myNet < -0.01
            ? 'Debes ${money(-summary.myNet)}'
            : 'Tú estás a cero';
    final body = settlements.isEmpty
        ? 'No tienes pagos pendientes. Puedes revisar abajo el balance del grupo.'
        : settlements.map((d) => d.fromId == AppData.user?.id ? 'Pagas a ${d.toName}: ${money(d.amount)}' : '${d.fromName} te paga: ${money(d.amount)}').join(' · ');

    return AppCard(
      padding: const EdgeInsets.all(15),
      color: color.withOpacity(.09),
      child: Row(children: [
        Container(width: 44, height: 44, decoration: BoxDecoration(color: color.withOpacity(.14), borderRadius: BorderRadius.circular(15)), child: Icon(summary.myNet.abs() <= .01 ? Icons.check_circle_rounded : Icons.payments_rounded, color: color, size: 23)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(body, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800, height: 1.25)),
        ])),
        const SizedBox(width: 8),
        IconButton(onPressed: onCreate, icon: Icon(Icons.add_circle_rounded, color: color), tooltip: 'Añadir gasto'),
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

class FinanceOptimizerInfoCard extends StatelessWidget {
  final FinanceSummary summary;
  const FinanceOptimizerInfoCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final hasPending = summary.settlements.isNotEmpty;
    final title = hasPending ? 'Pagos mínimos para cuadrar el grupo' : 'Sin deudas pendientes';
    final body = hasPending
        ? 'Hay ${summary.peopleWithBalance} personas con saldo. Grupli calcula el balance neto del grupo y propone ${summary.settlements.length} pago${summary.settlements.length == 1 ? '' : 's'} para dejarlo a cero, aunque el grupo tenga muchos miembros.'
        : 'Todos los balances están compensados. No hace falta mover dinero ahora mismo.';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: hasPending ? AppColors.tealSoft : AppColors.greenSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: (hasPending ? AppColors.teal : AppColors.green).withOpacity(.16)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: Colors.white.withOpacity(.78), borderRadius: BorderRadius.circular(14)),
          child: Icon(hasPending ? Icons.auto_awesome_rounded : Icons.verified_rounded, color: hasPending ? AppColors.teal : AppColors.green),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 14.5)),
          const SizedBox(height: 4),
          Text(body, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800, height: 1.25, fontSize: 12.5)),
        ])),
      ]),
    );
  }
}


class FinanceBalanceMemberRow extends StatelessWidget {
  final String userId;
  final String name;
  final String avatarUrl;
  final double balance;
  final VoidCallback onTap;
  const FinanceBalanceMemberRow({
    super.key,
    required this.userId,
    required this.name,
    required this.avatarUrl,
    required this.balance,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final positive = balance > .01;
    final negative = balance < -.01;
    final color = positive ? AppColors.green : negative ? AppColors.red : AppColors.muted;
    final title = positive ? 'Le deben' : negative ? 'Debe' : 'A cero';
    final amount = money(balance.abs());
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          ProfileAvatar(name: name, avatarUrl: avatarUrl, radius: 22),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
            const SizedBox(height: 3),
            Text('Toca para ver quién debe y por qué', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 12)),
          ])),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12)),
            const SizedBox(height: 2),
            Text(amount, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 15)),
          ]),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        ]),
      ),
    );
  }
}

class FinanceBalanceBarsCard extends StatelessWidget {
  final FinanceSummary summary;
  const FinanceBalanceBarsCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final entries = summary.balances.entries.toList()
      ..sort((a, b) => b.value.abs().compareTo(a.value.abs()));
    final visible = entries.where((e) => e.value.abs() > .01).toList();
    final maxValue = visible.isEmpty ? 1.0 : visible.map((e) => e.value.abs()).reduce(max);
    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 42, height: 42, decoration: BoxDecoration(color: AppColors.tealSoft, borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.bar_chart_rounded, color: AppColors.teal)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Saldos del grupo', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 3),
            Text('${summary.creditorsCount} cobran · ${summary.debtorsCount} deben · verde cobra / rojo paga', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800, fontSize: 12)),
          ])),
        ]),
        const SizedBox(height: 14),
        if (visible.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Text('Todos están a cero. No hay dinero pendiente.', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800)),
          )
        else
          ...visible.map((entry) => FinanceBalanceBarRow(
            name: summary.names[entry.key] ?? 'Miembro',
            avatarUrl: summary.avatars[entry.key] ?? '',
            value: entry.value,
            maxValue: maxValue,
          )),
      ]),
    );
  }
}

class FinanceBalanceBarRow extends StatelessWidget {
  final String name;
  final String avatarUrl;
  final double value;
  final double maxValue;
  const FinanceBalanceBarRow({super.key, required this.name, required this.avatarUrl, required this.value, required this.maxValue});

  @override
  Widget build(BuildContext context) {
    final positive = value > 0.01;
    final negative = value < -0.01;
    final color = positive ? AppColors.green : negative ? AppColors.red : AppColors.muted;
    final label = positive ? 'le deben' : negative ? 'debe' : 'en equilibrio';
    final factor = max(.12, min(1.0, value.abs() / max(1.0, maxValue)));
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          ProfileAvatar(name: name, avatarUrl: avatarUrl, radius: 16),
          const SizedBox(width: 9),
          Expanded(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink))),
          Text('${value >= 0 ? '+' : '-'}${money(value.abs())}', style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 15)),
        ]),
        const SizedBox(height: 7),
        SizedBox(
          height: 34,
          child: Row(children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: FractionallySizedBox(
                  widthFactor: negative ? factor : .02,
                  alignment: Alignment.centerRight,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 32,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: negative ? AppColors.red.withOpacity(.22) : AppColors.faint,
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(11)),
                    ),
                    child: negative ? Text('-${money(value.abs())}', maxLines: 1, overflow: TextOverflow.fade, style: const TextStyle(color: AppColors.red, fontWeight: FontWeight.w900, fontSize: 12)) : null,
                  ),
                ),
              ),
            ),
            Container(width: 1, height: 34, color: AppColors.line),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: positive ? factor : .02,
                  alignment: Alignment.centerLeft,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 32,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: positive ? AppColors.green.withOpacity(.24) : AppColors.faint,
                      borderRadius: const BorderRadius.horizontal(right: Radius.circular(11)),
                    ),
                    child: positive ? Text('+${money(value.abs())}', maxLines: 1, overflow: TextOverflow.fade, style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.w900, fontSize: 12)) : null,
                  ),
                ),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 3),
        Text(label, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800, fontSize: 11)),
      ]),
    );
  }
}

class SettlementPaymentRow extends StatelessWidget {
  final SettlementDebt debt;
  final bool large;
  final VoidCallback? onPaid;
  const SettlementPaymentRow({super.key, required this.debt, this.large = false, this.onPaid});

  @override
  Widget build(BuildContext context) {
    final myId = AppData.user?.id ?? '';
    final title = debt.fromId == myId
        ? 'Pagas a ${debt.toName}'
        : debt.toId == myId
            ? '${debt.fromName} te paga'
            : '${debt.fromName} paga a ${debt.toName}';
    final subtitle = debt.fromId == myId || debt.toId == myId
        ? 'Movimiento directo para dejar tu balance a cero'
        : 'Pago recomendado para compensar el grupo';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: large ? 13 : 11),
      child: Row(children: [
        SizedBox(
          width: 58,
          height: 38,
          child: Stack(children: [
            Positioned(left: 0, top: 1, child: ProfileAvatar(name: debt.fromName, avatarUrl: debt.fromAvatarUrl, radius: 18)),
            Positioned(right: 0, top: 1, child: ProfileAvatar(name: debt.toName, avatarUrl: debt.toAvatarUrl, radius: 18)),
            Positioned(left: 23, top: 11, child: Container(width: 18, height: 18, decoration: BoxDecoration(color: AppColors.white, shape: BoxShape.circle, border: Border.all(color: AppColors.line)), child: const Icon(Icons.arrow_forward_rounded, size: 12, color: AppColors.teal))),
          ]),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink)),
          const SizedBox(height: 2),
          Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w700)),
        ])),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(color: AppColors.tealSoft, borderRadius: BorderRadius.circular(99)),
            child: Text(money(debt.amount), style: const TextStyle(color: AppColors.tealDark, fontWeight: FontWeight.w900, fontSize: 14.5)),
          ),
          if (onPaid != null) ...[
            const SizedBox(height: 6),
            SizedBox(
              height: 32,
              child: TextButton.icon(
                onPressed: onPaid,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 9),
                  foregroundColor: AppColors.tealDark,
                  backgroundColor: AppColors.tealSoft,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                ),
                icon: const Icon(Icons.check_circle_outline_rounded, size: 15),
                label: const Text('Liquidar', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
              ),
            ),
          ],
        ]),
      ]),
    );
  }
}

class SettlementHistoryRow extends StatelessWidget {
  final Map<String, dynamic> payment;
  final List<Map<String, dynamic>> members;
  final VoidCallback? onCancel;
  const SettlementHistoryRow({super.key, required this.payment, required this.members, this.onCancel});

  @override
  Widget build(BuildContext context) {
    final fromId = AppData.text(payment['from_user']);
    final toId = AppData.text(payment['to_user']);
    final amount = AppData.doubleValue(payment['amount']);
    final date = DateTime.tryParse(AppData.text(payment['paid_at']))?.toLocal();
    final dateText = date == null ? 'Registrado' : DateFormat('d MMM', 'es_ES').format(date).replaceAll('.', '');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(children: [
        SizedBox(
          width: 58,
          height: 38,
          child: Stack(children: [
            Positioned(left: 0, top: 1, child: ProfileAvatar(name: financeMemberName(fromId, members), avatarUrl: financeMemberAvatarUrl(fromId, members), radius: 18)),
            Positioned(right: 0, top: 1, child: ProfileAvatar(name: financeMemberName(toId, members), avatarUrl: financeMemberAvatarUrl(toId, members), radius: 18)),
            Positioned(left: 23, top: 11, child: Container(width: 18, height: 18, decoration: BoxDecoration(color: AppColors.white, shape: BoxShape.circle, border: Border.all(color: AppColors.line)), child: const Icon(Icons.check_rounded, size: 12, color: AppColors.green))),
          ]),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${financeMemberName(fromId, members)} pagó a ${financeMemberName(toId, members)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink)),
          const SizedBox(height: 2),
          Text(dateText, style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w700)),
        ])),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(money(amount), style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.w900, fontSize: 14.5)),
          if (onCancel != null) ...[
            const SizedBox(height: 5),
            SizedBox(
              height: 30,
              child: TextButton(
                onPressed: onCancel,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  foregroundColor: AppColors.red,
                  backgroundColor: AppColors.redSoft,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                ),
                child: const Text('Deshacer', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
              ),
            ),
          ],
        ]),
      ]),
    );
  }
}


class FinanceAutoBalanceCard extends StatelessWidget {
  final FinanceSummary summary;
  final int openCount;
  final int settledCount;
  const FinanceAutoBalanceCard({super.key, required this.summary, required this.openCount, required this.settledCount});

  @override
  Widget build(BuildContext context) {
    final hasPending = summary.pendingAmount > 0.01;
    final color = hasPending ? AppColors.teal : AppColors.green;
    final title = hasPending ? 'Cuentas compensadas' : 'Todo cuadrado';
    final body = hasPending
        ? 'Compensa deudas cruzadas y muestra solo lo que hay que mover.'
        : 'No hay pagos pendientes.';

    return AppCard(
      padding: const EdgeInsets.all(15),
      color: AppColors.surface,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: color.withOpacity(.12), borderRadius: BorderRadius.circular(15)),
            child: Icon(hasPending ? Icons.auto_awesome_rounded : Icons.verified_rounded, color: color, size: 23),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 5),
            Text(body, style: Theme.of(context).textTheme.bodyMedium),
          ])),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _FinanceAutoMetric(label: 'Total', value: money(summary.pendingAmount), color: AppColors.amber)),
          const SizedBox(width: 8),
          Expanded(child: _FinanceAutoMetric(label: 'A mover', value: money(summary.settlementAmount), color: AppColors.teal)),
          const SizedBox(width: 8),
          Expanded(child: _FinanceAutoMetric(label: 'Restado', value: money(summary.compensatedAmount), color: AppColors.green)),
        ]),
        const SizedBox(height: 10),
        Text(
          hasPending
              ? '$openCount ${openCount == 1 ? 'gasto abierto' : 'gastos abiertos'} · ${summary.settlements.length} ${summary.settlements.length == 1 ? 'pago recomendado' : 'pagos recomendados'} para dejarlo a cero.'
              : '$settledCount ${settledCount == 1 ? 'gasto liquidado' : 'gastos liquidados'} · sin pagos pendientes.',
          style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800, fontSize: 12),
        ),
      ]),
    );
  }
}

class _FinanceAutoMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _FinanceAutoMetric({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 10),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.line)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontSize: 10.5, fontWeight: FontWeight.w800)),
      const SizedBox(height: 4),
      Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w900)),
    ]),
  );
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
            : '$participants participantes · cada uno debe ${money(equalShare)} · luego se optimiza en Saldos';
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
  final List<Map<String, dynamic>> settlementPayments;
  late final FinanceSummary summary;

  _FinanceData({required this.expenses, required this.members, required this.settlementPayments}) {
    summary = FinanceSummary.from(expenses, members, settlementPayments);
  }

  static _FinanceData empty() => _FinanceData(expenses: const [], members: const [], settlementPayments: const []);

  static Future<_FinanceData> load(String groupId) async {
    final results = await Future.wait([AppData.expenses(groupId), AppData.members(groupId), AppData.settlementPayments(groupId)]);
    return _FinanceData(expenses: results[0], members: results[1], settlementPayments: results[2]);
  }
}

class FinanceSummary {
  final Map<String, String> names;
  final Map<String, String> avatars;
  final Map<String, double> balances;
  final List<SettlementDebt> settlements;
  final double totalExpenses;
  final double pendingAmount;
  final double myNet;

  FinanceSummary({
    required this.names,
    required this.avatars,
    required this.balances,
    required this.settlements,
    required this.totalExpenses,
    required this.pendingAmount,
    required this.myNet,
  });

  double get settlementAmount => double.parse(settlements.fold<double>(0, (sum, debt) => sum + debt.amount).toStringAsFixed(2));

  int get peopleWithBalance => balances.values.where((value) => value.abs() > 0.01).length;

  int get debtorsCount => balances.values.where((value) => value < -0.01).length;

  int get creditorsCount => balances.values.where((value) => value > 0.01).length;

  double get compensatedAmount {
    final value = pendingAmount - settlementAmount;
    return double.parse(max(0, value).toStringAsFixed(2));
  }

  List<MapEntry<String, double>> get sortedBalances {
    final list = balances.entries.where((entry) => entry.value.abs() > 0.01).toList();
    list.sort((a, b) => b.value.abs().compareTo(a.value.abs()));
    return list;
  }

  factory FinanceSummary.from(List<Map<String, dynamic>> expenses, List<Map<String, dynamic>> members, List<Map<String, dynamic>> settlementPayments) {
    final names = <String, String>{};
    final avatars = <String, String>{};
    final balances = <String, double>{};
    for (final m in members) {
      final id = m['user_id']?.toString() ?? '';
      if (id.isEmpty) continue;
      names[id] = memberName(m);
      avatars[id] = memberAvatarUrl(m);
      balances[id] = 0;
    }

    double total = 0;
    for (final e in expenses) {
      if (AppData.text(e['status']) == 'cancelled') continue;
      total += AppData.doubleValue(e['amount']);
      final paidBy = e['paid_by']?.toString() ?? '';
      names.putIfAbsent(paidBy, () => financeMemberName(paidBy, members));
      avatars.putIfAbsent(paidBy, () => financeMemberAvatarUrl(paidBy, members));
      balances.putIfAbsent(paidBy, () => 0);
      for (final p in expenseParticipants(e)) {
        final userId = p['user_id']?.toString() ?? '';
        if (userId.isEmpty || userId == paidBy) continue;
        final share = AppData.doubleValue(p['share_amount']);
        final alreadyPaid = p['paid'] == true;
        names.putIfAbsent(userId, () => financeMemberName(userId, members));
        avatars.putIfAbsent(userId, () => financeMemberAvatarUrl(userId, members));
        balances.putIfAbsent(userId, () => 0);
        if (!alreadyPaid) {
          balances[paidBy] = double.parse(((balances[paidBy] ?? 0) + share).toStringAsFixed(2));
          balances[userId] = double.parse(((balances[userId] ?? 0) - share).toStringAsFixed(2));
        }
      }
    }

    for (final payment in settlementPayments) {
      if (AppData.text(payment['status'], 'paid') != 'paid') continue;
      final fromId = AppData.text(payment['from_user']);
      final toId = AppData.text(payment['to_user']);
      final amount = AppData.doubleValue(payment['amount']);
      if (fromId.isEmpty || toId.isEmpty || amount <= 0) continue;
      names.putIfAbsent(fromId, () => financeMemberName(fromId, members));
      names.putIfAbsent(toId, () => financeMemberName(toId, members));
      avatars.putIfAbsent(fromId, () => financeMemberAvatarUrl(fromId, members));
      avatars.putIfAbsent(toId, () => financeMemberAvatarUrl(toId, members));
      balances.putIfAbsent(fromId, () => 0);
      balances.putIfAbsent(toId, () => 0);
      balances[fromId] = double.parse(((balances[fromId] ?? 0) + amount).toStringAsFixed(2));
      balances[toId] = double.parse(((balances[toId] ?? 0) - amount).toStringAsFixed(2));
    }

    final settlements = buildSettlements(balances, names, avatars);
    final netPending = balances.values.where((value) => value > 0.01).fold<double>(0, (sum, value) => sum + value);
    final myId = AppData.user?.id ?? '';
    return FinanceSummary(
      names: names,
      avatars: avatars,
      balances: balances,
      settlements: settlements,
      totalExpenses: double.parse(total.toStringAsFixed(2)),
      pendingAmount: double.parse(netPending.toStringAsFixed(2)),
      myNet: double.parse((balances[myId] ?? 0).toStringAsFixed(2)),
    );
  }
}

class SettlementDebt {
  final String fromId;
  final String toId;
  final String fromName;
  final String toName;
  final String fromAvatarUrl;
  final String toAvatarUrl;
  final double amount;
  const SettlementDebt({
    required this.fromId,
    required this.toId,
    required this.fromName,
    required this.toName,
    required this.fromAvatarUrl,
    required this.toAvatarUrl,
    required this.amount,
  });
}

List<SettlementDebt> buildSettlements(Map<String, double> balances, Map<String, String> names, Map<String, String> avatars) {
  final nodes = _settlementNodesFromBalances(balances);
  if (nodes.isEmpty) return const [];

  // Optimizador escalable para cualquier tamaño de grupo.
  // No liquida gasto por gasto: primero calcula el balance neto de cada miembro,
  // cruza deudas y propone una lista corta de pagos para dejar todos los saldos a cero.
  // Funciona igual con 3, 20 o 100 miembros activos porque trabaja en céntimos y empareja
  // deudores/receptores por importe pendiente, generando como máximo N-1 movimientos útiles.
  return _buildScalableNetSettlements(nodes, names, avatars);
}

class _SettlementNode {
  final String id;
  final int cents;
  const _SettlementNode(this.id, this.cents);
}

int _moneyToCents(double value) => (value * 100).round();

double _centsToMoney(int cents) => double.parse((cents / 100).toStringAsFixed(2));

List<_SettlementNode> _settlementNodesFromBalances(Map<String, double> balances) {
  final nodes = balances.entries
      .map((entry) => _SettlementNode(entry.key, _moneyToCents(entry.value)))
      .where((node) => node.cents.abs() > 0)
      .toList();
  if (nodes.isEmpty) return const [];

  // Corrige pequeñas diferencias de redondeo para que la suma sea exactamente 0 céntimos.
  final sum = nodes.fold<int>(0, (total, node) => total + node.cents);
  if (sum == 0) return nodes;
  nodes.sort((a, b) => b.cents.abs().compareTo(a.cents.abs()));
  final first = nodes.first;
  nodes[0] = _SettlementNode(first.id, first.cents - sum);
  return nodes.where((node) => node.cents.abs() > 0).toList();
}

List<SettlementDebt> _buildScalableNetSettlements(List<_SettlementNode> nodes, Map<String, String> names, Map<String, String> avatars) {
  final debtors = nodes.where((node) => node.cents < 0).map((node) => MapEntry(node.id, -node.cents)).toList();
  final creditors = nodes.where((node) => node.cents > 0).map((node) => MapEntry(node.id, node.cents)).toList();
  debtors.sort((a, b) => b.value.compareTo(a.value));
  creditors.sort((a, b) => b.value.compareTo(a.value));

  final result = <SettlementDebt>[];
  var i = 0;
  var j = 0;
  while (i < debtors.length && j < creditors.length) {
    final amountCents = min(debtors[i].value, creditors[j].value);
    if (amountCents > 0) {
      result.add(SettlementDebt(
        fromId: debtors[i].key,
        toId: creditors[j].key,
        fromName: names[debtors[i].key] ?? 'Miembro',
        toName: names[creditors[j].key] ?? 'Miembro',
        fromAvatarUrl: avatars[debtors[i].key] ?? '',
        toAvatarUrl: avatars[creditors[j].key] ?? '',
        amount: _centsToMoney(amountCents),
      ));
    }
    debtors[i] = MapEntry(debtors[i].key, debtors[i].value - amountCents);
    creditors[j] = MapEntry(creditors[j].key, creditors[j].value - amountCents);
    if (debtors[i].value <= 0) i++;
    if (creditors[j].value <= 0) j++;
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
  if (summary.compensatedAmount > 0.01) {
    return 'Total ${money(summary.pendingAmount)} · mover ${money(summary.settlementAmount)}.';
  }
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
  final String avatarUrl;
  final double value;
  const BalanceRow({super.key, required this.name, required this.value, this.avatarUrl = ''});

  @override
  Widget build(BuildContext context) {
    final color = value > 0.01 ? AppColors.green : value < -0.01 ? AppColors.red : AppColors.muted;
    final label = value > 0.01 ? 'Le deben' : value < -0.01 ? 'Debe' : 'En equilibrio';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(children: [
        ProfileAvatar(name: name, avatarUrl: avatarUrl, radius: 18),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w700)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(color: color.withOpacity(.10), borderRadius: BorderRadius.circular(99)),
          child: Text(money(value), style: TextStyle(color: color, fontWeight: FontWeight.w900)),
        ),
      ]),
    );
  }
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
  bool loading = true;
  String? error;
  List<Map<String, dynamic>> tournaments = [];

  String get groupId => widget.group['id'].toString();

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void didUpdateWidget(covariant TournamentsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshSeed != widget.refreshSeed || oldWidget.group['id'] != widget.group['id']) {
      load(soft: true);
    }
  }

  Future<void> load({bool soft = false}) async {
    if (!mounted) return;
    if (!soft) setState(() { loading = true; error = null; });
    try {
      final data = await AppData.tournaments(groupId).timeout(const Duration(seconds: 12));
      if (!mounted) return;
      setState(() {
        tournaments = data;
        loading = false;
        error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = humanError(e);
      });
    }
  }

  Future<void> openCreate() async {
    final created = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => TournamentCreateSimpleScreen(group: widget.group),
    ));
    if (created == true) await load(soft: true);
  }

  Future<void> openTournament(Map<String, dynamic> tournament) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => TournamentDetailSimpleScreen(
        tournamentId: tournament['id'].toString(),
        group: widget.group,
      ),
    ));
    await load(soft: true);
  }

  List<TournamentDashboardMatch> _allMatches({bool played = false}) {
    final output = <TournamentDashboardMatch>[];
    for (final tournament in tournaments) {
      final teams = tournamentTeams(tournament);
      final names = teamNameMap(teams);
      for (final match in tournamentMatches(tournament)) {
        final isPlayed = AppData.text(match['status']) == 'played';
        if (played != isPlayed) continue;
        final a = tournamentMatchSideName(match, names, true);
        final b = tournamentMatchSideName(match, names, false);
        output.add(TournamentDashboardMatch(
          tournament: tournament,
          match: match,
          teamA: a,
          teamB: b,
          played: isPlayed,
        ));
      }
    }
    output.sort((a, b) {
      final dateA = AppData.text(a.match['scheduled_at']);
      final dateB = AppData.text(b.match['scheduled_at']);
      if (dateA.isNotEmpty || dateB.isNotEmpty) return dateA.compareTo(dateB);
      final round = AppData.intValue(a.match['round']).compareTo(AppData.intValue(b.match['round']));
      if (round != 0) return round;
      return AppData.text(a.match['created_at']).compareTo(AppData.text(b.match['created_at']));
    });
    return output;
  }

  @override
  Widget build(BuildContext context) {
    final active = tournaments.where((t) => !['finished', 'cancelled'].contains(AppData.text(t['status'], 'active'))).toList();
    final finished = tournaments.where((t) => ['finished', 'cancelled'].contains(AppData.text(t['status'], 'active'))).toList();
    final results = _allMatches(played: true).reversed.take(4).toList();

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: AppColors.red,
        onRefresh: () => load(soft: true),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 104),
          children: [
            TournamentGroupHeader(
              subtitle: AppData.text(widget.group['name'], 'Grupo'),
            ),
            const SizedBox(height: 10),
            TournamentPremiumBanner(),
            const SizedBox(height: 14),
            if (loading)
              const CenterLoader(label: 'Cargando torneos...')
            else if (error != null)
              ErrorBlock(message: error!, onRetry: () => load())
            else if (tournaments.isEmpty)
              TournamentCleanEmptyState(onCreate: openCreate)
            else ...[
              TournamentSectionHeader(title: 'Torneos activos', action: active.isEmpty ? null : 'Ver todos'),
              const SizedBox(height: 8),
              ...active.take(4).map((t) => TournamentActiveCard(tournament: t, onTap: () => openTournament(t))),
              const SizedBox(height: 16),
              TournamentSectionHeader(title: 'Últimos resultados'),
              const SizedBox(height: 8),
              if (results.isEmpty)
                EmptySlim(icon: Icons.sports_score_rounded, title: 'Aún no hay resultados', body: 'Cuando registres marcadores aparecerán aquí.')
              else
                ...results.map((m) => TournamentDashboardMatchCard(item: m, onTap: () => openTournament(m.tournament))),
              if (finished.isNotEmpty) ...[
                const SizedBox(height: 16),
                TournamentSectionHeader(title: 'Finalizados'),
                const SizedBox(height: 8),
                ...finished.take(3).map((t) => TournamentActiveCard(tournament: t, onTap: () => openTournament(t), compact: true)),
              ],
              const SizedBox(height: 18),
              PrimaryButton(label: 'Crear torneo o liga', icon: Icons.add_rounded, onTap: openCreate),
            ],
          ],
        ),
      ),
    );
  }
}

class TournamentCreateSimpleScreen extends StatefulWidget {
  final Map<String, dynamic> group;
  const TournamentCreateSimpleScreen({super.key, required this.group});

  @override
  State<TournamentCreateSimpleScreen> createState() => _TournamentCreateSimpleScreenState();
}

class _TournamentCreateSimpleScreenState extends State<TournamentCreateSimpleScreen> {
  final name = TextEditingController();
  final participants = TextEditingController();
  final pairings = TextEditingController();
  final location = TextEditingController();
  final courtName = TextEditingController();
  String format = 'liga';
  String teamType = 'equipo';
  String scoringType = 'football';
  String creationTemplate = 'league';
  bool advancedMode = true;
  bool addToAgenda = true;
  bool scheduleMatches = true;
  bool loading = false;
  int step = 0;
  int leagueLegs = 1;
  int leagueRoundsLimit = 0;
  int americanoRounds = 5;
  int courtsCount = 1;
  int winPoints = 3;
  int drawPoints = 1;
  int lossPoints = 0;
  int targetScore = 0;
  int bestOf = 3;
  int daysBetweenRounds = 7;
  int durationMinutes = 60;
  int intervalMinutes = 70;
  DateTime firstMatchDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay firstMatchTime = const TimeOfDay(hour: 20, minute: 0);
  final List<TournamentManualDraftRow> manualRows = [];

  @override
  void dispose() {
    name.dispose();
    participants.dispose();
    pairings.dispose();
    location.dispose();
    courtName.dispose();
    super.dispose();
  }

  void applyScoringDefaults(String type) {
    final cfg = scoringConfigForType(type);
    scoringType = type;
    winPoints = AppData.intValue(cfg['win'], 3);
    drawPoints = AppData.intValue(cfg['draw'], 1);
    lossPoints = AppData.intValue(cfg['loss'], 0);
    bestOf = AppData.intValue(cfg['best_of'], 3);
    targetScore = AppData.intValue(cfg['target_score']);
  }

  void applyQuickTemplate(String template) {
    creationTemplate = template;
    pairings.clear();
    manualRows.clear();
    switch (template) {
      case 'padel_league':
        format = 'liga';
        teamType = 'pareja';
        courtsCount = max(1, courtsCount);
        leagueLegs = 1;
        leagueRoundsLimit = 0;
        scheduleMatches = true;
        addToAgenda = true;
        applyScoringDefaults('tennis_padel');
        name.text = name.text.trim().isEmpty ? 'Liga de pádel' : name.text;
        break;
      case 'americano_padel':
        format = 'americano';
        teamType = 'individual';
        courtsCount = max(1, courtsCount);
        americanoRounds = max(5, americanoRounds);
        scheduleMatches = true;
        addToAgenda = true;
        applyScoringDefaults('general');
        name.text = name.text.trim().isEmpty ? 'Americano de pádel' : name.text;
        break;
      case 'quick_cup':
        format = 'eliminatoria';
        teamType = 'equipo';
        scheduleMatches = true;
        addToAgenda = true;
        applyScoringDefaults(scoringType == 'tennis_padel' ? 'tennis_padel' : 'general');
        name.text = name.text.trim().isEmpty ? 'Eliminatoria' : name.text;
        break;
      case 'manual_day':
        format = 'manual';
        teamType = 'equipo';
        scheduleMatches = true;
        addToAgenda = true;
        applyScoringDefaults('general');
        name.text = name.text.trim().isEmpty ? 'Manual' : name.text;
        break;
      default:
        format = 'liga';
        teamType = 'equipo';
        leagueLegs = 1;
        leagueRoundsLimit = 0;
        scheduleMatches = true;
        addToAgenda = true;
        applyScoringDefaults('general');
        name.text = name.text.trim().isEmpty ? 'Liga' : name.text;
    }
  }

  Future<void> fillMembers() async {
    try {
      final members = await AppData.members(widget.group['id'].toString());
      final names = members.map(memberDisplayName).where((n) => n.trim().length >= 2).toSet().toList();
      if (names.isEmpty) {
        if (mounted) await showToast(context, 'Todavía no hay miembros para cargar.', danger: true);
        return;
      }
      setState(() => participants.text = names.join('\n'));
    } catch (e) {
      if (mounted) await showToast(context, humanError(e), danger: true);
    }
  }

  List<String> get participantNames {
    final fromList = parseTournamentParticipantNames(participants.text);
    final fromPairs = tournamentNamesFromManualPairings(parseTournamentPairings(pairings.text));
    final fromVisual = manualRows.expand((row) => [row.teamAName, row.teamBName]).toList();
    return mergeTournamentNames([...fromList, ...fromPairs, ...fromVisual]);
  }

  List<String> get manualEditorParticipants {
    final fromList = parseTournamentParticipantNames(participants.text);
    final fromPairs = tournamentNamesFromManualPairings(parseTournamentPairings(pairings.text));
    return mergeTournamentNames([...fromList, ...fromPairs]);
  }

  int get effectiveRoundLimit {
    if (format == 'americano') return americanoRounds;
    if (format != 'liga') return 0;
    return leagueRoundsLimit;
  }

  int get effectiveLegs => format == 'liga' ? leagueLegs : 1;

  List<TournamentDraftMatch> get draftMatches {
    final visual = manualRows.map((row) => row.draftMatch).toList();
    if (format == 'manual' && visual.isNotEmpty) return visual;
    final manual = parseTournamentPairings(pairings.text);
    if (format == 'manual' || manual.isNotEmpty) return manual;
    return previewPairingsForFormat(format, participantNames, legs: effectiveLegs, maxRounds: effectiveRoundLimit, courts: courtsCount);
  }

  List<TournamentSchedulePreviewRow> get schedulePreviewRows {
    final counters = <int, int>{};
    if (format == 'manual' && manualRows.isNotEmpty) {
      return manualRows.map((row) {
        final round = max(1, row.round);
        final orderInsideRound = counters[round] ?? 0;
        counters[round] = orderInsideRound + 1;
        final fallback = tournamentScheduledAtForIndex(scheduleConfig, round, orderInsideRound);
        final court = row.courtName.trim().isNotEmpty ? row.courtName.trim() : tournamentCourtNameForIndex(scheduleConfig, orderInsideRound);
        return TournamentSchedulePreviewRow(match: row.draftMatch, scheduledAt: row.scheduledAt ?? fallback, courtName: court);
      }).toList();
    }
    return draftMatches.map((match) {
      final round = max(1, match.round);
      final orderInsideRound = counters[round] ?? 0;
      counters[round] = orderInsideRound + 1;
      return TournamentSchedulePreviewRow(
        match: match,
        scheduledAt: tournamentScheduledAtForIndex(scheduleConfig, round, orderInsideRound),
        courtName: tournamentCourtNameForIndex(scheduleConfig, orderInsideRound),
      );
    }).toList();
  }

  Map<String, dynamic> get formatConfig => {
    'version': 16,
    'legs': effectiveLegs,
    'max_rounds': effectiveRoundLimit,
    'americano_rounds': americanoRounds,
    'courts_count': courtsCount,
    'manual_pairings': format == 'manual' || pairings.text.trim().isNotEmpty,
    'randomize_pairings': true,
  };

  Map<String, dynamic> get scoringConfig {
    final cfg = Map<String, dynamic>.from(scoringConfigForType(scoringType));
    cfg['win'] = winPoints;
    cfg['draw'] = scoringAllowDraw(scoringType, cfg) ? drawPoints : 0;
    cfg['loss'] = lossPoints;
    cfg['best_of'] = bestOf;
    if (targetScore > 0) cfg['target_score'] = targetScore;
    cfg['version'] = 16;
    return cfg;
  }

  Map<String, dynamic> get scheduleConfig {
    final first = DateTime(firstMatchDate.year, firstMatchDate.month, firstMatchDate.day, firstMatchTime.hour, firstMatchTime.minute);
    return {
      'version': 16,
      'enabled': scheduleMatches,
      'add_to_agenda': addToAgenda,
      'first_start_at': first.toUtc().toIso8601String(),
      'days_between_rounds': daysBetweenRounds,
      'duration_minutes': durationMinutes,
      'interval_minutes': intervalMinutes,
      'matches_per_round': max(1, courtsCount),
      'courts_count': max(1, courtsCount),
      'location': location.text.trim(),
      'court_name': courtName.text.trim(),
    };
  }

  bool validateStep(int value) {
    if (value == 0) return true;
    if (value == 1) {
      if (participantNames.length < 2) {
        showToast(context, 'Añade al menos 2 participantes/equipos.', danger: true);
        return false;
      }
      return true;
    }
    if (value == 2) {
      if ((format == 'manual' || pairings.text.trim().isNotEmpty) && draftMatches.isEmpty) {
        showToast(context, 'Escribe emparejamientos tipo: Jornada 1: Equipo Azul vs Equipo Rojo', danger: true);
        return false;
      }
      return true;
    }
    if (value == 3) return true;
    if (value == 4) return true;
    return true;
  }

  Future<void> next() async {
    if (!validateStep(step)) return;
    if (step < 5) {
      setState(() => step++);
    } else {
      await create();
    }
  }

  Future<void> create() async {
    final title = name.text.trim().isEmpty ? defaultTournamentName(format) : name.text.trim();
    final names = participantNames;
    final matches = draftMatches;
    if (title.length < 2) {
      await showToast(context, 'Pon un nombre a la competición.', danger: true);
      return;
    }
    if (names.length < 2) {
      await showToast(context, 'Añade al menos 2 participantes/equipos.', danger: true);
      return;
    }
    if ((format == 'manual' || pairings.text.trim().isNotEmpty) && matches.isEmpty) {
      await showToast(context, 'Faltan emparejamientos manuales válidos.', danger: true);
      return;
    }

    setState(() => loading = true);
    try {
      final firstStart = DateTime(firstMatchDate.year, firstMatchDate.month, firstMatchDate.day, firstMatchTime.hour, firstMatchTime.minute);
      final tournamentId = await AppData.createTournament(
        widget.group['id'].toString(),
        title,
        format: format,
        teamType: teamType,
        scoringType: scoringType,
        scoringConfig: scoringConfig,
        formatConfig: formatConfig,
        scheduleConfig: scheduleConfig,
        tieBreakers: defaultTieBreakers(scoringType),
        status: scheduleMatches ? 'scheduled' : 'draft',
        startsAt: scheduleMatches ? firstStart : null,
      );
      await AppData.addTournamentTeams(tournamentId, names);
      final created = await AppData.tournament(tournamentId);
      final teams = tournamentTeams(created);
      if (format == 'manual' && manualRows.isNotEmpty) {
        await AppData.createManualMatchRows(tournamentId, teams, manualRows, scheduleConfig: scheduleConfig);
      } else if (format == 'manual' || pairings.text.trim().isNotEmpty) {
        await AppData.createManualMatches(tournamentId, teams, matches, scheduleConfig: scheduleConfig);
      } else {
        await AppData.generateMatches(tournamentId, format, teams, formatConfig: formatConfig, scheduleConfig: scheduleConfig);
      }
      if (addToAgenda && scheduleMatches) {
        await AppData.createAgendaEventsForTournament(widget.group['id'].toString(), tournamentId, title);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) await showToast(context, humanError(e), danger: true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> pickDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: firstMatchDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      locale: const Locale('es', 'ES'),
    );
    if (value != null) setState(() => firstMatchDate = value);
  }

  Future<void> pickTime() async {
    final value = await showTimePicker(context: context, initialTime: firstMatchTime);
    if (value != null) setState(() => firstMatchTime = value);
  }

  Future<void> addManualDraftRow() async {
    final available = manualEditorParticipants;
    if (available.length < 2) {
      await showToast(context, 'Añade al menos 2 participantes antes de crear partidos.', danger: true);
      return;
    }
    final row = await showTournamentManualDraftDialog(
      context,
      participants: available,
      defaultRound: manualRows.isEmpty ? 1 : manualRows.map((r) => r.round).reduce(max),
      defaultDuration: durationMinutes,
      defaultLocation: location.text,
      defaultCourtName: courtName.text,
      defaultDate: scheduleMatches ? DateTime(firstMatchDate.year, firstMatchDate.month, firstMatchDate.day, firstMatchTime.hour, firstMatchTime.minute) : null,
    );
    if (row != null) setState(() => manualRows.add(row));
  }

  Future<void> editManualDraftRow(int index) async {
    if (index < 0 || index >= manualRows.length) return;
    final row = await showTournamentManualDraftDialog(
      context,
      participants: manualEditorParticipants,
      initial: manualRows[index],
      defaultRound: manualRows[index].round,
      defaultDuration: manualRows[index].durationMinutes,
      defaultLocation: manualRows[index].location,
      defaultCourtName: manualRows[index].courtName,
      defaultDate: manualRows[index].scheduledAt,
    );
    if (row != null) setState(() => manualRows[index] = row);
  }

  void moveManualDraftRow(int index, int delta) {
    final target = index + delta;
    if (index < 0 || target < 0 || index >= manualRows.length || target >= manualRows.length) return;
    setState(() {
      final row = manualRows.removeAt(index);
      manualRows.insert(target, row);
    });
  }

  void duplicateManualDraftRound(int round) {
    final rows = manualRows.where((row) => row.round == round).toList();
    if (rows.isEmpty) return;
    final nextRound = manualRows.fold<int>(0, (value, row) => max(value, row.round)) + 1;
    setState(() {
      manualRows.addAll(rows.map((row) => row.copyWith(round: nextRound, clearScheduledAt: true)));
    });
  }

  @override
  Widget build(BuildContext context) {
    return DirectPage(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeader(title: 'Crear torneo', subtitle: stepSubtitle(step), leading: true),
      const SizedBox(height: 10),
      TournamentStepIndicator(step: step, total: 6),
      const SizedBox(height: 16),
      if (step == 0) _buildTypeStep()
      else if (step == 1) _buildParticipantsStep()
      else if (step == 2) _buildFormatStep()
      else if (step == 3) _buildScoringStep()
      else if (step == 4) _buildCalendarStep()
      else _buildReviewStep(),
      const SizedBox(height: 18),
      Row(children: [
        if (step > 0) ...[
          Expanded(child: SecondaryButton(label: 'Volver', icon: Icons.arrow_back_rounded, onTap: () => setState(() => step--))),
          const SizedBox(width: 10),
        ],
        Expanded(child: PrimaryButton(label: step == 5 ? 'Crear torneo' : 'Siguiente', icon: step == 5 ? Icons.emoji_events_rounded : Icons.arrow_forward_rounded, loading: loading, onTap: next)),
      ]),
    ]));
  }

  Widget _buildTypeStep() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TournamentCreationHeroCard(),
      const SizedBox(height: 12),
      AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const FieldLabel('Nombre'),
        TextField(controller: name, textCapitalization: TextCapitalization.sentences, decoration: InputDecoration(hintText: defaultTournamentName(format))),
      ])),
      const SizedBox(height: 12),
      FieldLabel('Tipo de torneo'),
      const SizedBox(height: 8),
      TournamentQuickTemplateGrid(
        selected: creationTemplate,
        onChanged: (value) => setState(() => applyQuickTemplate(value)),
      ),
    ]);
  }

  Widget _buildParticipantsStep() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      FieldLabel('Tipo de participantes'),
      const SizedBox(height: 8),
      TournamentChoiceGrid(
        value: teamType,
        options: const [
          TournamentChoice('individual', 'Jugadores', 'Uno contra uno', Icons.person_rounded),
          TournamentChoice('pareja', 'Parejas', 'Ana / Javi', Icons.people_rounded),
          TournamentChoice('equipo', 'Equipos', 'Nombres libres', Icons.groups_rounded),
        ],
        onChanged: (v) => setState(() => teamType = v),
      ),
      const SizedBox(height: 14),
      AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Expanded(child: FieldLabel('Participantes')),
          TextButton.icon(onPressed: fillMembers, icon: const Icon(Icons.group_add_rounded, size: 18), label: const Text('Miembros')),
        ]),
        TextField(
          controller: participants,
          minLines: 8,
          maxLines: 12,
          textCapitalization: TextCapitalization.words,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: teamType == 'pareja' ? 'Ana / Javi\nMarta / Luis\nPádel Salvaje' : 'Los Invencibles del Viernes\nEquipo Azul\nPádel Salvaje',
            helperText: 'Un participante por línea. Podrás renombrar o retirar después.',
          ),
        ),
        const SizedBox(height: 10),
        Text('${participantNames.length} participantes preparados', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800)),
      ])),
    ]);
  }

  Widget _buildFormatStep() {
    final fullRounds = max(0, participantNames.length.isOdd ? participantNames.length : participantNames.length - 1);
    final americanoRecommendedRounds = recommendedAmericanoRounds(participantNames.length, courtsCount);
    final totalLeagueRounds = fullRounds * max(1, leagueLegs);
    final limitedLeagueRounds = leagueRoundsLimit <= 0 ? totalLeagueRounds : leagueRoundsLimit * max(1, leagueLegs);
    final preview = draftMatches.take(10).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      FieldLabel(advancedMode ? 'Formato detallado' : 'Formato'),
      const SizedBox(height: 8),
      if (!advancedMode)
        TournamentSimpleFormatConfigCard(
          format: format,
          rounds: format == 'americano' ? americanoRounds : leagueRoundsLimit,
          courts: courtsCount,
          onRoundsChanged: (v) => setState(() {
            if (format == 'americano') {
              americanoRounds = v;
            } else if (format == 'liga') {
              leagueRoundsLimit = v;
            }
          }),
          onCourtsChanged: (v) => setState(() => courtsCount = v),
        ),
      if (advancedMode)
        AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(tournamentFormatLabel(format), style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 16)),
        const SizedBox(height: 6),
        Text(tournamentFormatSubtitle(format), style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, height: 1.3)),
        const SizedBox(height: 12),
        if (format == 'liga') ...[
          TournamentCounterRow(label: 'Vueltas', value: leagueLegs, min: 1, max: 4, onChanged: (v) => setState(() => leagueLegs = v), helper: leagueLegs == 1 ? 'Solo ida' : '$leagueLegs vueltas'),
          TournamentCounterRow(label: 'Jornadas por vuelta', value: leagueRoundsLimit, min: 0, max: max(1, fullRounds), zeroLabel: 'Todas', onChanged: (v) => setState(() => leagueRoundsLimit = v), helper: leagueRoundsLimit == 0 ? 'Liga completa: $fullRounds por vuelta · $totalLeagueRounds en total' : '$leagueRoundsLimit por vuelta · $limitedLeagueRounds en total'),
        ] else if (format == 'americano') ...[
          TournamentCounterRow(label: 'Rondas', value: americanoRounds, min: 1, max: 40, onChanged: (v) => setState(() => americanoRounds = v), helper: 'Recomendado: $americanoRecommendedRounds rondas'),
          TournamentCounterRow(label: 'Pistas / mesas', value: courtsCount, min: 1, max: 12, onChanged: (v) => setState(() => courtsCount = v), helper: '1 partido por pista y ronda'),
          const SizedBox(height: 6),
          Wrap(spacing: 8, runSpacing: 8, children: const [
            TournamentRuleChip(label: 'Ranking individual'),
            TournamentRuleChip(label: 'Pareja distinta si se puede'),
            TournamentRuleChip(label: 'Descansos equilibrados'),
          ]),
          const SizedBox(height: 8),
          Text(americanoRulesText(participantNames.length, courtsCount, americanoRounds), style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, height: 1.3)),
          if (participantNames.length >= 4 && americanoRounds != americanoRecommendedRounds) ...[
            const SizedBox(height: 10),
            SecondaryButton(label: 'Usar $americanoRecommendedRounds rondas recomendadas', icon: Icons.auto_awesome_rounded, onTap: () => setState(() => americanoRounds = americanoRecommendedRounds)),
          ],
        ] else if (format == 'eliminatoria') ...[
          Wrap(spacing: 8, runSpacing: 8, children: const [
            TournamentRuleChip(label: 'Cabezas de serie'),
            TournamentRuleChip(label: 'Byes automáticos'),
            TournamentRuleChip(label: 'Cuadro visual'),
            TournamentRuleChip(label: 'Sorteo automático'),
          ]),
          const SizedBox(height: 8),
          const Text('Al crear el torneo, la app sortea automáticamente los cruces para evitar ventajas por el orden de escritura. Si el número no cuadra, los pases directos también se asignan tras el sorteo.', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700)),
        ] else ...[
          const Text('Escribe los partidos a mano. Puedes poner Jornada 1, Jornada 2, etc.', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700)),
        ],
      ])),
      const SizedBox(height: 12),
      if (format == 'manual') ...[
        AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Expanded(child: Text('Editor visual de partidos', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900))),
            TournamentRuleChip(label: '${manualRows.length} partidos'),
          ]),
          const SizedBox(height: 8),
          Text('Añade cruces con selectores, fecha individual, pista y notas. Es más seguro que escribirlo a mano.', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, height: 1.3)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: PrimaryButton(label: 'Añadir partido', icon: Icons.add_rounded, onTap: addManualDraftRow)),
            if (manualRows.isNotEmpty) ...[
              const SizedBox(width: 8),
              Expanded(child: SecondaryButton(label: 'Duplicar jornada', icon: Icons.copy_rounded, onTap: () => duplicateManualDraftRound(manualRows.map((r) => r.round).reduce(max)))),
            ],
          ]),
          const SizedBox(height: 12),
          if (manualRows.isEmpty)
            EmptySlim(icon: Icons.table_rows_rounded, title: 'Sin partidos manuales', body: 'Pulsa Añadir partido para crear los cruces uno a uno.')
          else
            ...List.generate(manualRows.length, (index) => TournamentManualDraftRowCard(
              row: manualRows[index],
              index: index,
              onEdit: () => editManualDraftRow(index),
              onDelete: () => setState(() => manualRows.removeAt(index)),
              onMoveUp: index == 0 ? null : () => moveManualDraftRow(index, -1),
              onMoveDown: index == manualRows.length - 1 ? null : () => moveManualDraftRow(index, 1),
            )),
        ])),
        const SizedBox(height: 12),
        AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Expanded(child: Text('Importar desde texto', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900))),
            TournamentRuleChip(label: '${parseTournamentPairings(pairings.text).length} escritos'),
          ]),
          const SizedBox(height: 8),
          TextField(
            controller: pairings,
            minLines: 4,
            maxLines: 10,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Jornada 1: Equipo Azul vs Los Invencibles\nJornada 1: Ana / Javi vs Marta / Luis',
              helperText: 'Solo se usará si no has añadido partidos en el editor visual.',
            ),
          ),
        ])),
      ] else ...[
        AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Expanded(child: Text('Cruces manuales opcionales', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900))),
            TournamentRuleChip(label: '${draftMatches.length} partidos'),
          ]),
          const SizedBox(height: 8),
          TextField(
            controller: pairings,
            minLines: 4,
            maxLines: 12,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Jornada 1: Equipo Azul vs Los Invencibles\nJornada 1: Ana / Javi vs Marta / Luis\nJornada 2: Pádel Salvaje vs Anónimos FC',
              helperText: 'Si lo rellenas, la app usará estos cruces.',
            ),
          ),
        ])),
      ],
      const SizedBox(height: 14),
      SectionHeader(title: 'Vista previa'),
      const SizedBox(height: 8),
      if (preview.isEmpty)
        EmptySlim(icon: Icons.sports_score_rounded, title: 'Sin cruces todavía', body: 'Añade participantes o escribe emparejamientos manuales.')
      else
        ...preview.map((m) => TournamentDraftMatchTile(match: m)),
    ]);
  }

  Widget _buildScoringStep() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      FieldLabel('Deporte y resultado'),
      const SizedBox(height: 8),
      TournamentSportEmojiPicker(
        value: scoringType,
        onChanged: (v) => setState(() => applyScoringDefaults(v)),
      ),
      const SizedBox(height: 10),
      TournamentValidationCard(scoringType: scoringType, scoringConfig: scoringConfig),
      const SizedBox(height: 14),
      AppCard(color: AppColors.redSoft, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.rule_rounded, color: AppColors.red),
          const SizedBox(width: 8),
          Expanded(child: Text('Resultado del partido: ${scoringTypeLabel(scoringType)}', style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900))),
        ]),
        const SizedBox(height: 8),
        Text(scoringConfigFullText(scoringType, scoringConfig), style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, height: 1.3)),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: [
          TournamentRuleChip(label: scoringUsesSetMode(scoringType, scoringConfig) ? 'Resultado por sets' : 'Marcador simple'),
          TournamentRuleChip(label: scoringAllowDraw(scoringType, scoringConfig) ? 'Permite empate' : 'Sin empate'),
          if (targetScore > 0) TournamentRuleChip(label: 'Hasta $targetScore ${scoringScoreLabel(scoringType, scoringConfig)}'),
        ]),
      ])),
      const SizedBox(height: 12),
      AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Puntos de clasificación', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        TournamentCounterRow(label: 'Victoria', value: winPoints, min: 0, max: 10, onChanged: (v) => setState(() => winPoints = v)),
        if (scoringAllowDraw(scoringType, scoringConfig)) TournamentCounterRow(label: 'Empate', value: drawPoints, min: 0, max: 10, onChanged: (v) => setState(() => drawPoints = v)),
        TournamentCounterRow(label: 'Derrota', value: lossPoints, min: -3, max: 5, onChanged: (v) => setState(() => lossPoints = v)),
        TournamentCounterRow(label: 'Objetivo del partido', value: targetScore, min: 0, max: 999, zeroLabel: 'Libre', onChanged: (v) => setState(() => targetScore = v), helper: 'Ej: mus a 30, ping-pong a 11'),
        if (scoringUsesSetMode(scoringType, scoringConfig)) TournamentCounterRow(label: 'Mejor de', value: bestOf, min: 1, max: 7, onChanged: (v) => setState(() => bestOf = v.isEven ? v + 1 : v), helper: 'Sets/rondas'),
      ])),
      const SizedBox(height: 12),
      AppCard(color: AppColors.faint, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Desempates', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text(defaultTieBreakers(scoringType).map(tieBreakerLabel).join(' → '), style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, height: 1.3)),
      ])),
    ]);
  }

  Widget _buildCalendarStep() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      FieldLabel('Calendario de partidos'),
      const SizedBox(height: 8),
      AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Expanded(child: Text('Programar fechas', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900))),
          Switch(value: scheduleMatches, activeThumbColor: AppColors.red, onChanged: (v) => setState(() => scheduleMatches = v)),
        ]),
        if (scheduleMatches) ...[
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: SecondaryButton(label: DateFormat('d MMM', 'es_ES').format(firstMatchDate), icon: Icons.calendar_today_rounded, onTap: pickDate)),
            const SizedBox(width: 10),
            Expanded(child: SecondaryButton(label: firstMatchTime.format(context), icon: Icons.schedule_rounded, onTap: pickTime)),
          ]),
          const SizedBox(height: 10),
          TournamentCounterRow(label: 'Días entre jornadas', value: daysBetweenRounds, min: 0, max: 30, onChanged: (v) => setState(() => daysBetweenRounds = v)),
          TournamentCounterRow(label: 'Pistas / mesas simultáneas', value: courtsCount, min: 1, max: 12, onChanged: (v) => setState(() => courtsCount = v), helper: courtsCount == 1 ? 'una a la vez' : 'partidos en paralelo'),
        ],
      ])),
      const SizedBox(height: 12),
      AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Expanded(child: Text('Añadir a Agenda del grupo', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900))),
          Switch(value: addToAgenda, activeThumbColor: AppColors.red, onChanged: scheduleMatches ? (v) => setState(() => addToAgenda = v) : null),
        ]),
        const SizedBox(height: 8),
        TextField(controller: location, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Ubicación opcional', hintText: 'Polideportivo, bar, casa de Ana...')),
        const SizedBox(height: 8),
        TextField(controller: courtName, textCapitalization: TextCapitalization.words, decoration: InputDecoration(labelText: courtsCount <= 1 ? 'Pista / mesa / campo opcional' : 'Nombre base de pistas/mesas', hintText: courtsCount <= 1 ? 'Pista 2, Mesa 1...' : 'Pista, Mesa, Campo...')),
      ])),
      if (scheduleMatches) ...[
        const SizedBox(height: 12),
        SectionHeader(title: 'Vista previa de calendario'),
        const SizedBox(height: 8),
        if (schedulePreviewRows.isEmpty)
          EmptySlim(icon: Icons.calendar_month_rounded, title: 'Sin vista previa', body: 'Añade participantes o emparejamientos para ver fechas antes de crear.')
        else
          ...schedulePreviewRows.take(8).map((row) => TournamentSchedulePreviewTile(row: row)),
        if (schedulePreviewRows.length > 8)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('+ ${schedulePreviewRows.length - 8} partidos más', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800, fontSize: 12)),
          ),
      ],
    ]);
  }

  Widget _buildReviewStep() {
    final title = name.text.trim().isEmpty ? defaultTournamentName(format) : name.text.trim();
    final names = participantNames;
    final matches = draftMatches;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      AppCard(color: AppColors.faint, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        TournamentReviewRow(label: 'Nombre', value: title),
        TournamentReviewRow(label: 'Formato', value: tournamentFormatLabel(format)),
        TournamentReviewRow(label: 'Participantes', value: '${names.length}'),
        TournamentReviewRow(label: 'Partidos previstos', value: '${matches.length}'),
        TournamentReviewRow(label: 'Puntuación', value: '${scoringTypeLabel(scoringType)} · V$winPoints ${scoringAllowDraw(scoringType, scoringConfig) ? 'E$drawPoints ' : ''}D$lossPoints'),
        TournamentReviewRow(label: 'Calendario', value: scheduleMatches ? '${DateFormat('d MMM', 'es_ES').format(firstMatchDate)} · ${firstMatchTime.format(context)}' : 'Sin fechas'),
        TournamentReviewRow(label: 'Agenda', value: addToAgenda && scheduleMatches ? 'Sí' : 'No'),
      ])),
      const SizedBox(height: 12),
      TournamentPremiumMiniCard(),
      const SizedBox(height: 12),
      SectionHeader(title: 'Primeros partidos'),
      const SizedBox(height: 8),
      if (matches.isEmpty)
        EmptySlim(icon: Icons.info_outline_rounded, title: 'Se generarán al crear', body: 'La app generará los cruces con los participantes añadidos.')
      else if (scheduleMatches)
        ...schedulePreviewRows.take(6).map((row) => TournamentSchedulePreviewTile(row: row))
      else
        ...matches.take(6).map((m) => TournamentDraftMatchTile(match: m)),
    ]);
  }
}

class TournamentDetailSimpleScreen extends StatefulWidget {
  final String tournamentId;
  final Map<String, dynamic> group;
  const TournamentDetailSimpleScreen({super.key, required this.tournamentId, required this.group});

  @override
  State<TournamentDetailSimpleScreen> createState() => _TournamentDetailSimpleScreenState();
}

class _TournamentDetailSimpleScreenState extends State<TournamentDetailSimpleScreen> {
  bool loading = true;
  String? error;
  Map<String, dynamic>? tournament;
  int tab = 0;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load({bool soft = false}) async {
    if (!mounted) return;
    if (!soft) setState(() { loading = true; error = null; });
    try {
      final data = await AppData.tournament(widget.tournamentId).timeout(const Duration(seconds: 12));
      if (!mounted) return;
      setState(() {
        tournament = data;
        loading = false;
        error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = humanError(e);
      });
    }
  }

  Future<void> addParticipants() async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Añadir jugadores, parejas o equipos'),
        content: SizedBox(
          width: double.maxFinite,
          child: TextField(
            controller: controller,
            minLines: 6,
            maxLines: 10,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'Ana\nJavi\nMarta / Luis\nEquipo azul',
              helperText: 'Uno por línea. Puedes escribir jugadores, parejas o equipos. Después podrás renombrar, cambiar seed o eliminar desde Participantes.',
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Añadir')),
        ],
      ),
    );
    controller.dispose();
    final names = parseTournamentParticipantNames(value ?? '');
    if (names.isEmpty) return;
    try {
      await AppData.addTournamentTeams(widget.tournamentId, names);
      await load(soft: true);
      if (mounted) await showToast(context, 'Participantes añadidos. Regenera o añade partidos si lo necesitas.');
    } catch (e) {
      if (mounted) await showToast(context, humanError(e), danger: true);
    }
  }

  Future<void> addGroupMembersVisual() async {
    try {
      final members = await AppData.members(widget.group['id'].toString());
      if (!mounted) return;
      final selected = await showTournamentMemberPickerDialog(context, members: members);
      if (selected == null || selected.isEmpty) return;
      final added = await AppData.addTournamentTeamsFromMembers(widget.tournamentId, selected);
      await load(soft: true);
      if (mounted) {
        await showToast(
          context,
          added == 0 ? 'No se añadieron miembros nuevos: ya estaban en el torneo.' : '$added participante${added == 1 ? '' : 's'} añadidos.',
          danger: added == 0,
        );
      }
    } catch (e) {
      if (mounted) await showToast(context, humanError(e), danger: true);
    }
  }

  Future<void> createPairVisual() async {
    try {
      final members = await AppData.members(widget.group['id'].toString());
      if (!mounted) return;
      final pair = await showTournamentPairCreatorDialog(context, members: members);
      if (pair == null) return;
      await AppData.addTournamentPairFromMembers(widget.tournamentId, pair.first, pair.second, customName: pair.name);
      await load(soft: true);
      if (mounted) await showToast(context, 'Pareja creada.');
    } catch (e) {
      if (mounted) await showToast(context, humanError(e), danger: true);
    }
  }

  Future<void> editTournamentRules() async {
    final t = tournament;
    if (t == null) return;
    final matches = tournamentMatches(t);
    final hasResults = matches.any(matchCountsForStandings);
    final edited = await showTournamentEditorDialog(context, tournament: t, hasResults: hasResults);
    if (edited == null) return;

    if (hasResults && edited.rulesChanged) {
      await showToast(context, 'Hay resultados registrados. Para proteger la tabla solo se permite cambiar el nombre.', danger: true);
      return;
    }

    try {
      await AppData.updateTournamentEditor(
        widget.tournamentId,
        name: edited.name,
        scoringType: edited.scoringType,
        scoringConfig: edited.scoringConfig,
        formatConfig: edited.formatConfig,
        tieBreakers: edited.tieBreakers,
      );
      await load(soft: true);
      if (mounted) await showToast(context, 'Torneo actualizado.');
    } catch (e) {
      if (mounted) await showToast(context, humanError(e), danger: true);
    }
  }

  Future<void> showFullHistory() async {
    final t = tournament;
    if (t == null) return;
    await showTournamentHistoryDialog(context, tournament: t, matches: tournamentMatches(t), teams: tournamentTeams(t));
  }

  Future<void> addManualMatches() async {
    final t = tournament;
    if (t == null) return;
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Añadir partidos manuales'),
        content: TextField(
          controller: controller,
          minLines: 6,
          maxLines: 10,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Jornada 2: Equipo Azul vs Equipo Rojo\nJornada 2: Ana / Javi vs Marta / Luis'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Añadir')),
        ],
      ),
    );
    controller.dispose();
    final pairs = parseTournamentPairings(value ?? '');
    if (pairs.isEmpty) return;
    try {
      await AppData.addManualMatches(widget.tournamentId, tournamentTeams(t), pairs, scheduleConfig: tournamentScheduleConfig(t));
      await load(soft: true);
      if (mounted) await showToast(context, 'Partidos añadidos.');
    } catch (e) {
      if (mounted) await showToast(context, humanError(e), danger: true);
    }
  }

  Future<void> regenerate() async {
    final t = tournament;
    if (t == null) return;
    final format = AppData.text(t['format'], 'liga');
    if (format == 'manual') {
      await addManualMatches();
      return;
    }
    final teams = tournamentTeams(t);
    if (teams.length < 2) {
      await showToast(context, 'Añade al menos 2 participantes.', danger: true);
      return;
    }
    final matches = tournamentMatches(t);
    final results = matches.where(matchCountsForStandings).length;
    if (results > 0) {
      await showToast(context, 'No se puede regenerar una liga con resultados. Borra primero los resultados o crea otra competición.', danger: true);
      return;
    }
    if (matches.isNotEmpty) {
      final ok = await confirmAction(
        context,
        title: '¿Regenerar calendario?',
        body: 'Se borrarán los partidos pendientes actuales para crear un calendario nuevo. Los resultados ya registrados bloquean esta acción.',
        danger: true,
        confirmLabel: 'Regenerar',
      );
      if (ok != true) return;
    }
    try {
      await AppData.generateMatches(widget.tournamentId, format, teams, formatConfig: tournamentFormatConfig(t), scheduleConfig: tournamentScheduleConfig(t));
      await load(soft: true);
      if (mounted) await showToast(context, 'Calendario generado.');
    } catch (e) {
      if (mounted) await showToast(context, humanError(e), danger: true);
    }
  }

  Future<void> nextRound() async {
    final t = tournament;
    if (t == null) return;
    try {
      await AppData.generateNextEliminationRound(widget.tournamentId, tournamentMatches(t));
      await load(soft: true);
      if (mounted) await showToast(context, 'Siguiente ronda generada.');
    } catch (e) {
      if (mounted) await showToast(context, humanError(e), danger: true);
    }
  }

  Future<void> thirdPlace() async {
    final t = tournament;
    if (t == null) return;
    try {
      await AppData.generateThirdPlaceMatch(widget.tournamentId, tournamentMatches(t));
      await load(soft: true);
      if (mounted) await showToast(context, 'Partido por el tercer puesto creado.');
    } catch (e) {
      if (mounted) await showToast(context, humanError(e), danger: true);
    }
  }

  Future<void> reprogramTournamentCalendar() async {
    final t = tournament;
    if (t == null) return;
    await showTournamentBulkScheduleDialog(
      context,
      tournament: t,
      group: widget.group,
      teams: tournamentTeams(t),
      matches: tournamentMatches(t),
      onChanged: () => load(soft: true),
    );
  }

  Future<void> deleteTournament() async {
    final ok = await confirmAction(
      context,
      title: '¿Eliminar competición?',
      body: 'Se borrarán participantes, partidos y resultados. Esta acción no se puede deshacer.',
      danger: true,
      confirmLabel: 'Eliminar',
    );
    if (ok != true) return;
    try {
      await AppData.deleteTournament(widget.tournamentId);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) await showToast(context, humanError(e), danger: true);
    }
  }

  Future<void> setStatus(String status) async {
    try {
      await AppData.updateTournamentStatus(widget.tournamentId, status);
      await load(soft: true);
    } catch (e) {
      if (mounted) await showToast(context, humanError(e), danger: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = tournament;
    final teams = t == null ? <Map<String, dynamic>>[] : tournamentTeams(t);
    final matches = t == null ? <Map<String, dynamic>>[] : tournamentMatches(t);
    final scoringType = t == null ? 'general' : AppData.text(t['scoring_type'], 'general');
    final scoringConfig = t == null ? scoringConfigForType('general') : resolvedScoringConfig(scoringType, t['scoring_config']);
    final tieBreakers = t == null ? defaultTieBreakers(scoringType) : tournamentTieBreakers(t, scoringType);
    final standings = calculateStandings(teams, matches, scoringType: scoringType, scoringConfig: scoringConfig, tieBreakers: tieBreakers);
    final format = t == null ? 'liga' : AppData.text(t['format'], 'liga');
    final played = matches.where(matchCountsForStandings).length;
    final pending = matches.length - played;

    return DirectPage(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeader(title: t == null ? 'Competición' : AppData.text(t['name'], 'Competición'), subtitle: t == null ? 'Cargando...' : '${tournamentFormatLabel(format)} · ${teamTypeLabel(AppData.text(t['team_type'], 'equipo'))} · Jornada ${currentTournamentRound(matches)}', leading: true),
      const SizedBox(height: 14),
      if (loading && t == null)
        const CenterLoader(label: 'Cargando competición...')
      else if (error != null && t == null)
        ErrorBlock(message: error!, onRetry: () => load())
      else ...[
        TournamentDetailHero(
          tournament: t ?? {},
          leader: standings.isEmpty ? null : standings.first,
          teams: teams.length,
          played: played,
          total: matches.length,
          pending: pending,
          onAdd: addParticipants,
          onGenerate: regenerate,
        ),
        const SizedBox(height: 12),
        TournamentTabsBar(index: tab, format: format, onChanged: (i) => setState(() => tab = i)),
        const SizedBox(height: 14),
        if (tab == 0)
          TournamentOverviewPanel(
            tournament: t ?? {},
            teams: teams,
            matches: matches,
            standings: standings,
            onAddParticipants: addParticipants,
            onGenerate: regenerate,
            onManualMatches: addManualMatches,
            onBulkSchedule: reprogramTournamentCalendar,
            onNextRound: format == 'eliminatoria' ? nextRound : null,
            onChanged: () => load(soft: true),
          )
        else if (tab == 1)
          TournamentMatchesPanel(
            tournament: t ?? {},
            group: widget.group,
            matches: matches,
            teams: teams,
            scoringType: scoringType,
            scoringConfig: scoringConfig,
            onBulkSchedule: reprogramTournamentCalendar,
            onChanged: () => load(soft: true),
          )
        else if (tab == 2)
          format == 'eliminatoria'
              ? TournamentEliminationBracketPanel(
                  tournament: t ?? {},
                  group: widget.group,
                  matches: matches,
                  teams: teams,
                  scoringType: scoringType,
                  scoringConfig: scoringConfig,
                  onNextRound: nextRound,
                  onThirdPlace: thirdPlace,
                  onChanged: () => load(soft: true),
                )
              : TournamentStandingsPanel(standings: standings, matches: matches, tieBreakers: tieBreakers, scoringType: scoringType, scoringConfig: scoringConfig)
        else if (tab == 3)
          TournamentStatsPanel(standings: standings, matches: matches, teams: teams, scoringType: scoringType, scoringConfig: scoringConfig)
        else if (tab == 4)
          TournamentTeamsPanel(teams: teams, matches: matches, showSeeds: format == 'eliminatoria', onChanged: () => load(soft: true), onAdd: addParticipants, onAddMembers: addGroupMembersVisual, onCreatePair: createPairVisual)
        else
          TournamentSettingsPanel(
            tournament: t ?? {},
            matches: matches,
            onRegenerate: regenerate,
            onManualMatches: addManualMatches,
            onBulkSchedule: reprogramTournamentCalendar,
            onAddParticipants: addParticipants,
            onCheckIn: () => showTournamentCheckInDialog(context, teams: teams),
            onEditTournament: editTournamentRules,
            onHistory: showFullHistory,
            onSetStatus: setStatus,
            onDelete: deleteTournament,
          ),
        const SizedBox(height: 16),
      ],
    ]));
  }
}

class TournamentDashboardMatch {
  final Map<String, dynamic> tournament;
  final Map<String, dynamic> match;
  final String teamA;
  final String teamB;
  final bool played;
  const TournamentDashboardMatch({required this.tournament, required this.match, required this.teamA, required this.teamB, required this.played});
}

class TournamentDraftMatch {
  final int round;
  final String teamAName;
  final String teamBName;
  const TournamentDraftMatch({required this.round, required this.teamAName, required this.teamBName});
}

class TournamentManualDraftRow {
  final int round;
  final String teamAName;
  final String teamBName;
  final DateTime? scheduledAt;
  final int durationMinutes;
  final String location;
  final String courtName;
  final String notes;
  const TournamentManualDraftRow({
    required this.round,
    required this.teamAName,
    required this.teamBName,
    this.scheduledAt,
    this.durationMinutes = 60,
    this.location = '',
    this.courtName = '',
    this.notes = '',
  });

  TournamentDraftMatch get draftMatch => TournamentDraftMatch(round: round, teamAName: teamAName, teamBName: teamBName);

  TournamentManualDraftRow copyWith({
    int? round,
    String? teamAName,
    String? teamBName,
    DateTime? scheduledAt,
    bool clearScheduledAt = false,
    int? durationMinutes,
    String? location,
    String? courtName,
    String? notes,
  }) => TournamentManualDraftRow(
    round: round ?? this.round,
    teamAName: teamAName ?? this.teamAName,
    teamBName: teamBName ?? this.teamBName,
    scheduledAt: clearScheduledAt ? null : scheduledAt ?? this.scheduledAt,
    durationMinutes: durationMinutes ?? this.durationMinutes,
    location: location ?? this.location,
    courtName: courtName ?? this.courtName,
    notes: notes ?? this.notes,
  );
}

class TournamentSchedulePreviewRow {
  final TournamentDraftMatch match;
  final DateTime? scheduledAt;
  final String courtName;
  const TournamentSchedulePreviewRow({required this.match, this.scheduledAt, this.courtName = ''});
}

class TournamentGroupHeader extends StatelessWidget {
  final String subtitle;
  const TournamentGroupHeader({super.key, required this.subtitle});

  @override
  Widget build(BuildContext context) => AppCard(
    color: AppColors.navyDeep,
    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Torneos', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 23, letterSpacing: -.5)),
        const SizedBox(height: 2),
        Row(children: [
          Flexible(child: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xDFFFFFFF), fontWeight: FontWeight.w700))),
          const SizedBox(width: 4),
          const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 18),
        ]),
      ])),
    ]),
  );
}

class TournamentSectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  const TournamentSectionHeader({super.key, required this.title, this.action});
  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: Text(title, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 15))),
    if (action != null) Text(action!, style: const TextStyle(color: AppColors.blue, fontWeight: FontWeight.w800, fontSize: 12)),
  ]);
}

class TournamentActiveCard extends StatelessWidget {
  final Map<String, dynamic> tournament;
  final VoidCallback onTap;
  final bool compact;
  const TournamentActiveCard({super.key, required this.tournament, required this.onTap, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final teams = tournamentTeams(tournament);
    final matches = tournamentMatches(tournament);
    final played = matches.where(matchCountsForStandings).length;
    final status = AppData.text(tournament['status'], 'active');
    final progress = matches.isEmpty ? 0.0 : (played / matches.length).clamp(0.0, 1.0);
    final scoring = AppData.text(tournament['scoring_type'], 'general');
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          TournamentIconBadge(scoringType: scoring, finished: status == 'finished'),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(AppData.text(tournament['name'], 'Competición'), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, height: 1.05)),
            const SizedBox(height: 5),
            Row(children: [
              Container(width: 6, height: 6, decoration: BoxDecoration(color: tournamentStatusColor(status), shape: BoxShape.circle)),
              const SizedBox(width: 5),
              Expanded(child: Text(tournamentStatusLabel(status), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: tournamentStatusColor(status), fontWeight: FontWeight.w800, fontSize: 12))),
              Text('Jornada ${currentTournamentRound(matches)}', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 11)),
            ]),
            if (!compact) ...[
              const SizedBox(height: 8),
              ClipRRect(borderRadius: BorderRadius.circular(999), child: LinearProgressIndicator(value: progress, minHeight: 4, color: AppColors.green, backgroundColor: AppColors.lineSoft)),
            ],
          ])),
          const SizedBox(width: 8),
          Text('${teams.length}', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w900, fontSize: 12)),
        ]),
      ),
    );
  }
}

class TournamentDashboardMatchCard extends StatelessWidget {
  final TournamentDashboardMatch item;
  final VoidCallback onTap;
  const TournamentDashboardMatchCard({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final score = item.played ? '${AppData.intValue(item.match['score_a'])} - ${AppData.intValue(item.match['score_b'])}' : 'Pendiente';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(children: [
          SizedBox(width: 44, child: Text('J${AppData.intValue(item.match['round'], 1)}', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.blue, fontWeight: FontWeight.w900, fontSize: 12))),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(AppData.text(item.tournament['name'], 'Torneo'), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800, fontSize: 11)),
            const SizedBox(height: 2),
            Text('${item.teamA}  vs  ${item.teamB}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, height: 1.05)),
            const SizedBox(height: 2),
            Text(tournamentMatchDateText(item.match), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 10)),
          ])),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(color: item.played ? AppColors.greenSoft : AppColors.orangeSoft, borderRadius: BorderRadius.circular(999)),
            child: Text(score, style: TextStyle(color: item.played ? AppColors.green : AppColors.orange, fontWeight: FontWeight.w900, fontSize: 11)),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        ]),
      ),
    );
  }
}

class TournamentIconBadge extends StatelessWidget {
  final String scoringType;
  final bool finished;
  const TournamentIconBadge({super.key, required this.scoringType, this.finished = false});
  @override
  Widget build(BuildContext context) {
    final icon = switch (scoringType) {
      'football' => Icons.sports_soccer_rounded,
      'tennis_padel' => Icons.sports_tennis_rounded,
      'basketball' => Icons.sports_basketball_rounded,
      'cards_mus' => Icons.style_rounded,
      _ => Icons.emoji_events_rounded,
    };
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(color: finished ? AppColors.faint : AppColors.navyDeep, borderRadius: BorderRadius.circular(15)),
      child: Icon(icon, color: finished ? AppColors.muted : Colors.white, size: 24),
    );
  }
}

class TournamentCleanEmptyState extends StatelessWidget {
  final VoidCallback onCreate;
  const TournamentCleanEmptyState({super.key, required this.onCreate});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 58, height: 58, decoration: BoxDecoration(color: AppColors.tealSoft, borderRadius: BorderRadius.circular(20)), child: const Icon(Icons.emoji_events_rounded, color: AppColors.teal, size: 29)),
        const SizedBox(height: 14),
        const Text('Crea tu primera competición', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 19, letterSpacing: -.2)),
        const SizedBox(height: 6),
        const Text('Organiza una liga, eliminatoria, americano o partidos manuales. La app te crea partidos, tabla, resultados y agenda.', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, height: 1.35)),
        const SizedBox(height: 16),
        PrimaryButton(label: 'Crear torneo o liga', icon: Icons.add_rounded, onTap: onCreate),
      ]),
    ),
    const SizedBox(height: 12),
    AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
        Text('Elige según tu grupo', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
        SizedBox(height: 10),
        TournamentEmptyTip(icon: Icons.table_chart_rounded, title: 'Liga', body: 'Varias jornadas con clasificación.'),
        TournamentEmptyTip(icon: Icons.account_tree_rounded, title: 'Eliminatoria', body: 'Copa rápida con rondas.'),
        TournamentEmptyTip(icon: Icons.edit_calendar_rounded, title: 'Manual', body: 'Tú decides los cruces y fechas.'),
        TournamentEmptyTip(icon: Icons.shuffle_rounded, title: 'Americano', body: 'Rondas rotativas para pádel o tenis.'),
      ]),
    ),
  ]);
}

class TournamentEmptyTip extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const TournamentEmptyTip({super.key, required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Row(children: [
      Container(width: 34, height: 34, decoration: BoxDecoration(color: AppColors.faint, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: AppColors.blue, size: 18)),
      const SizedBox(width: 10),
      Expanded(child: RichText(text: TextSpan(style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, height: 1.2), children: [
        TextSpan(text: '$title: ', style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
        TextSpan(text: body),
      ]))),
    ]),
  );
}

class TournamentEmptyState extends StatelessWidget {
  final VoidCallback onCreate;
  const TournamentEmptyState({super.key, required this.onCreate});
  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 54, height: 54, decoration: BoxDecoration(color: AppColors.redSoft, borderRadius: BorderRadius.circular(18)), child: const Icon(Icons.emoji_events_rounded, color: AppColors.red)),
      const SizedBox(height: 12),
      const Text('Crea tu primer torneo', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 17)),
      const SizedBox(height: 5),
      const Text('Liga, eliminatoria, americano o manual. Con partidos, tabla y estadísticas.', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, height: 1.3)),
      const SizedBox(height: 14),
      PrimaryButton(label: 'Crear torneo o liga', icon: Icons.add_rounded, onTap: onCreate),
    ]),
  );
}

class TournamentStepIndicator extends StatelessWidget {
  final int step;
  final int total;
  const TournamentStepIndicator({super.key, required this.step, this.total = 5});
  @override
  Widget build(BuildContext context) => Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(total, (index) {
    final selected = index == step;
    final done = index < step;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: selected ? 27 : 22,
      height: selected ? 27 : 22,
      decoration: BoxDecoration(color: selected || done ? AppColors.red : AppColors.faint, shape: BoxShape.circle, border: Border.all(color: selected || done ? AppColors.red : AppColors.line)),
      child: Center(child: Text('${index + 1}', style: TextStyle(color: selected || done ? Colors.white : AppColors.muted, fontSize: 11, fontWeight: FontWeight.w900))),
    );
  }));
}


class TournamentCreationHeroCard extends StatelessWidget {
  const TournamentCreationHeroCard({super.key});

  @override
  Widget build(BuildContext context) => AppCard(
    color: AppColors.navyDeep,
    padding: const EdgeInsets.all(15),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(color: Colors.white.withOpacity(.12), borderRadius: BorderRadius.circular(16)),
        child: const Center(child: Text('🏆', style: TextStyle(fontSize: 25))),
      ),
      const SizedBox(width: 12),
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Crea un torneo sin complicarte', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17, height: 1.1)),
        SizedBox(height: 5),
        Text('Elige una plantilla rápida. Si quieres tocarlo todo, activa el modo avanzado.', style: TextStyle(color: Color(0xDFFFFFFF), fontWeight: FontWeight.w700, height: 1.25)),
      ])),
    ]),
  );
}

IconData tournamentTemplateIcon(String value) {
  switch (value) {
    case 'americano_padel':
      return Icons.sync_alt_rounded;
    case 'quick_cup':
      return Icons.account_tree_rounded;
    case 'manual_day':
      return Icons.tune_rounded;
    case 'league':
    default:
      return Icons.table_chart_rounded;
  }
}

class TournamentQuickTemplate {
  final String value;
  final String emoji;
  final String title;
  final String body;
  final String badge;
  const TournamentQuickTemplate(this.value, this.emoji, this.title, this.body, {this.badge = ''});
}

class TournamentQuickTemplateGrid extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  const TournamentQuickTemplateGrid({super.key, required this.selected, required this.onChanged});

  static const templates = [
    TournamentQuickTemplate('league', '', 'Liga', 'Jornadas y clasificación'),
    TournamentQuickTemplate('americano_padel', '', 'Americano', 'Rondas y ranking individual'),
    TournamentQuickTemplate('quick_cup', '', 'Eliminatoria', 'Cuadro, semifinal y final'),
    TournamentQuickTemplate('manual_day', '', 'Manual', 'Tú decides los partidos'),
  ];

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: templates.map((item) {
      final active = selected == item.value;
      return InkWell(
        onTap: () => onChanged(item.value),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 154,
          constraints: const BoxConstraints(minHeight: 112),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: active ? AppColors.redSoft : AppColors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: active ? AppColors.red : AppColors.line),
            boxShadow: active ? [BoxShadow(color: AppColors.red.withOpacity(.10), blurRadius: 16, offset: const Offset(0, 8))] : null,
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: active ? AppColors.red : AppColors.faint, borderRadius: BorderRadius.circular(12)),
                child: Icon(tournamentTemplateIcon(item.value), color: active ? Colors.white : AppColors.muted, size: 18),
              ),
              const Spacer(),
              if (item.badge.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.red, borderRadius: BorderRadius.circular(999)),
                  child: Text(item.badge, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 9)),
                ),
            ]),
            const SizedBox(height: 8),
            Text(item.title, style: TextStyle(color: active ? AppColors.red : AppColors.ink, fontWeight: FontWeight.w900, fontSize: 13.5)),
            const SizedBox(height: 3),
            Text(item.body, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 11, height: 1.2)),
          ]),
        ),
      );
    }).toList(),
  );
}

class TournamentAdvancedToggleCard extends StatelessWidget {
  final bool enabled;
  final ValueChanged<bool> onChanged;
  const TournamentAdvancedToggleCard({super.key, required this.enabled, required this.onChanged});

  @override
  Widget build(BuildContext context) => AppCard(
    color: enabled ? AppColors.orangeSoft : AppColors.faint,
    padding: const EdgeInsets.all(12),
    child: Row(children: [
      Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: Icon(enabled ? Icons.tune_rounded : Icons.auto_awesome_rounded, color: enabled ? AppColors.orange : AppColors.teal),
      ),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(enabled ? 'Modo avanzado activo' : 'Modo rápido recomendado', style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
        const SizedBox(height: 3),
        Text(enabled ? 'Puedes tocar formato, rondas, vueltas, cruces y reglas.' : 'Sigues los mismos pasos, pero la app oculta ajustes técnicos y aplica valores seguros.', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 12)),
      ])),
      Switch(value: enabled, activeThumbColor: AppColors.orange, onChanged: onChanged),
    ]),
  );
}

class TournamentQuickModeInfoCard extends StatelessWidget {
  const TournamentQuickModeInfoCard({super.key});

  @override
  Widget build(BuildContext context) => AppCard(
    color: AppColors.tealSoft,
    padding: const EdgeInsets.all(11),
    child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(Icons.info_outline_rounded, color: AppColors.teal, size: 20),
      SizedBox(width: 9),
      Expanded(child: Text(
        'Modo rápido: eliges Liga, Americano, Eliminatoria o Manual y sigues el mismo proceso, pero sin ajustes técnicos innecesarios.',
        style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800, height: 1.25, fontSize: 12),
      )),
    ]),
  );
}

class TournamentSimpleFormatSummary extends StatelessWidget {
  final String format;
  final String scoringType;
  final String teamType;
  const TournamentSimpleFormatSummary({super.key, required this.format, required this.scoringType, required this.teamType});

  @override
  Widget build(BuildContext context) => AppCard(
    color: AppColors.tealSoft,
    padding: const EdgeInsets.all(12),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 42, height: 42, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)), child: Center(child: Text(scoringEmoji(scoringType), style: const TextStyle(fontSize: 23)))),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${tournamentFormatLabel(format)} · ${teamTypeLabel(teamType)}', style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text('${scoringTypeLabel(scoringType)} · ${tournamentFormatSubtitle(format)}', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, height: 1.25, fontSize: 12)),
      ])),
    ]),
  );
}

class TournamentSimpleFormatConfigCard extends StatelessWidget {
  final String format;
  final int rounds;
  final int courts;
  final ValueChanged<int> onRoundsChanged;
  final ValueChanged<int> onCourtsChanged;
  const TournamentSimpleFormatConfigCard({super.key, required this.format, required this.rounds, required this.courts, required this.onRoundsChanged, required this.onCourtsChanged});

  @override
  Widget build(BuildContext context) {
    if (format == 'manual' || format == 'eliminatoria') {
      return AppCard(color: AppColors.faint, child: Text(format == 'manual'
          ? 'Manual: añade cruces con selectores y fecha individual. Puedes importar texto si prefieres.'
          : 'Eliminatoria: la app crea cuadro, byes, cabezas de serie, siguiente ronda y tercer puesto.',
        style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, height: 1.3),
      ));
    }
    return AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(format == 'americano' ? 'Configuración rápida de americano' : 'Configuración rápida de liga', style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
      const SizedBox(height: 10),
      if (format == 'americano')
        TournamentCounterRow(label: 'Rondas', value: rounds <= 0 ? 5 : rounds, min: 1, max: 20, onChanged: onRoundsChanged, helper: 'ranking individual')
      else
        TournamentCounterRow(label: 'Jornadas límite', value: rounds, min: 0, max: 30, zeroLabel: 'Todas', onChanged: onRoundsChanged, helper: 'déjalo en Todas para liga completa'),
      TournamentCounterRow(label: 'Pistas / mesas', value: courts, min: 1, max: 12, onChanged: onCourtsChanged, helper: courts <= 1 ? 'una a la vez' : 'en paralelo'),
    ]));
  }
}

class TournamentSportPreset {
  final String value;
  final String emoji;
  final String title;
  final String body;
  const TournamentSportPreset(this.value, this.emoji, this.title, this.body);
}

class TournamentSportEmojiPicker extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const TournamentSportEmojiPicker({super.key, required this.value, required this.onChanged});

  static const presets = [
    TournamentSportPreset('football', '⚽', 'Fútbol', 'Goles'),
    TournamentSportPreset('tennis_padel', '🎾', 'Pádel/Tenis', 'Sets'),
    TournamentSportPreset('basketball', '🏀', 'Basket', 'Puntos'),
    TournamentSportPreset('volleyball', '🏐', 'Voleibol', 'Sets'),
    TournamentSportPreset('ping_pong', '🏓', 'Ping pong', 'A 11'),
    TournamentSportPreset('cards_mus', '🃏', 'Mus/Cartas', 'Tantos'),
    TournamentSportPreset('darts', '🎯', 'Dardos', '301/501'),
    TournamentSportPreset('billiards', '🎱', 'Billar', 'Partidas'),
    TournamentSportPreset('esports', '🎮', 'Gaming', 'Mapas'),
    TournamentSportPreset('custom', '✨', 'Libre', 'Avanzado'),
  ];

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: presets.map((item) {
      final selected = item.value == value;
      return InkWell(
        onTap: () => onChanged(item.value),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 103,
          constraints: const BoxConstraints(minHeight: 92),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: selected ? AppColors.redSoft : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? AppColors.red : AppColors.line),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Text(item.emoji, style: const TextStyle(fontSize: 25)),
            const SizedBox(height: 6),
            Text(item.title, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: selected ? AppColors.red : AppColors.ink, fontWeight: FontWeight.w900, fontSize: 11.5)),
            const SizedBox(height: 2),
            Text(item.body, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 10)),
          ]),
        ),
      );
    }).toList(),
  );
}

class TournamentValidationCard extends StatelessWidget {
  final String scoringType;
  final Map<String, dynamic> scoringConfig;
  const TournamentValidationCard({super.key, required this.scoringType, required this.scoringConfig});

  @override
  Widget build(BuildContext context) => AppCard(
    color: AppColors.blueSoft,
    padding: const EdgeInsets.all(12),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 36, height: 36, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.verified_rounded, color: AppColors.blue, size: 20)),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${scoringEmoji(scoringType)} ${scoringTypeLabel(scoringType)}', style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(scoringValidationText(scoringType, scoringConfig), style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800, height: 1.25, fontSize: 12)),
      ])),
    ]),
  );
}

void showPremiumUpsellDialog(BuildContext context, {String feature = 'Torneos Pro'}) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Grupli Premium'),
      content: const Text('Preparado para pago mensual: sin anuncios, torneos ilimitados, estadísticas avanzadas, exportar PDF/imagen, fase de grupos + playoff, doble eliminación, suizo, recordatorios y página pública.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
        FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Próximamente')),
      ],
    ),
  );
}

class TournamentPremiumBanner extends StatelessWidget {
  const TournamentPremiumBanner({super.key});

  @override
  Widget build(BuildContext context) => AppCard(
    color: AppColors.faint,
    padding: const EdgeInsets.all(12),
    onTap: () => showPremiumUpsellDialog(context),
    child: Row(children: [
      Container(width: 38, height: 38, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13)), child: const Center(child: Text('👑', style: TextStyle(fontSize: 21)))),
      const SizedBox(width: 10),
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Torneos Pro preparado', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
        SizedBox(height: 3),
        Text('Sin anuncios, formatos avanzados y estadísticas premium.', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 12)),
      ])),
      const Icon(Icons.chevron_right_rounded, color: AppColors.orange),
    ]),
  );
}

class TournamentPremiumMiniCard extends StatelessWidget {
  const TournamentPremiumMiniCard({super.key});

  @override
  Widget build(BuildContext context) => AppCard(
    color: AppColors.tealSoft,
    padding: const EdgeInsets.all(12),
    child: Row(children: [
      const Text('👑', style: TextStyle(fontSize: 22)),
      const SizedBox(width: 10),
      const Expanded(child: Text('Premium preparado: exports, grupos + playoff, suizo, doble eliminación y stats avanzadas.', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800, height: 1.25))),
      TextButton(onPressed: () => showPremiumUpsellDialog(context), child: const Text('Ver')),
    ]),
  );
}

class TournamentPremiumSettingsCard extends StatelessWidget {
  const TournamentPremiumSettingsCard({super.key});

  @override
  Widget build(BuildContext context) => AppCard(
    color: AppColors.faint,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Opciones Premium preparadas', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: const [
        TournamentRuleChip(label: 'Exportar PDF/imagen'),
        TournamentRuleChip(label: 'Página pública'),
        TournamentRuleChip(label: 'Stats avanzadas'),
        TournamentRuleChip(label: 'Recordatorios'),
      ]),
      const SizedBox(height: 10),
      SecondaryButton(label: 'Ver Premium', icon: Icons.workspace_premium_rounded, onTap: () => showPremiumUpsellDialog(context)),
    ]),
  );
}


class TournamentBigChoice extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title;
  final String body;
  final String? badge;
  final VoidCallback onTap;
  const TournamentBigChoice({super.key, required this.selected, required this.icon, required this.title, required this.body, this.badge, required this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: AppCard(
      onTap: onTap,
      color: selected ? AppColors.redSoft : AppColors.white,
      padding: const EdgeInsets.all(13),
      child: Row(children: [
        Container(width: 48, height: 48, decoration: BoxDecoration(color: AppColors.red, borderRadius: BorderRadius.circular(15)), child: Icon(icon, color: Colors.white)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(title, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 16))),
            if (badge != null) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: AppColors.red, borderRadius: BorderRadius.circular(999)), child: Text(badge!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 9))),
          ]),
          const SizedBox(height: 3),
          Text(body, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 12, height: 1.25)),
        ])),
        const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
      ]),
    ),
  );
}

class TournamentChoice {
  final String value;
  final String title;
  final String body;
  final IconData icon;
  const TournamentChoice(this.value, this.title, this.body, this.icon);
}

class TournamentChoiceGrid extends StatelessWidget {
  final String value;
  final List<TournamentChoice> options;
  final ValueChanged<String> onChanged;
  const TournamentChoiceGrid({super.key, required this.value, required this.options, required this.onChanged});

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: options.map((option) {
      final selected = option.value == value;
      return InkWell(
        onTap: () => onChanged(option.value),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 102,
          constraints: const BoxConstraints(minHeight: 90),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: selected ? AppColors.redSoft : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? AppColors.red : AppColors.line),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Icon(option.icon, color: selected ? AppColors.red : AppColors.muted, size: 24),
            const SizedBox(height: 7),
            Text(option.title, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: selected ? AppColors.red : AppColors.ink, fontWeight: FontWeight.w900, fontSize: 12)),
            const SizedBox(height: 2),
            Text(option.body, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 10)),
          ]),
        ),
      );
    }).toList(),
  );
}

class TournamentRuleChip extends StatelessWidget {
  final String label;
  const TournamentRuleChip({super.key, required this.label});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(color: Colors.white.withOpacity(.75), borderRadius: BorderRadius.circular(999), border: Border.all(color: AppColors.lineSoft)),
    child: Text(label, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w900, fontSize: 11)),
  );
}

class TournamentDraftMatchTile extends StatelessWidget {
  final TournamentDraftMatch match;
  const TournamentDraftMatchTile({super.key, required this.match});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(children: [
        SizedBox(width: 32, child: Text('${match.round}', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w900))),
        Expanded(child: Text(match.teamAName, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, height: 1.05))),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('vs', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w900, fontSize: 11))),
        Expanded(child: Text(match.teamBName, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.end, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, height: 1.05))),
      ]),
    ),
  );
}

class TournamentSchedulePreviewTile extends StatelessWidget {
  final TournamentSchedulePreviewRow row;
  const TournamentSchedulePreviewTile({super.key, required this.row});

  @override
  Widget build(BuildContext context) {
    final date = row.scheduledAt == null ? 'Sin fecha' : DateFormat('EEE d MMM · HH:mm', 'es_ES').format(row.scheduledAt!);
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: AppColors.tealSoft, borderRadius: BorderRadius.circular(13)),
            child: Center(child: Text('${row.match.round}', style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.w900))),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${row.match.teamAName} vs ${row.match.teamBName}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, height: 1.05)),
            const SizedBox(height: 4),
            Text([
              date,
              if (row.courtName.trim().isNotEmpty) row.courtName.trim(),
            ].join(' · '), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800, fontSize: 11)),
          ])),
        ]),
      ),
    );
  }
}

class TournamentManualDraftRowCard extends StatelessWidget {
  final TournamentManualDraftRow row;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  const TournamentManualDraftRowCard({super.key, required this.row, required this.index, required this.onEdit, required this.onDelete, this.onMoveUp, this.onMoveDown});

  @override
  Widget build(BuildContext context) {
    final date = row.scheduledAt == null ? 'Sin fecha individual' : DateFormat('EEE d MMM · HH:mm', 'es_ES').format(row.scheduledAt!);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 34, height: 34, decoration: BoxDecoration(color: AppColors.redSoft, borderRadius: BorderRadius.circular(12)), child: Center(child: Text('${row.round}', style: const TextStyle(color: AppColors.red, fontWeight: FontWeight.w900)))),
            const SizedBox(width: 10),
            Expanded(child: Text('${row.teamAName} vs ${row.teamBName}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, height: 1.05))),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'up') onMoveUp?.call();
                if (value == 'down') onMoveDown?.call();
                if (value == 'delete') onDelete();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Editar partido')),
                if (onMoveUp != null) const PopupMenuItem(value: 'up', child: Text('Subir')),
                if (onMoveDown != null) const PopupMenuItem(value: 'down', child: Text('Bajar')),
                const PopupMenuItem(value: 'delete', child: Text('Retirar / eliminar')),
              ],
            ),
          ]),
          const SizedBox(height: 6),
          Text([
            date,
            if (row.courtName.trim().isNotEmpty) row.courtName.trim(),
            if (row.location.trim().isNotEmpty) row.location.trim(),
          ].join(' · '), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800, fontSize: 11)),
        ]),
      ),
    );
  }
}

class TournamentMatchEditorResult {
  final String teamAId;
  final String teamBId;
  final int round;
  final DateTime? scheduledAt;
  final int durationMinutes;
  final String location;
  final String courtName;
  final String notes;
  final bool syncAgenda;
  const TournamentMatchEditorResult({required this.teamAId, required this.teamBId, required this.round, this.scheduledAt, required this.durationMinutes, required this.location, required this.courtName, required this.notes, required this.syncAgenda});
}

Future<TournamentManualDraftRow?> showTournamentManualDraftDialog(
  BuildContext context, {
  required List<String> participants,
  TournamentManualDraftRow? initial,
  int defaultRound = 1,
  int defaultDuration = 60,
  String defaultLocation = '',
  String defaultCourtName = '',
  DateTime? defaultDate,
}) async {
  if (participants.length < 2) return null;
  String? teamA = participants.contains(initial?.teamAName) ? initial!.teamAName : participants.first;
  String? teamB = participants.contains(initial?.teamBName) ? initial!.teamBName : participants.firstWhere((p) => p != teamA, orElse: () => participants.last);
  final roundController = TextEditingController(text: '${initial?.round ?? defaultRound}');
  final durationController = TextEditingController(text: '${initial?.durationMinutes ?? defaultDuration}');
  final locationController = TextEditingController(text: initial?.location ?? defaultLocation);
  final courtController = TextEditingController(text: initial?.courtName ?? defaultCourtName);
  final notesController = TextEditingController(text: initial?.notes ?? '');
  var useDate = initial?.scheduledAt != null || defaultDate != null;
  DateTime selectedDate = initial?.scheduledAt ?? defaultDate ?? DateTime.now().add(const Duration(days: 1));
  TimeOfDay selectedTime = TimeOfDay(hour: selectedDate.hour, minute: selectedDate.minute);

  final row = await showDialog<TournamentManualDraftRow>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setLocal) => AlertDialog(
        title: Text(initial == null ? 'Añadir partido' : 'Editar partido'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          DropdownButtonFormField<String>(
            value: teamA,
            decoration: const InputDecoration(labelText: 'Participante A'),
            items: participants.map((name) => DropdownMenuItem(value: name, child: Text(name, overflow: TextOverflow.ellipsis))).toList(),
            onChanged: (v) => setLocal(() => teamA = v),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: teamB,
            decoration: const InputDecoration(labelText: 'Participante B'),
            items: participants.map((name) => DropdownMenuItem(value: name, child: Text(name, overflow: TextOverflow.ellipsis))).toList(),
            onChanged: (v) => setLocal(() => teamB = v),
          ),
          const SizedBox(height: 8),
          TextField(controller: roundController, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(labelText: 'Jornada')),
          CheckboxListTile(
            value: useDate,
            onChanged: (v) => setLocal(() => useDate = v == true),
            contentPadding: EdgeInsets.zero,
            title: const Text('Poner fecha individual'),
          ),
          if (useDate) Row(children: [
            Expanded(child: SecondaryButton(label: DateFormat('d MMM', 'es_ES').format(selectedDate), icon: Icons.calendar_today_rounded, onTap: () async {
              final picked = await showDatePicker(context: dialogContext, initialDate: selectedDate, firstDate: DateTime.now().subtract(const Duration(days: 365)), lastDate: DateTime.now().add(const Duration(days: 730)), locale: const Locale('es', 'ES'));
              if (picked != null) setLocal(() => selectedDate = DateTime(picked.year, picked.month, picked.day, selectedDate.hour, selectedDate.minute));
            })),
            const SizedBox(width: 8),
            Expanded(child: SecondaryButton(label: selectedTime.format(dialogContext), icon: Icons.schedule_rounded, onTap: () async {
              final picked = await showTimePicker(context: dialogContext, initialTime: selectedTime);
              if (picked != null) setLocal(() { selectedTime = picked; selectedDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, picked.hour, picked.minute); });
            })),
          ]),
          const SizedBox(height: 8),
          TextField(controller: durationController, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(labelText: 'Duración minutos')),
          const SizedBox(height: 8),
          TextField(controller: courtController, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Pista / mesa / campo')),
          const SizedBox(height: 8),
          TextField(controller: locationController, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Ubicación')),
          const SizedBox(height: 8),
          TextField(controller: notesController, minLines: 2, maxLines: 4, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Notas')),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          FilledButton(
            onPressed: teamA == null || teamB == null || teamA == teamB ? null : () => Navigator.pop(dialogContext, TournamentManualDraftRow(
              round: max(1, int.tryParse(roundController.text.trim()) ?? defaultRound),
              teamAName: teamA!,
              teamBName: teamB!,
              scheduledAt: useDate ? DateTime(selectedDate.year, selectedDate.month, selectedDate.day, selectedTime.hour, selectedTime.minute) : null,
              durationMinutes: max(15, int.tryParse(durationController.text.trim()) ?? defaultDuration),
              location: locationController.text.trim(),
              courtName: courtController.text.trim(),
              notes: notesController.text.trim(),
            )),
            child: const Text('Guardar'),
          ),
        ],
      ),
    ),
  );
  roundController.dispose();
  durationController.dispose();
  locationController.dispose();
  courtController.dispose();
  notesController.dispose();
  return row;
}

Future<TournamentMatchEditorResult?> showTournamentMatchEditorDialog(BuildContext context, {required List<Map<String, dynamic>> teams, int defaultRound = 1}) async {
  if (teams.length < 2) return null;
  final ids = teams.map((t) => AppData.text(t['id'])).where((id) => id.isNotEmpty).toList();
  final names = teamNameMap(teams);
  String? teamA = ids.first;
  String? teamB = ids.firstWhere((id) => id != teamA, orElse: () => ids.last);
  final roundController = TextEditingController(text: '$defaultRound');
  final durationController = TextEditingController(text: '60');
  final locationController = TextEditingController();
  final courtController = TextEditingController();
  final notesController = TextEditingController();
  var useDate = false;
  var syncAgenda = true;
  DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay selectedTime = const TimeOfDay(hour: 20, minute: 0);

  final result = await showDialog<TournamentMatchEditorResult>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setLocal) => AlertDialog(
        title: const Text('Añadir partido manual'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          DropdownButtonFormField<String>(
            value: teamA,
            decoration: const InputDecoration(labelText: 'Participante A'),
            items: ids.map((id) => DropdownMenuItem(value: id, child: Text(names[id] ?? 'Participante'))).toList(),
            onChanged: (v) => setLocal(() => teamA = v),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: teamB,
            decoration: const InputDecoration(labelText: 'Participante B'),
            items: ids.map((id) => DropdownMenuItem(value: id, child: Text(names[id] ?? 'Participante'))).toList(),
            onChanged: (v) => setLocal(() => teamB = v),
          ),
          const SizedBox(height: 8),
          TextField(controller: roundController, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(labelText: 'Jornada')),
          CheckboxListTile(value: useDate, onChanged: (v) => setLocal(() => useDate = v == true), contentPadding: EdgeInsets.zero, title: const Text('Programar fecha')),
          if (useDate) Row(children: [
            Expanded(child: SecondaryButton(label: DateFormat('d MMM', 'es_ES').format(selectedDate), icon: Icons.calendar_today_rounded, onTap: () async {
              final picked = await showDatePicker(context: dialogContext, initialDate: selectedDate, firstDate: DateTime.now().subtract(const Duration(days: 365)), lastDate: DateTime.now().add(const Duration(days: 730)), locale: const Locale('es', 'ES'));
              if (picked != null) setLocal(() => selectedDate = DateTime(picked.year, picked.month, picked.day, selectedTime.hour, selectedTime.minute));
            })),
            const SizedBox(width: 8),
            Expanded(child: SecondaryButton(label: selectedTime.format(dialogContext), icon: Icons.schedule_rounded, onTap: () async {
              final picked = await showTimePicker(context: dialogContext, initialTime: selectedTime);
              if (picked != null) setLocal(() { selectedTime = picked; selectedDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, picked.hour, picked.minute); });
            })),
          ]),
          const SizedBox(height: 8),
          TextField(controller: durationController, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(labelText: 'Duración minutos')),
          const SizedBox(height: 8),
          TextField(controller: courtController, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Pista / mesa / campo')),
          const SizedBox(height: 8),
          TextField(controller: locationController, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Ubicación')),
          const SizedBox(height: 8),
          TextField(controller: notesController, minLines: 2, maxLines: 4, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Notas')),
          if (useDate) CheckboxListTile(value: syncAgenda, onChanged: (v) => setLocal(() => syncAgenda = v == true), contentPadding: EdgeInsets.zero, title: const Text('Añadir a Agenda')),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          FilledButton(
            onPressed: teamA == null || teamB == null || teamA == teamB ? null : () => Navigator.pop(dialogContext, TournamentMatchEditorResult(
              teamAId: teamA!,
              teamBId: teamB!,
              round: max(1, int.tryParse(roundController.text.trim()) ?? defaultRound),
              scheduledAt: useDate ? DateTime(selectedDate.year, selectedDate.month, selectedDate.day, selectedTime.hour, selectedTime.minute) : null,
              durationMinutes: max(15, int.tryParse(durationController.text.trim()) ?? 60),
              location: locationController.text.trim(),
              courtName: courtController.text.trim(),
              notes: notesController.text.trim(),
              syncAgenda: syncAgenda,
            )),
            child: const Text('Añadir'),
          ),
        ],
      ),
    ),
  );
  roundController.dispose();
  durationController.dispose();
  locationController.dispose();
  courtController.dispose();
  notesController.dispose();
  return result;
}

Future<int?> showTournamentDuplicateRoundDialog(BuildContext context, {required List<Map<String, dynamic>> matches}) async {
  final rounds = matches.map((m) => AppData.intValue(m['round'], 1)).toSet().toList()..sort();
  if (rounds.isEmpty) return null;
  var selected = rounds.last;
  return showDialog<int>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setLocal) => AlertDialog(
        title: const Text('Duplicar jornada'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Se copiarán los mismos cruces en una jornada nueva, sin resultados ni fecha.', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            value: selected,
            decoration: const InputDecoration(labelText: 'Jornada a duplicar'),
            items: rounds.map((round) => DropdownMenuItem(value: round, child: Text('Jornada $round'))).toList(),
            onChanged: (v) => setLocal(() => selected = v ?? selected),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, selected), child: const Text('Duplicar')),
        ],
      ),
    ),
  );
}

class TournamentReviewRow extends StatelessWidget {
  final String label;
  final String value;
  const TournamentReviewRow({super.key, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(children: [
      Expanded(child: Text(label, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800))),
      Flexible(child: Text(value, textAlign: TextAlign.end, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900))),
    ]),
  );
}


class TournamentCounterRow extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final int stepValue;
  final String? zeroLabel;
  final String? helper;
  final ValueChanged<int> onChanged;
  const TournamentCounterRow({super.key, required this.label, required this.value, required this.min, required this.max, this.stepValue = 1, this.zeroLabel, this.helper, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final shown = value == 0 && zeroLabel != null ? zeroLabel! : value.toString();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
          if (helper != null) Text(helper!, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 11)),
        ])),
        IconButton(onPressed: value <= min ? null : () => onChanged(value - stepValue < min ? min : value - stepValue), icon: const Icon(Icons.remove_circle_outline_rounded)),
        Container(
          width: 58,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(color: AppColors.faint, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.line)),
          child: Text(shown, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
        ),
        IconButton(onPressed: value >= max ? null : () => onChanged(value + stepValue > max ? max : value + stepValue), icon: const Icon(Icons.add_circle_outline_rounded)),
      ]),
    );
  }
}

class TournamentDetailHero extends StatelessWidget {
  final Map<String, dynamic> tournament;
  final TeamStanding? leader;
  final int teams;
  final int played;
  final int total;
  final int pending;
  final VoidCallback onAdd;
  final VoidCallback onGenerate;
  const TournamentDetailHero({super.key, required this.tournament, required this.leader, required this.teams, required this.played, required this.total, required this.pending, required this.onAdd, required this.onGenerate});

  @override
  Widget build(BuildContext context) {
    final progress = total <= 0 ? 0.0 : (played / total).clamp(0.0, 1.0);
    final scoringType = AppData.text(tournament['scoring_type'], 'general');
    return AppCard(
      color: AppColors.navyDeep,
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          TournamentIconBadge(scoringType: scoringType),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 7, height: 7, decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(AppData.text(tournament['status'], 'active') == 'finished' ? 'Finalizada' : 'En curso', style: const TextStyle(color: Color(0xDFFFFFFF), fontWeight: FontWeight.w800, fontSize: 12)),
            ]),
            const SizedBox(height: 4),
            Text(total == 0 ? 'Genera los partidos para empezar.' : '$played de $total resultados registrados', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17, height: 1.1)),
          ])),
          FilledButton.icon(onPressed: total == 0 ? onGenerate : onAdd, icon: Icon(total == 0 ? Icons.auto_awesome_motion_rounded : Icons.group_add_rounded, size: 18), label: Text(total == 0 ? 'Generar' : 'Añadir'), style: FilledButton.styleFrom(backgroundColor: AppColors.red, foregroundColor: Colors.white)),
        ]),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(value: progress, minHeight: 8, color: AppColors.green, backgroundColor: Colors.white.withOpacity(.18)),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: TournamentHeroStat(value: '$teams', label: 'Equipos')),
          const SizedBox(width: 8),
          Expanded(child: TournamentHeroStat(value: '$pending', label: 'Pendientes')),
          const SizedBox(width: 8),
          Expanded(child: TournamentHeroStat(value: leader?.points.toString() ?? '0', label: leader == null ? 'Puntos líder' : leader!.name)),
        ]),
      ]),
    );
  }
}

class TournamentHeroStat extends StatelessWidget {
  final String value;
  final String label;
  const TournamentHeroStat({super.key, required this.value, required this.label});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: Colors.white.withOpacity(.10), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withOpacity(.10))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17)),
      const SizedBox(height: 2),
      Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xCFFFFFFF), fontWeight: FontWeight.w800, fontSize: 10.5)),
    ]),
  );
}

class TournamentTabsBar extends StatelessWidget {
  final int index;
  final String format;
  final ValueChanged<int> onChanged;
  const TournamentTabsBar({super.key, required this.index, this.format = 'liga', required this.onChanged});
  @override
  Widget build(BuildContext context) {
    final items = [
      const ('Resumen', Icons.dashboard_rounded),
      const ('Partidos', Icons.sports_score_rounded),
      (format == 'eliminatoria' ? 'Cuadro' : 'Tabla', format == 'eliminatoria' ? Icons.account_tree_rounded : Icons.table_chart_rounded),
      const ('Stats', Icons.query_stats_rounded),
      const ('Equipos', Icons.groups_rounded),
      const ('Ajustes', Icons.tune_rounded),
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.navyDeep, borderRadius: BorderRadius.circular(16)),
      child: Row(children: List.generate(items.length, (i) {
        final selected = i == index;
        return Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(13),
            onTap: () => onChanged(i),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(color: selected ? AppColors.red : Colors.transparent, borderRadius: BorderRadius.circular(13)),
              child: Text(items[i].$1, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: selected ? Colors.white : const Color(0xCFFFFFFF))),
            ),
          ),
        );
      })),
    );
  }
}

class TournamentOverviewPanel extends StatelessWidget {
  final Map<String, dynamic> tournament;
  final List<Map<String, dynamic>> teams;
  final List<Map<String, dynamic>> matches;
  final List<TeamStanding> standings;
  final VoidCallback onAddParticipants;
  final VoidCallback onGenerate;
  final VoidCallback onManualMatches;
  final VoidCallback onBulkSchedule;
  final VoidCallback? onNextRound;
  final VoidCallback onChanged;
  const TournamentOverviewPanel({super.key, required this.tournament, required this.teams, required this.matches, required this.standings, required this.onAddParticipants, required this.onGenerate, required this.onManualMatches, required this.onBulkSchedule, this.onNextRound, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final pendingAll = matches.where((m) => !matchCountsForStandings(m) && !['cancelled', 'bye'].contains(AppData.text(m['status']))).toList();
    final pending = pendingAll.take(4).toList();
    final names = teamNameMap(teams);
    final format = AppData.text(tournament['format'], 'liga');
    final nextTitle = teams.length < 2
        ? 'Añade participantes'
        : matches.isEmpty
            ? 'Genera los partidos'
            : pendingAll.isEmpty
                ? 'Competición lista para cerrar'
                : 'Siguiente partido pendiente';
    final nextBody = teams.length < 2
        ? 'Primero elige quién juega. Puedes añadir equipos, parejas o jugadores.'
        : matches.isEmpty
            ? 'Crea el calendario para ver jornadas, fechas y resultados.'
            : pendingAll.isEmpty
                ? 'Todos los partidos están jugados. Revisa la tabla y finaliza desde Ajustes.'
                : 'Toca un partido para registrar resultado, cambiar fecha o aplazarlo.';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TournamentNextStepCard(title: nextTitle, body: nextBody, icon: teams.length < 2 ? Icons.group_add_rounded : matches.isEmpty ? Icons.auto_awesome_motion_rounded : pendingAll.isEmpty ? Icons.verified_rounded : Icons.sports_score_rounded),
      const SizedBox(height: 12),
      if (teams.length < 2)
        EmptySlim(icon: Icons.group_add_rounded, title: 'Añade participantes', body: 'Necesitas al menos dos equipos, parejas o jugadores.')
      else if (matches.isEmpty)
        AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Calendario pendiente', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(format == 'manual' ? 'Añade los emparejamientos manuales para empezar.' : 'Genera todos los partidos automáticamente según el formato elegido.', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          PrimaryButton(label: format == 'manual' ? 'Añadir partidos' : 'Generar partidos', icon: format == 'manual' ? Icons.add_link_rounded : Icons.auto_awesome_motion_rounded, onTap: format == 'manual' ? onManualMatches : onGenerate),
        ]))
      else ...[
        SectionHeader(title: 'Próximo partido'),
        const SizedBox(height: 8),
        if (pending.isEmpty)
          EmptySlim(icon: Icons.verified_rounded, title: 'Todo jugado', body: onNextRound == null ? 'Puedes marcar la competición como finalizada.' : 'Puedes generar la siguiente ronda.')
        else
          ...pending.map((m) => TournamentSimpleMatchCard(match: m, teams: teams, scoringType: AppData.text(tournament['scoring_type'], 'general'), scoringConfig: tournament['scoring_config'], onChanged: onChanged)),
        if (onNextRound != null) ...[
          const SizedBox(height: 10),
          SecondaryButton(label: 'Generar siguiente ronda', icon: Icons.account_tree_rounded, onTap: onNextRound!),
        ],
        const SizedBox(height: 16),
        SectionHeader(title: 'Último resultado'),
        const SizedBox(height: 8),
        if (matches.where(matchCountsForStandings).isEmpty)
          EmptySlim(icon: Icons.sports_score_rounded, title: 'Sin resultados', body: 'Toca un partido para meter marcador.')
        else
          TournamentLatestResultCard(match: matches.where(matchCountsForStandings).last, names: names, scoringType: AppData.text(tournament['scoring_type'], 'general'), scoringConfig: tournament['scoring_config']),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: StatCard(icon: Icons.sports_score_rounded, value: '${matches.length}', label: 'Partidos', color: AppColors.red)),
          const SizedBox(width: 8),
          Expanded(child: StatCard(icon: Icons.done_all_rounded, value: '${matches.length - pendingAll.length}', label: 'Jugados', color: AppColors.green)),
          const SizedBox(width: 8),
          Expanded(child: StatCard(icon: Icons.percent_rounded, value: matches.isEmpty ? '0%' : '${(((matches.length - pendingAll.length) / matches.length) * 100).round()}%', label: 'Progreso', color: AppColors.blue)),
        ]),
        const SizedBox(height: 16),
        SectionHeader(title: 'Líder actual'),
        const SizedBox(height: 8),
        if (standings.isEmpty)
          EmptySlim(icon: Icons.table_chart_rounded, title: 'Sin clasificación', body: 'Registra resultados para calcular la tabla.')
        else
          TournamentStandingTile(standing: standings.first, scoringType: AppData.text(tournament['scoring_type'], 'general'), scoringConfig: tournament['scoring_config'], highlighted: true),
      ],
    ]);
  }
}

class TournamentNextStepCard extends StatelessWidget {
  final String title;
  final String body;
  final IconData icon;
  const TournamentNextStepCard({super.key, required this.title, required this.body, required this.icon});

  @override
  Widget build(BuildContext context) => AppCard(
    color: AppColors.tealSoft,
    padding: const EdgeInsets.all(13),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 42, height: 42, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: AppColors.teal, size: 22)),
      const SizedBox(width: 11),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 15)),
        const SizedBox(height: 4),
        Text(body, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, height: 1.25)),
      ])),
    ]),
  );
}



class TournamentEditFocusCard extends StatelessWidget {
  final Map<String, dynamic> tournament;
  final List<Map<String, dynamic>> teams;
  final List<Map<String, dynamic>> matches;
  final List<TeamStanding> standings;
  final VoidCallback onAddParticipants;
  final VoidCallback onBulkSchedule;
  final VoidCallback onManualMatches;
  final VoidCallback onCheckIn;
  const TournamentEditFocusCard({
    super.key,
    required this.tournament,
    required this.teams,
    required this.matches,
    required this.standings,
    required this.onAddParticipants,
    required this.onBulkSchedule,
    required this.onManualMatches,
    required this.onCheckIn,
  });

  @override
  Widget build(BuildContext context) {
    final names = teamNameMap(teams);
    final pending = matches.where((m) => !matchCountsForStandings(m) && !['cancelled', 'bye'].contains(AppData.text(m['status']))).toList();
    pending.sort((a, b) {
      final date = AppData.text(a['scheduled_at']).compareTo(AppData.text(b['scheduled_at']));
      if (date != 0) return date;
      final round = AppData.intValue(a['round']).compareTo(AppData.intValue(b['round']));
      if (round != 0) return round;
      return AppData.intValue(a['order_index']).compareTo(AppData.intValue(b['order_index']));
    });
    final next = pending.isNotEmpty ? pending.first : null;
    final format = AppData.text(tournament['format'], 'liga');
    final canAddManualMatch = format == 'manual' || format == 'liga';

    return AppCard(
      color: AppColors.navyDeep,
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: Colors.white.withOpacity(.12), borderRadius: BorderRadius.circular(15)),
            child: const Center(child: Text('✏️', style: TextStyle(fontSize: 23))),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Panel de edición', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17, height: 1.1)),
            const SizedBox(height: 4),
            Text(
              teams.isEmpty
                  ? 'Empieza añadiendo jugadores, parejas o equipos.'
                  : next == null
                      ? 'Todo está jugado. Puedes revisar tabla, participantes o ajustes.'
                      : 'Edita jugadores, fechas y partidos sin perder el control del torneo.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xDFFFFFFF), fontWeight: FontWeight.w700, height: 1.25),
            ),
          ])),
        ]),
        if (next != null) ...[
          const SizedBox(height: 10),
          TournamentLiveNowMini(match: next, teams: teams, names: names),
        ],
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: SecondaryButton(label: 'Añadir jugadores', icon: Icons.group_add_rounded, onTap: onAddParticipants)),
          const SizedBox(width: 8),
          Expanded(child: SecondaryButton(label: 'Cambiar fechas', icon: Icons.edit_calendar_rounded, onTap: onBulkSchedule)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          if (canAddManualMatch) ...[
            Expanded(child: SecondaryButton(label: 'Añadir partido', icon: Icons.add_link_rounded, onTap: onManualMatches)),
            const SizedBox(width: 8),
          ],
          Expanded(child: SecondaryButton(label: 'Check-in', icon: Icons.how_to_reg_rounded, onTap: onCheckIn)),
        ]),
      ]),
    );
  }
}


class TournamentLiveNowMini extends StatelessWidget {
  final Map<String, dynamic> match;
  final List<Map<String, dynamic>> teams;
  final Map<String, String> names;
  const TournamentLiveNowMini({super.key, required this.match, required this.teams, required this.names});

  @override
  Widget build(BuildContext context) {
    final rest = americanoRestText(match, names);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white.withOpacity(.10), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withOpacity(.10))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text([
          AppData.text(match['round_name'], 'Partido'),
          tournamentMatchDateText(match),
          if (AppData.text(match['court_name']).isNotEmpty) AppData.text(match['court_name']),
        ].join(' · '), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xCFFFFFFF), fontWeight: FontWeight.w800, fontSize: 11)),
        const SizedBox(height: 5),
        Text('${tournamentMatchSideName(match, names, true)} vs ${tournamentMatchSideName(match, names, false)}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, height: 1.1)),
        if (rest.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text('Descansan: $rest', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xDFFFFFFF), fontWeight: FontWeight.w700, fontSize: 11)),
        ],
      ]),
    );
  }
}

Future<void> showTournamentCheckInDialog(BuildContext context, {required List<Map<String, dynamic>> teams}) async {
  final checked = <String>{for (final team in teams) AppData.text(team['id'])};
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setLocal) => AlertDialog(
        title: const Text('Check-in de participantes'),
        content: SizedBox(
          width: double.maxFinite,
          child: teams.isEmpty
              ? const Text('Aún no hay participantes.')
              : SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: teams.map((team) {
                  final id = AppData.text(team['id']);
                  return CheckboxListTile(
                    value: checked.contains(id),
                    onChanged: (value) => setLocal(() {
                      if (value == true) {
                        checked.add(id);
                      } else {
                        checked.remove(id);
                      }
                    }),
                    title: Text(AppData.text(team['name'], 'Participante')),
                    subtitle: Text(checked.contains(id) ? 'Presente' : 'Falta'),
                  );
                }).toList())),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          FilledButton(onPressed: () {
            Navigator.pop(dialogContext);
            showToast(context, '${checked.length}/${teams.length} participantes marcados como presentes.');
          }, child: const Text('Guardar')),
        ],
      ),
    ),
  );
}



class TournamentEliminationBracketPanel extends StatelessWidget {
  final Map<String, dynamic> tournament;
  final Map<String, dynamic> group;
  final List<Map<String, dynamic>> matches;
  final List<Map<String, dynamic>> teams;
  final String scoringType;
  final Map<String, dynamic> scoringConfig;
  final VoidCallback onNextRound;
  final VoidCallback onThirdPlace;
  final VoidCallback onChanged;
  const TournamentEliminationBracketPanel({
    super.key,
    required this.tournament,
    required this.group,
    required this.matches,
    required this.teams,
    required this.scoringType,
    required this.scoringConfig,
    required this.onNextRound,
    required this.onThirdPlace,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      return EmptySlim(icon: Icons.account_tree_rounded, title: 'Cuadro pendiente', body: 'Genera los cruces para ver el cuadro de la eliminatoria.');
    }
    final names = teamNameMap(teams);
    final normalMatches = matches.where((m) => AppData.text(AppData.asMap(m['result_details'])['stage']) != 'third_place').toList();
    final thirdPlace = matches.where((m) => AppData.text(AppData.asMap(m['result_details'])['stage']) == 'third_place' || AppData.text(m['round_name']).toLowerCase().contains('tercer')).toList();
    final grouped = <int, List<Map<String, dynamic>>>{};
    for (final match in normalMatches) {
      final round = AppData.intValue(match['round'], 1);
      grouped.putIfAbsent(round, () => []).add(match);
    }
    final rounds = grouped.keys.toList()..sort();
    for (final round in rounds) {
      grouped[round]!.sort((a, b) => AppData.intValue(a['order_index']).compareTo(AppData.intValue(b['order_index'])));
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      AppCard(color: AppColors.tealSoft, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 42, height: 42, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.account_tree_rounded, color: AppColors.teal)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Cuadro de eliminatoria', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(height: 3),
            Text('${teams.length} participantes · ${matches.length} partidos · byes visibles', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700)),
          ])),
        ]),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: const [
          TournamentRuleChip(label: 'Cabezas de serie'),
          TournamentRuleChip(label: 'Pases directos'),
          TournamentRuleChip(label: 'Siguiente ronda'),
          TournamentRuleChip(label: 'Tercer puesto'),
        ]),
      ])),
      const SizedBox(height: 12),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (final round in rounds) ...[
            SizedBox(
              width: 270,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                TournamentBracketRoundHeader(roundName: AppData.text(grouped[round]!.first['round_name'], eliminationRoundNameForRemaining(grouped[round]!.length * 2)), count: grouped[round]!.length),
                const SizedBox(height: 8),
                ...grouped[round]!.map((match) => TournamentBracketMatchCard(match: match, teams: teams, names: names, scoringType: scoringType, scoringConfig: scoringConfig, onChanged: onChanged, group: group, tournamentName: AppData.text(tournament['name'], 'Torneo'))),
              ]),
            ),
            const SizedBox(width: 12),
          ],
          if (thirdPlace.isNotEmpty)
            SizedBox(
              width: 270,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                TournamentBracketRoundHeader(roundName: 'Tercer puesto', count: thirdPlace.length),
                const SizedBox(height: 8),
                ...thirdPlace.map((match) => TournamentBracketMatchCard(match: match, teams: teams, names: names, scoringType: scoringType, scoringConfig: scoringConfig, onChanged: onChanged, group: group, tournamentName: AppData.text(tournament['name'], 'Torneo'))),
              ]),
            ),
        ]),
      ),
      const SizedBox(height: 12),
      if (canGenerateEliminationNextRound(matches))
        SecondaryButton(label: 'Generar siguiente ronda', icon: Icons.account_tree_rounded, onTap: onNextRound),
      if (canGenerateEliminationNextRound(matches) && canCreateEliminationThirdPlace(matches)) const SizedBox(height: 8),
      if (canCreateEliminationThirdPlace(matches))
        SecondaryButton(label: 'Crear partido por el tercer puesto', icon: Icons.workspace_premium_rounded, onTap: onThirdPlace),
      if (!canGenerateEliminationNextRound(matches) && !canCreateEliminationThirdPlace(matches)) ...[
        const SizedBox(height: 4),
        EmptySlim(icon: Icons.info_outline_rounded, title: 'Cuadro al día', body: 'Cierra todos los partidos de la ronda actual para avanzar.')
      ],
    ]);
  }
}

class TournamentBracketRoundHeader extends StatelessWidget {
  final String roundName;
  final int count;
  const TournamentBracketRoundHeader({super.key, required this.roundName, required this.count});

  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: Text(roundName, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 15))),
    TournamentRuleChip(label: '$count'),
  ]);
}

class TournamentBracketMatchCard extends StatelessWidget {
  final Map<String, dynamic> match;
  final List<Map<String, dynamic>> teams;
  final Map<String, String> names;
  final String scoringType;
  final Map<String, dynamic> scoringConfig;
  final VoidCallback onChanged;
  final Map<String, dynamic> group;
  final String tournamentName;
  const TournamentBracketMatchCard({
    super.key,
    required this.match,
    required this.teams,
    required this.names,
    required this.scoringType,
    required this.scoringConfig,
    required this.onChanged,
    required this.group,
    required this.tournamentName,
  });

  @override
  Widget build(BuildContext context) {
    final status = AppData.text(match['status'], 'pending');
    final aId = AppData.text(match['team_a']);
    final bId = AppData.text(match['team_b']);
    final a = names[aId] ?? 'Pendiente';
    final b = bId.isEmpty || bId == 'null' ? 'Pase directo' : names[bId] ?? 'Pendiente';
    final winner = tournamentMatchWinnerId(match);
    final bye = status == 'bye' || b == 'Pase directo';
    final score = matchCountsForStandings(match) || bye ? '${AppData.intValue(match['score_a'])} - ${AppData.intValue(match['score_b'])}' : matchStatusLabel(status);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        color: bye ? AppColors.violetSoft : AppColors.white,
        padding: const EdgeInsets.all(11),
        onTap: bye ? null : () => showMatchResultDialog(context, match: match, teams: teams, scoringType: scoringType, scoringConfig: scoringConfig, onChanged: onChanged),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: matchStatusColor(status).withOpacity(.12), borderRadius: BorderRadius.circular(999)),
              child: Text(bye ? 'BYE' : matchStatusLabel(status), style: TextStyle(color: matchStatusColor(status), fontWeight: FontWeight.w900, fontSize: 10)),
            ),
            const SizedBox(width: 6),
            Expanded(child: Text(tournamentMatchDateText(match), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 10))),
          ]),
          const SizedBox(height: 9),
          TournamentBracketTeamLine(name: a, seed: tournamentSeedForTeam(teams, aId), winner: winner == aId),
          const SizedBox(height: 6),
          TournamentBracketTeamLine(name: b, seed: tournamentSeedForTeam(teams, bId), winner: winner == bId),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: Text(score, style: TextStyle(color: bye ? AppColors.violet : matchStatusColor(status), fontWeight: FontWeight.w900, fontSize: 12))),
            if (!bye) TextButton(onPressed: () => showMatchScheduleDialog(context, match: match, group: group, tournamentName: tournamentName, teams: teams, onChanged: onChanged), child: const Text('Fecha')),
          ]),
        ]),
      ),
    );
  }
}

class TournamentBracketTeamLine extends StatelessWidget {
  final String name;
  final int seed;
  final bool winner;
  const TournamentBracketTeamLine({super.key, required this.name, required this.seed, required this.winner});

  @override
  Widget build(BuildContext context) => Row(children: [
    Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(color: winner ? AppColors.green : AppColors.faint, borderRadius: BorderRadius.circular(10)),
      child: Center(child: Text(seed > 0 ? '$seed' : '-', style: TextStyle(color: winner ? Colors.white : AppColors.muted, fontWeight: FontWeight.w900, fontSize: 11))),
    ),
    const SizedBox(width: 8),
    Expanded(child: Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: winner ? AppColors.green : AppColors.ink, fontWeight: FontWeight.w900, height: 1.05))),
    if (winner) const Icon(Icons.check_circle_rounded, color: AppColors.green, size: 18),
  ]);
}

int tournamentSeedForTeam(List<Map<String, dynamic>> teams, String teamId) {
  if (teamId.isEmpty || teamId == 'null') return 0;
  for (final team in teams) {
    if (AppData.text(team['id']) == teamId) return AppData.intValue(team['seed']);
  }
  return 0;
}


class TournamentMatchesPanel extends StatefulWidget {
  final Map<String, dynamic> tournament;
  final Map<String, dynamic> group;
  final List<Map<String, dynamic>> matches;
  final List<Map<String, dynamic>> teams;
  final String scoringType;
  final Map<String, dynamic> scoringConfig;
  final VoidCallback onBulkSchedule;
  final VoidCallback onChanged;
  const TournamentMatchesPanel({super.key, required this.tournament, required this.group, required this.matches, required this.teams, required this.scoringType, required this.scoringConfig, required this.onBulkSchedule, required this.onChanged});

  @override
  State<TournamentMatchesPanel> createState() => _TournamentMatchesPanelState();
}

class _TournamentMatchesPanelState extends State<TournamentMatchesPanel> {
  String filter = 'all';

  List<Map<String, dynamic>> get filteredMatches {
    if (filter == 'played') return widget.matches.where(matchCountsForStandings).toList();
    if (filter == 'postponed') return widget.matches.where((m) => AppData.text(m['status']) == 'postponed').toList();
    if (filter == 'pending') return widget.matches.where((m) {
      final status = AppData.text(m['status'], 'pending');
      return status != 'played' && status != 'postponed' && status != 'cancelled' && status != 'bye';
    }).toList();
    return widget.matches;
  }

  Future<void> addVisualManualMatch() async {
    if (widget.teams.length < 2) {
      await showToast(context, 'Añade al menos 2 participantes.', danger: true);
      return;
    }
    final result = await showTournamentMatchEditorDialog(
      context,
      teams: widget.teams,
      defaultRound: widget.matches.isEmpty ? 1 : widget.matches.fold<int>(1, (value, match) => max(value, AppData.intValue(match['round'], 1))),
    );
    if (result == null) return;
    try {
      final created = await AppData.addTournamentMatch(
        tournamentId: AppData.text(widget.tournament['id']),
        teamAId: result.teamAId,
        teamBId: result.teamBId,
        round: result.round,
        scheduledAt: result.scheduledAt,
        durationMinutes: result.durationMinutes,
        location: result.location,
        courtName: result.courtName,
        notes: result.notes,
      );
      if (result.syncAgenda && result.scheduledAt != null) {
        await AppData.syncMatchAgendaEvent(
          groupId: AppData.text(widget.group['id']),
          tournamentName: AppData.text(widget.tournament['name'], 'Torneo'),
          match: created,
          teamNames: teamNameMap(widget.teams),
        );
      }
      widget.onChanged();
    } catch (e) {
      if (mounted) await showToast(context, humanError(e), danger: true);
    }
  }

  Future<void> duplicateRound() async {
    final round = await showTournamentDuplicateRoundDialog(context, matches: widget.matches);
    if (round == null) return;
    try {
      await AppData.duplicateTournamentRound(AppData.text(widget.tournament['id']), round);
      widget.onChanged();
      if (mounted) await showToast(context, 'Jornada duplicada. Puedes reordenarla o cambiar fechas.');
    } catch (e) {
      if (mounted) await showToast(context, humanError(e), danger: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isManual = AppData.text(widget.tournament['format']) == 'manual';
    if (widget.matches.isEmpty) {
      if (isManual) {
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          EmptySlim(icon: Icons.table_rows_rounded, title: 'Sin partidos todavía', body: 'Añade partidos manuales con selectores y fechas individuales.'),
          const SizedBox(height: 10),
          PrimaryButton(label: 'Añadir partido', icon: Icons.add_rounded, onTap: addVisualManualMatch),
        ]);
      }
      return EmptySlim(icon: Icons.sports_score_rounded, title: 'Sin partidos todavía', body: 'Genera el calendario desde Resumen.');
    }
    final shown = filteredMatches;
    final grouped = <int, List<Map<String, dynamic>>>{};
    for (final match in shown) {
      final round = AppData.intValue(match['round'], 1);
      grouped.putIfAbsent(round, () => []).add(match);
    }
    final rounds = grouped.keys.toList()..sort();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      AppCard(
        padding: const EdgeInsets.all(8),
        child: Row(children: [
          Expanded(child: TournamentSmallFilter(label: 'Todos', selected: filter == 'all', onTap: () => setState(() => filter = 'all'))),
          Expanded(child: TournamentSmallFilter(label: 'Pendientes', selected: filter == 'pending', onTap: () => setState(() => filter = 'pending'))),
          Expanded(child: TournamentSmallFilter(label: 'Jugados', selected: filter == 'played', onTap: () => setState(() => filter = 'played'))),
          Expanded(child: TournamentSmallFilter(label: 'Aplazados', selected: filter == 'postponed', onTap: () => setState(() => filter = 'postponed'))),
        ]),
      ),
      const SizedBox(height: 8),
      if (isManual) ...[
        Row(children: [
          Expanded(child: PrimaryButton(label: 'Añadir partido', icon: Icons.add_rounded, onTap: addVisualManualMatch)),
          const SizedBox(width: 8),
          Expanded(child: SecondaryButton(label: 'Duplicar jornada', icon: Icons.copy_rounded, onTap: duplicateRound)),
        ]),
        const SizedBox(height: 8),
      ],
      SecondaryButton(label: 'Reprogramar jornada o lote', icon: Icons.edit_calendar_rounded, onTap: widget.onBulkSchedule),
      const SizedBox(height: 12),
      if (shown.isEmpty)
        EmptySlim(icon: Icons.filter_alt_rounded, title: 'Sin partidos en este filtro', body: 'Cambia el filtro para ver otros partidos.')
      else ...[
        for (final round in rounds) ...[
          SectionHeader(title: AppData.text(widget.tournament['format']) == 'americano' ? 'Ronda $round' : 'Jornada $round'),
          const SizedBox(height: 8),
          ...grouped[round]!.map((m) => TournamentSimpleMatchCard(match: m, allMatches: widget.matches, group: widget.group, tournamentName: AppData.text(widget.tournament['name'], 'Torneo'), teams: widget.teams, scoringType: widget.scoringType, scoringConfig: widget.scoringConfig, onChanged: widget.onChanged)),
          const SizedBox(height: 12),
        ],
      ],
    ]);
  }
}

class TournamentSmallFilter extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  const TournamentSmallFilter({super.key, required this.label, this.selected = false, this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(999),
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(color: selected ? AppColors.red : Colors.transparent, borderRadius: BorderRadius.circular(999)),
      child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: selected ? Colors.white : AppColors.muted, fontWeight: FontWeight.w900, fontSize: 10.5)),
    ),
  );
}

class TournamentSimpleMatchCard extends StatelessWidget {
  final Map<String, dynamic> match;
  final List<Map<String, dynamic>> allMatches;
  final Map<String, dynamic>? group;
  final String tournamentName;
  final List<Map<String, dynamic>> teams;
  final String scoringType;
  final Map<String, dynamic>? scoringConfig;
  final VoidCallback onChanged;
  const TournamentSimpleMatchCard({super.key, required this.match, this.allMatches = const [], this.group, this.tournamentName = 'Torneo', required this.teams, this.scoringType = 'general', this.scoringConfig, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final names = teamNameMap(teams);
    final aName = tournamentMatchSideName(match, names, true);
    final bName = tournamentMatchSideName(match, names, false);
    final restText = americanoRestText(match, names);
    final status = AppData.text(match['status'], 'pending');
    final played = matchCountsForStandings(match);
    final specialText = matchSpecialResultText(match, names);
    final detailScore = specialText.isNotEmpty ? specialText : matchDetailScoreText(match, scoringType, scoringConfig);
    final score = played ? '${AppData.intValue(match['score_a'])} - ${AppData.intValue(match['score_b'])}' : matchStatusLabel(status);
    final dateText = tournamentMatchDateText(match);
    final statusColor = matchStatusColor(status);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        onTap: () => showMatchResultDialog(context, match: match, teams: teams, scoringType: scoringType, scoringConfig: scoringConfig, onChanged: onChanged),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: statusColor.withOpacity(.12), borderRadius: BorderRadius.circular(999)),
              child: Text(AppData.text(match['round_name'], 'Jornada ${AppData.intValue(match['round'], 1)}'), style: TextStyle(color: statusColor, fontWeight: FontWeight.w900, fontSize: 10)),
            ),
            const SizedBox(width: 6),
            Expanded(child: Text(dateText, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800, fontSize: 11))),
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'result') {
                  await showMatchResultDialog(context, match: match, teams: teams, scoringType: scoringType, scoringConfig: scoringConfig, onChanged: onChanged);
                } else if (value == 'schedule') {
                  await showMatchScheduleDialog(context, match: match, group: group, tournamentName: tournamentName, teams: teams, onChanged: onChanged);
                } else if (value == 'special') {
                  await showSpecialMatchResultDialog(context, match: match, teams: teams, onChanged: onChanged);
                } else if (value == 'history') {
                  await showMatchHistoryDialog(context, match: match);
                } else if (value == 'postponed' || value == 'cancelled' || value == 'pending') {
                  try {
                    await AppData.updateMatchStatus(match['id'].toString(), value);
                    onChanged();
                  } catch (e) {
                    if (context.mounted) await showToast(context, humanError(e), danger: true);
                  }
                } else if (value == 'open_event') {
                  final eventId = AppData.text(match['event_id']);
                  if (eventId.isEmpty || group == null) {
                    if (context.mounted) await showToast(context, 'Este partido todavía no tiene evento de Agenda.', danger: true);
                    return;
                  }
                  try {
                    await AppData.openTournamentMatchEvent(context, eventId, group!);
                  } catch (e) {
                    if (context.mounted) await showToast(context, humanError(e), danger: true);
                  }
                } else if (value == 'reopen') {
                  try {
                    await AppData.reopenMatch(match['id'].toString());
                    onChanged();
                  } catch (e) {
                    if (context.mounted) await showToast(context, humanError(e), danger: true);
                  }
                } else if (value == 'move_up' || value == 'move_down') {
                  try {
                    await AppData.shiftTournamentMatchOrder(match['id'].toString(), allMatches, value == 'move_up' ? -1 : 1);
                    onChanged();
                  } catch (e) {
                    if (context.mounted) await showToast(context, humanError(e), danger: true);
                  }
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'result', child: Text('Registrar resultado')),
                const PopupMenuItem(value: 'special', child: Text('No presentado / victoria admin.')),
                const PopupMenuItem(value: 'schedule', child: Text('Cambiar fecha / pista')),
                const PopupMenuItem(value: 'move_up', child: Text('Subir en la jornada')),
                const PopupMenuItem(value: 'move_down', child: Text('Bajar en la jornada')),
                if (matchResultHistory(match).isNotEmpty) const PopupMenuItem(value: 'history', child: Text('Ver historial')),
                if (AppData.text(match['event_id']).isNotEmpty) const PopupMenuItem(value: 'open_event', child: Text('Abrir en Agenda')),
                const PopupMenuItem(value: 'postponed', child: Text('Marcar aplazado')),
                const PopupMenuItem(value: 'cancelled', child: Text('Cancelar partido')),
                const PopupMenuItem(value: 'pending', child: Text('Volver a pendiente')),
                if (matchCountsForStandings(match)) const PopupMenuItem(value: 'reopen', child: Text('Borrar resultado')),
              ],
            ),
          ]),
          const SizedBox(height: 9),
          Row(children: [
            Expanded(child: Text(aName, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, height: 1.05))),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Column(children: [
              Text(score, style: TextStyle(color: played ? AppColors.green : statusColor, fontWeight: FontWeight.w900, fontSize: 12)),
              if (detailScore != null) Text(detailScore, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 9)),
            ])),
            Expanded(child: Text(bName, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.end, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, height: 1.05))),
          ]),
          if (AppData.text(match['court_name']).isNotEmpty || AppData.text(match['location']).isNotEmpty || restText.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text([
              if (AppData.text(match['court_name']).isNotEmpty) AppData.text(match['court_name']),
              if (AppData.text(match['location']).isNotEmpty) AppData.text(match['location']),
              if (restText.isNotEmpty) 'Descansan: $restText',
            ].join(' · '), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 11)),
          ],
        ]),
      ),
    );
  }
}

class TournamentLatestResultCard extends StatelessWidget {
  final Map<String, dynamic> match;
  final Map<String, String> names;
  final String scoringType;
  final dynamic scoringConfig;
  const TournamentLatestResultCard({super.key, required this.match, required this.names, required this.scoringType, this.scoringConfig});

  @override
  Widget build(BuildContext context) {
    final aName = tournamentMatchSideName(match, names, true);
    final bName = tournamentMatchSideName(match, names, false);
    final details = matchDetailScoreText(match, scoringType, scoringConfig);
    return AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text(aName, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900))),
        Text('${AppData.intValue(match['score_a'])} - ${AppData.intValue(match['score_b'])}', style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.w900, fontSize: 16)),
        Expanded(child: Text(bName, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.end, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900))),
      ]),
      if (details != null) ...[
        const SizedBox(height: 5),
        Text(details, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800, fontSize: 12)),
      ],
    ]));
  }
}

class TournamentStandingsPanel extends StatelessWidget {
  final List<TeamStanding> standings;
  final List<Map<String, dynamic>> matches;
  final List<String> tieBreakers;
  final String scoringType;
  final Map<String, dynamic> scoringConfig;
  const TournamentStandingsPanel({super.key, required this.standings, required this.matches, required this.tieBreakers, required this.scoringType, required this.scoringConfig});

  @override
  Widget build(BuildContext context) {
    if (standings.isEmpty) return EmptySlim(icon: Icons.table_chart_rounded, title: 'Sin tabla todavía', body: 'Registra resultados para calcular la clasificación.');
    final isAmericano = matches.any(isAmericanoMatch);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionHeader(title: isAmericano ? 'Ranking completo' : 'Tabla completa'),
      const SizedBox(height: 8),
      AppCard(
        padding: const EdgeInsets.all(10),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 14,
            horizontalMargin: 6,
            headingTextStyle: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w900, fontSize: 11),
            dataTextStyle: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800, fontSize: 12),
            columns: [
              const DataColumn(label: Text('#')),
              DataColumn(label: Text(isAmericano ? 'Jugador' : 'Equipo')),
              const DataColumn(label: Text('PJ')),
              const DataColumn(label: Text('G')),
              const DataColumn(label: Text('E')),
              const DataColumn(label: Text('P')),
              const DataColumn(label: Text('+')),
              const DataColumn(label: Text('-')),
              const DataColumn(label: Text('DIF')),
              const DataColumn(label: Text('NP')),
              const DataColumn(label: Text('PTS')),
            ],
            rows: List.generate(standings.length, (index) {
              final s = standings[index];
              return DataRow(cells: [
                DataCell(Text('${index + 1}', style: TextStyle(fontWeight: FontWeight.w900, color: index == 0 ? AppColors.green : AppColors.ink))),
                DataCell(SizedBox(width: 150, child: Text(s.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)))),
                DataCell(Text('${s.played}')),
                DataCell(Text('${s.wins}')),
                DataCell(Text('${s.draws}')),
                DataCell(Text('${s.losses}')),
                DataCell(Text('${s.goalsFor}')),
                DataCell(Text('${s.goalsAgainst}')),
                DataCell(Text('${s.goalDifference}')),
                DataCell(Text('${s.noShows}')),
                DataCell(Text('${s.points}', style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.w900))),
              ]);
            }),
          ),
        ),
      ),
      const SizedBox(height: 10),
      TournamentTieBreakersCompactCard(tieBreakers: tieBreakers),
      const SizedBox(height: 12),
      SectionHeader(title: 'Detalle de posiciones'),
      const SizedBox(height: 8),
      ...List.generate(standings.length, (index) => TournamentStandingRankCard(
        position: index + 1,
        standing: standings[index],
        scoringType: scoringType,
        scoringConfig: scoringConfig,
        explanation: standingRankReason(index, standings, tieBreakers, scoringType, scoringConfig),
      )),
    ]);
  }
}

class TournamentTieBreakersCompactCard extends StatelessWidget {
  final List<String> tieBreakers;
  const TournamentTieBreakersCompactCard({super.key, required this.tieBreakers});

  @override
  Widget build(BuildContext context) => AppCard(
    color: AppColors.faint,
    padding: const EdgeInsets.all(11),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 32, height: 32, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.rule_rounded, color: AppColors.teal, size: 18)),
      const SizedBox(width: 9),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Desempates', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 12)),
        const SizedBox(height: 3),
        Text(standingsOrderText(tieBreakers), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, height: 1.25, fontSize: 11.5)),
      ])),
    ]),
  );
}

class TournamentTieBreakersInfoCard extends StatelessWidget {
  final List<String> tieBreakers;
  const TournamentTieBreakersInfoCard({super.key, required this.tieBreakers});

  @override
  Widget build(BuildContext context) => AppCard(
    color: AppColors.blueSoft,
    padding: const EdgeInsets.all(12),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 36, height: 36, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.rule_rounded, color: AppColors.blue, size: 20)),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Criterios de desempate', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(standingsOrderText(tieBreakers), style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800, height: 1.25)),
      ])),
    ]),
  );
}

class TournamentStandingRankCard extends StatelessWidget {
  final int position;
  final TeamStanding standing;
  final String scoringType;
  final dynamic scoringConfig;
  final String explanation;
  const TournamentStandingRankCard({super.key, required this.position, required this.standing, required this.scoringType, this.scoringConfig, required this.explanation});

  @override
  Widget build(BuildContext context) {
    final podium = position <= 3;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        color: podium ? AppColors.orangeSoft : AppColors.white,
        padding: const EdgeInsets.all(12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: podium ? AppColors.orange : AppColors.faint, borderRadius: BorderRadius.circular(14)),
            child: Center(child: Text('$position', style: TextStyle(color: podium ? Colors.white : AppColors.muted, fontWeight: FontWeight.w900))),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(standing.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, height: 1.05)),
            const SizedBox(height: 4),
            Text(standingDetailText(standing, scoringType, scoringConfig), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 12)),
            const SizedBox(height: 4),
            Text(explanation, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.blue, fontWeight: FontWeight.w800, fontSize: 11, height: 1.2)),
          ])),
          const SizedBox(width: 8),
          Text('${standing.points} pts', style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.w900, fontSize: 16)),
        ]),
      ),
    );
  }
}

class TournamentStandingTile extends StatelessWidget {
  final TeamStanding standing;
  final String scoringType;
  final dynamic scoringConfig;
  final bool highlighted;
  const TournamentStandingTile({super.key, required this.standing, required this.scoringType, this.scoringConfig, this.highlighted = false});

  @override
  Widget build(BuildContext context) => AppCard(
    color: highlighted ? AppColors.orangeSoft : AppColors.white,
    padding: const EdgeInsets.all(12),
    child: Row(children: [
      Container(width: 40, height: 40, decoration: BoxDecoration(color: highlighted ? AppColors.orange : AppColors.tealSoft, borderRadius: BorderRadius.circular(14)), child: Icon(highlighted ? Icons.emoji_events_rounded : Icons.groups_rounded, color: highlighted ? Colors.white : AppColors.teal)),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(standing.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, height: 1.05)),
        const SizedBox(height: 4),
        Text(standingDetailText(standing, scoringType, scoringConfig), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 12)),
      ])),
      Text('${standing.points} pts', style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.w900, fontSize: 16)),
    ]),
  );
}

class TournamentStatsPanel extends StatelessWidget {
  final List<TeamStanding> standings;
  final List<Map<String, dynamic>> matches;
  final List<Map<String, dynamic>> teams;
  final String scoringType;
  final Map<String, dynamic> scoringConfig;
  const TournamentStatsPanel({super.key, required this.standings, required this.matches, required this.teams, required this.scoringType, required this.scoringConfig});

  @override
  Widget build(BuildContext context) {
    final played = matches.where(matchCountsForStandings).length;
    final pending = matches.where((m) => !matchCountsForStandings(m) && !['cancelled', 'bye'].contains(AppData.text(m['status']))).length;
    if (standings.isEmpty || played == 0) {
      return EmptySlim(
        icon: Icons.query_stats_rounded,
        title: 'Sin estadísticas útiles todavía',
        body: 'Cuando registres resultados aparecerán datos reales del torneo. De momento usa la pestaña Tabla para ver la clasificación.',
      );
    }

    final leader = standings.first;
    final wins = bestWins(standings);
    final diff = bestGoalDifference(standings);
    final pointsFor = bestGoalsFor(standings);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionHeader(title: 'Resumen estadístico'),
      const SizedBox(height: 8),
      AppCard(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(children: [
          TournamentStatsRow(icon: Icons.emoji_events_rounded, color: AppColors.orange, label: 'Líder', value: leader.name, detail: '${leader.points} pts'),
          const Divider(height: 1, indent: 58, color: AppColors.line),
          TournamentStatsRow(icon: Icons.done_all_rounded, color: AppColors.green, label: 'Más victorias', value: wins.name, detail: '${wins.wins} victorias'),
          const Divider(height: 1, indent: 58, color: AppColors.line),
          TournamentStatsRow(icon: Icons.trending_up_rounded, color: AppColors.blue, label: 'Mejor diferencia', value: diff.name, detail: '${diff.goalDifference}'),
          const Divider(height: 1, indent: 58, color: AppColors.line),
          TournamentStatsRow(icon: Icons.add_chart_rounded, color: AppColors.violet, label: 'Más a favor', value: pointsFor.name, detail: '${pointsFor.goalsFor}'),
          const Divider(height: 1, indent: 58, color: AppColors.line),
          TournamentStatsRow(icon: Icons.pending_actions_rounded, color: pending == 0 ? AppColors.green : AppColors.red, label: 'Pendientes', value: '$pending partidos', detail: pending == 0 ? 'Todo cerrado' : 'Aún quedan resultados'),
        ]),
      ),
    ]);
  }
}

class TournamentStatsRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String detail;
  const TournamentStatsRow({super.key, required this.icon, required this.color, required this.label, required this.value, required this.detail});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    child: Row(children: [
      Container(width: 36, height: 36, decoration: BoxDecoration(color: color.withOpacity(.10), borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: color, size: 19)),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
      ])),
      const SizedBox(width: 8),
      Text(detail, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12)),
    ]),
  );
}

class TournamentMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String detail;
  final IconData icon;
  final Color color;
  const TournamentMetricCard({super.key, required this.title, required this.value, required this.detail, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(12),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color),
      const SizedBox(height: 10),
      Text(title, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800, fontSize: 11)),
      const SizedBox(height: 4),
      Text(value, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, height: 1.05)),
      const SizedBox(height: 4),
      Text(detail, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12)),
    ]),
  );
}



class TournamentSettingsEditPanel extends StatelessWidget {
  final String format;
  final List<Map<String, dynamic>> matches;
  final VoidCallback onAddParticipants;
  final VoidCallback onBulkSchedule;
  final VoidCallback onManualMatches;
  final VoidCallback onCheckIn;
  const TournamentSettingsEditPanel({
    super.key,
    required this.format,
    required this.matches,
    required this.onAddParticipants,
    required this.onBulkSchedule,
    required this.onManualMatches,
    required this.onCheckIn,
  });

  @override
  Widget build(BuildContext context) {
    final canAddManualMatch = format == 'manual' || format == 'liga';
    return AppCard(
      color: AppColors.navyDeep,
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: Colors.white.withOpacity(.12), borderRadius: BorderRadius.circular(15)),
            child: const Icon(Icons.edit_note_rounded, color: Colors.white),
          ),
          const SizedBox(width: 10),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Panel de edición', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17, height: 1.1)),
            SizedBox(height: 4),
            Text('Edita jugadores, fechas y partidos desde Ajustes para no saturar el resumen.', style: TextStyle(color: Color(0xDFFFFFFF), fontWeight: FontWeight.w700, height: 1.25)),
          ])),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: SecondaryButton(label: 'Añadir jugadores', icon: Icons.group_add_rounded, onTap: onAddParticipants)),
          const SizedBox(width: 8),
          Expanded(child: SecondaryButton(label: 'Cambiar fechas', icon: Icons.edit_calendar_rounded, onTap: matches.isEmpty ? () => showToast(context, 'No hay partidos para mover.', danger: true) : onBulkSchedule)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          if (canAddManualMatch) ...[
            Expanded(child: SecondaryButton(label: 'Añadir partido', icon: Icons.add_link_rounded, onTap: onManualMatches)),
            const SizedBox(width: 8),
          ],
          Expanded(child: SecondaryButton(label: 'Check-in', icon: Icons.how_to_reg_rounded, onTap: onCheckIn)),
        ]),
      ]),
    );
  }
}


class TournamentSettingsPanel extends StatelessWidget {
  final Map<String, dynamic> tournament;
  final List<Map<String, dynamic>> matches;
  final VoidCallback onRegenerate;
  final VoidCallback onManualMatches;
  final VoidCallback onBulkSchedule;
  final VoidCallback onAddParticipants;
  final VoidCallback onCheckIn;
  final VoidCallback onEditTournament;
  final VoidCallback onHistory;
  final ValueChanged<String> onSetStatus;
  final VoidCallback onDelete;
  const TournamentSettingsPanel({super.key, required this.tournament, required this.matches, required this.onRegenerate, required this.onManualMatches, required this.onBulkSchedule, required this.onAddParticipants, required this.onCheckIn, required this.onEditTournament, required this.onHistory, required this.onSetStatus, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final format = AppData.text(tournament['format'], 'liga');
    final scoringType = AppData.text(tournament['scoring_type'], 'general');
    final scoringConfig = resolvedScoringConfig(scoringType, tournament['scoring_config']);
    final formatConfig = tournamentFormatConfig(tournament);
    final scheduleConfig = tournamentScheduleConfig(tournament);
    final status = AppData.text(tournament['status'], 'active');
    final scheduled = matches.where((m) => AppData.text(m['scheduled_at']).isNotEmpty).length;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Configuración del torneo', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 16)),
        const SizedBox(height: 10),
        TournamentReviewRow(label: 'Estado', value: tournamentStatusLabel(status)),
        TournamentReviewRow(label: 'Formato', value: tournamentFormatLabel(format)),
        TournamentReviewRow(label: 'Participantes', value: teamTypeLabel(AppData.text(tournament['team_type'], 'equipo'))),
        TournamentReviewRow(label: 'Puntuación', value: scoringConfigShortText(scoringType, scoringConfig)),
        TournamentReviewRow(label: 'Jornadas límite', value: AppData.intValue(formatConfig['max_rounds']) == 0 ? 'Todas' : '${AppData.intValue(formatConfig['max_rounds'])}'),
        TournamentReviewRow(label: 'Vueltas', value: '${AppData.intValue(formatConfig['legs'], 1)}'),
        TournamentReviewRow(label: 'Partidos con fecha', value: '$scheduled/${matches.length}'),
        TournamentReviewRow(label: 'Agenda', value: scheduleConfig['add_to_agenda'] == true ? 'Activada' : 'No'),
      ])),
      const SizedBox(height: 12),
      TournamentSettingsEditPanel(
        format: format,
        matches: matches,
        onAddParticipants: onAddParticipants,
        onBulkSchedule: onBulkSchedule,
        onManualMatches: onManualMatches,
        onCheckIn: onCheckIn,
      ),
      const SizedBox(height: 12),
      AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('Editar torneo', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        const Text('Cambia nombre, deporte y reglas. Si ya hay resultados, las reglas se bloquean para no romper la clasificación.', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, height: 1.25)),
        const SizedBox(height: 12),
        SecondaryButton(label: 'Editar nombre / deporte / reglas', icon: Icons.edit_note_rounded, onTap: onEditTournament),
        const SizedBox(height: 8),
        SecondaryButton(label: 'Ver historial de cambios', icon: Icons.history_rounded, onTap: onHistory),
      ])),
      const SizedBox(height: 12),
      AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(format == 'manual' ? 'Partidos manuales' : 'Calendario y cruces', style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text('Si ya hay resultados, la app bloquea la regeneración para no romper la liga. Rehaz el calendario solo antes de empezar.', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, height: 1.25)),
        const SizedBox(height: 12),
        SecondaryButton(label: format == 'manual' ? 'Añadir partidos manuales' : 'Regenerar partidos', icon: format == 'manual' ? Icons.add_link_rounded : Icons.refresh_rounded, onTap: format == 'manual' ? onManualMatches : onRegenerate),
        if (matches.isNotEmpty) ...[
          const SizedBox(height: 8),
          SecondaryButton(label: 'Mover jornada / cambiar fechas', icon: Icons.edit_calendar_rounded, onTap: onBulkSchedule),
        ],
      ])),
      const SizedBox(height: 12),
      AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('Estado', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          ActionChip(label: const Text('Programado'), onPressed: () => onSetStatus('scheduled')),
          ActionChip(label: const Text('En curso'), onPressed: () => onSetStatus('active')),
          ActionChip(label: const Text('Pausado'), onPressed: () => onSetStatus('paused')),
          ActionChip(label: const Text('Finalizado'), onPressed: () => onSetStatus('finished')),
        ]),
      ])),
      const SizedBox(height: 12),
      TournamentPremiumSettingsCard(),
      const SizedBox(height: 12),
      DangerButton(label: 'Eliminar competición', icon: Icons.delete_outline_rounded, onTap: onDelete),
    ]);
  }
}

class TournamentTeamsPanel extends StatelessWidget {
  final List<Map<String, dynamic>> teams;
  final List<Map<String, dynamic>> matches;
  final bool showSeeds;
  final VoidCallback onChanged;
  final VoidCallback onAdd;
  final VoidCallback onAddMembers;
  final VoidCallback onCreatePair;
  const TournamentTeamsPanel({super.key, required this.teams, required this.matches, this.showSeeds = false, required this.onChanged, required this.onAdd, required this.onAddMembers, required this.onCreatePair});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TournamentParticipantsEditorHeader(
        teamsCount: teams.length,
        onAddText: onAdd,
        onAddMembers: onAddMembers,
        onCreatePair: onCreatePair,
      ),
      const SizedBox(height: 12),
      if (teams.isEmpty)
        EmptySlim(icon: Icons.groups_rounded, title: 'Sin participantes', body: 'Añade miembros del grupo, crea una pareja o escribe equipos manualmente.')
      else
        ...teams.map((team) => TournamentTeamCard(team: team, matches: matches, showSeed: showSeeds, onChanged: onChanged)),
    ]);
  }
}

class TournamentTeamCard extends StatelessWidget {
  final Map<String, dynamic> team;
  final List<Map<String, dynamic>> matches;
  final bool showSeed;
  final VoidCallback onChanged;
  const TournamentTeamCard({super.key, required this.team, required this.matches, this.showSeed = false, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final id = team['id'].toString();
    final played = matches.where((m) => matchCountsForStandings(m) && (AppData.text(m['team_a']) == id || AppData.text(m['team_b']) == id)).length;
    final scheduled = matches.where((m) => AppData.text(m['team_a']) == id || AppData.text(m['team_b']) == id).length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          ProfileAvatar(name: AppData.text(team['name'], 'Participante'), avatarUrl: AppData.text(team['avatar_url']), radius: 19),
          if (showSeed) ...[
            const SizedBox(width: 8),
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(color: AppColors.tealSoft, borderRadius: BorderRadius.circular(11)),
              child: Center(child: Text('#${AppData.intValue(team['seed'])}', style: const TextStyle(color: AppColors.orange, fontWeight: FontWeight.w900, fontSize: 11))),
            ),
          ],
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(AppData.text(team['name'], 'Participante'), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, height: 1.05)),
            const SizedBox(height: 3),
            Text('$played/$scheduled partidos jugados', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 12)),
          ])),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'rename') renameTournamentTeamDialog(context, team: team, onChanged: onChanged);
              if (value == 'seed') setTournamentTeamSeedDialog(context, team: team, onChanged: onChanged);
              if (value == 'delete') deleteTournamentTeamDialog(context, team: team, matches: matches, onChanged: onChanged);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'rename', child: Text('Renombrar')),
              if (showSeed) const PopupMenuItem(value: 'seed', child: Text('Cambiar cabeza de serie')),
              const PopupMenuItem(value: 'delete', child: Text('Retirar / eliminar')),
            ],
          ),
        ]),
      ),
    );
  }
}



class TournamentParticipantsEditorHeader extends StatelessWidget {
  final int teamsCount;
  final VoidCallback onAddText;
  final VoidCallback onAddMembers;
  final VoidCallback onCreatePair;
  const TournamentParticipantsEditorHeader({
    super.key,
    required this.teamsCount,
    required this.onAddText,
    required this.onAddMembers,
    required this.onCreatePair,
  });

  @override
  Widget build(BuildContext context) => AppCard(
    color: AppColors.faint,
    padding: const EdgeInsets.all(12),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.redSoft, borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.groups_rounded, color: AppColors.red)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Editor de participantes', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
          const SizedBox(height: 3),
          Text('$teamsCount participante${teamsCount == 1 ? '' : 's'} · añade miembros, parejas o equipos', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 12)),
        ])),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: SecondaryButton(label: 'Miembros', icon: Icons.group_add_rounded, onTap: onAddMembers)),
        const SizedBox(width: 8),
        Expanded(child: SecondaryButton(label: 'Pareja', icon: Icons.people_rounded, onTap: onCreatePair)),
      ]),
      const SizedBox(height: 8),
      SecondaryButton(label: 'Escribir nombres / equipos', icon: Icons.edit_rounded, onTap: onAddText),
    ]),
  );
}

class TournamentPairDraft {
  final Map<String, dynamic> first;
  final Map<String, dynamic> second;
  final String name;
  const TournamentPairDraft({required this.first, required this.second, this.name = ''});
}

class TournamentEditorDraft {
  final String name;
  final String scoringType;
  final Map<String, dynamic> scoringConfig;
  final Map<String, dynamic> formatConfig;
  final List<String> tieBreakers;
  final bool rulesChanged;
  const TournamentEditorDraft({
    required this.name,
    required this.scoringType,
    required this.scoringConfig,
    required this.formatConfig,
    required this.tieBreakers,
    required this.rulesChanged,
  });
}

Future<List<Map<String, dynamic>>?> showTournamentMemberPickerDialog(BuildContext context, {required List<Map<String, dynamic>> members}) async {
  if (members.isEmpty) {
    await showToast(context, 'Este grupo todavía no tiene miembros para añadir.', danger: true);
    return null;
  }
  final selected = <String>{};
  final byId = <String, Map<String, dynamic>>{
    for (final member in members) AppData.text(member['user_id'], AppData.text(AppData.asMap(member['profiles'])['id'])): member,
  }..removeWhere((key, value) => key.isEmpty);

  return showDialog<List<Map<String, dynamic>>>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setLocal) => AlertDialog(
        title: const Text('Añadir miembros del grupo'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: members.map((member) {
            final id = AppData.text(member['user_id'], AppData.text(AppData.asMap(member['profiles'])['id']));
            final checked = selected.contains(id);
            return CheckboxListTile(
              value: checked,
              onChanged: id.isEmpty ? null : (value) => setLocal(() {
                if (value == true) {
                  selected.add(id);
                } else {
                  selected.remove(id);
                }
              }),
              secondary: ProfileAvatar(name: memberDisplayName(member), avatarUrl: memberAvatarUrl(member), radius: 18),
              title: Text(memberDisplayName(member), style: const TextStyle(fontWeight: FontWeight.w900)),
              subtitle: const Text('Miembro del grupo'),
              contentPadding: EdgeInsets.zero,
            );
          }).toList())),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          FilledButton(
            onPressed: selected.isEmpty ? null : () => Navigator.pop(dialogContext, selected.map((id) => byId[id]).whereType<Map<String, dynamic>>().toList()),
            child: Text('Añadir ${selected.length}'),
          ),
        ],
      ),
    ),
  );
}

Future<TournamentPairDraft?> showTournamentPairCreatorDialog(BuildContext context, {required List<Map<String, dynamic>> members}) async {
  if (members.length < 2) {
    await showToast(context, 'Necesitas al menos 2 miembros para crear una pareja.', danger: true);
    return null;
  }

  final ids = members.map((m) => AppData.text(m['user_id'], AppData.text(AppData.asMap(m['profiles'])['id']))).where((id) => id.isNotEmpty).toList();
  final byId = <String, Map<String, dynamic>>{
    for (final member in members) AppData.text(member['user_id'], AppData.text(AppData.asMap(member['profiles'])['id'])): member,
  }..removeWhere((key, value) => key.isEmpty);
  var firstId = ids.first;
  var secondId = ids.length > 1 ? ids[1] : ids.first;
  final nameController = TextEditingController();

  final result = await showDialog<TournamentPairDraft>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setLocal) {
        final first = byId[firstId]!;
        final second = byId[secondId]!;
        final suggested = '${memberDisplayName(first)} / ${memberDisplayName(second)}';
        return AlertDialog(
          title: const Text('Crear pareja visual'),
          content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            DropdownButtonFormField<String>(
              value: firstId,
              decoration: const InputDecoration(labelText: 'Jugador 1'),
              items: ids.map((id) => DropdownMenuItem(value: id, child: Text(memberDisplayName(byId[id]!)))).toList(),
              onChanged: (value) => setLocal(() {
                firstId = value ?? firstId;
                if (firstId == secondId) {
                  secondId = ids.firstWhere((id) => id != firstId, orElse: () => secondId);
                }
              }),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: secondId,
              decoration: const InputDecoration(labelText: 'Jugador 2'),
              items: ids.map((id) => DropdownMenuItem(value: id, child: Text(memberDisplayName(byId[id]!)))).toList(),
              onChanged: (value) => setLocal(() {
                secondId = value ?? secondId;
                if (firstId == secondId) {
                  firstId = ids.firstWhere((id) => id != secondId, orElse: () => firstId);
                }
              }),
            ),
            const SizedBox(height: 10),
            Row(children: [
              ProfileAvatar(name: memberDisplayName(first), avatarUrl: memberAvatarUrl(first), radius: 18),
              const SizedBox(width: 6),
              const Icon(Icons.add_rounded, color: AppColors.muted, size: 18),
              const SizedBox(width: 6),
              ProfileAvatar(name: memberDisplayName(second), avatarUrl: memberAvatarUrl(second), radius: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(suggested, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900))),
            ]),
            const SizedBox(height: 10),
            TextField(
              controller: nameController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: 'Nombre opcional de la pareja', hintText: suggested),
            ),
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
            FilledButton(
              onPressed: firstId == secondId ? null : () => Navigator.pop(dialogContext, TournamentPairDraft(first: byId[firstId]!, second: byId[secondId]!, name: nameController.text.trim())),
              child: const Text('Crear pareja'),
            ),
          ],
        );
      },
    ),
  );
  nameController.dispose();
  return result;
}

Future<TournamentEditorDraft?> showTournamentEditorDialog(BuildContext context, {required Map<String, dynamic> tournament, required bool hasResults}) async {
  final nameController = TextEditingController(text: AppData.text(tournament['name']));
  final originalScoringType = AppData.text(tournament['scoring_type'], 'general');
  var scoringType = originalScoringType;
  var cfg = resolvedScoringConfig(originalScoringType, tournament['scoring_config']);
  final originalCfgJson = jsonEncode(cfg);
  final originalFormatConfig = tournamentFormatConfig(tournament);
  final originalFormatConfigJson = jsonEncode(originalFormatConfig);
  var formatConfig = Map<String, dynamic>.from(originalFormatConfig);
  final win = TextEditingController(text: '${scoringWinPoints(scoringType, cfg)}');
  final draw = TextEditingController(text: '${scoringDrawPoints(scoringType, cfg)}');
  final loss = TextEditingController(text: '${scoringLossPoints(scoringType, cfg)}');
  final target = TextEditingController(text: '${AppData.intValue(cfg['target_score'])}');
  final bestOf = TextEditingController(text: '${scoringBestOf(scoringType, cfg)}');
  final maxRounds = TextEditingController(text: '${AppData.intValue(formatConfig['max_rounds'])}');
  final legs = TextEditingController(text: '${AppData.intValue(formatConfig['legs'], 1)}');

  void applyType(String type) {
    scoringType = type;
    cfg = scoringConfigForType(type);
    win.text = '${scoringWinPoints(type, cfg)}';
    draw.text = '${scoringDrawPoints(type, cfg)}';
    loss.text = '${scoringLossPoints(type, cfg)}';
    target.text = '${AppData.intValue(cfg['target_score'])}';
    bestOf.text = '${scoringBestOf(type, cfg)}';
  }

  final result = await showDialog<TournamentEditorDraft>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setLocal) => AlertDialog(
        title: const Text('Editar torneo'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          TextField(controller: nameController, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Nombre del torneo')),
          const SizedBox(height: 12),
          if (hasResults)
            AppCard(
              color: AppColors.tealSoft,
              padding: const EdgeInsets.all(10),
              child: const Text('Hay resultados registrados. Para proteger la tabla, el deporte y las reglas están bloqueados. Puedes cambiar el nombre.', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800, height: 1.25)),
            )
          else ...[
            const Text('Deporte', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            TournamentSportEmojiPicker(value: scoringType, onChanged: (value) => setLocal(() => applyType(value))),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: TextField(controller: win, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(labelText: 'Victoria'))),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: draw, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(labelText: 'Empate'))),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: loss, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(labelText: 'Derrota'))),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: TextField(controller: target, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(labelText: 'Objetivo'))),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: bestOf, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(labelText: 'Mejor de'))),
            ]),
            const SizedBox(height: 12),
            const Text('Formato', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: TextField(controller: maxRounds, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(labelText: 'Jornadas límite'))),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: legs, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(labelText: 'Vueltas'))),
            ]),
          ],
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          FilledButton(onPressed: () {
            final nextCfg = Map<String, dynamic>.from(cfg);
            nextCfg['win'] = int.tryParse(win.text.trim()) ?? scoringWinPoints(scoringType, cfg);
            nextCfg['draw'] = int.tryParse(draw.text.trim()) ?? scoringDrawPoints(scoringType, cfg);
            nextCfg['loss'] = int.tryParse(loss.text.trim()) ?? scoringLossPoints(scoringType, cfg);
            final targetScore = int.tryParse(target.text.trim()) ?? 0;
            if (targetScore > 0) nextCfg['target_score'] = targetScore;
            nextCfg['best_of'] = max(1, int.tryParse(bestOf.text.trim()) ?? scoringBestOf(scoringType, cfg));
            final nextFormat = Map<String, dynamic>.from(formatConfig);
            nextFormat['max_rounds'] = int.tryParse(maxRounds.text.trim()) ?? AppData.intValue(nextFormat['max_rounds']);
            nextFormat['legs'] = max(1, int.tryParse(legs.text.trim()) ?? AppData.intValue(nextFormat['legs'], 1));
            final rulesChanged = hasResults ? false : (scoringType != originalScoringType || jsonEncode(nextCfg) != originalCfgJson || jsonEncode(nextFormat) != originalFormatConfigJson);
            Navigator.pop(dialogContext, TournamentEditorDraft(
              name: nameController.text.trim(),
              scoringType: hasResults ? originalScoringType : scoringType,
              scoringConfig: hasResults ? resolvedScoringConfig(originalScoringType, tournament['scoring_config']) : nextCfg,
              formatConfig: hasResults ? originalFormatConfig : nextFormat,
              tieBreakers: hasResults ? tournamentTieBreakers(tournament, originalScoringType) : defaultTieBreakers(scoringType),
              rulesChanged: rulesChanged,
            ));
          }, child: const Text('Guardar')),
        ],
      ),
    ),
  );

  nameController.dispose();
  win.dispose();
  draw.dispose();
  loss.dispose();
  target.dispose();
  bestOf.dispose();
  maxRounds.dispose();
  legs.dispose();
  return result;
}

Future<void> showTournamentHistoryDialog(BuildContext context, {required Map<String, dynamic> tournament, required List<Map<String, dynamic>> matches, required List<Map<String, dynamic>> teams}) async {
  final names = teamNameMap(teams);
  final items = <Map<String, dynamic>>[];
  for (final match in matches) {
    final title = '${tournamentMatchSideName(match, names, true)} vs ${tournamentMatchSideName(match, names, false)}';
    for (final entry in matchResultHistory(match)) {
      items.add({
        'title': title,
        'text': matchHistoryEntryText(entry),
        'at': AppData.text(entry['at']),
      });
    }
  }
  items.sort((a, b) => AppData.text(b['at']).compareTo(AppData.text(a['at'])));
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Historial del torneo'),
      content: SizedBox(
        width: double.maxFinite,
        child: items.isEmpty
            ? const Text('Todavía no hay cambios registrados en resultados o partidos.')
            : SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: items.take(30).map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  color: AppColors.faint,
                  padding: const EdgeInsets.all(10),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(AppData.text(item['title']), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text(AppData.text(item['text']), style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, height: 1.25)),
                  ]),
                ),
              )).toList())),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cerrar')),
      ],
    ),
  );
}


Future<void> showMatchScheduleDialog(BuildContext context, {required Map<String, dynamic> match, Map<String, dynamic>? group, String tournamentName = 'Torneo', required List<Map<String, dynamic>> teams, required VoidCallback onChanged}) async {
  final scheduled = DateTime.tryParse(AppData.text(match['scheduled_at']))?.toLocal();
  DateTime selectedDate = scheduled ?? DateTime.now().add(const Duration(days: 1));
  TimeOfDay selectedTime = scheduled == null ? const TimeOfDay(hour: 20, minute: 0) : TimeOfDay(hour: scheduled.hour, minute: scheduled.minute);
  final duration = TextEditingController(text: AppData.text(match['duration_minutes']).isEmpty ? '60' : AppData.text(match['duration_minutes']));
  final location = TextEditingController(text: AppData.text(match['location']));
  final court = TextEditingController(text: AppData.text(match['court_name']));
  final notes = TextEditingController(text: AppData.text(match['notes']));
  var clearDate = false;
  var syncAgenda = AppData.text(match['event_id']).isNotEmpty;

  final result = await showDialog<String>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setLocal) => AlertDialog(
        title: const Text('Fecha del partido'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: SecondaryButton(label: DateFormat('d MMM', 'es_ES').format(selectedDate), icon: Icons.calendar_today_rounded, onTap: () async {
              final picked = await showDatePicker(
                context: dialogContext,
                initialDate: selectedDate,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now().add(const Duration(days: 730)),
                locale: const Locale('es', 'ES'),
              );
              if (picked != null) setLocal(() { selectedDate = picked; clearDate = false; });
            })),
            const SizedBox(width: 8),
            Expanded(child: SecondaryButton(label: selectedTime.format(dialogContext), icon: Icons.schedule_rounded, onTap: () async {
              final picked = await showTimePicker(context: dialogContext, initialTime: selectedTime);
              if (picked != null) setLocal(() { selectedTime = picked; clearDate = false; });
            })),
          ]),
          CheckboxListTile(
            value: clearDate,
            onChanged: (v) => setLocal(() => clearDate = v == true),
            contentPadding: EdgeInsets.zero,
            title: const Text('Dejar sin fecha'),
          ),
          TextField(controller: duration, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(labelText: 'Duración en minutos')),
          const SizedBox(height: 8),
          TextField(controller: location, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Ubicación')),
          const SizedBox(height: 8),
          TextField(controller: court, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Pista / mesa / campo')),
          const SizedBox(height: 8),
          TextField(controller: notes, minLines: 2, maxLines: 4, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Notas')),
          if (group != null) CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: syncAgenda,
            onChanged: clearDate ? null : (v) => setLocal(() => syncAgenda = v == true),
            title: Text(AppData.text(match['event_id']).isEmpty ? 'Añadir también a Agenda' : 'Actualizar evento de Agenda'),
          ),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, 'save'), child: const Text('Guardar')),
        ],
      ),
    ),
  );

  try {
    if (result == 'save') {
      final start = clearDate ? null : DateTime(selectedDate.year, selectedDate.month, selectedDate.day, selectedTime.hour, selectedTime.minute);
      await AppData.updateMatchSchedule(match['id'].toString(), start, int.tryParse(duration.text.trim()) ?? 60, location.text, court.text, notes.text);
      if (syncAgenda && start != null && group != null) {
        final updated = Map<String, dynamic>.from(match)
          ..['scheduled_at'] = start.toUtc().toIso8601String()
          ..['duration_minutes'] = int.tryParse(duration.text.trim()) ?? 60
          ..['location'] = location.text
          ..['court_name'] = court.text
          ..['notes'] = notes.text;
        await AppData.syncMatchAgendaEvent(
          groupId: group['id'].toString(),
          tournamentName: tournamentName,
          match: updated,
          teamNames: teamNameMap(teams),
        );
      }
      onChanged();
    }
  } catch (e) {
    if (context.mounted) await showToast(context, humanError(e), danger: true);
  } finally {
    duration.dispose();
    location.dispose();
    court.dispose();
    notes.dispose();
  }
}


Future<void> showTournamentBulkScheduleDialog(
  BuildContext context, {
  required Map<String, dynamic> tournament,
  required Map<String, dynamic> group,
  required List<Map<String, dynamic>> teams,
  required List<Map<String, dynamic>> matches,
  required VoidCallback onChanged,
}) async {
  if (matches.isEmpty) {
    await showToast(context, 'No hay partidos para reprogramar.', danger: true);
    return;
  }

  final movable = matches.where((m) {
    final status = AppData.text(m['status'], 'pending');
    return status != 'played' && status != 'cancelled' && status != 'bye';
  }).toList();

  if (movable.isEmpty) {
    await showToast(context, 'No hay partidos pendientes que se puedan mover.', danger: true);
    return;
  }

  final rounds = movable.map((m) => AppData.intValue(m['round'], 1)).toSet().toList()..sort();
  String scope = 'round_${rounds.first}';
  final firstScheduled = movable
      .map((m) => DateTime.tryParse(AppData.text(m['scheduled_at']))?.toLocal())
      .whereType<DateTime>()
      .toList()
    ..sort();

  DateTime selectedDate = firstScheduled.isNotEmpty ? firstScheduled.first : DateTime.now().add(const Duration(days: 1));
  TimeOfDay selectedTime = firstScheduled.isNotEmpty ? TimeOfDay(hour: firstScheduled.first.hour, minute: firstScheduled.first.minute) : const TimeOfDay(hour: 20, minute: 0);
  final duration = TextEditingController(text: AppData.text(movable.first['duration_minutes']).isEmpty ? '60' : AppData.text(movable.first['duration_minutes']));
  final interval = TextEditingController(text: '70');
  final location = TextEditingController(text: AppData.text(movable.first['location']));
  final court = TextEditingController(text: AppData.text(movable.first['court_name']).replaceFirst(RegExp(r'\s+\d+$'), ''));
  int courts = 1;
  bool syncAgenda = true;

  List<Map<String, dynamic>> selectedMatchesForScope(String value) {
    final base = movable.where((m) {
      if (value == 'all') return true;
      if (value == 'pending') return AppData.text(m['status'], 'pending') != 'played';
      if (value.startsWith('round_')) {
        final round = int.tryParse(value.replaceFirst('round_', '')) ?? 1;
        return AppData.intValue(m['round'], 1) == round;
      }
      return true;
    }).toList();
    base.sort((a, b) {
      final round = AppData.intValue(a['round']).compareTo(AppData.intValue(b['round']));
      if (round != 0) return round;
      return AppData.intValue(a['order_index']).compareTo(AppData.intValue(b['order_index']));
    });
    return base;
  }

  List<Widget> previewWidgets(String value) {
    final selected = selectedMatchesForScope(value).take(6).toList();
    final names = teamNameMap(teams);
    final start = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, selectedTime.hour, selectedTime.minute);
    return List.generate(selected.length, (index) {
      final match = selected[index];
      final wave = index ~/ max(1, courts);
      final planned = start.add(Duration(minutes: wave * (int.tryParse(interval.text.trim()) ?? 70)));
      final courtLabel = courts <= 1
          ? court.text.trim()
          : (court.text.trim().isEmpty ? 'Pista ${(index % courts) + 1}' : '${court.text.trim()} ${(index % courts) + 1}');
      final a = tournamentMatchSideName(match, names, true);
      final b = tournamentMatchSideName(match, names, false);
      return Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 88, child: Text(DateFormat('EEE d · HH:mm', 'es_ES').format(planned), style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800, fontSize: 11))),
          Expanded(child: Text('$a vs $b', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 12))),
          if (courtLabel.isNotEmpty) ...[
            const SizedBox(width: 6),
            Text(courtLabel, style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.w900, fontSize: 11)),
          ],
        ]),
      );
    });
  }

  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setLocal) {
        final selected = selectedMatchesForScope(scope);
        return AlertDialog(
          title: const Text('Reprogramar partidos'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              DropdownButtonFormField<String>(
                value: scope,
                decoration: const InputDecoration(labelText: 'Qué quieres mover'),
                items: [
                  for (final round in rounds) DropdownMenuItem(value: 'round_$round', child: Text('Jornada $round completa')),
                  const DropdownMenuItem(value: 'pending', child: Text('Todos los pendientes')),
                  const DropdownMenuItem(value: 'all', child: Text('Todos los no jugados')),
                ],
                onChanged: (v) => setLocal(() => scope = v ?? scope),
              ),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: SecondaryButton(label: DateFormat('d MMM', 'es_ES').format(selectedDate), icon: Icons.calendar_today_rounded, onTap: () async {
                  final picked = await showDatePicker(
                    context: dialogContext,
                    initialDate: selectedDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 730)),
                    locale: const Locale('es', 'ES'),
                  );
                  if (picked != null) setLocal(() => selectedDate = picked);
                })),
                const SizedBox(width: 8),
                Expanded(child: SecondaryButton(label: selectedTime.format(dialogContext), icon: Icons.schedule_rounded, onTap: () async {
                  final picked = await showTimePicker(context: dialogContext, initialTime: selectedTime);
                  if (picked != null) setLocal(() => selectedTime = picked);
                })),
              ]),
              const SizedBox(height: 10),
              TextField(controller: location, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Ubicación')),
              const SizedBox(height: 8),
              TextField(controller: court, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Nombre base pista/mesa', hintText: 'Pista, Mesa, Campo...')),
              const SizedBox(height: 8),
              Row(children: [
                const Expanded(child: Text('Pistas/mesas simultáneas', style: TextStyle(fontWeight: FontWeight.w900))),
                IconButton(onPressed: courts <= 1 ? null : () => setLocal(() => courts--), icon: const Icon(Icons.remove_circle_outline_rounded)),
                Text('$courts', style: const TextStyle(fontWeight: FontWeight.w900)),
                IconButton(onPressed: courts >= 12 ? null : () => setLocal(() => courts++), icon: const Icon(Icons.add_circle_outline_rounded)),
              ]),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: syncAgenda,
                onChanged: (v) => setLocal(() => syncAgenda = v == true),
                title: const Text('Sincronizar con Agenda'),
                subtitle: const Text('Crea o actualiza los eventos vinculados.'),
              ),
              const SizedBox(height: 8),
              Text('Vista previa · ${selected.length} partido${selected.length == 1 ? '' : 's'}', style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              ...previewWidgets(scope),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')),
            FilledButton(onPressed: selected.isEmpty ? null : () => Navigator.pop(dialogContext, true), child: const Text('Guardar fechas')),
          ],
        );
      },
    ),
  );

  if (result != true) {
    duration.dispose();
    interval.dispose();
    location.dispose();
    court.dispose();
    return;
  }

  final selected = selectedMatchesForScope(scope);
  final ok = await confirmAction(
    context,
    title: '¿Guardar nueva programación?',
    body: 'Se actualizarán ${selected.length} partido${selected.length == 1 ? '' : 's'} con las fechas de la vista previa. Si están vinculados a Agenda, también se actualizarán los eventos.',
    confirmLabel: 'Guardar fechas',
  );
  if (ok != true) {
    duration.dispose();
    interval.dispose();
    location.dispose();
    court.dispose();
    return;
  }

  try {
    final start = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, selectedTime.hour, selectedTime.minute);
    await AppData.bulkScheduleTournamentMatches(
      groupId: group['id'].toString(),
      tournamentName: AppData.text(tournament['name'], 'Torneo'),
      matches: selected,
      teams: teams,
      firstStart: start,
      durationMinutes: int.tryParse(duration.text.trim()) ?? 60,
      intervalMinutes: int.tryParse(interval.text.trim()) ?? 70,
      courtsCount: courts,
      location: location.text,
      courtName: court.text,
      syncAgenda: syncAgenda,
    );
    onChanged();
    if (context.mounted) await showToast(context, 'Calendario actualizado.');
  } catch (e) {
    if (context.mounted) await showToast(context, humanError(e), danger: true);
  } finally {
    duration.dispose();
    interval.dispose();
    location.dispose();
    court.dispose();
  }
}

Future<void> showMatchResultDialog(BuildContext context, {required Map<String, dynamic> match, required List<Map<String, dynamic>> teams, required String scoringType, Map<String, dynamic>? scoringConfig, required VoidCallback onChanged}) async {
  final names = teamNameMap(teams);
  final aName = tournamentMatchSideName(match, names, true);
  final bName = tournamentMatchSideName(match, names, false);
  final setMode = scoringUsesSetMode(scoringType, scoringConfig);
  final aController = TextEditingController(text: AppData.text(match['score_a']));
  final bController = TextEditingController(text: AppData.text(match['score_b']));
  final setsController = TextEditingController(text: matchDetailSets(match).map((set) => '${set['a']}-${set['b']}').join('\n'));
  final played = matchCountsForStandings(match);
  final result = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('$aName vs $bName'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (setMode) ...[
          const Text('Introduce cada set en una línea:', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          TextField(
            controller: setsController,
            minLines: 4,
            maxLines: 7,
            keyboardType: TextInputType.multiline,
            decoration: const InputDecoration(hintText: '6-4\n3-6\n10-8', helperText: 'La app calcula sets ganados y juegos.'),
          ),
        ] else ...[
          Row(children: [
            Expanded(child: TextField(controller: aController, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: InputDecoration(labelText: matchInputLabel(scoringType, true, scoringConfig)))),
            const SizedBox(width: 10),
            Expanded(child: TextField(controller: bController, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: InputDecoration(labelText: matchInputLabel(scoringType, false, scoringConfig)))),
          ]),
        ],
      ])),
      actions: [
        if (played) TextButton(onPressed: () => Navigator.pop(context, 'reopen'), child: const Text('Borrar resultado')),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(context, 'save'), child: const Text('Guardar')),
      ],
    ),
  );
  final matchId = match['id'].toString();
  try {
    if (result == 'reopen') {
      await AppData.reopenMatch(matchId);
      onChanged();
      return;
    }
    if (result != 'save') return;
    if (setMode) {
      final parsed = parseSetScoreInput(setsController.text);
      if (parsed.isEmpty) {
        if (context.mounted) await showToast(context, 'Introduce al menos un set válido.', danger: true);
        return;
      }
      final setsA = parsed.where((set) => set['a']! > set['b']!).length;
      final setsB = parsed.where((set) => set['b']! > set['a']!).length;
      if (setsA == setsB) {
        if (context.mounted) await showToast(context, 'En este deporte no puede quedar empate a sets.', danger: true);
        return;
      }
      await AppData.setMatchResult(matchId, setsA, setsB, details: {'sets': parsed, 'scoring_type': scoringType});
    } else {
      final a = int.tryParse(aController.text.trim());
      final b = int.tryParse(bController.text.trim());
      if (a == null || b == null) {
        if (context.mounted) await showToast(context, 'Introduce dos marcadores válidos.', danger: true);
        return;
      }
      if (!scoringAllowDraw(scoringType, scoringConfig) && a == b) {
        if (context.mounted) await showToast(context, 'Este sistema no permite empate.', danger: true);
        return;
      }
      await AppData.setMatchResult(matchId, a, b, details: {'scoring_type': scoringType});
    }
    onChanged();
  } catch (e) {
    if (context.mounted) await showToast(context, humanError(e), danger: true);
  } finally {
    aController.dispose();
    bController.dispose();
    setsController.dispose();
  }
}

Future<void> showSpecialMatchResultDialog(BuildContext context, {required Map<String, dynamic> match, required List<Map<String, dynamic>> teams, required VoidCallback onChanged}) async {
  final names = teamNameMap(teams);
  final aId = AppData.text(match['team_a']);
  final bId = AppData.text(match['team_b']);
  final aName = names[aId] ?? 'Local';
  final bName = names[bId] ?? 'Visitante';
  if (aId.isEmpty || bId.isEmpty || bId == 'null') {
    await showToast(context, 'Este partido no tiene dos participantes.', danger: true);
    return;
  }
  final note = TextEditingController();
  final action = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Resultado especial'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('Úsalo para no presentados, abandonos o decisiones del administrador.', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        TextField(controller: note, minLines: 2, maxLines: 3, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Nota opcional', hintText: 'Ej: avisó tarde, abandono, decisión del grupo...')),
        const SizedBox(height: 12),
        SecondaryButton(label: '$aName no se presentó', icon: Icons.person_off_rounded, onTap: () => Navigator.pop(dialogContext, 'no_show_a')),
        const SizedBox(height: 8),
        SecondaryButton(label: '$bName no se presentó', icon: Icons.person_off_rounded, onTap: () => Navigator.pop(dialogContext, 'no_show_b')),
        const SizedBox(height: 8),
        SecondaryButton(label: 'Victoria admin. $aName', icon: Icons.gavel_rounded, onTap: () => Navigator.pop(dialogContext, 'walkover_a')),
        const SizedBox(height: 8),
        SecondaryButton(label: 'Victoria admin. $bName', icon: Icons.gavel_rounded, onTap: () => Navigator.pop(dialogContext, 'walkover_b')),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
      ],
    ),
  );
  try {
    if (action == 'no_show_a') {
      await AppData.setSpecialMatchResult(match['id'].toString(), winnerTeamId: bId, loserTeamId: aId, specialResult: 'no_show', note: note.text);
    } else if (action == 'no_show_b') {
      await AppData.setSpecialMatchResult(match['id'].toString(), winnerTeamId: aId, loserTeamId: bId, specialResult: 'no_show', note: note.text);
    } else if (action == 'walkover_a') {
      await AppData.setSpecialMatchResult(match['id'].toString(), winnerTeamId: aId, loserTeamId: bId, specialResult: 'walkover', note: note.text);
    } else if (action == 'walkover_b') {
      await AppData.setSpecialMatchResult(match['id'].toString(), winnerTeamId: bId, loserTeamId: aId, specialResult: 'walkover', note: note.text);
    } else {
      return;
    }
    onChanged();
  } catch (e) {
    if (context.mounted) await showToast(context, humanError(e), danger: true);
  } finally {
    note.dispose();
  }
}

Future<void> showMatchHistoryDialog(BuildContext context, {required Map<String, dynamic> match}) async {
  final history = matchResultHistory(match).reversed.toList();
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Historial del partido'),
      content: SizedBox(
        width: double.maxFinite,
        child: history.isEmpty
            ? const Text('Todavía no hay cambios registrados.')
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: history.take(12).map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(matchHistoryEntryText(item), style: const TextStyle(fontWeight: FontWeight.w700)),
                )).toList(),
              ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cerrar')),
      ],
    ),
  );
}

Future<void> renameTournamentTeamDialog(BuildContext context, {required Map<String, dynamic> team, required VoidCallback onChanged}) async {
  final controller = TextEditingController(text: AppData.text(team['name']));
  final name = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Renombrar'),
      content: TextField(controller: controller, autofocus: true, textCapitalization: TextCapitalization.words),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Guardar')),
      ],
    ),
  );
  controller.dispose();
  if (name == null) return;
  try {
    await AppData.renameTournamentTeam(team['id'].toString(), name);
    onChanged();
  } catch (e) {
    if (context.mounted) await showToast(context, humanError(e), danger: true);
  }
}

Future<void> setTournamentTeamSeedDialog(BuildContext context, {required Map<String, dynamic> team, required VoidCallback onChanged}) async {
  final controller = TextEditingController(text: AppData.text(team['seed']).isEmpty ? '1' : AppData.text(team['seed']));
  final value = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Cabeza de serie'),
      content: TextField(
        controller: controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(labelText: 'Número de seed', helperText: '1 es el favorito principal. El cuadro se genera por este orden.'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Guardar')),
      ],
    ),
  );
  controller.dispose();
  final seed = int.tryParse((value ?? '').trim());
  if (seed == null) return;
  try {
    await AppData.updateTournamentTeamSeed(team['id'].toString(), seed);
    onChanged();
  } catch (e) {
    if (context.mounted) await showToast(context, humanError(e), danger: true);
  }
}

Future<void> deleteTournamentTeamDialog(BuildContext context, {required Map<String, dynamic> team, required List<Map<String, dynamic>> matches, required VoidCallback onChanged}) async {
  final teamId = team['id'].toString();
  final linked = matches.where((m) => AppData.text(m['team_a']) == teamId || AppData.text(m['team_b']) == teamId || americanoSideIds(m, 'side_a_ids').contains(teamId) || americanoSideIds(m, 'side_b_ids').contains(teamId)).toList();
  final played = linked.where(matchCountsForStandings).length;
  final ok = await confirmAction(
    context,
    title: linked.isEmpty ? '¿Eliminar participante?' : '¿Retirar participante?',
    body: linked.isEmpty
        ? 'Se eliminará definitivamente porque todavía no tiene partidos vinculados.'
        : 'Tiene ${linked.length} partido${linked.length == 1 ? '' : 's'} vinculado${linked.length == 1 ? '' : 's'}${played > 0 ? ' y $played con resultado' : ''}. Para no romper el historial, se marcará como retirado en lugar de borrarlo.',
    danger: true,
    confirmLabel: linked.isEmpty ? 'Eliminar' : 'Retirar',
  );
  if (ok != true) return;
  try {
    final action = await AppData.safeRemoveTournamentTeam(teamId);
    onChanged();
    if (context.mounted) await showToast(context, action == 'deleted' ? 'Participante eliminado.' : 'Participante retirado sin romper partidos.');
  } catch (e) {
    if (context.mounted) await showToast(context, humanError(e), danger: true);
  }
}

String defaultTournamentName(String format) {
  switch (format) {
    case 'eliminatoria': return 'Copa del grupo';
    case 'americano': return 'Americano del grupo';
    case 'manual': return 'Torneo manual';
    default: return 'Liga del grupo';
  }
}

String stepSubtitle(int step) {
  switch (step) {
    case 0: return 'Nombre y tipo de competición.';
    case 1: return 'Añade equipos, parejas o jugadores.';
    case 2: return 'Jornadas, vueltas, rondas y emparejamientos.';
    case 3: return 'Resultado del partido y puntos de clasificación.';
    case 4: return 'Fechas, duración, pista y Agenda.';
    default: return 'Comprueba todo antes de crear.';
  }
}

List<TournamentDraftMatch> parseTournamentPairings(String raw) {
  final output = <TournamentDraftMatch>[];
  var fallbackRound = 1;
  for (final line in raw.split(RegExp(r'[\n;]+'))) {
    var clean = line.trim();
    if (clean.isEmpty) continue;
    var round = fallbackRound;
    final roundMatch = RegExp(r'(?:jornada|ronda|round)\s*(\d+)', caseSensitive: false).firstMatch(clean);
    if (roundMatch != null) round = int.tryParse(roundMatch.group(1) ?? '') ?? round;
    if (clean.contains(':')) clean = clean.substring(clean.indexOf(':') + 1).trim();
    final parts = clean.split(RegExp(r'\s+(?:vs\.?|contra|v)\s+|\s+-\s+', caseSensitive: false));
    if (parts.length < 2) continue;
    final a = parts.first.trim().replaceAll(RegExp(r'\s+'), ' ');
    final b = parts.sublist(1).join(' vs ').trim().replaceAll(RegExp(r'\s+'), ' ');
    if (a.length < 2 || b.length < 2) continue;
    output.add(TournamentDraftMatch(round: round, teamAName: a, teamBName: b));
    fallbackRound = round;
  }
  return output;
}

List<String> tournamentNamesFromManualPairings(List<TournamentDraftMatch> pairs) {
  return mergeTournamentNames(pairs.expand((p) => [p.teamAName, p.teamBName]).toList());
}

List<String> mergeTournamentNames(List<String> values) {
  final seen = <String>{};
  final output = <String>[];
  for (final value in values) {
    final clean = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (clean.length < 2) continue;
    final key = clean.toLowerCase();
    if (seen.add(key)) output.add(clean);
  }
  return output;
}

List<TournamentDraftMatch> previewPairingsForFormat(
  String format,
  List<String> names, {
  int legs = 1,
  int maxRounds = 0,
  int courts = 1,
}) {
  final clean = mergeTournamentNames(names);
  if (clean.length < 2) return const [];
  final rows = <TournamentDraftMatch>[];
  if (format == 'americano') {
    final generated = generateAmericanoRoundsIds(clean, rounds: maxRounds > 0 ? maxRounds : 5, courts: courts);
    return generated.map((item) => TournamentDraftMatch(
      round: item.round,
      teamAName: item.sideA.join(' / '),
      teamBName: item.sideB.join(' / '),
    )).toList();
  }

  if (format == 'eliminatoria') {
    final targetBracket = nextPowerOfTwoAtLeast(clean.length);
    final byes = max(0, targetBracket - clean.length);
    final byeNames = clean.take(byes).toList();
    final playNames = clean.skip(byes).toList();
    final byeRows = byeNames.map((name) => TournamentDraftMatch(round: 1, teamAName: name, teamBName: 'Pase directo')).toList();
    final playRows = <TournamentDraftMatch>[];
    var left = 0;
    var right = playNames.length - 1;
    while (left < right) {
      playRows.add(TournamentDraftMatch(round: 1, teamAName: playNames[left], teamBName: playNames[right]));
      left++;
      right--;
    }
    final maxRows = max(byeRows.length, playRows.length);
    for (var i = 0; i < maxRows; i++) {
      if (i < byeRows.length) rows.add(byeRows[i]);
      if (i < playRows.length) rows.add(playRows[i]);
    }
    return rows;
  }

  final rotation = <String?>[...clean];
  if (rotation.length.isOdd) rotation.add(null);
  final n = rotation.length;
  final generated = <List<TournamentDraftMatch>>[];
  for (var round = 1; round < n; round++) {
    final roundRows = <TournamentDraftMatch>[];
    for (var i = 0; i < n ~/ 2; i++) {
      final a = rotation[i];
      final b = rotation[n - 1 - i];
      if (a == null || b == null) continue;
      final swap = round.isEven;
      roundRows.add(TournamentDraftMatch(round: round, teamAName: swap ? b : a, teamBName: swap ? a : b));
    }
    generated.add(roundRows);
    final fixed = rotation.first;
    final rest = rotation.sublist(1);
    rest.insert(0, rest.removeLast());
    rotation
      ..clear()
      ..add(fixed)
      ..addAll(rest);
  }
  final limited = maxRounds > 0 ? generated.take(maxRounds).toList() : generated;
  for (var leg = 1; leg <= max(1, legs); leg++) {
    for (var r = 0; r < limited.length; r++) {
      final targetRound = r + 1 + ((leg - 1) * limited.length);
      for (final match in limited[r]) {
        rows.add(leg.isOdd
            ? TournamentDraftMatch(round: targetRound, teamAName: match.teamAName, teamBName: match.teamBName)
            : TournamentDraftMatch(round: targetRound, teamAName: match.teamBName, teamBName: match.teamAName));
      }
    }
  }
  return rows;
}

int currentTournamentRound(List<Map<String, dynamic>> matches) {
  if (matches.isEmpty) return 1;
  final pending = matches.where((m) => !matchCountsForStandings(m) && !['cancelled', 'bye'].contains(AppData.text(m['status']))).toList();
  if (pending.isNotEmpty) return AppData.intValue(pending.first['round'], 1);
  return matches.fold<int>(1, (value, match) => max(value, AppData.intValue(match['round'], 1)));
}

List<Map<String, int>> parseSetScoreInput(String raw) {
  final sets = <Map<String, int>>[];
  for (final line in raw.split(RegExp(r'[\n,;]+'))) {
    final match = RegExp(r'(\d+)\s*[-/]\s*(\d+)').firstMatch(line.trim());
    if (match == null) continue;
    final a = int.tryParse(match.group(1) ?? '');
    final b = int.tryParse(match.group(2) ?? '');
    if (a == null || b == null) continue;
    sets.add({'a': a, 'b': b});
  }
  return sets;
}

TeamStanding bestWins(List<TeamStanding> rows) {
  final copy = [...rows]..sort((a, b) {
    final wins = b.wins.compareTo(a.wins);
    if (wins != 0) return wins;
    return b.points.compareTo(a.points);
  });
  return copy.first;
}

TeamStanding bestGoalDifference(List<TeamStanding> rows) {
  final copy = [...rows]..sort((a, b) {
    final diff = b.goalDifference.compareTo(a.goalDifference);
    if (diff != 0) return diff;
    return b.points.compareTo(a.points);
  });
  return copy.first;
}

TeamStanding bestGoalsFor(List<TeamStanding> rows) {
  final copy = [...rows]..sort((a, b) {
    final goals = b.goalsFor.compareTo(a.goalsFor);
    if (goals != 0) return goals;
    return b.points.compareTo(a.points);
  });
  return copy.first;
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

  void reload() => setState(() { future = AppData.members(widget.group['id'].toString()); });

  Map<String, dynamic>? _me(List<Map<String, dynamic>> members) {
    final uid = AppData.user?.id;
    for (final member in members) {
      if (member['user_id']?.toString() == uid) return member;
    }
    return null;
  }

  String _myRole(List<Map<String, dynamic>> members) => AppData.text(_me(members)?['role'], 'member');

  bool _canManage(List<Map<String, dynamic>> members) {
    final role = _myRole(members);
    return role == 'owner' || role == 'admin';
  }

  Future<void> _changeRole(Map<String, dynamic> member, String role) async {
    final name = memberName(member);
    try {
      await AppData.updateMemberRole(member['id'].toString(), role);
      reload();
      if (mounted) await showToast(context, role == 'admin' ? '$name ahora es admin.' : '$name vuelve a ser miembro.');
    } catch (e) {
      if (mounted) await showToast(context, humanError(e), danger: true);
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
      if (mounted) await showToast(context, humanError(e), danger: true);
    }
  }

  Future<void> _leaveGroup(String groupName, bool isOwner) async {
    if (isOwner) {
      await showToast(context, 'El owner no puede salir sin transferir o eliminar el grupo.', danger: true);
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Salir del grupo'),
        content: Text('Vas a salir de $groupName. Para volver necesitarás una invitación.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Salir')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await AppData.leaveGroup(widget.group['id'].toString());
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
      await showToast(context, 'Has salido del grupo.');
    } catch (e) {
      if (mounted) await showToast(context, humanError(e), danger: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupName = AppData.text(widget.group['name'], 'Grupo');
    final code = AppData.text(widget.group['invite_code'], '------');
    return DirectPage(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        PageHeader(title: 'Miembros', subtitle: 'Personas, roles y permisos del grupo.', leading: true),
        const SizedBox(height: 14),
        InviteAccessCard(groupName: groupName, code: code, compact: false),
        const SizedBox(height: 14),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const CenterLoader(label: 'Cargando miembros...');
            if (snapshot.hasError) return ErrorBlock(message: humanError(snapshot.error), onRetry: reload);
            final members = snapshot.data ?? [];
            final admins = members.where((m) => ['owner', 'admin'].contains(AppData.text(m['role']))).toList();
            final regular = members.where((m) => AppData.text(m['role']) == 'member').toList();
            final canManage = _canManage(members);
            final myRole = _myRole(members);
            final isOwner = myRole == 'owner';
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: StatCard(icon: Icons.groups_rounded, value: members.length.toString(), label: 'Total', color: AppColors.teal)),
                const SizedBox(width: 10),
                Expanded(child: StatCard(icon: Icons.admin_panel_settings_rounded, value: admins.length.toString(), label: 'Admins', color: AppColors.violet)),
                const SizedBox(width: 10),
                Expanded(child: StatCard(icon: Icons.person_outline_rounded, value: regular.length.toString(), label: 'Miembros', color: AppColors.orange)),
              ]),
              const SizedBox(height: 16),
              RoleInfoCard(role: myRole),
              const SizedBox(height: 18),
              SectionHeader(title: 'Owner y administradores'),
              const SizedBox(height: 8),
              ...admins.map((m) => ManageMemberCard(member: m, canManage: canManage, onRole: _changeRole, onRemove: _remove)),
              const SizedBox(height: 16),
              SectionHeader(title: 'Miembros'),
              const SizedBox(height: 8),
              if (regular.isEmpty)
                EmptySlim(icon: Icons.person_add_alt_1_rounded, title: 'Aún no hay miembros normales', body: 'Invita a tu grupo con el código cuando esté listo.')
              else
                ...regular.map((m) => ManageMemberCard(member: m, canManage: canManage, onRole: _changeRole, onRemove: _remove)),
              const SizedBox(height: 16),
              PermissionMatrixCard(),
              const SizedBox(height: 16),
              if (isOwner)
                AppCard(
                  color: AppColors.tealSoft,
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                    Icon(Icons.shield_rounded, color: AppColors.teal),
                    SizedBox(width: 10),
                    Expanded(child: Text('Eres owner del grupo. Puedes gestionar miembros y eliminar el grupo desde Ajustes.', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800, height: 1.3))),
                  ]),
                )
              else
                DangerButton(
                  label: 'Salir del grupo',
                  icon: Icons.logout_rounded,
                  onTap: () => _leaveGroup(groupName, isOwner),
                ),
            ]);
          },
        ),
      ]),
    );
  }
}


class GroupSettingsScreen extends StatefulWidget {
  final Map<String, dynamic> group;
  final VoidCallback? onChanged;
  const GroupSettingsScreen({super.key, required this.group, this.onChanged});

  @override
  State<GroupSettingsScreen> createState() => _GroupSettingsScreenState();
}

class _GroupSettingsScreenState extends State<GroupSettingsScreen> {
  late Map<String, dynamic> group;
  late final TextEditingController nameController;
  late final TextEditingController descriptionController;
  late final TextEditingController timezoneController;
  late final TextEditingController rulesController;
  String type = 'otro';
  String currency = 'EUR';
  String language = 'es';
  bool savingCover = false;
  bool savingInfo = false;
  bool regeneratingCode = false;

  @override
  void initState() {
    super.initState();
    group = Map<String, dynamic>.from(widget.group);
    nameController = TextEditingController(text: AppData.text(group['name'], 'Grupo'));
    descriptionController = TextEditingController(text: AppData.text(group['description'], groupTypeDefaultDescription(AppData.text(group['type'], 'otro'))));
    timezoneController = TextEditingController(text: AppData.text(group['timezone'], 'Europe/Madrid'));
    rulesController = TextEditingController(text: AppData.text(group['rules']));
    type = groupTypeValue(AppData.text(group['type'], 'otro'));
    currency = AppData.text(group['currency'], 'EUR').toUpperCase();
    language = AppData.text(group['language'], 'es').toLowerCase();
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    timezoneController.dispose();
    rulesController.dispose();
    super.dispose();
  }

  Future<void> saveInfo() async {
    setState(() => savingInfo = true);
    try {
      await AppData.updateGroupInfo(
        group['id'].toString(),
        name: nameController.text,
        type: type,
        description: descriptionController.text,
        currency: currency,
        timezone: timezoneController.text,
        language: language,
        rules: rulesController.text,
      );
      if (!mounted) return;
      setState(() {
        group['name'] = nameController.text.trim();
        group['type'] = type;
        group['description'] = descriptionController.text.trim();
        group['currency'] = currency;
        group['timezone'] = timezoneController.text.trim();
        group['language'] = language;
        group['rules'] = rulesController.text.trim();
      });
      widget.onChanged?.call();
      await showToast(context, 'Grupo actualizado.');
    } catch (e) {
      if (!mounted) return;
      await showToast(context, humanError(e), danger: true);
    } finally {
      if (mounted) setState(() => savingInfo = false);
    }
  }

  Future<void> changeCover() async {
    setState(() => savingCover = true);
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 88, maxWidth: 2400);
      if (picked == null) return;
      final raw = await picked.readAsBytes();
      if (!mounted) return;
      final framed = await Navigator.of(context).push<Uint8List>(MaterialPageRoute(
        builder: (_) => ImageFrameEditorScreen(
          bytes: raw,
          title: 'Ajustar portada',
          helper: 'Arrastra y pellizca la imagen para dejar el banner bien encuadrado.',
          aspectRatio: 16 / 7,
          outputWidth: 1600,
        ),
      ));
      if (framed == null) return;
      final url = await AppData.uploadGroupCoverBytes(group['id'].toString(), framed, 'group-cover.png');
      if (!mounted) return;
      setState(() => group['cover_url'] = url);
      widget.onChanged?.call();
      await showToast(context, 'Foto del grupo actualizada.');
    } catch (e) {
      if (!mounted) return;
      await showToast(context, humanError(e), danger: true);
    } finally {
      if (mounted) setState(() => savingCover = false);
    }
  }

  Future<void> removeCover() async {
    setState(() => savingCover = true);
    try {
      await AppData.removeGroupCover(group['id'].toString());
      if (!mounted) return;
      setState(() => group['cover_url'] = null);
      widget.onChanged?.call();
      await showToast(context, 'Foto del grupo eliminada.');
    } catch (e) {
      if (!mounted) return;
      await showToast(context, humanError(e), danger: true);
    } finally {
      if (mounted) setState(() => savingCover = false);
    }
  }

  Future<void> regenerateInviteCode() async {
    final confirm = await showConfirmDialog(
      context,
      title: 'Regenerar código',
      message: 'El código anterior dejará de servir para nuevas invitaciones. Los miembros actuales seguirán dentro.',
      confirm: 'Regenerar',
      danger: true,
    );
    if (confirm != true) return;
    setState(() => regeneratingCode = true);
    try {
      final code = await AppData.regenerateGroupInviteCode(group['id'].toString());
      if (!mounted) return;
      setState(() => group['invite_code'] = code);
      widget.onChanged?.call();
      await showToast(context, 'Código regenerado.');
    } catch (e) {
      if (!mounted) return;
      await showToast(context, humanError(e), danger: true);
    } finally {
      if (mounted) setState(() => regeneratingCode = false);
    }
  }

  Future<void> deleteGroupFlow() async {
    final isOwner = AppData.text(group['owner_id']) == AppData.user?.id;
    if (!isOwner) {
      await showToast(context, 'Solo el owner puede eliminar este grupo.', danger: true);
      return;
    }

    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar grupo'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Vas a eliminar "${AppData.text(group['name'], 'este grupo')}".'),
          const SizedBox(height: 10),
          const Text('Se eliminarán sus miembros, eventos, asistencias, gastos, liquidaciones, torneos y notificaciones relacionadas.'),
          const SizedBox(height: 14),
          const Text('Escribe ELIMINAR GRUPO para confirmar.', style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          TextField(controller: controller, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(hintText: 'ELIMINAR GRUPO')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () => Navigator.pop(context, controller.text.trim().toUpperCase() == 'ELIMINAR GRUPO'),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    final typed = controller.text;
    controller.dispose();
    if (confirmed != true) {
      if (typed.trim().isNotEmpty && mounted) await showToast(context, 'Escribe ELIMINAR GRUPO exactamente para eliminarlo.', danger: true);
      return;
    }

    try {
      await AppData.deleteGroup(group['id'].toString(), 'ELIMINAR GRUPO');
      widget.onChanged?.call();
      if (!mounted) return;
      await showToast(context, 'Grupo eliminado.');
      if (mounted) Navigator.of(context).pop('deleted');
    } catch (e) {
      if (mounted) await showToast(context, humanError(e), danger: true);
    }
  }

  @override Widget build(BuildContext context) {
    final name = AppData.text(group['name'], 'Grupo');
    final code = AppData.text(group['invite_code'], '------');
    return DirectPage(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeader(title: 'Ajustes del grupo', subtitle: 'Identidad, invitaciones y permisos de $name', leading: true),
      const SizedBox(height: 16),
      AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 46, height: 46, decoration: BoxDecoration(color: AppColors.tealSoft, borderRadius: BorderRadius.circular(16)), child: Icon(groupTypeIcon(type), color: AppColors.teal)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Información básica', style: Theme.of(context).textTheme.titleMedium),
            Text('Esto ayuda a Grupli a ordenar planes, gastos y torneos.', style: Theme.of(context).textTheme.bodyMedium),
          ])),
        ]),
        const SizedBox(height: 16),
        FieldLabel('Nombre del grupo'),
        TextField(controller: nameController, textInputAction: TextInputAction.next, decoration: const InputDecoration(hintText: 'Nombre del grupo')),
        const SizedBox(height: 12),
        FieldLabel('Tipo de grupo'),
        DropdownButtonFormField<String>(
          value: type,
          decoration: const InputDecoration(prefixIcon: Icon(Icons.category_rounded)),
          items: const [
            DropdownMenuItem(value: 'deporte', child: Text('Deporte')),
            DropdownMenuItem(value: 'amigos', child: Text('Amigos')),
            DropdownMenuItem(value: 'viaje', child: Text('Viaje')),
            DropdownMenuItem(value: 'cartas', child: Text('Cartas')),
            DropdownMenuItem(value: 'otro', child: Text('Otro')),
          ],
          onChanged: (v) => setState(() => type = groupTypeValue(v ?? 'otro')),
        ),
        const SizedBox(height: 12),
        FieldLabel('Descripción'),
        TextField(controller: descriptionController, maxLines: 3, decoration: const InputDecoration(hintText: 'Explica para qué se usa este grupo')),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            FieldLabel('Moneda'),
            DropdownButtonFormField<String>(
              value: currency,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.payments_rounded)),
              items: const [
                DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                DropdownMenuItem(value: 'USD', child: Text('USD')),
                DropdownMenuItem(value: 'GBP', child: Text('GBP')),
              ],
              onChanged: (v) => setState(() => currency = v ?? 'EUR'),
            ),
          ])),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            FieldLabel('Idioma'),
            DropdownButtonFormField<String>(
              value: language,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.language_rounded)),
              items: const [
                DropdownMenuItem(value: 'es', child: Text('ES')),
                DropdownMenuItem(value: 'en', child: Text('EN')),
              ],
              onChanged: (v) => setState(() => language = v ?? 'es'),
            ),
          ])),
        ]),
        const SizedBox(height: 12),
        FieldLabel('Zona horaria'),
        TextField(controller: timezoneController, decoration: const InputDecoration(prefixIcon: Icon(Icons.schedule_rounded), hintText: 'Europe/Madrid')),
        const SizedBox(height: 12),
        PrimaryButton(label: savingInfo ? 'Guardando...' : 'Guardar cambios', icon: Icons.save_rounded, loading: savingInfo, onTap: saveInfo),
      ])),
      const SizedBox(height: 16),
      GroupCoverSettingsCard(group: group, saving: savingCover, onChange: changeCover, onRemove: removeCover),
      const SizedBox(height: 16),
      InviteAccessCard(groupName: name, code: code, compact: true, onRegenerate: regeneratingCode ? null : regenerateInviteCode),
      const SizedBox(height: 16),
      AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        FieldLabel('Reglas del grupo'),
        TextField(controller: rulesController, minLines: 2, maxLines: 5, decoration: const InputDecoration(hintText: 'Ej. Confirmar asistencia antes del jueves, gastos con ticket...')),
        const SizedBox(height: 12),
        SecondaryButton(label: 'Guardar reglas', icon: Icons.rule_rounded, onTap: saveInfo),
      ])),
      const SizedBox(height: 16),
      SectionHeader(title: 'Administración'),
      const SizedBox(height: 8),
      SettingsRow(icon: Icons.groups_rounded, title: 'Miembros y roles', subtitle: 'Owner, admins y miembros', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => MembersScreen(group: group)))),
      SettingsRow(icon: Icons.verified_user_rounded, title: 'Permisos', subtitle: 'Qué puede hacer cada rol', onTap: () => showPermissionSheet(context)),
      SettingsRow(icon: Icons.delete_outline_rounded, title: 'Eliminar grupo', subtitle: 'Solo owner · elimina eventos, gastos y torneos', danger: true, onTap: deleteGroupFlow),
    ]));
  }
}

class GroupCoverSettingsCard extends StatelessWidget {
  final Map<String, dynamic> group;
  final bool saving;
  final VoidCallback onChange;
  final VoidCallback onRemove;
  const GroupCoverSettingsCard({super.key, required this.group, required this.saving, required this.onChange, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final cover = AppData.text(group['cover_url']);
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Container(
            height: 128,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF073A57), Color(0xFF0B6B8F)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            ),
            child: cover.isNotEmpty
                ? Image.network(cover, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.image_rounded, color: Colors.white, size: 34)))
                : const Center(child: Icon(Icons.image_rounded, color: Colors.white, size: 34)),
          ),
        ),
        const SizedBox(height: 12),
        Text('Foto del grupo', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text('Dale identidad al grupo en Inicio y Mis grupos.', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: SecondaryButton(label: saving ? 'Guardando...' : 'Cambiar foto', icon: Icons.photo_camera_rounded, onTap: saving ? () {} : onChange)),
          if (cover.isNotEmpty) ...[
            const SizedBox(width: 10),
            Expanded(child: DangerButton(label: 'Quitar', icon: Icons.delete_outline_rounded, onTap: saving ? () {} : onRemove)),
          ],
        ]),
      ]),
    );
  }
}


class GroupAlertBell extends StatelessWidget {
  final Map<String, dynamic> group;
  final List<Map<String, dynamic>> pendingEvents;
  final Future<void> Function(Map<String, dynamic> event) onEventOpen;
  final VoidCallback onChanged;

  const GroupAlertBell({
    super.key,
    required this.group,
    required this.pendingEvents,
    required this.onEventOpen,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: AppData.notifications(),
      builder: (context, snapshot) {
        final groupId = group['id']?.toString();
        final notifications = (snapshot.data ?? const <Map<String, dynamic>>[])
            .where((n) => groupId == null || n['group_id']?.toString() == groupId)
            .take(12)
            .toList();
        final unread = notifications.where((n) => n['read_at'] == null).length;
        final count = pendingEvents.length + unread;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            CircleIconButton(
              icon: count > 0 ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
              onTap: () => showGroupAlertsSheet(
                context,
                group: group,
                pendingEvents: pendingEvents,
                notifications: notifications,
                onEventOpen: onEventOpen,
                onChanged: onChanged,
              ),
            ),
            if (count > 0)
              Positioned(
                right: -2,
                top: -4,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    color: AppColors.red,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Text(count > 9 ? '9+' : count.toString(), style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w900)),
                ),
              ),
          ],
        );
      },
    );
  }
}

void showGroupAlertsSheet(
  BuildContext context, {
  required Map<String, dynamic> group,
  required List<Map<String, dynamic>> pendingEvents,
  required List<Map<String, dynamic>> notifications,
  required Future<void> Function(Map<String, dynamic> event) onEventOpen,
  required VoidCallback onChanged,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => GroupAlertsSheet(
      rootContext: context,
      group: group,
      pendingEvents: pendingEvents,
      notifications: notifications,
      onEventOpen: onEventOpen,
      onChanged: onChanged,
    ),
  );
}

class GroupAlertsSheet extends StatelessWidget {
  final BuildContext rootContext;
  final Map<String, dynamic> group;
  final List<Map<String, dynamic>> pendingEvents;
  final List<Map<String, dynamic>> notifications;
  final Future<void> Function(Map<String, dynamic> event) onEventOpen;
  final VoidCallback onChanged;

  const GroupAlertsSheet({
    super.key,
    required this.rootContext,
    required this.group,
    required this.pendingEvents,
    required this.notifications,
    required this.onEventOpen,
    required this.onChanged,
  });

  Future<void> _openNotification(BuildContext context, Map<String, dynamic> notification) async {
    final id = notification['id']?.toString();
    if (id != null && id.isNotEmpty) await AppData.markNotificationRead(id);
    if (context.mounted) Navigator.of(context).pop();
    onChanged();
    final groupId = notification['group_id']?.toString();
    if (groupId != null && groupId.isNotEmpty && rootContext.mounted) {
      await Navigator.of(rootContext).push(MaterialPageRoute(builder: (_) => GroupShell(groupId: groupId)));
      onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasContent = pendingEvents.isNotEmpty || notifications.isNotEmpty;
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * .72),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.lineSoft),
          boxShadow: const [BoxShadow(color: Color(0x24102033), blurRadius: 34, offset: Offset(0, 16))],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 10),
          Container(width: 44, height: 5, decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(99))),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 10, 10),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Avisos del grupo', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 3),
                Text(AppData.text(group['name'], 'Grupo'), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700)),
              ])),
              IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close_rounded)),
            ]),
          ),
          Flexible(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
              shrinkWrap: true,
              children: [
                if (!hasContent)
                  EmptySlim(icon: Icons.notifications_none_rounded, title: 'Sin avisos pendientes', body: 'Cuando haya respuestas, gastos o cambios importantes aparecerán aquí.'),
                if (pendingEvents.isNotEmpty) ...[
                  const _SheetLabel('Respuestas pendientes'),
                  ...pendingEvents.take(6).map((event) => PendingDecisionRow(
                    event: event,
                    onTap: () async {
                      Navigator.of(context).pop();
                      await onEventOpen(event);
                    },
                  )),
                  const SizedBox(height: 8),
                ],
                if (notifications.isNotEmpty) ...[
                  const _SheetLabel('Notificaciones'),
                  AppCard(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(children: [
                      for (int i = 0; i < notifications.length; i++) ...[
                        NotificationListRow(notification: notifications[i], onTap: () => _openNotification(context, notifications[i])),
                        if (i != notifications.length - 1) const Divider(height: 1, indent: 64, color: AppColors.line),
                      ],
                    ]),
                  ),
                ],
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

class _SheetLabel extends StatelessWidget {
  final String text;
  const _SheetLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(2, 12, 2, 8),
    child: Text(text, style: const TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: .2)),
  );
}

class PendingDecisionRow extends StatelessWidget {
  final Map<String, dynamic> event;
  final VoidCallback onTap;
  const PendingDecisionRow({super.key, required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(event['starts_at']?.toString() ?? '')?.toLocal() ?? DateTime.now();
    final color = eventKindColor(event);
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      child: Row(children: [
        Container(
          width: 40,
          height: 42,
          decoration: BoxDecoration(color: eventKindSoftColor(event), borderRadius: BorderRadius.circular(14)),
          child: Icon(notificationIcon('event'), color: color, size: 20),
        ),
        const SizedBox(width: 11),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(AppData.text(event['title'], 'Evento'), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink)),
          const SizedBox(height: 3),
          Text('${longDateTime(date)} · responde asistencia', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w700)),
        ])),
        const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
      ]),
    );
  }
}

class NotificationsScreen extends StatefulWidget {
  final VoidCallback onChanged;
  const NotificationsScreen({super.key, required this.onChanged});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<Map<String, dynamic>>> future;

  @override
  void initState() {
    super.initState();
    load();
  }

  void load() => future = AppData.notifications();
  void reload() => setState(load);

  Future<void> markAll() async {
    await AppData.markAllNotificationsRead();
    reload();
  }

  Future<void> openNotification(Map<String, dynamic> notification) async {
    final id = notification['id']?.toString();
    if (id != null && id.isNotEmpty) await AppData.markNotificationRead(id);
    final groupId = notification['group_id']?.toString();
    reload();
    widget.onChanged();
    if (!mounted) return;
    if (groupId != null && groupId.isNotEmpty) {
      final tab = notificationGroupTab(notification);
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => GroupShell(groupId: groupId, initialTab: tab)));
      widget.onChanged();
      reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: AppColors.teal,
        onRefresh: () async => reload(),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: future,
          builder: (context, snapshot) {
            final notifications = snapshot.data ?? [];
            final unread = notifications.where((n) => n['read_at'] == null).length;
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 112),
              children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: PageHeader(title: 'Avisos', subtitle: unread == 0 ? 'Todo leído en tus grupos.' : '$unread aviso${unread == 1 ? '' : 's'} sin leer', leading: false)),
                  if (unread > 0)
                    TextButton(onPressed: markAll, child: const Text('Leer todo')),
                ]),
                const SizedBox(height: 12),
                PushStatusCard(onEnable: () async {
                  final token = await PushNotificationService.enableForCurrentDevice();
                  if (!mounted) return;
                  if (token == null) {
                    await showToast(context, 'Falta Firebase o el permiso de notificaciones está desactivado.', danger: true);
                  } else {
                    await showToast(context, 'Notificaciones push activadas en este dispositivo.');
                  }
                }),
                const SizedBox(height: 16),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const CenterLoader(label: 'Cargando avisos...')
                else if (snapshot.hasError)
                  ErrorBlock(message: 'No se pudieron cargar los avisos. Ejecuta el SQL de notificaciones si acabas de actualizar.', onRetry: reload)
                else if (notifications.isEmpty)
                  EmptyBlock(
                    icon: Icons.notifications_none_rounded,
                    title: 'Sin avisos todavía',
                    body: 'Cuando alguien cree una quedada, añada un gasto, registre un resultado o entre al grupo, aparecerá aquí.',
                  )
                else
                  AppCard(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(children: [
                      for (int i = 0; i < notifications.length; i++) ...[
                        NotificationListRow(notification: notifications[i], onTap: () => openNotification(notifications[i])),
                        if (i != notifications.length - 1) const Divider(height: 1, indent: 64, color: AppColors.line),
                      ],
                    ]),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class PushStatusCard extends StatelessWidget {
  final Future<void> Function() onEnable;
  const PushStatusCard({super.key, required this.onEnable});

  @override
  Widget build(BuildContext context) {
    final configured = AppConfig.firebaseConfigured || !kIsWeb;
    return AppCard(
      color: configured ? AppColors.tealSoft : AppColors.surface,
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: configured ? AppColors.white : AppColors.tealSoft, borderRadius: BorderRadius.circular(15)),
          child: Icon(configured ? Icons.notifications_active_rounded : Icons.notifications_none_rounded, color: AppColors.teal),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(configured ? 'Push preparado para APK' : 'Push pendiente de Firebase', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            configured
                ? 'Activa este dispositivo para recibir avisos del grupo aunque la app no esté abierta.'
                : 'Los avisos internos ya funcionan. Para push real necesitas Firebase y google-services.json en Android.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(onPressed: onEnable, icon: const Icon(Icons.power_settings_new_rounded), label: Text(configured ? 'Activar en este dispositivo' : 'Comprobar configuración')),
          ),
        ])),
      ]),
    );
  }
}

class NotificationListRow extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback onTap;
  const NotificationListRow({super.key, required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final unread = notification['read_at'] == null;
    final type = AppData.text(notification['type'], 'general');
    final color = notificationColor(type);
    final created = DateTime.tryParse(notification['created_at']?.toString() ?? '')?.toLocal();
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Stack(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: color.withOpacity(.12), borderRadius: BorderRadius.circular(14)),
              child: Icon(notificationIcon(type), color: color, size: 21),
            ),
            if (unread)
              Positioned(right: 0, top: 0, child: Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppColors.red, shape: BoxShape.circle))),
          ]),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(AppData.text(notification['title'], 'Aviso'), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: unread ? FontWeight.w900 : FontWeight.w800, color: AppColors.ink))),
              if (created != null) Text(notificationTime(created), style: const TextStyle(color: AppColors.muted, fontSize: 11, fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 4),
            Text(AppData.text(notification['body'], 'Hay una novedad en tu grupo.'), maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium),
          ])),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        ]),
      ),
    );
  }
}


int notificationGroupTabFromValues(String routeType, String type) {
  final value = AppData.text(routeType, AppData.text(type)).toLowerCase();
  if (value.contains('event') || value.contains('agenda') || value.contains('attendance') || value.contains('calendar')) return 1;
  if (value.contains('finance') || value.contains('expense') || value.contains('settlement') || value.contains('payment') || value.contains('gasto')) return 2;
  if (value.contains('tournament') || value.contains('match') || value.contains('torneo') || value.contains('resultado')) return 3;
  if (value.contains('member') || value.contains('grupo') || value.contains('group') || value.contains('invite')) return 4;
  return 0;
}

int notificationGroupTab(Map<String, dynamic> notification) {
  return notificationGroupTabFromValues(
    AppData.text(notification['route_type']),
    AppData.text(notification['type']),
  );
}

IconData notificationIcon(String type) {
  return switch (type) {
    'event' => Icons.event_available_rounded,
    'finance' => Icons.account_balance_wallet_rounded,
    'tournament' => Icons.emoji_events_rounded,
    'member' => Icons.groups_rounded,
    _ => Icons.notifications_rounded,
  };
}

Color notificationColor(String type) {
  return switch (type) {
    'event' => AppColors.teal,
    'finance' => AppColors.green,
    'tournament' => AppColors.orange,
    'member' => AppColors.violet,
    _ => AppColors.blue,
  };
}

String notificationTime(DateTime date) {
  final now = DateTime.now();
  final diff = now.difference(date);
  if (diff.inMinutes < 1) return 'ahora';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  if (diff.inDays < 7) return '${diff.inDays}d';
  return DateFormat('dd/MM', 'es_ES').format(date);
}


class SupportTicketScreen extends StatefulWidget {
  final Map<String, dynamic>? group;
  final String screen;
  const SupportTicketScreen({super.key, this.group, this.screen = 'perfil'});

  @override
  State<SupportTicketScreen> createState() => _SupportTicketScreenState();
}

class _SupportTicketScreenState extends State<SupportTicketScreen> {
  final title = TextEditingController();
  final description = TextEditingController();
  String type = 'bug';
  String priority = 'normal';
  bool loading = false;
  late Future<List<Map<String, dynamic>>> myTicketsFuture;

  @override
  void initState() {
    super.initState();
    myTicketsFuture = AppData.mySupportTickets();
  }

  @override
  void dispose() {
    title.dispose();
    description.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    setState(() => loading = true);
    try {
      await AppData.createSupportTicket(
        groupId: widget.group?['id']?.toString(),
        type: type,
        priority: priority,
        title: title.text,
        description: description.text,
        screen: widget.screen,
      );
      title.clear();
      description.clear();
      setState(() { myTicketsFuture = AppData.mySupportTickets(); });
      if (mounted) await showToast(context, 'Reporte enviado. Gracias, lo revisarás desde el panel admin.');
    } catch (e) {
      if (mounted) await showToast(context, humanError(e), danger: true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupName = AppData.text(widget.group?['name'], 'Cuenta general');
    return DirectPage(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeader(title: 'Ayuda y soporte', subtitle: 'Reporta errores, dudas o sugerencias sin salir de Grupli.', leading: true),
      const SizedBox(height: 14),
      AppCard(
        padding: const EdgeInsets.all(16),
        color: AppColors.tealSoft,
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.support_agent_rounded, color: AppColors.teal)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Enviar reporte', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('Zona: $groupName · Versión v15.21 · ${kIsWeb ? 'web' : defaultTargetPlatform.name}', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800)),
          ])),
        ]),
      ),
      const SizedBox(height: 14),
      AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        FieldLabel('Tipo de reporte'),
        DropdownButtonFormField<String>(
          value: type,
          items: const [
            DropdownMenuItem(value: 'bug', child: Text('Bug o fallo')),
            DropdownMenuItem(value: 'cuenta', child: Text('Cuenta / acceso')),
            DropdownMenuItem(value: 'grupo', child: Text('Grupo / invitación')),
            DropdownMenuItem(value: 'evento', child: Text('Evento / asistencia')),
            DropdownMenuItem(value: 'finanzas', child: Text('Finanzas / pagos')),
            DropdownMenuItem(value: 'torneo', child: Text('Torneos / resultados')),
            DropdownMenuItem(value: 'sugerencia', child: Text('Sugerencia')),
            DropdownMenuItem(value: 'otro', child: Text('Otro')),
          ],
          onChanged: (v) => setState(() => type = v ?? 'bug'),
        ),
        const SizedBox(height: 12),
        FieldLabel('Prioridad'),
        DropdownButtonFormField<String>(
          value: priority,
          items: const [
            DropdownMenuItem(value: 'low', child: Text('Baja')),
            DropdownMenuItem(value: 'normal', child: Text('Normal')),
            DropdownMenuItem(value: 'high', child: Text('Alta')),
            DropdownMenuItem(value: 'critical', child: Text('Crítica')),
          ],
          onChanged: (v) => setState(() => priority = v ?? 'normal'),
        ),
        const SizedBox(height: 12),
        FieldLabel('Título'),
        TextField(controller: title, decoration: const InputDecoration(hintText: 'Ej. No me deja marcar un pago')),
        const SizedBox(height: 12),
        FieldLabel('Descripción'),
        TextField(controller: description, minLines: 4, maxLines: 7, decoration: const InputDecoration(hintText: 'Cuenta qué ha pasado, en qué pantalla y qué esperabas que ocurriera.')),
        const SizedBox(height: 16),
        PrimaryButton(label: 'Enviar reporte', icon: Icons.send_rounded, loading: loading, onTap: submit),
      ])),
      const SizedBox(height: 18),
      SectionHeader(title: 'Tus reportes recientes'),
      const SizedBox(height: 8),
      FutureBuilder<List<Map<String, dynamic>>>(
        future: myTicketsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const CenterLoader(label: 'Cargando reportes...');
          final tickets = snapshot.data ?? [];
          if (tickets.isEmpty) return EmptySlim(icon: Icons.inbox_rounded, title: 'Sin reportes todavía', body: 'Cuando envíes algo aparecerá aquí.');
          return Column(children: tickets.take(5).map((ticket) => SupportTicketCard(ticket: ticket)).toList());
        },
      ),
    ]));
  }
}


class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  String filter = 'open';
  int section = 0;
  late Future<_AdminDashboardData> future;

  @override
  void initState() {
    super.initState();
    load();
  }

  void load() {
    future = _AdminDashboardData.load(status: filter);
  }

  void reload() => setState(load);

  Future<void> changeStatus(Map<String, dynamic> ticket, String status, {String? note}) async {
    final role = await AppData.currentAppAdminRole();
    if (role == 'viewer' || role.isEmpty) {
      if (mounted) await showToast(context, 'Tu rol puede ver métricas, pero no modificar reportes.', danger: true);
      return;
    }
    try {
      await AppData.updateSupportTicketStatus(ticket['id'].toString(), status, note: note);
      reload();
      if (mounted) await showToast(context, 'Reporte actualizado.');
    } catch (e) {
      if (mounted) await showToast(context, humanError(e), danger: true);
    }
  }

  Future<void> replyToTicket(Map<String, dynamic> ticket) async {
    final controller = TextEditingController(text: AppData.text(ticket['admin_note']));
    final note = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Responder reporte'),
        content: TextField(
          controller: controller,
          minLines: 4,
          maxLines: 7,
          decoration: const InputDecoration(
            hintText: 'Escribe una respuesta visible para el usuario...',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Guardar respuesta')),
        ],
      ),
    );
    controller.dispose();
    if (note == null) return;
    await changeStatus(ticket, 'reviewing', note: note);
  }

  Future<void> setUserStatus(Map<String, dynamic> user, String status) async {
    final email = AppData.text(user['email']);
    if (email.isEmpty) return;
    final label = status == 'blocked' ? 'bloquear' : 'activar';
    final ok = await confirmAction(
      context,
      title: '¿${label[0].toUpperCase()}${label.substring(1)} usuario?',
      body: status == 'blocked'
          ? 'El usuario podrá seguir existiendo en base de datos, pero quedará marcado como bloqueado para soporte/admin.'
          : 'El usuario volverá a aparecer como activo.',
      danger: status == 'blocked',
      confirmLabel: status == 'blocked' ? 'Bloquear' : 'Activar',
    );
    if (ok != true) return;
    try {
      await AppData.adminSetUserStatus(email, status);
      reload();
      if (mounted) await showToast(context, status == 'blocked' ? 'Usuario bloqueado.' : 'Usuario activado.');
    } catch (e) {
      if (mounted) await showToast(context, humanError(e), danger: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DirectPage(child: FutureBuilder<_AdminDashboardData>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const CenterLoader(label: 'Cargando panel admin...');
        if (snapshot.hasError) return ErrorBlock(message: humanError(snapshot.error), onRetry: reload);
        final data = snapshot.data ?? _AdminDashboardData.empty();
        final overview = data.overview;
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          PageHeader(title: 'Panel admin', subtitle: 'Soporte, usuarios, grupos y calidad de Grupli.', leading: true),
          const SizedBox(height: 10),
          AdminRoleInfoCard(role: data.role),
          const SizedBox(height: 12),
          AdminOverviewHero(overview: overview),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: AdminMetricCard(label: 'Usuarios', value: '${AppData.intValue(overview['users'])}', icon: Icons.people_alt_rounded, color: AppColors.teal)),
            const SizedBox(width: 9),
            Expanded(child: AdminMetricCard(label: 'Grupos', value: '${AppData.intValue(overview['groups'])}', icon: Icons.groups_rounded, color: AppColors.violet)),
          ]),
          const SizedBox(height: 9),
          Row(children: [
            Expanded(child: AdminMetricCard(label: 'Reportes', value: '${AppData.intValue(overview['open_tickets'])}', icon: Icons.support_agent_rounded, color: AppColors.orange)),
            const SizedBox(width: 9),
            Expanded(child: AdminMetricCard(label: 'Críticos', value: '${AppData.intValue(overview['critical_tickets'])}', icon: Icons.warning_amber_rounded, color: AppColors.red)),
          ]),
          const SizedBox(height: 14),
          AdminSectionTabs(index: section, role: data.role, onChanged: (i) => setState(() => section = i)),
          const SizedBox(height: 14),
          if (section == 0) ...[
            SectionHeader(
              title: 'Reportes de usuarios',
              action: data.isViewer ? 'Solo lectura' : filter == 'open' ? 'Ver todos' : 'Abiertos',
              onTap: data.isViewer ? null : () { setState(() { filter = filter == 'open' ? 'all' : 'open'; load(); }); },
            ),
            const SizedBox(height: 8),
            if (data.isViewer)
              EmptySlim(icon: Icons.visibility_rounded, title: 'Modo viewer', body: 'Puedes ver métricas y estado general, pero no detalles sensibles ni acciones de soporte.')
            else if (data.tickets.isEmpty)
              EmptySlim(icon: Icons.verified_rounded, title: filter == 'open' ? 'No hay reportes abiertos' : 'No hay reportes', body: 'Cuando un usuario reporte algo aparecerá aquí.')
            else
              ...data.tickets.map((ticket) => AdminTicketCard(
                ticket: ticket,
                canHandle: data.canHandleSupport,
                onStatus: (status) => changeStatus(ticket, status),
                onReply: data.canHandleSupport ? () => replyToTicket(ticket) : null,
              )),
          ] else if (section == 1) ...[
            SectionHeader(title: 'Usuarios', action: data.isOwner ? '${data.users.length}' : 'Owner'),
            const SizedBox(height: 8),
            if (!data.isOwner)
              EmptySlim(icon: Icons.lock_rounded, title: 'Solo owner', body: 'Los usuarios son información sensible. Support y viewer no pueden gestionarlos.')
            else if (data.users.isEmpty)
              EmptySlim(icon: Icons.people_alt_rounded, title: 'Sin usuarios visibles', body: 'Ejecuta el SQL v15.29 si esta lista aparece vacía.')
            else
              ...data.users.map((u) => AdminUserCard(user: u, onBlock: () => setUserStatus(u, 'blocked'), onActivate: () => setUserStatus(u, 'active'))),
          ] else if (section == 2) ...[
            SectionHeader(title: 'Grupos', action: data.isOwner ? '${data.groups.length}' : 'Owner'),
            const SizedBox(height: 8),
            if (!data.isOwner)
              EmptySlim(icon: Icons.lock_rounded, title: 'Solo owner', body: 'La vista completa de grupos queda reservada al owner.')
            else if (data.groups.isEmpty)
              EmptySlim(icon: Icons.groups_rounded, title: 'Sin grupos visibles', body: 'Cuando se creen grupos aparecerán aquí.')
            else
              ...data.groups.map((g) => AdminGroupCard(group: g)),
          ] else if (section == 3) ...[
            SectionHeader(title: 'Dispositivos push', action: data.isOwner ? '${data.devices.length}' : 'Owner'),
            const SizedBox(height: 8),
            if (!data.isOwner)
              EmptySlim(icon: Icons.lock_rounded, title: 'Solo owner', body: 'Los tokens/dispositivos son datos técnicos sensibles.')
            else if (data.devices.isEmpty)
              EmptySlim(icon: Icons.phone_android_rounded, title: 'Sin dispositivos', body: 'Aparecerán cuando los usuarios activen push en la APK.')
            else
              ...data.devices.map((d) => AdminDeviceCard(device: d)),
          ] else ...[
            SectionHeader(title: 'Actividad y calidad', action: '${data.qualityEvents.length}'),
            const SizedBox(height: 8),
            if (data.qualityEvents.isEmpty)
              EmptySlim(icon: Icons.insights_rounded, title: 'Sin eventos todavía', body: 'Se guardarán reportes y señales internas útiles.')
            else
              ...data.qualityEvents.take(20).map((event) => QualityEventCard(event: event)),
          ],
        ]);
      },
    ));
  }
}

class _AdminDashboardData {
  final Map<String, dynamic> overview;
  final List<Map<String, dynamic>> tickets;
  final List<Map<String, dynamic>> qualityEvents;
  final List<Map<String, dynamic>> users;
  final List<Map<String, dynamic>> groups;
  final List<Map<String, dynamic>> devices;
  final String role;
  const _AdminDashboardData({
    required this.overview,
    required this.tickets,
    required this.qualityEvents,
    required this.users,
    required this.groups,
    required this.devices,
    this.role = '',
  });
  static _AdminDashboardData empty() => const _AdminDashboardData(overview: {}, tickets: [], qualityEvents: [], users: [], groups: [], devices: [], role: '');
  bool get isOwner => role == 'owner';
  bool get canHandleSupport => role == 'owner' || role == 'support';
  bool get isViewer => role == 'viewer';
  static Future<_AdminDashboardData> load({String status = 'open'}) async {
    final role = await AppData.currentAppAdminRole();
    final isOwner = role == 'owner';
    final results = await Future.wait([
      AppData.adminOverview(),
      role == 'viewer' ? Future.value(<Map<String, dynamic>>[]) : AppData.adminSupportTickets(status: status),
      AppData.adminQualityEvents(),
      isOwner ? AppData.adminUsersOverview() : Future.value(<Map<String, dynamic>>[]),
      isOwner ? AppData.adminGroupsOverview() : Future.value(<Map<String, dynamic>>[]),
      isOwner ? AppData.adminDevicesOverview() : Future.value(<Map<String, dynamic>>[]),
    ]);
    return _AdminDashboardData(
      overview: AppData.asMap(results[0]),
      tickets: AppData.asList(results[1]),
      qualityEvents: AppData.asList(results[2]),
      users: AppData.asList(results[3]),
      groups: AppData.asList(results[4]),
      devices: AppData.asList(results[5]),
      role: role,
    );
  }
}

class SupportTicketCard extends StatelessWidget {
  final Map<String, dynamic> ticket;
  const SupportTicketCard({super.key, required this.ticket});
  @override
  Widget build(BuildContext context) {
    final status = AppData.text(ticket['status'], 'open');
    final color = ticketStatusColor(status);
    final group = AppData.asMap(ticket['groups']);
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withOpacity(.10), borderRadius: BorderRadius.circular(14)), child: Icon(ticketTypeIcon(AppData.text(ticket['type'])), color: color)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(AppData.text(ticket['title'], 'Reporte'), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink)),
            const SizedBox(height: 3),
            Text('${ticketStatusLabel(status)} · ${AppData.text(group['name'], 'Cuenta general')}', style: const TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w700)),
          ])),
          _MiniChip(text: ticketPriorityLabel(AppData.text(ticket['priority'], 'normal')), color: ticketPriorityColor(AppData.text(ticket['priority'], 'normal'))),
        ]),
        if (AppData.text(ticket['admin_note']).isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.tealSoft, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.teal.withOpacity(.14))),
            child: Text('Respuesta de soporte: ${AppData.text(ticket['admin_note'])}', style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800, height: 1.3)),
          ),
        ],
      ])),
    );
  }
}


class AdminRoleInfoCard extends StatelessWidget {
  final String role;
  const AdminRoleInfoCard({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final normalized = role.isEmpty ? 'viewer' : role;
    final color = normalized == 'owner' ? AppColors.orange : normalized == 'support' ? AppColors.teal : AppColors.violet;
    final title = normalized == 'owner' ? 'Owner de la app' : normalized == 'support' ? 'Soporte' : 'Viewer';
    final body = normalized == 'owner'
        ? 'Control total: usuarios, grupos, reportes, métricas y acciones críticas.'
        : normalized == 'support'
            ? 'Puede ver y responder reportes, sin tocar acciones críticas de usuarios.'
            : 'Solo métricas y estado general. No puede modificar información sensible.';
    return AppCard(
      padding: const EdgeInsets.all(13),
      color: color.withOpacity(.08),
      child: Row(children: [
        Container(width: 42, height: 42, decoration: BoxDecoration(color: color.withOpacity(.14), borderRadius: BorderRadius.circular(14)), child: Icon(normalized == 'owner' ? Icons.workspace_premium_rounded : normalized == 'support' ? Icons.support_agent_rounded : Icons.visibility_rounded, color: color)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
          const SizedBox(height: 3),
          Text(body, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 12.5, height: 1.25)),
        ])),
        _MiniChip(text: normalized.toUpperCase(), color: color),
      ]),
    );
  }
}

class AdminOverviewHero extends StatelessWidget {
  final Map<String, dynamic> overview;
  const AdminOverviewHero({super.key, required this.overview});
  @override
  Widget build(BuildContext context) {
    final open = AppData.intValue(overview['open_tickets']);
    final critical = AppData.intValue(overview['critical_tickets']);
    final good = open == 0 && critical == 0;
    return AppCard(
      color: good ? AppColors.greenSoft : AppColors.tealDark,
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        Container(width: 48, height: 48, decoration: BoxDecoration(color: good ? AppColors.white : Colors.white.withOpacity(.13), borderRadius: BorderRadius.circular(16)), child: Icon(good ? Icons.verified_rounded : Icons.admin_panel_settings_rounded, color: good ? AppColors.green : Colors.white)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(good ? 'Todo controlado' : '$open reportes abiertos', style: TextStyle(color: good ? AppColors.ink : Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
          const SizedBox(height: 4),
          Text(critical > 0 ? '$critical críticos necesitan revisión prioritaria.' : 'Revisa soporte, usuarios y señales de calidad desde aquí.', style: TextStyle(color: good ? AppColors.muted : const Color(0xDFFFFFFF), fontWeight: FontWeight.w700)),
        ])),
      ]),
    );
  }
}

class AdminMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const AdminMetricCard({super.key, required this.label, required this.value, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(14),
    child: Row(children: [
      Container(width: 38, height: 38, decoration: BoxDecoration(color: color.withOpacity(.11), borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: color, size: 20)),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink, fontSize: 19)),
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800, fontSize: 12)),
      ])),
    ]),
  );
}

class AdminTicketCard extends StatelessWidget {
  final Map<String, dynamic> ticket;
  final bool canHandle;
  final ValueChanged<String> onStatus;
  final VoidCallback? onReply;
  const AdminTicketCard({super.key, required this.ticket, this.canHandle = true, required this.onStatus, this.onReply});
  @override
  Widget build(BuildContext context) {
    final profile = AppData.asMap(ticket['profiles']);
    final group = AppData.asMap(ticket['groups']);
    final status = AppData.text(ticket['status'], 'open');
    final priority = AppData.text(ticket['priority'], 'normal');
    final name = AppData.text(profile['full_name'], AppData.text(profile['email'], 'Usuario'));
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ProfileAvatar(name: name, avatarUrl: AppData.text(profile['avatar_url']), radius: 21),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(AppData.text(ticket['title'], 'Reporte'), style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink))),
              _MiniChip(text: ticketPriorityLabel(priority), color: ticketPriorityColor(priority)),
            ]),
            const SizedBox(height: 3),
            Text('${ticketTypeLabel(AppData.text(ticket['type']))} · ${AppData.text(group['name'], 'Cuenta general')} · ${ticketStatusLabel(status)}', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 12)),
          ])),
        ]),
        const SizedBox(height: 10),
        Text(AppData.text(ticket['description'], 'Sin descripción'), style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700, height: 1.35)),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _MiniChip(text: AppData.text(ticket['app_version'], AppConfig.appVersion), color: AppColors.teal),
          _MiniChip(text: AppData.text(ticket['device_info'], 'dispositivo'), color: AppColors.violet),
          _MiniChip(text: AppData.text(ticket['screen'], 'app'), color: AppColors.muted),
        ]),
        if (AppData.text(ticket['admin_note']).isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.greenSoft, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.green.withOpacity(.15))),
            child: Text('Respuesta admin: ${AppData.text(ticket['admin_note'])}', style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800, height: 1.3)),
          ),
        ],
        const SizedBox(height: 12),
        if (canHandle)
          Wrap(spacing: 8, runSpacing: 8, children: [
            SizedBox(width: 130, child: SecondaryButton(label: 'Revisando', icon: Icons.search_rounded, onTap: () => onStatus('reviewing'))),
            SizedBox(width: 130, child: PrimaryButton(label: 'Resolver', icon: Icons.check_rounded, onTap: () => onStatus('resolved'))),
            SizedBox(width: 120, child: SecondaryButton(label: 'Cerrar', icon: Icons.archive_rounded, onTap: () => onStatus('closed'))),
            if (onReply != null) SizedBox(width: 130, child: SecondaryButton(label: 'Responder', icon: Icons.reply_rounded, onTap: () => onReply!.call())),
          ])
        else
          EmptySlim(icon: Icons.visibility_rounded, title: 'Solo lectura', body: 'Tu rol no permite modificar reportes.'),
      ])),
    );
  }
}

class QualityEventCard extends StatelessWidget {
  final Map<String, dynamic> event;
  const QualityEventCard({super.key, required this.event});
  @override
  Widget build(BuildContext context) {
    final profile = AppData.asMap(event['profiles']);
    final group = AppData.asMap(event['groups']);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.blueSoft, borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.insights_rounded, color: AppColors.blue, size: 19)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(AppData.text(event['event_type'], 'evento'), style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink)),
            const SizedBox(height: 2),
            Text('${AppData.text(profile['email'], 'usuario')} · ${AppData.text(group['name'], 'sin grupo')} · ${AppData.text(event['screen'], 'app')}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 12)),
          ])),
        ]),
      ),
    );
  }
}


class AdminSectionTabs extends StatelessWidget {
  final int index;
  final String role;
  final ValueChanged<int> onChanged;
  const AdminSectionTabs({super.key, required this.index, required this.role, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.support_agent_rounded, 'Reportes', AppColors.orange),
      (Icons.people_alt_rounded, 'Usuarios', AppColors.teal),
      (Icons.groups_rounded, 'Grupos', AppColors.violet),
      (Icons.phone_android_rounded, 'Dispositivos', AppColors.blue),
      (Icons.insights_rounded, 'Actividad', AppColors.green),
    ];
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, i) {
          final selected = index == i;
          final item = items[i];
          return InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => onChanged(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
              decoration: BoxDecoration(
                color: selected ? item.$3 : AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: selected ? item.$3 : AppColors.line),
                boxShadow: selected ? [BoxShadow(color: item.$3.withOpacity(.22), blurRadius: 14, offset: const Offset(0, 7))] : null,
              ),
              child: Row(children: [
                Icon(item.$1, size: 17, color: selected ? Colors.white : item.$3),
                const SizedBox(width: 7),
                Text(item.$2, style: TextStyle(color: selected ? Colors.white : AppColors.ink, fontWeight: FontWeight.w900, fontSize: 12)),
              ]),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: items.length,
      ),
    );
  }
}

class AdminUserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onBlock;
  final VoidCallback onActivate;
  const AdminUserCard({super.key, required this.user, required this.onBlock, required this.onActivate});

  @override
  Widget build(BuildContext context) {
    final name = AppData.text(user['full_name'], AppData.text(user['email'], 'Usuario'));
    final email = AppData.text(user['email'], 'sin email');
    final status = AppData.text(user['status'], 'active');
    final role = AppData.text(user['admin_role'], '');
    final isBlocked = status == 'blocked';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.all(13),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            ProfileAvatar(name: name, avatarUrl: AppData.text(user['avatar_url']), radius: 22),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text(email, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 12)),
            ])),
            _MiniChip(text: isBlocked ? 'BLOQUEADO' : 'ACTIVO', color: isBlocked ? AppColors.red : AppColors.green),
          ]),
          const SizedBox(height: 10),
          Wrap(spacing: 7, runSpacing: 7, children: [
            if (role.isNotEmpty) _MiniChip(text: role.toUpperCase(), color: role == 'owner' ? AppColors.orange : role == 'support' ? AppColors.teal : AppColors.violet),
            _MiniChip(text: '${AppData.intValue(user['groups_count'])} grupos', color: AppColors.violet),
            _MiniChip(text: '${AppData.intValue(user['devices_count'])} dispositivos', color: AppColors.blue),
            _MiniChip(text: AppData.text(user['last_seen_at']).isEmpty ? 'sin actividad push' : 'push visto', color: AppColors.muted),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: SecondaryButton(label: isBlocked ? 'Activar' : 'Bloquear', icon: isBlocked ? Icons.lock_open_rounded : Icons.block_rounded, onTap: isBlocked ? onActivate : onBlock)),
          ]),
        ]),
      ),
    );
  }
}

class AdminGroupCard extends StatelessWidget {
  final Map<String, dynamic> group;
  const AdminGroupCard({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    final name = AppData.text(group['name'], 'Grupo');
    final ownerEmail = AppData.text(group['owner_email'], 'owner no disponible');
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.all(13),
        child: Row(children: [
          Container(width: 46, height: 46, decoration: BoxDecoration(color: AppColors.violetSoft, borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.groups_rounded, color: AppColors.violet)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
            const SizedBox(height: 3),
            Text('Owner: $ownerEmail', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 12)),
            const SizedBox(height: 8),
            Wrap(spacing: 7, runSpacing: 7, children: [
              _MiniChip(text: '${AppData.intValue(group['members_count'])} miembros', color: AppColors.teal),
              _MiniChip(text: '${AppData.intValue(group['events_count'])} eventos', color: AppColors.orange),
              _MiniChip(text: '${AppData.intValue(group['expenses_count'])} gastos', color: AppColors.green),
              _MiniChip(text: '${AppData.intValue(group['tournaments_count'])} torneos', color: AppColors.red),
            ]),
          ])),
        ]),
      ),
    );
  }
}

class AdminDeviceCard extends StatelessWidget {
  final Map<String, dynamic> device;
  const AdminDeviceCard({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    final enabled = device['enabled'] != false;
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: AppCard(
        padding: const EdgeInsets.all(13),
        child: Row(children: [
          Container(width: 42, height: 42, decoration: BoxDecoration(color: enabled ? AppColors.blueSoft : AppColors.faint, borderRadius: BorderRadius.circular(14)), child: Icon(enabled ? Icons.notifications_active_rounded : Icons.notifications_off_rounded, color: enabled ? AppColors.blue : AppColors.muted)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(AppData.text(device['email'], 'Usuario'), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
            const SizedBox(height: 3),
            Text('${AppData.text(device['platform'], 'plataforma')} · ${AppData.text(device['app_version'], AppConfig.appVersion)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 12)),
            const SizedBox(height: 7),
            Wrap(spacing: 7, runSpacing: 7, children: [
              _MiniChip(text: enabled ? 'activo' : 'apagado', color: enabled ? AppColors.green : AppColors.muted),
              _MiniChip(text: AppData.text(device['last_seen_at']).isEmpty ? 'sin last seen' : 'last seen', color: AppColors.blue),
            ]),
          ])),
        ]),
      ),
    );
  }
}

IconData ticketTypeIcon(String type) {
  switch (type) {
    case 'cuenta': return Icons.person_outline_rounded;
    case 'grupo': return Icons.groups_rounded;
    case 'evento': return Icons.event_rounded;
    case 'finanzas': return Icons.account_balance_wallet_rounded;
    case 'torneo': return Icons.emoji_events_rounded;
    case 'sugerencia': return Icons.lightbulb_outline_rounded;
    default: return Icons.bug_report_rounded;
  }
}

String ticketTypeLabel(String type) {
  switch (type) {
    case 'cuenta': return 'Cuenta';
    case 'grupo': return 'Grupo';
    case 'evento': return 'Evento';
    case 'finanzas': return 'Finanzas';
    case 'torneo': return 'Torneo';
    case 'sugerencia': return 'Sugerencia';
    case 'otro': return 'Otro';
    default: return 'Bug';
  }
}

String ticketStatusLabel(String status) {
  switch (status) {
    case 'reviewing': return 'En revisión';
    case 'resolved': return 'Resuelto';
    case 'closed': return 'Cerrado';
    default: return 'Abierto';
  }
}

Color ticketStatusColor(String status) {
  switch (status) {
    case 'reviewing': return AppColors.blue;
    case 'resolved': return AppColors.green;
    case 'closed': return AppColors.muted;
    default: return AppColors.orange;
  }
}

String ticketPriorityLabel(String priority) {
  switch (priority) {
    case 'critical': return 'Crítica';
    case 'high': return 'Alta';
    case 'low': return 'Baja';
    default: return 'Normal';
  }
}

Color ticketPriorityColor(String priority) {
  switch (priority) {
    case 'critical': return AppColors.red;
    case 'high': return AppColors.orange;
    case 'low': return AppColors.muted;
    default: return AppColors.teal;
  }
}


class ProfileScreen extends StatefulWidget {
  final VoidCallback onChanged;
  final ValueChanged<int>? onNavigateRoot;
  const ProfileScreen({super.key, required this.onChanged, this.onNavigateRoot});

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
      if (mounted) await showToast(context, humanError(e), danger: true);
    }
  }

  Future<void> changePhoto() async {
    if (photoLoading) return;
    setState(() => photoLoading = true);
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 88,
      );
      if (picked == null) return;
      final raw = await picked.readAsBytes();
      if (!mounted) return;
      final framed = await Navigator.of(context).push<Uint8List>(MaterialPageRoute(
        builder: (_) => ImageFrameEditorScreen(
          bytes: raw,
          title: 'Ajustar foto',
          helper: 'Arrastra y pellizca para centrar tu foto dentro del círculo.',
          aspectRatio: 1,
          outputWidth: 900,
          circularPreview: true,
        ),
      ));
      if (framed == null) return;
      await AppData.uploadAvatarBytes(framed, 'avatar.png');
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
    final ok = await confirmAction(
      context,
      title: '¿Quitar foto?',
      body: 'Volverás al avatar con iniciales. Puedes subir otra foto cuando quieras.',
      danger: true,
    );
    if (ok != true) return;
    try {
      await AppData.removeAvatar();
      reload();
      if (mounted) await showToast(context, 'Foto eliminada.');
    } catch (e) {
      if (mounted) await showToast(context, humanError(e), danger: true);
    }
  }

  Future<void> confirmSignOut() async {
    final ok = await confirmAction(
      context,
      title: '¿Cerrar sesión?',
      body: 'Podrás volver a entrar con tu correo cuando quieras.',
      danger: true,
      confirmLabel: 'Cerrar sesión',
    );
    if (ok != true) return;
    await AppData.sb.auth.signOut();
  }

  Future<void> deleteAccountFlow() async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar cuenta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Esta acción elimina tu cuenta de Grupli, tu perfil, tu foto, tus dispositivos, tus avisos y tu acceso a los grupos.'),
            const SizedBox(height: 10),
            const Text('Si eres owner de algún grupo, esos grupos también se eliminarán con sus eventos, gastos y torneos.'),
            const SizedBox(height: 14),
            const Text('Escribe ELIMINAR para confirmar.', style: TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(hintText: 'ELIMINAR'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () => Navigator.pop(context, controller.text.trim().toUpperCase() == 'ELIMINAR'),
            child: const Text('Eliminar cuenta'),
          ),
        ],
      ),
    );
    final typed = controller.text;
    controller.dispose();
    if (confirmed != true) {
      if (typed.trim().isNotEmpty && mounted) {
        await showToast(context, 'Para eliminar la cuenta debes escribir ELIMINAR exactamente.', danger: true);
      }
      return;
    }

    try {
      await AppData.deleteMyAccount('ELIMINAR');
      if (mounted) await showToast(context, 'Cuenta eliminada.');
    } catch (e) {
      if (mounted) await showToast(context, humanError(e), danger: true);
    }
  }

  void showNotificationsSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(22, 10, 22, 30),
            child: FutureBuilder<Map<String, dynamic>>(
              future: AppData.notificationSettings(),
              builder: (context, snapshot) {
                final settings = snapshot.data ?? {};
                bool enabled(String key) => settings[key] != false;
                Future<void> toggle(String key, bool value) async {
                  await AppData.updateNotificationSettings({key: value});
                  setSheetState(() {});
                }
                return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  const SheetTitle(icon: Icons.notifications_active_outlined, title: 'Notificaciones', body: 'Elige qué avisos quieres recibir por grupo. Las notificaciones internas funcionan con Supabase; el push móvil se activa con Firebase.'),
                  const SizedBox(height: 12),
                  NotificationPreferenceSwitch(icon: Icons.event_available_rounded, title: 'Eventos', body: 'Nuevas quedadas, cambios y cancelaciones', value: enabled('notify_events'), onChanged: (v) => toggle('notify_events', v)),
                  NotificationPreferenceSwitch(icon: Icons.account_balance_wallet_rounded, title: 'Finanzas', body: 'Gastos nuevos y pagos importantes', value: enabled('notify_expenses'), onChanged: (v) => toggle('notify_expenses', v)),
                  NotificationPreferenceSwitch(icon: Icons.emoji_events_rounded, title: 'Torneos', body: 'Torneos, partidos y resultados', value: enabled('notify_tournaments'), onChanged: (v) => toggle('notify_tournaments', v)),
                  NotificationPreferenceSwitch(icon: Icons.groups_rounded, title: 'Miembros', body: 'Entradas al grupo y cambios de rol', value: enabled('notify_members'), onChanged: (v) => toggle('notify_members', v)),
                  const SizedBox(height: 12),
                  PrimaryButton(label: 'Activar push en este dispositivo', icon: Icons.notifications_active_rounded, onTap: () async {
                    final token = await PushNotificationService.enableForCurrentDevice();
                    if (!mounted) return;
                    if (token == null) {
                      await showToast(context, 'Falta Firebase o el permiso de notificaciones está desactivado.', danger: true);
                    } else {
                      await showToast(context, 'Push activado en este dispositivo.');
                    }
                  }),
                  const SizedBox(height: 8),
                  SecondaryButton(label: 'Enviar aviso de prueba', icon: Icons.bolt_rounded, onTap: () async {
                    try {
                      await AppData.createTestNotification();
                      if (!mounted) return;
                      await showToast(context, 'Aviso de prueba creado. Si el webhook está activo, llegará push al móvil.');
                    } catch (e) {
                      if (!mounted) return;
                      await showToast(context, 'No se pudo crear la prueba. Ejecuta el SQL v15.22.', danger: true);
                    }
                  }),
                ]);
              },
            ),
          );
        },
      ),
    );
  }

  void showPrivacySheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 10, 22, 30),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: const [
          SheetTitle(icon: Icons.lock_outline_rounded, title: 'Privacidad y seguridad', body: 'Grupli está pensada para grupos cerrados. Nadie entra sin invitación o código.'),
          SizedBox(height: 12),
          PreferencePreviewRow(icon: Icons.verified_user_rounded, title: 'Cuenta protegida', body: 'Acceso mediante Supabase Auth y sesión privada'),
          PreferencePreviewRow(icon: Icons.groups_rounded, title: 'Grupos privados', body: 'El contenido del grupo queda limitado a sus miembros'),
          PreferencePreviewRow(icon: Icons.admin_panel_settings_rounded, title: 'Roles claros', body: 'Owner, admins y miembros tienen permisos separados'),
          PreferencePreviewRow(icon: Icons.delete_outline_rounded, title: 'Eliminación de cuenta', body: 'Puedes iniciar el borrado de cuenta desde Perfil con confirmación explícita'),
        ]),
      ),
    );
  }

  void showAboutSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 10, 22, 30),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: const [
          SheetTitle(icon: Icons.auto_awesome_rounded, title: 'Grupli', body: 'App para organizar grupos privados: quedadas, calendario, gastos, torneos, miembros y permisos.'),
          SizedBox(height: 12),
          PreferencePreviewRow(icon: Icons.phone_android_rounded, title: 'Versión', body: 'v15.22 · Push notifications reales'),
          PreferencePreviewRow(icon: Icons.web_rounded, title: 'Preparada para web/PWA/APK', body: 'Lista para pruebas reales y control interno'),
        ]),
      ),
    );
  }

  Future<void> openSupport() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SupportTicketScreen(screen: 'perfil')));
    reload();
  }

  Future<void> openAdminPanel() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminDashboardScreen()));
    reload();
  }

  Future<void> openProfileGroup(Map<String, dynamic> group) async {
    final groupId = group['id']?.toString() ?? '';
    if (groupId.isEmpty) return;
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => GroupShell(groupId: groupId)));
    reload();
  }

  Future<void> openAllGroups(List<Map<String, dynamic>> groups) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ProfileAllGroupsScreen(groups: groups, onOpenGroup: openProfileGroup),
    ));
    reload();
  }

  void goBackFromProfile() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    widget.onNavigateRoot?.call(0);
  }

  @override
  Widget build(BuildContext context) {
    return DirectPage(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
      child: FutureBuilder<_ProfileData>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CenterLoader(label: 'Cargando perfil...');
          }
          if (snapshot.hasError) {
            return ErrorBlock(message: humanError(snapshot.error), onRetry: reload);
          }

          final data = snapshot.data ?? _ProfileData.empty();
          final name = data.name;
          final email = data.email;
          final avatarUrl = data.avatarUrl;
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              RoundBackButton(onTap: goBackFromProfile),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Perfil', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 4),
                Text('Tu cuenta, foto, grupos y ajustes básicos.', style: Theme.of(context).textTheme.bodyMedium),
              ])),
              CircleIconButton(icon: Icons.refresh_rounded, onTap: reload),
            ]),
            const SizedBox(height: 16),
            AppCard(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
              child: Column(children: [
                Stack(alignment: Alignment.bottomRight, children: [
                  ProfileAvatar(name: name, avatarUrl: avatarUrl, radius: 54),
                  Material(
                    color: AppColors.teal,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: changePhoto,
                      child: SizedBox(
                        width: 36,
                        height: 36,
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
                const SizedBox(height: 8),
              ]),
            ),
            const SizedBox(height: 18),
            SectionHeader(title: 'Cuenta'),
            const SizedBox(height: 8),
            SettingsRow(icon: Icons.edit_rounded, title: 'Nombre visible', subtitle: name, onTap: () => editName(name)),
            SettingsRow(icon: Icons.photo_camera_rounded, title: 'Cambiar foto', subtitle: photoLoading ? 'Subiendo imagen...' : 'Elige una imagen de tu dispositivo', onTap: changePhoto),
            if (avatarUrl.isNotEmpty)
              SettingsRow(icon: Icons.delete_outline_rounded, title: 'Quitar foto', subtitle: 'Volver al avatar con iniciales', danger: true, onTap: removePhoto),
            const SizedBox(height: 8),
            SectionHeader(title: 'Tus grupos', action: 'Ver todos', onTap: () => openAllGroups(data.groups)),
            const SizedBox(height: 8),
            if (data.groups.isEmpty)
              EmptySlim(icon: Icons.groups_rounded, title: 'Aún no tienes grupos', body: 'Crea o únete a un grupo desde Inicio.')
            else
              ...data.groups.take(3).map((group) => ProfileGroupMiniCard(group: group, onTap: () => openProfileGroup(group))),
            if (data.groups.length > 3)
              SettingsRow(icon: Icons.more_horiz_rounded, title: 'Ver todos los grupos', subtitle: '${data.groups.length} grupos en total', onTap: () => openAllGroups(data.groups)),
            const SizedBox(height: 8),
            SectionHeader(title: 'Ajustes'),
            const SizedBox(height: 8),
            SettingsRow(icon: Icons.notifications_none_rounded, title: 'Notificaciones', subtitle: 'Eventos, gastos y torneos', onTap: showNotificationsSheet),
            SettingsRow(icon: Icons.language_rounded, title: 'Idioma', subtitle: 'Español ahora · inglés preparado para lanzamiento', onTap: () => showToast(context, 'La app se lanzará como mínimo en español e inglés.')),
            SettingsRow(icon: Icons.lock_outline_rounded, title: 'Privacidad y seguridad', subtitle: 'Grupos cerrados, roles y acceso privado', onTap: showPrivacySheet),
            SettingsRow(icon: Icons.help_outline_rounded, title: 'Ayuda y soporte', subtitle: 'Reportar bugs, dudas o sugerencias', onTap: openSupport),
            if (data.isAdmin)
              SettingsRow(icon: Icons.admin_panel_settings_rounded, title: 'Panel admin', subtitle: 'Roles, reportes, métricas y calidad de Grupli', onTap: openAdminPanel),
            SettingsRow(icon: Icons.info_outline_rounded, title: 'Acerca de Grupli', subtitle: 'Versión y estado del producto', onTap: showAboutSheet),
            SettingsRow(icon: Icons.delete_forever_rounded, title: 'Eliminar cuenta', subtitle: 'Borra tu cuenta y datos personales de Grupli', danger: true, onTap: deleteAccountFlow),
            const SizedBox(height: 10),
            DangerButton(label: 'Cerrar sesión', icon: Icons.logout_rounded, onTap: confirmSignOut),
          ]);
        },
      ),
    );
  }
}

class ProfileAllGroupsScreen extends StatelessWidget {
  final List<Map<String, dynamic>> groups;
  final Future<void> Function(Map<String, dynamic> group) onOpenGroup;
  const ProfileAllGroupsScreen({super.key, required this.groups, required this.onOpenGroup});

  @override
  Widget build(BuildContext context) {
    return DirectPage(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        PageHeader(title: 'Tus grupos', subtitle: '${groups.length} grupos en total. Toca uno para abrirlo.', leading: true),
        const SizedBox(height: 14),
        if (groups.isEmpty)
          EmptyBlock(icon: Icons.groups_rounded, title: 'Aún no tienes grupos', body: 'Crea o únete a un grupo desde Inicio.')
        else
          ...groups.map((group) => ProfileGroupMiniCard(group: group, onTap: () => onOpenGroup(group))),
      ]),
    );
  }
}

class _ProfileData {
  final Map<String, dynamic> profile;
  final List<Map<String, dynamic>> groups;
  final bool isAdmin;

  const _ProfileData({required this.profile, required this.groups, this.isAdmin = false});

  static _ProfileData empty() => const _ProfileData(profile: {}, groups: [], isAdmin: false);

  static Future<_ProfileData> load() async {
    final results = await Future.wait([
      AppData.profile(),
      AppData.myGroups(),
      AppData.isSuperAdmin(),
    ]);
    return _ProfileData(
      profile: AppData.asMap(results[0]),
      groups: AppData.asList(results[1]),
      isAdmin: results[2] == true,
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

class AccountStatusPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const AccountStatusPill({super.key, required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(color: color.withOpacity(.10), borderRadius: BorderRadius.circular(99), border: Border.all(color: color.withOpacity(.18))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 15, color: color),
      const SizedBox(width: 6),
      Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12)),
    ]),
  );
}

class ProfileGroupMiniCard extends StatelessWidget {
  final Map<String, dynamic> group;
  final VoidCallback onTap;
  const ProfileGroupMiniCard({super.key, required this.group, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = AppData.text(group['name'], 'Grupo');
    final role = AppData.text(group['role'], 'member');
    final members = AppData.intValue(group['members_count'], 1);
    final events = AppData.intValue(group['events_count'], 0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        child: Row(children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: AppColors.tealSoft, borderRadius: BorderRadius.circular(15)),
            child: const Icon(Icons.groups_rounded, color: AppColors.teal),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink))),
              RoleBadge(role: role),
            ]),
            const SizedBox(height: 4),
            Text('$members miembros · $events eventos', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 12)),
          ])),
        ]),
      ),
    );
  }
}

class SheetTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const SheetTitle({super.key, required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(color: AppColors.tealSoft, borderRadius: BorderRadius.circular(16)),
      child: Icon(icon, color: AppColors.teal),
    ),
    const SizedBox(height: 12),
    Text(title, style: Theme.of(context).textTheme.titleLarge),
    const SizedBox(height: 6),
    Text(body, style: Theme.of(context).textTheme.bodyMedium),
  ]);
}

class PreferencePreviewRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const PreferencePreviewRow({super.key, required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      child: Row(children: [
        Icon(icon, color: AppColors.teal),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink)),
          const SizedBox(height: 2),
          Text(body, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
        ])),
      ]),
    ),
  );
}



class NotificationPreferenceSwitch extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final bool value;
  final ValueChanged<bool> onChanged;
  const NotificationPreferenceSwitch({super.key, required this.icon, required this.title, required this.body, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(children: [
        Container(width: 38, height: 38, decoration: BoxDecoration(color: AppColors.tealSoft, borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: AppColors.teal, size: 20)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink)),
          const SizedBox(height: 2),
          Text(body, style: const TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w700)),
        ])),
        Switch(value: value, activeColor: AppColors.teal, onChanged: onChanged),
      ]),
    ),
  );
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
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withOpacity(.12),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(body, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 9),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(actionLabel, style: TextStyle(color: color, fontWeight: FontWeight.w900)),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward_rounded, size: 18, color: color),
              ]),
            ),
          ),
        ])),
      ]),
    );
  }
}

void showGroupQuickActionsSheet(
  BuildContext context, {
  required Map<String, dynamic> group,
  required VoidCallback onSettings,
  required VoidCallback onMembers,
  required VoidCallback onMore,
  required VoidCallback onReport,
}) {
  final name = AppData.text(group['name'], 'Grupo');
  final code = AppData.text(group['invite_code'], '------');
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(14),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(28), boxShadow: const [BoxShadow(color: Color(0x1C061A2A), blurRadius: 32, offset: Offset(0, 14))]),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 42, height: 42, decoration: BoxDecoration(color: AppColors.tealSoft, borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.tune_rounded, color: AppColors.teal)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium),
              const Text('Acciones rápidas del grupo', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800, fontSize: 12)),
            ])),
          ]),
          const SizedBox(height: 12),
          SettingsRow(icon: Icons.edit_rounded, title: 'Editar grupo', subtitle: 'Nombre, portada y ajustes', onTap: () { Navigator.pop(sheetContext); onSettings(); }),
          SettingsRow(icon: Icons.groups_rounded, title: 'Miembros', subtitle: 'Roles, admins y expulsiones', onTap: () { Navigator.pop(sheetContext); onMembers(); }),
          SettingsRow(icon: Icons.link_rounded, title: 'Copiar enlace', subtitle: InviteLinks.joinUrl(code), onTap: () { Navigator.pop(sheetContext); copyInviteLink(context, code); }),
          SettingsRow(icon: Icons.share_rounded, title: 'Compartir invitación', subtitle: 'Enviar por WhatsApp u otra app', onTap: () { Navigator.pop(sheetContext); Share.share(inviteText(name, code)); }),
          SettingsRow(icon: Icons.more_horiz_rounded, title: 'Ver todo', subtitle: 'Invitaciones, permisos y privacidad', onTap: () { Navigator.pop(sheetContext); onMore(); }),
          SettingsRow(icon: Icons.support_agent_rounded, title: 'Reportar problema', subtitle: 'Enviar incidencia sobre este grupo', onTap: () { Navigator.pop(sheetContext); onReport(); }),
        ]),
      ),
    ),
  );
}


class GroupHeroCard extends StatelessWidget {
  final String name;
  final String coverUrl;
  final VoidCallback? onEdit;
  final VoidCallback? onMore;
  const GroupHeroCard({super.key, required this.name, this.coverUrl = '', this.onEdit, this.onMore});

  @override
  Widget build(BuildContext context) {
    final hasCover = coverUrl.trim().isNotEmpty;
    return Container(
      height: 148,
      decoration: BoxDecoration(
        color: AppColors.navHome,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [BoxShadow(color: Color(0x2A053A59), blurRadius: 30, offset: Offset(0, 14))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(children: [
          Positioned.fill(
            child: hasCover
                ? Image.network(
                    coverUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: AppColors.navHome),
                  )
                : Container(color: AppColors.navHome),
          ),
          if (hasCover)
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x12000000), Color(0x55000000)],
                  ),
                ),
              ),
            ),
          Positioned(right: 16, top: 14, child: _HeroActionButton(icon: Icons.edit_rounded, tooltip: 'Editar grupo', onTap: onEdit)),
          Positioned(left: 18, right: 18, bottom: 20, child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 29,
                fontWeight: FontWeight.w900,
                height: 1.0,
                letterSpacing: -0.85,
                shadows: [Shadow(color: Color(0x88000000), blurRadius: 12, offset: Offset(0, 3))],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Planes, gastos y torneos del grupo',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                shadows: [Shadow(color: Color(0x88000000), blurRadius: 10, offset: Offset(0, 2))],
              ),
            ),
          ])),
        ]),
      ),
    );
  }
}

class _HeroActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  const _HeroActionButton({required this.icon, required this.tooltip, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(99),
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0x22FFFFFF),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0x33FFFFFF)),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
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
    return Padding(
      padding: const EdgeInsets.only(left: 2, right: 2),
      child: Row(children: [
        Container(width: 4, height: 20, decoration: BoxDecoration(color: AppColors.teal, borderRadius: BorderRadius.circular(99))),
        const SizedBox(width: 8),
        Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
        if (action != null)
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(99),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(color: AppColors.tealSoft, borderRadius: BorderRadius.circular(99), border: Border.all(color: const Color(0x19008F86))),
              child: Text(action!, style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.w900, fontSize: 12)),
            ),
          ),
      ]),
    );
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


class DashboardUpcomingEventsCard extends StatelessWidget {
  final List<Map<String, dynamic>> events;
  final Map<String, dynamic> group;
  final VoidCallback onChanged;
  const DashboardUpcomingEventsCard({super.key, required this.events, required this.group, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final ordered = [...events]..sort((a, b) {
      final da = DateTime.tryParse(AppData.text(a['starts_at'])) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final db = DateTime.tryParse(AppData.text(b['starts_at'])) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return da.compareTo(db);
    });
    final firstDate = DateTime.tryParse(AppData.text(ordered.first['starts_at']))?.toLocal() ?? DateTime.now();
    final hasTournament = ordered.any(eventIsTournamentEvent);
    final accent = hasTournament ? AppColors.teal : eventKindColor(ordered.first);

    Future<void> openEvent(Map<String, dynamic> event) async {
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => EventDetailScreen(event: event, group: group)));
      onChanged();
    }

    return AppCard(
      color: hasTournament ? const Color(0xFF2F260E) : AppColors.navy,
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 58,
            height: 62,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: accent.withOpacity(.28))),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(shortWeekday(firstDate).toUpperCase(), style: TextStyle(color: accent, fontSize: 10, fontWeight: FontWeight.w900)),
              Text(firstDate.day.toString(), style: const TextStyle(color: AppColors.ink, fontSize: 24, fontWeight: FontWeight.w900, height: 1)),
              Text(DateFormat('MMM', 'es_ES').format(firstDate).replaceAll('.', ''), style: const TextStyle(color: AppColors.muted, fontSize: 10, fontWeight: FontWeight.w800)),
            ]),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${ordered.length} planes el mismo día', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, height: 1.05)),
            const SizedBox(height: 5),
            Text(hasTournament ? 'Incluye partidos de liga/torneo' : 'Toca uno para abrir su tarjeta', style: TextStyle(color: hasTournament ? AppColors.amberSoft : const Color(0xDFFFFFFF), fontWeight: FontWeight.w800, fontSize: 12)),
          ])),
        ]),
        const SizedBox(height: 12),
        for (final event in ordered.take(4)) ...[
          DashboardUpcomingEventRow(event: event, onTap: () => openEvent(event)),
          if (event != ordered.take(4).last) const Divider(height: 1, color: Color(0x25FFFFFF)),
        ],
        if (ordered.length > 4) ...[
          const SizedBox(height: 8),
          Text('+ ${ordered.length - 4} más en Agenda', style: const TextStyle(color: Color(0xDFFFFFFF), fontWeight: FontWeight.w800)),
        ],
      ]),
    );
  }
}

class DashboardUpcomingEventRow extends StatelessWidget {
  final Map<String, dynamic> event;
  final VoidCallback onTap;
  const DashboardUpcomingEventRow({super.key, required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(AppData.text(event['starts_at']))?.toLocal() ?? DateTime.now();
    final color = eventKindColor(event);
    final isTournament = eventIsTournamentEvent(event);
    final yes = attendanceCount(event, 'yes');
    final minPeople = AppData.intValue(event['min_people'], 1);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: isTournament ? AppColors.amber.withOpacity(.16) : Colors.white.withOpacity(.10), borderRadius: BorderRadius.circular(14)),
            child: Icon(eventKindIcon(event), color: isTournament ? AppColors.amber : color, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(AppData.text(event['title'], 'Evento'), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13.5)),
            const SizedBox(height: 3),
            Text('${DateFormat('HH:mm', 'es_ES').format(date)} · $yes/$minPeople van', style: const TextStyle(color: Color(0xDFFFFFFF), fontWeight: FontWeight.w700, fontSize: 11.5)),
          ])),
          if (isTournament) const TournamentAgendaBadge(),
        ]),
      ),
    );
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
      await showToast(context, humanError(e), danger: true);
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
    final color = eventKindColor(event);
    final isTournament = eventIsTournamentEvent(event);
    final missing = max(0, minPeople - yes);
    final progress = minPeople <= 0 ? 0.0 : min(1.0, yes / minPeople);

    return AppCard(
      color: isTournament ? const Color(0xFF2F260E) : AppColors.navy,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      onTap: () async {
        await Navigator.of(context).push(MaterialPageRoute(builder: (_) => EventDetailScreen(event: event, group: widget.group)));
        widget.onChanged();
      },
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 58,
            height: 62,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white.withOpacity(.18))),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(shortWeekday(date).toUpperCase(), style: const TextStyle(color: AppColors.navAgenda, fontSize: 10, fontWeight: FontWeight.w900)),
              Text(date.day.toString(), style: const TextStyle(color: AppColors.ink, fontSize: 24, fontWeight: FontWeight.w900, height: 1)),
              Text(DateFormat('MMM', 'es_ES').format(date).replaceAll('.', ''), style: const TextStyle(color: AppColors.muted, fontSize: 10, fontWeight: FontWeight.w800)),
            ]),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(AppData.text(event['title'], 'Evento'), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900, height: 1.05, letterSpacing: -.25))),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(color: missing == 0 ? AppColors.greenSoft : AppColors.orangeSoft, borderRadius: BorderRadius.circular(99)),
                child: Text(missing == 0 ? 'Listo' : 'Faltan $missing', style: TextStyle(color: missing == 0 ? AppColors.green : AppColors.orange, fontSize: 11.5, fontWeight: FontWeight.w900)),
              ),
            ]),
            const SizedBox(height: 7),
            Wrap(spacing: 10, runSpacing: 6, children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.schedule_rounded, size: 15, color: color),
                const SizedBox(width: 4),
                Text(DateFormat('HH:mm', 'es_ES').format(date), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
              ]),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 210),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.place_outlined, size: 15, color: color),
                  const SizedBox(width: 4),
                  Flexible(child: Text(AppData.text(event['location'], 'Sin ubicación'), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xDFFFFFFF)))),
                ]),
              ),
            ]),
          ])),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: progress, minHeight: 6, backgroundColor: Color(0x30FFFFFF), color: AppColors.green))),
          const SizedBox(width: 10),
          Text('$yes/$minPeople', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: GlassAttendanceButton(label: 'Voy', count: yes, selected: mine == 'yes', color: AppColors.green, onTap: saving ? () {} : () => setStatus('yes'))),
          const SizedBox(width: 8),
          Expanded(child: GlassAttendanceButton(label: 'Duda', count: maybe, selected: mine == 'maybe', color: AppColors.amber, onTap: saving ? () {} : () => setStatus('maybe'))),
          const SizedBox(width: 8),
          Expanded(child: GlassAttendanceButton(label: 'No', count: no, selected: mine == 'no', color: AppColors.red, onTap: saving ? () {} : () => setStatus('no'))),
        ]),
      ]),
    );
  }
}

class DashboardMiniSummaryRow extends StatelessWidget {
  final int events;
  final int pending;
  final double balance;
  final int tournaments;
  final VoidCallback? onCalendar;
  final VoidCallback? onFinances;
  final VoidCallback? onTournaments;
  const DashboardMiniSummaryRow({super.key, required this.events, required this.pending, required this.balance, required this.tournaments, this.onCalendar, this.onFinances, this.onTournaments});

  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: MiniSummaryTile(icon: Icons.calendar_month_rounded, label: 'Agenda', value: events.toString(), color: AppColors.navAgenda, onTap: onCalendar)),
    const SizedBox(width: 8),
    Expanded(child: MiniSummaryTile(icon: Icons.account_balance_wallet_rounded, label: 'Balance', value: money(balance), color: balance < -0.01 ? AppColors.red : AppColors.navFinance, onTap: onFinances)),
    const SizedBox(width: 8),
    Expanded(child: MiniSummaryTile(icon: Icons.emoji_events_rounded, label: 'Torneos', value: tournaments.toString(), color: AppColors.navTournaments, onTap: onTournaments)),
  ]);
}

class MiniSummaryTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;
  const MiniSummaryTile({super.key, required this.icon, required this.label, required this.value, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) => AppCard(
    onTap: onTap,
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 10),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(height: 6),
      Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.ink, fontSize: 14.5, fontWeight: FontWeight.w900)),
      const SizedBox(height: 2),
      Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontSize: 11.5, fontWeight: FontWeight.w800)),
    ]),
  );
}

class GlassAttendanceButton extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const GlassAttendanceButton({super.key, required this.label, required this.count, required this.selected, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: 42,
      decoration: BoxDecoration(
        color: selected ? color : color.withOpacity(.12),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: selected ? color : color.withOpacity(.28), width: 1.2),
        boxShadow: selected ? [BoxShadow(color: color.withOpacity(.20), blurRadius: 14, offset: const Offset(0, 6))] : const [],
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(selected ? Icons.check_circle_rounded : Icons.circle_outlined, color: selected ? Colors.white : color, size: 15),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(color: selected ? Colors.white : color, fontSize: 12.5, fontWeight: FontWeight.w900)),
          const SizedBox(width: 4),
          Text(count.toString(), style: TextStyle(color: selected ? Colors.white : color, fontSize: 12.5, fontWeight: FontWeight.w900)),
        ]),
      ),
    ),
  );
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
    final routineGroups = <String, List<Map<String, dynamic>>>{};
    final singleEvents = <Map<String, dynamic>>[];

    for (final event in events) {
      if (eventIsRoutine(event)) {
        final key = AppData.text(event['title'], 'Rutina');
        routineGroups.putIfAbsent(key, () => <Map<String, dynamic>>[]).add(event);
      } else {
        singleEvents.add(event);
      }
    }

    routineGroups.forEach((title, groupEvents) {
      groupEvents.sort((a, b) {
        final da = DateTime.tryParse(a['starts_at']?.toString() ?? '') ?? DateTime.now();
        final db = DateTime.tryParse(b['starts_at']?.toString() ?? '') ?? DateTime.now();
        return da.compareTo(db);
      });
      final first = groupEvents.first;
      final date = DateTime.tryParse(first['starts_at']?.toString() ?? '')?.toLocal() ?? DateTime.now();
      items.add(_DashboardActivityItem(
        date: date,
        icon: Icons.repeat_rounded,
        color: eventKindColor(first),
        title: title,
        body: '${groupEvents.length} fechas programadas',
        onTapKind: 'calendar',
      ));
    });

    for (final event in singleEvents.take(4)) {
      final date = DateTime.tryParse(event['starts_at']?.toString() ?? '')?.toLocal();
      if (date == null) continue;
      final yes = attendanceCount(event, 'yes');
      final minPeople = AppData.intValue(event['min_people'], 1);
      items.add(_DashboardActivityItem(
        date: date,
        icon: Icons.event_available_rounded,
        color: eventKindColor(event),
        title: AppData.text(event['title'], 'Quedada'),
        body: '${shortWeekday(date)} ${date.day} · $yes/$minPeople',
        onTapKind: 'calendar',
      ));
    }

    for (final expense in expenses.take(2)) {
      final created = DateTime.tryParse(expense['created_at']?.toString() ?? '')?.toLocal() ?? DateTime.now();
      final status = AppData.text(expense['status'], 'pending') == 'paid' ? 'liquidado' : 'pendiente';
      items.add(_DashboardActivityItem(
        date: created,
        icon: Icons.account_balance_wallet_rounded,
        color: AppData.text(expense['status'], 'pending') == 'paid' ? AppColors.green : AppColors.amber,
        title: AppData.text(expense['concept'], 'Gasto'),
        body: '${money(AppData.doubleValue(expense['amount']))} · $status',
        onTapKind: 'finances',
      ));
    }

    for (final tournament in tournaments.take(2)) {
      final created = DateTime.tryParse(tournament['created_at']?.toString() ?? '')?.toLocal() ?? DateTime.now();
      final finished = AppData.text(tournament['status'], 'active') == 'finished';
      items.add(_DashboardActivityItem(
        date: created,
        icon: Icons.emoji_events_rounded,
        color: finished ? AppColors.violet : AppColors.orange,
        title: AppData.text(tournament['name'], 'Competición'),
        body: finished ? 'Finalizado' : 'En curso',
        onTapKind: 'tournaments',
      ));
    }

    items.sort((a, b) => b.date.compareTo(a.date));
    return items.take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = _items();

    if (items.isEmpty) {
      return EmptySlim(
        icon: Icons.bolt_rounded,
        title: 'Sin actividad todavía',
        body: 'Los próximos planes aparecerán aquí.',
      );
    }

    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
              const Divider(height: 1, indent: 56, color: AppColors.line),
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





class CalendarCompactHeader extends StatelessWidget {
  final int todayEvents;
  final int weekEvents;
  final int pendingResponses;
  final VoidCallback onToday;
  const CalendarCompactHeader({super.key, required this.todayEvents, required this.weekEvents, required this.pendingResponses, required this.onToday});

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
    child: Row(children: [
      Expanded(child: _CalendarMiniStat(label: 'Hoy', value: todayEvents.toString(), color: AppColors.teal)),
      Container(width: 1, height: 28, color: AppColors.line),
      Expanded(child: _CalendarMiniStat(label: '7 días', value: weekEvents.toString(), color: AppColors.blue)),
      Container(width: 1, height: 28, color: AppColors.line),
      Expanded(child: _CalendarMiniStat(label: 'Pendientes', value: pendingResponses.toString(), color: AppColors.amber)),
      const SizedBox(width: 6),
      TextButton(onPressed: onToday, child: const Text('Hoy')),
    ]),
  );
}

class _CalendarMiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _CalendarMiniStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 11, fontWeight: FontWeight.w800)),
    const SizedBox(height: 3),
    Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900)),
  ]);
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


class WeekStrip extends StatelessWidget {
  final List<DateTime> days;
  final DateTime selected;
  final Map<String, List<Map<String, dynamic>>> eventsByDay;
  final ValueChanged<DateTime> onSelect;

  const WeekStrip({
    super.key,
    required this.days,
    required this.selected,
    required this.eventsByDay,
    required this.onSelect,
  });

  List<Map<String, dynamic>> eventsFor(DateTime day) {
    return eventsByDay[calendarDayKey(day)] ?? const <Map<String, dynamic>>[];
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 68,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        clipBehavior: Clip.none,
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 7),
        itemBuilder: (context, index) {
          final day = days[index];
          final active = sameDay(day, selected);
          final dayEvents = eventsFor(day);
          final hasEvents = dayEvents.isNotEmpty;
          final mainColor = hasEvents ? eventKindColor(dayEvents.first) : AppColors.line;
          final today = sameDay(day, DateTime.now());
          return InkWell(
            onTap: () => onSelect(day),
            borderRadius: BorderRadius.circular(17),
            child: Container(
              width: 52,
              padding: const EdgeInsets.fromLTRB(5, 7, 5, 7),
              decoration: BoxDecoration(
                color: active ? AppColors.teal : hasEvents ? eventKindSoftColor(dayEvents.first) : AppColors.surface,
                borderRadius: BorderRadius.circular(17),
                border: Border.all(
                  color: active ? AppColors.teal : today ? AppColors.teal.withOpacity(.45) : hasEvents ? mainColor.withOpacity(.38) : AppColors.line,
                  width: active || today || hasEvents ? 1.3 : 1,
                ),
                boxShadow: active ? const [BoxShadow(color: Color(0x15008F86), blurRadius: 12, offset: Offset(0, 6))] : null,
              ),
              child: Column(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(shortWeekday(day).toUpperCase(), maxLines: 1, style: TextStyle(color: active ? Colors.white : AppColors.muted, fontWeight: FontWeight.w900, fontSize: 10.5)),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(day.day.toString(), maxLines: 1, style: TextStyle(color: active ? Colors.white : AppColors.ink, fontWeight: FontWeight.w900, fontSize: 19)),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 8,
                  child: Center(
                    child: hasEvents
                        ? Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 2,
                            runSpacing: 0,
                            children: [
                              for (final event in dayEvents.take(3))
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: active ? Colors.white : eventKindColor(event),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              if (dayEvents.length > 3)
                                Text('+', style: TextStyle(color: active ? Colors.white : AppColors.ink, fontWeight: FontWeight.w900, fontSize: 9, height: .8)),
                            ],
                          )
                        : Container(width: today ? 16 : 6, height: 4, decoration: BoxDecoration(color: active ? Colors.white : AppColors.line, borderRadius: BorderRadius.circular(99))),
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


class EventTypeLegend extends StatelessWidget {
  final List<Map<String, dynamic>> events;
  const EventTypeLegend({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    final kinds = <String, Map<String, dynamic>>{};
    for (final event in events) {
      kinds.putIfAbsent(eventKind(event), () => event);
    }
    final ordered = <String>['quedada', 'partido', 'entrenamiento', 'torneo', 'cena', 'reunion']
        .where((kind) => kinds.containsKey(kind))
        .toList();
    if (ordered.isEmpty) return const SizedBox.shrink();

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      color: AppColors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(children: [
          for (int i = 0; i < ordered.length; i++) ...[
            EventLegendMiniChip(event: kinds[ordered[i]] ?? {'title': ordered[i]}),
            if (i != ordered.length - 1) const SizedBox(width: 7),
          ],
        ]),
      ),
    );
  }
}

class EventLegendMiniChip extends StatelessWidget {
  final Map<String, dynamic> event;
  const EventLegendMiniChip({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final color = eventKindColor(event);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(.09),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(.22)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(eventKindIcon(event), color: color, size: 13),
        const SizedBox(width: 5),
        Text(eventKindLabel(event), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 11)),
      ]),
    );
  }
}


class RoutineBadge extends StatelessWidget {
  final String label;
  final bool compact;
  const RoutineBadge({super.key, required this.label, this.compact = true});

  @override
  Widget build(BuildContext context) {
    final horizontal = compact ? 8.0 : 10.0;
    final vertical = compact ? 5.0 : 6.0;
    final iconSize = compact ? 14.0 : 16.0;
    final fontSize = compact ? 11.5 : 12.5;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical),
      decoration: BoxDecoration(
        color: AppColors.violet.withOpacity(.10),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppColors.violet.withOpacity(.22)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.repeat_rounded, color: AppColors.violet, size: iconSize),
        const SizedBox(width: 5),
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.violet, fontSize: fontSize, fontWeight: FontWeight.w900)),
      ]),
    );
  }
}


class TournamentAgendaBadge extends StatelessWidget {
  const TournamentAgendaBadge({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: AppColors.amber.withOpacity(.42)),
    ),
    child: const Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.emoji_events_rounded, color: AppColors.amber, size: 13),
      SizedBox(width: 4),
      Text('Torneo', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 10.5)),
    ]),
  );
}

class EventKindPill extends StatelessWidget {
  final Map<String, dynamic> event;
  final bool compact;
  const EventKindPill({super.key, required this.event, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final color = eventKindColor(event);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: compact ? 5 : 6),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withOpacity(.24)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(eventKindIcon(event), color: color, size: compact ? 14 : 16),
        const SizedBox(width: 5),
        Text(eventKindLabel(event), style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: compact ? 11 : 12)),
      ]),
    );
  }
}


class EventScopeCard extends StatelessWidget {
  final String title;
  final String value;
  final ValueChanged<String> onChanged;
  const EventScopeCard({super.key, required this.title, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => AppCard(
    color: AppColors.violetSoft,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 42, height: 42, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.repeat_rounded, color: AppColors.violet)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 3),
          const Text('Elige qué fechas quieres modificar.', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700)),
        ])),
      ]),
      const SizedBox(height: 12),
      Wrap(spacing: 8, runSpacing: 8, children: [
        RoutineChoice(label: 'Solo esta fecha', selected: value == 'single', onTap: () => onChanged('single')),
        RoutineChoice(label: 'Esta y futuras', selected: value == 'future', onTap: () => onChanged('future')),
        RoutineChoice(label: 'Toda la rutina', selected: value == 'all', onTap: () => onChanged('all')),
      ]),
    ]),
  );
}

Future<String?> showRoutineScopeDialog(BuildContext context, {required String title, required String actionLabel}) {
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(
          leading: const Icon(Icons.event_rounded),
          title: const Text('Solo esta fecha'),
          subtitle: const Text('No cambia el resto de la rutina.'),
          onTap: () => Navigator.pop(context, 'single'),
        ),
        ListTile(
          leading: const Icon(Icons.update_rounded),
          title: const Text('Esta y futuras'),
          subtitle: const Text('Mantiene las fechas pasadas intactas.'),
          onTap: () => Navigator.pop(context, 'future'),
        ),
        ListTile(
          leading: const Icon(Icons.repeat_rounded),
          title: const Text('Toda la rutina'),
          subtitle: const Text('Aplica a todas las fechas conectadas.'),
          onTap: () => Navigator.pop(context, 'all'),
        ),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar'))],
    ),
  );
}

class RoutineChoice extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const RoutineChoice({super.key, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(15),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: selected ? AppColors.teal : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: selected ? AppColors.teal : AppColors.line),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.repeat_rounded, color: selected ? Colors.white : AppColors.teal, size: 17),
        const SizedBox(width: 7),
        Text(label, style: TextStyle(color: selected ? Colors.white : AppColors.ink, fontWeight: FontWeight.w900)),
      ]),
    ),
  );
}

class RoutineInfoBox extends StatelessWidget {
  final String text;
  const RoutineInfoBox({super.key, required this.text});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(.72),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.line),
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Icon(Icons.info_outline_rounded, color: AppColors.teal, size: 20),
      const SizedBox(width: 9),
      Expanded(child: Text(text, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, height: 1.35))),
    ]),
  );
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
  final String? repeatLabel;

  const EventFormPreviewCard({
    super.key,
    required this.title,
    required this.date,
    required this.location,
    required this.minPeople,
    required this.template,
    this.repeatLabel,
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
    final isRoutine = repeatLabel != null && repeatLabel!.trim().isNotEmpty;
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
            child: Icon(isRoutine ? Icons.repeat_rounded : icon, color: Colors.white, size: 27),
          ),
          const SizedBox(width: 13),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900, height: 1.05)),
            const SizedBox(height: 8),
            Text(longDateTime(date), style: const TextStyle(color: Color(0xEFFFFFFF), fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(location.trim().isEmpty ? 'Lugar por definir' : location.trim(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xDFFFFFFF), fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withOpacity(.16), borderRadius: BorderRadius.circular(99)),
                child: Text('Mínimo $minPeople asistentes', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
              ),
              if (isRoutine)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(.22), borderRadius: BorderRadius.circular(99)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.repeat_rounded, color: Colors.white, size: 14),
                    const SizedBox(width: 5),
                    Text(repeatLabel!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
                  ]),
                ),
            ]),
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
              Text(AppData.text(event['title'], 'Evento'), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, height: 1.05, letterSpacing: -0.4)),
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



class EventMetaChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const EventMetaChip({super.key, required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 190),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(color: Colors.white.withOpacity(.72), borderRadius: BorderRadius.circular(99), border: Border.all(color: color.withOpacity(.14))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 5),
        Flexible(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.ink, fontSize: 12, fontWeight: FontWeight.w800))),
      ]),
    );
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

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 54,
    child: DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(colors: [AppColors.tealDark, AppColors.teal], begin: Alignment.topLeft, end: Alignment.bottomRight),
        boxShadow: const [BoxShadow(color: Color(0x22008F86), blurRadius: 18, offset: Offset(0, 8))],
      ),
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        onPressed: loading ? null : onTap,
        icon: loading
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Icon(icon ?? Icons.check_rounded, size: 20),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: -.1)),
      ),
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
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.teal,
        side: const BorderSide(color: Color(0x33008F86)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
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
    this.padding = const EdgeInsets.all(13),
    this.onTap,
    this.color = AppColors.white,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(24);
    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: radius,
        border: Border.all(color: AppColors.lineSoft),
        boxShadow: const [
          BoxShadow(color: Color(0x0B0B1B2E), blurRadius: 24, offset: Offset(0, 10)),
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
    decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line), boxShadow: const [BoxShadow(color: Color(0x08111B34), blurRadius: 12, offset: Offset(0, 4))]),
    child: IconButton(icon: const Icon(Icons.arrow_back_rounded, size: 20), onPressed: onTap ?? () => Navigator.of(context).maybePop()),
  );
}


class OwnProfileButton extends StatelessWidget {
  final VoidCallback onTap;
  const OwnProfileButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: AppData.profile(),
      builder: (context, snapshot) {
        final profile = snapshot.data ?? const <String, dynamic>{};
        final name = AppData.text(profile['full_name'], AppData.user?.email?.split('@').first ?? 'Perfil');
        final avatar = AppData.text(profile['avatar_url']);
        return InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Container(
            width: 42,
            height: 42,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.line),
              boxShadow: const [BoxShadow(color: Color(0x07111B34), blurRadius: 12, offset: Offset(0, 4))],
            ),
            child: ProfileAvatar(name: name, avatarUrl: avatar, radius: 18),
          ),
        );
      },
    );
  }
}

class CircleIconButton extends StatelessWidget {
  final IconData icon; final VoidCallback onTap; final bool filled;
  const CircleIconButton({super.key, required this.icon, required this.onTap, this.filled = false});
  @override Widget build(BuildContext context) => Container(
    width: 42,
    height: 42,
    decoration: BoxDecoration(
      color: filled ? AppColors.navHome : AppColors.white,
      shape: BoxShape.circle,
      border: filled ? null : Border.all(color: AppColors.line),
      boxShadow: filled ? const [BoxShadow(color: Color(0x33053A59), blurRadius: 18, offset: Offset(0, 8))] : const [BoxShadow(color: Color(0x07111B34), blurRadius: 12, offset: Offset(0, 4))],
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
  final Map<String, dynamic> group;
  final VoidCallback onTap;
  const GroupHomeCard({super.key, required this.group, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = AppData.text(group['name'], 'Grupo');
    final members = AppData.intValue(group['members_count'], 1);
    final events = AppData.intValue(group['events_count'], 0);
    final cover = AppData.text(group['cover_url']);
    final hasCover = cover.trim().isNotEmpty;
    final memberLabel = members == 1 ? 'miembro' : 'miembros';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        button: true,
        label: 'Abrir grupo $name',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            height: 122,
            decoration: BoxDecoration(
              color: AppColors.navHome,
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [BoxShadow(color: Color(0x26053A59), blurRadius: 28, offset: Offset(0, 14))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Stack(children: [
                Positioned.fill(
                  child: hasCover
                      ? Image.network(
                          cover,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(color: AppColors.navHome),
                        )
                      : Container(color: AppColors.navHome),
                ),
                if (hasCover)
                  const Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [Color(0x99000000), Color(0x44000000), Color(0x22000000)],
                        ),
                      ),
                    ),
                  ),
                if (!hasCover)
                  Positioned(
                    left: 18,
                    top: 24,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(color: const Color(0x22000000), borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0x33FFFFFF))),
                      child: Icon(groupTypeIcon(AppData.text(group['type'], 'otro')), color: Colors.white, size: 34),
                    ),
                  ),
                Positioned(
                  left: hasCover ? 24 : 108,
                  right: 58,
                  top: 21,
                  bottom: 18,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -.35,
                            shadows: [Shadow(color: Color(0x88000000), blurRadius: 12, offset: Offset(0, 3))],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle)),
                    ]),
                    const SizedBox(height: 6),
                    Row(children: [
                      const Icon(Icons.lock_rounded, size: 13, color: Color(0xF2FFFFFF)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Privado · $members $memberLabel',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w900, shadows: [Shadow(color: Color(0x88000000), blurRadius: 8, offset: Offset(0, 2))]),
                        ),
                      ),
                    ]),
                    const Spacer(),
                    Wrap(spacing: 6, runSpacing: 6, children: [
                      _MiniChip(text: events == 0 ? 'Sin eventos' : '$events ${events == 1 ? 'evento' : 'eventos'}', color: AppColors.teal),
                      const _MiniChip(text: 'Invitación', color: AppColors.violet),
                    ]),
                  ]),
                ),
                Positioned(
                  right: 14,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(color: Color(0x30FFFFFF), shape: BoxShape.circle),
                      child: const Icon(Icons.chevron_right_rounded, color: Colors.white),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),
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
          NavSpec(Icons.calendar_month_rounded, 'Agenda'),
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

Color navColorFor(int index, int count) {
  if (count <= 3) {
    switch (index) {
      case 0: return AppColors.navHome;
      case 1: return AppColors.amber;
      default: return AppColors.violet;
    }
  }
  switch (index) {
    case 0: return AppColors.navHome;
    case 1: return AppColors.navAgenda;
    case 2: return AppColors.navFinance;
    case 3: return AppColors.navTournaments;
    default: return AppColors.navMore;
  }
}

class BottomBar extends StatelessWidget {
  final List<NavSpec> items;
  final int index;
  final ValueChanged<int> onTap;
  const BottomBar({super.key, required this.items, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
    padding: const EdgeInsets.all(7),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: AppColors.lineSoft),
      boxShadow: const [BoxShadow(color: Color(0x14111B34), blurRadius: 28, offset: Offset(0, -4))],
    ),
    child: Row(children: List.generate(items.length, (i) {
      final active = i == index;
      final spec = items[i];
      final color = navColorFor(i, items.length);
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => onTap(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            height: 58,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
            decoration: BoxDecoration(
              color: active ? color : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              boxShadow: active ? [BoxShadow(color: color.withOpacity(.24), blurRadius: 16, offset: const Offset(0, 7))] : null,
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(spec.icon, size: 22, color: active ? Colors.white : color),
              const SizedBox(height: 3),
              Text(
                spec.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: items.length >= 5 ? 9.4 : 10.2, fontWeight: FontWeight.w900, color: active ? Colors.white : AppColors.muted),
              ),
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
  @override Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
    if (leading) ...[RoundBackButton(onTap: () => Navigator.of(context).maybePop()), const SizedBox(width: 12)],
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.headlineMedium),
      if (subtitle.trim().isNotEmpty) ...[
        const SizedBox(height: 5),
        Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, height: 1.25)),
      ],
    ]))
  ]);
}

class CenterLoader extends StatelessWidget { final String label; const CenterLoader({super.key, required this.label}); @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 40), child: Column(children: [const CircularProgressIndicator(color: AppColors.teal), const SizedBox(height: 12), Text(label, style: Theme.of(context).textTheme.bodyMedium)])); }

class ErrorBlock extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const ErrorBlock({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final sessionProblem = looksLikeSessionProblem(message);
    return AppCard(child: Column(children: [
      Container(width: 58, height: 58, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.redSoft), child: const Icon(Icons.error_outline_rounded, color: AppColors.red, size: 30)),
      const SizedBox(height: 12),
      Text(sessionProblem ? 'Sesión caducada' : 'Algo no ha cargado bien', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
      const SizedBox(height: 7),
      Text(humanizeError(message), textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
      const SizedBox(height: 14),
      if (sessionProblem) ...[
        PrimaryButton(
          label: 'Salir y volver a entrar',
          icon: Icons.logout_rounded,
          onTap: () async {
            await AppData.clearLocalSession();
            onRetry();
          },
        ),
        const SizedBox(height: 10),
      ],
      SecondaryButton(label: 'Reintentar', icon: Icons.refresh_rounded, onTap: onRetry),
    ]));
  }
}

class EmptyBlock extends StatelessWidget {
  final IconData icon; final String title; final String body;
  const EmptyBlock({super.key, required this.icon, required this.title, required this.body});
  @override Widget build(BuildContext context) => AppCard(
    color: AppColors.surface,
    padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
    child: Column(children: [
      Container(width: 68, height: 68, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.tealSoft, border: Border.all(color: const Color(0x220B6B8F))), child: Icon(icon, color: AppColors.teal, size: 32)),
      const SizedBox(height: 14),
      Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 7),
      Text(body, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, height: 1.35)),
    ]),
  );
}

class EmptySlim extends StatelessWidget {
  final IconData icon; final String title; final String body;
  const EmptySlim({super.key, required this.icon, required this.title, this.body = ''});
  @override Widget build(BuildContext context) => AppCard(
    color: AppColors.surface,
    padding: const EdgeInsets.all(14),
    child: Row(children: [
      Container(width: 40, height: 40, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.tealSoft, border: Border.all(color: const Color(0x1A0B6B8F))), child: Icon(icon, color: AppColors.teal, size: 20)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink)),
        if (body.trim().isNotEmpty) ...[const SizedBox(height: 4), Text(body, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, height: 1.25))],
      ])),
    ]),
  );
}

bool looksLikeNetworkError(String raw) {
  final text = raw.toLowerCase();
  return text.contains('network') ||
      text.contains('socket') ||
      text.contains('connection') ||
      text.contains('failed host lookup') ||
      text.contains('xmlhttprequest') ||
      text.contains('internet');
}

bool looksLikeSessionProblem(String raw) {
  final text = raw.toLowerCase();
  if (text.contains('invalid login credentials') || text.contains('email not confirmed') || text.contains('invalid email')) return false;
  return text.contains('not_authenticated') ||
      text.contains('usuario no autenticado') ||
      text.contains('jwt') ||
      text.contains('refresh token') ||
      text.contains('invalid refresh') ||
      text.contains('invalid_grant') ||
      text.contains('session_id') ||
      text.contains('session not found') ||
      text.contains('session from') ||
      text.contains('auth session missing') ||
      text.contains('no current user') ||
      text.contains('session expired') ||
      text.contains('expired token');
}

String humanizeError(String raw) {
  final original = raw.replaceAll('Exception: ', '').trim();
  final text = original.toLowerCase();
  if (text.isEmpty) return 'No se pudo completar la acción. Inténtalo de nuevo.';
  if (text.contains('invalid login credentials')) return 'Email o contraseña incorrectos.';
  if (text.contains('email not confirmed')) return 'Confirma tu email antes de iniciar sesión.';
  if (text.contains('invalid email')) return 'El email no tiene un formato válido.';
  if (text.contains('weak password')) return 'La contraseña es demasiado débil.';
  if (text.contains('user already registered') || text.contains('already registered')) return 'Esta cuenta ya existe. Inicia sesión en lugar de registrarte.';
  if (text.contains('confirmation_required')) return 'Para eliminar la cuenta debes escribir ELIMINAR exactamente.';
  if (looksLikeSessionProblem(original)) return 'La sesión guardada en este móvil estaba caducada. Pulsa “Salir y volver a entrar” o “Limpiar sesión de este móvil” e inicia sesión otra vez.';
  if (text.contains('owner_protected') || text.contains('owner') || text.contains('creador del grupo')) return 'El creador del grupo está protegido. Transfiere o elimina el grupo antes de hacer esa acción.';
  if (text.contains('member_not_found') || text.contains('not_member')) return 'Ese miembro ya no está disponible en el grupo.';
  if (text.contains('invalid_role')) return 'Ese rol no es válido.';
  if (text.contains('settlement_payments') || text.contains('create_settlement_payment_atomic')) return 'Falta actualizar la base de datos de finanzas. Ejecuta el último parche SQL de finanzas/realtime y vuelve a probar.';
  if (text.contains('permission') || text.contains('policy') || text.contains('rls') || text.contains('not allowed') || text.contains('denied') || text.contains('violates row-level')) return 'No tienes permiso para hacer esa acción.';
  if (looksLikeNetworkError(original)) return 'No se pudo conectar. Revisa tu conexión e inténtalo de nuevo.';
  if (text.contains('duplicate') || text.contains('already') || text.contains('unique constraint')) return 'Parece que esto ya existe o ya se había guardado.';
  if (text.contains('foreign key') || text.contains('violates') || text.contains('constraint')) return 'No se pudo guardar porque hay datos relacionados. Revisa la acción e inténtalo de nuevo.';
  if (text.contains('postgrestexception') || text.contains('pgrst') || text.contains('supabase') || text.contains('postgres')) return 'No se pudo completar la acción en la base de datos. Inténtalo otra vez.';
  if (original.length > 120) return 'No se pudo completar la acción. Inténtalo de nuevo.';
  return original;
}

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





class AgendaPremiumHero extends StatelessWidget {
  final List<Map<String, dynamic>> events;
  final List<Map<String, dynamic>> upcomingEvents;
  final Map<String, dynamic> group;
  final VoidCallback onCreate;
  final VoidCallback onChanged;

  const AgendaPremiumHero({
    super.key,
    required this.events,
    required this.upcomingEvents,
    required this.group,
    required this.onCreate,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final next = upcomingEvents.isNotEmpty ? upcomingEvents.first : null;
    final nextDayEvents = eventsOnSameDay(upcomingEvents, next);
    final totalYes = upcomingEvents.fold<int>(0, (sum, e) => sum + attendanceCount(e, 'yes'));
    final totalMaybe = upcomingEvents.fold<int>(0, (sum, e) => sum + attendanceCount(e, 'maybe'));

    if (next != null) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (nextDayEvents.length > 1)
          AgendaSameDayCompactCard(events: nextDayEvents, group: group, onChanged: onChanged, title: 'Próximos de ese día')
        else
          EventAgendaCard(event: next, group: group, onChanged: onChanged),
        const SizedBox(height: 10),
        AgendaMatteStatsRow(
          events: events.length,
          upcoming: upcomingEvents.length,
          attendance: '$totalYes / $totalMaybe',
        ),
      ]);
    }

    return AppCard(
      color: AppColors.navy,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 58,
            height: 62,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white.withOpacity(.18))),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('SIN', style: TextStyle(color: AppColors.navAgenda, fontSize: 10, fontWeight: FontWeight.w900)),
              const Text('+', style: TextStyle(color: AppColors.ink, fontSize: 25, fontWeight: FontWeight.w900, height: 1)),
              Text(DateFormat('MMM', 'es_ES').format(DateTime.now()).replaceAll('.', ''), style: const TextStyle(color: AppColors.muted, fontSize: 10, fontWeight: FontWeight.w800)),
            ]),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
            Text('Próximo plan', style: TextStyle(color: Color(0xDFFFFFFF), fontSize: 12, fontWeight: FontWeight.w800)),
            SizedBox(height: 4),
            Text(
              'Crea el primer plan del grupo',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 21, height: 1.05, letterSpacing: -.25),
            ),
          ])),
          const SizedBox(width: 8),
          SizedBox(
            height: 42,
            child: TextButton.icon(
              onPressed: onCreate,
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.navy,
                padding: const EdgeInsets.symmetric(horizontal: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Crear', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        const Text(
          'Elige un día, crea un evento y el grupo podrá confirmar asistencia desde la Agenda.',
          style: TextStyle(color: Color(0xDFFFFFFF), fontWeight: FontWeight.w700, height: 1.32),
        ),
        const SizedBox(height: 12),
        AgendaMatteStatsRow(events: events.length, upcoming: upcomingEvents.length, attendance: '$totalYes / $totalMaybe'),
      ]),
    );
  }
}

class AgendaMatteStatsRow extends StatelessWidget {
  final int events;
  final int upcoming;
  final String attendance;
  const AgendaMatteStatsRow({super.key, required this.events, required this.upcoming, required this.attendance});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: MatteStatTile(label: 'Eventos', value: '$events', icon: Icons.calendar_month_rounded, color: AppColors.navAgenda)),
      const SizedBox(width: 8),
      Expanded(child: MatteStatTile(label: 'Próximos', value: '$upcoming', icon: Icons.event_available_rounded, color: AppColors.teal)),
      const SizedBox(width: 8),
      Expanded(child: MatteStatTile(label: 'Van / duda', value: attendance, icon: Icons.groups_rounded, color: AppColors.green)),
    ]);
  }
}

class MatteStatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const MatteStatTile({super.key, required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(color: color.withOpacity(.10), borderRadius: BorderRadius.circular(11)),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 15)),
          const SizedBox(height: 1),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800, fontSize: 10.5)),
        ])),
      ]),
    );
  }
}

class AgendaViewSwitch extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  const AgendaViewSwitch({super.key, required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(5),
      color: AppColors.tealSoft,
      child: Row(children: [
        Expanded(child: _AgendaSwitchItem(label: 'Semana', icon: Icons.view_week_rounded, selected: index == 0, onTap: () => onChanged(0))),
        const SizedBox(width: 5),
        Expanded(child: _AgendaSwitchItem(label: 'Mes', icon: Icons.calendar_month_rounded, selected: index == 1, onTap: () => onChanged(1))),
      ]),
    );
  }
}

class _AgendaSwitchItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _AgendaSwitchItem({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 42,
        decoration: BoxDecoration(
          color: selected ? AppColors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: selected ? [BoxShadow(color: AppColors.teal.withOpacity(.10), blurRadius: 12, offset: const Offset(0, 6))] : null,
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: selected ? AppColors.teal : AppColors.muted, size: 18),
          const SizedBox(width: 7),
          Text(label, style: TextStyle(color: selected ? AppColors.ink : AppColors.muted, fontWeight: FontWeight.w900)),
        ]),
      ),
    );
  }
}

class AgendaWeekHeader extends StatelessWidget {
  final DateTime selected;
  final int weekEvents;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;
  const AgendaWeekHeader({super.key, required this.selected, required this.weekEvents, required this.onPrevious, required this.onNext, required this.onToday});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 6));
    return Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${DateFormat('d MMM', 'es_ES').format(start)} — ${DateFormat('d MMM', 'es_ES').format(end)}', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 2),
        Text('$weekEvents planes en los próximos 7 días', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 12)),
      ])),
      TextButton.icon(onPressed: onToday, icon: const Icon(Icons.today_rounded, size: 17), label: const Text('Hoy')),
    ]);
  }
}

class AgendaMonthHeader extends StatelessWidget {
  final DateTime month;
  final int eventsCount;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;
  const AgendaMonthHeader({super.key, required this.month, required this.eventsCount, required this.onPrevious, required this.onNext, required this.onToday});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      _RoundIconButton(icon: Icons.chevron_left_rounded, onTap: onPrevious),
      const SizedBox(width: 8),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(monthTitle(month), style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 2),
        Text('$eventsCount eventos este mes', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 12)),
      ])),
      TextButton(onPressed: onToday, child: const Text('Hoy')),
      _RoundIconButton(icon: Icons.chevron_right_rounded, onTap: onNext),
    ]);
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(15), border: Border.all(color: AppColors.line)),
      child: Icon(icon, color: AppColors.ink),
    ),
  );
}

class PremiumWeekStrip extends StatelessWidget {
  final List<DateTime> days;
  final DateTime selected;
  final Map<String, List<Map<String, dynamic>>> eventsByDay;
  final ValueChanged<DateTime> onSelect;

  const PremiumWeekStrip({super.key, required this.days, required this.selected, required this.eventsByDay, required this.onSelect});

  List<Map<String, dynamic>> eventsFor(DateTime day) => eventsByDay[calendarDayKey(day)] ?? const <Map<String, dynamic>>[];

  @override
  Widget build(BuildContext context) {
    return Row(children: days.map((day) {
      final active = sameDay(day, selected);
      final today = sameDay(day, DateTime.now());
      final dayEvents = eventsFor(day);
      final hasEvents = dayEvents.isNotEmpty;
      final color = agendaDayAccentColor(dayEvents);
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onSelect(day),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: 82,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              decoration: BoxDecoration(
                color: active ? AppColors.teal : AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: active ? AppColors.teal : today ? AppColors.teal.withOpacity(.45) : hasEvents ? AppColors.line : AppColors.line),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(shortWeekday(day).toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: active ? Colors.white : AppColors.muted, fontSize: 10, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(day.day.toString(), style: TextStyle(color: active ? Colors.white : AppColors.ink, fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                SizedBox(
                  height: 11,
                  child: hasEvents
                      ? Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 2,
                          children: [
                            for (final event in dayEvents.take(3))
                              Container(width: 6, height: 6, decoration: BoxDecoration(color: active ? Colors.white : eventKindColor(event), shape: BoxShape.circle)),
                            if (dayEvents.length > 3)
                              Text('+', style: TextStyle(color: active ? Colors.white : AppColors.ink, fontWeight: FontWeight.w900, fontSize: 10, height: .8)),
                          ],
                        )
                      : Container(width: today ? 18 : 7, height: 4, decoration: BoxDecoration(color: active ? Colors.white : AppColors.line, borderRadius: BorderRadius.circular(99))),
                ),
              ]),
            ),
          ),
        ),
      );
    }).toList());
  }
}

class PremiumMonthCalendar extends StatelessWidget {
  final DateTime month;
  final DateTime selected;
  final Map<String, List<Map<String, dynamic>>> eventsByDay;
  final ValueChanged<DateTime> onSelect;
  const PremiumMonthCalendar({super.key, required this.month, required this.selected, required this.eventsByDay, required this.onSelect});

  List<Map<String, dynamic>> eventsFor(DateTime day) => eventsByDay[calendarDayKey(day)] ?? const <Map<String, dynamic>>[];

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month, 1);
    final startOffset = (first.weekday + 6) % 7;
    final days = DateTime(month.year, month.month + 1, 0).day;
    final cells = <DateTime?>[];
    for (int i = 0; i < startOffset; i++) { cells.add(null); }
    for (int d = 1; d <= days; d++) { cells.add(DateTime(month.year, month.month, d)); }
    while (cells.length % 7 != 0) { cells.add(null); }

    final rows = <List<DateTime?>>[];
    for (int i = 0; i < cells.length; i += 7) {
      rows.add(cells.sublist(i, min(i + 7, cells.length)));
    }

    return AppCard(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
      color: AppColors.surface,
      child: Column(children: [
        Row(children: ['L','M','X','J','V','S','D'].map((d) => Expanded(child: Center(child: Text(d, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.muted, fontSize: 12))))).toList()),
        const SizedBox(height: 10),
        ...rows.map((row) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(children: row.map((day) {
            if (day == null) return const Expanded(child: SizedBox(height: 46));
            final active = sameDay(day, selected);
            final today = sameDay(day, DateTime.now());
            final dayEvents = eventsFor(day);
            final hasEvents = dayEvents.isNotEmpty;
            final mainColor = agendaDayAccentColor(dayEvents);
            return Expanded(
              child: SizedBox(
                height: 46,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onSelect(day),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
                    decoration: BoxDecoration(
                      color: active ? AppColors.teal : Colors.transparent,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: active ? AppColors.teal : today ? AppColors.teal.withOpacity(.45) : hasEvents ? AppColors.line : Colors.transparent),
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(day.day.toString(), maxLines: 1, style: TextStyle(color: active ? Colors.white : AppColors.ink, fontWeight: active || hasEvents || today ? FontWeight.w900 : FontWeight.w700, fontSize: 14)),
                      const SizedBox(height: 4),
                      SizedBox(
                        height: 7,
                        child: hasEvents
                            ? Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 1.8,
                                children: [
                                  for (final event in dayEvents.take(3))
                                    Container(width: 5.5, height: 5.5, decoration: BoxDecoration(color: active ? Colors.white : eventKindColor(event), shape: BoxShape.circle)),
                                ],
                              )
                            : today
                                ? Container(width: 14, height: 4, decoration: BoxDecoration(color: active ? Colors.white : AppColors.teal, borderRadius: BorderRadius.circular(99)))
                                : const SizedBox.shrink(),
                      ),
                    ]),
                  ),
                ),
              ),
            );
          }).toList()),
        )),
      ]),
    );
  }
}

class AgendaSelectedDayCard extends StatelessWidget {
  final DateTime day;
  final List<Map<String, dynamic>> events;
  final int confirmed;
  final int maybe;
  final VoidCallback onCreate;
  const AgendaSelectedDayCard({super.key, required this.day, required this.events, required this.confirmed, required this.maybe, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final hasEvents = events.isNotEmpty;
    final color = agendaDayAccentColor(events);
    return AppCard(
      padding: const EdgeInsets.all(14),
      color: agendaDaySoftColor(events),
      child: Row(children: [
        Container(
          width: 58,
          height: 64,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: color.withOpacity(.16))),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(shortWeekday(day).toUpperCase(), style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w900)),
            Text(day.day.toString(), style: const TextStyle(color: AppColors.ink, fontSize: 23, fontWeight: FontWeight.w900)),
          ]),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(longDay(day), maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            hasEvents ? '${events.length} plan${events.length == 1 ? '' : 'es'} · $confirmed van · $maybe duda' : 'Día libre para crear un nuevo plan',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 12.5, height: 1.25),
          ),
        ])),
        const SizedBox(width: 8),
        SizedBox(
          height: 40,
          child: TextButton.icon(
            onPressed: onCreate,
            style: TextButton.styleFrom(backgroundColor: AppColors.white, foregroundColor: color, padding: const EdgeInsets.symmetric(horizontal: 11), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Crear', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ),
      ]),
    );
  }
}

class PremiumAgendaEmptyState extends StatelessWidget {
  final bool hasAnyEvents;
  final DateTime selected;
  final VoidCallback onCreate;
  const PremiumAgendaEmptyState({super.key, required this.hasAnyEvents, required this.selected, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      color: AppColors.surface,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 48, height: 48, decoration: BoxDecoration(color: AppColors.tealSoft, borderRadius: BorderRadius.circular(17)), child: const Icon(Icons.event_available_rounded, color: AppColors.navAgenda)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(hasAnyEvents ? 'No hay planes este día' : 'Empieza la agenda del grupo', style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(height: 4),
            Text(
              hasAnyEvents
                  ? 'El ${DateFormat('d MMM', 'es_ES').format(selected)} está libre. Puedes crear un plan o revisar los próximos eventos.'
                  : 'Crea el primer evento y los miembros podrán confirmar asistencia desde aquí.',
              style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, height: 1.32),
            ),
          ])),
        ]),
        const SizedBox(height: 14),
        SizedBox(width: double.infinity, child: PrimaryButton(label: 'Crear plan para este día', icon: Icons.add_rounded, onTap: onCreate)),
      ]),
    );
  }
}

class AgendaRecoveryCard extends StatelessWidget {
  final VoidCallback onCreate;
  final VoidCallback onRetry;
  const AgendaRecoveryCard({super.key, required this.onCreate, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.tealSoft,
      child: Row(children: [
        Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.event_available_rounded, color: AppColors.teal)),
        const SizedBox(width: 12),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('La agenda no puede quedar en blanco', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
          SizedBox(height: 3),
          Text('Aunque falle la carga, siempre verás este panel para reintentar o crear un plan.', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 12, height: 1.25)),
        ])),
        const SizedBox(width: 8),
        Column(children: [
          SizedBox(width: 96, child: PrimaryButton(label: 'Crear', icon: Icons.add_rounded, onTap: onCreate)),
          const SizedBox(height: 7),
          SizedBox(width: 96, child: SecondaryButton(label: 'Reintentar', icon: Icons.refresh_rounded, onTap: onRetry)),
        ]),
      ]),
    );
  }
}

class CalendarOverviewCard extends StatelessWidget {
  final List<Map<String, dynamic>> events;
  final List<Map<String, dynamic>> upcomingEvents;
  final VoidCallback onCreate;
  const CalendarOverviewCard({super.key, required this.events, required this.upcomingEvents, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final next = upcomingEvents.isNotEmpty ? upcomingEvents.first : null;
    final activeEvents = events.length;
    final nextDate = next == null ? null : DateTime.tryParse(next['starts_at']?.toString() ?? '')?.toLocal();
    final nextColor = next == null ? AppColors.teal : eventKindColor(next);
    final totalYes = upcomingEvents.fold<int>(0, (sum, e) => sum + attendanceCount(e, 'yes'));
    final totalMaybe = upcomingEvents.fold<int>(0, (sum, e) => sum + attendanceCount(e, 'maybe'));

    return AppCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.navy,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Stack(children: [
            Positioned(
              right: -32,
              top: -38,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: nextColor.withOpacity(.22),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              left: -26,
              bottom: -34,
              child: Container(
                width: 108,
                height: 108,
                decoration: BoxDecoration(
                  color: AppColors.blue.withOpacity(.18),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(.13), borderRadius: BorderRadius.circular(16)),
                    child: Icon(next == null ? Icons.calendar_month_rounded : eventKindIcon(next), color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      next == null ? 'Aún no hay planes' : 'Próximo plan',
                      style: const TextStyle(color: Color(0xDFFFFFFF), fontWeight: FontWeight.w800, fontSize: 12),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      next == null ? 'Crea el primer evento del grupo' : AppData.text(next['title'], 'Evento'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 19, height: 1.05),
                    ),
                  ])),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 38,
                    child: TextButton.icon(
                      onPressed: onCreate,
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.navy,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Crear', style: TextStyle(fontWeight: FontWeight.w900)),
                    ),
                  ),
                ]),
                if (next != null) ...[
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    _WhiteMetaPill(icon: Icons.schedule_rounded, text: nextDate == null ? 'Fecha pendiente' : longDateTime(nextDate)),
                    _WhiteMetaPill(icon: Icons.place_outlined, text: AppData.text(next['location'], 'Sin ubicación')),
                    _WhiteMetaPill(icon: Icons.people_alt_rounded, text: "${attendanceCount(next, 'yes')} van · mínimo ${AppData.intValue(next['min_people'], 2)}"),
                  ]),
                ],
                const SizedBox(height: 13),
                Row(children: [
                  Expanded(child: _DarkAgendaMetric(label: 'Eventos', value: '$activeEvents')),
                  const SizedBox(width: 8),
                  Expanded(child: _DarkAgendaMetric(label: 'Próximos', value: '${upcomingEvents.length}')),
                  const SizedBox(width: 8),
                  Expanded(child: _DarkAgendaMetric(label: 'Van / duda', value: '$totalYes / $totalMaybe')),
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _WhiteMetaPill extends StatelessWidget {
  final IconData icon;
  final String text;
  const _WhiteMetaPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 240),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(color: Colors.white.withOpacity(.14), borderRadius: BorderRadius.circular(99), border: Border.all(color: Colors.white.withOpacity(.12))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: Colors.white, size: 15),
        const SizedBox(width: 6),
        Flexible(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12))),
      ]),
    );
  }
}

class _DarkAgendaMetric extends StatelessWidget {
  final String label;
  final String value;
  const _DarkAgendaMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(color: Colors.white.withOpacity(.12), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white.withOpacity(.10))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xDFFFFFFF), fontSize: 10.5, fontWeight: FontWeight.w800)),
        const SizedBox(height: 3),
        Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900)),
      ]),
    );
  }
}

class CalendarDaySummary extends StatelessWidget {
  final DateTime day;
  final List<Map<String, dynamic>> events;
  final int confirmed;
  final int maybe;
  final VoidCallback onCreate;
  const CalendarDaySummary({super.key, required this.day, required this.events, required this.confirmed, required this.maybe, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final hasEvents = events.isNotEmpty;
    final color = agendaDayAccentColor(events);
    return AppCard(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
      child: Row(children: [
        DateBadge(date: day),
        const SizedBox(width: 11),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(longDay(day), maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            hasEvents ? '${events.length} plan${events.length == 1 ? '' : 'es'} · $confirmed van · $maybe duda' : 'Día libre',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 12.5),
          ),
        ])),
        const SizedBox(width: 8),
        SizedBox(
          height: 38,
          child: TextButton.icon(
            onPressed: onCreate,
            style: TextButton.styleFrom(backgroundColor: color.withOpacity(.10), foregroundColor: color, padding: const EdgeInsets.symmetric(horizontal: 11), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Crear', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ),
      ]),
    );
  }
}



String agendaSelectedDayTitle(DateTime day) {
  final today = DateTime.now();
  if (sameDay(day, today)) return 'Hoy';
  return DateFormat('EEEE d MMM', 'es_ES').format(day).replaceAll('.', '');
}

class AgendaGroupedUpcomingList extends StatelessWidget {
  final List<Map<String, dynamic>> events;
  final Map<String, dynamic> group;
  final VoidCallback onChanged;
  final DateTime? excludeDay;
  final VoidCallback onCreate;
  const AgendaGroupedUpcomingList({
    super.key,
    required this.events,
    required this.group,
    required this.onChanged,
    this.excludeDay,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    final filtered = events.where((event) {
      if (excludeDay == null) return true;
      final date = DateTime.tryParse(AppData.text(event['starts_at']))?.toLocal();
      return date == null || !sameDay(date, excludeDay!);
    }).toList()
      ..sort((a, b) {
        final da = DateTime.tryParse(AppData.text(a['starts_at'])) ?? DateTime.fromMillisecondsSinceEpoch(0);
        final db = DateTime.tryParse(AppData.text(b['starts_at'])) ?? DateTime.fromMillisecondsSinceEpoch(0);
        return da.compareTo(db);
      });

    if (filtered.isEmpty) {
      return AgendaNoMorePlansCard(onCreate: onCreate);
    }

    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final event in filtered) {
      final date = DateTime.tryParse(AppData.text(event['starts_at']))?.toLocal();
      if (date == null) continue;
      grouped.putIfAbsent(calendarDayKey(date), () => <Map<String, dynamic>>[]).add(event);
    }

    final keys = grouped.keys.toList()..sort();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (final key in keys.take(5)) ...[
        AgendaSameDayCompactCard(
          events: grouped[key]!,
          group: group,
          onChanged: onChanged,
          title: agendaSelectedDayTitle(DateTime.parse(key)),
          compactHeader: true,
        ),
        const SizedBox(height: 10),
      ],
      if (keys.length > 5)
        AppCard(
          color: AppColors.surface,
          padding: const EdgeInsets.all(12),
          child: Text('+ ${keys.length - 5} días más con planes', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800)),
        ),
    ]);
  }
}

class AgendaNoMorePlansCard extends StatelessWidget {
  final VoidCallback onCreate;
  const AgendaNoMorePlansCard({super.key, required this.onCreate});

  @override
  Widget build(BuildContext context) => AppCard(
    color: AppColors.surface,
    padding: const EdgeInsets.all(14),
    child: Row(children: [
      Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(color: AppColors.tealSoft, borderRadius: BorderRadius.circular(15)),
        child: const Icon(Icons.event_available_rounded, color: AppColors.orange, size: 20),
      ),
      const SizedBox(width: 10),
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('No hay más planes', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
        SizedBox(height: 3),
        Text('Crea un nuevo evento para el grupo.', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 12)),
      ])),
      const SizedBox(width: 8),
      TextButton.icon(
        onPressed: onCreate,
        style: TextButton.styleFrom(
          backgroundColor: AppColors.teal,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        icon: const Icon(Icons.add_rounded, size: 18),
        label: const Text('Crear', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
    ]),
  );
}

class AgendaSameDayCompactCard extends StatelessWidget {
  final List<Map<String, dynamic>> events;
  final Map<String, dynamic> group;
  final VoidCallback onChanged;
  final String title;
  final bool compactHeader;
  const AgendaSameDayCompactCard({super.key, required this.events, required this.group, required this.onChanged, this.title = 'Planes del día', this.compactHeader = false});

  @override
  Widget build(BuildContext context) {
    final ordered = [...events]..sort((a, b) {
      final da = DateTime.tryParse(AppData.text(a['starts_at'])) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final db = DateTime.tryParse(AppData.text(b['starts_at'])) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return da.compareTo(db);
    });
    final firstDate = DateTime.tryParse(AppData.text(ordered.first['starts_at']))?.toLocal() ?? DateTime.now();
    final hasTournament = ordered.any(eventIsTournamentEvent);
    final accent = hasTournament ? AppColors.teal : eventKindColor(ordered.first);

    Future<void> openEvent(Map<String, dynamic> event) async {
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => EventDetailScreen(event: event, group: group)));
      onChanged();
    }

    return AppCard(
      color: AppColors.white,
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 45,
            height: 48,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: accent.withOpacity(.20))),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(shortWeekday(firstDate).toUpperCase(), style: TextStyle(color: accent, fontSize: 9.5, fontWeight: FontWeight.w900)),
              Text(firstDate.day.toString(), style: const TextStyle(color: AppColors.ink, fontSize: 19, fontWeight: FontWeight.w900, height: 1)),
            ]),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 15)),
            const SizedBox(height: 3),
            Text('${ordered.length} evento${ordered.length == 1 ? '' : 's'} · ${DateFormat('d MMM', 'es_ES').format(firstDate).replaceAll('.', '')}', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800, fontSize: 12)),
          ])),
          if (hasTournament) const TournamentAgendaBadge(),
        ]),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(17), border: Border.all(color: AppColors.lineSoft)),
          child: Column(children: [
            for (int i = 0; i < ordered.take(6).length; i++) ...[
              AgendaCompactEventRow(event: ordered[i], onTap: () => openEvent(ordered[i])),
              if (i != ordered.take(6).length - 1) const Divider(height: 1, indent: 58, color: AppColors.lineSoft),
            ],
          ]),
        ),
        if (ordered.length > 6) ...[
          const SizedBox(height: 8),
          Text('+ ${ordered.length - 6} más', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800, fontSize: 12)),
        ],
      ]),
    );
  }
}

class AgendaCompactEventRow extends StatelessWidget {
  final Map<String, dynamic> event;
  final VoidCallback onTap;
  const AgendaCompactEventRow({super.key, required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(AppData.text(event['starts_at']))?.toLocal() ?? DateTime.now();
    final color = eventKindColor(event);
    final isTournament = eventIsTournamentEvent(event);
    final yes = attendanceCount(event, 'yes');
    final minPeople = AppData.intValue(event['min_people'], 1);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        child: Row(children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: isTournament ? Colors.white : eventKindSoftColor(event), borderRadius: BorderRadius.circular(14), border: Border.all(color: isTournament ? AppColors.lineSoft : Colors.transparent)),
            child: Icon(eventKindIcon(event), color: isTournament ? AppColors.amber : color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(AppData.text(event['title'], 'Evento'), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 13)),
            const SizedBox(height: 3),
            Text('${DateFormat('HH:mm', 'es_ES').format(date)} · $yes/$minPeople van', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 11.5)),
          ])),
          const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        ]),
      ),
    );
  }
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
    if (saving) return;
    if (mounted) setState(() => saving = true);
    try {
      await AppData.setAttendance(widget.event['id'].toString(), status);
      widget.onChanged();
    } catch (e) {
      if (mounted) await showToast(context, e.toString(), danger: true);
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
    final color = eventKindColor(event);
    final isTournament = eventIsTournamentEvent(event);
    final progress = min(1.0, yes / max(1, minPeople));

    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: AppCard(
        color: AppColors.white,
        padding: EdgeInsets.zero,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: open,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(11, 11, 11, 8),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 48,
                  height: 52,
                  decoration: BoxDecoration(color: eventKindSoftColor(event), borderRadius: BorderRadius.circular(17)),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(eventKindIcon(event), color: color, size: 20),
                    const SizedBox(height: 3),
                    Text(DateFormat('HH:mm', 'es_ES').format(date), style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900)),
                  ]),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Wrap(spacing: 6, runSpacing: 6, children: [
                    EventKindPill(event: event, compact: true),
                    if (isTournament) const TournamentAgendaBadge(),
                    if (eventIsRoutine(event)) RoutineBadge(label: eventRoutineBadge(event)),
                  ]),
                  const SizedBox(height: 7),
                  Text(AppData.text(event['title'], 'Evento'), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.ink, fontSize: 16.5, fontWeight: FontWeight.w900, height: 1.1)),
                  const SizedBox(height: 6),
                  MetaLine(icon: Icons.place_outlined, text: AppData.text(event['location'], 'Sin ubicación')),
                  const SizedBox(height: 7),
                  Row(children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 7,
                          backgroundColor: AppColors.line,
                          valueColor: AlwaysStoppedAnimation<Color>(viable ? AppColors.green : color),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('$yes/$minPeople', style: TextStyle(color: viable ? AppColors.green : color, fontWeight: FontWeight.w900, fontSize: 12)),
                  ]),
                  const SizedBox(height: 6),
                  Text(
                    viable ? 'Plan viable · mínimo alcanzado' : 'Faltan ${max(0, minPeople - yes)} para alcanzar el mínimo',
                    style: TextStyle(color: viable ? AppColors.green : AppColors.amber, fontWeight: FontWeight.w900, fontSize: 12),
                  ),
                ])),
                const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
              ]),
            ),
          ),
          Container(height: 1, color: AppColors.lineSoft),
          Padding(
            padding: const EdgeInsets.fromLTRB(11, 9, 11, 11),
            child: Row(children: [
              Expanded(child: CompactAttendanceButton(label: 'Voy', count: yes, selected: mine == 'yes', color: AppColors.green, onTap: saving ? () {} : () => setStatus('yes'))),
              const SizedBox(width: 7),
              Expanded(child: CompactAttendanceButton(label: 'Duda', count: maybe, selected: mine == 'maybe', color: AppColors.amber, onTap: saving ? () {} : () => setStatus('maybe'))),
              const SizedBox(width: 7),
              Expanded(child: CompactAttendanceButton(label: 'No', count: no, selected: mine == 'no', color: AppColors.red, onTap: saving ? () {} : () => setStatus('no'))),
            ]),
          ),
        ]),
      ),
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
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Container(
      height: 38,
      decoration: BoxDecoration(color: selected ? color.withOpacity(.12) : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: selected ? color : AppColors.lineSoft)),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(selected ? Icons.check_circle_rounded : Icons.circle_outlined, size: 15, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w900)),
        const SizedBox(width: 4),
        Text(count.toString(), style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w900)),
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
          ProfileAvatar(name: name, avatarUrl: memberAvatarUrl(m), radius: 18),
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
    final color = eventKindColor(event);
    final soft = eventKindSoftColor(event);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: color.withOpacity(.16)),
          boxShadow: [BoxShadow(color: color.withOpacity(.045), blurRadius: 18, offset: const Offset(0, 8))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Material(
            color: AppColors.white,
            child: InkWell(
              onTap: onTap,
              child: IntrinsicHeight(
                child: Row(children: [
                  Container(width: 6, color: color),
                  Expanded(child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(children: [
                      Container(
                        width: 54,
                        height: 58,
                        decoration: BoxDecoration(color: soft, borderRadius: BorderRadius.circular(17)),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text(shortWeekday(d).toUpperCase(), style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w900)),
                          Text(d.day.toString(), style: const TextStyle(color: AppColors.ink, fontSize: 22, fontWeight: FontWeight.w900)),
                        ]),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Icon(eventKindIcon(event), color: color, size: 16),
                          const SizedBox(width: 5),
                          Text(eventKindLabel(event), style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.w900)),
                          if (eventIsRoutine(event)) ...[
                            const SizedBox(width: 8),
                            Icon(Icons.repeat_rounded, color: color, size: 14),
                            const SizedBox(width: 4),
                            Flexible(child: Text(eventRoutineBadge(event), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.w900))),
                          ],
                        ]),
                        const SizedBox(height: 4),
                        Text(AppData.text(event['title'], 'Evento'), maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 5),
                        MetaLine(icon: Icons.schedule_rounded, text: DateFormat('dd/MM · HH:mm', 'es_ES').format(d)),
                        MetaLine(icon: Icons.place_outlined, text: AppData.text(event['location'], 'Sin ubicación')),
                      ])),
                      const SizedBox(width: 8),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisAlignment: MainAxisAlignment.center, children: [
                        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: viable ? AppColors.greenSoft : AppColors.orangeSoft, borderRadius: BorderRadius.circular(99)), child: Text(viable ? '$yes/$minPeople OK' : '$yes/$minPeople', style: TextStyle(color: viable ? AppColors.green : AppColors.orange, fontWeight: FontWeight.w900, fontSize: 12))),
                        const SizedBox(height: 6),
                        Text('$maybe duda', style: const TextStyle(color: AppColors.muted, fontSize: 11, fontWeight: FontWeight.w700)),
                      ]),
                    ]),
                  )),
                ]),
              ),
            ),
          ),
        ),
      ),
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
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              ProfileAvatar(name: financeMemberName(paidBy, members), avatarUrl: financeMemberAvatarUrl(paidBy, members), radius: 21),
              Container(
                width: 17,
                height: 17,
                decoration: BoxDecoration(color: settled ? AppColors.green : AppColors.orange, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                child: Icon(settled ? Icons.check_rounded : Icons.receipt_long_rounded, size: 10, color: Colors.white),
              ),
            ],
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
    final scoringType = AppData.text(tournament['scoring_type'], 'general');
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
            Text('${tournamentFormatLabel(format)} · ${teamTypeLabel(AppData.text(tournament['team_type'], 'equipo'))} · ${scoringTypeLabel(scoringType)}', style: Theme.of(context).textTheme.bodyMedium),
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



class InviteAccessCard extends StatelessWidget {
  final String groupName;
  final String code;
  final bool compact;
  final VoidCallback? onRegenerate;
  const InviteAccessCard({super.key, required this.groupName, required this.code, this.compact = false, this.onRegenerate});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.all(compact ? 14 : 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(color: AppColors.tealSoft, borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.lock_person_rounded, color: AppColors.teal),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Acceso privado', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 3),
            Text('Nadie entra al grupo sin recibir este código.', style: Theme.of(context).textTheme.bodyMedium),
          ])),
        ]),
        const SizedBox(height: 14),
        InviteCodeBox(code: code),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: SecondaryButton(label: 'Copiar link', icon: Icons.link_rounded, onTap: () => copyInviteLink(context, code))),
          const SizedBox(width: 10),
          Expanded(child: PrimaryButton(label: 'Compartir', icon: Icons.share_rounded, onTap: () => Share.share(inviteText(groupName, code)))),
        ]),
        const SizedBox(height: 10),
        InviteLinkBox(code: code),
        if (onRegenerate != null) ...[
          const SizedBox(height: 10),
          DangerButton(label: 'Regenerar código', icon: Icons.refresh_rounded, onTap: onRegenerate!),
        ],
      ]),
    );
  }
}

class InviteCodeBox extends StatelessWidget {
  final String code;
  const InviteCodeBox({super.key, required this.code});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.tealSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x33008F86)),
      ),
      child: Row(children: [
        const Icon(Icons.qr_code_2_rounded, color: AppColors.teal),
        const SizedBox(width: 12),
        Expanded(child: Text(code, textAlign: TextAlign.center, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900, letterSpacing: 3, color: AppColors.teal))),
        const SizedBox(width: 12),
        const Icon(Icons.ios_share_rounded, color: AppColors.teal),
      ]),
    );
  }
}


class InviteLinkBox extends StatelessWidget {
  final String code;
  const InviteLinkBox({super.key, required this.code});

  @override
  Widget build(BuildContext context) {
    final link = InviteLinks.joinUrl(code);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(children: [
        const Icon(Icons.link_rounded, color: AppColors.teal, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(link, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700, fontSize: 12))),
        const SizedBox(width: 8),
        InkWell(
          onTap: () => copyInviteLink(context, code),
          borderRadius: BorderRadius.circular(12),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Text('Copiar', style: TextStyle(color: AppColors.teal, fontWeight: FontWeight.w900)),
          ),
        ),
      ]),
    );
  }
}

class RoleInfoCard extends StatelessWidget {
  final String role;
  const RoleInfoCard({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final isOwner = role == 'owner';
    final isAdmin = role == 'admin';
    final color = isOwner ? AppColors.orange : isAdmin ? AppColors.teal : AppColors.violet;
    final title = isOwner ? 'Eres owner del grupo' : isAdmin ? 'Eres admin' : 'Eres miembro';
    final body = isOwner
        ? 'Puedes nombrar admins, quitar admins y gestionar el grupo. Tu rol está protegido.'
        : isAdmin
            ? 'Puedes ayudar a gestionar miembros y mantener el grupo ordenado.'
            : 'Puedes participar en quedadas, gastos y torneos. Los admins gestionan permisos.';
    return AppCard(
      color: AppColors.surface,
      child: Row(children: [
        Container(width: 42, height: 42, decoration: BoxDecoration(color: color.withOpacity(.12), borderRadius: BorderRadius.circular(15)), child: Icon(isOwner ? Icons.workspace_premium_rounded : isAdmin ? Icons.admin_panel_settings_rounded : Icons.person_rounded, color: color)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 3),
          Text(body, style: Theme.of(context).textTheme.bodyMedium),
        ])),
      ]),
    );
  }
}

class PermissionMatrixCard extends StatelessWidget {
  final bool compact;
  const PermissionMatrixCard({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 38, height: 38, decoration: BoxDecoration(color: AppColors.tealSoft, borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.verified_user_rounded, color: AppColors.teal, size: 21)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Permisos claros', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 2),
            Text('Cada rol tiene límites para evitar errores humanos.', style: Theme.of(context).textTheme.bodyMedium),
          ])),
        ]),
        const SizedBox(height: 12),
        PermissionLine(role: 'Owner', body: 'Control total, admins, miembros y acciones críticas.', color: AppColors.orange),
        PermissionLine(role: 'Admin', body: 'Gestiona miembros y ayuda a mantener el grupo.', color: AppColors.teal),
        PermissionLine(role: 'Miembro', body: 'Participa en eventos, gastos y torneos del grupo.', color: AppColors.violet),
        if (!compact) ...[
          const SizedBox(height: 8),
          Text('El owner queda protegido: no puede ser expulsado ni degradado desde la app.', style: Theme.of(context).textTheme.bodyMedium),
        ],
      ]),
    );
  }
}

class PermissionLine extends StatelessWidget {
  final String role;
  final String body;
  final Color color;
  const PermissionLine({super.key, required this.role, required this.body, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: color.withOpacity(.10), borderRadius: BorderRadius.circular(99)),
          child: Text(role, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 11)),
        ),
        const SizedBox(width: 9),
        Expanded(child: Text(body, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 12.5, height: 1.35))),
      ]),
    );
  }
}


Future<void> showMemberProfileSheet(
  BuildContext context,
  Map<String, dynamic> member,
  bool canEditThis,
  Future<void> Function(Map<String, dynamic> member, String role) onRole,
  Future<void> Function(Map<String, dynamic> member) onRemove,
) async {
  final profile = AppData.asMap(member['profiles']);
  final name = memberName(member);
  final role = AppData.text(member['role'], 'member');
  final email = AppData.text(profile['email'], 'sin email');
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 22),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: ProfileAvatar(name: name, avatarUrl: AppData.text(profile['avatar_url']), radius: 42)),
          const SizedBox(height: 12),
          Center(child: Text(name, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge)),
          const SizedBox(height: 4),
          Center(child: Text(email, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium)),
          const SizedBox(height: 12),
          Center(child: RoleBadge(role: role)),
          const SizedBox(height: 18),
          RoleInfoCard(role: role),
          if (canEditThis) ...[
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: SecondaryButton(
                label: role == 'admin' ? 'Quitar admin' : 'Hacer admin',
                icon: role == 'admin' ? Icons.person_outline_rounded : Icons.admin_panel_settings_rounded,
                onTap: () {
                  Navigator.pop(context);
                  onRole(member, role == 'admin' ? 'member' : 'admin');
                },
              )),
              const SizedBox(width: 10),
              Expanded(child: DangerButton(
                label: 'Expulsar',
                icon: Icons.person_remove_rounded,
                onTap: () {
                  Navigator.pop(context);
                  onRemove(member);
                },
              )),
            ]),
          ] else ...[
            const SizedBox(height: 14),
            EmptySlim(
              icon: Icons.lock_outline_rounded,
              title: 'Sin acciones disponibles',
              body: role == 'owner' ? 'El owner está protegido.' : 'Solo owner/admins pueden gestionar otros miembros.',
            ),
          ],
        ]),
      ),
    ),
  );
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
        onTap: () => showMemberProfileSheet(context, member, canEditThis, onRole, onRemove),
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


class MonthGrid extends StatelessWidget {
  final DateTime month;
  final DateTime selected;
  final Map<String, List<Map<String, dynamic>>> eventsByDay;
  final ValueChanged<DateTime> onSelect;
  const MonthGrid({super.key, required this.month, required this.selected, required this.eventsByDay, required this.onSelect});

  List<Map<String, dynamic>> eventsFor(DateTime day) {
    return eventsByDay[calendarDayKey(day)] ?? const <Map<String, dynamic>>[];
  }

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month, 1);
    final startOffset = (first.weekday + 6) % 7;
    final days = DateTime(month.year, month.month + 1, 0).day;
    final cells = <DateTime?>[];
    for (int i = 0; i < startOffset; i++) { cells.add(null); }
    for (int d = 1; d <= days; d++) { cells.add(DateTime(month.year, month.month, d)); }
    while (cells.length % 7 != 0) { cells.add(null); }

    final rows = <List<DateTime?>>[];
    for (int i = 0; i < cells.length; i += 7) {
      rows.add(cells.sublist(i, min(i + 7, cells.length)));
    }

    return Column(children: [
      Row(children: ['L','M','X','J','V','S','D'].map((d) => Expanded(child: Center(child: Text(d, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.muted, fontSize: 12))))).toList()),
      const SizedBox(height: 8),
      ...rows.map((row) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(children: row.map((day) {
          if (day == null) return const Expanded(child: SizedBox(height: 42));
          final active = sameDay(day, selected);
          final today = sameDay(day, DateTime.now());
          final dayEvents = eventsFor(day);
          final hasEvents = dayEvents.isNotEmpty;
          final mainColor = hasEvents ? eventKindColor(dayEvents.first) : AppColors.line;
          return Expanded(
            child: SizedBox(
              height: 42,
              child: InkWell(
                onTap: () => onSelect(day),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                  decoration: BoxDecoration(
                    color: active ? AppColors.teal : hasEvents ? eventKindSoftColor(dayEvents.first) : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: active ? AppColors.teal : today ? AppColors.teal.withOpacity(.55) : hasEvents ? mainColor.withOpacity(.32) : Colors.transparent,
                      width: active || today || hasEvents ? 1.2 : 1,
                    ),
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        day.day.toString(),
                        maxLines: 1,
                        style: TextStyle(
                          color: active ? Colors.white : AppColors.ink,
                          fontWeight: active || hasEvents || today ? FontWeight.w900 : FontWeight.w700,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    SizedBox(
                      height: 7,
                      child: Center(
                        child: hasEvents
                            ? Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 1.5,
                                children: [
                                  for (final event in dayEvents.take(3))
                                    Container(
                                      width: 5.5,
                                      height: 5.5,
                                      decoration: BoxDecoration(color: active ? Colors.white : eventKindColor(event), shape: BoxShape.circle),
                                    ),
                                ],
                              )
                            : const SizedBox(height: 5),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          );
        }).toList()),
      )),
    ]);
  }
}


class PatternIcons extends StatelessWidget { const PatternIcons({super.key}); @override Widget build(BuildContext context) => Wrap(spacing: 24, runSpacing: 20, children: List.generate(70, (i) => Icon([Icons.event_available_rounded, Icons.calendar_month_rounded, Icons.account_balance_wallet_rounded, Icons.emoji_events_rounded, Icons.lock_rounded, Icons.qr_code_rounded][i % 6], size: 17, color: Colors.white))); }

void showPermissionSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 30),
      child: Column(mainAxisSize: MainAxisSize.min, children: const [
        PermissionMatrixCard(),
      ]),
    ),
  );
}


Future<bool?> confirmAction(
  BuildContext context, {
  required String title,
  required String body,
  bool danger = false,
  String confirmLabel = 'Confirmar',
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: danger ? AppColors.red : AppColors.teal),
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
}

String humanError(Object? error) {
  return humanizeError(error?.toString() ?? '');
}


void copyInviteCode(BuildContext context, String code) {
  Clipboard.setData(ClipboardData(text: InviteLinks.normalizeCode(code)));
  showToast(context, 'Código copiado.');
}

void copyInviteLink(BuildContext context, String code) {
  Clipboard.setData(ClipboardData(text: InviteLinks.joinUrl(code)));
  showToast(context, 'Link de invitación copiado.');
}

String inviteText(String groupName, String code) {
  final clean = InviteLinks.normalizeCode(code);
  return 'Únete a $groupName en Grupli. Toca este enlace y entrarás directamente al grupo:\n\n${InviteLinks.joinUrl(clean)}\n\nSi tienes la app instalada, se abrirá automáticamente. Código: $clean';
}

void showCodeSheet(BuildContext context, String code, String groupName) {
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 30),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Invitación privada', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 6),
        Text('Comparte este link solo con quien quieras dentro del grupo.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 14),
        InviteCodeBox(code: code),
        const SizedBox(height: 10),
        InviteLinkBox(code: code),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: SecondaryButton(label: 'Copiar link', icon: Icons.link_rounded, onTap: () => copyInviteLink(context, code))),
          const SizedBox(width: 10),
          Expanded(child: PrimaryButton(label: 'Compartir', icon: Icons.share_rounded, onTap: () => Share.share(inviteText(groupName, code)))),
        ]),
      ]),
    ),
  );
}
