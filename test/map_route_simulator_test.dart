import 'dart:convert';

import 'package:coyhaique_basecamp_pt/features/map/presentation/screens/mapbox_directions_services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Simulador de la generación de rutas con Mapbox Directions.
///
/// Usa un cliente HTTP falso para recorrer los escenarios de respuesta sin
/// red real. Cubre el servicio que usa el mapa al calcular una ruta
/// (MapboxDirectionsService). El origen de la ruta (ubicación del usuario
/// frente a la Plaza de Armas) se valida en PR aparte.
const _token = 'pk.test-token';

MapboxDirectionsService _service(http.Client client) =>
    MapboxDirectionsService(accessToken: _token, client: client);

http.Response _okRoute({
  double distance = 1500,
  double duration = 900,
  List<List<double>> coordinates = const [
    [-72.1, -45.5],
    [-72.2, -45.6],
  ],
}) {
  return http.Response(
    jsonEncode({
      'code': 'Ok',
      'routes': [
        {
          'distance': distance,
          'duration': duration,
          'geometry': {'coordinates': coordinates},
        },
      ],
    }),
    200,
  );
}

void main() {
  group('Simulador de ruta Mapbox (MapboxDirectionsService)', () {
    test('ruta válida: parsea geometría, distancia y duración', () async {
      final client = MockClient((_) async => _okRoute());

      final route = await _service(client).getRoute(
        fromLongitude: -72.1,
        fromLatitude: -45.5,
        toLongitude: -72.2,
        toLatitude: -45.6,
      );

      expect(route, isNotNull);
      expect(route!.coordinates, hasLength(2));
      expect(route.coordinates.first, [-72.1, -45.5]);
      expect(route.distanceLabel, '1.5 km');
      expect(route.durationLabel, '15 min');
    });

    test('la petición envía lon,lat en orden, perfil y token', () async {
      late http.Request captured;
      final client = MockClient((request) async {
        captured = request;
        return _okRoute();
      });

      await _service(client).getRoute(
        fromLongitude: -72.1,
        fromLatitude: -45.5,
        toLongitude: -72.2,
        toLatitude: -45.6,
        profile: RouteProfile.walking,
      );

      expect(captured.url.host, 'api.mapbox.com');
      expect(
        captured.url.path,
        '/directions/v5/mapbox/walking/-72.1,-45.5;-72.2,-45.6',
      );
      expect(captured.url.queryParameters['access_token'], _token);
      expect(captured.url.queryParameters['geometries'], 'geojson');
      expect(captured.url.queryParameters['overview'], 'full');
    });

    test('Mapbox responde code distinto de Ok: devuelve null', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({'code': 'NoRoute', 'routes': <dynamic>[]}),
          200,
        ),
      );

      final route = await _service(client).getRoute(
        fromLongitude: -72.1,
        fromLatitude: -45.5,
        toLongitude: -70.0,
        toLatitude: -40.0,
      );

      expect(route, isNull);
    });

    test('respuesta Ok sin rutas: devuelve null', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({'code': 'Ok', 'routes': <dynamic>[]}),
          200,
        ),
      );

      final route = await _service(client).getRoute(
        fromLongitude: -72.1,
        fromLatitude: -45.5,
        toLongitude: -72.2,
        toLatitude: -45.6,
      );

      expect(route, isNull);
    });

    test('HTTP 500 lanza excepción (el mapa muestra mensaje de error)', () async {
      final client = MockClient((_) async => http.Response('boom', 500));

      expect(
        () => _service(client).getRoute(
          fromLongitude: -72.1,
          fromLatitude: -45.5,
          toLongitude: -72.2,
          toLatitude: -45.6,
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'mensaje',
            contains('HTTP 500'),
          ),
        ),
      );
    });

    test('HTTP 401 (token inválido) lanza excepción', () async {
      final client = MockClient((_) async => http.Response('unauthorized', 401));

      expect(
        () => _service(client).getRoute(
          fromLongitude: -72.1,
          fromLatitude: -45.5,
          toLongitude: -72.2,
          toLatitude: -45.6,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('etiquetas: menos de 1 km en metros y minutos sin horas', () {
      const route = RouteResult(
        coordinates: [],
        distanceMeters: 450,
        durationSeconds: 300,
      );

      expect(route.distanceLabel, '450 m');
      expect(route.durationLabel, '5 min');
    });

    test('etiquetas: más de 60 minutos se expresan en horas', () {
      const route = RouteResult(
        coordinates: [],
        distanceMeters: 12000,
        durationSeconds: 5400,
      );

      expect(route.distanceLabel, '12.0 km');
      expect(route.durationLabel, '1 h 30 min');
    });
  });
}