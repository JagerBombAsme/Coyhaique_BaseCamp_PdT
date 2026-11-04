import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authUserProvider = StreamProvider<User?>((ref) async* {
  final client = Supabase.instance.client;

  // Estado actual al abrir la aplicación.
  yield client.auth.currentUser;

  // Cambios posteriores:
  // login, logout, recuperación de sesión, etc.
  await for (final authState in client.auth.onAuthStateChange) {
    yield authState.session?.user;
  }
});