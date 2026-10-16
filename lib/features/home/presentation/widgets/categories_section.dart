import 'package:flutter/material.dart';

import '../../../../core/models/category_model.dart';
import 'destination_image.dart';

class CategoriesSection extends StatelessWidget {
  final String title;
  final List<CategoryModel> categories;
  final String language;
  final Function(String route) onCategoryTap;

  const CategoriesSection({
    super.key,
    required this.title,
    required this.categories,
    required this.language,
    required this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 130,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: categories.length,
            separatorBuilder: (context, index) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final cat = categories[index];
              final catName = cat.getNombre(language);
              final imageUrl = _resolveCategoryImage(cat);

              return GestureDetector(
                onTap: () => onCategoryTap(cat.route),
                child: Container(
                  width: 150,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: const Color(0xFF2C2A2F),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      DestinationImage(
                        assetPath: imageUrl,
                        label: catName,
                      ),
                      // Dark gradient
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.15),
                              Colors.black.withValues(alpha: 0.70),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                cat.icon,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              catName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _resolveCategoryImage(CategoryModel cat) {
    if (cat.imageUrl != null &&
        cat.imageUrl!.isNotEmpty &&
        !cat.imageUrl!.contains('example.com')) {
      return cat.imageUrl!;
    }
    final slug = cat.slug.toLowerCase();
    final group = (cat.groupType ?? '').toLowerCase();
    if (slug.contains('gastro') ||
        group.contains('gastro') ||
        slug.contains('restauran')) {
      return 'assets/images/gastronomia_fogon.jpg';
    }
    if (slug.contains('aloj') ||
        group.contains('aloj') ||
        slug.contains('hotel')) {
      return 'assets/images/alojamiento_hotel.jpg';
    }
    if (slug.contains('cult') ||
        group.contains('cult') ||
        slug.contains('patrimon')) {
      return 'assets/images/cultura_gaucho.jpg';
    }
    if (slug.contains('ruta') ||
        slug.contains('avent') ||
        slug.contains('trek')) {
      return 'assets/images/cordon_divisadero.jpg';
    }
    return 'assets/images/miradores_coyhaique.jpg';
  }
}
