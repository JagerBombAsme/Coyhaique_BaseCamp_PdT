/// Validaciones de los formularios de cuenta (HU-16, RNF-10).
class AuthValidators {
  const AuthValidators._();

  static const int minPasswordLength = 8;

  static bool isValidEmail(String email) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.trim());

  /// Al menos 8 caracteres, con una letra y un número.
  static bool isValidPassword(String password) =>
      password.length >= minPasswordLength &&
      RegExp(r'[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]').hasMatch(password) &&
      RegExp(r'\d').hasMatch(password);

  /// Código de recuperación de Supabase: 6 a 8 dígitos.
  static bool isValidCode(String code) => RegExp(r'^\d{6,8}$').hasMatch(code.trim());

  static String? emailError(String email, bool es) {
    if (email.trim().isEmpty) return es ? 'Ingresa tu correo.' : 'Enter your email.';
    if (!isValidEmail(email)) {
      return es ? 'Ingresa un correo electrónico válido.' : 'Enter a valid email address.';
    }
    return null;
  }

  static String? passwordError(String password, bool es) {
    if (password.isEmpty) return es ? 'Ingresa una contraseña.' : 'Enter a password.';
    if (!isValidPassword(password)) {
      return es
          ? 'Usa al menos 8 caracteres, con letras y números.'
          : 'Use at least 8 characters, with letters and numbers.';
    }
    return null;
  }

  static String? confirmError(String password, String confirm, bool es) {
    if (confirm != password) {
      return es ? 'Las contraseñas no coinciden.' : 'Passwords do not match.';
    }
    return null;
  }
}
