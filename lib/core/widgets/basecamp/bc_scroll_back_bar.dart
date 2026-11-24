import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/basecamp_tokens.dart';

/// Barra superior que aparece cuando una pantalla con foto de cabecera se
/// desplaza y el botón «Volver» de la foto sale de la vista.
///
/// Resuelve dos defectos de esas pantallas: el usuario se quedaba sin un
/// «Volver» visible y el texto pasaba por debajo de la barra de estado.
///
/// Uso:
/// ```dart
/// final collapsed = ValueNotifier(false);
/// Stack(children: [
///   NotificationListener<ScrollNotification>(
///     onNotification: (n) => bcTrackCollapse(n, collapsed, threshold),
///     child: CustomScrollView(...),
///   ),
///   BcScrollBackBar(visible: collapsed, title: 'Transfer', ...),
/// ]);
/// ```
class BcScrollBackBar extends StatelessWidget {
  const BcScrollBackBar({
    super.key,
    required this.visible,
    required this.title,
    required this.backLabel,
    required this.onBack,
  });

  final ValueListenable<bool> visible;
  final String title;
  final String backLabel;
  final VoidCallback onBack;

  /// Alto de la barra, sin contar la barra de estado.
  static const double height = 56;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: ValueListenableBuilder<bool>(
        valueListenable: visible,
        // Visible la barra es blanca: los íconos de la barra de estado pasan a
        // oscuros (sobre la foto de cabecera son claros y quedaban blanco
        // sobre blanco al bajar).
        builder: (context, show, _) => AnnotatedRegion<SystemUiOverlayStyle>(
          value: show
              ? SystemUiOverlayStyle.dark.copyWith(
                  statusBarColor: Colors.transparent,
                )
              : SystemUiOverlayStyle.light.copyWith(
                  statusBarColor: Colors.transparent,
                ),
          child: IgnorePointer(
          ignoring: !show,
          child: ExcludeSemantics(
            excluding: !show,
            child: AnimatedOpacity(
              opacity: show ? 1 : 0,
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 180),
              child: Material(
                color: BcColors.surface,
                elevation: 2,
                shadowColor: BcColors.ink.withValues(alpha: 0.2),
                child: Padding(
                  padding: EdgeInsets.only(top: top),
                  child: SizedBox(
                    height: height,
                    child: Row(
                      children: [
                        const SizedBox(width: BcSpace.s1),
                        IconButton(
                          tooltip: backLabel,
                          onPressed: onBack,
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: BcColors.ink,
                          ),
                        ),
                        const SizedBox(width: BcSpace.s1),
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: BcText.title().copyWith(fontSize: 17),
                          ),
                        ),
                        const SizedBox(width: BcSpace.s4),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        ),
      ),
    );
  }
}

/// Actualiza [collapsed] según cuánto se desplazó el contenido principal.
/// [threshold] es el desplazamiento desde el que la cabecera ya no se ve.
/// Devuelve false para no detener la notificación.
bool bcTrackCollapse(
  ScrollNotification notification,
  ValueNotifier<bool> collapsed,
  double threshold,
) {
  if (notification.depth != 0 ||
      notification.metrics.axis != Axis.vertical) {
    return false;
  }
  final next = notification.metrics.pixels > threshold;
  if (collapsed.value != next) collapsed.value = next;
  return false;
}

/// Envuelve el contenido desplazable de una pantalla con foto de cabecera y
/// muestra [BcScrollBackBar] cuando la cabecera sale de la vista. Para
/// pantallas sin estado propio.
class BcBackOnScroll extends StatefulWidget {
  const BcBackOnScroll({
    super.key,
    required this.collapseAt,
    required this.title,
    required this.backLabel,
    required this.onBack,
    required this.child,
  });

  /// Desplazamiento desde el que la cabecera ya no se ve.
  final double collapseAt;
  final String title;
  final String backLabel;
  final VoidCallback onBack;
  final Widget child;

  @override
  State<BcBackOnScroll> createState() => _BcBackOnScrollState();
}

class _BcBackOnScrollState extends State<BcBackOnScroll> {
  final ValueNotifier<bool> _collapsed = ValueNotifier(false);

  @override
  void dispose() {
    _collapsed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: (n) =>
              bcTrackCollapse(n, _collapsed, widget.collapseAt),
          child: widget.child,
        ),
        BcScrollBackBar(
          visible: _collapsed,
          title: widget.title,
          backLabel: widget.backLabel,
          onBack: widget.onBack,
        ),
      ],
    );
  }
}
