import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/language_provider.dart';
import '../../../language/widgets/language_selection_screen.dart';

class ProfileLanguageScreen extends ConsumerWidget {
  const ProfileLanguageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void saveLanguage(String languageCode) {
      ref.read(languageProvider.notifier).setLanguage(languageCode);

      if (!context.mounted) return;

      context.pop();
    }

    return LanguageSelectionScreen(
      mode: LanguageSelectionMode.profile,
      onConfirm: saveLanguage,
      onBack: () => context.pop(),
    );
  }
}
