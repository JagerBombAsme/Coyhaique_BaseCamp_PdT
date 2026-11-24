import 'package:flutter/material.dart';

import '../../../../core/theme/basecamp_tokens.dart';
import '../../../../core/widgets/basecamp/bc_widgets.dart';
import 'itinerary_views.dart' show itineraryMotion;

/// Componentes del formulario de planificación: chips, avisos y esqueleto
/// de carga. Todos usan los tokens de BaseCamp.

/// Chip de selección múltiple (intereses, filtros). Elegido: fondo glaciar y
/// ícono de verificación en lugar del ícono de la categoría.
class PlannerFilterChip extends StatelessWidget {
  const PlannerFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final leading = selected ? Icons.check_rounded : icon;

    return Semantics(
      button: true,
      selected: selected,
      excludeSemantics: true,
      label: label,
      onTap: onTap,
      child: BcPressable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: itineraryMotion(context, 160),
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? BcColors.glacier : BcColors.surface,
            borderRadius: BorderRadius.circular(BcRadius.pill),
            border: Border.all(
              color: selected ? BcColors.glacier : BcColors.line,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[
                Icon(leading, size: 18, color: BcColors.ink),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  style: BcText.button(color: BcColors.ink).copyWith(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum PlannerNoticeTone { info, danger }

/// Aviso en línea con ícono, texto y una acción opcional para salir del
/// estado (reintentar, abrir ajustes).
class PlannerNotice extends StatelessWidget {
  const PlannerNotice({
    super.key,
    required this.icon,
    required this.text,
    this.tone = PlannerNoticeTone.info,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String text;
  final PlannerNoticeTone tone;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final danger = tone == PlannerNoticeTone.danger;
    final accent = danger ? BcColors.danger : BcColors.glacierDeep;
    final action = actionLabel;

    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 6, 10),
      decoration: BoxDecoration(
        color: danger
            ? BcColors.danger.withValues(alpha: 0.07)
            : BcColors.surface,
        borderRadius: BorderRadius.circular(BcRadius.control),
        border: Border.all(
          color: danger ? BcColors.danger.withValues(alpha: 0.35) : BcColors.line,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: accent),
              const SizedBox(width: 10),
              Expanded(child: Text(text, style: BcText.caption(color: danger ? BcColors.danger : BcColors.ink))),
            ],
          ),
          if (action != null && onAction != null)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(foregroundColor: accent, minimumSize: const Size(48, 48)),
                child: Text(action),
              ),
            ),
        ],
      ),
    );
  }
}

/// Esqueleto de una lista de lugares mientras se cargan.
class PlannerSkeletonList extends StatelessWidget {
  const PlannerSkeletonList({
    super.key,
    required this.semanticLabel,
    this.rows = 6,
  });

  final String semanticLabel;
  final int rows;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      child: ExcludeSemantics(
        child: ListView.builder(
          shrinkWrap: true,
          primary: false,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: rows,
          itemBuilder: (context, index) => const _SkeletonRow(),
        ),
      ),
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  @override
  Widget build(BuildContext context) {
    const box = BoxDecoration(
      color: BcColors.line,
      borderRadius: BorderRadius.all(Radius.circular(BcRadius.tag)),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: BcColors.line,
              borderRadius: BorderRadius.all(Radius.circular(BcRadius.control)),
            ),
          ),
          const SizedBox(width: BcSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FractionallySizedBox(
                  widthFactor: 0.7,
                  child: Container(height: 14, decoration: box),
                ),
                const SizedBox(height: BcSpace.s2),
                FractionallySizedBox(
                  widthFactor: 0.4,
                  child: Container(height: 10, decoration: box),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
