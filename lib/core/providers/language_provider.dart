import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageNotifier extends StateNotifier<Locale> {
  LanguageNotifier() : super(const Locale('es')) {
    _load();
  }

  static const String _key = 'language_code';

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_key);
      if (code != null && mounted) state = Locale(code);
    } catch (_) {
      // Sin preferencias: se usa español.
    }
  }

  void setLanguage(String languageCode) {
    state = Locale(languageCode);
    _save(languageCode);
  }

  Future<void> _save(String languageCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, languageCode);
    } catch (_) {
      // Si no se puede guardar, el cambio vale solo para esta sesión.
    }
  }
}

final languageProvider = StateNotifierProvider<LanguageNotifier, Locale>((ref) {
  return LanguageNotifier();
});
