import 'dart:math' as math;

/// Dónde está el usuario respecto al transfer: en el radio del aeropuerto,
/// en la ciudad de Coyhaique o en cualquier otro lugar.
enum AirportZone { atAirport, inCity, elsewhere }

/// Zonas del transfer (HU-18). Funciones puras, sin acceso a la ubicación.
abstract final class AirportZones {
  /// Aeropuerto de Balmaceda (SCBA / BBA).
  static const double airportLatitude = -45.9161;
  static const double airportLongitude = -71.6895;

  /// Radio alrededor del aeropuerto en que se ofrece el transfer de llegada.
  static const double airportRadiusKm = 5;

  /// Plaza de Armas de Coyhaique, el mismo punto que usa el planificador.
  static const double cityLatitude = -45.5712;
  static const double cityLongitude = -72.0685;

  /// Radio que se considera «en la ciudad».
  static const double cityRadiusKm = 15;

  /// Distancia en línea recta (haversine), en kilómetros.
  static double distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusKm = 6371.0;
    double rad(double degrees) => degrees * math.pi / 180;

    final dLat = rad(lat2 - lat1);
    final dLon = rad(lon2 - lon1);
    final a =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(rad(lat1)) *
            math.cos(rad(lat2)) *
            math.pow(math.sin(dLon / 2), 2);
    return 2 * earthRadiusKm * math.asin(math.sqrt(a));
  }

  static AirportZone classify(double latitude, double longitude) {
    final toAirport = distanceKm(
      latitude,
      longitude,
      airportLatitude,
      airportLongitude,
    );
    if (toAirport <= airportRadiusKm) return AirportZone.atAirport;

    final toCity = distanceKm(
      latitude,
      longitude,
      cityLatitude,
      cityLongitude,
    );
    if (toCity <= cityRadiusKm) return AirportZone.inCity;

    return AirportZone.elsewhere;
  }
}
