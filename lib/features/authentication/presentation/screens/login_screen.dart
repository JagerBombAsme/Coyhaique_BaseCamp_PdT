import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/auth_text_field.dart';
import '../../../../core/widgets/glass_auth_card.dart';
import '../../../../core/providers/language_provider.dart';
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
  bool _rememberMe = false;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Debes ingresar correo y contraseña.');
      return;
    }

    if (!AuthValidators.isValidEmail(email)) {
      _showMessage('Ingresa un correo electrónico válido.');
      return;
    }

    final success = await ref
        .read(authControllerProvider.notifier)
        .signIn(email: email, password: password);

    if (!mounted) return;

    if (success) {
      _showMessage('Inicio de sesión correcto.');

      // La pantalla no decide a dónde navegar.
      // El router o pantalla padre manejará esa decisión.
      widget.onLogin?.call();

      return;
    }

    // Sin conexión, Supabase lanza AuthRetryableFetchException con el texto
    // «ClientException with SocketException: Failed host lookup». Se traduce
    // a un mensaje claro y nunca se muestra el texto técnico.
    final error = ref.read(authControllerProvider).error;
    final isSpanish = ref.read(languageProvider).languageCode == 'es';

    _showMessage(
      error == null
          ? 'No fue posible iniciar sesión.'
          : authErrorMessage(error, isSpanish: isSpanish),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    final isLoading = authState.isLoading;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/cultura_gaucho.jpg',
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) {
              return const ColoredBox(
                color: Color(0xFF1B2421),
                child: Center(
                  child: Icon(
                    Icons.landscape_outlined,
                    size: 72,
                    color: Colors.white30,
                  ),
                ),
              );
            },
          ),

          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x22000000),
                  Color(0x44000000),
                  Color(0x77000000),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Stack(
              children: [
                Positioned(
                  top: 14,
                  left: 18,
                  child: _BackButton(
                    onPressed: isLoading ? null : widget.onBack,
                  ),
                ),

                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 350),
                      child: GlassAuthCard(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(22, 34, 28, 30),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Bienvenido',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 34,
                                  height: 1.05,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -1.0,
                                ),
                              ),

                              const SizedBox(height: 10),

                              Text(
                                'Inicia sesión para continuar explorando Coyhaique Basecamp.',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.82),
                                  fontSize: 15,
                                  height: 1.45,
                                ),
                              ),

                              const SizedBox(height: 30),

                              AuthTextField(
                                controller: _emailController,
                                label: 'Correo electrónico',
                                keyboardType: TextInputType.emailAddress,
                                prefixIcon: Icons.person_outline_rounded,
                              ),

                              const SizedBox(height: 14),

                              AuthTextField(
                                controller: _passwordController,
                                label: 'Contraseña',
                                obscureText: _obscurePassword,
                                prefixIcon: Icons.lock_outline_rounded,
                                suffixIcon: _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                onSuffixPressed: isLoading
                                    ? null
                                    : () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                              ),

                              const SizedBox(height: 16),

                              Row(
                                children: [
                                  _RememberCheckbox(
                                    value: _rememberMe,
                                    enabled: !isLoading,
                                    onChanged: (value) {
                                      setState(() {
                                        _rememberMe = value;
                                      });
                                    },
                                  ),

                                  const SizedBox(width: 10),

                                  Expanded(
                                    child: Text(
                                      'Recordarme',
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.88,
                                        ),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),

                                  TextButton(
                                    onPressed: isLoading
                                        ? null
                                        : () => widget.onForgotPassword?.call(
                                              _emailController.text.trim(),
                                            ),
                                    child: Text(
                                      '¿Olvidaste tu contraseña?',
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.72,
                                        ),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 22),

                              _AuthPrimaryButton(
                                text: isLoading
                                    ? 'Ingresando...'
                                    : 'Iniciar sesión',
                                isLoading: isLoading,
                                onPressed: isLoading ? null : _handleLogin,
                              ),

                              const SizedBox(height: 18),

                              Center(
                                child: Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      '¿No tienes una cuenta? ',
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.72,
                                        ),
                                        fontSize: 14,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: isLoading
                                          ? null
                                          : widget.onSignUp,
                                      child: const Text(
                                        'Crear cuenta',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 22),

                              Center(
                                child: Text(
                                  'Coyhaique Basecamp',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.48),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.5,
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthPrimaryButton extends StatelessWidget {
  const _AuthPrimaryButton({
    required this.text,
    required this.onPressed,
    required this.isLoading,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF7D9A58),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(
            0xFF7D9A58,
          ).withValues(alpha: 0.65),
          disabledForegroundColor: Colors.white70,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.white,
                ),
              )
            : Text(text),
      ),
    );
  }
}

class _RememberCheckbox extends StatelessWidget {
  const _RememberCheckbox({
    required this.value,
    required this.onChanged,
    required this.enabled,
  });

  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? () => onChanged(!value) : null,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: value
              ? const Color(0xFF7D9A58)
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: value
                ? const Color(0xFF91AF6A)
                : Colors.white.withValues(alpha: 0.30),
          ),
        ),
        child: value
            ? const Icon(Icons.check_rounded, size: 17, color: Colors.white)
            : null,
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Material(
          color: Colors.black.withValues(alpha: 0.20),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(16),
            child: const SizedBox(
              width: 48,
              height: 48,
              child: Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
