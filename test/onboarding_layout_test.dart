import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grupli/main.dart';

void main() {
  for (final size in [const Size(320, 568), const Size(640, 360)]) {
    testWidgets('onboarding remains usable at $size with enlarged text', (tester) async {
      appLocale = const Locale('es');
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var finished = false;
      await tester.pumpWidget(MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.5)),
          child: child!,
        ),
        home: OnboardingScreen(onFinish: () async { finished = true; }),
      ));
      await tester.pump(const Duration(milliseconds: 700));
      for (var page = 0; page < 2; page++) {
        final next = find.text('Siguiente');
        expect(tester.getRect(next).bottom, lessThanOrEqualTo(size.height));
        await tester.tap(next);
        await tester.pump(const Duration(milliseconds: 400));
      }
      await tester.tap(find.text('Empezar'));
      await tester.pump();
      expect(finished, isTrue);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
