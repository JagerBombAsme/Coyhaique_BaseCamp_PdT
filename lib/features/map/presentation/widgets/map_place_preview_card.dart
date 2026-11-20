import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/basecamp_tokens.dart';
import '../../../../core/widgets/basecamp/bc_widgets.dart';
import '../map_places.dart';

/// Medio de transporte para la ruta desde la tarjeta.
enum MapRouteMode { walking, driving }

/// Resumen de la ruta activa que se muestra dentro de la tarjeta.
class MapRouteSummary {
  const MapRouteSummary({
    required this.text,
    required this.mode,
    required this.onClear,
  });

  /// «Origen → Destino · distancia · tiempo».
  final String text;
  final MapRouteMode mode;
  final VoidCallback onClear;
}

/// Tarjeta flotante con la vista previa de un lugar sobre el mapa.
///
/// Un único componente para los dos caminos de selección: tocar un marcador y
/// elegir un resultado del buscador. Recibe el lugar ya elegido ([place]); con
/// `null` se oculta. La entrada y la salida se animan aquí mismo (deslizar y
/// aparecer), y sin animación si el sistema pide reducir el movimiento.
///
/// No calcula rutas ni navega: avisa con [onRoute] y [onOpenDetail], que
/// conecta la pantalla del mapa con el sistema de rutas y la navegación que ya
/// existen. No muestra estrellas ni valoraciones.
class MapPlacePreviewCard extends StatelessWidget {
  const MapPlacePreviewCard({
    super.key,
    required this.place,
    required this.isSpanish,
    required this.onClose,
    required this.onRoute,
    this.onOpenDetail,
    this.canRoute = true,
    this.online = true,
    this.routingMode,
    this.routeSummary,
  });

  /// Lugar elegido. Null = tarjeta oculta.
  final MapPlace? place;
  final bool isSpanish;
  final VoidCallback onClose;

  /// Pide una ruta a pie o en auto hacia [place].
  final void Function(MapRouteMode mode) onRoute;

  /// Abre la ficha. Solo se ofrece si el lugar tiene id (viene de places_v2).
  final void Function(MapPlace place)? onOpenDetail;

  /// false para los puntos de partida (plaza y centro): no tienen ruta.
  final bool canRoute;

  /// Sin conexión los botones de ruta se ven atenuados pero siguen tocables:
  /// la pantalla explica por qué no se puede calcular.
  final bool online;

  /// Medio cuya ruta se está calculando; muestra un indicador y bloquea los
  /// botones.
  final MapRouteMode? routingMode;

  /// Ruta activa, si hay una dibujada en el mapa.
  final MapRouteSummary? routeSummary;

  @override
  Widget build(BuildContext context) {
    final current = place;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return AnimatedSwitcher(
      duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 280),
      reverseDuration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 200),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.14),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: Alignment.bottomCenter,
          children: [...previousChildren, if (currentChild != null) currentChild],
        );
      },
      child: current == null
          ? const SizedBox.shrink(key: ValueKey<String>('sin-lugar'))
          : _PreviewBody(
              key: ValueKey<String>(current.id ?? current.nameEs),
              place: current,
              isSpanish: isSpanish,
              onClose: onClose,
              onRoute: onRoute,
              onOpenDetail: onOpenDetail,
              canRoute: canRoute,
              online: online,
              routingMode: routingMode,
              routeSummary: routeSummary,
            ),
    );
  }
}

class _PreviewBody extends StatelessWidget {
  const _PreviewBody({
    super.key,
    required this.place,
    required this.isSpanish,
    required this.onClose,
    required this.onRoute,
    required this.onOpenDetail,
    required this.canRoute,
    required this.online,
    required this.routingMode,
    required this.routeSummary,
  });

  final MapPlace place;
  final bool isSpanish;
  final VoidCallback onClose;
  final void Function(MapRouteMode mode) onRoute;
  final void Function(MapPlace place)? onOpenDetail;
  final bool canRoute;
  final bool online;
  final MapRouteMode? routingMode;
  final MapRouteSummary? routeSummary;

  /// Máximo de fotos en la galería (evita cargar decenas de imágenes).
  static const int _maxPhotos = 8;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    // Pantallas bajas: galería más chica para que la tarjeta no tape el
    // buscador.
    final galleryHeight = size.height < 700 ? 72.0 : 96.0;

    final category = place.categoryLabel(isSpanish: isSpanish);
    final location = place.locationLabel(isSpanish: isSpanish);
    final photos = place.photoUrls.take(_maxPhotos).toList();
    final openDetail = onOpenDetail;
    final showDetail = place.id != null && openDetail != null;
    final description = place.description(isSpanish: isSpanish);

    return Container(
      decoration: BoxDecoration(
        color: BcColors.surface,
        borderRadius: BorderRadius.circular(BcRadius.tile),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(BcRadius.tile),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: size.height * 0.52),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              BcSpace.s4,
              BcSpace.s3,
              BcSpace.s2,
              BcSpace.s4,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: BcSpace.s2),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (category.isNotEmpty) BcTag(category),
                            if (category.isNotEmpty)
                              const SizedBox(height: BcSpace.s2),
                            Semantics(
                              header: true,
                              child: Text(
                                place.name(isSpanish: isSpanish),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: BcText.title().copyWith(fontSize: 18),
                              ),
                            ),
                            const SizedBox(height: BcSpace.s1),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 1),
                                  child: Icon(
                                    Icons.place_outlined,
                                    size: 16,
                                    color: BcColors.glacierDeep,
                                  ),
                                ),
                                const SizedBox(width: BcSpace.s1),
                                Expanded(
                                  child: Text(
                                    location,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: BcText.caption(),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: isSpanish ? 'Cerrar' : 'Close',
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 44,
                      ),
                      onPressed: onClose,
                      icon: const Icon(Icons.close_rounded, color: BcColors.ink),
                    ),
                  ],
                ),
                if (photos.isNotEmpty) ...[
                  const SizedBox(height: BcSpace.s3),
                  Padding(
                    padding: const EdgeInsets.only(right: BcSpace.s2),
                    child: SizedBox(
                      height: galleryHeight,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: photos.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(width: BcSpace.s2),
                        itemBuilder: (context, index) => _GalleryPhoto(
                          url: photos[index],
                          height: galleryHeight,
                          label: isSpanish
                              ? '${place.name(isSpanish: true)}, foto ${index + 1}'
                              : '${place.name(isSpanish: false)}, photo ${index + 1}',
                        ),
                      ),
                    ),
                  ),
                ] else if (place.id == null && description.isNotEmpty) ...[
                  // Los puntos fijos no tienen ficha ni fotos: la descripción
                  // es toda su información.
                  const SizedBox(height: BcSpace.s2),
                  Padding(
                    padding: const EdgeInsets.only(right: BcSpace.s2),
                    child: Text(
                      description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: BcText.caption(color: BcColors.ink),
                    ),
                  ),
                ],
                if (!place.verified) ...[
                  const SizedBox(height: BcSpace.s2),
                  Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 14,
                        color: BcColors.muted,
                      ),
                      const SizedBox(width: BcSpace.s1),
                      Text(
                        isSpanish
                            ? 'Ubicación aproximada'
                            : 'Approximate location',
                        style: BcText.caption(),
                      ),
                    ],
                  ),
                ],
                if (routeSummary != null) ...[
                  const SizedBox(height: BcSpace.s3),
                  _RouteSummaryRow(summary: routeSummary!, isSpanish: isSpanish),
                ],
                if (showDetail || canRoute) ...[
                  const SizedBox(height: BcSpace.s3),
                  Padding(
                    padding: const EdgeInsets.only(right: BcSpace.s2),
                    child: Column(
                      children: [
                        if (showDetail)
                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: FilledButton.icon(
                              onPressed: () => openDetail?.call(place),
                              icon: const Icon(
                                Icons.arrow_forward_rounded,
                                size: 20,
                              ),
                              label: Text(isSpanish ? 'Ver ficha' : 'View details'),
                              style: FilledButton.styleFrom(
                                backgroundColor: BcColors.glacier,
                                foregroundColor: BcColors.ink,
                                elevation: 0,
                                textStyle: BcText.button(),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    BcRadius.control,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if (showDetail && canRoute)
                          const SizedBox(height: BcSpace.s2),
                        if (canRoute)
                          Opacity(
                            opacity: online ? 1 : 0.45,
                            child: Row(
                              children: [
                                Expanded(
                                  child: _RouteButton(
                                    mode: MapRouteMode.walking,
                                    label: isSpanish ? 'A pie' : 'On foot',
                                    icon: Icons.directions_walk_rounded,
                                    routingMode: routingMode,
                                    onRoute: onRoute,
                                  ),
                                ),
                                const SizedBox(width: BcSpace.s2),
                                Expanded(
                                  child: _RouteButton(
                                    mode: MapRouteMode.driving,
                                    label: isSpanish ? 'En auto' : 'By car',
                                    icon: Icons.directions_car_rounded,
                                    routingMode: routingMode,
                                    onRoute: onRoute,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GalleryPhoto extends StatelessWidget {
  const _GalleryPhoto({
    required this.url,
    required this.height,
    required this.label,
  });

  final String url;
  final double height;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: label,
      child: ExcludeSemantics(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(BcRadius.control),
          child: SizedBox(
            width: height * 1.35,
            height: height,
            child: CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              memCacheWidth: 400,
              placeholder: (_, _) => const BcLogoPlaceholder(),
              errorWidget: (_, _, _) => const BcLogoPlaceholder(),
            ),
          ),
        ),
      ),
    );
  }
}

class _RouteButton extends StatelessWidget {
  const _RouteButton({
    required this.mode,
    required this.label,
    required this.icon,
    required this.routingMode,
    required this.onRoute,
  });

  final MapRouteMode mode;
  final String label;
  final IconData icon;
  final MapRouteMode? routingMode;
  final void Function(MapRouteMode mode) onRoute;

  @override
  Widget build(BuildContext context) {
    final busy = routingMode != null;
    final loading = routingMode == mode;

    return SizedBox(
      height: 46,
      child: OutlinedButton.icon(
        onPressed: busy ? null : () => onRoute(mode),
        icon: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: BcColors.ink,
                ),
              )
            : Icon(icon, size: 20),
        label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        style: OutlinedButton.styleFrom(
          foregroundColor: BcColors.ink,
          side: const BorderSide(color: BcColors.line, width: 1.5),
          textStyle: BcText.button(),
          padding: const EdgeInsets.symmetric(horizontal: BcSpace.s2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BcRadius.control),
          ),
        ),
      ),
    );
  }
}

class _RouteSummaryRow extends StatelessWidget {
  const _RouteSummaryRow({required this.summary, required this.isSpanish});

  final MapRouteSummary summary;
  final bool isSpanish;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          summary.mode == MapRouteMode.walking
              ? Icons.directions_walk_rounded
              : Icons.directions_car_rounded,
          size: 18,
          color: BcColors.glacierDeep,
        ),
        const SizedBox(width: BcSpace.s2),
        Expanded(
          child: Text(
            summary.text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: BcText.caption(color: BcColors.ink),
          ),
        ),
        TextButton(
          onPressed: summary.onClear,
          style: TextButton.styleFrom(
            foregroundColor: BcColors.glacierDeep,
            minimumSize: const Size(44, 44),
          ),
          child: Text(isSpanish ? 'Quitar ruta' : 'Remove route'),
        ),
      ],
    );
  }
}
