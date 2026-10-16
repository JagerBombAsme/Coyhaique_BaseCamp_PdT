import 'package:flutter/material.dart';

import 'destination_image.dart';

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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isBookmarked
                ? 'Destino guardado en favoritos'
                : 'Destino eliminado de favoritos',
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final heroHeight =
        (MediaQuery.sizeOf(context).height * 0.52).clamp(360.0, 480.0);

    return SizedBox(
      height: heroHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background Hero Image
          DestinationImage(
            assetPath: widget.imagePath,
            label: '${widget.title} paisaje patagónico',
            placeholderColors: const [
              Color(0xFF8B9CB3),
              Color(0xFF2C567A),
              Color(0xFF211F22),
            ],
          ),

          // Linear Gradient Overlays (top and bottom blend into #211F22)
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0, 0.35, 0.65, 1],
                colors: [
                  Colors.black.withValues(alpha: 0.18),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.15),
                  const Color(0xFF211F22),
                ],
              ),
            ),
          ),

          // Content Overlay
          Positioned(
            top: topInset + 20,
            left: 24,
            right: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: _isBookmarked ? 'Guardado' : 'Guardar',
                      onPressed: _handleBookmark,
                      style: IconButton.styleFrom(
                        backgroundColor:
                            Colors.white.withValues(alpha: 0.14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(46, 46),
                      ),
                      icon: Icon(
                        _isBookmarked
                            ? Icons.bookmark_rounded
                            : Icons.bookmarks_outlined,
                        size: 22,
                        color: _isBookmarked ? Colors.amber : Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 280),
                  child: Text(
                    widget.description,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.88),
                      fontSize: 14,
                      height: 1.4,
                      fontWeight: FontWeight.w400,
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
