import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/activity_dto.dart';
import '../repository/activity_repository.dart';

final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  return ActivityRepository();
});

final activitiesProvider = FutureProvider<List<ActivityDto>>((ref) async {
  final repository = ref.read(activityRepositoryProvider);

  return repository.getActivities();
});
