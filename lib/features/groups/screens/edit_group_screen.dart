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
  final _time = TextEditingController();
  final _location = TextEditingController();

  String _type = 'deporte';
  String _privacy = 'privado';
  bool _loading = false;
  bool _saving = false;
  String _role = 'member';
  int _minPeople = 2;
  final List<String> _selectedDays = [];

  @override
  void initState() {
    super.initState();
    _loadGroup();
  }

  @override
  void dispose() {
    _name.dispose();
    _time.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _loadGroup() async {
    setState(() => _loading = true);
    try {
      final g = await GroupsRepository().getGroup(widget.groupId);
      _name.text = (g['name'] ?? '').toString();
      _type = (g['type'] ?? 'deporte').toString();
      _privacy = (g['privacy'] ?? 'privado').toString();
      _time.text = (g['default_time'] ?? '').toString();
      _location.text = (g['default_location'] ?? '').toString();
      _minPeople = ((g['min_people'] ?? 2) as num).toInt();
      _role = (g['my_role'] ?? 'member').toString();
      _selectedDays
        ..clear()
        ..addAll(((g['default_days'] ?? '') as String).split(',').map((e) => e.trim()).where((e) => e.isNotEmpty));
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
        'default_days': _selectedDays.join(', '),
        'default_time': _time.text.trim(),
        'default_location': _location.text.trim(),
        'min_people': _minPeople,
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

  void _toggleDay(String day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
      }
    });
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
                const SizedBox(height: AppSpacing.xl),
                AppCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    AppTextField(controller: _name, label: 'Nombre del grupo', validator: (v) => Validators.requiredText(v, 'El nombre')),
                    const SizedBox(height: AppSpacing.lg),
                    Text('Tipo de grupo', style: AppTypography.small.copyWith(color: AppColors.navy, fontSize: 13)),
                    const SizedBox(height: AppSpacing.sm),
                    SegmentedControl(values: const ['deporte', 'cartas', 'otro'], selected: _type, onChanged: (v) => setState(() => _type = v)),
                    const SizedBox(height: AppSpacing.lg),
                    Text('Privacidad', style: AppTypography.small.copyWith(color: AppColors.navy, fontSize: 13)),
                    const SizedBox(height: AppSpacing.sm),
                    SegmentedControl(values: const ['privado', 'público'], selected: _privacy, onChanged: (v) => setState(() => _privacy = v)),
                    const SizedBox(height: AppSpacing.lg),
                    Text('Días', style: AppTypography.small.copyWith(color: AppColors.navy, fontSize: 13)),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'].map((day) {
                        final active = _selectedDays.contains(day);
                        return GestureDetector(
                          onTap: () => _toggleDay(day),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                            decoration: BoxDecoration(
                              color: active ? AppColors.tealSoft : AppColors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: active ? AppColors.teal : AppColors.border),
                            ),
                            child: Text(day, style: TextStyle(color: active ? AppColors.tealDark : AppColors.textMuted, fontWeight: FontWeight.w800, fontSize: 12.8)),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(controller: _time, label: 'Hora', prefixIcon: const Icon(Icons.access_time_rounded, color: AppColors.textMuted)),
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(controller: _location, label: 'Ubicación', hint: 'Pista, bar, casa, club...', prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.textMuted)),
                    const SizedBox(height: AppSpacing.lg),
                    Text('Nº mínimo de personas', style: AppTypography.small.copyWith(color: AppColors.navy, fontSize: 13)),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(children: [
                        const Icon(Icons.people_outline_rounded, color: AppColors.textMuted),
                        const SizedBox(width: 12),
                        Text('$_minPeople', style: AppTypography.body.copyWith(fontWeight: FontWeight.w800)),
                        const Spacer(),
                        IconButton(onPressed: _minPeople > 1 ? () => setState(() => _minPeople--) : null, icon: const Icon(Icons.remove_rounded)),
                        IconButton(onPressed: () => setState(() => _minPeople++), icon: const Icon(Icons.add_rounded)),
                      ]),
                    ),
                  ]),
                ),
                const SizedBox(height: AppSpacing.xl),
                PrimaryButton(label: 'Guardar cambios', loading: _saving, icon: Icons.check_rounded, onPressed: _save),
              ]),
            ),
    );
  }
}
