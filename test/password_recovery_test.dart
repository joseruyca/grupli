import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:grupli/main.dart';

void main() {
  testWidgets('recovery validates confirmation, preserves password and blocks duplicate saves', (tester) async {
    appLocale = const Locale('es');
    final pending = Completer<void>();
    var calls = 0;
    var finished = false;
    String? saved;
    await tester.pumpWidget(MaterialApp(locale: const Locale('es'), supportedLocales: const [Locale('es')], localizationsDelegates: GlobalMaterialLocalizations.delegates, home: PasswordRecoveryScreen(
      onSaved: () => finished = true,
      savePassword: (value) { calls++; saved = value; return pending.future; },
    )));
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), ' secret123 ');
    await tester.enterText(fields.at(1), 'different');
    await tester.tap(find.text('Guardar contraseña'));
    await tester.pump();
    expect(calls, 0);
    expect(find.text('Usa al menos 8 caracteres y repite la misma contraseña.'), findsOneWidget);
    await tester.enterText(fields.at(1), ' secret123 ');
    await tester.tap(find.text('Guardar contraseña'));
    await tester.pump();
    expect(saved, ' secret123 ');
    expect(calls, 1);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);
    pending.complete();
    await tester.pump();
    expect(finished, isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
