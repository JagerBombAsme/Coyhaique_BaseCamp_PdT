import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/language_provider.dart';

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
