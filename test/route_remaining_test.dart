import 'package:flutter_test/flutter_test.dart';

import 'package:coyhaique_basecamp_pt/features/map/domain/route_tracking.dart';

void main() {
  // Ruta recta de 4 puntos (3 tramos iguales), en formato [lng, lat].
  final even = <List<double>>[
    [-72.0, -45.00],
    [-72.0, -45.01],
    [-72.0, -45.02],
    [-72.0, -45.03],
  ];

  group('remainingRouteFraction', () {
    test('al inicio falta toda la ruta', () {
      expect(remainingRouteFraction(even, 0), 1);
    });

    test('tramos iguales: avanzar un punto deja 2/3', () {
      expect(remainingRouteFraction(even, 1), closeTo(2 / 3, 1e-6));
    });

    test('en el último punto ya llegó', () {
      expect(remainingRouteFraction(even, 3), 0);
      expect(remainingRouteFraction(even, 9), 0);
    });

    test('pondera por el largo de cada tramo', () {
      final uneven = <List<double>>[
        [-72.0, -45.00],
        [-72.0, -45.01], // tramo corto
        [-72.0, -45.04], // tramo largo
      ];
      // Falta el tramo largo: 3 de 4 partes.
      expect(remainingRouteFraction(uneven, 1), closeTo(0.75, 1e-6));
    });

    test('una ruta sin tramos devuelve 0', () {
      expect(remainingRouteFraction(const [], 0), 0);
      expect(remainingRouteFraction([even.first], 0), 0);
    });
  });

  group('llegada', () {
    test('a pocos metros del destino se da por llegado', () {
      // ~11 m al norte del destino.
      final d = distanceToRouteMeters(-45.0999, -72.0, [
        [-72.0, -45.1],
      ]);
      expect(d <= arrivalMeters, isTrue);
    });

    test('a cientos de metros no se da por llegado', () {
      final d = distanceToRouteMeters(-45.095, -72.0, [
        [-72.0, -45.1],
      ]);
      expect(d > arrivalMeters, isTrue);
    });
  });

  group('routeBearingAt', () {
    test('ruta hacia el norte = 0°', () {
      final north = <List<double>>[
        [-72.0, -45.00],
        [-72.0, -44.99],
      ];
      expect(routeBearingAt(north, 0), closeTo(0, 0.01));
    });

    test('ruta hacia el este = 90°', () {
      final east = <List<double>>[
        [-72.00, -45.0],
        [-71.99, -45.0],
      ];
      expect(routeBearingAt(east, 0), closeTo(90, 0.01));
    });

    test('ruta hacia el sur = 180° y hacia el oeste = 270°', () {
      expect(
        routeBearingAt([
          [-72.0, -45.00],
          [-72.0, -45.01],
        ], 0),
        closeTo(180, 0.01),
      );
      expect(
        routeBearingAt([
          [-72.00, -45.0],
          [-72.01, -45.0],
        ], 0),
        closeTo(270, 0.01),
      );
    });

    test('mira más allá de un tramo diminuto', () {
      final line = <List<double>>[
        [-72.0, -45.0],
        [-72.0, -44.99999], // ~1 m al norte
        [-71.99, -44.99999], // luego al este
      ];
      expect(routeBearingAt(line, 0), closeTo(90, 1));
    });

    test('ruta sin tramos devuelve 0', () {
      expect(routeBearingAt(const [], 0), 0);
    });
  });
}

