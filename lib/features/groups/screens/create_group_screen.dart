import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/errors.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../ui/app_card.dart';
import '../../../ui/app_header.dart';
import '../../../ui/app_screen.dart';
import '../../../ui/app_ui_helpers.dart';
import '../../../ui/buttons.dart';
import '../../../ui/inputs.dart';
import '../../../ui/toast.dart';
import '../../../shared/utils/validators.dart';
import '../groups_repository.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final id = await GroupsRepository().createGroup(name: _name.text);
      if (mounted) context.go('/app/groups/$id');
    } catch (e) {
      if (mounted) AppToast.show(context, humanError(e), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      child: Form(
        key: _formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const AppHeader(
            title: 'Nuevo grupo',
            subtitle: 'Crea un espacio privado para organizar quedadas, calendario, gastos y torneos.',
            showBack: true,
          ),
          const SizedBox(height: AppSpacing.xl),
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              AppTextField(
                controller: _name,
                label: 'Nombre del grupo',
                hint: 'Ej. Pádel viernes, Amigos, Fútbol sala…',
                validator: (v) => Validators.requiredText(v, 'El nombre'),
              ),
              const SizedBox(height: AppSpacing.lg),
              const _PrincipleLine(icon: Icons.lock_outline_rounded, title: 'Privado por defecto', body: 'Nadie puede encontrarlo públicamente.'),
              const SizedBox(height: AppSpacing.md),
              const _PrincipleLine(icon: Icons.link_rounded, title: 'Acceso por invitación', body: 'Código ahora. Enlace y QR cuando activemos invitaciones.'),
              const SizedBox(height: AppSpacing.md),
              const _PrincipleLine(icon: Icons.event_available_rounded, title: 'La organización va dentro', body: 'Cada quedada tendrá su fecha, hora, lugar y asistencia.'),
            ]),
          ),
          const SizedBox(height: AppSpacing.lg),
          InfoPanel(
            icon: Icons.auto_awesome_rounded,
            title: 'Qué tendrá dentro',
            body: 'Eventos con asistencia, calendario, finanzas tipo Tricount y ligas/torneos. El creador será admin del grupo.',
            color: AppColors.teal,
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(label: 'Crear grupo', icon: Icons.check_rounded, loading: _loading, onPressed: _submit),
        ]),
      ),
    );
  }
}

class _PrincipleLine extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _PrincipleLine({required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SoftIconBox(icon: icon, color: AppColors.teal, size: 38),
      const SizedBox(width: AppSpacing.md),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: AppTypography.body.copyWith(fontWeight: FontWeight.w900, color: AppColors.navy)),
        const SizedBox(height: 2),
        Text(body, style: AppTypography.muted),
      ])),
    ]);
  }
}
