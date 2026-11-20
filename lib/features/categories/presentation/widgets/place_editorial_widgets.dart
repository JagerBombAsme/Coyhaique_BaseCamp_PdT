import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/basecamp_tokens.dart';
import '../../../../core/widgets/basecamp/bc_widgets.dart';
import '../../data/models/place_dto.dart';

// =================================================================
// DATOS DE APOYO (funciones puras, con prueba en test/)
// =================================================================

/// Si [value] trae texto real (no vacío, no «null», no «n/a»).
bool placeHasText(String? value) {
  if (value == null) return false;
  final normalized = value.trim().toLowerCase();
  return normalized.isNotEmpty && normalized != 'null' && normalized != 'n/a';
}

/// Fotos del lugar sin repetir: la portada primero y luego `place_media_v2`.
/// Una URL que aparece en ambas fuentes se cuenta una sola vez.
List<String> placePhotoUrls(PlaceDto place) {
  final seen = <String>{};
  final urls = <String>[];

  void add(String? raw) {
    if (!placeHasText(raw)) return;
    final url = raw!.trim();
    if (seen.add(url)) urls.add(url);
  }

  add(place.imageUrl);
  for (final item in place.media) {
    add(item.externalUrl);
  }
  return urls;
}

Duration _motion(BuildContext context, Duration normal) =>
    MediaQuery.disableAnimationsOf(context) ? Duration.zero : normal;

// =================================================================
// A. HERO FOTOGRÁFICO
// =================================================================

/// Fotografía a ancho completo con la categoría y el nombre encima.
/// Sin barra superior: solo Atrás y Actualizar flotando sobre la foto.
class PlaceHero extends StatelessWidget {
  const PlaceHero({
    super.key,
    required this.title,
    required this.categoryLabel,
    required this.photoUrl,
    required this.height,
    required this.backLabel,
    required this.reloadLabel,
    required this.onBack,
    required this.onReload,
  });

  final String title;
  final String categoryLabel;
  final String? photoUrl;
  final double height;
  final String backLabel;
  final String reloadLabel;
  final VoidCallback onBack;

  /// null mientras se actualiza (el botón queda deshabilitado).
  final VoidCallback? onReload;

  /// El título se achica con el largo para que quepa en 2–3 líneas.
  static double titleSize(int length) {
    if (length <= 14) return 46;
    if (length <= 26) return 38;
    return 31;
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final upper = title.toUpperCase();

    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          BcPhotoImage(source: photoUrl ?? ''),
          const BcPhotoShade(from: 0.3, topShade: 0.4),
          PositionedDirectional(
            top: top + BcSpace.s3,
            start: BcSpace.gutter,
            child: BcCornerButton(
              icon: Icons.arrow_back_rounded,
              semanticLabel: backLabel,
              onTap: onBack,
            ),
          ),
          PositionedDirectional(
            top: top + BcSpace.s3,
            end: BcSpace.gutter,
            child: BcCornerButton(
              icon: Icons.refresh_rounded,
              semanticLabel: reloadLabel,
              onTap: onReload,
            ),
          ),
          PositionedDirectional(
            start: BcSpace.gutter,
            end: BcSpace.gutter,
            bottom: 28,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                BcTag(categoryLabel),
                const SizedBox(height: BcSpace.s4),
                Semantics(
                  header: true,
                  child: Text(
                    upper,
                    style: BcText.display(
                      titleSize(upper.length),
                      color: BcColors.onPhoto,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =================================================================
// B. TRANSICIÓN EDITORIAL
// =================================================================

/// Franja bajo la foto: tipo de destino y la frase descriptiva si existe.
/// Va sobre el mismo fondo que el resto, sin tarjeta flotante.
class PlaceLede extends StatelessWidget {
  const PlaceLede({super.key, required this.kicker, this.lede});

  final String kicker;
  final String? lede;

  @override
  Widget build(BuildContext context) {
    final hasLede = placeHasText(lede);

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        BcSpace.gutter,
        24,
        BcSpace.gutter,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BcKicker(kicker),
          if (hasLede) ...[
            const SizedBox(height: BcSpace.s3),
            Text(
              lede!.trim(),
              style: BcText.title().copyWith(
                fontSize: 22,
                height: 1.25,
                letterSpacing: -0.3,
              ),
            ),
          ],
          const SizedBox(height: 24),
          const Divider(height: 1, thickness: 1, color: BcColors.line),
        ],
      ),
    );
  }
}

// =================================================================
// C. SOBRE EL LUGAR
// =================================================================

/// Encabezado de sección en tipografía editorial.
class PlaceSectionTitle extends StatelessWidget {
  const PlaceSectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(text.toUpperCase(), style: BcText.displaySection),
    );
  }
}

/// «Sobre el lugar»: descripción real con «Leer más» solo si no cabe en
/// [collapsedLines] líneas. Solo cambia lo que se ve, no los datos.
class PlaceAboutSection extends StatefulWidget {
  const PlaceAboutSection({
    super.key,
    required this.heading,
    required this.description,
    required this.emptyText,
    required this.moreLabel,
    required this.lessLabel,
  });

  final String heading;
  final String description;
  final String emptyText;
  final String moreLabel;
  final String lessLabel;

  static const int collapsedLines = 7;

  @override
  State<PlaceAboutSection> createState() => _PlaceAboutSectionState();
}

class _PlaceAboutSectionState extends State<PlaceAboutSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final hasText = placeHasText(widget.description);
    final style = BcText.body(
      color: BcColors.ink,
    ).copyWith(fontSize: 16, height: 1.6);

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        BcSpace.gutter,
        BcSpace.section,
        BcSpace.gutter,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PlaceSectionTitle(widget.heading),
          const SizedBox(height: BcSpace.s4),
          if (!hasText)
            Text(
              widget.emptyText,
              style: BcText.caption().copyWith(fontStyle: FontStyle.italic),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final painter = TextPainter(
                    text: TextSpan(text: widget.description, style: style),
                    maxLines: PlaceAboutSection.collapsedLines,
                    textDirection: Directionality.of(context),
                    textScaler: MediaQuery.textScalerOf(context),
                  )..layout(maxWidth: constraints.maxWidth);
                  final overflows = painter.didExceedMaxLines;
                  painter.dispose();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedSize(
                        duration: _motion(
                          context,
                          const Duration(milliseconds: 200),
                        ),
                        curve: Curves.easeOut,
                        alignment: Alignment.topCenter,
                        child: Text(
                          widget.description.trim(),
                          style: style,
                          maxLines: overflows && !_expanded
                              ? PlaceAboutSection.collapsedLines
                              : null,
                          overflow: TextOverflow.fade,
                        ),
                      ),
                      if (overflows)
                        BcPressable(
                          onTap: () => setState(() => _expanded = !_expanded),
                          semanticLabel: _expanded
                              ? widget.lessLabel
                              : widget.moreLabel,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 48),
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(
                                (_expanded ? widget.lessLabel : widget.moreLabel)
                                    .toUpperCase(),
                                style: BcText.label(color: BcColors.glacierDeep),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// =================================================================
// D. GALERÍA
// =================================================================

/// Galería horizontal y asimétrica. [urls] son las fotos que NO están ya
/// en el hero. Con una sola foto adicional ocupa todo el ancho.
class PlaceGallery extends StatelessWidget {
  const PlaceGallery({
    super.key,
    required this.heading,
    required this.countLabel,
    required this.urls,
    required this.photoLabel,
    required this.onOpen,
  });

  final String heading;
  final String countLabel;
  final List<String> urls;

  /// Texto accesible de cada foto (ej. «Foto 2 de 5»); recibe su posición.
  final String Function(int index) photoLabel;

  /// Abre la foto [index] (posición dentro de [urls]).
  final ValueChanged<int> onOpen;

  /// Ancho × alto de cada foto, en ciclo: proporciones distintas.
  static const List<(double, double)> _sizes = [
    (220, 300),
    (170, 220),
    (200, 260),
  ];

  @override
  Widget build(BuildContext context) {
    if (urls.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsetsDirectional.only(top: BcSpace.section + 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: BcSpace.gutter,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: PlaceSectionTitle(heading)),
                const SizedBox(width: BcSpace.s3),
                Text(countLabel.toUpperCase(), style: BcText.label(color: BcColors.muted)),
              ],
            ),
          ),
          const SizedBox(height: BcSpace.s4),
          if (urls.length == 1)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: BcSpace.gutter,
              ),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: _GalleryTile(
                  url: urls.first,
                  label: photoLabel(0),
                  onTap: () => onOpen(0),
                ),
              ),
            )
          else
            SizedBox(
              height: 300,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: BcSpace.gutter,
                ),
                itemCount: urls.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final (w, h) = _sizes[index % _sizes.length];
                  return Align(
                    alignment: index.isEven
                        ? Alignment.topCenter
                        : Alignment.bottomCenter,
                    child: SizedBox(
                      width: w,
                      height: h,
                      child: _GalleryTile(
                        url: urls[index],
                        label: photoLabel(index),
                        onTap: () => onOpen(index),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _GalleryTile extends StatelessWidget {
  const _GalleryTile({
    required this.url,
    required this.label,
    required this.onTap,
  });

  final String url;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BcPressable(
      onTap: onTap,
      semanticLabel: label,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(BcRadius.control),
        child: BcPhotoImage(source: url),
      ),
    );
  }
}

/// Visor de fotos a pantalla completa: desliza entre fotos y pellizca
/// para ampliar.
class PlacePhotoViewer extends StatefulWidget {
  const PlacePhotoViewer({
    super.key,
    required this.urls,
    required this.initialIndex,
    required this.closeLabel,
  });

  final List<String> urls;
  final int initialIndex;
  final String closeLabel;

  @override
  State<PlacePhotoViewer> createState() => _PlacePhotoViewerState();
}

class _PlacePhotoViewerState extends State<PlacePhotoViewer> {
  late final PageController _controller = PageController(
    initialPage: widget.initialIndex,
  );
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: BcColors.ink,
      body: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.urls.length,
            onPageChanged: (value) => setState(() => _index = value),
            itemBuilder: (context, index) {
              return InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Center(
                  child: CachedNetworkImage(
                    imageUrl: widget.urls[index],
                    fit: BoxFit.contain,
                    memCacheWidth: 1440,
                    placeholder: (_, _) =>
                        const BcLogoPlaceholder(showProgress: true),
                    errorWidget: (_, _, _) => const BcLogoPlaceholder(),
                  ),
                ),
              );
            },
          ),
          PositionedDirectional(
            top: top + BcSpace.s3,
            start: BcSpace.gutter,
            child: BcCornerButton(
              icon: Icons.close_rounded,
              semanticLabel: widget.closeLabel,
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
          PositionedDirectional(
            top: top + BcSpace.s3,
            end: BcSpace.gutter,
            child: Container(
              height: 50,
              alignment: Alignment.center,
              child: Text(
                '${_index + 1} / ${widget.urls.length}',
                style: BcText.label(color: BcColors.onPhoto),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =================================================================
// E. INFORMACIÓN PRÁCTICA
// =================================================================

class PlaceFact {
  const PlaceFact(this.label, this.value);

  final String label;
  final String value;
}

/// Datos prácticos como lista editorial: etiqueta pequeña, valor debajo y
/// una línea fina entre cada dato. Solo recibe los datos que existen.
class PlaceFacts extends StatelessWidget {
  const PlaceFacts({
    super.key,
    required this.heading,
    required this.facts,
    required this.disclaimer,
    required this.verification,
  });

  final String heading;
  final List<PlaceFact> facts;
  final String disclaimer;
  final String verification;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        BcSpace.gutter,
        BcSpace.section + 6,
        BcSpace.gutter,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (facts.isNotEmpty) ...[
            PlaceSectionTitle(heading),
            const SizedBox(height: BcSpace.s4),
            const Divider(height: 1, thickness: 1, color: BcColors.ink),
            for (final fact in facts)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: BcColors.line),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fact.label.toUpperCase(),
                      style: BcText.label(color: BcColors.muted),
                    ),
                    const SizedBox(height: BcSpace.s1),
                    Text(
                      fact.value,
                      style: BcText.body(
                        color: BcColors.ink,
                      ).copyWith(fontSize: 16, height: 1.4),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: BcSpace.s4 + 4),
          ],
          Text(disclaimer, style: BcText.caption()),
          const SizedBox(height: BcSpace.s2),
          Text(verification, style: BcText.caption()),
        ],
      ),
    );
  }
}

// =================================================================
// F. BARRA DE ACCIONES
// =================================================================

/// Barra inferior. Cada acción aparece solo si su callback no es null.
/// La principal (Cómo llegar) va en Glacier; las demás, debajo.
class PlaceActionBar extends StatelessWidget {
  const PlaceActionBar({
    super.key,
    required this.directionsLabel,
    required this.scheduleLabel,
    required this.websiteLabel,
    required this.infoLabel,
    this.onDirections,
    this.onSchedule,
    this.onWebsite,
    this.onInfo,
  });

  final String directionsLabel;
  final String scheduleLabel;
  final String websiteLabel;
  final String infoLabel;
  final VoidCallback? onDirections;
  final VoidCallback? onSchedule;
  final VoidCallback? onWebsite;
  final VoidCallback? onInfo;

  @override
  Widget build(BuildContext context) {
    final secondary = <Widget>[
      if (onSchedule != null)
        _SecondaryAction(
          icon: Icons.schedule_rounded,
          label: scheduleLabel,
          onTap: onSchedule!,
        ),
      if (onWebsite != null)
        _SecondaryAction(
          icon: Icons.language_rounded,
          label: websiteLabel,
          onTap: onWebsite!,
        ),
      if (onInfo != null)
        _SecondaryAction(
          icon: Icons.info_outline_rounded,
          label: infoLabel,
          onTap: onInfo!,
        ),
    ];

    if (onDirections == null && secondary.isEmpty) {
      return const SizedBox.shrink();
    }

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: BcColors.surface,
        border: Border(top: BorderSide(color: BcColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            BcSpace.gutter,
            BcSpace.s3,
            BcSpace.gutter,
            BcSpace.s3,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onDirections != null)
                BcButton(
                  label: directionsLabel,
                  icon: Icons.near_me_rounded,
                  onPressed: onDirections,
                ),
              if (onDirections != null && secondary.isNotEmpty)
                const SizedBox(height: BcSpace.s2),
              if (secondary.isNotEmpty)
                Row(
                  children: [
                    for (final action in secondary) Expanded(child: action),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecondaryAction extends StatelessWidget {
  const _SecondaryAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BcPressable(
      onTap: onTap,
      semanticLabel: label,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 6,
          horizontal: 4,
        ),
        child: ExcludeSemantics(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: BcColors.ink),
              const SizedBox(height: 2),
              Text(
                label,
                textAlign: TextAlign.center,
                style: BcText.caption(
                  color: BcColors.ink,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
