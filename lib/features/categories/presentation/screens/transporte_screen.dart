import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/language_provider.dart';
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

    final items = [
      const CategoryItem(
        id: 'trans_1',
        title: 'Transfer Aeropuerto Balmaceda',
        subtitle: 'Servicio Diario Directo',
        description: 'Transporte de pasajeros desde y hacia el aeropuerto.',
        imageUrl: 'https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?auto=format&fit=crop&w=600&q=80',
      ),
      const CategoryItem(
        id: 'trans_2',
        title: 'Buses Suray',
        subtitle: 'Terminal de Buses',
        description: 'Conexión Coyhaique - Puerto Aysén - Chaitén.',
        imageUrl: 'https://images.unsplash.com/photo-1570125909232-eb263c188f7e?auto=format&fit=crop&w=600&q=80',
      ),
    ];

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
  }
}
