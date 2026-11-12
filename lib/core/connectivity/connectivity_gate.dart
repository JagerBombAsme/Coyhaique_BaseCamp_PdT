import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/router/app_router.dart';
import '../local/catalog_status_provider.dart';
import '../providers/language_provider.dart';
import '../theme/app_theme.dart';

/// Estado de conexión que ve el usuario al entrar a cualquier pantalla.
enum _NetState { checking, online, offlineWithData, offlineNoData }

/// Revisa la conexión al iniciar la app, al cambiar de red y cada vez que se
/// navega a otra pantalla.
///
/// - Con conexión: no muestra nada.
/// - Sin conexión y con datos descargados: banda superior y la app sigue
///   funcionando con la copia local (HU-09, HU-10).
/// - Sin conexión y sin datos descargados: cubre la pantalla con un aviso para
///   activar la conexión y reintentar.
///
/// Limitación: connectivity_plus informa si hay red activa, no si Internet
/// responde. Si hay red sin salida a Internet, las consultas fallan y cada
/// pantalla lo muestra como hasta ahora.
class ConnectivityGate extends ConsumerStatefulWidget {
  const ConnectivityGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<ConnectivityGate> createState() => _ConnectivityGateState();
}

class _ConnectivityGateState extends ConsumerState<ConnectivityGate> {
  _NetState _state = _NetState.checking;
  DateTime? _lastSync;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = Connectivity().onConnectivityChanged.listen(
      (_) => _refresh(),
    );
    // Cada navegación revisa la conexión: así el aviso aparece al ingresar
    // a cualquier pantalla.
    appRouter.routeInformationProvider.addListener(_refresh);
    _refresh();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    appRouter.routeInformationProvider.removeListener(_refresh);
    super.dispose();
  }

  Future<void> _refresh() async {
    final results = await Connectivity().checkConnectivity();
    final online = results.any((r) => r != ConnectivityResult.none);

    DateTime? lastSync;
    if (!online) {
      lastSync = await ref.read(catalogLocalDbProvider).getLastSyncAt();
    }
    if (!mounted) return;

    setState(() {
      _lastSync = lastSync;
      _state = online
          ? _NetState.online
          : (lastSync == null
              ? _NetState.offlineNoData
              : _NetState.offlineWithData);
    });
  }

  @override
  Widget build(BuildContext context) {
    final es = ref.watch(languageProvider).languageCode == 'es';

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (_state == _NetState.offlineWithData)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _OfflineBanner(isSpanish: es, lastSync: _lastSync),
          ),
        if (_state == _NetState.offlineNoData)
          Positioned.fill(
            child: _NoConnectionCard(isSpanish: es, onRetry: _refresh),
          ),
      ],
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({required this.isSpanish, required this.lastSync});

  final bool isSpanish;
  final DateTime? lastSync;

  @override
  Widget build(BuildContext context) {
    final date = lastSync == null ? '' : _formatDate(lastSync!);
    final text = isSpanish
        ? 'Sin conexión. Usas los datos descargados el $date.'
        : 'No connection. You are using the data downloaded on $date.';

    return Material(
      color: AppTheme.primaryDark,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.cloud_off_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoConnectionCard extends StatelessWidget {
  const _NoConnectionCard({required this.isSpanish, required this.onRetry});

  final bool isSpanish;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFE8EBED),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.wifi_off_rounded,
                  size: 56,
                  color: AppTheme.primaryDark,
                ),
                const SizedBox(height: 16),
                Text(
                  isSpanish ? 'Sin conexión' : 'No connection',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryDark,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  isSpanish
                      ? 'Activa tu conexión a internet (Wi-Fi o datos móviles).\n\nSi aún no has descargado los datos de la aplicación, necesitas conexión para hacerlo la primera vez.'
                      : 'Turn on your internet connection (Wi-Fi or mobile data).\n\nIf you have not downloaded the app data yet, you need a connection to do it the first time.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, height: 1.4),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: onRetry,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryDark,
                  ),
                  child: Text(isSpanish ? 'Reintentar' : 'Try again'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _formatDate(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}-${two(d.month)}-${d.year} ${two(d.hour)}:${two(d.minute)}';
}
