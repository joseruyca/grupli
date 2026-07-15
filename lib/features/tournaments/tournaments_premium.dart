part of 'package:grupli/main.dart';
// ignore_for_file: override_on_non_overriding_member

class TournamentValidationCard extends StatelessWidget {
  final String format;
  final String scoringType;
  final Map<String, dynamic> scoringConfig;
  const TournamentValidationCard({super.key, required this.format, required this.scoringType, required this.scoringConfig});

  @override
  Widget build(BuildContext context) => AppCard(
    color: AppColors.blueSoft,
    padding: const EdgeInsets.all(12),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 36, height: 36, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.verified_rounded, color: AppColors.blue, size: 20)),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(tournamentClassificationTitle(format, scoringType, scoringConfig), style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(scoringValidationText(scoringType, scoringConfig), style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, height: 1.25, fontSize: 12)),
      ])),
    ]),
  );
}

void showPremiumUpsellDialog(BuildContext context, {String feature = 'Premium de grupo', Map<String, dynamic>? group}) {
  final premiumFeature = GrupliPremium.isPremiumFeature(feature) ? GrupliPremium.feature(feature) : null;
  final title = premiumFeature?.title ?? feature;
  final description = premiumFeature?.description ?? 'Herramientas avanzadas para grupos que organizan torneos con frecuencia.';
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Grupli Premium'),
      content: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink)),
          const SizedBox(height: 8),
          Text(description, style: const TextStyle(fontWeight: FontWeight.w700, height: 1.3)),
          const SizedBox(height: 10),
          const Text('Premium será por grupo: todos los miembros disfrutarán las funciones avanzadas de ese grupo y la experiencia irá sin anuncios. La parte gratis seguirá cubriendo torneos completos, resultados y clasificación.', style: TextStyle(fontWeight: FontWeight.w700, height: 1.3, color: AppColors.muted)),
          const SizedBox(height: 12),
          ...GrupliPremium.features.take(7).map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(item.icon, color: AppColors.teal, size: 18),
              const SizedBox(width: 7),
              Expanded(child: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w800))),
            ]),
          )),
          const SizedBox(height: 8),
          const Text('Los pagos reales todavía están desactivados. Esta fase prepara permisos, pantalla y bloqueos suaves sin tocar la experiencia gratis.', style: TextStyle(fontWeight: FontWeight.w700, height: 1.25, color: AppColors.muted, fontSize: 12)),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cerrar')),
        FilledButton(onPressed: () {
          Navigator.pop(dialogContext);
          if (group != null) {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => PremiumGroupScreen(group: group)));
          }
        }, child: Text(group == null ? 'Preparado' : 'Ver Premium')),
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
      Container(width: 38, height: 38, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13)), child: const Center(child: Icon(Icons.workspace_premium_rounded, color: AppColors.orange, size: 20))),
      const SizedBox(width: 10),
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Premium de grupo preparado', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
        SizedBox(height: 3),
        Text('Más herramientas para grupos que organizan torneos a menudo.', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 12)),
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
      const Icon(Icons.workspace_premium_rounded, color: AppColors.orange, size: 22),
      const SizedBox(width: 10),
      const Expanded(child: Text('Gratis ahora, Premium preparado para más adelante: calendario avanzado, exportar, ranking histórico y estadísticas avanzadas.', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800, height: 1.25))),
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
      const Text('Gratis completo, Premium preparado', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
      const SizedBox(height: 6),
      const Text('La app ya cubre lo esencial gratis. Cuando activemos Premium, sumará estadísticas avanzadas, exportaciones, ranking histórico, automatización de jornadas y sin anuncios.', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, height: 1.25)),
      const SizedBox(height: 10),
      Wrap(spacing: 8, runSpacing: 8, children: [
        const TournamentRuleChip(label: 'Gratis: crear torneos'),
        const TournamentRuleChip(label: 'Gratis: resultados y clasificación'),
        const TournamentRuleChip(label: 'Premium: stats avanzadas'),
        const TournamentRuleChip(label: 'Premium: exportar'),
        const TournamentRuleChip(label: 'Premium: ranking histórico'),
        const TournamentRuleChip(label: 'Premium: sin anuncios'),
        const TournamentRuleChip(label: 'Premium: plantillas'),
      ]),
      const SizedBox(height: 10),
      SecondaryButton(label: 'Ver Premium futuro', icon: Icons.workspace_premium_rounded, onTap: () => showPremiumUpsellDialog(context)),
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
