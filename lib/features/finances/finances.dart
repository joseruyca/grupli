part of grupli_app;

class FinancesTab extends StatefulWidget {
  final Map<String, dynamic> group;
  final int refreshSeed;
  const FinancesTab({super.key, required this.group, required this.refreshSeed});
  @override
  State<FinancesTab> createState() => _FinancesTabState();
}

class _FinancesTabState extends State<FinancesTab> {
  late Future<_FinanceData> future;
  int financeSection = 0;
  bool savingSettlement = false;
  bool cancellingSettlement = false;

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void didUpdateWidget(covariant FinancesTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshSeed != widget.refreshSeed) load();
  }

  void load() => future = _FinanceData.load(widget.group['id'].toString());
  void reload() => setState(load);

  Future<void> openCreate() async {
    final ok = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => CreateExpenseScreen(groupId: widget.group['id'].toString())));
    if (ok == true) reload();
  }

  Future<void> openFinanceInsights(_FinanceData data) async {
    final entitlement = GrupliPremium.entitlementForGroup(widget.group);
    if (!entitlement.canUse('finance_insights')) {
      await showPremiumFeatureGate(context, group: widget.group, featureKey: 'finance_insights');
      return;
    }
    await showFinanceInsightsSheet(context, data: data);
  }

  Future<void> markSettlementPaid(SettlementDebt debt) async {
    final confirmed = await confirmAction(
      context,
      title: 'Liquidar pago',
      body: '${debt.fromName} pagó a ${debt.toName} ${money(debt.amount)}. Esto actualizará el balance neto del grupo.',
      confirmLabel: 'Liquidar',
    );
    if (confirmed != true) return;

    setState(() => savingSettlement = true);
    try {
      await AppData.createSettlementPayment(widget.group['id'].toString(), debt.fromId, debt.toId, debt.amount);
      reload();
      if (mounted) await showToast(context, 'Liquidación registrada.');
    } catch (e) {
      if (mounted) await showToast(context, humanError(e), danger: true);
    } finally {
      if (mounted) setState(() => savingSettlement = false);
    }
  }

  Future<void> undoSettlementPayment(Map<String, dynamic> payment) async {
    final amount = AppData.doubleValue(payment['amount']);
    final confirmed = await confirmAction(
      context,
      title: 'Deshacer liquidación',
      body: 'El pago de ${money(amount)} volverá a contarse como pendiente en el balance del grupo.',
      confirmLabel: 'Deshacer',
      danger: true,
    );
    if (confirmed != true) return;

    setState(() => cancellingSettlement = true);
    try {
      await AppData.cancelSettlementPayment(AppData.text(payment['id']));
      reload();
      if (mounted) await showToast(context, 'Liquidación deshecha.');
    } catch (e) {
      if (mounted) await showToast(context, humanError(e), danger: true);
    } finally {
      if (mounted) setState(() => cancellingSettlement = false);
    }
  }


  void openBalanceDetail(String userId, _FinanceData data) {
    final summary = data.summary;
    final name = summary.names[userId] ?? financeMemberName(userId, data.members);
    final avatar = summary.avatars[userId] ?? financeMemberAvatarUrl(userId, data.members);
    final balance = summary.balances[userId] ?? 0;
    final toPay = summary.settlements.where((d) => d.fromId == userId).toList();
    final toReceive = summary.settlements.where((d) => d.toId == userId).toList();
    final relatedExpenses = data.expenses.where((expense) {
      final paidBy = AppData.text(expense['paid_by']);
      if (paidBy == userId) return true;
      return expenseParticipants(expense).any((p) => AppData.text(p['user_id']) == userId);
    }).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .82,
        minChildSize: .45,
        maxChildSize: .94,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          children: [
            Row(children: [
              ProfileAvatar(name: name, avatarUrl: avatar, radius: 25),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 3),
                Text(
                  balance > .01 ? 'Le deben ${money(balance)}' : balance < -.01 ? 'Debe ${money(balance.abs())}' : 'Está a cero',
                  style: TextStyle(color: balance > .01 ? AppColors.green : balance < -.01 ? AppColors.red : AppColors.muted, fontWeight: FontWeight.w900),
                ),
              ])),
            ]),
            const SizedBox(height: 18),
            if (toPay.isEmpty && toReceive.isEmpty)
              EmptySlim(icon: Icons.verified_rounded, title: 'Sin pagos pendientes', body: 'Esta persona no tiene que mover dinero ahora mismo.')
            else ...[
              if (toPay.isNotEmpty) ...[
                SectionHeader(title: 'Tiene que pagar', action: '${toPay.length}'),
                const SizedBox(height: 8),
                AppCard(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(children: [
                    for (int i = 0; i < toPay.length; i++) ...[
                      SettlementPaymentRow(debt: toPay[i], onPaid: savingSettlement ? null : () {
                        Navigator.pop(context);
                        markSettlementPaid(toPay[i]);
                      }),
                      if (i != toPay.length - 1) const Divider(height: 1, indent: 76, color: AppColors.line),
                    ],
                  ]),
                ),
                const SizedBox(height: 14),
              ],
              if (toReceive.isNotEmpty) ...[
                SectionHeader(title: 'Tiene que recibir', action: '${toReceive.length}'),
                const SizedBox(height: 8),
                AppCard(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(children: [
                    for (int i = 0; i < toReceive.length; i++) ...[
                      SettlementPaymentRow(debt: toReceive[i], onPaid: savingSettlement ? null : () {
                        Navigator.pop(context);
                        markSettlementPaid(toReceive[i]);
                      }),
                      if (i != toReceive.length - 1) const Divider(height: 1, indent: 76, color: AppColors.line),
                    ],
                  ]),
                ),
                const SizedBox(height: 14),
              ],
            ],
            SectionHeader(title: 'Movimientos relacionados', action: '${relatedExpenses.length}'),
            const SizedBox(height: 8),
            if (relatedExpenses.isEmpty)
              EmptySlim(icon: Icons.receipt_long_rounded, title: 'Sin gastos relacionados', body: 'No aparece en ningún gasto del grupo.')
            else
              ...relatedExpenses.take(8).map((expense) => ExpenseCard(
                expense: expense,
                members: data.members,
                onTap: () async {
                  Navigator.pop(context);
                  final ok = await Navigator.of(this.context).push<bool>(MaterialPageRoute(builder: (_) => ExpenseDetailScreen(expense: expense, members: data.members)));
                  if (ok == true) reload();
                },
              )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Stack(children: [
        FutureBuilder<_FinanceData>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CenterLoader(label: 'Calculando balances...');
            }
            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
                children: [ErrorBlock(message: snapshot.error.toString(), onRetry: reload)],
              );
            }

            final data = snapshot.data ?? _FinanceData.empty();
            final summary = data.summary;
            final hasMovements = data.expenses.isNotEmpty || data.settlementPayments.isNotEmpty;
            final balanceEntries = summary.sortedBalances;
            final premium = GrupliPremium.entitlementForGroup(widget.group);

            return RefreshIndicator(
              color: AppColors.green,
              onRefresh: () async => reload(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 112),
                children: [
                  PageHeader(title: 'Finanzas', subtitle: 'Gastos, deudas y pagos del grupo.', leading: false),
                  const SizedBox(height: 14),
                  FinanceHeroCard(summary: summary, onCreate: openCreate),
                  const SizedBox(height: 12),
                  FinanceHumanNextStepCard(
                    summary: summary,
                    expensesCount: data.expenses.length,
                    settledCount: data.settlementPayments.length,
                    onCreate: openCreate,
                  ),
                  const SizedBox(height: 12),
                  premium.canUse('finance_insights')
                      ? FinanceAdvancedInsightsCard(
                          summary: summary,
                          data: data,
                          onOpen: () => openFinanceInsights(data),
                        )
                      : FinancePremiumTeaserCard(
                          onOpen: () => openFinanceInsights(data),
                        ),
                  const SizedBox(height: 12),
                  FinanceSegmentedTabs(index: financeSection, onChanged: (i) => setState(() => financeSection = i > 1 ? 1 : i)),
                  const SizedBox(height: 14),
                  if (financeSection == 0) ...[
                    SectionHeader(title: 'Movimientos', action: hasMovements ? '${data.expenses.length + data.settlementPayments.length}' : '0'),
                    const SizedBox(height: 8),
                    if (!hasMovements)
                      EmptyBlock(icon: Icons.receipt_long_rounded, title: 'Aún no hay movimientos', body: 'Añade el primer gasto. Aquí verás lo que se ha pagado y si falta algo por liquidar.')
                    else ...[
                      if (data.expenses.isNotEmpty) ...[
                        SectionHeader(title: 'Gastos pagados', action: 'Total ${money(summary.totalExpenses)}'),
                        const SizedBox(height: 8),
                        ...data.expenses.map((e) => ExpenseCard(
                          expense: e,
                          members: data.members,
                          onTap: () async {
                            final ok = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => ExpenseDetailScreen(expense: e, members: data.members)));
                            if (ok == true) reload();
                          },
                        )),
                      ],
                      if (data.settlementPayments.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        SectionHeader(title: 'Pagos registrados', action: '${data.settlementPayments.length}'),
                        const SizedBox(height: 8),
                        AppCard(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(children: [
                            for (int i = 0; i < data.settlementPayments.length; i++) ...[
                              SettlementHistoryRow(
                                payment: data.settlementPayments[i],
                                members: data.members,
                                onCancel: cancellingSettlement ? null : () => undoSettlementPayment(data.settlementPayments[i]),
                              ),
                              if (i != data.settlementPayments.length - 1) const Divider(height: 1, indent: 76, color: AppColors.line),
                            ],
                          ]),
                        ),
                      ],
                    ],
                  ] else ...[
                    FinanceAutoBalanceCard(summary: summary, openCount: data.expenses.length, settledCount: data.settlementPayments.length),
                    const SizedBox(height: 12),
                    FinanceBalanceBarsCard(summary: summary),
                    const SizedBox(height: 16),
                    SectionHeader(title: 'Saldos', action: balanceEntries.isEmpty ? 'Todo a cero' : '${balanceEntries.length} personas'),
                    const SizedBox(height: 8),
                    if (balanceEntries.isEmpty)
                      EmptyBlock(icon: Icons.verified_rounded, title: 'Todo queda a cero', body: 'No hay deudas pendientes entre miembros.')
                    else
                      AppCard(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(children: [
                          for (int i = 0; i < balanceEntries.length; i++) ...[
                            FinanceBalanceMemberRow(
                              userId: balanceEntries[i].key,
                              name: summary.names[balanceEntries[i].key] ?? 'Miembro',
                              avatarUrl: summary.avatars[balanceEntries[i].key] ?? '',
                              balance: balanceEntries[i].value,
                              onTap: () => openBalanceDetail(balanceEntries[i].key, data),
                            ),
                            if (i != balanceEntries.length - 1) const Divider(height: 1, indent: 76, color: AppColors.line),
                          ],
                        ]),
                      ),
                    const SizedBox(height: 14),
                    SectionHeader(title: 'Pagos recomendados', action: summary.settlements.isEmpty ? '0' : '${summary.settlements.length}'),
                    const SizedBox(height: 8),
                    if (summary.settlements.isEmpty)
                      EmptySlim(icon: Icons.verified_rounded, title: 'No hay nada que pagar', body: 'Los saldos del grupo están compensados.')
                    else
                      AppCard(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(children: [
                          for (int i = 0; i < summary.settlements.length; i++) ...[
                            SettlementPaymentRow(
                              debt: summary.settlements[i],
                              onPaid: savingSettlement ? null : () => markSettlementPaid(summary.settlements[i]),
                            ),
                            if (i != summary.settlements.length - 1) const Divider(height: 1, indent: 76, color: AppColors.line),
                          ],
                        ]),
                      ),
                  ],
                ],
              ),
            );
          },
        ),
        Positioned(
          right: 20,
          bottom: 20,
          child: FloatingActionButton.extended(
            backgroundColor: AppColors.green,
            foregroundColor: Colors.white,
            onPressed: openCreate,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Gasto', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ),
      ]),
    );
  }
}

class CreateExpenseScreen extends StatefulWidget {
  final String groupId;
  final Map<String, dynamic>? expense;
  const CreateExpenseScreen({super.key, required this.groupId, this.expense});
  bool get editing => expense != null;
  @override
  State<CreateExpenseScreen> createState() => _CreateExpenseScreenState();
}

class _CreateExpenseScreenState extends State<CreateExpenseScreen> {
  final concept = TextEditingController();
  final amount = TextEditingController();
  final note = TextEditingController();
  bool loading = false;
  bool initialized = false;
  String? paidBy;
  String splitMode = 'all';
  final selected = <String>{};
  final customShares = <String, TextEditingController>{};
  late Future<List<Map<String, dynamic>>> membersFuture;

  @override
  void initState() {
    super.initState();
    final editingExpense = widget.expense;
    if (editingExpense != null) {
      concept.text = AppData.text(editingExpense['concept']);
      final value = AppData.doubleValue(editingExpense['amount']);
      amount.text = value > 0 ? value.toStringAsFixed(2).replaceAll('.', ',') : '';
      note.text = AppData.text(editingExpense['note']);
      splitMode = 'custom';
    }
    membersFuture = AppData.members(widget.groupId);
    amount.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    concept.dispose();
    amount.dispose();
    note.dispose();
    for (final controller in customShares.values) {
      controller.dispose();
    }
    super.dispose();
  }

  double get amountValue => double.tryParse(amount.text.replaceAll(',', '.')) ?? 0;

  void initMembers(List<Map<String, dynamic>> members) {
    if (initialized || members.isEmpty) return;
    final editingExpense = widget.expense;
    if (editingExpense != null) {
      paidBy = AppData.text(editingExpense['paid_by']);
      final participants = expenseParticipants(editingExpense);
      selected
        ..clear()
        ..addAll(participants.map((p) => p['user_id'].toString()));
      if (paidBy != null && paidBy!.isNotEmpty) selected.add(paidBy!);
      for (final member in members) {
        final id = member['user_id'].toString();
        final participant = participants.where((p) => p['user_id']?.toString() == id).toList();
        final controller = TextEditingController();
        if (participant.isNotEmpty) {
          final share = AppData.doubleValue(participant.first['share_amount']);
          controller.text = share > 0 ? share.toStringAsFixed(2).replaceAll('.', ',') : '';
        }
        customShares[id] = controller;
      }
    } else {
      paidBy = members.any((m) => m['user_id']?.toString() == AppData.user?.id) ? AppData.user?.id : members.first['user_id'].toString();
      selected.addAll(members.map((m) => m['user_id'].toString()));
      for (final member in members) {
        final id = member['user_id'].toString();
        customShares[id] = TextEditingController();
      }
    }
    initialized = true;
  }

  void setMode(String mode, List<Map<String, dynamic>> members) {
    setState(() {
      splitMode = mode;
      if (mode == 'all') {
        selected
          ..clear()
          ..addAll(members.map((m) => m['user_id'].toString()));
      }
      if (paidBy != null) selected.add(paidBy!);
      if (mode == 'custom') syncCustomShares(members);
    });
  }

  void syncCustomShares(List<Map<String, dynamic>> members) {
    final ids = selected.toList();
    final equal = ids.isEmpty ? 0.0 : amountValue / ids.length;
    for (final member in members) {
      final id = member['user_id'].toString();
      final controller = customShares.putIfAbsent(id, () => TextEditingController());
      if (selected.contains(id) && controller.text.trim().isEmpty) {
        controller.text = equal > 0 ? equal.toStringAsFixed(2).replaceAll('.', ',') : '';
      }
      if (!selected.contains(id)) controller.text = '';
    }
  }

  double customShareFor(String id) => double.tryParse((customShares[id]?.text ?? '').replaceAll(',', '.')) ?? 0;

  double customTotal() => selected.fold<double>(0, (sum, id) => sum + customShareFor(id));

  Map<String, double> sharesFor(List<Map<String, dynamic>> members) {
    if (splitMode == 'custom') {
      return {for (final id in selected) id: double.parse(customShareFor(id).toStringAsFixed(2))};
    }
    final ids = selected.toList();
    if (ids.isEmpty) return {};
    final totalCents = (amountValue * 100).round();
    final base = totalCents ~/ ids.length;
    var remainder = totalCents - (base * ids.length);
    final result = <String, double>{};
    for (final id in ids) {
      final cents = base + (remainder > 0 ? 1 : 0);
      if (remainder > 0) remainder--;
      result[id] = double.parse((cents / 100).toStringAsFixed(2));
    }
    return result;
  }

  Future<void> save(List<Map<String, dynamic>> members) async {
    final value = amountValue;
    if (concept.text.trim().isEmpty || value <= 0 || paidBy == null || selected.isEmpty) {
      await showToast(context, 'Completa concepto, importe, pagador y participantes.', danger: true);
      return;
    }
    if (splitMode == 'custom') {
      final total = customTotal();
      if ((total - value).abs() > .05) {
        await showToast(context, 'Los importes personalizados deben sumar ${money(value)}.', danger: true);
        return;
      }
    }
    setState(() => loading = true);
    try {
      if (widget.editing) {
        await AppData.updateExpenseWithShares(widget.expense!['id'].toString(), concept.text, value, paidBy!, sharesFor(members), note.text);
      } else {
        await AppData.createExpenseWithShares(widget.groupId, concept.text, value, paidBy!, sharesFor(members), note.text);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      await showToast(context, humanError(e), danger: true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DirectPage(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeader(title: widget.editing ? 'Editar gasto' : 'Nuevo gasto', subtitle: widget.editing ? 'Ajusta importe, pagador o reparto.' : 'Importe, pagador y reparto en pocos pasos.', leading: true),
      const SizedBox(height: 18),
      AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 46, height: 46, decoration: BoxDecoration(color: AppColors.tealSoft, borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.receipt_long_rounded, color: AppColors.teal)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.editing ? 'Actualizar gasto' : '¿Qué se ha pagado?', style: Theme.of(context).textTheme.titleMedium),
            Text(widget.editing ? 'Los cambios recalculan los saldos al guardar.' : 'Elige quién pagó y cómo se reparte.', style: Theme.of(context).textTheme.bodyMedium),
          ])),
        ]),
        const SizedBox(height: 16),
        FieldLabel('Concepto'),
        TextField(controller: concept, decoration: const InputDecoration(hintText: 'Ej. Pista de pádel, cena, gasolina...')),
        const SizedBox(height: 12),
        FieldLabel('Importe total'),
        TextField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(hintText: '0,00 €')),
      ])),
      const SizedBox(height: 14),
      FutureBuilder<List<Map<String, dynamic>>>(
        future: membersFuture,
        builder: (context, snapshot) {
          final members = snapshot.data ?? [];
          initMembers(members);
          final value = amountValue;
          final equalShare = selected.isEmpty ? 0.0 : value / selected.length;
          final custom = customTotal();
          final diff = value - custom;
          if (snapshot.connectionState == ConnectionState.waiting) return const CenterLoader(label: 'Cargando miembros...');
          if (snapshot.hasError) return ErrorBlock(message: snapshot.error.toString(), onRetry: () => setState(() { membersFuture = AppData.members(widget.groupId); }));
          if (members.isEmpty) return EmptyBlock(icon: Icons.groups_rounded, title: 'No hay miembros', body: 'Añade miembros al grupo para poder repartir gastos.');
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              FieldLabel('Pagado por'),
              DropdownButtonFormField<String>(
                value: paidBy,
                items: members.map((m) => DropdownMenuItem(
                  value: m['user_id'].toString(),
                  child: Row(children: [
                    ProfileAvatar(name: memberName(m), avatarUrl: memberAvatarUrl(m), radius: 14),
                    const SizedBox(width: 8),
                    Text(memberName(m)),
                  ]),
                )).toList(),
                onChanged: (v) => setState(() {
                  paidBy = v;
                  if (v != null) selected.add(v);
                  if (splitMode == 'custom') syncCustomShares(members);
                }),
              ),
            ])),
            const SizedBox(height: 14),
            AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              FieldLabel('Reparto'),
              Row(children: [
                Expanded(child: ChoicePill(label: 'Todos', active: splitMode == 'all', onTap: () => setMode('all', members))),
                const SizedBox(width: 8),
                Expanded(child: ChoicePill(label: 'Algunos', active: splitMode == 'some', onTap: () => setMode('some', members))),
                const SizedBox(width: 8),
                Expanded(child: ChoicePill(label: 'Manual', active: splitMode == 'custom', onTap: () => setMode('custom', members))),
              ]),
              const SizedBox(height: 12),
              Wrap(spacing: 9, runSpacing: 9, children: members.map((m) {
                final id = m['user_id'].toString();
                final active = selected.contains(id);
                return FilterChip(
                  avatar: ProfileAvatar(name: memberName(m), avatarUrl: memberAvatarUrl(m), radius: 12),
                  label: Text(memberName(m)),
                  selected: active,
                  onSelected: (v) => setState(() {
                    if (splitMode == 'all') splitMode = 'some';
                    if (v) {
                      selected.add(id);
                    } else {
                      selected.remove(id);
                    }
                    if (paidBy != null) selected.add(paidBy!);
                    if (splitMode == 'custom') syncCustomShares(members);
                  }),
                );
              }).toList()),
              if (splitMode == 'custom') ...[
                const SizedBox(height: 14),
                FieldLabel('Importe por persona'),
                ...members.where((m) => selected.contains(m['user_id'].toString())).map((m) {
                  final id = m['user_id'].toString();
                  final controller = customShares.putIfAbsent(id, () => TextEditingController());
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(children: [
                      Expanded(child: Row(children: [
                        ProfileAvatar(name: memberName(m), avatarUrl: memberAvatarUrl(m), radius: 15),
                        const SizedBox(width: 8),
                        Expanded(child: Text(memberName(m), overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900))),
                      ])),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 108,
                        child: TextField(
                          controller: controller,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          textAlign: TextAlign.right,
                          decoration: const InputDecoration(hintText: '0,00'),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ]),
                  );
                }),
              ],
              const SizedBox(height: 12),
              FinanceSplitPreview(
                participants: selected.length,
                amount: value,
                equalShare: equalShare,
                customMode: splitMode == 'custom',
                customTotal: custom,
                diff: diff,
              ),
            ])),
          ]);
        },
      ),
      const SizedBox(height: 14),
      AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        FieldLabel('Nota opcional'),
        TextField(controller: note, maxLines: 3, decoration: const InputDecoration(hintText: 'Ej. Reserva incluida, se pagó con tarjeta...')),
      ])),
      const SizedBox(height: 24),
      FutureBuilder<List<Map<String, dynamic>>>(
        future: membersFuture,
        builder: (context, snapshot) {
          final members = snapshot.data ?? [];
          return PrimaryButton(label: widget.editing ? 'Guardar cambios' : 'Guardar gasto', loading: loading, onTap: () => save(members));
        },
      ),
    ]));
  }
}

class ExpenseDetailScreen extends StatefulWidget {
  final Map<String, dynamic> expense;
  final List<Map<String, dynamic>> members;
  const ExpenseDetailScreen({super.key, required this.expense, required this.members});

  @override
  State<ExpenseDetailScreen> createState() => _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends State<ExpenseDetailScreen> {
  bool loading = false;

  Future<void> run(Future<void> Function() action) async {
    setState(() => loading = true);
    try {
      await action();
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      await showToast(context, humanError(e), danger: true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> editExpense(Map<String, dynamic> expense) async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CreateExpenseScreen(
          groupId: AppData.text(expense['group_id']),
          expense: expense,
        ),
      ),
    );
    if (ok == true && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final expense = widget.expense;
    final expenseId = expense['id'].toString();
    final paidBy = AppData.text(expense['paid_by']);
    final participants = expenseParticipants(expense);
    final total = AppData.doubleValue(expense['amount']);
    final unpaid = unpaidAmount(expense);
    final status = AppData.text(expense['status'], 'pending');
    return DirectPage(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeader(title: AppData.text(expense['concept'], 'Gasto'), subtitle: 'Detalle y pagos', leading: true),
      const SizedBox(height: 18),
      AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          ProfileAvatar(name: financeMemberName(paidBy, widget.members), avatarUrl: financeMemberAvatarUrl(paidBy, widget.members), radius: 22),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(money(total), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: AppColors.ink)),
            Text('Pagado por ${financeMemberName(paidBy, widget.members)}', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700)),
          ])),
          _MiniChip(text: status == 'paid' || unpaid <= .01 ? 'Liquidado' : 'Pendiente', color: status == 'paid' || unpaid <= .01 ? AppColors.green : AppColors.orange),
        ]),
        if (AppData.text(expense['note']).isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(AppData.text(expense['note']), style: Theme.of(context).textTheme.bodyMedium),
        ],
      ])),
      const SizedBox(height: 18),
      SectionHeader(title: 'Participantes y pagos'),
      const SizedBox(height: 8),
      AppCard(child: Column(children: participants.map((p) {
        final userId = p['user_id'].toString();
        final paid = p['paid'] == true;
        final share = AppData.doubleValue(p['share_amount']);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(children: [
            ProfileAvatar(name: financeMemberName(userId, widget.members), avatarUrl: financeMemberAvatarUrl(userId, widget.members), radius: 17),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(financeMemberName(userId, widget.members), style: const TextStyle(fontWeight: FontWeight.w900)),
              Text(userId == paidBy ? 'Pagó el gasto' : paid ? 'Pago registrado' : 'Pendiente de pagar', style: TextStyle(color: paid ? AppColors.green : AppColors.muted, fontSize: 12)),
            ])),
            Text(money(share.toDouble()), style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(width: 8),
            userId == paidBy
                ? const Icon(Icons.payments_rounded, color: AppColors.teal)
                : IconButton(
                    tooltip: paid ? 'Marcar pendiente' : 'Marcar pagado',
                    onPressed: loading ? null : () => run(() => AppData.setExpenseParticipantPaid(expenseId, userId, !paid)),
                    icon: Icon(paid ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, color: paid ? AppColors.green : AppColors.muted),
                  ),
          ]),
        );
      }).toList())),
      const SizedBox(height: 18),
      SecondaryButton(label: 'Editar gasto', icon: Icons.edit_rounded, onTap: loading ? () {} : () => editExpense(expense)),
      const SizedBox(height: 10),
      if (unpaid > .01) PrimaryButton(label: 'Marcar gasto liquidado', icon: Icons.verified_rounded, loading: loading, onTap: () => run(() => AppData.markExpenseSettled(expenseId))),
      if (unpaid <= .01 || status == 'paid') ...[
        SecondaryButton(label: 'Reabrir pagos', icon: Icons.restart_alt_rounded, onTap: () => run(() => AppData.reopenExpense(expenseId))),
      ],
      const SizedBox(height: 10),
      DangerButton(label: 'Eliminar gasto', icon: Icons.delete_outline_rounded, onTap: () => run(() => AppData.deleteExpense(expenseId))),
    ]));
  }
}


class FinanceSegmentedTabs extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  const FinanceSegmentedTabs({super.key, required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const icons = [Icons.receipt_long_rounded, Icons.account_balance_wallet_rounded];
    const labels = ['Movimientos', 'Saldos'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.faint, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.line)),
      child: Row(children: List.generate(labels.length, (i) {
        final selected = index == i;
        return Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(15),
            onTap: () => onChanged(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: selected ? AppColors.green : Colors.transparent,
                borderRadius: BorderRadius.circular(15),
                boxShadow: selected ? const [BoxShadow(color: Color(0x1A073A57), blurRadius: 14, offset: Offset(0, 6))] : null,
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(icons[i], color: selected ? Colors.white : AppColors.muted, size: 17),
                const SizedBox(width: 6),
                Text(labels[i], style: TextStyle(color: selected ? Colors.white : AppColors.ink, fontWeight: FontWeight.w900, fontSize: 12)),
              ]),
            ),
          ),
        );
      })),
    );
  }
}

class FinanceHeroCard extends StatelessWidget {
  final FinanceSummary summary;
  final VoidCallback onCreate;
  const FinanceHeroCard({super.key, required this.summary, required this.onCreate});

  void _showMetricInfo(BuildContext context, String title, String value, String body) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 22),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: AppColors.greenSoft, borderRadius: BorderRadius.circular(15)),
                child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.green, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(color: AppColors.ink, fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(color: AppColors.greenDark, fontSize: 22, fontWeight: FontWeight.w900)),
              ])),
            ]),
            const SizedBox(height: 14),
            Text(body, style: const TextStyle(color: AppColors.muted, fontSize: 13.5, height: 1.35, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            SecondaryButton(label: 'Entendido', icon: Icons.check_rounded, onTap: () => Navigator.pop(context)),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clean = summary.pendingAmount <= .01;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      color: AppColors.greenDark,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(color: Colors.white.withOpacity(.12), borderRadius: BorderRadius.circular(15)),
            child: Icon(clean ? Icons.verified_rounded : Icons.account_balance_wallet_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_financeMainTitle(summary), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 19.5, fontWeight: FontWeight.w900, letterSpacing: -.25, height: 1.08)),
            const SizedBox(height: 4),
            Text(clean ? 'Nadie debe dinero.' : '${summary.settlements.length} pago${summary.settlements.length == 1 ? '' : 's'} recomendado${summary.settlements.length == 1 ? '' : 's'} para cuadrar el grupo.', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xEFFFFFFF), fontSize: 13, fontWeight: FontWeight.w800, height: 1.25)),
          ])),
          const SizedBox(width: 10),
          SizedBox(
            height: 40,
            child: TextButton.icon(
              onPressed: onCreate,
              style: TextButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.greenDark, padding: const EdgeInsets.symmetric(horizontal: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Gasto', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _HeroFinanceMetric(
            label: 'Gastado',
            value: money(summary.totalExpenses),
            onTap: () => _showMetricInfo(context, 'Gastado', money(summary.totalExpenses), 'Suma de todos los gastos registrados en el grupo. Sirve para entender cuánto se ha movido en total, no lo que debe una persona concreta.'),
          )),
          const SizedBox(width: 8),
          Expanded(child: _HeroFinanceMetric(
            label: 'Falta',
            value: money(summary.pendingAmount),
            onTap: () => _showMetricInfo(context, 'Pendiente', money(summary.pendingAmount), 'Dinero que todavía queda por compensar entre miembros. Cuando las liquidaciones se registran correctamente, este valor baja hasta cero.'),
          )),
          const SizedBox(width: 8),
          Expanded(child: _HeroFinanceMetric(
            label: 'Mover',
            value: money(summary.settlementAmount),
            onTap: () => _showMetricInfo(context, 'A mover', money(summary.settlementAmount), 'Cantidad mínima recomendada para liquidar el grupo con el menor número de pagos posible.'),
          )),
        ]),
      ]),
    );
  }
}

class _HeroFinanceMetric extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  const _HeroFinanceMetric({required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(color: Colors.white.withOpacity(.14), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(.16))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xDFFFFFFF), fontSize: 10.5, fontWeight: FontWeight.w800))),
            const Icon(Icons.info_outline_rounded, color: Color(0xDFFFFFFF), size: 13),
          ]),
          const SizedBox(height: 5),
          SizedBox(
            height: 22,
            width: double.infinity,
            child: FittedBox(
              alignment: Alignment.centerLeft,
              fit: BoxFit.scaleDown,
              child: Text(value, maxLines: 1, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
            ),
          ),
        ]),
      ),
    );
  }
}

class FinanceMyStatusCard extends StatelessWidget {
  final FinanceSummary summary;
  final List<SettlementDebt> settlements;
  final VoidCallback onCreate;
  const FinanceMyStatusCard({super.key, required this.summary, required this.settlements, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final color = summary.myNet > 0.01 ? AppColors.green : summary.myNet < -0.01 ? AppColors.red : AppColors.teal;
    final title = summary.myNet > 0.01
        ? 'Te deben ${money(summary.myNet)}'
        : summary.myNet < -0.01
            ? 'Debes ${money(-summary.myNet)}'
            : 'Tú estás a cero';
    final body = settlements.isEmpty
        ? 'No tienes pagos pendientes. Puedes revisar abajo el balance del grupo.'
        : settlements.map((d) => d.fromId == AppData.user?.id ? 'Pagas a ${d.toName}: ${money(d.amount)}' : '${d.fromName} te paga: ${money(d.amount)}').join(' · ');

    return AppCard(
      padding: const EdgeInsets.all(15),
      color: color.withOpacity(.09),
      child: Row(children: [
        Container(width: 44, height: 44, decoration: BoxDecoration(color: color.withOpacity(.14), borderRadius: BorderRadius.circular(15)), child: Icon(summary.myNet.abs() <= .01 ? Icons.check_circle_rounded : Icons.payments_rounded, color: color, size: 23)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(body, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800, height: 1.25)),
        ])),
        const SizedBox(width: 8),
        IconButton(onPressed: onCreate, icon: Icon(Icons.add_circle_rounded, color: color), tooltip: 'Añadir gasto'),
      ]),
    );
  }
}

class FinanceMiniMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const FinanceMiniMetric({super.key, required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      color: AppColors.surface,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 30, height: 30, decoration: BoxDecoration(color: color.withOpacity(.12), shape: BoxShape.circle), child: Icon(icon, size: 17, color: color)),
        const SizedBox(height: 7),
        Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink, fontSize: 14)),
        const SizedBox(height: 2),
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.muted, fontSize: 10.5)),
      ]),
    );
  }
}

class FinanceOptimizerInfoCard extends StatelessWidget {
  final FinanceSummary summary;
  const FinanceOptimizerInfoCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final hasPending = summary.settlements.isNotEmpty;
    final title = hasPending ? 'Pagos mínimos para cuadrar el grupo' : 'Sin deudas pendientes';
    final body = hasPending
        ? 'Hay ${summary.peopleWithBalance} personas con saldo. Grupli calcula el balance neto del grupo y propone ${summary.settlements.length} pago${summary.settlements.length == 1 ? '' : 's'} para dejarlo a cero, aunque el grupo tenga muchos miembros.'
        : 'Todos los balances están compensados. No hace falta mover dinero ahora mismo.';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: hasPending ? AppColors.tealSoft : AppColors.greenSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: (hasPending ? AppColors.teal : AppColors.green).withOpacity(.16)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: Colors.white.withOpacity(.78), borderRadius: BorderRadius.circular(14)),
          child: Icon(hasPending ? Icons.auto_awesome_rounded : Icons.verified_rounded, color: hasPending ? AppColors.teal : AppColors.green),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 14.5)),
          const SizedBox(height: 4),
          Text(body, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800, height: 1.25, fontSize: 12.5)),
        ])),
      ]),
    );
  }
}


class FinanceBalanceMemberRow extends StatelessWidget {
  final String userId;
  final String name;
  final String avatarUrl;
  final double balance;
  final VoidCallback onTap;
  const FinanceBalanceMemberRow({
    super.key,
    required this.userId,
    required this.name,
    required this.avatarUrl,
    required this.balance,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final positive = balance > .01;
    final negative = balance < -.01;
    final color = positive ? AppColors.green : negative ? AppColors.red : AppColors.muted;
    final title = positive ? 'Le deben' : negative ? 'Debe' : 'A cero';
    final amount = money(balance.abs());
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          ProfileAvatar(name: name, avatarUrl: avatarUrl, radius: 22),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
            const SizedBox(height: 3),
            Text('Toca para ver quién debe y por qué', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 12)),
          ])),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12)),
            const SizedBox(height: 2),
            Text(amount, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 15)),
          ]),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        ]),
      ),
    );
  }
}

class FinanceBalanceBarsCard extends StatelessWidget {
  final FinanceSummary summary;
  const FinanceBalanceBarsCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final entries = summary.balances.entries.toList()
      ..sort((a, b) => b.value.abs().compareTo(a.value.abs()));
    final visible = entries.where((e) => e.value.abs() > .01).toList();
    final maxValue = visible.isEmpty ? 1.0 : visible.map((e) => e.value.abs()).reduce(max);
    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 42, height: 42, decoration: BoxDecoration(color: AppColors.tealSoft, borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.bar_chart_rounded, color: AppColors.teal)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Saldos del grupo', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 3),
            Text('${summary.creditorsCount} cobran · ${summary.debtorsCount} deben · verde cobra / rojo paga', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800, fontSize: 12)),
          ])),
        ]),
        const SizedBox(height: 14),
        if (visible.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Text('Todos están a cero. No hay dinero pendiente.', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800)),
          )
        else
          ...visible.map((entry) => FinanceBalanceBarRow(
            name: summary.names[entry.key] ?? 'Miembro',
            avatarUrl: summary.avatars[entry.key] ?? '',
            value: entry.value,
            maxValue: maxValue,
          )),
      ]),
    );
  }
}

class FinanceBalanceBarRow extends StatelessWidget {
  final String name;
  final String avatarUrl;
  final double value;
  final double maxValue;
  const FinanceBalanceBarRow({super.key, required this.name, required this.avatarUrl, required this.value, required this.maxValue});

  @override
  Widget build(BuildContext context) {
    final positive = value > 0.01;
    final negative = value < -0.01;
    final color = positive ? AppColors.green : negative ? AppColors.red : AppColors.muted;
    final label = positive ? 'le deben' : negative ? 'debe' : 'en equilibrio';
    final factor = max(.12, min(1.0, value.abs() / max(1.0, maxValue)));
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          ProfileAvatar(name: name, avatarUrl: avatarUrl, radius: 16),
          const SizedBox(width: 9),
          Expanded(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink))),
          Text('${value >= 0 ? '+' : '-'}${money(value.abs())}', style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 15)),
        ]),
        const SizedBox(height: 7),
        SizedBox(
          height: 34,
          child: Row(children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: FractionallySizedBox(
                  widthFactor: negative ? factor : .02,
                  alignment: Alignment.centerRight,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 32,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: negative ? AppColors.red.withOpacity(.22) : AppColors.faint,
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(11)),
                    ),
                    child: negative ? Text('-${money(value.abs())}', maxLines: 1, overflow: TextOverflow.fade, style: const TextStyle(color: AppColors.red, fontWeight: FontWeight.w900, fontSize: 12)) : null,
                  ),
                ),
              ),
            ),
            Container(width: 1, height: 34, color: AppColors.line),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: positive ? factor : .02,
                  alignment: Alignment.centerLeft,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 32,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: positive ? AppColors.green.withOpacity(.24) : AppColors.faint,
                      borderRadius: const BorderRadius.horizontal(right: Radius.circular(11)),
                    ),
                    child: positive ? Text('+${money(value.abs())}', maxLines: 1, overflow: TextOverflow.fade, style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.w900, fontSize: 12)) : null,
                  ),
                ),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 3),
        Text(label, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800, fontSize: 11)),
      ]),
    );
  }
}

class SettlementPaymentRow extends StatelessWidget {
  final SettlementDebt debt;
  final bool large;
  final VoidCallback? onPaid;
  const SettlementPaymentRow({super.key, required this.debt, this.large = false, this.onPaid});

  @override
  Widget build(BuildContext context) {
    final myId = AppData.user?.id ?? '';
    final title = debt.fromId == myId
        ? 'Pagas a ${debt.toName}'
        : debt.toId == myId
            ? '${debt.fromName} te paga'
            : '${debt.fromName} paga a ${debt.toName}';
    final subtitle = debt.fromId == myId || debt.toId == myId
        ? 'Movimiento directo para dejar tu balance a cero'
        : 'Pago recomendado para compensar el grupo';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: large ? 13 : 11),
      child: Row(children: [
        SizedBox(
          width: 58,
          height: 38,
          child: Stack(children: [
            Positioned(left: 0, top: 1, child: ProfileAvatar(name: debt.fromName, avatarUrl: debt.fromAvatarUrl, radius: 18)),
            Positioned(right: 0, top: 1, child: ProfileAvatar(name: debt.toName, avatarUrl: debt.toAvatarUrl, radius: 18)),
            Positioned(left: 23, top: 11, child: Container(width: 18, height: 18, decoration: BoxDecoration(color: AppColors.white, shape: BoxShape.circle, border: Border.all(color: AppColors.line)), child: const Icon(Icons.arrow_forward_rounded, size: 12, color: AppColors.teal))),
          ]),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink)),
          const SizedBox(height: 2),
          Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w700)),
        ])),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(color: AppColors.tealSoft, borderRadius: BorderRadius.circular(99)),
            child: Text(money(debt.amount), style: const TextStyle(color: AppColors.tealDark, fontWeight: FontWeight.w900, fontSize: 14.5)),
          ),
          if (onPaid != null) ...[
            const SizedBox(height: 6),
            SizedBox(
              height: 32,
              child: TextButton.icon(
                onPressed: onPaid,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 9),
                  foregroundColor: AppColors.tealDark,
                  backgroundColor: AppColors.tealSoft,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                ),
                icon: const Icon(Icons.check_circle_outline_rounded, size: 15),
                label: const Text('Liquidar', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
              ),
            ),
          ],
        ]),
      ]),
    );
  }
}

class SettlementHistoryRow extends StatelessWidget {
  final Map<String, dynamic> payment;
  final List<Map<String, dynamic>> members;
  final VoidCallback? onCancel;
  const SettlementHistoryRow({super.key, required this.payment, required this.members, this.onCancel});

  @override
  Widget build(BuildContext context) {
    final fromId = AppData.text(payment['from_user']);
    final toId = AppData.text(payment['to_user']);
    final amount = AppData.doubleValue(payment['amount']);
    final date = DateTime.tryParse(AppData.text(payment['paid_at']))?.toLocal();
    final dateText = date == null ? 'Registrado' : DateFormat('d MMM', 'es_ES').format(date).replaceAll('.', '');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(children: [
        SizedBox(
          width: 58,
          height: 38,
          child: Stack(children: [
            Positioned(left: 0, top: 1, child: ProfileAvatar(name: financeMemberName(fromId, members), avatarUrl: financeMemberAvatarUrl(fromId, members), radius: 18)),
            Positioned(right: 0, top: 1, child: ProfileAvatar(name: financeMemberName(toId, members), avatarUrl: financeMemberAvatarUrl(toId, members), radius: 18)),
            Positioned(left: 23, top: 11, child: Container(width: 18, height: 18, decoration: BoxDecoration(color: AppColors.white, shape: BoxShape.circle, border: Border.all(color: AppColors.line)), child: const Icon(Icons.check_rounded, size: 12, color: AppColors.green))),
          ]),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${financeMemberName(fromId, members)} pagó a ${financeMemberName(toId, members)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink)),
          const SizedBox(height: 2),
          Text(dateText, style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w700)),
        ])),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(money(amount), style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.w900, fontSize: 14.5)),
          if (onCancel != null) ...[
            const SizedBox(height: 5),
            SizedBox(
              height: 30,
              child: TextButton(
                onPressed: onCancel,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  foregroundColor: AppColors.red,
                  backgroundColor: AppColors.redSoft,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                ),
                child: const Text('Deshacer', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
              ),
            ),
          ],
        ]),
      ]),
    );
  }
}


class FinanceAutoBalanceCard extends StatelessWidget {
  final FinanceSummary summary;
  final int openCount;
  final int settledCount;
  const FinanceAutoBalanceCard({super.key, required this.summary, required this.openCount, required this.settledCount});

  @override
  Widget build(BuildContext context) {
    final hasPending = summary.pendingAmount > 0.01;
    final color = hasPending ? AppColors.teal : AppColors.green;
    final title = hasPending ? 'Cuentas compensadas' : 'Todo cuadrado';
    final body = hasPending
        ? 'Compensa deudas cruzadas y muestra solo lo que hay que mover.'
        : 'No hay pagos pendientes.';

    return AppCard(
      padding: const EdgeInsets.all(15),
      color: AppColors.surface,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: color.withOpacity(.12), borderRadius: BorderRadius.circular(15)),
            child: Icon(hasPending ? Icons.auto_awesome_rounded : Icons.verified_rounded, color: color, size: 23),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 5),
            Text(body, style: Theme.of(context).textTheme.bodyMedium),
          ])),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _FinanceAutoMetric(label: 'Total', value: money(summary.pendingAmount), color: AppColors.amber)),
          const SizedBox(width: 8),
          Expanded(child: _FinanceAutoMetric(label: 'A mover', value: money(summary.settlementAmount), color: AppColors.teal)),
          const SizedBox(width: 8),
          Expanded(child: _FinanceAutoMetric(label: 'Restado', value: money(summary.compensatedAmount), color: AppColors.green)),
        ]),
        const SizedBox(height: 10),
        Text(
          hasPending
              ? '$openCount ${openCount == 1 ? 'gasto abierto' : 'gastos abiertos'} · ${summary.settlements.length} ${summary.settlements.length == 1 ? 'pago recomendado' : 'pagos recomendados'} para dejarlo a cero.'
              : '$settledCount ${settledCount == 1 ? 'gasto liquidado' : 'gastos liquidados'} · sin pagos pendientes.',
          style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800, fontSize: 12),
        ),
      ]),
    );
  }
}

class _FinanceAutoMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _FinanceAutoMetric({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 10),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.line)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontSize: 10.5, fontWeight: FontWeight.w800)),
      const SizedBox(height: 4),
      Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w900)),
    ]),
  );
}

class FinanceSplitPreview extends StatelessWidget {
  final int participants;
  final double amount;
  final double equalShare;
  final bool customMode;
  final double customTotal;
  final double diff;
  const FinanceSplitPreview({super.key, required this.participants, required this.amount, required this.equalShare, required this.customMode, required this.customTotal, required this.diff});

  @override
  Widget build(BuildContext context) {
    final ok = !customMode || diff.abs() <= .05;
    final color = ok ? AppColors.teal : AppColors.red;
    final text = participants == 0
        ? 'Elige al menos un participante.'
        : customMode
            ? (ok ? 'Reparto manual equilibrado · total ${money(customTotal)}' : 'Faltan/sobran ${money(diff.abs())} para cuadrar el total')
            : '$participants participantes · cada uno debe ${money(equalShare)} · luego se optimiza en Saldos';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color.withOpacity(.10), borderRadius: BorderRadius.circular(15), border: Border.all(color: color.withOpacity(.18))),
      child: Row(children: [
        Icon(ok ? Icons.calculate_rounded : Icons.warning_amber_rounded, color: color),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink))),
      ]),
    );
  }
}

class _FinanceData {
  final List<Map<String, dynamic>> expenses;
  final List<Map<String, dynamic>> members;
  final List<Map<String, dynamic>> settlementPayments;
  late final FinanceSummary summary;

  _FinanceData({required this.expenses, required this.members, required this.settlementPayments}) {
    summary = FinanceSummary.from(expenses, members, settlementPayments);
  }

  static _FinanceData empty() => _FinanceData(expenses: const [], members: const [], settlementPayments: const []);

  static Future<_FinanceData> load(String groupId) async {
    final results = await Future.wait([AppData.expenses(groupId), AppData.members(groupId), AppData.settlementPayments(groupId)]);
    return _FinanceData(expenses: results[0], members: results[1], settlementPayments: results[2]);
  }
}

class FinanceSummary {
  final Map<String, String> names;
  final Map<String, String> avatars;
  final Map<String, double> balances;
  final List<SettlementDebt> settlements;
  final double totalExpenses;
  final double pendingAmount;
  final double myNet;

  FinanceSummary({
    required this.names,
    required this.avatars,
    required this.balances,
    required this.settlements,
    required this.totalExpenses,
    required this.pendingAmount,
    required this.myNet,
  });

  double get settlementAmount => double.parse(settlements.fold<double>(0, (sum, debt) => sum + debt.amount).toStringAsFixed(2));

  int get peopleWithBalance => balances.values.where((value) => value.abs() > 0.01).length;

  int get debtorsCount => balances.values.where((value) => value < -0.01).length;

  int get creditorsCount => balances.values.where((value) => value > 0.01).length;

  double get compensatedAmount {
    final value = pendingAmount - settlementAmount;
    return double.parse(max(0, value).toStringAsFixed(2));
  }

  List<MapEntry<String, double>> get sortedBalances {
    final list = balances.entries.where((entry) => entry.value.abs() > 0.01).toList();
    list.sort((a, b) => b.value.abs().compareTo(a.value.abs()));
    return list;
  }

  factory FinanceSummary.from(List<Map<String, dynamic>> expenses, List<Map<String, dynamic>> members, List<Map<String, dynamic>> settlementPayments) {
    final names = <String, String>{};
    final avatars = <String, String>{};
    final balances = <String, double>{};
    for (final m in members) {
      final id = m['user_id']?.toString() ?? '';
      if (id.isEmpty) continue;
      names[id] = memberName(m);
      avatars[id] = memberAvatarUrl(m);
      balances[id] = 0;
    }

    double total = 0;
    for (final e in expenses) {
      if (AppData.text(e['status']) == 'cancelled') continue;
      total += AppData.doubleValue(e['amount']);
      final paidBy = e['paid_by']?.toString() ?? '';
      names.putIfAbsent(paidBy, () => financeMemberName(paidBy, members));
      avatars.putIfAbsent(paidBy, () => financeMemberAvatarUrl(paidBy, members));
      balances.putIfAbsent(paidBy, () => 0);
      for (final p in expenseParticipants(e)) {
        final userId = p['user_id']?.toString() ?? '';
        if (userId.isEmpty || userId == paidBy) continue;
        final share = AppData.doubleValue(p['share_amount']);
        final alreadyPaid = p['paid'] == true;
        names.putIfAbsent(userId, () => financeMemberName(userId, members));
        avatars.putIfAbsent(userId, () => financeMemberAvatarUrl(userId, members));
        balances.putIfAbsent(userId, () => 0);
        if (!alreadyPaid) {
          balances[paidBy] = double.parse(((balances[paidBy] ?? 0) + share).toStringAsFixed(2));
          balances[userId] = double.parse(((balances[userId] ?? 0) - share).toStringAsFixed(2));
        }
      }
    }

    for (final payment in settlementPayments) {
      if (AppData.text(payment['status'], 'paid') != 'paid') continue;
      final fromId = AppData.text(payment['from_user']);
      final toId = AppData.text(payment['to_user']);
      final amount = AppData.doubleValue(payment['amount']);
      if (fromId.isEmpty || toId.isEmpty || amount <= 0) continue;
      names.putIfAbsent(fromId, () => financeMemberName(fromId, members));
      names.putIfAbsent(toId, () => financeMemberName(toId, members));
      avatars.putIfAbsent(fromId, () => financeMemberAvatarUrl(fromId, members));
      avatars.putIfAbsent(toId, () => financeMemberAvatarUrl(toId, members));
      balances.putIfAbsent(fromId, () => 0);
      balances.putIfAbsent(toId, () => 0);
      balances[fromId] = double.parse(((balances[fromId] ?? 0) + amount).toStringAsFixed(2));
      balances[toId] = double.parse(((balances[toId] ?? 0) - amount).toStringAsFixed(2));
    }

    final settlements = buildSettlements(balances, names, avatars);
    final netPending = balances.values.where((value) => value > 0.01).fold<double>(0, (sum, value) => sum + value);
    final myId = AppData.user?.id ?? '';
    return FinanceSummary(
      names: names,
      avatars: avatars,
      balances: balances,
      settlements: settlements,
      totalExpenses: double.parse(total.toStringAsFixed(2)),
      pendingAmount: double.parse(netPending.toStringAsFixed(2)),
      myNet: double.parse((balances[myId] ?? 0).toStringAsFixed(2)),
    );
  }
}

Future<void> showFinanceInsightsSheet(BuildContext context, {_FinanceData? data}) async {
  if (data == null) return;
  final summary = data.summary;
  final activeExpenses = data.expenses.where((expense) => AppData.text(expense['status']) != 'cancelled').toList();
  if (activeExpenses.isEmpty) {
    await showToast(context, 'Añade algún gasto para ver el análisis avanzado.');
    return;
  }

  final paidTotals = <String, double>{};
  Map<String, dynamic>? biggestExpense;
  for (final expense in activeExpenses) {
    final paidBy = AppData.text(expense['paid_by']);
    if (paidBy.isNotEmpty) {
      paidTotals[paidBy] = (paidTotals[paidBy] ?? 0) + AppData.doubleValue(expense['amount']);
    }
    if (biggestExpense == null || AppData.doubleValue(expense['amount']) > AppData.doubleValue(biggestExpense['amount'])) {
      biggestExpense = expense;
    }
  }
  final topPayer = paidTotals.isEmpty ? null : paidTotals.entries.reduce((a, b) => a.value >= b.value ? a : b);
  final averageExpense = summary.totalExpenses / activeExpenses.length;
  final biggestAmount = biggestExpense == null ? 0.0 : AppData.doubleValue(biggestExpense['amount']);
  final topPayerName = topPayer == null ? 'Sin datos' : financeMemberName(topPayer.key, data.members);
  final topPayerTotal = topPayer == null ? 0.0 : topPayer.value;
  final biggestConcept = biggestExpense == null ? 'Gasto' : AppData.text(biggestExpense['concept'], 'Gasto');

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: AppCard(
          color: AppColors.white,
          padding: const EdgeInsets.all(18),
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(width: 46, height: 46, decoration: BoxDecoration(color: AppColors.tealSoft, borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.insights_rounded, color: AppColors.teal)),
                const SizedBox(width: 12),
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Análisis financiero avanzado', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 17)),
                  SizedBox(height: 4),
                  Text('Lectura extra para grupos que quieren entender mejor sus gastos sin tocar la base gratis.', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, height: 1.25)),
                ])),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: FinanceFocusMetric(label: 'Gasto medio', value: money(averageExpense), color: AppColors.teal)),
                const SizedBox(width: 8),
                Expanded(child: FinanceFocusMetric(label: 'Mayor gasto', value: money(biggestAmount), color: AppColors.orange)),
                const SizedBox(width: 8),
                Expanded(child: FinanceFocusMetric(label: 'Pagado más', value: money(topPayerTotal), color: AppColors.green)),
              ]),
              const SizedBox(height: 14),
              AppCard(
                color: AppColors.faint,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Qué destaca', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  Text('La persona que más ha adelantado es $topPayerName con ${money(topPayerTotal)}.', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, height: 1.25)),
                  const SizedBox(height: 6),
                  Text('El gasto más alto es $biggestConcept por ${money(biggestAmount)}.', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, height: 1.25)),
                  const SizedBox(height: 6),
                  Text('Hay ${summary.peopleWithBalance} personas con saldo y ${summary.settlements.length} pago${summary.settlements.length == 1 ? '' : 's'} recomendado${summary.settlements.length == 1 ? '' : 's'} para dejar el grupo a cero.', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, height: 1.25)),
                ]),
              ),
              const SizedBox(height: 10),
              const Text('Premium añade este contexto y también quita anuncios de toda la app.', style: TextStyle(color: AppColors.orange, fontWeight: FontWeight.w800, height: 1.25)),
              const SizedBox(height: 14),
              SecondaryButton(label: 'Cerrar', icon: Icons.close_rounded, onTap: () => Navigator.pop(sheetContext)),
            ]),
          ),
        ),
      ),
    ),
  );
}

class SettlementDebt {
  final String fromId;
  final String toId;
  final String fromName;
  final String toName;
  final String fromAvatarUrl;
  final String toAvatarUrl;
  final double amount;
  const SettlementDebt({
    required this.fromId,
    required this.toId,
    required this.fromName,
    required this.toName,
    required this.fromAvatarUrl,
    required this.toAvatarUrl,
    required this.amount,
  });
}

List<SettlementDebt> buildSettlements(Map<String, double> balances, Map<String, String> names, Map<String, String> avatars) {
  final nodes = _settlementNodesFromBalances(balances);
  if (nodes.isEmpty) return const [];

  // Optimizador escalable para cualquier tamaño de grupo.
  // No liquida gasto por gasto: primero calcula el balance neto de cada miembro,
  // cruza deudas y propone una lista corta de pagos para dejar todos los saldos a cero.
  // Funciona igual con 3, 20 o 100 miembros activos porque trabaja en céntimos y empareja
  // deudores/receptores por importe pendiente, generando como máximo N-1 movimientos útiles.
  return _buildScalableNetSettlements(nodes, names, avatars);
}

class _SettlementNode {
  final String id;
  final int cents;
  const _SettlementNode(this.id, this.cents);
}

int _moneyToCents(double value) => (value * 100).round();

double _centsToMoney(int cents) => double.parse((cents / 100).toStringAsFixed(2));

List<_SettlementNode> _settlementNodesFromBalances(Map<String, double> balances) {
  final nodes = balances.entries
      .map((entry) => _SettlementNode(entry.key, _moneyToCents(entry.value)))
      .where((node) => node.cents.abs() > 0)
      .toList();
  if (nodes.isEmpty) return const [];

  // Corrige pequeñas diferencias de redondeo para que la suma sea exactamente 0 céntimos.
  final sum = nodes.fold<int>(0, (total, node) => total + node.cents);
  if (sum == 0) return nodes;
  nodes.sort((a, b) => b.cents.abs().compareTo(a.cents.abs()));
  final first = nodes.first;
  nodes[0] = _SettlementNode(first.id, first.cents - sum);
  return nodes.where((node) => node.cents.abs() > 0).toList();
}

List<SettlementDebt> _buildScalableNetSettlements(List<_SettlementNode> nodes, Map<String, String> names, Map<String, String> avatars) {
  final debtors = nodes.where((node) => node.cents < 0).map((node) => MapEntry(node.id, -node.cents)).toList();
  final creditors = nodes.where((node) => node.cents > 0).map((node) => MapEntry(node.id, node.cents)).toList();
  debtors.sort((a, b) => b.value.compareTo(a.value));
  creditors.sort((a, b) => b.value.compareTo(a.value));

  final result = <SettlementDebt>[];
  var i = 0;
  var j = 0;
  while (i < debtors.length && j < creditors.length) {
    final amountCents = min(debtors[i].value, creditors[j].value);
    if (amountCents > 0) {
      result.add(SettlementDebt(
        fromId: debtors[i].key,
        toId: creditors[j].key,
        fromName: names[debtors[i].key] ?? 'Miembro',
        toName: names[creditors[j].key] ?? 'Miembro',
        fromAvatarUrl: avatars[debtors[i].key] ?? '',
        toAvatarUrl: avatars[creditors[j].key] ?? '',
        amount: _centsToMoney(amountCents),
      ));
    }
    debtors[i] = MapEntry(debtors[i].key, debtors[i].value - amountCents);
    creditors[j] = MapEntry(creditors[j].key, creditors[j].value - amountCents);
    if (debtors[i].value <= 0) i++;
    if (creditors[j].value <= 0) j++;
  }
  return result;
}

List<Map<String, dynamic>> expenseParticipants(Map<String, dynamic> expense) {
  final raw = expense['expense_participants'];
  if (raw is! List) return [];
  return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
}

double unpaidAmount(Map<String, dynamic> expense) {
  final paidBy = expense['paid_by']?.toString();
  return expenseParticipants(expense).fold<double>(0, (sum, p) {
    if (p['user_id']?.toString() == paidBy) return sum;
    return p['paid'] == true ? sum : sum + AppData.doubleValue(p['share_amount']);
  });
}

String financeMemberName(String userId, List<Map<String, dynamic>> members) {
  for (final m in members) {
    if (m['user_id']?.toString() == userId) return memberName(m);
  }
  return userId == AppData.user?.id ? 'Tú' : 'Miembro';
}

String _financeMainTitle(FinanceSummary summary) {
  if (summary.pendingAmount <= 0.01) return 'Todo está cuadrado';
  if (summary.myNet > 0.01) return 'Te deben ${money(summary.myNet)}';
  if (summary.myNet < -0.01) return 'Debes ${money(-summary.myNet)}';
  return 'Hay pagos pendientes';
}

class SettlementRow extends StatelessWidget {
  final SettlementDebt debt;
  const SettlementRow({super.key, required this.debt});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(children: [
      Expanded(child: Text('${debt.fromName} paga a ${debt.toName}', style: const TextStyle(fontWeight: FontWeight.w900))),
      Text(money(debt.amount), style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.w900)),
    ]),
  );
}

class BalanceRow extends StatelessWidget {
  final String name;
  final String avatarUrl;
  final double value;
  const BalanceRow({super.key, required this.name, required this.value, this.avatarUrl = ''});

  @override
  Widget build(BuildContext context) {
    final color = value > 0.01 ? AppColors.green : value < -0.01 ? AppColors.red : AppColors.muted;
    final label = value > 0.01 ? 'Le deben' : value < -0.01 ? 'Debe' : 'En equilibrio';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(children: [
        ProfileAvatar(name: name, avatarUrl: avatarUrl, radius: 18),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w700)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(color: color.withOpacity(.10), borderRadius: BorderRadius.circular(99)),
          child: Text(money(value), style: TextStyle(color: color, fontWeight: FontWeight.w900)),
        ),
      ]),
    );
  }
}

class ChoicePill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const ChoicePill({super.key, required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: Container(
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: active ? AppColors.teal : Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: active ? AppColors.teal : AppColors.line)),
      child: Text(label, style: TextStyle(color: active ? Colors.white : AppColors.ink, fontWeight: FontWeight.w900)),
    ),
  );
}


class FinanceHumanNextStepCard extends StatelessWidget {
  final FinanceSummary summary;
  final int expensesCount;
  final int settledCount;
  final VoidCallback onCreate;
  const FinanceHumanNextStepCard({super.key, required this.summary, required this.expensesCount, required this.settledCount, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final clean = summary.pendingAmount <= 0.01;
    final firstDebt = summary.settlements.isEmpty ? null : summary.settlements.first;
    final title = clean
        ? 'Las cuentas respiran'
        : firstDebt != null
            ? 'Siguiente pago claro'
            : 'Hay saldo pendiente';
    final body = clean
        ? expensesCount == 0
            ? 'Aún no hay gastos. Cuando alguien pague algo, Grupli te dirá exactamente quién debe qué.'
            : '$expensesCount ${expensesCount == 1 ? 'movimiento registrado' : 'movimientos registrados'} y ningún pago pendiente.'
        : firstDebt != null
            ? '${firstDebt.fromName} paga a ${firstDebt.toName} ${money(firstDebt.amount)}. Con eso el grupo se acerca a cero.'
            : 'Revisa los saldos para entender qué queda por compensar.';
    return AppCard(
      color: AppColors.surfaceWarm,
      accentColor: clean ? AppColors.green : AppColors.navFinance,
      padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 46, height: 46, decoration: BoxDecoration(color: clean ? AppColors.greenSoft : AppColors.tealMist, borderRadius: AppColors.humanRadius, border: Border.all(color: const Color(0x160E6B73))), child: Icon(clean ? Icons.verified_rounded : Icons.swap_horiz_rounded, color: clean ? AppColors.green : AppColors.navFinance, size: 24)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 17.5, height: 1.08, letterSpacing: -.2)),
            const SizedBox(height: 5),
            Text(body, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, height: 1.32, fontSize: 13.2)),
          ])),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: FinanceFocusMetric(label: 'Pendiente', value: money(summary.pendingAmount), color: clean ? AppColors.green : AppColors.amber)),
          const SizedBox(width: 8),
          Expanded(child: FinanceFocusMetric(label: 'A mover', value: money(summary.settlementAmount), color: AppColors.navFinance)),
          const SizedBox(width: 8),
          Expanded(child: FinanceFocusMetric(label: 'Liquidado', value: '$settledCount', color: AppColors.blue)),
        ]),
        if (expensesCount == 0) ...[
          const SizedBox(height: 14),
          SecondaryButton(label: 'Añadir primer gasto', icon: Icons.add_rounded, onTap: onCreate),
        ],
      ]),
    );
  }
}

class FinancePremiumTeaserCard extends StatelessWidget {
  final VoidCallback onOpen;
  const FinancePremiumTeaserCard({super.key, required this.onOpen});

  @override
  Widget build(BuildContext context) => AppCard(
    color: AppColors.orangeSoft,
    accentColor: AppColors.orange,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 46, height: 46, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.workspace_premium_rounded, color: AppColors.orange, size: 22)),
        const SizedBox(width: 12),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Finanzas avanzadas', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 17)),
          SizedBox(height: 4),
          Text('Premium también quita anuncios y añade un análisis más completo para quien organiza mucho.', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, height: 1.25)),
        ])),
      ]),
      const SizedBox(height: 10),
      Wrap(spacing: 8, runSpacing: 8, children: const [
        TournamentRuleChip(label: 'Sin anuncios'),
        TournamentRuleChip(label: 'Análisis avanzado'),
        TournamentRuleChip(label: 'Exportar balances'),
      ]),
      const SizedBox(height: 10),
      SecondaryButton(label: 'Ver Premium', icon: Icons.workspace_premium_rounded, onTap: onOpen),
    ]),
  );
}

class FinanceAdvancedInsightsCard extends StatelessWidget {
  final FinanceSummary summary;
  final _FinanceData data;
  final VoidCallback onOpen;
  const FinanceAdvancedInsightsCard({super.key, required this.summary, required this.data, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final activeExpenses = data.expenses.where((expense) => AppData.text(expense['status']) != 'cancelled').toList();
    final total = summary.totalExpenses;
    final average = activeExpenses.isEmpty ? 0.0 : total / activeExpenses.length;
    MapEntry<String, double>? topPayer;
    Map<String, dynamic>? biggestExpense;
    final paidTotals = <String, double>{};
    for (final expense in activeExpenses) {
      final paidBy = AppData.text(expense['paid_by']);
      if (paidBy.isNotEmpty) {
        paidTotals[paidBy] = (paidTotals[paidBy] ?? 0) + AppData.doubleValue(expense['amount']);
      }
      if (biggestExpense == null || AppData.doubleValue(expense['amount']) > AppData.doubleValue(biggestExpense['amount'])) {
        biggestExpense = expense;
      }
    }
    if (paidTotals.isNotEmpty) {
      topPayer = paidTotals.entries.reduce((a, b) => a.value >= b.value ? a : b);
    }
    final topPayerLabel = topPayer == null ? 'Sin datos' : '${financeMemberName(topPayer.key, data.members)} · ${money(topPayer.value)}';
    final biggestLabel = biggestExpense == null ? 'Sin datos' : '${AppData.text(biggestExpense['concept'], 'Gasto')} · ${money(AppData.doubleValue(biggestExpense['amount']))}';

    return AppCard(
      color: AppColors.tealSoft,
      accentColor: AppColors.teal,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 46, height: 46, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.insights_rounded, color: AppColors.teal, size: 22)),
          const SizedBox(width: 12),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Análisis avanzado', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 17)),
            SizedBox(height: 4),
            Text('Lectura rápida del grupo para quien organiza más de una cuenta o quiere ir un paso más allá.', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, height: 1.25)),
          ])),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: FinanceMiniMetric(icon: Icons.functions_rounded, label: 'Gasto medio', value: money(average), color: AppColors.teal)),
          const SizedBox(width: 8),
          Expanded(child: FinanceMiniMetric(icon: Icons.receipt_long_rounded, label: 'Mayor gasto', value: biggestExpense == null ? '—' : money(AppData.doubleValue(biggestExpense['amount'])), color: AppColors.orange)),
          const SizedBox(width: 8),
          Expanded(child: FinanceMiniMetric(icon: Icons.person_rounded, label: 'Más ha adelantado', value: topPayer == null ? '—' : money(topPayer.value), color: AppColors.green)),
        ]),
        const SizedBox(height: 10),
        Text('Top: $topPayerLabel', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800, height: 1.25, fontSize: 12)),
        const SizedBox(height: 4),
        Text('Mayor gasto: $biggestLabel', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800, height: 1.25, fontSize: 12)),
        const SizedBox(height: 4),
        Text('Sin anuncios y con información extra para quien organiza más a menudo.', style: const TextStyle(color: AppColors.orange, fontWeight: FontWeight.w800, height: 1.25, fontSize: 12)),
        const SizedBox(height: 10),
        SecondaryButton(label: 'Abrir análisis', icon: Icons.insights_rounded, onTap: onOpen),
      ]),
    );
  }
}

class FinanceFocusMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const FinanceFocusMetric({super.key, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
    decoration: BoxDecoration(color: color.withOpacity(.10), borderRadius: AppColors.humanRadius, border: Border.all(color: color.withOpacity(.17))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 15.5, height: 1)),
      const SizedBox(height: 3),
      Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800, fontSize: 10.5)),
    ]),
  );
}
