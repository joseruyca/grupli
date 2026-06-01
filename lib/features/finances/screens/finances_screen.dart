import 'package:flutter/material.dart';
import '../../../core/errors.dart';
import '../../../core/supabase_client.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../ui/app_card.dart';
import '../../../ui/app_header.dart';
import '../../../ui/app_screen.dart';
import '../../../ui/bottom_sheet.dart';
import '../../../ui/buttons.dart';
import '../../../ui/empty_state.dart';
import '../../../ui/inputs.dart';
import '../../../ui/loading_state.dart';
import '../../../ui/stat_card.dart';
import '../../../ui/toast.dart';
import '../../../shared/utils/formatters.dart';
import '../finances_repository.dart';

class FinancesScreen extends StatefulWidget {
  final String groupId;
  const FinancesScreen({super.key, required this.groupId});

  @override
  State<FinancesScreen> createState() => _FinancesScreenState();
}

class _FinancesScreenState extends State<FinancesScreen> {
  late Future<_FinanceData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_FinanceData> _load() async {
    final repo = FinancesRepository();
    final ex = await repo.expenses(widget.groupId);
    List<Map<String, dynamic>> balances = [];
    try { balances = await repo.balances(widget.groupId); } catch (_) {}
    return _FinanceData(ex, balances);
  }

  void _refresh() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AppHeader(
          title: 'Finanzas',
          subtitle: 'Gastos tipo Tricount y balances claros.',
          showBack: true,
          trailing: IconButton.filled(onPressed: () => showAppBottomSheet(context, CreateExpenseSheet(groupId: widget.groupId)).then((_) => _refresh()), icon: const Icon(Icons.add_rounded)),
        ),
        const SizedBox(height: AppSpacing.lg),
        FutureBuilder<_FinanceData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const LoadingState();
            if (snapshot.hasError) return AppCard(child: Text(snapshot.error.toString()));
            final data = snapshot.data!;
            final total = data.expenses.fold<double>(0, (sum, e) => sum + ((e['amount'] ?? 0) as num).toDouble());
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              StatCard(label: 'Total gastado', value: Fmt.money.format(total), icon: Icons.payments_rounded, color: AppColors.coral),
              const SizedBox(height: AppSpacing.lg),
              Text('Quién debe a quién', style: AppTypography.section),
              const SizedBox(height: AppSpacing.md),
              if (data.balances.isEmpty)
                AppCard(child: Text('Aún no hay saldos calculados. Crea un gasto con participantes.', style: AppTypography.muted))
              else
                ...data.balances.map((b) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: AppCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Text('${b['debtor_name']} debe ${Fmt.money.format(((b['amount'] ?? 0) as num).toDouble())} a ${b['creditor_name']}', style: AppTypography.body.copyWith(fontWeight: FontWeight.w800)),
                  ),
                )),
              const SizedBox(height: AppSpacing.lg),
              Text('Movimientos', style: AppTypography.section),
              const SizedBox(height: AppSpacing.md),
              if (data.expenses.isEmpty)
                EmptyState(icon: Icons.receipt_long_rounded, title: 'Sin gastos', body: 'Crea el primer gasto del grupo.')
              else
                ...data.expenses.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: AppCard(
                    child: Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(e['concept'] ?? 'Gasto', style: AppTypography.section),
                        Text(e['note'] ?? 'Reparto igual entre participantes', style: AppTypography.muted),
                      ])),
                      Text(Fmt.money.format(((e['amount'] ?? 0) as num).toDouble()), style: AppTypography.section.copyWith(color: AppColors.coral)),
                    ]),
                  ),
                )),
            ]);
          },
        ),
      ]),
    );
  }
}

class _FinanceData {
  final List<Map<String, dynamic>> expenses;
  final List<Map<String, dynamic>> balances;
  _FinanceData(this.expenses, this.balances);
}

class CreateExpenseSheet extends StatefulWidget {
  final String groupId;
  const CreateExpenseSheet({super.key, required this.groupId});

  @override
  State<CreateExpenseSheet> createState() => _CreateExpenseSheetState();
}

class _CreateExpenseSheetState extends State<CreateExpenseSheet> {
  final _concept = TextEditingController();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  List<Map<String, dynamic>> _members = [];
  final Set<String> _selected = {};
  String? _payer;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    try {
      final rows = await FinancesRepository().groupMembers(widget.groupId);
      final me = SupabaseService.currentUser?.id;
      setState(() {
        _members = rows;
        _selected.addAll(rows.map((m) => m['user_id'].toString()));
        _payer = me ?? (rows.isNotEmpty ? rows.first['user_id'].toString() : null);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _create() async {
    final amount = double.tryParse(_amount.text.replaceAll(',', '.'));
    if (_concept.text.trim().isEmpty || amount == null || amount <= 0 || _payer == null || _selected.isEmpty) {
      AppToast.show(context, 'Revisa concepto, importe, pagador y participantes.', error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      await FinancesRepository().createExpense(
        groupId: widget.groupId,
        concept: _concept.text,
        amount: amount,
        paidBy: _payer!,
        participants: _selected.toList(),
        note: _note.text,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) AppToast.show(context, humanError(e), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingState();
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Crear gasto', style: AppTypography.section),
      const SizedBox(height: AppSpacing.lg),
      AppTextField(controller: _concept, label: 'Concepto'),
      const SizedBox(height: AppSpacing.md),
      AppTextField(controller: _amount, label: 'Importe', keyboardType: TextInputType.number),
      const SizedBox(height: AppSpacing.md),
      AppTextField(controller: _note, label: 'Nota', maxLines: 2),
      const SizedBox(height: AppSpacing.lg),
      Text('Participantes', style: AppTypography.small),
      ..._members.map((m) {
        final profile = Map<String, dynamic>.from((m['profiles'] ?? {}) as Map);
        final name = (profile['full_name'] ?? profile['email'] ?? 'Usuario').toString();
        final id = m['user_id'].toString();
        return CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: _selected.contains(id),
          onChanged: (v) => setState(() => v == true ? _selected.add(id) : _selected.remove(id)),
          title: Text(name),
          secondary: Radio<String>(value: id, groupValue: _payer, onChanged: (v) => setState(() => _payer = v)),
        );
      }),
      const SizedBox(height: AppSpacing.md),
      if (_amount.text.isNotEmpty && _selected.isNotEmpty)
        Text('Se repartirá entre ${_selected.length}.', style: AppTypography.muted),
      const SizedBox(height: AppSpacing.lg),
      PrimaryButton(label: 'Guardar gasto', loading: _saving, onPressed: _create),
    ]);
  }
}
