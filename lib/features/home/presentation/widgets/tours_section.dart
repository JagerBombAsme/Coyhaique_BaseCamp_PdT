import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'home_visual_tokens.dart';
import 'section_header.dart';
import 'tour_card.dart';

class TourItemData {
  final String id;
  final String title;
  final String imagePath;
  final String? subtitle;
  final VoidCallback? onTap;

  const TourItemData({
    required this.id,
    required this.title,
    required this.imagePath,
    this.subtitle,
    this.onTap,
  });
}

class ToursSection extends StatelessWidget {
  final String title;
  final String viewAllText;
  final List<TourItemData> items;
  final VoidCallback? onViewAll;

  const ToursSection({
    super.key,
    this.title = 'Tours',
    this.viewAllText = 'View all',
    required this.items,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    // La altura crece con el tamaño de texto del sistema para que el
    // título/subtítulo de las tarjetas no se desborde.
    final textScale =
        (MediaQuery.textScalerOf(context).scale(16) / 16).clamp(1.0, 1.6);
    final listHeight = math.max(310.0, 240.0 + 60.0 * textScale);

    return Padding(
      padding: HomeVisualTokens.sectionPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: title,
            count: items.length,
            actionText: viewAllText,
            onAction: onViewAll,
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: listHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(
                left: HomeVisualTokens.pagePadding,
                right: 40,
              ),
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final item = items[index];

                return TourCard(
                  key: ValueKey(item.id),
                  title: item.title,
                  imagePath: item.imagePath,
                  subtitle: item.subtitle,
                  onTap: item.onTap,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
