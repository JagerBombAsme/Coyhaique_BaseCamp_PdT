import 'package:flutter/material.dart';

import '../../../../core/models/category_model.dart';
import 'destination_image.dart';
import 'home_visual_tokens.dart';
import 'pressable_scale.dart';
import 'section_header.dart';

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

  static const double _tileWidth = 150;
  static const double _tileHeight = 130;
  static const double _tilePadding = 12;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();

    final tileRadius = BorderRadius.circular(HomeVisualTokens.imageRadius);

    // Concéntrico: chip = radio de la tarjeta − padding (20 − 12 = 8).
    final chipRadius = BorderRadius.circular(
      HomeVisualTokens.innerRadius(
        HomeVisualTokens.imageRadius,
        _tilePadding,
      ),
    );

    return Padding(
      padding: HomeVisualTokens.sectionPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: title),
          const SizedBox(height: 18),
          SizedBox(
            height: _tileHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: HomeVisualTokens.pagePadding,
              ),
              itemCount: categories.length,
              separatorBuilder: (context, index) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final cat = categories[index];
                final catName = cat.getNombre(language);
                final imageUrl = _resolveCategoryImage(cat);

                return PressableScale(
                  semanticLabel: catName,
                  excludeChildSemantics: true,
                  onTap: () => onCategoryTap(cat.route),
                  child: SizedBox(
                    width: _tileWidth,
                    child: DestinationImage(
                      assetPath: imageUrl,
                      label: catName,
                      borderRadius: tileRadius,
                      overlay: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0.2, 1],
                            colors: [
                              HomeVisualTokens.deepIce.withValues(alpha: 0.04),
                              HomeVisualTokens.deepIce.withValues(alpha: 0.82),
                            ],
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(_tilePadding),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.78),
                                  borderRadius: chipRadius,
                                  border: Border.all(
                                    color: HomeVisualTokens.outline,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(6),
                                  child: Icon(
                                    cat.icon,
                                    size: 16,
                                    color: HomeVisualTokens.deepIce,
                                  ),
                                ),
                              ),
                              Text(
                                catName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: HomeVisualTokens.tileLabel,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
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
