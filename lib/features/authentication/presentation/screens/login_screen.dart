import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show TextInput;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/basecamp_tokens.dart';
import '../../../../core/widgets/auth_text_field.dart';
import '../../../../core/widgets/glass_auth_card.dart';
import '../../../../core/providers/language_provider.dart';
import '../widgets/auth_page_layout.dart';
import '/features/authentication/data/auth_error_messages.dart';
import '/features/authentication/data/auth_validators.dart';
import '/features/authentication/data/providers/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({
    super.key,
    this.onBack,
    this.onLogin,
    this.onSignUp,
    this.onForgotPassword,
  });

  final VoidCallback? onBack;
  final VoidCallback? onLogin;
  final VoidCallback? onSignUp;

  /// Recibe el correo escrito, para no tener que escribirlo de nuevo.
  final ValueChanged<String>? onForgotPassword;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _obscurePassword = true;
  bool _submitted = false;
  String? _errorMessage;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  String? _passwordError(String password, bool es) => password.isEmpty
      ? (es ? 'Ingresa tu contraseña.' : 'Enter your password.')
      : null;

  Future<void> _handleLogin(bool es) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _submitted = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // Los errores de cada campo se ven junto al campo (errorText).
    if (AuthValidators.emailError(email, es) != null ||
        _passwordError(password, es) != null) {
      return;
    }

    final success = await ref
        .read(authControllerProvider.notifier)
        .signIn(email: email, password: password);

    if (!mounted) return;

    if (success) {
      // Le avisa al sistema que el formulario terminó bien: el gestor de
      // contraseñas puede ofrecer guardar las credenciales.
      TextInput.finishAutofillContext();

      // La pantalla no decide a dónde navegar.
      // El router o pantalla padre manejará esa decisión.
      widget.onLogin?.call();

      return;
    }

    // Sin conexión, Supabase lanza AuthRetryableFetchException con el texto
    // «ClientException with SocketException: Failed host lookup». Se traduce
    // a un mensaje claro y nunca se muestra el texto técnico.
    final error = ref.read(authControllerProvider).error;

    setState(() {
      _errorMessage = error == null
          ? (es ? 'No fue posible iniciar sesión.' : 'Could not sign in.')
          : authErrorMessage(error, isSpanish: es);
    });
  }

  @override
  Widget build(BuildContext context) {
    final es = ref.watch(languageProvider).languageCode == 'es';
    final authState = ref.watch(authControllerProvider);

    final isLoading = authState.isLoading;

    final email = _emailController.text;
    final password = _passwordController.text;

    return Scaffold(
      backgroundColor: BcColors.ink,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AuthBackdrop(),

          SafeArea(
            child: Stack(
              children: [
                Positioned(
                  top: 14,
                  left: BcSpace.gutter,
                  child: AuthBackButton(
                    onPressed: isLoading ? null : widget.onBack,
                  ),
                ),

                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 76, 24, 22),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 380),
                      child: GlassAuthCard(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(22, 30, 24, 26),
                          child: AutofillGroup(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Semantics(
                                  header: true,
                                  child: Text(
                                    es ? 'BIENVENIDO' : 'WELCOME',
                                    style: BcText.display(
                                      42,
                                      color: BcColors.onPhoto,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 12),

                                Text(
                                  es
                                      ? 'Inicia sesión para continuar explorando Coyhaique Basecamp.'
                                      : 'Sign in to keep exploring Coyhaique Basecamp.',
                                  style: BcText.body(
                                    color: BcColors.onPhoto.withValues(
                                      alpha: 0.86,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 28),

                                AuthTextField(
                                  controller: _emailController,
                                  label: es ? 'Correo electrónico' : 'Email',
                                  keyboardType: TextInputType.emailAddress,
                                  prefixIcon: Icons.mail_outline_rounded,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [
                                    AutofillHints.username,
                                    AutofillHints.email,
                                  ],
                                  enabled: !isLoading,
                                  maxLength: 254,
                                  errorText: _submitted
                                      ? AuthValidators.emailError(email, es)
                                      : null,
                                  onChanged: (_) => setState(() {}),
                                ),

                                const SizedBox(height: 14),

                                AuthTextField(
                                  controller: _passwordController,
                                  label: es ? 'Contraseña' : 'Password',
                                  obscureText: _obscurePassword,
                                  prefixIcon: Icons.lock_outline_rounded,
                                  textInputAction: TextInputAction.done,
                                  autofillHints: const [AutofillHints.password],
                                  enabled: !isLoading,
                                  errorText: _submitted
                                      ? _passwordError(password, es)
                                      : null,
                                  onChanged: (_) => setState(() {}),
                                  onSubmitted: (_) => _handleLogin(es),
                                  suffixIcon: _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  suffixTooltip: _obscurePassword
                                      ? (es
                                            ? 'Mostrar contraseña'
                                            : 'Show password')
                                      : (es
                                            ? 'Ocultar contraseña'
                                            : 'Hide password'),
                                  onSuffixPressed: isLoading
                                      ? null
                                      : () {
                                          setState(() {
                                            _obscurePassword =
                                                !_obscurePassword;
                                          });
                                        },
                                ),

                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: isLoading
                                        ? null
                                        : () => widget.onForgotPassword?.call(
                                            _emailController.text.trim(),
                                          ),
                                    style: TextButton.styleFrom(
                                      foregroundColor: BcColors.glacier,
                                      minimumSize: const Size(48, 48),
                                    ),
                                    child: Text(
                                      es
                                          ? '¿Olvidaste tu contraseña?'
                                          : 'Forgot your password?',
                                      style: BcText.title(
                                        color: BcColors.glacier,
                                      ).copyWith(fontSize: 13),
                                    ),
                                  ),
                                ),

                                if (_errorMessage != null) ...[
                                  const SizedBox(height: 6),
                                  AuthInlineMessage(text: _errorMessage!),
                                ],

                                const SizedBox(height: 16),

                                AuthPrimaryAction(
                                  text: es ? 'Iniciar sesión' : 'Sign in',
                                  isLoading: isLoading,
                                  onPressed: () => _handleLogin(es),
                                ),

                                const SizedBox(height: 14),

                                Center(
                                  child: Wrap(
                                    alignment: WrapAlignment.center,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      Text(
                                        es
                                            ? '¿No tienes una cuenta? '
                                            : "Don't have an account? ",
                                        style: BcText.body(
                                          color: BcColors.onPhoto.withValues(
                                            alpha: 0.86,
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: isLoading
                                            ? null
                                            : widget.onSignUp,
                                        style: TextButton.styleFrom(
                                          foregroundColor: BcColors.glacier,
                                          minimumSize: const Size(48, 48),
                                        ),
                                        child: Text(
                                          es
                                              ? 'Crear cuenta'
                                              : 'Create account',
                                          style: BcText.title(
                                            color: BcColors.glacier,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 16),

                                Center(
                                  child: Text(
                                    'COYHAIQUE · BASECAMP',
                                    style: BcText.label(
                                      color: BcColors.onPhoto.withValues(
                                        alpha: 0.6,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
