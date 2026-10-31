import 'dart:async';
import 'dart:io';

import 'package:coyhaique_basecamp_pt/features/authentication/data/auth_error_messages.dart';
import 'package:coyhaique_basecamp_pt/features/authentication/data/auth_validators.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// HU-16 y RNF-13: los errores de cuenta se muestran con mensajes claros y
/// nunca con el texto técnico de la excepción.
void main() {
  group('sin conexión', () {
    final cases = <Object>[
      const SocketException('Failed host lookup: xyz.supabase.co'),
      TimeoutException('timeout'),
      AuthException(
        'ClientException with SocketException: Failed host lookup: '
        "'xyz.supabase.co' (OS Error: No address associated with hostname, errno = 7)",
      ),
    ];

    for (final error in cases) {
      test('${error.runtimeType} se reconoce como falta de conexión', () {
        expect(isNetworkError(error), isTrue);
        final message = authErrorMessage(error);
        expect(message, contains('No hay conexión'));
        expect(message.toLowerCase(), isNot(contains('exception')));
      });
    }
  });

  test('credenciales incorrectas', () {
    final error = AuthException('Invalid login credentials', code: 'invalid_credentials');
    expect(isNetworkError(error), isFalse);
    expect(authErrorMessage(error), 'Correo o contraseña incorrectos.');
  });

  test('un error desconocido no muestra el texto técnico', () {
    final message = authErrorMessage(AuthException('unexpected_failure xyz'));
    expect(message, isNot(contains('xyz')));
  });

  test('mensajes en inglés', () {
    expect(
      authErrorMessage(const SocketException('x'), isSpanish: false),
      startsWith('There is no Internet connection'),
    );
  });

  group('validaciones', () {
    test('contraseña: 8 caracteres con letras y números', () {
      expect(AuthValidators.isValidPassword('abc12345'), isTrue);
      expect(AuthValidators.isValidPassword('abcdefgh'), isFalse);
      expect(AuthValidators.isValidPassword('12345678'), isFalse);
      expect(AuthValidators.isValidPassword('ab1'), isFalse);
    });

    test('correo', () {
      expect(AuthValidators.isValidEmail('ana@correo.cl'), isTrue);
      expect(AuthValidators.isValidEmail('ana@correo'), isFalse);
    });

    test('código de recuperación de 6 a 8 dígitos', () {
      expect(AuthValidators.isValidCode('123456'), isTrue);
      expect(AuthValidators.isValidCode('12345678'), isTrue);
      expect(AuthValidators.isValidCode('12a456'), isFalse);
      expect(AuthValidators.isValidCode('12345'), isFalse);
    });
  });
}
