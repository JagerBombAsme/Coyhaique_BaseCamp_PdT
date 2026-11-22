import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/route_step.dart';

/// Resultado de una ruta calculada por Mapbox.
class RouteResult {
  /// Puntos de la ruta en formato [longitud, latitud].
  final List<List<double>> coordinates;
  final double distanceMeters;
  final double durationSeconds;

  /// Maniobras de la ruta (giros, rotondas, llegada). Vacío si no se pidieron.
  final List<RouteStep> steps;

  const RouteResult({
    required this.coordinates,
    required this.distanceMeters,
    required this.durationSeconds,
    this.steps = const [],
  });

  String get distanceLabel {
    if (distanceMeters >= 1000) {
      return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
    }
    return '${distanceMeters.round()} m';
  }

  String get durationLabel {
    final minutes = (durationSeconds / 60).round();
    if (minutes < 60) return '$minutes min';

    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    return rest == 0 ? '$hours h' : '$hours h $rest min';
  }
}

/// Perfiles disponibles en la Directions API.
class RouteProfile {
  static const driving = 'driving';
  static const walking = 'walking';
  static const cycling = 'cycling';
  static const drivingTraffic = 'driving-traffic';
}

class MapboxDirectionsService {
  MapboxDirectionsService({required this.accessToken, http.Client? client})
    : _client = client ?? http.Client();

  final String accessToken;
  final http.Client _client;

  /// Calcula la ruta entre dos puntos.
  /// Devuelve null si Mapbox no encuentra ninguna ruta.
  Future<RouteResult?> getRoute({
    required double fromLongitude,
    required double fromLatitude,
    required double toLongitude,
    required double toLatitude,
    String profile = RouteProfile.driving,
  }) async {
    final uri = Uri.https(
      'api.mapbox.com',
      '/directions/v5/mapbox/$profile/'
          '$fromLongitude,$fromLatitude;$toLongitude,$toLatitude',
      {
        'geometries': 'geojson', // la línea llega como lista de coordenadas
        'overview': 'full', // geometría completa (no simplificada)
        'steps': 'true', // maniobras: giros, rotondas y llegada
        'access_token': accessToken,
      },
    );

    final response = await _client
        .get(uri)
        .timeout(const Duration(seconds: 15));

    // 422: Mapbox no puede generar una ruta entre estos puntos (por ejemplo,
    // están demasiado lejos). Es un «sin ruta», no un fallo de la app.
    if (response.statusCode == 422) {
      return null;
    }

    if (response.statusCode != 200) {
      throw Exception('Directions API: HTTP ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final routes = json['routes'] as List<dynamic>?;

    if (json['code'] != 'Ok' || routes == null || routes.isEmpty) {
      return null;
    }

    final best = routes.first as Map<String, dynamic>;
    final geometry = best['geometry'] as Map<String, dynamic>;
    final rawCoordinates = geometry['coordinates'] as List<dynamic>;

    final coordinates = rawCoordinates
        .map<List<double>>(
          (point) => [
            (point[0] as num).toDouble(),
            (point[1] as num).toDouble(),
          ],
        )
        .toList();

    return RouteResult(
      coordinates: coordinates,
      distanceMeters: (best['distance'] as num).toDouble(),
      durationSeconds: (best['duration'] as num).toDouble(),
      steps: _parseSteps(best['legs'], coordinates),
    );
  }

  /// Convierte las maniobras de Mapbox y las ubica sobre la línea, en orden.
  /// Una maniobra mal formada se omite: no debe impedir mostrar la ruta.
  List<RouteStep> _parseSteps(Object? legs, List<List<double>> coordinates) {
    final steps = <RouteStep>[];
    if (legs is! List<dynamic>) return steps;

    var searchFrom = 0;
    for (final leg in legs) {
      final rawSteps = leg is Map<String, dynamic> ? leg['steps'] : null;
      if (rawSteps is! List<dynamic>) continue;

      for (final raw in rawSteps) {
        final maneuver = raw is Map<String, dynamic> ? raw['maneuver'] : null;
        if (maneuver is! Map<String, dynamic>) continue;
        final location = maneuver['location'];
        if (location is! List<dynamic> || location.length < 2) continue;

        final index = routeIndexOf(
          coordinates,
          (location[0] as num).toDouble(),
          (location[1] as num).toDouble(),
          start: searchFrom,
        );
        searchFrom = index;
        steps.add(
          RouteStep(
            type: maneuver['type'] as String? ?? '',
            modifier: maneuver['modifier'] as String?,
            name: (raw as Map<String, dynamic>)['name'] as String? ?? '',
            coordIndex: index,
          ),
        );
      }
    }
    return steps;
  }

  void dispose() => _client.close();
}
