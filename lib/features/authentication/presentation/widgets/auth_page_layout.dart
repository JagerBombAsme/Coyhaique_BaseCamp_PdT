import 'package:flutter/material.dart';

import '../../../../core/theme/basecamp_tokens.dart';
import '../../../../core/widgets/basecamp/bc_widgets.dart';
import '../../../../core/widgets/glass_auth_card.dart';

/// Foto de fondo con degradado tinta, para las pantallas de cuenta.
class AuthBackdrop extends StatelessWidget {
  const AuthBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return const Stack(
      fit: StackFit.expand,
      children: [
        BcPhotoImage(source: 'assets/images/cultura_gaucho.jpg'),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0x66121416),
                Color(0x8C121416),
                BcColors.photoShade,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Fondo, botón volver y tarjeta tinta comunes a las pantallas de cuenta
/// (inicio de sesión, registro y recuperación), con la identidad
/// «afiche de montaña»: azul glacier y tinta.
class AuthPageLayout extends StatelessWidget {
  const AuthPageLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.onBack,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final VoidCallback? onBack;

  /// Acento de las pantallas de cuenta. Antes era verde; ahora es el glacier
  /// de la marca.
  @Deprecated('Usa BcColors.glacier')
  static const Color green = BcColors.glacier;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BcColors.ink,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AuthBackdrop(),
          SafeArea(
            child: Stack(
              children: [
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 76, 24, 22),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 380),
                      child: GlassAuthCard(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(22, 30, 24, 26),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Semantics(
                                header: true,
                                child: Text(
                                  title.toUpperCase(),
                                  style: BcText.display(
                                    38,
                                    color: BcColors.onPhoto,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                subtitle,
                                style: BcText.body(
                                  color: BcColors.onPhoto.withValues(
                                    alpha: 0.86,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              ...children,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 14,
                  left: BcSpace.gutter,
                  child: AuthBackButton(onPressed: onBack),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Botón volver de las pantallas de cuenta (botón de esquina de la marca).
class AuthBackButton extends StatelessWidget {
  const AuthBackButton({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return BcCornerButton(
      icon: Icons.arrow_back_rounded,
      semanticLabel: MaterialLocalizations.of(context).backButtonTooltip,
      onTap: onPressed,
    );
  }
}

/// Botón principal azul glacier con texto tinta (7,2:1) de las pantallas de
/// cuenta.
class AuthPrimaryAction extends StatelessWidget {
  const AuthPrimaryAction({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return BcButton(
      label: text,
      isLoading: isLoading,
      onPressed: onPressed,
    );
  }
}

/// Mensaje dentro de la tarjeta (error o información).
class AuthInlineMessage extends StatelessWidget {
  const AuthInlineMessage({super.key, required this.text, this.isError = true});

  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    // Sobre tarjeta tinta: error en rosa claro (paleta oscura) e información
    // en glacier. Siempre con ícono y texto, nunca solo color.
    final color = isError ? BcDarkColors.danger : BcColors.glacier;
    // liveRegion: el lector de pantalla anuncia el mensaje cuando aparece,
    // sin que la persona tenga que buscarlo.
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: BcColors.ink.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(BcRadius.control),
          border: Border.all(color: color.withValues(alpha: 0.7)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: Icon(
                isError
                    ? Icons.error_outline_rounded
                    : Icons.check_circle_outline_rounded,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(text, style: BcText.caption(color: color).copyWith(
                fontSize: 13.5,
                height: 1.35,
              )),
            ),
          ],
        ),
      ),
    );
  }
}
