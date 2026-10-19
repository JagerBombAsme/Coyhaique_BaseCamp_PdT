import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_provider.dart';

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(
  AuthController.new,
);

class AuthController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> signIn({required String email, required String password}) async {
    state = const AsyncLoading();

    try {
      final repository = ref.read(authRepositoryProvider);

      final response = await repository.signIn(
        email: email,
        password: password,
      );

      state = const AsyncData(null);

      return response.user != null;
    } on AuthException catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }

  Future<void> signOut() async {
    state = const AsyncLoading();

    try {
      final repository = ref.read(authRepositoryProvider);

      await repository.signOut();

      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);

      rethrow;
    }
  }
}
