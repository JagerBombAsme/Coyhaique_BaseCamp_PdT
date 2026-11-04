import 'package:supabase_flutter/supabase_flutter.dart';

/// Acceso a Supabase Auth (HU-16).
///
/// Cada llamada tiene un tiempo máximo de 15 s (RNF-13): sin conexión o con
/// mala señal, la pantalla recibe un error y muestra un mensaje claro en vez
/// de quedarse cargando.
class AuthRepository {
  const AuthRepository(this._client);

  final SupabaseClient _client;

  static const Duration _timeout = Duration(seconds: 15);

  User? get currentUser => _client.auth.currentUser;

  Session? get currentSession => _client.auth.currentSession;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _client.auth
        .signInWithPassword(email: email.trim(), password: password)
        .timeout(_timeout);
  }

  /// Crea la cuenta con correo y contraseña; no se piden otros datos.
  /// Si el proyecto exige confirmar el correo, la respuesta no trae sesión.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) {
    return _client.auth
        .signUp(email: email.trim(), password: password)
        .timeout(_timeout);
  }

  /// Confirma la cuenta con el código del correo de registro. Si es correcto,
  /// Supabase inicia la sesión. Requiere que la plantilla «Confirm signup»
  /// incluya {{ .Token }}; así no se depende de la Site URL ni de enlaces
  /// profundos (el enlace por defecto abre http://localhost:3000).
  Future<AuthResponse> verifySignUpCode({
    required String email,
    required String code,
  }) {
    return _client.auth
        .verifyOTP(email: email.trim(), token: code.trim(), type: OtpType.signup)
        .timeout(_timeout);
  }

  /// Reenvía el correo de confirmación de la cuenta.
  Future<void> resendSignUpCode({required String email}) {
    return _client.auth
        .resend(type: OtpType.signup, email: email.trim())
        .timeout(_timeout);
  }

  Future<void> signOut() {
    return _client.auth.signOut().timeout(_timeout);
  }

  /// Envía el correo de recuperación con un código de un solo uso.
  /// La plantilla «Reset Password» de Supabase debe incluir {{ .Token }}.
  Future<void> resetPassword({required String email}) {
    return _client.auth.resetPasswordForEmail(email.trim()).timeout(_timeout);
  }

  /// Valida el código de recuperación. Si es correcto, Supabase abre una
  /// sesión temporal que permite cambiar la contraseña.
  Future<AuthResponse> verifyRecoveryCode({
    required String email,
    required String code,
  }) {
    return _client.auth
        .verifyOTP(email: email.trim(), token: code.trim(), type: OtpType.recovery)
        .timeout(_timeout);
  }

  Future<UserResponse> updatePassword(String newPassword) {
    return _client.auth
        .updateUser(UserAttributes(password: newPassword))
        .timeout(_timeout);
  }
}
