import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/errors.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../ui/app_header.dart';
import '../../../ui/app_screen.dart';
import '../../../ui/buttons.dart';
import '../../../ui/inputs.dart';
import '../../../ui/toast.dart';
import '../../../shared/utils/validators.dart';
import '../auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _repeat = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _repeat.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await AuthService().signUp(name: _name.text, email: _email.text, password: _password.text);
      if (mounted) {
        AppToast.show(context, 'Cuenta creada. Ya puedes usar Grupli.');
        context.go('/app');
      }
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppHeader(title: 'Crear cuenta', subtitle: 'Comencemos. Es rápido y fácil.', showBack: true),
            const SizedBox(height: AppSpacing.xxl),
            AppTextField(
              controller: _name,
              label: 'Nombre',
              hint: 'Tu nombre',
              validator: (v) => Validators.requiredText(v, 'El nombre'),
              prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              controller: _email,
              label: 'Correo electrónico',
              hint: 'tu@email.com',
              keyboardType: TextInputType.emailAddress,
              validator: Validators.email,
              prefixIcon: const Icon(Icons.mail_outline_rounded, color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              controller: _password,
              label: 'Contraseña',
              hint: 'Mínimo 8 caracteres',
              obscure: true,
              validator: Validators.password,
              prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.textMuted),
              suffixIcon: const Icon(Icons.visibility_outlined, color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              controller: _repeat,
              label: 'Repetir contraseña',
              hint: 'Repite tu contraseña',
              obscure: true,
              validator: (value) => value != _password.text ? 'Las contraseñas no coinciden.' : null,
              prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.textMuted),
              suffixIcon: const Icon(Icons.visibility_outlined, color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.xxl),
            PrimaryButton(label: 'Crear cuenta', icon: Icons.person_add_alt_1_rounded, loading: _loading, onPressed: _submit),
            const SizedBox(height: AppSpacing.md),
            SecondaryButton(label: 'Ya tengo cuenta', icon: Icons.login_rounded, onPressed: () => context.go('/login')),
          ],
        ),
      ),
    );
  }
}
