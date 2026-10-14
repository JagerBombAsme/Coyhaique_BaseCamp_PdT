import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/models/category_model.dart';
import '../models/place_dto.dart';

/// Repositorio de datos turísticos adaptado al modelo Supabase V2
/// según ANTIGRAVITY_AI_CONTEXT.md (tablas categories_v2, places_v2, place_media_v2)
class PlacesRepository {
  final SupabaseClient _client = Supabase.instance.client;

  /// Obtiene categorías activas desde categories_v2
  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await _client
          .from('categories_v2')
          .select()
          .eq('is_active', true)
          .order('name_es');

      final list = (response as List)
          .map((json) => CategoryModel.fromJson(json as Map<String, dynamic>))
          .toList();

      if (list.isNotEmpty) return list;
    } catch (_) {
      // Fallback local en caso de desconexión
    }
    return homeCategories;
  }

  /// Obtiene atractivos turísticos (places_v2 donde kind = 'place' y retired_at es null)
  Future<List<PlaceDto>> getPlaces() async {
    try {
      final response = await _client
          .from('places_v2')
          .select('''
            *,
            place_media_v2 (*),
            categories_v2 (*)
          ''')
          .eq('kind', 'place')
          .eq('is_active', true)
          .isFilter('retired_at', null)
          .order('name_es');

      final list = (response as List)
          .map((json) => PlaceDto.fromJson(json as Map<String, dynamic>))
          .toList();

      if (list.isNotEmpty) return list;
    } catch (_) {
      // Fallback a datos locales de contingencia
    }
    return _getFallbackPlaces().where((p) => p.kind == 'place').toList();
  }

  /// Obtiene actividades / tours (places_v2 donde kind = 'activity' y retired_at es null)
  Future<List<PlaceDto>> getActivities() async {
    try {
      final response = await _client
          .from('places_v2')
          .select('''
            *,
            place_media_v2 (*),
            categories_v2 (*)
          ''')
          .eq('kind', 'activity')
          .eq('is_active', true)
          .isFilter('retired_at', null)
          .order('name_es');

      final list = (response as List)
          .map((json) => PlaceDto.fromJson(json as Map<String, dynamic>))
          .toList();

      if (list.isNotEmpty) return list;
    } catch (_) {
      // Fallback
    }
    return _getFallbackPlaces().where((p) => p.kind == 'activity').toList();
  }

  /// Filtra lugares por category_id (UUID) o category_slug de compatibilidad
  Future<List<PlaceDto>> getPlacesByCategory(String categoryIdOrSlug) async {
    if (categoryIdOrSlug.isEmpty || categoryIdOrSlug == 'all' || categoryIdOrSlug == 'todos') {
      return getPlaces();
    }

    try {
      // Intentar primero por category_id exacto (UUID)
      final response = await _client
          .from('places_v2')
          .select('''
            *,
            place_media_v2 (*),
            categories_v2 (*)
          ''')
          .eq('category_id', categoryIdOrSlug)
          .eq('is_active', true)
          .isFilter('retired_at', null)
          .order('name_es');

      final list = (response as List)
          .map((json) => PlaceDto.fromJson(json as Map<String, dynamic>))
          .toList();

      if (list.isNotEmpty) return list;

      // Si no retornó por UUID, intentar por slug de categoría unida
      final allPlaces = await getPlaces();
      final filtered = allPlaces.where((p) =>
          p.categoryId == categoryIdOrSlug ||
          (p.categorySlug != null && p.categorySlug!.toLowerCase() == categoryIdOrSlug.toLowerCase()) ||
          (p.category != null && p.category!.slug.toLowerCase() == categoryIdOrSlug.toLowerCase())
      ).toList();

      if (filtered.isNotEmpty) return filtered;
    } catch (_) {
      // Fallback
    }

    return _getFallbackPlaces().where((p) =>
        p.categoryId == categoryIdOrSlug ||
        (p.categorySlug != null && p.categorySlug!.toLowerCase() == categoryIdOrSlug.toLowerCase())
    ).toList();
  }

  /// Obtiene detalle completo de un atractivo por ID (HU-02)
  Future<PlaceDto?> getPlaceById(String id) async {
    try {
      final response = await _client
          .from('places_v2')
          .select('''
            *,
            place_media_v2 (*),
            categories_v2 (*)
          ''')
          .eq('id', id)
          .eq('is_active', true)
          .isFilter('retired_at', null)
          .maybeSingle();

      if (response != null) {
        return PlaceDto.fromJson(response);
      }
    } catch (_) {
      // Fallback
    }

    final fallback = _getFallbackPlaces();
    return fallback.firstWhere(
      (p) => p.id == id,
      orElse: () => fallback.first,
    );
  }

  List<PlaceDto> _getFallbackPlaces() {
    return const [
      PlaceDto(
        id: 'gastro_1',
        categoryId: 'gastronomia',
        categorySlug: 'gastronomia',
        kind: 'place',
        titleEs: 'Restaurante El Fogón',
        titleEn: 'El Fogón Restaurant',
        subtitleEs: 'Coyhaique Centro',
        subtitleEn: 'Downtown Coyhaique',
        descriptionEs: 'Especialidad en asado al palo y carnes patagónicas tradicionales de la Región de Aysén.',
        descriptionEn: 'Specializing in spit roast and traditional Patagonian meats from the Aysén Region.',
        imageUrl: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&w=600&q=80',
        rating: 4.8,
        isFeatured: true,
      ),
      PlaceDto(
        id: 'aloj_1',
        categoryId: 'alojamientos',
        categorySlug: 'alojamientos',
        kind: 'place',
        titleEs: 'Lodge Valle Simpson',
        titleEn: 'Valle Simpson Lodge',
        subtitleEs: 'Sector El Blanco',
        subtitleEn: 'El Blanco Sector',
        descriptionEs: 'Cabañas equipadas rodeadas de naturaleza y ríos cristalinos.',
        descriptionEn: 'Fully equipped cabins surrounded by nature and crystal-clear rivers.',
        imageUrl: 'https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=600&q=80',
        rating: 4.9,
        isFeatured: true,
      ),
      PlaceDto(
        id: 'cult_1',
        categoryId: 'cultura',
        categorySlug: 'cultura',
        kind: 'place',
        titleEs: 'Museo Regional de Aysén',
        titleEn: 'Aysén Regional Museum',
        subtitleEs: 'Sector Escuela Agrícola',
        subtitleEn: 'Agricultural School Sector',
        descriptionEs: 'Patrimonio histórico e identidad pionera de la Región de Aysén.',
        descriptionEn: 'Historical heritage and pioneer identity of the Aysén Region.',
        imageUrl: 'https://images.unsplash.com/photo-1565008447742-97f6f38c985c?auto=format&fit=crop&w=600&q=80',
        rating: 4.7,
      ),
      PlaceDto(
        id: 'act_1',
        categoryId: 'aventura',
        categorySlug: 'aventura',
        kind: 'activity',
        titleEs: 'Trekking Reserva Nacional Coyhaique',
        titleEn: 'Coyhaique National Reserve Trekking',
        subtitleEs: 'Senderos Las Bandurrias',
        subtitleEn: 'Las Bandurrias Trails',
        descriptionEs: 'Recorrido guiado de 4 horas por senderos con vistas panorámicas al valle.',
        descriptionEn: '4-hour guided hike along scenic trails overlooking the valley.',
        imageUrl: 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?auto=format&fit=crop&w=600&q=80',
        rating: 4.9,
      ),
    ];
  }
}
