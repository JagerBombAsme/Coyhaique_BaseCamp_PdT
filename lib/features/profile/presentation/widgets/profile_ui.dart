import 'package:flutter/material.dart';

import '../../../home/presentation/widgets/home_visual_tokens.dart';
import '../../../home/presentation/widgets/pressable_scale.dart';

/// Piezas visuales compartidas por "Mi perfil" y "Configuración".
///
/// Usan exclusivamente la paleta de [HomeVisualTokens] (hielo, nieve y
/// agua patagónica) para que ambas pantallas se sientan parte del inicio.
abstract final class ProfileUi {
  /// Rojo de acciones destructivas (cerrar sesión, errores).
  /// Único color fuera de la paleta: comunica peligro.
  static const Color danger = Color(0xFFC62828);

  static const BoxDecoration cardDecoration = BoxDecoration(
    color: HomeVisualTokens.surface,
    borderRadius: BorderRadius.all(Radius.circular(HomeVisualTokens.cardRadius)),
    boxShadow: HomeVisualTokens.softShadow,
  );

  static const BoxDecoration sectionDecoration = BoxDecoration(
    color: HomeVisualTokens.surface,
    borderRadius: BorderRadius.all(
      Radius.circular(HomeVisualTokens.sectionRadius),
    ),
    boxShadow: HomeVisualTokens.elevatedShadow,
  );

  static const TextStyle body = TextStyle(
    color: HomeVisualTokens.textSecondary,
    fontSize: 14,
    height: 1.45,
  );
}

/// Fondo con el mismo degradado hielo → nieve que la pantalla de inicio.
class ProfileBackground extends StatelessWidget {
  final Widget child;

  const ProfileBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            HomeVisualTokens.iceBlue,
            HomeVisualTokens.background,
            HomeVisualTokens.surface,
          ],
          stops: [0.0, 0.4, 1.0],
        ),
      ),
      child: child,
    );
  }
}

/// Botón de ícono 48×48 sobre superficie clara (área táctil ≥ 44 px).
class ProfileIconButton extends StatelessWidget {
  final IconData icon;
  final String semanticLabel;
  final VoidCallback onTap;

  const ProfileIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: semanticLabel,
      child: PressableScale(
        semanticLabel: semanticLabel,
        excludeChildSemantics: true,
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: HomeVisualTokens.surface,
            borderRadius: BorderRadius.all(
              Radius.circular(HomeVisualTokens.controlRadius),
            ),
            boxShadow: HomeVisualTokens.softShadow,
          ),
          child: Icon(icon, color: HomeVisualTokens.deepIce, size: 22),
        ),
      ),
    );
  }
}

/// Botón tipo píldora con escala 0.96 al presionar.
///
/// [filled] = acción principal (azul profundo); si no, acción secundaria
/// sobre azul hielo. Ambos mantienen contraste AA con su texto.
class ProfilePillButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool filled;
  final bool loading;
  final Color? foregroundOverride;
  final Color? backgroundOverride;

  const ProfilePillButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.filled = true,
    this.loading = false,
    this.foregroundOverride,
    this.backgroundOverride,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = foregroundOverride ??
        (filled ? Colors.white : HomeVisualTokens.deepIce);
    final background = backgroundOverride ??
        (filled ? HomeVisualTokens.deepIce : HomeVisualTokens.iceBlue);
    final enabled = onTap != null && !loading;

    return PressableScale(
      semanticLabel: label,
      excludeChildSemantics: true,
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        opacity: enabled || loading ? 1 : 0.5,
        duration: HomeVisualTokens.stateDuration,
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(25),
          ),
          child: AnimatedSwitcher(
            duration: HomeVisualTokens.stateDuration,
            child: loading
                ? SizedBox(
                    key: const ValueKey('loading'),
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: foreground,
                    ),
                  )
                : Row(
                    key: const ValueKey('label'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 18, color: foreground),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: foreground,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.1,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Estado vacío / error con ícono en círculo hielo, título y acción.
class ProfileStatusView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;
  final bool isError;

  const ProfileStatusView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isError
                    ? ProfileUi.danger.withValues(alpha: 0.08)
                    : HomeVisualTokens.iceBlue,
              ),
              child: Icon(
                icon,
                size: 34,
                color: isError ? ProfileUi.danger : HomeVisualTokens.deepIce,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: HomeVisualTokens.cardTitle.copyWith(fontSize: 18),
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: HomeVisualTokens.caption,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Indicador de carga con el acento de la paleta.
class ProfileLoading extends StatelessWidget {
  const ProfileLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: HomeVisualTokens.accentStrong,
        strokeWidth: 2.5,
      ),
    );
  }
}
