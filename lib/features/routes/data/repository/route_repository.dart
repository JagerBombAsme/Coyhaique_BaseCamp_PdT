import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter/foundation.dart';
import '../models/route_dto.dart';
class RouteRepository {
  final SupabaseClient _client;

  RouteRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;
  Future<List<RouteDto>> getRoutes() async {
    final response = await _client
        .from('places_v2')
        .select()
        .eq('kind', 'activity')
        .eq('is_active', true)
        .order('name_es');

    debugPrint('ACTIVIDADES SUPABASE: $response');

    return [];
  }

  Future<void> testActivities() async {
    final response = await _client
        .from('places_v2')
        .select()
        .eq('kind', 'activity')
        .eq('is_active', true)
        .order('name_es');

    debugPrint('ACTIVIDADES: $response');
  }
}
