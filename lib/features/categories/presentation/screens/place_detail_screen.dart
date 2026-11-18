import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/basecamp_tokens.dart';
import '../../../../core/widgets/basecamp/bc_widgets.dart';
import '../../../../core/providers/language_provider.dart';

import '../../data/models/place_dto.dart';
import '../../data/providers/places_provider.dart';
import '../widgets/place_distance_card.dart';
import '../widgets/place_hero_header.dart';

class PlaceDetailScreen extends ConsumerStatefulWidget {
  final String placeId;
  final VoidCallback onBack;

  const PlaceDetailScreen({
    super.key,
    required this.placeId,
    required this.onBack,
  });

  @override
  ConsumerState<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends ConsumerState<PlaceDetailScreen> {
  bool _isFavorite = false;
  bool _isReloading = false;

  Future<void> _reloadPlace({bool showMessage = false}) async {
    if (_isReloading) {
      return;
    }

    setState(() {
      _isReloading = true;
    });

    try {
      final provider = placeDetailProvider(widget.placeId);

      ref.invalidate(provider);

      await ref.read(provider.future);

      if (!mounted) {
        return;
      }

      if (showMessage) {
        final locale = ref.read(languageProvider);

        final isSpanish = locale.languageCode == 'es';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isSpanish ? 'Información actualizada.' : 'Information updated.',
            ),
            duration: const Duration(milliseconds: 900),
          ),
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      final locale = ref.read(languageProvider);

      final isSpanish = locale.languageCode == 'es';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isSpanish
                ? 'No fue posible actualizar la información.'
                : 'Could not update information.',
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

  void _toggleFavorite(bool isSpanish) {
    setState(() {
      _isFavorite = !_isFavorite;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isFavorite
              ? (isSpanish ? 'Añadido a favoritos' : 'Added to favorites')
              : (isSpanish
                    ? 'Eliminado de favoritos'
                    : 'Removed from favorites'),
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(languageProvider);

    final isSpanish = locale.languageCode == 'es';

    final placeAsync = ref.watch(placeDetailProvider(widget.placeId));

    return Scaffold(
      backgroundColor: BcColors.fog,

      body: placeAsync.when(
        data: (place) {
          if (place == null) {
            return _buildNotFoundWidget(isSpanish);
          }

          return _buildContent(context, place, isSpanish);
        },

        // ==========================================================
        // LOADING
        // ==========================================================
        loading: () {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryDark),
          );
        },

        // ==========================================================
        // ERROR
        // ==========================================================
        error: (error, stackTrace) {
          debugPrint('ERROR PlaceDetailScreen: $error');

          return _buildErrorWidget(error, isSpanish);
        },
      ),
    );
  }

  // ================================================================
  // CONTENIDO
  // ================================================================

  Widget _buildContent(BuildContext context, PlaceDto place, bool isSpanish) {
    final subtitle = place.getSubtitle(isSpanish);

    final description = place.getDescription(isSpanish);

    // ==============================================================
    // PULL TO REFRESH
    // ==============================================================

    return RefreshIndicator(
      onRefresh: () {
        return _reloadPlace();
      },

      color: AppTheme.primaryDark,

      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            // ======================================================
            // CABECERA (identidad visual: foto, título y botones)
            // ======================================================
            PlaceHeroHeader(
              place: place,
              isSpanish: isSpanish,
              isFavorite: _isFavorite,
              onBack: widget.onBack,
              onToggleFavorite: () => _toggleFavorite(isSpanish),
            ),

            // ======================================================
            // DISTANCIA (origen: Plaza de Armas o ubicación)
            // ======================================================
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: PlaceDistanceCard(place: place, isSpanish: isSpanish),
            ),

            // ======================================================
            // INFORMACIÓN
            // ======================================================
            Padding(
              padding: const EdgeInsets.all(24),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  // =================================================
                  // SUBTÍTULO
                  // =================================================
                  if (subtitle.isNotEmpty) ...[
                    Text(subtitle, style: BcText.title(color: BcColors.ink)),

                    const SizedBox(height: 12),
                  ],

                  // =================================================
                  // DESCRIPCIÓN
                  // =================================================
                  if (description.isNotEmpty)
                    Text(description, style: BcText.body(color: BcColors.ink))
                  else
                    Text(
                      isSpanish
                          ? 'No hay descripción disponible.'
                          : 'No description available.',
                      style: BcText.body(color: BcColors.muted),
                    ),

                  // =================================================
                  // DIRECCIÓN
                  // =================================================
                  if (_hasValue(place.address)) ...[
                    const SizedBox(height: 20),

                    _buildInfoRow(
                      icon: Icons.location_on,
                      text: place.address!,
                    ),
                  ],

                  // =================================================
                  // HORARIO
                  // =================================================
                  if (_hasValue(place.schedule)) ...[
                    const SizedBox(height: 12),

                    _buildInfoRow(
                      icon: Icons.access_time_rounded,
                      text: place.schedule!,
                    ),
                  ],

                  // =================================================
                  // PRECIO
                  // =================================================
                  if (_hasValue(place.referencePrice)) ...[
                    const SizedBox(height: 12),

                    _buildInfoRow(
                      icon: Icons.attach_money_rounded,
                      text: place.referencePrice!,
                    ),
                  ],

                  // =================================================
                  // CONTACTO
                  // =================================================
                  if (_hasValue(place.contactInfo)) ...[
                    const SizedBox(height: 12),

                    _buildInfoRow(
                      icon: Icons.phone_rounded,
                      text: place.contactInfo!,
                    ),
                  ],

                  // =================================================
                  // WEB
                  // =================================================
                  if (_hasValue(place.websiteUrl)) ...[
                    const SizedBox(height: 12),

                    _buildInfoRow(
                      icon: Icons.language_rounded,
                      text: place.websiteUrl!,
                    ),
                  ],

                  // =================================================
                  // GALERÍA
                  // =================================================
                  if (place.media.length > 1) ...[
                    const SizedBox(height: 24),

                    Text(
                      isSpanish ? 'Galería de fotos' : 'Photo gallery',
                      style: BcText.title(color: BcColors.ink),
                    ),

                    const SizedBox(height: 12),

                    SizedBox(
                      height: 100,

                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,

                        itemCount: place.media.length,

                        separatorBuilder: (context, index) {
                          return const SizedBox(width: 10);
                        },

                        itemBuilder: (context, index) {
                          final mediaItem = place.media[index];

                          final url = mediaItem.externalUrl;

                          if (!_hasValue(url)) {
                            return const SizedBox.shrink();
                          }

                          return ClipRRect(
                            borderRadius: BorderRadius.circular(
                              BcRadius.control,
                            ),

                            child: CachedNetworkImage(
                              imageUrl: url!,

                              width: 140,

                              height: 100,

                              fit: BoxFit.cover,

                              placeholder: (context, url) {
                                return Container(
                                  width: 140,

                                  color: BcColors.surface,

                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,

                                      color: BcColors.ink,
                                    ),
                                  ),
                                );
                              },

                              errorWidget: (context, url, error) =>
                                  const SizedBox(
                                    width: 140,
                                    child: BcLogoPlaceholder(),
                                  ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  const Divider(color: BcColors.surface),

                  const SizedBox(height: 20),

                  // =================================================
                  // AVISO
                  // =================================================
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      const Icon(
                        Icons.info_outline_rounded,

                        color: BcColors.glacierDeep,

                        size: 20,
                      ),

                      const SizedBox(width: 8),

                      Expanded(
                        child: Text(
                          isSpanish
                              ? 'La información mostrada es referencial. Se recomienda verificar horarios, precios y disponibilidad directamente con el prestador antes de realizar la visita.'
                              : 'The information shown is for reference. It is recommended to verify schedules, prices and availability directly with the provider before visiting.',

                          style: BcText.body(color: BcColors.muted),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // FILA DE INFORMACIÓN
  // ================================================================

  Widget _buildInfoRow({required IconData icon, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Icon(icon, color: BcColors.glacierDeep, size: 20),

        const SizedBox(width: 8),

        Expanded(
          child: Text(text, style: BcText.body(color: BcColors.muted)),
        ),
      ],
    );
  }

  // ================================================================
  // VALIDAR TEXTO
  // ================================================================

  bool _hasValue(String? value) {
    if (value == null) {
      return false;
    }

    final normalized = value.trim();

    if (normalized.isEmpty) {
      return false;
    }

    if (normalized.toLowerCase() == 'null') {
      return false;
    }

    if (normalized.toLowerCase() == 'n/a') {
      return false;
    }

    return true;
  }

  // ================================================================
  // NO ENCONTRADO
  // ================================================================

  Widget _buildNotFoundWidget(bool isSpanish) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            const Icon(
              Icons.search_off,
              size: 60,
              color: AppTheme.textSecondary,
            ),

            const SizedBox(height: 16),

            Text(
              isSpanish ? 'Lugar no encontrado' : 'Place not found',
              style: BcText.title(color: BcColors.ink),
            ),

            const SizedBox(height: 20),

            FilledButton.icon(
              onPressed: _isReloading
                  ? null
                  : () {
                      _reloadPlace(showMessage: true);
                    },

              icon: const Icon(Icons.refresh_rounded),

              label: Text(isSpanish ? 'Reintentar' : 'Retry'),
            ),

            const SizedBox(height: 8),

            TextButton(
              onPressed: widget.onBack,

              child: Text(isSpanish ? 'Volver' : 'Back'),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // ERROR
  // ================================================================

  Widget _buildErrorWidget(Object error, bool isSpanish) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.redAccent),

            const SizedBox(height: 16),

            Text(
              isSpanish ? 'Error al cargar lugar' : 'Error loading place',
              textAlign: TextAlign.center,
              style: BcText.title(color: BcColors.ink),
            ),

            const SizedBox(height: 8),

            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: BcText.body(color: BcColors.muted),
            ),

            const SizedBox(height: 20),

            FilledButton.icon(
              onPressed: _isReloading
                  ? null
                  : () {
                      _reloadPlace(showMessage: true);
                    },

              icon: _isReloading
                  ? const SizedBox(
                      width: 18,
                      height: 18,

                      child: CircularProgressIndicator(
                        strokeWidth: 2,

                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.refresh_rounded),

              label: Text(isSpanish ? 'Reintentar' : 'Retry'),
            ),

            const SizedBox(height: 8),

            TextButton(
              onPressed: widget.onBack,

              child: Text(isSpanish ? 'Volver' : 'Back'),
            ),
          ],
        ),
      ),
    );
  }
}
