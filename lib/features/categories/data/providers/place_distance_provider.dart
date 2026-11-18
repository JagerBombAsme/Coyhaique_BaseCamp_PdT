import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

/// Origen de la distancia en la ficha: false = Plaza de Armas, true = ubicación.
class PlaceDistanceOriginNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setFromLocation(bool value) => state = value;
}

final placeDistanceOriginProvider =
    NotifierProvider<PlaceDistanceOriginNotifier, bool>(
  PlaceDistanceOriginNotifier.new,
);

/// Posición actual, o null si no hay servicio, permiso o respuesta.
final currentPositionProvider =
    FutureProvider.autoDispose<Position?>((ref) async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 10),
      ),
    );
  } catch (_) {
    return null;
  }
});