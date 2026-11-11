import 'package:flutter/material.dart';

import '../../../core/utils/text_normalizer.dart';

/// Lugar del mapa. El texto en ambos idiomas es obligatorio: un lugar sin
/// traducción no compila, así que el inglés nunca falta en la aplicación.
class MapPlace {
  const MapPlace({
    required this.nameEs,
    required this.nameEn,
    required this.descriptionEs,
    required this.descriptionEn,
    required this.icon,
    required this.longitude,
    required this.latitude,
    this.zoom = 15.0,
    this.verified = true,
    this.id,
  });

  final String nameEs;
  final String nameEn;
  final String descriptionEs;
  final String descriptionEn;
  final IconData icon;
  final double longitude;
  final double latitude;
  final double zoom;

  /// false = coordenadas aproximadas (sin marcador en el mapa y con aviso).

  final bool verified;
  final String? id;

  String name({required bool isSpanish}) => isSpanish ? nameEs : nameEn;

  String description({required bool isSpanish}) =>
      isSpanish ? descriptionEs : descriptionEn;

  /// Busca en ambos idiomas, sin distinguir mayúsculas ni tildes.
  bool matches(String query) {
    final term = normalizeForSearch(query);
    return normalizeForSearch(nameEs).contains(term) ||
        normalizeForSearch(nameEn).contains(term);
  }
}

abstract final class MapPlaces {
  static const MapPlace center = MapPlace(
    nameEs: 'Coyhaique Centro',
    nameEn: 'Downtown Coyhaique',
    descriptionEs: 'Centro de la ciudad, punto de partida para recorrer Aysén.',
    descriptionEn: 'City center and starting point for exploring Aysén.',
    icon: Icons.location_city,
    longitude: -72.068265,
    latitude: -45.571225,
    zoom: 13.0,
  );

  // Coordenadas de la ciudad: coinciden con la Plaza de Armas.
  // Es el punto de partida de las rutas.
  static const MapPlace plaza = MapPlace(
    nameEs: 'Plaza de Armas',
    nameEn: 'Plaza de Armas',
    descriptionEs:
        'Plaza pentagonal de la que parten 10 calles. Aquí está la feria artesanal.',
    descriptionEn:
        'Pentagonal main square where 10 streets begin. The craft market is here.',
    icon: Icons.park_outlined,
    longitude: -72.068265,
    latitude: -45.571225,
    zoom: 16.0,
  );

  // Aeropuerto Balmaceda (BBA), el principal de Aysén.
  // Wikipedia: 45°54′58″S 71°41′15″W. Está a ~50 km de la ciudad.
  // Si prefieres el aeródromo Teniente Vidal (a ~3 km al suroeste):
  //   latitude: -45.59444, longitude: -72.10667
  static const MapPlace airport = MapPlace(
    nameEs: 'Aeropuerto Balmaceda',
    nameEn: 'Balmaceda Airport',
    descriptionEs:
        'Principal aeropuerto de Aysén, a unos 50 km al sureste de Coyhaique. Vuelos a Santiago y Puerto Montt.',
    descriptionEn:
        'Main airport in Aysén, about 50 km southeast of Coyhaique. Flights to Santiago and Puerto Montt.',
    icon: Icons.flight,
    longitude: -71.68750,
    latitude: -45.91611,
    zoom: 12.5,
  );

  static const List<MapPlace> all = [
    plaza,
    // Centro de la reserva según Wikipedia (45°30′40″S 71°59′45″W).
    MapPlace(
      nameEs: 'Reserva Nacional',
      nameEn: 'National Reserve',
      descriptionEs:
          'Reserva creada en 1948, a menos de 5 km de la ciudad. Tiene lagunas como Laguna Verde y miradores hacia Coyhaique.',
      descriptionEn:
          'Reserve created in 1948, less than 5 km from the city. It has lakes such as Laguna Verde and viewpoints over Coyhaique.',
      icon: Icons.forest_outlined,
      longitude: -71.99583,
      latitude: -45.51111,
      zoom: 12.5,
    ),
    // Dirección confirmada por SERNATUR: Bulnes 35, a ~150 m de la plaza.
    MapPlace(
      nameEs: 'SERNATUR',
      nameEn: 'SERNATUR',
      descriptionEs:
          'Oficina de información turística (Bulnes 35). Pide mapas y consulta el estado de rutas y actividades.',
      descriptionEn:
          'Tourist information office (Bulnes 35). Ask for maps and check the status of routes and activities.',
      icon: Icons.info_outline,
      longitude: -72.06757009107555,
      latitude: -45.56999552963736,
      zoom: 16.5,
    ),
    // Cumbre de 1.205 m (Andeshandbook: 45°36′29.9″S 72°04′32.2″W).
    // Está al sur de la ciudad, a ~4 km del centro.
    MapPlace(
      nameEs: 'Cerro Mackay',
      nameEn: 'Cerro Mackay',
      descriptionEs:
          'La postal más reconocible de Coyhaique (1.205 m), al sur de la ciudad. Trekking y escalada. El acceso cruza terrenos privados: respeta cercos y propietarios.',
      descriptionEn:
          "Coyhaique's most recognizable landmark (1,205 m), south of the city. Trekking and climbing. Access crosses private land: respect fences and landowners.",
      icon: Icons.landscape_outlined,
      longitude: -72.075611,
      latitude: -45.608306,
      zoom: 13.5,
    ),
    airport,
  ];
}
