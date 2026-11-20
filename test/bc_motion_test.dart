import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:coyhaique_basecamp_pt/core/widgets/basecamp/bc_motion.dart';

Widget _app(Widget child, {bool reduceMotion = false}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: Scaffold(body: child),
    ),
  );
}

void main() {
  group('BcEntrance', () {
    testWidgets('anima los primeros elementos y termina visible', (tester) async {
      await tester.pumpWidget(
        _app(const BcEntrance(index: 2, child: Text('lugar'))),
      );
      expect(find.byType(Animate), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.text('lugar'), findsOneWidget);
    });

    testWidgets('no anima pasado el máximo escalonado', (tester) async {
      await tester.pumpWidget(
        _app(
          const BcEntrance(index: BcMotion.maxStaggered, child: Text('lugar')),
        ),
      );
      expect(find.byType(Animate), findsNothing);
      expect(find.text('lugar'), findsOneWidget);
    });

    testWidgets('no anima si el sistema reduce el movimiento', (tester) async {
      await tester.pumpWidget(
        _app(const BcEntrance(child: Text('lugar')), reduceMotion: true),
      );
      expect(find.byType(Animate), findsNothing);
      expect(find.text('lugar'), findsOneWidget);
    });
  });

  group('BcSwitcher', () {
    testWidgets('cambia un grupo por otro y quita el anterior', (tester) async {
      Widget build(String key) => _app(
        BcSwitcher(
          child: Text(key, key: ValueKey(key)),
        ),
      );

      await tester.pumpWidget(build('buscador'));
      expect(find.text('buscador'), findsOneWidget);

      await tester.pumpWidget(build('ruta'));
      await tester.pumpAndSettle();
      expect(find.text('ruta'), findsOneWidget);
      expect(find.text('buscador'), findsNothing);
    });

    testWidgets('con movimiento reducido el cambio es inmediato', (tester) async {
      Widget build(String key) => _app(
        BcSwitcher(child: Text(key, key: ValueKey(key))),
        reduceMotion: true,
      );

      await tester.pumpWidget(build('buscador'));
      await tester.pumpWidget(build('ruta'));
      await tester.pump();
      expect(find.text('buscador'), findsNothing);
      expect(find.text('ruta'), findsOneWidget);
    });
  });
}
