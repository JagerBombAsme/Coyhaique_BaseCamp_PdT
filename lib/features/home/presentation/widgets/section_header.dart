import 'package:flutter/material.dart';

import 'home_visual_tokens.dart';
import 'pressable_scale.dart';

/// Encabezado compartido por todas las secciones del Home
/// (misma jerarquía tipográfica en Tours y Explorar).
class SectionHeader extends StatelessWidget {
  final String title;
  final int? count;
  final String? actionText;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.count,
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
            child: Row(
              children: [
                Flexible(
                  child: Semantics(
                    header: true,
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: HomeVisualTokens.sectionTitle,
                    ),
                  ),
                ),
                if (count != null) ...[
                  const SizedBox(width: 10),
                  _CountBadge(count: count!),
                ],
              ],
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

class _CountBadge extends StatelessWidget {
  final int count;

  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: HomeVisualTokens.iceBlue,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: HomeVisualTokens.outline),
        ),
        child: Text('$count', style: HomeVisualTokens.badge),
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
              style: TextStyle(
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
