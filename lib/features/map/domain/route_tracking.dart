import 'dart:math' as math;

/// Distancia, en metros, a partir de la cual se avisa que el usuario se alejó
/// de la ruta. Sirve para no avisar por el error normal del GPS.
const double offRouteMeters = 50;

/// Distancia al destino, en metros, a partir de la cual se da por llegado.
const double arrivalMeters = 40;

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

/// Fracción de la ruta que falta por recorrer (1 = toda, 0 = llegó), según el
/// punto [fromIndex] donde está el usuario. Pondera cada tramo por su largo,
/// porque los puntos de Mapbox no están a distancias iguales.
double remainingRouteFraction(List<List<double>> coordinates, int fromIndex) {
  if (coordinates.length < 2) return 0;
  if (fromIndex <= 0) return 1;
  if (fromIndex >= coordinates.length - 1) return 0;

  var total = 0.0;
  var remaining = 0.0;
  for (var i = 0; i < coordinates.length - 1; i++) {
    final a = coordinates[i];
    final b = coordinates[i + 1];
    final length = _distanceToSegmentMeters(a[1], a[0], b[1], b[0], b[1], b[0]);
    total += length;
    if (i >= fromIndex) remaining += length;
  }
  return total == 0 ? 1 : remaining / total;
}

/// Largo, en metros, del tramo de la ruta entre los puntos [from] y [to].
double routeLengthMeters(List<List<double>> coordinates, int from, int to) {
  final end = math.min(to, coordinates.length - 1);
  var total = 0.0;
  for (var i = math.max(from, 0); i < end; i++) {
    final a = coordinates[i];
    final b = coordinates[i + 1];
    total += _distanceToSegmentMeters(a[1], a[0], b[1], b[0], b[1], b[0]);
  }
  return total;
}

/// Rumbo, en grados (0 = norte, 90 = este), con que sigue la ruta desde el
/// punto [index]. Mira unos 25 m hacia adelante para no depender de un
/// tramo diminuto. Sirve para orientar el mapa cuando el GPS no da rumbo
/// (por ejemplo, con el auto detenido).
double routeBearingAt(List<List<double>> coordinates, int index) {
  if (coordinates.length < 2) return 0;
  final start = index.clamp(0, coordinates.length - 2);
  final from = coordinates[start];

  var target = coordinates[start + 1];
  for (var i = start + 1; i < coordinates.length; i++) {
    target = coordinates[i];
    final d = distanceToRouteMeters(from[1], from[0], [target]);
    if (d >= 25) break;
  }

  final dLng = (target[0] - from[0]) * math.cos(from[1] * math.pi / 180);
  final dLat = target[1] - from[1];
  if (dLng == 0 && dLat == 0) return 0;
  final degrees = math.atan2(dLng, dLat) * 180 / math.pi;
  return (degrees + 360) % 360;
}
