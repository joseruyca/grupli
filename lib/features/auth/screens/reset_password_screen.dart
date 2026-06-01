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

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _repeat = TextEditingController();
  bool _loading = false;

  Future<void> _submit() async {
    if (_loading) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await AuthService().updatePassword(_password.text);
      if (mounted) {
        AppToast.show(context, 'Contraseña actualizada.');
        context.go('/login');
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
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const AppHeader(title: 'Nueva contraseña', subtitle: 'Crea una contraseña nueva para tu cuenta.', showBack: true),
          const SizedBox(height: AppSpacing.xxl),
          AppTextField(controller: _password, label: 'Nueva contraseña', obscure: true, validator: Validators.password),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            controller: _repeat,
            label: 'Repetir contraseña',
            obscure: true,
            validator: (value) => value != _password.text ? 'Las contraseñas no coinciden.' : null,
          ),
          const SizedBox(height: AppSpacing.xxl),
          PrimaryButton(label: 'Actualizar contraseña', loading: _loading, onPressed: _submit),
        ]),
      ),
    );
  }
}
