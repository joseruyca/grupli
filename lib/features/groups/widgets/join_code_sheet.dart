import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/errors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../ui/buttons.dart';
import '../../../ui/inputs.dart';
import '../../../ui/toast.dart';
import '../groups_repository.dart';

class JoinCodeSheet extends StatefulWidget {
  const JoinCodeSheet({super.key});

  @override
  State<JoinCodeSheet> createState() => _JoinCodeSheetState();
}

class _JoinCodeSheetState extends State<JoinCodeSheet> {
  final _code = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    if (_loading) return;
    if (_code.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      final id = await GroupsRepository().joinByCode(_code.text);
      if (mounted) {
        Navigator.pop(context);
        context.go('/app/groups/$id');
      }
    } catch (e) {
      if (mounted) AppToast.show(context, humanError(e), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Unirse con código', style: AppTypography.section),
        const SizedBox(height: AppSpacing.sm),
        Text('Pega el código que te han enviado.', style: AppTypography.muted),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(controller: _code, label: 'Código', hint: 'EJ: AB12CD'),
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(label: 'Entrar al grupo', loading: _loading, onPressed: _join),
      ],
    );
  }
}
