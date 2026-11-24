import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/basecamp_tokens.dart';
import '../../../../core/widgets/basecamp/bc_widgets.dart';
import '../../domain/itinerary_planner.dart';

/// Forma de ver el itinerario: la línea de tiempo de un día o todos los días
/// como bloques en orden cronológico.
enum ItineraryViewMode { day, calendar }

/// Ícono de un lugar según su categoría principal (viene de la base).
typedef PlaceIconResolver = IconData Function(PlannerPlace place);

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
    '&modo=${Uri.encodeQueryComponent(mode)}'
    '&t=${DateTime.now().millisecondsSinceEpoch}',
  );
}

// =================================================================
// CONTROLES: selector de día
// =================================================================

/// Fila horizontal de días («Día 1», «Día 2»…) con el botón para agregar
/// otro. Mide 44 dp de alto.
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
      height: (MediaQuery.textScalerOf(context).scale(14) * 1.2 + 24).clamp(48.0, 160.0).toDouble(),
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
              label: isSpanish ? 'Agregar día' : 'Add day',
              icon: Icons.add_rounded,
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
    this.icon,
    this.outlined = false,
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final bool outlined;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const fg = BcColors.ink;
    final glyph = icon;
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
          constraints: const BoxConstraints(minWidth: 72, minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? BcColors.glacier
                : (outlined ? Colors.transparent : BcColors.surface),
            borderRadius: BorderRadius.circular(BcRadius.pill),
            border: outlined ? Border.all(color: BcColors.muted) : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (glyph != null) ...[
                Icon(glyph, size: 18, color: fg),
                const SizedBox(width: 4),
              ],
              Text(label, style: BcText.button(color: fg).copyWith(fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Día sin actividades: explica la situación y ofrece agregar un lugar.
class ItineraryEmptyDay extends StatelessWidget {
  const ItineraryEmptyDay({
    super.key,
    required this.isSpanish,
    required this.onAdd,
    this.message,
  });

  final bool isSpanish;
  final VoidCallback onAdd;

  /// Texto propio (por ejemplo, cuando ningún lugar cupo en el tiempo).
  final String? message;

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
          const Icon(
            Icons.travel_explore_rounded,
            size: 32,
            color: BcColors.glacierDeep,
          ),
          const SizedBox(height: BcSpace.s3),
          Text(
            es ? 'Este día aún no tiene lugares' : 'This day has no places yet',
            style: BcText.title().copyWith(fontSize: 17),
          ),
          const SizedBox(height: BcSpace.s2),
          Text(
            message ??
                (es
                    ? 'Agrega lugares del catálogo para armar el día.'
                    : 'Add places from the catalog to build the day.'),
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
// VISTA CALENDARIO: bloques por día en orden cronológico
// =================================================================

/// Todos los días del itinerario como bloques de tiempo. La altura de cada
/// bloque crece con la duración estimada de la visita. Es una vista de
/// lectura: tocar un día lo abre en la línea de tiempo para editarlo.
class ItineraryCalendarView extends StatelessWidget {
  const ItineraryCalendarView({
    super.key,
    required this.schedules,
    required this.activeDay,
    required this.isSpanish,
    required this.iconFor,
    required this.onOpenDay,
  });

  /// Horarios de cada día, en orden.
  final List<ItinerarySchedule> schedules;
  final int activeDay;
  final bool isSpanish;
  final PlaceIconResolver iconFor;
  final ValueChanged<int> onOpenDay;

  @override
  Widget build(BuildContext context) {
    final es = isSpanish;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var day = 0; day < schedules.length; day++)
          Padding(
            padding: const EdgeInsets.only(bottom: BcSpace.s4),
            child: _CalendarDay(
              day: day,
              schedule: schedules[day],
              selected: day == activeDay,
              isSpanish: es,
              iconFor: iconFor,
              onOpen: () => onOpenDay(day),
            ),
          ),
      ],
    );
  }
}

class _CalendarDay extends StatelessWidget {
  const _CalendarDay({
    required this.day,
    required this.schedule,
    required this.selected,
    required this.isSpanish,
    required this.iconFor,
    required this.onOpen,
  });

  final int day;
  final ItinerarySchedule schedule;
  final bool selected;
  final bool isSpanish;
  final PlaceIconResolver iconFor;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final es = isSpanish;
    final stops = schedule.stops;
    final range = stops.isEmpty
        ? (es ? 'Sin lugares' : 'No places')
        : '${ItineraryPlanner.formatClock(schedule.startMinute)} – '
              '${ItineraryPlanner.formatClock(schedule.endMinute)}';

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
      decoration: BoxDecoration(
        color: BcColors.surface,
        borderRadius: BorderRadius.circular(BcRadius.card),
        border: Border.all(
          color: selected ? BcColors.glacier : BcColors.surface,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            label: es
                ? 'Abrir ${itineraryDayLabel(day, true)}, $range'
                : 'Open ${itineraryDayLabel(day, false)}, $range',
            excludeSemantics: true,
            onTap: onOpen,
            child: InkWell(
              onTap: onOpen,
              borderRadius: BorderRadius.circular(BcRadius.control),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Row(
                  children: [
                    Text(
                      itineraryDayLabel(day, es).toUpperCase(),
                      style: BcText.display(22),
                    ),
                    const SizedBox(width: BcSpace.s3),
                    Expanded(child: Text(range, style: BcText.caption())),
                    Text(
                      es ? 'Editar' : 'Edit',
                      style: BcText.button(color: BcColors.glacierDeep)
                          .copyWith(fontSize: 14),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: BcColors.glacierDeep,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (stops.isNotEmpty) const SizedBox(height: BcSpace.s2),
          for (var i = 0; i < stops.length; i++) ...[
            if (i > 0 && stops[i].travelMinutes > 0)
              _CalendarGap(minutes: stops[i].travelMinutes),
            if (i > 0 && stops[i].travelMinutes == 0)
              const SizedBox(height: BcSpace.s2),
            _CalendarBlock(
              stop: stops[i],
              isSpanish: es,
              icon: iconFor(stops[i].place),
            ),
          ],
        ],
      ),
    );
  }
}

/// Bloque de una actividad. Lugar: franja glaciar; actividad: franja tinta.
/// El tipo también se distingue por el ícono.
class _CalendarBlock extends StatelessWidget {
  const _CalendarBlock({
    required this.stop,
    required this.isSpanish,
    required this.icon,
  });

  final ScheduledStop stop;
  final bool isSpanish;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final place = stop.place;
    final es = isSpanish;
    final start = ItineraryPlanner.formatClock(stop.arrivalMinute);
    final end = ItineraryPlanner.formatClock(stop.departureMinute);
    final visit = ItineraryPlanner.formatDuration(place.visitMinutes);
    // 60 min ≈ 64 dp; nunca menos de 56 ni más de 128.
    final height = (place.visitMinutes * 64 / 60).clamp(56.0, 128.0);

    return Semantics(
      button: true,
      excludeSemantics: true,
      label:
          '$start ${es ? 'a' : 'to'} $end, ${place.name(es)}. '
          '${es ? 'Visita estimada' : 'Estimated visit'} $visit',
      onTap: () => openPlaceDetail(context, place),
      child: Material(
        color: BcColors.fog,
        borderRadius: BorderRadius.circular(BcRadius.control),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => openPlaceDetail(context, place),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: height),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ColoredBox(
                    color: place.kind == 'activity'
                        ? BcColors.ink
                        : BcColors.glacier,
                    child: const SizedBox(width: 5),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(icon, size: 20, color: BcColors.ink),
                          const SizedBox(width: 10),
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
                                const SizedBox(height: 2),
                                Text(
                                  '$start – $end · est. $visit',
                                  style: BcText.caption(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CalendarGap extends StatelessWidget {
  const _CalendarGap({required this.minutes});

  final int minutes;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 16, top: 4, bottom: 4),
      child: Row(
        children: [
          const Icon(
            Icons.more_vert_rounded,
            size: 16,
            color: BcColors.muted,
          ),
          const SizedBox(width: 6),
          Text(
            '≈ ${ItineraryPlanner.formatDuration(minutes)}',
            style: BcText.caption(),
          ),
        ],
      ),
    );
  }
}
