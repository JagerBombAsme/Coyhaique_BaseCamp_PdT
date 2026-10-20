import 'dart:ui';
import 'package:flutter/material.dart';

/// Barra inferior dividida en dos:
/// - Píldora izquierda con 3 pestañas (índices 0, 1, 2)
/// - Botón circular derecho (índice 3)
class GlassNavBar extends StatelessWidget {
  const GlassNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.isDark = true,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool isDark;

  static const double _height = 64;

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? const Color.fromARGB(255, 79, 170, 255) : const Color.fromARGB(255, 33, 31, 158);
    final inactive = isDark ? const Color.fromARGB(179, 122, 122, 122) : const Color.fromARGB(136, 0, 0, 0);

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
                  isDark: isDark,
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _NavItem(
                          icon: Icons.home_rounded,
                          label: 'Home',
                          selected: currentIndex == 0,
                          accent: accent,
                          inactive: inactive,
                          isDark: isDark,
                          onTap: () => onTap(0),
                        ),
                        _NavItem(
                          icon: Icons.event_note_rounded,
                          label: 'Plan',
                          selected: currentIndex == 1,
                          accent: accent,
                          inactive: inactive,
                          isDark: isDark,
                          onTap: () => onTap(1),
                        ),
                        _NavItem(
                          icon: Icons.map_rounded,
                          label: 'Mapa',
                          selected: currentIndex == 2,
                          accent: accent,
                          inactive: inactive,
                          isDark: isDark,
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
                  isDark: isDark,
                  highlighted: currentIndex == 3,
                  child: SizedBox(
                    width: _height,
                    height: _height,
                    child: Icon(
                      Icons.person_rounded,
                      size: 28,
                      color: currentIndex == 3 ? accent : inactive,
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
    required this.accent,
    required this.inactive,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final Color accent;
  final Color inactive;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selectedBg = (isDark ? Colors.white : Colors.black).withOpacity(
      isDark ? 0.14 : 0.08,
    );

    return Expanded(
      flex: selected ? 3 : 2,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: selected ? selectedBg : Colors.transparent,
            borderRadius: BorderRadius.circular(40),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 26, color: selected ? accent : inactive),
              if (selected) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: accent,
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
    required this.isDark,
    this.highlighted = false,
  });

  final Widget child;
  final bool isDark;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final base = isDark ? Colors.white : Colors.black;
    final radius = BorderRadius.circular(40);

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                base.withOpacity(highlighted ? 0.28 : (isDark ? 0.22 : 0.10)),
                base.withOpacity(highlighted ? 0.12 : (isDark ? 0.06 : 0.04)),
              ],
            ),
            border: Border.all(color: base.withOpacity(isDark ? 0.18 : 0.10)),
          ),
          child: child,
        ),
      ),
    );
  }
}
