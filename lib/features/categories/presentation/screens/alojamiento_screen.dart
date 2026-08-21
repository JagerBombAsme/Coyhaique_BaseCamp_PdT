import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/language_provider.dart';
import 'category_list_screen.dart';

class AlojamientoScreen extends ConsumerWidget {
  final ValueChanged<String> onPlaceClick;

  const AlojamientoScreen({
    super.key,
    required this.onPlaceClick,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(languageProvider);
    final isSpanish = locale.languageCode == 'es';

    final items = [
      const CategoryItem(
        id: 'aloja_1',
        title: 'Hotel Diego de Almagro',
        subtitle: 'Av. O\'Higgins 42',
        description: 'Hotel 4 estrellas con vista al valle.',
        imageUrl: 'https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=600&q=80',
      ),
      const CategoryItem(
        id: 'aloja_2',
        title: 'Cabañas Alto Coyhaique',
        subtitle: 'Camino a Reserva Nacional',
        description: 'Cabañas totalmente equipadas en plena naturaleza.',
        imageUrl: 'https://images.unsplash.com/photo-1587061949409-02df41d5e562?auto=format&fit=crop&w=600&q=80',
      ),
    ];

    return CategoryListScreen(
      title: isSpanish ? 'Encuentra tu\nalojamiento' : 'Find your\naccommodation',
      subtitle: isSpanish
          ? 'Hoteles, hostales y cabañas disponibles en Coyhaique.'
          : 'Hotels, hostels and cabins available in Coyhaique.',
      searchPlaceholder: isSpanish ? 'Buscar alojamiento...' : 'Search accommodation...',
      tabs: isSpanish
          ? ['Todos', 'Hoteles', 'Hostales', 'Cabañas']
          : ['All', 'Hotels', 'Hostels', 'Cabins'],
      selectedTab: isSpanish ? 'Todos' : 'All',
      featuredItems: items,
      popularItems: items,
      onItemClick: (item) => onPlaceClick(item.id),
    );
  }
}
