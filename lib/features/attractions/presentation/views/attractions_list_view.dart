import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../categories/data/providers/places_provider.dart';

/// Listado de atractivos (HU-01 / HU-03) según USER_FLOWS.md
class AttractionsListView extends ConsumerWidget {
  final String? initialCategory;

  const AttractionsListView({super.key, this.initialCategory});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(languageProvider);
    final isSpanish = locale.languageCode == 'es';
    final placesAsync = initialCategory != null && initialCategory!.isNotEmpty
        ? ref.watch(placesByCategoryProvider(initialCategory!))
        : ref.watch(placesProvider);

    return Scaffold(
      backgroundColor: AppTheme.slateLight,
      appBar: AppBar(
        title: Text(
          isSpanish ? 'Atractivos Turísticos' : 'Tourist Attractions',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
      ),
      body: placesAsync.when(
        data: (places) {
          if (places.isEmpty) {
            return Center(
              child: Text(
                isSpanish
                    ? 'No se encontraron atractivos en esta categoría.'
                    : 'No attractions found in this category.',
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: places.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final place = places[index];
              final title = place.getTitle(isSpanish);
              final subtitle = place.getSubtitle(isSpanish);
              final description = place.getDescription(isSpanish);

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => context.push('/attractions/${place.id}'),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey[200],
                            child: place.imageUrl != null && place.imageUrl!.isNotEmpty
                                ? Image.network(
                                    place.imageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => const Icon(Icons.broken_image),
                                  )
                                : const Icon(Icons.place, color: AppTheme.primaryDark),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                subtitle,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.primaryDark,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryDark),
        ),
        error: (error, _) => Center(
          child: Text(
            isSpanish ? 'Error al cargar atractivos' : 'Error loading attractions',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }
}
