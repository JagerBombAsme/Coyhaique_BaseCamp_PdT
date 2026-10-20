import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/route_dto.dart';

class RouteRepository {
  final SupabaseClient _client;

  RouteRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  Future<List<RouteDto>> getRoutes() async {
    final response = await _client.from('routes').select().order('title_es');

    return (response as List)
        .map((json) => RouteDto.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }
}
