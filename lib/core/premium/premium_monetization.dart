part of 'package:grupli/main.dart';

enum PremiumBillingChannel {
  disabled,
  appStore,
  playBilling,
  stripeFuture,
}

class PremiumAdPlacement {
  final String screen;
  final String placement;
  final String behavior;
  final bool hiddenByPremium;

  const PremiumAdPlacement({
    required this.screen,
    required this.placement,
    required this.behavior,
    this.hiddenByPremium = true,
  });
}

class PremiumPurchaseResult {
  final bool success;
  final String message;
  final String providerId;
  final GroupPremiumEntitlement? entitlement;
  final String? transactionId;

  const PremiumPurchaseResult({
    required this.success,
    required this.message,
    required this.providerId,
    this.entitlement,
    this.transactionId,
  });

  factory PremiumPurchaseResult.success({
    required String providerId,
    required String message,
    GroupPremiumEntitlement? entitlement,
    String? transactionId,
  }) {
    return PremiumPurchaseResult(
      success: true,
      message: message,
      providerId: providerId,
      entitlement: entitlement,
      transactionId: transactionId,
    );
  }

  factory PremiumPurchaseResult.failure({
    required String providerId,
    required String message,
  }) {
    return PremiumPurchaseResult(
      success: false,
      message: message,
      providerId: providerId,
    );
  }
}

abstract class PremiumBillingProvider {
  const PremiumBillingProvider();

  String get id;
  String get label;
  PremiumBillingChannel get channel;
  bool get isAvailable;
  bool get supportsRestore;

  Future<GroupPremiumEntitlement> resolveEntitlement(Map<String, dynamic> group);

  Future<PremiumPurchaseResult> startCheckout({
    required String groupId,
    required String planId,
  });

  Future<PremiumPurchaseResult> restorePurchases({
    required String userId,
  });
}

class DisabledPremiumBillingProvider extends PremiumBillingProvider {
  const DisabledPremiumBillingProvider();

  @override
  String get id => 'disabled';

  @override
  String get label => appIsEnglish ? 'Billing disabled' : 'Billing desactivado';

  @override
  PremiumBillingChannel get channel => PremiumBillingChannel.disabled;

  @override
  bool get isAvailable => false;

  @override
  bool get supportsRestore => false;

  @override
  Future<GroupPremiumEntitlement> resolveEntitlement(Map<String, dynamic> group) async {
    return GroupPremiumEntitlement.fromGroup(group);
  }

  @override
  Future<PremiumPurchaseResult> startCheckout({
    required String groupId,
    required String planId,
  }) async {
    return PremiumPurchaseResult.failure(
      providerId: id,
      message: appIsEnglish ? 'Purchases are not active yet.' : 'Las compras todavía no están activas.',
    );
  }

  @override
  Future<PremiumPurchaseResult> restorePurchases({
    required String userId,
  }) async {
    return PremiumPurchaseResult.failure(
      providerId: id,
      message: appIsEnglish ? 'There are no active purchases to restore yet.' : 'No hay compras activas para restaurar todavía.',
    );
  }
}

class GrupliMonetizationBlueprint {
  static const bool adsEnabled = false;
  static const bool adsRespectPremium = true;
  static const bool adsUseRemoteOverride = true;
  static const bool adsSoftLaunch = false;

  static List<String> get mobileBillingRoutes => [
    appIsEnglish ? 'iOS: App Store' : 'iOS: App Store',
    appIsEnglish ? 'Android: Google Play' : 'Android: Google Play',
  ];

  static List<String> get webBillingRoutes => [
    appIsEnglish ? 'Future web: Stripe' : 'Web futura: Stripe',
  ];

  static List<PremiumAdPlacement> get adPlacements => [
    PremiumAdPlacement(
      screen: appIsEnglish ? 'Group home' : 'Inicio del grupo',
      placement: appIsEnglish ? 'Below the group hero' : 'Debajo del hero del grupo',
      behavior: appIsEnglish ? 'Very discreet native banner after the user has seen the main content.' : 'Banner nativo muy discreto cuando el usuario ya ha visto el contenido principal.',
    ),
    PremiumAdPlacement(
      screen: appIsEnglish ? 'Group home' : 'Inicio del grupo',
      placement: appIsEnglish ? 'At the end of long sections' : 'Al final de bloques largos',
      behavior: appIsEnglish ? 'Only as a closing element, never above important actions.' : 'Solo como cierre, nunca por encima de acciones importantes.',
    ),
    PremiumAdPlacement(
      screen: appIsEnglish ? 'Agenda' : 'Agenda',
      placement: appIsEnglish ? 'After the upcoming events list' : 'Después de la lista de próximos eventos',
      behavior: appIsEnglish ? 'Does not interrupt creating or editing events.' : 'No interrumpe crear o editar eventos.',
    ),
    PremiumAdPlacement(
      screen: appIsEnglish ? 'Tournaments' : 'Torneos',
      placement: appIsEnglish ? 'After the tournaments or results list' : 'Tras el listado de torneos o resultados',
      behavior: appIsEnglish ? 'Never inside the flow to create a tournament, record a score or close a round.' : 'Nunca dentro del flujo de crear torneo, registrar marcador o cerrar ronda.',
    ),
    PremiumAdPlacement(
      screen: appIsEnglish ? 'Finances' : 'Finanzas',
      placement: appIsEnglish ? 'After the summary and at the end of the history' : 'Después del resumen y al final del historial',
      behavior: appIsEnglish ? 'Does not appear inside expense settlement or balance calculations.' : 'No aparece dentro de liquidar gastos ni del cálculo de saldos.',
    ),
    PremiumAdPlacement(
      screen: appIsEnglish ? 'Profile' : 'Perfil',
      placement: appIsEnglish ? 'In info cards or empty states' : 'En tarjetas informativas o vacíos de contenido',
      behavior: appIsEnglish ? 'Only as visual support, without blocking settings or permissions.' : 'Solo como apoyo visual, sin bloquear ajustes ni permisos.',
    ),
  ];

  static List<String> get blockedScreens => [
    appIsEnglish ? 'Create tournament' : 'Crear torneo',
    appIsEnglish ? 'Record result' : 'Registrar resultado',
    appIsEnglish ? 'Settle expenses' : 'Liquidar gastos',
    appIsEnglish ? 'Purchase screen' : 'Pantalla de compra',
  ];

  static const Map<String, bool> screenAdFlags = {
    'inicio_grupo': true,
    'agenda': true,
    'torneos': true,
    'finanzas': true,
    'perfil': true,
    'compra': false,
    'crear_torneo': false,
    'registrar_resultado': false,
    'liquidar_gastos': false,
  };

  static List<String> get monetizationRules => [
    appIsEnglish ? 'One subscription per group.' : 'Una sola suscripción por grupo.',
    appIsEnglish ? 'Premium removes ads across the whole app.' : 'Premium quita anuncios en toda la app.',
    appIsEnglish ? 'The free version stays fully usable.' : 'La versión gratis sigue siendo completa.',
    appIsEnglish ? 'The backend decides access, not the UI.' : 'El backend decide el acceso, no la UI.',
  ];

  static const PremiumBillingProvider disabledProvider = DisabledPremiumBillingProvider();

  static bool shouldShowAds({
    required String screenKey,
    required bool premiumActive,
    bool remoteOverride = false,
  }) {
    final normalized = _normalizeScreenKey(screenKey);
    final overrideEnabled = adsUseRemoteOverride && remoteOverride;
    if (!adsEnabled && !adsSoftLaunch && !overrideEnabled) return false;
    if (adsRespectPremium && premiumActive) return false;
    if (blockedScreens.contains(screenKey) || blockedScreens.contains(_screenLabelForKey(normalized))) return false;
    return screenAdFlags[normalized] ?? false;
  }

  static List<PremiumAdPlacement> placementsForScreen(String screenKey) {
    final normalized = _normalizeScreenKey(screenKey);
    return adPlacements.where((placement) => _screenKeyForLabel(placement.screen) == normalized).toList(growable: false);
  }

  static String _normalizeScreenKey(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'inicio del grupo' || normalized == 'group home') return 'inicio_grupo';
    if (normalized == 'agenda') return 'agenda';
    if (normalized == 'torneos' || normalized == 'tournaments') return 'torneos';
    if (normalized == 'finanzas' || normalized == 'finances') return 'finanzas';
    if (normalized == 'perfil' || normalized == 'profile') return 'perfil';
    if (normalized == 'crear torneo' || normalized == 'create tournament') return 'crear_torneo';
    if (normalized == 'registrar resultado' || normalized == 'record result') return 'registrar_resultado';
    if (normalized == 'liquidar gastos' || normalized == 'settle expenses') return 'liquidar_gastos';
    if (normalized == 'pantalla de compra' || normalized == 'purchase screen') return 'compra';
    return normalized.replaceAll(' ', '_');
  }

  static String _screenKeyForLabel(String label) {
    return _normalizeScreenKey(label);
  }

  static String _screenLabelForKey(String key) {
    switch (key) {
      case 'inicio_grupo':
        return appIsEnglish ? 'Group home' : 'Inicio del grupo';
      case 'agenda':
        return appIsEnglish ? 'Agenda' : 'Agenda';
      case 'torneos':
        return appIsEnglish ? 'Tournaments' : 'Torneos';
      case 'finanzas':
        return appIsEnglish ? 'Finances' : 'Finanzas';
      case 'perfil':
        return appIsEnglish ? 'Profile' : 'Perfil';
      case 'crear_torneo':
        return appIsEnglish ? 'Create tournament' : 'Crear torneo';
      case 'registrar_resultado':
        return appIsEnglish ? 'Record result' : 'Registrar resultado';
      case 'liquidar_gastos':
        return appIsEnglish ? 'Settle expenses' : 'Liquidar gastos';
      case 'compra':
        return appIsEnglish ? 'Purchase screen' : 'Pantalla de compra';
      default:
        return key.replaceAll('_', ' ');
    }
  }
}
