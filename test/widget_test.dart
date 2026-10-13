import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coyhaique_basecamp_pt/main.dart';

void main() {
  testWidgets('CoyhaiqueApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: CoyhaiqueApp(),
      ),
    );

    // Verifica que se renderiza el Splash inicial
    expect(find.text('Coyhaique BaseCamp'), findsOneWidget);

    // Avanza el temporizador de Splash (1600ms) y asienta la navegación a Onboarding
    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pumpAndSettle();

    // Verifica que tras el Splash se navega a Selección de idioma según USER_FLOWS.md
    expect(find.text('Selecciona tu idioma'), findsOneWidget);
  });
}
