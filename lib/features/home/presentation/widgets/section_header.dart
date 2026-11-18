import 'package:flutter/material.dart';

import 'home_visual_tokens.dart';
import 'pressable_scale.dart';

/// Encabezado compartido por las secciones del Home.
/// Muestra «TÍTULO : 3 actividades disponibles» en la misma línea.
class SectionHeader extends StatelessWidget {
  final String title;
  final int? count;

  /// Texto que acompaña a la cifra, por ejemplo «actividades disponibles».
  final String countLabel;
  final String? actionText;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.count,
    this.countLabel = 'lugares disponibles',
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: HomeVisualTokens.pagePadding,
      ),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: title,
                      style: HomeVisualTokens.sectionTitle,
                    ),
                    if (count != null) ...[
                      TextSpan(
                        text: ' : ',
                        style: HomeVisualTokens.sectionTitle,
                      ),
                      TextSpan(
                        text: '$count $countLabel',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: HomeVisualTokens.accentStrong,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (actionText != null && onAction != null) ...[
            const SizedBox(width: 12),
            _ViewAllButton(text: actionText!, onTap: onAction!),
          ],
        ],
      ),
    );
  }
}

class _ViewAllButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _ViewAllButton({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      semanticLabel: text,
      excludeChildSemantics: true,
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
        padding: const EdgeInsets.fromLTRB(14, 9, 12, 9),
        decoration: BoxDecoration(
          color: HomeVisualTokens.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: HomeVisualTokens.outline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: const TextStyle(
                color: HomeVisualTokens.accentStrong,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 5),
            Icon(
              Icons.arrow_forward_rounded,
              size: 16,
              color: HomeVisualTokens.accentStrong.withValues(alpha: 0.82),
            ),
          ],
        ),
      ),
    );
  }
}
