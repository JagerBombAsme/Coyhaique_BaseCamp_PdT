import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

enum LanguageSelectionMode { onboarding, profile }

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({
    super.key,
    required this.onConfirm,
    required this.mode,
    this.onBack,
    this.heroImage = 'assets/images/climbers_language.jpg',
  });

  final ValueChanged<String> onConfirm;
  final LanguageSelectionMode mode;
  final VoidCallback? onBack;
  final String heroImage;

  @override
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  late String _selectedLanguage;

  @override
  void initState() {
    super.initState();
    _selectedLanguage = 'es';
  }

  bool get _isSpanish => _selectedLanguage == 'es';

  bool get _isOnboarding => widget.mode == LanguageSelectionMode.onboarding;

  String get _headerTitle =>
      _isOnboarding
          ? (_isSpanish ? 'Selecciona tu idioma' : 'Select your language')
          : (_isSpanish ? 'Idioma' : 'Language');

  String get _title => _isSpanish ? 'Elige tu idioma' : 'Choose your language';

  String get _subtitle => _isOnboarding
      ? (_isSpanish
            ? 'Puedes cambiarlo más adelante desde tu perfil.'
            : 'You can change it later from your profile.')
      : (_isSpanish
            ? 'Selecciona el idioma que deseas usar en la aplicación.'
            : 'Select the language you want to use in the app.');

  String get _confirmLabel => _isOnboarding
      ? (_isSpanish ? 'Confirmar y continuar' : 'Confirm & continue')
      : (_isSpanish ? 'Guardar idioma' : 'Save language');

  String get _eyebrow => _isSpanish
      ? 'Idioma de la aplicación'
      : 'Application language';

  String get _hint => _isOnboarding
      ? (_isSpanish
            ? 'Lo podrás cambiar también desde tu perfil.'
            : 'You can also change it from your profile.')
      : (_isSpanish
            ? 'El cambio se aplica al instante.'
            : 'The change applies instantly.');

  void _confirm() {
    widget.onConfirm(_selectedLanguage);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ==========================================================
          // FONDO GRADIENTE DE MARCA
          // ==========================================================
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.primaryDark,
                    Color(0xFF1B5E78),
                  ],
                ),
              ),
            ),
          ),

          // ==========================================================
          // HERO: IMAGEN + ENCABEZADO
          // ==========================================================
          SizedBox(
            width: double.infinity,
            height: screenHeight * 0.52,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  widget.heroImage,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),

                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x99000000),
                        Color(0x33000000),
                        Colors.transparent,
                      ],
                      stops: [0.0, 0.45, 1.0],
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
                        _BackButton(onPressed: widget.onBack ?? _defaultBack),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 11),
                            child: Text(
                              _headerTitle,
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

          // ==========================================================
          // PANEL INFERIOR
          // ==========================================================
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(
                maxHeight: screenHeight * 0.72,
              ),
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 30,
                    offset: Offset(0, -8),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
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

                      const SizedBox(height: 24),

                      Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppTheme.accentLightBlue,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.translate_rounded,
                              size: 19,
                              color: AppTheme.accentBlue,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _eyebrow,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      Text(
                        _title,
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
                        _subtitle,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.35,
                          color: AppTheme.textSecondary,
                        ),
                      ),

                      const SizedBox(height: 24),

                      _LanguageCard(
                        title: 'Español',
                        subtitle: 'Español de Chile / Latinoamérica',
                        flagEmoji: '🇨🇱',
                        isSelected: _selectedLanguage == 'es',
                        onTap: () {
                          setState(() => _selectedLanguage = 'es');
                        },
                      ),

                      const SizedBox(height: 12),

                      _LanguageCard(
                        title: 'English',
                        subtitle: 'International English',
                        flagEmoji: '🇬🇧',
                        isSelected: _selectedLanguage == 'en',
                        onTap: () {
                          setState(() => _selectedLanguage = 'en');
                        },
                      ),

                      const SizedBox(height: 20),

                      Row(
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 15,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _hint,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      _ConfirmButton(
                        label: _confirmLabel,
                        onPressed: _confirm,
                        isOnboarding: _isOnboarding,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _defaultBack() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
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

class _LanguageCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String flagEmoji;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageCard({
    required this.title,
    required this.subtitle,
    required this.flagEmoji,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_LanguageCard> createState() => _LanguageCardState();
}

class _LanguageCardState extends State<_LanguageCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: widget.isSelected,
      label: '${widget.title}. ${widget.subtitle}',
      child: AnimatedScale(
        scale: _pressed ? 0.985 : 1,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            onHighlightChanged: (v) => setState(() => _pressed = v),
            borderRadius: BorderRadius.circular(22),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                gradient: widget.isSelected
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFEAF3FB),
                          Color(0xFFF5F9FF),
                        ],
                      )
                    : null,
                color: widget.isSelected ? null : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: widget.isSelected
                      ? AppTheme.accentBlue
                      : const Color(0xFFE2E8F0),
                  width: widget.isSelected ? 1.8 : 1,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _FlagBadge(emoji: widget.flagEmoji, active: widget.isSelected),

                  const SizedBox(width: 16),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: widget.isSelected
                                ? AppTheme.accentBlue
                                : AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.subtitle,
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

                  _SelectionIndicator(selected: widget.isSelected),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FlagBadge extends StatelessWidget {
  final String emoji;
  final bool active;

  const _FlagBadge({required this.emoji, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: active
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.accentLightBlue, Color(0xFFDCEBf7)],
              )
            : null,
        color: active ? null : Colors.white,
        border: Border.all(
          color: active ? AppTheme.accentBlue : const Color(0xFFE2E8F0),
          width: active ? 1.6 : 1,
        ),
      ),
      child: Text(emoji, style: const TextStyle(fontSize: 30)),
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
          color: selected ? AppTheme.accentBlue : const Color(0xFFCBD5E1),
        ),
      ),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 180),
        scale: selected ? 1 : 0,
        child: const DecoratedBox(
          decoration: BoxDecoration(
            color: AppTheme.accentBlue,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _ConfirmButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isOnboarding;

  const _ConfirmButton({
    required this.label,
    required this.onPressed,
    required this.isOnboarding,
  });

  @override
  State<_ConfirmButton> createState() => _ConfirmButtonState();
}

class _ConfirmButtonState extends State<_ConfirmButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final icon = widget.isOnboarding
        ? Icons.arrow_forward_rounded
        : Icons.check_rounded;

    return AnimatedScale(
      scale: _pressed ? 0.98 : 1,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOut,
      child: SizedBox(
        width: double.infinity,
        height: 58,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [AppTheme.primaryDark, AppTheme.accentBlue],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x332E7BB4),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onPressed,
              onHighlightChanged: (v) => setState(() => _pressed = v),
              borderRadius: BorderRadius.circular(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(icon, size: 22, color: Colors.white),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
