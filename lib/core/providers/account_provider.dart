import 'package:flutter_riverpod/flutter_riverpod.dart';

/// TEMPORAL.
///
/// Este provider debe ser reemplazado posteriormente por el estado
/// real de autenticación de la aplicación.
///
/// true  = usuario con cuenta
/// false = usuario invitado / sin cuenta
final hasAccountProvider = StateProvider<bool>((ref) {
  return false;
});