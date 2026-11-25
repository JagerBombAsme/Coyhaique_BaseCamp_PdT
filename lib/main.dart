import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/router/app_router.dart';
import 'core/config/app_config.dart';
import 'core/connectivity/connectivity_gate.dart';
import 'core/local/catalog_download_consent.dart';
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

  // Idioma elegido en una apertura anterior: se lee antes del primer frame
  // para que la app abra en ese idioma y no pase otra vez por la selección.
  final prefs = await SharedPreferences.getInstance();
  final savedLanguage = prefs.getString(languageStorageKey);

  final container = ProviderContainer(
    overrides: [
      languageProvider.overrideWith(
        (ref) => LanguageNotifier(
          initial: savedLanguage == null ? null : Locale(savedLanguage),
        ),
      ),
      languageSavedProvider.overrideWithValue(savedLanguage != null),
    ],
  );

  // Al abrir la aplicación se descarga el catálogo para consultarlo sin
  // conexión (HU-09), pero solo después de que la persona aceptó el mensaje
  // que lo explica (se muestra una vez, en el inicio). Si no hay conexión, la
  // descarga falla en silencio y se conserva la copia anterior.
  if (prefs.getBool(catalogDownloadAcceptedKey) ?? false) {
    unawaited(container.read(catalogStatusProvider.notifier).download());
  }
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const CoyhaiqueApp(),
    ),
  );
}
