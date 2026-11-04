import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/language_provider.dart';
import '../../../../core/theme/basecamp_tokens.dart';
import '../../../../core/widgets/basecamp/bc_widgets.dart';

/// Bienvenida: continuar como invitado, iniciar sesión o crear cuenta.
/// La foto ocupa toda la pantalla (sistema Coyhaique BaseCamp).
class AuthGatewayView extends ConsumerWidget {
  const AuthGatewayView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSpanish = ref.watch(languageProvider).languageCode == 'es';
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
            const BcPhotoImage(
              source: BcPhoto.montanistas,
              alignment: Alignment(0.28, 0),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0, 0.18, 0.42, 0.62, 0.8],
                  colors: [
                    Color(0x73121416),
                    Color(0x00121416),
                    Color(0x00121416),
                    Color(0x8C121416),
                    BcColors.photoShade,
                  ],
                ),
              ),
            ),
            Positioned(
              left: BcSpace.gutter,
              top: top + 14,
              child: BcCornerButton(
                icon: Icons.arrow_back_rounded,
                semanticLabel: isSpanish
                    ? 'Volver al selector de idioma'
                    : 'Back to language selector',
                onTap: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/language-selection');
                  }
                },
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  BcSpace.gutter,
                  0,
                  BcSpace.gutter,
                  24,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const BcTag(
                      'Patagonia',
                      lead: 'Aysén',
                      style: BcTagStyle.ink,
                    ),
                    const SizedBox(height: 12),
                    Semantics(
                      header: true,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          isSpanish
                              ? 'EXPLORA\nCOYHAIQUE'
                              : 'EXPLORE\nCOYHAIQUE',
                          style: BcText.display(62, color: BcColors.onPhoto),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      isSpanish
                          ? 'Inicia sesión para guardar tus itinerarios o explora directamente como invitado.'
                          : 'Sign in to save your itineraries, or explore directly as a guest.',
                      style: BcText.body(
                        color: BcColors.onPhoto.withValues(alpha: 0.88),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 1. Invitado: la consulta no exige cuenta (HU-16).
                    BcButton(
                      icon: Icons.hiking_rounded,
                      label: isSpanish
                          ? 'Continuar como invitado'
                          : 'Continue as guest',
                      onPressed: () => context.push('/initial-location'),
                    ),
                    const SizedBox(height: 12),

                    // 2. Iniciar sesión.
                    BcButton(
                      style: BcButtonStyle.surface,
                      label: isSpanish ? 'Iniciar sesión' : 'Sign in',
                      onPressed: () => context.push('/auth'),
                    ),
                    const SizedBox(height: 8),

                    // 3. Crear cuenta.
                    Center(
                      child: TextButton(
                        onPressed: () => context.push('/register'),
                        style: TextButton.styleFrom(
                          foregroundColor: BcColors.onPhoto,
                          minimumSize: const Size(48, 48),
                        ),
                        child: Text.rich(
                          TextSpan(
                            style: BcText.body(color: BcColors.onPhoto),
                            children: [
                              TextSpan(
                                text: isSpanish
                                    ? '¿No tienes cuenta? '
                                    : "Don't have an account? ",
                              ),
                              TextSpan(
                                text: isSpanish ? 'Regístrate' : 'Sign up',
                                style: BcText.title(color: BcColors.onPhoto)
                                    .copyWith(
                                  decoration: TextDecoration.underline,
                                  decorationColor: BcColors.glacier,
                                  decorationThickness: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
