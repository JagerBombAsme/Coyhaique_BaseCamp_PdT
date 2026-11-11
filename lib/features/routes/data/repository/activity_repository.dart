import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/local/catalog_local_db.dart';
import '../models/activity_dto.dart';


/// [CatalogUnavailableException].
class ActivityRepository {
  ActivityRepository({
    SupabaseClient? client,
    CatalogLocalDb? localDb,
  })  : _client = client ?? Supabase.instance.client,
        _localDb = localDb ?? CatalogLocalDb.instance;

  final SupabaseClient _client;
  final CatalogLocalDb _localDb;

  static const Duration _timeout = Duration(seconds: 15);

  Future<List<ActivityDto>> getActivities() async {
    try {
      final response = await _client
          .from('places_v2')
          .select('''
            id,
            category_id,
            kind,
            name_es,
            name_en,
            description_es,
            description_en,
            meeting_point,
            latitude,
            longitude,
            schedule,
            reference_price,
            contact_info,
            website_url,
            image_url,
            is_active
          ''')
          .eq('kind', 'activity')
          .eq('is_active', true)
          .isFilter('retired_at', null)
          .order('name_es')
          .timeout(_timeout);

      return response
          .map<ActivityDto>(
            (json) => ActivityDto.fromJson(Map<String, dynamic>.from(json)),
          )
          .toList();
    } catch (_) {
      if (!await _localDb.hasData()) {
        throw const CatalogUnavailableException();
      }
      final rows = await _localDb.getPlaces(kind: 'activity');
      return rows.map(ActivityDto.fromJson).toList();
    }
  }
}
