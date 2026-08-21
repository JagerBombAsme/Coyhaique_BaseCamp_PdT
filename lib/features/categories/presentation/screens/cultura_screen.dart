import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/language_provider.dart';
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

    final items = [
      const CategoryItem(
        id: 'cult_1',
        title: 'Museo Regional de Aysén',
        subtitle: 'Sector Escuela Agrícola',
        description: 'Patrimonio e historia del poblamiento patagónico.',
        imageUrl: 'https://images.unsplash.com/photo-1565008447742-97f6f38c985c?auto=format&fit=crop&w=600&q=80',
      ),
      const CategoryItem(
        id: 'cult_2',
        title: 'Monumento al Ovejero',
        subtitle: 'Entrada Norte Coyhaique',
        description: 'Homenaje a los pioneros y trabajadores de la Patagonia.',
        imageUrl: 'https://images.unsplash.com/photo-1541872703-74c5e44368f9?auto=format&fit=crop&w=600&q=80',
      ),
    ];

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
  }
}
