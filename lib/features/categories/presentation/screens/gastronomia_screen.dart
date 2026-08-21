import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/language_provider.dart';
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

    final items = [
      const CategoryItem(
        id: 'gastro_1',
        title: 'Restaurante El Fogón',
        subtitle: 'Coyhaique Centro',
        description: 'Especialidad en asado al palo y carnes patagónicas.',
        imageUrl: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&w=600&q=80',
      ),
      const CategoryItem(
        id: 'gastro_2',
        title: 'Café de la Plaza',
        subtitle: 'Plaza de Armas',
        description: 'Repostería artesanal, chocolates y café de especialidad.',
        imageUrl: 'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?auto=format&fit=crop&w=600&q=80',
      ),
      const CategoryItem(
        id: 'gastro_3',
        title: 'Cervecería D\'Olbek',
        subtitle: 'Camino a Simpson',
        description: 'Cerveza artesanal patagónica y tablas para compartir.',
        imageUrl: 'https://images.unsplash.com/photo-1514933651103-005eec06c04b?auto=format&fit=crop&w=600&q=80',
      ),
    ];

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
  }
}
