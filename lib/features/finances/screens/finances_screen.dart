import 'package:flutter/material.dart';
import '../../../core/errors.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../ui/app_card.dart';
import '../../../ui/app_header.dart';
import '../../../ui/app_screen.dart';
import '../../../ui/app_ui_helpers.dart';
import '../../../ui/avatar.dart';
import '../../../ui/bottom_sheet.dart';
import '../../../ui/buttons.dart';
import '../../../ui/empty_state.dart';
import '../../../ui/inputs.dart';
import '../../../ui/loading_state.dart';
import '../../../ui/status_chip.dart';
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
  String _filter = 'Todos';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_FinanceData> _load() async {
    final repo = FinancesRepository();
    final ex = await repo.expenses(widget.groupId);
    List<Map<String, dynamic>> balances = [];
    try {
      balances = await repo.balances(widget.groupId);
    } catch (_) {
      balances = [];
    }
    return _FinanceData(ex, balances);
  }

  void _refresh() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AppHeader(
          title: 'Finanzas',
          subtitle: 'Gastos compartidos claros y sin cuentas raras.',
          showBack: true,
          trailing: IconButton.filled(
            onPressed: () => showAppBottomSheet(context, CreateExpenseSheet(groupId: widget.groupId)).then((_) => _refresh()),
            icon: const Icon(Icons.add_rounded),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        FutureBuilder<_FinanceData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const LoadingState();
            if (snapshot.hasError) return AppCard(child: Text(humanError(snapshot.error!), style: AppTypography.body));
            final data = snapshot.data!;
            final total = data.expenses.fold<double>(0, (sum, e) => sum + ((e['amount'] ?? 0) as num).toDouble());
            final pending = data.expenses.where((e) => (e['status'] ?? 'pending') == 'pending').length;
            final filtered = data.expenses.where((e) {
              final status = (e['status'] ?? 'pending').toString();
              if (_filter == 'Pendientes') return status == 'pending';
              if (_filter == 'Pagados') return status == 'paid';
              return true;
            }).toList();

            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: _MoneyCard(label: 'Total del grupo', amount: total, helper: '${data.expenses.length} movimientos')),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: _MoneyCard(label: 'Pendientes', amount: pending.toDouble(), helper: 'gastos abiertos', isCount: true)),
              ]),
              const SizedBox(height: AppSpacing.lg),
              SectionTitle(title: '¿Quién debe a quién?'),
              const SizedBox(height: AppSpacing.sm),
              if (data.balances.isEmpty)
                InfoPanel(
                  icon: Icons.balance_rounded,
                  title: 'Todavía no hay saldos',
                  body: 'Crea un gasto con participantes para que Grupli calcule los balances.',
                  color: AppColors.teal,
                )
              else
                ...data.balances.take(6).map((b) {
                  final debtor = b['debtor_name']?.toString() ?? 'Alguien';
                  final creditor = b['creditor_name']?.toString() ?? 'alguien';
                  final amount = ((b['amount'] ?? 0) as num).toDouble();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: AppCard(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(children: [
                        const SoftIconBox(icon: Icons.compare_arrows_rounded, color: AppColors.amber, size: 38),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(child: Text('$debtor debe a $creditor', style: AppTypography.body.copyWith(fontWeight: FontWeight.w700))),
                        Text(Fmt.money.format(amount), style: AppTypography.body.copyWith(color: AppColors.danger, fontWeight: FontWeight.w900)),
                      ]),
                    ),
                  );
                }),
              const SizedBox(height: AppSpacing.lg),
              SectionTitle(title: 'Movimientos'),
              const SizedBox(height: AppSpacing.sm),
              Row(children: ['Todos', 'Pendientes', 'Pagados'].map((f) {
                final active = f == _filter;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () => setState(() => _filter = f),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        decoration: BoxDecoration(
                          color: active ? AppColors.teal : AppColors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: active ? AppColors.teal : AppColors.border),
                        ),
                        child: Text(f, textAlign: TextAlign.center, style: TextStyle(color: active ? Colors.white : AppColors.textMuted, fontWeight: FontWeight.w800, fontSize: 12)),
                      ),
                    ),
                  ),
                );
              }).toList()),
              const SizedBox(height: AppSpacing.md),
              if (filtered.isEmpty)
                EmptyState(icon: Icons.receipt_long_rounded, title: 'Sin gastos', body: 'Añade el primer gasto del grupo.')
              else
                ...filtered.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: AppCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(children: [
                      const SoftIconBox(icon: Icons.receipt_long_rounded, color: AppColors.lilac, size: 44),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(e['concept']?.toString() ?? 'Gasto', style: AppTypography.body.copyWith(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 3),
                          Text(_expenseDate(e), style: AppTypography.small),
                        ]),
                      ),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text(Fmt.money.format(((e['amount'] ?? 0) as num).toDouble()), style: AppTypography.body.copyWith(fontWeight: FontWeight.w900, color: AppColors.navy)),
                        const SizedBox(height: 4),
                        StatusChip(label: (e['status'] ?? 'pending') == 'paid' ? 'Pagado' : 'Pendiente', color: (e['status'] ?? 'pending') == 'paid' ? AppColors.success : AppColors.danger),
                      ]),
                    ]),
                  ),
                )),
            ]);
          },
        ),
      ]),
    );
  }

  String _expenseDate(Map<String, dynamic> e) {
    final raw = e['created_at'];
    if (raw == null) return 'Sin fecha';
    try {
      return Fmt.day.format(DateTime.parse(raw.toString()));
    } catch (_) {
      return 'Sin fecha';
    }
  }
}

class _MoneyCard extends StatelessWidget {
  final String label;
  final double amount;
  final String helper;
  final bool isCount;
  const _MoneyCard({required this.label, required this.amount, required this.helper, this.isCount = false});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      color: AppColors.mintSoft,
      border: const BorderSide(color: Color(0xFFD3E7E0)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: AppTypography.small.copyWith(color: AppColors.navy)),
        const SizedBox(height: 8),
        Text(isCount ? amount.toInt().toString() : Fmt.money.format(amount), style: AppTypography.section.copyWith(color: AppColors.tealDark, fontSize: 21)),
        const SizedBox(height: 4),
        Text(helper, style: AppTypography.small),
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
  bool _manual = false;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    try {
      final members = await FinancesRepository().groupMembers(widget.groupId);
      setState(() {
        _members = members;
        _selected.addAll(members.map((m) => m['user_id'].toString()));
        _payer = members.isEmpty ? null : members.first['user_id'].toString();
        _loading = false;
      });
    } catch (e) {
      if (mounted) AppToast.show(context, humanError(e), error: true);
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _create() async {
    if (_saving || _concept.text.trim().isEmpty || _selected.isEmpty || _payer == null) return;
    final amount = double.tryParse(_amount.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      AppToast.show(context, 'Introduce un importe válido.', error: true);
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
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) AppToast.show(context, humanError(e), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  double? get _amountValue => double.tryParse(_amount.text.replaceAll(',', '.'));

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingState();
    final amount = _amountValue;
    final share = amount == null || _selected.isEmpty ? null : amount / _selected.length;
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Nuevo gasto', style: AppTypography.section),
      const SizedBox(height: AppSpacing.lg),
      AppTextField(controller: _concept, label: 'Concepto', hint: 'Cena del viernes'),
      const SizedBox(height: AppSpacing.md),
      Row(children: [
        Expanded(child: AppTextField(controller: _amount, label: 'Importe total', hint: '30,00', keyboardType: TextInputType.number)),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: _PayerSelect(members: _members, value: _payer, onChanged: (v) => setState(() => _payer = v))),
      ]),
      const SizedBox(height: AppSpacing.md),
      Row(children: [
        Expanded(child: Text('Participantes (${_selected.length})', style: AppTypography.small.copyWith(color: AppColors.navy))),
        Text('Editar', style: AppTypography.small.copyWith(color: AppColors.teal)),
      ]),
      const SizedBox(height: AppSpacing.sm),
      Wrap(spacing: 10, runSpacing: 10, children: [
        ..._members.map((m) {
          final id = m['user_id'].toString();
          final profile = Map<String, dynamic>.from((m['profiles'] ?? {}) as Map);
          final name = (profile['full_name'] ?? profile['email'] ?? 'Usuario').toString();
          final active = _selected.contains(id);
          return GestureDetector(
            onTap: () => setState(() => active ? _selected.remove(id) : _selected.add(id)),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Opacity(opacity: active ? 1 : 0.35, child: MemberAvatar(url: null, fallback: name, size: 42)),
              const SizedBox(height: 4),
              SizedBox(width: 58, child: Text(name.split(' ').first, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: AppTypography.small)),
            ]),
          );
        }),
      ]),
      const SizedBox(height: AppSpacing.md),
      Row(children: [
        Expanded(child: _SplitButton(label: 'Reparto igual', active: !_manual, onTap: () => setState(() => _manual = false))),
        const SizedBox(width: 8),
        Expanded(child: _SplitButton(label: 'Manual', active: _manual, onTap: () => setState(() => _manual = true))),
      ]),
      const SizedBox(height: AppSpacing.md),
      AppTextField(controller: _note, label: 'Nota', hint: 'Para la comida y las bebidas', maxLines: 2),
      if (share != null) ...[
        const SizedBox(height: AppSpacing.md),
        InfoPanel(
          icon: Icons.calculate_rounded,
          title: '${_payerName()} pagó ${Fmt.money.format(amount)}.',
          body: 'Se reparte entre ${_selected.length}. Cada uno debe ${Fmt.money.format(share)}.',
          color: AppColors.teal,
        ),
      ],
      const SizedBox(height: AppSpacing.lg),
      PrimaryButton(label: 'Guardar gasto', loading: _saving, onPressed: _create),
    ]);
  }

  String _payerName() {
    final match = _members.where((m) => m['user_id'].toString() == _payer).toList();
    if (match.isEmpty) return 'Alguien';
    final profile = Map<String, dynamic>.from((match.first['profiles'] ?? {}) as Map);
    final name = (profile['full_name'] ?? profile['email'] ?? 'Alguien').toString();
    return name.split(' ').first;
  }
}

class _PayerSelect extends StatelessWidget {
  final List<Map<String, dynamic>> members;
  final String? value;
  final ValueChanged<String?> onChanged;
  const _PayerSelect({required this.members, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: const InputDecoration(labelText: 'Pagado por'),
      items: members.map((m) {
        final profile = Map<String, dynamic>.from((m['profiles'] ?? {}) as Map);
        final name = (profile['full_name'] ?? profile['email'] ?? 'Usuario').toString();
        return DropdownMenuItem(value: m['user_id'].toString(), child: Text(name, overflow: TextOverflow.ellipsis));
      }).toList(),
      onChanged: onChanged,
    );
  }
}

class _SplitButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _SplitButton({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? AppColors.tealSoft : AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: active ? AppColors.teal : AppColors.border),
        ),
        child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: active ? AppColors.tealDark : AppColors.textMuted, fontWeight: FontWeight.w800)),
      ),
    );
  }
}
