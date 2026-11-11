import 'package:shared_preferences/shared_preferences.dart';

/// Estado local del invitado: se guarda solo en el teléfono.
///
/// No hay cuenta ni token de sesión: basta con saber que el usuario eligió
/// «Continuar como invitado» y qué perfil animal eligió.
class GuestStore {
  GuestStore._();

  static const String _guestKey = 'guest_mode';
  static const String _animalKey = 'guest_animal';

  static Future<bool> isGuest() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_guestKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<String?> animal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_animalKey);
    } catch (_) {
      return null;
    }
  }

  static Future<void> markGuest() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_guestKey, true);
    } catch (_) {
      // Sin almacenamiento: el invitado sigue en esta sesión.
    }
  }

  static Future<void> setAnimal(String animalId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_animalKey, animalId);
    } catch (_) {
      // Sin almacenamiento: la elección vale solo para esta sesión.
    }
  }
}
