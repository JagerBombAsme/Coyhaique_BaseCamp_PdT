import 'package:flutter/material.dart';

import 'destination_image.dart';
import 'home_visual_tokens.dart';
import 'pressable_scale.dart';

class TourCard extends StatelessWidget {
  static const double width = 188;
  static const double imageHeight = 220;

  final String title;
  final String imagePath;
  final String? subtitle;
  final VoidCallback? onTap;

  const TourCard({
    super.key,
    required this.title,
    required this.imagePath,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(HomeVisualTokens.cardRadius);
    final hasSubtitle = subtitle != null && subtitle!.trim().isNotEmpty;

    return PressableScale(
      onTap: onTap,
      semanticLabel: hasSubtitle ? '$title, $subtitle' : title,
      excludeChildSemantics: true,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: radius,
                boxShadow: HomeVisualTokens.softShadow,
              ),
              child: SizedBox(
                height: imageHeight,
                child: DestinationImage(
                  assetPath: imagePath,
                  label: title,
                  borderRadius: radius,
                  overlay: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0.55, 1],
                        colors: [Color(0x00000000), Color(0x66000000)],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: HomeVisualTokens.cardTitle,
            ),
            if (hasSubtitle) ...[
              const SizedBox(height: 5),
              Text(
                subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: HomeVisualTokens.caption,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
