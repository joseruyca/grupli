import 'package:intl/intl.dart';

class Fmt {
  static final money = NumberFormat.currency(locale: 'es_ES', symbol: '€');
  static final day = DateFormat('EEE d MMM', 'es_ES');
  static final date = DateFormat('dd/MM/yyyy', 'es_ES');
  static final hour = DateFormat('HH:mm', 'es_ES');
  static final dateTime = DateFormat('dd/MM/yyyy HH:mm', 'es_ES');
}
