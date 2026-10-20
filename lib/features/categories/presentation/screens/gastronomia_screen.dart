import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/language_provider.dart';
import '../../data/providers/places_provider.dart';
import 'category_list_screen.dart';

class GastronomiaScreen extends ConsumerWidget {
  final ValueChanged<String> onPlaceClick;

  const GastronomiaScreen({
    super.key,
    required this.onPlaceClick,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(languageProvider);
    final isSpanish = locale.languageCode == 'es';
    final placesAsync = ref.watch(placesByCategoryProvider('gastronomia'));

    return placesAsync.when(
      data: (places) {
        final items = places.map((p) => CategoryItem(
          id: p.id,
          title: p.getTitle(isSpanish),
          subtitle: p.getSubtitle(isSpanish),
          description: p.getDescription(isSpanish),
          imageUrl: p.imageUrl ?? 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&w=600&q=80',
        )).toList();

        return CategoryListScreen(
          title: isSpanish ? 'Sabores de\nCoyhaique' : 'Flavors of\nCoyhaique',
          subtitle: isSpanish
              ? 'Restaurantes, cafeterías y comida típica de la Patagonia.'
              : 'Restaurants, cafes and typical food of Patagonia.',
          searchPlaceholder: isSpanish ? 'Buscar gastronomía...' : 'Search gastronomy...',
          tabs: isSpanish
              ? ['Todos', 'Restaurantes', 'Cafeterías', 'Comida típica']
              : ['All', 'Restaurants', 'Cafes', 'Traditional food'],
          selectedTab: isSpanish ? 'Todos' : 'All',
          featuredItems: items,
          popularItems: items,
          onItemClick: (item) => onPlaceClick(item.id),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        body: Center(child: Text(err.toString())),
      ),
    );
  }
}
