import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../categories/data/models/place_dto.dart';
import '../models/itinerary_models.dart';

/// Itinerarios guardados del usuario (itineraries_v2 e itinerary_items_v2).
///
/// Guardar y recuperar requiere sesión iniciada. Las políticas RLS de
/// Supabase dejan ver y modificar solo los itinerarios propios (HU-07,
/// MASVS-AUTH). Requiere conexión: los itinerarios no se guardan en la copia
/// local del catálogo.
class ItineraryRepository {
  ItineraryRepository(this._client);

  final SupabaseClient _client;

  static const Duration _timeout = Duration(seconds: 15);

  String _requireUserId() {
    final user = _client.auth.currentUser;
    if (user == null) throw const ItineraryAuthRequiredException();
    return user.id;
  }

  /// Itinerarios del usuario, del más reciente al más antiguo.
  Future<List<SavedItinerarySummary>> listMine() async {
    final userId = _requireUserId();
    final rows = await _client
        .from('itineraries_v2')
        .select('id, name, created_at, updated_at, itinerary_items_v2(count)')
        .eq('user_id', userId)
        .order('updated_at', ascending: false)
        .timeout(_timeout);
    return rows.map(SavedItinerarySummary.fromJson).toList();
  }

  /// Itinerario con sus lugares en orden.
  Future<SavedItineraryDetail> getDetail(String itineraryId) async {
    _requireUserId();

    final header = await _client
        .from('itineraries_v2')
        .select('id, name, user_id')
        .eq('id', itineraryId)
        .single()
        .timeout(_timeout);

    final items = await _client
        .from('itinerary_items_v2')
        .select('position, planned_time, place_id, places_v2(*, categories_v2(*))')
        .eq('itinerary_id', itineraryId)
        .order('position')
        .timeout(_timeout);

    final stops = <PlaceDto>[];
    var missing = 0;
    int? firstMinute;

    for (final row in items) {
      final place = row['places_v2'];
      final active = place is Map &&
          place['is_active'] != false &&
          place['retired_at'] == null;
      if (!active) {
        missing++;
        continue;
      }
      firstMinute ??= parsePlannedTime(row['planned_time']);
      stops.add(PlaceDto.fromJson(Map<String, dynamic>.from(place)));
    }

    return SavedItineraryDetail(
      id: header['id'].toString(),
      name: (header['name'] ?? '').toString(),
      ownerId: header['user_id'].toString(),
      stops: stops.map(plannerPlaceFromDto).toList(),
      firstPlannedMinute: firstMinute,
      missingPlaces: missing,
    );
  }

  /// Crea un itinerario y devuelve su id. Si fallan los lugares, elimina la
  /// cabecera para no dejar itinerarios vacíos.
  Future<String> create({
    required String name,
    required List<ItineraryItemInput> items,
  }) async {
    final userId = _requireUserId();

    final created = await _client
        .from('itineraries_v2')
        .insert({'user_id': userId, 'name': name.trim()})
        .select('id')
        .single()
        .timeout(_timeout);
    final id = created['id'].toString();

    try {
      await _insertItems(id, items);
    } catch (_) {
      await _client.from('itineraries_v2').delete().eq('id', id);
      rethrow;
    }
    return id;
  }

  /// Reemplaza el nombre y los lugares de un itinerario propio. Si la
  /// inserción de los lugares nuevos falla, intenta restaurar los anteriores.
  Future<void> update({
    required String itineraryId,
    required String name,
    required List<ItineraryItemInput> items,
  }) async {
    _requireUserId();

    final previous = await _client
        .from('itinerary_items_v2')
        .select('place_id, position, planned_time, notes')
        .eq('itinerary_id', itineraryId)
        .timeout(_timeout);

    await _client
        .from('itineraries_v2')
        .update({
          'name': name.trim(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', itineraryId)
        .timeout(_timeout);

    await _client
        .from('itinerary_items_v2')
        .delete()
        .eq('itinerary_id', itineraryId)
        .timeout(_timeout);

    try {
      await _insertItems(itineraryId, items);
    } catch (_) {
      if (previous.isNotEmpty) {
        await _client.from('itinerary_items_v2').insert([
          for (final row in previous) {...row, 'itinerary_id': itineraryId},
        ]);
      }
      rethrow;
    }
  }

  /// Elimina un itinerario propio; sus lugares se borran en cascada.
  Future<void> delete(String itineraryId) async {
    _requireUserId();
    await _client
        .from('itineraries_v2')
        .delete()
        .eq('id', itineraryId)
        .timeout(_timeout);
  }

  Future<void> _insertItems(
    String itineraryId,
    List<ItineraryItemInput> items,
  ) async {
    if (items.isEmpty) return;
    await _client
        .from('itinerary_items_v2')
        .insert([
          for (final item in items)
            {
              'itinerary_id': itineraryId,
              'place_id': item.placeId,
              'position': item.position,
              'planned_time': item.plannedTime,
            },
        ])
        .timeout(_timeout);
  }
}

/// Se lanza al intentar guardar o consultar itinerarios sin sesión.
class ItineraryAuthRequiredException implements Exception {
  const ItineraryAuthRequiredException();

  @override
  String toString() => 'Debes iniciar sesión para guardar itinerarios.';
}
