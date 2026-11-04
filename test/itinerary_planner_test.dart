import 'package:coyhaique_basecamp_pt/features/planner/domain/itinerary_planner.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pruebas de las reglas de la propuesta de itinerario (HU-07).
void main() {
  const origin = ItineraryPlanner.coyhaique;

  PlannerPlace place(
    String id, {
    required double lat,
    required double lon,
    String category = 'cat-a',
    String kind = 'place',
  }) {
    return PlannerPlace(
      id: id,
      nameEs: 'Lugar $id',
      kind: kind,
      categoryId: category,
      latitude: lat,
      longitude: lon,
      visitMinutes: ItineraryPlanner.defaultVisitMinutes(kind),
    );
  }

  // Cerca de la plaza (≈1 km), a media distancia (≈10 km) y lejos (≈90 km).
  final near = place('near', lat: -45.5650, lon: -72.0600);
  final mid = place('mid', lat: -45.6000, lon: -71.9600, category: 'cat-b');
  final far = place('far', lat: -46.3000, lon: -72.4000);
  final noLocation = PlannerPlace(
    id: 'none',
    nameEs: 'Sin coordenadas',
    kind: 'place',
    categoryId: 'cat-a',
    visitMinutes: 60,
  );

  test('elige primero el lugar más cercano y respeta el tiempo', () {
    final result = ItineraryPlanner.propose(
      candidates: [far, mid, near],
      origin: origin,
      availableMinutes: 4 * 60,
    );

    expect(result.map((p) => p.id), ['near', 'mid']);
  });

  test('filtra por intereses declarados', () {
    final result = ItineraryPlanner.propose(
      candidates: [far, mid, near],
      origin: origin,
      availableMinutes: 4 * 60,
      interests: {'cat-b'},
    );

    expect(result.map((p) => p.id), ['mid']);
  });

  test('omite lugares sin coordenadas y devuelve vacío si nada cabe', () {
    final result = ItineraryPlanner.propose(
      candidates: [noLocation, far],
      origin: origin,
      availableMinutes: 2 * 60,
    );

    expect(result, isEmpty);
  });

  test('las mismas entradas producen la misma propuesta', () {
    List<String> run() => ItineraryPlanner.propose(
          candidates: [mid, far, near],
          origin: origin,
          availableMinutes: 12 * 60,
        ).map((p) => p.id).toList();

    expect(run(), run());
  });

  test('el horario suma traslados y visitas en el orden indicado', () {
    final schedule = ItineraryPlanner.schedule(
      stops: [near, mid],
      origin: origin,
      startMinute: 9 * 60,
    );

    final first = schedule.stops[0];
    final second = schedule.stops[1];

    expect(first.arrivalMinute, 9 * 60 + first.travelMinutes);
    expect(
      second.arrivalMinute,
      first.departureMinute + second.travelMinutes,
    );
    expect(
      schedule.endMinute,
      second.departureMinute + schedule.returnTravelMinutes,
    );
  });

  test('traslado redondeado a 5 minutos y 0 sin coordenadas', () {
    final t = ItineraryPlanner.travelMinutes(
      origin.latitude,
      origin.longitude,
      mid.latitude,
      mid.longitude,
    );
    expect(t % 5, 0);
    expect(t, greaterThan(0));
    expect(
      ItineraryPlanner.travelMinutes(origin.latitude, origin.longitude, null, null),
      0,
    );
  });

  test('formato de hora y duración', () {
    expect(ItineraryPlanner.formatClock(9 * 60 + 5), '09:05');
    expect(ItineraryPlanner.formatDuration(45), '45 min');
    expect(ItineraryPlanner.formatDuration(120), '2 h');
    expect(ItineraryPlanner.formatDuration(95), '1 h 35 min');
  });
}
