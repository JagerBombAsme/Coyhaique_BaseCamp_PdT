import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class DestinationImage extends StatelessWidget {
  final String assetPath;
  final String label;
  final List<Color>? placeholderColors;
  final BoxFit fit;

  const DestinationImage({
    super.key,
    required this.assetPath,
    required this.label,
    this.placeholderColors,
    this.fit = BoxFit.cover,
  });

  bool get _isNetwork => assetPath.startsWith('http://') || assetPath.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    if (_isNetwork) {
      return CachedNetworkImage(
        imageUrl: assetPath,
        width: double.infinity,
        height: double.infinity,
        fit: fit,
        placeholder: (context, url) => _buildPlaceholder(),
        errorWidget: (context, url, error) => _buildPlaceholder(),
      );
    }

    return Image.asset(
      assetPath,
      width: double.infinity,
      height: double.infinity,
      fit: fit,
      semanticLabel: label,
      errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
    );
  }

  Widget _buildPlaceholder() {
    final colors = placeholderColors ??
        const [
          Color(0xFF36343B),
          Color(0xFF28262C),
          Color(0xFF1B1A1E),
        ];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.landscape_rounded,
            size: 40,
            color: Colors.white24,
          ),
          if (label.isNotEmpty) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
