import 'package:coyhaique_basecamp_pt/features/transport/domain/airport_zone.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const airportLat = AirportZones.airportLatitude;
  const airportLon = AirportZones.airportLongitude;
  const cityLat = AirportZones.cityLatitude;
  const cityLon = AirportZones.cityLongitude;

  // 1 grado de latitud ≈ 111,19 km.
  test('el aeropuerto cuenta como «en el aeropuerto»', () {
    expect(AirportZones.classify(airportLat, airportLon), AirportZone.atAirport);
  });

  test('a 4 km del aeropuerto sigue dentro del radio', () {
    expect(
      AirportZones.classify(airportLat + 0.036, airportLon),
      AirportZone.atAirport,
    );
  });

  test('a 6 km del aeropuerto queda fuera del radio', () {
    expect(
      AirportZones.classify(airportLat + 0.054, airportLon),
      AirportZone.elsewhere,
    );
  });

  test('la Plaza de Armas está en la ciudad', () {
    expect(AirportZones.classify(cityLat, cityLon), AirportZone.inCity);
  });

  test('a 10 km de la plaza sigue siendo ciudad; a 20 km no', () {
    expect(
      AirportZones.classify(cityLat + 0.09, cityLon),
      AirportZone.inCity,
    );
    expect(
      AirportZones.classify(cityLat + 0.18, cityLon),
      AirportZone.elsewhere,
    );
  });

  test('un punto a medio camino entre ciudad y aeropuerto no es ninguno', () {
    expect(
      AirportZones.classify(
        (cityLat + airportLat) / 2,
        (cityLon + airportLon) / 2,
      ),
      AirportZone.elsewhere,
    );
  });

  test('Coyhaique y Balmaceda están a unos 50 km', () {
    final km = AirportZones.distanceKm(cityLat, cityLon, airportLat, airportLon);
    expect(km, inInclusiveRange(45, 60));
  });
}
