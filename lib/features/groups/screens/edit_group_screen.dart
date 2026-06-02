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
import '../../../ui/loading_state.dart';
import '../../../ui/toast.dart';
import '../../../ui/group_bottom_nav.dart';
import '../../../shared/utils/validators.dart';
import '../groups_repository.dart';

class EditGroupScreen extends StatefulWidget {
  final String groupId;
  const EditGroupScreen({super.key, required this.groupId});

  @override
  State<EditGroupScreen> createState() => _EditGroupScreenState();
}

class _EditGroupScreenState extends State<EditGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();

  bool _loading = false;
  bool _saving = false;
  String _role = 'member';

  @override
  void initState() {
    super.initState();
    _loadGroup();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _loadGroup() async {
    setState(() => _loading = true);
    try {
      final g = await GroupsRepository().getGroup(widget.groupId);
      _name.text = (g['name'] ?? '').toString();
      _role = (g['my_role'] ?? 'member').toString();
    } catch (e) {
      if (mounted) AppToast.show(context, humanError(e), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_role != 'owner' && _role != 'admin') {
      AppToast.show(context, 'Solo admin u owner pueden editar el grupo.', error: true);
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      await GroupsRepository().updateGroup(widget.groupId, {
        'name': _name.text.trim(),
        'type': 'otro',
        'privacy': 'privado',
        'default_days': null,
        'default_time': null,
        'default_location': null,
        'min_people': 1,
      });
      if (mounted) {
        AppToast.show(context, 'Grupo actualizado.');
        context.go('/app/groups/${widget.groupId}');
      }
    } catch (e) {
      if (mounted) AppToast.show(context, humanError(e), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      bottomNavigationBar: GroupBottomNav(groupId: widget.groupId, index: 4),
      child: _loading
          ? const LoadingState()
          : Form(
              key: _formKey,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const AppHeader(
                  title: 'Editar grupo',
                  subtitle: 'Cambia solo lo esencial. El grupo seguirá siendo privado.',
                  showBack: true,
                ),
                const SizedBox(height: AppSpacing.xl),
                AppCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    AppTextField(
                      controller: _name,
                      label: 'Nombre del grupo',
                      validator: (v) => Validators.requiredText(v, 'El nombre'),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Icon(Icons.lock_outline_rounded, color: AppColors.tealDark, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Este grupo es cerrado. No hay modo público, horario global ni mínimo de personas en el grupo. Eso se decide después en cada quedada.',
                          style: AppTypography.muted.copyWith(color: AppColors.navy),
                        ),
                      ),
                    ]),
                  ]),
                ),
                const SizedBox(height: AppSpacing.xl),
                PrimaryButton(label: 'Guardar cambios', loading: _saving, icon: Icons.check_rounded, onPressed: _save),
              ]),
            ),
    );
  }
}
