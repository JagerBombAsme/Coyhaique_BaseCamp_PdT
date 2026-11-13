import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/router/app_router.dart';
import 'core/config/app_config.dart';
import 'core/connectivity/connectivity_gate.dart';
import 'core/local/catalog_status_provider.dart';
import 'core/providers/language_provider.dart';
import 'core/theme/app_theme.dart';

class CoyhaiqueApp extends ConsumerWidget {
  const CoyhaiqueApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(languageProvider);

    return MaterialApp.router(
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
      routerConfig: appRouter,
      builder: (context, child) =>
          ConnectivityGate(child: child ?? const SizedBox.shrink()),
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Impide que Google Fonts descargue fuentes en tiempo de ejecución.
  // Las fuentes deben estar incluidas localmente como assets.
  GoogleFonts.config.allowRuntimeFetching = false;

  // Registra la licencia SIL OFL incluida con las fuentes.
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('assets/google_fonts/OFL.txt');

    yield LicenseEntryWithLineBreaks(['google_fonts'], license);
  });

  AppConfig.validate();

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    publishableKey: AppConfig.supabasePublishableKey,
  );

  MapboxOptions.setAccessToken(
    const String.fromEnvironment('MAPBOX_ACCESS_TOKEN'),
  );

  // Al abrir la aplicación con conexión se descarga el catálogo para
  // consultarlo sin conexión (HU-09). Si no hay conexión, la descarga falla
  // en silencio y se conserva la copia anterior.
  final container = ProviderContainer();

  unawaited(container.read(catalogStatusProvider.notifier).download());

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const CoyhaiqueApp(),
    ),
  );
}
