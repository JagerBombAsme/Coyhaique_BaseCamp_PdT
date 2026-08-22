import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/language_provider.dart';
import 'core/widgets/bottom_nav_bar.dart';
import 'features/categories/presentation/screens/category_screen.dart';
import 'features/categories/presentation/screens/place_detail_screen.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'features/map/presentation/screens/map_screen.dart';
import 'features/planner/presentation/screens/planificacion_screen.dart';
import 'features/profile/presentation/screens/profile_screen.dart';
import 'features/routes/presentation/screens/route_detail_screen.dart';
import 'features/routes/presentation/screens/route_screen.dart';
import 'features/welcome/presentation/screens/welcome_screen.dart';

class CoyhaiqueApp extends ConsumerWidget {
  const CoyhaiqueApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(languageProvider);

    return MaterialApp(
      title: 'Coyhaique BaseCamp',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: locale,
      supportedLocales: const [Locale('es'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AppNavigationWrapper(),
    );
  }
}

class AppNavigationWrapper extends StatefulWidget {
  const AppNavigationWrapper({super.key});

  @override
  State<AppNavigationWrapper> createState() => _AppNavigationWrapperState();
}

class _AppNavigationWrapperState extends State<AppNavigationWrapper> {
  int _currentTab = 0;
  String? _activeCategoryRoute;
  String? _selectedPlaceId;
  String? _selectedRouteId;
  bool _showWelcomeScreen = false;
  bool _showRouteScreen = false;

  void _navigateToCategory(String route) {
    if (route == 'aventura') {
      setState(() {
        _showRouteScreen = true;
      });
    } else {
      setState(() {
        _activeCategoryRoute = route;
      });
    }
  }

  void _navigateToPlaceDetail(String placeId) {
    setState(() {
      _selectedPlaceId = placeId;
    });
  }

  void _navigateToRouteDetail(String routeId) {
    setState(() {
      _selectedRouteId = routeId;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showWelcomeScreen) {
      return Scaffold(
        body: Stack(
          children: [
            const WelcomeScreen(),
            Positioned(
              top: 48,
              left: 16,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
                onPressed: () => setState(() => _showWelcomeScreen = false),
              ),
            ),
          ],
        ),
      );
    }

    if (_selectedPlaceId != null) {
      return PlaceDetailScreen(
        placeId: _selectedPlaceId!,
        onBack: () => setState(() => _selectedPlaceId = null),
      );
    }

    if (_selectedRouteId != null) {
      return RouteDetailScreen(routeId: _selectedRouteId!);
    }

    if (_showRouteScreen) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => setState(() => _showRouteScreen = false),
          ),
          title: const Text('Rutas de Aventura'),
        ),
        body: RouteScreen(onRouteClick: _navigateToRouteDetail),
      );
    }

    if (_activeCategoryRoute != null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => setState(() => _activeCategoryRoute = null),
          ),
          title: Text(_activeCategoryRoute!.toUpperCase()),
        ),
        body: CategoryScreen(
          category: _activeCategoryRoute!,
          onPlaceClick: _navigateToPlaceDetail,
          onRoutesClick: () => setState(() {
            _activeCategoryRoute = null;
            _showRouteScreen = true;
          }),
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentTab,
        children: [
          HomeScreen(
            onNavigate: _navigateToCategory,
            onProfileClick: () => setState(() => _currentTab = 3),
          ),
          const PlanificacionScreen(),
          const MapScreen(),
          ProfileScreen(
            onLanguageChangeClick: () =>
                setState(() => _showWelcomeScreen = true),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentTab,
        onTap: (index) {
          setState(() {
            _currentTab = index;
            _activeCategoryRoute = null;
            _selectedPlaceId = null;
            _selectedRouteId = null;
            _showRouteScreen = false;
          });
        },
      ),
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {
    // Continuar con valores por defecto si no existe el archivo .env
  }

  final supabaseUrl = dotenv.env['SUPABASE_URL'] ??
      'https://mijtzoqfuqqxymexewoh.supabase.co';
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ??
      'sb_publishable_0rWbty5pFicV8RIuz77o6A_8fYGeUSw';

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(const ProviderScope(child: CoyhaiqueApp()));
}
