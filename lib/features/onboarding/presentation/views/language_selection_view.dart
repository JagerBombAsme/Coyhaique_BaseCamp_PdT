import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/language_provider.dart';

/// Pantalla de selección de idioma (HU-30) según USER_FLOWS.md
/// Cumple con Heurística de Usabilidad #3 (Control y libertad del usuario)
/// y patrón de confirmación explícita (Don Norman / Luke Wroblewski).
class LanguageSelectionView extends ConsumerStatefulWidget {
  const LanguageSelectionView({super.key});

  @override
  ConsumerState<LanguageSelectionView> createState() => _LanguageSelectionViewState();
}

class _LanguageSelectionViewState extends ConsumerState<LanguageSelectionView> {
  late String _selectedLanguage;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _selectedLanguage = ref.read(languageProvider).languageCode;
  }

  void _onConfirmLanguage() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    ref.read(languageProvider.notifier).setLanguage(_selectedLanguage);
    await Future.delayed(const Duration(milliseconds: 250));

    if (!mounted) return;
    setState(() => _isProcessing = false);
    context.go('/auth');
  }

  @override
  Widget build(BuildContext context) {
    final isSpanish = _selectedLanguage == 'es';

    return Scaffold(
      backgroundColor: AppTheme.slateLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          tooltip: isSpanish ? 'Volver atrás' : 'Go back',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/splash');
            }
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryDark.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.language_rounded,
                    size: 48,
                    color: AppTheme.primaryDark,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isSpanish ? 'Selecciona tu idioma' : 'Select your language',
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
                    ? 'Elige tu preferencia y confirma para continuar a la aplicación.'
                    : 'Choose your preference and confirm to continue to the app.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 36),

              // Opción Español
              _LanguageOptionCard(
                title: 'Español',
                subtitle: 'Español de Chile / Latinoamérica',
                flagEmoji: '🇨🇱',
                isSelected: _selectedLanguage == 'es',
                onTap: () => setState(() => _selectedLanguage = 'es'),
              ),
              const SizedBox(height: 16),

              // Opción Inglés
              _LanguageOptionCard(
                title: 'English',
                subtitle: 'International English',
                flagEmoji: '🇬🇧',
                isSelected: _selectedLanguage == 'en',
                onTap: () => setState(() => _selectedLanguage = 'en'),
              ),

              const Spacer(),

              // Botón inferior ergonómico de confirmación (Zona del pulgar)
              ElevatedButton(
                onPressed: _isProcessing ? null : _onConfirmLanguage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryDark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                child: _isProcessing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isSpanish ? 'Confirmar y continuar' : 'Confirm & continue',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 20),
                        ],
                      ),
              ),
              const SizedBox(height: 12),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
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
              color: isSelected
                  ? AppTheme.primaryDark.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.03),
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
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppTheme.primaryDark : AppTheme.textPrimary,
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
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppTheme.primaryDark : const Color(0xFFCBD5E1),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
