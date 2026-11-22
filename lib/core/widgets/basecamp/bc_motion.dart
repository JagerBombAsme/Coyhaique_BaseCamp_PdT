import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Tiempos y curvas del movimiento de la app. Un solo lugar para que todas
/// las animaciones se sientan parte del mismo sistema.
abstract final class BcMotion {
  /// Salidas y cambios pequeños.
  static const Duration fast = Duration(milliseconds: 180);

  /// Entradas y cambios de estado habituales.
  static const Duration base = Duration(milliseconds: 320);

  /// Retraso entre un elemento y el siguiente en una entrada escalonada.
  static const Duration stagger = Duration(milliseconds: 45);

  /// Solo los primeros elementos se escalonan: lo que está fuera de la
  /// pantalla no necesita animarse y una lista larga no se vuelve lenta.
  static const int maxStaggered = 8;

  /// Entrar: arranca rápido y se asienta (se siente «ligero»).
  static const Curve enter = Curves.easeOutCubic;

  /// Salir: arranca despacio y acelera, como algo que se va.
  static const Curve exit = Curves.easeInCubic;
}

/// Entrada de un elemento de lista: aparece con un fundido y sube un poco.
/// Con [index] los elementos entran uno tras otro. No anima cuando el sistema
/// pide reducir el movimiento ni pasado [BcMotion.maxStaggered].
///
/// Si la lista cambia de contenido (por ejemplo, al filtrar), da a este
/// widget una `key` propia de cada elemento para que los nuevos entren.
class BcEntrance extends StatelessWidget {
  const BcEntrance({
    super.key,
    required this.child,
    this.index = 0,
    this.offset = const Offset(0, 0.08),
  });

  final Widget child;

  /// Posición del elemento en la lista; define su retraso.
  final int index;

  /// Desplazamiento inicial, como fracción del tamaño del elemento.
  final Offset offset;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context) ||
        index >= BcMotion.maxStaggered) {
      return child;
    }

    return child
        .animate(delay: BcMotion.stagger * index)
        .fadeIn(duration: BcMotion.base, curve: BcMotion.enter)
        .slide(
          begin: offset,
          end: Offset.zero,
          duration: BcMotion.base,
          curve: BcMotion.enter,
        );
  }
}

/// Cambia un grupo de botones o paneles por otro: el que sale se desliza y se
/// desvanece, el que entra llega con el mismo gesto. Cada hijo debe tener una
/// `key` distinta para que se note el cambio.
///
/// [offset] es hacia dónde se van y desde dónde llegan, como fracción del
/// tamaño del hijo (por ejemplo `Offset(0, -0.25)` = hacia arriba). La salida
/// es más corta que la entrada. Sin animación si el sistema pide reducir el
/// movimiento.
class BcSwitcher extends StatelessWidget {
  const BcSwitcher({
    super.key,
    required this.child,
    this.offset = const Offset(0, 0.15),
    this.alignment = Alignment.topCenter,
    this.animateSize = true,
  });

  final Widget child;
  final Offset offset;

  /// Hacia dónde se alinean los hijos mientras uno sale y otro entra.
  final AlignmentGeometry alignment;

  /// Anima también el alto, para que lo que está debajo no salte cuando los
  /// dos grupos miden distinto.
  final bool animateSize;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    final switcher = AnimatedSwitcher(
      duration: reduceMotion ? Duration.zero : BcMotion.base,
      reverseDuration: reduceMotion ? Duration.zero : BcMotion.fast,
      switchInCurve: BcMotion.enter,
      switchOutCurve: BcMotion.exit,
      layoutBuilder: (current, previous) => Stack(
        alignment: alignment,
        children: [...previous, if (current != null) current],
      ),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(begin: offset, end: Offset.zero)
              .animate(animation),
          child: child,
        ),
      ),
      child: child,
    );

    if (!animateSize || reduceMotion) return switcher;
    return AnimatedSize(
      duration: BcMotion.base,
      curve: BcMotion.enter,
      alignment: alignment,
      child: switcher,
    );
  }
}
