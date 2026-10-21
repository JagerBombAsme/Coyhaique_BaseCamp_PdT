import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/category_model.dart';
import '../../../../core/providers/language_provider.dart';
import '../../data/providers/places_provider.dart';
import 'category_list_screen.dart';

class CategoryPlacesScreen extends ConsumerWidget {
  final CategoryModel category;
  final ValueChanged<String> onPlaceClick;

  const CategoryPlacesScreen({
    super.key,
    required this.category,
    required this.onPlaceClick,
  });

  static const Color _refreshColor = Color(0xFF2E5F73);

  /// Recarga los lugares de la categoría.
  /// Devuelve un Future para que el indicador se oculte al terminar.
  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(placesByCategoryProvider(category.id));

    try {
      await ref.read(placesByCategoryProvider(category.id).future);
    } catch (_) {
      // El error se muestra en pantalla con el botón "Reintentar".
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(languageProvider);
    final language = locale.languageCode;
    final isSpanish = language == 'es';

    // category.id es la FK de places_v2.category_id
    final placesAsync = ref.watch(placesByCategoryProvider(category.id));

    return placesAsync.when(
      // Mientras se recarga, se mantiene la lista visible
      // (si no, el spinner reemplazaría la pantalla y cortaría el gesto).
      skipLoadingOnRefresh: true,
      skipLoadingOnReload: true,

      data: (places) {
        final items = places.map((place) {
          return CategoryItem(
            id: place.id,
            title: place.getTitle(isSpanish),
            subtitle: place.getSubtitle(isSpanish),
            description: place.getDescription(isSpanish),
            imageUrl: place.imageUrl,
          );
        }).toList();

        final description = category.getDescripcion(language).trim();

        return RefreshIndicator(
          onRefresh: () => _refresh(ref),
          color: _refreshColor,
          backgroundColor: Colors.white,
          child: CategoryListScreen(
            title: category.getNombre(language),
            subtitle: description.isNotEmpty
                ? description
                : isSpanish
                    ? 'Información disponible en Coyhaique.'
                    : 'Available information in Coyhaique.',
            searchPlaceholder: isSpanish ? 'Buscar...' : 'Search...',
            tabs: [isSpanish ? 'Todos' : 'All'],
            selectedTab: isSpanish ? 'Todos' : 'All',
            featuredItems: items,

            // No inventamos popularidad. Por ahora queda vacío.
            popularItems: const [],

            onItemClick: (item) => onPlaceClick(item.id),
            onReload: () => _refresh(ref),
          ),
        );
      },

      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),

      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: RefreshIndicator(
          onRefresh: () => _refresh(ref),
          color: _refreshColor,
          // ListView para que el gesto de deslizar funcione también aquí.
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            children: [
              SizedBox(height: MediaQuery.sizeOf(context).height * 0.25),
              Text(
                isSpanish
                    ? 'No fue posible cargar la información.'
                    : 'Could not load information.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Center(
                child: FilledButton(
                  onPressed: () => _refresh(ref),
                  child: Text(isSpanish ? 'Reintentar' : 'Retry'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}