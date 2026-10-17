import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import 'home_visual_tokens.dart';

/// Cambio contextual de ícono: opacity 0→1, scale 0.25→1, blur 4→0,
/// sin rebote. El hijo debe llevar una `key` distinta por estado.
class AnimatedIconSwap extends StatelessWidget {
  final Widget child;

  const AnimatedIconSwap({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return AnimatedSwitcher(
      duration: reduceMotion ? Duration.zero : HomeVisualTokens.iconDuration,
      switchInCurve: HomeVisualTokens.iconCurve,
      switchOutCurve: HomeVisualTokens.iconCurve,
      transitionBuilder: (child, animation) {
        return AnimatedBuilder(
          animation: animation,
          child: child,
          builder: (context, child) {
            final t = animation.value.clamp(0.0, 1.0).toDouble();
            final sigma = 4.0 * (1 - t);

            Widget result = Opacity(
              opacity: t,
              child: Transform.scale(
                scale: 0.25 + 0.75 * t,
                child: child,
              ),
            );

            if (sigma > 0.05) {
              result = ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
                child: result,
              );
            }

            return result;
          },
        );
      },
      child: child,
    );
  }
}
