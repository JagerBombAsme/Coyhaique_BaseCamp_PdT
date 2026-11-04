/// Enlaces legales de la aplicación (HU-19, Google Play).
///
/// La política de privacidad y los términos se publicarán en la landing page
/// (HU-23, GitHub Pages). Mientras la URL esté vacía, las pantallas no
/// muestran el enlace. Se puede definir al compilar con
/// --dart-define=PRIVACY_POLICY_URL=https://...
abstract final class LegalLinks {
  static const String privacyPolicyUrl = String.fromEnvironment('PRIVACY_POLICY_URL');

  static const String termsUrl = String.fromEnvironment('TERMS_URL');

  static bool get hasPrivacyPolicy => privacyPolicyUrl.isNotEmpty;
}
