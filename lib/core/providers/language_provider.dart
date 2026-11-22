import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Clave en SharedPreferences con el código del idioma elegido (es/en).
const String languageStorageKey = 'app_language';

/// true si el usuario ya eligió idioma en este teléfono. El composition root
/// (main.dart) lo define leyendo SharedPreferences antes de runApp; sin
/// override queda en false (primer uso).
final languageSavedProvider = Provider<bool>((ref) => false);

class LanguageNotifier extends StateNotifier<Locale> {
  LanguageNotifier({Locale? initial}) : super(initial ?? const Locale('es'));

  /// Cambia el idioma de la app y lo guarda en el teléfono para la próxima
  /// apertura.
  void setLanguage(String languageCode) {
    state = Locale(languageCode);
    _save(languageCode);
  }

  Future<void> _save(String languageCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(languageStorageKey, languageCode);
    } catch (_) {
      // Si no se puede guardar, el idioma vale solo para esta sesión.
    }
  }
}

final languageProvider = StateNotifierProvider<LanguageNotifier, Locale>((ref) {
  return LanguageNotifier();
});
