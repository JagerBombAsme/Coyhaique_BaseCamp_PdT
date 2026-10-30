import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/local/catalog_status_provider.dart';
import '../../../../core/models/category_model.dart';
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

/// Obtiene las categorías pertenecientes
/// a un determinado group_type.
///
/// Ejemplo:
///
/// categoriesByGroupProvider('transporte')
///
/// devuelve:
/// - Bus interurbano
/// - Bus Rural e Interurbano
/// - Rent a Car
final categoriesByGroupProvider =
    FutureProvider.family<
        List<CategoryModel>,
        String>(
  (ref, groupType) async {
    final categories =
        await ref.watch(categoriesProvider.future);

    final normalizedGroup =
        groupType.trim().toLowerCase();

    final result = categories.where(
      (category) {
        final categoryGroup =
            category.groupType
                ?.trim()
                .toLowerCase();

        return category.isActive &&
            categoryGroup == normalizedGroup;
      },
    ).toList();

    result.sort(
      (a, b) => a.nombreEs
          .toLowerCase()
          .compareTo(
            b.nombreEs.toLowerCase(),
          ),
    );

    return result;
  },
);