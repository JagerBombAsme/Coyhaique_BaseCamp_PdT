import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/providers/language_provider.dart';

class OnboardingLanguageScreen extends ConsumerStatefulWidget {
  const OnboardingLanguageScreen({super.key});

  @override
  ConsumerState<OnboardingLanguageScreen> createState() =>
      _OnboardingLanguageScreenState();
}

class _OnboardingLanguageScreenState
    extends ConsumerState<OnboardingLanguageScreen> {
  late String _selectedLanguage;

  @override
  void initState() {
    super.initState();

    _selectedLanguage = ref.read(languageProvider).languageCode;
  }

  void _confirmLanguage() {
    ref.read(languageProvider.notifier).setLanguage(_selectedLanguage);

    if (!mounted) return;

    context.go('/auth-gateway');
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/intro');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSpanish = _selectedLanguage == 'es';

    final screenHeight = MediaQuery.sizeOf(context).height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ============================================================
          // IMAGEN SUPERIOR
          // ============================================================
          SizedBox(
            width: double.infinity,
            height: screenHeight * 0.57,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/climbers_language.jpg',
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),

                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.center,
                      colors: [
                        Color(0x88000000),
                        Color(0x22000000),
                        Colors.transparent,
                      ],
                      stops: [0.0, 0.40, 1.0],
                    ),
                  ),
                ),

                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _BackButton(onPressed: _goBack),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 11),
                            child: Text(
                              isSpanish
                                  ? 'Selecciona tu idioma'
                                  : 'Select your language',
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 21,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                                shadows: [
                                  Shadow(
                                    color: Color(0x66000000),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 52),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ============================================================
          // PANEL INFERIOR
          // ============================================================
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x1F000000),
                    blurRadius: 28,
                    offset: Offset(0, -6),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD1D5DB),
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    Text(
                      isSpanish ? 'Elige tu idioma' : 'Choose your language',
                      style: const TextStyle(
                        fontSize: 29,
                        height: 1.08,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      isSpanish
                          ? 'Puedes cambiarlo más adelante desde tu perfil.'
                          : 'You can change it later from your profile.',
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.35,
                        color: AppTheme.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 24),

                    _LanguageOptionCard(
                      title: 'Español',
                      subtitle: 'Español de Chile / Latinoamérica',
                      flagEmoji: '🇨🇱',
                      isSelected: _selectedLanguage == 'es',
                      onTap: () {
                        setState(() {
                          _selectedLanguage = 'es';
                        });
                      },
                    ),

                    const SizedBox(height: 12),

                    _LanguageOptionCard(
                      title: 'English',
                      subtitle: 'International English',
                      flagEmoji: '🇬🇧',
                      isSelected: _selectedLanguage == 'en',
                      onTap: () {
                        setState(() {
                          _selectedLanguage = 'en';
                        });
                      },
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: ElevatedButton(
                        onPressed: _confirmLanguage,
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: AppTheme.primaryDark,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isSpanish
                                  ? 'Confirmar y continuar'
                                  : 'Confirm & continue',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),

                            const SizedBox(width: 10),

                            const Icon(Icons.arrow_forward_rounded, size: 22),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// COMPONENTES
// ================================================================

class _BackButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _BackButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.16),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 21,
            color: Colors.white,
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
  final VoidCallback onTap;

  const _LanguageOptionCard({
    required this.title,
    required this.subtitle,
    required this.flagEmoji,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: '$title. $subtitle',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primaryDark.withValues(alpha: 0.045)
                  : Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isSelected
                    ? AppTheme.primaryDark
                    : const Color(0xFFE2E8F0),
                width: isSelected ? 1.7 : 1,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x09000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(flagEmoji, style: const TextStyle(fontSize: 30)),
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? AppTheme.primaryDark
                              : AppTheme.textPrimary,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.3,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                _SelectionIndicator(selected: isSelected),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectionIndicator extends StatelessWidget {
  final bool selected;

  const _SelectionIndicator({required this.selected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 28,
      height: 28,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          width: 2,
          color: selected ? AppTheme.primaryDark : const Color(0xFFCBD5E1),
        ),
      ),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 180),
        scale: selected ? 1 : 0,
        child: const DecoratedBox(
          decoration: BoxDecoration(
            color: AppTheme.primaryDark,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
