import 'package:coyhaique_basecamp_pt/features/planner/data/models/itinerary_models.dart';
import 'package:coyhaique_basecamp_pt/features/planner/data/providers/planner_provider.dart';
import 'package:coyhaique_basecamp_pt/features/planner/domain/itinerary_planner.dart';
import 'package:flutter_test/flutter_test.dart';

PlannerPlace _place(String id, {double lat = -45.57, double lon = -72.07}) {
  return PlannerPlace(
    id: id,
    nameEs: 'Lugar $id',
    kind: 'place',
    categoryId: 'c',
    latitude: lat,
    longitude: lon,
    visitMinutes: 60,
  );
}

void main() {
  group('PlannerState con varios días', () {
    final a = _place('a');
    final b = _place('b');
    final c = _place('c');

    test('sin propuesta no hay días', () {
      const state = PlannerState();
      expect(state.hasProposal, isFalse);
      expect(state.dayCount, 0);
      expect(state.stops, isNull);
      expect(state.allPlaces, isEmpty);
    });

    test('stops y schedule corresponden al día activo', () {
      final state = const PlannerState().copyWith(
        days: [
          [a, b],
          [c],
        ],
        activeDay: 1,
      );
      expect(state.dayCount, 2);
      expect(state.stops, [c]);
      expect(state.schedule.stops.map((s) => s.place), [c]);
      expect(state.scheduleOf(0).stops.map((s) => s.place), [a, b]);
    });

    test('allPlaces junta los lugares de todos los días', () {
      final state = const PlannerState().copyWith(
        days: [
          [a],
          [b, c],
        ],
      );
      expect(state.allPlaces, {a, b, c});
    });

    test('todos los días parten de la misma hora de inicio', () {
      final state = const PlannerState().copyWith(
        startMinute: 8 * 60,
        days: [
          [a],
          [b],
        ],
      );
      expect(state.scheduleOf(0).startMinute, 8 * 60);
      expect(state.scheduleOf(1).startMinute, 8 * 60);
    });

    test('un día fuera de rango da un horario vacío', () {
      final state = const PlannerState().copyWith(
        days: [
          [a],
        ],
      );
      expect(state.scheduleOf(5).stops, isEmpty);
    });

    test('clearDays vuelve al formulario y al día 1', () {
      final state = const PlannerState()
          .copyWith(
            days: [
              [a],
            ],
            activeDay: 0,
          )
          .copyWith(clearDays: true);
      expect(state.hasProposal, isFalse);
      expect(state.activeDay, 0);
    });
  });

  group('ItineraryItemInput', () {
    test('el día por defecto es 1', () {
      const item = ItineraryItemInput(
        placeId: 'p',
        position: 0,
        plannedMinute: 9 * 60,
      );
      expect(item.dayIndex, 1);
      expect(item.plannedTime, '09:00:00');
    });
  });
}
