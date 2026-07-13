part of grupli_app;

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
  String get label => 'Billing desactivado';

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
      message: 'Las compras todavía no están activas.',
    );
  }

  @override
  Future<PremiumPurchaseResult> restorePurchases({
    required String userId,
  }) async {
    return PremiumPurchaseResult.failure(
      providerId: id,
      message: 'No hay compras activas para restaurar todavía.',
    );
  }
}

class GrupliMonetizationBlueprint {
  static const bool adsEnabled = false;
  static const bool adsRespectPremium = true;
  static const bool adsUseRemoteOverride = true;
  static const bool adsSoftLaunch = false;

  static const List<String> mobileBillingRoutes = [
    'iOS: App Store',
    'Android: Google Play',
  ];

  static const List<String> webBillingRoutes = [
    'Web futura: Stripe',
  ];

  static const List<PremiumAdPlacement> adPlacements = [
    PremiumAdPlacement(
      screen: 'Inicio del grupo',
      placement: 'Debajo del hero del grupo',
      behavior: 'Banner nativo muy discreto cuando el usuario ya ha visto el contenido principal.',
    ),
    PremiumAdPlacement(
      screen: 'Inicio del grupo',
      placement: 'Al final de bloques largos',
      behavior: 'Solo como cierre, nunca por encima de acciones importantes.',
    ),
    PremiumAdPlacement(
      screen: 'Agenda',
      placement: 'Después de la lista de próximos eventos',
      behavior: 'No interrumpe crear o editar eventos.',
    ),
    PremiumAdPlacement(
      screen: 'Torneos',
      placement: 'Tras el listado de torneos o resultados',
      behavior: 'Nunca dentro del flujo de crear torneo, registrar marcador o cerrar ronda.',
    ),
    PremiumAdPlacement(
      screen: 'Finanzas',
      placement: 'Después del resumen y al final del historial',
      behavior: 'No aparece dentro de liquidar gastos ni del cálculo de saldos.',
    ),
    PremiumAdPlacement(
      screen: 'Perfil',
      placement: 'En tarjetas informativas o vacíos de contenido',
      behavior: 'Solo como apoyo visual, sin bloquear ajustes ni permisos.',
    ),
  ];

  static const List<String> blockedScreens = [
    'Crear torneo',
    'Registrar resultado',
    'Liquidar gastos',
    'Pantalla de compra',
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

  static const List<String> monetizationRules = [
    'Una sola suscripción por grupo.',
    'Premium quita anuncios en toda la app.',
    'La versión gratis sigue siendo completa.',
    'El backend decide el acceso, no la UI.',
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
    if (normalized == 'inicio del grupo') return 'inicio_grupo';
    if (normalized == 'agenda') return 'agenda';
    if (normalized == 'torneos') return 'torneos';
    if (normalized == 'finanzas') return 'finanzas';
    if (normalized == 'perfil') return 'perfil';
    if (normalized == 'crear torneo') return 'crear_torneo';
    if (normalized == 'registrar resultado') return 'registrar_resultado';
    if (normalized == 'liquidar gastos') return 'liquidar_gastos';
    if (normalized == 'pantalla de compra') return 'compra';
    return normalized.replaceAll(' ', '_');
  }

  static String _screenKeyForLabel(String label) {
    return _normalizeScreenKey(label);
  }

  static String _screenLabelForKey(String key) {
    switch (key) {
      case 'inicio_grupo':
        return 'Inicio del grupo';
      case 'agenda':
        return 'Agenda';
      case 'torneos':
        return 'Torneos';
      case 'finanzas':
        return 'Finanzas';
      case 'perfil':
        return 'Perfil';
      case 'crear_torneo':
        return 'Crear torneo';
      case 'registrar_resultado':
        return 'Registrar resultado';
      case 'liquidar_gastos':
        return 'Liquidar gastos';
      case 'compra':
        return 'Pantalla de compra';
      default:
        return key.replaceAll('_', ' ');
    }
  }
}
