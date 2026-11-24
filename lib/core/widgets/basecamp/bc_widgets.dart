import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../theme/basecamp_tokens.dart';

class BcPressable extends StatefulWidget {
  const BcPressable({
    super.key,
    required this.child,
    this.onTap,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  State<BcPressable> createState() => _BcPressableState();
}

class _BcPressableState extends State<BcPressable> {
  bool _down = false;

  void _set(bool value) {
    if (widget.onTap == null || _down == value) return;
    setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: widget.onTap != null,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        child: AnimatedScale(
          scale: _down ? 0.96 : 1,
          duration: const Duration(milliseconds: 110),
          child: widget.child,
        ),
      ),
    );
  }
}

class BcPhotoImage extends StatelessWidget {
  const BcPhotoImage({
    super.key,
    required this.source,
    this.alignment = Alignment.center,
    this.fit = BoxFit.cover,
  });

  final String source;
  final Alignment alignment;
  final BoxFit fit;

  /// Ancho máximo de decodificación, en píxeles. Una foto a pantalla
  /// completa en un teléfono de 3x no necesita más.
  static const int _maxDecodeWidth = 1440;

  @override
  Widget build(BuildContext context) {
    // Sin foto: fondo tinta con el logo BC tenue, nunca una foto ajena.
    const fallback = BcLogoPlaceholder();

    if (source.trim().isEmpty) return fallback;

    // La foto se decodifica al tamaño con que se dibuja y no al de su
    // archivo original (muchas vienen de sitios externos en alta
    // resolución). Sin ancho acotado se decodifica completa.
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final decodeWidth = width.isFinite && width > 0
            ? math.min((width * pixelRatio).ceil(), _maxDecodeWidth)
            : null;

        final image = source.startsWith('http')
            // Con caché en disco: una foto ya vista se reutiliza.
            ? CachedNetworkImage(
                imageUrl: source,
                fit: fit,
                alignment: alignment,
                memCacheWidth: decodeWidth,
                fadeInDuration: const Duration(milliseconds: 200),
                errorWidget: (_, _, _) => fallback,
              )
            : Image.asset(
                source,
                fit: fit,
                alignment: alignment,
                cacheWidth: decodeWidth,
                errorBuilder: (_, _, _) => fallback,
              );

        return ColorFiltered(colorFilter: BcPhoto.filter, child: image);
      },
    );
  }
}

class BcLogoPlaceholder extends StatelessWidget {
  const BcLogoPlaceholder({super.key, this.showProgress = false});

  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: BcColors.ink,
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          FractionallySizedBox(
            widthFactor: 0.6,
            child: Opacity(
              opacity: 0.22,
              child: Image.asset(
                BcBrand.logoWhite,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.landscape_rounded,
                  size: 56,
                  color: BcColors.glacier,
                ),
              ),
            ),
          ),
          if (showProgress)
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: BcColors.glacier,
              ),
            ),
        ],
      ),
    );
  }
}

/// Degradado oscuro bajo el texto que va sobre una foto.
class BcPhotoShade extends StatelessWidget {
  const BcPhotoShade({super.key, this.from = 0.4, this.topShade = 0});

  /// Fracción de la altura donde empieza el oscurecimiento inferior.
  final double from;

  /// Opacidad de una franja oscura arriba (para la barra de estado).
  final double topShade;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0, 0.18, from, 1],
            colors: [
              BcColors.ink.withValues(alpha: topShade),
              BcColors.ink.withValues(alpha: 0),
              BcColors.ink.withValues(alpha: 0),
              BcColors.photoShade,
            ],
          ),
        ),
      ),
    );
  }
}

// =================================================================
// ETIQUETAS
// =================================================================

enum BcTagStyle { glacier, ink }

/// Etiqueta corta en mayúsculas. En la variante [BcTagStyle.ink], [lead]
/// va en azul glaciar («AYSÉN» · PATAGONIA).
class BcTag extends StatelessWidget {
  const BcTag(
    this.text, {
    super.key,
    this.style = BcTagStyle.glacier,
    this.lead,
  });

  final String text;
  final String? lead;
  final BcTagStyle style;

  @override
  Widget build(BuildContext context) {
    final isInk = style == BcTagStyle.ink;
    final fg = isInk ? BcColors.onPhoto : BcColors.ink;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: isInk ? BcColors.ink : BcColors.glacier,
        borderRadius: BorderRadius.circular(BcRadius.tag),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            if (lead != null)
              TextSpan(
                text: '${lead!.toUpperCase()} · ',
                style: BcText.label(
                  color: isInk ? BcColors.glacier : BcColors.ink,
                ),
              ),
            TextSpan(
              text: text.toUpperCase(),
              style: BcText.label(color: fg),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kicker sobre un título: punto azul y texto gris en mayúsculas.
class BcKicker extends StatelessWidget {
  const BcKicker(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: BcColors.glacierDeep,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text.toUpperCase(),
            style: BcText.label(color: BcColors.muted),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class BcCornerButton extends StatelessWidget {
  const BcCornerButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return BcPressable(
      onTap: onTap,
      semanticLabel: semanticLabel,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: BcColors.surface.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(BcRadius.field),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F000000),
              blurRadius: 18,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Icon(icon, color: BcColors.ink, size: 24),
      ),
    );
  }
}

enum BcButtonStyle { glacier, surface, ink }

class BcButton extends StatelessWidget {
  const BcButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.style = BcButtonStyle.glacier,
    this.isLoading = false,
    this.height = 54,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final BcButtonStyle style;
  final bool isLoading;
  final double height;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (style) {
      BcButtonStyle.glacier => (BcColors.glacier, BcColors.ink),
      BcButtonStyle.surface => (BcColors.surface, BcColors.ink),
      BcButtonStyle.ink => (BcColors.ink, BcColors.onPhoto),
    };
    final enabled = onPressed != null && !isLoading;

    return SizedBox(
      width: double.infinity,
      height: height,
      child: FilledButton(
        onPressed: enabled ? onPressed : null,
        style: FilledButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          disabledBackgroundColor: bg.withValues(alpha: 0.6),
          disabledForegroundColor: fg.withValues(alpha: 0.7),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BcRadius.field),
          ),
          textStyle: BcText.button(color: fg),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4, color: fg),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 22),
                    const SizedBox(width: 10),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: BcText.button(color: fg),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class BcCategoryButton extends StatelessWidget {
  const BcCategoryButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return BcPressable(
      onTap: onTap,
      semanticLabel: label,
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: highlighted
              ? BcColors.glacier
              : BcColors.surface.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(BcRadius.control),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: BcColors.ink),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: BcText.title(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Chip horizontal de categoría (fila desplazable, estilo «Hiking»).
class BcCategoryChip extends StatelessWidget {
  const BcCategoryChip({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return BcPressable(
      onTap: onTap,
      semanticLabel: label,
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: highlighted ? BcColors.glacier : BcColors.fog,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: BcColors.ink),
            const SizedBox(width: 8),
            Text(label, maxLines: 1, style: BcText.title()),
          ],
        ),
      ),
    );
  }
}

/// Encabezado de sección: kicker opcional, título display y «Ver todos».
class BcSectionHeader extends StatelessWidget {
  const BcSectionHeader({
    super.key,
    required this.title,
    this.kicker,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? kicker;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: BcSpace.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (kicker != null) ...[BcKicker(kicker!), const SizedBox(height: 8)],
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    title.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: BcText.displaySection,
                  ),
                ),
              ),
              if (actionLabel != null && onAction != null)
                BcPressable(
                  onTap: onAction,
                  semanticLabel: actionLabel,
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 44),
                    alignment: Alignment.bottomCenter,
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Container(
                      padding: const EdgeInsets.only(bottom: 2),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: BcColors.glacier, width: 2),
                        ),
                      ),
                      child: Text(actionLabel!, style: BcText.title()),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Dato corto de una tarjeta de tour (horario, precio, etc.).
class BcMetric {
  const BcMetric(this.icon, this.text);

  final IconData icon;
  final String text;
}

/// Tarjeta grande con foto para carruseles: título arriba, datos y flecha abajo.
class BcTourCard extends StatelessWidget {
  const BcTourCard({
    super.key,
    required this.title,
    required this.image,
    required this.onTap,
    this.tag,
    this.metrics = const [],
  });

  final String title;
  final String image;
  final VoidCallback onTap;
  final String? tag;
  final List<BcMetric> metrics;

  static const double width = 270;
  static const double height = 300;

  @override
  Widget build(BuildContext context) {
    return BcPressable(
      onTap: onTap,
      semanticLabel: [title, ...metrics.map((m) => m.text)].join(', '),
      child: SizedBox(
        width: width,
        height: height,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(BcRadius.card),
          child: Stack(
            fit: StackFit.expand,
            children: [
              BcPhotoImage(source: image),
              const BcPhotoShade(from: 0.35),
              Positioned(
                left: 16,
                right: 16,
                top: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (tag != null && tag!.isNotEmpty) ...[
                      BcTag(tag!),
                      const SizedBox(height: 10),
                    ],
                    Text(
                      title.toUpperCase(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: BcText.displayCard,
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 16,
                right: 64,
                bottom: 16,
                child: _TourMetricsRow(metrics: metrics),
              ),
              Positioned(
                right: 14,
                bottom: 14,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: BcColors.surface.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: BcColors.onPhoto.withValues(alpha: 0.6),
                    ),
                  ),
                  child: const Icon(
                    Icons.arrow_outward_rounded,
                    size: 20,
                    color: BcColors.onPhoto,
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

class _TourMetricsRow extends StatelessWidget {
  const _TourMetricsRow({required this.metrics});

  final List<BcMetric> metrics;

  @override
  Widget build(BuildContext context) {
    if (metrics.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 14,
      runSpacing: 6,
      children: [
        for (final metric in metrics)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(metric.icon, size: 16, color: BcColors.glacier),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  metric.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: BcText.caption(color: BcColors.onPhoto),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// Tile de información o acceso rápido (oscuro o claro).
class BcInfoTile extends StatelessWidget {
  const BcInfoTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.dark = false,
    this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool dark;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final fg = dark ? BcColors.onPhoto : BcColors.ink;

    return BcPressable(
      onTap: onTap,
      semanticLabel: subtitle == null ? title : '$title. $subtitle',
      child: Container(
        constraints: const BoxConstraints(minHeight: 112),
        padding: const EdgeInsets.only(
          left: 14,
          top: 10,
          right: 14,
          bottom: 14,
        ),
        decoration: BoxDecoration(
          color: dark ? BcColors.ink : BcColors.surface,
          borderRadius: BorderRadius.circular(BcRadius.tile),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: dark ? BcColors.glacier : BcColors.ink),
                const Spacer(),
                ?trailing,
              ],
            ),
            const SizedBox(height: 16),
            Text(title, style: BcText.title(color: fg)),
            if (subtitle != null) ...[
              const SizedBox(height: 1),
              Text(
                subtitle!,
                style: BcText.caption(
                  color: dark
                      ? BcColors.onPhoto.withValues(alpha: 0.78)
                      : BcColors.muted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Grupo de filas sobre fondo blanco (preferencias, cuenta).
class BcListGroup extends StatelessWidget {
  const BcListGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        rows.add(const Divider(height: 1, thickness: 1, color: BcColors.line));
      }
      rows.add(children[i]);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(BcRadius.tile),
      child: Material(
        color: BcColors.surface,
        child: Column(children: rows),
      ),
    );
  }
}

/// Fila de un [BcListGroup].
class BcListRow extends StatelessWidget {
  const BcListRow({
    super.key,
    required this.icon,
    required this.label,
    this.value,
    this.onTap,
    this.danger = false,
    this.showChevron = true,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback? onTap;
  final bool danger;
  final bool showChevron;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final color = danger ? BcColors.danger : BcColors.ink;

    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 54),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label, style: BcText.title(color: color)),
              ),
              if (value != null) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    value!,
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    style: BcText.caption(),
                  ),
                ),
              ],
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
              if (showChevron && onTap != null && trailing == null) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: BcColors.muted,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Mensaje de estado (vacío, error) con acción opcional.
class BcMessage extends StatelessWidget {
  const BcMessage({
    super.key,
    required this.icon,
    required this.text,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 36, color: BcColors.muted),
          const SizedBox(height: 10),
          Text(
            text,
            textAlign: TextAlign.center,
            style: BcText.body(color: BcColors.ink),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: 200,
              child: BcButton(
                label: actionLabel!,
                icon: Icons.refresh_rounded,
                style: BcButtonStyle.ink,
                height: 46,
                onPressed: onAction,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Tile horizontal: icono a la izquierda y título con subtítulo al lado.
class BcWideInfoTile extends StatelessWidget {
  const BcWideInfoTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.dark = false,
    this.onTap,
    this.trailing,
    this.subtitleSize,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool dark;
  final VoidCallback? onTap;
  final Widget? trailing;
  final double? subtitleSize;

  /// Ícono sobre el texto, para tarjetas angostas. Con dos tarjetas lado a
  /// lado (~175 dp) el ícono al costado dejaba ~85 dp para el texto y el
  /// subtítulo se partía en cinco líneas. Es un parámetro y no un
  /// LayoutBuilder porque la tarjeta suele ir dentro de un IntrinsicHeight.
  final bool compact;

  /// Ancho bajo el cual conviene [compact].
  static const double compactBelowWidth = 200;

  @override
  Widget build(BuildContext context) {
    final fg = dark ? BcColors.onPhoto : BcColors.ink;
    final iconColor = dark ? BcColors.glacier : BcColors.ink;
    final extra = trailing;

    final texts = <Widget>[
      Text(title, style: BcText.title(color: fg).copyWith(fontSize: 13)),
      if (subtitle != null) ...[
        const SizedBox(height: 2),
        Text(
          subtitle!,
          style: BcText.caption(
            color: dark
                ? BcColors.onPhoto.withValues(alpha: 0.78)
                : BcColors.muted,
          ).copyWith(fontSize: subtitleSize),
        ),
      ],
    ];

    return BcPressable(
      onTap: onTap,
      semanticLabel: subtitle == null ? title : '$title. $subtitle',
      child: Container(
            constraints: const BoxConstraints(minHeight: 88),
            padding: compact
                ? const EdgeInsets.all(12)
                : const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            decoration: BoxDecoration(
              color: dark ? BcColors.ink : BcColors.surface,
              borderRadius: BorderRadius.circular(BcRadius.tile),
            ),
            child: compact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(icon, size: 28, color: iconColor),
                          const Spacer(),
                          ?extra,
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...texts,
                    ],
                  )
                : Row(
                    children: [
                      Icon(icon, size: 32, color: iconColor),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: texts,
                        ),
                      ),
                      if (extra != null) ...[const SizedBox(width: 8), extra],
                    ],
                  ),
      ),
    );
  }
}
