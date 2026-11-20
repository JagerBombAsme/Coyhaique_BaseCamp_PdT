import 'dart:async';
import 'dart:typed_data';

import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../../../core/local/catalog_status_provider.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/basecamp_tokens.dart';
import '../../../categories/data/models/place_dto.dart';
import '../../../categories/data/providers/places_provider.dart';
import '../../../trip_info/presentation/widgets/trip_notice.dart';
import '../../domain/route_step.dart';
import '../../domain/route_tracking.dart';
import '../map_places.dart';
import '../widgets/destination_pin.dart';
import '../widgets/map_place_preview_card.dart';
import '../widgets/map_route_panel.dart';
import '../widgets/route_maneuver.dart';
import 'mapbox_directions_services.dart';

// ===============================================================
// ESTILOS DE MAPA
// ===============================================================

enum MapStyleOption {
  outdoors('Terreno', 'Terrain', Icons.terrain, MapboxStyles.OUTDOORS),
  satellite(
    'Satélite',
    'Satellite',
    Icons.satellite_alt,
    MapboxStyles.SATELLITE_STREETS,
  ),
  streets('Calles', 'Streets', Icons.map_outlined, MapboxStyles.MAPBOX_STREETS);

  const MapStyleOption(this.labelEs, this.labelEn, this.icon, this.uri);

  final String labelEs;
  final String labelEn;
  final IconData icon;
  final String uri;

  String label({required bool isSpanish}) => isSpanish ? labelEs : labelEn;
}

/// Estado del permiso de ubicación. El mapa se muestra siempre; sin permiso
/// solo aparece un aviso (M-07).
enum _LocationGate { checking, granted, serviceOff, denied, deniedForever }

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({
    super.key,
    this.routeFromAirport = false,
    this.routePlaceId,
    this.routeMode,
    this.onOpenPlace,
  });

  /// Abre el mapa con la ruta Aeropuerto Balmaceda → Plaza de Armas
  /// (pantalla «¿Desde dónde partes?», viaje en transporte propio).
  final bool routeFromAirport;

  /// Lugar (id de places_v2) que se muestra al abrir el mapa, por ejemplo
  /// desde el itinerario. Con [routeMode] también se traza la ruta hasta él
  /// desde la ubicación del usuario, igual que los botones de su tarjeta.
  final String? routePlaceId;
  final MapRouteMode? routeMode;

  /// Abre la ficha del lugar (botón «Ver ficha»). Lo conecta el router.
  /// Solo se ofrece para lugares que vienen de places_v2 (tienen id).
  final void Function(MapPlace place)? onOpenPlace;

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen>
    with WidgetsBindingObserver {
  // ===============================================================
  // CONFIGURACIÓN
  // Los puntos fijos viven en map_places.dart. Los lugares del catálogo
  // llegan de places_v2 y reemplazan a la lista fija cuando se cargan.
  // ===============================================================

  static const MapPlace _center = MapPlaces.center;
  static const MapPlace _plaza = MapPlaces.plaza;

  static const double _initialZoom = 12.5;

  /// Idioma activo de la app (Riverpod). Sin tocar el estado aquí.
  bool get _isSpanish => ref.read(languageProvider).languageCode == 'es';

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  /// Lugares del mapa. Parte con la lista fija y, cuando llegan los datos de
  /// places_v2, se reemplaza por la Plaza de Armas más los lugares activos.
  /// Si la carga falla o viene vacía, se conserva la lista fija.
  List<MapPlace> _places = MapPlaces.all;

  MapboxMap? _mapboxMap;
  CircleAnnotationManager? _markerManager;

  /// Pin del destino (modo ruta) y su imagen, que se dibuja una sola vez.
  PointAnnotationManager? _pinManager;
  Uint8List? _pinImage;
  final Map<String, MapPlace> _placeByAnnotationId = {};

  /// Evita dos redibujos de marcadores a la vez (estilo y datos pueden
  /// coincidir) y que queden administradores de marcadores sin quitar.
  bool _redrawingMarkers = false;
  bool _redrawAgain = false;

  MapPlace _selectedPlace = _center;

  /// Lugar de la tarjeta flotante (marcador tocado o resultado del
  /// buscador). Null = sin tarjeta.
  MapPlace? _previewPlace;

  /// Medio cuya ruta se está pidiendo desde la tarjeta (obtener la ubicación
  /// puede tardar hasta 10 s).
  MapRouteMode? _routeMode;

  /// Medio de la ruta dibujada (a pie o en auto).
  String _routeProfile = RouteProfile.walking;
  MapStyleOption _style = MapStyleOption.outdoors;

  // Ruta activa (si hay una dibujada en el mapa).
  PolylineAnnotationManager? _routeManager;
  RouteResult? _route;
  MapPlace? _routeFrom;
  MapPlace? _routeTo;

  /// La ruta parte de la ubicación del usuario (se puede recalcular).
  bool _routeFromUser = false;

  /// Posición en vivo mientras hay una ruta (solo mueve el punto, no recalcula).
  StreamSubscription<geolocator.Position>? _trackSub;

  /// Evita repetir el aviso de «te alejaste» mientras sigue fuera de la ruta.
  bool _offRoute = false;

  /// Punto de la ruta donde está el usuario. Lo que queda atrás se borra.
  int _trimIndex = 0;

  /// El usuario llegó al destino (a menos de [arrivalMeters]).
  bool _arrived = false;

  /// La cámara sigue al usuario con el mapa girado según su rumbo (modo
  /// navegación). Se apaga al mover el mapa con el dedo.
  bool _followUser = false;
  Timer? _followTimer;

  /// Evita dos redibujos de la línea a la vez.
  bool _trimBusy = false;
  bool _loadingRoute = false;

  /// Ruta desde el aeropuerto pedida antes de que el mapa terminara de cargar.
  late bool _pendingAirportRoute = widget.routeFromAirport;

  /// Lugar pedido desde fuera del mapa (itinerario) que aún no se pudo
  /// mostrar porque faltaba el estilo del mapa o la carga de lugares.
  late String? _pendingPlaceId = widget.routePlaceId;
  late MapRouteMode? _pendingPlaceMode = widget.routeMode;

  /// Estado de la ubicación. El mapa se muestra siempre: sin permiso solo se
  /// muestra un aviso con la acción para activarla (M-07).
  _LocationGate _gate = _LocationGate.checking;

  /// El usuario cerró el aviso de ubicación en esta visita al mapa.
  bool _locationNoticeDismissed = false;

  /// Conexión a internet. Sin conexión el mapa muestra su propio aviso fijo
  /// y las rutas avisan antes de calcularse (FIX-001, FIX-002).
  bool _online = true;

  /// Fecha de la última descarga del catálogo, para el aviso sin conexión.
  DateTime? _lastSync;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  /// El estilo del mapa terminó de cargar. Se reinicia al cambiar de estilo.
  bool _styleLoaded = false;

  /// El estilo no cargó teniendo conexión: Mapbox no disponible (FIX-010).
  bool _mapLoadFailed = false;

  /// Lugares filtrados según el texto del buscador.
  List<MapPlace> get _filteredPlaces {
    return _places.where((p) => p.matches(_searchController.text)).toList();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // El mapa no exige la ubicación: solo se revisa el estado, sin pedir el
    // permiso. Se pide al usar "Mi ubicación", A pie o En auto (M-07).
    unawaited(_checkLocation(requestIfNeeded: false));

    // Conexión: estado inicial y cambios mientras el mapa está abierto.
    _connectivitySub = Connectivity().onConnectivityChanged.listen(
      _onConnectivityChanged,
    );
    unawaited(Connectivity().checkConnectivity().then(_onConnectivityChanged));

    // Carga los lugares de places_v2 y los dibuja cuando llegan.
    ref.listenManual<AsyncValue<List<PlaceDto>>>(placesProvider, (_, next) {
      next.when(
        data: _applyLoadedPlaces,
        loading: () {},
        error: (_, _) {
          // El mensaje se difiere: aquí todavía no se puede usar el context.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showMessage(
              _isSpanish
                  ? 'No se pudieron cargar los lugares'
                  : 'The places could not be loaded',
            );
          });
        },
      );
    }, fireImmediately: true);
  }

  /// Reemplaza la lista fija por los lugares de places_v2 y redibuja.
  void _applyLoadedPlaces(List<PlaceDto> dtos) {
    final loaded = _toMapPlaces(dtos);
    // Sin lugares válidos se conserva la lista fija (el mapa no queda vacío).
    if (loaded.isEmpty || !mounted) return;

    final all = <MapPlace>[_plaza, ...loaded];

    // El aeropuerto es el origen de la ruta «desde el aeropuerto»: si la base
    // de datos no lo trae, se agrega el punto fijo.
    final hasAirport = loaded.any((p) => p.nameEs == MapPlaces.airport.nameEs);
    if (!hasAirport) all.add(MapPlaces.airport);

    setState(() => _places = all);
    _redrawMarkers();
    unawaited(_openRequestedPlace());
  }

  /// Muestra el lugar pedido desde el itinerario y, si se indicó, traza la
  /// ruta a pie o en auto. Espera a que el estilo y los lugares estén
  /// cargados; se reintenta cuando llegan.
  Future<void> _openRequestedPlace() async {
    final id = _pendingPlaceId;
    if (id == null || !_styleLoaded || !mounted) return;

    MapPlace? place;
    for (final candidate in _places) {
      if (candidate.id == id) place = candidate;
    }
    if (place == null) return;

    final mode = _pendingPlaceMode;
    _pendingPlaceId = null;
    _pendingPlaceMode = null;
    await _goToPlace(place);
    if (mode != null && mounted) await _routeToPlace(place, mode);
  }

  /// Convierte los lugares de places_v2 en puntos del mapa. Solo incluye
  /// lugares activos con coordenadas válidas. El inglés usa el español como
  /// respaldo cuando la ficha no tiene traducción.
  List<MapPlace> _toMapPlaces(List<PlaceDto> dtos) {
    final result = <MapPlace>[];
    for (final dto in dtos) {
      final lat = dto.latitude;
      final lng = dto.longitude;
      if (!dto.isActive || lat == null || lng == null) continue;
      if (lat == 0 && lng == 0) continue;
      if (dto.titleEs.trim().isEmpty || dto.titleEs == _plaza.nameEs) continue;

      final descriptionEs = dto.getDescription(true).isNotEmpty
          ? dto.getDescription(true)
          : (dto.subtitleEs ?? '');
      final descriptionEn = dto.getDescription(false).isNotEmpty
          ? dto.getDescription(false)
          : descriptionEs;

      // Fotografías reales del catálogo, sin repetir; si el lugar no tiene
      // galería se usa su foto principal.
      final photos = <String>[
        for (final media in dto.media)
          if ((media.externalUrl ?? '').isNotEmpty) media.externalUrl!,
      ];
      final mainPhoto = dto.imageUrl ?? '';
      if (photos.isEmpty && mainPhoto.isNotEmpty) photos.add(mainPhoto);

      result.add(
        MapPlace(
          id: dto.id,
          nameEs: dto.getTitle(true),
          nameEn: dto.getTitle(false),
          descriptionEs: descriptionEs,
          descriptionEn: descriptionEn,
          icon: dto.category?.icon ?? Icons.place_outlined,
          longitude: lng,
          latitude: lat,
          categoryEs: dto.category?.getNombre('es') ?? '',
          categoryEn: dto.category?.getNombre('en') ?? '',
          address: dto.address ?? dto.meetingPoint,
          photoUrls: photos.toSet().toList(),
        ),
      );
    }
    return result;
  }

  /// Actualiza el estado de conexión y la fecha de la última descarga.
  /// Al volver la conexión se reintenta un mapa que no había cargado.
  Future<void> _onConnectivityChanged(List<ConnectivityResult> results) async {
    final online = results.any((r) => r != ConnectivityResult.none);
    DateTime? lastSync;
    if (!online) {
      try {
        lastSync = await ref.read(catalogLocalDbProvider).getLastSyncAt();
      } catch (_) {
        lastSync = null;
      }
    }
    if (!mounted) return;
    setState(() {
      _online = online;
      _lastSync = lastSync;
    });
    if (online && _mapLoadFailed) await _retryMapLoad();
  }

  /// Al volver de los ajustes del teléfono se revisa de nuevo el permiso.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_checkLocation(requestIfNeeded: false));
    }
  }

  /// Revisa GPS y permiso y actualiza [_gate].
  Future<void> _checkLocation({required bool requestIfNeeded}) async {
    var next = _LocationGate.denied;
    try {
      if (!await geolocator.Geolocator.isLocationServiceEnabled()) {
        next = _LocationGate.serviceOff;
      } else {
        var permission = await geolocator.Geolocator.checkPermission();
        if (permission == geolocator.LocationPermission.denied &&
            requestIfNeeded) {
          permission = await geolocator.Geolocator.requestPermission();
        }
        next = switch (permission) {
          geolocator.LocationPermission.whileInUse ||
          geolocator.LocationPermission.always => _LocationGate.granted,
          geolocator.LocationPermission.deniedForever =>
            _LocationGate.deniedForever,
          _ => _LocationGate.denied,
        };
      }
    } catch (_) {
      next = _LocationGate.denied;
    }
    if (!mounted) return;
    setState(() => _gate = next);
  }

  @override
  void didUpdateWidget(covariant MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // La pestaña del mapa se conserva: si llega una nueva petición de ruta,
    // se dibuja de inmediato o al terminar de cargar el estilo.
    if (widget.routeFromAirport && !oldWidget.routeFromAirport) {
      if (_markerManager != null) {
        _showAirportRoute();
      } else {
        _pendingAirportRoute = true;
      }
    }

    // Nuevo lugar pedido desde el itinerario (la pestaña se conserva).
    final placeId = widget.routePlaceId;
    if (placeId != null &&
        (placeId != oldWidget.routePlaceId ||
            widget.routeMode != oldWidget.routeMode)) {
      _pendingPlaceId = placeId;
      _pendingPlaceMode = widget.routeMode;
      unawaited(_openRequestedPlace());
    }
  }

  /// Ruta Aeropuerto Balmaceda → Plaza de Armas de Coyhaique.
  /// Es para transporte propio (50 km): se calcula en auto, no a pie.
  Future<void> _showAirportRoute() async {
    await _showRoute(
      from: MapPlaces.airport,
      to: _plaza,
      profile: RouteProfile.driving,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _trackSub?.cancel();
    _followTimer?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // ===============================================================
  // LÓGICA DEL MAPA
  // ===============================================================

  void _onMapCreated(MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;

    // Brújula debajo del buscador y de los chips (no tapada por ellos).
    final topInset = MediaQuery.paddingOf(context).top;
    mapboxMap.compass.updateSettings(
      CompassSettings(
        position: OrnamentPosition.TOP_RIGHT,
        marginTop: topInset + 130,
        marginRight: 16,
      ),
    );

    // La barra de escala chocaría con la tarjeta inferior.
    mapboxMap.scaleBar.updateSettings(ScaleBarSettings(enabled: false));
  }

  /// Se ejecuta al cargar el mapa y cada vez que cambia el estilo,
  /// así los marcadores siempre se redibujan.
  Future<void> _onStyleLoaded(StyleLoadedEventData _) async {
    final map = _mapboxMap;
    if (map == null || !mounted) return;

    setState(() {
      _styleLoaded = true;
      _mapLoadFailed = false;
    });

    await _applyMapLanguage(ref.read(languageProvider).languageCode);

    await _redrawMarkers();

    // Si había una ruta activa, se vuelve a dibujar con el nuevo estilo.
    final route = _route;
    if (route != null) {
      await _drawRouteLine(route);
    }

    if (_pendingAirportRoute) {
      _pendingAirportRoute = false;
      await _showAirportRoute();
    }

    await _openRequestedPlace();
  }

  /// Error al cargar el mapa. Solo cuenta si el estilo aún no cargó (una
  /// tesela suelta que falla no impide usar el mapa) y si hay conexión: sin
  /// conexión ya se muestra el aviso propio del mapa.
  void _onMapLoadError(MapLoadingErrorEventData _) {
    if (!mounted || _styleLoaded || !_online) return;
    setState(() => _mapLoadFailed = true);
  }

  /// Vuelve a pedir el estilo del mapa (botón «Reintentar»).
  Future<void> _retryMapLoad() async {
    if (!mounted) return;
    setState(() {
      _mapLoadFailed = false;
      _styleLoaded = false;
    });
    await _mapboxMap?.loadStyleURI(_style.uri);
  }

  /// Dibuja un marcador por lugar. Se llama al cargar el mapa, al cambiar el
  /// estilo y al llegar los datos de places_v2. Si se pide mientras ya hay un
  /// redibujo en curso, se repite al terminar (siempre con la lista vigente).
  Future<void> _redrawMarkers() async {
    if (_redrawingMarkers) {
      _redrawAgain = true;
      return;
    }
    _redrawingMarkers = true;
    try {
      do {
        _redrawAgain = false;
        await _drawMarkersOnce();
      } while (_redrawAgain && mounted);
    } finally {
      _redrawingMarkers = false;
    }
  }

  Future<void> _drawMarkersOnce() async {
    final map = _mapboxMap;
    if (map == null || !mounted) return;

    final oldManager = _markerManager;
    if (oldManager != null) {
      await map.annotations.removeAnnotationManager(oldManager);
      _markerManager = null;
    }
    _placeByAnnotationId.clear();

    final oldPin = _pinManager;
    if (oldPin != null) {
      await map.annotations.removeAnnotationManager(oldPin);
      _pinManager = null;
    }

    // Modo ruta: solo el pin del destino, con forma propia para que no se
    // confunda con el punto azul de la ubicación del usuario.
    final target = _routeTo;
    if (target != null) {
      try {
        final pins = await map.annotations.createPointAnnotationManager();
        _pinManager = pins;
        final image = _pinImage ??= await buildDestinationPinPng();
        await pins.create(
          PointAnnotationOptions(
            geometry: Point(
              coordinates: Position(target.longitude, target.latitude),
            ),
            image: image,
            iconAnchor: IconAnchor.BOTTOM,
            iconSize: 1.0,
          ),
        );
        return;
      } catch (e) {
        // Sin pin se dibuja el círculo grande de respaldo (abajo).
        debugPrint('ERROR PIN DESTINO: $e');
      }
    }

    final manager = await map.annotations.createCircleAnnotationManager();
    _markerManager = manager;

    // Con una ruta activa solo se ve el destino (modo ruta).
    final destination = _routeTo;
    final visible = destination != null
        ? [destination]
        : _places.where((p) => p.verified).toList();

    for (final place in visible) {
      final isDestination = destination != null;
      final annotation = await manager.create(
        CircleAnnotationOptions(
          geometry: Point(
            coordinates: Position(place.longitude, place.latitude),
          ),
          circleRadius: isDestination ? 13 : 9,
          circleColor: (isDestination ? BcColors.glacierDeep : AppTheme.primaryDark)
              .toARGB32(),
          circleStrokeColor: Colors.white.toARGB32(),
          circleStrokeWidth: isDestination ? 4 : 3,
        ),
      );
      _placeByAnnotationId[annotation.id] = place;
    }

    // Tocar un marcador = ir a ese lugar y mostrar su tarjeta, que ofrece
    // «Ver ficha» cuando el lugar viene de places_v2.
    manager.tapEvents(
      onTap: (annotation) {
        // En modo ruta los marcadores no abren otras fichas.
        if (_route != null) return;
        final place = _placeByAnnotationId[annotation.id];
        if (place != null) _goToPlace(place);
      },
    );
  }

  /// Traduce las etiquetas del propio mapa (calles, ciudades, países). Un
  /// fallo aquí no debe impedir usar el mapa.
  Future<void> _applyMapLanguage(String languageCode) async {
    try {
      await _mapboxMap?.style.localizeLabels(languageCode, null);
    } catch (e) {
      debugPrint('ERROR IDIOMA DEL MAPA: $e');
    }
  }

  /// Único punto de entrada para mover la cámara y actualizar el estado.
  /// Con [showPreview] (por defecto) abre la tarjeta del lugar; el botón de
  /// centrar el mapa la cierra.
  Future<void> _goToPlace(MapPlace place, {bool showPreview = true}) async {
    _searchFocus.unfocus();
    setState(() {
      _selectedPlace = place;
      _previewPlace = showPreview ? place : null;
    });

    final map = _mapboxMap;
    if (map == null) return;

    await map.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(place.longitude, place.latitude)),
        zoom: place.zoom,
      ),
      MapAnimationOptions(duration: 1000),
    );
  }

  Future<void> _zoomBy(double delta) async {
    final map = _mapboxMap;
    if (map == null) return;

    final camera = await map.getCameraState();
    await map.easeTo(
      CameraOptions(zoom: camera.zoom + delta),
      MapAnimationOptions(duration: 250),
    );
  }

  Future<void> _changeStyle(MapStyleOption option) async {
    if (option == _style) return;
    setState(() {
      _style = option;
      _styleLoaded = false;
    });
    await _mapboxMap?.loadStyleURI(option.uri);
  }

  // ===============================================================
  // RUTAS (Mapbox Directions API)
  // ===============================================================

  /// Calcula y dibuja la ruta [from] -> [to].
  Future<void> _showRoute({
    required MapPlace from,
    required MapPlace to,
    String profile = RouteProfile.walking,
    bool fromUser = false,
  }) async {
    final map = _mapboxMap;
    if (map == null || _loadingRoute) return;
    if (_blockRouteIfOffline()) return;

    setState(() => _loadingRoute = true);

    try {
      // Mismo token con el que se inicializó el mapa.
      final token = await MapboxOptions.getAccessToken();
      final service = MapboxDirectionsService(accessToken: token);

      final RouteResult? route;
      try {
        route = await service.getRoute(
          fromLongitude: from.longitude,
          fromLatitude: from.latitude,
          toLongitude: to.longitude,
          toLatitude: to.latitude,
          profile: profile,
        );
      } finally {
        service.dispose();
      }

      if (route == null) {
        // Mapbox respondió, pero no hay ruta entre los puntos: es la distancia.
        _showMessage(
          _isSpanish
              ? 'No se encontró una ruta por la distancia entre estos puntos.'
              : 'No route was found because of the distance between these points.',
        );
        return;
      }

      await _drawRouteLine(route);

      // Encuadra la ruta completa en pantalla.
      await _frameRoute(route: route, duration: 1200);

      if (!mounted) return;
      _searchFocus.unfocus();
      // Solo la ruta que parte del usuario lo sigue: una ruta de referencia
      // (aeropuerto → plaza) no debe recortarse ni avisar que se alejó.
      if (fromUser) {
        _startTracking();
      } else {
        _stopTracking();
      }
      setState(() {
        _route = route;
        _routeFrom = from;
        _routeTo = to;
        _routeProfile = profile;
        _routeFromUser = fromUser;
        _previewPlace = null;
        _followUser = false;
      });
      // Modo ruta: solo queda el marcador del destino.
      unawaited(_redrawMarkers());

      // Se muestra la ruta completa un momento y luego la cámara pasa a
      // seguir al usuario (solo si la ruta parte de su ubicación).
      _followTimer?.cancel();
      if (fromUser) {
        _followTimer = Timer(const Duration(milliseconds: 2800), () {
          if (mounted && _route != null) unawaited(_startFollowing());
        });
      }

      // Aviso de uso seguro cada vez que se genera una ruta (RNF-14).
      TripNotice.show(
        context,
        kind: profile == RouteProfile.walking
            ? TripNoticeKind.walk
            : TripNoticeKind.route,
      );
    } catch (e) {
      debugPrint('ERROR RUTA: $e');
      // Fallo de la app o de la conexión con el servicio, no de la distancia.
      _showMessage(
        _isSpanish
            ? 'No se pudo calcular la ruta por un fallo de la aplicación. Inténtalo de nuevo.'
            : 'The route could not be calculated due to an app error. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _loadingRoute = false);
    }
  }

  /// Calcula la ruta desde la ubicación actual del usuario hasta [place] con
  /// el medio elegido en la tarjeta (a pie o en auto). Sin conexión avisa; sin
  /// ubicación no traza nada.
  Future<void> _routeToPlace(MapPlace place, MapRouteMode mode) async {
    if (_routeMode != null || _blockRouteIfOffline()) return;

    setState(() => _routeMode = mode);
    try {
      final origin = await _currentUserOrigin();
      if (origin == null || !mounted) return;
      await _showRoute(
        from: origin,
        to: place,
        fromUser: true,
        profile: mode == MapRouteMode.walking
            ? RouteProfile.walking
            : RouteProfile.driving,
      );
    } finally {
      if (mounted) setState(() => _routeMode = null);
    }
  }

  /// Ubicación actual del usuario como origen de la ruta. Devuelve null si
  /// falta GPS o permiso, o si no se pudo obtener a tiempo: en ese caso no
  /// se traza ninguna ruta (no se usa la Plaza como respaldo).
  Future<MapPlace?> _currentUserOrigin() async {
    if (!await geolocator.Geolocator.isLocationServiceEnabled()) {
      _showMessage(
        _isSpanish ? 'Activa el GPS de tu teléfono' : 'Turn on your phone GPS',
      );
      return null;
    }

    var permission = await geolocator.Geolocator.checkPermission();
    if (permission == geolocator.LocationPermission.denied) {
      permission = await geolocator.Geolocator.requestPermission();
    }
    unawaited(_checkLocation(requestIfNeeded: false));
    if (permission == geolocator.LocationPermission.denied ||
        permission == geolocator.LocationPermission.deniedForever) {
      _showMessage(
        _isSpanish
            ? 'Se necesita permiso de ubicación'
            : 'Location permission is required',
      );
      return null;
    }

    try {
      final position = await geolocator.Geolocator.getCurrentPosition(
        locationSettings: const geolocator.LocationSettings(
          accuracy: geolocator.LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      if (!mounted) return null;
      return MapPlace(
        nameEs: 'Tu ubicación',
        nameEn: 'Your location',
        descriptionEs: 'Punto de partida desde tu posición actual.',
        descriptionEn: 'Starting point from your current position.',
        icon: Icons.my_location,
        longitude: position.longitude,
        latitude: position.latitude,
      );
    } catch (e) {
      debugPrint('ERROR UBICACIÓN: $e');
      if (mounted) {
        _showMessage(
          _isSpanish
              ? 'No se pudo obtener tu ubicación'
              : 'Your location could not be determined',
        );
      }
      return null;
    }
  }

  /// Sin conexión las rutas no se calculan (las calcula Mapbox en línea):
  /// se avisa de inmediato, sin esperar ni mostrar un error (FIX-001).
  bool _blockRouteIfOffline() {
    if (_online) return false;
    _showMessage(
      _isSpanish
          ? 'Las rutas necesitan conexión a internet. Mientras tanto, puedes ver dónde está el lugar en el mapa.'
          : 'Routes need an internet connection. Meanwhile, you can see where the place is on the map.',
    );
    return true;
  }

  /// Dibuja la línea de la ruta en el mapa.
  Future<void> _drawRouteLine(RouteResult route) async {
    final map = _mapboxMap;
    if (map == null) return;

    final old = _routeManager;
    if (old != null) {
      await map.annotations.removeAnnotationManager(old);
      _routeManager = null;
    }

    final manager = await map.annotations.createPolylineAnnotationManager();
    _routeManager = manager;

    await manager.create(
      PolylineAnnotationOptions(
        geometry: LineString(
          coordinates: route.coordinates
              .map((c) => Position(c[0], c[1]))
              .toList(),
        ),
        lineColor: AppTheme.primaryDark.toARGB32(),
        lineWidth: 5,
      ),
    );
  }

  /// Apaga el seguimiento de la cámara (sin redibujar: lo hace quien llama).
  void _stopFollowing() {
    _followTimer?.cancel();
    _followTimer = null;
    _followUser = false;
  }

  /// El usuario movió el mapa con el dedo: se deja de seguirlo.
  void _onUserMovedMap() {
    if (!_followUser || !mounted) return;
    setState(() => _followUser = false);
  }

  /// Activa la cámara de navegación: centrada en el usuario, inclinada y
  /// girada hacia donde avanza. Las siguientes posiciones la mantienen.
  Future<void> _startFollowing() async {
    if (_mapboxMap == null || _route == null || !_routeFromUser) return;
    setState(() => _followUser = true);

    try {
      final position = await geolocator.Geolocator.getCurrentPosition(
        locationSettings: const geolocator.LocationSettings(
          accuracy: geolocator.LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
      if (!mounted || !_followUser) return;
      await _moveFollowCamera(
        lat: position.latitude,
        lng: position.longitude,
        heading: position.heading,
        speed: position.speed,
        initial: true,
      );
    } catch (e) {
      debugPrint('ERROR CÁMARA DE SEGUIMIENTO: $e');
    }
  }

  /// Centra la cámara en el usuario y la gira hacia su rumbo. En movimiento
  /// usa el rumbo del GPS; parado, el de la ruta, para que el giro que se
  /// muestra coincida con lo que se ve. Zoom e inclinación solo se fijan al
  /// empezar: después el usuario puede acercar o alejar a su gusto.
  Future<void> _moveFollowCamera({
    required double lat,
    required double lng,
    double? heading,
    double? speed,
    bool initial = false,
    bool onRoute = true,
  }) async {
    final map = _mapboxMap;
    final route = _route;
    if (map == null || route == null) return;

    final moving =
        speed != null && speed >= 1.5 && heading != null && heading >= 0;
    final double? bearing = moving
        ? heading
        : (onRoute ? routeBearingAt(route.coordinates, _trimIndex) : null);
    final walking = _routeProfile == RouteProfile.walking;

    await map.easeTo(
      CameraOptions(
        center: Point(coordinates: Position(lng, lat)),
        bearing: bearing,
        zoom: initial ? (walking ? 18.0 : 17.0) : null,
        pitch: initial ? (walking ? 45.0 : 50.0) : null,
      ),
      MapAnimationOptions(duration: initial ? 1000 : 700),
    );
  }

  /// Deja de seguir al usuario y reinicia el avance de la ruta.
  void _stopTracking() {
    _trackSub?.cancel();
    _trackSub = null;
    _offRoute = false;
    _arrived = false;
    _trimIndex = 0;
  }

  /// Encuadra la ruta en el espacio libre entre la barra superior y el panel.
  /// Sin [route] usa la ruta activa y solo el tramo que falta por recorrer.
  Future<void> _frameRoute({RouteResult? route, int duration = 800}) async {
    final map = _mapboxMap;
    final active = route ?? _route;
    if (map == null || active == null) return;
    // Pedir la ruta completa a mano apaga el seguimiento.
    if (route == null) _stopFollowing();

    var coordinates = active.coordinates;
    if (route == null && _trimIndex < coordinates.length - 1) {
      coordinates = coordinates.sublist(_trimIndex);
    }

    final camera = await map.cameraForCoordinates(
      coordinates.map((c) => Point(coordinates: Position(c[0], c[1]))).toList(),
      MbxEdgeInsets(
        // Más espacio arriba cuando la barra muestra la próxima maniobra.
        top: active.steps.isEmpty ? 150 : 230,
        left: 40,
        bottom: 330,
        right: 40,
      ),
      // Vista general siempre con el norte arriba y sin inclinación.
      0,
      0,
    );
    await map.flyTo(camera, MapAnimationOptions(duration: duration));
  }

  /// Mueve el punto del usuario mientras la ruta está activa y avisa si se
  /// aleja. No recalcula la ruta: cada cálculo es una solicitud a Mapbox.
  void _startTracking() {
    _stopTracking();

    final map = _mapboxMap;
    if (map != null) {
      unawaited(
        map.location
            .updateSettings(LocationComponentSettings(enabled: true))
            .catchError((Object e) => debugPrint('ERROR PUNTO USUARIO: $e')),
      );
    }

    _trackSub =
        geolocator.Geolocator.getPositionStream(
          locationSettings: geolocator.LocationSettings(
            accuracy: geolocator.LocationAccuracy.high,
            distanceFilter: 10,
          ),
        ).listen(
          _onTrackedPosition,
          onError: (Object e) => debugPrint('ERROR SEGUIMIENTO: $e'),
        );
  }

  void _onTrackedPosition(geolocator.Position position) {
    final route = _route;
    if (!mounted || route == null) return;

    final meters = distanceToRouteMeters(
      position.latitude,
      position.longitude,
      route.coordinates,
    );
    final off = meters > offRouteMeters;

    // El aviso y el botón «Recalcular» viven en el panel de la ruta.
    if (off != _offRoute) {
      setState(() => _offRoute = off);
      if (off) unawaited(HapticFeedback.mediumImpact());
    }

    // Llegada: se mide contra el destino, no contra el último punto de la ruta.
    final destination = _routeTo;
    if (destination != null && !_arrived) {
      final toDestination = distanceToRouteMeters(
        position.latitude,
        position.longitude,
        [
          [destination.longitude, destination.latitude],
        ],
      );
      if (toDestination <= arrivalMeters) {
        setState(() => _arrived = true);
        unawaited(HapticFeedback.mediumImpact());
      }
    }

    // La línea se borra detrás del usuario: solo avanza, nunca vuelve atrás.
    final index = nearestRouteIndex(
      position.latitude,
      position.longitude,
      route.coordinates,
    );
    if (index > _trimIndex) {
      setState(() => _trimIndex = index);
      unawaited(_redrawFromIndex(route));
    }

    if (_followUser) {
      unawaited(
        _moveFollowCamera(
          lat: position.latitude,
          lng: position.longitude,
          heading: position.heading,
          speed: position.speed,
          onRoute: !off,
        ),
      );
    }
  }

  /// Vuelve a dibujar la línea solo con el tramo que falta por recorrer.
  Future<void> _redrawFromIndex(RouteResult route) async {
    if (_trimBusy || _trimIndex >= route.coordinates.length - 1) return;

    _trimBusy = true;
    try {
      await _drawRouteLine(
        RouteResult(
          coordinates: route.coordinates.sublist(_trimIndex),
          distanceMeters: route.distanceMeters,
          durationSeconds: route.durationSeconds,
        ),
      );
    } finally {
      _trimBusy = false;
    }
  }

  Future<void> _clearRoute() async {
    _stopTracking();
    _stopFollowing();

    final map = _mapboxMap;
    final manager = _routeManager;

    if (map != null && manager != null) {
      await map.annotations.removeAnnotationManager(manager);
    }
    _routeManager = null;

    if (!mounted) return;
    setState(() {
      _route = null;
      // Al terminar la ruta se vuelve a la tarjeta del lugar de destino.
      _previewPlace = _routeTo;
      _routeFrom = null;
      _routeTo = null;
      _routeFromUser = false;
    });
    // Termina el modo ruta: vuelven todos los marcadores y el mapa se
    // endereza (norte arriba, sin inclinación).
    unawaited(_redrawMarkers());
    unawaited(
      _mapboxMap?.easeTo(
        CameraOptions(bearing: 0, pitch: 0),
        MapAnimationOptions(duration: 600),
      ),
    );
  }

  /// Vuelve a calcular la ruta desde la ubicación actual hasta el mismo
  /// destino y con el mismo medio (cuando el usuario se alejó).
  Future<void> _recalculateRoute() async {
    final to = _routeTo;
    if (to == null || !_routeFromUser) return;
    await _routeToPlace(
      to,
      _routeProfile == RouteProfile.walking
          ? MapRouteMode.walking
          : MapRouteMode.driving,
    );
  }

  /// Ubicación real del usuario (GPS).
  Future<void> _goToMyLocation() async {
    final map = _mapboxMap;
    if (map == null) return;

    if (!await geolocator.Geolocator.isLocationServiceEnabled()) {
      _showMessage(
        _isSpanish ? 'Activa el GPS de tu teléfono' : 'Turn on your phone GPS',
      );
      return;
    }

    var permission = await geolocator.Geolocator.checkPermission();
    if (permission == geolocator.LocationPermission.denied) {
      permission = await geolocator.Geolocator.requestPermission();
    }
    unawaited(_checkLocation(requestIfNeeded: false));
    if (permission == geolocator.LocationPermission.denied ||
        permission == geolocator.LocationPermission.deniedForever) {
      _showMessage(
        _isSpanish
            ? 'Se necesita permiso de ubicación'
            : 'Location permission is required',
      );
      return;
    }

    try {
      // Punto azul de "tú estás aquí".
      await map.location.updateSettings(
        LocationComponentSettings(enabled: true, pulsingEnabled: true),
      );

      final position = await geolocator.Geolocator.getCurrentPosition(
        locationSettings: const geolocator.LocationSettings(
          accuracy: geolocator.LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      await map.flyTo(
        CameraOptions(
          center: Point(
            coordinates: Position(position.longitude, position.latitude),
          ),
          zoom: 15.0,
        ),
        MapAnimationOptions(duration: 1200),
      );
    } catch (_) {
      _showMessage(
        _isSpanish
            ? 'No se pudo obtener tu ubicación'
            : 'Your location could not be determined',
      );
    }
  }

  // ===============================================================
  // BUSCADOR
  // ===============================================================

  /// Al presionar "buscar" en el teclado, va al primer resultado.
  void _onSearchSubmitted(String _) {
    final results = _filteredPlaces;

    if (results.isEmpty) {
      _showMessage(
        _isSpanish ? 'No se encontraron lugares' : 'No places found',
      );
      return;
    }

    _goToPlace(results.first);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {});
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  // ===============================================================
  // BUILD
  // ===============================================================

  @override
  Widget build(BuildContext context) {
    // Redibuja los textos y traduce el mapa si cambia el idioma: esta pestaña
    // se conserva mientras el usuario cambia el idioma desde su perfil.
    ref.watch(languageProvider);
    ref.listen<Locale>(languageProvider, (_, next) {
      _applyMapLanguage(next.languageCode);
    });

    // Con una ruta activa, «atrás» termina la ruta en vez de salir de la app.
    return PopScope(
      canPop: _route == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_clearRoute());
      },
      child: Scaffold(body: _buildMapStack()),
    );
  }

  Widget _buildMapStack() {
    return Stack(
      children: [
        Positioned.fill(
          child: MapWidget(
            styleUri: _style.uri,
            cameraOptions: CameraOptions(
              center: Point(
                coordinates: Position(_center.longitude, _center.latitude),
              ),
              zoom: _initialZoom,
            ),
            onMapCreated: _onMapCreated,
            onStyleLoadedListener: _onStyleLoaded,
            onMapLoadErrorListener: _onMapLoadError,
            onScrollListener: (_) => _onUserMovedMap(),
          ),
        ),

        // Mapa cargando (con conexión): indicador para que no parezca colgado.
        if (_online && !_styleLoaded && !_mapLoadFailed)
          const IgnorePointer(
            child: Center(
              child: SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppTheme.primaryDark,
                ),
              ),
            ),
          ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                // Modo ruta: sin buscador ni lugares rápidos, solo el destino.
                if (_route != null)
                  MapRouteEntrance(fromTop: true, child: _buildRouteHeader())
                else ...[
                  _buildSearchBar(),
                  const SizedBox(height: 12),
                  _buildQuickLocations(),
                ],
                // Aviso fijo sin conexión, propio del mapa (FIX-002).
                if (!_online) ...[
                  const SizedBox(height: 10),
                  _buildOfflineNotice(),
                ],
                // Aviso para activar la ubicación; el mapa funciona sin ella.
                if (_showLocationNotice && _route == null) ...[
                  const SizedBox(height: 10),
                  _buildLocationNotice(),
                ],
              ],
            ),
          ),
        ),

        if (_route != null)
          // Modo ruta: controles en fila sobre el panel, ambos a todo el ancho.
          Positioned(
            left: 16,
            right: 16,
            bottom: 110,
            child: MapRouteEntrance(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: _buildControls(horizontal: true),
                  ),
                  const SizedBox(height: 12),
                  _buildRoutePanel(),
                ],
              ),
            ),
          )
        else ...[
          // Tarjeta flotante del lugar elegido (marcador o buscador).
          Positioned(
            left: 16,
            right: 76,
            bottom: 110,
            child: _buildPreviewCard(),
          ),

          // Controles del mapa.
          Positioned(right: 16, bottom: 110, child: _buildControls()),
        ],

        // El mapa no cargó teniendo conexión (FIX-010).
        if (_online && _mapLoadFailed)
          Positioned.fill(child: _buildMapErrorCard()),
      ],
    );
  }

  /// Aviso fijo bajo el buscador mientras no hay conexión. El mapa sigue
  /// usable con lo ya cargado y el GPS, que no necesita internet.
  Widget _buildOfflineNotice() {
    final es = _isSpanish;
    final sync = _lastSync;
    final date = sync == null ? null : _formatSyncDate(sync);
    final text = es
        ? (date == null
              ? 'Sin conexión. Las rutas necesitan internet.'
              : 'Sin conexión · Datos del $date. Las rutas necesitan internet.')
        : (date == null
              ? 'No connection. Routes need internet.'
              : 'No connection · Data from $date. Routes need internet.');

    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.primaryDark,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(Icons.cloud_off_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Tarjeta cuando el mapa no carga teniendo conexión, con «Reintentar».
  /// El resto de la app (pestañas, fichas) sigue disponible.
  Widget _buildMapErrorCard() {
    final es = _isSpanish;
    return ColoredBox(
      color: const Color(0xFFE8EBED),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.map_outlined,
                  size: 56,
                  color: AppTheme.primaryDark,
                ),
                const SizedBox(height: 16),
                Text(
                  es
                      ? 'No se pudo cargar el mapa. Revisa tu conexión e inténtalo de nuevo.'
                      : 'The map could not be loaded. Check your connection and try again.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, height: 1.4),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _retryMapLoad,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryDark,
                  ),
                  child: Text(es ? 'Reintentar' : 'Try again'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Si hay que avisar que la ubicación no está disponible.
  bool get _showLocationNotice =>
      !_locationNoticeDismissed &&
      _gate != _LocationGate.granted &&
      _gate != _LocationGate.checking;

  /// Aviso descartable bajo el buscador cuando falta GPS o permiso. No
  /// bloquea el mapa: se puede explorar sin la ubicación (M-07).
  Widget _buildLocationNotice() {
    final es = _isSpanish;

    final (String text, String action, VoidCallback onAction) = switch (_gate) {
      _LocationGate.serviceOff => (
        es
            ? 'La ubicación del teléfono está desactivada. Actívala para ver dónde estás.'
            : 'Phone location is off. Turn it on to see where you are.',
        es ? 'Activar' : 'Turn on',
        () => geolocator.Geolocator.openLocationSettings(),
      ),
      _LocationGate.deniedForever => (
        es
            ? 'El permiso de ubicación está bloqueado. Actívalo en los ajustes para ver dónde estás.'
            : 'Location permission is blocked. Turn it on in settings to see where you are.',
        es ? 'Ajustes' : 'Settings',
        () => geolocator.Geolocator.openAppSettings(),
      ),
      _ => (
        es
            ? 'Permite la ubicación para ver dónde estás y trazar rutas desde ti.'
            : 'Allow location to see where you are and plan routes from you.',
        es ? 'Permitir' : 'Allow',
        () => _checkLocation(requestIfNeeded: true),
      ),
    };

    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        padding: const EdgeInsetsDirectional.only(start: 12, top: 4, bottom: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const ExcludeSemantics(
              child: Icon(
                Icons.location_off_rounded,
                size: 20,
                color: AppTheme.primaryDark,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(fontSize: 13, height: 1.3),
              ),
            ),
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryDark,
              ),
              child: Text(
                action,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            IconButton(
              tooltip: es ? 'Cerrar aviso' : 'Dismiss',
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              icon: const Icon(Icons.close_rounded, size: 18),
              onPressed: () => setState(() => _locationNoticeDismissed = true),
            ),
          ],
        ),
      ),
    );
  }

  // ===============================================================
  // CONTROLES (zoom, estilo, GPS, centrar)
  // ===============================================================

  Widget _buildControls({bool horizontal = false}) {
    // En una ruta propia el botón de ubicación activa la cámara de navegación.
    final followRoute = _route != null && _routeFromUser;
    return Flex(
      direction: horizontal ? Axis.horizontal : Axis.vertical,
      mainAxisSize: MainAxisSize.min,
      children: [
        _circleButton(
          child: IconButton(
            tooltip: _isSpanish ? 'Acercar' : 'Zoom in',
            icon: const Icon(Icons.add, color: AppTheme.primaryDark),
            onPressed: () => _zoomBy(1),
          ),
        ),
        const SizedBox(width: 8, height: 8),
        _circleButton(
          child: IconButton(
            tooltip: _isSpanish ? 'Alejar' : 'Zoom out',
            icon: const Icon(Icons.remove, color: AppTheme.primaryDark),
            onPressed: () => _zoomBy(-1),
          ),
        ),
        if (_route == null) ...[
        const SizedBox(width: 8, height: 8),
        _circleButton(
          child: PopupMenuButton<MapStyleOption>(
            tooltip: _isSpanish ? 'Estilo del mapa' : 'Map style',
            icon: const Icon(
              Icons.layers_outlined,
              color: AppTheme.primaryDark,
            ),
            onSelected: _changeStyle,
            itemBuilder: (_) => MapStyleOption.values
                .map(
                  (option) => PopupMenuItem<MapStyleOption>(
                    value: option,
                    child: Row(
                      children: [
                        Icon(
                          option.icon,
                          size: 20,
                          color: option == _style
                              ? AppTheme.primaryDark
                              : Colors.black54,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          option.label(isSpanish: _isSpanish),
                          style: TextStyle(
                            fontWeight: option == _style
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        ],
        const SizedBox(width: 8, height: 8),
        _circleButton(
          filled: _followUser,
          child: IconButton(
            tooltip: followRoute
                ? (_isSpanish ? 'Seguir mi ubicación' : 'Follow my location')
                : (_isSpanish ? 'Mi ubicación' : 'My location'),
            icon: Icon(
              followRoute ? Icons.navigation_rounded : Icons.my_location,
              color: _followUser ? Colors.white : AppTheme.primaryDark,
            ),
            onPressed: followRoute
                ? () => unawaited(_startFollowing())
                : _goToMyLocation,
          ),
        ),
        if (_route != null) ...[
          const SizedBox(width: 8, height: 8),
          _circleButton(
            filled: true,
            child: IconButton(
              tooltip: _isSpanish ? 'Ver toda la ruta' : 'Show full route',
              icon: const Icon(Icons.route_rounded, color: Colors.white),
              onPressed: () => unawaited(_frameRoute()),
            ),
          ),
        ],
        if (_route == null) ...[
          const SizedBox(width: 8, height: 8),
          _circleButton(
            filled: true,
            child: IconButton(
              tooltip: _isSpanish
                  ? 'Centrar en Coyhaique'
                  : 'Center on Coyhaique',
              icon: const Icon(Icons.center_focus_strong, color: Colors.white),
              onPressed: () => _goToPlace(_center, showPreview: false),
            ),
          ),
        ],
      ],
    );
  }

  Widget _circleButton({required Widget child, bool filled = false}) {
    return Material(
      color: filled ? AppTheme.primaryDark : Colors.white,
      elevation: 3,
      shape: const CircleBorder(),
      child: SizedBox(width: 46, height: 46, child: Center(child: child)),
    );
  }

  // ===============================================================
  // BUSCADOR (UI)
  // ===============================================================

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 10,
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocus,
        textInputAction: TextInputAction.search,
        onSubmitted: _onSearchSubmitted,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: _isSpanish
              ? 'Buscar destinos, servicios en el mapa...'
              : 'Search destinations, services on the map...',
          prefixIcon: const Icon(Icons.search, color: AppTheme.primaryDark),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: _clearSearch,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  // ===============================================================
  // ACCESOS RÁPIDOS (filtrados por el buscador)
  // ===============================================================

  Widget _buildQuickLocations() {
    final places = _filteredPlaces;

    if (places.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: places.map((place) {
          final isSelected = identical(place, _selectedPlace);

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              avatar: Icon(
                place.icon,
                size: 18,
                color: isSelected ? Colors.white : AppTheme.primaryDark,
              ),
              label: Text(
                place.name(isSpanish: _isSpanish),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
              backgroundColor: isSelected ? AppTheme.primaryDark : Colors.white,
              elevation: 2,
              onPressed: () => _goToPlace(place),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ===============================================================
  // MODO RUTA (barra superior y panel inferior)
  // ===============================================================

  MapRouteMode get _activeMode => _routeProfile == RouteProfile.walking
      ? MapRouteMode.walking
      : MapRouteMode.driving;

  Widget _buildRouteHeader() {
    return MapRouteHeader(
      destination: _routeTo?.name(isSpanish: _isSpanish) ?? '',
      mode: _activeMode,
      isSpanish: _isSpanish,
      origin: _routeFromUser ? null : _routeFrom?.name(isSpanish: _isSpanish),
      maneuver: _currentManeuver(),
    );
  }

  /// Próximo giro según el avance del usuario. Solo con seguimiento, en la
  /// ruta y antes de llegar: fuera de ruta las indicaciones ya no sirven.
  MapManeuver? _currentManeuver() {
    final route = _route;
    if (route == null || !_routeFromUser || _arrived || _offRoute) return null;

    final step = nextManeuverStep(route.steps, _trimIndex);
    if (step == null) return null;

    return MapManeuver.fromStep(
      step: step,
      meters: routeLengthMeters(route.coordinates, _trimIndex, step.coordIndex),
      isSpanish: _isSpanish,
    );
  }

  Widget _buildRoutePanel() {
    final route = _route;
    final destination = _routeTo;
    if (route == null || destination == null) return const SizedBox.shrink();

    // Lo que falta por recorrer, estimado según el avance del usuario.
    final fraction = remainingRouteFraction(route.coordinates, _trimIndex);
    final remaining = RouteResult(
      coordinates: const [],
      distanceMeters: route.distanceMeters * fraction,
      durationSeconds: route.durationSeconds * fraction,
    );

    final openDetail = widget.onOpenPlace;
    return MapRoutePanel(
      destination: destination.name(isSpanish: _isSpanish),
      mode: _activeMode,
      isSpanish: _isSpanish,
      durationLabel: remaining.durationLabel,
      distanceLabel: remaining.distanceLabel,
      tracking: _routeFromUser,
      offRoute: _offRoute,
      arrived: _arrived,
      recalculating: _loadingRoute || _routeMode != null,
      onEnd: _clearRoute,
      onRecalculate: _routeFromUser ? _recalculateRoute : null,
      onOpenDetail: destination.id != null && openDetail != null
          ? () => openDetail(destination)
          : null,
    );
  }

  // ===============================================================
  // TARJETA FLOTANTE DEL LUGAR
  // ===============================================================

  /// Conecta [MapPlacePreviewCard] con la ficha (`onOpenPlace`, que define el
  /// router) y con el sistema de rutas de esta pantalla.
  Widget _buildPreviewCard() {
    final place = _previewPlace;
    final route = _route;

    return MapPlacePreviewCard(
      place: place,
      isSpanish: _isSpanish,
      online: _online,
      // La plaza y el centro son el punto de partida: no tienen ruta.
      canRoute:
          place != null &&
          !identical(place, _plaza) &&
          !identical(place, _center),
      routingMode: _routeMode,
      onClose: () => setState(() => _previewPlace = null),
      onOpenDetail: widget.onOpenPlace,
      onRoute: (mode) {
        if (place != null) _routeToPlace(place, mode);
      },
      routeSummary: route == null
          ? null
          : MapRouteSummary(
              text:
                  '${_routeFrom?.name(isSpanish: _isSpanish) ?? ''} → '
                  '${_routeTo?.name(isSpanish: _isSpanish) ?? ''} · '
                  '${route.distanceLabel} · ${route.durationLabel}',
              mode: _routeProfile == RouteProfile.walking
                  ? MapRouteMode.walking
                  : MapRouteMode.driving,
              onClear: _clearRoute,
            ),
    );
  }
}

/// Fecha de descarga para el aviso sin conexión (dd-mm-aaaa).
String _formatSyncDate(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}-${two(d.month)}-${d.year}';
}
