import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/language_provider.dart';
import '../theme/basecamp_tokens.dart';

/// Barra inferior del sistema «Coyhaique BaseCamp».
///
/// - Píldora tinta con 3 pestañas (índices 0, 1, 2).
/// - Círculo tinta aparte para Perfil (índice 3).
/// La pestaña activa se rellena en azul glaciar con ícono y texto tinta.
class GlassNavBar extends ConsumerWidget {
  const GlassNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const double _height = 64;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSpanish = ref.watch(languageProvider).languageCode == 'es';

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: SizedBox(
          height: _height,
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: BcColors.ink.withValues(alpha: 0.96),
                    borderRadius: BorderRadius.circular(BcRadius.pill),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _NavItem(
                        icon: Icons.home_rounded,
                        label: isSpanish ? 'Inicio' : 'Home',
                        selected: currentIndex == 0,
                        onTap: () => onTap(0),
                      ),
                      _NavItem(
                        icon: Icons.event_note_rounded,
                        label: 'Plan',
                        selected: currentIndex == 1,
                        onTap: () => onTap(1),
                      ),
                      _NavItem(
                        icon: Icons.map_rounded,
                        label: isSpanish ? 'Mapa' : 'Map',
                        selected: currentIndex == 2,
                        onTap: () => onTap(2),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Semantics(
                button: true,
                selected: currentIndex == 3,
                label: isSpanish ? 'Perfil' : 'Profile',
                child: GestureDetector(
                  onTap: () => onTap(3),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: _height,
                    height: _height,
                    decoration: BoxDecoration(
                      color: currentIndex == 3
                          ? BcColors.glacier
                          : BcColors.ink.withValues(alpha: 0.96),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person_rounded,
                      size: 28,
                      color: currentIndex == 3
                          ? BcColors.ink
                          : BcColors.onPhoto.withValues(alpha: 0.7),
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
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: selected ? 3 : 2,
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: selected ? BcColors.glacier : Colors.transparent,
              borderRadius: BorderRadius.circular(BcRadius.pill),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 25,
                  color: selected
                      ? BcColors.ink
                      : BcColors.onPhoto.withValues(alpha: 0.6),
                ),
                if (selected) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: BcText.button(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
