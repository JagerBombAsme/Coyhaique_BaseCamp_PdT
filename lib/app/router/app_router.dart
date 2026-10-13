import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/bottom_nav_bar.dart';
import '../../features/attractions/presentation/views/attraction_detail_view.dart';
import '../../features/attractions/presentation/views/attractions_list_view.dart';
import '../../features/authentication/presentation/views/auth_gateway_view.dart';
import '../../features/categories/presentation/screens/category_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/location/presentation/views/initial_location_view.dart';
import '../../features/map/presentation/screens/map_screen.dart';
import '../../features/onboarding/presentation/views/language_selection_view.dart';
import '../../features/onboarding/presentation/views/splash_view.dart';
import '../../features/planner/presentation/screens/planificacion_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/routes/presentation/screens/route_detail_screen.dart';
import '../../features/routes/presentation/screens/route_screen.dart';

/// Configuración de enrutamiento centralizado GoRouter
/// según ARCHITECTURE.md y USER_FLOWS.md
final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    // -------------------------------------------------------------
    // 1. FLUJO DE INICIO (USER_FLOWS.md Sección 2)
    // -------------------------------------------------------------
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashView(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const LanguageSelectionView(),
    ),
    GoRoute(
      path: '/auth',
      builder: (context, state) => const AuthGatewayView(),
    ),
    GoRoute(
      path: '/initial-location',
      builder: (context, state) => const InitialLocationView(),
    ),

    // -------------------------------------------------------------
    // 2. SHELL PRINCIPAL CON BARRA DE NAVEGACIÓN (BottomNavBar)
    // -------------------------------------------------------------
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return Scaffold(
          body: navigationShell,
          bottomNavigationBar: BottomNavBar(
            currentIndex: navigationShell.currentIndex,
            onTap: (index) => navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            ),
          ),
        );
      },
      branches: [
        // Pestaña 0: Inicio
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => HomeScreen(
                onNavigate: (route) {
                  if (route == 'aventura') {
                    context.push('/routes');
                  } else {
                    context.push('/categories/$route');
                  }
                },
                onProfileClick: () => context.go('/profile'),
              ),
            ),
          ],
        ),

        // Pestaña 1: Planificador de Itinerario (HU-04 / HU-13)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/itinerary',
              builder: (context, state) => const PlanificacionScreen(),
            ),
          ],
        ),

        // Pestaña 2: Mapa y Puntos Cercanos (HU-06)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/map',
              builder: (context, state) => const MapScreen(),
            ),
          ],
        ),

        // Pestaña 3: Perfil y Preferencias (HU-29 / HU-30)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => ProfileScreen(
                onLanguageChangeClick: () => context.push('/onboarding'),
              ),
            ),
          ],
        ),
      ],
    ),

    // -------------------------------------------------------------
    // 3. EXPLORACIÓN TURÍSTICA Y RUTAS (USER_FLOWS.md Secciones 3 y 4)
    // -------------------------------------------------------------
    GoRoute(
      path: '/attractions',
      builder: (context, state) {
        final category = state.uri.queryParameters['category'];
        return AttractionsListView(initialCategory: category);
      },
    ),
    GoRoute(
      path: '/attractions/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return AttractionDetailView(attractionId: id);
      },
    ),
    GoRoute(
      path: '/categories/:slug',
      builder: (context, state) {
        final slug = state.pathParameters['slug'] ?? '';
        return Scaffold(
          appBar: AppBar(
            title: Text(slug.toUpperCase()),
          ),
          body: CategoryScreen(
            category: slug,
            onPlaceClick: (placeId) => context.push('/attractions/$placeId'),
            onRoutesClick: () => context.push('/routes'),
          ),
        );
      },
    ),
    GoRoute(
      path: '/routes',
      builder: (context, state) => RouteScreen(
        onRouteClick: (routeId) => context.push('/routes/$routeId'),
      ),
    ),
    GoRoute(
      path: '/routes/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return RouteDetailScreen(routeId: id);
      },
    ),
  ],
);
