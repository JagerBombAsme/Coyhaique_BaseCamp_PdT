import 'package:coyhaique_basecamp_pt/core/providers/language_provider.dart';
import 'package:coyhaique_basecamp_pt/features/language/screens/onboarding_screen.dart';
import 'package:coyhaique_basecamp_pt/features/language/widgets/language_selection_screen.dart';
import 'package:coyhaique_basecamp_pt/features/profile/presentation/screens/profile_language_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

const _spanishOption = ValueKey('language-option-es');
const _englishOption = ValueKey('language-option-en');

Widget _screen({
  LanguageSelectionMode mode = LanguageSelectionMode.onboarding,
  String initialLanguage = 'es',
  ValueChanged<String>? onConfirm,
  VoidCallback? onBack,
}) {
  return MaterialApp(
    home: LanguageSelectionScreen(
      mode: mode,
      initialLanguage: initialLanguage,
      onConfirm: onConfirm ?? (_) {},
      onBack: onBack ?? () {},
    ),
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('starts on the language received and shows its copy', (
    tester,
  ) async {
    await tester.pumpWidget(_screen(initialLanguage: 'en'));

    expect(find.text('CHOOSE YOUR\nLANGUAGE'), findsOneWidget);
    expect(
      tester.getSemantics(find.byKey(_englishOption)),
      isSemantics(
        isChecked: true,
        hasCheckedState: true,
        isInMutuallyExclusiveGroup: true,
      ),
    );
    expect(
      tester.getSemantics(find.byKey(_spanishOption)),
      isSemantics(
        isChecked: false,
        hasCheckedState: true,
        isInMutuallyExclusiveGroup: true,
      ),
    );
  });

  testWidgets(
    'selecting an option updates the copy and is what gets confirmed',
    (tester) async {
      String? confirmed;
      await tester.pumpWidget(_screen(onConfirm: (code) => confirmed = code));

      expect(find.text('ELIGE TU\nIDIOMA'), findsOneWidget);

      await tester.tap(find.byKey(_englishOption));
      await tester.pumpAndSettle();

      expect(find.text('CHOOSE YOUR\nLANGUAGE'), findsOneWidget);
      expect(confirmed, isNull);

      await tester.tap(find.text('Confirm & continue'));

      expect(confirmed, 'en');
    },
  );

  testWidgets('profile mode labels the action as saving', (tester) async {
    String? confirmed;
    await tester.pumpWidget(
      _screen(
        mode: LanguageSelectionMode.profile,
        onConfirm: (code) => confirmed = code,
      ),
    );

    expect(find.text('Guardar idioma'), findsOneWidget);
    expect(find.text('Confirmar y continuar'), findsNothing);

    await tester.tap(find.text('Guardar idioma'));

    expect(confirmed, 'es');
  });

  testWidgets('back button calls onBack', (tester) async {
    var backCalls = 0;
    await tester.pumpWidget(_screen(onBack: () => backCalls++));

    await tester.tap(find.bySemanticsLabel('Volver'));

    expect(backCalls, 1);
  });

  testWidgets('back button label follows the selected language', (
    tester,
  ) async {
    await tester.pumpWidget(_screen());

    await tester.tap(find.byKey(_englishOption));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Back'), findsOneWidget);
    expect(find.bySemanticsLabel('Volver'), findsNothing);
  });

  testWidgets('language code stays on one line with very large text', (
    tester,
  ) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(412, 915),
          textScaler: TextScaler.linear(2),
        ),
        child: _screen(),
      ),
    );

    final code = tester.getRect(find.text('ES'));
    const oneLineAtDoubleScale = 27 * 2;
    expect(code.height, lessThanOrEqualTo(oneLineAtDoubleScale));
    expect(code.width, lessThanOrEqualTo(48));
  });

  group('onboarding route', () {
    Future<ProviderContainer> pumpOnboarding(WidgetTester tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(languageProvider.notifier).setLanguage('en');

      final router = GoRouter(
        initialLocation: '/language-selection',
        routes: [
          GoRoute(
            path: '/language-selection',
            builder: (_, _) => const OnboardingLanguageScreen(),
          ),
          GoRoute(path: '/auth-gateway', builder: (_, _) => const Text('auth')),
          GoRoute(path: '/intro', builder: (_, _) => const Text('intro')),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      return container;
    }

    testWidgets('starts on the current language', (tester) async {
      await pumpOnboarding(tester);

      expect(find.text('CHOOSE YOUR\nLANGUAGE'), findsOneWidget);
    });

    testWidgets('confirm applies the language and opens the gateway', (
      tester,
    ) async {
      final container = await pumpOnboarding(tester);

      await tester.tap(find.byKey(_spanishOption));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmar y continuar'));
      await tester.pumpAndSettle();

      expect(container.read(languageProvider).languageCode, 'es');
      expect(find.text('auth'), findsOneWidget);
    });

    testWidgets('back returns to the intro when there is nothing to pop', (
      tester,
    ) async {
      await pumpOnboarding(tester);

      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();

      expect(find.text('intro'), findsOneWidget);
    });
  });

  group('profile route', () {
    Future<ProviderContainer> pumpProfile(WidgetTester tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final router = GoRouter(
        initialLocation: '/profile',
        routes: [
          GoRoute(path: '/profile', builder: (_, _) => const Text('profile')),
          GoRoute(
            path: '/profile/language',
            builder: (_, _) => const ProfileLanguageScreen(),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      router.push('/profile/language');
      await tester.pumpAndSettle();
      return container;
    }

    testWidgets('saving applies the language and returns', (tester) async {
      final container = await pumpProfile(tester);

      await tester.tap(find.byKey(_englishOption));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save language'));
      await tester.pumpAndSettle();

      expect(container.read(languageProvider).languageCode, 'en');
      expect(find.text('profile'), findsOneWidget);
    });

    testWidgets('back returns without changing the language', (tester) async {
      final container = await pumpProfile(tester);

      await tester.tap(find.byKey(_englishOption));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();

      expect(container.read(languageProvider).languageCode, 'es');
      expect(find.text('profile'), findsOneWidget);
    });
  });

  testWidgets('fits small screens with large text without overflowing', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(320, 480),
          textScaler: TextScaler.linear(1.5),
        ),
        child: _screen(),
      ),
    );

    expect(tester.takeException(), isNull);

    final confirm = find.text('Confirmar y continuar');
    await tester.ensureVisible(confirm);
    await tester.pumpAndSettle();
    expect(find.text('ELIGE TU\nIDIOMA'), findsOneWidget);
    expect(tester.getRect(confirm).bottom, lessThanOrEqualTo(480));
  });
}
