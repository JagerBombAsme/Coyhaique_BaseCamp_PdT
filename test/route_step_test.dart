import 'package:flutter_test/flutter_test.dart';

import 'package:coyhaique_basecamp_pt/features/map/domain/route_step.dart';
import 'package:coyhaique_basecamp_pt/features/map/domain/route_tracking.dart';
import 'package:coyhaique_basecamp_pt/features/map/presentation/widgets/route_maneuver.dart';

void main() {
  const steps = [
    RouteStep(type: 'depart', modifier: null, name: 'Av. Uno', coordIndex: 0),
    RouteStep(type: 'turn', modifier: 'left', name: 'Calle Dos', coordIndex: 3),
    RouteStep(type: 'turn', modifier: 'right', name: '', coordIndex: 6),
    RouteStep(type: 'arrive', modifier: null, name: '', coordIndex: 9),
  ];

  group('nextManeuverStep', () {
    test('al inicio la próxima es el primer giro, no la salida', () {
      expect(nextManeuverStep(steps, 0)?.coordIndex, 3);
    });

    test('al pasar un giro se avanza al siguiente', () {
      expect(nextManeuverStep(steps, 3)?.coordIndex, 6);
      expect(nextManeuverStep(steps, 7)?.type, 'arrive');
    });

    test('sin maniobras por delante devuelve null', () {
      expect(nextManeuverStep(steps, 9), isNull);
      expect(nextManeuverStep(const [], 0), isNull);
    });
  });

  group('routeIndexOf', () {
    final line = <List<double>>[
      [-72.0, -45.00],
      [-72.0, -45.01],
      [-72.0, -45.02],
      [-72.0, -45.01], // vuelve por el mismo lugar
    ];

    test('respeta el punto de partida de la búsqueda', () {
      expect(routeIndexOf(line, -72.0, -45.01), 1);
      expect(routeIndexOf(line, -72.0, -45.01, start: 2), 3);
    });
  });

  group('routeLengthMeters', () {
    test('suma los tramos entre dos puntos', () {
      final line = <List<double>>[
        [-72.0, -45.00],
        [-72.0, -45.01],
        [-72.0, -45.02],
      ];
      // 0,01° de latitud ≈ 1,11 km.
      expect(routeLengthMeters(line, 0, 2), closeTo(2224, 5));
      expect(routeLengthMeters(line, 1, 2), closeTo(1112, 5));
      expect(routeLengthMeters(line, 2, 2), 0);
    });
  });

  group('MapManeuver', () {
    test('giro a la izquierda en español, con calle y distancia redondeada', () {
      final m = MapManeuver.fromStep(
        step: steps[1],
        meters: 237,
        isSpanish: true,
      );
      expect(m.text, 'Gira a la izquierda');
      expect(m.distanceLabel, '240 m');
      expect(m.street, 'Calle Dos');
    });

    test('en inglés y sin calle', () {
      final m = MapManeuver.fromStep(
        step: steps[2],
        meters: 1500,
        isSpanish: false,
      );
      expect(m.text, 'Turn right');
      expect(m.distanceLabel, '1.5 km');
      expect(m.street, isNull);
    });

    test('muy cerca dice «Ahora» y la llegada habla del destino', () {
      final m = MapManeuver.fromStep(
        step: steps[3],
        meters: 8,
        isSpanish: true,
      );
      expect(m.distanceLabel, 'Ahora');
      expect(m.text, 'Llegarás a tu destino');
    });
  });
}
