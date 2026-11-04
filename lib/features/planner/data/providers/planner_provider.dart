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

final plannerProvider =
    StateNotifierProvider<PlannerNotifier, PlannerState>((ref) {
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
    this.stops,
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

  /// null mientras no se ha generado ni cargado una propuesta.
  final List<PlannerPlace>? stops;

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

  bool get hasProposal => stops != null;

  ItinerarySchedule get schedule => ItineraryPlanner.schedule(
        stops: stops ?? const [],
        origin: origin,
        startMinute: startMinute,
      );

  PlannerState copyWith({
    int? startMinute,
    int? availableMinutes,
    bool? useMyLocation,
    PlannerOrigin? origin,
    List<PlannerPlace>? stops,
    bool clearStops = false,
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
      stops: clearStops ? null : (stops ?? this.stops),
      candidates: candidates ?? this.candidates,
      isGenerating: isGenerating ?? this.isGenerating,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      locationFallback: locationFallback ?? this.locationFallback,
      savedItineraryId:
          clearSaved ? null : (savedItineraryId ?? this.savedItineraryId),
      savedOwnerId: clearSaved ? null : (savedOwnerId ?? this.savedOwnerId),
      savedName: clearSaved ? null : (savedName ?? this.savedName),
      pendingSave: pendingSave ?? this.pendingSave,
    );
  }
}

class PlannerNotifier extends StateNotifier<PlannerState> {
  PlannerNotifier(this._ref) : super(const PlannerState());

  final Ref _ref;

  void setStartMinute(int minute) => state = state.copyWith(startMinute: minute);

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
    return unique.values.toList()
      ..sort((a, b) => a.nameEs.compareTo(b.nameEs));
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
        stops: stops,
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

  void removeAt(int index) {
    final stops = [...?state.stops]..removeAt(index);
    state = state.copyWith(stops: stops);
  }

  void reorder(int oldIndex, int newIndex) {
    final stops = [...?state.stops];
    if (newIndex > oldIndex) newIndex -= 1;
    final item = stops.removeAt(oldIndex);
    stops.insert(newIndex, item);
    state = state.copyWith(stops: stops);
  }

  void add(PlannerPlace place) {
    final stops = [...?state.stops];
    if (stops.contains(place)) return;
    stops.add(place);
    state = state.copyWith(stops: stops);
  }

  /// Vuelve al formulario. Conserva tiempo, intereses y punto de partida.
  void reset() {
    state = state.copyWith(
      clearStops: true,
      clearSaved: true,
      clearError: true,
      pendingSave: false,
    );
  }

  void setPendingSave(bool value) => state = state.copyWith(pendingSave: value);

  /// Abre un itinerario guardado para verlo o editarlo.
  Future<SavedItineraryDetail> loadSaved(String itineraryId) async {
    final detail =
        await _ref.read(itineraryRepositoryProvider).getDetail(itineraryId);

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
      stops: detail.stops,
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

    final schedule = state.schedule;
    final items = [
      for (var i = 0; i < schedule.stops.length; i++)
        ItineraryItemInput(
          placeId: schedule.stops[i].place.id,
          position: i,
          plannedMinute: schedule.stops[i].arrivalMinute,
        ),
    ];

    state = state.copyWith(isSaving: true);
    try {
      final repository = _ref.read(itineraryRepositoryProvider);
      final existing = state.savedItineraryId;
      String id;
      if (existing != null && state.savedOwnerId == user.id) {
        await repository.update(itineraryId: existing, name: name, items: items);
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
