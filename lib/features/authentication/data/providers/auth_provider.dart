import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/supabase_provider.dart';
import '../repositories/auth_repository.dart';

final authRepositoryProvider =
    Provider<AuthRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);

  return AuthRepository(client);
});