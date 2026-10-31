import 'dart:convert';

import 'package:http/http.dart' as http;

/// Resultado de una ruta calculada por Mapbox.
class RouteResult {
  /// Puntos de la ruta en formato [longitud, latitud].
  final List<List<double>> coordinates;
  final double distanceMeters;
  final double durationSeconds;

  const RouteResult({
    required this.coordinates,
    required this.distanceMeters,
    required this.durationSeconds,
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
        'access_token': accessToken,
      },
    );

    final response = await _client
        .get(uri)
        .timeout(const Duration(seconds: 15));

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
    );
  }

  void dispose() => _client.close();
}
