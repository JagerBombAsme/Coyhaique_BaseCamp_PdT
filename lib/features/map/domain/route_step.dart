import 'route_tracking.dart';

/// Una maniobra de la ruta (giro, rotonda, llegada…) tal como la entrega
/// Mapbox, ubicada sobre la línea dibujada.
class RouteStep {
  const RouteStep({
    required this.type,
    required this.modifier,
    required this.name,
    required this.coordIndex,
  });

  /// Tipo de Mapbox: turn, depart, arrive, roundabout, fork, merge…
  final String type;

  /// Dirección de Mapbox: left, slight right, straight, uturn… Puede faltar.
  final String? modifier;

  /// Calle a la que lleva la maniobra. Vacío si no tiene nombre.
  final String name;

  /// Índice del punto de la línea donde ocurre la maniobra.
  final int coordIndex;
}

/// Índice del punto de [coordinates] más cercano a ([lng], [lat]), buscando
/// desde [start]. Así una ruta que pasa dos veces por el mismo lugar no
/// confunde el orden de las maniobras.
int routeIndexOf(
  List<List<double>> coordinates,
  double lng,
  double lat, {
  int start = 0,
}) {
  if (coordinates.isEmpty) return 0;
  var bestIndex = start.clamp(0, coordinates.length - 1);
  var bestDistance = double.infinity;
  for (var i = bestIndex; i < coordinates.length; i++) {
    final d = distanceToRouteMeters(lat, lng, [coordinates[i]]);
    if (d < bestDistance) {
      bestDistance = d;
      bestIndex = i;
    }
  }
  return bestIndex;
}

/// Próxima maniobra por delante del punto [fromIndex] de la ruta. La salida
/// («depart») no cuenta. Null si ya no queda ninguna.
RouteStep? nextManeuverStep(List<RouteStep> steps, int fromIndex) {
  for (final step in steps) {
    if (step.type == 'depart') continue;
    if (step.coordIndex > fromIndex) return step;
  }
  return null;
}
