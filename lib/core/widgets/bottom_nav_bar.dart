import 'dart:ui';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Barra inferior dividida en dos:
/// - Píldora izquierda con 3 pestañas (índices 0, 1, 2)
/// - Botón circular derecho (índice 3)
///
/// El único aspecto dinámico es el COLOR, resuelto desde el
/// [NavGlassColors] del tema actual (modo claro/oscuro). La geometría,
/// tamaño y posición son fijos; la navegación se conserva intacta.
class GlassNavBar extends StatelessWidget {
  const GlassNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const double _height = 64;

  @override
  Widget build(BuildContext context) {
    final glass = Theme.of(context).extension<NavGlassColors>() ??
        NavGlassColors.light;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
        child: SizedBox(
          height: _height,
          child: Row(
            children: [
              Expanded(
                child: _Glass(
                  gradient: [glass.scrimTop, glass.scrimBottom],
                  borderColor: glass.border,
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _NavItem(
                          icon: Icons.home_rounded,
                          label: 'Home',
                          selected: currentIndex == 0,
                          colors: glass,
                          onTap: () => onTap(0),
                        ),
                        _NavItem(
                          icon: Icons.event_note_rounded,
                          label: 'Plan',
                          selected: currentIndex == 1,
                          colors: glass,
                          onTap: () => onTap(1),
                        ),
                        _NavItem(
                          icon: Icons.map_rounded,
                          label: 'Mapa',
                          selected: currentIndex == 2,
                          colors: glass,
                          onTap: () => onTap(2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // ---- Derecha: círculo (Perfil) ----
              GestureDetector(
                onTap: () => onTap(3),
                child: _Glass(
                  gradient: [glass.scrimTop, glass.scrimBottom],
                  borderColor: glass.border,
                  fill: currentIndex == 3 ? glass.selectedContainer : null,
                  child: SizedBox(
                    width: _height,
                    height: _height,
                    child: currentIndex == 3
                        ? Icon(
                            Icons.person_rounded,
                            size: 28,
                            color: glass.selectedForeground,
                          )
                        : Container(
                            width: 44,
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: glass.unselectedBackdrop,
                            ),
                            child: Icon(
                              Icons.person_rounded,
                              size: 24,
                              color: glass.unselectedForeground,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.colors,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final NavGlassColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: selected ? 3 : 2,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: selected ? colors.selectedContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(40),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (selected)
                Icon(icon, size: 26, color: colors.selectedForeground)
              else
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.unselectedBackdrop,
                  ),
                  child: Icon(icon, size: 24, color: colors.unselectedForeground),
                ),
              if (selected) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.selectedForeground,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Glass extends StatelessWidget {
  const _Glass({
    required this.child,
    required this.gradient,
    required this.borderColor,
    this.fill,
  });

  final Widget child;
  final List<Color> gradient;
  final Color borderColor;

  /// Si no es nulo, reemplaza el degradado por un color sólido
  /// (usado para el estado seleccionado del botón de perfil).
  final Color? fill;

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(40));

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            color: fill,
            gradient: fill == null
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradient,
                  )
                : null,
            border: Border.all(color: borderColor),
          ),
          child: child,
        ),
      ),
    );
  }
}
