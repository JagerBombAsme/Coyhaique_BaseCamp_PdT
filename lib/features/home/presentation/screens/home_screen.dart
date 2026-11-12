import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/local/catalog_status_provider.dart';
import '../../../../core/models/category_model.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/theme/basecamp_tokens.dart';
import '../../../../core/widgets/basecamp/bc_widgets.dart';
import '../../../categories/data/providers/places_provider.dart' as places;
import '../../../categories/presentation/widgets/place_search_delegate.dart';
import '../../../routes/data/models/activity_dto.dart';
import '../../../routes/data/providers/activity_provider.dart';
import '../../../trip_info/presentation/widgets/trip_notice.dart';

/// Inicio con la identidad «afiche de montaña» (sistema Coyhaique BaseCamp).
///
/// Hero con el nombre detrás de la cumbre de Cerro Castillo, búsqueda
/// visible (HU-04), tours (HU-03), accesos a «Antes de tu viaje» (HU-25) y a
/// la información sin conexión (HU-09, HU-10), y categorías (HU-01).
class HomeScreen extends ConsumerStatefulWidget {
  final Function(String route) onNavigate;
  final VoidCallback onProfileClick;

  const HomeScreen({
    super.key,
    required this.onNavigate,
    required this.onProfileClick,
  });

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Aviso de uso seguro al entrar al inicio, una vez por sesión (RNF-14).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      TripNotice.show(context, kind: TripNoticeKind.home, oncePerSession: true);
    });
  }

  Future<void> _refresh() async {
    ref.invalidate(activitiesProvider);
    ref.invalidate(places.categoriesProvider);
    ref.invalidate(places.placesProvider);
    ref.invalidate(places.activitiesProvider);
    await ref.read(activitiesProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(languageProvider).languageCode;
    final isSpanish = language == 'es';

    final activitiesAsync = ref.watch(activitiesProvider);

    final categoriesAsync = ref.watch(places.mainCategoriesProvider);

    final activeCategories = categoriesAsync.maybeWhen(
      data: (value) => value,
      orElse: () => <CategoryModel>[],
    );
    final categoryList =
        activeCategories.isNotEmpty ? activeCategories : homeCategories;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: BcColors.fog,
        body: RefreshIndicator(
          onRefresh: _refresh,
          color: BcColors.ink,
          backgroundColor: BcColors.surface,
          edgeOffset: MediaQuery.paddingOf(context).top + 8,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _HomeHero(
                  isSpanish: isSpanish,
                  onProfile: widget.onProfileClick,
                ),
                const SizedBox(height: BcSpace.section),
                _buildTours(context, activitiesAsync, categoryList, isSpanish),
                const SizedBox(height: 22),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: BcSpace.gutter,
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: BcInfoTile(
                            dark: true,
                            icon: Icons.health_and_safety_rounded,
                            title: isSpanish
                                ? 'Antes de tu viaje'
                                : 'Before your trip',
                            subtitle: isSpanish
                                ? 'Emergencias, prevención y transporte'
                                : 'Emergencies, safety and transport',
                            onTap: () => context.push(tripInfoRoute),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: _OfflineTile(isSpanish: isSpanish)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: BcSpace.section),
                _ExploreBand(
                  isSpanish: isSpanish,
                  language: language,
                  categories: categoryList,
                  onCategoryTap: widget.onNavigate,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================================================================
  // TOURS
  // ================================================================

  Widget _buildTours(
    BuildContext context,
    AsyncValue<List<ActivityDto>> activitiesAsync,
    List<CategoryModel> categories,
    bool isSpanish,
  ) {
    return activitiesAsync.when(
      loading: () => const SizedBox(
        height: 240,
        child: Center(
          child: CircularProgressIndicator(color: BcColors.ink, strokeWidth: 2.5),
        ),
      ),
      error: (error, _) {
        debugPrint('ERROR ACTIVIDADES HOME: $error');
        return BcMessage(
          icon: Icons.cloud_off_rounded,
          text: isSpanish
              ? 'No fue posible cargar las actividades.'
              : 'Unable to load activities.',
          actionLabel: isSpanish ? 'Reintentar' : 'Retry',
          onAction: () => ref.invalidate(activitiesProvider),
        );
      },
      data: (activities) {
        if (activities.isEmpty) {
          return BcMessage(
            icon: Icons.explore_outlined,
            text: isSpanish
                ? 'No hay actividades disponibles actualmente.'
                : 'There are currently no activities available.',
          );
        }

        final categoryNames = {
          for (final c in categories) c.id: c.getNombre(isSpanish ? 'es' : 'en'),
        };

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BcSectionHeader(
              title: 'Tours',
              kicker: isSpanish
                  ? '${activities.length} ${activities.length == 1 ? 'actividad disponible' : 'actividades disponibles'}'
                  : '${activities.length} ${activities.length == 1 ? 'activity' : 'activities'} available',
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: BcTourCard.height,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: BcSpace.gutter),
                itemCount: activities.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final activity = activities[index];
                  return BcTourCard(
                    key: ValueKey(activity.id),
                    title: activity.getName(isSpanish),
                    image: activity.imageUrl ?? '',
                    tag: categoryNames[activity.categoryId],
                    subtitle: _subtitle(activity, isSpanish),
                    onTap: () => context.push('/attractions/${activity.id}'),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  String _subtitle(ActivityDto activity, bool isSpanish) {
    final price = activity.referencePrice?.trim();
    final normalized = price?.toLowerCase() ?? '';
    final isAvailabilityText =
        normalized.startsWith('ver disponibilidad con el operador');
    if (price != null && price.isNotEmpty && !isAvailabilityText) return price;

    final schedule = activity.schedule?.trim();
    if (schedule != null && schedule.isNotEmpty) return schedule;

    return isSpanish ? 'Ver información →' : 'View information →';
  }
}

// =================================================================
// HERO
// =================================================================

/// Hero: cielo de niebla, foto de Laguna Cerro Castillo, el nombre en
/// display y encima la misma foto recortada, para que las cumbres corten
/// las letras.
class _HomeHero extends StatelessWidget {
  const _HomeHero({required this.isSpanish, required this.onProfile});

  final bool isSpanish;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final top = MediaQuery.paddingOf(context).top;

    // Proporciones del concepto aprobado (pantalla de 412 px).
    final photoSize = width * 1.36;
    final photoLeft = -(photoSize - width) / 2;
    final photoTop = top + 88;
    final height = photoTop + photoSize - 50;

    Widget photo(String asset) => Positioned(
          left: photoLeft,
          top: photoTop,
          width: photoSize,
          height: photoSize,
          child: BcPhotoImage(source: asset),
        );

    return SizedBox(
      height: height,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Cielo de niebla.
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFD3D8DB), BcColors.fogDeep, Color(0xFF9AA3A8)],
                ),
              ),
            ),
          ),

          // Foto completa, fundida hacia arriba en la niebla.
          Positioned(
            left: photoLeft,
            top: photoTop,
            width: photoSize,
            height: photoSize,
            child: ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (rect) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0, 0.22],
                colors: [Colors.transparent, Colors.black],
              ).createShader(rect),
              child: const BcPhotoImage(source: BcPhoto.cerroCastillo),
            ),
          ),

          // Nombre del lugar, detrás de las cumbres.
          Positioned(
            left: 16,
            right: 16,
            top: photoTop + 6,
            child: Semantics(
              header: true,
              label: 'Coyhaique',
              excludeSemantics: true,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text('COYHAIQUE', style: BcText.displayHero),
              ),
            ),
          ),

          // Cumbres recortadas por delante del título.
          photo(BcPhoto.cerroCastilloRecorte),

          const Positioned.fill(child: BcPhotoShade(from: 0.55)),

          // Etiqueta del territorio.
          Positioned(
            left: BcSpace.gutter,
            top: photoTop - 26,
            child: const BcTag('Patagonia', lead: 'Aysén', style: BcTagStyle.ink),
          ),

          // Botones de esquina.
          Positioned(
            left: BcSpace.gutter,
            top: top + 14,
            child: BcCornerButton(
              icon: Icons.person_rounded,
              semanticLabel: isSpanish ? 'Perfil' : 'Profile',
              onTap: onProfile,
            ),
          ),
          Positioned(
            right: BcSpace.gutter,
            top: top + 14,
            child: BcCornerButton(
              icon: Icons.info_rounded,
              semanticLabel: isSpanish ? 'Antes de tu viaje' : 'Before your trip',
              onTap: () => context.push(tripInfoRoute),
            ),
          ),

          // Cifra, descripción y búsqueda.
          Positioned(
            left: BcSpace.gutter,
            right: BcSpace.gutter,
            bottom: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Icon(
                      Icons.landscape_rounded,
                      size: 38,
                      color: BcColors.onPhoto,
                    ),
                    const SizedBox(width: 8),
                    Text('45°34′S', style: BcText.figure()),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          isSpanish
                              ? 'CAPITAL REGIONAL\nDE AYSÉN'
                              : 'REGIONAL CAPITAL\nOF AYSÉN',
                          style: BcText.label(color: BcColors.onPhoto),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  isSpanish
                      ? 'Montañas, ríos patagónicos y naturaleza para descansar o salir a la aventura.'
                      : 'Mountains, Patagonian rivers and nature to rest or head out on an adventure.',
                  style: BcText.body(
                    color: BcColors.onPhoto.withValues(alpha: 0.88),
                  ),
                ),
                const SizedBox(height: 16),
                _SearchBar(isSpanish: isSpanish),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Campo visible que abre la búsqueda de lugares y actividades (HU-04).
class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.isSpanish});

  final bool isSpanish;

  @override
  Widget build(BuildContext context) {
    final label =
        isSpanish ? 'Buscar lugares y actividades' : 'Search places and activities';

    return BcPressable(
      semanticLabel: label,
      onTap: () => showSearch<void>(
        context: context,
        delegate: PlaceSearchDelegate(isSpanish: isSpanish),
      ),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: BcColors.surface.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(BcRadius.field),
        ),
        child: Row(
          children: [
            const Icon(Icons.search_rounded, color: BcColors.ink),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: BcText.body(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =================================================================
// INFORMACIÓN SIN CONEXIÓN (HU-09, HU-10)
// =================================================================

class _OfflineTile extends ConsumerWidget {
  const _OfflineTile({required this.isSpanish});

  final bool isSpanish;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(catalogStatusProvider);
    final date = status.lastSyncAt == null
        ? null
        : DateFormat('dd-MM-yyyy').format(status.lastSyncAt!);

    final (title, subtitle, icon) = switch (status) {
      _ when status.isSyncing => (
          isSpanish ? 'Descargando…' : 'Downloading…',
          isSpanish ? 'Para usar sin conexión' : 'For offline use',
          Icons.downloading_rounded,
        ),
      _ when status.usingOfflineData => (
          isSpanish ? 'Sin conexión' : 'Offline',
          isSpanish
              ? 'Viendo datos del $date'
              : 'Showing data from $date',
          Icons.cloud_off_rounded,
        ),
      _ when date != null => (
          isSpanish ? 'Disponible sin conexión' : 'Available offline',
          isSpanish ? 'Descargado el $date · Actualizar' : 'Downloaded $date · Update',
          Icons.download_done_rounded,
        ),
      _ => (
          isSpanish ? 'Descargar información' : 'Download information',
          isSpanish ? 'Para usarla sin señal' : 'To use it without signal',
          Icons.download_rounded,
        ),
    };

    return BcInfoTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      trailing: status.isSyncing
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: BcColors.ink),
            )
          : null,
      onTap: status.isSyncing ? null : () => _download(context, ref),
    );
  }

  Future<void> _download(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await ref.read(catalogStatusProvider.notifier).download();

    if (ok) {
      ref.invalidate(places.categoriesProvider);
      ref.invalidate(places.placesProvider);
      ref.invalidate(places.activitiesProvider);
      ref.invalidate(activitiesProvider);
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? (isSpanish
                  ? 'Descarga completa. La información está disponible sin conexión.'
                  : 'Download complete. Information is available offline.')
              : (isSpanish
                  ? 'No se pudo descargar. Se conserva la información anterior.'
                  : 'Download failed. The previous information was kept.'),
        ),
      ),
    );
  }
}

// =================================================================
// EXPLORAR
// =================================================================

/// Banda de foto con «EXPLORAR» y las categorías en grilla de dos columnas.
/// Las categorías que el usuario declaró como intereses van en azul.
class _ExploreBand extends ConsumerWidget {
  const _ExploreBand({
    required this.isSpanish,
    required this.language,
    required this.categories,
    required this.onCategoryTap,
  });

  final bool isSpanish;
  final String language;
  final List<CategoryModel> categories;
  final Function(String route) onCategoryTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final interests = ref.watch(places.validInterestsProvider);

    return Container(
      decoration: const BoxDecoration(
        color: BcColors.ink,
        image: DecorationImage(
          image: AssetImage('assets/images/cordon_divisadero.jpg'),
          fit: BoxFit.cover,
          alignment: Alignment(0, -0.4),
          colorFilter: BcPhoto.filter,
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0, 0.28, 0.55, 1],
            colors: [
              BcColors.fog,
              BcColors.fog.withValues(alpha: 0),
              Colors.transparent,
              BcColors.ink.withValues(alpha: 0.7),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 40, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    isSpanish ? 'EXPLORAR' : 'EXPLORE',
                    style: BcText.display(66, color: BcColors.onPhoto),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text.rich(
                  TextSpan(
                    style: BcText.label(color: BcColors.onPhoto),
                    children: [
                      TextSpan(text: isSpanish ? 'REGIÓN DE ' : 'REGION OF '),
                      TextSpan(
                        text: 'AYSÉN',
                        style: BcText.label(color: BcColors.glacier),
                      ),
                      const TextSpan(text: ' · CHILE'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 70),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: categories.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  mainAxisExtent: 50,
                ),
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return BcCategoryButton(
                    icon: category.icon,
                    label: category.getNombre(language),
                    highlighted: interests.contains(category.id),
                    onTap: () => onCategoryTap(category.route),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
