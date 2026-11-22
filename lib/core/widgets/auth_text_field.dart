import 'package:flutter/material.dart';

import '../theme/basecamp_tokens.dart';

/// Campo de las pantallas de cuenta, sobre tarjeta tinta: relleno claro
/// tenue, foco en glacier y errores con borde y texto (nunca solo color).
class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.label,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixPressed,
    this.suffixTooltip,
    this.errorText,
    this.textInputAction,
    this.onSubmitted,
    this.onChanged,
    this.autofillHints,
    this.enabled = true,
    this.maxLength,
  });

  final String label;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixPressed;

  /// Texto que leen los lectores de pantalla en el botón del extremo
  /// (por ejemplo «Mostrar contraseña»).
  final String? suffixTooltip;
  final String? errorText;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final Iterable<String>? autofillHints;
  final bool enabled;
  final int? maxLength;

  static OutlineInputBorder _border(Color color, double width) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(BcRadius.field),
        borderSide: BorderSide(color: color, width: width),
      );

  @override
  Widget build(BuildContext context) {
    final soft = BcColors.onPhoto.withValues(alpha: 0.82);

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      enabled: enabled,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      onChanged: onChanged,
      autofillHints: autofillHints,
      maxLength: maxLength,
      autocorrect: false,
      enableSuggestions: !obscureText,
      cursorColor: BcColors.glacier,
      style: BcText.body(color: BcColors.onPhoto).copyWith(fontSize: 15),
      decoration: InputDecoration(
        // La etiqueta se queda visible al escribir (flota arriba); un
        // «hint» desaparece y obliga a recordar qué campo era.
        labelText: label,
        labelStyle: BcText.body(color: soft),
        floatingLabelStyle: BcText.caption(color: BcColors.glacier),
        counterText: '',
        filled: true,
        fillColor: BcColors.onPhoto.withValues(alpha: 0.10),
        border: _border(Colors.transparent, 0),
        enabledBorder: _border(BcColors.onPhoto.withValues(alpha: 0.18), 1),
        disabledBorder: _border(BcColors.onPhoto.withValues(alpha: 0.08), 1),
        focusedBorder: _border(BcColors.glacier, 2),
        errorBorder: _border(BcDarkColors.danger, 1.5),
        focusedErrorBorder: _border(BcDarkColors.danger, 2),
        errorText: errorText,
        errorMaxLines: 3,
        errorStyle: BcText.caption(color: BcDarkColors.danger),
        prefixIconColor: soft,
        suffixIconColor: soft,
        prefixIcon: prefixIcon == null
            ? null
            : Icon(prefixIcon),
        suffixIcon: suffixIcon == null
            ? null
            : IconButton(
                onPressed: onSuffixPressed,
                tooltip: suffixTooltip,
                icon: Icon(suffixIcon),
              ),
      ),
    );
  }
}
