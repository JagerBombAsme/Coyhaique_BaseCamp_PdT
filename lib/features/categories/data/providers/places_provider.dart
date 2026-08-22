import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/place_dto.dart';
import '../repository/places_repository.dart';

final placesRepositoryProvider = Provider<PlacesRepository>((ref) {
  return PlacesRepository();
});

final placesProvider = FutureProvider<List<PlaceDto>>((ref) async {
  final repository = ref.read(placesRepositoryProvider);
  return repository.getPlaces();
});

final placesByCategoryProvider = FutureProvider.family<List<PlaceDto>, String>((ref, categorySlug) async {
  final repository = ref.read(placesRepositoryProvider);
  return repository.getPlacesByCategory(categorySlug);
});

final placeDetailProvider = FutureProvider.family<PlaceDto?, String>((ref, id) async {
  final repository = ref.read(placesRepositoryProvider);
  return repository.getPlaceById(id);
});
