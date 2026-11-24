import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/connectivity/network_status.dart';
import '../../../../core/local/catalog_local_db.dart';
import '../../../../core/models/category_model.dart';
import '../../../../core/models/informational_content_dto.dart';
import '../models/place_dto.dart';

/// Repositorio de datos turísticos sobre el modelo Supabase V2
/// (categories_v2, places_v2, place_media_v2, informational_content_v2).
///
/// Sin ninguna red activa (modo avión) o justo después de una falla de
/// conexión, responde de inmediato con la copia local descargada (HU-10,
/// RNF-04), sin esperar a Supabase ([NetworkStatus]). En los demás casos
/// consulta primero Supabase y, si falla o tarda más de 15 s (RNF-13), usa la
/// copia local.
/// Si tampoco hay copia local, lanza [CatalogUnavailableException]: la
/// pantalla muestra el error con «Reintentar», nunca datos de ejemplo.
class PlacesRepository {
  PlacesRepository({
    SupabaseClient? client,
    CatalogLocalDb? localDb,
    NetworkStatus? network,
    this._onDataSource,
  })  : _client = client ?? Supabase.instance.client,
        _localDb = localDb ?? CatalogLocalDb.instance,
        _network = network ?? NetworkStatus.instance;

  final SupabaseClient _client;
  final CatalogLocalDb _localDb;
  final NetworkStatus _network;
  final void Function(bool usingOfflineData)? _onDataSource;

  static const Duration _timeout = Duration(seconds: 15);

  static const String _placeSelect = '''
    *,
    place_media_v2 (*),
    categories_v2 (*)
  ''';

  /// Ejecuta la consulta remota y, si falla, la local.
  Future<T> _remoteOrLocal<T>({
    required Future<T> Function() remote,
    required Future<T> Function() local,
  }) async {
    // Atajo sin red: la copia local responde de inmediato.
    if (await _network.shouldSkipRemote() && await _localDb.hasData()) {
      final result = await local();
      _report(true);
      return result;
    }
    try {
      final result = await remote().timeout(_timeout);
      _network.markSuccess();
      _report(false);
      return result;
    } catch (error) {
      // Un error de programa o de formato de los datos (TypeError,
      // StateError, FormatException) no es falta de conexión: se propaga para
      // no mostrarlo como «sin conexión» (C-08).
      if (error is Error || error is FormatException) {
        debugPrint('ERROR catálogo (no es de conexión): $error');
        rethrow;
      }
      debugPrint('Catálogo remoto no disponible, se usa copia local: $error');
      _network.markFailure();
      if (!await _localDb.hasData()) {
        throw const CatalogUnavailableException();
      }
      final result = await local();
      _report(true);
      return result;
    }
  }

  void _report(bool usingOfflineData) {
    final callback = _onDataSource;
    if (callback == null) return;
    // Se difiere para no modificar otro provider mientras este se construye.
    Future.microtask(() => callback(usingOfflineData));
  }

  List<PlaceDto> _toPlaces(List<dynamic> rows) => rows
      .map((json) => PlaceDto.fromJson(Map<String, dynamic>.from(json as Map)))
      .toList();

  /// Categorías activas (categories_v2).
  Future<List<CategoryModel>> getCategories() {
    return _remoteOrLocal(
      remote: () async {
        final response = await _client
            .from('categories_v2')
            .select()
            .eq('is_active', true)
            .order('name_es');
        return response.map(CategoryModel.fromJson).toList();
      },
      local: () async {
        final rows = await _localDb.getCategories();
        return rows.map(CategoryModel.fromJson).toList();
      },
    );
  }

  /// Atractivos (places_v2 con kind = 'place').
  Future<List<PlaceDto>> getPlaces() => _getByKind('place');

  /// Actividades y tours (places_v2 con kind = 'activity').
  Future<List<PlaceDto>> getActivities() => _getByKind('activity');

  Future<List<PlaceDto>> _getByKind(String kind) {
    return _remoteOrLocal(
      remote: () async {
        final response = await _client
            .from('places_v2')
            .select(_placeSelect)
            .eq('kind', kind)
            .eq('is_active', true)
            .isFilter('retired_at', null)
            .order('name_es');
        return _toPlaces(response);
      },
      local: () async => _toPlaces(await _localDb.getPlaces(kind: kind)),
    );
  }

  /// Lugares por categoría: UUID de categories_v2, slug, group_type o nombre.
  Future<List<PlaceDto>> getPlacesByCategory(String categoryIdOrSlug) async {
    final trimmed = categoryIdOrSlug.trim();

    if (trimmed.isEmpty || trimmed == 'all' || trimmed == 'todos') {
      return getPlaces();
    }

    final isUuid = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(trimmed);

    if (isUuid) {
      return _remoteOrLocal(
        remote: () async {
          final response = await _client
              .from('places_v2')
              .select(_placeSelect)
              .eq('category_id', trimmed)
              .eq('is_active', true)
              .isFilter('retired_at', null)
              .order('name_es');
          return _toPlaces(response);
        },
        local: () async =>
            _toPlaces(await _localDb.getPlaces(categoryId: trimmed)),
      );
    }

    // Slug, group_type (gastronomia, alojamiento, etc.) o nombre de categoría.
    final allPlaces = await getPlaces();
    final term = trimmed.toLowerCase();
    final singularTerm = term.endsWith('s') && term.length > 4
        ? term.substring(0, term.length - 1)
        : term;

    return allPlaces.where((p) {
      final catId = p.categoryId.toLowerCase();
      final catSlug = p.categorySlug?.toLowerCase() ?? '';
      final groupType = p.category?.groupType?.toLowerCase() ?? '';
      final joinedSlug = p.category?.slug.toLowerCase() ?? '';
      final catName = p.category?.nameEs.toLowerCase() ?? '';

      return catId == term ||
          catSlug == term ||
          catSlug == singularTerm ||
          groupType == term ||
          groupType == singularTerm ||
          joinedSlug == term ||
          joinedSlug == singularTerm ||
          catName.contains(term) ||
          catName.contains(singularTerm);
    }).toList();
  }

  /// Detalle de un atractivo o actividad (HU-02). Devuelve null si no existe
  /// o no está activo.
  Future<PlaceDto?> getPlaceById(String id) {
    return _remoteOrLocal(
      remote: () async {
        final response = await _client
            .from('places_v2')
            .select(_placeSelect)
            .eq('id', id)
            .eq('is_active', true)
            .isFilter('retired_at', null)
            .maybeSingle();
        return response == null ? null : PlaceDto.fromJson(response);
      },
      local: () async {
        final row = await _localDb.getPlaceById(id);
        return row == null ? null : PlaceDto.fromJson(row);
      },
    );
  }

  /// Contenido informativo: guías, prevención, historia y restricciones
  /// (informational_content_v2). Base de la información preventiva (HU-25).
  Future<List<InformationalContentDto>> getInformationalContent({
    String? contentType,
  }) {
    final hasType = contentType != null && contentType.isNotEmpty;

    return _remoteOrLocal(
      remote: () async {
        var query = _client
            .from('informational_content_v2')
            .select()
            .eq('is_active', true);
        if (hasType) {
          query = query.eq('content_type', contentType);
        }
        final response = await query;
        return response.map(InformationalContentDto.fromJson).toList();
      },
      local: () async {
        final rows = await _localDb.getInformationalContent(
          contentType: hasType ? contentType : null,
        );
        return rows.map(InformationalContentDto.fromJson).toList();
      },
    );
  }
}
