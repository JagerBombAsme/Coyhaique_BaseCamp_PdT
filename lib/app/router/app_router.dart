import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/basecamp_tokens.dart';

import '../../core/widgets/bottom_nav_bar.dart';

import '../../features/authentication/presentation/screens/forgot_password_screen.dart';
import '../../features/authentication/presentation/screens/login_screen.dart';
import '../../features/authentication/presentation/screens/register_screen.dart';
import '../../features/authentication/presentation/views/auth_gateway_view.dart';

import '../../features/attractions/presentation/views/attraction_detail_view.dart';
import '../../features/attractions/presentation/views/attractions_list_view.dart';

import '../../features/categories/presentation/screens/category_screen.dart';

import '../../features/guest/presentation/screens/guest_profile_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';

import '../../features/location/presentation/views/initial_location_view.dart';
import '../../features/map/presentation/screens/map_screen.dart';

// ================================================================
// IDIOMA
// ================================================================

import '../../features/language/screens/onboarding_screen.dart';
import '../../features/profile/presentation/screens/profile_language_screen.dart';

import '../../features/language/presentation/views/nature_intro_view.dart';
import '../../features/language/presentation/views/splash_view.dart';

import '../../features/planner/presentation/screens/planificacion_screen.dart';
import '../../features/planner/presentation/screens/saved_itineraries_screen.dart';
import '../../features/trip_info/presentation/screens/trip_info_screen.dart';
import '../../features/trip_info/presentation/widgets/trip_notice.dart';
import '../../features/transport/domain/transfer_request.dart';
import '../../features/transport/presentation/screens/transfer_code_screen.dart';
import '../../features/transport/presentation/screens/transfer_request_screen.dart';
import '../../features/transport/presentation/screens/transfers_screen.dart';
import '../../features/transport/presentation/widgets/transfer_widgets.dart';

import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/interests_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';

import '../../features/routes/presentation/screens/route_detail_screen.dart';
import '../../features/routes/presentation/screens/route_screen.dart';

// ================================================================
// CREACIÓN DEL ROUTER
// ================================================================

/// Ruta de retorno tras iniciar sesión. Solo acepta rutas internas de la
/// aplicación; cualquier otro valor vuelve al inicio.
String _safeReturnPath(String? from) {
  if (from == null || !from.startsWith('/') || from.startsWith('//')) {
    return '/home';
  }
  if (from.startsWith('/auth') ||
      from.startsWith('/register') ||
      from.startsWith('/forgot-password')) {
    return '/home';
  }
  return from;
}

String _authPath(String path, GoRouterState state, {String? email}) {
  final from = state.uri.queryParameters['from'];
  final query = <String, String>{
    if (from != null && from.isNotEmpty) 'from': from,
    if (email != null && email.isNotEmpty) 'email': email,
  };
  return Uri(path: path, queryParameters: query.isEmpty ? null : query).toString();
}

GoRouter _createRouter() {
  String? lastLocation;

  late final GoRouter router;

  router = GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: false,

    routes: [
      // =============================================================
      // SPLASH
      // =============================================================
      GoRoute(
        path: '/splash',
        builder: (context, state) {
          return const SplashView();
        },
      ),

      // =============================================================
      // INTRO
      // =============================================================
      GoRoute(
        path: '/intro',
        builder: (context, state) {
          return const NatureIntroView();
        },
      ),

      // =============================================================
      // IDIOMA - ONBOARDING
      // =============================================================
      GoRoute(
        path: '/language-selection',
        builder: (context, state) {
          return const OnboardingLanguageScreen();
        },
      ),

      // =============================================================
      // IDIOMA - PERFIL
      // =============================================================
      GoRoute(
        path: interestsRoute,
        builder: (context, state) => const InterestsScreen(),
      ),

      GoRoute(
        path: '/profile/language',
        builder: (context, state) {
          return const ProfileLanguageScreen();
        },
      ),

      // =============================================================
      // UBICACIÓN INICIAL
      // =============================================================
      GoRoute(
        path: '/initial-location',
        builder: (context, state) {
          return const InitialLocationView();
        },
      ),

      // =============================================================
      // INVITADO - PERFIL ANIMAL
      // =============================================================
      GoRoute(
        path: '/guest-profile',
        builder: (context, state) => const GuestProfileScreen(),
      ),

      // =============================================================
      // AUTH GATEWAY
      // =============================================================
      GoRoute(
        path: '/auth-gateway',
        builder: (context, state) {
          return const AuthGatewayView();
        },
      ),

      // =============================================================
      // LOGIN
      // =============================================================
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

            // Vuelve a la pantalla que pidió iniciar sesión (por ejemplo,
            // la planificación al guardar un itinerario, HU-07).
            onLogin: () {
              context.go(_safeReturnPath(state.uri.queryParameters['from']));
            },

            onSignUp: () {
              context.push(_authPath('/register', state));
            },

            onForgotPassword: (email) {
              context.push(_authPath('/forgot-password', state, email: email));
            },
          );
        },
      ),

      // =============================================================
      // REGISTRO (HU-16)
      // =============================================================
      GoRoute(
        path: '/register',
        builder: (context, state) {
          return RegisterScreen(
            onBack: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/auth-gateway');
              }
            },
            onSignedIn: () {
              context.go(_safeReturnPath(state.uri.queryParameters['from']));
            },
            onGoToLogin: () {
              // Reemplaza la pila para no dejar dos pantallas de login.
              context.go(_authPath('/auth', state));
            },
            onForgotPassword: () {
              context.push(_authPath('/forgot-password', state));
            },
          );
        },
      ),

      // =============================================================
      // RECUPERAR CONTRASEÑA (HU-16)
      // =============================================================
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) {
          return ForgotPasswordScreen(
            initialEmail: state.uri.queryParameters['email'],
            onBack: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/auth');
              }
            },
            onDone: () {
              context.go(_safeReturnPath(state.uri.queryParameters['from']));
            },
          );
        },
      ),

      // =============================================================
      // NAVEGACIÓN PRINCIPAL
      // =============================================================
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {

          return Scaffold(
            extendBody: true,

            backgroundColor: BcColors.fog,

            body: navigationShell,

            bottomNavigationBar: GlassNavBar(
              currentIndex: navigationShell.currentIndex,

              onTap: (index) {
                navigationShell.goBranch(
                  index,

                  // Si toca la pestaña actual,
                  // vuelve a la ruta raíz de esa rama.
                  initialLocation: index == navigationShell.currentIndex,
                );
              },
            ),
          );
        },

        branches: [
          // ===========================================================
          // PESTAÑA 0: HOME
          // ===========================================================
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

          // ===========================================================
          // PESTAÑA 1: PLANIFICADOR
          // ===========================================================
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

          // ===========================================================
          // PESTAÑA 2: MAPA
          // ===========================================================
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/map',
                builder: (context, state) {
                  return MapScreen(
                    routeFromAirport:
                        state.uri.queryParameters['ruta'] == 'aeropuerto',
                  );
                },
              ),
            ],
          ),

          // ===========================================================
          // PESTAÑA 3: PERFIL
          // ===========================================================
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) {
                  return const ProfileScreen();
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
      // ATRACTIVOS TURÍSTICOS
      // =============================================================
      GoRoute(
        path: '/activities/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';

          return AttractionDetailView(attractionId: id);
        },
      ),
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
        path: savedItinerariesRoute,
        builder: (context, state) => const SavedItinerariesScreen(),
      ),

      GoRoute(
        path: tripInfoRoute,
        builder: (context, state) => const TripInfoScreen(),
      ),

      // =============================================================
      // TRANSFER DESDE EL AEROPUERTO (HU-18)
      // =============================================================
      GoRoute(
        path: transfersRoute,
        builder: (context, state) => const TransfersScreen(),
      ),

      GoRoute(
        path: '$transfersRoute/:id',
        builder: (context, state) => TransferRequestScreen(
          serviceId: state.pathParameters['id'] ?? '',
        ),
      ),

      GoRoute(
        path: transferCodeRoute,
        builder: (context, state) => TransferCodeScreen(
          request: state.extra is TransferRequest
              ? state.extra as TransferRequest
              : null,
        ),
      ),

      // =============================================================
      // CATEGORÍAS
      // =============================================================
      GoRoute(
        path: '/categories/:slug',
        builder: (context, state) {
          final slug = state.pathParameters['slug'] ?? '';

          // Aviso de transporte referencial al abrir categorías de
          // transporte, una vez por sesión (RNF-14).
          // CategoryScreen trae su propia cabecera; sin AppBar aquí.
          return TripNoticeOnOpen(
            kind: TripNoticeKind.transport,
            enabled: slug.toLowerCase().contains('transp'),
            child: CategoryScreen(
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
      // RUTAS TURÍSTICAS
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

    // ===============================================================
    // ERROR GLOBAL DE NAVEGACIÓN
    // ===============================================================
    errorBuilder: (context, state) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FCFE),

        appBar: AppBar(title: const Text('Ruta no encontrada')),

        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 56,
                  color: Color(0xFF2E5F73),
                ),

                const SizedBox(height: 16),

                Text(
                  'No fue posible abrir la ruta:\n${state.uri}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF244652),
                  ),
                ),

                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: () {
                    context.go('/home');
                  },
                  child: const Text('Volver al inicio'),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );

  // ================================================================
  // LOGGER GLOBAL DE NAVEGACIÓN
  // ================================================================

  void logCurrentRoute() {
    final uri = router.routeInformationProvider.value.uri;

    final location = uri.toString();

    if (location == lastLocation) {
      return;
    }

    lastLocation = location;

    debugPrint('');
    debugPrint('════════════════════════════════════════════');
    debugPrint('🧭 RUTA ACTUAL: $location');
    debugPrint('📍 PATH: ${uri.path}');

    if (uri.pathSegments.isNotEmpty) {
      debugPrint('🧩 SEGMENTOS: ${uri.pathSegments}');
    }

    if (uri.queryParameters.isNotEmpty) {
      debugPrint('🔎 QUERY: ${uri.queryParameters}');
    }

    debugPrint('════════════════════════════════════════════');
    debugPrint('');
  }

  router.routeInformationProvider.addListener(logCurrentRoute);

  // Imprime también la ruta inicial.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    logCurrentRoute();
  });

  return router;
}

// ================================================================
// ROUTER GLOBAL
// ================================================================

final GoRouter appRouter = _createRouter();
