import 'package:flutter/material.dart';

class CategoryModel {
  final String id;
  final String nombreEs;
  final String nombreEn;
  final String descripcionEs;
  final String descripcionEn;
  final IconData icon;
  final String route;
  final String imageUrl;

  const CategoryModel({
    required this.id,
    required this.nombreEs,
    required this.nombreEn,
    required this.descripcionEs,
    required this.descripcionEn,
    required this.icon,
    required this.route,
    required this.imageUrl,
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
    descripcionEs: 'Sabores y asados de la Patagonia',
    descripcionEn: 'Flavors and roasts of Patagonia',
    icon: Icons.restaurant,
    route: 'gastronomia',
    imageUrl: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&w=600&q=80',
  ),
  CategoryModel(
    id: 'alojamientos',
    nombreEs: 'Alojamiento',
    nombreEn: 'Accommodation',
    descripcionEs: 'Dónde quedarse en Coyhaique',
    descripcionEn: 'Where to stay in Coyhaique',
    icon: Icons.hotel,
    route: 'alojamientos',
    imageUrl: 'https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=600&q=80',
  ),
  CategoryModel(
    id: 'cultura',
    nombreEs: 'Cultura y Museo',
    nombreEn: 'Culture & Museum',
    descripcionEs: 'Encuentro con la historia patagónica',
    descripcionEn: 'Encounter with Patagonian history',
    icon: Icons.museum,
    route: 'cultura',
    imageUrl: 'https://images.unsplash.com/photo-1565008447742-97f6f38c985c?auto=format&fit=crop&w=600&q=80',
  ),
  CategoryModel(
    id: 'aventura',
    nombreEs: 'Rutas de Aventura',
    nombreEn: 'Adventure Routes',
    descripcionEs: 'Senderos y miradores en la naturaleza',
    descripcionEn: 'Trails and viewpoints in nature',
    icon: Icons.directions_run,
    route: 'aventura',
    imageUrl: 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?auto=format&fit=crop&w=600&q=80',
  ),
  CategoryModel(
    id: 'transporte',
    nombreEs: 'Transporte',
    nombreEn: 'Transport',
    descripcionEs: 'Transfers y rutas por la región',
    descripcionEn: 'Transfers and routes around the region',
    icon: Icons.directions_bus,
    route: 'transporte',
    imageUrl: 'https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?auto=format&fit=crop&w=600&q=80',
  ),
  CategoryModel(
    id: 'naturaleza',
    nombreEs: 'Naturaleza y Parques',
    nombreEn: 'Nature & Parks',
    descripcionEs: 'Reservas y paisajes patagónicos',
    descripcionEn: 'Reserves and Patagonian landscapes',
    icon: Icons.park,
    route: 'naturaleza',
    imageUrl: 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=600&q=80',
  ),
];
