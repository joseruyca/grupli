import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/errors.dart';
import '../../../theme/colors.dart';
import '../../../theme/radii.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../ui/app_card.dart';
import '../../../ui/app_header.dart';
import '../../../ui/app_screen.dart';
import '../../../ui/buttons.dart';
import '../../../ui/inputs.dart';
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
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            color: AppColors.mintSoft,
            border: const BorderSide(color: Color(0xFFD7E8E2)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.lightbulb_outline_rounded, color: AppColors.teal),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Pádel, fútbol, running o gimnasio van como Deportivo. Cartas, cenas o planes sociales van como Social.',
                  style: AppTypography.muted.copyWith(color: AppColors.navy),
                ),
              ),
            ]),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              AppTextField(
                controller: _name,
                label: 'Nombre del grupo',
                hint: 'Ej. Pádel los findes',
                validator: (v) => Validators.requiredText(v, 'El nombre'),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Tipo de grupo', style: AppTypography.small.copyWith(color: AppColors.navy, fontSize: 13)),
              const SizedBox(height: AppSpacing.sm),
              Row(children: [
                Expanded(child: _ChoiceCard(label: 'Deportivo', helper: 'Pádel, fútbol...', icon: Icons.sports_soccer_rounded, active: _type == 'deporte', onTap: () => setState(() => _type = 'deporte'))),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: _ChoiceCard(label: 'Social', helper: 'Cartas, cenas...', icon: Icons.style_rounded, active: _type == 'cartas', onTap: () => setState(() => _type = 'cartas'))),
              ]),
              const SizedBox(height: AppSpacing.sm),
              _ChoiceCard(label: 'Otro', helper: 'Cualquier grupo distinto', icon: Icons.more_horiz_rounded, active: _type == 'otro', onTap: () => setState(() => _type = 'otro'), wide: true),
              const SizedBox(height: AppSpacing.lg),
              Text('Privacidad', style: AppTypography.small.copyWith(color: AppColors.navy, fontSize: 13)),
              const SizedBox(height: AppSpacing.sm),
              Row(children: [
                Expanded(child: _ChoiceCard(label: 'Privado', helper: 'Solo por invitación', icon: Icons.lock_outline_rounded, active: _privacy == 'privado', onTap: () => setState(() => _privacy = 'privado'))),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: _ChoiceCard(label: 'Público', helper: 'Cualquiera puede unirse', icon: Icons.public_rounded, active: _privacy == 'público', onTap: () => setState(() => _privacy = 'público'))),
              ]),
              const SizedBox(height: AppSpacing.lg),
              Text('Días habituales', style: AppTypography.small.copyWith(color: AppColors.navy, fontSize: 13)),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'].map((day) {
                  final active = _selectedDays.contains(day);
                  return GestureDetector(
                    onTap: () => _toggleDay(day),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 140),
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                      decoration: BoxDecoration(
                        color: active ? AppColors.tealSoft : AppColors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: active ? AppColors.teal : AppColors.border),
                      ),
                      child: Text(day, style: TextStyle(color: active ? AppColors.tealDark : AppColors.textMuted, fontWeight: FontWeight.w900, fontSize: 12.8)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                controller: _time,
                label: 'Hora habitual',
                hint: '20:00',
                prefixIcon: const Icon(Icons.access_time_rounded, color: AppColors.textMuted),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                controller: _location,
                label: 'Ubicación habitual',
                hint: 'Pista, bar, casa, club...',
                prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.textMuted),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Nº mínimo de personas', style: AppTypography.small.copyWith(color: AppColors.navy, fontSize: 13)),
              const SizedBox(height: AppSpacing.sm),
              Container(
                decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(children: [
                  const Icon(Icons.people_outline_rounded, color: AppColors.textMuted),
                  const SizedBox(width: 12),
                  Text('$_minPeople', style: AppTypography.body.copyWith(fontWeight: FontWeight.w900)),
                  const Spacer(),
                  IconButton(onPressed: _minPeople > 1 ? () => setState(() => _minPeople--) : null, icon: const Icon(Icons.remove_rounded)),
                  IconButton(onPressed: () => setState(() => _minPeople++), icon: const Icon(Icons.add_rounded)),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(label: 'Crear grupo', icon: Icons.check_rounded, loading: _loading, onPressed: _submit),
          const SizedBox(height: AppSpacing.md),
        ]),
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  final String label;
  final String helper;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  final bool wide;

  const _ChoiceCard({
    required this.label,
    required this.helper,
    required this.icon,
    required this.active,
    required this.onTap,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        width: wide ? double.infinity : null,
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: active ? AppColors.tealSoft : AppColors.white,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: active ? AppColors.teal : AppColors.border),
        ),
        child: Row(children: [
          Icon(icon, color: active ? AppColors.tealDark : AppColors.textMuted, size: 20),
          const SizedBox(width: 9),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: TextStyle(color: active ? AppColors.tealDark : AppColors.navy, fontWeight: FontWeight.w900, fontSize: 13)),
              const SizedBox(height: 2),
              Text(helper, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.small),
            ]),
          ),
        ]),
      ),
    );
  }
}
