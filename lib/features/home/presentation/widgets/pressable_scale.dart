import 'package:flutter/material.dart';

import 'home_visual_tokens.dart';

/// Feedback táctil unificado: scale 0.96 al presionar.
/// Respeta "reducir movimiento": sin escala, usa un atenuado como señal.
class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final bool excludeChildSemantics;
  final double scale;

  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.semanticLabel,
    this.excludeChildSemantics = false,
    this.scale = HomeVisualTokens.pressScale,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value || !mounted) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    Widget content = AnimatedScale(
      scale: _pressed && !reduceMotion ? widget.scale : 1,
      duration: reduceMotion ? Duration.zero : HomeVisualTokens.pressDuration,
      curve: Curves.easeOut,
      child: widget.child,
    );

    if (reduceMotion && _pressed) {
      content = Opacity(opacity: 0.8, child: content);
    }

    return Semantics(
      button: enabled,
      enabled: enabled,
      label: widget.semanticLabel,
      excludeSemantics: widget.excludeChildSemantics,
      onTap: widget.onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => _setPressed(true) : null,
        onTapUp: enabled ? (_) => _setPressed(false) : null,
        onTapCancel: enabled ? () => _setPressed(false) : null,
        onTap: widget.onTap,
        child: content,
      ),
    );
  }
}
