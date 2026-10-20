import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/category_model.dart';
import '../../../../core/providers/language_provider.dart';

import '../../../categories/data/providers/places_provider.dart'
    hide activitiesProvider;

import '../../../routes/data/models/activity_dto.dart';
import '../../../routes/data/providers/activity_provider.dart';

import '../widgets/categories_section.dart';
import '../widgets/destination_hero.dart';
import '../widgets/glass_icon_button.dart';
import '../widgets/home_surface.dart';
import '../widgets/home_visual_tokens.dart';
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
  static const _statusBarStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  );

  static const Color _snowWhite = Color(0xFFF8FCFE);

  static const Color _pureWhite = Color(0xFFFFFFFF);

  static const Color _iceBlue = Color(0xFFDFF4FF);

  static const Color _iceBlueMedium = Color(0xFFBFE8F8);

  static const Color _iceAccent = Color(0xFF5FA8C6);

  static const Color _iceDark = Color(0xFF2E5F73);

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(languageProvider);

    final language = locale.languageCode;

    final isSpanish = language == 'es';

    // ================================================================
    // SUPABASE - ACTIVIDADES
    // ================================================================

    final activitiesAsync = ref.watch(activitiesProvider);

    // ================================================================
    // CATEGORÍAS
    // ================================================================

    final categoriesAsync = ref.watch(categoriesProvider);

    final activeCategories = categoriesAsync.maybeWhen(
      data: (value) => value.where((category) => category.isActive).toList(),
      orElse: () => <CategoryModel>[],
    );

    final categoryList = activeCategories.isNotEmpty
        ? activeCategories
        : homeCategories;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _statusBarStyle,
      child: Scaffold(
        backgroundColor: _snowWhite,
        body: Stack(
          children: [
            // =========================================================
            // FONDO
            // =========================================================
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [_iceBlue, _snowWhite, _pureWhite],
                    stops: [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),

            // =========================================================
            // CONTENIDO
            // =========================================================
            RefreshIndicator(
              onRefresh: () async {
                // Refresca las actividades
                // provenientes de places_v2.
                ref.invalidate(activitiesProvider);

                ref.invalidate(categoriesProvider);

                ref.invalidate(placesProvider);

                // Esperamos a que las actividades
                // vuelvan a cargarse.
                await ref.read(activitiesProvider.future);
              },
              color: _iceDark,
              backgroundColor: _pureWhite,
              strokeWidth: 2.4,
              edgeOffset: MediaQuery.paddingOf(context).top + 8,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // =================================================
                    // HERO
                    // =================================================
                    DestinationHero(
                      title: 'Coyhaique',
                      description: isSpanish
                          ? 'Coyhaique ofrece vistas a la montaña, ríos patagónicos y un entorno natural inigualable. Perfecto tanto para descansar como para la aventura.'
                          : 'Coyhaique offers mountain views, Patagonian rivers, and an unmatched natural setting. Perfect for both relaxing and active trips.',
                      imagePath: 'assets/images/cerro_castillo_laguna.jpg',
                    ),

                    // =================================================
                    // TOURS / ACTIVIDADES DESDE SUPABASE
                    // =================================================
                    Transform.translate(
                      offset: const Offset(0, -18),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: HomeVisualTokens.sectionMargin,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: _iceAccent.withValues(alpha: 0.12),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),

                          child: HomeSurface(
                            child: _buildActivitiesSection(
                              activitiesAsync,
                              isSpanish,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: HomeVisualTokens.sectionGap),

                    // =================================================
                    // CATEGORÍAS
                    // =================================================
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: HomeVisualTokens.sectionMargin,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: _iceBlueMedium.withValues(alpha: 0.35),
                              blurRadius: 28,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),

                        child: HomeSurface(
                          ambientGlow: true,
                          child: CategoriesSection(
                            title: isSpanish ? 'Explorar' : 'Explore',
                            categories: categoryList,
                            language: language,
                            onCategoryTap: widget.onNavigate,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // =========================================================
            // PERFIL
            // =========================================================
            Positioned(
              top: DestinationHero.controlTop(context),
              left: HomeVisualTokens.pagePadding,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _iceDark.withValues(alpha: 0.18),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),

                child: GlassIconButton(
                  semanticLabel: isSpanish ? 'Perfil' : 'Profile',
                  onTap: widget.onProfileClick,
                  child: const Icon(
                    Icons.person_outline_rounded,
                    size: 24,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // ACTIVIDADES ASYNC
  // ================================================================

  Widget _buildActivitiesSection(
    AsyncValue<List<ActivityDto>> activitiesAsync,
    bool isSpanish,
  ) {
    return activitiesAsync.when(
      // ==============================================================
      // DATOS
      // ==============================================================
      data: (activities) {
        if (activities.isEmpty) {
          return _buildEmptyActivities(isSpanish);
        }

        final tourItems = activities
            .map<TourItemData>(
              (activity) => _mapActivityToTourItem(activity, isSpanish),
            )
            .toList();

        return ToursSection(
          title: isSpanish ? 'Actividades' : 'Activities',
          viewAllText: isSpanish ? 'Ver todos' : 'View all',
          items: tourItems,
          onViewAll: () {
            widget.onNavigate('aventura');
          },
        );
      },

      // ==============================================================
      // CARGANDO
      // ==============================================================
      loading: () {
        return SizedBox(
          height: 180,
          child: Center(
            child: CircularProgressIndicator(
              color: _iceAccent,
              strokeWidth: 2.5,
            ),
          ),
        );
      },

      // ==============================================================
      // ERROR
      // ==============================================================
      error: (error, stackTrace) {
        return _buildActivitiesError(isSpanish);
      },
    );
  }

  // ================================================================
  // ACTIVITY DTO -> TOUR ITEM
  // ================================================================

  TourItemData _mapActivityToTourItem(ActivityDto activity, bool isSpanish) {
    return TourItemData(
      id: activity.id,

      title: activity.getName(isSpanish),

      imagePath: _getActivityImage(activity),

      subtitle: _buildActivitySubtitle(activity, isSpanish),

      onTap: () {
        widget.onNavigate('aventura');
      },
    );
  }

  // ================================================================
  // SUBTÍTULO
  // ================================================================

  String _buildActivitySubtitle(ActivityDto activity, bool isSpanish) {
    final price = activity.referencePrice?.trim();

    // Si existe un precio real útil,
    // se muestra primero.
    if (price != null &&
        price.isNotEmpty &&
        price.toLowerCase() != 'ver disponibilidad con el operador.') {
      return price;
    }

    final schedule = activity.schedule?.trim();

    if (schedule != null && schedule.isNotEmpty) {
      return schedule;
    }

    return isSpanish ? 'Ver información' : 'View information';
  }

  // ================================================================
  // IMAGEN
  //
  // places_v2 todavía no tiene image_url.
  // Por eso se usa un asset local según el nombre.
  // ================================================================

  String _getActivityImage(ActivityDto activity) {
    final title = activity.nameEs.toLowerCase();

    if (title.contains('mármol') || title.contains('marmol')) {
      return 'assets/images/catedral_de_marmol.jpg';
    }

    if (title.contains('queulat')) {
      return 'assets/images/ventisquero_queulat.jpg';
    }

    if (title.contains('divisadero')) {
      return 'assets/images/cordon_divisadero.jpg';
    }

    if (title.contains('bicicleta') || title.contains('cicloturismo')) {
      return 'assets/images/miradores_coyhaique.jpg';
    }

    if (title.contains('trekking') || title.contains('expediciones')) {
      return 'assets/images/cerro_castillo_panoramico.jpg';
    }

    if (title.contains('lagunas')) {
      return 'assets/images/cerro_castillo_laguna.jpg';
    }

    return 'assets/images/cerro_castillo_panoramico.jpg';
  }

  // ================================================================
  // SIN ACTIVIDADES
  // ================================================================

  Widget _buildEmptyActivities(bool isSpanish) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.explore_outlined,
            size: 36,
            color: _iceDark.withValues(alpha: 0.7),
          ),

          const SizedBox(height: 10),

          Text(
            isSpanish
                ? 'No hay tours disponibles actualmente.'
                : 'There are currently no tours available.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _iceDark,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // ERROR
  // ================================================================

  Widget _buildActivitiesError(bool isSpanish) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.cloud_off_outlined,
            size: 36,
            color: _iceDark.withValues(alpha: 0.7),
          ),

          const SizedBox(height: 10),

          Text(
            isSpanish
                ? 'No fue posible cargar los tours.'
                : 'Unable to load tours.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _iceDark,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 10),

          TextButton(
            onPressed: () {
              ref.invalidate(activitiesProvider);
            },
            child: Text(isSpanish ? 'Reintentar' : 'Retry'),
          ),
        ],
      ),
    );
  }
}
