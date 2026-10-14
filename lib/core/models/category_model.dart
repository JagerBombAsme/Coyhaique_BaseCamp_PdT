import 'package:flutter/material.dart';

/// Modelo de categoría adaptado para categories_v2 según ANTIGRAVITY_AI_CONTEXT.md
class CategoryModel {
  final String id;
  final String slug;
  final String nombreEs;
  final String? nombreEn;
  final String? descripcionEs;
  final String? descripcionEn;
  final String? groupType;
  final String? imageUrl;
  final IconData icon;
  final String route;
  final bool isActive;

  const CategoryModel({
    required this.id,
    required this.slug,
    required this.nombreEs,
    this.nombreEn,
    this.descripcionEs,
    this.descripcionEn,
    this.groupType,
    this.imageUrl,
    required this.icon,
    required this.route,
    this.isActive = true,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    final slug = json['slug']?.toString() ?? '';
    final groupType = json['group_type']?.toString();

    return CategoryModel(
      id: json['id']?.toString() ?? '',
      slug: slug,
      nombreEs: json['name_es'] ?? json['nombre_es'] ?? '',
      nombreEn: json['name_en'] ?? json['nombre_en'],
      descripcionEs: json['description_es'] ?? json['descripcion_es'],
      descripcionEn: json['description_en'] ?? json['descripcion_en'],
      groupType: groupType,
      imageUrl: json['image_url'],
      icon: _getIconForCategory(slug, groupType),
      route: slug,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'slug': slug,
      'name_es': nombreEs,
      'name_en': nombreEn,
      'description_es': descripcionEs,
      'description_en': descripcionEn,
      'group_type': groupType,
      'image_url': imageUrl,
      'is_active': isActive,
    };
  }

  String getNombre(String language) {
    if (language == 'en' && nombreEn != null && nombreEn!.isNotEmpty) {
      return nombreEn!;
    }
    return nombreEs;
  }

  String getDescripcion(String language) {
    if (language == 'en' && descripcionEn != null && descripcionEn!.isNotEmpty) {
      return descripcionEn!;
    }
    return descripcionEs ?? '';
  }

  static IconData _getIconForCategory(String slug, String? groupType) {
    final lower = '${slug.toLowerCase()} ${groupType?.toLowerCase() ?? ''}';
    if (lower.contains('gastro') || lower.contains('restauran') || lower.contains('bar') || lower.contains('cafe')) {
      return Icons.restaurant_rounded;
    }
    if (lower.contains('aloj') || lower.contains('hotel') || lower.contains('hostal') || lower.contains('cabana')) {
      return Icons.hotel_rounded;
    }
    if (lower.contains('cultur') || lower.contains('museo') || lower.contains('histor')) {
      return Icons.museum_rounded;
    }
    if (lower.contains('avent') || lower.contains('ruta') || lower.contains('sender') || lower.contains('trek')) {
      return Icons.directions_run_rounded;
    }
    if (lower.contains('transp') || lower.contains('transfer') || lower.contains('bus')) {
      return Icons.directions_bus_rounded;
    }
    if (lower.contains('natur') || lower.contains('parque') || lower.contains('reserva')) {
      return Icons.park_rounded;
    }
    return Icons.landscape_rounded;
  }
}

/// Fallback local en caso de desconexión temporal
const List<CategoryModel> homeCategories = [
  CategoryModel(
    id: 'gastronomia',
    slug: 'gastronomia',
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
    slug: 'alojamiento',
    nombreEs: 'Alojamiento',
    nombreEn: 'Accommodation',
    descripcionEs: 'Dónde quedarse en Coyhaique',
    descripcionEn: 'Where to stay in Coyhaique',
    icon: Icons.hotel,
    route: 'alojamiento',
    imageUrl: 'https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=600&q=80',
  ),
  CategoryModel(
    id: 'cultura',
    slug: 'cultura',
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
    slug: 'aventura',
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
    slug: 'transporte',
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
    slug: 'naturaleza',
    nombreEs: 'Naturaleza y Parques',
    nombreEn: 'Nature & Parks',
    descripcionEs: 'Reservas y paisajes patagónicos',
    descripcionEn: 'Reserves and Patagonian landscapes',
    icon: Icons.park,
    route: 'naturaleza',
    imageUrl: 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=600&q=80',
  ),
];
