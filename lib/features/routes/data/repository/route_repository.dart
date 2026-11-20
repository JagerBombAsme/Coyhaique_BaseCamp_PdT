import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/route_dto.dart';

/// Rutas de aventura (HU-20).
///
/// Todavía no existe una fuente de datos de rutas: la pantalla muestra el
/// aviso «Próximamente». Cuando haya datos reales, `getRoutes` los leerá
/// desde Supabase. Hasta entonces devuelve una lista vacía y no consulta
/// ni registra nada.
class RouteRepository {
  RouteRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  // ignore: unused_field
  final SupabaseClient _client;

  Future<List<RouteDto>> getRoutes() async => const <RouteDto>[];
}
