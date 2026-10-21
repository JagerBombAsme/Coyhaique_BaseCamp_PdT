import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/category_model.dart';

import '../../data/providers/places_provider.dart';

import 'category_places_screen.dart';
import 'group_type_screen.dart';

class CategoryScreen extends ConsumerWidget {
  final String category;
  final ValueChanged<String> onPlaceClick;
  final VoidCallback onRoutesClick;

  const CategoryScreen({
    super.key,
    required this.category,
    required this.onPlaceClick,
    required this.onRoutesClick,
  });

  // ================================================================
  // RECARGAR DATOS
  // ================================================================

  Future<void> _reloadData(
    WidgetRef ref,
  ) async {
    ref.invalidate(categoriesProvider);
    ref.invalidate(placesProvider);

    await ref.read(categoriesProvider.future);
    await ref.read(placesProvider.future);
  }

  // ================================================================
  // WRAPPER CON BOTÓN DE RECARGA
  // ================================================================

  Widget _withReloadButton({
    required BuildContext context,
    required WidgetRef ref,
    required Widget child,
  }) {
    return Stack(
      children: [
        Positioned.fill(
          child: child,
        ),

        Positioned(
          top:
              MediaQuery.paddingOf(context).top +
              12,
          right: 16,
          child: Material(
            color: Colors.white,
            elevation: 5,
            shape: const CircleBorder(),
            child: IconButton(
              tooltip: 'Recargar',
              icon: const Icon(
                Icons.refresh_rounded,
                color: AppTheme.primaryDark,
              ),
              onPressed: () async {
                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Actualizando información...',
                    ),
                    duration: Duration(
                      milliseconds: 800,
                    ),
                  ),
                );

                try {
                  await _reloadData(ref);

                  if (!context.mounted) {
                    return;
                  }

                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Información actualizada.',
                      ),
                      duration: Duration(
                        milliseconds: 900,
                      ),
                    ),
                  );
                } catch (error) {
                  if (!context.mounted) {
                    return;
                  }

                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    SnackBar(
                      content: Text(
                        'No fue posible actualizar la información.\n$error',
                      ),
                    ),
                  );
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final normalized =
        category.trim().toLowerCase();

    // ==============================================================
    // GRUPOS PRINCIPALES
    // ==============================================================

    switch (normalized) {
      case 'actividad':
      case 'actividades':
        return _withReloadButton(
          context: context,
          ref: ref,
          child: GroupTypeScreen(
            groupType: 'actividad',
            onPlaceClick: onPlaceClick,
          ),
        );

      case 'alojamiento':
      case 'alojamientos':
        return _withReloadButton(
          context: context,
          ref: ref,
          child: GroupTypeScreen(
            groupType: 'alojamiento',
            onPlaceClick: onPlaceClick,
          ),
        );

      case 'atractivo':
      case 'atractivos':
      case 'explorar':
        return _withReloadButton(
          context: context,
          ref: ref,
          child: GroupTypeScreen(
            groupType: 'atractivo',
            onPlaceClick: onPlaceClick,
          ),
        );

      case 'gastronomia':
      case 'gastronomía':
        return _withReloadButton(
          context: context,
          ref: ref,
          child: GroupTypeScreen(
            groupType: 'gastronomia',
            onPlaceClick: onPlaceClick,
          ),
        );

      case 'servicio':
      case 'servicios':
        return _withReloadButton(
          context: context,
          ref: ref,
          child: GroupTypeScreen(
            groupType: 'servicio',
            onPlaceClick: onPlaceClick,
          ),
        );

      case 'transporte':
      case 'transportes':
        return _withReloadButton(
          context: context,
          ref: ref,
          child: GroupTypeScreen(
            groupType: 'transporte',
            onPlaceClick: onPlaceClick,
          ),
        );

      // ============================================================
      // RUTA DE AVENTURA EXISTENTE
      // ============================================================

      case 'aventura':
        WidgetsBinding.instance
            .addPostFrameCallback(
          (_) {
            onRoutesClick();
          },
        );

        return const SizedBox.shrink();
    }

    // ==============================================================
    // CATEGORÍA ESPECÍFICA
    // ==============================================================

    final categoriesAsync =
        ref.watch(categoriesProvider);

    return categoriesAsync.when(
      // ============================================================
      // DATOS
      // ============================================================

      data: (categories) {
        CategoryModel? selectedCategory;

        for (final item in categories) {
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
          return _withReloadButton(
            context: context,
            ref: ref,
            child: CategoryPlacesScreen(
              category: selectedCategory,
              onPlaceClick:
                  onPlaceClick,
            ),
          );
        }

        return ComingSoonScreen(
          category: category,
        );
      },

      // ============================================================
      // CARGANDO
      // ============================================================

      loading: () {
        return const Scaffold(
          body: Center(
            child:
                CircularProgressIndicator(
              color:
                  AppTheme.primaryDark,
            ),
          ),
        );
      },

      // ============================================================
      // ERROR
      // ============================================================

      error: (error, stackTrace) {
        debugPrint(
          'ERROR CATEGORIES: $error',
        );

        return Scaffold(
          backgroundColor:
              const Color(
            0xFFF8F9FA,
          ),
          body: SafeArea(
            child: Center(
              child: Padding(
                padding:
                    const EdgeInsets.all(
                  24,
                ),
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .center,
                  children: [
                    const Icon(
                      Icons
                          .cloud_off_rounded,
                      size: 54,
                      color:
                          AppTheme.primaryDark,
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    const Text(
                      'No fue posible cargar las categorías.',
                      textAlign:
                          TextAlign.center,
                      style:
                          TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                        color:
                            AppTheme.textPrimary,
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
                        color:
                            AppTheme.textSecondary,
                      ),
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    ElevatedButton.icon(
                      onPressed:
                          () async {
                        try {
                          await _reloadData(
                            ref,
                          );
                        } catch (
                          reloadError
                        ) {
                          debugPrint(
                            'ERROR AL RECARGAR: $reloadError',
                          );
                        }
                      },

                      style:
                          ElevatedButton
                              .styleFrom(
                        backgroundColor:
                            AppTheme.primaryDark,
                        foregroundColor:
                            Colors.white,
                      ),

                      icon:
                          const Icon(
                        Icons
                            .refresh_rounded,
                      ),

                      label:
                          const Text(
                        'Reintentar',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ===================================================================
// PANTALLA PRÓXIMAMENTE
// ===================================================================

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
      backgroundColor:
          const Color(
        0xFFF8F9FA,
      ),

      body: SafeArea(
        child: Center(
          child: Padding(
            padding:
                const EdgeInsets.all(
              24,
            ),
            child: Container(
              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 24,
                vertical: 18,
              ),
              decoration:
                  BoxDecoration(
                color:
                    AppTheme
                        .accentLightBlue,
                borderRadius:
                    BorderRadius.circular(
                  16,
                ),
              ),
              child: Column(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  const Icon(
                    Icons
                        .construction_rounded,
                    color:
                        AppTheme.accentBlue,
                    size: 38,
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  Text(
                    title,
                    textAlign:
                        TextAlign.center,
                    style:
                        const TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.bold,
                      color:
                          AppTheme.accentBlue,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}