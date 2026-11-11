import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../../../core/local/catalog_status_provider.dart';
import '../../../../core/models/category_model.dart';
import '../../../../core/providers/auth/auth_user_provider.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/theme/basecamp_tokens.dart';
import '../../../../core/widgets/basecamp/bc_widgets.dart';
import '../../../categories/data/providers/places_provider.dart' as places;
import '../../../categories/presentation/widgets/place_search_delegate.dart';
import '../../../routes/data/models/activity_dto.dart';
import '../../../profile/presentation/screens/interests_screen.dart';
import '../../../routes/data/providers/activity_provider.dart';
import '../../../trip_info/presentation/widgets/trip_notice.dart';

/// Pantalla de inicio de Coyhaique BaseCamp.
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

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  static const _saveDelay = Duration(seconds: 12);
  static const _hintDuration = Duration(seconds: 6);
  final _captureKey = GlobalKey();
  final _saveKey = GlobalKey();
  late final AnimationController _flyCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );
  OverlayEntry? _flyEntry;
  Timer? _saveTimer;
  bool _isFlying = false;
  Rect? _lastTilesRect;

  /// Tarjetas invisibles mientras vuelan (siguen ocupando su lugar).
  bool _fading = false;

  /// Descarga en curso: el botón muestra un indicador y no responde.
  bool _saving = false;

  /// Captura de las tarjetas usada en el vuelo de ida y vuelta.
  ui.Image? _tilesImage;
  Timer? _hintTimer;

  /// Tarjetas guardadas en el botón (ocultas en su lugar).
  bool _tilesHidden = false;

  /// El botón aparece después del primer guardado.
  bool _buttonShown = false;
  String? _hint;
  bool get _isEs => ref.read(languageProvider).languageCode == 'es';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      TripNotice.show(context, kind: TripNoticeKind.home, oncePerSession: true);
    });
    _saveTimer = Timer(_saveDelay, _minimizeTiles);
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _hintTimer?.cancel();
    _flyEntry?.remove();
    _flyCtrl.dispose();
    _tilesImage?.dispose();
    super.dispose();
  }

  Rect? _rectOf(GlobalKey key) {
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  Rect _saveRect(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Rect.fromLTWH(BcSpace.gutter + 54, top + 14, 44, 44);
  }

  /// Rectángulo donde están las tarjetas (siempre 80 px de alto, aunque
  /// estén ocultas, para que el destino del vuelo sea estable).
  Rect? _tilesSlot() {
    final r = _rectOf(_captureKey);
    if (r == null) return null;
    return Rect.fromLTWH(r.left, r.top, r.width, _infoTileHeight);
  }

  /// Minimiza las tarjetas hacia el botón superior (efecto genie).
  Future<void> _minimizeTiles() async {
    if (!mounted || _tilesHidden || _isFlying) return;
    _isFlying = true;
    final screen = Offset.zero & MediaQuery.sizeOf(context);
    final tiles = _tilesSlot();
    _lastTilesRect = tiles;
    // Si las tarjetas están fuera de pantalla no hay nada que capturar:
    // se ocultan sin vuelo.
    final image = tiles != null && screen.overlaps(tiles)
        ? await _captureTiles()
        : null;
    if (!mounted) {
      image?.dispose();
      return;
    }
    if (kDebugMode) {
      debugPrint('Genie minimizar: tiles=$tiles captura=${image != null}');
    }
    if (tiles == null) {
      _finishMinimize();
      return;
    }
    _tilesImage?.dispose();
    _tilesImage = image;
    setState(() => _fading = true);
    _flyTiles(
      image: image,
      tiles: tiles,
      button: _saveRect(context),
      reverse: false,
      onDone: _finishMinimize,
    );
  }

  void _finishMinimize() {
    setState(() {
      _isFlying = false;
      _fading = false;
      _tilesHidden = true;
      _buttonShown = true;
    });
    _rememberFirst('home_hint_saved').then((first) {
      if (first && mounted) {
        _showHint(
          _isEs
              ? 'Aquí podrás ver tu descarga e información antes de comenzar tu viaje'
              : 'Here you can see your download and information before starting your trip',
        );
      }
    });
  }

  /// Botón de guardado: devuelve las tarjetas y descarga la información.
  Future<void> _onSaveTap() async {
    if (_saving) return;
    final isSpanish = _isEs;
    setState(() => _saving = true);
    final firstTap = await _rememberFirst('home_hint_download');
    if (!mounted) return;
    if (firstTap) {
      _showHint(
        isSpanish
            ? 'Descargarás siempre tu info'
            : 'You will always download your info',
      );
    }
    // La descarga empieza ya; las tarjetas vuelven mientras corre.
    final download = downloadOfflineCatalog(context, ref);
    if (_tilesHidden) _restoreTiles();
    await download;
    if (mounted) setState(() => _saving = false);
  }

  /// Devuelve las tarjetas desde el botón a su lugar original.
  void _restoreTiles() {
    final image = _tilesImage;
    final tiles = _lastTilesRect;
    if (_isFlying || tiles == null) {
      setState(() => _tilesHidden = false);
      return;
    }
    _isFlying = true;
    // Las tarjetas aparecen en su lugar al empezar el vuelo, pero invisibles,
    // para que al terminar el vuelo ya tengan su tamaño final (sin parpadeo).
    setState(() {
      _tilesHidden = false;
      _fading = true;
    });
    _flyTiles(
      image: image,
      tiles: tiles,
      button: _rectOf(_saveKey) ?? _saveRect(context),
      reverse: true,
      onDone: () => setState(() {
        _fading = false;
        _isFlying = false;
      }),
    );
  }

  /// Toma una imagen real de las tarjetas para deformarla en el vuelo.
  Future<ui.Image?> _captureTiles() async {
    try {
      final boundary =
          _captureKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) {
        if (kDebugMode) debugPrint('Genie: no hay zona de captura');
        return null;
      }
      final pixelRatio = MediaQuery.devicePixelRatioOf(context);
      return await boundary.toImage(pixelRatio: pixelRatio);
    } catch (error) {
      if (kDebugMode) debugPrint('Captura de tarjetas falló: $error');
      return null;
    }
  }

  /// Vuelo de la imagen. Con reverse=false va de las tarjetas al botón;
  /// con reverse=true, del botón a las tarjetas.
  void _flyTiles({
    required ui.Image? image,
    required Rect tiles,
    required Rect button,
    required bool reverse,
    required VoidCallback onDone,
  }) {
    _flyEntry?.remove();
    _flyCtrl.stop();
    final entry = OverlayEntry(
      builder: (_) => Positioned.fill(
        child: IgnorePointer(
          child: AnimatedBuilder(
            animation: _flyCtrl,
            builder: (_, __) => CustomPaint(
              painter: _GenieFlyPainter(
                image: image,
                progress: _flyCtrl.value,
                from: tiles,
                to: button,
              ),
            ),
          ),
        ),
      ),
    );
    _flyEntry = entry;
    Overlay.of(context, rootOverlay: true).insert(entry);
    final done = reverse
        ? _flyCtrl.reverse(from: 1)
        : _flyCtrl.forward(from: 0);
    done.whenComplete(() {
      if (_flyEntry == entry) {
        entry.remove();
        _flyEntry = null;
      }
      if (mounted) onDone();
    });
  }

  void _showHint(String text) {
    _hintTimer?.cancel();
    setState(() => _hint = text);
    _hintTimer = Timer(_hintDuration, () {
      if (mounted) setState(() => _hint = null);
    });
  }

  /// true solo la primera vez que se pide la clave (se guarda en el teléfono).
  Future<bool> _rememberFirst(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(key) ?? false) return false;
      await prefs.setBool(key, true);
      return true;
    } catch (_) {
      return false;
    }
  }

  List<Widget> _topOverlay(BuildContext context, bool isSpanish) {
    final top = MediaQuery.paddingOf(context).top;
    final left = BcSpace.gutter + 54;
    return [
      Positioned(
        left: BcSpace.gutter,
        top: top + 14,
        child: BcCornerButton(
          icon: Icons.person_rounded,
          semanticLabel: isSpanish ? 'Perfil' : 'Profile',
          onTap: widget.onProfileClick,
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
      if (_buttonShown)
        Positioned(
          left: left,
          top: top + 14,
          child: _SaveButton(
            key: _saveKey,
            isSpanish: isSpanish,
            busy: _saving,
            onTap: _onSaveTap,
          ),
        ),
      if (_hint != null)
        Positioned(
          left: left,
          right: BcSpace.gutter,
          top: top + 14 + 44 + 8,
          child: _HintBubble(text: _hint!),
        ),
    ];
  }

  Future<void> _refresh() async {
    ref.invalidate(activitiesProvider);
    ref.invalidate(places.categoriesProvider);
    ref.invalidate(places.mainCategoriesProvider);
    ref.invalidate(places.placesProvider);
    ref.invalidate(places.activitiesProvider);
    try {
      await ref.read(activitiesProvider.future);
    } catch (error) {
      if (kDebugMode) debugPrint('Error al actualizar inicio: $error');
    }
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
    final categoryList = activeCategories.isNotEmpty
        ? activeCategories
        : homeCategories;
    final isLoggedIn =
        ref.watch(authUserProvider).valueOrNull != null ||
        _currentSessionUser();
    // Intereses guardados (ids de categorías principales), en orden alfabético.
    final interestIds = ref.watch(places.validInterestsProvider);
    final interestCategories =
        categoryList.where((c) => interestIds.contains(c.id)).toList()..sort(
          (a, b) => a.getNombre(language).compareTo(b.getNombre(language)),
        );
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: BcColors.fog,
        body: Stack(
          fit: StackFit.expand,
          children: [
            RefreshIndicator(
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
                    _HomeHero(isSpanish: isSpanish),
                    _ExploreBand(
                      isSpanish: isSpanish,
                      language: language,
                      categories: categoryList,
                      onCategoryTap: widget.onNavigate,
                    ),
                    _InfoTiles(
                      captureKey: _captureKey,
                      isSpanish: isSpanish,
                      hidden: _tilesHidden,
                      faded: _fading,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: BcSpace.gutter,
                      ),
                      child: _SearchBar(isSpanish: isSpanish),
                    ),
                    const SizedBox(height: BcSpace.section),
                    if (isLoggedIn) ...[
                      _buildTours(
                        context,
                        activitiesAsync,
                        categoryList,
                        isSpanish,
                      ),
                      for (final category in interestCategories)
                        _InterestSection(
                          category: category,
                          isSpanish: isSpanish,
                          language: language,
                        ),
                      if (interestCategories.isEmpty)
                        _PersonalizeCta(
                          message: isSpanish
                              ? 'Aún no tienes intereses seleccionados.'
                              : "You haven't selected any interests yet.",
                          actionLabel: isSpanish
                              ? 'Selecciona tus intereses'
                              : 'Choose your interests',
                          onTap: () => context.push(interestsRoute),
                        ),
                    ] else ...[
                      _PersonalizeCta(
                        message: isSpanish
                            ? 'Selecciona tus intereses y personaliza tu app iniciando sesión.'
                            : 'Choose your interests and personalize your app by signing in.',
                        actionLabel: isSpanish ? 'Iniciar sesión' : 'Sign in',
                        onTap: () => context.push('/auth'),
                      ),
                      const SizedBox(height: BcSpace.section),
                      const _CoyhaiqueCarousel(),
                    ],
                  ],
                ),
              ),
            ),
            ..._topOverlay(context, isSpanish),
          ],
        ),
      ),
    );
  }

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
          child: CircularProgressIndicator(
            color: BcColors.ink,
            strokeWidth: 2.5,
          ),
        ),
      ),
      error: (error, _) {
        if (kDebugMode) debugPrint('ERROR ACTIVIDADES HOME: $error');
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
          for (final category in categories)
            category.id: category.getNombre(isSpanish ? 'es' : 'en'),
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
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final activity = activities[index];
                  return BcTourCard(
                    key: ValueKey(activity.id),
                    title: activity.getName(isSpanish),
                    image: activity.imageUrl ?? '',
                    tag: categoryNames[activity.categoryId],
                    metrics: _metrics(activity, isSpanish),
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

  List<BcMetric> _metrics(ActivityDto activity, bool isSpanish) {
    final price = activity.referencePrice?.trim() ?? '';
    final isAvailabilityText = price.toLowerCase().startsWith(
      'ver disponibilidad con el operador',
    );
    final schedule = activity.schedule?.trim() ?? '';
    final metrics = <BcMetric>[
      if (schedule.isNotEmpty) BcMetric(Icons.schedule_rounded, schedule),
      if (price.isNotEmpty && !isAvailabilityText)
        BcMetric(Icons.sell_outlined, price),
    ];
    if (metrics.isEmpty) {
      metrics.add(
        BcMetric(
          Icons.info_outline_rounded,
          isSpanish ? 'Ver información' : 'View information',
        ),
      );
    }
    return metrics;
  }
}

/// Texto de cada categoría en EXPLORAR, en forma de pregunta.
String _exploreLabel(CategoryModel category, String language) {
  final isEs = language == 'es';
  final group = (category.groupType ?? category.route).trim().toLowerCase();
  final label = switch (group) {
    'gastronomia' => isEs ? '¿Qué comer?' : 'What to eat?',
    'alojamiento' => isEs ? 'Dónde dormir' : 'Where to sleep',
    'atractivo' => isEs ? '¿Qué visitar?' : 'What to visit?',
    'actividad' => isEs ? '¿Qué hacer?' : 'What to do?',
    'transporte' => isEs ? '¿Cómo llegar?' : 'How to get there?',
    'servicio' => isEs ? '¿Qué necesito?' : 'What do I need?',
    _ => null,
  };
  return label ?? category.getNombre(language);
}

/// Tamaño del subtítulo de las tarjetas (cámbialo aquí).
const double _tileSubtitleSize = 8;

/// Alto de las tarjetas «Antes de tu viaje» y «Disponible sin conexión».
const double _infoTileHeight = 80;
const double _infoTilesGap = 10;

/// Espacio bajo las tarjetas, antes de la búsqueda.
const double _tilesBottomGap = 16;

/// Encabezado fotográfico: a los 6 segundos se desvanece y el contenido sube.
class _HomeHero extends StatefulWidget {
  const _HomeHero({required this.isSpanish});
  final bool isSpanish;
  @override
  State<_HomeHero> createState() => _HomeHeroState();
}

class _HomeHeroState extends State<_HomeHero> {
  static const _collapseDelay = Duration(seconds: 6);
  static const _animDuration = Duration(milliseconds: 700);
  static const _curve = Curves.easeInOutCubic;
  Timer? _timer;
  bool _collapsed = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(_collapseDelay, () {
      if (mounted) setState(() => _collapsed = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSpanish = widget.isSpanish;
    final width = MediaQuery.sizeOf(context).width;
    final top = MediaQuery.paddingOf(context).top;
    final collapsed = _collapsed;
    final photoSize = width * 1.36;
    final photoTop = top + 60;
    final expandedHeight = photoTop + photoSize - 50;
    final titleTop = photoTop + 70;
    return AnimatedContainer(
      duration: _animDuration,
      curve: _curve,
      height: collapsed ? 0 : expandedHeight,
      child: AnimatedOpacity(
        duration: _animDuration,
        opacity: collapsed ? 0 : 1,
        child: IgnorePointer(
          ignoring: collapsed,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              const Positioned.fill(
                child: BcPhotoImage(
                  source: BcPhoto.gauchosinr,
                  alignment: Alignment.center,
                ),
              ),
              const Positioned.fill(
                child: IgnorePointer(child: BcPhotoShade(from: 0.55)),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: top + 150,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          BcColors.ink.withValues(alpha: 0.55),
                          BcColors.ink.withValues(alpha: 0.25),
                          BcColors.ink.withValues(alpha: 0),
                        ],
                        stops: const [0, 0.6, 1],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                top: titleTop,
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
              Positioned(
                left: BcSpace.gutter,
                top: photoTop + 130,
                child: const BcTag(
                  'Patagonia',
                  lead: 'Aysén',
                  style: BcTagStyle.ink,
                ),
              ),
              Positioned(
                left: BcSpace.gutter,
                right: BcSpace.gutter,
                bottom: 24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
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
                        Text(
                          '45°34′S',
                          style: BcText.figure().copyWith(
                            color: BcColors.glacier,
                          ),
                        ),
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tarjetas «Antes de tu viaje» y «Disponible sin conexión», bajo EXPLORAR.
class _InfoTiles extends StatelessWidget {
  const _InfoTiles({
    required this.captureKey,
    required this.isSpanish,
    this.hidden = false,
    this.faded = false,
  });

  /// Zona que se captura para el efecto de vuelo.
  final GlobalKey captureKey;
  final bool isSpanish;

  /// Cuando están guardadas en el botón, se ocultan en su lugar.
  final bool hidden;

  /// Durante el vuelo siguen en su lugar, pero invisibles.
  final bool faded;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeInOutCubic,
      alignment: Alignment.topCenter,
      child: SizedBox(
        height: hidden ? 0 : _infoTileHeight + _tilesBottomGap,
        child: ClipRect(
          child: IgnorePointer(
            ignoring: hidden,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: BcSpace.gutter),
              child: Opacity(
                opacity: faded ? 0.0 : 1.0,
                child: SizedBox(
                  height: _infoTileHeight,
                  child: RepaintBoundary(
                    key: captureKey,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: BcWideInfoTile(
                            dark: true,
                            icon: Icons.health_and_safety_rounded,
                            title: isSpanish
                                ? 'Antes de tu viaje'
                                : 'Before your trip',
                            subtitle: isSpanish
                                ? 'Emergencias, prevención y transporte'
                                : 'Emergencies, safety and transport',
                            onTap: () => context.push(tripInfoRoute),
                            subtitleSize: _tileSubtitleSize,
                          ),
                        ),
                        const SizedBox(width: _infoTilesGap),
                        Expanded(child: _OfflineTile(isSpanish: isSpanish)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Botón de guardado, a la derecha de Perfil.
class _SaveButton extends StatelessWidget {
  const _SaveButton({
    super.key,
    required this.isSpanish,
    required this.busy,
    required this.onTap,
  });
  final bool isSpanish;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (busy) {
      return Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: BcColors.surface,
          shape: BoxShape.circle,
        ),
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: BcColors.ink),
        ),
      );
    }
    return SizedBox(
      width: 44,
      height: 44,
      child: BcCornerButton(
        icon: Icons.download_done_rounded,
        semanticLabel: isSpanish
            ? 'Descargar información'
            : 'Download information',
        onTap: onTap,
      ),
    );
  }
}

/// Globo de texto sobre el botón de guardado.
class _HintBubble extends StatelessWidget {
  const _HintBubble({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: BcColors.ink,
          borderRadius: BorderRadius.circular(BcRadius.control),
        ),
        child: Text(text, style: BcText.caption(color: BcColors.onPhoto)),
      ),
    );
  }
}

/// Campo de búsqueda de lugares y actividades.
class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.isSpanish});
  final bool isSpanish;

  @override
  Widget build(BuildContext context) {
    final label = isSpanish
        ? 'Buscar lugares y actividades'
        : 'Search places and activities';
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

/// Estado y descarga del catálogo sin conexión (tarjeta oscura).
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
        date == null
            ? (isSpanish ? 'Datos guardados' : 'Saved data')
            : (isSpanish
                  ? 'Viendo datos del $date'
                  : 'Showing data from $date'),
        Icons.cloud_off_rounded,
      ),
      _ when date != null => (
        isSpanish ? 'Disponible sin conexión' : 'Available offline',
        isSpanish
            ? 'Descargado el $date · Actualizar'
            : 'Downloaded $date · Update',
        Icons.download_done_rounded,
      ),
      _ => (
        isSpanish ? 'Descargar información' : 'Download information',
        isSpanish ? 'Para usarla sin señal' : 'To use it without signal',
        Icons.download_rounded,
      ),
    };
    return BcWideInfoTile(
      dark: true,
      icon: icon,
      title: title,
      subtitle: subtitle,
      subtitleSize: _tileSubtitleSize,
      trailing: status.isSyncing
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: BcColors.glacier,
              ),
            )
          : null,
      onTap: status.isSyncing
          ? null
          : () => downloadOfflineCatalog(context, ref),
    );
  }
}

Future<void> downloadOfflineCatalog(BuildContext context, WidgetRef ref) async {
  final isSpanish = ref.read(languageProvider).languageCode == 'es';
  bool ok;
  try {
    ok = await ref.read(catalogStatusProvider.notifier).download();
  } catch (error) {
    if (kDebugMode) debugPrint('Error al descargar catálogo: $error');
    ok = false;
  }
  if (!context.mounted) return;
  if (ok) {
    ref.invalidate(places.categoriesProvider);
    ref.invalidate(places.mainCategoriesProvider);
    ref.invalidate(places.placesProvider);
    ref.invalidate(places.activitiesProvider);
    ref.invalidate(activitiesProvider);
  }
  ScaffoldMessenger.of(context).showSnackBar(
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

/// true si hay una sesión de Supabase abierta (sin esperar al stream).
bool _currentSessionUser() {
  try {
    return Supabase.instance.client.auth.currentUser != null;
  } catch (_) {
    return false;
  }
}

/// Tours de una categoría de interés elegida por el usuario.
class _InterestSection extends ConsumerWidget {
  const _InterestSection({
    required this.category,
    required this.isSpanish,
    required this.language,
  });
  final CategoryModel category;
  final bool isSpanish;
  final String language;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Un interés es una categoría principal: sus lugares pueden estar
    // asignados a sus subcategorías, igual que en la pantalla de categoría.
    final allCategories =
        ref.watch(places.categoriesProvider).valueOrNull ?? const [];
    final ids = <String>{
      category.id,
      for (final c in allCategories)
        if (c.parentId == category.id) c.id,
    };
    final places_ = ref.watch(places.placesProvider).valueOrNull ?? const [];
    final activities_ =
        ref.watch(places.activitiesProvider).valueOrNull ?? const [];
    final items = [
      ...places_,
      ...activities_,
    ].where((p) => ids.contains(p.categoryId)).toList();
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BcSectionHeader(
          title: category.getNombre(language),
          kicker: isSpanish
              ? '${items.length} ${items.length == 1 ? 'lugar' : 'lugares'}'
              : '${items.length} ${items.length == 1 ? 'place' : 'places'}',
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: BcTourCard.height,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: BcSpace.gutter),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final place = items[index];
              final subtitle = place.getSubtitle(isSpanish);
              return BcTourCard(
                key: ValueKey(place.id),
                title: place.getTitle(isSpanish),
                image: place.imageUrl ?? '',
                metrics: [
                  if (subtitle.isNotEmpty)
                    BcMetric(Icons.place_outlined, subtitle),
                ],
                onTap: () => context.push('/attractions/${place.id}'),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Mensaje con un botón (iniciar sesión o elegir intereses).
class _PersonalizeCta extends StatelessWidget {
  const _PersonalizeCta({
    required this.message,
    required this.actionLabel,
    required this.onTap,
  });
  final String message;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: BcSpace.gutter),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: BcColors.surface,
          borderRadius: BorderRadius.circular(BcRadius.tile),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message, style: BcText.body(color: BcColors.ink)),
            const SizedBox(height: 14),
            BcButton(label: actionLabel, onPressed: onTap),
          ],
        ),
      ),
    );
  }
}

/// Carrusel de fotos de Coyhaique (para invitados).
class _CoyhaiqueCarousel extends StatelessWidget {
  const _CoyhaiqueCarousel();
  static const List<String> _photos = [
    'assets/images/centro_de_coyhaique.png',
    'assets/images/cerro_castillo_laguna.jpg',
    'assets/images/mckay.jpg',
    'assets/images/cordon_divisadero.jpg',
    'assets/images/sendero_leneros.jpg',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const BcSectionHeader(title: 'Coyhaique'),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: BcSpace.gutter),
            itemCount: _photos.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) => ClipRRect(
              borderRadius: BorderRadius.circular(BcRadius.card),
              child: SizedBox(
                width: 260,
                child: BcPhotoImage(source: _photos[index]),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Banda de exploración con categorías destacadas.
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
    return ColoredBox(
      color: BcColors.surface,
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
                  style: BcText.display(66, color: BcColors.ink),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text.rich(
                TextSpan(
                  style: BcText.label(color: BcColors.ink),
                  children: [
                    TextSpan(text: isSpanish ? 'REGIÓN DE ' : 'REGION OF '),
                    TextSpan(
                      text: 'AYSÉN',
                      style: BcText.label(color: BcColors.glacierDeep),
                    ),
                    const TextSpan(text: ' · CHILE'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              height: 46,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: categories.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return BcCategoryChip(
                      icon: Icons.apps_rounded,
                      label: isSpanish ? 'Todo' : 'All',
                      onTap: () => onCategoryTap('todos'),
                    );
                  }
                  final category = categories[index - 1];
                  return BcCategoryChip(
                    icon: category.icon,
                    label: _exploreLabel(category, language),
                    highlighted: interests.contains(category.id),
                    onTap: () => onCategoryTap(category.route),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pinta la imagen de las tarjetas en franjas horizontales que se encogen
/// hacia el botón (efecto genie). progress: 0 = tarjetas, 1 = botón.
class _GenieFlyPainter extends CustomPainter {
  _GenieFlyPainter({
    required this.image,
    required this.progress,
    required this.from,
    required this.to,
  });
  final ui.Image? image;
  final double progress;
  final Rect from;
  final Rect to;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress >= 1.0) return;
    final double p = Curves.easeInOutCubic.transform(progress.clamp(0.0, 1.0));
    final int rows = from.height.round();
    if (rows <= 0) return;
    final img = image;
    final double srcW = img == null ? 0.0 : img.width.toDouble();
    final double srcH = img == null ? 0.0 : img.height.toDouble();
    final double scaleY = srcH / rows;
    final double widthNow = from.width + (to.width - from.width) * p * p;
    final paint = Paint()
      ..filterQuality = FilterQuality.medium
      ..isAntiAlias = true;
    for (var i = 0; i < rows; i++) {
      final double ratio = i / rows;
      final double lp = math.pow(p, 1.5 + (1 - ratio) / 2).toDouble();
      if (lp >= 1.0) continue;
      final double yFrom = from.top + i;
      final double yTo = to.top + (ratio * to.height);
      final double y =
          yFrom + (yTo - yFrom) * lp - (35 * math.sin(math.pi * p));
      final double twist = math.sin(ratio * math.pi / 2);
      final double sliceW = from.width - (from.width - widthNow) * twist;
      final double cx = from.center.dx + (to.center.dx - from.center.dx) * lp;
      final double h = math.max(0.5, 1.0 - (0.5 * lp));
      final dst = Rect.fromLTWH(cx - (sliceW / 2), y, sliceW, h);
      if (img == null) {
        canvas.drawRect(dst, Paint()..color = BcColors.ink);
      } else {
        canvas.drawImageRect(
          img,
          Rect.fromLTWH(0, i * scaleY, srcW, scaleY),
          dst,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GenieFlyPainter old) =>
      old.progress != progress ||
      old.image != image ||
      old.from != from ||
      old.to != to;
}
