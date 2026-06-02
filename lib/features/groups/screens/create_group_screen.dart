import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/errors.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../ui/app_screen.dart';
import '../../../ui/buttons.dart';
import '../../../ui/inputs.dart';
import '../../../ui/mock_ui.dart';
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
          const MockHeader(title: 'Nuevo grupo', showBack: true),
          const SizedBox(height: 34),
          Center(
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(color: AppColors.lilacSoft, borderRadius: BorderRadius.circular(32)),
              child: const Icon(Icons.groups_2_rounded, color: AppColors.teal, size: 48),
            ),
          ),
          const SizedBox(height: 28),
          AppTextField(controller: _name, label: 'Nombre del grupo', hint: 'Ej. Pádel los miércoles', validator: (v) => Validators.requiredText(v, 'El nombre')),
          const SizedBox(height: 22),
          MockCard(
            color: AppColors.canvasWarm,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Todos los grupos son privados.', style: AppTypography.body.copyWith(fontWeight: FontWeight.w900, color: AppColors.navy)),
              const SizedBox(height: 6),
              Text('El acceso será solo por invitación, código o QR. Los eventos, gastos y torneos se configuran dentro del grupo.', style: AppTypography.muted),
            ]),
          ),
          const SizedBox(height: 26),
          PrimaryButton(label: 'Crear grupo', icon: Icons.check_rounded, loading: _loading, onPressed: _submit),
        ]),
      ),
    );
  }
}
