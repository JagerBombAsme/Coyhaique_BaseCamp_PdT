import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../../../core/providers/language_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../categories/data/models/place_dto.dart';
import '../../../categories/data/providers/places_provider.dart';
import '../../../trip_info/presentation/widgets/trip_notice.dart';
import '../map_places.dart';
import 'mapbox_directions_services.dart';
import 'transport_mode_screen.dart';

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

/// Estado del permiso de ubicación. Sin permiso no se muestra el mapa.
enum _LocationGate { checking, granted, serviceOff, denied, deniedForever }

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key, this.routeFromAirport = false, this.onOpenPlace});

  /// Abre el mapa con la ruta Aeropuerto Balmaceda → Plaza de Armas
  /// (pantalla «¿Desde dónde partes?», viaje en transporte propio).
  final bool routeFromAirport;

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
  final Map<String, MapPlace> _placeByAnnotationId = {};

  /// Evita dos redibujos de marcadores a la vez (estilo y datos pueden
  /// coincidir) y que queden administradores de marcadores sin quitar.
  bool _redrawingMarkers = false;
  bool _redrawAgain = false;

  MapPlace _selectedPlace = _center;
  MapStyleOption _style = MapStyleOption.outdoors;

  // Ruta activa (si hay una dibujada en el mapa).
  PolylineAnnotationManager? _routeManager;
  RouteResult? _route;
  MapPlace? _routeFrom;
  MapPlace? _routeTo;
  bool _loadingRoute = false;

  /// Ruta desde el aeropuerto pedida antes de que el mapa terminara de cargar.
  late bool _pendingAirportRoute = widget.routeFromAirport;

  /// Permiso de ubicación: el mapa solo se muestra cuando está concedido.
  _LocationGate _gate = _LocationGate.checking;

  /// Lugares filtrados según el texto del buscador.
  List<MapPlace> get _filteredPlaces {
    return _places.where((p) => p.matches(_searchController.text)).toList();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Al abrir el mapa se pide la ubicación (no se muestra el mapa sin ella).
    _checkLocation(requestIfNeeded: true);

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
        ),
      );
    }
    return result;
  }

  /// Al volver de los ajustes del teléfono se revisa de nuevo el permiso.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkLocation(requestIfNeeded: false);
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

    final manager = await map.annotations.createCircleAnnotationManager();
    _markerManager = manager;

    for (final place in _places.where((p) => p.verified)) {
      final annotation = await manager.create(
        CircleAnnotationOptions(
          geometry: Point(
            coordinates: Position(place.longitude, place.latitude),
          ),
          circleRadius: 9,
          circleColor: AppTheme.primaryDark.toARGB32(),
          circleStrokeColor: Colors.white.toARGB32(),
          circleStrokeWidth: 3,
        ),
      );
      _placeByAnnotationId[annotation.id] = place;
    }

    // Tocar un marcador = ir a ese lugar y mostrar su tarjeta, que ofrece
    // «Ver ficha» cuando el lugar viene de places_v2.
    manager.tapEvents(
      onTap: (annotation) {
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
  Future<void> _goToPlace(MapPlace place) async {
    _searchFocus.unfocus();
    setState(() => _selectedPlace = place);

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
    setState(() => _style = option);
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
  }) async {
    final map = _mapboxMap;
    if (map == null || _loadingRoute) return;

    setState(() => _loadingRoute = true);

    try {
      // Mismo token con el que se inicializó el mapa.
      final token = await MapboxOptions.getAccessToken();
      final service = MapboxDirectionsService(accessToken: token);

      final route = await service.getRoute(
        fromLongitude: from.longitude,
        fromLatitude: from.latitude,
        toLongitude: to.longitude,
        toLatitude: to.latitude,
        profile: profile,
      );
      service.dispose();

      if (route == null) {
        _showMessage(_isSpanish ? 'No se encontró una ruta' : 'No route found');
        return;
      }

      await _drawRouteLine(route);

      // Encuadra la ruta completa en pantalla.
      final camera = await map.cameraForCoordinates(
        route.coordinates
            .map((c) => Point(coordinates: Position(c[0], c[1])))
            .toList(),
        MbxEdgeInsets(top: 180, left: 40, bottom: 280, right: 90),
        null,
        null,
      );
      await map.flyTo(camera, MapAnimationOptions(duration: 1200));

      if (!mounted) return;
      setState(() {
        _route = route;
        _routeFrom = from;
        _routeTo = to;
      });

      // Aviso de uso seguro cada vez que se genera una ruta (RNF-14).
      TripNotice.show(
        context,
        kind: profile == RouteProfile.walking
            ? TripNoticeKind.walk
            : TripNoticeKind.route,
      );
    } catch (e) {
      debugPrint('ERROR RUTA: $e');
      _showMessage(
        _isSpanish
            ? 'No se pudo calcular la ruta'
            : 'The route could not be calculated',
      );
    } finally {
      if (mounted) setState(() => _loadingRoute = false);
    }
  }

  /// Pregunta si la persona anda a pie o en auto y calcula la ruta desde la
  /// Plaza de Armas con ese medio. Si cierra la pantalla, no pasa nada.
  Future<void> _chooseTransportAndRoute(MapPlace place) async {
    final profile = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        fullscreenDialog: true,
        builder: (_) => const TransportModeScreen(),
      ),
    );
    if (profile == null || !mounted) return;
    await _showRoute(from: _plaza, to: place, profile: profile);
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

  Future<void> _clearRoute() async {
    final map = _mapboxMap;
    final manager = _routeManager;

    if (map != null && manager != null) {
      await map.annotations.removeAnnotationManager(manager);
    }
    _routeManager = null;

    if (!mounted) return;
    setState(() {
      _route = null;
      _routeFrom = null;
      _routeTo = null;
    });
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

    return Scaffold(
      body: _gate == _LocationGate.granted
          ? _buildMapStack()
          : _buildLocationGate(),
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
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                _buildSearchBar(),
                const SizedBox(height: 12),
                _buildQuickLocations(),
              ],
            ),
          ),
        ),

        // Tarjeta de información del lugar seleccionado.
        Positioned(left: 16, right: 76, bottom: 110, child: _buildInfoCard()),

        // Controles del mapa.
        Positioned(right: 16, bottom: 110, child: _buildControls()),
      ],
    );
  }

  /// Pantalla que reemplaza al mapa mientras no hay permiso de ubicación.
  Widget _buildLocationGate() {
    final es = _isSpanish;

    if (_gate == _LocationGate.checking) {
      return const Center(child: CircularProgressIndicator());
    }

    final (String text, String action, VoidCallback onAction) = switch (_gate) {
      _LocationGate.serviceOff => (
        es
            ? 'Activa la ubicación de tu teléfono para ver el mapa.'
            : 'Turn on your phone location to see the map.',
        es ? 'Activar ubicación' : 'Turn on location',
        () => geolocator.Geolocator.openLocationSettings(),
      ),
      _LocationGate.deniedForever => (
        es
            ? 'El permiso de ubicación está bloqueado. Actívalo en los ajustes de la aplicación para ver el mapa.'
            : 'Location permission is blocked. Turn it on in the app settings to see the map.',
        es ? 'Abrir ajustes' : 'Open settings',
        () => geolocator.Geolocator.openAppSettings(),
      ),
      _ => (
        es
            ? 'Activa los permisos de ubicación para ver el mapa.'
            : 'Turn on location permissions to see the map.',
        es ? 'Permitir ubicación' : 'Allow location',
        () => _checkLocation(requestIfNeeded: true),
      ),
    };

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
                  Icons.location_off_rounded,
                  size: 56,
                  color: AppTheme.primaryDark,
                ),
                const SizedBox(height: 16),
                Text(
                  es ? 'Ubicación necesaria' : 'Location needed',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryDark,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, height: 1.4),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: onAction,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryDark,
                  ),
                  child: Text(action),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => _checkLocation(requestIfNeeded: false),
                  child: Text(es ? 'Ya la activé' : 'I turned it on'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===============================================================
  // CONTROLES (zoom, estilo, GPS, centrar)
  // ===============================================================

  Widget _buildControls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _circleButton(
          child: IconButton(
            tooltip: _isSpanish ? 'Acercar' : 'Zoom in',
            icon: const Icon(Icons.add, color: AppTheme.primaryDark),
            onPressed: () => _zoomBy(1),
          ),
        ),
        const SizedBox(height: 8),
        _circleButton(
          child: IconButton(
            tooltip: _isSpanish ? 'Alejar' : 'Zoom out',
            icon: const Icon(Icons.remove, color: AppTheme.primaryDark),
            onPressed: () => _zoomBy(-1),
          ),
        ),
        const SizedBox(height: 8),
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
        const SizedBox(height: 8),
        _circleButton(
          child: IconButton(
            tooltip: _isSpanish ? 'Mi ubicación' : 'My location',
            icon: const Icon(Icons.my_location, color: AppTheme.primaryDark),
            onPressed: _goToMyLocation,
          ),
        ),
        const SizedBox(height: 8),
        _circleButton(
          filled: true,
          child: IconButton(
            tooltip: _isSpanish
                ? 'Centrar en Coyhaique'
                : 'Center on Coyhaique',
            icon: const Icon(Icons.center_focus_strong, color: Colors.white),
            onPressed: () => _goToPlace(_center),
          ),
        ),
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
  // TARJETA DE INFORMACIÓN
  // ===============================================================

  Widget _buildInfoCard() {
    final place = _selectedPlace;
    final description = place.description(isSpanish: _isSpanish);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(place.icon, color: AppTheme.primaryDark, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  place.name(isSpanish: _isSpanish),
                  style: const TextStyle(
                    color: AppTheme.primaryDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              description,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 12.5,
                height: 1.3,
              ),
            ),
          ],
          ..._buildDetailSection(place),
          ..._buildRouteSection(place),
          if (!place.verified) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.info_outline, size: 14, color: Colors.orange),
                const SizedBox(width: 4),
                Text(
                  _isSpanish ? 'Ubicación aproximada' : 'Approximate location',
                  style: const TextStyle(fontSize: 11.5, color: Colors.orange),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ===============================================================
  // FICHA DEL LUGAR
  // ===============================================================

  /// «Ver ficha»: solo para lugares que vienen de places_v2 (tienen id) y
  /// cuando el router conectó la navegación. Los puntos fijos no tienen ficha.
  List<Widget> _buildDetailSection(MapPlace place) {
    final onOpenPlace = widget.onOpenPlace;
    if (place.id == null || onOpenPlace == null) return const [];

    return [
      const SizedBox(height: 6),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => onOpenPlace(place),
          icon: const Icon(Icons.arrow_forward, size: 16),
          label: Text(_isSpanish ? 'Ver ficha' : 'View details'),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const ui.Size(0, 32),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ),
    ];
  }

  // ===============================================================
  // RUTA EN LA TARJETA
  // ===============================================================

  List<Widget> _buildRouteSection(MapPlace place) {
    final route = _route;

    // Hay una ruta activa: muestra distancia, tiempo y botón para quitarla.
    if (route != null) {
      final from = _routeFrom?.name(isSpanish: _isSpanish) ?? '';
      final to = _routeTo?.name(isSpanish: _isSpanish) ?? '';

      return [
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(
              Icons.directions_car_outlined,
              size: 16,
              color: AppTheme.primaryDark,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '$from → $to · ${route.distanceLabel} · ${route.durationLabel}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryDark,
                ),
              ),
            ),
          ],
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _clearRoute,
            icon: const Icon(Icons.close, size: 16),
            label: Text(_isSpanish ? 'Quitar ruta' : 'Remove route'),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const ui.Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
      ];
    }

    // La plaza y el centro son el punto de partida: no tienen ruta.
    if (identical(place, _plaza) || identical(place, _center)) {
      return const [];
    }

    return [
      const SizedBox(height: 6),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: _loadingRoute
              ? null
              : () => _chooseTransportAndRoute(place),
          icon: _loadingRoute
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.directions, size: 18),
          label: Text(
            _isSpanish ? '¿Andas a pie o en auto?' : 'On foot or by car?',
          ),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const ui.Size(0, 32),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ),
    ];
  }
}
