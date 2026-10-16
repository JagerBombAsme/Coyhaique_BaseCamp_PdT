import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/category_model.dart';
import '../../../../core/utils/language_provider.dart';
import '../../../categories/data/providers/places_provider.dart';
import '../../../routes/data/models/route_dto.dart';
import '../../../routes/data/providers/route_provider.dart';
import '../widgets/categories_section.dart';
import '../widgets/destination_hero.dart';
import '../widgets/tours_section.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final Function(String route) onNavigate;
  final VoidCallback onProfileClick;

  const HomeScreen({
    super.key,
    required this.onNavigate,
    required this.onProfileClick,
  });

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(languageProvider);
    final language = locale.languageCode;
    final isSpanish = language == 'es';

    final routesAsync = ref.watch(routesProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF211F22),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(routesProvider);
          ref.invalidate(categoriesProvider);
          ref.invalidate(placesProvider);
        },
        color: Colors.white,
        backgroundColor: const Color(0xFF2C2A2F),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Principal estilo Tenerife / Destino
              DestinationHero(
                title: 'Coyhaique',
                description: isSpanish
                    ? 'Coyhaique ofrece vistas a la montaña, ríos patagónicos y un entorno natural inigualable. Perfecto tanto para descansar como para la aventura.'
                    : 'Coyhaique offers mountain views, Patagonian rivers, and an unmatched natural setting. Perfect for both relaxing and active trips.',
                imagePath: 'assets/images/cerro_castillo_laguna.jpg',
              ),

              const SizedBox(height: 28),

              // Sección de Tours horizontales
              routesAsync.when(
                data: (routes) {
                  final items = routes.isNotEmpty
                      ? routes.map((r) => _mapRouteToTourItem(r, isSpanish)).toList()
                      : _buildFallbackTourItems(isSpanish);

                  return ToursSection(
                    title: 'Tours',
                    viewAllText: isSpanish ? 'Ver todos' : 'View all',
                    items: items,
                    onViewAll: () => widget.onNavigate('aventura'),
                  );
                },
                loading: () => ToursSection(
                  title: 'Tours',
                  viewAllText: isSpanish ? 'Ver todos' : 'View all',
                  items: _buildFallbackTourItems(isSpanish),
                  onViewAll: () => widget.onNavigate('aventura'),
                ),
                error: (error, stackTrace) => ToursSection(
                  title: 'Tours',
                  viewAllText: isSpanish ? 'Ver todos' : 'View all',
                  items: _buildFallbackTourItems(isSpanish),
                  onViewAll: () => widget.onNavigate('aventura'),
                ),
              ),

              const SizedBox(height: 32),

              // Sección de Categorías
              categoriesAsync.when(
                data: (categories) {
                  final activeCategories = categories.where((c) => c.isActive).toList();
                  final list = activeCategories.isNotEmpty ? activeCategories : homeCategories;

                  return CategoriesSection(
                    title: isSpanish ? 'Explorar' : 'Explore',
                    categories: list,
                    language: language,
                    onCategoryTap: widget.onNavigate,
                  );
                },
                loading: () => CategoriesSection(
                  title: isSpanish ? 'Explorar' : 'Explore',
                  categories: homeCategories,
                  language: language,
                  onCategoryTap: widget.onNavigate,
                ),
                error: (error, stackTrace) => CategoriesSection(
                  title: isSpanish ? 'Explorar' : 'Explore',
                  categories: homeCategories,
                  language: language,
                  onCategoryTap: widget.onNavigate,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TourItemData _mapRouteToTourItem(RouteDto route, bool isSpanish) {
    String imagePath;
    if (route.imageUrl != null &&
        route.imageUrl!.isNotEmpty &&
        !route.imageUrl!.contains('example.com')) {
      imagePath = route.imageUrl!;
    } else {
      final title = route.titleEs.toLowerCase();
      if (title.contains('castillo')) {
        imagePath = 'assets/images/cerro_castillo_panoramico.jpg';
      } else if (title.contains('divisadero')) {
        imagePath = 'assets/images/cordon_divisadero.jpg';
      } else if (title.contains('leñero') || title.contains('lenero')) {
        imagePath = 'assets/images/sendero_leneros.jpg';
      } else if (title.contains('mirador')) {
        imagePath = 'assets/images/miradores_coyhaique.jpg';
      } else if (title.contains('marmol') || title.contains('mármol')) {
        imagePath = 'assets/images/catedral_de_marmol.jpg';
      } else if (title.contains('queulat')) {
        imagePath = 'assets/images/ventisquero_queulat.jpg';
      } else {
        imagePath = 'assets/images/cerro_castillo_panoramico.jpg';
      }
    }

    return TourItemData(
      id: route.id,
      title: route.getTitle(isSpanish),
      imagePath: imagePath,
      subtitle:
          '${route.duration} • ${isSpanish ? route.difficultyEs : (route.difficultyEn ?? route.difficultyEs)}',
      onTap: () {
        widget.onNavigate('aventura');
      },
    );
  }

  List<TourItemData> _buildFallbackTourItems(bool isSpanish) {
    return [
      TourItemData(
        id: '1',
        title: isSpanish ? 'Capillas de Mármol' : 'Marble Caves',
        imagePath: 'assets/images/catedral_de_marmol.jpg',
        subtitle: isSpanish
            ? 'Lago Gral. Carrera • Excursión lacustre'
            : 'Gral. Carrera Lake • Boat tour',
        onTap: () => widget.onNavigate('aventura'),
      ),
      TourItemData(
        id: '2',
        title: isSpanish
            ? 'Ventisquero Colgante Queulat'
            : 'Queulat Hanging Glacier',
        imagePath: 'assets/images/ventisquero_queulat.jpg',
        subtitle: isSpanish
            ? 'Parque Nacional • Sendero Glaciar'
            : 'National Park • Glacier Trail',
        onTap: () => widget.onNavigate('aventura'),
      ),
      TourItemData(
        id: '3',
        title: isSpanish
            ? 'Trekking Laguna Cerro Castillo'
            : 'Cerro Castillo Lagoon Trek',
        imagePath: 'assets/images/cerro_castillo_panoramico.jpg',
        subtitle: isSpanish ? '8h 00m • Alta exigencia' : '8h 00m • High difficulty',
        onTap: () => widget.onNavigate('aventura'),
      ),
      TourItemData(
        id: '4',
        title: isSpanish ? 'Cordón Divisadero' : 'Divisadero Ridge',
        imagePath: 'assets/images/cordon_divisadero.jpg',
        subtitle: isSpanish ? '4h 30m • Dificultad media' : '4h 30m • Medium difficulty',
        onTap: () => widget.onNavigate('aventura'),
      ),
      TourItemData(
        id: '5',
        title: isSpanish ? 'Miradores de Coyhaique' : 'Coyhaique Viewpoints',
        imagePath: 'assets/images/miradores_coyhaique.jpg',
        subtitle: isSpanish ? '2h 30m • Dificultad baja' : '2h 30m • Low difficulty',
        onTap: () => widget.onNavigate('aventura'),
      ),
    ];
  }
}
