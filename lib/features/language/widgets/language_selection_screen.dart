import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/basecamp_tokens.dart';
import '../../../core/widgets/basecamp/bc_widgets.dart';

enum LanguageSelectionMode { onboarding, profile }

/// Selector de idioma del onboarding y del perfil (sistema Coyhaique
/// BaseCamp). El texto cambia al instante con la opción marcada, pero el
/// idioma solo se aplica al confirmar.
class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({
    super.key,
    required this.onConfirm,
    required this.mode,
    required this.onBack,
    this.initialLanguage = 'es',
  });

  final ValueChanged<String> onConfirm;
  final LanguageSelectionMode mode;
  final VoidCallback onBack;
  final String initialLanguage;

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  /// Margen superior que deja libre el botón de esquina.
  static const double _cornerButtonSpace = 72;

  /// Tramo en que el oscurecimiento aparece antes de llegar al contenido.
  static const double _scrimLeadIn = 56;

  late String _selectedLanguage = widget.initialLanguage;

  bool get _isSpanish => _selectedLanguage == 'es';

  bool get _isOnboarding => widget.mode == LanguageSelectionMode.onboarding;

  String get _title => _isSpanish ? 'ELIGE TU\nIDIOMA' : 'CHOOSE YOUR\nLANGUAGE';

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

  void _select(String languageCode) {
    setState(() => _selectedLanguage = languageCode);
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: BcColors.ink,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const BcPhotoImage(source: BcPhoto.cerroCastillo),
            const _StatusBarShade(),
            _buildContent(top),
            Positioned(
              left: BcSpace.gutter,
              top: top + 14,
              child: BcCornerButton(
                icon: Icons.arrow_back_rounded,
                semanticLabel: _isSpanish ? 'Volver' : 'Back',
                onTap: widget.onBack,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Contenido alineado abajo; se desplaza si no cabe en la pantalla. El
  /// oscurecimiento va con el contenido para que el título siempre quede
  /// legible, sea cual sea el alto de la pantalla.
  Widget _buildContent(double top) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: EdgeInsets.only(top: top + _cornerButtonSpace),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DecoratedBox(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0, 0.14, 0.4],
                        colors: [
                          Color(0x00121416),
                          Color(0x8C121416),
                          BcColors.photoShade,
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        BcSpace.gutter,
                        _scrimLeadIn,
                        BcSpace.gutter,
                        bottom + 24,
                      ),
                      child: _buildSelector(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BcTag('Patagonia', lead: 'Aysén', style: BcTagStyle.ink),
        const SizedBox(height: 12),
        Semantics(
          header: true,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _title,
              style: BcText.display(62, color: BcColors.onPhoto),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          _subtitle,
          style: BcText.body(color: BcColors.onPhoto.withValues(alpha: 0.88)),
        ),
        const SizedBox(height: 20),
        _LanguageOption(
          key: const ValueKey('language-option-es'),
          code: 'ES',
          title: 'Español',
          subtitle: 'Español de Chile / Latinoamérica',
          isSelected: _isSpanish,
          onTap: () => _select('es'),
        ),
        const SizedBox(height: 10),
        _LanguageOption(
          key: const ValueKey('language-option-en'),
          code: 'EN',
          title: 'English',
          subtitle: 'International English',
          isSelected: !_isSpanish,
          onTap: () => _select('en'),
        ),
        const SizedBox(height: 20),
        BcButton(
          icon: _isOnboarding
              ? Icons.arrow_forward_rounded
              : Icons.check_rounded,
          label: _confirmLabel,
          onPressed: () => widget.onConfirm(_selectedLanguage),
        ),
      ],
    );
  }
}

/// Oscurece la parte superior de la foto, bajo la barra de estado.
class _StatusBarShade extends StatelessWidget {
  const _StatusBarShade();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0, 0.18],
          colors: [Color(0x73121416), Color(0x00121416)],
        ),
      ),
    );
  }
}

/// Opción de idioma: se rellena de azul glaciar cuando está marcada.
class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    super.key,
    required this.code,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  final String code;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: isSelected,
      inMutuallyExclusiveGroup: true,
      child: BcPressable(
        onTap: onTap,
        semanticLabel: '$title. $subtitle',
        child: ExcludeSemantics(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            constraints: const BoxConstraints(minHeight: 72),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? BcColors.glacier : BcColors.surface,
              borderRadius: BorderRadius.circular(BcRadius.tile),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 48,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(code, style: BcText.display(27)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: BcText.title()),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: BcText.caption(
                          color: isSelected ? BcColors.ink : BcColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  isSelected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 24,
                  color: isSelected ? BcColors.ink : BcColors.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
