import 'package:flutter/material.dart';

import '../../../../core/theme/basecamp_tokens.dart';
import '../../../../core/widgets/basecamp/bc_widgets.dart';
import 'map_place_preview_card.dart';
import 'route_maneuver.dart';

IconData _modeIcon(MapRouteMode mode) => mode == MapRouteMode.walking
    ? Icons.directions_walk_rounded
    : Icons.directions_car_rounded;

const List<BoxShadow> _floatingShadow = [
  BoxShadow(color: Color(0x33000000), blurRadius: 18, offset: Offset(0, 6)),
];

/// Barra superior del modo ruta: reemplaza al buscador mientras hay una ruta
/// activa. Muestra la próxima maniobra (si la hay), el medio y el destino.
/// Terminar la ruta se hace desde el panel inferior, donde llega el pulgar.
class MapRouteHeader extends StatelessWidget {
  const MapRouteHeader({
    super.key,
    required this.destination,
    required this.mode,
    required this.isSpanish,
    this.origin,
    this.maneuver,
  });

  final String destination;
  final MapRouteMode mode;
  final bool isSpanish;

  /// Solo para rutas que no parten de la ubicación del usuario (por ejemplo
  /// aeropuerto → plaza): dice desde dónde se calculó.
  final String? origin;

  /// Próximo giro o maniobra. Null = no se muestra (sin seguimiento, fuera de
  /// la ruta o ya llegó).
  final MapManeuver? maneuver;

  @override
  Widget build(BuildContext context) {
    final walking = mode == MapRouteMode.walking;
    final modeLabel = isSpanish
        ? (walking ? 'A pie' : 'En auto')
        : (walking ? 'On foot' : 'By car');
    final kicker = origin == null
        ? (isSpanish ? '$modeLabel hacia' : '$modeLabel to')
        : (isSpanish
              ? 'Desde $origin · $modeLabel'
              : 'From $origin · $modeLabel');
    final next = maneuver;

    return Container(
      padding: const EdgeInsets.all(BcSpace.s4),
      decoration: BoxDecoration(
        color: BcColors.ink,
        borderRadius: BorderRadius.circular(BcRadius.tile),
        boxShadow: _floatingShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (next != null) ...[
            _ManeuverRow(maneuver: next),
            const SizedBox(height: BcSpace.s3),
            Divider(
              height: 1,
              thickness: 1,
              color: BcColors.onPhoto.withValues(alpha: 0.18),
            ),
            const SizedBox(height: BcSpace.s3),
          ],
          Semantics(
            header: true,
            child: Row(
              children: [
                Icon(
                  _modeIcon(mode),
                  color: BcColors.glacier,
                  size: next == null ? 26 : 20,
                ),
                const SizedBox(width: BcSpace.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        kicker.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: BcText.label(color: BcColors.glacier),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        destination,
                        maxLines: next == null ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: BcText.title(color: BcColors.onPhoto),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Próxima maniobra: flecha grande, distancia, qué hacer y a qué calle.
class _ManeuverRow extends StatelessWidget {
  const _ManeuverRow({required this.maneuver});

  final MapManeuver maneuver;

  @override
  Widget build(BuildContext context) {
    final street = maneuver.street;
    return Semantics(
      label: '${maneuver.distanceLabel}, ${maneuver.text}'
          '${street == null ? '' : ', $street'}',
      child: ExcludeSemantics(
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: BcColors.glacier,
                shape: BoxShape.circle,
              ),
              child: Icon(maneuver.icon, color: BcColors.ink, size: 36),
            ),
            const SizedBox(width: BcSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    maneuver.distanceLabel.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: BcText.display(28, color: BcColors.onPhoto),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    maneuver.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: BcText.title(color: BcColors.onPhoto),
                  ),
                  if (street != null)
                    Text(
                      street,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: BcText.caption(
                        color: BcColors.onPhoto.withValues(alpha: 0.7),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Panel inferior del modo ruta. Tres estados, siempre con icono y texto
/// (nunca solo color): en camino, fuera de la ruta y llegada.
class MapRoutePanel extends StatelessWidget {
  const MapRoutePanel({
    super.key,
    required this.destination,
    required this.mode,
    required this.isSpanish,
    required this.durationLabel,
    required this.distanceLabel,
    required this.tracking,
    required this.offRoute,
    required this.arrived,
    required this.recalculating,
    required this.onEnd,
    this.onRecalculate,
    this.onOpenDetail,
  });

  final String destination;
  final MapRouteMode mode;
  final bool isSpanish;

  /// Tiempo y distancia: lo que falta si [tracking], el total si no.
  final String durationLabel;
  final String distanceLabel;

  /// La ruta sigue al usuario (parte de su ubicación). Las rutas de
  /// referencia, como aeropuerto → plaza, solo muestran el total.
  final bool tracking;

  final bool offRoute;
  final bool arrived;
  final bool recalculating;

  final VoidCallback onEnd;

  /// null = no se puede recalcular.
  final VoidCallback? onRecalculate;

  /// null = el destino no tiene ficha.
  final VoidCallback? onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final title = arrived
        ? (isSpanish ? 'Llegaste' : 'You have arrived')
        : durationLabel;
    final subtitle = arrived
        ? destination
        : tracking
        ? (isSpanish ? '$distanceLabel restantes' : '$distanceLabel left')
        : (isSpanish ? '$distanceLabel en total' : '$distanceLabel total');

    return Container(
      padding: const EdgeInsets.all(BcSpace.s4),
      decoration: BoxDecoration(
        color: BcColors.surface,
        borderRadius: BorderRadius.circular(BcRadius.tile),
        boxShadow: _floatingShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            label: '$title, $subtitle',
            child: ExcludeSemantics(
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: BcColors.glacier,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      arrived ? Icons.check_rounded : _modeIcon(mode),
                      color: BcColors.ink,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: BcSpace.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: BcText.display(arrived ? 24 : 32),
                        ),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: BcText.caption(color: BcColors.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (offRoute && !arrived) ...[
            const SizedBox(height: BcSpace.s3),
            _OffRouteBanner(
              isSpanish: isSpanish,
              recalculating: recalculating,
              onRecalculate: onRecalculate,
            ),
          ],
          const SizedBox(height: BcSpace.s4),
          Row(
            children: [
              if (onOpenDetail != null) ...[
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: onOpenDetail,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: BcColors.ink,
                        side: const BorderSide(
                          color: BcColors.line,
                          width: 1.5,
                        ),
                        textStyle: BcText.button(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: BcSpace.s2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(BcRadius.control),
                        ),
                      ),
                      child: Text(
                        isSpanish ? 'Ver ficha' : 'Details',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: BcSpace.s2),
              ],
              Expanded(
                child: BcButton(
                  // Sin icono: el ancho se deja al texto para que no se corte.
                  label: isSpanish ? 'Terminar' : 'End route',
                  style: BcButtonStyle.ink,
                  height: 48,
                  onPressed: onEnd,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Aviso de que el usuario salió de la ruta, con la acción para corregirlo.
class _OffRouteBanner extends StatelessWidget {
  const _OffRouteBanner({
    required this.isSpanish,
    required this.recalculating,
    required this.onRecalculate,
  });

  final bool isSpanish;
  final bool recalculating;
  final VoidCallback? onRecalculate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(BcSpace.s3),
      decoration: BoxDecoration(
        color: BcColors.danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(BcRadius.control),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Se anuncia a los lectores de pantalla solo cuando aparece.
          Semantics(
            liveRegion: true,
            child: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 22,
                  color: BcColors.danger,
                ),
                const SizedBox(width: BcSpace.s2),
                Expanded(
                  child: Text(
                    isSpanish ? 'Te alejaste de la ruta' : 'You left the route',
                    style: BcText.title(color: BcColors.ink),
                  ),
                ),
              ],
            ),
          ),
          if (onRecalculate != null) ...[
            const SizedBox(height: BcSpace.s3),
            BcButton(
              label: isSpanish ? 'Recalcular ruta' : 'Recalculate route',
              icon: Icons.refresh_rounded,
              height: 46,
              isLoading: recalculating,
              onPressed: onRecalculate,
            ),
          ],
        ],
      ),
    );
  }
}
