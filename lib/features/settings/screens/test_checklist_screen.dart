import 'package:flutter/material.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../ui/app_card.dart';
import '../../../ui/app_header.dart';
import '../../../ui/app_screen.dart';
import '../../../ui/status_chip.dart';

class TestChecklistScreen extends StatefulWidget {
  const TestChecklistScreen({super.key});

  @override
  State<TestChecklistScreen> createState() => _TestChecklistScreenState();
}

class _TestChecklistScreenState extends State<TestChecklistScreen> {
  final Set<String> _done = {};

  int get _total => _sections.fold<int>(0, (sum, section) => sum + section.items.length);
  int get _completed => _done.length;

  void _toggle(String id) {
    setState(() {
      if (_done.contains(id)) {
        _done.remove(id);
      } else {
        _done.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = _total == 0 ? 0.0 : _completed / _total;
    return AppScreen(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const AppHeader(
          title: 'Revisión v9',
          subtitle: 'Checklist real antes de cambiar página por página.',
          showBack: true,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          color: AppColors.mintSoft,
          border: const BorderSide(color: Color(0xFFD4E7DF)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text('Progreso de revisión', style: AppTypography.section.copyWith(fontSize: 18))),
              StatusChip(label: '$_completed/$_total', color: AppColors.teal),
            ]),
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: AppColors.white,
                color: AppColors.teal,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Marca cada punto mientras pruebas con dos usuarios reales. Si algo falla, no seguimos con diseño hasta corregirlo.',
              style: AppTypography.muted,
            ),
          ]),
        ),
        const SizedBox(height: AppSpacing.lg),
        ..._sections.map((section) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          child: _ChecklistSection(
            section: section,
            done: _done,
            onToggle: _toggle,
          ),
        )),
      ]),
    );
  }
}

class _ChecklistSection extends StatelessWidget {
  final _CheckSection section;
  final Set<String> done;
  final ValueChanged<String> onToggle;

  const _ChecklistSection({required this.section, required this.done, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final count = section.items.where((item) => done.contains(item.id)).length;
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: section.color.withOpacity(0.12), borderRadius: BorderRadius.circular(16)),
            child: Icon(section.icon, color: section.color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(section.title, style: AppTypography.section.copyWith(fontSize: 18)),
            const SizedBox(height: 3),
            Text(section.subtitle, style: AppTypography.muted),
          ])),
          StatusChip(label: '$count/${section.items.length}', color: section.color),
        ]),
        const SizedBox(height: AppSpacing.md),
        ...section.items.map((item) {
          final checked = done.contains(item.id);
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => onToggle(item.id),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: checked ? AppColors.tealSoft : AppColors.canvas,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: checked ? AppColors.teal.withOpacity(0.35) : AppColors.border),
                ),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(checked ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, color: checked ? AppColors.teal : AppColors.textMuted),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(item.title, style: AppTypography.body.copyWith(fontWeight: FontWeight.w800)),
                    if (item.detail != null) ...[
                      const SizedBox(height: 4),
                      Text(item.detail!, style: AppTypography.muted),
                    ],
                  ])),
                ]),
              ),
            ),
          );
        }),
      ]),
    );
  }
}

class _CheckSection {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<_CheckItem> items;

  const _CheckSection({required this.title, required this.subtitle, required this.icon, required this.color, required this.items});
}

class _CheckItem {
  final String id;
  final String title;
  final String? detail;

  const _CheckItem(this.id, this.title, [this.detail]);
}

const _sections = [
  _CheckSection(
    title: 'Usuarios A/B',
    subtitle: 'Comprueba que dos cuentas reales funcionan como deben.',
    icon: Icons.people_alt_rounded,
    color: AppColors.teal,
    items: [
      _CheckItem('ab_01', 'Usuario A crea una cuenta y entra sin error.'),
      _CheckItem('ab_02', 'Usuario A crea un grupo y aparece como owner.'),
      _CheckItem('ab_03', 'Usuario B crea una cuenta independiente.'),
      _CheckItem('ab_04', 'Usuario B entra al grupo usando el código.'),
      _CheckItem('ab_05', 'A y B ven el mismo grupo y la misma lista de miembros.'),
    ],
  ),
  _CheckSection(
    title: 'Roles y permisos',
    subtitle: 'Owner, admin y miembro no deben poder hacer lo mismo.',
    icon: Icons.verified_user_rounded,
    color: AppColors.amber,
    items: [
      _CheckItem('role_01', 'Un miembro normal no puede eliminar el grupo.'),
      _CheckItem('role_02', 'Un miembro normal no puede expulsar a otros.'),
      _CheckItem('role_03', 'El owner puede hacer admin a otro usuario.'),
      _CheckItem('role_04', 'Un admin puede editar grupo y gestionar miembros.'),
      _CheckItem('role_05', 'Nadie puede expulsar ni degradar al owner.', 'Debe mostrar error claro y no romper la pantalla.'),
    ],
  ),
  _CheckSection(
    title: 'Flujos principales',
    subtitle: 'Antes del rediseño final, todo debe responder.',
    icon: Icons.route_rounded,
    color: AppColors.success,
    items: [
      _CheckItem('flow_01', 'Crear, editar y abrir grupo.'),
      _CheckItem('flow_02', 'Crear quedada y responder Voy/Duda/No.'),
      _CheckItem('flow_03', 'Crear gasto con varios participantes y ver balances.'),
      _CheckItem('flow_04', 'Crear torneo, equipos, partidos y resultados.'),
      _CheckItem('flow_05', 'Editar perfil, subir avatar y cambiar ajustes.'),
    ],
  ),
  _CheckSection(
    title: 'RLS y seguridad',
    subtitle: 'Nada de datos cruzados entre grupos.',
    icon: Icons.shield_rounded,
    color: AppColors.lilac,
    items: [
      _CheckItem('rls_01', 'Usuario B no ve grupos donde no es miembro.'),
      _CheckItem('rls_02', 'Usuario B no puede abrir una URL directa de grupo ajeno.'),
      _CheckItem('rls_03', 'Usuario B no puede modificar gastos/eventos/torneos de grupo ajeno.'),
      _CheckItem('rls_04', 'Ejecutar supabase/security_checks.sql no muestra tablas sin RLS.'),
      _CheckItem('rls_05', 'Ejecutar supabase/patch_v9_rls_hardening.sql en Supabase.'),
    ],
  ),
  _CheckSection(
    title: 'Publicación',
    subtitle: 'Confirmación final antes de diseño página por página.',
    icon: Icons.rocket_launch_rounded,
    color: AppColors.coral,
    items: [
      _CheckItem('pub_01', 'flutter analyze sin errores.'),
      _CheckItem('pub_02', 'Local Chrome funciona.'),
      _CheckItem('pub_03', 'Commit limpio en GitHub.'),
      _CheckItem('pub_04', 'Vercel despliega el commit correcto.'),
      _CheckItem('pub_05', 'Probar en incógnito para descartar caché.'),
    ],
  ),
];
