import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/route_dto.dart';
import '../repository/route_repository.dart';

final routeRepositoryProvider = Provider<RouteRepository>((ref) {
  return RouteRepository();
});

final routesProvider = FutureProvider<List<RouteDto>>((ref) async {
  final repository = ref.read(routeRepositoryProvider);
  return repository.getRoutes();
});

final routeDetailProvider = FutureProvider.family<RouteDto?, String>((ref, id) async {
  final repository = ref.read(routeRepositoryProvider);
  final routes = await repository.getRoutes();
  for (final route in routes) {
    if (route.id == id) return route;
  }
  return null;
});
