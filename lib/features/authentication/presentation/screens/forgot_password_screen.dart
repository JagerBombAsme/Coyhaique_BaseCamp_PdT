import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/language_provider.dart';
import '../../../../core/widgets/auth_text_field.dart';
import '../../data/auth_error_messages.dart';
import '../../data/auth_validators.dart';
import '../../data/providers/auth_controller.dart';
import '../widgets/auth_page_layout.dart';

/// Recuperar la contraseña (HU-16) con un código enviado por correo.
///
/// 1. El usuario escribe su correo y recibe un código de un solo uso.
/// 2. Escribe el código y la contraseña nueva; queda con sesión iniciada.
///
/// Se usa código y no enlace para no depender de enlaces profundos
/// (deep links) en Android. Requiere que la plantilla «Reset Password» de
/// Supabase incluya {{ .Token }}.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({
    super.key,
    this.initialEmail,
    this.onBack,
    this.onDone,
  });

  final String? initialEmail;
  final VoidCallback? onBack;

  /// La contraseña se cambió y el usuario quedó con sesión iniciada.
  final VoidCallback? onDone;

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  static const int _resendSeconds = 60;

  late final _emailController = TextEditingController(text: widget.initialEmail ?? '');
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _codeSent = false;
  bool _submitted = false;
  bool _obscure = true;
  String? _errorMessage;
  int _cooldown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _cooldown = _resendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() => _cooldown--);
      if (_cooldown <= 0) timer.cancel();
    });
  }

  Future<void> _sendCode(bool es) async {
    FocusScope.of(context).unfocus();
    final email = _emailController.text.trim();
    final emailError = AuthValidators.emailError(email, es);
    if (emailError != null) {
      setState(() {
        _submitted = true;
        _errorMessage = null;
      });
      return;
    }

    setState(() => _errorMessage = null);
    final ok = await ref.read(authControllerProvider.notifier).requestPasswordReset(email);
    if (!mounted) return;

    if (ok) {
      setState(() {
        _codeSent = true;
        _submitted = false;
      });
      _startCooldown();
    } else {
      _showError(es);
    }
  }

  Future<void> _resetPassword(bool es) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _submitted = true;
      _errorMessage = null;
    });

    final code = _codeController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (_codeError(code, es) != null ||
        AuthValidators.passwordError(password, es) != null ||
        AuthValidators.confirmError(password, confirm, es) != null) {
      return;
    }

    final ok = await ref.read(authControllerProvider.notifier).resetPasswordWithCode(
          email: _emailController.text.trim(),
          code: code,
          newPassword: password,
        );
    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            es
                ? 'Contraseña actualizada. Sesión iniciada.'
                : 'Password updated. You are signed in.',
          ),
        ),
      );
      widget.onDone?.call();
    } else {
      _showError(es);
    }
  }

  void _showError(bool es) {
    final error = ref.read(authControllerProvider).error;
    setState(() {
      _errorMessage = error == null
          ? (es ? 'No fue posible completar la operación.' : 'The operation could not be completed.')
          : authErrorMessage(error, isSpanish: es);
    });
  }

  String? _codeError(String code, bool es) {
    if (code.isEmpty) return es ? 'Ingresa el código del correo.' : 'Enter the code from the email.';
    if (!AuthValidators.isValidCode(code)) {
      return es ? 'El código tiene solo números (6 a 8 dígitos).' : 'The code has only digits (6 to 8).';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final es = ref.watch(languageProvider).languageCode == 'es';
    final isLoading = ref.watch(authControllerProvider).isLoading;

    return _codeSent ? _buildResetStep(es, isLoading) : _buildEmailStep(es, isLoading);
  }

  Widget _buildEmailStep(bool es, bool isLoading) {
    final email = _emailController.text;
    return AuthPageLayout(
      onBack: isLoading ? null : widget.onBack,
      title: es ? 'Recuperar contraseña' : 'Reset password',
      subtitle: es
          ? 'Escribe el correo de tu cuenta. Te enviaremos un código para crear una contraseña nueva.'
          : 'Enter your account email. We will send you a code to create a new password.',
      children: [
        AuthTextField(
          controller: _emailController,
          label: es ? 'Correo electrónico' : 'Email',
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icons.mail_outline_rounded,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.email],
          enabled: !isLoading,
          maxLength: 254,
          errorText: _submitted ? AuthValidators.emailError(email, es) : null,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _sendCode(es),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 14),
          AuthInlineMessage(text: _errorMessage!),
        ],
        const SizedBox(height: 20),
        AuthPrimaryAction(
          text: es ? 'Enviar código' : 'Send code',
          isLoading: isLoading,
          onPressed: () => _sendCode(es),
        ),
      ],
    );
  }

  Widget _buildResetStep(bool es, bool isLoading) {
    final code = _codeController.text;
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    return AuthPageLayout(
      onBack: isLoading
          ? null
          : () => setState(() {
                _codeSent = false;
                _submitted = false;
                _errorMessage = null;
              }),
      title: es ? 'Nueva contraseña' : 'New password',
      subtitle: es
          ? 'Si existe una cuenta con ${_emailController.text.trim()}, te enviamos un código. Revisa también la carpeta de spam.'
          : 'If an account exists for ${_emailController.text.trim()}, we sent you a code. Also check your spam folder.',
      children: [
        AuthTextField(
          controller: _codeController,
          label: es ? 'Código del correo' : 'Code from the email',
          keyboardType: TextInputType.number,
          prefixIcon: Icons.pin_outlined,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.oneTimeCode],
          enabled: !isLoading,
          maxLength: 8,
          errorText: _submitted ? _codeError(code, es) : null,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 14),
        AuthTextField(
          controller: _passwordController,
          label: es ? 'Contraseña nueva' : 'New password',
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
          onSubmitted: (_) => _resetPassword(es),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 14),
          AuthInlineMessage(text: _errorMessage!),
        ],
        const SizedBox(height: 20),
        AuthPrimaryAction(
          text: es ? 'Guardar contraseña' : 'Save password',
          isLoading: isLoading,
          onPressed: () => _resetPassword(es),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: isLoading || _cooldown > 0 ? null : () => _sendCode(es),
          child: Text(
            _cooldown > 0
                ? (es ? 'Reenviar código en $_cooldown s' : 'Resend code in $_cooldown s')
                : (es ? 'Reenviar código' : 'Resend code'),
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      ],
    );
  }
}
