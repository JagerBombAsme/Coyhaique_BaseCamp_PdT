import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/place_dto.dart';

class PlacesRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<PlaceDto>> getPlaces() async {
    try {
      final response = await _client.from('places').select();
      final list = (response as List).map((json) => PlaceDto.fromJson(json)).toList();
      if (list.isNotEmpty) return list;
    } catch (_) {
      // Fallback to local default data if Supabase table is unreachable or empty
    }
    return _getFallbackPlaces();
  }

  Future<List<PlaceDto>> getPlacesByCategory(String categorySlug) async {
    try {
      final response = await _client
          .from('places')
          .select()
          .eq('category_slug', categorySlug);
      final list = (response as List).map((json) => PlaceDto.fromJson(json)).toList();
      if (list.isNotEmpty) return list;
    } catch (_) {
      // Fallback
    }
    return _getFallbackPlaces().where((p) => p.categorySlug == categorySlug || categorySlug == 'all').toList();
  }

  Future<PlaceDto?> getPlaceById(String id) async {
    try {
      final response = await _client
          .from('places')
          .select()
          .eq('id', id)
          .single();
      return PlaceDto.fromJson(response);
    } catch (_) {
      final fallback = _getFallbackPlaces();
      return fallback.firstWhere(
        (p) => p.id == id,
        orElse: () => fallback.first,
      );
    }
  }

  List<PlaceDto> _getFallbackPlaces() {
    return const [
      PlaceDto(
        id: 'gastro_1',
        categorySlug: 'gastronomia',
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
        id: 'gastro_2',
        categorySlug: 'gastronomia',
        titleEs: 'Café de la Plaza',
        titleEn: 'Plaza Café',
        subtitleEs: 'Plaza de Armas',
        subtitleEn: 'Main Square',
        descriptionEs: 'Repostería artesanal, chocolates y café de especialidad preparado por baristas locales.',
        descriptionEn: 'Artisanal pastries, chocolates and specialty coffee prepared by local baristas.',
        imageUrl: 'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?auto=format&fit=crop&w=600&q=80',
        rating: 4.6,
        isPopular: true,
      ),
      PlaceDto(
        id: 'aloj_1',
        categorySlug: 'alojamientos',
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
        categorySlug: 'cultura',
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
        id: 'trans_1',
        categorySlug: 'transporte',
        titleEs: 'Terminal de Buses Coyhaique',
        titleEn: 'Coyhaique Bus Terminal',
        subtitleEs: 'Av. O\'Higgins',
        subtitleEn: 'O\'Higgins Ave.',
        descriptionEs: 'Conexión terrestre a Puerto Aysén, Cerro Castillo, Cochrane y Balmaceda.',
        descriptionEn: 'Land connection to Puerto Aysén, Cerro Castillo, Cochrane and Balmaceda.',
        imageUrl: 'https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?auto=format&fit=crop&w=600&q=80',
      ),
    ];
  }
}
