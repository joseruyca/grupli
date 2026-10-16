/// Keep monetary arithmetic in cents; the split must preserve the exact total.
class FinanceMoney {
  static int cents(double value) {
    if (!value.isFinite || value < 0) throw ArgumentError('invalid_amount');
    return (value * 100).round();
  }
  static Map<String, double> splitEqual(double amount, Iterable<String> people) {
    final ids = people.where((id) => id.trim().isNotEmpty).toSet().toList()..sort();
    if (ids.isEmpty) throw ArgumentError('invalid_participants');
    final total = cents(amount), base = total ~/ ids.length, remainder = total % ids.length;
    return {for (var i = 0; i < ids.length; i++) ids[i]: (base + (i < remainder ? 1 : 0)) / 100};
  }
  static bool matchesTotal(double amount, Iterable<double> shares) {
    try { return cents(amount) == shares.fold<int>(0, (sum, value) => sum + cents(value)); }
    on ArgumentError { return false; }
  }
}
