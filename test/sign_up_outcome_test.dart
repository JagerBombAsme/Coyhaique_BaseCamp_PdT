import 'package:coyhaique_basecamp_pt/features/authentication/data/providers/auth_controller.dart';
import 'package:flutter_test/flutter_test.dart';

/// BUG-007 / CP-PF16-03: el registro con un correo ya registrado debe
/// distinguirse de una cuenta nueva que espera confirmación.
void main() {
  group('signUpOutcomeFor', () {
    test('con sesión: cuenta creada e iniciada', () {
      expect(
        signUpOutcomeFor(hasSession: true, identities: const []),
        SignUpOutcome.signedIn,
      );
    });

    test('sin sesión y con una identidad: cuenta nueva que espera confirmación', () {
      expect(
        signUpOutcomeFor(hasSession: false, identities: [Object()]),
        SignUpOutcome.confirmationRequired,
      );
    });

    test('sin sesión y sin identidades: el correo ya estaba registrado', () {
      expect(
        signUpOutcomeFor(hasSession: false, identities: const []),
        SignUpOutcome.alreadyRegistered,
      );
    });

    test('sin datos de identidades: se mantiene el flujo de confirmación', () {
      expect(
        signUpOutcomeFor(hasSession: false, identities: null),
        SignUpOutcome.confirmationRequired,
      );
    });
  });
}
