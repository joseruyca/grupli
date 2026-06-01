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
  bool _sent = false;

  Future<void> _submit() async {
    if (_loading) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await AuthService().sendRecovery(_email.text);
      if (mounted) setState(() => _sent = true);
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
          const AppHeader(title: 'Recuperar contraseña', subtitle: 'Te enviaremos un enlace para restablecerla.', showBack: true),
          const SizedBox(height: AppSpacing.xxl),
          AppTextField(
            controller: _email,
            label: 'Correo electrónico',
            hint: 'tu@email.com',
            keyboardType: TextInputType.emailAddress,
            validator: Validators.email,
            prefixIcon: const Icon(Icons.mail_outline_rounded, color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.xxl),
          PrimaryButton(label: 'Enviar enlace de recuperación', icon: Icons.send_rounded, loading: _loading, onPressed: _submit),
          if (_sent) ...[
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              color: AppColors.mintSoft,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.check_rounded, color: AppColors.success),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Si el correo existe, recibirás el enlace en minutos.', style: AppTypography.body.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text('Revisa también tu carpeta de spam o promociones.', style: AppTypography.muted),
                    ]),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          SecondaryButton(label: 'Volver a login', icon: Icons.arrow_back_rounded, onPressed: () => context.go('/login')),
        ]),
      ),
    );
  }
}
