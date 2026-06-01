import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/errors.dart';
import '../../../theme/spacing.dart';
import '../../../ui/app_header.dart';
import '../../../ui/app_screen.dart';
import '../../../ui/buttons.dart';
import '../../../ui/inputs.dart';
import '../../../ui/segmented_control.dart';
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
  final _days = TextEditingController(text: 'Lunes, miércoles');
  final _time = TextEditingController(text: '20:00');
  final _location = TextEditingController();
  final _minPeople = TextEditingController(text: '2');
  String _type = 'deporte';
  String _privacy = 'privado';
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _days.dispose();
    _time.dispose();
    _location.dispose();
    _minPeople.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final id = await GroupsRepository().createGroup(
        name: _name.text,
        type: _type,
        privacy: _privacy,
        defaultDays: _days.text,
        defaultTime: _time.text,
        defaultLocation: _location.text,
        minPeople: int.tryParse(_minPeople.text) ?? 2,
      );
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
          const AppHeader(title: 'Crear grupo', subtitle: 'Define lo básico. Luego podrás editarlo.', showBack: true),
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
          PrimaryButton(label: 'Crear grupo', loading: _loading, onPressed: _submit),
        ]),
      ),
    );
  }
}
