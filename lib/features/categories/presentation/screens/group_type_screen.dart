import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/language_provider.dart';
import '../../../../../core/widgets/category_card.dart';
import '../../data/providers/places_provider.dart';
import 'category_places_screen.dart';

class GroupTypeScreen extends ConsumerWidget {
  final String groupType;
  final ValueChanged<String> onPlaceClick;

  const GroupTypeScreen({
    super.key,
    required this.groupType,
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

    final categoriesAsync =
        ref.watch(
      categoriesByGroupProvider(groupType),
    );

    return Scaffold(
      backgroundColor:
          const Color(0xFFF8FAFA),
      appBar: AppBar(
        backgroundColor:
            const Color(0xFFF8FAFA),
        elevation: 0,
        foregroundColor:
            AppTheme.primaryDark,
        title: Text(
          _getGroupTitle(
            groupType,
            language,
          ),
        ),
      ),
      body: categoriesAsync.when(
        data: (categories) {
          if (categories.isEmpty) {
            return Center(
              child: Padding(
                padding:
                    const EdgeInsets.all(24),
                child: Text(
                  language == 'es'
                      ? 'No hay categorías disponibles.'
                      : 'No categories available.',
                  textAlign:
                      TextAlign.center,
                  style: const TextStyle(
                    color:
                        AppTheme.textSecondary,
                  ),
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(
                categoriesByGroupProvider(
                  groupType,
                ),
              );
            },
            child: ListView.builder(
              padding:
                  const EdgeInsets.all(20),
              itemCount:
                  categories.length,
              itemBuilder:
                  (context, index) {
                final category =
                    categories[index];

                return CategoryCard(
                  category: category,
                  language: language,
                  onClick: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            CategoryPlacesScreen(
                          category:
                              category,
                          onPlaceClick:
                              onPlaceClick,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
        loading: () =>
            const Center(
          child:
              CircularProgressIndicator(),
        ),
        error: (error, _) {
          return Center(
            child: Padding(
              padding:
                  const EdgeInsets.all(24),
              child: Column(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  Text(
                    language == 'es'
                        ? 'No fue posible cargar las categorías.'
                        : 'Could not load categories.',
                    textAlign:
                        TextAlign.center,
                    style:
                        const TextStyle(
                      color: Colors.red,
                    ),
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
                      color: AppTheme
                          .textSecondary,
                    ),
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  FilledButton(
                    onPressed: () {
                      ref.invalidate(
                        categoriesByGroupProvider(
                          groupType,
                        ),
                      );
                    },
                    child: Text(
                      language == 'es'
                          ? 'Reintentar'
                          : 'Retry',
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _getGroupTitle(
    String group,
    String language,
  ) {
    final normalized =
        group.trim().toLowerCase();

    if (language == 'en') {
      switch (normalized) {
        case 'actividad':
          return 'Activities';
        case 'alojamiento':
          return 'Accommodation';
        case 'atractivo':
          return 'Attractions';
        case 'gastronomia':
          return 'Gastronomy';
        case 'servicio':
          return 'Services';
        case 'transporte':
          return 'Transport';
        default:
          return group;
      }
    }

    switch (normalized) {
      case 'actividad':
        return 'Actividades';
      case 'alojamiento':
        return 'Alojamiento';
      case 'atractivo':
        return 'Atractivos';
      case 'gastronomia':
        return 'Gastronomía';
      case 'servicio':
        return 'Servicios';
      case 'transporte':
        return 'Transporte';
      default:
        return group;
    }
  }
}