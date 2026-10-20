import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../../../core/theme/app_theme.dart';

// ===============================================================
// MODELO DE UBICACIÓN
// ===============================================================

class MapPlace {
  final String name;
  final IconData icon;
  final double longitude;
  final double latitude;
  final double zoom;

  const MapPlace({
    required this.name,
    required this.icon,
    required this.longitude,
    required this.latitude,
    this.zoom = 15.0,
  });
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
    icon: Icons.location_city,
    longitude: -72.0683,
    latitude: -45.5712,
    zoom: 13.0,
  );

  static const double _initialZoom = 12.5;

  // ⚠️ Coordenadas APROXIMADAS: verifícalas antes de publicar.
  static const List<MapPlace> _places = [
    MapPlace(
      name: 'SERNATUR',
      icon: Icons.info_outline,
      longitude: -72.0679,
      latitude: -45.5719,
    ),
    MapPlace(
      name: 'Plaza de Armas',
      icon: Icons.park_outlined,
      longitude: -72.0662,
      latitude: -45.5752,
    ),
    MapPlace(
      name: 'Reserva Nacional',
      icon: Icons.forest_outlined,
      longitude: -72.0167,
      latitude: -45.5333,
      zoom: 13.5,
    ),
    MapPlace(
      name: 'Cerro Mackay',
      icon: Icons.landscape_outlined,
      longitude: -72.0773,
      latitude: -45.5879,
      zoom: 14.0,
    ),
  ];

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  MapboxMap? _mapboxMap;
  MapPlace _selectedPlace = _center;

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
  // LÓGICA
  // ===============================================================

  void _onMapCreated(MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;
  }

  /// Único punto de entrada para mover la cámara y actualizar el estado.
  Future<void> _goToPlace(MapPlace place) async {
    _searchFocus.unfocus();

    // Actualiza la UI de inmediato (feedback instantáneo).
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

  /// Al presionar "buscar" en el teclado, va al primer resultado.
  void _onSearchSubmitted(String _) {
    final results = _filteredPlaces;

    if (results.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se encontraron lugares')),
      );
      return;
    }

    _goToPlace(results.first);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {});
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
              cameraOptions: CameraOptions(
                center: Point(
                  coordinates: Position(_center.longitude, _center.latitude),
                ),
                zoom: _initialZoom,
              ),
              onMapCreated: _onMapCreated,
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
          Positioned(
            left: 16,
            bottom: 110,
            child: _buildSelectedLocationLabel(),
          ),
          Positioned(
            right: 20,
            bottom: 110,
            child: FloatingActionButton(
              heroTag: 'map_location_button',
              backgroundColor: AppTheme.primaryDark,
              tooltip: 'Centrar en Coyhaique',
              onPressed: () => _goToPlace(_center),
              // Ícono acorde a la acción real (no es GPS del usuario).
              child: const Icon(Icons.center_focus_strong, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ===============================================================
  // BUSCADOR
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
        // Solo reconstruye lo necesario (filtro + botón de limpiar).
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
  // INDICADOR DE UBICACIÓN SELECCIONADA
  // ===============================================================

  Widget _buildSelectedLocationLabel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.location_on, color: AppTheme.primaryDark, size: 18),
          const SizedBox(width: 6),
          Text(
            _selectedPlace.name,
            style: const TextStyle(
              color: AppTheme.primaryDark,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
