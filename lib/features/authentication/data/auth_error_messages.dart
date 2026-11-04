import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Traduce los errores de autenticación a mensajes para el usuario.
///
/// Nunca muestra el texto técnico de la excepción (por ejemplo
/// «ClientException with SocketException: Failed host lookup»): ese texto no
/// le sirve al usuario y expone detalles internos (MASVS-PLATFORM, RNF-13).
/// El detalle se escribe solo en la consola de depuración.
String authErrorMessage(Object error, {bool isSpanish = true}) {
  if (kDebugMode) debugPrint('[auth] ${error.runtimeType}: $error');

  String t(String es, String en) => isSpanish ? es : en;

  if (isNetworkError(error)) {
    return t(
      'No hay conexión a Internet. Revisa tu señal o Wi-Fi e intenta nuevamente. Puedes seguir usando la información descargada sin iniciar sesión.',
      'There is no Internet connection. Check your signal or Wi-Fi and try again. You can keep using the downloaded information without signing in.',
    );
  }

  if (error is AuthWeakPasswordException) {
    return t(
      'La contraseña es muy débil. Usa al menos 8 caracteres, con letras y números.',
      'The password is too weak. Use at least 8 characters, with letters and numbers.',
    );
  }

  if (error is AuthException) {
    final code = error.code?.toLowerCase() ?? '';
    final message = error.message.toLowerCase();
    bool has(String value) => code == value || message.contains(value);

    if (has('invalid_credentials') || message.contains('invalid login credentials')) {
      return t('Correo o contraseña incorrectos.', 'Incorrect email or password.');
    }
    if (has('email_not_confirmed') || message.contains('email not confirmed')) {
      return t(
        'Debes confirmar tu correo. Revisa tu bandeja de entrada y la carpeta de spam.',
        'You must confirm your email. Check your inbox and spam folder.',
      );
    }
    if (has('user_already_exists') ||
        has('email_exists') ||
        message.contains('already registered')) {
      return t(
        'Ya existe una cuenta con este correo. Inicia sesión o recupera tu contraseña.',
        'An account with this email already exists. Sign in or reset your password.',
      );
    }
    if (has('otp_expired') ||
        message.contains('token has expired') ||
        (message.contains('invalid') && message.contains('otp'))) {
      return t(
        'El código no es válido o venció. Solicita uno nuevo.',
        'The code is invalid or has expired. Request a new one.',
      );
    }
    if (has('same_password')) {
      return t(
        'La nueva contraseña debe ser distinta de la anterior.',
        'The new password must be different from the previous one.',
      );
    }
    if (has('weak_password') || message.contains('password should be')) {
      return t(
        'La contraseña es muy débil. Usa al menos 8 caracteres, con letras y números.',
        'The password is too weak. Use at least 8 characters, with letters and numbers.',
      );
    }
    if (has('email_address_invalid') || message.contains('invalid format')) {
      return t('El correo electrónico no es válido.', 'The email address is not valid.');
    }
    if (has('over_request_rate_limit') ||
        has('over_email_send_rate_limit') ||
        message.contains('rate limit') ||
        message.contains('too many requests') ||
        error.statusCode == '429') {
      return t(
        'Demasiados intentos. Espera unos minutos e intenta nuevamente.',
        'Too many attempts. Wait a few minutes and try again.',
      );
    }
    if (has('signup_disabled')) {
      return t(
        'El registro de cuentas no está disponible en este momento.',
        'Sign up is not available right now.',
      );
    }
    if (error.statusCode != null && error.statusCode!.startsWith('5')) {
      return t(
        'El servicio no está disponible en este momento. Intenta más tarde.',
        'The service is not available right now. Try again later.',
      );
    }
  }

  return t(
    'No fue posible completar la operación. Intenta nuevamente.',
    'The operation could not be completed. Try again.',
  );
}

/// true si el error se debe a falta de conexión o a que el servidor no
/// respondió a tiempo.
///
/// Supabase envuelve los errores de red en [AuthRetryableFetchException]
/// (que es un [AuthException]); por eso el inicio de sesión sin conexión
/// mostraba el texto técnico del ClientException.
bool isNetworkError(Object error) {
  if (error is SocketException ||
      error is TimeoutException ||
      error is HandshakeException ||
      error is HttpException) {
    return true;
  }
  if (error is AuthRetryableFetchException) return true;

  final text = error.toString().toLowerCase();
  const hints = [
    'socketexception',
    'failed host lookup',
    'clientexception',
    'connection refused',
    'connection reset',
    'connection closed',
    'network is unreachable',
    'no address associated',
    'handshakeexception',
    'timed out',
  ];
  return hints.any(text.contains);
}
