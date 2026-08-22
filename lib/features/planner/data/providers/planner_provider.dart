import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/planner_destination_dto.dart';
import '../repository/planner_repository.dart';

final plannerRepositoryProvider = Provider<PlannerRepository>((ref) {
  return PlannerRepository();
});

final plannerDestinationsProvider = FutureProvider<List<PlannerDestinationDto>>((ref) async {
  final repository = ref.read(plannerRepositoryProvider);
  return repository.getDestinations();
});
