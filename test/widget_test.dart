import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coyhaique_basecamp_pt/main.dart';

void main() {
  testWidgets('CoyhaiqueApp smoke test & usability flow test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: CoyhaiqueApp(),
      ),
    );

    // 1. Verifica Splash inicial
    expect(find.text('Coyhaique BaseCamp'), findsOneWidget);

    // 2. Avanza temporizador de Splash
    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pumpAndSettle();

    // 3. Verifica pantalla de Selección de idioma con botón de confirmación explícito y botón atrás
    expect(find.text('Selecciona tu idioma'), findsOneWidget);
    expect(find.text('Confirmar y continuar'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);

    // 4. Presiona confirmar idioma
    await tester.tap(find.text('Confirmar y continuar'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    // 5. Verifica llegada a la pantalla de Acceso (AuthGateway) con su botón de retroceso
    expect(find.text('Explora Coyhaique a tu manera'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
  });
}
