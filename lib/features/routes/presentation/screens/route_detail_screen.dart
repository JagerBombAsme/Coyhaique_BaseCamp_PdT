import '../../../../core/widgets/basecamp/bc_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/language_provider.dart';
import '../../data/providers/route_provider.dart';

class RouteDetailScreen extends ConsumerWidget {
  final String routeId;

  const RouteDetailScreen({
    super.key,
    required this.routeId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(languageProvider);
    final isSpanish = locale.languageCode == 'es';
    final routeAsync = ref.watch(routeDetailProvider(routeId));

    return Scaffold(
      backgroundColor: const Color(0xFFFDFCFB),
      appBar: AppBar(
        title: Text(isSpanish ? 'Detalle de Ruta' : 'Route Details'),
        backgroundColor: Colors.white,
      ),
      body: routeAsync.when(
        data: (route) {
          if (route == null) {
            return Center(
              child: Text(isSpanish ? 'Ruta no encontrada' : 'Route not found'),
            );
          }

          final title = route.getTitle(isSpanish);
          final description = route.getDescription(isSpanish);
          final difficulty = route.getDifficulty(isSpanish);
          final imageUrl = route.imageUrl;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: SizedBox(
                    height: 240,
                    width: double.infinity,
                    child: BcPhotoImage(
                      source: imageUrl ?? '',
                      fallbackCategory: 'ruta',
                      isSpanish: isSpanish,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.accentLightBlue,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        difficulty,
                        style: const TextStyle(
                          color: AppTheme.accentBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.timer, color: AppTheme.primaryDark, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      '${isSpanish ? 'Duración:' : 'Duration:'} ${route.duration}',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    if (route.distanceKm != null) ...[
                      const SizedBox(width: 20),
                      const Icon(Icons.straighten, color: AppTheme.primaryDark, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        '${isSpanish ? 'Distancia:' : 'Distance:'} ${route.distanceKm} km',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  isSpanish ? 'Descripción de la Ruta' : 'Route Description',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text(
            isSpanish
                ? 'No fue posible mostrar esta ruta.'
                : 'This route could not be displayed.',
          ),
        ),
      ),
    );
  }
}
