import 'package:flutter/material.dart';

import '../../../../core/theme/basecamp_tokens.dart';
import '../../../../core/widgets/basecamp/bc_widgets.dart';
import '../../domain/itinerary_planner.dart';
import 'itinerary_views.dart';

// =================================================================
// CAPACIDAD DE TIEMPO
// =================================================================

/// Horario del día y cuánto del tiempo disponible ocupa. Al pasarse cambia
/// a rojo y además lo dice en texto, con un ícono de advertencia.
class TimeCapacityBar extends StatelessWidget {
  const TimeCapacityBar({
    super.key,
    required this.schedule,
    required this.availableMinutes,
    required this.isSpanish,
  });

  final ItinerarySchedule schedule;
  final int availableMinutes;
  final bool isSpanish;

  @override
  Widget build(BuildContext context) {
    final es = isSpanish;
    final isEmpty = schedule.stops.isEmpty;
    final used = isEmpty ? 0 : schedule.totalMinutes;
    final exceeded = used > availableMinutes;
    final remaining = availableMinutes - used;
    final ratio = availableMinutes <= 0
        ? 0.0
        : (used / availableMinutes).clamp(0.0, 1.0);
    final start = ItineraryPlanner.formatClock(schedule.startMinute);
    final limit = ItineraryPlanner.formatClock(
      schedule.startMinute + availableMinutes,
    );
    final usedText = ItineraryPlanner.formatDuration(used);
    final availableText = ItineraryPlanner.formatDuration(availableMinutes);

    final String status;
    if (isEmpty) {
      status = es
          ? 'Tienes $availableText disponibles, de $start a $limit.'
          : 'You have $availableText available, from $start to $limit.';
    } else if (exceeded) {
      final over = ItineraryPlanner.formatDuration(-remaining);
      status = es
          ? 'Te pasas por $over de tu tiempo. Quita un lugar o cambia el orden.'
          : 'You go $over over your time. Remove a place or change the order.';
    } else {
      final left = ItineraryPlanner.formatDuration(remaining);
      status = es
          ? 'Usas $usedText de $availableText · te quedan $left'
          : 'You use $usedText of $availableText · $left left';
    }

    return Container(
      padding: const EdgeInsets.all(BcSpace.s4),
      decoration: BoxDecoration(
        color: BcColors.surface,
        borderRadius: BorderRadius.circular(BcRadius.tile),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            label: es ? 'Tiempo usado' : 'Time used',
            value: '${(used / (availableMinutes == 0 ? 1 : availableMinutes) * 100).round()} %',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(BcRadius.pill),
              child: SizedBox(
                height: 10,
                child: Stack(
                  children: [
                    const Positioned.fill(child: ColoredBox(color: BcColors.fog)),
                    Positioned.fill(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(end: ratio),
                        duration: itineraryMotion(context, 300),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) => FractionallySizedBox(
                          alignment: AlignmentDirectional.centerStart,
                          widthFactor: value,
                          child: ColoredBox(
                            color: exceeded ? BcColors.danger : BcColors.glacier,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                exceeded ? Icons.warning_amber_rounded : Icons.timelapse_rounded,
                size: 18,
                color: exceeded ? BcColors.danger : BcColors.glacierDeep,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  status,
                  style: BcText.caption(
                    color: exceeded ? BcColors.danger : BcColors.ink,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =================================================================
// LÍNEA DE TIEMPO
// =================================================================

/// Recorrido del día como línea de tiempo: salida, cada parada con su
/// traslado estimado, regreso y el tiempo libre que queda. Las paradas se
/// reordenan arrastrando el asa; las horas se recalculan al soltar.
class ItineraryTimeline extends StatelessWidget {
  const ItineraryTimeline({
    super.key,
    required this.schedule,
    required this.availableMinutes,
    required this.originLabel,
    required this.isSpanish,
    required this.iconFor,
    required this.onReorder,
    required this.onRemove,
  });

  final ItinerarySchedule schedule;
  final int availableMinutes;
  final String originLabel;
  final bool isSpanish;
  final PlaceIconResolver iconFor;
  final ReorderCallback onReorder;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    final es = isSpanish;
    final stops = schedule.stops;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TimelineRow(
          time: ItineraryPlanner.formatClock(schedule.startMinute),
          node: const _Node.icon(Icons.flag_rounded),
          drawTop: false,
          child: _Endpoint(
            title: es ? 'Salida' : 'Start',
            subtitle: originLabel,
          ),
        ),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          itemCount: stops.length,
          onReorder: onReorder,
          proxyDecorator: (child, index, animation) => Material(
            type: MaterialType.transparency,
            child: ScaleTransition(
              scale: Tween<double>(begin: 1, end: 1.02).animate(animation),
              child: child,
            ),
          ),
          itemBuilder: (context, index) {
            final stop = stops[index];
            return _TimelineStop(
              key: ValueKey(stop.place.id),
              stop: stop,
              index: index,
              isSpanish: es,
              icon: iconFor(stop.place),
              onRemove: () => onRemove(index),
              onMoveUp: index > 0 ? () => onReorder(index, index - 1) : null,
              onMoveDown: index < stops.length - 1 ? () => onReorder(index, index + 2) : null,
            );
          },
        ),
        if (schedule.returnTravelMinutes > 0)
          _TravelConnector(
            minutes: schedule.returnTravelMinutes,
            isSpanish: es,
          ),
        _TimelineRow(
          time: ItineraryPlanner.formatClock(schedule.endMinute),
          node: const _Node.icon(Icons.home_rounded),
          drawBottom: false,
          child: _Endpoint(
            title: es ? 'Regreso estimado' : 'Estimated return',
            subtitle: es ? 'A $originLabel' : 'To $originLabel',
          ),
        ),
      ],
    );
  }
}

/// Una parada con el traslado que la precede.
class _TimelineStop extends StatelessWidget {
  const _TimelineStop({
    super.key,
    required this.stop,
    required this.index,
    required this.isSpanish,
    required this.icon,
    required this.onRemove,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  final ScheduledStop stop;
  final int index;
  final bool isSpanish;
  final IconData icon;
  final VoidCallback onRemove;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (stop.travelMinutes > 0)
          _TravelConnector(minutes: stop.travelMinutes, isSpanish: isSpanish),
        _TimelineRow(
          time: ItineraryPlanner.formatClock(stop.arrivalMinute),
          timeEnd: ItineraryPlanner.formatClock(stop.departureMinute),
          node: _Node.number(index + 1),
          child: _StopCard(
            stop: stop,
            index: index,
            isSpanish: isSpanish,
            icon: icon,
            onRemove: onRemove,
            onMoveUp: onMoveUp,
            onMoveDown: onMoveDown,
          ),
        ),
      ],
    );
  }
}

/// Ancho de la columna de horas: cabe «00:00» en negrita con la letra del
/// sistema hasta 1,3×.
double _timeColumnWidth(BuildContext context) =>
    (MediaQuery.textScalerOf(context).scale(15) * 3.2 + 10).clamp(60.0, 125.0).toDouble();

/// Fila de la línea de tiempo: hora, riel con su nodo y contenido.
class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.time,
    required this.node,
    required this.child,
    this.timeEnd,
    this.drawTop = true,
    this.drawBottom = true,
  });

  final String time;
  final String? timeEnd;
  final _Node node;
  final bool drawTop;
  final bool drawBottom;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final end = timeEnd;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: _timeColumnWidth(context),
            child: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Una hora nunca se parte en dos líneas («09:0» / «0»).
                  Text(time, softWrap: false, style: BcText.title()),
                  if (end != null)
                    Text(end, softWrap: false, style: BcText.caption()),
                ],
              ),
            ),
          ),
          SizedBox(
            width: 34,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 12,
                  child: drawTop ? const _RailLine() : null,
                ),
                Center(child: node),
                Expanded(child: drawBottom ? const _RailLine() : const SizedBox()),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: BcSpace.s3),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _RailLine extends StatelessWidget {
  const _RailLine();

  @override
  Widget build(BuildContext context) {
    // Ancho del riel (34) menos 2 px de línea, centrada.
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: ColoredBox(color: BcColors.line),
    );
  }
}

/// Nodo del riel: ícono (salida, regreso), número de parada o círculo
/// vacío (tiempo libre).
class _Node extends StatelessWidget {
  const _Node.icon(IconData this.icon) : number = null, hollow = false;
  const _Node.number(int this.number) : icon = null, hollow = false;
  const _Node.hollow() : icon = null, number = null, hollow = true;

  final IconData? icon;
  final int? number;
  final bool hollow;

  @override
  Widget build(BuildContext context) {
    final glyph = icon;
    final n = number;
    return ExcludeSemantics(
      child: Container(
        width: 26,
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: hollow
              ? BcColors.fog
              : (n != null ? BcColors.glacier : BcColors.ink),
          border: hollow ? Border.all(color: BcColors.muted, width: 2) : null,
        ),
        child: glyph != null
            ? Icon(glyph, size: 14, color: BcColors.onPhoto)
            : (n != null
                  ? Text('$n', style: BcText.label(color: BcColors.ink))
                  : null),
      ),
    );
  }
}

/// Traslado estimado entre dos puntos. Siempre se rotula como estimado.
class _TravelConnector extends StatelessWidget {
  const _TravelConnector({required this.minutes, required this.isSpanish});

  final int minutes;
  final bool isSpanish;

  @override
  Widget build(BuildContext context) {
    final duration = ItineraryPlanner.formatDuration(minutes);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(width: _timeColumnWidth(context)),
          const SizedBox(width: 34, child: _RailLine()),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: BcSpace.s3),
              child: Row(
                children: [
                  const Icon(
                    Icons.directions_car_outlined,
                    size: 16,
                    color: BcColors.muted,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      isSpanish
                          ? '≈ $duration de traslado, estimado'
                          : '≈ $duration travel, estimated',
                      style: BcText.caption(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Endpoint extends StatelessWidget {
  const _Endpoint({
    required this.title,
    required this.subtitle,
    this.muted = false,
  });

  final String title;
  final String subtitle;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: BcText.title(color: muted ? BcColors.muted : BcColors.ink),
          ),
          const SizedBox(height: 2),
          Text(subtitle, style: BcText.caption()),
        ],
      ),
    );
  }
}

enum _StopAction { details, walk, car, moveUp, moveDown, remove }

/// Tarjeta de una parada: foto (o ícono si no tiene), nombre, categoría y
/// duración estimada de la visita. Tocarla abre la ficha.
class _StopCard extends StatelessWidget {
  const _StopCard({
    required this.stop,
    required this.index,
    required this.isSpanish,
    required this.icon,
    required this.onRemove,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  final ScheduledStop stop;
  final int index;
  final bool isSpanish;
  final IconData icon;
  final VoidCallback onRemove;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  @override
  Widget build(BuildContext context) {
    final es = isSpanish;
    final place = stop.place;
    final image = place.imageUrl;
    final visit = ItineraryPlanner.formatDuration(place.visitMinutes);
    final compact = MediaQuery.sizeOf(context).width < 390 || MediaQuery.textScalerOf(context).scale(15) > 19;

    return Material(
      color: BcColors.surface,
      borderRadius: BorderRadius.circular(BcRadius.tile),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openPlaceDetail(context, place),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(10, 10, 0, 10),
          child: Row(
            children: [
              if (!compact) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(BcRadius.control),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: image != null && image.trim().isNotEmpty
                      ? BcPhotoImage(source: image)
                      : ColoredBox(
                          color: BcColors.fog,
                          child: Icon(icon, color: BcColors.muted, size: 28),
                        ),
                ),
              ),
              const SizedBox(width: BcSpace.s3),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name(es),
                      softWrap: true,
                      style: BcText.title(),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        es ? 'Visita estimada $visit' : 'Estimated visit $visit',
                        if (!place.hasLocation)
                          es ? 'sin ubicación' : 'no location',
                      ].join(' · '),
                      style: BcText.caption(color: BcColors.glacierDeep),
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ReorderableDragStartListener(
                    index: index,
                    child: Semantics(
                      button: true,
                      label: es
                          ? 'Mover ${place.name(es)}'
                          : 'Move ${place.name(es)}',
                      child: const SizedBox(
                        width: 48,
                        height: 48,
                        child: Icon(
                          Icons.drag_indicator_rounded,
                          color: BcColors.muted,
                        ),
                      ),
                    ),
                  ),
                  PopupMenuButton<_StopAction>(
                    tooltip: es ? 'Más acciones' : 'More actions',
                    icon: const Icon(Icons.more_horiz_rounded, color: BcColors.ink),
                    onSelected: (action) {
                      switch (action) {
                        case _StopAction.details:
                          openPlaceDetail(context, place);
                        case _StopAction.walk:
                          openPlaceRoute(context, place, 'pie');
                        case _StopAction.car:
                          openPlaceRoute(context, place, 'auto');
                        case _StopAction.moveUp:
                          onMoveUp?.call();
                        case _StopAction.moveDown:
                          onMoveDown?.call();
                        case _StopAction.remove:
                          onRemove();
                      }
                    },
                    itemBuilder: (context) => [
                      _menuItem(
                        _StopAction.details,
                        Icons.info_outline_rounded,
                        es ? 'Ver ficha' : 'View details',
                      ),
                      if (place.hasLocation) ...[
                        _menuItem(
                          _StopAction.walk,
                          Icons.directions_walk_rounded,
                          es ? 'Ruta a pie' : 'Walking route',
                        ),
                        _menuItem(
                          _StopAction.car,
                          Icons.directions_car_rounded,
                          es ? 'Ruta en auto' : 'Driving route',
                        ),
                      ],
                      if (onMoveUp != null)
                        _menuItem(_StopAction.moveUp, Icons.arrow_upward_rounded, es ? 'Mover arriba' : 'Move up'),
                      if (onMoveDown != null)
                        _menuItem(_StopAction.moveDown, Icons.arrow_downward_rounded, es ? 'Mover abajo' : 'Move down'),
                      _menuItem(
                        _StopAction.remove,
                        Icons.remove_circle_outline_rounded,
                        es ? 'Quitar del día' : 'Remove from day',
                        color: BcColors.danger,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  PopupMenuItem<_StopAction> _menuItem(
    _StopAction value,
    IconData icon,
    String label, {
    Color color = BcColors.ink,
  }) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: BcSpace.s3),
          Flexible(child: Text(label, style: BcText.body(color: color))),
        ],
      ),
    );
  }
}
