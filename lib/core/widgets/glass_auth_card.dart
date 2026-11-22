import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/basecamp_tokens.dart';

/// Tarjeta de las pantallas de cuenta: fondo tinta sobre la foto, sin borde
/// ni sombra (sistema de diseño «afiche de montaña»). El desenfoque suaviza
/// la foto detrás para que el texto blanco se lea (contraste mayor a 7:1).
class GlassAuthCard extends StatelessWidget {
  const GlassAuthCard({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(BcRadius.card),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 18,
          sigmaY: 18,
        ),
        child: ColoredBox(
          color: BcColors.ink.withValues(alpha: 0.78),
          child: child,
        ),
      ),
    );
  }
}
