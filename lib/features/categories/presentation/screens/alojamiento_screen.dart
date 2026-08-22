import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/language_provider.dart';
import '../../data/providers/places_provider.dart';
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
    final placesAsync = ref.watch(placesByCategoryProvider('alojamientos'));

    return placesAsync.when(
      data: (places) {
        final items = places.map((p) => CategoryItem(
          id: p.id,
          title: p.getTitle(isSpanish),
          subtitle: p.getSubtitle(isSpanish),
          description: p.getDescription(isSpanish),
          imageUrl: p.imageUrl ?? 'https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=600&q=80',
        )).toList();

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
