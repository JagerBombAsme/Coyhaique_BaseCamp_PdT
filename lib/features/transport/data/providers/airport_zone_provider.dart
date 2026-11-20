import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../domain/airport_zone.dart';

/// Zona del usuario según su ubicación, o null si no se puede saber
/// (GPS apagado, sin permiso o sin respuesta).
///
/// Nunca pide el permiso: solo usa la ubicación si ya fue concedida, para
/// no interrumpir el inicio con un diálogo.
final airportZoneProvider = FutureProvider.autoDispose<AirportZone?>((
  ref,
) async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) return null;

    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    Position? position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 8),
        ),
      );
    } catch (error) {
      debugPrint('Sin posición actual para el transfer: $error');
      position = await Geolocator.getLastKnownPosition();
    }
    if (position == null) return null;

    return AirportZones.classify(position.latitude, position.longitude);
  } catch (error) {
    debugPrint('No se pudo ubicar al usuario para el transfer: $error');
    return null;
  }
});
