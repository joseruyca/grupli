class FinanceBalance {
  final String fromUserId;
  final String fromName;
  final String toUserId;
  final String toName;
  final double amount;

  const FinanceBalance({
    required this.fromUserId,
    required this.fromName,
    required this.toUserId,
    required this.toName,
    required this.amount,
  });
}

class FinanceMember {
  final String userId;
  final String name;
  final String? email;

  const FinanceMember({required this.userId, required this.name, this.email});
}

class FinanceCalculator {
  static List<FinanceMember> membersFromRows(List<Map<String, dynamic>> rows) {
    return rows.map((m) {
      final profile = Map<String, dynamic>.from((m['profiles'] ?? {}) as Map);
      final name = (profile['full_name'] ?? profile['email'] ?? 'Usuario').toString();
      return FinanceMember(
        userId: m['user_id'].toString(),
        name: name,
        email: profile['email']?.toString(),
      );
    }).toList();
  }

  static String memberName(List<FinanceMember> members, String? userId) {
    if (userId == null) return 'Alguien';
    final found = members.where((m) => m.userId == userId).toList();
    if (found.isEmpty) return 'Usuario';
    return found.first.name;
  }

  static double amountOf(Object? value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  static double netForUser({
    required String userId,
    required List<Map<String, dynamic>> expenses,
    required List<Map<String, dynamic>> settlements,
  }) {
    final nets = _netMap(expenses: expenses, settlements: settlements);
    return _round2(nets[userId] ?? 0);
  }

  static double totalPending(List<Map<String, dynamic>> expenses) {
    return _round2(expenses
        .where((e) => (e['status'] ?? 'pending').toString() == 'pending')
        .fold<double>(0, (sum, e) => sum + amountOf(e['amount'])));
  }

  static List<FinanceBalance> balances({
    required List<Map<String, dynamic>> expenses,
    required List<Map<String, dynamic>> settlements,
    required List<FinanceMember> members,
  }) {
    final nets = _netMap(expenses: expenses, settlements: settlements);
    final debtors = <MapEntry<String, double>>[];
    final creditors = <MapEntry<String, double>>[];

    for (final entry in nets.entries) {
      final value = _round2(entry.value);
      if (value < -0.009) debtors.add(MapEntry(entry.key, -value));
      if (value > 0.009) creditors.add(MapEntry(entry.key, value));
    }

    debtors.sort((a, b) => b.value.compareTo(a.value));
    creditors.sort((a, b) => b.value.compareTo(a.value));

    final result = <FinanceBalance>[];
    var i = 0;
    var j = 0;
    while (i < debtors.length && j < creditors.length) {
      final amount = _round2(debtors[i].value < creditors[j].value ? debtors[i].value : creditors[j].value);
      if (amount > 0.009) {
        result.add(FinanceBalance(
          fromUserId: debtors[i].key,
          fromName: memberName(members, debtors[i].key),
          toUserId: creditors[j].key,
          toName: memberName(members, creditors[j].key),
          amount: amount,
        ));
      }

      debtors[i] = MapEntry(debtors[i].key, _round2(debtors[i].value - amount));
      creditors[j] = MapEntry(creditors[j].key, _round2(creditors[j].value - amount));
      if (debtors[i].value <= 0.009) i++;
      if (creditors[j].value <= 0.009) j++;
    }

    return result;
  }

  static Map<String, double> _netMap({
    required List<Map<String, dynamic>> expenses,
    required List<Map<String, dynamic>> settlements,
  }) {
    final nets = <String, double>{};

    void add(String? userId, double value) {
      if (userId == null || userId.isEmpty) return;
      nets[userId] = (nets[userId] ?? 0) + value;
    }

    for (final expense in expenses) {
      final status = (expense['status'] ?? 'pending').toString();
      if (status != 'pending') continue;

      final paidBy = expense['paid_by']?.toString();
      final amount = amountOf(expense['amount']);
      add(paidBy, amount);

      final participants = List<Map<String, dynamic>>.from((expense['expense_participants'] ?? []) as List);
      for (final participant in participants) {
        add(participant['user_id']?.toString(), -amountOf(participant['share_amount']));
      }
    }

    for (final settlement in settlements) {
      final status = (settlement['status'] ?? 'pending').toString();
      if (status != 'paid') continue;

      final from = settlement['from_user']?.toString();
      final to = settlement['to_user']?.toString();
      final amount = amountOf(settlement['amount']);
      add(from, amount);
      add(to, -amount);
    }

    return nets.map((key, value) => MapEntry(key, _round2(value)));
  }

  static double _round2(double value) => (value * 100).roundToDouble() / 100;
}
