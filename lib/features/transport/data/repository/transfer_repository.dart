import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/transfer_service.dart';

/// Resultado de la consulta de transfers, con su origen.
class TransferListResult {
  const TransferListResult({
    required this.services,
    required this.fromCache,
    this.savedAt,
  });

  final List<TransferService> services;

  /// true cuando no hubo conexión y se usó la copia guardada en el teléfono.
  final bool fromCache;

  /// Momento en que se guardó la copia local.
  final DateTime? savedAt;
}

/// Sin conexión y sin copia guardada.
class TransfersUnavailableException implements Exception {
  const TransfersUnavailableException();
}

/// Fichas de transfer (`transport_services_v2`, HU-18).
///
/// Solo lectura: RLS entrega las fichas activas. Cada consulta exitosa se
/// guarda en el teléfono, para que la lista y el QR funcionen al bajar del
/// avión aunque no haya señal. No se envía ni se guarda ningún dato del
/// pasajero.
class TransferRepository {
  TransferRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const Duration timeout = Duration(seconds: 15);
  static const String _cacheKey = 'transfer_services_v2_cache';

  static const String _columns =
      'id, name, description_es, description_en, origin_es, origin_en, '
      'stand_location_es, stand_location_en, whatsapp_number, '
      'reference_fare_clp, fare_notes_es, fare_notes_en, capacity, '
      'accepts_cash, accepts_card, schedule_es, schedule_en, image_url, '
      'verification_level, qr_enabled, last_verified_date';

  /// Transfers del aeropuerto. Con conexión consulta Supabase y actualiza la
  /// copia local; sin conexión devuelve la copia guardada.
  Future<TransferListResult> getAirportTransfers() async {
    try {
      final rows = await _fetchRemote();
      await _saveCache(rows);
      return TransferListResult(
        services: rows.map(TransferService.fromJson).toList(),
        fromCache: false,
      );
    } catch (_) {
      final cached = await _readCache();
      if (cached == null) throw const TransfersUnavailableException();
      return cached;
    }
  }

  /// Actualiza solo la copia local. La usa la descarga del catálogo; si
  /// falla, no afecta al resto de la descarga.
  Future<void> refreshCache() async {
    final rows = await _fetchRemote();
    await _saveCache(rows);
  }

  Future<List<Map<String, dynamic>>> _fetchRemote() async {
    final response = await _client
        .from('transport_services_v2')
        .select(_columns)
        .eq('service_type', 'airport_transfer')
        .eq('is_active', true)
        .isFilter('retired_at', null)
        .order('sort_order')
        .order('name')
        .timeout(timeout);

    return response
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  Future<void> _saveCache(List<Map<String, dynamic>> rows) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _cacheKey,
      jsonEncode({
        'saved_at': DateTime.now().toIso8601String(),
        'rows': rows,
      }),
    );
  }

  Future<TransferListResult?> _readCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw == null) return null;

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final rows = (decoded['rows'] as List)
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList();
      return TransferListResult(
        services: rows.map(TransferService.fromJson).toList(),
        fromCache: true,
        savedAt: DateTime.tryParse(decoded['saved_at']?.toString() ?? ''),
      );
    } catch (_) {
      return null;
    }
  }
}
