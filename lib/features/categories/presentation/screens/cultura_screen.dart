import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/language_provider.dart';
import '../../data/providers/places_provider.dart';
import 'category_list_screen.dart';

class CulturaScreen extends ConsumerWidget {
  final ValueChanged<String> onPlaceClick;

  const CulturaScreen({
    super.key,
    required this.onPlaceClick,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(languageProvider);
    final isSpanish = locale.languageCode == 'es';
    final placesAsync = ref.watch(placesByCategoryProvider('cultura'));

    return placesAsync.when(
      data: (places) {
        final items = places.map((p) => CategoryItem(
          id: p.id,
          title: p.getTitle(isSpanish),
          subtitle: p.getSubtitle(isSpanish),
          description: p.getDescription(isSpanish),
          imageUrl: p.imageUrl ?? 'https://images.unsplash.com/photo-1565008447742-97f6f38c985c?auto=format&fit=crop&w=600&q=80',
        )).toList();

        return CategoryListScreen(
          title: isSpanish ? 'Cultura y\nPatrimonio' : 'Culture and\nHeritage',
          subtitle: isSpanish
              ? 'Museos, monumentos y tradiciones de Coyhaique.'
              : 'Museums, monuments and traditions of Coyhaique.',
          searchPlaceholder: isSpanish ? 'Buscar cultura...' : 'Search culture...',
          tabs: isSpanish
              ? ['Todos', 'Museo', 'Monumento', 'Tradición']
              : ['All', 'Museum', 'Monument', 'Tradition'],
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
