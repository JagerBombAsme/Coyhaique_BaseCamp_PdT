import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/language_provider.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  bool _isChangingLanguage = false;

  void _changeLanguage(String languageCode) async {
    if (_isChangingLanguage) return;

    setState(() {
      _isChangingLanguage = true;
    });

    await Future.delayed(const Duration(milliseconds: 1700));

    if (!mounted) return;

    ref.read(languageProvider.notifier).setLanguage(languageCode);

    setState(() {
      _isChangingLanguage = false;
    });

    // Navigate to Home or next screen if desired
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = ref.watch(languageProvider);
    final isSpanish = currentLocale.languageCode == 'es';

    return Scaffold(
      backgroundColor: AppTheme.slateLight,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 56.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isSpanish
                        ? 'Selecciona el idioma para\nla app'
                        : 'Select the language for\nthe app',
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      height: 1.12,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    isSpanish
                        ? 'Elige el idioma de visualización para comenzar tu experiencia turística.'
                        : 'Choose the display language to start your tourist experience.',
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.46,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 34),
                  LanguageButton(
                    text: 'Español',
                    selected: isSpanish,
                    enabled: !_isChangingLanguage,
                    onClick: () => _changeLanguage('es'),
                  ),
                  const SizedBox(height: 14),
                  LanguageButton(
                    text: 'English',
                    selected: !isSpanish,
                    enabled: !_isChangingLanguage,
                    onClick: () => _changeLanguage('en'),
                  ),
                ],
              ),
            ),
          ),
          if (_isChangingLanguage)
            LoadingOverlay(isEnglish: !isSpanish),
        ],
      ),
    );
  }
}

class LanguageButton extends StatelessWidget {
  final String text;
  final bool selected;
  final bool enabled;
  final VoidCallback onClick;

  const LanguageButton({
    super.key,
    required this.text,
    required this.selected,
    this.enabled = true,
    required this.onClick,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onClick : null,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryDark : Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            color: selected ? Colors.white : AppTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class LoadingOverlay extends StatelessWidget {
  final bool isEnglish;

  const LoadingOverlay({
    super.key,
    required this.isEnglish,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color.fromRGBO(0, 0, 0, 0.35),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  color: AppTheme.primaryDark,
                  strokeWidth: 4,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isEnglish
                    ? 'Espera mientras cambiamos el idioma,\nPuede que tu pantalla parpadee,\nTranquilo te cuidamos...'
                    : 'Please wait while we change the language,\nYour screen may flicker,\nDon\'t worry, we\'ve got you covered...',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
