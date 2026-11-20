import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/basecamp_tokens.dart';
import '../../../../core/widgets/basecamp/bc_widgets.dart';
import '../../../../core/local/catalog_local_db.dart';
import '../../../../core/providers/language_provider.dart';

import '../../data/models/place_dto.dart';
import '../../data/providers/places_provider.dart';

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

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(languageProvider);

    final isSpanish = locale.languageCode == 'es';

    final placeAsync = ref.watch(placeDetailProvider(widget.placeId));

    return Scaffold(
      backgroundColor: const Color(0xFFFDFCFB),

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
    final title = place.getTitle(isSpanish);

    final subtitle = place.getSubtitle(isSpanish);

    final description = place.getDescription(isSpanish);

    // El subtítulo cae en la descripción o en la dirección cuando no hay uno
    // propio; en ese caso se omite para no repetir el mismo texto (C-04).
    final showSubtitle = subtitle.trim().isNotEmpty &&
        subtitle.trim() != description.trim() &&
        subtitle.trim() != (place.address ?? '').trim();

    final imageUrl = place.imageUrl;

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
            Stack(
              children: [
                Container(
                  height: 380,

                  width: double.infinity,

                  color: AppTheme.primaryDark,

                  child: _buildMainImage(imageUrl),
                ),

                // ==================================================
                // GRADIENTE
                // ==================================================
                Container(
                  height: 380,

                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,

                      end: Alignment.bottomCenter,

                      colors: [Colors.transparent, Colors.black87],

                      stops: [0.5, 1.0],
                    ),
                  ),
                ),

                // ==================================================
                // VOLVER
                // ==================================================
                Positioned(
                  top: 48,

                  left: 16,

                  child: CircleAvatar(
                    backgroundColor: Colors.white.withValues(alpha: 0.85),

                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back,

                        color: AppTheme.textPrimary,
                      ),

                      onPressed: widget.onBack,
                    ),
                  ),
                ),

                // ==================================================
                // ACCIONES
                // ==================================================
                Positioned(
                  top: 48,

                  right: 16,

                  child: Row(
                    children: [
                      // ============================================
                      // RECARGAR
                      // ============================================
                      CircleAvatar(
                        backgroundColor: Colors.white.withValues(alpha: 0.85),

                        child: IconButton(
                          tooltip: isSpanish ? 'Actualizar' : 'Refresh',

                          onPressed: _isReloading
                              ? null
                              : () {
                                  _reloadPlace(showMessage: true);
                                },

                          icon: _isReloading
                              ? const SizedBox(
                                  width: 19,
                                  height: 19,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.primaryDark,
                                  ),
                                )
                              : const Icon(
                                  Icons.refresh_rounded,
                                  color: AppTheme.primaryDark,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ==================================================
                // TÍTULO SOBRE IMAGEN
                // ==================================================
                Positioned(
                  bottom: 24,

                  left: 24,

                  right: 24,

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,

                          vertical: 4,
                        ),

                        decoration: BoxDecoration(
                          color: AppTheme.primaryDark,

                          borderRadius: BorderRadius.circular(8),
                        ),

                        child: Text(
                          (place.categorySlug != null &&
                                      place.categorySlug!.isNotEmpty
                                  ? place.categorySlug!
                                  : (place.category?.slug ??
                                        (isSpanish ? 'LUGAR' : 'PLACE')))
                              .toUpperCase(),

                          style: const TextStyle(
                            color: Colors.white,

                            fontSize: 11,

                            fontWeight: FontWeight.bold,

                            letterSpacing: 1,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        title,

                        style: const TextStyle(
                          color: Colors.white,

                          fontSize: 28,

                          fontWeight: FontWeight.bold,

                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
                  if (showSubtitle) ...[
                    Text(subtitle, style: BcText.title(color: BcColors.ink)),
                    const SizedBox(height: 12),
                  ],

                  // =================================================
                  // DESCRIPCIÓN
                  // =================================================
                  if (description.isNotEmpty)
                    Text(
                      description,

                      style: const TextStyle(
                        color: Color(0xFF4A4A4A),

                        fontSize: 16,

                        height: 1.5,
                      ),
                    )
                  else
                    Text(
                      isSpanish
                          ? 'No hay descripción disponible.'
                          : 'No description available.',

                      style: const TextStyle(
                        color: AppTheme.textSecondary,

                        fontSize: 14,

                        fontStyle: FontStyle.italic,
                      ),
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

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        const Icon(
                          Icons.language_rounded,

                          color: AppTheme.primaryDark,

                          size: 20,
                        ),

                        const SizedBox(width: 8),

                        Expanded(
                          child: Text(
                            place.websiteUrl!,

                            style: const TextStyle(
                              color: AppTheme.primaryDark,

                              fontSize: 14,

                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // =================================================
                  // GALERÍA
                  // =================================================
                  if (place.media.length > 1) ...[
                    const SizedBox(height: 24),

                    Text(
                      isSpanish ? 'Galería de fotos' : 'Photo gallery',

                      style: const TextStyle(
                        fontSize: 17,

                        fontWeight: FontWeight.bold,

                        color: Color(0xFF2C3E50),
                      ),
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
                            borderRadius: BorderRadius.circular(12),

                            child: CachedNetworkImage(
                              imageUrl: url!,

                              width: 140,

                              height: 100,

                              fit: BoxFit.cover,

                              placeholder: (context, url) {
                                return Container(
                                  width: 140,

                                  color: Colors.grey[200],

                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,

                                      color: AppTheme.primaryDark,
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

                  const Divider(color: Color(0xFFEEEEEE)),

                  const SizedBox(height: 20),

                  // =================================================
                  // AVISO
                  // =================================================
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            color: AppTheme.primaryDark,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isSpanish
                                  ? 'La información mostrada es referencial. Se recomienda verificar horarios, precios y disponibilidad directamente con el prestador antes de realizar la visita.'
                                  : 'The information shown is for reference. It is recommended to verify schedules, prices and availability directly with the provider before visiting.',
                              style: const TextStyle(
                                color: Color(0xFF7F8C8D),
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(left: 28),
                        child: Text(
                          _verificationText(place.lastVerifiedDate, isSpanish),
                          style: const TextStyle(
                            color: Color(0xFF7F8C8D),
                            fontSize: 14,
                            height: 1.4,
                          ),
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
  // IMAGEN PRINCIPAL
  // ================================================================

  Widget _buildMainImage(String? imageUrl) {
    // Sin foto o con error: logo BC sobre tinta (sistema Coyhaique BaseCamp).
    if (!_hasValue(imageUrl)) return const BcLogoPlaceholder();

    return CachedNetworkImage(
      imageUrl: imageUrl!,
      fit: BoxFit.cover,
      placeholder: (context, url) =>
          const BcLogoPlaceholder(showProgress: true),
      errorWidget: (context, url, error) => const BcLogoPlaceholder(),
    );
  }

  // ================================================================
  // FILA DE INFORMACIÓN
  // ================================================================

  Widget _buildInfoRow({required IconData icon, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Icon(icon, color: AppTheme.primaryDark, size: 20),

        const SizedBox(width: 8),

        Expanded(
          child: Text(
            text,

            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
        ),
      ],
    );
  }

  // ================================================================
  // VALIDAR TEXTO
  // ================================================================
  String _verificationText(DateTime? date, bool isSpanish) {
    if (date == null) {
      return isSpanish
          ? 'Fecha de verificación no disponible.'
          : 'Verification date not available.';
    }
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final formatted = '$day-$month-${date.year}';
    return isSpanish
        ? 'Fecha de verificación: $formatted'
        : 'Verification date: $formatted';
  }

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

              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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

  /// Texto para el usuario según el tipo de fallo; el detalle técnico queda
  /// solo en el registro (debugPrint en `build`).
  String _errorMessage(Object error, bool isSpanish) {
    if (error is CatalogUnavailableException) {
      return isSpanish
          ? 'No hay conexión ni información descargada. '
              'Conéctate a Internet y vuelve a intentarlo.'
          : 'No connection and no downloaded information. '
              'Connect to the Internet and try again.';
    }
    return isSpanish
        ? 'No fue posible mostrar este lugar. Inténtalo de nuevo.'
        : 'This place could not be displayed. Please try again.';
  }

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

              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Text(
              _errorMessage(error, isSpanish),

              textAlign: TextAlign.center,

              style: const TextStyle(
                fontSize: 12,

                color: AppTheme.textSecondary,
              ),
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
