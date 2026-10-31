import '../../../categories/data/models/place_dto.dart';
import '../../domain/itinerary_planner.dart';

/// Convierte un registro de places_v2 en un lugar del planificador.
PlannerPlace plannerPlaceFromDto(PlaceDto dto) {
  return PlannerPlace(
    id: dto.id,
    nameEs: dto.titleEs,
    nameEn: dto.titleEn,
    kind: dto.kind,
    // Con la jerarquía de categorías, los intereses son categorías
    // principales: se compara con la principal de la subcategoría.
    categoryId: dto.category?.parentId ?? dto.categoryId,
    categoryNameEs: dto.category?.nombreEs,
    categoryNameEn: dto.category?.nombreEn,
    latitude: dto.latitude,
    longitude: dto.longitude,
    visitMinutes: ItineraryPlanner.defaultVisitMinutes(dto.kind),
  );
}

/// Itinerario guardado (itineraries_v2), para la lista «Mis itinerarios».
class SavedItinerarySummary {
  const SavedItinerarySummary({
    required this.id,
    required this.name,
    required this.itemCount,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final int itemCount;
  final DateTime? updatedAt;

  factory SavedItinerarySummary.fromJson(Map<String, dynamic> json) {
    var count = 0;
    final items = json['itinerary_items_v2'];
    if (items is List && items.isNotEmpty) {
      final first = items.first;
      if (first is Map && first['count'] is num) {
        count = (first['count'] as num).toInt();
      }
    }

    return SavedItinerarySummary(
      id: json['id'].toString(),
      name: (json['name'] ?? '').toString(),
      itemCount: count,
      updatedAt: DateTime.tryParse(
        (json['updated_at'] ?? json['created_at'] ?? '').toString(),
      )?.toLocal(),
    );
  }
}

/// Itinerario guardado con sus lugares en orden (itinerary_items_v2).
class SavedItineraryDetail {
  const SavedItineraryDetail({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.stops,
    required this.firstPlannedMinute,
    required this.missingPlaces,
  });

  final String id;
  final String name;
  final String ownerId;
  final List<PlannerPlace> stops;

  /// Hora planificada del primer lugar, en minutos desde la medianoche.
  final int? firstPlannedMinute;

  /// Lugares guardados que ya no están activos en el catálogo.
  final int missingPlaces;
}

/// Lugar a guardar con su posición y hora estimada.
class ItineraryItemInput {
  const ItineraryItemInput({
    required this.placeId,
    required this.position,
    required this.plannedMinute,
  });

  final String placeId;
  final int position;
  final int plannedMinute;

  /// Formato de la columna planned_time (time) de Postgres.
  String get plannedTime => '${ItineraryPlanner.formatClock(plannedMinute)}:00';
}

/// Convierte «HH:mm:ss» en minutos desde la medianoche.
int? parsePlannedTime(Object? value) {
  final text = value?.toString();
  if (text == null || text.isEmpty) return null;
  final parts = text.split(':');
  if (parts.length < 2) return null;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null) return null;
  return h * 60 + m;
}
