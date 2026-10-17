import 'package:flutter/material.dart';

import 'animated_icon_swap.dart';
import 'destination_image.dart';
import 'glass_icon_button.dart';
import 'home_visual_tokens.dart';

class DestinationHero extends StatefulWidget {
  final String title;
  final String description;
  final String imagePath;
  final VoidCallback? onBookmarkToggle;
  final bool initialBookmarked;

  const DestinationHero({
    super.key,
    this.title = 'Coyhaique',
    this.description =
        'Coyhaique ofrece vistas a la montaña, ríos patagónicos y un entorno natural inigualable. Perfecto tanto para descansar como para la aventura.',
    this.imagePath = 'assets/images/cerro_castillo_laguna.jpg',
    this.onBookmarkToggle,
    this.initialBookmarked = false,
  });

  /// Offset superior compartido con el botón de perfil del Home,
  /// para que ambos controles queden alineados en la misma línea.
  static double controlTop(BuildContext context) =>
      MediaQuery.paddingOf(context).top + 12;

  @override
  State<DestinationHero> createState() => _DestinationHeroState();
}

class _DestinationHeroState extends State<DestinationHero> {
  late bool _isBookmarked;

  @override
  void initState() {
    super.initState();
    _isBookmarked = widget.initialBookmarked;
  }

  void _handleBookmark() {
    setState(() {
      _isBookmarked = !_isBookmarked;
    });

    if (widget.onBookmarkToggle != null) {
      widget.onBookmarkToggle!();
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 1),
          backgroundColor: HomeVisualTokens.surfaceElevated,
          content: Text(
            _isBookmarked
                ? 'Destino guardado en favoritos'
                : 'Destino eliminado de favoritos',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final heroHeight =
        (MediaQuery.sizeOf(context).height * 0.56).clamp(420.0, 540.0);

    return SizedBox(
      height: heroHeight,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DestinationImage(
            assetPath: widget.imagePath,
            label: '${widget.title} paisaje patagónico',
            showOutline: false,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.20, 0.52, 0.76, 1.0],
                colors: [
                  const Color(0x99000000),
                  const Color(0x22000000),
                  const Color(0x00000000),
                  HomeVisualTokens.background.withValues(alpha: 0.6),
                  HomeVisualTokens.background,
                ],
              ),
            ),
          ),
          Positioned(
            top: DestinationHero.controlTop(context),
            right: HomeVisualTokens.pagePadding,
            child: GlassIconButton(
              active: _isBookmarked,
              semanticLabel: _isBookmarked
                  ? 'Quitar de favoritos'
                  : 'Guardar en favoritos',
              onTap: _handleBookmark,
              child: AnimatedIconSwap(
                child: Icon(
                  _isBookmarked
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  key: ValueKey(_isBookmarked),
                  size: 24,
                  color: _isBookmarked
                      ? HomeVisualTokens.accent
                      : Colors.white,
                ),
              ),
            ),
          ),
          Positioned(
            left: HomeVisualTokens.pagePadding,
            right: HomeVisualTokens.pagePadding,
            bottom: 44,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    widget.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 38,
                      height: 1.02,
                      fontWeight: FontWeight.w800,
                      color: HomeVisualTokens.textPrimary,
                      letterSpacing: -1.1,
                      shadows: [
                        Shadow(
                          color: Color(0x66000000),
                          blurRadius: 18,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 340),
                  child: Text(
                    widget.description,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.86),
                      fontSize: 15,
                      height: 1.5,
                      fontWeight: FontWeight.w400,
                      shadows: const [
                        Shadow(
                          color: Color(0x66000000),
                          blurRadius: 12,
                          offset: Offset(0, 2),
                        ),
                      ],
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
