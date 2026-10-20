import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import 'home_visual_tokens.dart';
import 'pressable_scale.dart';

/// Botón de ícono 48×48 (≥ 44 px de área táctil) con efecto vidrio,
/// usado sobre imágenes: perfil y favoritos comparten la misma pieza.
class GlassIconButton extends StatelessWidget {
  final Widget child;
  final String semanticLabel;
  final VoidCallback onTap;
  final bool active;

  const GlassIconButton({
    super.key,
    required this.child,
    required this.semanticLabel,
    required this.onTap,
    this.active = false,
  });

  static const double size = 48;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(HomeVisualTokens.controlRadius);

    return PressableScale(
      semanticLabel: semanticLabel,
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: HomeVisualTokens.softShadow,
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: AnimatedContainer(
              duration: HomeVisualTokens.stateDuration,
              curve: Curves.easeOut,
              width: size,
              height: size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active
                    ? HomeVisualTokens.iceBlue.withValues(alpha: 0.92)
                    : Colors.white.withValues(alpha: 0.72),
                borderRadius: radius,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.86),
                ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
