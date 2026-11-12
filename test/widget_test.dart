import 'package:coyhaique_basecamp_pt/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('La pantalla inicial muestra la marca y avanza a la intro', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: CoyhaiqueApp()));
    await tester.pump();

    // Pantalla inicial con la identidad visual vigente.
    expect(find.text('COYHAIQUE BASECAMP'), findsOneWidget);

    // Tras 1,6 s, la app avanza a la intro.
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('WITH US'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  });
}
