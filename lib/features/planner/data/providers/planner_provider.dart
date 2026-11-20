import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/providers/auth/auth_user_provider.dart';
import '../../../../core/providers/interests_provider.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../categories/data/models/place_dto.dart';
import '../../../categories/data/providers/places_provider.dart';
import '../../domain/itinerary_planner.dart';
import '../models/itinerary_models.dart';
import '../repository/itinerary_repository.dart';

/// Grupos de categorías que no son lugares para visitar y quedan fuera de la
/// propuesta (se consultan en sus propias pantallas).
const Set<String> excludedPlannerGroups = {
  'transporte',
  'servicio',
  'alojamiento',
};

bool isPlannerCategory(String? groupType) =>
    !excludedPlannerGroups.contains(groupType?.trim().toLowerCase());

final itineraryRepositoryProvider = Provider<ItineraryRepository>((ref) {
  return ItineraryRepository(ref.watch(supabaseClientProvider));
});

/// Itinerarios guardados del usuario con sesión iniciada.
final savedItinerariesProvider =
    FutureProvider.autoDispose<List<SavedItinerarySummary>>((ref) async {
      final user = ref.watch(authUserProvider).valueOrNull;
      if (user == null) return const [];
      return ref.read(itineraryRepositoryProvider).listMine();
    });

final plannerProvider = StateNotifierProvider<PlannerNotifier, PlannerState>((
  ref,
) {
  return PlannerNotifier(ref);
});

/// Estado de la planificación. Se mantiene al navegar (por ejemplo, al ir a
/// iniciar sesión para guardar) y se pierde al cerrar la aplicación.
class PlannerState {
  const PlannerState({
    this.startMinute = 9 * 60,
    this.availableMinutes = 6 * 60,
    this.useMyLocation = false,
    this.origin = ItineraryPlanner.coyhaique,
    this.days,
    this.activeDay = 0,
    this.candidates = const [],
    this.isGenerating = false,
    this.isSaving = false,
    this.errorMessage,
    this.locationFallback = false,
    this.savedItineraryId,
    this.savedOwnerId,
    this.savedName,
    this.pendingSave = false,
  });

  final int startMinute;
  final int availableMinutes;
  final bool useMyLocation;
  final PlannerOrigin origin;

  /// Lugares de cada día, en orden. null mientras no se ha generado ni
  /// cargado una propuesta; si no es null, tiene al menos un día.
  final List<List<PlannerPlace>>? days;

  /// Día que se está viendo o editando (índice desde 0).
  final int activeDay;

  /// Lugares disponibles para agregar a mano.
  final List<PlannerPlace> candidates;

  final bool isGenerating;
  final bool isSaving;
  final String? errorMessage;

  /// true si se pidió la ubicación y se usó Coyhaique por no tener permiso.
  final bool locationFallback;

  /// Itinerario guardado que se está editando.
  final String? savedItineraryId;
  final String? savedOwnerId;
  final String? savedName;

  /// El usuario pidió guardar sin sesión y fue a iniciar sesión.
  final bool pendingSave;

  bool get hasProposal => days != null;

  int get dayCount => days?.length ?? 0;

  /// Lugares del día activo.
  List<PlannerPlace>? get stops {
    final all = days;
    if (all == null || all.isEmpty) return null;
    return all[activeDay.clamp(0, all.length - 1)];
  }

  /// Horarios estimados del día activo.
  ItinerarySchedule get schedule => scheduleOf(activeDay);

  /// Horarios estimados de un día. Todos los días parten de la misma hora y
  /// del mismo punto de partida.
  ItinerarySchedule scheduleOf(int day) {
    final all = days;
    return ItineraryPlanner.schedule(
      stops: all != null && day >= 0 && day < all.length ? all[day] : const [],
      origin: origin,
      startMinute: startMinute,
    );
  }

  /// Lugares de todos los días (un lugar solo puede estar una vez).
  Set<PlannerPlace> get allPlaces => {
    for (final day in days ?? const <List<PlannerPlace>>[]) ...day,
  };

  PlannerState copyWith({
    int? startMinute,
    int? availableMinutes,
    bool? useMyLocation,
    PlannerOrigin? origin,
    List<List<PlannerPlace>>? days,
    bool clearDays = false,
    int? activeDay,
    List<PlannerPlace>? candidates,
    bool? isGenerating,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
    bool? locationFallback,
    String? savedItineraryId,
    String? savedOwnerId,
    String? savedName,
    bool clearSaved = false,
    bool? pendingSave,
  }) {
    return PlannerState(
      startMinute: startMinute ?? this.startMinute,
      availableMinutes: availableMinutes ?? this.availableMinutes,
      useMyLocation: useMyLocation ?? this.useMyLocation,
      origin: origin ?? this.origin,
      days: clearDays ? null : (days ?? this.days),
      activeDay: clearDays ? 0 : (activeDay ?? this.activeDay),
      candidates: candidates ?? this.candidates,
      isGenerating: isGenerating ?? this.isGenerating,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      locationFallback: locationFallback ?? this.locationFallback,
      savedItineraryId: clearSaved
          ? null
          : (savedItineraryId ?? this.savedItineraryId),
      savedOwnerId: clearSaved ? null : (savedOwnerId ?? this.savedOwnerId),
      savedName: clearSaved ? null : (savedName ?? this.savedName),
      pendingSave: pendingSave ?? this.pendingSave,
    );
  }
}

class PlannerNotifier extends StateNotifier<PlannerState> {
  PlannerNotifier(this._ref) : super(const PlannerState());

  final Ref _ref;

  void setStartMinute(int minute) =>
      state = state.copyWith(startMinute: minute);

  void setAvailableMinutes(int minutes) =>
      state = state.copyWith(availableMinutes: minutes);

  void setUseMyLocation(bool value) =>
      state = state.copyWith(useMyLocation: value);

  /// Carga los lugares y actividades del catálogo (Supabase o copia local).
  Future<List<PlannerPlace>> _loadCandidates() async {
    final repository = _ref.read(placesRepositoryProvider);
    final results = await Future.wait([
      repository.getPlaces(),
      repository.getActivities(),
    ]);
    final all = <PlaceDto>[...results[0], ...results[1]];
    final unique = <String, PlannerPlace>{};
    for (final dto in all) {
      if (!isPlannerCategory(dto.category?.groupType)) continue;
      unique[dto.id] = plannerPlaceFromDto(dto);
    }
    return unique.values.toList()..sort((a, b) => a.nameEs.compareTo(b.nameEs));
  }

  Future<void> ensureCandidates() async {
    if (state.candidates.isNotEmpty) return;
    try {
      state = state.copyWith(candidates: await _loadCandidates());
    } catch (_) {
      // Se informa al generar; agregar a mano queda vacío.
    }
  }

  /// Ubicación del usuario o, si no hay permiso o no responde, Coyhaique.
  Future<(PlannerOrigin, bool)> _resolveOrigin() async {
    if (!state.useMyLocation) return (ItineraryPlanner.coyhaique, false);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return (ItineraryPlanner.coyhaique, true);
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return (ItineraryPlanner.coyhaique, true);
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return (
        PlannerOrigin(
          latitude: position.latitude,
          longitude: position.longitude,
          isUserLocation: true,
        ),
        false,
      );
    } catch (_) {
      return (ItineraryPlanner.coyhaique, true);
    }
  }

  /// Genera una propuesta nueva con las reglas de [ItineraryPlanner].
  Future<void> generate() async {
    state = state.copyWith(isGenerating: true, clearError: true);
    try {
      final candidates = await _loadCandidates();
      final (origin, fallback) = await _resolveOrigin();
      final interests = _ref.read(interestsProvider);

      // Solo se filtra por intereses que existen entre los candidatos.
      final known = candidates.map((c) => c.categoryId).toSet();
      final activeInterests = interests.where(known.contains).toSet();

      final stops = ItineraryPlanner.propose(
        candidates: candidates,
        origin: origin,
        availableMinutes: state.availableMinutes,
        interests: activeInterests,
      );

      state = state.copyWith(
        candidates: candidates,
        origin: origin,
        locationFallback: fallback,
        days: [stops],
        activeDay: 0,
        isGenerating: false,
        clearSaved: true,
      );
    } catch (_) {
      state = state.copyWith(
        isGenerating: false,
        errorMessage: 'catalog_unavailable',
      );
    }
  }

  /// Máximo de días de un itinerario (coincide con el CHECK de day_index).
  static const int maxDays = 14;

  /// Copia de los días con [change] aplicado al día activo.
  List<List<PlannerPlace>> _withActiveDay(
    void Function(List<PlannerPlace> stops) change,
  ) {
    final days = <List<PlannerPlace>>[
      for (final day in state.days ?? const <List<PlannerPlace>>[])
        <PlannerPlace>[...day],
    ];
    if (days.isEmpty) return days;
    change(days[state.activeDay.clamp(0, days.length - 1)]);
    return days;
  }

  /// Quita un lugar del día activo.
  void removeAt(int index) {
    state = state.copyWith(days: _withActiveDay((s) => s.removeAt(index)));
  }

  /// Reordena los lugares del día activo.
  void reorder(int oldIndex, int newIndex) {
    state = state.copyWith(
      days: _withActiveDay((stops) {
        if (newIndex > oldIndex) newIndex -= 1;
        final item = stops.removeAt(oldIndex);
        stops.insert(newIndex, item);
      }),
    );
  }

  /// Agrega un lugar al día activo. Un lugar no se repite en el itinerario.
  void add(PlannerPlace place) {
    if (state.allPlaces.contains(place)) return;
    state = state.copyWith(days: _withActiveDay((s) => s.add(place)));
  }

  /// Cambia el día que se está viendo.
  void setActiveDay(int day) {
    final count = state.dayCount;
    if (count == 0) return;
    state = state.copyWith(activeDay: day.clamp(0, count - 1));
  }

  /// Agrega un día vacío al final y lo deja activo.
  void addDay() {
    final days = state.days;
    if (days == null || days.length >= maxDays) return;
    state = state.copyWith(
      days: [...days, <PlannerPlace>[]],
      activeDay: days.length,
    );
  }

  /// Elimina un día con sus lugares. Siempre queda al menos un día.
  void removeDay(int day) {
    final days = state.days;
    if (days == null || days.length <= 1 || day < 0 || day >= days.length) {
      return;
    }
    final next = [...days]..removeAt(day);
    state = state.copyWith(
      days: next,
      activeDay: state.activeDay.clamp(0, next.length - 1),
    );
  }

  /// Vuelve al formulario. Conserva tiempo, intereses y punto de partida.
  void reset() {
    state = state.copyWith(
      clearDays: true,
      clearSaved: true,
      clearError: true,
      pendingSave: false,
    );
  }

  void setPendingSave(bool value) => state = state.copyWith(pendingSave: value);

  /// Abre un itinerario guardado para verlo o editarlo.
  Future<SavedItineraryDetail> loadSaved(String itineraryId) async {
    final detail = await _ref
        .read(itineraryRepositoryProvider)
        .getDetail(itineraryId);

    // La hora de inicio se deduce de la hora planificada del primer lugar.
    var start = state.startMinute;
    final first = detail.firstPlannedMinute;
    if (first != null && detail.stops.isNotEmpty) {
      final p = detail.stops.first;
      final travel = ItineraryPlanner.travelMinutes(
        ItineraryPlanner.coyhaique.latitude,
        ItineraryPlanner.coyhaique.longitude,
        p.latitude,
        p.longitude,
      );
      start = (first - travel).clamp(0, 24 * 60 - 1);
    }

    state = state.copyWith(
      days: detail.days,
      activeDay: 0,
      origin: ItineraryPlanner.coyhaique,
      useMyLocation: false,
      locationFallback: false,
      startMinute: start,
      savedItineraryId: detail.id,
      savedOwnerId: detail.ownerId,
      savedName: detail.name,
      clearError: true,
    );
    ensureCandidates();
    return detail;
  }

  /// Guarda la propuesta. Crea un itinerario nuevo o actualiza el que se está
  /// editando, si pertenece al usuario actual.
  Future<void> save(String name) async {
    final user = _ref.read(authUserProvider).valueOrNull;
    if (user == null) throw const ItineraryAuthRequiredException();

    // `position` es único en todo el itinerario: se numera de corrido
    // recorriendo los días en orden. Los días vacíos no guardan filas.
    final items = <ItineraryItemInput>[];
    for (var day = 0; day < state.dayCount; day++) {
      for (final stop in state.scheduleOf(day).stops) {
        items.add(
          ItineraryItemInput(
            placeId: stop.place.id,
            position: items.length,
            plannedMinute: stop.arrivalMinute,
            dayIndex: day + 1,
          ),
        );
      }
    }

    state = state.copyWith(isSaving: true);
    try {
      final repository = _ref.read(itineraryRepositoryProvider);
      final existing = state.savedItineraryId;
      String id;
      if (existing != null && state.savedOwnerId == user.id) {
        await repository.update(
          itineraryId: existing,
          name: name,
          items: items,
        );
        id = existing;
      } else {
        id = await repository.create(name: name, items: items);
      }
      state = state.copyWith(
        isSaving: false,
        savedItineraryId: id,
        savedOwnerId: user.id,
        savedName: name.trim(),
        pendingSave: false,
      );
      _ref.invalidate(savedItinerariesProvider);
    } catch (_) {
      state = state.copyWith(isSaving: false);
      rethrow;
    }
  }
}
