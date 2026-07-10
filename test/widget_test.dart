import 'package:flutter_test/flutter_test.dart';

import 'package:grupli/main.dart';

void main() {
  testWidgets('muestra la pantalla de configuración pendiente', (tester) async {
    await tester.pumpWidget(const GrupliConfigurationMissingApp());

    expect(find.text('Configuración pendiente'), findsOneWidget);
    expect(find.textContaining('configuración segura'), findsOneWidget);
  });
}
