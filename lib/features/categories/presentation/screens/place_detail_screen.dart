import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/language_provider.dart';
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
  bool _isFavorite = false;

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
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryDark),
        ),
        error: (error, stack) => _buildErrorWidget(error, isSpanish),
      ),
    );
  }

  Widget _buildContent(BuildContext context, PlaceDto place, bool isSpanish) {
    final title = place.getTitle(isSpanish);
    final subtitle = place.getSubtitle(isSpanish);
    final description = place.getDescription(isSpanish);
    final imageUrl = place.imageUrl ??
        'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&w=800&q=80';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Image Stack
          Stack(
            children: [
              Container(
                height: 380,
                width: double.infinity,
                color: AppTheme.primaryDark,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(color: AppTheme.primaryDark),
                ),
              ),
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
              Positioned(
                top: 48,
                left: 16,
                child: CircleAvatar(
                  backgroundColor: Colors.white.withValues(alpha: 0.85),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
                    onPressed: widget.onBack,
                  ),
                ),
              ),
              Positioned(
                top: 48,
                right: 16,
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.white.withValues(alpha: 0.85),
                      child: IconButton(
                        icon: Icon(
                          _isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: _isFavorite ? const Color(0xFFD32F2F) : AppTheme.primaryDark,
                        ),
                        onPressed: () {
                          setState(() {
                            _isFavorite = !_isFavorite;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(_isFavorite
                                  ? (isSpanish ? 'Añadido a favoritos' : 'Added to favorites')
                                  : (isSpanish ? 'Eliminado de favoritos' : 'Removed from favorites')),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    CircleAvatar(
                      backgroundColor: Colors.white.withValues(alpha: 0.85),
                      child: IconButton(
                        icon: const Icon(Icons.share, color: AppTheme.primaryDark),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isSpanish ? 'Enlace compartido' : 'Link shared'),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 24,
                left: 24,
                right: 24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryDark,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        (place.categorySlug != null && place.categorySlug!.isNotEmpty
                            ? place.categorySlug!
                            : (place.category?.slug ?? 'ATRACTIVO')).toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
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
          // Body Details
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (subtitle.isNotEmpty) ...[
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Text(
                  description.isNotEmpty
                      ? description
                      : (isSpanish
                          ? 'Ubicado en la Patagonia chilena, este lugar destaca por su calidad y atención a visitantes.'
                          : 'Located in Chilean Patagonia, this place stands out for its quality and warm service.'),
                  style: const TextStyle(
                    color: Color(0xFF4A4A4A),
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                if (place.address != null && place.address!.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: AppTheme.primaryDark, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          place.address!,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (place.schedule != null && place.schedule!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.access_time_rounded, color: AppTheme.primaryDark, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          place.schedule!,
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ],
                if (place.referencePrice != null && place.referencePrice!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.attach_money_rounded, color: AppTheme.primaryDark, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          place.referencePrice!,
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ],
                if (place.contactInfo != null && place.contactInfo!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.phone_rounded, color: AppTheme.primaryDark, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          place.contactInfo!,
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ],
                if (place.websiteUrl != null && place.websiteUrl!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.language_rounded, color: AppTheme.primaryDark, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          place.websiteUrl!,
                          style: const TextStyle(color: AppTheme.primaryDark, fontSize: 14, decoration: TextDecoration.underline),
                        ),
                      ),
                    ],
                  ),
                ],
                if (place.media.length > 1) ...[
                  const SizedBox(height: 24),
                  Text(
                    isSpanish ? 'Galería de Fotos' : 'Photo Gallery',
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
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, idx) {
                        final mediaItem = place.media[idx];
                        final url = mediaItem.externalUrl;
                        if (url == null || url.isEmpty) return const SizedBox.shrink();
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: url,
                            width: 140,
                            height: 100,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Container(
                              width: 140,
                              color: Colors.grey[200],
                              child: const Icon(Icons.broken_image),
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
                Text(
                  isSpanish ? 'Información Adicional' : 'Additional Information',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isSpanish
                      ? 'Disponible durante todo el año en la Región de Aysén. Se recomienda verificar horarios y condiciones climáticas antes de tu visita.'
                      : 'Available year-round in the Aysén Region. Checking schedules and weather conditions prior to visit is recommended.',
                  style: const TextStyle(
                    color: Color(0xFF7F8C8D),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFoundWidget(bool isSpanish) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 60, color: AppTheme.textSecondary),
          const SizedBox(height: 16),
          Text(
            isSpanish ? 'Lugar no encontrado' : 'Place not found',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: widget.onBack,
            child: Text(isSpanish ? 'Volver' : 'Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(Object error, bool isSpanish) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.redAccent),
          const SizedBox(height: 16),
          Text(
            isSpanish ? 'Error al cargar lugar' : 'Error loading place',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(error.toString(), style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: widget.onBack,
            child: Text(isSpanish ? 'Volver' : 'Back'),
          ),
        ],
      ),
    );
  }
}
