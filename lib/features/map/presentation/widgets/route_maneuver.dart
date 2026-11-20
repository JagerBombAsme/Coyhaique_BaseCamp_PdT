import 'package:flutter/material.dart';

import '../../domain/route_step.dart';

/// Próxima maniobra lista para mostrar: icono, distancia y texto.
@immutable
class MapManeuver {
  const MapManeuver({
    required this.icon,
    required this.distanceLabel,
    required this.text,
    this.street,
  });

  /// Arma la maniobra a [meters] metros de distancia, en el idioma activo.
  factory MapManeuver.fromStep({
    required RouteStep step,
    required double meters,
    required bool isSpanish,
  }) {
    return MapManeuver(
      icon: _icon(step.type, step.modifier),
      distanceLabel: _distance(meters, isSpanish),
      text: _text(step.type, step.modifier, isSpanish),
      street: step.name.trim().isEmpty ? null : step.name.trim(),
    );
  }

  final IconData icon;
  final String distanceLabel;
  final String text;

  /// Calle a la que lleva la maniobra, si tiene nombre.
  final String? street;
}

String _distance(double meters, bool isSpanish) {
  if (meters < 20) return isSpanish ? 'Ahora' : 'Now';
  if (meters >= 1000) return '${(meters / 1000).toStringAsFixed(1)} km';
  // Redondeado a decenas: más legible que «237 m» mientras se conduce.
  return '${(meters / 10).round() * 10} m';
}

bool _isLeft(String? modifier) => modifier != null && modifier.contains('left');

bool _isRight(String? modifier) =>
    modifier != null && modifier.contains('right');

IconData _icon(String type, String? modifier) {
  switch (type) {
    case 'arrive':
      return Icons.flag_rounded;
    case 'roundabout':
    case 'rotary':
    case 'roundabout turn':
    case 'exit roundabout':
    case 'exit rotary':
      return _isLeft(modifier)
          ? Icons.roundabout_left_rounded
          : Icons.roundabout_right_rounded;
    case 'fork':
      return _isLeft(modifier)
          ? Icons.fork_left_rounded
          : Icons.fork_right_rounded;
    case 'merge':
      return Icons.merge_rounded;
  }
  switch (modifier) {
    case 'uturn':
      return Icons.u_turn_left_rounded;
    case 'sharp left':
      return Icons.turn_sharp_left_rounded;
    case 'sharp right':
      return Icons.turn_sharp_right_rounded;
    case 'slight left':
      return Icons.turn_slight_left_rounded;
    case 'slight right':
      return Icons.turn_slight_right_rounded;
    case 'left':
      return Icons.turn_left_rounded;
    case 'right':
      return Icons.turn_right_rounded;
  }
  return Icons.straight_rounded;
}

String _turn(String? modifier, bool es) {
  switch (modifier) {
    case 'uturn':
      return es ? 'Haz un cambio de sentido' : 'Make a U-turn';
    case 'sharp left':
      return es ? 'Gira cerrado a la izquierda' : 'Turn sharp left';
    case 'sharp right':
      return es ? 'Gira cerrado a la derecha' : 'Turn sharp right';
    case 'slight left':
      return es ? 'Gira ligeramente a la izquierda' : 'Turn slightly left';
    case 'slight right':
      return es ? 'Gira ligeramente a la derecha' : 'Turn slightly right';
    case 'left':
      return es ? 'Gira a la izquierda' : 'Turn left';
    case 'right':
      return es ? 'Gira a la derecha' : 'Turn right';
  }
  return es ? 'Sigue recto' : 'Continue straight';
}

String _lowerFirst(String text) =>
    text.isEmpty ? text : text[0].toLowerCase() + text.substring(1);

String _text(String type, String? modifier, bool es) {
  switch (type) {
    case 'arrive':
      if (_isLeft(modifier)) {
        return es
            ? 'Tu destino está a la izquierda'
            : 'Your destination is on the left';
      }
      if (_isRight(modifier)) {
        return es
            ? 'Tu destino está a la derecha'
            : 'Your destination is on the right';
      }
      return es ? 'Llegarás a tu destino' : 'You will reach your destination';
    case 'roundabout':
    case 'rotary':
    case 'roundabout turn':
      return es ? 'Entra en la rotonda' : 'Enter the roundabout';
    case 'exit roundabout':
    case 'exit rotary':
      return es ? 'Sal de la rotonda' : 'Exit the roundabout';
    case 'fork':
      if (_isLeft(modifier)) return es ? 'Mantente a la izquierda' : 'Keep left';
      if (_isRight(modifier)) return es ? 'Mantente a la derecha' : 'Keep right';
      return es ? 'Sigue recto' : 'Continue straight';
    case 'merge':
      return es ? 'Incorpórate' : 'Merge';
    case 'on ramp':
      return es ? 'Toma el acceso' : 'Take the ramp';
    case 'off ramp':
      return es ? 'Toma la salida' : 'Take the exit';
    case 'end of road':
      final prefix = es ? 'Al final de la calle, ' : 'At the end of the road, ';
      return '$prefix${_lowerFirst(_turn(modifier, es))}';
  }
  return _turn(modifier, es);
}
