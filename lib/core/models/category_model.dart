import 'package:flutter/material.dart';

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

  /// Categoría principal a la que pertenece (null en las principales).
  final String? parentId;

  /// Orden de presentación dentro de su nivel.
  final int sortOrder;

  bool get isMain => parentId == null;

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
    this.parentId,
    this.sortOrder = 0,
  });

  factory CategoryModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final slug = json['slug']?.toString() ?? '';
    final groupType =
        json['group_type']?.toString();

    return CategoryModel(
      id: json['id']?.toString() ?? '',
      slug: slug,
      nombreEs:
          json['name_es'] ??
          json['nombre_es'] ??
          '',
      nombreEn:
          json['name_en'] ??
          json['nombre_en'],
      descripcionEs:
          json['description_es'] ??
          json['descripcion_es'],
      descripcionEn:
          json['description_en'] ??
          json['descripcion_en'],
      groupType: groupType,
      imageUrl: json['image_url']?.toString(),
      icon: _getIconForCategory(
        slug,
        groupType,
      ),

      // Cada categoría conserva su propio slug.
      // El groupType se usa por separado
      // para agrupar categorías.
      route: slug,

      isActive:
          json['is_active'] as bool? ?? true,

      parentId: _nullableId(json['parent_id']),

      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
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
      'parent_id': parentId,
      'sort_order': sortOrder,
    };
  }

  static String? _nullableId(Object? value) {
    final text = value?.toString();
    if (text == null || text.isEmpty || text == 'null') return null;
    return text;
  }

  String get nameEs => nombreEs;

  String? get nameEn => nombreEn;

  String get name => nombreEs;

  String? get descriptionEs => descripcionEs;

  String? get descriptionEn => descripcionEn;

  String getNombre(String language) {
    if (language == 'en' &&
        nombreEn != null &&
        nombreEn!.trim().isNotEmpty) {
      return nombreEn!;
    }

    return nombreEs;
  }

  String getDescripcion(String language) {
    if (language == 'en' &&
        descripcionEn != null &&
        descripcionEn!.trim().isNotEmpty) {
      return descripcionEn!;
    }

    return descripcionEs ?? '';
  }

  static IconData _getIconForCategory(
    String slug,
    String? groupType,
  ) {
    final lower =
        '${slug.toLowerCase()} '
        '${groupType?.toLowerCase() ?? ''}';

    if (lower.contains('gastro') ||
        lower.contains('restauran') ||
        lower.contains('bar') ||
        lower.contains('cafe') ||
        lower.contains('cafeter')) {
      return Icons.restaurant_rounded;
    }

    if (lower.contains('aloj') ||
        lower.contains('hotel') ||
        lower.contains('hostal') ||
        lower.contains('cabana') ||
        lower.contains('cabaña') ||
        lower.contains('lodge')) {
      return Icons.hotel_rounded;
    }

    if (lower.contains('cultur') ||
        lower.contains('museo') ||
        lower.contains('histor')) {
      return Icons.museum_rounded;
    }

    if (lower.contains('avent') ||
        lower.contains('ruta') ||
        lower.contains('sender') ||
        lower.contains('trek') ||
        lower.contains('actividad') ||
        lower.contains('kayak') ||
        lower.contains('ciclismo')) {
      return Icons.directions_run_rounded;
    }

    if (lower.contains('transp') ||
        lower.contains('transfer') ||
        lower.contains('bus') ||
        lower.contains('rent')) {
      return Icons.directions_bus_rounded;
    }

    if (lower.contains('servicio') ||
        lower.contains('estacionamiento') ||
        lower.contains('estación')) {
      return Icons.miscellaneous_services_rounded;
    }

    if (lower.contains('natur') ||
        lower.contains('parque') ||
        lower.contains('reserva') ||
        lower.contains('mirador')) {
      return Icons.park_rounded;
    }

    return Icons.landscape_rounded;
  }
}

/// Datos locales únicamente como contingencia.
/// La fuente principal continúa siendo Supabase V2.
const List<CategoryModel> homeCategories = [
  CategoryModel(
    id: 'gastronomia',
    slug: 'gastronomia',
    nombreEs: 'Gastronomía',
    nombreEn: 'Gastronomy',
    descripcionEs:
        'Sabores y gastronomía de la Patagonia',
    descripcionEn:
        'Flavors and gastronomy of Patagonia',
    groupType: 'gastronomia',
    icon: Icons.restaurant,
    route: 'gastronomia',
    imageUrl:
        'https://images.unsplash.com/photo-1555396273-367ea4eb4db5'
        '?auto=format&fit=crop&w=600&q=80',
  ),
  CategoryModel(
    id: 'alojamiento',
    slug: 'alojamiento',
    nombreEs: 'Alojamiento',
    nombreEn: 'Accommodation',
    descripcionEs:
        'Dónde quedarse en Coyhaique',
    descripcionEn:
        'Where to stay in Coyhaique',
    groupType: 'alojamiento',
    icon: Icons.hotel,
    route: 'alojamiento',
    imageUrl:
        'https://images.unsplash.com/photo-1566073771259-6a8506099945'
        '?auto=format&fit=crop&w=600&q=80',
  ),
  CategoryModel(
    id: 'atractivo',
    slug: 'atractivo',
    nombreEs: 'Atractivos',
    nombreEn: 'Attractions',
    descripcionEs:
        'Lugares y atractivos turísticos',
    descripcionEn:
        'Tourist places and attractions',
    groupType: 'atractivo',
    icon: Icons.landscape,
    route: 'atractivo',
    imageUrl:
        'https://images.unsplash.com/photo-1506744038136-46273834b3fb'
        '?auto=format&fit=crop&w=600&q=80',
  ),
  CategoryModel(
    id: 'actividad',
    slug: 'actividad',
    nombreEs: 'Actividades',
    nombreEn: 'Activities',
    descripcionEs:
        'Tours y actividades en la Patagonia',
    descripcionEn:
        'Tours and activities in Patagonia',
    groupType: 'actividad',
    icon: Icons.directions_run,
    route: 'actividad',
    imageUrl:
        'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b'
        '?auto=format&fit=crop&w=600&q=80',
  ),
  CategoryModel(
    id: 'servicio',
    slug: 'servicio',
    nombreEs: 'Servicios',
    nombreEn: 'Services',
    descripcionEs:
        'Servicios útiles disponibles',
    descripcionEn:
        'Available useful services',
    groupType: 'servicio',
    icon: Icons.miscellaneous_services,
    route: 'servicio',
  ),
  CategoryModel(
    id: 'transporte',
    slug: 'transporte',
    nombreEs: 'Transporte',
    nombreEn: 'Transport',
    descripcionEs:
        'Opciones de transporte en la región',
    descripcionEn:
        'Transport options in the region',
    groupType: 'transporte',
    icon: Icons.directions_bus,
    route: 'transporte',
    imageUrl:
        'https://images.unsplash.com/photo-1544620347-c4fd4a3d5957'
        '?auto=format&fit=crop&w=600&q=80',
  ),
];