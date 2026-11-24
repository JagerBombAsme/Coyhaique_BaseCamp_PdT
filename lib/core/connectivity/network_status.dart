import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Decide si una consulta debe ir directo a la copia local, sin esperar a
/// Supabase.
///
/// Sin este atajo, en modo avión cada consulta esperaba a que fallara la
/// conexión (hasta 15 s, RNF-13) antes de leer la copia local, y una pantalla
/// con varias consultas sumaba esas esperas.
///
/// Se salta la consulta remota en dos casos:
/// - el teléfono no tiene ninguna red activa (modo avión, sin Wi-Fi ni datos);
/// - una consulta remota falló por conexión hace menos de [_cooldown]
///   (señal débil o red sin salida a Internet), para no repetir la espera
///   en cada pantalla.
///
/// Cuando vuelve una red, el atajo se reinicia y la siguiente consulta vuelve
/// a intentar Supabase.
class NetworkStatus {
  NetworkStatus._() {
    _subscription = Connectivity().onConnectivityChanged.listen(
      (results) {
        if (_hasNetwork(results)) _failedAt = null;
      },
      // Sin el plugin (pruebas) o con un error del sistema, solo se pierde el
      // reinicio anticipado del atajo; el tiempo de espera sigue aplicando.
      onError: (Object error) =>
          debugPrint('Sin aviso de cambios de red: $error'),
    );
  }

  /// Instancia única de la app. Su suscripción dura lo que dura la app.
  static final NetworkStatus instance = NetworkStatus._();

  static const Duration _cooldown = Duration(seconds: 30);

  // ignore: unused_field
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  DateTime? _failedAt;

  static bool _hasNetwork(List<ConnectivityResult> results) =>
      results.isEmpty || results.any((r) => r != ConnectivityResult.none);

  /// Indica si se debe saltar la consulta remota y usar la copia local.
  Future<bool> shouldSkipRemote() async {
    final failedAt = _failedAt;
    if (failedAt != null && DateTime.now().difference(failedAt) < _cooldown) {
      return true;
    }
    try {
      final results = await Connectivity().checkConnectivity();
      return !_hasNetwork(results);
    } catch (error) {
      // Si no se puede consultar el estado de red, se intenta Supabase.
      debugPrint('No se pudo consultar el estado de red: $error');
      return false;
    }
  }

  /// Registra que una consulta remota falló por conexión.
  void markFailure() => _failedAt = DateTime.now();

  /// Registra que una consulta remota respondió.
  void markSuccess() => _failedAt = null;
}
