import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

/// Transición entre pantallas de toda la app: la pantalla nueva se desliza
/// desde la derecha y la anterior se corre un poco hacia la izquierda (efecto
/// de profundidad). Al volver ocurre al revés, y además se puede volver
/// arrastrando desde el borde izquierdo de la pantalla.
///
/// Se registra una sola vez en el tema (`pageTransitionsTheme`) y vale para
/// todas las rutas de go_router. Sin animación (y sin gesto) cuando el sistema
/// pide reducir el movimiento.
class BcPageTransitionsBuilder extends PageTransitionsBuilder {
  const BcPageTransitionsBuilder();

  static const PageTransitionsBuilder _slide = CupertinoPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return _slide.buildTransitions<T>(
      route,
      context,
      animation,
      secondaryAnimation,
      child,
    );
  }
}
