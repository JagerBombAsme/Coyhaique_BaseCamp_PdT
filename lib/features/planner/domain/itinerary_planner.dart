import 'dart:math' as math;

/// Reglas explícitas de la propuesta de itinerario (HU-07).
///
/// No usa inteligencia artificial ni perfilamiento: la propuesta depende solo
/// de los intereses que declara el usuario, de la duración estimada de cada
/// visita y de la distancia desde el punto de partida. Las mismas entradas
/// producen siempre la misma propuesta, lo que permite verificarla.
class ItineraryPlanner {
  const ItineraryPlanner._();

  /// Punto de partida por defecto: Plaza de Armas de Coyhaique.
  static const PlannerOrigin coyhaique = PlannerOrigin(
    latitude: -45.5712,
    longitude: -72.0685,
    isUserLocation: false,
  );

  /// Duración por defecto mientras places_v2 no tenga la columna
  /// estimated_visit_minutes (registro de cambios pendientes en Supabase).
  static const int defaultPlaceMinutes = 60;
  static const int defaultActivityMinutes = 120;

  /// Velocidad media en carretera y factor de corrección de la línea recta.
  /// El traslado es una estimación referencial, no una ruta (HU-07).
  static const double averageSpeedKmh = 40;
  static const double roadFactor = 1.3;

  /// Máximo de lugares propuestos en un día.
  static const int maxStops = 8;

  /// Duración estimada de la visita según el tipo de registro.
  static int defaultVisitMinutes(String kind) =>
      kind == 'activity' ? defaultActivityMinutes : defaultPlaceMinutes;

  /// Distancia en línea recta (fórmula del haversine), en kilómetros.
  static double distanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusKm = 6371.0;
    double rad(double deg) => deg * math.pi / 180;
    final dLat = rad(lat2 - lat1);
    final dLon = rad(lon2 - lon1);
    final a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(rad(lat1)) *
            math.cos(rad(lat2)) *
            math.pow(math.sin(dLon / 2), 2);
    return 2 * earthRadiusKm * math.asin(math.sqrt(a));
  }

  /// Minutos de traslado estimados, redondeados hacia arriba a 5 minutos.
  /// Devuelve 0 si alguno de los puntos no tiene coordenadas.
  static int travelMinutes(
    double? fromLat,
    double? fromLon,
    double? toLat,
    double? toLon,
  ) {
    if (fromLat == null || fromLon == null || toLat == null || toLon == null) {
      return 0;
    }
    final km = distanceKm(fromLat, fromLon, toLat, toLon) * roadFactor;
    final minutes = km / averageSpeedKmh * 60;
    if (minutes <= 0) return 0;
    return (minutes / 5).ceil() * 5;
  }

  /// Genera la propuesta.
  ///
  /// 1. Considera solo lugares con coordenadas y, si el usuario declaró
  ///    intereses, solo los de esas categorías.
  /// 2. Desde el punto actual elige el lugar más cercano cuyo traslado,
  ///    visita y regreso al punto de partida caben en el tiempo restante.
  /// 3. Repite hasta que no quepa ningún otro lugar o se llegue a [maxStops].
  ///
  /// Los empates se resuelven por nombre para que el resultado sea estable.
  static List<PlannerPlace> propose({
    required List<PlannerPlace> candidates,
    required PlannerOrigin origin,
    required int availableMinutes,
    Set<String> interests = const {},
  }) {
    final pool = candidates
        .where((p) => p.hasLocation)
        .where((p) => interests.isEmpty || interests.contains(p.categoryId))
        .toList()
      ..sort((a, b) => a.nameEs.compareTo(b.nameEs));

    final result = <PlannerPlace>[];
    var remaining = availableMinutes;
    var currentLat = origin.latitude;
    var currentLon = origin.longitude;

    while (result.length < maxStops) {
      PlannerPlace? best;
      var bestTravel = 0;
      var bestDistance = double.infinity;

      for (final place in pool) {
        final travel = travelMinutes(
          currentLat,
          currentLon,
          place.latitude,
          place.longitude,
        );
        final back = travelMinutes(
          place.latitude,
          place.longitude,
          origin.latitude,
          origin.longitude,
        );
        if (travel + place.visitMinutes + back > remaining) continue;

        final distance = distanceKm(
          currentLat,
          currentLon,
          place.latitude!,
          place.longitude!,
        );
        if (distance < bestDistance) {
          best = place;
          bestTravel = travel;
          bestDistance = distance;
        }
      }

      if (best == null) break;

      result.add(best);
      pool.remove(best);
      remaining -= bestTravel + best.visitMinutes;
      currentLat = best.latitude!;
      currentLon = best.longitude!;
    }

    return result;
  }

  /// Calcula la hora estimada de llegada a cada lugar, en el orden dado
  /// (el usuario puede reordenar, agregar o quitar lugares).
  static ItinerarySchedule schedule({
    required List<PlannerPlace> stops,
    required PlannerOrigin origin,
    required int startMinute,
  }) {
    final scheduled = <ScheduledStop>[];
    var clock = startMinute;
    double? lat = origin.latitude;
    double? lon = origin.longitude;

    for (final place in stops) {
      final travel = travelMinutes(lat, lon, place.latitude, place.longitude);
      clock += travel;
      scheduled.add(
        ScheduledStop(place: place, travelMinutes: travel, arrivalMinute: clock),
      );
      clock += place.visitMinutes;
      if (place.hasLocation) {
        lat = place.latitude;
        lon = place.longitude;
      }
    }

    final back = stops.isEmpty
        ? 0
        : travelMinutes(lat, lon, origin.latitude, origin.longitude);

    return ItinerarySchedule(
      stops: scheduled,
      startMinute: startMinute,
      returnTravelMinutes: back,
      endMinute: clock + back,
    );
  }

  /// Formatea minutos desde la medianoche como HH:mm (24 h).
  static String formatClock(int minuteOfDay) {
    final m = minuteOfDay % (24 * 60);
    final h = (m ~/ 60).toString().padLeft(2, '0');
    final mm = (m % 60).toString().padLeft(2, '0');
    return '$h:$mm';
  }

  /// Formatea una duración como «1 h 30 min», «45 min» o «2 h».
  static String formatDuration(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '$m min';
    if (m == 0) return '$h h';
    return '$h h $m min';
  }
}

/// Punto desde el que se calcula la propuesta.
class PlannerOrigin {
  const PlannerOrigin({
    required this.latitude,
    required this.longitude,
    required this.isUserLocation,
  });

  final double latitude;
  final double longitude;

  /// true si es la ubicación del usuario; false si es Coyhaique.
  final bool isUserLocation;
}

/// Lugar o actividad que puede formar parte del itinerario.
class PlannerPlace {
  const PlannerPlace({
    required this.id,
    required this.nameEs,
    this.nameEn,
    required this.kind,
    required this.categoryId,
    this.categoryNameEs,
    this.categoryNameEn,
    this.latitude,
    this.longitude,
    required this.visitMinutes,
  });

  final String id;
  final String nameEs;
  final String? nameEn;
  final String kind;
  final String categoryId;
  final String? categoryNameEs;
  final String? categoryNameEn;
  final double? latitude;
  final double? longitude;
  final int visitMinutes;

  bool get hasLocation => latitude != null && longitude != null;

  String name(bool isSpanish) {
    final en = nameEn;
    return !isSpanish && en != null && en.isNotEmpty ? en : nameEs;
  }

  String? categoryName(bool isSpanish) {
    final en = categoryNameEn;
    return !isSpanish && en != null && en.isNotEmpty ? en : categoryNameEs;
  }

  @override
  bool operator ==(Object other) => other is PlannerPlace && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Lugar con su hora estimada de llegada.
class ScheduledStop {
  const ScheduledStop({
    required this.place,
    required this.travelMinutes,
    required this.arrivalMinute,
  });

  final PlannerPlace place;
  final int travelMinutes;
  final int arrivalMinute;

  int get departureMinute => arrivalMinute + place.visitMinutes;
}

/// Itinerario con horarios estimados.
class ItinerarySchedule {
  const ItinerarySchedule({
    required this.stops,
    required this.startMinute,
    required this.returnTravelMinutes,
    required this.endMinute,
  });

  final List<ScheduledStop> stops;
  final int startMinute;
  final int returnTravelMinutes;
  final int endMinute;

  int get totalMinutes => endMinute - startMinute;
}
