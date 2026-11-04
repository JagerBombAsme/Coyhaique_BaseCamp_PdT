import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/transport/data/repository/transfer_repository.dart';
import 'catalog_local_db.dart';

/// Resultado de una descarga completa del catálogo.
class CatalogSyncResult {
  final int categories;
  final int places;
  final int informationalContent;
  final DateTime syncedAt;

  const CatalogSyncResult({
    required this.categories,
    required this.places,
    required this.informationalContent,
    required this.syncedAt,
  });
}

/// Descarga el catálogo activo desde Supabase y lo guarda en el teléfono
/// (subproceso «Descargar catálogo» del BPMN de uso sin conexión).
///
/// 1. Solicita categorías, lugares y actividades (con imágenes y categoría)
///    y contenido informativo activos. RLS entrega solo lo público.
/// 2. Si las tres consultas terminan bien, reemplaza la copia local en una
///    sola transacción.
/// 3. Si cualquiera falla, lanza la excepción y la copia anterior se conserva.
class CatalogSyncService {
  CatalogSyncService({
    SupabaseClient? client,
    CatalogLocalDb? localDb,
  })  : _client = client ?? Supabase.instance.client,
        _localDb = localDb ?? CatalogLocalDb.instance;

  final SupabaseClient _client;
  final CatalogLocalDb _localDb;

  /// Tiempo máximo de espera por consulta (RNF-13).
  static const Duration timeout = Duration(seconds: 15);

  Future<CatalogSyncResult> downloadCatalog() async {
    final categories = await _client
        .from('categories_v2')
        .select()
        .eq('is_active', true)
        .timeout(timeout);

    final places = await _client
        .from('places_v2')
        .select('''
          *,
          place_media_v2 (*),
          categories_v2 (*)
        ''')
        .eq('is_active', true)
        .isFilter('retired_at', null)
        .timeout(timeout);

    final informationalContent = await _client
        .from('informational_content_v2')
        .select()
        .eq('is_active', true)
        .timeout(timeout);

    final syncedAt = DateTime.now();

    final categoryRows = _rows(categories);
    final placeRows = _rows(places);
    final infoRows = _rows(informationalContent);

    await _localDb.replaceAll(
      categories: categoryRows,
      places: placeRows,
      informationalContent: infoRows,
      syncedAt: syncedAt,
    );

    // Fichas de transfer (HU-18): copia aparte para usarlas al bajar del
    // avión sin señal. Si falla, el catálogo ya quedó guardado igual.
    try {
      await TransferRepository(client: _client).refreshCache();
    } catch (_) {}

    return CatalogSyncResult(
      categories: categoryRows.length,
      places: placeRows.length,
      informationalContent: infoRows.length,
      syncedAt: syncedAt,
    );
  }

  List<Map<String, dynamic>> _rows(List<dynamic> response) {
    return response
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }
}
