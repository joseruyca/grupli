import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/errors.dart';
import '../../../theme/spacing.dart';
import '../../../ui/app_header.dart';
import '../../../ui/app_screen.dart';
import '../../../ui/buttons.dart';
import '../../../ui/inputs.dart';
import '../../../ui/loading_state.dart';
import '../../../ui/segmented_control.dart';
import '../../../ui/toast.dart';
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
  final _days = TextEditingController();
  final _time = TextEditingController();
  final _location = TextEditingController();
  final _minPeople = TextEditingController();

  String _type = 'deporte';
  String _privacy = 'privado';
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
    _days.dispose();
    _time.dispose();
    _location.dispose();
    _minPeople.dispose();
    super.dispose();
  }

  Future<void> _loadGroup() async {
    setState(() => _loading = true);
    try {
      final g = await GroupsRepository().getGroup(widget.groupId);
      _name.text = (g['name'] ?? '').toString();
      _type = (g['type'] ?? 'deporte').toString();
      _privacy = (g['privacy'] ?? 'privado').toString();
      _days.text = (g['default_days'] ?? '').toString();
      _time.text = (g['default_time'] ?? '').toString();
      _location.text = (g['default_location'] ?? '').toString();
      _minPeople.text = (g['min_people'] ?? 2).toString();
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
        'type': _type,
        'privacy': _privacy,
        'default_days': _days.text.trim(),
        'default_time': _time.text.trim(),
        'default_location': _location.text.trim(),
        'min_people': int.tryParse(_minPeople.text.trim()) ?? 2,
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
      child: _loading
          ? const LoadingState()
          : Form(
              key: _formKey,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const AppHeader(title: 'Editar grupo', subtitle: 'Ajusta la información base del grupo.', showBack: true),
                const SizedBox(height: AppSpacing.xxl),
                AppTextField(controller: _name, label: 'Nombre del grupo', validator: (v) => Validators.requiredText(v, 'El nombre')),
                const SizedBox(height: AppSpacing.lg),
                SegmentedControl(values: const ['deporte', 'cartas', 'otro'], selected: _type, onChanged: (v) => setState(() => _type = v)),
                const SizedBox(height: AppSpacing.lg),
                SegmentedControl(values: const ['privado', 'público'], selected: _privacy, onChanged: (v) => setState(() => _privacy = v)),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(controller: _days, label: 'Días habituales'),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(controller: _time, label: 'Hora habitual'),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(controller: _location, label: 'Ubicación habitual', hint: 'Pista, bar, casa, club...'),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(controller: _minPeople, label: 'Mínimo de personas', keyboardType: TextInputType.number, validator: (v) {
                  final n = int.tryParse((v ?? '').trim());
                  if (n == null || n < 1) return 'Introduce un número válido.';
                  return null;
                }),
                const SizedBox(height: AppSpacing.xxl),
                PrimaryButton(label: 'Guardar cambios', loading: _saving, onPressed: _save),
              ]),
            ),
    );
  }
}
