import 'package:flutter/material.dart';

import 'home_visual_tokens.dart';

class DestinationImage extends StatelessWidget {
  final String assetPath;
  final String label;
  final List<Color> placeholderColors;

  /// Si se indica, recorta imagen, overlay y contorno con el mismo radio.
  final BorderRadius? borderRadius;

  /// Contorno de 1 px en blanco puro al 10 % para dar profundidad.
  /// Desactívalo en imágenes a sangre (hero).
  final bool showOutline;

  /// Capa entre la imagen y el contorno (p. ej. un degradado), de modo que
  /// el contorno nunca quede oscurecido por ella.
  final Widget? overlay;

  const DestinationImage({
    super.key,
    required this.assetPath,
    required this.label,
    this.borderRadius,
    this.showOutline = true,
    this.overlay,
    this.placeholderColors = const [
      Color(0xFFDDF3FC),
      Color(0xFFBFE6F4),
      HomeVisualTokens.background,
    ],
  });

  static Widget _fadeIn(
    BuildContext context,
    Widget child,
    int? frame,
    bool wasSynchronouslyLoaded,
  ) {
    if (wasSynchronouslyLoaded) return child;

    return AnimatedOpacity(
      opacity: frame == null ? 0 : 1,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRemote = assetPath.startsWith('http://') ||
        assetPath.startsWith('https://');

    final Widget image = isRemote
        ? Image.network(
            assetPath,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            semanticLabel: label,
            frameBuilder: _fadeIn,
            errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
          )
        : Image.asset(
            assetPath,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            semanticLabel: label,
            frameBuilder: _fadeIn,
            errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
          );

    Widget content = Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: HomeVisualTokens.surfaceMuted),
        image,
        ?overlay,
        if (showOutline)
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: borderRadius,
                border: Border.all(
                  color: HomeVisualTokens.outline,
                  width: 1,
                ),
              ),
            ),
          ),
      ],
    );

    if (borderRadius != null) {
      content = ClipRRect(borderRadius: borderRadius!, child: content);
    }

    return content;
  }

  Widget _buildPlaceholder() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: placeholderColors,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.landscape_outlined,
          size: 44,
          color: HomeVisualTokens.accentStrong,
        ),
      ),
    );
  }
}
