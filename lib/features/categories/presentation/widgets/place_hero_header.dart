import 'package:flutter/material.dart';

import '../../../../core/theme/basecamp_tokens.dart';
import '../../../../core/widgets/basecamp/bc_widgets.dart';
import '../../data/models/place_dto.dart';

/// Cabecera de la ficha con el formato de la identidad visual: foto
/// desaturada a todo el ancho, título en mayúsculas y botones de esquina.
class PlaceHeroHeader extends StatelessWidget {
  const PlaceHeroHeader({
    super.key,
    required this.place,
    required this.isSpanish,
    required this.isFavorite,
    required this.onBack,
    required this.onToggleFavorite,
  });

  final PlaceDto place;
  final bool isSpanish;
  final bool isFavorite;
  final VoidCallback onBack;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    final category = (place.categorySlug?.isNotEmpty ?? false)
        ? place.categorySlug!
        : (place.category?.slug ?? (isSpanish ? 'LUGAR' : 'PLACE'));

    final favoriteLabel = isSpanish
        ? (isFavorite ? 'Quitar de favoritos' : 'Añadir a favoritos')
        : (isFavorite ? 'Remove from favorites' : 'Add to favorites');

    return SizedBox(
      height: top + 320,
      child: Stack(
        fit: StackFit.expand,
        children: [
          BcPhotoImage(source: place.imageUrl ?? '', fallbackCategory: '${place.categorySlug ?? ''} ${place.category?.groupType ?? ''} ${place.category?.nombreEs ?? ''}', isSpanish: isSpanish),
          const BcPhotoShade(from: 0.35, topShade: 0.4),
          Positioned(
            left: BcSpace.gutter,
            top: top + 14,
            child: BcCornerButton(
              icon: Icons.arrow_back_rounded,
              semanticLabel: isSpanish ? 'Volver' : 'Back',
              onTap: onBack,
            ),
          ),
          Positioned(
            right: BcSpace.gutter,
            top: top + 14,
            child: BcCornerButton(
              icon: isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              semanticLabel: favoriteLabel,
              onTap: onToggleFavorite,
            ),
          ),
          Positioned(
            left: BcSpace.gutter,
            right: BcSpace.gutter,
            bottom: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BcTag(
                  category.toUpperCase(),
                  lead: 'Aysén',
                  style: BcTagStyle.ink,
                ),
                const SizedBox(height: 12),
                Semantics(
                  header: true,
                  child: Text(
                    place.getTitle(isSpanish).toUpperCase(),
                    style: BcText.display(44, color: BcColors.onPhoto),
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
