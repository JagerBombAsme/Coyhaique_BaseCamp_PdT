import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/route_dto.dart';

class RouteRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<RouteDto>> getRoutes() async {
    try {
      final response = await _client.from('routes').select();
      final list = (response as List).map((json) => RouteDto.fromJson(json)).toList();
      if (list.isNotEmpty) return list;
    } catch (_) {
      // Fallback
    }
    return _getFallbackRoutes();
  }

  Future<RouteDto?> getRouteById(String id) async {
    try {
      final response = await _client
          .from('routes')
          .select()
          .eq('id', id)
          .single();
      return RouteDto.fromJson(response);
    } catch (_) {
      final list = _getFallbackRoutes();
      return list.firstWhere(
        (r) => r.id == id,
        orElse: () => list.first,
      );
    }
  }

  List<RouteDto> _getFallbackRoutes() {
    return const [
      RouteDto(
        id: '1',
        titleEs: 'Ruta Miradores de Coyhaique',
        titleEn: 'Coyhaique Viewpoints Route',
        descriptionEs: 'Descubre los mejores miradores urbanos y naturales de Coyhaique con vistas panorámicas increíbles.',
        descriptionEn: 'Discover the best urban and natural viewpoints of Coyhaique with incredible panoramic views.',
        duration: '2h 30m',
        difficultyEs: 'Baja',
        difficultyEn: 'Low',
        distanceKm: 5.2,
        imageUrl: 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=600&q=80',
      ),
      RouteDto(
        id: '2',
        titleEs: 'Sendero Los Leñeros',
        titleEn: 'Los Leñeros Trail',
        descriptionEs: 'Sendero corto con dos miradores hacia la ciudad de Coyhaique y río Simpson.',
        descriptionEn: 'Short trail with two viewpoints overlooking Coyhaique city and Simpson river.',
        duration: '1h 45m',
        difficultyEs: 'Baja',
        difficultyEn: 'Low',
        distanceKm: 3.8,
        imageUrl: 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?auto=format&fit=crop&w=600&q=80',
      ),
      RouteDto(
        id: '3',
        titleEs: 'Circuito 4 Lagunas',
        titleEn: '4 Lakes Circuit',
        descriptionEs: 'Recorrido completo que conecta Laguna Verde, Laguna Pato, Laguna Anibal Pinto y Laguna Toro.',
        descriptionEn: 'Full circuit connecting Verde, Pato, Anibal Pinto, and Toro lakes.',
        duration: '4h 00m',
        difficultyEs: 'Media',
        difficultyEn: 'Medium',
        distanceKm: 9.5,
        imageUrl: 'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?auto=format&fit=crop&w=600&q=80',
      ),
      RouteDto(
        id: '4',
        titleEs: 'Ascenso Cerro Cinchao',
        titleEn: 'Mount Cinchao Climb',
        descriptionEs: 'Desafío a la cima del cerro Cinchao (1.361 m) con vista panorámica a la cordillera patagónica.',
        descriptionEn: 'Challenge to Mount Cinchao summit (1,361 m) with panoramic view of the Patagonian range.',
        duration: '6h 00m',
        difficultyEs: 'Alta',
        difficultyEn: 'High',
        distanceKm: 14.0,
        imageUrl: 'https://images.unsplash.com/photo-1469854523086-cc02fe5d8800?auto=format&fit=crop&w=600&q=80',
      ),
    ];
  }
}
