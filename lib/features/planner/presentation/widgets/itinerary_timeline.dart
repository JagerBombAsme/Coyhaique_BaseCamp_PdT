import 'package:flutter/material.dart';

import '../../../../core/theme/basecamp_tokens.dart';
import '../../domain/itinerary_planner.dart';


class ItineraryTimeline extends StatelessWidget {
  const ItineraryTimeline({
    super.key,
    required this.schedule,
    required this.isSpanish,
    this.onOpen,
    this.onRemove,
    this.onReorder,
  });

  final ItinerarySchedule schedule;
  final bool isSpanish;
  final void Function(PlannerPlace place)? onOpen;
  final void Function(int index)? onRemove;
  final void Function(int oldIndex, int newIndex)? onReorder;

  @override
  Widget build(BuildContext context) {
    final stops = schedule.stops;
    if (stops.isEmpty) return const SizedBox.shrink();
    final last = stops.length - 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < stops.length; i++)
          _StopRow(
            stop: stops[i],
            isSpanish: isSpanish,
            isFirst: i == 0,
            onOpen: onOpen == null ? null : () => onOpen!(stops[i].place),
            onMoveUp: i > 0 && onReorder != null
                ? () => onReorder!(i, i - 1)
                : null,
            onMoveDown: i < last && onReorder != null
                ? () => onReorder!(i, i + 2)
                : null,
            onRemove: onRemove == null ? null : () => onRemove!(i),
          ),
        _ReturnRow(schedule: schedule, isSpanish: isSpanish),
      ],
    );
  }
}

class _StopRow extends StatelessWidget {
  const _StopRow({
    required this.stop,
    required this.isSpanish,
    required this.isFirst,
    this.onOpen,
    this.onMoveUp,
    this.onMoveDown,
    this.onRemove,
  });

  final ScheduledStop stop;
  final bool isSpanish;
  final bool isFirst;
  final VoidCallback? onOpen;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final place = stop.place;
    final category = place.categoryName(isSpanish);
    final visit = ItineraryPlanner.formatDuration(place.visitMinutes);
    final travel = stop.travelMinutes;
    final detail = travel > 0
        ? (isSpanish
              ? 'Traslado ${ItineraryPlanner.formatDuration(travel)} · Visita $visit'
              : 'Travel ${ItineraryPlanner.formatDuration(travel)} · Visit $visit')
        : (isSpanish ? 'Visita $visit' : 'Visit $visit');

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TimeLabel(minute: stop.arrivalMinute),
          _Rail(isFirst: isFirst, isLast: false, dotColor: BcColors.glacier),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 14),
              child: InkWell(
                borderRadius: BorderRadius.circular(BcRadius.tile),
                onTap: onOpen,
                child: _Card(
                  title: place.name(isSpanish),
                  subtitle: category,
                  detail: detail,
                  actions: [
                    if (onMoveUp != null)
                      _CardAction(
                        icon: Icons.arrow_upward_rounded,
                        tooltip: isSpanish ? 'Subir' : 'Move up',
                        onPressed: onMoveUp!,
                      ),
                    if (onMoveDown != null)
                      _CardAction(
                        icon: Icons.arrow_downward_rounded,
                        tooltip: isSpanish ? 'Bajar' : 'Move down',
                        onPressed: onMoveDown!,
                      ),
                    if (onRemove != null)
                      _CardAction(
                        icon: Icons.remove_circle_outline_rounded,
                        tooltip: isSpanish ? 'Quitar' : 'Remove',
                        onPressed: onRemove!,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReturnRow extends StatelessWidget {
  const _ReturnRow({required this.schedule, required this.isSpanish});

  final ItinerarySchedule schedule;
  final bool isSpanish;

  @override
  Widget build(BuildContext context) {
    final back = schedule.returnTravelMinutes;
    final detail = back > 0
        ? (isSpanish
              ? 'Traslado de regreso ${ItineraryPlanner.formatDuration(back)}'
              : 'Return trip ${ItineraryPlanner.formatDuration(back)}')
        : (isSpanish ? 'Sin traslado de regreso' : 'No return trip');

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TimeLabel(minute: schedule.endMinute),
          const _Rail(isFirst: false, isLast: true, dotColor: BcColors.ink),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 4),
              child: _Card(
                title: isSpanish ? 'Regreso' : 'Return',
                detail: detail,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Hora alineada con el título de la tarjeta.
class _TimeLabel extends StatelessWidget {
  const _TimeLabel({required this.minute});

  final int minute;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58,
      child: Padding(
        padding: const EdgeInsets.only(top: 14, right: 4, left:1),
        child: Text(
          ItineraryPlanner.formatClock(minute),
          textAlign: TextAlign.right,
          style: BcText.title(),
        ),
      ),
    );
  }
}

/// Línea vertical con un punto. La línea no se dibuja por encima del primer
/// punto ni por debajo del último.
class _Rail extends StatelessWidget {
  const _Rail({
    required this.isFirst,
    required this.isLast,
    required this.dotColor,
  });

  final bool isFirst;
  final bool isLast;
  final Color dotColor;

  @override
  Widget build(BuildContext context) {
    const dotSize = 14.0;
    const lineWidth = 2.0;

    return SizedBox(
      width: 22,
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: lineWidth,
              color: isFirst ? Colors.transparent : BcColors.line,
            ),
          ),
          Container(
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          Expanded(
            child: Container(
              width: lineWidth,
              color: isLast ? Colors.transparent : BcColors.line,
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.title,
    required this.detail,
    this.subtitle,
    this.actions = const [],
  });

  final String title;
  final String? subtitle;
  final String detail;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 6, 6),
      decoration: BoxDecoration(
        color: BcColors.surface,
        borderRadius: BorderRadius.circular(BcRadius.tile),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: BcText.title()),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(subtitle!, style: BcText.caption()),
          ],
          const SizedBox(height: 8),
          Text(detail, style: BcText.caption()),
          if (actions.isNotEmpty)
            Row(mainAxisAlignment: MainAxisAlignment.end, children: actions),
        ],
      ),
    );
  }
}

class _CardAction extends StatelessWidget {
  const _CardAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 20, color: BcColors.ink),
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 36, height: 36),
    );
  }
}
