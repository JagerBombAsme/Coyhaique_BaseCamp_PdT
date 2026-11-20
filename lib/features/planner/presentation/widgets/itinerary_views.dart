import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/basecamp_tokens.dart';
import '../../../../core/widgets/basecamp/bc_widgets.dart';
import '../../domain/itinerary_planner.dart';

/// Forma de ver el itinerario: un día con tarjetas grandes o todos los días
/// en orden cronológico.
enum ItineraryViewMode { day, calendar }

/// Duración de las transiciones del itinerario. Sin animación si el usuario
/// pidió reducir el movimiento.
Duration itineraryMotion(BuildContext context, [int milliseconds = 260]) {
  return MediaQuery.disableAnimationsOf(context)
      ? Duration.zero
      : Duration(milliseconds: milliseconds);
}

/// «Día 1», «Day 1». Los días no tienen fecha de calendario: no se inventa.
String itineraryDayLabel(int dayIndex, bool isSpanish) =>
    isSpanish ? 'Día ${dayIndex + 1}' : 'Day ${dayIndex + 1}';

/// Ficha del lugar (la misma que abre el resto de la app).
void openPlaceDetail(BuildContext context, PlannerPlace place) {
  context.push('/attractions/${place.id}');
}

/// Abre el mapa en el lugar y traza la ruta con las funciones del mapa.
/// [mode] es `pie` o `auto`.
void openPlaceRoute(BuildContext context, PlannerPlace place, String mode) {
  context.go(
    '/map?lugar=${Uri.encodeQueryComponent(place.id)}'
    '&modo=${Uri.encodeQueryComponent(mode)}',
  );
}

/// Texto de duración y traslado de una parada. La duración de la visita es
/// una estimación por tipo de lugar mientras places_v2 no traiga
/// estimated_visit_minutes (P-01), y así se rotula.
String itineraryStopMeta(ScheduledStop stop, bool isSpanish) {
  final visit = ItineraryPlanner.formatDuration(stop.place.visitMinutes);
  final travel = ItineraryPlanner.formatDuration(stop.travelMinutes);
  return [
    isSpanish ? 'Visita estimada $visit' : 'Estimated visit $visit',
    if (stop.travelMinutes > 0)
      isSpanish ? 'traslado $travel' : 'travel $travel',
    if (!stop.place.hasLocation) isSpanish ? 'sin ubicación' : 'no location',
  ].join(' · ');
}

// =================================================================
// CONTROLES: selector de vista y de día
// =================================================================

/// Selector «Día | Calendario».
class ItineraryModeSelector extends StatelessWidget {
  const ItineraryModeSelector({
    super.key,
    required this.mode,
    required this.isSpanish,
    required this.onChanged,
  });

  final ItineraryViewMode mode;
  final bool isSpanish;
  final ValueChanged<ItineraryViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ModePill(
          label: isSpanish ? 'Día' : 'Day',
          selected: mode == ItineraryViewMode.day,
          onTap: () => onChanged(ItineraryViewMode.day),
        ),
        const SizedBox(width: BcSpace.s2),
        _ModePill(
          label: isSpanish ? 'Calendario' : 'Calendar',
          selected: mode == ItineraryViewMode.calendar,
          onTap: () => onChanged(ItineraryViewMode.calendar),
        ),
      ],
    );
  }
}

class _ModePill extends StatelessWidget {
  const _ModePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      excludeSemantics: true,
      label: label,
      onTap: onTap,
      child: BcPressable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: itineraryMotion(context, 200),
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? BcColors.ink : BcColors.surface,
            borderRadius: BorderRadius.circular(BcRadius.pill),
          ),
          child: Text(
            label,
            style: BcText.button(
              color: selected ? BcColors.onPhoto : BcColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

/// Botón redondo «+» para agregar un lugar.
class ItineraryAddButton extends StatelessWidget {
  const ItineraryAddButton({
    super.key,
    required this.semanticLabel,
    required this.onTap,
  });

  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BcPressable(
      onTap: onTap,
      semanticLabel: semanticLabel,
      child: Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
          color: BcColors.glacier,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.add_rounded, color: BcColors.ink, size: 26),
      ),
    );
  }
}

/// Fila de días («Día 1», «Día 2»…) con el botón para agregar otro.
class ItineraryDayChips extends StatelessWidget {
  const ItineraryDayChips({
    super.key,
    required this.dayCount,
    required this.activeDay,
    required this.canAddDay,
    required this.isSpanish,
    required this.onSelect,
    required this.onAddDay,
  });

  final int dayCount;
  final int activeDay;
  final bool canAddDay;
  final bool isSpanish;
  final ValueChanged<int> onSelect;
  final VoidCallback onAddDay;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (var i = 0; i < dayCount; i++) ...[
            _DayChip(
              label: itineraryDayLabel(i, isSpanish),
              selected: i == activeDay,
              onTap: () => onSelect(i),
            ),
            const SizedBox(width: BcSpace.s2),
          ],
          if (canAddDay)
            _DayChip(
              label: isSpanish ? '+ Día' : '+ Day',
              selected: false,
              outlined: true,
              onTap: onAddDay,
            ),
        ],
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.outlined = false,
  });

  final String label;
  final bool selected;
  final bool outlined;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      excludeSemantics: true,
      label: label,
      onTap: onTap,
      child: BcPressable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: itineraryMotion(context, 200),
          height: 44,
          constraints: const BoxConstraints(minWidth: 72),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? BcColors.glacier : BcColors.surface,
            borderRadius: BorderRadius.circular(BcRadius.pill),
            border: outlined ? Border.all(color: BcColors.line) : null,
          ),
          child: Text(label, style: BcText.button(color: BcColors.ink)),
        ),
      ),
    );
  }
}

// =================================================================
// VISTA DÍA: tarjetas grandes y verticales
// =================================================================

/// Tarjeta de una actividad del día. Muestra hora, nombre, categoría,
/// duración y traslado, y las acciones: ficha, ruta a pie, ruta en auto y
/// quitar. [index] es la posición en la lista reordenable.
class ItineraryStopCard extends StatelessWidget {
  const ItineraryStopCard({
    super.key,
    required this.stop,
    required this.index,
    required this.isSpanish,
    required this.onRemove,
  });

  final ScheduledStop stop;
  final int index;
  final bool isSpanish;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final place = stop.place;
    final category = place.categoryName(isSpanish);
    final es = isSpanish;

    return Padding(
      padding: const EdgeInsets.only(bottom: BcSpace.s3),
      child: Material(
        color: BcColors.ink,
        borderRadius: BorderRadius.circular(BcRadius.card),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => openPlaceDetail(context, place),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 4, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        ItineraryPlanner.formatClock(stop.arrivalMinute),
                        style: BcText.display(28, color: BcColors.glacier),
                      ),
                    ),
                    const SizedBox(width: BcSpace.s3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            place.name(es),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: BcText.title(
                              color: BcColors.onPhoto,
                            ).copyWith(fontSize: 18),
                          ),
                          if (category != null && category.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              category,
                              style: BcText.caption(
                                color: BcColors.onPhoto.withValues(alpha: 0.72),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    ReorderableDragStartListener(
                      index: index,
                      child: Semantics(
                        label: es ? 'Mover' : 'Move',
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: Icon(
                            Icons.drag_indicator_rounded,
                            color: BcColors.onPhoto.withValues(alpha: 0.72),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: BcSpace.s2),
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 12),
                  child: Text(
                    itineraryStopMeta(stop, es),
                    style: BcText.caption(
                      color: BcColors.onPhoto.withValues(alpha: 0.72),
                    ),
                  ),
                ),
                const SizedBox(height: BcSpace.s3),
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 12),
                  child: Wrap(
                    spacing: BcSpace.s2,
                    runSpacing: BcSpace.s2,
                    children: [
                      _CardAction(
                        label: es ? 'Ver ficha' : 'View details',
                        icon: Icons.chevron_right_rounded,
                        filled: true,
                        onTap: () => openPlaceDetail(context, place),
                      ),
                      if (place.hasLocation) ...[
                        _CardAction(
                          label: es ? 'A pie' : 'On foot',
                          icon: Icons.directions_walk_rounded,
                          onTap: () => openPlaceRoute(context, place, 'pie'),
                        ),
                        _CardAction(
                          label: es ? 'En auto' : 'By car',
                          icon: Icons.directions_car_rounded,
                          onTap: () => openPlaceRoute(context, place, 'auto'),
                        ),
                      ],
                      _CardAction(
                        label: es ? 'Quitar' : 'Remove',
                        icon: Icons.remove_circle_outline_rounded,
                        iconOnly: true,
                        onTap: onRemove,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CardAction extends StatelessWidget {
  const _CardAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.filled = false,
    this.iconOnly = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;
  final bool iconOnly;

  @override
  Widget build(BuildContext context) {
    final fg = filled ? BcColors.ink : BcColors.onPhoto;

    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: filled ? BcColors.glacier : Colors.transparent,
        shape: StadiumBorder(
          side: filled
              ? BorderSide.none
              : BorderSide(color: BcColors.onPhoto.withValues(alpha: 0.28)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: iconOnly ? 10 : 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 20, color: fg),
                  if (!iconOnly) ...[
                    const SizedBox(width: 6),
                    Text(label, style: BcText.button(color: fg).copyWith(fontSize: 14)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Mensaje del día sin actividades.
class ItineraryEmptyDay extends StatelessWidget {
  const ItineraryEmptyDay({
    super.key,
    required this.isSpanish,
    required this.onAdd,
  });

  final bool isSpanish;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final es = isSpanish;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: BcColors.surface,
        borderRadius: BorderRadius.circular(BcRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            es ? 'Este día no tiene actividades' : 'This day has no activities',
            style: BcText.title(),
          ),
          const SizedBox(height: BcSpace.s2),
          Text(
            es
                ? 'Agrega lugares del catálogo para armar el día.'
                : 'Add places from the catalog to build the day.',
            style: BcText.body(),
          ),
          const SizedBox(height: BcSpace.s4),
          BcButton(
            label: es ? 'Agregar lugar' : 'Add place',
            icon: Icons.add_location_alt_rounded,
            height: 48,
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }
}

// =================================================================
// VISTA CALENDARIO: días y actividades en orden cronológico
// =================================================================

/// Todos los días del itinerario, uno bajo otro, con sus actividades en
/// orden de hora. Es una vista de lectura: tocar un día lo abre en la vista
/// Día para editarlo.
class ItineraryCalendarView extends StatelessWidget {
  const ItineraryCalendarView({
    super.key,
    required this.schedules,
    required this.activeDay,
    required this.isSpanish,
    required this.onOpenDay,
  });

  /// Horarios de cada día, en orden.
  final List<ItinerarySchedule> schedules;
  final int activeDay;
  final bool isSpanish;
  final ValueChanged<int> onOpenDay;

  @override
  Widget build(BuildContext context) {
    final es = isSpanish;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
      decoration: BoxDecoration(
        color: BcColors.ink,
        borderRadius: BorderRadius.circular(BcRadius.card + 4),
      ),
      child: Column(
        children: [
          for (var day = 0; day < schedules.length; day++)
            Padding(
              padding: const EdgeInsets.only(bottom: BcSpace.s4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DayMarker(
                    number: day + 1,
                    selected: day == activeDay,
                    isSpanish: es,
                    onTap: () => onOpenDay(day),
                  ),
                  const SizedBox(width: BcSpace.s2),
                  Expanded(
                    child: schedules[day].stops.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.only(top: 14),
                            child: Text(
                              es ? 'Sin actividades' : 'No activities',
                              style: BcText.body(
                                color: BcColors.onPhoto.withValues(alpha: 0.72),
                              ),
                            ),
                          )
                        : Column(
                            children: [
                              for (final stop in schedules[day].stops)
                                _CalendarStopTile(stop: stop, isSpanish: es),
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

class _DayMarker extends StatelessWidget {
  const _DayMarker({
    required this.number,
    required this.selected,
    required this.isSpanish,
    required this.onTap,
  });

  final int number;
  final bool selected;
  final bool isSpanish;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = itineraryDayLabel(number - 1, isSpanish);
    final fg = selected ? BcColors.ink : BcColors.onPhoto;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: BcPressable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: itineraryMotion(context, 200),
          width: 60,
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? BcColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(BcRadius.tile),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                (isSpanish ? 'Día' : 'Day').toUpperCase(),
                style: BcText.label(
                  color: selected
                      ? BcColors.muted
                      : BcColors.onPhoto.withValues(alpha: 0.72),
                ),
              ),
              const SizedBox(height: 2),
              Text('$number', style: BcText.display(34, color: fg)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CalendarStopTile extends StatelessWidget {
  const _CalendarStopTile({required this.stop, required this.isSpanish});

  final ScheduledStop stop;
  final bool isSpanish;

  @override
  Widget build(BuildContext context) {
    final place = stop.place;
    final es = isSpanish;
    final category = place.categoryName(es);
    final time = ItineraryPlanner.formatClock(stop.arrivalMinute);
    final visit = ItineraryPlanner.formatDuration(place.visitMinutes);

    return Padding(
      padding: const EdgeInsets.only(bottom: BcSpace.s2),
      child: Semantics(
        button: true,
        excludeSemantics: true,
        label:
            '$time, ${place.name(es)}. '
            '${es ? 'Visita estimada' : 'Estimated visit'} $visit',
        onTap: () => openPlaceDetail(context, place),
        child: Material(
          color: BcColors.surface,
          borderRadius: BorderRadius.circular(BcRadius.tile),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => openPlaceDetail(context, place),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 64),
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 6, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            place.name(es),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: BcText.title(),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            [
                              if (category != null && category.isNotEmpty)
                                category,
                              'est. $visit',
                            ].join(' · '),
                            style: BcText.caption(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: BcSpace.s2),
                    Text(time, style: BcText.display(20)),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: BcColors.muted,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
