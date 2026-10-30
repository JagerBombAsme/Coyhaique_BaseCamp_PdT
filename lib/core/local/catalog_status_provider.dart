import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'catalog_local_db.dart';
import 'catalog_sync_service.dart';

/// Estado de la copia local del catálogo que ve el usuario.
class CatalogStatus {
  /// Fecha de la última descarga completa (null si nunca se descargó).
  final DateTime? lastSyncAt;

  /// true cuando la última consulta se respondió con la copia local
  /// porque no hubo conexión con Supabase.
  final bool usingOfflineData;

  /// true mientras se descarga el catálogo.
  final bool isSyncing;

  /// true si la última descarga falló (la copia anterior se conserva).
  final bool lastDownloadFailed;

  const CatalogStatus({
    this.lastSyncAt,
    this.usingOfflineData = false,
    this.isSyncing = false,
    this.lastDownloadFailed = false,
  });

  CatalogStatus copyWith({
    DateTime? lastSyncAt,
    bool? usingOfflineData,
    bool? isSyncing,
    bool? lastDownloadFailed,
  }) {
    return CatalogStatus(
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      usingOfflineData: usingOfflineData ?? this.usingOfflineData,
      isSyncing: isSyncing ?? this.isSyncing,
      lastDownloadFailed: lastDownloadFailed ?? this.lastDownloadFailed,
    );
  }
}

class CatalogStatusNotifier extends StateNotifier<CatalogStatus> {
  CatalogStatusNotifier(this._syncService, this._localDb)
      : super(const CatalogStatus()) {
    _loadLastSync();
  }

  final CatalogSyncService _syncService;
  final CatalogLocalDb _localDb;

  Future<void> _loadLastSync() async {
    final lastSync = await _localDb.getLastSyncAt();
    if (!mounted) return;
    state = state.copyWith(lastSyncAt: lastSync);
  }

  /// Descarga el catálogo completo. Se usa al abrir la aplicación con
  /// conexión y desde el botón «Descargar ahora». Devuelve true si terminó
  /// bien. Si falla, la copia anterior se conserva.
  Future<bool> download() async {
    if (state.isSyncing) return false;

    state = state.copyWith(isSyncing: true, lastDownloadFailed: false);

    try {
      final result = await _syncService.downloadCatalog();
      if (!mounted) return true;
      state = state.copyWith(
        isSyncing: false,
        lastSyncAt: result.syncedAt,
        usingOfflineData: false,
      );
      return true;
    } catch (_) {
      if (!mounted) return false;
      state = state.copyWith(isSyncing: false, lastDownloadFailed: true);
      return false;
    }
  }

  /// Lo informan los repositorios según el origen de los datos mostrados.
  void setUsingOfflineData(bool value) {
    if (!mounted || state.usingOfflineData == value) return;
    state = state.copyWith(usingOfflineData: value);
  }
}

final catalogLocalDbProvider = Provider<CatalogLocalDb>((ref) {
  return CatalogLocalDb.instance;
});

final catalogSyncServiceProvider = Provider<CatalogSyncService>((ref) {
  return CatalogSyncService(localDb: ref.read(catalogLocalDbProvider));
});

final catalogStatusProvider =
    StateNotifierProvider<CatalogStatusNotifier, CatalogStatus>((ref) {
  return CatalogStatusNotifier(
    ref.read(catalogSyncServiceProvider),
    ref.read(catalogLocalDbProvider),
  );
});
