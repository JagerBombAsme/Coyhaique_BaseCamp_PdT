import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/activity_dto.dart';

class ActivityRepository {
  final SupabaseClient _client;

  ActivityRepository({
    SupabaseClient? client,
  }) : _client =
            client ?? Supabase.instance.client;

  Future<List<ActivityDto>> getActivities() async {
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
        .order('name_es');

    return response
        .map<ActivityDto>(
          (json) => ActivityDto.fromJson(
            Map<String, dynamic>.from(json),
          ),
        )
        .toList();
  }
}