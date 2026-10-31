import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/local/catalog_status_provider.dart';
import '../../../../core/models/category_model.dart';
import '../../../../core/providers/interests_provider.dart';
import '../../../../core/models/informational_content_dto.dart';
import '../models/place_dto.dart';
import '../repository/places_repository.dart';

final placesRepositoryProvider =
    Provider<PlacesRepository>((ref) {
  return PlacesRepository(
    localDb: ref.read(catalogLocalDbProvider),
    onDataSource: (usingOfflineData) => ref
        .read(catalogStatusProvider.notifier)
        .setUsingOfflineData(usingOfflineData),
  );
});

/// Todas las categorías activas desde categories_v2.
final categoriesProvider =
    FutureProvider<List<CategoryModel>>((ref) async {
  final repository =
      ref.read(placesRepositoryProvider);

  return repository.getCategories();
});

/// Lugares / atractivos.
final placesProvider =
    FutureProvider<List<PlaceDto>>((ref) async {
  final repository =
      ref.read(placesRepositoryProvider);

  return repository.getPlaces();
});

/// Actividades.
final activitiesProvider =
    FutureProvider<List<PlaceDto>>((ref) async {
  final repository =
      ref.read(placesRepositoryProvider);

  return repository.getActivities();
});

/// Lugares por categoría.
///
/// Puede recibir:
/// - UUID de categories_v2
/// - slug
/// - group_type
final placesByCategoryProvider =
    FutureProvider.family<List<PlaceDto>, String>(
  (ref, categoryIdOrSlug) async {
    final repository =
        ref.read(placesRepositoryProvider);

    return repository.getPlacesByCategory(
      categoryIdOrSlug,
    );
  },
);

/// Detalle HU-02.
final placeDetailProvider =
    FutureProvider.family<PlaceDto?, String>(
  (ref, id) async {
    final repository =
        ref.read(placesRepositoryProvider);

    return repository.getPlaceById(id);
  },
);

/// Contenido informativo.
final informationalContentProvider =
    FutureProvider.family<
        List<InformationalContentDto>,
        String?>(
  (ref, contentType) async {
    final repository =
        ref.read(placesRepositoryProvider);

    return repository.getInformationalContent(
      contentType: contentType,
    );
  },
);

/// Lista dinámica de group_type existentes.
///
/// Con la BDD actual debería obtener:
///
/// actividad
/// alojamiento
/// atractivo
/// gastronomia
/// servicio
/// transporte
final groupTypesProvider =
    FutureProvider<List<String>>((ref) async {
  final categories =
      await ref.watch(categoriesProvider.future);

  final groups = categories
      .where(
        (category) =>
            category.isActive &&
            category.groupType != null &&
            category.groupType!
                .trim()
                .isNotEmpty,
      )
      .map(
        (category) =>
            category.groupType!
                .trim()
                .toLowerCase(),
      )
      .toSet()
      .toList();

  groups.sort();

  return groups;
});

/// true cuando la base ya tiene la jerarquía de categorías
/// (migración 2026-10-30: principales + subcategorías con parent_id).
bool hasCategoryTree(List<CategoryModel> categories) =>
    categories.any((c) => c.parentId != null);

/// Cantidad de lugares y actividades activos por categoría.
final placeCountByCategoryProvider =
    FutureProvider<Map<String, int>>((ref) async {
  final results = await Future.wait([
    ref.watch(placesProvider.future),
    ref.watch(activitiesProvider.future),
  ]);

  final counts = <String, int>{};
  for (final place in [...results[0], ...results[1]]) {
    counts[place.categoryId] = (counts[place.categoryId] ?? 0) + 1;
  }
  return counts;
});

/// Categorías principales (Atractivos, Actividades y tours, Gastronomía,
/// Alojamiento, Transporte, Servicios), en su orden.
///
/// Si la base todavía no tiene la jerarquía, devuelve todas las activas,
/// como antes.
final mainCategoriesProvider =
    FutureProvider<List<CategoryModel>>((ref) async {
  final categories = await ref.watch(categoriesProvider.future);
  final active = categories.where((c) => c.isActive).toList();

  if (!hasCategoryTree(active)) return active;

  final parentIds = active.map((c) => c.parentId).whereType<String>().toSet();
  return active.where((c) => c.isMain && parentIds.contains(c.id)).toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
});

/// Intereses guardados que todavía corresponden a una categoría principal.
/// Descarta identificadores de categorías eliminadas o reorganizadas.
final validInterestsProvider = Provider<Set<String>>((ref) {
  final saved = ref.watch(interestsProvider);
  final mains = ref.watch(mainCategoriesProvider).valueOrNull;
  if (mains == null) return saved;
  final valid = mains.map((c) => c.id).toSet();
  return saved.where(valid.contains).toSet();
});

/// Subcategorías de un grupo (group_type), en su orden.
///
/// Con la jerarquía: solo subcategorías con al menos un lugar o actividad
/// (las vacías quedan ocultas hasta que se carguen datos). Sin la
/// jerarquía: todas las categorías activas del grupo, como antes.
///
/// Ejemplo: categoriesByGroupProvider('gastronomia') devuelve
/// Cafeterías, Restaurantes, Comida tradicional y patagónica.
final categoriesByGroupProvider =
    FutureProvider.family<List<CategoryModel>, String>(
  (ref, groupType) async {
    final categories = await ref.watch(categoriesProvider.future);
    final normalizedGroup = groupType.trim().toLowerCase();

    final inGroup = categories.where(
      (c) =>
          c.isActive &&
          c.groupType?.trim().toLowerCase() == normalizedGroup,
    );

    if (!hasCategoryTree(categories)) {
      return inGroup.toList()
        ..sort(
          (a, b) => a.nombreEs.toLowerCase().compareTo(b.nombreEs.toLowerCase()),
        );
    }

    Map<String, int> counts;
    try {
      counts = await ref.watch(placeCountByCategoryProvider.future);
    } catch (_) {
      counts = const {};
    }

    return inGroup
        .where((c) => !c.isMain)
        .where((c) => counts.isEmpty || (counts[c.id] ?? 0) > 0)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  },
);
