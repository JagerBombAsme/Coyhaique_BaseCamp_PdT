import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/language_provider.dart';
import '../widgets/language_selection_screen.dart';

class OnboardingLanguageScreen extends ConsumerWidget {
  const OnboardingLanguageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void confirmLanguage(String languageCode) {
      ref.read(languageProvider.notifier).setLanguage(languageCode);

      if (!context.mounted) return;

      context.go('/auth-gateway');
    }

    void goBack() {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/intro');
      }
    }

    return LanguageSelectionScreen(
      mode: LanguageSelectionMode.onboarding,
      onConfirm: confirmLanguage,
      onBack: goBack,
    );
  }
}
