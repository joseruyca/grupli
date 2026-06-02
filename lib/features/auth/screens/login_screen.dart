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
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const MockHeader(title: '¡Bienvenido de nuevo!', subtitle: 'Inicia sesión para continuar.', showBack: true),
          const SizedBox(height: 24),
          _SocialButton(icon: Icons.g_mobiledata_rounded, label: 'Continuar con Google'),
          const SizedBox(height: 10),
          _SocialButton(icon: Icons.apple_rounded, label: 'Continuar con Apple'),
          const SizedBox(height: 18),
          Row(children: [const Expanded(child: Divider()), Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text('o', style: AppTypography.small)), const Expanded(child: Divider())]),
          const SizedBox(height: 18),
          AppTextField(controller: _email, label: 'Correo electrónico', hint: 'tu@email.com', keyboardType: TextInputType.emailAddress, validator: Validators.email, prefixIcon: const Icon(Icons.mail_outline_rounded, color: AppColors.textMuted)),
          const SizedBox(height: 14),
          AppTextField(controller: _password, label: 'Contraseña', hint: '••••••••', obscure: true, validator: Validators.password, prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.textMuted), suffixIcon: const Icon(Icons.visibility_outlined, color: AppColors.textMuted)),
          Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => context.go('/recover'), child: const Text('¿Olvidaste tu contraseña?'))),
          const SizedBox(height: 10),
          PrimaryButton(label: 'Iniciar sesión', icon: Icons.login_rounded, loading: _loading, onPressed: _submit),
          const SizedBox(height: 18),
          Center(child: Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [Text('¿No tienes cuenta?', style: AppTypography.small), TextButton(onPressed: () => context.go('/register'), child: const Text('Regístrate'))])),
        ]),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SocialButton({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: () => AppToast.show(context, 'Conexión social pendiente.'),
        style: OutlinedButton.styleFrom(foregroundColor: AppColors.navy, side: const BorderSide(color: AppColors.borderStrong), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        icon: Icon(icon, color: icon == Icons.apple_rounded ? Colors.black : AppColors.teal),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
  }
}
