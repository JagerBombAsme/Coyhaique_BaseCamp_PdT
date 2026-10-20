import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/language_provider.dart';
import '../../data/providers/places_provider.dart';
import 'category_list_screen.dart';

class TransporteScreen extends ConsumerWidget {
  final ValueChanged<String> onPlaceClick;

  const TransporteScreen({
    super.key,
    required this.onPlaceClick,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(languageProvider);
    final isSpanish = locale.languageCode == 'es';
    final placesAsync = ref.watch(placesByCategoryProvider('transporte'));

    return placesAsync.when(
      data: (places) {
        final items = places.map((p) => CategoryItem(
          id: p.id,
          title: p.getTitle(isSpanish),
          subtitle: p.getSubtitle(isSpanish),
          description: p.getDescription(isSpanish),
          imageUrl: p.imageUrl ?? 'https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?auto=format&fit=crop&w=600&q=80',
        )).toList();

        return CategoryListScreen(
          title: isSpanish ? 'Transportes de\nCoyhaique' : 'Transport in\nCoyhaique',
          subtitle: isSpanish
              ? 'Viajes, rutas y transporte desde y hacia el aeropuerto.'
              : 'Trips, routes and transport to and from the airport.',
          searchPlaceholder: isSpanish ? 'Buscar transporte...' : 'Search transport...',
          tabs: isSpanish
              ? ['Todos', 'Viajes', 'Transfers', 'Rutas']
              : ['All', 'Trips', 'Transfers', 'Routes'],
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
