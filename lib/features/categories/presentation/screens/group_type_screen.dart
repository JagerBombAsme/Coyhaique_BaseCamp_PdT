import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../../core/widgets/category_card.dart';

import '../../data/providers/places_provider.dart';
import 'category_places_screen.dart';

class GroupTypeScreen extends ConsumerStatefulWidget {
  final String groupType;
  final ValueChanged<String> onPlaceClick;

  const GroupTypeScreen({
    super.key,
    required this.groupType,
    required this.onPlaceClick,
  });

  @override
  ConsumerState<GroupTypeScreen> createState() =>
      _GroupTypeScreenState();
}

class _GroupTypeScreenState
    extends ConsumerState<GroupTypeScreen> {
  bool _isReloading = false;

  // ================================================================
  // RECARGAR CATEGORÍAS DEL GRUPO
  // ================================================================

  Future<void> _reloadCategories() async {
    if (_isReloading) {
      return;
    }

    setState(() {
      _isReloading = true;
    });

    try {
      final provider =
          categoriesByGroupProvider(
        widget.groupType,
      );

      ref.invalidate(provider);

      await ref.read(provider.future);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isSpanish
                ? 'Categorías actualizadas.'
                : 'Categories updated.',
          ),
          duration: const Duration(
            milliseconds: 900,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isSpanish
                ? 'No fue posible actualizar las categorías.'
                : 'Could not update categories.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isReloading = false;
        });
      }
    }
  }

  bool get _isSpanish {
    final locale = ref.read(
      languageProvider,
    );

    return locale.languageCode == 'es';
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(
      languageProvider,
    );

    final language =
        locale.languageCode;

    final categoriesAsync =
        ref.watch(
      categoriesByGroupProvider(
        widget.groupType,
      ),
    );

    return Scaffold(
      backgroundColor:
          const Color(
        0xFFF8FAFA,
      ),

      appBar: AppBar(
        backgroundColor:
            const Color(
          0xFFF8FAFA,
        ),

        elevation: 0,

        foregroundColor:
            AppTheme.primaryDark,

        title: Text(
          _getGroupTitle(
            widget.groupType,
            language,
          ),
        ),

        actions: [
          IconButton(
            tooltip:
                language == 'es'
                    ? 'Actualizar'
                    : 'Refresh',

            onPressed:
                _isReloading
                    ? null
                    : _reloadCategories,

            icon:
                _isReloading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(
                          strokeWidth:
                              2,
                          color:
                              AppTheme
                                  .primaryDark,
                        ),
                      )
                    : const Icon(
                        Icons
                            .refresh_rounded,
                      ),
          ),

          const SizedBox(
            width: 8,
          ),
        ],
      ),

      body:
          categoriesAsync.when(
        // ==========================================================
        // DATOS
        // ==========================================================

        data: (categories) {
          if (categories.isEmpty) {
            return RefreshIndicator(
              onRefresh:
                  _reloadCategories,

              color:
                  AppTheme
                      .primaryDark,

              child:
                  ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),

                padding:
                    const EdgeInsets.all(
                  24,
                ),

                children: [
                  SizedBox(
                    height:
                        MediaQuery.of(context)
                                .size
                                .height *
                            0.55,

                    child:
                        Center(
                      child:
                          Column(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .center,

                        children: [
                          const Icon(
                            Icons
                                .category_outlined,
                            size:
                                52,
                            color:
                                AppTheme
                                    .textSecondary,
                          ),

                          const SizedBox(
                            height:
                                16,
                          ),

                          Text(
                            language ==
                                    'es'
                                ? 'No hay categorías disponibles.'
                                : 'No categories available.',

                            textAlign:
                                TextAlign
                                    .center,

                            style:
                                const TextStyle(
                              fontSize:
                                  16,
                              color:
                                  AppTheme
                                      .textSecondary,
                            ),
                          ),

                          const SizedBox(
                            height:
                                16,
                          ),

                          FilledButton.icon(
                            onPressed:
                                _isReloading
                                    ? null
                                    : _reloadCategories,

                            icon:
                                const Icon(
                              Icons
                                  .refresh_rounded,
                            ),

                            label:
                                Text(
                              language ==
                                      'es'
                                  ? 'Actualizar'
                                  : 'Refresh',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh:
                _reloadCategories,

            color:
                AppTheme.primaryDark,

            child:
                ListView.builder(
              physics:
                  const AlwaysScrollableScrollPhysics(),

              padding:
                  const EdgeInsets.all(
                20,
              ),

              itemCount:
                  categories.length,

              itemBuilder:
                  (
                context,
                index,
              ) {
                final category =
                    categories[index];

                return CategoryCard(
                  category:
                      category,

                  language:
                      language,

                  onClick:
                      () {
                    Navigator.of(
                      context,
                    ).push(
                      MaterialPageRoute(
                        builder:
                            (_) {
                          return CategoryPlacesScreen(
                            category:
                                category,

                            onPlaceClick:
                                widget
                                    .onPlaceClick,
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          );
        },

        // ==========================================================
        // CARGANDO
        // ==========================================================

        loading: () {
          return const Center(
            child:
                CircularProgressIndicator(
              color:
                  AppTheme
                      .primaryDark,
            ),
          );
        },

        // ==========================================================
        // ERROR
        // ==========================================================

        error: (
          error,
          stackTrace,
        ) {
          debugPrint(
            'ERROR GroupTypeScreen: $error',
          );

          return Center(
            child: Padding(
              padding:
                  const EdgeInsets.all(
                24,
              ),

              child:
                  Column(
                mainAxisSize:
                    MainAxisSize.min,

                children: [
                  const Icon(
                    Icons
                        .cloud_off_rounded,

                    size:
                        52,

                    color:
                        Colors.redAccent,
                  ),

                  const SizedBox(
                    height:
                        16,
                  ),

                  Text(
                    language == 'es'
                        ? 'No fue posible cargar las categorías.'
                        : 'Could not load categories.',

                    textAlign:
                        TextAlign.center,

                    style:
                        const TextStyle(
                      fontSize:
                          16,

                      fontWeight:
                          FontWeight.bold,

                      color:
                          AppTheme
                              .textPrimary,
                    ),
                  ),

                  const SizedBox(
                    height:
                        8,
                  ),

                  Text(
                    error.toString(),

                    textAlign:
                        TextAlign.center,

                    style:
                        const TextStyle(
                      fontSize:
                          12,

                      color:
                          AppTheme
                              .textSecondary,
                    ),
                  ),

                  const SizedBox(
                    height:
                        20,
                  ),

                  FilledButton.icon(
                    onPressed:
                        _isReloading
                            ? null
                            : _reloadCategories,

                    icon:
                        _isReloading
                            ? const SizedBox(
                                width:
                                    18,
                                height:
                                    18,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth:
                                      2,
                                  color:
                                      Colors
                                          .white,
                                ),
                              )
                            : const Icon(
                                Icons
                                    .refresh_rounded,
                              ),

                    label:
                        Text(
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

  // ================================================================
  // TÍTULO DEL GRUPO
  // ================================================================

  String _getGroupTitle(
    String group,
    String language,
  ) {
    final normalized =
        group
            .trim()
            .toLowerCase();

    if (language == 'en') {
      switch (normalized) {
        case 'actividad':
          return 'Activities';

        case 'alojamiento':
          return 'Accommodation';

        case 'atractivo':
          return 'Attractions';

        case 'gastronomia':
        case 'gastronomía':
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
      case 'gastronomía':
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