import 'package:flutter/material.dart';

class CategoryModel {
  final String id;
  final String nombreEs;
  final String nombreEn;
  final String descripcionEs;
  final String descripcionEn;
  final IconData icon;
  final String route;

  const CategoryModel({
    required this.id,
    required this.nombreEs,
    required this.nombreEn,
    required this.descripcionEs,
    required this.descripcionEn,
    required this.icon,
    required this.route,
  });

  String getNombre(String language) {
    if (language == 'en') {
      return nombreEn.isEmpty ? nombreEs : nombreEn;
    }
    return nombreEs;
  }

  String getDescripcion(String language) {
    if (language == 'en') {
      return descripcionEn.isEmpty ? descripcionEs : descripcionEn;
    }
    return descripcionEs;
  }
}

const List<CategoryModel> homeCategories = [
  CategoryModel(
    id: 'gastronomia',
    nombreEs: 'Gastronomía',
    nombreEn: 'Gastronomy',
    descripcionEs: 'Sabores de la Patagonia',
    descripcionEn: 'Flavors of Patagonia',
    icon: Icons.restaurant,
    route: 'gastronomia',
  ),
  CategoryModel(
    id: 'alojamientos',
    nombreEs: 'Alojamiento',
    nombreEn: 'Accommodation',
    descripcionEs: 'Dónde quedarse en Coyhaique',
    descripcionEn: 'Where to stay in Coyhaique',
    icon: Icons.hotel,
    route: 'alojamientos',
  ),
  CategoryModel(
    id: 'cultura',
    nombreEs: 'Cultura',
    nombreEn: 'Culture',
    descripcionEs: 'Encuentro con la historia',
    descripcionEn: 'Encounter with history',
    icon: Icons.museum,
    route: 'cultura',
  ),
  CategoryModel(
    id: 'aventura',
    nombreEs: 'Rutas',
    nombreEn: 'Routes',
    descripcionEs: 'Adrenalina en la Patagonia',
    descripcionEn: 'Adrenaline in Patagonia',
    icon: Icons.directions_run,
    route: 'aventura',
  ),
  CategoryModel(
    id: 'transporte',
    nombreEs: 'Transporte',
    nombreEn: 'Transport',
    descripcionEs: 'Cómo moverse por la ciudad',
    descripcionEn: 'How to get around the city',
    icon: Icons.directions_bus,
    route: 'transporte',
  ),
  CategoryModel(
    id: 'naturaleza',
    nombreEs: 'Naturaleza y parques',
    nombreEn: 'Nature and parks',
    descripcionEs: 'Reservas y paisajes únicos',
    descripcionEn: 'Reserves and unique landscapes',
    icon: Icons.park,
    route: 'naturaleza',
  ),
];
