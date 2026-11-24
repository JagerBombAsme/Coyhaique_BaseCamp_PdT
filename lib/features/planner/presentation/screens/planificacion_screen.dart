import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/providers/auth/auth_user_provider.dart';
import '../../../../core/providers/interests_provider.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/theme/basecamp_tokens.dart';
import '../../../../core/utils/text_normalizer.dart';
import '../../../../core/widgets/basecamp/bc_widgets.dart';
import '../../../categories/data/providers/places_provider.dart';
import '../../data/providers/planner_provider.dart';
import '../../domain/itinerary_planner.dart';
import '../widgets/itinerary_timeline.dart';
import '../widgets/itinerary_views.dart';
import '../widgets/planner_form_widgets.dart';

/// Ruta de «Mis itinerarios».
const String savedItinerariesRoute = '/itinerary/saved';

/// Íconos de las categorías principales por id. Vienen de la base: no hay
/// categorías escritas en el código.
final _categoryIconsProvider = Provider.autoDispose<Map<String, IconData>>((
  ref,
) {
  final categories = ref.watch(mainCategoriesProvider).valueOrNull ?? const [];
  return {for (final c in categories) c.id: c.icon};
});

/// Ícono de un lugar: el de su categoría o uno genérico según el tipo.
IconData _iconFor(Map<String, IconData> icons, PlannerPlace place) =>
    icons[place.categoryId] ??
    (place.kind == 'activity'
        ? Icons.directions_run_rounded
        : Icons.place_rounded);

/// Planificación de la visita (HU-07).
///
/// El usuario indica su tiempo disponible y, si quiere, sus intereses. La
/// aplicación propone lugares con reglas explícitas y el usuario puede
/// agregar, quitar y reordenar. Generar y consultar no requiere cuenta;
/// guardar sí. La propuesta es referencial: no es una reserva ni una ruta de
/// navegación.
class PlanificacionScreen extends ConsumerStatefulWidget {
  const PlanificacionScreen({super.key});

  @override
  ConsumerState<PlanificacionScreen> createState() =>
      _PlanificacionScreenState();
}

enum _ProposalAction { toggleView, addDay, removeDay, discard }

class _PlanificacionScreenState extends ConsumerState<PlanificacionScreen> {
  /// Vista del itinerario. El calendario y los días extra quedan en el menú
  /// «⋮» para que la pantalla principal sea solo el recorrido.
  ItineraryViewMode _mode = ItineraryViewMode.day;

  void _setMode(ItineraryViewMode mode) => setState(() => _mode = mode);

  @override
  Widget build(BuildContext context) {
    final isSpanish = ref.watch(languageProvider).languageCode == 'es';
    final es = isSpanish;
    final state = ref.watch(plannerProvider);

    // Al volver de iniciar sesión, se retoma el guardado pendiente.
    ref.listen(authUserProvider, (previous, next) {
      final user = next.valueOrNull;
      if (user == null || !ref.read(plannerProvider).pendingSave) return;
      Future.delayed(const Duration(milliseconds: 400), () {
        if (!mounted) return;
        if (!ref.read(plannerProvider).pendingSave) return;
        ref.read(plannerProvider.notifier).setPendingSave(false);
        _openSaveDialog(isSpanish);
      });
    });

    return Scaffold(
      backgroundColor: BcColors.fog,
      appBar: AppBar(
        backgroundColor: BcColors.fog,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: es ? 'Mis itinerarios' : 'My itineraries',
            onPressed: () => context.push(savedItinerariesRoute),
            icon: const Icon(Icons.bookmarks_outlined, color: BcColors.ink),
          ),
          if (state.hasProposal)
            PopupMenuButton<_ProposalAction>(
              tooltip: es ? 'Más opciones' : 'More options',
              icon: const Icon(Icons.more_vert_rounded, color: BcColors.ink),
              onSelected: (action) {
                switch (action) {
                  case _ProposalAction.toggleView:
                    _setMode(
                      _mode == ItineraryViewMode.day
                          ? ItineraryViewMode.calendar
                          : ItineraryViewMode.day,
                    );
                  case _ProposalAction.addDay:
                    ref.read(plannerProvider.notifier).addDay();
                    _setMode(ItineraryViewMode.day);
                  case _ProposalAction.removeDay:
                    unawaited(_confirmRemoveDay(es));
                  case _ProposalAction.discard:
                    unawaited(_confirmDiscard(es));
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: _ProposalAction.toggleView,
                  child: Text(
                    _mode == ItineraryViewMode.day
                        ? (es ? 'Ver todos los días' : 'See all days')
                        : (es ? 'Ver el recorrido' : 'See the route'),
                  ),
                ),
                if (state.dayCount < PlannerNotifier.maxDays)
                  PopupMenuItem(
                    value: _ProposalAction.addDay,
                    child: Text(es ? 'Agregar otro día' : 'Add another day'),
                  ),
                if (state.dayCount > 1)
                  PopupMenuItem(
                    value: _ProposalAction.removeDay,
                    child: Text(
                      es
                          ? 'Quitar ${itineraryDayLabel(state.activeDay, true).toLowerCase()}'
                          : 'Remove ${itineraryDayLabel(state.activeDay, false).toLowerCase()}',
                    ),
                  ),
                PopupMenuItem(
                  value: _ProposalAction.discard,
                  child: Text(
                    es ? 'Descartar y volver a empezar' : 'Discard and start over',
                    style: BcText.body(color: BcColors.danger),
                  ),
                ),
              ],
            ),
          const SizedBox(width: BcSpace.s1),
        ],
      ),
      body: AnimatedSwitcher(
        duration: itineraryMotion(context, 250),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: state.hasProposal
            ? _ProposalView(
                key: const ValueKey('proposal'),
                isSpanish: es,
                mode: _mode,
                onModeChanged: _setMode,
                onSave: () => _onSave(es),
              )
            : _PlannerForm(key: const ValueKey('form'), isSpanish: es),
      ),
    );
  }

  void _onSave(bool isSpanish) {
    final user = ref.read(authUserProvider).valueOrNull;
    if (user == null) {
      _askToLogin(isSpanish);
      return;
    }
    _openSaveDialog(isSpanish);
  }

  /// Vuelve al formulario. Si hay lugares, pide confirmación: lo que no se
  /// guardó se pierde.
  Future<void> _confirmDiscard(bool es) async {
    final notifier = ref.read(plannerProvider.notifier);
    if (ref.read(plannerProvider).allPlaces.isNotEmpty) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.restart_alt_rounded),
          title: Text(es ? '¿Descartar la propuesta?' : 'Discard the proposal?'),
          content: Text(
            es
                ? 'Volverás al formulario. Los cambios que no guardaste se pierden; tu tiempo, intereses y punto de partida se mantienen.'
                : 'You will go back to the form. Unsaved changes are lost; your time, interests and starting point are kept.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(es ? 'Cancelar' : 'Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: BcColors.danger),
              onPressed: () => Navigator.pop(context, true),
              child: Text(es ? 'Descartar' : 'Discard'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    notifier.reset();
  }

  /// Quita el día activo; si tiene lugares pide confirmación.
  Future<void> _confirmRemoveDay(bool es) async {
    final state = ref.read(plannerProvider);
    final notifier = ref.read(plannerProvider.notifier);
    final day = state.activeDay;

    if (state.schedule.stops.isNotEmpty) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(es ? 'Quitar día' : 'Remove day'),
          content: Text(
            es
                ? 'Se quitarán ${itineraryDayLabel(day, true)} y sus lugares del itinerario.'
                : '${itineraryDayLabel(day, false)} and its places will be removed from the itinerary.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(es ? 'Cancelar' : 'Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(es ? 'Quitar' : 'Remove'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    notifier.removeDay(day);
  }

  Future<void> _askToLogin(bool isSpanish) async {
    final goToLogin = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.bookmark_add_outlined),
        title: Text(
          isSpanish ? 'Inicia sesión para guardar' : 'Sign in to save',
        ),
        content: Text(
          isSpanish
              ? 'Puedes crear y revisar el itinerario sin cuenta. Para guardarlo y verlo después, inicia sesión. Tu itinerario se mantiene mientras tanto.'
              : 'You can create and review the itinerary without an account. To save it and see it later, sign in. Your itinerary is kept meanwhile.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(isSpanish ? 'Ahora no' : 'Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(isSpanish ? 'Iniciar sesión' : 'Sign in'),
          ),
        ],
      ),
    );
    if (goToLogin != true || !mounted) return;
    ref.read(plannerProvider.notifier).setPendingSave(true);
    context.push('/auth?from=${Uri.encodeComponent('/itinerary')}');
  }

  Future<void> _openSaveDialog(bool isSpanish) async {
    final state = ref.read(plannerProvider);
    final suggested =
        state.savedName ??
        (isSpanish
            ? 'Mi visita ${DateFormat('dd-MM-yyyy').format(DateTime.now())}'
            : 'My visit ${DateFormat('yyyy-MM-dd').format(DateTime.now())}');

    final name = await showDialog<String>(
      context: context,
      builder: (context) => _SaveDialog(
        initialName: suggested,
        isSpanish: isSpanish,
        isUpdate: state.savedItineraryId != null,
      ),
    );
    if (name == null || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    try {
      await ref.read(plannerProvider.notifier).save(name);
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            isSpanish ? 'Itinerario guardado.' : 'Itinerary saved.',
          ),
          action: SnackBarAction(
            label: isSpanish ? 'Ver mis itinerarios' : 'My itineraries',
            onPressed: () => router.push(savedItinerariesRoute),
          ),
        ),
      );
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            isSpanish
                ? 'No se pudo guardar. Revisa tu conexión e intenta de nuevo; el itinerario se mantiene.'
                : 'It could not be saved. Check your connection and try again; the itinerary is kept.',
          ),
        ),
      );
    }
  }
}

// =================================================================
// FORMULARIO
// =================================================================

/// Tres preguntas con chips y un botón. Nada más.
class _PlannerForm extends ConsumerWidget {
  const _PlannerForm({super.key, required this.isSpanish});

  final bool isSpanish;

  static const List<int> _presetHours = [3, 6, 9];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final es = isSpanish;
    final state = ref.watch(plannerProvider);
    final notifier = ref.read(plannerProvider.notifier);
    final interests = ref.watch(interestsProvider);
    final categoriesAsync = ref.watch(mainCategoriesProvider);
    final hours = state.availableMinutes ~/ 60;
    final isPreset = _presetHours.contains(hours);
    final start = ItineraryPlanner.formatClock(state.startMinute);
    final end = ItineraryPlanner.formatClock(
      state.startMinute + state.availableMinutes,
    );
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return _PlannerActionLayout(
      bottomInset: bottomInset,
      content: [
            Semantics(
              header: true,
              child: Text(
                (es ? 'Arma tu día' : 'Plan your day').toUpperCase(),
                style: BcText.display(40),
              ),
            ),
            const SizedBox(height: BcSpace.s2),
            Text(
              es
                  ? 'Responde tres preguntas y te proponemos un recorrido.'
                  : 'Answer three questions and we suggest a route.',
              style: BcText.body(),
            ),
            const SizedBox(height: BcSpace.section),

            // 1. Tiempo
            _Question(es ? '¿Cuánto tiempo tienes?' : 'How much time do you have?'),
            Wrap(
              spacing: BcSpace.s2,
              runSpacing: BcSpace.s2,
              children: [
                for (final h in _presetHours)
                  PlannerFilterChip(
                    label: '$h h',
                    selected: hours == h,
                    onTap: () => notifier.setAvailableMinutes(h * 60),
                  ),
                PlannerFilterChip(
                  label: isPreset ? (es ? 'Otro' : 'Other') : '$hours h',
                  icon: Icons.tune_rounded,
                  selected: !isPreset,
                  onTap: () => _pickHours(context, ref, hours),
                ),
              ],
            ),
            const SizedBox(height: BcSpace.s2),
            Row(
              children: [
                Expanded(
                  child: Text(
                    es ? 'De $start a $end' : 'From $start to $end',
                    style: BcText.body(color: BcColors.ink),
                  ),
                ),
                Flexible(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: BcColors.glacierDeep,
                      minimumSize: const Size(48, 48),
                    ),
                    onPressed: () => _pickStart(context, ref),
                    child: Text(es ? 'Cambiar hora' : 'Change time', textAlign: TextAlign.center),
                  ),
                ),
              ],
            ),
            const SizedBox(height: BcSpace.section),

            // 2. Intereses
            _Question(es ? '¿Qué te interesa?' : 'What are you into?'),
            categoriesAsync.when(
              data: (categories) {
                final lang = es ? 'es' : 'en';
                final visible =
                    categories
                        .where(
                          (c) => c.isActive && isPlannerCategory(c.groupType),
                        )
                        .toList()
                      ..sort(
                        (a, b) => a.getNombre(lang).compareTo(b.getNombre(lang)),
                      );
                return Wrap(
                  spacing: BcSpace.s2,
                  runSpacing: BcSpace.s2,
                  children: [
                    PlannerFilterChip(
                      label: es ? 'Todo' : 'Everything',
                      selected: interests.isEmpty,
                      onTap: () => ref.read(interestsProvider.notifier).clear(),
                    ),
                    for (final category in visible)
                      PlannerFilterChip(
                        label: category.getNombre(lang),
                        icon: category.icon,
                        selected: interests.contains(category.id),
                        onTap: () => ref
                            .read(interestsProvider.notifier)
                            .toggle(category.id),
                      ),
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: BcSpace.s3),
                child: LinearProgressIndicator(),
              ),
              error: (_, _) => Text(
                es
                    ? 'No se cargaron los intereses. Se usarán todos los lugares.'
                    : 'Interests did not load. All places will be used.',
                style: BcText.caption(),
              ),
            ),
            const SizedBox(height: BcSpace.section),

            // 3. Partida
            _Question(es ? '¿Desde dónde sales?' : 'Where do you start?'),
            Wrap(
              spacing: BcSpace.s2,
              runSpacing: BcSpace.s2,
              children: [
                PlannerFilterChip(
                  label: 'Plaza de Armas',
                  icon: Icons.location_city_rounded,
                  selected: !state.useMyLocation,
                  onTap: () => notifier.setUseMyLocation(false),
                ),
                PlannerFilterChip(
                  label: es ? 'Mi ubicación' : 'My location',
                  icon: Icons.my_location_rounded,
                  selected: state.useMyLocation,
                  onTap: () => notifier.setUseMyLocation(true),
                ),
              ],
            ),

            if (state.errorMessage != null) ...[
              const SizedBox(height: BcSpace.s4),
              PlannerNotice(
                tone: PlannerNoticeTone.danger,
                icon: Icons.cloud_off_rounded,
                text: es
                    ? 'Sin conexión y sin información descargada. Conéctate e intenta de nuevo.'
                    : 'No connection and no downloaded information. Connect and try again.',
              ),
            ],
      ],
      actions: BcButton(
            label: es ? 'Crear mi itinerario' : 'Create my itinerary',
            icon: Icons.auto_awesome_rounded,
            isLoading: state.isGenerating,
            onPressed: notifier.generate,
      ),
    );
  }

  Future<void> _pickStart(BuildContext context, WidgetRef ref) async {
    final state = ref.read(plannerProvider);
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: state.startMinute ~/ 60,
        minute: state.startMinute % 60,
      ),
    );
    if (picked == null) return;
    ref
        .read(plannerProvider.notifier)
        .setStartMinute(picked.hour * 60 + picked.minute);
  }

  /// Otra duración (2 a 12 h) en un diálogo pequeño.
  Future<void> _pickHours(BuildContext context, WidgetRef ref, int current) async {
    final es = isSpanish;
    final picked = await showDialog<int>(
      context: context,
      builder: (context) {
        var value = current.clamp(2, 12);
        return StatefulBuilder(
          builder: (context, setLocal) => AlertDialog(
            title: Text(es ? '¿Cuántas horas?' : 'How many hours?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$value h', style: BcText.display(40)),
                Slider(
                  value: value.toDouble(),
                  min: 2,
                  max: 12,
                  divisions: 10,
                  label: '$value h',
                  semanticFormatterCallback: (v) =>
                      es ? '${v.round()} horas' : '${v.round()} hours',
                  onChanged: (v) => setLocal(() => value = v.round()),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(es ? 'Cancelar' : 'Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, value),
                child: Text(es ? 'Listo' : 'Done'),
              ),
            ],
          ),
        );
      },
    );
    if (picked != null) {
      ref.read(plannerProvider.notifier).setAvailableMinutes(picked * 60);
    }
  }
}

/// The footer participates in layout; it cannot cover the final list item.
/// On very short windows, actions join the scroll content instead.
class _PlannerActionLayout extends StatelessWidget {
  const _PlannerActionLayout({required this.bottomInset, required this.content, required this.actions});

  final double bottomInset;
  final List<Widget> content;
  final Widget actions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final largeText = MediaQuery.textScalerOf(context).scale(15) > 19;
        final inline = constraints.maxHeight - bottomInset < (largeText ? 400 : 260);
        final footer = Padding(
          padding: const EdgeInsets.fromLTRB(BcSpace.gutter, BcSpace.s3, BcSpace.gutter, BcSpace.s3),
          child: actions,
        );
        final list = ListView(
          padding: EdgeInsets.fromLTRB(BcSpace.gutter, BcSpace.s1, BcSpace.gutter, inline ? 0 : BcSpace.s4),
          children: [
            ...content,
            if (inline) ...[const SizedBox(height: BcSpace.s4), actions],
          ],
        );
        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: inline ? list : Column(
            children: [
              Expanded(child: list),
              Material(color: BcColors.fog, child: footer),
            ],
          ),
        );
      },
    );
  }
}

/// Pregunta del formulario.
class _Question extends StatelessWidget {
  const _Question(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: BcSpace.s3),
      child: Semantics(
        header: true,
        child: Text(text, style: BcText.title().copyWith(fontSize: 17)),
      ),
    );
  }
}

// =================================================================
// ITINERARIO GENERADO
// =================================================================

class _ProposalView extends ConsumerWidget {
  const _ProposalView({
    super.key,
    required this.isSpanish,
    required this.mode,
    required this.onModeChanged,
    required this.onSave,
  });

  final bool isSpanish;
  final ItineraryViewMode mode;
  final ValueChanged<ItineraryViewMode> onModeChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final es = isSpanish;
    final state = ref.watch(plannerProvider);
    final notifier = ref.read(plannerProvider.notifier);
    final icons = ref.watch(_categoryIconsProvider);
    IconData iconFor(PlannerPlace place) => _iconFor(icons, place);

    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final schedule = state.schedule;
    final count = schedule.stops.length;
    final originName = state.origin.isUserLocation
        ? (es ? 'Tu ubicación' : 'Your location')
        : 'Plaza de Armas';

    final line = [
      es
          ? '$count ${count == 1 ? 'lugar' : 'lugares'}'
          : '$count ${count == 1 ? 'place' : 'places'}',
      if (count > 0)
        '${ItineraryPlanner.formatClock(schedule.startMinute)} – '
            '${ItineraryPlanner.formatClock(schedule.endMinute)}',
    ].join(' · ');

    void openAdd() => _openAddSheet(context, ref, iconFor);

    return _PlannerActionLayout(
      bottomInset: bottomInset,
      content: [
            Semantics(
              header: true,
              child: Text(
                (state.savedName ?? (es ? 'Tu recorrido' : 'Your route'))
                    .toUpperCase(),
                style: BcText.display(38),
              ),
            ),
            const SizedBox(height: BcSpace.s2),
            Text(line, style: BcText.body(color: BcColors.ink)),

            if (state.locationFallback) ...[
              const SizedBox(height: BcSpace.s3),
              PlannerNotice(
                icon: Icons.location_off_rounded,
                text: es
                    ? 'No pudimos usar tu ubicación; partimos desde la Plaza de Armas.'
                    : 'We could not use your location; we start from Plaza de Armas.',
                actionLabel: es ? 'Ajustes' : 'Settings',
                onAction: () => unawaited(Geolocator.openAppSettings()),
              ),
            ],

            // Los días solo aparecen si hay más de uno.
            if (state.dayCount > 1 && mode == ItineraryViewMode.day) ...[
              const SizedBox(height: BcSpace.s4),
              ItineraryDayChips(
                dayCount: state.dayCount,
                activeDay: state.activeDay,
                canAddDay: false,
                isSpanish: es,
                onSelect: notifier.setActiveDay,
                onAddDay: notifier.addDay,
              ),
            ],
            const SizedBox(height: BcSpace.s4),

            AnimatedSwitcher(
              duration: itineraryMotion(context, 220),
              child: mode == ItineraryViewMode.day
                  ? _DayContent(
                      key: ValueKey('day-${state.activeDay}'),
                      isSpanish: es,
                      originLabel: originName,
                      iconFor: iconFor,
                      onAdd: openAdd,
                    )
                  : ItineraryCalendarView(
                      key: const ValueKey('calendar'),
                      schedules: [
                        for (var d = 0; d < state.dayCount; d++)
                          state.scheduleOf(d),
                      ],
                      activeDay: state.activeDay,
                      isSpanish: es,
                      iconFor: iconFor,
                      onOpenDay: (day) {
                        notifier.setActiveDay(day);
                        onModeChanged(ItineraryViewMode.day);
                      },
                    ),
            ),
            const SizedBox(height: BcSpace.s4),
            Text(
              es
                  ? 'Horarios y traslados son estimados. Confirma con cada lugar.'
                  : 'Times and travel are estimates. Confirm with each place.',
              style: BcText.caption(),
            ),
      ],
      actions: LayoutBuilder(
        builder: (context, constraints) {
          final add = BcButton(
            label: es ? 'Agregar' : 'Add',
            icon: Icons.add_rounded,
            style: BcButtonStyle.surface,
            onPressed: openAdd,
          );
          final save = BcButton(
            label: state.savedItineraryId != null
                ? (es ? 'Guardar cambios' : 'Save changes')
                : (es ? 'Guardar' : 'Save'),
            icon: Icons.bookmark_add_rounded,
            isLoading: state.isSaving,
            onPressed: state.allPlaces.isEmpty ? null : onSave,
          );
          if (constraints.maxWidth < 320 || MediaQuery.textScalerOf(context).scale(15) > 19) {
            return Column(children: [add, const SizedBox(height: BcSpace.s2), save]);
          }
          return Row(children: [Expanded(child: add), const SizedBox(width: BcSpace.s2), Expanded(child: save)]);
        },
      ),
    );
  }

  Future<void> _openAddSheet(
    BuildContext context,
    WidgetRef ref,
    PlaceIconResolver iconFor,
  ) async {
    final notifier = ref.read(plannerProvider.notifier);
    final dayLabel = itineraryDayLabel(ref.read(plannerProvider).activeDay, isSpanish);

    final selected = await showModalBottomSheet<PlannerPlace>(
      context: context,
      isScrollControlled: true,
      // Sobre la barra de navegación flotante: con el navegador de la
      // pestaña la hoja quedaba debajo y la barra tapaba los últimos lugares.
      useRootNavigator: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: BcColors.fog,
      builder: (context) => _AddPlaceSheet(
        isSpanish: isSpanish,
        dayLabel: dayLabel,
        iconFor: iconFor,
      ),
    );
    if (selected != null && context.mounted) {
      notifier.add(selected);
      onModeChanged(ItineraryViewMode.day);
    }
  }
}

/// Día activo: barra de tiempo y recorrido (o el día vacío).
class _DayContent extends ConsumerWidget {
  const _DayContent({
    super.key,
    required this.isSpanish,
    required this.originLabel,
    required this.iconFor,
    required this.onAdd,
  });

  final bool isSpanish;
  final String originLabel;
  final PlaceIconResolver iconFor;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final es = isSpanish;
    final state = ref.watch(plannerProvider);
    final notifier = ref.read(plannerProvider.notifier);
    final schedule = state.schedule;

    if (schedule.stops.isEmpty) {
      return ItineraryEmptyDay(
        isSpanish: es,
        onAdd: onAdd,
        message: state.dayCount == 1
            ? (es
                  ? 'Ningún lugar cabe en ese tiempo. Prueba con más horas, otros intereses o agrega lugares a mano.'
                  : 'No place fits that time. Try more hours, other interests or add places by hand.')
            : null,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TimeCapacityBar(
          schedule: schedule,
          availableMinutes: state.availableMinutes,
          isSpanish: es,
        ),
        const SizedBox(height: BcSpace.s4),
        ItineraryTimeline(
          schedule: schedule,
          availableMinutes: state.availableMinutes,
          originLabel: originLabel,
          isSpanish: es,
          iconFor: iconFor,
          onReorder: notifier.reorder,
          onRemove: (index) => _removeWithUndo(context, ref, index),
        ),
      ],
    );
  }

  /// Quita la parada y ofrece deshacer en vez de pedir confirmación.
  void _removeWithUndo(BuildContext context, WidgetRef ref, int index) {
    final es = isSpanish;
    final notifier = ref.read(plannerProvider.notifier);
    final stops = ref.read(plannerProvider).stops;
    if (stops == null || index < 0 || index >= stops.length) return;
    final place = stops[index];
    final messenger = ScaffoldMessenger.of(context);

    notifier.removeAt(index);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            es ? 'Quitaste ${place.name(es)}.' : 'You removed ${place.name(es)}.',
          ),
          action: SnackBarAction(
            label: es ? 'Deshacer' : 'Undo',
            onPressed: () {
              // Vuelve a su posición en el mismo día.
              notifier.add(place);
              final after = ref.read(plannerProvider).stops;
              if (after == null) return;
              final last = after.length - 1;
              final target = math.min(index, last);
              if (target != last) notifier.reorder(last, target);
            },
          ),
        ),
      );
  }
}

// =================================================================
// AGREGAR LUGAR
// =================================================================

class _AddPlaceSheet extends ConsumerStatefulWidget {
  const _AddPlaceSheet({
    required this.isSpanish,
    required this.dayLabel,
    required this.iconFor,
  });

  final bool isSpanish;
  final String dayLabel;
  final PlaceIconResolver iconFor;

  @override
  ConsumerState<_AddPlaceSheet> createState() => _AddPlaceSheetState();
}

class _AddPlaceSheetState extends ConsumerState<_AddPlaceSheet> {
  String _query = '';
  String? _categoryId;
  late Future<void> _loading;

  @override
  void initState() {
    super.initState();
    _loading = ref.read(plannerProvider.notifier).ensureCandidates();
  }

  void _retry() {
    setState(() {
      _loading = ref.read(plannerProvider.notifier).ensureCandidates();
    });
  }

  @override
  Widget build(BuildContext context) {
    final es = widget.isSpanish;
    final state = ref.watch(plannerProvider);
    final inItinerary = state.allPlaces;
    final term = normalizeForSearch(_query);
    final media = MediaQuery.of(context);
    final keyboard = media.viewInsets.bottom;
    final height = math.max(media.size.height * 0.85 - keyboard, 0.0);

    // Categorías presentes entre los candidatos (datos reales del catálogo).
    final categories = <String, String>{};
    for (final p in state.candidates) {
      final name = p.categoryName(es);
      if (name != null && name.isNotEmpty) categories[p.categoryId] = name;
    }
    final categoryEntries = categories.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    final options = state.candidates
        .where((p) => !inItinerary.contains(p))
        .where((p) => _categoryId == null || p.categoryId == _categoryId)
        .where(
          (p) =>
              term.isEmpty ||
              normalizeForSearch(p.nameEs).contains(term) ||
              normalizeForSearch(p.nameEn ?? '').contains(term) ||
              normalizeForSearch(p.categoryNameEs ?? '').contains(term),
        )
        .toList();

    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: SizedBox(
        height: height,
        child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverList(
              delegate: SliverChildListDelegate([
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (es
                                  ? 'Agregar a ${widget.dayLabel}'
                                  : 'Add to ${widget.dayLabel}')
                              .toUpperCase(),
                          style: BcText.label(color: BcColors.muted),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          es ? 'Elige un lugar' : 'Choose a place',
                          style: BcText.title().copyWith(fontSize: 19),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: es ? 'Cerrar' : 'Close',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: TextField(
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: BcColors.surface,
                  prefixIcon: const Icon(Icons.search_rounded),
                  hintText: es
                      ? 'Buscar un lugar o actividad'
                      : 'Search a place or activity',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(BcRadius.field),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            if (categoryEntries.length > 1)
              SizedBox(
                height: math.max(48.0, MediaQuery.textScalerOf(context).scale(14) * 1.2 + 24),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    PlannerFilterChip(
                      label: es ? 'Todas' : 'All',
                      selected: _categoryId == null,
                      onTap: () => setState(() => _categoryId = null),
                    ),
                    for (final entry in categoryEntries) ...[
                      const SizedBox(width: BcSpace.s2),
                      PlannerFilterChip(
                        label: entry.value,
                        selected: _categoryId == entry.key,
                        onTap: () => setState(
                          () => _categoryId =
                              _categoryId == entry.key ? null : entry.key,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: BcSpace.s2),
              ]),
            ),
            FutureBuilder<void>(
                future: _loading,
                builder: (context, snapshot) {
                  final loading =
                      snapshot.connectionState != ConnectionState.done;
                  if (state.candidates.isEmpty && loading) {
                    return SliverToBoxAdapter(child: PlannerSkeletonList(
                      semanticLabel: es ? 'Cargando lugares' : 'Loading places',
                    ));
                  }
                  if (state.candidates.isEmpty) {
                    return SliverToBoxAdapter(child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: PlannerNotice(
                          tone: PlannerNoticeTone.danger,
                          icon: Icons.cloud_off_rounded,
                          text: es
                              ? 'No se pudieron cargar los lugares. Revisa tu conexión o descarga la información desde el inicio.'
                              : 'Places could not be loaded. Check your connection or download the information from the home screen.',
                          actionLabel: es ? 'Reintentar' : 'Retry',
                          onAction: _retry,
                        ),
                      ),
                    ));
                  }
                  if (options.isEmpty) {
                    return SliverToBoxAdapter(child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.search_off_rounded,
                            size: 32,
                            color: BcColors.muted,
                          ),
                          const SizedBox(height: BcSpace.s2),
                          Text(
                            es ? 'Sin resultados' : 'No results',
                            style: BcText.title(),
                          ),
                          const SizedBox(height: BcSpace.s2),
                          TextButton(
                            onPressed: () => setState(() => _categoryId = null),
                            child: Text(
                              es ? 'Ver todas las categorías' : 'Show all categories',
                            ),
                          ),
                        ],
                      ),
                    ));
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    sliver: SliverList(delegate: SliverChildBuilderDelegate(
                      (context, index) => _AddPlaceRow(
                      place: options[index],
                      isSpanish: es,
                      icon: widget.iconFor(options[index]),
                      ),
                      childCount: options.length,
                    )),
                  );
                },
            ),
          ],
        ),
      ),
    );
  }
}

class _AddPlaceRow extends StatelessWidget {
  const _AddPlaceRow({
    required this.place,
    required this.isSpanish,
    required this.icon,
  });

  final PlannerPlace place;
  final bool isSpanish;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final es = isSpanish;
    final category = place.categoryName(es);
    final image = place.imageUrl;
    final visit = ItineraryPlanner.formatDuration(place.visitMinutes);

    return Padding(
      padding: const EdgeInsets.only(bottom: BcSpace.s2),
      child: Semantics(
        button: true,
        excludeSemantics: true,
        label: es
            ? 'Agregar ${place.name(es)}. Visita estimada $visit'
            : 'Add ${place.name(es)}. Estimated visit $visit',
        onTap: () => Navigator.pop(context, place),
        child: Material(
          color: BcColors.surface,
          borderRadius: BorderRadius.circular(BcRadius.tile),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => Navigator.pop(context, place),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(10, 10, 12, 10),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(BcRadius.control),
                    child: SizedBox(
                      width: 52,
                      height: 52,
                      child: BcPhotoImage(
                        source: image ?? '',
                        fallbackCategory:
                            '${place.categorySlug ?? ''} ${place.categoryNameEs ?? ''} '
                            '${bcReferenceCategoryForIcon(icon)} ${place.kind}',
                        isSpanish: es,
                      ),
                    ),
                  ),
                  const SizedBox(width: BcSpace.s3),
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
                            es ? 'visita est. $visit' : 'est. visit $visit',
                          ].join(' · '),
                          style: BcText.caption(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: BcSpace.s2),
                  const Icon(
                    Icons.add_circle_rounded,
                    color: BcColors.glacierDeep,
                    size: 28,
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

// =================================================================
// GUARDAR
// =================================================================

class _SaveDialog extends StatefulWidget {
  const _SaveDialog({
    required this.initialName,
    required this.isSpanish,
    required this.isUpdate,
  });

  final String initialName;
  final bool isSpanish;
  final bool isUpdate;

  @override
  State<_SaveDialog> createState() => _SaveDialogState();
}

class _SaveDialogState extends State<_SaveDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialName,
  );
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      setState(
        () =>
            _error = widget.isSpanish ? 'Escribe un nombre.' : 'Enter a name.',
      );
      return;
    }
    Navigator.pop(context, name);
  }

  @override
  Widget build(BuildContext context) {
    final es = widget.isSpanish;
    return AlertDialog(
      icon: const Icon(Icons.bookmark_add_rounded),
      title: Text(
        widget.isUpdate
            ? (es ? 'Guardar cambios' : 'Save changes')
            : (es ? 'Guardar itinerario' : 'Save itinerary'),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            es
                ? 'Lo verás en «Mis itinerarios».'
                : 'You will find it in “My itineraries”.',
            style: BcText.caption(),
          ),
          const SizedBox(height: BcSpace.s3),
          TextField(
            controller: _controller,
            autofocus: true,
            maxLength: 80,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: es ? 'Nombre' : 'Name',
              errorText: _error,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(es ? 'Cancelar' : 'Cancel'),
        ),
        FilledButton(onPressed: _submit, child: Text(es ? 'Guardar' : 'Save')),
      ],
    );
  }
}
