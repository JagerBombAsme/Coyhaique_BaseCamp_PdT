import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/category_model.dart';
import '../../../../core/providers/language_provider.dart';

import '../../../categories/data/providers/places_provider.dart'
  hide activitiesProvider;
import '../../../categories/presentation/widgets/place_search_delegate.dart';

import '../../../routes/data/models/activity_dto.dart';
import '../../../routes/data/providers/activity_provider.dart';

import '../../../trip_info/presentation/widgets/trip_notice.dart';
import '../widgets/catalog_status_card.dart';
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
  @override
  void initState() {
    super.initState();
    // Aviso de uso seguro al entrar al inicio, una vez por sesión (RNF-14).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      TripNotice.show(
        context,
        kind: TripNoticeKind.home,
        oncePerSession: true,
      );
    });
  }

  static const _statusBarStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  );

  // Paleta única: todo sale de HomeVisualTokens.
  static const Color _snowWhite = HomeVisualTokens.background;

  static const Color _pureWhite = HomeVisualTokens.surface;

  static const Color _iceBlue = HomeVisualTokens.iceBlue;

  static const Color _iceAccent = HomeVisualTokens.accentStrong;

  static const Color _iceDark = HomeVisualTokens.deepIce;

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(languageProvider);

    final language = locale.languageCode;

    final isSpanish = language == 'es';

    // ================================================================
    // ACTIVIDADES DESDE SUPABASE
    // places_v2
    // kind = activity
    // is_active = true
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
                ref.invalidate(activitiesProvider);

                ref.invalidate(categoriesProvider);

                ref.invalidate(placesProvider);

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
                      // Búsqueda de lugares y actividades (HU-04)
                      trailingAction: GlassIconButton(
                        semanticLabel: isSpanish ? 'Buscar' : 'Search',
                        onTap: () => showSearch<void>(
                          context: context,
                          delegate: PlaceSearchDelegate(isSpanish: isSpanish),
                        ),
                        // Ícono oscuro: el vidrio es blanco al 72 %.
                        child: const Icon(
                          Icons.search_rounded,
                          size: 24,
                          color: _iceDark,
                        ),
                      ),
                    ),

                    // =================================================
                    // TOURS / ACTIVIDADES
                    // =================================================
                    Transform.translate(
                      offset: const Offset(0, -18),
                      // HomeSurface ya trae su sombra en capas.
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: HomeVisualTokens.sectionMargin,
                        ),
                        child: HomeSurface(
                          child: _buildActivitiesSection(
                            context,
                            activitiesAsync,
                            isSpanish,
                          ),
                        ),
                      ),
                    ),

                    // =================================================
                    // INFORMACIÓN DESCARGADA (HU-09, HU-10)
                    // =================================================
                    const CatalogStatusCard(),

                    // =================================================
                    // ANTES DE TU VIAJE (HU-25, RNF-14)
                    // =================================================
                    const TripInfoEntryCard(),

                    const SizedBox(height: HomeVisualTokens.sectionGap + 4),

                    // =================================================
                    // CATEGORÍAS
                    // =================================================
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: HomeVisualTokens.sectionMargin,
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
              // GlassIconButton ya trae softShadow; la sombra circular
              // anterior no coincidía con su forma redondeada.
              child: GlassIconButton(
                semanticLabel: isSpanish ? 'Perfil' : 'Profile',
                onTap: widget.onProfileClick,
                child: const Icon(
                  Icons.person_outline_rounded,
                  size: 24,
                  color: _iceDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // SECCIÓN ACTIVIDADES
  // ================================================================

  Widget _buildActivitiesSection(
    BuildContext context,
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
              (activity) =>
                  _mapActivityToTourItem(context, activity, isSpanish),
            )
            .toList();

        return ToursSection(
          title: isSpanish ? 'Tours' : 'Tours',
          viewAllText: isSpanish ? 'Ver todos' : 'View all',
          items: tourItems,

          // -----------------------------------------------------------
          // Por ahora NO usamos /routes.
          //
          // /routes todavía corresponde a la antigua pantalla
          // "Rutas de Aventura".
          //
          // Mostramos todas las actividades disponibles en el carrusel.
          // Posteriormente podemos crear /activities.
          // -----------------------------------------------------------
          onViewAll: null,
        );
      },

      // ==============================================================
      // CARGANDO
      // ==============================================================
      loading: () {
        return const SizedBox(
          height: 200,
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
        debugPrint('ERROR ACTIVIDADES HOME: $error');

        return _buildActivitiesError(isSpanish);
      },
    );
  }

  // ================================================================
  // ACTIVITY -> TOUR ITEM
  // ================================================================

  TourItemData _mapActivityToTourItem(
    BuildContext context,
    ActivityDto activity,
    bool isSpanish,
    
  ) {
    
    return TourItemData(
      id: activity.id,

      title: activity.getName(isSpanish),

      imagePath: activity.imageUrl ?? '',

      subtitle: _buildActivitySubtitle(activity, isSpanish),

      onTap: () {
        debugPrint('ACTIVIDAD SELECCIONADA: ${activity.id}');

        context.push('/attractions/${activity.id}');
      },
    );
  }

  String _buildActivitySubtitle(ActivityDto activity, bool isSpanish) {
    final price = activity.referencePrice?.trim();

    // Si existe un precio concreto,
    // lo mostramos.
    if (price != null && price.isNotEmpty && !_isAvailabilityText(price)) {
      return price;
    }

    final schedule = activity.schedule?.trim();

    if (schedule != null && schedule.isNotEmpty) {
      return schedule;
    }

    return isSpanish ? 'Ver información' : 'View information';
  }

  bool _isAvailabilityText(String value) {
    final normalized = value.trim().toLowerCase();

    return normalized == 'ver disponibilidad con el operador.' ||
        normalized == 'ver disponibilidad con el operador';
        
  }

  // ================================================================
  // IMÁGENES
  //
  // places_v2 todavía no tiene image_url.
  // Mientras tanto resolvemos assets locales según el nombre.
  // ================================================================

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
                ? 'No hay actividades disponibles actualmente.'
                : 'There are currently no activities available.',
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
  // ERROR ACTIVIDADES
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
                ? 'No fue posible cargar las actividades.'
                : 'Unable to load activities.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _iceDark,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 14),

          TextButton.icon(
            onPressed: () {
              ref.invalidate(activitiesProvider);
            },
            style: TextButton.styleFrom(
              foregroundColor: _iceDark,
              backgroundColor: _iceBlue,
              minimumSize: const Size(44, 44),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              shape: const StadiumBorder(),
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(isSpanish ? 'Reintentar' : 'Retry'),
          ),
        ],
      ),
    );
  }
}
