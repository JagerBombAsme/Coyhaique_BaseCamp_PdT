import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile_dto.dart';

class ProfileRepository {
  final SupabaseClient _client;

  ProfileRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  ProfileDto? _cachedProfile;

  // ================================================================
  // OBTENER PERFIL
  // ================================================================

  Future<ProfileDto?> getProfile({required String userId}) async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      // El usuario existe en Auth, pero todavía no tiene
      // una fila de perfil creada.
      if (response == null) {
        return null;
      }

      final profile = ProfileDto.fromJson(response);

      _cachedProfile = profile;

      return profile;
    } catch (error) {
      // Solo utilizamos caché si pertenece al mismo usuario.
      if (_cachedProfile != null && _cachedProfile!.id == userId) {
        return _cachedProfile;
      }

      // Un error de red/backend NO debe confundirse
      // con "usuario sin cuenta".
      rethrow;
    }
  }

  // ================================================================
  // ACTUALIZAR PERFIL EXISTENTE
  // ================================================================

  Future<void> updateProfile({
    required String userId,
    required ProfileDto profile,
  }) async {
    if (profile.id != userId) {
      throw StateError('El perfil no corresponde al usuario autenticado.');
    }

    await _client.from('profiles').update(profile.toJson()).eq('id', userId);

    _cachedProfile = profile;
  }

  // ================================================================
  // CREAR O ACTUALIZAR PERFIL
  //
  // Lo utilizaremos posteriormente cuando construyamos
  // "Personaliza tu perfil".
  // ================================================================

  Future<void> upsertProfile({
    required String userId,
    required ProfileDto profile,
  }) async {
    if (profile.id != userId) {
      throw StateError('El perfil no corresponde al usuario autenticado.');
    }

    await _client.from('profiles').upsert(profile.toJson(), onConflict: 'id');

    _cachedProfile = profile;
  }

  // ================================================================
  // LIMPIAR CACHÉ
  // ================================================================

  void clearCache() {
    _cachedProfile = null;
  }
}
