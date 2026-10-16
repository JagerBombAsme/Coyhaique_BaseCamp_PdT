import 'package:flutter/material.dart';

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
    final displayTitle = '$title (${items.length})';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  displayTitle,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              if (onViewAll != null)
                TextButton(
                  onPressed: onViewAll,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white.withValues(alpha: 0.8),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: Text(
                    viewAllText,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 285,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final item = items[index];
              return TourCard(
                title: item.title,
                imagePath: item.imagePath,
                subtitle: item.subtitle,
                onTap: item.onTap,
              );
            },
          ),
        ),
      ],
    );
  }
}
