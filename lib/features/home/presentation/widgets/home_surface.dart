import 'package:flutter/material.dart';

import 'home_visual_tokens.dart';

/// Superficie de sección: la profundidad viene de la sombra en capas
/// (con anillo translúcido), no de un borde dibujado encima.
class HomeSurface extends StatelessWidget {
  final Widget child;
  final bool ambientGlow;

  const HomeSurface({
    super.key,
    required this.child,
    this.ambientGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(
      Radius.circular(HomeVisualTokens.sectionRadius),
    );

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: HomeVisualTokens.surface,
        borderRadius: radius,
        boxShadow: HomeVisualTokens.elevatedShadow,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            if (ambientGlow) ...[
              Positioned(
                top: -80,
                left: -45,
                child: _Glow(
                  size: 190,
                  color: HomeVisualTokens.iceBlueMedium.withValues(alpha: 0.34),
                ),
              ),
              Positioned(
                right: -70,
                bottom: -105,
                child: _Glow(
                  size: 210,
                  color: HomeVisualTokens.iceBlue.withValues(alpha: 0.48),
                ),
              ),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  final double size;
  final Color color;

  const _Glow({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}
