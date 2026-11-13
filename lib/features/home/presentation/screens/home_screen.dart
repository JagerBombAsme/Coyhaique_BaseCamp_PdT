import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
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
    with TickerProviderStateMixin {
  static const _saveDelay = Duration(seconds: 12);

  /// Momento del vuelo (0–1) en que el contenido de abajo empieza a subir.
  /// En 0,5 las tarjetas ya están saliendo de su zona por el embudo, así el
  /// contenido sube «detrás» de ellas. Al restaurar es el mismo punto en
  /// reversa: el espacio se abre antes de que las tarjetas aterricen.
  static const double _spaceMoveAt = 0.5;

  /// Resorte del espacio de las tarjetas: amortiguamiento crítico (ratio 1),
  /// sin rebote, ~0,55 s. Más rigidez = más rápido; ratio < 1 = rebota.
  static final _spaceSpring = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 140,
    ratio: 1,
  );
  static const _hintDuration = Duration(seconds: 6);

  /// Duración del vuelo de las tarjetas hacia el botón (y de vuelta).
  /// Súbela o bájala aquí para hacer la animación más lenta o más rápida.
  static const _flyDuration = Duration(milliseconds: 4200);
  final _captureKey = GlobalKey();
  final _saveKey = GlobalKey();
  late final AnimationController _flyCtrl = AnimationController(
    vsync: this,
    duration: _flyDuration,
  );

  /// Parte abierta del espacio de las tarjetas (1 = abierto, 0 = cerrado).
  /// Va aparte del vuelo: el contenido de abajo sube con su propio resorte.
  late final AnimationController _spaceCtrl = AnimationController(
    vsync: this,
    value: 1,
  );
  Timer? _saveTimer;
  Timer? _hintTimer;

  /// Hay un vuelo (o su preparación) en curso: no se acepta otro.
  bool _busy = false;

  /// El vuelo se está dibujando: las tarjetas originales quedan invisibles.
  bool _animating = false;

  /// Tarjetas guardadas en el botón (el espacio que ocupaban está cerrado).
  bool _minimized = false;

  /// Descarga en curso: el botón muestra un indicador y no responde.
  bool _saving = false;

  /// Captura de las tarjetas usada en el vuelo de ida y vuelta.
  ui.Image? _tilesImage;
  OverlayEntry? _activeOverlay;

  /// Dónde estaban las tarjetas al minimizarlas (respaldo para el regreso).
  Rect? _originalRect;

  /// El botón aparece después del primer guardado.
  bool _buttonShown = false;
  String? _hint;
  bool get _isEs => ref.read(languageProvider).languageCode == 'es';

  /// Cierra o abre el espacio de las tarjetas con el resorte, partiendo de
  /// la posición y velocidad actuales (si se invierte a medio camino, no salta).
  void _moveSpace({required bool open}) {
    final target = open ? 1.0 : 0.0;
    if (_spaceCtrl.value == target && !_spaceCtrl.isAnimating) return;
    _spaceCtrl.animateWith(
      SpringSimulation(
        _spaceSpring,
        _spaceCtrl.value,
        target,
        _spaceCtrl.velocity,
        tolerance: const Tolerance(distance: 0.001, velocity: 0.01),
      ),
    );
  }

  /// Cuenta las llegadas al botón; cada cambio dispara su rebote.
  int _arrivals = 0;
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
    // Retirar el overlay antes de liberar la imagen a la que puede acceder.
    _activeOverlay?.remove();
    _activeOverlay?.dispose();
    _activeOverlay = null;
    _flyCtrl.dispose();
    _spaceCtrl.dispose();
    _tilesImage?.dispose();
    super.dispose();
  }

  /// Posición y tamaño de un widget relativos al Overlay donde se dibuja el vuelo.
  Rect? _rect(GlobalKey key, RenderBox overlayBox) {
    final object = key.currentContext?.findRenderObject();
    if (object is! RenderBox || !object.attached || !object.hasSize) {
      return null;
    }
    try {
      return object.localToGlobal(Offset.zero, ancestor: overlayBox) &
          object.size;
    } catch (error) {
      if (kDebugMode) debugPrint('Genie: no se pudo medir el widget: $error');
      return null;
    }
  }

  Rect _saveRect(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Rect.fromLTWH(BcSpace.gutter + 54, top + 14, 44, 44);
  }

  void _genieLog(String message) {
    if (kDebugMode) debugPrint('Genie: $message');
  }

  /// Minimiza las tarjetas hacia el botón superior (efecto genie).
  Future<void> _minimizeTiles() => _runGenie(restoring: false);

  /// El usuario vuelve a guardar las tarjetas en el botón cuando quiera.
  void _hideTiles() {
    if (_busy || _saving || _minimized) return;
    // Si aún no corrió el guardado automático, ya no hace falta.
    _saveTimer?.cancel();
    unawaited(_minimizeTiles());
  }

  void _finishMinimize() {
    setState(() {
      _minimized = true;
      _buttonShown = true;
      _arrivals++;
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
    if (_saving || _busy) return;
    setState(() => _saving = true);
    try {
      final firstTap = await _rememberFirst('home_hint_download');
      if (!mounted) return;
      if (firstTap) {
        _showHint(
          _isEs
              ? 'Descargarás siempre tu info'
              : 'You will always download your info',
        );
      }
      // Terminar primero la restauración: evita cambios de catálogo mientras
      // la imagen capturada se está deformando en pantalla.
      if (_minimized) await _runGenie(restoring: true);
      if (!mounted) return;
      await downloadOfflineCatalog(context, ref);
    } catch (error, stack) {
      if (kDebugMode) debugPrint('Genie / descarga: $error\n$stack');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Toma una imagen real de las tarjetas para deformarla en el vuelo.
  Future<ui.Image?> _captureTiles() async {
    // Esperar a que Flutter termine el fotograma evita capturar antes de
    // que la zona esté pintada.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return null;
    final object = _captureKey.currentContext?.findRenderObject();
    // debugNeedsPaint solo existe en modo debug: en release lanzaría error.
    if (object is! RenderRepaintBoundary ||
        !object.attached ||
        (kDebugMode && object.debugNeedsPaint)) {
      if (kDebugMode) debugPrint('Genie: no hay zona de captura');
      return null;
    }
    try {
      final ratio = MediaQuery.devicePixelRatioOf(context).clamp(1.0, 2.0);
      return await object.toImage(pixelRatio: ratio);
    } catch (error) {
      if (kDebugMode) debugPrint('Captura de tarjetas falló: $error');
      return null;
    }
  }

  /// Vuelo de las tarjetas. restoring=false va de las tarjetas al botón;
  /// restoring=true, del botón a las tarjetas.
  Future<void> _runGenie({required bool restoring}) async {
    if (_busy || !mounted || restoring != _minimized) {
      _genieLog(
        'ignorado busy=$_busy mounted=$mounted '
        'restoring=$restoring minimized=$_minimized',
      );
      return;
    }
    _busy = true;
    _genieLog('inicio restoring=$restoring');
    OverlayEntry? entry;
    VoidCallback? spaceTrigger;
    try {
      final overlay = Overlay.of(context, rootOverlay: true);
      final box = overlay.context.findRenderObject();
      if (box is! RenderBox) {
        throw StateError('No se encontró el RenderBox del Overlay');
      }
      // Se miden ANTES de cerrar o abrir el espacio.
      final tilesRect =
          _rect(_captureKey, box) ?? (restoring ? _originalRect : null);
      Rect? visualFrom = tilesRect;
      final buttonRect = _rect(_saveKey, box) ?? _saveRect(context);
      _genieLog('overlay=${box.size} tiles=$tilesRect boton=$buttonRect');
      if (tilesRect == null) {
        _genieLog('SIN VUELO: no se pudo medir la zona de las tarjetas');
        // No hay dónde dibujar el vuelo: se pasa al estado final, pero el
        // espacio igual se mueve con el resorte (sin salto).
        if (restoring) {
          _flyCtrl.value = 0.0;
          _moveSpace(open: true);
          setState(() => _minimized = false);
        } else {
          _flyCtrl.value = 1.0;
          _moveSpace(open: false);
          _finishMinimize();
        }
        return;
      }
      if (!restoring) {
        // Si el usuario desplazó el scroll, el efecto sigue siendo visible:
        // se inicia desde el borde visible más próximo, sin mover el scroll.
        final viewport = Offset.zero & box.size;
        final isVisible = viewport.overlaps(tilesRect);
        if (!isVisible) {
          final y = tilesRect.bottom <= viewport.top
              ? viewport.top + 6
              : viewport.bottom - math.min(tilesRect.height, 70.0) - 6;
          visualFrom = Rect.fromLTWH(
            tilesRect.left
                .clamp(0.0, math.max(0.0, box.size.width - tilesRect.width))
                .toDouble(),
            y,
            tilesRect.width,
            tilesRect.height,
          );
          _genieLog('tarjetas fuera de vista; animación visible alternativa');
        }
        final image = isVisible ? await _captureTiles() : null;
        if (!mounted) {
          image?.dispose();
          return;
        }
        _genieLog(
          image == null
              ? 'CAPTURA NULA: se usará una superficie de respaldo'
              : 'captura ok ${image.width}x${image.height}',
        );
        _tilesImage?.dispose();
        _tilesImage = image;
        _originalRect = tilesRect;
      }
      if (!mounted) return;
      if (restoring) {
        final viewport = Offset.zero & box.size;
        if (!viewport.overlaps(tilesRect)) {
          final y = tilesRect.bottom < 0
              ? 6.0
              : box.size.height - math.min(tilesRect.height, 70.0) - 6;
          visualFrom = Rect.fromLTWH(
            tilesRect.left
                .clamp(0.0, math.max(0.0, box.size.width - tilesRect.width))
                .toDouble(),
            y,
            tilesRect.width,
            tilesRect.height,
          );
        }
      }
      final painter = _GenieMeshPainter(
        image: _tilesImage,
        from: visualFrom!,
        to: buttonRect,
        animation: _flyCtrl,
      );
      entry = OverlayEntry(
        builder: (_) => Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(child: CustomPaint(painter: painter)),
          ),
        ),
      );
      overlay.insert(entry);
      _activeOverlay = entry;
      _genieLog('capa insertada, animando ${_flyDuration.inMilliseconds} ms');
      // Las tarjetas originales se vuelven invisibles durante el vuelo. El
      // espacio se mueve cuando el vuelo cruza _spaceMoveAt (en ambos
      // sentidos), así queda sincronizado con el vuelo aunque cambie su
      // duración.
      setState(() => _animating = true);
      void moveSpaceWhenCrossed() {
        final crossed = restoring
            ? _flyCtrl.value <= _spaceMoveAt
            : _flyCtrl.value >= _spaceMoveAt;
        if (!crossed) return;
        _flyCtrl.removeListener(moveSpaceWhenCrossed);
        _moveSpace(open: restoring);
      }

      spaceTrigger = moveSpaceWhenCrossed;
      _flyCtrl.addListener(moveSpaceWhenCrossed);
      if (restoring) {
        await _flyCtrl.reverse(from: 1.0).orCancel;
      } else {
        await _flyCtrl.forward(from: 0.0).orCancel;
      }
      _genieLog('vuelo terminado');
      if (!mounted) return;
      // Por si el umbral no llegó a cruzarse (vuelo interrumpido o muy corto).
      _moveSpace(open: restoring);
      if (restoring) {
        setState(() => _minimized = false);
      } else {
        _finishMinimize();
      }
    } on TickerCanceled {
      _genieLog('cancelado (TickerCanceled)');
      // Se cerró la pantalla durante la animación.
    } catch (error) {
      _genieLog('ERROR: $error');
      // Ante un fallo se deja el estado final sin vuelo; el espacio igual
      // se mueve con el resorte.
      if (mounted) {
        if (restoring) {
          _flyCtrl.value = 0.0;
          _moveSpace(open: true);
          setState(() => _minimized = false);
        } else {
          _flyCtrl.value = 1.0;
          _moveSpace(open: false);
          _finishMinimize();
        }
      }
    } finally {
      final trigger = spaceTrigger;
      if (trigger != null) _flyCtrl.removeListener(trigger);
      if (entry != null && _activeOverlay == entry) {
        _activeOverlay = null;
        entry.remove();
        entry.dispose();
      }
      if (mounted) {
        setState(() {
          _busy = false;
          _animating = false;
        });
      }
    }
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
          child: _ArrivalPulse(
            trigger: _arrivals,
            child: _SaveButton(
              key: _saveKey,
              isSpanish: isSpanish,
              busy: _saving,
              onTap: _onSaveTap,
            ),
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
                    // El espacio se cierra con su propio resorte y lo de
                    // abajo sube suavemente.
                    _InfoTiles(
                      captureKey: _captureKey,
                      isSpanish: isSpanish,
                      openFraction: _spaceCtrl,
                      visible: !_animating && !_minimized,
                      onHide: _hideTiles,
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

/// Franja superior que ocupan Perfil, Descargar información e Información
/// (14 de margen + botón de 50 + 8 de aire). Cuando el encabezado se pliega,
/// queda este alto libre para que EXPLORAR no pase por debajo de los botones.
const double _topButtonsBand = 14 + 50 + 8;

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
      // Plegado no llega a 0: deja libre la franja de los botones superiores.
      height: collapsed ? top + _topButtonsBand : expandedHeight,
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
    required this.openFraction,
    required this.visible,
    required this.onHide,
  });

  /// Guarda las tarjetas en el botón superior (efecto genie).
  final VoidCallback onHide;

  /// Zona que se captura para el efecto de vuelo.
  final GlobalKey captureKey;
  final bool isSpanish;

  /// Parte del espacio que sigue abierta (1 = completo, 0 = cerrado).
  /// Se anima en la capa de render: no reconstruye las tarjetas por fotograma.
  final Animation<double> openFraction;

  /// Durante el vuelo y cuando están guardadas en el botón no se ven.
  final bool visible;
  @override
  Widget build(BuildContext context) {
    const fullHeight = _infoTileHeight + _tilesBottomGap;
    // SizeTransition recorta y reduce el alto anclado arriba; las tarjetas
    // conservan su tamaño completo, así la captura y el vuelo parten siempre
    // de la misma forma y el contenido de abajo sube de manera continua.
    return SizeTransition(
      sizeFactor: openFraction,
      alignment: Alignment.topCenter,
      child: SizedBox(
        height: fullHeight,
        child: IgnorePointer(
          ignoring: !visible,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: BcSpace.gutter),
            child: Opacity(
              opacity: visible ? 1.0 : 0.0,
              child: SizedBox(
                height: _infoTileHeight,
                // El botón de ocultar queda fuera de la captura: no
                // aparece deformado dentro del vuelo.
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _tilesRow(context),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: _HideTilesButton(
                        isSpanish: isSpanish,
                        onTap: onHide,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Las dos tarjetas, dentro de la zona que se captura para el vuelo.
  Widget _tilesRow(BuildContext context) {
    return RepaintBoundary(
      key: captureKey,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: BcWideInfoTile(
              dark: true,
              icon: Icons.health_and_safety_rounded,
              title: isSpanish ? 'Antes de tu viaje' : 'Before your trip',
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

/// Pequeño rebote del botón cuando las tarjetas terminan de entrar en él.
class _ArrivalPulse extends StatefulWidget {
  const _ArrivalPulse({required this.trigger, required this.child});

  /// Cada vez que cambia, el botón rebota.
  final int trigger;
  final Widget child;

  @override
  State<_ArrivalPulse> createState() => _ArrivalPulseState();
}

class _ArrivalPulseState extends State<_ArrivalPulse>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 420);

  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: _duration,
  );

  /// Se infla al recibir las tarjetas y vuelve a su tamaño.
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 0.85,
        end: 1.18,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 40,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.18,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.elasticOut)),
      weight: 60,
    ),
  ]).animate(_ctrl);

  @override
  void initState() {
    super.initState();
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(_ArrivalPulse old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger) _ctrl.forward(from: 0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ScaleTransition(scale: _scale, child: widget.child);
}

/// Botón pequeño sobre las tarjetas para volver a guardarlas en el botón.
class _HideTilesButton extends StatelessWidget {
  const _HideTilesButton({required this.isSpanish, required this.onTap});
  final bool isSpanish;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: isSpanish ? 'Ocultar tarjetas' : 'Hide cards',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        // Zona táctil de 40 px aunque el círculo visible sea pequeño.
        child: SizedBox(
          width: 40,
          height: 40,
          child: Align(
            alignment: Alignment.topRight,
            child: Container(
              width: 24,
              height: 24,
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: BcColors.surface.withValues(alpha: 0.92),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.keyboard_arrow_up_rounded,
                size: 18,
                color: BcColors.ink,
              ),
            ),
          ),
        ),
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
    // Mismo gris del fondo: EXPLORAR se integra a la pantalla, sin tarjeta.
    return ColoredBox(
      color: BcColors.fog,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
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
                    TextSpan(
                      text: isSpanish ? 'CIUDAD DE ' : 'COYHAIQUE ',
                      style: BcText.label(
                        color: isSpanish ? BcColors.ink : BcColors.glacierDeep,
                      ),
                    ),
                    TextSpan(
                      text: isSpanish ? 'COYHAIQUE' : 'CITY',
                      style: BcText.label(
                        color: isSpanish ? BcColors.glacierDeep : BcColors.ink,
                      ),
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

/// Efecto genie sobre una malla con la imagen de las tarjetas, en dos fases
/// que se solapan:
///  1. Curvatura: los lados se doblan en un embudo en S hacia el botón; el
///     borde lejano conserva su ancho y el cercano se estrecha.
///  2. Succión: el contenido recorre el embudo, acelerando, y se comprime
///     dentro del botón, donde se desvanece.
/// Al restaurar, el controlador corre al revés y las tarjetas «brotan» del
/// botón. Si la captura falla, dibuja una superficie de respaldo para que el
/// botón nunca parezca no responder.
class _GenieMeshPainter extends CustomPainter {
  _GenieMeshPainter({
    required this.image,
    required this.from,
    required this.to,
    required Animation<double> animation,
  }) : _animation = animation,
       super(repaint: animation);
  final ui.Image? image;
  final Rect from;
  final Rect to;
  final Animation<double> _animation;

  /// Filas de la malla: más filas = curva del embudo más suave.
  static const int _meshRows = 120;

  /// Fase 1 (curvatura): los lados se doblan hacia el botón.
  static const double _curveEnd = 0.42;

  /// Fase 2 (succión): el contenido recorre el embudo. Se solapa con la 1.
  static const double _slideStart = 0.18;

  /// Al final la imagen se desvanece dentro del botón.
  static const double _fadeStart = 0.9;

  /// Largo mínimo del tramo entre botón y tarjetas (evita embudos planos).
  static const double _minGap = 40;

  /// La imagen termina algo más pequeña que el botón: parece entrar en él.
  late final Rect _target = to.deflate(math.min(to.width, to.height) * 0.2);

  late final Float32List _uv = _makeUv();
  late final Uint16List _indices = _makeIndices();
  late final Paint _paint = _createPaint();
  Paint _createPaint() {
    final paint = Paint()
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.medium;
    final img = image;
    if (img != null) {
      paint.shader = ui.ImageShader(
        img,
        ui.TileMode.clamp,
        ui.TileMode.clamp,
        Matrix4.identity().storage,
        filterQuality: FilterQuality.medium,
      );
    } else {
      paint.color = BcColors.ink;
    }
    return paint;
  }

  /// Coordenadas de textura: dos vértices (izquierda, derecha) por fila.
  Float32List _makeUv() {
    final w = image?.width.toDouble() ?? 1.0;
    final h = image?.height.toDouble() ?? 1.0;
    final values = Float32List((_meshRows + 1) * 4);
    for (var i = 0; i <= _meshRows; i++) {
      final v = i / _meshRows * h;
      values
        ..[i * 4] = 0
        ..[i * 4 + 1] = v
        ..[i * 4 + 2] = w
        ..[i * 4 + 3] = v;
    }
    return values;
  }

  /// Dos triángulos por fila, compartiendo vértices con la fila siguiente.
  Uint16List _makeIndices() {
    final values = Uint16List(_meshRows * 6);
    for (var i = 0; i < _meshRows; i++) {
      final tl = i * 2;
      final tr = tl + 1;
      final bl = tl + 2;
      final br = tl + 3;
      values.setAll(i * 6, [tl, tr, bl, tr, br, bl]);
    }
    return values;
  }

  /// Progreso de una fase dentro de [start, end] del tiempo total.
  static double _phase(double t, double start, double end, Curve curve) =>
      curve.transform(((t - start) / (end - start)).clamp(0.0, 1.0));

  @override
  void paint(Canvas canvas, Size size) {
    final t = _animation.value;
    if (t <= 0) return;

    // El embudo se recorre como una distancia d medida desde el borde del
    // botón más lejano a las tarjetas:
    //   [0, d1]   dentro del botón
    //   [d1, d2]  tramo libre entre botón y tarjetas
    //   [d2, d3]  zona original de las tarjetas
    final gap = math.max((from.top - _target.bottom).abs(), _minGap);
    final d1 = _target.height;
    final d2 = d1 + gap;
    final d3 = d2 + from.height;

    final curve = _phase(t, 0, _curveEnd, Curves.easeInOutCubic);
    final slide = _phase(t, _slideStart, 1, Curves.easeInCubic);

    // Altura en pantalla de cada punto del embudo.
    double yAt(double d) {
      if (d <= d1) return _target.top + d;
      if (d <= d2) {
        return ui.lerpDouble(_target.bottom, from.top, (d - d1) / gap)!;
      }
      return from.top + (d - d2);
    }

    // Lados del embudo: curva en S desde el botón hasta el borde lejano de
    // las tarjetas, que conserva su ancho. curve=0 deja los lados rectos.
    (double, double) edgesAt(double d) {
      final x = ((d - d1) / (d3 - d1)).clamp(0.0, 1.0);
      final open = Curves.easeInOutCubic.transform(x);
      final left = ui.lerpDouble(_target.left, from.left, open)!;
      final right = ui.lerpDouble(_target.right, from.right, open)!;
      return (
        ui.lerpDouble(from.left, left, curve)!,
        ui.lerpDouble(from.right, right, curve)!,
      );
    }

    // El contenido se desliza por el embudo y se comprime en el botón.
    final top = ui.lerpDouble(d2, 0, slide)!;
    final bottom = ui.lerpDouble(d3, d1, slide)!;
    final positions = Float32List((_meshRows + 1) * 4);
    for (var i = 0; i <= _meshRows; i++) {
      final d = ui.lerpDouble(top, bottom, i / _meshRows)!;
      final y = yAt(d);
      final (left, right) = edgesAt(d);
      positions
        ..[i * 4] = left
        ..[i * 4 + 1] = y
        ..[i * 4 + 2] = right
        ..[i * 4 + 3] = y;
    }

    final vertices = ui.Vertices.raw(
      ui.VertexMode.triangles,
      positions,
      textureCoordinates: _uv,
      indices: _indices,
    );
    final opacity = 1 - _phase(t, _fadeStart, 1, Curves.easeIn);
    if (opacity < 1) {
      canvas.saveLayer(
        from.expandToInclude(to).inflate(4),
        Paint()..color = Color.fromRGBO(0, 0, 0, opacity),
      );
    }
    canvas.drawVertices(vertices, ui.BlendMode.srcOver, _paint);
    if (opacity < 1) canvas.restore();
    vertices.dispose();
  }

  @override
  bool shouldRepaint(covariant _GenieMeshPainter old) =>
      old.image != image ||
      old.from != from ||
      old.to != to ||
      old._animation != _animation;
}
