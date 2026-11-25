import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/language_provider.dart';
import '../theme/basecamp_tokens.dart';

/// Persistent navigation, with the original ink/glacier visual identity.
class GlassNavBar extends ConsumerWidget {
  const GlassNavBar({super.key, required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final es = ref.watch(languageProvider).languageCode == 'es';
    final labels = [es ? 'Inicio' : 'Home', 'Plan', es ? 'Mapa' : 'Map', es ? 'Perfil' : 'Profile'];
    const icons = [Icons.home_rounded, Icons.event_note_rounded, Icons.map_rounded, Icons.person_rounded];
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 360 || MediaQuery.textScalerOf(context).scale(15) > 19;
            return Material(
              color: BcColors.ink,
              borderRadius: BorderRadius.circular(BcRadius.pill),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    for (var i = 0; i < labels.length; i++)
                      Expanded(
                        child: Semantics(
                          selected: currentIndex == i,
                          child: Tooltip(
                            message: labels[i],
                            excludeFromSemantics: true,
                            child: TextButton(
                              onPressed: () => onTap(i),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
                                minimumSize: const Size(48, 48),
                                foregroundColor: currentIndex == i ? BcColors.ink : BcColors.onPhoto,
                                backgroundColor: currentIndex == i ? BcColors.glacier : Colors.transparent,
                                animationDuration: reduceMotion ? Duration.zero : const Duration(milliseconds: 180),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(icons[i], size: 24, semanticLabel: compact ? labels[i] : null),
                                  if (!compact) ...[
                                    const SizedBox(height: 2),
                                    Text(labels[i], textAlign: TextAlign.center, style: BcText.caption(color: currentIndex == i ? BcColors.ink : BcColors.onPhoto)),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
