import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Intereses declarados por el usuario (HU-21): identificadores de
/// categories_v2.
///
/// Se guardan solo en el teléfono (decisión del 27-10-2026). No se envían a
/// Supabase ni se infieren del comportamiento del usuario. Los usa la
/// propuesta de itinerario (HU-07) y, más adelante, la pantalla de inicio.
final interestsProvider =
    StateNotifierProvider<InterestsNotifier, Set<String>>((ref) {
  return InterestsNotifier();
});

class InterestsNotifier extends StateNotifier<Set<String>> {
  InterestsNotifier() : super(const {}) {
    _load();
  }

  static const String _key = 'declared_interests';

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(_key);
      if (saved != null && mounted) state = saved.toSet();
    } catch (_) {
      // Sin preferencias guardadas: se parte sin intereses.
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_key, state.toList()..sort());
    } catch (_) {
      // Si no se puede guardar, el cambio vale solo para esta sesión.
    }
  }

  void toggle(String categoryId) {
    final next = {...state};
    if (!next.remove(categoryId)) next.add(categoryId);
    state = next;
    _save();
  }

  void setAll(Set<String> categoryIds) {
    state = {...categoryIds};
    _save();
  }

  void clear() => setAll(const {});
}
