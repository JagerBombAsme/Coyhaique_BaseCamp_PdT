import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_provider.dart';

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(
  AuthController.new,
);

/// Resultado del registro.
enum SignUpOutcome {
  /// La cuenta quedó creada y con sesión iniciada.
  signedIn,

  /// Supabase envió un correo para confirmar la cuenta antes de entrar.
  confirmationRequired,
}

/// Lógica de autenticación (HU-16). Cada método deja el error en `state`
/// para que la pantalla lo traduzca con `authErrorMessage`.
class AuthController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<T?> _run<T>(Future<T> Function() action) async {
    state = const AsyncLoading();
    try {
      final result = await action();
      state = const AsyncData(null);
      return result;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return null;
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    final response = await _run(
      () => ref.read(authRepositoryProvider).signIn(email: email, password: password),
    );
    return response?.user != null;
  }

  /// Devuelve null si falló; el error queda en `state`.
  Future<SignUpOutcome?> signUp({
    required String email,
    required String password,
  }) async {
    final response = await _run(
      () => ref.read(authRepositoryProvider).signUp(email: email, password: password),
    );
    if (response == null) return null;
    return response.session != null
        ? SignUpOutcome.signedIn
        : SignUpOutcome.confirmationRequired;
  }

  /// Confirma la cuenta con el código del correo; deja la sesión iniciada.
  Future<bool> verifySignUpCode({
    required String email,
    required String code,
  }) async {
    final response = await _run(
      () => ref.read(authRepositoryProvider).verifySignUpCode(email: email, code: code),
    );
    return response?.session != null;
  }

  Future<bool> resendSignUpCode(String email) async {
    final ok = await _run(() async {
      await ref.read(authRepositoryProvider).resendSignUpCode(email: email);
      return true;
    });
    return ok == true;
  }

  Future<bool> requestPasswordReset(String email) async {
    final ok = await _run(() async {
      await ref.read(authRepositoryProvider).resetPassword(email: email);
      return true;
    });
    return ok == true;
  }

  /// Valida el código del correo y guarda la contraseña nueva. Al terminar,
  /// el usuario queda con sesión iniciada.
  Future<bool> resetPasswordWithCode({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final ok = await _run(() async {
      final repository = ref.read(authRepositoryProvider);
      await repository.verifyRecoveryCode(email: email, code: code);
      await repository.updatePassword(newPassword);
      return true;
    });
    return ok == true;
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    try {
      await ref.read(authRepositoryProvider).signOut();
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}
