import 'dart:math' as math;

/// Distancia, en metros, a partir de la cual se avisa que el usuario se alejó
/// de la ruta. Sirve para no avisar por el error normal del GPS.
const double offRouteMeters = 50;

/// Distancia en metros desde un punto hasta la parte más cercana de la ruta.
///
/// [coordinates] viene en formato [longitud, latitud], como lo entrega
/// Mapbox. La proyección es plana y local: basta para distancias de pocos km.
double distanceToRouteMeters(
  double lat,
  double lng,
  List<List<double>> coordinates,
) {
  if (coordinates.isEmpty) return double.infinity;

  if (coordinates.length == 1) {
    final p = coordinates.first;
    return _distanceToSegmentMeters(lat, lng, p[1], p[0], p[1], p[0]);
  }

  var best = double.infinity;
  for (var i = 0; i < coordinates.length - 1; i++) {
    final a = coordinates[i];
    final b = coordinates[i + 1];
    final d = _distanceToSegmentMeters(lat, lng, a[1], a[0], b[1], b[0]);
    if (d < best) best = d;
  }
  return best;
}

double _distanceToSegmentMeters(
  double lat,
  double lng,
  double lat1,
  double lng1,
  double lat2,
  double lng2,
) {
  const kmPerDegLat = 111.2;
  final kmPerDegLng = kmPerDegLat * math.cos(lat * math.pi / 180);

  final px = (lng - lng1) * kmPerDegLng;
  final py = (lat - lat1) * kmPerDegLat;
  final bx = (lng2 - lng1) * kmPerDegLng;
  final by = (lat2 - lat1) * kmPerDegLat;

  final lengthSquared = bx * bx + by * by;
  final t = lengthSquared == 0
      ? 0.0
      : ((px * bx + py * by) / lengthSquared).clamp(0.0, 1.0);

  final dx = px - t * bx;
  final dy = py - t * by;
  return math.sqrt(dx * dx + dy * dy) * 1000;
}

/// Índice del punto de [coordinates] más cercano a la posición. Devuelve 0 si
/// la ruta está vacía. Usa el mismo formato [longitud, latitud].
int nearestRouteIndex(double lat, double lng, List<List<double>> coordinates) {
  var bestIndex = 0;
  var bestDistance = double.infinity;
  for (var i = 0; i < coordinates.length; i++) {
    final d = distanceToRouteMeters(lat, lng, [coordinates[i]]);
    if (d < bestDistance) {
      bestDistance = d;
      bestIndex = i;
    }
  }
  return bestIndex;
}
