import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/local/catalog_status_provider.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../categories/data/providers/places_provider.dart' as places;
import '../../../routes/data/providers/activity_provider.dart' as routes;
import 'home_visual_tokens.dart';

/// Estado de la información descargada y botón «Descargar ahora»
/// (HU-09, HU-10; BPMN de descarga y uso sin conexión).
///
/// - Sin conexión: avisa que se muestra la copia local y su fecha.
/// - Con conexión: muestra la fecha de la última descarga.
/// - El botón vuelve a descargar todo; si falla, se conserva la copia
///   anterior y se informa el error.
class CatalogStatusCard extends ConsumerWidget {
  const CatalogStatusCard({super.key});

  static const Color _ink = HomeVisualTokens.deepIce;
  // Ámbar oscuro: único tono fuera de la paleta, reservado para advertir
  // que la información puede estar desactualizada.
  static const Color _warning = Color(0xFF8A5A00);
  static const Color _warningSurface = Color(0xFFFFF8E8);

  static const double _padding = 12;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(catalogStatusProvider);
    final isSpanish = ref.watch(languageProvider).languageCode == 'es';
    final dateText = status.lastSyncAt == null
        ? null
        : DateFormat('dd-MM-yyyy HH:mm').format(status.lastSyncAt!);

    final String message;
    if (status.isSyncing) {
      message = isSpanish
          ? 'Descargando información para usarla sin conexión…'
          : 'Downloading information for offline use…';
    } else if (status.usingOfflineData) {
      message = isSpanish
          ? 'Sin conexión: estás viendo la información descargada el '
              '$dateText. Puede no estar actualizada.'
          : 'Offline: you are viewing information downloaded on '
              '$dateText. It may be out of date.';
    } else if (dateText != null) {
      message = isSpanish
          ? 'Información disponible sin conexión, descargada el $dateText.'
          : 'Information available offline, downloaded on $dateText.';
    } else {
      message = isSpanish
          ? 'Aún no hay información descargada para usar sin conexión.'
          : 'No information has been downloaded for offline use yet.';
    }

    final offline = status.usingOfflineData;
    final color = offline ? _warning : _ink;

    return AnimatedContainer(
      duration: HomeVisualTokens.stateDuration,
      curve: Curves.easeOut,
      // Sin margen superior: la sección de tours ya se solapa 18 px
      // sobre el hero y deja ese espacio visible por debajo.
      margin: const EdgeInsets.fromLTRB(
        HomeVisualTokens.sectionMargin,
        0,
        HomeVisualTokens.sectionMargin,
        0,
      ),
      padding: const EdgeInsets.fromLTRB(_padding, _padding, 8, _padding),
      decoration: BoxDecoration(
        color: offline ? _warningSurface : HomeVisualTokens.surface,
        borderRadius: BorderRadius.circular(HomeVisualTokens.cardRadius),
        boxShadow: HomeVisualTokens.softShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: offline
                  ? _warning.withValues(alpha: 0.12)
                  : HomeVisualTokens.iceBlue,
              // Concéntrico con la tarjeta: 24 − 12 = 12.
              borderRadius: BorderRadius.circular(
                HomeVisualTokens.innerRadius(
                  HomeVisualTokens.cardRadius,
                  _padding,
                ),
              ),
            ),
            child: Icon(
              offline ? Icons.cloud_off_rounded : Icons.download_done_rounded,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: color,
                height: 1.3,
                // La fecha cambia tras cada descarga: sin saltos de ancho.
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            height: 44,
            child: AnimatedSwitcher(
              duration: HomeVisualTokens.stateDuration,
              child: status.isSyncing
                  ? const Padding(
                      key: ValueKey('syncing'),
                      padding: EdgeInsets.symmetric(horizontal: 18),
                      child: Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: HomeVisualTokens.accentStrong,
                          ),
                        ),
                      ),
                    )
                  : TextButton(
                      key: const ValueKey('download'),
                      onPressed: () => _download(context, ref, isSpanish),
                      style: TextButton.styleFrom(
                        foregroundColor: HomeVisualTokens.deepIce,
                        backgroundColor: HomeVisualTokens.iceBlue,
                        minimumSize: const Size(44, 44),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        shape: const StadiumBorder(),
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: Text(isSpanish ? 'Descargar' : 'Download'),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _download(
    BuildContext context,
    WidgetRef ref,
    bool isSpanish,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await ref.read(catalogStatusProvider.notifier).download();

    if (ok) {
      ref.invalidate(places.categoriesProvider);
      ref.invalidate(places.placesProvider);
      ref.invalidate(places.activitiesProvider);
      ref.invalidate(routes.activitiesProvider);
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? (isSpanish
                  ? 'Descarga completa. La información está disponible sin conexión.'
                  : 'Download complete. Information is available offline.')
              : (isSpanish
                  ? 'No se pudo descargar. Se conserva la información anterior.'
                  : 'Download failed. The previous information was kept.'),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: HomeVisualTokens.deepIce,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HomeVisualTokens.controlRadius),
        ),
      ),
    );
  }
}
