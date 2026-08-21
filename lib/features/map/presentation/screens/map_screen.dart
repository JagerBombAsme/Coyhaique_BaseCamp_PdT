import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedLocation = 'Coyhaique Centro';

  final List<Map<String, dynamic>> _quickLocations = [
    {'name': 'SERNATUR', 'icon': Icons.info_outline, 'sub': 'Información Turística'},
    {'name': 'Plaza de Armas', 'icon': Icons.park_outlined, 'sub': 'Centro Urbano'},
    {'name': 'Reserva Nacional', 'icon': Icons.forest_outlined, 'sub': 'Naturaleza'},
    {'name': 'Cerro Mackay', 'icon': Icons.landscape_outlined, 'sub': 'Mirador'},
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
          // Interactive Map Simulation View
          Container(
            color: const Color(0xFFE5E9EC),
            width: double.infinity,
            height: double.infinity,
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.map,
                        size: 100,
                        color: Color(0xFFB0BEC5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Mapa Turístico de Coyhaique',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ubicación actual: $_selectedLocation',
                        style: const TextStyle(
                          color: AppTheme.primaryDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Simulated Pin Marker
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.45,
                  left: MediaQuery.of(context).size.width * 0.45,
                  child: const Column(
                    children: [
                      Icon(Icons.location_on, size: 48, color: Colors.redAccent),
                      Card(
                        elevation: 4,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Text(
                            'Coyhaique',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Top Search bar & quick chips
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Buscar destinos, servicios en el mapa...',
                        prefixIcon: const Icon(Icons.search, color: AppTheme.primaryDark),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _quickLocations.map((location) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ActionChip(
                            avatar: Icon(location['icon'] as IconData, size: 18, color: AppTheme.primaryDark),
                            label: Text(
                              location['name'] as String,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            backgroundColor: Colors.white,
                            elevation: 2,
                            onPressed: () {
                              setState(() {
                                _selectedLocation = location['name'] as String;
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
          // Floating location button
          Positioned(
            bottom: 30,
            right: 20,
            child: FloatingActionButton(
              backgroundColor: AppTheme.primaryDark,
              onPressed: () {
                setState(() {
                  _selectedLocation = 'Coyhaique Centro';
                });
              },
              child: const Icon(Icons.my_location, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
