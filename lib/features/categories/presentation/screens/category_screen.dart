import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/providers/places_provider.dart';
import 'category_places_screen.dart';
import 'group_type_screen.dart';
import '../../../../core/models/category_model.dart';

class CategoryScreen
    extends ConsumerWidget {
  final String category;
  final ValueChanged<String>
      onPlaceClick;
  final VoidCallback onRoutesClick;

  const CategoryScreen({
    super.key,
    required this.category,
    required this.onPlaceClick,
    required this.onRoutesClick,
  });

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final normalized =
        category.trim().toLowerCase();

    /*
     * GRUPOS PRINCIPALES
     *
     * Si recibimos el nombre de un
     * group_type, mostramos primero
     * sus subcategorías.
     */
    switch (normalized) {
      case 'actividad':
      case 'actividades':
        return GroupTypeScreen(
          groupType: 'actividad',
          onPlaceClick: onPlaceClick,
        );

      case 'alojamiento':
      case 'alojamientos':
        return GroupTypeScreen(
          groupType: 'alojamiento',
          onPlaceClick: onPlaceClick,
        );

      case 'atractivo':
      case 'atractivos':
      case 'explorar':
        return GroupTypeScreen(
          groupType: 'atractivo',
          onPlaceClick: onPlaceClick,
        );

      case 'gastronomia':
      case 'gastronomía':
        return GroupTypeScreen(
          groupType: 'gastronomia',
          onPlaceClick: onPlaceClick,
        );

      case 'servicio':
      case 'servicios':
        return GroupTypeScreen(
          groupType: 'servicio',
          onPlaceClick: onPlaceClick,
        );

      case 'transporte':
      case 'transportes':
        return GroupTypeScreen(
          groupType: 'transporte',
          onPlaceClick: onPlaceClick,
        );

      /*
       * Ruta de aventura existente.
       * La conservamos para no romper
       * el flujo previo.
       */
      case 'aventura':
        WidgetsBinding.instance
            .addPostFrameCallback((_) {
          onRoutesClick();
        });

        return const SizedBox.shrink();
    }

    /*
     * Si no era un group_type,
     * buscamos la categoría concreta
     * en categories_v2.
     */
    final categoriesAsync =
        ref.watch(categoriesProvider);

    return categoriesAsync.when(
      data: (categories) {
        CategoryModel? selectedCategory;

        for (final item
            in categories) {
          final slug =
              item.slug
                  .trim()
                  .toLowerCase();

          final id =
              item.id
                  .trim()
                  .toLowerCase();

          final name =
              item.nombreEs
                  .trim()
                  .toLowerCase();

          if (slug == normalized ||
              id == normalized ||
              name == normalized) {
              selectedCategory = item;
              break;
          }
        }

        if (selectedCategory != null) {
        return CategoryPlacesScreen(
          category: selectedCategory,
          onPlaceClick: onPlaceClick,
        );
      }


        return ComingSoonScreen(
          category: category,
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
        body: Center(
          child: Padding(
            padding:
                const EdgeInsets.all(24),
            child: Text(
              'Error al cargar categorías:\n$error',
              textAlign:
                  TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

/// Clase auxiliar interna.
/// Evita paquetes adicionales solo
/// para buscar un elemento nullable.
class CategoryModelSearchResult {
  final dynamic category;

  const CategoryModelSearchResult({
    required this.category,
  });
}

class ComingSoonScreen
    extends StatelessWidget {
  final String category;

  const ComingSoonScreen({
    super.key,
    required this.category,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final title =
        category.isEmpty
            ? 'Próximamente'
            : 'Próximamente: '
                '${category[0].toUpperCase()}'
                '${category.substring(1)}';

    return Scaffold(
      body: Center(
        child: Padding(
          padding:
              const EdgeInsets.all(24),
          child: Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 16,
            ),
            decoration:
                BoxDecoration(
              color:
                  AppTheme.accentLightBlue,
              borderRadius:
                  BorderRadius.circular(
                    16,
                  ),
            ),
            child: Text(
              title,
              style:
                  const TextStyle(
                fontSize: 16,
                fontWeight:
                    FontWeight.bold,
                color:
                    AppTheme.accentBlue,
              ),
            ),
          ),
        ),
      ),
    );
  }
}