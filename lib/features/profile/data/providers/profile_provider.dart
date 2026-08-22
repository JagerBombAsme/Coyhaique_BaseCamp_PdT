import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/profile_dto.dart';
import '../repository/profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});

final profileProvider = FutureProvider<ProfileDto>((ref) async {
  final repository = ref.read(profileRepositoryProvider);
  return repository.getProfile();
});
