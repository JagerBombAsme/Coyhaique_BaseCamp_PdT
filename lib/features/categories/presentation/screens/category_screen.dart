import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/category_model.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/theme/basecamp_tokens.dart';
import '../../../../core/utils/text_normalizer.dart';
import '../../../../core/widgets/basecamp/bc_widgets.dart';
import '../../data/models/place_dto.dart';
import '../../data/providers/places_provider.dart';
import '../../../transport/presentation/widgets/transfer_widgets.dart';

/// Pantalla de una categoría principal (HU-01, HU-02).
///
/// Un solo nivel: título de la categoría principal (por ejemplo
/// GASTRONOMÍA), sus subcategorías como filtros (Todas · Cafeterías ·
/// Restaurantes…) y los lugares debajo. Si [category] es una subcategoría,
/// se abre su principal con ese filtro elegido.
///
/// Se recarga solo deslizando hacia abajo.
class CategoryScreen extends ConsumerStatefulWidget {
  const CategoryScreen({
    super.key,
    required this.category,
    required this.onPlaceClick,
    required this.onRoutesClick,
  });

  /// Slug, UUID o nombre de la categoría.
  final String category;
  final ValueChanged<String> onPlaceClick;
  final VoidCallback onRoutesClick;

  @override
  ConsumerState<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends ConsumerState<CategoryScreen> {
  /// Subcategoría elegida; null = Todas.
  String? _selectedId;
  bool _initialized = false;
  String _query = '';

  /// Foto de cabecera por grupo (assets del proyecto).
  static const Map<String, String> _groupPhotos = {
    'atractivo': 'assets/images/cerro_castillo_panoramico.jpg',
    'actividad': 'assets/images/sendero_leneros.jpg',
    'gastronomia': 'assets/images/gastronomia_fogon.jpg',
    'alojamiento': 'assets/images/alojamiento_hotel.jpg',
    'transporte': 'assets/images/cordon_divisadero.jpg',
    'servicio': 'assets/images/miradores_coyhaique.jpg',
  };

  Future<void> _refresh() async {
    ref.invalidate(categoriesProvider);
    ref.invalidate(placesProvider);
    ref.invalidate(activitiesProvider);
    try {
      await Future.wait([
        ref.read(categoriesProvider.future),
        ref.read(placesProvider.future),
        ref.read(activitiesProvider.future),
      ]);
    } catch (_) {
      // El error se muestra en la pantalla con «Reintentar».
    }
  }

  @override
  Widget build(BuildContext context) {
    final normalized = widget.category.trim().toLowerCase();

    // Ruta antigua de «aventura»: lleva a recorridos.
    if (normalized == 'aventura') {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => widget.onRoutesClick(),
      );
      return const Scaffold(backgroundColor: BcColors.fog);
    }

    final language = ref.watch(languageProvider).languageCode;
    final isSpanish = language == 'es';
    final categoriesAsync = ref.watch(categoriesProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: BcColors.fog,
        body: categoriesAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: BcColors.ink),
          ),
          error: (_, _) => _ErrorBody(
            isSpanish: isSpanish,
            text: isSpanish
                ? 'No hay conexión ni información descargada. Conéctate a Internet y vuelve a intentarlo.'
                : 'There is no connection and no downloaded information. Connect to the Internet and try again.',
            onRetry: _refresh,
          ),
          data: (categories) {
            final resolved = _resolve(categories, normalized);
            if (resolved == null) {
              return _ErrorBody(
                isSpanish: isSpanish,
                icon: Icons.search_off_rounded,
                text: isSpanish
                    ? 'Esta categoría no está disponible.'
                    : 'This category is not available.',
                onRetry: _refresh,
              );
            }

            if (!_initialized) {
              _initialized = true;
              _selectedId = resolved.preselectedId;
            }

            return _buildContent(context, resolved, language, isSpanish);
          },
        ),
      ),
    );
  }

  // ================================================================
  // RESOLVER CATEGORÍA PRINCIPAL Y SUBCATEGORÍAS
  // ================================================================

  _Resolved? _resolve(List<CategoryModel> categories, String normalized) {
    bool matches(CategoryModel c) =>
        c.slug.toLowerCase() == normalized ||
        c.id.toLowerCase() == normalized ||
        c.nombreEs.trim().toLowerCase() == normalized;

    const groupAliases = {
      'actividades': 'actividad',
      'alojamientos': 'alojamiento',
      'atractivos': 'atractivo',
      'explorar': 'atractivo',
      'gastronomía': 'gastronomia',
      'servicios': 'servicio',
      'transportes': 'transporte',
    };
    final key = groupAliases[normalized] ?? normalized;

    final active = categories.where((c) => c.isActive).toList();
    final hasTree = hasCategoryTree(active);

    CategoryModel? found;
    for (final c in active) {
      if (matches(c) || c.slug.toLowerCase() == key) {
        found = c;
        break;
      }
    }

    final match = found;

    // Grupo sin categoría principal (base antigua sin jerarquía).
    final groupType = (match?.groupType ?? key).trim().toLowerCase();

    if (hasTree && match != null && !match.isMain) {
      // Subcategoría: abre su principal con ese filtro.
      final parentId = match.parentId;
      final parent = active.where((c) => c.id == parentId).firstOrNull;
      return _Resolved(
        main: parent,
        groupType: parent?.groupType?.toLowerCase() ?? groupType,
        preselectedId: match.id,
      );
    }

    if (hasTree && match != null && match.isMain) {
      return _Resolved(main: match, groupType: groupType);
    }

    // Base sin jerarquía: grupo conocido o categoría suelta.
    final groupExists = active.any(
      (c) => c.groupType?.trim().toLowerCase() == groupType,
    );
    if (match == null && !groupExists) return null;
    return _Resolved(
      main: null,
      groupType: groupType,
      preselectedId: match != null && match.slug.toLowerCase() != key
          ? match.id
          : null,
    );
  }

  // ================================================================
  // CONTENIDO
  // ================================================================

  Widget _buildContent(
    BuildContext context,
    _Resolved resolved,
    String language,
    bool isSpanish,
  ) {
    final subsAsync = ref.watch(categoriesByGroupProvider(resolved.groupType));
    final placesAsync = ref.watch(placesProvider);
    final activitiesAsync = ref.watch(activitiesProvider);

    final subs = subsAsync.valueOrNull ?? const <CategoryModel>[];
    final subIds = subs.map((c) => c.id).toSet();
    final subNames = {for (final c in subs) c.id: c.getNombre(language)};

    final loading = placesAsync.isLoading || activitiesAsync.isLoading;
    final failed = placesAsync.hasError && activitiesAsync.hasError;

    final all = <PlaceDto>[
      ...placesAsync.valueOrNull ?? const [],
      ...activitiesAsync.valueOrNull ?? const [],
    ];

    final term = normalizeForSearch(_query);
    final items =
        all
            .where(
              (p) => _selectedId == null
                  ? subIds.contains(p.categoryId)
                  : p.categoryId == _selectedId,
            )
            .where(
              (p) =>
                  term.isEmpty ||
                  normalizeForSearch(p.titleEs).contains(term) ||
                  normalizeForSearch(p.titleEn).contains(term) ||
                  normalizeForSearch(p.address).contains(term),
            )
            .toList()
          ..sort(
            (a, b) => normalizeForSearch(
              a.getTitle(isSpanish),
            ).compareTo(normalizeForSearch(b.getTitle(isSpanish))),
          );

    final title =
        resolved.main?.getNombre(language) ??
        _groupTitle(resolved.groupType, isSpanish);

    return RefreshIndicator(
      onRefresh: _refresh,
      color: BcColors.ink,
      backgroundColor: BcColors.surface,
      edgeOffset: MediaQuery.paddingOf(context).top,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _Header(
              title: title,
              photo: _groupPhotos[resolved.groupType] ?? BcPhoto.cerroCastillo,
              count: loading ? null : items.length,
              isSpanish: isSpanish,
            ),
          ),

          // Filtros por subcategoría.
          if (subs.length > 1)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 64,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(
                    BcSpace.gutter,
                    16,
                    BcSpace.gutter,
                    8,
                  ),
                  children: [
                    _FilterChip(
                      label: isSpanish ? 'Todas' : 'All',
                      selected: _selectedId == null,
                      onTap: () => setState(() => _selectedId = null),
                    ),
                    for (final sub in subs)
                      _FilterChip(
                        label: sub.getNombre(language),
                        selected: _selectedId == sub.id,
                        onTap: () => setState(() => _selectedId = sub.id),
                      ),
                  ],
                ),
              ),
            ),

          // Transfer desde el aeropuerto (HU-18), solo en Transporte.
          if (resolved.groupType == 'transporte')
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  BcSpace.gutter,
                  12,
                  BcSpace.gutter,
                  4,
                ),
                child: TransferEntryCard(
                  isSpanish: isSpanish,
                  onTap: () => context.push(transfersRoute),
                ),
              ),
            ),

          // Búsqueda dentro de la categoría.
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                BcSpace.gutter,
                8,
                BcSpace.gutter,
                12,
              ),
              child: TextField(
                onChanged: (value) => setState(() => _query = value),
                textInputAction: TextInputAction.search,
                style: BcText.body(color: BcColors.ink),
                decoration: InputDecoration(
                  hintText: isSpanish
                      ? 'Buscar en ${title.toLowerCase()}'
                      : 'Search in ${title.toLowerCase()}',
                  hintStyle: BcText.body(),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: BcColors.ink,
                  ),
                  filled: true,
                  fillColor: BcColors.surface,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(BcRadius.field),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(BcRadius.field),
                    borderSide: const BorderSide(
                      color: BcColors.glacierDeep,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
          ),

          if (loading && all.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: CircularProgressIndicator(color: BcColors.ink),
              ),
            )
          else if (failed)
            SliverToBoxAdapter(
              child: BcMessage(
                icon: Icons.cloud_off_rounded,
                text: isSpanish
                    ? 'No hay conexión ni información descargada. Conéctate a Internet y vuelve a intentarlo.'
                    : 'There is no connection and no downloaded information. Connect to the Internet and try again.',
                actionLabel: isSpanish ? 'Reintentar' : 'Retry',
                onAction: _refresh,
              ),
            )
          else if (items.isEmpty)
            SliverToBoxAdapter(
              child: BcMessage(
                icon: Icons.search_off_rounded,
                text: term.isNotEmpty
                    ? (isSpanish
                          ? 'Sin resultados para «$_query».'
                          : 'No results for "$_query".')
                    : (isSpanish
                          ? 'Todavía no hay lugares publicados en esta categoría.'
                          : 'There are no places published in this category yet.'),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                BcSpace.gutter,
                0,
                BcSpace.gutter,
                40,
              ),
              sliver: SliverList.separated(
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final place = items[index];
                  return _PlaceCard(
                    place: place,
                    isSpanish: isSpanish,
                    subcategory: _selectedId == null
                        ? subNames[place.categoryId]
                        : null,
                    onTap: () => widget.onPlaceClick(place.id),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  String _groupTitle(String groupType, bool isSpanish) {
    return switch (groupType) {
      'atractivo' => isSpanish ? 'Atractivos' : 'Attractions',
      'actividad' => isSpanish ? 'Actividades y tours' : 'Activities and tours',
      'gastronomia' => isSpanish ? 'Gastronomía' : 'Food and drink',
      'alojamiento' => isSpanish ? 'Alojamiento' : 'Accommodation',
      'transporte' => isSpanish ? 'Transporte' : 'Transport',
      'servicio' => isSpanish ? 'Servicios' : 'Services',
      _ => groupType,
    };
  }
}

class _Resolved {
  const _Resolved({
    required this.main,
    required this.groupType,
    this.preselectedId,
  });

  final CategoryModel? main;
  final String groupType;
  final String? preselectedId;
}

// =================================================================
// CABECERA
// =================================================================

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.photo,
    required this.count,
    required this.isSpanish,
  });

  final String title;
  final String photo;
  final int? count;
  final bool isSpanish;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    return SizedBox(
      height: top + 230,
      child: Stack(
        fit: StackFit.expand,
        children: [
          BcPhotoImage(source: photo),
          const BcPhotoShade(from: 0.35, topShade: 0.4),
          Positioned(
            left: BcSpace.gutter,
            top: top + 14,
            child: BcCornerButton(
              icon: Icons.arrow_back_rounded,
              semanticLabel: isSpanish ? 'Volver' : 'Back',
              onTap: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/home');
                }
              },
            ),
          ),
          Positioned(
            left: BcSpace.gutter,
            right: BcSpace.gutter,
            bottom: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BcTag(
                  count == null
                      ? (isSpanish ? 'Cargando' : 'Loading')
                      : isSpanish
                      ? '$count ${count == 1 ? 'lugar' : 'lugares'}'
                      : '$count ${count == 1 ? 'place' : 'places'}',
                  lead: 'Aysén',
                  style: BcTagStyle.ink,
                ),
                const SizedBox(height: 12),
                Semantics(
                  header: true,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      title.toUpperCase(),
                      style: BcText.display(52, color: BcColors.onPhoto),
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
// FILTRO
// =================================================================

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Semantics(
        selected: selected,
        button: true,
        child: BcPressable(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? BcColors.ink : BcColors.surface,
              borderRadius: BorderRadius.circular(BcRadius.pill),
            ),
            child: Text(
              label,
              style: BcText.title(
                color: selected ? BcColors.onPhoto : BcColors.ink,
              ).copyWith(fontSize: 14),
            ),
          ),
        ),
      ),
    );
  }
}

// =================================================================
// TARJETA DE LUGAR
// =================================================================

class _PlaceCard extends StatelessWidget {
  const _PlaceCard({
    required this.place,
    required this.isSpanish,
    required this.onTap,
    this.subcategory,
  });

  final PlaceDto place;
  final bool isSpanish;
  final VoidCallback onTap;

  /// Se muestra solo con el filtro «Todas».
  final String? subcategory;

  @override
  Widget build(BuildContext context) {
    final subtitle = place.getSubtitle(isSpanish);

    return BcPressable(
      onTap: onTap,
      semanticLabel: place.getTitle(isSpanish),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: BcColors.surface,
          borderRadius: BorderRadius.circular(BcRadius.tile),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(BcRadius.control),
              child: SizedBox(
                width: 88,
                height: 88,
                child: BcPhotoImage(source: place.imageUrl ?? ''),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (subcategory != null && subcategory!.isNotEmpty) ...[
                    Text(
                      subcategory!.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: BcText.label(color: BcColors.glacierDeep),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    place.getTitle(isSpanish),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: BcText.title().copyWith(fontSize: 16),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: BcText.caption(),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: BcColors.muted),
          ],
        ),
      ),
    );
  }
}

// =================================================================
// ERROR
// =================================================================

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({
    required this.isSpanish,
    required this.text,
    required this.onRetry,
    this.icon = Icons.cloud_off_rounded,
  });

  final bool isSpanish;
  final String text;
  final Future<void> Function() onRetry;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    return Stack(
      children: [
        Center(
          child: BcMessage(
            icon: icon,
            text: text,
            actionLabel: isSpanish ? 'Reintentar' : 'Retry',
            onAction: onRetry,
          ),
        ),
        Positioned(
          left: BcSpace.gutter,
          top: top + 14,
          child: BcCornerButton(
            icon: Icons.arrow_back_rounded,
            semanticLabel: isSpanish ? 'Volver' : 'Back',
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
          ),
        ),
      ],
    );
  }
}
