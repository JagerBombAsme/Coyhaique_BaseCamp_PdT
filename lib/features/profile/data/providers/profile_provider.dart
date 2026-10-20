import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/auth/auth_user_provider.dart';
import '../models/profile_dto.dart';
import '../repository/profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});

final profileProvider = FutureProvider<ProfileDto?>((ref) async {
  // Esperamos el estado real de autenticación.
  final user = await ref.watch(authUserProvider.future);

  // Invitado.
  if (user == null) {
    return null;
  }

  final repository = ref.read(profileRepositoryProvider);

  return repository.getProfile(userId: user.id);
});
