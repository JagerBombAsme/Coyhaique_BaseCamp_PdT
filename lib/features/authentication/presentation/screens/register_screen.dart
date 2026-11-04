import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/legal_links.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/widgets/auth_text_field.dart';
import '../../data/auth_error_messages.dart';
import '../../data/auth_validators.dart';
import '../../data/providers/auth_controller.dart';
import '../widgets/auth_page_layout.dart';

/// Crear cuenta (HU-16).
///
/// Solo pide correo y contraseña: son los datos necesarios para iniciar
/// sesión y guardar itinerarios (Ley 19.628, minimización de datos). La cuenta
/// es opcional: las funciones de consulta no la exigen.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({
    super.key,
    this.onBack,
    this.onSignedIn,
    this.onGoToLogin,
    this.onForgotPassword,
    this.confirmEmail,
  });

  /// Si viene, abre directamente el paso de confirmación para ese correo
  /// (por ejemplo, desde el login cuando la cuenta aún no está confirmada).
  final String? confirmEmail;

  final VoidCallback? onBack;

  /// La cuenta quedó creada (o confirmada) con sesión iniciada.
  final VoidCallback? onSignedIn;
  final VoidCallback? onGoToLogin;
  final VoidCallback? onForgotPassword;

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscure = true;
  bool _accepted = false;
  bool _submitted = false;
  String? _errorMessage;

  /// Correo al que se envió el código de confirmación.
  late String? _confirmationSentTo = widget.confirmEmail;

  final _codeController = TextEditingController();
  bool _codeSubmitted = false;
  String? _codeMessage;
  bool _codeMessageIsError = true;
  int _cooldown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit(bool es) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _submitted = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    final hasErrors = AuthValidators.emailError(email, es) != null ||
        AuthValidators.passwordError(password, es) != null ||
        AuthValidators.confirmError(password, confirm, es) != null;
    if (hasErrors) return;

    if (!_accepted) {
      setState(() {
        _errorMessage = es
            ? 'Para crear la cuenta debes aceptar el uso de tu correo.'
            : 'To create the account you must accept the use of your email.';
      });
      return;
    }

    final outcome = await ref
        .read(authControllerProvider.notifier)
        .signUp(email: email, password: password);

    if (!mounted) return;

    switch (outcome) {
      case SignUpOutcome.signedIn:
        widget.onSignedIn?.call();
      case SignUpOutcome.confirmationRequired:
        setState(() => _confirmationSentTo = email);
        _startCooldown();
      case null:
        final error = ref.read(authControllerProvider).error;
        setState(() {
          _errorMessage = error == null
              ? (es ? 'No fue posible crear la cuenta.' : 'The account could not be created.')
              : authErrorMessage(error, isSpanish: es);
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final es = ref.watch(languageProvider).languageCode == 'es';
    final isLoading = ref.watch(authControllerProvider).isLoading;

    final sentTo = _confirmationSentTo;
    if (sentTo != null) return _buildConfirmation(es, sentTo);

    final email = _emailController.text;
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    return AutofillGroup(
      child: AuthPageLayout(
        onBack: isLoading ? null : widget.onBack,
        title: es ? 'Crear cuenta' : 'Create account',
        subtitle: es
            ? 'La cuenta es opcional. Te permite guardar tus itinerarios y verlos después.'
            : 'The account is optional. It lets you save your itineraries and see them later.',
        children: [
          AuthTextField(
            controller: _emailController,
            label: es ? 'Correo electrónico' : 'Email',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.mail_outline_rounded,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            enabled: !isLoading,
            maxLength: 254,
            errorText: _submitted ? AuthValidators.emailError(email, es) : null,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          AuthTextField(
            controller: _passwordController,
            label: es ? 'Contraseña' : 'Password',
            obscureText: _obscure,
            prefixIcon: Icons.lock_outline_rounded,
            suffixIcon: _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            onSuffixPressed: () => setState(() => _obscure = !_obscure),
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.newPassword],
            enabled: !isLoading,
            maxLength: 72,
            errorText: _submitted ? AuthValidators.passwordError(password, es) : null,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          AuthTextField(
            controller: _confirmController,
            label: es ? 'Repite la contraseña' : 'Repeat the password',
            obscureText: _obscure,
            prefixIcon: Icons.lock_reset_rounded,
            textInputAction: TextInputAction.done,
            enabled: !isLoading,
            maxLength: 72,
            errorText: _submitted ? AuthValidators.confirmError(password, confirm, es) : null,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _submit(es),
          ),
          const SizedBox(height: 8),
          Text(
            es
                ? 'Al menos 8 caracteres, con letras y números.'
                : 'At least 8 characters, with letters and numbers.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 12.5),
          ),
          const SizedBox(height: 16),
          _ConsentRow(
            value: _accepted,
            enabled: !isLoading,
            isSpanish: es,
            onChanged: (value) => setState(() {
              _accepted = value;
              if (value) _errorMessage = null;
            }),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 14),
            AuthInlineMessage(text: _errorMessage!),
          ],
          const SizedBox(height: 20),
          AuthPrimaryAction(
            text: es ? 'Crear cuenta' : 'Create account',
            isLoading: isLoading,
            onPressed: () => _submit(es),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                es ? '¿Ya tienes cuenta? ' : 'Already have an account? ',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.72), fontSize: 14),
              ),
              TextButton(
                onPressed: isLoading ? null : widget.onGoToLogin,
                child: Text(
                  es ? 'Inicia sesión' : 'Sign in',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _cooldown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() => _cooldown--);
      if (_cooldown <= 0) timer.cancel();
    });
  }

  String? _codeError(String code, bool es) {
    if (code.trim().isEmpty) {
      return es ? 'Ingresa el código del correo.' : 'Enter the code from the email.';
    }
    if (!AuthValidators.isValidCode(code)) {
      return es ? 'El código tiene solo números (6 a 8 dígitos).' : 'The code has only digits (6 to 8).';
    }
    return null;
  }

  Future<void> _verifyCode(bool es, String email) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _codeSubmitted = true;
      _codeMessage = null;
    });
    final code = _codeController.text.trim();
    if (_codeError(code, es) != null) return;

    final ok = await ref
        .read(authControllerProvider.notifier)
        .verifySignUpCode(email: email, code: code);
    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(es ? 'Cuenta confirmada. Sesión iniciada.' : 'Account confirmed. You are signed in.'),
        ),
      );
      widget.onSignedIn?.call();
      return;
    }

    final error = ref.read(authControllerProvider).error;
    setState(() {
      _codeMessageIsError = true;
      _codeMessage = error == null
          ? (es ? 'No fue posible confirmar la cuenta.' : 'The account could not be confirmed.')
          : authErrorMessage(error, isSpanish: es);
    });
  }

  Future<void> _resendCode(bool es, String email) async {
    setState(() => _codeMessage = null);
    final ok = await ref.read(authControllerProvider.notifier).resendSignUpCode(email);
    if (!mounted) return;
    final error = ref.read(authControllerProvider).error;
    setState(() {
      _codeMessageIsError = !ok;
      _codeMessage = ok
          ? (es ? 'Te enviamos un código nuevo.' : 'We sent you a new code.')
          : (error == null
              ? (es ? 'No fue posible reenviar el código.' : 'The code could not be resent.')
              : authErrorMessage(error, isSpanish: es));
    });
    if (ok) _startCooldown();
  }

  /// Paso 2: confirmar la cuenta con el código del correo, dentro de la app.
  Widget _buildConfirmation(bool es, String email) {
    final isLoading = ref.watch(authControllerProvider).isLoading;
    final code = _codeController.text;

    return AuthPageLayout(
      onBack: isLoading ? null : widget.onBack,
      title: es ? 'Confirma tu correo' : 'Confirm your email',
      subtitle: es
          ? 'Te enviamos un código a $email. Escríbelo aquí para activar tu cuenta.'
          : 'We sent a code to $email. Enter it here to activate your account.',
      children: [
        AuthTextField(
          controller: _codeController,
          label: es ? 'Código del correo' : 'Code from the email',
          keyboardType: TextInputType.number,
          prefixIcon: Icons.pin_outlined,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.oneTimeCode],
          enabled: !isLoading,
          maxLength: 8,
          errorText: _codeSubmitted ? _codeError(code, es) : null,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _verifyCode(es, email),
        ),
        const SizedBox(height: 8),
        Text(
          es
              ? 'Si no lo ves en unos minutos, revisa la carpeta de spam. Si ya tenías una cuenta con este correo, inicia sesión o recupera tu contraseña.'
              : 'If you do not see it in a few minutes, check your spam folder. If you already had an account with this email, sign in or reset your password.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 12.5, height: 1.35),
        ),
        if (_codeMessage != null) ...[
          const SizedBox(height: 14),
          AuthInlineMessage(text: _codeMessage!, isError: _codeMessageIsError),
        ],
        const SizedBox(height: 20),
        AuthPrimaryAction(
          text: es ? 'Confirmar cuenta' : 'Confirm account',
          isLoading: isLoading,
          onPressed: () => _verifyCode(es, email),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: isLoading || _cooldown > 0 ? null : () => _resendCode(es, email),
          child: Text(
            _cooldown > 0
                ? (es ? 'Reenviar código en $_cooldown s' : 'Resend code in $_cooldown s')
                : (es ? 'Reenviar código' : 'Resend code'),
            style: const TextStyle(color: Colors.white70),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: isLoading ? null : widget.onGoToLogin,
              child: Text(es ? 'Iniciar sesión' : 'Sign in'),
            ),
            TextButton(
              onPressed: isLoading ? null : widget.onForgotPassword,
              child: Text(es ? 'Recuperar contraseña' : 'Reset password'),
            ),
          ],
        ),
      ],
    );
  }
}

class _ConsentRow extends StatelessWidget {
  const _ConsentRow({
    required this.value,
    required this.enabled,
    required this.isSpanish,
    required this.onChanged,
  });

  final bool value;
  final bool enabled;
  final bool isSpanish;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final es = isSpanish;
    final textStyle = TextStyle(
      color: Colors.white.withValues(alpha: 0.85),
      fontSize: 13,
      height: 1.4,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 28,
          height: 28,
          child: Checkbox(
            value: value,
            onChanged: enabled ? (v) => onChanged(v ?? false) : null,
            activeColor: AuthPageLayout.green,
            side: BorderSide(color: Colors.white.withValues(alpha: 0.6)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: enabled ? () => onChanged(!value) : null,
            child: Text.rich(
              TextSpan(
                style: textStyle,
                children: [
                  TextSpan(
                    text: es
                        ? 'Acepto que mi correo se use solo para iniciar sesión y guardar mis itinerarios. Puedo eliminar mi cuenta cuando quiera.'
                        : 'I agree that my email is used only to sign in and save my itineraries. I can delete my account at any time.',
                  ),
                  if (LegalLinks.hasPrivacyPolicy) ...[
                    const TextSpan(text: ' '),
                    TextSpan(
                      text: es ? 'Política de privacidad' : 'Privacy policy',
                      style: const TextStyle(
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => launchUrl(
                              Uri.parse(LegalLinks.privacyPolicyUrl),
                              mode: LaunchMode.externalApplication,
                            ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
