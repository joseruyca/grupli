part of 'package:grupli/main.dart';

class PremiumFeatureDefinition {
  final String key;
  final String title;
  final String description;
  final IconData icon;
  final bool visibleInPreview;

  const PremiumFeatureDefinition({
    required this.key,
    required this.title,
    required this.description,
    required this.icon,
    this.visibleInPreview = true,
  });
}

class GroupPremiumEntitlement {
  final bool active;
  final String status;
  final DateTime? validUntil;
  final Set<String> enabledFeatures;

  const GroupPremiumEntitlement({
    required this.active,
    required this.status,
    required this.validUntil,
    required this.enabledFeatures,
  });

  factory GroupPremiumEntitlement.fromGroup(Map<String, dynamic> group) {
    final rawStatus = AppData.text(
      group['premium_status'] ?? group['subscription_status'] ?? group['billing_status'],
      'free',
    ).toLowerCase();
    final explicitActive = group['premium_active'] == true || group['is_premium'] == true;
    final untilText = AppData.text(group['premium_until'] ?? group['subscription_until'] ?? group['premium_valid_until']);
    DateTime? until;
    if (untilText.isNotEmpty) {
      until = DateTime.tryParse(untilText)?.toUtc();
    }
    final notExpired = until == null || until.isAfter(DateTime.now().toUtc());
    final activeByStatus = ['active', 'trialing', 'premium'].contains(rawStatus);
    final active = (explicitActive || activeByStatus) && notExpired;

    final features = <String>{};
    final rawFeatures = group['premium_features'] ?? group['entitlements'];
    if (rawFeatures is List) {
      features.addAll(rawFeatures.map((item) => item.toString()));
    } else if (rawFeatures is Map) {
      rawFeatures.forEach((key, value) {
        if (value == true) features.add(key.toString());
      });
    }

    return GroupPremiumEntitlement(
      active: active,
      status: active ? 'active' : rawStatus,
      validUntil: until,
      enabledFeatures: features,
    );
  }

  bool canUse(String featureKey) {
    if (!GrupliPremium.isPremiumFeature(featureKey)) return true;
    return active && (enabledFeatures.isEmpty || enabledFeatures.contains(featureKey));
  }

  String get label => active
      ? (appIsEnglish ? 'Premium active' : 'Premium activo')
      : (appIsEnglish ? 'Free plan' : 'Plan gratis');
}

class GrupliPremium {
  static PremiumBillingProvider get billingProvider => GrupliMonetizationBlueprint.disabledProvider;
  static bool get billingEnabled => billingProvider.isAvailable;
  static const String scope = 'group';
  static const int freeActiveTournamentsPerGroup = 2;
  static const bool largeGroupsAreFree = true;
  static const bool participantLimitsEnabled = false;
  static const bool thirdPlaceIsFree = true;
  static List<String> get mobileBillingRoutes => GrupliMonetizationBlueprint.mobileBillingRoutes;
  static List<String> get webBillingRoutes => GrupliMonetizationBlueprint.webBillingRoutes;
  static List<PremiumAdPlacement> get adPlacements => GrupliMonetizationBlueprint.adPlacements;
  static List<String> get blockedAdPlacements => GrupliMonetizationBlueprint.blockedScreens;
  static List<String> get monetizationRules => GrupliMonetizationBlueprint.monetizationRules;
  static bool get adsEnabled => GrupliMonetizationBlueprint.adsEnabled;
  static bool get adsRespectPremium => GrupliMonetizationBlueprint.adsRespectPremium;
  static bool get adsSoftLaunch => GrupliMonetizationBlueprint.adsSoftLaunch;

  static bool shouldShowAds({
    required String screenKey,
    required bool premiumActive,
    bool remoteOverride = false,
  }) {
    return GrupliMonetizationBlueprint.shouldShowAds(
      screenKey: screenKey,
      premiumActive: premiumActive,
      remoteOverride: remoteOverride,
    );
  }

  static List<PremiumAdPlacement> placementsForScreen(String screenKey) {
    return GrupliMonetizationBlueprint.placementsForScreen(screenKey);
  }

  static List<PremiumFeatureDefinition> get features => [
    PremiumFeatureDefinition(
      key: 'unlimited_active_tournaments',
      title: appIsEnglish ? 'Unlimited active tournaments' : 'Torneos activos ilimitados',
      description: appIsEnglish ? 'For groups running several competitions at the same time.' : 'Para grupos que organizan varias competiciones a la vez.',
      icon: Icons.all_inclusive_rounded,
    ),
    PremiumFeatureDefinition(
      key: 'advanced_americano',
      title: appIsEnglish ? 'Advanced americano' : 'Americano avanzado',
      description: appIsEnglish ? 'Smart rotations, balanced breaks and fewer repeats.' : 'Rotaciones inteligentes, descansos equilibrados y menos repeticiones.',
      icon: Icons.shuffle_rounded,
    ),
    PremiumFeatureDefinition(
      key: 'smart_multi_courts',
      title: appIsEnglish ? 'Smart multiple courts' : 'Múltiples pistas inteligentes',
      description: appIsEnglish ? 'Distribute matches across courts, tables or fields automatically.' : 'Reparte partidos por pista, mesa o campo de forma automática.',
      icon: Icons.grid_view_rounded,
    ),
    PremiumFeatureDefinition(
      key: 'advanced_calendar',
      title: appIsEnglish ? 'Advanced auto calendar' : 'Calendario automático avanzado',
      description: appIsEnglish ? 'Generates rounds, detects conflicts and reshuffles dates.' : 'Genera jornadas, detecta conflictos y reorganiza fechas.',
      icon: Icons.auto_awesome_rounded,
    ),
    PremiumFeatureDefinition(
      key: 'move_matchdays',
      title: 'Mover jornadas completas',
      description: 'Cambia una jornada entera sin editar partido por partido.',
      icon: Icons.edit_calendar_rounded,
    ),
    PremiumFeatureDefinition(
      key: 'advanced_stats',
      title: 'Estadísticas avanzadas',
      description: 'Rachas, evolución, comparativas e historial de rendimiento.',
      icon: Icons.insights_rounded,
    ),
    PremiumFeatureDefinition(
      key: 'custom_tiebreakers',
      title: 'Desempates configurables',
      description: 'Cambia el orden de desempates según las reglas del grupo.',
      icon: Icons.rule_rounded,
    ),
    PremiumFeatureDefinition(
      key: 'exports',
      title: 'Exportar clasificación',
      description: 'Prepara PDF, imagen o archivo para compartir fuera de Grupli.',
      icon: Icons.ios_share_rounded,
    ),
    PremiumFeatureDefinition(
      key: 'finance_insights',
      title: appIsEnglish ? 'Advanced finances' : 'Finanzas avanzadas',
      description: appIsEnglish ? 'Deeper analysis, expense context and a faster view of the balance.' : 'Análisis más profundo, contexto de gastos y lectura rápida del balance.',
      icon: Icons.insights_rounded,
    ),
    PremiumFeatureDefinition(
      key: 'ad_free',
      title: appIsEnglish ? 'No ads' : 'Sin anuncios',
      description: appIsEnglish ? 'Remove ads from the whole app for a cleaner experience.' : 'Quita la publicidad de toda la app para una experiencia más limpia.',
      icon: Icons.do_not_disturb_rounded,
    ),
    PremiumFeatureDefinition(
      key: 'beautiful_share',
      title: 'Compartir resumen bonito',
      description: 'Crea una imagen clara para WhatsApp, Instagram o el grupo.',
      icon: Icons.auto_awesome_motion_rounded,
    ),
    PremiumFeatureDefinition(
      key: 'duplicate_tournaments',
      title: 'Duplicar torneo',
      description: 'Repite una liga o torneo con la misma estructura.',
      icon: Icons.copy_rounded,
    ),
    PremiumFeatureDefinition(
      key: 'saved_templates',
      title: 'Plantillas guardadas',
      description: 'Guarda formatos habituales para crearlos más rápido.',
      icon: Icons.bookmark_rounded,
    ),
    PremiumFeatureDefinition(
      key: 'seeding',
      title: 'Cabezas de serie',
      description: 'Ordena favoritos o usa ranking para preparar el cuadro.',
      icon: Icons.military_tech_rounded,
    ),
    PremiumFeatureDefinition(
      key: 'historical_group_ranking',
      title: 'Ranking histórico del grupo',
      description: 'Ranking acumulado entre torneos y temporadas.',
      icon: Icons.leaderboard_rounded,
    ),
    PremiumFeatureDefinition(
      key: 'group_visual_customization',
      title: 'Personalización visual del grupo',
      description: 'Detalles de color, portada y estilo para grupos muy activos.',
      icon: Icons.palette_rounded,
    ),
  ];

  static List<String> get freeTournamentPrinciples => [
    appIsEnglish ? 'Large groups stay free' : 'Grupos grandes gratis',
    appIsEnglish ? 'Wide participant counts stay free' : 'Participantes amplios gratis',
    appIsEnglish ? 'League, knockout, manual and basic americano' : 'Liga, eliminatoria, manual y americano básico',
    appIsEnglish ? 'Results by sport' : 'Resultados por deporte',
    appIsEnglish ? 'Basic standings' : 'Clasificación básica',
    appIsEnglish ? 'Third place included' : 'Tercer puesto incluido',
    appIsEnglish ? 'Edit matches one by one' : 'Editar partidos uno a uno',
    appIsEnglish ? 'Add matches to Agenda' : 'Añadir partidos a Agenda',
  ];

  static Set<String> get featureKeys => features.map((feature) => feature.key).toSet();

  static bool isPremiumFeature(String key) => featureKeys.contains(key);

  static PremiumFeatureDefinition feature(String key) {
    return features.firstWhere(
      (item) => item.key == key,
      orElse: () => PremiumFeatureDefinition(
        key: key,
        title: appIsEnglish ? 'Premium feature' : 'Función Premium',
        description: appIsEnglish ? 'Advanced tool for groups that use Grupli a lot.' : 'Herramienta avanzada para grupos que usan mucho Grupli.',
        icon: Icons.workspace_premium_rounded,
      ),
    );
  }

  static GroupPremiumEntitlement entitlementForGroup(Map<String, dynamic> group) {
    return GroupPremiumEntitlement.fromGroup(group);
  }
}

Future<bool> showPremiumFeatureGate(
  BuildContext context, {
  required Map<String, dynamic> group,
  required String featureKey,
}) async {
  final entitlement = GrupliPremium.entitlementForGroup(group);
  if (entitlement.canUse(featureKey)) return true;
  final feature = GrupliPremium.feature(featureKey);
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: AppCard(
          color: AppColors.white,
          padding: const EdgeInsets.all(18),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(width: 46, height: 46, decoration: BoxDecoration(color: AppColors.orangeSoft, borderRadius: BorderRadius.circular(16)), child: Icon(feature.icon, color: AppColors.orange)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(appIsEnglish ? 'Included in Grupli Premium' : 'Incluido en Grupli Premium', style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 17)),
                const SizedBox(height: 4),
                Text(feature.title, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800)),
              ])),
            ]),
            const SizedBox(height: 12),
            Text(feature.description, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700, height: 1.3)),
            const SizedBox(height: 10),
            Text(appIsEnglish ? 'Billing is not live yet. This screen prepares the experience for enabling Premium per group later, and Premium will also remove ads from the app.' : 'Los pagos aún no están activos. Esta pantalla deja preparada la experiencia para activar Premium por grupo más adelante, y Premium también quitará anuncios de la app.', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, height: 1.25)),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: SecondaryButton(label: appIsEnglish ? 'Not now' : 'Ahora no', icon: Icons.close_rounded, onTap: () => Navigator.pop(sheetContext, false))),
              const SizedBox(width: 10),
              Expanded(child: PrimaryButton(label: appIsEnglish ? 'See Premium' : 'Ver Premium', icon: Icons.workspace_premium_rounded, onTap: () {
                Navigator.pop(sheetContext, false);
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => PremiumGroupScreen(group: group)));
              })),
            ]),
          ]),
        ),
      ),
    ),
  );
  return result == true;
}
