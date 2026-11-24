import 'package:coyhaique_basecamp_pt/core/widgets/basecamp/bc_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regresión UI-03 (auditoría 23-11-2026): la tarjeta «Disponible sin
/// conexión» del inicio se desbordaba 26 px con ~175 dp de ancho (dos
/// tarjetas lado a lado en un teléfono de 411 dp, letra 1,1×).
void main() {
  Future<void> pumpTile(
    WidgetTester tester, {
    required double width,
    required double textScale,
    required bool compact,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: width,
                // Igual que en el inicio: las dos tarjetas toman el alto de la
                // más alta.
                child: IntrinsicHeight(
                  child: BcWideInfoTile(
                    dark: true,
                    icon: Icons.download_done_rounded,
                    title: 'Disponible sin conexión',
                    subtitle: 'Descargado el 23-11-2026 · Actualizar',
                    subtitleSize: 12,
                    compact: compact,
                    trailing: const SizedBox(width: 14),
                    onTap: () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  for (final scale in [1.0, 1.15, 1.3, 2.0]) {
    testWidgets('compacta a 160 dp no se desborda con letra $scale×', (
      tester,
    ) async {
      await pumpTile(tester, width: 160, textScale: scale, compact: true);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('ancha a 360 dp no se desborda con letra 1,3×', (tester) async {
    await pumpTile(tester, width: 360, textScale: 1.3, compact: false);
    expect(tester.takeException(), isNull);
  });

  testWidgets('la tarjeta cumple el área táctil mínima de Android', (
    tester,
  ) async {
    await pumpTile(tester, width: 175, textScale: 1.0, compact: true);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  });
}
