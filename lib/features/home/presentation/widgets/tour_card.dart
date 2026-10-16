import 'package:flutter/material.dart';

import 'destination_image.dart';

class TourCard extends StatelessWidget {
  final String title;
  final String imagePath;
  final String? subtitle;
  final List<Color>? placeholderColors;
  final VoidCallback? onTap;

  const TourCard({
    super.key,
    required this.title,
    required this.imagePath,
    this.subtitle,
    this.placeholderColors,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 185,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 220,
              width: 185,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: DestinationImage(
                  assetPath: imagePath,
                  label: title,
                  placeholderColors: placeholderColors,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                height: 1.25,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            if (subtitle != null && subtitle!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
