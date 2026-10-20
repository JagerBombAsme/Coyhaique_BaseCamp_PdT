import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/bottom_nav_bar.dart';
import '../../features/authentication/presentation/screens/login_screen.dart';
import '../../features/authentication/presentation/views/auth_gateway_view.dart';
import '../../features/attractions/presentation/views/attraction_detail_view.dart';
import '../../features/attractions/presentation/views/attractions_list_view.dart';
import '../../features/categories/presentation/screens/category_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/location/presentation/views/initial_location_view.dart';
import '../../features/map/presentation/screens/map_screen.dart';
import '../../features/onboarding/presentation/views/language_selection_view.dart';
import '../../features/onboarding/presentation/views/nature_intro_view.dart';
import '../../features/onboarding/presentation/views/splash_view.dart';
import '../../features/planner/presentation/screens/planificacion_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/routes/presentation/screens/route_detail_screen.dart';
import '../../features/routes/presentation/screens/route_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',

  routes: [
    // =============================================================
    // 1. FLUJO INICIAL
    // =============================================================
    GoRoute(
      path: '/splash',
      builder: (context, state) {
        return const SplashView();
      },
    ),

    GoRoute(
      path: '/intro',
      builder: (context, state) {
        return const NatureIntroView();
      },
    ),

    GoRoute(
      path: '/onboarding',
      builder: (context, state) {
        return const LanguageSelectionView();
      },
    ),
    GoRoute(
      path: '/auth',
      builder: (context, state) {
        return LoginScreen(
          onBack: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/auth-gateway');
            }
          },

          onLogin: () {
            context.go('/initial-location');
          },

          onSignUp: () {
            // Futuro:
            // context.push('/register');
          },
        );
      },
    ),
    GoRoute(
      path: '/auth-gateway',
      builder: (context, state) {
        return const AuthGatewayView();
      },
    ),

    GoRoute(
      path: '/initial-location',
      builder: (context, state) {
        return const InitialLocationView();
      },
    ),

    // =============================================================
    // 3. SHELL PRINCIPAL CON BARRA INFERIOR
    // =============================================================
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        final isHome = navigationShell.currentIndex == 0;

        return Scaffold(
          extendBody: true, 
          backgroundColor: isHome
              ? const Color(0xFF211F22)
              : const Color(0xFFF6F7F5),
          body: navigationShell,
          bottomNavigationBar: GlassNavBar(
            currentIndex: navigationShell.currentIndex,
            onTap: (index) {
              navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              );
            },
          ),
        );
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) {
                return HomeScreen(
                  onNavigate: (route) {
                    if (route == 'aventura') {
                      context.push('/routes');
                    } else {
                      context.push('/categories/$route');
                    }
                  },

                  onProfileClick: () {
                    context.go('/profile');
                  },
                );
              },
            ),
          ],
        ),

        // ---------------------------------------------------------
        // PESTAÑA 1: PLANIFICADOR
        // ---------------------------------------------------------
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/itinerary',
              builder: (context, state) {
                return const PlanificacionScreen();
              },
            ),
          ],
        ),

        // ---------------------------------------------------------
        // PESTAÑA 2: MAPA
        // ---------------------------------------------------------
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/map',
              builder: (context, state) {
                return const MapScreen();
              },
            ),
          ],
        ),

        // ---------------------------------------------------------
        // PESTAÑA 3: PERFIL
        // ---------------------------------------------------------
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) {
                return ProfileScreen(
                  onLanguageChangeClick: () {
                    context.push('/onboarding');
                  },
                );
              },
            ),

            GoRoute(
              path: '/profile/edit',
              builder: (context, state) {
                return const EditProfileScreen();
              },
            ),
          ],
        ),
      ],
    ),

    // =============================================================
    // 4. ATRACTIVOS TURÍSTICOS
    // =============================================================
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

    // =============================================================
    // 5. CATEGORÍAS
    // =============================================================
    GoRoute(
      path: '/categories/:slug',
      builder: (context, state) {
        final slug = state.pathParameters['slug'] ?? '';

        return Scaffold(
          appBar: AppBar(title: Text(slug.toUpperCase())),

          body: CategoryScreen(
            category: slug,

            onPlaceClick: (placeId) {
              context.push('/attractions/$placeId');
            },

            onRoutesClick: () {
              context.push('/routes');
            },
          ),
        );
      },
    ),

    // =============================================================
    // 6. RUTAS TURÍSTICAS
    // =============================================================
    GoRoute(
      path: '/routes',
      builder: (context, state) {
        return RouteScreen(
          onRouteClick: (routeId) {
            context.push('/routes/$routeId');
          },
        );
      },
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
