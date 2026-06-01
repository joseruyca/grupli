import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/errors.dart';
import '../../../theme/spacing.dart';
import '../../../ui/app_header.dart';
import '../../../ui/app_screen.dart';
import '../../../ui/buttons.dart';
import '../../../ui/inputs.dart';
import '../../../ui/toast.dart';
import '../../../shared/utils/validators.dart';
import '../auth_service.dart';

class RecoverScreen extends StatefulWidget {
  const RecoverScreen({super.key});

  @override
  State<RecoverScreen> createState() => _RecoverScreenState();
}

class _RecoverScreenState extends State<RecoverScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _loading = false;

  Future<void> _submit() async {
    if (_loading) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await AuthService().sendRecovery(_email.text);
      if (mounted) AppToast.show(context, 'Email de recuperación enviado.');
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
          const AppHeader(title: 'Recuperar contraseña', subtitle: 'Te enviaremos un enlace de recuperación.', showBack: true),
          const SizedBox(height: AppSpacing.xxl),
          AppTextField(controller: _email, label: 'Email', keyboardType: TextInputType.emailAddress, validator: Validators.email),
          const SizedBox(height: AppSpacing.xxl),
          PrimaryButton(label: 'Enviar email', loading: _loading, onPressed: _submit),
          const SizedBox(height: AppSpacing.md),
          SecondaryButton(label: 'Volver a login', icon: Icons.arrow_back_rounded, onPressed: () => context.go('/login')),
        ]),
      ),
    );
  }
}
