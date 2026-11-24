import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../theme/basecamp_tokens.dart';
import '../../utils/text_normalizer.dart';

class BcPressable extends StatefulWidget {
  const BcPressable({
    super.key,
    required this.child,
    this.onTap,
    this.semanticLabel,
    this.selected,
  });

  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final bool? selected;

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
    final enabled = widget.onTap != null;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final content = AnimatedScale(
      scale: enabled && _down && !reduceMotion ? 0.96 : 1,
      duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 110),
      child: widget.child,
    );
    if (!enabled) return content;

    return Semantics(
      button: true,
      enabled: true,
      selected: widget.selected,
      label: widget.semanticLabel,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: _set,
          child: content,
        ),
      ),
    );
  }
}

/// Los slugs del catálogo tienen prioridad sobre nombres traducidos y grupos.
const _bcSubcategoryAssets = <String, String>{
  'cafeterias': 'gastronomia/cafeterias.jpg',
  'restaurantes': 'gastronomia/restaurantes.jpg',
  'comida-tradicional': 'gastronomia/comida-tradicional.jpg',
  'fuentes-de-soda': 'gastronomia/fuentes-de-soda.jpg',
  'hoteles': 'alojamiento/hoteles.jpg',
  'cabanas': 'alojamiento/cabanas.jpg',
  'departamentos': 'alojamiento/departamentos.jpg',
  'buses': 'transporte/buses.jpg',
  'rent-a-car': 'transporte/rent-a-car.jpg',
  'bencineras': 'servicios/bencineras.jpg',
  'estacionamientos': 'servicios/estacionamientos.jpg',
  'banos-publicos': 'servicios/banos-publicos.jpg',
  'agencias-de-viaje': 'servicios/agencias-de-viaje.jpg',
};

/// Nombres en ambos idiomas y equivalencias del catálogo anterior.
/// Las variantes específicas se evalúan antes de las generales (restaurante).
const _bcSubcategoryAliases = <String, List<String>>{
  'comida-tradicional': [
    'comida tradicional', 'gastronomia patagonica', 'comida patagonica',
    'comida casera', 'comida chilena', 'comida tipica', 'parrilladas',
    'traditional and patagonian food', 'traditional food', 'patagonian food',
  ],
  'fuentes-de-soda': ['fuente de soda', 'fuentes de soda', 'colaciones',
    'diner', 'diners', 'set lunches'],
  'cafeterias': ['cafeteria', 'cafeterias', 'cafe', 'cafes', 'coffee shop',
    'coffee shops', 'chocolateria', 'pasteleria'],
  'restaurantes': ['restaurante', 'restaurantes', 'restaurant', 'restaurants'],
  'cabanas': ['cabana', 'cabanas', 'cabin', 'cabins'],
  'departamentos': ['departamento', 'departamentos', 'apartment', 'apartments'],
  'hoteles': ['hotel', 'hoteles', 'hotels', 'lodge'],
  'rent-a-car': ['rent a car', 'car rental', 'rental car', 'arriendo de autos'],
  'buses': ['bus', 'buses', 'bus interurbano'],
  'bencineras': ['bencinera', 'bencineras', 'estacion de servicio',
    'gas station', 'gas stations', 'fuel station', 'petrol station'],
  'estacionamientos': ['estacionamiento', 'estacionamientos', 'parking'],
  'banos-publicos': ['bano publico', 'banos publicos', 'public restroom',
    'public restrooms', 'public toilet', 'public toilets'],
  'agencias-de-viaje': ['agencia de viaje', 'agencias de viaje',
    'agencia de viajes', 'agencias de viajes', 'travel agency',
    'travel agencies', 'receptivo y emisivo'],
};

/// Foto ilustrativa local, nunca añadida a la galería real del lugar.
/// Si no hay una referencia específica, conserva los respaldos generales.
String bcReferenceAsset(String? category) {
  final key = normalizeForSearch(category);
  const base = 'assets/images/fallback';
  // Las llamadas del catálogo pasan primero el slug, seguido del grupo y
  // nombre. Se revisa primero ese identificador, sin depender del idioma.
  final tokens = key.split(' ');
  final slugAsset = _bcSubcategoryAssets[tokens.first];
  if (slugAsset != null) return '$base/$slugAsset';

  final words = ' ${key.replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim()} ';
  for (final entry in _bcSubcategoryAliases.entries) {
    if (entry.value.any((alias) => words.contains(' $alias '))) {
      return '$base/${_bcSubcategoryAssets[entry.key]}';
    }
  }
  bool matches(List<String> terms) => terms.any(key.contains);
  if (matches(['gastro', 'restauran', 'cafe', 'food', 'cocina', 'bar', 'pub'])) {
    return 'assets/images/gastronomia_fogon.jpg';
  }
  if (matches(['aloj', 'hotel', 'hostal', 'hostel', 'cabana', 'lodge', 'accommodation', 'hosped', 'departamento', 'camping'])) {
    return 'assets/images/alojamiento_hotel.jpg';
  }
  if (matches(['cultur', 'muse', 'histor', 'artesan', 'patrimonio', 'heritage'])) {
    return 'assets/images/cultura_gaucho.jpg';
  }
  if (matches(['transp', 'transfer', 'bus', 'rent a car', 'rent-a-car', 'taxi', 'servicio', 'service'])) {
    return 'assets/images/miradores_coyhaique.jpg';
  }
  if (matches(['avent', 'advent', 'actividad', 'activity', 'activit', 'sender', 'trek', 'hiking', 'kayak', 'ciclismo', 'ruta', 'route', 'tour'])) {
    return 'assets/images/mountain_hike.jpg';
  }
  if (matches(['natur', 'parque', 'park', 'reserva', 'reserve', 'bosque', 'forest'])) {
    return 'assets/images/nature_green_forest.jpg';
  }
  return 'assets/images/cerro_castillo_panoramico.jpg';
}

/// Respaldo para lugares del planificador que no conservan el slug.
String bcReferenceCategoryForIcon(IconData icon) {
  if (icon == Icons.restaurant_rounded || icon == Icons.restaurant) return 'gastronomia';
  if (icon == Icons.hotel_rounded || icon == Icons.hotel) return 'alojamiento';
  if (icon == Icons.museum_rounded) return 'cultura';
  if (icon == Icons.park_rounded) return 'naturaleza';
  if (icon == Icons.directions_run_rounded || icon == Icons.directions_run) return 'aventura';
  if (icon == Icons.directions_bus_rounded || icon == Icons.directions_bus) return 'transporte';
  return '';
}

class BcReferencePhoto extends StatelessWidget {
  const BcReferencePhoto({
    super.key,
    required this.category,
    required this.isSpanish,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.cacheWidth,
  });

  final String category;
  final bool isSpanish;
  final BoxFit fit;
  final Alignment alignment;
  final int? cacheWidth;

  @override
  Widget build(BuildContext context) {
    final label = isSpanish ? 'Imagen referencial' : 'Illustrative image';
    return Semantics(
      image: true,
      label: label,
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final showLabel = constraints.maxWidth >= 160 &&
                constraints.maxHeight >= 100;
            return Stack(
              fit: StackFit.passthrough,
              children: [
                Image.asset(
                  bcReferenceAsset(category),
                  fit: fit,
                  alignment: alignment,
                  width: constraints.maxWidth.isFinite ? constraints.maxWidth : null,
                  height: constraints.maxHeight.isFinite ? constraints.maxHeight : null,
                  cacheWidth: cacheWidth,
                  errorBuilder: (_, _, _) => const BcLogoPlaceholder(),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: Align(
                      alignment: showLabel ? Alignment.center : Alignment.bottomRight,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                          decoration: BoxDecoration(
                            color: BcColors.ink,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: showLabel
                              ? Text(
                                  label,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.white, fontSize: 11),
                                )
                              : const Icon(Icons.image_outlined, size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
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
    this.fallbackCategory,
    this.isSpanish = true,
  });

  final String source;

  /// Null conserva el respaldo de marca (p. ej. galerías reales).
  /// Una cadena vacía usa el paisaje genérico.
  final String? fallbackCategory;
  final bool isSpanish;
  final Alignment alignment;
  final BoxFit fit;

  /// Ancho máximo de decodificación, en píxeles. Una foto a pantalla
  /// completa en un teléfono de 3x no necesita más.
  static const int _maxDecodeWidth = 1440;

  @override
  Widget build(BuildContext context) {
    final cleanSource = source.trim();

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

        final fallback = fallbackCategory == null
            ? const BcLogoPlaceholder()
            : BcReferencePhoto(
                category: fallbackCategory!,
                isSpanish: isSpanish,
                fit: fit,
                alignment: alignment,
                cacheWidth: decodeWidth,
              );
        if (cleanSource.isEmpty ||
            const {'null', 'n/a', 'undefined'}.contains(cleanSource.toLowerCase())) {
          return fallback;
        }
        final uri = Uri.tryParse(cleanSource);
        final isNetwork = uri != null &&
            (uri.scheme == 'http' || uri.scheme == 'https') && uri.host.isNotEmpty;
        if (!isNetwork && !cleanSource.startsWith('assets/')) return fallback;
        final image = isNetwork
            // Con caché en disco: una foto ya vista se reutiliza.
            ? CachedNetworkImage(
                imageUrl: cleanSource,
                fit: fit,
                alignment: alignment,
                memCacheWidth: decodeWidth,
                fadeInDuration: const Duration(milliseconds: 200),
                errorWidget: (_, _, _) => fallback,
              )
            : Image.asset(
                cleanSource,
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
          minimumSize: Size(0, math.max(48.0, height)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        child: isLoading
            ? Semantics(
                label: label,
                liveRegion: true,
                child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4, color: fg),
                ),
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
                      textAlign: TextAlign.center,
                      softWrap: true,
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
      selected: highlighted,
      child: Container(
        constraints: const BoxConstraints(minHeight: 50),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
      selected: highlighted,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
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
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 300 ||
                  MediaQuery.textScalerOf(context).scale(15) > 19;
              final heading = Semantics(
                header: true,
                child: Text(title.toUpperCase(), style: BcText.displaySection),
              );
              final action = actionLabel != null && onAction != null
                  ? TextButton(
                      onPressed: onAction,
                      style: TextButton.styleFrom(
                        foregroundColor: BcColors.glacierDeep,
                        minimumSize: const Size(48, 48),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: Text(actionLabel!, style: BcText.title()),
                    )
                  : null;
              if (stacked) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [heading, if (action != null) action],
                );
              }
              return Row(
                children: [
                  Expanded(child: heading),
                  if (action != null) Flexible(child: action),
                ],
              );
            },
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
    this.fallbackCategory,
    this.isSpanish = true,
  });

  final String title;
  final String image;
  final VoidCallback onTap;
  final String? tag;
  final List<BcMetric> metrics;
  final String? fallbackCategory;
  final bool isSpanish;

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
              BcPhotoImage(source: image, fallbackCategory: fallbackCategory, isSpanish: isSpanish),
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
