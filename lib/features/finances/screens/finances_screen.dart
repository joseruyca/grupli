import 'package:flutter/material.dart';
import '../../../core/errors.dart';
import '../../../core/supabase_client.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../ui/app_card.dart';
import '../../../ui/app_header.dart';
import '../../../ui/app_ui_helpers.dart';
import '../../../ui/avatar.dart';
import '../../../ui/bottom_sheet.dart';
import '../../../ui/buttons.dart';
import '../../../ui/empty_state.dart';
import '../../../ui/inputs.dart';
import '../../../ui/loading_state.dart';
import '../../../ui/status_chip.dart';
import '../../../ui/toast.dart';
import '../../../ui/group_page_scaffold.dart';
import '../../../shared/utils/formatters.dart';
import '../finance_calculator.dart';
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
    final expenses = await repo.expenses(widget.groupId);
    final memberRows = await repo.groupMembers(widget.groupId);
    final settlements = await repo.settlements(widget.groupId);
    final members = FinanceCalculator.membersFromRows(memberRows);
    final balances = FinanceCalculator.balances(
      expenses: expenses,
      settlements: settlements,
      members: members,
    );
    return _FinanceData(
      expenses: expenses,
      settlements: settlements,
      members: members,
      balances: balances,
    );
  }

  void _refresh() => setState(() => _future = _load());

  Future<void> _expenseAction(String action, Map<String, dynamic> expense) async {
    final repo = FinancesRepository();
    final id = expense['id'].toString();
    try {
      if (action == 'paid') await repo.markExpensePaid(id);
      if (action == 'reopen') await repo.reopenExpense(id);
      if (action == 'cancel') await repo.cancelExpense(id);
      if (action == 'delete') await repo.deleteExpense(id);
      _refresh();
    } catch (e) {
      if (mounted) AppToast.show(context, humanError(e), error: true);
    }
  }

  Future<void> _settlementAction(String action, Map<String, dynamic> settlement) async {
    final repo = FinancesRepository();
    final id = settlement['id'].toString();
    try {
      if (action == 'paid') await repo.markSettlementPaid(id);
      if (action == 'cancel') await repo.cancelSettlement(id);
      _refresh();
    } catch (e) {
      if (mounted) AppToast.show(context, humanError(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GroupPageScaffold(
      groupId: widget.groupId,
      navIndex: 2,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AppHeader(
          title: 'Finanzas',
          subtitle: 'Gastos, balances y pagos sin confusión.',
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
            final currentUserId = SupabaseService.currentUser?.id;
            final myBalance = currentUserId == null
                ? 0.0
                : FinanceCalculator.netForUser(
                    userId: currentUserId,
                    expenses: data.expenses,
                    settlements: data.settlements,
                  );
            final totalPending = FinanceCalculator.totalPending(data.expenses);
            final pendingExpenses = data.expenses.where((e) => (e['status'] ?? 'pending') == 'pending').length;

            final filteredExpenses = data.expenses.where((e) {
              final status = (e['status'] ?? 'pending').toString();
              if (_filter == 'Pendientes') return status == 'pending';
              if (_filter == 'Pagados') return status == 'paid';
              if (_filter == 'Cancelados') return status == 'cancelled';
              return true;
            }).toList();

            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: _SummaryCard(
                    label: 'Tu saldo',
                    value: Fmt.money.format(myBalance),
                    helper: myBalance >= 0 ? 'A tu favor' : 'Debes dinero',
                    color: myBalance >= 0 ? AppColors.success : AppColors.danger,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _SummaryCard(
                    label: 'Pendiente',
                    value: Fmt.money.format(totalPending),
                    helper: '$pendingExpenses gastos abiertos',
                    color: AppColors.teal,
                  ),
                ),
              ]),
              const SizedBox(height: AppSpacing.md),
              Row(children: [
                Expanded(
                  child: SecondaryButton(
                    label: 'Registrar pago',
                    icon: Icons.payments_outlined,
                    onPressed: data.members.length < 2
                        ? null
                        : () => showAppBottomSheet(
                              context,
                              CreateSettlementSheet(groupId: widget.groupId, members: data.members),
                            ).then((_) => _refresh()),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: PrimaryButton(
                    label: 'Nuevo gasto',
                    icon: Icons.add_rounded,
                    onPressed: () => showAppBottomSheet(context, CreateExpenseSheet(groupId: widget.groupId)).then((_) => _refresh()),
                  ),
                ),
              ]),
              const SizedBox(height: AppSpacing.xl),
              SectionTitle(title: 'Quién debe a quién'),
              const SizedBox(height: AppSpacing.sm),
              if (data.balances.isEmpty)
                InfoPanel(
                  icon: Icons.balance_rounded,
                  title: 'Todo está equilibrado',
                  body: 'No hay deudas pendientes. Cuando se creen gastos, aparecerán aquí simplificados.',
                  color: AppColors.teal,
                )
              else
                ...data.balances.map((balance) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _BalanceCard(
                        balance: balance,
                        onRegister: () => showAppBottomSheet(
                          context,
                          CreateSettlementSheet(
                            groupId: widget.groupId,
                            members: data.members,
                            initialFrom: balance.fromUserId,
                            initialTo: balance.toUserId,
                            initialAmount: balance.amount,
                          ),
                        ).then((_) => _refresh()),
                      ),
                    )),
              const SizedBox(height: AppSpacing.lg),
              SectionTitle(title: 'Pagos registrados'),
              const SizedBox(height: AppSpacing.sm),
              if (data.settlements.isEmpty)
                AppCard(child: Text('Todavía no se ha registrado ningún pago entre miembros.', style: AppTypography.muted))
              else
                ...data.settlements.take(4).map((settlement) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _SettlementCard(
                        settlement: settlement,
                        members: data.members,
                        onAction: (action) => _settlementAction(action, settlement),
                      ),
                    )),
              const SizedBox(height: AppSpacing.lg),
              SectionTitle(title: 'Movimientos'),
              const SizedBox(height: AppSpacing.sm),
              _FilterRow(
                selected: _filter,
                values: const ['Todos', 'Pendientes', 'Pagados', 'Cancelados'],
                onChanged: (value) => setState(() => _filter = value),
              ),
              const SizedBox(height: AppSpacing.md),
              if (filteredExpenses.isEmpty)
                EmptyState(icon: Icons.receipt_long_rounded, title: 'Sin gastos', body: 'Añade el primer gasto del grupo.')
              else
                ...filteredExpenses.map((expense) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _ExpenseCard(
                        expense: expense,
                        members: data.members,
                        onAction: (action) => _expenseAction(action, expense),
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
  final List<Map<String, dynamic>> settlements;
  final List<FinanceMember> members;
  final List<FinanceBalance> balances;

  const _FinanceData({
    required this.expenses,
    required this.settlements,
    required this.members,
    required this.balances,
  });
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final String helper;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.helper,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      color: color.withOpacity(0.08),
      border: BorderSide(color: color.withOpacity(0.15)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: AppTypography.small.copyWith(color: AppColors.navy)),
        const SizedBox(height: 8),
        Text(value, style: AppTypography.section.copyWith(color: color, fontSize: 22)),
        const SizedBox(height: 4),
        Text(helper, style: AppTypography.small),
      ]),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final FinanceBalance balance;
  final VoidCallback onRegister;

  const _BalanceCard({required this.balance, required this.onRegister});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const SoftIconBox(icon: Icons.compare_arrows_rounded, color: AppColors.amber, size: 42),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: AppTypography.body,
                children: [
                  TextSpan(text: balance.fromName, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.navy)),
                  const TextSpan(text: ' debe a '),
                  TextSpan(text: balance.toName, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.navy)),
                ],
              ),
            ),
          ),
          Text(
            Fmt.money.format(balance.amount),
            style: AppTypography.body.copyWith(color: AppColors.danger, fontWeight: FontWeight.w900),
          ),
        ]),
        const SizedBox(height: AppSpacing.md),
        SecondaryButton(label: 'Registrar pago', icon: Icons.payments_outlined, onPressed: onRegister),
      ]),
    );
  }
}

class _SettlementCard extends StatelessWidget {
  final Map<String, dynamic> settlement;
  final List<FinanceMember> members;
  final ValueChanged<String> onAction;

  const _SettlementCard({
    required this.settlement,
    required this.members,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final fromName = FinanceCalculator.memberName(members, settlement['from_user']?.toString());
    final toName = FinanceCalculator.memberName(members, settlement['to_user']?.toString());
    final amount = FinanceCalculator.amountOf(settlement['amount']);
    final status = (settlement['status'] ?? 'pending').toString();

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        SoftIconBox(
          icon: status == 'paid' ? Icons.check_rounded : Icons.schedule_rounded,
          color: status == 'paid' ? AppColors.success : AppColors.warning,
          size: 40,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$fromName pagó a $toName', style: AppTypography.body.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 3),
            Text(_date(settlement['created_at']), style: AppTypography.small),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(Fmt.money.format(amount), style: AppTypography.body.copyWith(fontWeight: FontWeight.w900, color: AppColors.navy)),
          const SizedBox(height: 4),
          StatusChip(label: _statusLabel(status), color: _statusColor(status)),
        ]),
        PopupMenuButton<String>(
          onSelected: onAction,
          itemBuilder: (_) => [
            if (status == 'pending') const PopupMenuItem(value: 'paid', child: Text('Marcar pagado')),
            if (status != 'cancelled') const PopupMenuItem(value: 'cancel', child: Text('Cancelar')),
          ],
        ),
      ]),
    );
  }
}

class _ExpenseCard extends StatelessWidget {
  final Map<String, dynamic> expense;
  final List<FinanceMember> members;
  final ValueChanged<String> onAction;

  const _ExpenseCard({
    required this.expense,
    required this.members,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final amount = FinanceCalculator.amountOf(expense['amount']);
    final paidBy = FinanceCalculator.memberName(members, expense['paid_by']?.toString());
    final status = (expense['status'] ?? 'pending').toString();
    final participants = List<Map<String, dynamic>>.from((expense['expense_participants'] ?? []) as List);

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SoftIconBox(icon: Icons.receipt_long_rounded, color: AppColors.lilac, size: 44),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(expense['concept']?.toString() ?? 'Gasto', style: AppTypography.body.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text('${_date(expense['created_at'])} · $paidBy pagó', style: AppTypography.small),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              MetaPill(icon: Icons.people_outline_rounded, text: '${participants.length} participantes'),
              MetaPill(icon: Icons.splitscreen_rounded, text: _shareText(amount, participants)),
            ]),
          ]),
        ),
        const SizedBox(width: AppSpacing.sm),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(Fmt.money.format(amount), style: AppTypography.body.copyWith(fontWeight: FontWeight.w900, color: AppColors.navy)),
          const SizedBox(height: 6),
          StatusChip(label: _statusLabel(status), color: _statusColor(status)),
        ]),
        PopupMenuButton<String>(
          onSelected: onAction,
          itemBuilder: (_) => [
            if (status == 'pending') const PopupMenuItem(value: 'paid', child: Text('Marcar pagado')),
            if (status == 'paid') const PopupMenuItem(value: 'reopen', child: Text('Reabrir')),
            if (status != 'cancelled') const PopupMenuItem(value: 'cancel', child: Text('Cancelar')),
            const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
          ],
        ),
      ]),
    );
  }

  String _shareText(double amount, List<Map<String, dynamic>> participants) {
    if (participants.isEmpty) return 'Sin reparto';
    return '${Fmt.money.format(amount / participants.length)} c/u';
  }
}

class _FilterRow extends StatelessWidget {
  final String selected;
  final List<String> values;
  final ValueChanged<String> onChanged;

  const _FilterRow({
    required this.selected,
    required this.values,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: values.map((value) {
        final active = selected == value;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => onChanged(value),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: active ? AppColors.teal : AppColors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: active ? AppColors.teal : AppColors.border),
              ),
              child: Text(
                value,
                style: TextStyle(color: active ? Colors.white : AppColors.textMuted, fontWeight: FontWeight.w800, fontSize: 12),
              ),
            ),
          ),
        );
      }).toList()),
    );
  }
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
  List<FinanceMember> _members = [];
  final Set<String> _selected = {};
  final Map<String, TextEditingController> _manualShares = {};
  String? _payer;
  bool _loading = true;
  bool _saving = false;
  bool _manual = false;

  @override
  void initState() {
    super.initState();
    _amount.addListener(_recalculateEqualShares);
    _loadMembers();
  }

  @override
  void dispose() {
    _concept.dispose();
    _amount.dispose();
    _note.dispose();
    for (final controller in _manualShares.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadMembers() async {
    try {
      final rows = await FinancesRepository().groupMembers(widget.groupId);
      final members = FinanceCalculator.membersFromRows(rows);
      setState(() {
        _members = members;
        _selected.addAll(members.map((m) => m.userId));
        _payer = members.isEmpty ? null : members.first.userId;
        for (final member in members) {
          _manualShares[member.userId] = TextEditingController();
        }
        _loading = false;
      });
      _recalculateEqualShares();
    } catch (e) {
      if (mounted) AppToast.show(context, humanError(e), error: true);
      if (mounted) setState(() => _loading = false);
    }
  }

  void _recalculateEqualShares() {
    if (_manual) return;
    final amount = _amountValue;
    if (amount == null || _selected.isEmpty) return;
    final share = amount / _selected.length;
    for (final entry in _manualShares.entries) {
      entry.value.text = _selected.contains(entry.key) ? share.toStringAsFixed(2) : '0.00';
    }
  }

  double? get _amountValue => double.tryParse(_amount.text.replaceAll(',', '.'));

  Map<String, double> _shares() {
    final amount = _amountValue ?? 0;
    if (!_manual) {
      final share = _selected.isEmpty ? 0.0 : amount / _selected.length;
      return {for (final id in _selected) id: double.parse(share.toStringAsFixed(2))};
    }

    final result = <String, double>{};
    for (final id in _selected) {
      final value = double.tryParse((_manualShares[id]?.text ?? '').replaceAll(',', '.')) ?? 0;
      result[id] = value;
    }
    return result;
  }

  double _sumShares() => _shares().values.fold<double>(0, (sum, value) => sum + value);

  Future<void> _create() async {
    if (_saving || _concept.text.trim().isEmpty || _selected.isEmpty || _payer == null) return;
    final amount = _amountValue;
    if (amount == null || amount <= 0) {
      AppToast.show(context, 'Introduce un importe válido.', error: true);
      return;
    }
    final shares = _shares();
    if ((shares.values.fold<double>(0, (sum, value) => sum + value) - amount).abs() > 0.05) {
      AppToast.show(context, 'La suma del reparto debe coincidir con el total.', error: true);
      return;
    }

    setState(() => _saving = true);
    try {
      await FinancesRepository().createExpense(
        groupId: widget.groupId,
        concept: _concept.text,
        amount: amount,
        paidBy: _payer!,
        shares: shares,
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
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
        Text('Toca para incluir/excluir', style: AppTypography.small.copyWith(color: AppColors.textMuted)),
      ]),
      const SizedBox(height: AppSpacing.sm),
      Wrap(spacing: 10, runSpacing: 10, children: [
        ..._members.map((member) {
          final active = _selected.contains(member.userId);
          return GestureDetector(
            onTap: () {
              setState(() {
                active ? _selected.remove(member.userId) : _selected.add(member.userId);
                _recalculateEqualShares();
              });
            },
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Opacity(opacity: active ? 1 : 0.35, child: MemberAvatar(url: null, fallback: member.name, size: 42)),
              const SizedBox(height: 4),
              SizedBox(width: 62, child: Text(member.name.split(' ').first, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: AppTypography.small)),
            ]),
          );
        }),
      ]),
      const SizedBox(height: AppSpacing.md),
      Row(children: [
        Expanded(child: _SplitButton(label: 'Reparto igual', active: !_manual, onTap: () => setState(() { _manual = false; _recalculateEqualShares(); }))),
        const SizedBox(width: 8),
        Expanded(child: _SplitButton(label: 'Manual', active: _manual, onTap: () => setState(() => _manual = true))),
      ]),
      if (_manual) ...[
        const SizedBox(height: AppSpacing.md),
        AppCard(
          color: AppColors.canvasWarm,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Importes personalizados', style: AppTypography.body.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: AppSpacing.sm),
            ..._members.where((m) => _selected.contains(m.userId)).map((member) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(children: [
                    Expanded(child: Text(member.name, style: AppTypography.muted)),
                    SizedBox(
                      width: 110,
                      child: TextField(
                        controller: _manualShares[member.userId],
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: '0,00'),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ]),
                )),
            const Divider(),
            DataLine(label: 'Suma', value: Fmt.money.format(_sumShares()), valueColor: (_amountValue != null && (_sumShares() - _amountValue!).abs() <= 0.05) ? AppColors.success : AppColors.danger),
          ]),
        ),
      ],
      const SizedBox(height: AppSpacing.md),
      AppTextField(controller: _note, label: 'Nota', hint: 'Para la comida y las bebidas', maxLines: 2),
      if (share != null && !_manual) ...[
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
    final match = _members.where((m) => m.userId == _payer).toList();
    if (match.isEmpty) return 'Alguien';
    return match.first.name.split(' ').first;
  }
}

class CreateSettlementSheet extends StatefulWidget {
  final String groupId;
  final List<FinanceMember> members;
  final String? initialFrom;
  final String? initialTo;
  final double? initialAmount;

  const CreateSettlementSheet({
    super.key,
    required this.groupId,
    required this.members,
    this.initialFrom,
    this.initialTo,
    this.initialAmount,
  });

  @override
  State<CreateSettlementSheet> createState() => _CreateSettlementSheetState();
}

class _CreateSettlementSheetState extends State<CreateSettlementSheet> {
  final _amount = TextEditingController();
  String? _from;
  String? _to;
  bool _saving = false;
  bool _paidNow = true;

  @override
  void initState() {
    super.initState();
    _from = widget.initialFrom ?? (widget.members.isNotEmpty ? widget.members.first.userId : null);
    _to = widget.initialTo ?? (widget.members.length > 1 ? widget.members[1].userId : null);
    if (widget.initialAmount != null) _amount.text = widget.initialAmount!.toStringAsFixed(2);
  }

  Future<void> _create() async {
    final amount = double.tryParse(_amount.text.replaceAll(',', '.'));
    if (_saving || _from == null || _to == null || amount == null || amount <= 0) return;
    setState(() => _saving = true);
    try {
      await FinancesRepository().createSettlement(
        groupId: widget.groupId,
        fromUser: _from!,
        toUser: _to!,
        amount: amount,
        status: _paidNow ? 'paid' : 'pending',
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
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Registrar pago', style: AppTypography.section),
      const SizedBox(height: AppSpacing.lg),
      _MemberSelect(label: 'Quién paga', members: widget.members, value: _from, onChanged: (v) => setState(() => _from = v)),
      const SizedBox(height: AppSpacing.md),
      _MemberSelect(label: 'Quién recibe', members: widget.members, value: _to, onChanged: (v) => setState(() => _to = v)),
      const SizedBox(height: AppSpacing.md),
      AppTextField(controller: _amount, label: 'Importe', hint: '10,00', keyboardType: TextInputType.number),
      const SizedBox(height: AppSpacing.md),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: _paidNow,
        onChanged: (v) => setState(() => _paidNow = v),
        title: Text('Marcar como pagado ahora', style: AppTypography.body.copyWith(fontWeight: FontWeight.w800)),
        subtitle: Text('Si lo dejas pendiente, podrás marcarlo pagado después.', style: AppTypography.small),
        activeColor: AppColors.teal,
      ),
      const SizedBox(height: AppSpacing.lg),
      PrimaryButton(label: 'Guardar pago', loading: _saving, onPressed: _create),
    ]);
  }
}

class _PayerSelect extends StatelessWidget {
  final List<FinanceMember> members;
  final String? value;
  final ValueChanged<String?> onChanged;

  const _PayerSelect({
    required this.members,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _MemberSelect(label: 'Pagado por', members: members, value: value, onChanged: onChanged);
  }
}

class _MemberSelect extends StatelessWidget {
  final String label;
  final List<FinanceMember> members;
  final String? value;
  final ValueChanged<String?> onChanged;

  const _MemberSelect({
    required this.label,
    required this.members,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(labelText: label),
      items: members.map((member) {
        return DropdownMenuItem(value: member.userId, child: Text(member.name, overflow: TextOverflow.ellipsis));
      }).toList(),
      onChanged: onChanged,
    );
  }
}

class _SplitButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _SplitButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

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

String _date(Object? raw) {
  if (raw == null) return 'Sin fecha';
  try {
    return Fmt.day.format(DateTime.parse(raw.toString()));
  } catch (_) {
    return 'Sin fecha';
  }
}

String _statusLabel(String status) => switch (status) {
      'paid' => 'Pagado',
      'cancelled' => 'Cancelado',
      _ => 'Pendiente',
    };

Color _statusColor(String status) => switch (status) {
      'paid' => AppColors.success,
      'cancelled' => AppColors.textMuted,
      _ => AppColors.danger,
    };
