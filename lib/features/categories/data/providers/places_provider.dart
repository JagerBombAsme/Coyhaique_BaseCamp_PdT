import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/category_model.dart';
import '../models/place_dto.dart';
import '../repository/places_repository.dart';

final placesRepositoryProvider = Provider<PlacesRepository>((ref) {
  return PlacesRepository();
});

/// Proveedor para categorías desde categories_v2
final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
  final repository = ref.read(placesRepositoryProvider);
  return repository.getCategories();
});

/// Proveedor para lugares/atractivos desde places_v2 (kind = 'place')
final placesProvider = FutureProvider<List<PlaceDto>>((ref) async {
  final repository = ref.read(placesRepositoryProvider);
  return repository.getPlaces();
});

/// Proveedor para actividades/tours desde places_v2 (kind = 'activity')
final activitiesProvider = FutureProvider<List<PlaceDto>>((ref) async {
  final repository = ref.read(placesRepositoryProvider);
  return repository.getActivities();
});

/// Proveedor para filtrar por category_id o category_slug
final placesByCategoryProvider = FutureProvider.family<List<PlaceDto>, String>((ref, categoryIdOrSlug) async {
  final repository = ref.read(placesRepositoryProvider);
  return repository.getPlacesByCategory(categoryIdOrSlug);
});

/// Proveedor para detalle de atractivo por ID
final placeDetailProvider = FutureProvider.family<PlaceDto?, String>((ref, id) async {
  final repository = ref.read(placesRepositoryProvider);
  return repository.getPlaceById(id);
});
