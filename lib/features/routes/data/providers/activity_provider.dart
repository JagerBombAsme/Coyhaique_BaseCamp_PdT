import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/supabase_provider.dart';
import '../models/activity_dto.dart';
import '../repository/activity_repository.dart';

final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  return ActivityRepository(client: ref.watch(supabaseClientProvider));
});

final activitiesProvider = FutureProvider<List<ActivityDto>>((ref) async {
  final repository = ref.read(activityRepositoryProvider);

  return repository.getActivities();
});
