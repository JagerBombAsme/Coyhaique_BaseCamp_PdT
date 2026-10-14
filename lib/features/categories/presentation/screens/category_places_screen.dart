import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/category_model.dart';
import '../../../../core/utils/language_provider.dart';
import '../../data/providers/places_provider.dart';
import 'category_list_screen.dart';

class CategoryPlacesScreen
    extends ConsumerWidget {
  final CategoryModel category;
  final ValueChanged<String>
      onPlaceClick;

  const CategoryPlacesScreen({
    super.key,
    required this.category,
    required this.onPlaceClick,
  });

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final locale =
        ref.watch(languageProvider);

    final language =
        locale.languageCode;

    final isSpanish =
        language == 'es';

    /*
     * IMPORTANTE:
     *
     * usamos category.id porque
     * categories_v2.id es FK de:
     *
     * places_v2.category_id
     */
    final placesAsync =
        ref.watch(
      placesByCategoryProvider(
        category.id,
      ),
    );

    return placesAsync.when(
      data: (places) {
        final items =
            places.map((place) {
          return CategoryItem(
            id: place.id,
            title: place.getTitle(
              isSpanish,
            ),
            subtitle:
                place.getSubtitle(
              isSpanish,
            ),
            description:
                place.getDescription(
              isSpanish,
            ),
            imageUrl:
                place.imageUrl,
          );
        }).toList();

        return CategoryListScreen(
          title:
              category.getNombre(
            language,
          ),
          subtitle:
              category
                      .getDescripcion(
                        language,
                      )
                      .trim()
                      .isNotEmpty
                  ? category
                      .getDescripcion(
                        language,
                      )
                  : isSpanish
                      ? 'Información disponible en Coyhaique.'
                      : 'Available information in Coyhaique.',
          searchPlaceholder:
              isSpanish
                  ? 'Buscar...'
                  : 'Search...',
          tabs: [
            isSpanish
                ? 'Todos'
                : 'All',
          ],
          selectedTab:
              isSpanish
                  ? 'Todos'
                  : 'All',
          featuredItems: items,

          /*
           * No inventamos popularidad.
           * Por ahora queda vacío.
           */
          popularItems: const [],

          onItemClick: (item) {
            onPlaceClick(item.id);
          },

          onReload: () {
            ref.invalidate(
              placesByCategoryProvider(
                category.id,
              ),
            );
          },
        );
      },

      loading: () =>
          const Scaffold(
        body: Center(
          child:
              CircularProgressIndicator(),
        ),
      ),

      error: (error, _) =>
          Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding:
                const EdgeInsets.all(24),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                Text(
                  isSpanish
                      ? 'No fue posible cargar la información.'
                      : 'Could not load information.',
                  textAlign:
                      TextAlign.center,
                ),
                const SizedBox(
                  height: 8,
                ),
                Text(
                  error.toString(),
                  textAlign:
                      TextAlign.center,
                  style:
                      const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(
                  height: 16,
                ),
                FilledButton(
                  onPressed: () {
                    ref.invalidate(
                      placesByCategoryProvider(
                        category.id,
                      ),
                    );
                  },
                  child: Text(
                    isSpanish
                        ? 'Reintentar'
                        : 'Retry',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}