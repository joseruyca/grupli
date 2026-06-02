import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/errors.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../ui/app_card.dart';
import '../../../ui/app_header.dart';
import '../../../ui/app_screen.dart';
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
            title: 'Crear grupo',
            subtitle: 'Empieza con un grupo privado. Luego invitas a quien quieras.',
            showBack: true,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            color: AppColors.mintSoft,
            border: const BorderSide(color: Color(0xFFD7E8E2)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.lock_outline_rounded, color: AppColors.teal),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Grupo cerrado', style: AppTypography.body.copyWith(fontWeight: FontWeight.w900, color: AppColors.navy)),
                  const SizedBox(height: 4),
                  Text(
                    'No será público. Solo se podrá entrar con invitación, código, enlace o QR cuando activemos esas opciones.',
                    style: AppTypography.muted.copyWith(color: AppColors.navy),
                  ),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              AppTextField(
                controller: _name,
                label: 'Nombre del grupo',
                hint: 'Ej. Pádel viernes',
                validator: (v) => Validators.requiredText(v, 'El nombre'),
              ),
              const SizedBox(height: AppSpacing.lg),
              _PrivateRuleLine(icon: Icons.visibility_off_outlined, text: 'Siempre privado'),
              const SizedBox(height: AppSpacing.sm),
              _PrivateRuleLine(icon: Icons.qr_code_2_rounded, text: 'Acceso por código o enlace'),
              const SizedBox(height: AppSpacing.sm),
              _PrivateRuleLine(icon: Icons.event_available_rounded, text: 'Los días, horas y mínimos se configuran en cada quedada'),
            ]),
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(label: 'Crear grupo privado', icon: Icons.check_rounded, loading: _loading, onPressed: _submit),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Después podrás añadir miembros, crear quedadas, gastos y torneos desde dentro del grupo.',
            textAlign: TextAlign.center,
            style: AppTypography.small.copyWith(color: AppColors.textMuted),
          ),
        ]),
      ),
    );
  }
}

class _PrivateRuleLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _PrivateRuleLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 18, color: AppColors.tealDark),
      const SizedBox(width: 9),
      Expanded(child: Text(text, style: AppTypography.body.copyWith(fontWeight: FontWeight.w700))),
    ]);
  }
}
