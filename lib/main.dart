library grupli_app;

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;
import 'core/finance/finance_money.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
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

part 'core/theme/app_colors.dart';
part 'core/i18n/i18n.dart';
part 'core/app_data/app_data.dart';
part 'core/premium/group_premium.dart';
part 'core/premium/premium_monetization.dart';
part 'features/onboarding/onboarding.dart';
part 'features/auth/auth.dart';
part 'features/groups/groups.dart';
part 'features/agenda/agenda.dart';
part 'features/finances/finances.dart';
part 'features/tournaments/tournament_engine_v2.dart';
part 'features/tournaments/tournaments_shared.dart';
part 'features/tournaments/tournaments_premium.dart';
part 'features/tournaments/tournaments_creation.dart';
part 'features/tournaments/tournaments_detail.dart';
part 'features/tournaments/tournaments.dart';
part 'features/profile/profile_members_admin.dart';
part 'core/widgets/shared_widgets.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
Locale appLocale = resolveAppLocale(ui.PlatformDispatcher.instance.locale);

@pragma('vm:entry-point')
Future<void> grupliFirebaseMessagingBackgroundHandler(
    RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      if (AppConfig.firebaseConfigured) {
        await Firebase.initializeApp(
            options: PushNotificationService.firebaseOptions);
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
    FirebaseMessaging.onBackgroundMessage(
        grupliFirebaseMessagingBackgroundHandler);
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
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded,
                    color: Color(0xFF087A78), size: 42),
                SizedBox(height: 14),
                Text(
                  appIsEnglish
                      ? 'The connection stumbled'
                      : 'La conexión titubeó',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF12263A)),
                ),
                SizedBox(height: 8),
                Text(
                  appIsEnglish
                      ? 'No worries. Go back, try again and Grupli will pick up the thread.'
                      : 'No pasa nada. Vuelve atrás, inténtalo otra vez y Grupli recuperará el hilo.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6A7A89),
                      height: 1.35),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  };

  await loadStoredAppLocale();
  appLocale = resolveActiveAppLocale(ui.PlatformDispatcher.instance.locale);
  Intl.defaultLocale = appIntlLocale;
  await Future.wait([
    initializeDateFormatting('es_ES'),
    initializeDateFormatting('en_US'),
  ]);

  if (!AppConfig.hasSupabaseRuntimeConfig) {
    runApp(const GrupliConfigurationMissingApp());
    return;
  }

  try {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
      authOptions:
          const FlutterAuthClientOptions(authFlowType: AuthFlowType.pkce),
    );
  } catch (_) {
    runApp(const GrupliStartupErrorApp());
    return;
  }

  runApp(const GrupliApp());
}

class AppConfig {
  static const appVersion = 'v16.38';
  // Realtime ya está acotado por pantalla y con debounce. Lo dejamos activo
  // para que grupo, agenda, finanzas y torneos se refresquen sin depender solo
  // de navegación manual.
  static const enableRealtimeSubscriptions = true;

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
  static const firebaseMessagingSenderId =
      String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  static const firebaseProjectId =
      String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const firebaseVapidKey = String.fromEnvironment('FIREBASE_VAPID_KEY');
  static const osmGeocoderEndpointDefine =
      String.fromEnvironment('OSM_GEOCODER_ENDPOINT');
  static const fallbackOsmGeocoderEndpoint = 'https://photon.komoot.io/api/';

  static String get supabaseUrl => supabaseUrlDefine.trim();
  static String get supabaseAnonKey => supabaseAnonDefine.trim();
  static String get appBaseUrl => appBaseUrlDefine.trim().isNotEmpty
      ? appBaseUrlDefine.trim().replaceFirst(RegExp(r'/+$'), '')
      : fallbackAppBaseUrl;

  static String get osmGeocoderEndpoint =>
      osmGeocoderEndpointDefine.trim().isNotEmpty
          ? osmGeocoderEndpointDefine.trim()
          : fallbackOsmGeocoderEndpoint;

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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline_rounded,
                        color: Color(0xFF087A78), size: 42),
                    SizedBox(height: 14),
                    Text(
                      appIsEnglish
                          ? 'Configuration pending'
                          : 'Configuración pendiente',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF12263A)),
                    ),
                    SizedBox(height: 8),
                    Text(
                      appIsEnglish
                          ? 'The app needs secure environment configuration to start. Check the local .env file or your deployment environment variables.'
                          : 'La app necesita su configuración segura de entorno para arrancar. Revisa el archivo .env local o las variables del entorno de despliegue.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6A7A89),
                          height: 1.35),
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

class GrupliStartupErrorApp extends StatelessWidget {
  const GrupliStartupErrorApp({super.key});

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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sync_problem_rounded,
                        color: Color(0xFF087A78), size: 42),
                    SizedBox(height: 14),
                    Text(
                      appIsEnglish
                          ? 'Grupli could not find the way'
                          : 'Grupli no ha encontrado el camino',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF12263A)),
                    ),
                    SizedBox(height: 8),
                    Text(
                      appIsEnglish
                          ? 'The secure configuration did not respond in time. Refresh the page or reopen the app.'
                          : 'La configuración segura no respondió a tiempo. Actualiza la página o vuelve a abrir la app.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6A7A89),
                          height: 1.35),
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
  const PlaceSuggestion(
      {required this.description,
      this.source = 'OpenStreetMap',
      this.lat,
      this.lon});
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

    final response = await http.get(uri, headers: const {
      'Accept': 'application/json'
    }).timeout(const Duration(seconds: 8));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(appIsEnglish
          ? 'Could not search for the address right now.'
          : 'No se pudo buscar la dirección ahora mismo.');
    }

    final data = jsonDecode(response.body);
    if (data is! Map<String, dynamic>) return const [];
    final features = data['features'];
    if (features is! List) return const [];

    final seen = <String>{};
    final result = <PlaceSuggestion>[];
    for (final raw in features) {
      final feature =
          raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
      final props = feature['properties'] is Map
          ? Map<String, dynamic>.from(feature['properties'])
          : <String, dynamic>{};
      final geometry = feature['geometry'] is Map
          ? Map<String, dynamic>.from(feature['geometry'])
          : <String, dynamic>{};
      final coordinates = geometry['coordinates'];
      final description = _photonDescription(props);
      if (description.isEmpty || seen.contains(description.toLowerCase()))
        continue;
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
      if (street.isNotEmpty && street != name)
        [street, houseNumber].where((x) => x.isNotEmpty).join(' '),
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
      if (!unique.any((x) => x.toLowerCase() == part.toLowerCase()))
        unique.add(part);
    }
    return unique.join(', ');
  }
}

String mapsLaunchUrl(String address) {
  final clean = address.trim();
  if (clean.isEmpty) return '';
  final parsed = Uri.tryParse(clean);
  if (parsed != null && (parsed.scheme == 'http' || parsed.scheme == 'https'))
    return clean;
  return Uri.https(
          'www.google.com', '/maps/search/', {'api': '1', 'query': clean})
      .toString();
}

Future<void> openAddressInGoogleMaps(
    BuildContext context, String address) async {
  final url = mapsLaunchUrl(address);
  if (url.isEmpty) {
    await showToast(
        context,
        appIsEnglish
            ? 'This event has no address.'
            : 'Este evento no tiene dirección.',
        danger: true);
    return;
  }
  final uri = Uri.parse(url);
  try {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      await showToast(
          context,
          appIsEnglish
              ? 'Could not open Google Maps.'
              : 'No se pudo abrir Google Maps.',
          danger: true);
    }
  } catch (e) {
    if (context.mounted)
      await showToast(context, 'No se pudo abrir Google Maps.', danger: true);
  }
}

// core/theme/app_colors.dart moved to part file.

class GrupliApp extends StatefulWidget {
  const GrupliApp({super.key});

  @override
  State<GrupliApp> createState() => _GrupliAppState();
}

class _GrupliAppState extends State<GrupliApp> {
  void _onLocaleChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    appLocaleOverride.addListener(_onLocaleChanged);
  }

  @override
  void dispose() {
    appLocaleOverride.removeListener(_onLocaleChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    appLocale = resolveActiveAppLocale(ui.PlatformDispatcher.instance.locale);
    Intl.defaultLocale = appIntlLocale;
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
        scaffoldBackgroundColor: AppColors.bgShell,
        fontFamily: 'SF Pro Display',
        fontFamilyFallback: const ['Roboto', 'Helvetica Neue', 'Arial'],
        colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.teal, surface: AppColors.surface)
            .copyWith(
          primary: AppColors.teal,
          secondary: AppColors.orange,
          tertiary: AppColors.violet,
          error: AppColors.red,
          surface: AppColors.surface,
          surfaceTint: AppColors.tealSoft,
          outline: AppColors.line,
          outlineVariant: AppColors.lineSoft,
        ),
        visualDensity: VisualDensity.standard,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          iconTheme: IconThemeData(color: AppColors.ink),
          titleTextStyle: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: AppColors.ink,
              letterSpacing: -0.2),
        ),
        cardTheme: CardThemeData(
          color: AppColors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: AppColors.softRadius,
            side: const BorderSide(color: AppColors.lineSoft),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: AppColors.softRadius),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: AppColors.surface,
          modalBackgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.ink,
          contentTextStyle:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.white,
          indicatorColor: AppColors.tealSoft,
          labelTextStyle: MaterialStateProperty.resolveWith((states) {
            final selected = states.contains(MaterialState.selected);
            return TextStyle(
              fontSize: 11.2,
              fontWeight: FontWeight.w900,
              color: selected ? AppColors.ink : AppColors.muted,
              letterSpacing: -.05,
            );
          }),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.teal,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(borderRadius: AppColors.humanRadius),
            textStyle: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.white,
            foregroundColor: AppColors.ink,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
                borderRadius: AppColors.humanRadius,
                side: const BorderSide(color: AppColors.lineSoft)),
            textStyle: const TextStyle(fontWeight: FontWeight.w900),
            elevation: 0,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.ink,
            side: const BorderSide(color: AppColors.line),
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(borderRadius: AppColors.humanRadius),
            textStyle: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.teal,
            textStyle: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        progressIndicatorTheme:
            const ProgressIndicatorThemeData(color: AppColors.teal),
        pageTransitionsTheme: PageTransitionsTheme(
          builders: {
            TargetPlatform.android: ZoomPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.fuchsia: FadeUpwardsPageTransitionsBuilder(),
          },
        ),
        dividerTheme: const DividerThemeData(
            color: AppColors.line, thickness: 1, space: 1),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.surface,
          selectedColor: AppColors.tealSoft,
          side: const BorderSide(color: AppColors.line),
          labelStyle: const TextStyle(
              fontWeight: FontWeight.w800, color: AppColors.ink),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
              fontSize: 31.2,
              fontWeight: FontWeight.w900,
              color: AppColors.ink,
              height: 1.02,
              letterSpacing: -1.05),
          headlineMedium: TextStyle(
              fontSize: 25.6,
              fontWeight: FontWeight.w900,
              color: AppColors.ink,
              height: 1.06,
              letterSpacing: -0.55),
          titleLarge: TextStyle(
              fontSize: 19.5,
              fontWeight: FontWeight.w900,
              color: AppColors.ink,
              letterSpacing: -0.2),
          titleMedium: TextStyle(
              fontSize: 16.5,
              fontWeight: FontWeight.w900,
              color: AppColors.ink,
              height: 1.22),
          bodyLarge:
              TextStyle(fontSize: 16, color: AppColors.ink, height: 1.42),
          bodyMedium: TextStyle(
              fontSize: 14.6,
              color: AppColors.muted,
              height: 1.44,
              fontWeight: FontWeight.w600),
          labelLarge: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          hintStyle: const TextStyle(color: Color(0xFF9AA4B5)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          border: OutlineInputBorder(
              borderRadius: AppColors.humanRadius,
              borderSide: const BorderSide(color: AppColors.line)),
          enabledBorder: OutlineInputBorder(
              borderRadius: AppColors.humanRadius,
              borderSide: const BorderSide(color: AppColors.line)),
          focusedBorder: OutlineInputBorder(
              borderRadius: AppColors.humanRadius,
              borderSide: const BorderSide(color: AppColors.teal, width: 1.6)),
        ),
      ),
      locale: appLocale,
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
  String? _lastHandledInviteCode;
  DateTime? _lastHandledInviteAt;
  bool _recoveringPassword = false;
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
        if (event.event == AuthChangeEvent.passwordRecovery) _recoveringPassword = true;
        if (event.event == AuthChangeEvent.signedOut) _recoveringPassword = false;
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

  Future<void> _handleIncomingInviteLink(Uri uri,
      {required String source}) async {
    final code = InviteLinks.codeFromUri(uri);
    if (code == null || code.length < 4) return;

    final now = DateTime.now();
    if (_lastHandledInviteCode == code &&
        _lastHandledInviteAt != null &&
        now.difference(_lastHandledInviteAt!).inSeconds < 3) {
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
        nav.push(MaterialPageRoute(
            builder: (_) => AuthScreen(register: false, inviteCode: code)));
      } else {
        nav.push(MaterialPageRoute(
            builder: (_) => JoinInviteScreen(inviteCode: code)));
      }
    });
  }

  Future<void> _loadFirstRunState() async {
    try {
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
        unawaited(PushNotificationService.tryRegisterSilently());
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _session = Supabase.instance.client.auth.currentSession;
        _showOnboarding = _session == null;
        _ready = true;
      });
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
        ? const Scaffold(
            backgroundColor: AppColors.white,
            body: CenterLoader(label: 'Cargando...'))
        : _session == null
            ? (_showOnboarding
                ? OnboardingScreen(onFinish: _finishOnboarding)
                : WelcomeScreen(onShowIntro: _restartOnboarding))
            : _recoveringPassword
                ? PasswordRecoveryScreen(onSaved: () {
                    if (mounted) setState(() => _recoveringPassword = false);
                  })
                : const AuthedShell();
    return AppSurface(child: child);
  }
}

class AppSurface extends StatelessWidget {
  final Widget child;
  const AppSurface({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wideLayout = constraints.maxWidth > 700;
        return Container(
          color: AppColors.bgShell,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Container(
                margin: EdgeInsets.symmetric(
                  horizontal: wideLayout ? 16 : 0,
                  vertical: wideLayout ? 16 : 0,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: wideLayout ? BorderRadius.circular(30) : BorderRadius.zero,
                  border: wideLayout ? Border.all(color: AppColors.lineSoft) : null,
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.softShadow,
                      blurRadius: 26,
                      offset: Offset(0, 10),
                    )
                  ],
                ),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}

class GrupliAmbientPainter extends CustomPainter {
  const GrupliAmbientPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    paint.color = AppColors.tealSoft.withOpacity(.42);
    canvas.drawOval(
        Rect.fromLTWH(-size.width * .24, size.height * .06, size.width * .56,
            size.height * .22),
        paint);
    paint.color = AppColors.orangeSoft.withOpacity(.52);
    canvas.drawOval(
        Rect.fromLTWH(size.width * .62, size.height * .12, size.width * .34,
            size.height * .16),
        paint);
    paint.color = AppColors.violetSoft.withOpacity(.34);
    canvas.drawOval(
        Rect.fromLTWH(size.width * .18, size.height * .76, size.width * .56,
            size.height * .14),
        paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DirectPage extends StatelessWidget {
  final Widget child;
  final Widget? bottomNavigationBar;
  final EdgeInsetsGeometry padding;
  final bool scroll;
  const DirectPage(
      {super.key,
      required this.child,
      this.bottomNavigationBar,
      this.padding = const EdgeInsets.fromLTRB(22, 22, 22, 26),
      this.scroll = true});

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
      bottomNavigationBar: bottomNavigationBar == null
          ? null
          : SafeArea(top: false, child: bottomNavigationBar!),
    );
  }
}

// core/app_data/app_data.dart moved to part file.

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
      if (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.iOS ||
              defaultTargetPlatform == TargetPlatform.macOS)) {
        try {
          await FirebaseMessaging.instance
              .setForegroundNotificationPresentationOptions(
            alert: true,
            badge: true,
            sound: true,
          );
        } catch (_) {
          // Si el canal nativo aún no está listo, la app sigue funcionando.
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
        message: message.notification?.title ??
            AppData.text(message.data['title'], 'Push recibido'),
        metadata: message.data,
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen(handleMessageTap);
    FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      await AppData.registerDeviceToken(token, platformLabel);
      await AppData.logQualityEvent('push_token_refresh',
          screen: 'push', message: 'Token actualizado');
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
        MaterialPageRoute(
            builder: (_) => GroupShell(groupId: groupId, initialTab: tab)),
        (route) => route.isFirst,
      );
    } else {
      await nav.push(MaterialPageRoute(
          builder: (_) => NotificationsScreen(onChanged: () {})));
    }
  }

  static Future<String?> enableForCurrentDevice() async {
    final ready = await configureIfPossible();
    if (!ready) return null;
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(
        alert: true, badge: true, sound: true);
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      await AppData.logQualityEvent('push_permission_denied',
          screen: 'push', message: 'Permiso denegado');
      return null;
    }
    final token = await messaging.getToken(
        vapidKey: kIsWeb && AppConfig.firebaseVapidKey.trim().isNotEmpty
            ? AppConfig.firebaseVapidKey.trim()
            : null);
    if (token != null && token.trim().isNotEmpty) {
      await AppData.registerDeviceToken(token, platformLabel);
      await AppData.updateNotificationSettings({'push_enabled': true});
      await AppData.logQualityEvent('push_token_registered',
          screen: 'push',
          message: 'Token registrado',
          metadata: {'platform': platformLabel});
    }
    return token;
  }

  static Future<void> tryRegisterSilently() async {
    try {
      final ready = await configureIfPossible();
      if (!ready) return;
      final settings =
          await FirebaseMessaging.instance.getNotificationSettings();
      if (settings.authorizationStatus == AuthorizationStatus.denied ||
          settings.authorizationStatus == AuthorizationStatus.notDetermined)
        return;
      final token = await FirebaseMessaging.instance.getToken(
          vapidKey: kIsWeb && AppConfig.firebaseVapidKey.trim().isNotEmpty
              ? AppConfig.firebaseVapidKey.trim()
              : null);
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
      final token = await FirebaseMessaging.instance.getToken(
          vapidKey: kIsWeb && AppConfig.firebaseVapidKey.trim().isNotEmpty
              ? AppConfig.firebaseVapidKey.trim()
              : null);
      if (token != null && token.trim().isNotEmpty) {
        await AppData.disableCurrentDeviceToken(token);
      }
    } catch (_) {}
  }
}

String dateLabel(DateTime date) {
  return DateFormat('dd/MM · HH:mm', appDateLocale).format(date.toLocal());
}

String _cap(String value) {
  if (value.trim().isEmpty) return value;
  return value.substring(0, 1).toUpperCase() + value.substring(1);
}

String monthTitle(DateTime date) =>
    _cap(DateFormat('MMMM yyyy', appDateLocale).format(date));
String longDay(DateTime date) =>
    _cap(DateFormat('EEEE dd MMMM', appDateLocale).format(date));
String longDateTime(DateTime date) =>
    _cap(DateFormat('EEEE dd MMMM \u00B7 HH:mm', appDateLocale).format(date));
String shortWeekday(DateTime date) =>
    _cap(DateFormat('EEE', appDateLocale).format(date).replaceAll('.', ''));

String money(double value) {
  final formatted = NumberFormat.currency(
          locale: appIntlLocale, symbol: '\u20AC', decimalDigits: 2)
      .format(value.abs());
  return value < 0 ? '-$formatted' : formatted;
}

String newLocalUuid() {
  final random = Random.secure();
  String hex(int length) =>
      List.generate(length, (_) => random.nextInt(16).toRadixString(16)).join();
  return '${hex(8)}-${hex(4)}-4${hex(3)}-${(8 + random.nextInt(4)).toRadixString(16)}${hex(3)}-${hex(12)}';
}

String eventKind(Map<String, dynamic> event) {
  final explicit = AppData.text(event['kind']).toLowerCase();
  final title = AppData.text(event['title']).toLowerCase();
  final notes = AppData.text(event['notes']).toLowerCase();
  final joined = '$explicit $title $notes';

  // Importante: los partidos creados desde Torneos/Ligas deben verse como evento especial,
  // no como una quedada normal ni como un partido genérico de fútbol/pádel.
  if (joined.contains('partido de torneo') ||
      joined.contains('partido de liga') ||
      joined.contains('torneo') ||
      joined.contains('liga') ||
      joined.contains('copa') ||
      joined.contains('americano') ||
      joined.contains('eliminatoria')) {
    return 'torneo';
  }

  if (joined.contains('partido') ||
      joined.contains('fútbol') ||
      joined.contains('futbol') ||
      joined.contains('pádel') ||
      joined.contains('padel') ||
      joined.contains('tenis')) return 'partido';
  if (joined.contains('entrenamiento') ||
      joined.contains('entreno') ||
      joined.contains('gym')) return 'entrenamiento';
  if (joined.contains('cena') ||
      joined.contains('comida') ||
      joined.contains('bar') ||
      joined.contains('restaurante')) return 'cena';
  if (joined.contains('reunión') ||
      joined.contains('reunion') ||
      joined.contains('meeting')) return 'reunion';
  return 'quedada';
}

bool eventIsTournamentEvent(Map<String, dynamic> event) =>
    eventKind(event) == 'torneo';

Color agendaDayAccentColor(List<Map<String, dynamic>> events) {
  // Para días con torneos usamos teal como color estructural. El dorado queda solo
  // para puntos, chips e iconos pequeños, evitando una Agenda demasiado amarilla.
  if (events.any(eventIsTournamentEvent)) return AppColors.teal;
  return events.isNotEmpty ? eventKindColor(events.first) : AppColors.teal;
}

Color agendaDaySoftColor(List<Map<String, dynamic>> events) {
  if (events.any(eventIsTournamentEvent)) return AppColors.surface;
  return events.isNotEmpty
      ? eventKindSoftColor(events.first)
      : AppColors.tealSoft;
}

List<Map<String, dynamic>> eventsOnSameDay(
    List<Map<String, dynamic>> events, Map<String, dynamic>? anchor) {
  if (anchor == null) return const <Map<String, dynamic>>[];
  final anchorDate =
      DateTime.tryParse(AppData.text(anchor['starts_at']))?.toLocal();
  if (anchorDate == null) return [anchor];
  final result = events.where((event) {
    final date = DateTime.tryParse(AppData.text(event['starts_at']))?.toLocal();
    return date != null && sameDay(date, anchorDate);
  }).toList();
  result.sort((a, b) {
    final da = DateTime.tryParse(AppData.text(a['starts_at'])) ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final db = DateTime.tryParse(AppData.text(b['starts_at'])) ??
        DateTime.fromMillisecondsSinceEpoch(0);
    return da.compareTo(db);
  });
  return result;
}

bool eventIsRoutine(Map<String, dynamic> event) {
  if (AppData.text(event['event_series_id']).isNotEmpty) return true;
  final notes = AppData.text(event['notes']).toLowerCase();
  final title = AppData.text(event['title']).toLowerCase();
  return notes.contains('rutina:') ||
      title.contains('semanal') ||
      title.contains('mensual');
}

String eventRoutineBadge(Map<String, dynamic> event) {
  final frequency = AppData.text(event['recurrence_frequency']);
  if (frequency == 'weekly') return appIsEnglish ? 'Every week' : 'Cada semana';
  if (frequency == 'biweekly')
    return appIsEnglish ? 'Every 2 weeks' : 'Cada 2 semanas';
  if (frequency == 'monthly') return appIsEnglish ? 'Every month' : 'Cada mes';
  final notes = AppData.text(event['notes']);
  final match =
      RegExp(r'Rutina:\s*([^·\\n]+)', caseSensitive: false).firstMatch(notes);
  if (match != null)
    return _cap(
        match.group(1)?.trim() ?? (appIsEnglish ? 'routine' : 'rutina'));
  return appIsEnglish ? 'Routine' : 'Rutina';
}

String eventKindLabel(Map<String, dynamic> event) {
  switch (eventKind(event)) {
    case 'partido':
      return appIsEnglish ? 'Match' : 'Partido';
    case 'entrenamiento':
      return appIsEnglish ? 'Training' : 'Entrenamiento';
    case 'cena':
      return appIsEnglish ? 'Dinner' : 'Cena';
    case 'reunion':
      return appIsEnglish ? 'Meeting' : 'Reunión';
    case 'torneo':
      return appIsEnglish ? 'Tournament' : 'Torneo';
    default:
      return appIsEnglish ? 'Meetup' : 'Quedada';
  }
}

IconData eventKindIcon(Map<String, dynamic> event) {
  switch (eventKind(event)) {
    case 'partido':
      return Icons.sports_soccer_rounded;
    case 'entrenamiento':
      return Icons.fitness_center_rounded;
    case 'cena':
      return Icons.restaurant_rounded;
    case 'reunion':
      return Icons.forum_rounded;
    case 'torneo':
      return Icons.emoji_events_rounded;
    default:
      return Icons.groups_rounded;
  }
}

Color eventKindColor(Map<String, dynamic> event) {
  switch (eventKind(event)) {
    case 'partido':
      return const Color(0xFF1E63A7);
    case 'entrenamiento':
      return const Color(0xFF6F4BA4);
    case 'cena':
      return const Color(0xFFD97706);
    case 'reunion':
      return const Color(0xFF218A4B);
    case 'torneo':
      return const Color(0xFFE09B18);
    default:
      return AppColors.teal;
  }
}

Color eventKindSoftColor(Map<String, dynamic> event) {
  switch (eventKind(event)) {
    case 'partido':
      return const Color(0xFFE8F1FF);
    case 'entrenamiento':
      return const Color(0xFFF1EAFE);
    case 'cena':
      return const Color(0xFFFFF0D9);
    case 'reunion':
      return const Color(0xFFE7F6EC);
    case 'torneo':
      return const Color(0xFFFFF5DA);
    default:
      return AppColors.tealSoft;
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
    if (item['user_id']?.toString() == userId)
      return item['status']?.toString() ?? 'pending';
  }
  return 'pending';
}

bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
String calendarDayKey(DateTime day) =>
    '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

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
  if (clean == 'deporte' ||
      clean == 'amigos' ||
      clean == 'viaje' ||
      clean == 'cartas' ||
      clean == 'otro') return clean;
  return 'otro';
}

String groupTypeLabel(String value) {
  switch (groupTypeValue(value)) {
    case 'deporte':
      return 'Deporte';
    case 'amigos':
      return 'Amigos';
    case 'viaje':
      return 'Viaje';
    case 'cartas':
      return 'Cartas';
    default:
      return 'Otro';
  }
}

IconData groupTypeIcon(String value) {
  switch (groupTypeValue(value)) {
    case 'deporte':
      return Icons.sports_tennis_rounded;
    case 'amigos':
      return Icons.groups_2_rounded;
    case 'viaje':
      return Icons.flight_takeoff_rounded;
    case 'cartas':
      return Icons.style_rounded;
    default:
      return Icons.auto_awesome_rounded;
  }
}

String groupTypeDefaultDescription(String value) {
  switch (groupTypeValue(value)) {
    case 'deporte':
      return appIsEnglish
          ? 'Matches, attendance, expenses and tournaments.'
          : 'Partidos, asistencia, gastos y torneos del grupo.';
    case 'amigos':
      return appIsEnglish
          ? 'Plans, meetups and shared expenses among friends.'
          : 'Planes, quedadas y gastos compartidos entre amigos.';
    case 'viaje':
      return appIsEnglish
          ? 'Trip expenses, plans and organization.'
          : 'Gastos, planes y organización del viaje.';
    case 'cartas':
      return appIsEnglish
          ? 'Matches, expenses and leagues for the group.'
          : 'Partidas, gastos y ligas para el grupo.';
    default:
      return appIsEnglish
          ? 'Plans, expenses and tournaments for the group.'
          : 'Planes, gastos y torneos del grupo.';
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

Map<String, dynamic>? memberByUserId(
    List<Map<String, dynamic>> members, String userId) {
  for (final member in members) {
    if (member['user_id']?.toString() == userId) return member;
  }
  return null;
}

String financeMemberAvatarUrl(
    String userId, List<Map<String, dynamic>> members) {
  final member = memberByUserId(members, userId);
  if (member == null) return '';
  return memberAvatarUrl(member);
}

String initialsFor(String name) {
  final words =
      name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) return '?';
  if (words.length == 1) return words.first.substring(0, 1).toUpperCase();
  return '${words.first.substring(0, 1)}${words.last.substring(0, 1)}'
      .toUpperCase();
}

String attendanceLabel(String status) {
  switch (status) {
    case 'yes':
      return 'Va';
    case 'maybe':
      return 'Duda';
    case 'no':
      return 'No va';
    default:
      return 'Sin responder';
  }
}

Color attendanceColor(String status) {
  switch (status) {
    case 'yes':
      return AppColors.green;
    case 'maybe':
      return AppColors.amber;
    case 'no':
      return AppColors.red;
    default:
      return AppColors.muted;
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
    case 'draft':…12293 tokens truncated….map(
          (e) => {'a': AppData.intValue(e['a']), 'b': AppData.intValue(e['b'])})
      .toList();
}

int matchSetGamesFor(Map<String, dynamic> match, bool local) {
  var total = 0;
  for (final set in matchDetailSets(match)) {
    total += AppData.intValue(set[local ? 'a' : 'b']);
  }
  return total;
}

String matchPrimaryScoreText(Map<String, dynamic> match, String type,
    [dynamic raw]) {
  final a = AppData.intValue(match['score_a']);
  final b = AppData.intValue(match['score_b']);
  if (scoringUsesSetMode(type, raw) && matchDetailSets(match).isNotEmpty) {
    return 'Sets $a - $b';
  }
  return '$a - $b';
}

String? matchDetailScoreText(Map<String, dynamic> match, String type,
    [dynamic raw]) {
  if (!scoringUsesSetMode(type, raw)) return null;
  final sets = matchDetailSets(match);
  if (sets.isEmpty) return null;
  final secondaryA = matchSetGamesFor(match, true);
  final secondaryB = matchSetGamesFor(match, false);
  final secondaryLabel =
      scoringUsesGameSetMode(type, raw) ? 'juegos' : 'puntos';
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
  return status == 'played' ||
      status == 'bye' ||
      status == 'walkover' ||
      status == 'no_show';
}

bool eliminationHasThirdPlace(List<Map<String, dynamic>> matches) {
  return matches.any((m) {
    final details = AppData.asMap(m['result_details']);
    return AppData.text(details['stage']) == 'third_place' ||
        AppData.text(m['round_name']).toLowerCase().contains('tercer');
  });
}

bool canGenerateEliminationNextRound(List<Map<String, dynamic>> matches) {
  final normal = matches
      .where((m) =>
          AppData.text(AppData.asMap(m['result_details'])['stage']) !=
          'third_place')
      .toList();
  if (normal.isEmpty) return false;
  final latestRound = normal.fold<int>(
      0, (value, m) => max(value, AppData.intValue(m['round'])));
  final latest =
      normal.where((m) => AppData.intValue(m['round']) == latestRound).toList();
  if (latest.length <= 1) return false;
  return latest.every(eliminationMatchClosed);
}

bool canCreateEliminationThirdPlace(List<Map<String, dynamic>> matches) {
  if (eliminationHasThirdPlace(matches)) return false;
  final normal = matches
      .where((m) =>
          AppData.text(AppData.asMap(m['result_details'])['stage']) !=
          'third_place')
      .toList();
  final rounds =
      normal.map((m) => AppData.intValue(m['round'])).toSet().toList()..sort();
  for (final round in rounds.reversed) {
    final roundMatches =
        normal.where((m) => AppData.intValue(m['round']) == round).toList();
    if (roundMatches.length == 2)
      return roundMatches.every(eliminationMatchClosed);
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
  final teams =
      value.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  teams.sort((a, b) {
    final seedCompare = AppData.intValue(a['seed'], 999999)
        .compareTo(AppData.intValue(b['seed'], 999999));
    if (seedCompare != 0) return seedCompare;
    return AppData.text(a['name'])
        .toLowerCase()
        .compareTo(AppData.text(b['name']).toLowerCase());
  });
  return teams;
}

List<Map<String, dynamic>> tournamentMatches(Map<String, dynamic> tournament) {
  final value = tournament['matches'];
  if (value is! List) return [];
  final matches =
      value.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  matches.sort((a, b) {
    final roundCompare =
        AppData.intValue(a['round']).compareTo(AppData.intValue(b['round']));
    if (roundCompare != 0) return roundCompare;
    final orderCompare = AppData.intValue(a['order_index'])
        .compareTo(AppData.intValue(b['order_index']));
    if (orderCompare != 0) return orderCompare;
    final dateCompare = AppData.text(a['scheduled_at'])
        .compareTo(AppData.text(b['scheduled_at']));
    if (dateCompare != 0) return dateCompare;
    return AppData.text(a['created_at'])
        .compareTo(AppData.text(b['created_at']));
  });
  return matches;
}

String teamName(String? id, Map<String, String> names) {
  if (id == null || id.isEmpty || id == 'null') return 'Pendiente';
  return names[id] ?? 'Participante';
}

Map<String, String> teamNameMap(List<Map<String, dynamic>> teams) {
  return {
    for (final team in teams)
      team['id'].toString(): AppData.text(team['name'], 'Participante')
  };
}

Map<String, dynamic> matchResultDetails(Map<String, dynamic> match) {
  final raw = match['result_details'];
  if (raw is Map) return Map<String, dynamic>.from(raw);
  return <String, dynamic>{};
}

List<Map<String, dynamic>> matchResultHistory(Map<String, dynamic> match) {
  final history = matchResultDetails(match)['history'];
  if (history is List) {
    return history
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
  return <Map<String, dynamic>>[];
}

List<Map<String, dynamic>> matchHistoryWithEntry(
    Map<String, dynamic> current, String action, String note) {
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
  if (status == 'played' || status == 'no_show' || status == 'walkover')
    return true;
  return AppData.text(match['winner_team_id']).isNotEmpty &&
      AppData.text(match['team_a']).isNotEmpty &&
      AppData.text(match['team_b']).isNotEmpty &&
      status != 'cancelled' &&
      status != 'postponed' &&
      status != 'bye';
}

String matchSpecialResultText(
    Map<String, dynamic> match, Map<String, String> names) {
  final details = matchResultDetails(match);
  final special = AppData.text(details['special_result']);
  if (special.isEmpty) return '';
  final winner = names[AppData.text(match['winner_team_id'])] ?? 'Ganador';
  final loser = names[AppData.text(details['loser_team_id'])] ??
      names[AppData.text(details['no_show_team_id'])] ??
      'Rival';
  if (special == 'no_show')
    return appIsEnglish
        ? '$loser did not show up · $winner wins'
        : '$loser no se presentó · gana $winner';
  if (special == 'walkover')
    return appIsEnglish
        ? 'Administrative win for $winner'
        : 'Victoria administrativa para $winner';
  return AppData.text(details['label'], special);
}

List<String> tournamentTieBreakers(
    Map<String, dynamic> tournament, String scoringType) {
  final raw = tournament['tie_breakers'];
  if (raw is List) {
    final values =
        raw.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList();
    if (values.isNotEmpty) return values;
  }
  return TournamentEngineV2.defaultTieBreakers(
      scoringType, AppData.text(tournament['format'], 'liga'));
}

int _compareDesc(int a, int b) => b.compareTo(a);

int _directTieBreakerCompare(
    TeamStanding a,
    TeamStanding b,
    List<Map<String, dynamic>> matches,
    String scoringType,
    Map<String, dynamic>? scoringConfig) {
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
    final sameDuel =
        (teamA == a.id && teamB == b.id) || (teamA == b.id && teamB == a.id);
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

String standingsOrderTextForScoring(
    List<String> tieBreakers, String scoringType,
    [dynamic scoringConfig]) {
  return tieBreakers
      .map((value) =>
          tieBreakerLabelForScoring(value, scoringType, scoringConfig))
      .join(' → ');
}

String standingRankReason(
    int index,
    List<TeamStanding> standings,
    List<String> tieBreakers,
    String scoringType,
    Map<String, dynamic>? scoringConfig) {
  final current = standings[index];
  final diffLabel = scoringTableDifferenceLabel(scoringType, scoringConfig);
  final diffValue = current.goalDifference >= 0
      ? '+${current.goalDifference}'
      : '${current.goalDifference}';
  if (index == 0) {
    if (current.americanoRawScore) {
      return appIsEnglish
          ? 'Leads the individual ranking with ${current.points} accumulated pts and ${current.wins} wins.'
          : 'Lidera el ranking individual con ${current.points} pts acumulados y ${current.wins} victorias.';
    }
    return appIsEnglish
        ? 'Leads with ${current.points} pts · ${current.wins} wins · $diffLabel $diffValue.'
        : 'Lidera con ${current.points} pts · ${current.wins} victorias · $diffLabel $diffValue.';
  }
  final previous = standings[index - 1];
  if (current.points != previous.points) {
    return appIsEnglish
        ? '${previous.name} is ahead on points (${previous.points} vs ${current.points}).'
        : '${previous.name} está por delante por puntos (${previous.points} vs ${current.points}).';
  }
  for (final breaker in tieBreakers) {
    if (breaker == 'points') continue;
    if (breaker == 'wins' && current.wins != previous.wins)
      return appIsEnglish
          ? 'Tiebreak by wins: ${previous.wins} vs ${current.wins}.'
          : 'Desempate por victorias: ${previous.wins} vs ${current.wins}.';
    if ((breaker == 'difference' || breaker == 'set_difference') &&
        current.goalDifference != previous.goalDifference) {
      return appIsEnglish
          ? 'Tiebreak by ${tieBreakerLabelForScoring(breaker, scoringType, scoringConfig)}: ${previous.goalDifference} vs ${current.goalDifference}.'
          : 'Desempate por ${tieBreakerLabelForScoring(breaker, scoringType, scoringConfig)}: ${previous.goalDifference} vs ${current.goalDifference}.';
    }
    if (breaker == 'for' && current.goalsFor != previous.goalsFor) {
      return appIsEnglish
          ? 'Tiebreak by ${tieBreakerLabelForScoring(breaker, scoringType, scoringConfig)}: ${previous.goalsFor} vs ${current.goalsFor}.'
          : 'Desempate por ${tieBreakerLabelForScoring(breaker, scoringType, scoringConfig)}: ${previous.goalsFor} vs ${current.goalsFor}.';
    }
    if (breaker == 'game_difference' &&
        current.secondaryDifference != previous.secondaryDifference) {
      return appIsEnglish
          ? 'Tiebreak by ${tieBreakerLabelForScoring(breaker, scoringType, scoringConfig)}: ${previous.secondaryDifference} vs ${current.secondaryDifference}.'
          : 'Desempate por ${tieBreakerLabelForScoring(breaker, scoringType, scoringConfig)}: ${previous.secondaryDifference} vs ${current.secondaryDifference}.';
    }
    if (breaker == 'games_for' &&
        current.secondaryFor != previous.secondaryFor) {
      return appIsEnglish
          ? 'Tiebreak by ${tieBreakerLabelForScoring(breaker, scoringType, scoringConfig)}: ${previous.secondaryFor} vs ${current.secondaryFor}.'
          : 'Desempate por ${tieBreakerLabelForScoring(breaker, scoringType, scoringConfig)}: ${previous.secondaryFor} vs ${current.secondaryFor}.';
    }
    if (breaker == 'direct')
      return appIsEnglish
          ? 'Same score: head-to-head is checked before moving to difference.'
          : 'Mismo puntaje: se revisa enfrentamiento directo antes de seguir con la diferencia.';
  }
  return appIsEnglish
      ? 'Same score. The next configured criterion or alphabetical order applies.'
      : 'Mismo puntaje. Se aplica el siguiente criterio configurado o el orden alfabético.';
}

String matchHistoryEntryText(Map<String, dynamic> item) {
  final action = AppData.text(item['action'], 'Cambio');
  final note = AppData.text(item['note']);
  final raw = AppData.text(item['at']);
  final dt = DateTime.tryParse(raw)?.toLocal();
  final date =
      dt == null ? '' : DateFormat('d MMM HH:mm', appDateLocale).format(dt);
  return [if (date.isNotEmpty) date, action, if (note.isNotEmpty) note]
      .join(' · ');
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
  final breakers =
      tieBreakers.isEmpty ? defaultTieBreakers(scoringType) : tieBreakers;

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
      final aRows =
          sideA.map((id) => table[id]).whereType<TeamStanding>().toList();
      final bRows =
          sideB.map((id) => table[id]).whereType<TeamStanding>().toList();
      if (aRows.isEmpty || bRows.isEmpty) continue;
      for (final row in [...aRows, ...bRows]) {
        row.americanoRawScore = true;
      }

      final hasSetDetails = matchDetailSets(match).isNotEmpty;
      final hasRoundScoreDetails = details.containsKey('round_score_a') ||
          details.containsKey('round_score_b') ||
          AppData.text(details['score_model']) == 'americano_round';
      final americanoScoreA = hasRoundScoreDetails
          ? AppData.intValue(details['round_score_a'], scoreA)
          : setMode && hasSetDetails
              ? matchSetGamesFor(match, true)
              : scoreA;
      final americanoScoreB = hasRoundScoreDetails
          ? AppData.intValue(details['round_score_b'], scoreB)
          : setMode && hasSetDetails
              ? matchSetGamesFor(match, false)
              : scoreB;

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

      if (setMode && hasSetDetails) {
        for (final row in aRows) {
          row.secondaryFor += scoreA;
          row.secondaryAgainst += scoreB;
        }
        for (final row in bRows) {
          row.secondaryFor += scoreB;
          row.secondaryAgainst += scoreA;
        }
      }

      if (americanoScoreA > americanoScoreB) {
        for (final row in aRows) {
          row.wins++;
          row.points += americanoScoreA;
        }
        for (final row in bRows) {
          row.losses++;
          row.points += americanoScoreB;
        }
      } else if (americanoScoreA < americanoScoreB) {
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
      final loserId = AppData.text(
          details['loser_team_id'], AppData.text(details['no_show_team_id']));
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
  rows.sort((a, b) => compareTeamStandings(
      a, b, matches, breakers, scoringType, scoringConfig));
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
  double get winRate => played <= 0 ? 0 : wins / played;
}

Future<void> showToast(BuildContext context, String message,
    {bool danger = false}) async {
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
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar')),
        FilledButton(
          style: FilledButton.styleFrom(
              backgroundColor: danger ? AppColors.red : AppColors.teal),
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirm),
        ),
      ],
    ),
  );
}

class InviteLinks {
  static String normalizeCode(String value) {
    final clean =
        value.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    return clean.length > 24 ? clean.substring(0, 24) : clean;
  }

  static String joinUrl(String code) =>
      '${AppConfig.appBaseUrl}/join/${normalizeCode(code)}';
  static String appSchemeUrl(String code) =>
      'grupli://join/${normalizeCode(code)}';

  static String? codeFromUri(Uri uri) {
    final segments =
        uri.pathSegments.where((s) => s.trim().isNotEmpty).toList();

    if (uri.scheme.toLowerCase() == 'grupli' &&
        uri.host.toLowerCase() == 'join' &&
        segments.isNotEmpty) {
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
