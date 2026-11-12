import 'package:coyhaique_basecamp_pt/features/map/presentation/map_places.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const places = [MapPlaces.center, ...MapPlaces.all];

  test('every place has text in both languages', () {
    for (final place in places) {
      expect(place.name(isSpanish: true), isNotEmpty);
      expect(place.name(isSpanish: false), isNotEmpty);
      expect(place.description(isSpanish: true), isNotEmpty);
      expect(place.description(isSpanish: false), isNotEmpty);
    }
  });

  test('every description is actually translated', () {
    for (final place in places) {
      expect(
        place.description(isSpanish: false),
        isNot(place.description(isSpanish: true)),
      );
    }
  });

  test('returns the text of the requested language', () {
    const place = MapPlace(
      nameEs: 'Aeropuerto',
      nameEn: 'Airport',
      descriptionEs: 'Vuelos',
      descriptionEn: 'Flights',
      icon: Icons.flight,
      longitude: 0,
      latitude: 0,
    );

    expect(place.name(isSpanish: true), 'Aeropuerto');
    expect(place.name(isSpanish: false), 'Airport');
    expect(place.description(isSpanish: true), 'Vuelos');
    expect(place.description(isSpanish: false), 'Flights');
  });

  test('search finds a place in either language, ignoring accents and case', () {
    expect(MapPlaces.airport.matches('aeropuerto'), isTrue);
    expect(MapPlaces.airport.matches('AIRPORT'), isTrue);
    expect(MapPlaces.airport.matches('Balmaceda'), isTrue);
    expect(MapPlaces.airport.matches('plaza'), isFalse);
  });

  test('an empty search matches every place', () {
    expect(places.every((place) => place.matches('  ')), isTrue);
  });
}
