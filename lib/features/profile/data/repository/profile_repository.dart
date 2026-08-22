import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile_dto.dart';

class ProfileRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<ProfileDto> getProfile() async {
    final response = await _client
        .from('profiles')
        .select()
        .limit(1)
        .single();

    return ProfileDto.fromJson(response);
  }

  Future<void> updateProfile(ProfileDto profile) async {
    await _client
        .from('profiles')
        .update(profile.toJson())
        .eq('id', profile.id);
  }
}