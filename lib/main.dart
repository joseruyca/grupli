library grupli_app;

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';



part 'core/theme/app_colors.dart';
part 'core/app_data/app_data.dart';
part 'features/onboarding/onboarding.dart';
part 'features/auth/auth.dart';
part 'features/groups/groups.dart';
part 'features/agenda/agenda.dart';
part 'features/finances/finances.dart';
part 'features/tournaments/tournament_engine_v2.dart';
part 'features/tournaments/tournaments.dart';
part 'features/profile/profile_members_admin.dart';
part 'core/widgets/shared_widgets.dart';


final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.error_outline_rounded, color: Color(0xFF087A78), size: 42),
                SizedBox(height: 14),
                Text(
                  'Algo no ha ido bien',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF12263A)),
                ),
                SizedBox(height: 8),
                Text(
                  'Cierra esta pantalla y vuelve a intentarlo. Si se repite, envíanos un reporte desde Ayuda.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF6A7A89), height: 1.35),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  };

  Intl.defaultLocale = 'es_ES';
  await initializeDateFormatting('es_ES');

  if (!AppConfig.hasSupabaseRuntimeConfig) {
    runApp(const GrupliConfigurationMissingApp());
    return;
  }

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(authFlowType: AuthFlowType.pkce),
  );

  runApp(const GrupliApp());
}

class AppConfig {
  static const appVersion = 'v16.26.1-web-safe-restore';
  static const enableRealtimeSubscriptions = false;

  // Security baseline:
  // - No Supabase URL/key fallback is allowed in the frontend.
  // - Runtime config must arrive through --dart-define from .env locally
  //   or from Vercel environment variables in web builds.
  static const supabaseUrlDefine = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonDefine = String.fromEnvironment('SUPABASE_ANON_KEY');

  static const appBaseUrlDefine = String.fromEnvironment('APP_BASE_URL');
  static const fallbackAppBaseUrl = 'https://grupli.vercel.app';

  static const firebaseApiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const firebaseAppId = String.fromEnvironment('FIREBASE_APP_ID');
  static const firebaseMessagingSenderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  static const firebaseProjectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const firebaseVapidKey = String.fromEnvironment('FIREBASE_VAPID_KEY');
  static const osmGeocoderEndpointDefine = String.fromEnvironment('OSM_GEOCODER_ENDPOINT');
  static const fallbackOsmGeocoderEndpoint = 'https://photon.komoot.io/api/';

  static String get supabaseUrl => supabaseUrlDefine.trim();
  static String get supabaseAnonKey => supabaseAnonDefine.trim();
  static String get appBaseUrl => appBaseUrlDefine.trim().isNotEmpty ? appBaseUrlDefine.trim().replaceFirst(RegExp(r'/+$'), '') : fallbackAppBaseUrl;

  static String get osmGeocoderEndpoint => osmGeocoderEndpointDefine.trim().isNotEmpty ? osmGeocoderEndpointDefine.trim() : fallbackOsmGeocoderEndpoint;

  static bool get hasSupabaseRuntimeConfig =>
      supabaseUrl.trim().isNotEmpty &&
      supabaseAnonKey.trim().isNotEmpty &&
      supabaseUrl.trim().startsWith('https://') &&
      supabaseUrl.trim().contains('.supabase.co');

  static bool get firebaseConfigured =>
      firebaseApiKey.trim().isNotEmpty &&
      firebaseAppId.trim().isNotEmpty &&
      firebaseMessagingSenderId.trim().isNotEmpty &&
      firebaseProjectId.trim().isNotEmpty;
}

class GrupliConfigurationMissingApp extends StatelessWidget {
  const GrupliConfigurationMissingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFFF7FBFA),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420),
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE4EFEE)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 24,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline_rounded, color: Color(0xFF087A78), size: 42),
                    SizedBox(height: 14),
                    Text(
                      'Configuración pendiente',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF12263A)),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'La app necesita su configuración segura de entorno para arrancar. Revisa el archivo .env local o las variables del entorno de despliegue.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF6A7A89), height: 1.35),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
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


// core/theme/app_colors.dart moved to part file.

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
        visualDensity: VisualDensity.standard,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: ZoomPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.fuchsia: FadeUpwardsPageTransitionsBuilder(),
          },
        ),
        dividerTheme: const DividerThemeData(color: AppColors.line, thickness: 1, space: 1),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.surface,
          selectedColor: AppColors.tealSoft,
          side: const BorderSide(color: AppColors.line),
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: AppColors.ink, height: 1.04, letterSpacing: -0.85),
          headlineMedium: TextStyle(fontSize: 24.5, fontWeight: FontWeight.w900, color: AppColors.ink, height: 1.08, letterSpacing: -0.45),
          titleLarge: TextStyle(fontSize: 19.5, fontWeight: FontWeight.w900, color: AppColors.ink, letterSpacing: -0.2),
          titleMedium: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w900, color: AppColors.ink, height: 1.22),
          bodyLarge: TextStyle(fontSize: 16, color: AppColors.ink, height: 1.42),
          bodyMedium: TextStyle(fontSize: 14.2, color: AppColors.muted, height: 1.42, fontWeight: FontWeight.w600),
          labelLarge: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          hintStyle: const TextStyle(color: Color(0xFF9AA4B5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: AppColors.line)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: AppColors.line)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: AppColors.teal, width: 1.4)),
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
    // Web rescue: avoid registering external app-links plugins during startup.
    // Invite links on the web are still read from the current browser URL.
    if (kIsWeb) {
      try {
        await _handleIncomingInviteLink(Uri.base, source: 'web');
      } catch (_) {}
    }
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


// core/app_data/app_data.dart moved to part file.

class PushNotificationService {
  // Web rescue: push notifications are intentionally disabled in this build.
  // The app must not load Firebase/AppLinks plugins during startup until the
  // web deployment is stable again. Push can be reintroduced later behind
  // platform-specific files and a real Firebase web configuration.
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

  static Future<bool> configureIfPossible() async => false;
  static Future<String?> enableForCurrentDevice() async => null;
  static Future<void> tryRegisterSilently() async {}
  static Future<void> disableForCurrentDevice() async {}
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
    case 'partido': return const Color(0xFF1E63A7);
    case 'entrenamiento': return const Color(0xFF6F4BA4);
    case 'cena': return const Color(0xFFD97706);
    case 'reunion': return const Color(0xFF218A4B);
    case 'torneo': return const Color(0xFFE09B18);
    default: return AppColors.teal;
  }
}

Color eventKindSoftColor(Map<String, dynamic> event) {
  switch (eventKind(event)) {
    case 'partido': return const Color(0xFFE8F1FF);
    case 'entrenamiento': return const Color(0xFFF1EAFE);
    case 'cena': return const Color(0xFFFFF0D9);
    case 'reunion': return const Color(0xFFE7F6EC);
    case 'torneo': return const Color(0xFFFFF5DA);
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
  return TournamentEngineV2.defaultTieBreakers(scoringType, 'liga');
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


String scoringTableContractChip(String type, [dynamic raw]) {
  final model = scoringResultModel(type, raw);
  if (model == 'goals') return 'Tabla por goles';
  if (model == 'sets_games') return 'Tabla por sets/juegos';
  if (model == 'sets_points') return 'Tabla por sets/puntos';
  if (model == 'total_points') return 'Tabla por puntos';
  if (type == 'basketball') return 'Tabla por puntos';
  return 'Tabla adaptada';
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
        'score_model': 'goals',
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
        'score_model': 'sets_games',
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
        'score_model': 'total_points',
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
        'score_model': 'sets_points',
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
        'score_model': 'sets_points',
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
        'score_model': 'games',
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
        'score_model': 'target_points',
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
        'score_model': 'games',
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
        'score_model': 'games',
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
        'score_model': 'manual_points',
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
        'score_model': 'manual_points',
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
bool scoringUsesSetMode(String type, [dynamic raw]) => scoringResultModel(type, raw).startsWith('sets');
int scoringBestOf(String type, [dynamic raw]) => max(1, AppData.intValue(resolvedScoringConfig(type, raw)['best_of'], 3));
String scoringScoreLabel(String type, [dynamic raw]) => AppData.text(resolvedScoringConfig(type, raw)['score_label'], scoringMetricUnit(type, raw));
String scoringSetLabel(String type, [dynamic raw]) => AppData.text(resolvedScoringConfig(type, raw)['set_label'], 'juegos');
String scoringRankingLabel(String type, [dynamic raw]) => AppData.text(resolvedScoringConfig(type, raw)['ranking_label'], 'DIF');

String scoringResultModel(String type, [dynamic raw]) {
  final cfg = resolvedScoringConfig(type, raw);
  final model = AppData.text(cfg['score_model']);
  if (model.isNotEmpty) return model;
  return AppData.text(cfg['result_mode'], 'simple') == 'sets' ? 'sets_points' : 'manual_points';
}

bool scoringUsesGameSetMode(String type, [dynamic raw]) => scoringResultModel(type, raw) == 'sets_games';
bool scoringUsesPointSetMode(String type, [dynamic raw]) => scoringResultModel(type, raw) == 'sets_points';

String scoringTableForLabel(String type, [dynamic raw]) {
  switch (scoringResultModel(type, raw)) {
    case 'goals':
      return 'GF';
    case 'sets_games':
    case 'sets_points':
      return 'SF';
    case 'total_points':
      return 'PF';
    default:
      return '+';
  }
}

String scoringTableAgainstLabel(String type, [dynamic raw]) {
  switch (scoringResultModel(type, raw)) {
    case 'goals':
      return 'GC';
    case 'sets_games':
    case 'sets_points':
      return 'SC';
    case 'total_points':
      return 'PC';
    default:
      return '-';
  }
}

String scoringTableDifferenceLabel(String type, [dynamic raw]) {
  switch (scoringResultModel(type, raw)) {
    case 'goals':
      return 'DG';
    case 'sets_games':
    case 'sets_points':
      return 'DS';
    case 'total_points':
      return 'DP';
    default:
      return 'DIF';
  }
}

String scoringSecondaryForLabel(String type, [dynamic raw]) {
  switch (scoringResultModel(type, raw)) {
    case 'sets_games':
      return 'JF';
    case 'sets_points':
      return 'PF';
    default:
      return '+2';
  }
}

String scoringSecondaryAgainstLabel(String type, [dynamic raw]) {
  switch (scoringResultModel(type, raw)) {
    case 'sets_games':
      return 'JC';
    case 'sets_points':
      return 'PC';
    default:
      return '-2';
  }
}

String scoringSecondaryDifferenceLabel(String type, [dynamic raw]) {
  switch (scoringResultModel(type, raw)) {
    case 'sets_games':
      return 'DJ';
    case 'sets_points':
      return 'DP';
    default:
      return 'DIF2';
  }
}

String scoringResultInputTitle(String type, [dynamic raw]) {
  switch (scoringResultModel(type, raw)) {
    case 'goals':
      return 'Resultado por goles';
    case 'sets_games':
      return 'Resultado por sets y juegos';
    case 'sets_points':
      return 'Resultado por sets y puntos';
    case 'total_points':
      return 'Resultado por puntos totales';
    case 'games':
      return 'Resultado por juegos/partidas';
    default:
      return 'Resultado editable';
  }
}

String scoringResultInputHelp(String type, [dynamic raw]) {
  switch (scoringResultModel(type, raw)) {
    case 'goals':
      return 'Escribe los goles de cada equipo. La tabla calcula puntos, goles a favor, goles en contra y diferencia.';
    case 'sets_games':
      return 'Escribe cada set en una línea: 6-7, 6-4, 6-0. La app calcula Sets 2-1, juegos a favor/en contra y desempates.';
    case 'sets_points':
      return 'Escribe cada set en una línea: 25-21, 22-25, 15-12. La app calcula sets, puntos de set y diferencia.';
    case 'total_points':
      return 'Escribe los puntos anotados por cada equipo. La tabla calcula victorias y diferencia de puntos.';
    case 'games':
      return 'Escribe juegos, partidas o mapas ganados por cada lado.';
    default:
      return 'Marcador flexible. La clasificación usa las reglas configuradas para esta competición.';
  }
}

String scoringCreationHelp(String type, [dynamic raw]) {
  switch (scoringResultModel(type, raw)) {
    case 'goals':
      return 'Fútbol: marcador por goles. Tabla: puntos, GF, GC y DG.';
    case 'sets_games':
      return 'Tenis/Pádel: introduces sets completos. Tabla: victorias, sets, juegos y desempates.';
    case 'sets_points':
      return 'Voleibol/Ping pong: introduces sets completos. Tabla: victorias, sets, puntos y desempates.';
    case 'total_points':
      return 'Basket: marcador por puntos. Tabla: victorias, puntos a favor/en contra y diferencia.';
    default:
      return scoringConfigFullText(type, raw);
  }
}


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
  switch (scoringResultModel(type, cfg)) {
    case 'goals':
      return 'Fútbol real: goles, empate permitido, GF/GC/DG y puntos de liga.';
    case 'sets_games':
      return 'Raqueta: cada set guarda juegos. No se mete solo 2-1; se introducen todos los parciales.';
    case 'sets_points':
      return 'Sets: cada parcial guarda puntos. No hay empate a sets.';
    case 'total_points':
      return 'Basket: puntos totales, sin empate, diferencia de puntos.';
    default:
      if (!scoringAllowDraw(type, cfg)) return 'Validación: el marcador no puede quedar empatado.';
      return 'Validación: permite empate y calcula puntos/diferencia automáticamente.';
  }
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
  switch (scoringResultModel(type, cfg)) {
    case 'goals':
      return 'Goles · GF/GC/DG';
    case 'sets_games':
      return 'Sets + juegos · mejor de ${scoringBestOf(type, cfg)}';
    case 'sets_points':
      return 'Sets + puntos · mejor de ${scoringBestOf(type, cfg)}';
    case 'total_points':
      return 'Puntos totales · diferencia';
    default:
      return 'Victoria ${scoringWinPoints(type, cfg)} · empate ${scoringDrawPoints(type, cfg)} · derrota ${scoringLossPoints(type, cfg)}';
  }
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
    case 'no_shows': return 'no presentados';
    default: return value;
  }
}

String tieBreakerLabelForScoring(String value, String scoringType, [dynamic raw]) {
  switch (value) {
    case 'set_difference':
      return 'diferencia de sets';
    case 'game_difference':
      if (scoringUsesGameSetMode(scoringType, raw)) return 'diferencia de juegos';
      if (scoringUsesPointSetMode(scoringType, raw)) return 'diferencia de puntos de set';
      return tieBreakerLabel(value);
    case 'games_for':
      if (scoringUsesGameSetMode(scoringType, raw)) return 'juegos a favor';
      if (scoringUsesPointSetMode(scoringType, raw)) return 'puntos de set a favor';
      return tieBreakerLabel(value);
    case 'difference':
      if (scoringResultModel(scoringType, raw) == 'goals') return 'diferencia de goles';
      if (scoringResultModel(scoringType, raw) == 'total_points') return 'diferencia de puntos';
      return tieBreakerLabel(value);
    case 'for':
      if (scoringResultModel(scoringType, raw) == 'goals') return 'goles a favor';
      if (scoringResultModel(scoringType, raw) == 'total_points') return 'puntos a favor';
      return tieBreakerLabel(value);
    default:
      return tieBreakerLabel(value);
  }
}

String scoringConfigFullText(String type, [dynamic raw]) {
  final cfg = resolvedScoringConfig(type, raw);
  switch (scoringResultModel(type, cfg)) {
    case 'goals':
      return 'Se registra el marcador en goles. La clasificación usa puntos de liga, goles a favor, goles en contra y diferencia de goles.';
    case 'sets_games':
      return 'Se registra cada set con sus juegos. La app calcula sets ganados, juegos totales y desempates.';
    case 'sets_points':
      return 'Se registra cada set con sus puntos. La app calcula sets ganados, puntos totales y desempates.';
    case 'total_points':
      return 'Se registra el marcador total de puntos. La clasificación usa victorias, puntos a favor/en contra y diferencia.';
    default:
      return 'Marcador directo en ${scoringScoreLabel(type, cfg)}. La clasificación usa victoria ${scoringWinPoints(type, cfg)}, empate ${scoringDrawPoints(type, cfg)} y derrota ${scoringLossPoints(type, cfg)}.';
  }
}

String standingsHeaderForScoring(String type, [dynamic raw]) {
  if (scoringUsesSetMode(type, raw)) return 'PTS · DP · ${scoringSetLabel(type, raw).toUpperCase()}';
  return 'PTS · ${scoringRankingLabel(type, raw)} · PJ';
}

String standingDetailText(TeamStanding standing, String scoringType, [dynamic scoringConfig]) {
  final model = scoringResultModel(scoringType, scoringConfig);
  if (standing.americanoRawScore) {
    final unit = scoringUsesGameSetMode(scoringType, scoringConfig)
        ? 'juegos'
        : scoringUsesPointSetMode(scoringType, scoringConfig)
            ? 'puntos'
            : scoringScoreLabel(scoringType, scoringConfig);
    return '${standing.played} partidos · $unit ${standing.goalsFor}-${standing.goalsAgainst} · victorias ${standing.wins}';
  }
  switch (model) {
    case 'goals':
      return '${standing.wins}G · ${standing.draws}E · ${standing.losses}P · GF ${standing.goalsFor} · GC ${standing.goalsAgainst} · DG ${standing.goalDifference}';
    case 'sets_games':
      return '${standing.wins}G · ${standing.losses}P · sets ${standing.goalsFor}-${standing.goalsAgainst} · juegos ${standing.secondaryFor}-${standing.secondaryAgainst}';
    case 'sets_points':
      return '${standing.wins}G · ${standing.losses}P · sets ${standing.goalsFor}-${standing.goalsAgainst} · puntos ${standing.secondaryFor}-${standing.secondaryAgainst}';
    case 'total_points':
      return '${standing.wins}G · ${standing.losses}P · PF ${standing.goalsFor} · PC ${standing.goalsAgainst} · DP ${standing.goalDifference}';
    default:
      return '${standing.wins}G · ${standing.draws}E · ${standing.losses}P · ${scoringMetricUnit(scoringType, scoringConfig)} ${standing.goalsFor}-${standing.goalsAgainst}';
  }
}

String standingMetricText(TeamStanding standing, String scoringType, [dynamic scoringConfig]) {
  if (scoringUsesSetMode(scoringType, scoringConfig)) {
    return '${scoringTableDifferenceLabel(scoringType, scoringConfig)} ${standing.goalDifference} · ${scoringSecondaryDifferenceLabel(scoringType, scoringConfig)} ${standing.secondaryDifference}';
  }
  return 'PTS · ${scoringRankingLabel(scoringType, scoringConfig)} ${standing.goalDifference}';
}

String matchInputLabel(String type, bool local, [dynamic raw]) {
  final side = local ? 'Local' : 'Visitante';
  switch (scoringResultModel(type, raw)) {
    case 'goals':
      return '$side goles';
    case 'total_points':
      return '$side puntos';
    case 'games':
      return '$side juegos';
    default:
      if (scoringUsesSetMode(type, raw)) return '$side sets';
      return '$side ${scoringScoreLabel(type, raw)}';
  }
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

int matchSetGamesFor(Map<String, dynamic> match, bool local) {
  var total = 0;
  for (final set in matchDetailSets(match)) {
    total += AppData.intValue(set[local ? 'a' : 'b']);
  }
  return total;
}

String matchPrimaryScoreText(Map<String, dynamic> match, String type, [dynamic raw]) {
  final a = AppData.intValue(match['score_a']);
  final b = AppData.intValue(match['score_b']);
  if (scoringUsesSetMode(type, raw)) {
    return 'Sets $a - $b';
  }
  return '$a - $b';
}

String? matchDetailScoreText(Map<String, dynamic> match, String type, [dynamic raw]) {
  if (!scoringUsesSetMode(type, raw)) return null;
  final sets = matchDetailSets(match);
  if (sets.isEmpty) return null;
  final secondaryA = matchSetGamesFor(match, true);
  final secondaryB = matchSetGamesFor(match, false);
  final secondaryLabel = scoringUsesGameSetMode(type, raw) ? 'juegos' : 'puntos';
  return '$secondaryLabel $secondaryA-$secondaryB · ${sets.map((set) => '${set['a']}-${set['b']}').join(' · ')}';
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
  return TournamentEngineV2.defaultTieBreakers(scoringType, AppData.text(tournament['format'], 'liga'));
}

int _compareDesc(int a, int b) => b.compareTo(a);

int _directTieBreakerCompare(TeamStanding a, TeamStanding b, List<Map<String, dynamic>> matches, String scoringType, Map<String, dynamic>? scoringConfig) {
  var aPoints = 0;
  var bPoints = 0;
  var aDiff = 0;
  var bDiff = 0;
  var aFor = 0;
  var bFor = 0;
  var aSecondaryDiff = 0;
  var bSecondaryDiff = 0;
  var aSecondaryFor = 0;
  var bSecondaryFor = 0;
  final setMode = scoringUsesSetMode(scoringType, scoringConfig);
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
    final localSecondaryA = setMode ? matchSetGamesFor(match, true) : 0;
    final localSecondaryB = setMode ? matchSetGamesFor(match, false) : 0;
    final aSecondaryScore = teamA == a.id ? localSecondaryA : localSecondaryB;
    final bSecondaryScore = teamA == a.id ? localSecondaryB : localSecondaryA;
    aFor += aScore;
    bFor += bScore;
    aDiff += aScore - bScore;
    bDiff += bScore - aScore;
    aSecondaryFor += aSecondaryScore;
    bSecondaryFor += bSecondaryScore;
    aSecondaryDiff += aSecondaryScore - bSecondaryScore;
    bSecondaryDiff += bSecondaryScore - aSecondaryScore;
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
  c = _compareDesc(aFor, bFor);
  if (c != 0) return c;
  c = _compareDesc(aSecondaryDiff, bSecondaryDiff);
  if (c != 0) return c;
  return _compareDesc(aSecondaryFor, bSecondaryFor);
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
        c = _compareDesc(a.goalDifference, b.goalDifference);
        break;
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

String standingsOrderTextForScoring(List<String> tieBreakers, String scoringType, [dynamic scoringConfig]) {
  return tieBreakers.map((value) => tieBreakerLabelForScoring(value, scoringType, scoringConfig)).join(' → ');
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
    if (breaker == 'set_difference' && current.goalDifference != previous.goalDifference) return 'Desempate por diferencia de sets: ${previous.goalDifference} vs ${current.goalDifference}.';
    if (breaker == 'game_difference' && current.secondaryDifference != previous.secondaryDifference) return 'Desempate por ${tieBreakerLabel(breaker)}: ${previous.secondaryDifference} vs ${current.secondaryDifference}.';
    if (breaker == 'games_for' && current.secondaryFor != previous.secondaryFor) return 'Desempate por juegos/puntos a favor: ${previous.secondaryFor} vs ${current.secondaryFor}.';
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
      for (final row in [...aRows, ...bRows]) {
        row.americanoRawScore = true;
      }

      final americanoScoreA = setMode ? matchSetGamesFor(match, true) : scoreA;
      final americanoScoreB = setMode ? matchSetGamesFor(match, false) : scoreB;

      for (final row in aRows) {
        row.played++;
        row.goalsFor += americanoScoreA;
        row.goalsAgainst += americanoScoreB;
      }
      for (final row in bRows) {
        row.played++;
        row.goalsFor += americanoScoreB;
        row.goalsAgainst += americanoScoreA;
      }

      if (setMode) {
        for (final row in aRows) {
          row.secondaryFor += scoreA;
          row.secondaryAgainst += scoreB;
        }
        for (final row in bRows) {
          row.secondaryFor += scoreB;
          row.secondaryAgainst += scoreA;
        }
      }

      if (scoreA > scoreB) {
        for (final row in aRows) {
          row.wins++;
          row.points += americanoScoreA;
        }
        for (final row in bRows) {
          row.losses++;
          row.points += americanoScoreB;
        }
      } else if (scoreA < scoreB) {
        for (final row in bRows) {
          row.wins++;
          row.points += americanoScoreB;
        }
        for (final row in aRows) {
          row.losses++;
          row.points += americanoScoreA;
        }
      } else {
        for (final row in aRows) {
          row.draws++;
          row.points += americanoScoreA;
        }
        for (final row in bRows) {
          row.draws++;
          row.points += americanoScoreB;
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
  bool americanoRawScore = false;

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



// features/onboarding/onboarding.dart moved to part file.


// features/auth/auth.dart moved to part file.


// features/groups/groups.dart moved to part file.


// features/agenda/agenda.dart moved to part file.


// features/finances/finances.dart moved to part file.


// features/tournaments/tournaments.dart moved to part file.


// features/profile/profile_members_admin.dart moved to part file.


// core/widgets/shared_widgets.dart moved to part file.

