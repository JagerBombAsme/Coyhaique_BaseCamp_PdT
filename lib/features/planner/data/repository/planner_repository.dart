import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/planner_destination_dto.dart';

class PlannerRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<PlannerDestinationDto>> getDestinations() async {
    try {
      final response = await _client.from('destinations').select();
      final list = (response as List).map((json) => PlannerDestinationDto.fromJson(json)).toList();
      if (list.isNotEmpty) return list;
    } catch (_) {
      // Fallback
    }
    return _getFallbackDestinations();
  }

  List<PlannerDestinationDto> _getFallbackDestinations() {
    return const [
      PlannerDestinationDto(id: '1', name: 'Cerro Castillo', region: 'Aysén'),
      PlannerDestinationDto(id: '2', name: 'Reserva Nacional Coyhaique', region: 'Aysén'),
      PlannerDestinationDto(id: '3', name: 'Lago General Carrera', region: 'Aysén'),
      PlannerDestinationDto(id: '4', name: 'Puerto Chacabuco', region: 'Aysén'),
      PlannerDestinationDto(id: '5', name: 'Queulat & Ventisquero Colgante', region: 'Aysén'),
    ];
  }
}
