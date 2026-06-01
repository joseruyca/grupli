import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/errors.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../ui/app_header.dart';
import '../../../ui/app_screen.dart';
import '../../../ui/buttons.dart';
import '../../../ui/inputs.dart';
import '../../../ui/toast.dart';
import '../../../shared/utils/validators.dart';
import '../auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await AuthService().signIn(_email.text, _password.text);
      if (mounted) context.go('/app');
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
            const AppHeader(title: 'Iniciar sesión', subtitle: 'Qué bueno verte de nuevo.', showBack: true),
            const SizedBox(height: AppSpacing.xxl),
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
              hint: 'Tu contraseña',
              obscure: true,
              validator: Validators.password,
              prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.textMuted),
              suffixIcon: const Icon(Icons.visibility_outlined, color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.xxl),
            PrimaryButton(label: 'Iniciar sesión', icon: Icons.login_rounded, loading: _loading, onPressed: _submit),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('o', style: AppTypography.muted),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            TextButton.icon(onPressed: () => context.go('/register'), icon: const Icon(Icons.person_add_alt_1_rounded), label: const Text('Crear cuenta')),
            TextButton.icon(onPressed: () => context.go('/recover'), icon: const Icon(Icons.lock_reset_rounded), label: const Text('Recuperar contraseña')),
          ],
        ),
      ),
    );
  }
}
