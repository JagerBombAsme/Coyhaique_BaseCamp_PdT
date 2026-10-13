import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/language_provider.dart';

/// Pantalla de selección de idioma (HU-30) según USER_FLOWS.md
class LanguageSelectionView extends ConsumerStatefulWidget {
  const LanguageSelectionView({super.key});

  @override
  ConsumerState<LanguageSelectionView> createState() => _LanguageSelectionViewState();
}

class _LanguageSelectionViewState extends ConsumerState<LanguageSelectionView> {
  bool _isProcessing = false;

  void _selectLanguage(String languageCode) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    ref.read(languageProvider.notifier).setLanguage(languageCode);
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;
    context.go('/auth');
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = ref.watch(languageProvider);
    final isSpanish = currentLocale.languageCode == 'es';

    return Scaffold(
      backgroundColor: AppTheme.slateLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.language_rounded,
                size: 64,
                color: AppTheme.primaryDark,
              ),
              const SizedBox(height: 24),
              Text(
                isSpanish
                    ? 'Selecciona tu idioma'
                    : 'Select your language',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isSpanish
                    ? 'Podrás cambiarlo en cualquier momento desde tu perfil.'
                    : 'You can change this at any time in your profile settings.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 48),

              // Botón Español
              _LanguageOptionCard(
                title: 'Español',
                subtitle: 'Continuar en Español',
                flagEmoji: '🇨🇱',
                isSelected: isSpanish,
                isLoading: _isProcessing && isSpanish,
                onTap: () => _selectLanguage('es'),
              ),
              const SizedBox(height: 16),

              // Botón Inglés
              _LanguageOptionCard(
                title: 'English',
                subtitle: 'Continue in English',
                flagEmoji: '🇬🇧',
                isSelected: !isSpanish,
                isLoading: _isProcessing && !isSpanish,
                onTap: () => _selectLanguage('en'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String flagEmoji;
  final bool isSelected;
  final bool isLoading;
  final VoidCallback onTap;

  const _LanguageOptionCard({
    required this.title,
    required this.subtitle,
    required this.flagEmoji,
    required this.isSelected,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryDark : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(flagEmoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (isSelected)
              const Icon(Icons.check_circle, color: AppTheme.primaryDark),
          ],
        ),
      ),
    );
  }
}
