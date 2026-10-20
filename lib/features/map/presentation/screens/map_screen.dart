import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../../../core/theme/app_theme.dart';
import 'mapbox_directions_services.dart';

// ===============================================================
// MODELO DE UBICACIÓN
// ===============================================================

class MapPlace {
  final String name;
  final String description;
  final IconData icon;
  final double longitude;
  final double latitude;
  final double zoom;

  /// false = coordenadas aproximadas (sin marcador en el mapa y con aviso).
  final bool verified;

  const MapPlace({
    required this.name,
    required this.description,
    required this.icon,
    required this.longitude,
    required this.latitude,
    this.zoom = 15.0,
    this.verified = true,
  });
}

// ===============================================================
// ESTILOS DE MAPA
// ===============================================================

enum MapStyleOption {
  outdoors('Terreno', Icons.terrain, MapboxStyles.OUTDOORS),
  satellite('Satélite', Icons.satellite_alt, MapboxStyles.SATELLITE_STREETS),
  streets('Calles', Icons.map_outlined, MapboxStyles.MAPBOX_STREETS);

  const MapStyleOption(this.label, this.icon, this.uri);

  final String label;
  final IconData icon;
  final String uri;
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // ===============================================================
  // CONFIGURACIÓN
  // ===============================================================

  static const MapPlace _center = MapPlace(
    name: 'Coyhaique Centro',
    description: 'Centro de la ciudad, punto de partida para recorrer Aysén.',
    icon: Icons.location_city,
    longitude: -72.068265,
    latitude: -45.571225,
    zoom: 13.0,
  );

  static const double _initialZoom = 12.5;

  // Coordenadas de la ciudad: coinciden con la Plaza de Armas.
  // Es el punto de partida de las rutas.
  static const MapPlace _plaza = MapPlace(
    name: 'Plaza de Armas',
    description:
        'Plaza pentagonal de la que parten 10 calles. Aquí está la feria artesanal.',
    icon: Icons.park_outlined,
    longitude: -72.068265,
    latitude: -45.571225,
    zoom: 16.0,
  );

  static const List<MapPlace> _places = [
    _plaza,
    // Centro de la reserva según Wikipedia (45°30′40″S 71°59′45″W).
    MapPlace(
      name: 'Reserva Nacional',
      description:
          'Reserva creada en 1948, a menos de 5 km de la ciudad. Tiene lagunas como Laguna Verde y miradores hacia Coyhaique.',
      icon: Icons.forest_outlined,
      longitude: -71.99583,
      latitude: -45.51111,
      zoom: 12.5,
    ),
    // Dirección confirmada por SERNATUR: Bulnes 35, a ~150 m de la plaza.
    MapPlace(
      name: 'SERNATUR',
      description:
          'Oficina de información turística (Bulnes 35). Pide mapas y consulta el estado de rutas y actividades.',
      icon: Icons.info_outline,
      longitude: -72.06757009107555,
      latitude: -45.56999552963736,
      zoom: 16.5,
    ),
    // Cumbre de 1.205 m (Andeshandbook: 45°36′29.9″S 72°04′32.2″W).
    // Está al sur de la ciudad, a ~4 km del centro.
    MapPlace(
      name: 'Cerro Mackay',
      description:
          'La postal más reconocible de Coyhaique (1.205 m), al sur de la ciudad. Trekking y escalada. El acceso cruza terrenos privados: respeta cercos y propietarios.',
      icon: Icons.landscape_outlined,
      longitude: -72.075611,
      latitude: -45.608306,
      zoom: 13.5,
    ),
    // Aeropuerto Balmaceda (BBA), el principal de Aysén.
    // Wikipedia: 45°54′58″S 71°41′15″W. Está a ~50 km de la ciudad.
    // Si prefieres el aeródromo Teniente Vidal (a ~3 km al suroeste):
    //   latitude: -45.59444, longitude: -72.10667
    MapPlace(
      name: 'Aeropuerto Balmaceda',
      description:
          'Principal aeropuerto de Aysén, a unos 50 km al sureste de Coyhaique. Vuelos a Santiago y Puerto Montt.',
      icon: Icons.flight,
      longitude: -71.68750,
      latitude: -45.91611,
      zoom: 12.5,
    ),
  ];

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  MapboxMap? _mapboxMap;
  CircleAnnotationManager? _markerManager;
  final Map<String, MapPlace> _placeByAnnotationId = {};

  MapPlace _selectedPlace = _center;
  MapStyleOption _style = MapStyleOption.outdoors;

  // Ruta activa (si hay una dibujada en el mapa).
  PolylineAnnotationManager? _routeManager;
  RouteResult? _route;
  String? _routeLabel;
  bool _loadingRoute = false;

  /// Lugares filtrados según el texto del buscador.
  List<MapPlace> get _filteredPlaces {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _places;
    return _places.where((p) => p.name.toLowerCase().contains(query)).toList();
  }

  @override
  void dispose() {
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
    if (map == null) return;

    final oldManager = _markerManager;
    if (oldManager != null) {
      await map.annotations.removeAnnotationManager(oldManager);
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

    // Tocar un marcador = ir a ese lugar.
    manager.tapEvents(
      onTap: (annotation) {
        final place = _placeByAnnotationId[annotation.id];
        if (place != null) _goToPlace(place);
      },
    );

    // Si había una ruta activa, se vuelve a dibujar con el nuevo estilo.
    final route = _route;
    if (route != null) {
      await _drawRouteLine(route);
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
        profile: RouteProfile.driving,
      );
      service.dispose();

      if (route == null) {
        _showMessage('No se encontró una ruta');
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
        _routeLabel = '${from.name} → ${to.name}';
      });
    } catch (e) {
      debugPrint('ERROR RUTA: $e');
      _showMessage('No se pudo calcular la ruta');
    } finally {
      if (mounted) setState(() => _loadingRoute = false);
    }
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
      _routeLabel = null;
    });
  }

  /// Ubicación real del usuario (GPS).
  Future<void> _goToMyLocation() async {
    final map = _mapboxMap;
    if (map == null) return;

    if (!await geolocator.Geolocator.isLocationServiceEnabled()) {
      _showMessage('Activa el GPS de tu teléfono');
      return;
    }

    var permission = await geolocator.Geolocator.checkPermission();
    if (permission == geolocator.LocationPermission.denied) {
      permission = await geolocator.Geolocator.requestPermission();
    }
    if (permission == geolocator.LocationPermission.denied ||
        permission == geolocator.LocationPermission.deniedForever) {
      _showMessage('Se necesita permiso de ubicación');
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
      _showMessage('No se pudo obtener tu ubicación');
    }
  }

  // ===============================================================
  // BUSCADOR
  // ===============================================================

  /// Al presionar "buscar" en el teclado, va al primer resultado.
  void _onSearchSubmitted(String _) {
    final results = _filteredPlaces;

    if (results.isEmpty) {
      _showMessage('No se encontraron lugares');
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
    return Scaffold(
      body: Stack(
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
            tooltip: 'Acercar',
            icon: const Icon(Icons.add, color: AppTheme.primaryDark),
            onPressed: () => _zoomBy(1),
          ),
        ),
        const SizedBox(height: 8),
        _circleButton(
          child: IconButton(
            tooltip: 'Alejar',
            icon: const Icon(Icons.remove, color: AppTheme.primaryDark),
            onPressed: () => _zoomBy(-1),
          ),
        ),
        const SizedBox(height: 8),
        _circleButton(
          child: PopupMenuButton<MapStyleOption>(
            tooltip: 'Estilo del mapa',
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
                          option.label,
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
            tooltip: 'Mi ubicación',
            icon: const Icon(Icons.my_location, color: AppTheme.primaryDark),
            onPressed: _goToMyLocation,
          ),
        ),
        const SizedBox(height: 8),
        _circleButton(
          filled: true,
          child: IconButton(
            tooltip: 'Centrar en Coyhaique',
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
          hintText: 'Buscar destinos, servicios en el mapa...',
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
          final isSelected = place.name == _selectedPlace.name;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              avatar: Icon(
                place.icon,
                size: 18,
                color: isSelected ? Colors.white : AppTheme.primaryDark,
              ),
              label: Text(
                place.name,
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
                  place.name,
                  style: const TextStyle(
                    color: AppTheme.primaryDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            place.description,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 12.5,
              height: 1.3,
            ),
          ),
          ..._buildRouteSection(place),
          if (!place.verified) ...[
            const SizedBox(height: 6),
            const Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: Colors.orange),
                SizedBox(width: 4),
                Text(
                  'Ubicación aproximada',
                  style: TextStyle(fontSize: 11.5, color: Colors.orange),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ===============================================================
  // RUTA EN LA TARJETA
  // ===============================================================

  List<Widget> _buildRouteSection(MapPlace place) {
    final route = _route;

    // Hay una ruta activa: muestra distancia, tiempo y botón para quitarla.
    if (route != null) {
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
                '${_routeLabel ?? ''} · ${route.distanceLabel} · ${route.durationLabel}',
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
            label: const Text('Quitar ruta'),
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
    if (place.name == _plaza.name || place.name == _center.name) {
      return const [];
    }

    return [
      const SizedBox(height: 6),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: _loadingRoute
              ? null
              : () => _showRoute(from: _plaza, to: place),
          icon: _loadingRoute
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.directions, size: 18),
          label: const Text('Ruta desde la Plaza de Armas'),
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
