import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile_dto.dart';

class ProfileRepository {
  final SupabaseClient _client = Supabase.instance.client;
  static ProfileDto? _cachedProfile;

  Future<ProfileDto> getProfile() async {
    try {
      final user = _client.auth.currentUser;
      if (user != null) {
        final response = await _client
            .from('profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle();

        if (response != null) {
          _cachedProfile = ProfileDto.fromJson(response);
          return _cachedProfile!;
        }
      }

      final response = await _client
          .from('profiles')
          .select()
          .limit(1)
          .maybeSingle();

      if (response != null) {
        _cachedProfile = ProfileDto.fromJson(response);
        return _cachedProfile!;
      }
    } catch (_) {
      // Fallback a perfil en caché o predeterminado
    }

    return _cachedProfile ??
        const ProfileDto(
          id: 'local_user',
          fullName: 'Budiarti Ramlan',
          username: 'budiarti12',
          biography: 'Explorando las maravillas naturales de Coyhaique y la Patagonia.',
          language: 'es',
          role: 'Explorador',
          isVerified: true,
          city: 'Coyhaique',
          country: 'Chile',
        );
  }

  Future<void> updateProfile(ProfileDto profile) async {
    _cachedProfile = profile;
    try {
      await _client
          .from('profiles')
          .update(profile.toJson())
          .eq('id', profile.id);
    } catch (_) {
      // Guardado local en caso de estar offline o sin sesión remota
    }
  }
}