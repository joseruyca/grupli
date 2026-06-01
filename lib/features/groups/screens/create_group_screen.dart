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
  final _time = TextEditingController(text: '20:00');
  final _location = TextEditingController();
  int _minPeople = 4;
  String _type = 'deporte';
  String _privacy = 'privado';
  bool _loading = false;
  final List<String> _selectedDays = ['Lun', 'Mié', 'Vie'];

  @override
  void dispose() {
    _name.dispose();
    _time.dispose();
    _location.dispose();
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
        defaultDays: _selectedDays.join(', '),
        defaultTime: _time.text,
        defaultLocation: _location.text,
        minPeople: _minPeople,
      );
      if (mounted) context.go('/app/groups/$id');
    } catch (e) {
      if (mounted) AppToast.show(context, humanError(e), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
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
      child: Form(
        key: _formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const AppHeader(title: 'Crear grupo', subtitle: 'Hazlo fácil de entender desde el primer día.', showBack: true),
          const SizedBox(height: AppSpacing.xl),
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              AppTextField(controller: _name, label: 'Nombre del grupo', hint: 'Ej. Pádel los findes', validator: (v) => Validators.requiredText(v, 'El nombre')),
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
              AppTextField(controller: _time, label: 'Hora', hint: '20:00', prefixIcon: const Icon(Icons.access_time_rounded, color: AppColors.textMuted)),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(controller: _location, label: 'Ubicación', hint: 'Padel Indoor', prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.textMuted)),
              const SizedBox(height: AppSpacing.lg),
              Text('Nº mínimo de personas', style: AppTypography.small.copyWith(color: AppColors.navy, fontSize: 13)),
              const SizedBox(height: AppSpacing.sm),
              Container(
                decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.people_outline_rounded, color: AppColors.textMuted),
                    const SizedBox(width: 12),
                    Text('$_minPeople', style: AppTypography.body.copyWith(fontWeight: FontWeight.w800)),
                    const Spacer(),
                    IconButton(onPressed: _minPeople > 1 ? () => setState(() => _minPeople--) : null, icon: const Icon(Icons.remove_rounded)),
                    IconButton(onPressed: () => setState(() => _minPeople++), icon: const Icon(Icons.add_rounded)),
                  ],
                ),
              ),
            ]),
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(label: 'Crear grupo', loading: _loading, icon: Icons.check_rounded, onPressed: _submit),
        ]),
      ),
    );
  }
}
