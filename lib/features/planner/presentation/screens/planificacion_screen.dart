import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/providers/auth/auth_user_provider.dart';
import '../../../../core/providers/interests_provider.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/text_normalizer.dart';
import '../../../categories/data/providers/places_provider.dart';
import '../../data/providers/planner_provider.dart';
import '../../domain/itinerary_planner.dart';

/// Ruta de «Mis itinerarios».
const String savedItinerariesRoute = '/itinerary/saved';

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

class _PlanificacionScreenState extends ConsumerState<PlanificacionScreen> {
  @override
  Widget build(BuildContext context) {
    final isSpanish = ref.watch(languageProvider).languageCode == 'es';
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
      backgroundColor: AppTheme.slateLight,
      appBar: AppBar(
        title: Text(
          state.savedName ??
              (isSpanish ? 'Planifica tu visita' : 'Plan your visit'),
        ),
        actions: [
          IconButton(
            tooltip: isSpanish ? 'Mis itinerarios' : 'My itineraries',
            icon: const Icon(Icons.bookmarks_outlined),
            onPressed: () => context.push(savedItinerariesRoute),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: state.hasProposal
            ? _ProposalView(
                key: const ValueKey('proposal'),
                isSpanish: isSpanish,
                onSave: () => _onSave(isSpanish),
              )
            : _PlannerForm(
                key: const ValueKey('form'),
                isSpanish: isSpanish,
              ),
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

  Future<void> _askToLogin(bool isSpanish) async {
    final goToLogin = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isSpanish ? 'Inicia sesión para guardar' : 'Sign in to save'),
        content: Text(
          isSpanish
              ? 'Puedes generar y revisar la propuesta sin cuenta. Para guardarla y verla después, inicia sesión. Tu propuesta se mantiene mientras tanto.'
              : 'You can create and review the proposal without an account. To save it and see it later, sign in. Your proposal is kept meanwhile.',
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
    final suggested = state.savedName ??
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
          content: Text(isSpanish ? 'Itinerario guardado.' : 'Itinerary saved.'),
          action: SnackBarAction(
            label: isSpanish ? 'Ver mis itinerarios' : 'My itineraries',
            onPressed: () => router.push(savedItinerariesRoute),
          ),
        ),
      );
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            isSpanish
                ? 'No se pudo guardar. Revisa tu conexión e intenta de nuevo; la propuesta se mantiene.'
                : 'It could not be saved. Check your connection and try again; the proposal is kept.',
          ),
        ),
      );
    }
  }
}

// =================================================================
// FORMULARIO
// =================================================================

class _PlannerForm extends ConsumerWidget {
  const _PlannerForm({super.key, required this.isSpanish});

  final bool isSpanish;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(plannerProvider);
    final notifier = ref.read(plannerProvider.notifier);
    final interests = ref.watch(interestsProvider);
    final categoriesAsync = ref.watch(mainCategoriesProvider);
    final hours = state.availableMinutes ~/ 60;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
      children: [
        Text(
          isSpanish
              ? 'Indica tu tiempo disponible y, si quieres, tus intereses. Te proponemos lugares según tus intereses, la duración estimada de cada visita y la distancia desde el punto de partida.'
              : 'Tell us how much time you have and, if you like, your interests. We suggest places based on your interests, the estimated length of each visit and the distance from your starting point.',
          style: const TextStyle(color: AppTheme.textSecondary, height: 1.35),
        ),
        const SizedBox(height: 16),

        // Tiempo disponible
        _FormCard(
          icon: Icons.schedule_rounded,
          title: isSpanish ? 'Tiempo disponible' : 'Available time',
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(isSpanish ? 'Hora de inicio' : 'Start time'),
              trailing: OutlinedButton(
                onPressed: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay(
                      hour: state.startMinute ~/ 60,
                      minute: state.startMinute % 60,
                    ),
                  );
                  if (picked != null) {
                    notifier.setStartMinute(picked.hour * 60 + picked.minute);
                  }
                },
                child: Text(ItineraryPlanner.formatClock(state.startMinute)),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(isSpanish ? 'Duración del día' : 'Length of the day'),
                ),
                Text(
                  '$hours h',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            Slider(
              value: hours.toDouble(),
              min: 2,
              max: 12,
              divisions: 10,
              label: '$hours h',
              onChanged: (value) =>
                  notifier.setAvailableMinutes(value.round() * 60),
            ),
            Text(
              isSpanish
                  ? 'Termina cerca de las ${ItineraryPlanner.formatClock(state.startMinute + state.availableMinutes)}, incluido el regreso.'
                  : 'Ends around ${ItineraryPlanner.formatClock(state.startMinute + state.availableMinutes)}, including the way back.',
              style: const TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Intereses
        _FormCard(
          icon: Icons.interests_rounded,
          title: isSpanish ? 'Intereses (opcional)' : 'Interests (optional)',
          children: [
            Text(
              interests.isEmpty
                  ? (isSpanish
                      ? 'Sin intereses seleccionados se consideran todas las categorías.'
                      : 'With no interests selected, all categories are considered.')
                  : (isSpanish
                      ? 'Se guardan solo en tu teléfono.'
                      : 'They are stored only on your phone.'),
              style: const TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            categoriesAsync.when(
              data: (categories) {
                final visible = categories
                    .where((c) => c.isActive && isPlannerCategory(c.groupType))
                    .toList()
                  ..sort(
                    (a, b) => a
                        .getNombre(isSpanish ? 'es' : 'en')
                        .compareTo(b.getNombre(isSpanish ? 'es' : 'en')),
                  );
                return Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final category in visible)
                      FilterChip(
                        label: Text(category.getNombre(isSpanish ? 'es' : 'en')),
                        selected: interests.contains(category.id),
                        onSelected: (_) => ref
                            .read(interestsProvider.notifier)
                            .toggle(category.id),
                      ),
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(8),
                child: LinearProgressIndicator(),
              ),
              error: (_, __) => Text(
                isSpanish
                    ? 'No se pudieron cargar las categorías. Puedes generar la propuesta sin intereses.'
                    : 'Categories could not be loaded. You can create the proposal without interests.',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Punto de partida
        _FormCard(
          icon: Icons.place_rounded,
          title: isSpanish ? 'Punto de partida' : 'Starting point',
          children: [
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                  value: false,
                  icon: const Icon(Icons.location_city_rounded),
                  label: Text(isSpanish ? 'Coyhaique' : 'Coyhaique'),
                ),
                ButtonSegment(
                  value: true,
                  icon: const Icon(Icons.my_location_rounded),
                  label: Text(isSpanish ? 'Mi ubicación' : 'My location'),
                ),
              ],
              selected: {state.useMyLocation},
              onSelectionChanged: (value) => notifier.setUseMyLocation(value.first),
            ),
            const SizedBox(height: 6),
            Text(
              state.useMyLocation
                  ? (isSpanish
                      ? 'Se usa tu ubicación solo para calcular distancias; no se guarda.'
                      : 'Your location is used only to calculate distances; it is not stored.')
                  : (isSpanish
                      ? 'Desde la Plaza de Armas de Coyhaique.'
                      : 'From the Plaza de Armas in Coyhaique.'),
              style: const TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 20),

        if (state.errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              isSpanish
                  ? 'No hay conexión ni información descargada. Conéctate a Internet y vuelve a intentarlo.'
                  : 'There is no connection and no downloaded information. Connect to the Internet and try again.',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),

        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.primaryDark,
            minimumSize: const Size.fromHeight(52),
          ),
          onPressed: state.isGenerating ? null : notifier.generate,
          icon: state.isGenerating
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.auto_awesome_motion_rounded),
          label: Text(isSpanish ? 'Generar propuesta' : 'Create proposal'),
        ),
        const SizedBox(height: 10),
        Text(
          isSpanish
              ? 'No necesitas cuenta para generar la propuesta. Solo para guardarla.'
              : 'You do not need an account to create the proposal, only to save it.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
        ),
      ],
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: AppTheme.primaryDark),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

// =================================================================
// PROPUESTA
// =================================================================

class _ProposalView extends ConsumerWidget {
  const _ProposalView({
    super.key,
    required this.isSpanish,
    required this.onSave,
  });

  final bool isSpanish;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(plannerProvider);
    final notifier = ref.read(plannerProvider.notifier);
    final schedule = state.schedule;
    final exceeds = schedule.totalMinutes > state.availableMinutes;
    final isEmpty = schedule.stops.isEmpty;

    final header = Padding(
      key: const ValueKey('header'),
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEmpty
                    ? (isSpanish ? 'Sin lugares en la propuesta' : 'No places in the proposal')
                    : '${ItineraryPlanner.formatClock(schedule.startMinute)} – ${ItineraryPlanner.formatClock(schedule.endMinute)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryDark,
                ),
              ),
              const SizedBox(height: 4),
              if (!isEmpty)
                Text(
                  isSpanish
                      ? '${schedule.stops.length} ${schedule.stops.length == 1 ? 'lugar' : 'lugares'} · ${ItineraryPlanner.formatDuration(schedule.totalMinutes)} de ${ItineraryPlanner.formatDuration(state.availableMinutes)} disponibles'
                      : '${schedule.stops.length} ${schedule.stops.length == 1 ? 'place' : 'places'} · ${ItineraryPlanner.formatDuration(schedule.totalMinutes)} of ${ItineraryPlanner.formatDuration(state.availableMinutes)} available',
                ),
              Text(
                state.origin.isUserLocation
                    ? (isSpanish ? 'Desde tu ubicación' : 'From your location')
                    : (isSpanish ? 'Desde la Plaza de Armas de Coyhaique' : 'From the Plaza de Armas in Coyhaique'),
                style: const TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
              ),
              if (state.locationFallback)
                _Note(
                  icon: Icons.location_off_rounded,
                  text: isSpanish
                      ? 'No se pudo obtener tu ubicación; se calculó desde Coyhaique.'
                      : 'Your location could not be obtained; Coyhaique was used.',
                ),
              if (isEmpty)
                _Note(
                  icon: Icons.info_outline_rounded,
                  text: isSpanish
                      ? 'Ningún lugar cabe en el tiempo indicado con esos intereses. Aumenta el tiempo, cambia los intereses o agrega lugares a mano.'
                      : 'No place fits the time given with those interests. Increase the time, change the interests or add places by hand.',
                ),
              if (exceeds)
                _Note(
                  icon: Icons.warning_amber_rounded,
                  color: Colors.orange.shade800,
                  text: isSpanish
                      ? 'La propuesta supera tu tiempo disponible. Quita algún lugar o revisa el orden.'
                      : 'The proposal exceeds your available time. Remove a place or check the order.',
                ),
            ],
          ),
        ),
      ),
    );

    final footer = Padding(
      key: const ValueKey('footer'),
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!isEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                isSpanish
                    ? 'Regreso estimado: ${ItineraryPlanner.formatDuration(schedule.returnTravelMinutes)}'
                    : 'Estimated way back: ${ItineraryPlanner.formatDuration(schedule.returnTravelMinutes)}',
                style: const TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
              ),
            ),
          OutlinedButton.icon(
            onPressed: () => _openAddSheet(context, ref),
            icon: const Icon(Icons.add_location_alt_rounded),
            label: Text(isSpanish ? 'Agregar lugar' : 'Add place'),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryDark,
              minimumSize: const Size.fromHeight(50),
            ),
            onPressed: isEmpty || state.isSaving ? null : onSave,
            icon: state.isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.bookmark_add_rounded),
            label: Text(
              state.savedItineraryId != null
                  ? (isSpanish ? 'Guardar cambios' : 'Save changes')
                  : (isSpanish ? 'Guardar itinerario' : 'Save itinerary'),
            ),
          ),
          TextButton.icon(
            onPressed: notifier.reset,
            icon: const Icon(Icons.restart_alt_rounded),
            label: Text(isSpanish ? 'Nueva propuesta' : 'New proposal'),
          ),
          const SizedBox(height: 4),
          Text(
            isSpanish
                ? 'Propuesta referencial: no es una reserva ni una ruta de navegación. Los traslados se estiman en línea recta a ${ItineraryPlanner.averageSpeedKmh.round()} km/h y no consideran el estado del camino ni el clima. Confirma horarios con cada lugar.'
                : 'Reference proposal: it is not a booking or a navigation route. Travel times are estimated in a straight line at ${ItineraryPlanner.averageSpeedKmh.round()} km/h and do not consider road conditions or weather. Confirm opening hours with each place.',
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.35),
          ),
        ],
      ),
    );

    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
      header: header,
      footer: footer,
      buildDefaultDragHandles: false,
      itemCount: schedule.stops.length,
      onReorder: notifier.reorder,
      itemBuilder: (context, index) {
        final stop = schedule.stops[index];
        final place = stop.place;
        final category = place.categoryName(isSpanish);
        final details = [
          isSpanish
              ? 'Visita ${ItineraryPlanner.formatDuration(place.visitMinutes)}'
              : 'Visit ${ItineraryPlanner.formatDuration(place.visitMinutes)}',
          if (stop.travelMinutes > 0)
            isSpanish
                ? 'traslado ${ItineraryPlanner.formatDuration(stop.travelMinutes)}'
                : 'travel ${ItineraryPlanner.formatDuration(stop.travelMinutes)}',
          if (!place.hasLocation) isSpanish ? 'sin ubicación' : 'no location',
        ].join(' · ');

        return Card(
          key: ValueKey(place.id),
          color: Colors.white,
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            contentPadding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
            onTap: () => context.push('/attractions/${place.id}'),
            leading: CircleAvatar(
              backgroundColor: AppTheme.accentLightBlue,
              child: Text(
                ItineraryPlanner.formatClock(stop.arrivalMinute),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryDark,
                ),
              ),
            ),
            title: Text(
              place.name(isSpanish),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              [if (category != null && category.isNotEmpty) category, details].join('\n'),
            ),
            isThreeLine: category != null && category.isNotEmpty,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: isSpanish ? 'Quitar' : 'Remove',
                  icon: const Icon(Icons.remove_circle_outline_rounded),
                  onPressed: () => notifier.removeAt(index),
                ),
                ReorderableDragStartListener(
                  index: index,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.drag_handle_rounded,
                      semanticLabel: isSpanish ? 'Mover' : 'Move',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openAddSheet(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(plannerProvider.notifier);
    unawaited(notifier.ensureCandidates());

    final selected = await showModalBottomSheet<PlannerPlace>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _AddPlaceSheet(isSpanish: isSpanish),
    );
    if (selected != null) notifier.add(selected);
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.text, this.color});

  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.textSecondary;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: c),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: TextStyle(fontSize: 12.5, color: c))),
        ],
      ),
    );
  }
}

// =================================================================
// AGREGAR LUGAR
// =================================================================

class _AddPlaceSheet extends ConsumerStatefulWidget {
  const _AddPlaceSheet({required this.isSpanish});

  final bool isSpanish;

  @override
  ConsumerState<_AddPlaceSheet> createState() => _AddPlaceSheetState();
}

class _AddPlaceSheetState extends ConsumerState<_AddPlaceSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final es = widget.isSpanish;
    final state = ref.watch(plannerProvider);
    final inItinerary = {...?state.stops};
    final term = normalizeForSearch(_query);

    final options = state.candidates
        .where((p) => !inItinerary.contains(p))
        .where(
          (p) =>
              term.isEmpty ||
              normalizeForSearch(p.nameEs).contains(term) ||
              normalizeForSearch(p.nameEn).contains(term) ||
              normalizeForSearch(p.categoryNameEs).contains(term),
        )
        .toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.75,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                autofocus: true,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search_rounded),
                  hintText: es ? 'Buscar un lugar o actividad' : 'Search a place or activity',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            Expanded(
              child: state.candidates.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          es
                              ? 'Cargando lugares… Si no aparecen, revisa tu conexión o descarga la información.'
                              : 'Loading places… If none appear, check your connection or download the information.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : options.isEmpty
                      ? Center(child: Text(es ? 'Sin resultados.' : 'No results.'))
                      : ListView.separated(
                          itemCount: options.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final place = options[index];
                            return ListTile(
                              leading: Icon(
                                place.kind == 'activity'
                                    ? Icons.directions_run_rounded
                                    : Icons.place_rounded,
                              ),
                              title: Text(place.name(es)),
                              subtitle: Text(
                                [
                                  if (place.categoryName(es) != null) place.categoryName(es)!,
                                  es
                                      ? 'Visita ${ItineraryPlanner.formatDuration(place.visitMinutes)}'
                                      : 'Visit ${ItineraryPlanner.formatDuration(place.visitMinutes)}',
                                ].join(' · '),
                              ),
                              trailing: const Icon(Icons.add_rounded),
                              onTap: () => Navigator.pop(context, place),
                            );
                          },
                        ),
            ),
          ],
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
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialName);
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      setState(() => _error = widget.isSpanish ? 'Escribe un nombre.' : 'Enter a name.');
      return;
    }
    Navigator.pop(context, name);
  }

  @override
  Widget build(BuildContext context) {
    final es = widget.isSpanish;
    return AlertDialog(
      title: Text(
        widget.isUpdate
            ? (es ? 'Guardar cambios' : 'Save changes')
            : (es ? 'Guardar itinerario' : 'Save itinerary'),
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 80,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          labelText: es ? 'Nombre' : 'Name',
          errorText: _error,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(es ? 'Cancelar' : 'Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(es ? 'Guardar' : 'Save'),
        ),
      ],
    );
  }
}
