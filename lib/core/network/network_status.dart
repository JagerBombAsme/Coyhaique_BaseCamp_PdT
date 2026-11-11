import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Estado de red de toda la app. Se actualiza con cada cambio de wifi o
/// datos móviles, y los repositorios lo consultan antes de llamar a Supabase.
///
/// Es una señal de atajo, no una garantía: wifi sin salida a internet (por
/// ejemplo, un portal cautivo) aparece como conectado. Por eso las consultas
/// conservan su tiempo de espera y su respaldo con la copia local.
class NetworkStatus {
  NetworkStatus._();

  static final NetworkStatus instance = NetworkStatus._();

  /// true si el sistema informa al menos una interfaz de red activa.
  /// Empieza en true hasta que se consulte el estado real.
  final ValueNotifier<bool> online = ValueNotifier<bool>(true);

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool get isOnline => online.value;

  /// Consulta el estado actual y escucha sus cambios. Se llama una sola vez
  /// al arrancar la app.
  Future<void> start() async {
    if (_subscription != null) return;
    final connectivity = Connectivity();
    _update(await connectivity.checkConnectivity());
    _subscription = connectivity.onConnectivityChanged.listen(_update);
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  void _update(List<ConnectivityResult> results) {
    online.value = results.any((r) => r != ConnectivityResult.none);
  }
}
