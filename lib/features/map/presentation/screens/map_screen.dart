import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../../../core/theme/app_theme.dart';
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final TextEditingController _searchController = TextEditingController();

  MapboxMap? _mapboxMap;

  String _selectedLocation = 'Coyhaique Centro';

  final List<Map<String, dynamic>> _quickLocations = [
    {
      'name': 'SERNATUR',
      'icon': Icons.info_outline,
    },
    {
      'name': 'Plaza de Armas',
      'icon': Icons.park_outlined,
    },
    {
      'name': 'Reserva Nacional',
      'icon': Icons.forest_outlined,
    },
    {
      'name': 'Cerro Mackay',
      'icon': Icons.landscape_outlined,
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // =====================================================
          // MAPBOX
          // =====================================================
          Positioned.fill(
            child: MapWidget(
              onMapCreated: (mapboxMap) {
                _mapboxMap = mapboxMap;
                mapboxMap.setCamera(
                  CameraOptions(
                    center: Point(
                      coordinates: Position(
                        -72.0683,
                        -45.5712,
                      ),
                    ),
                    zoom: 12.5,
                  ),
                );
              },
            ),
          ),

          // =====================================================
          // BUSCADOR Y ACCESOS RÁPIDOS
          // =====================================================
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: 0.10,
                          ),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText:
                            'Buscar destinos, servicios en el mapa...',
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppTheme.primaryDark,
                        ),
                        suffixIcon:
                            _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.clear,
                                    ),
                                    onPressed: () {
                                      _searchController.clear();

                                      setState(() {});
                                    },
                                  )
                                : null,
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                      ),
                      onChanged: (_) {
                        setState(() {});
                      },
                    ),
                  ),

                  const SizedBox(height: 12),

                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children:
                          _quickLocations.map((location) {
                        return Padding(
                          padding: const EdgeInsets.only(
                            right: 8.0,
                          ),
                          child: ActionChip(
                            avatar: Icon(
                              location['icon'] as IconData,
                              size: 18,
                              color: AppTheme.primaryDark,
                            ),
                            label: Text(
                              location['name'] as String,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            backgroundColor: Colors.white,
                            elevation: 2,
                            onPressed: () {
                              setState(() {
                                _selectedLocation =
                                    location['name']
                                        as String;
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // =====================================================
          // UBICACIÓN SELECCIONADA
          // =====================================================
          Positioned(
            left: 16,
            bottom: 110,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(
                  alpha: 0.92,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: 0.10,
                    ),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.location_on,
                    color: AppTheme.primaryDark,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _selectedLocation,
                    style: const TextStyle(
                      color: AppTheme.primaryDark,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // =====================================================
          // BOTÓN DE UBICACIÓN
          // =====================================================
          Positioned(
            bottom: 110,
            right: 20,
            child: FloatingActionButton(
              heroTag: 'map_location_button',
              backgroundColor: AppTheme.primaryDark,
              onPressed: _goToCoyhaiqueCenter,
              child: const Icon(
                Icons.my_location,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _goToCoyhaiqueCenter() async {
    final mapboxMap = _mapboxMap;

    if (mapboxMap == null) {
      return;
    }

    setState(() {
      _selectedLocation = 'Coyhaique Centro';
    });

    await mapboxMap.flyTo(
      CameraOptions(
        center: Point(
          coordinates: Position(
            -72.0683,
            -45.5712,
          ),
        ),
        zoom: 13,
      ),
      MapAnimationOptions(
        duration: 1000,
      ),
    );
  }
}