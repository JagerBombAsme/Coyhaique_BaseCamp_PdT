import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/language_provider.dart';
import '../../../../core/theme/basecamp_tokens.dart';
import '../../../../core/widgets/basecamp/bc_widgets.dart';
import 'mapbox_directions_services.dart';

/// «¿Cómo quieres moverte?» (sistema «afiche de montaña»).
///
/// Pregunta si la persona anda a pie o en auto y devuelve el perfil de ruta
/// que el mapa va a calcular: [RouteProfile.walking] o
/// [RouteProfile.driving]. Si cierra sin elegir, no devuelve nada.
class TransportModeScreen extends ConsumerWidget {
  const TransportModeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final es = ref.watch(languageProvider).languageCode == 'es';
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: BcColors.fog,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            BcSpace.gutter,
            12,
            BcSpace.gutter,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // El contenido se desplaza si no cabe (letra grande o pantallas
              // bajas) en vez de desbordarse. La nota queda fija abajo.
              Expanded(
                child: SingleChildScrollView(
                  // Sin recorte: las tarjetas de ruta sobresalen con su sombra.
                  clipBehavior: Clip.none,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: BcCornerButton(
                          icon: Icons.arrow_back_rounded,
                          semanticLabel: es
                              ? 'Volver al mapa'
                              : 'Back to the map',
                          onTap: () => Navigator.of(context).pop(),
                        ),
                      ),
                      const SizedBox(height: 28),
                      BcTag(es ? 'Tu ruta' : 'Your route', lead: 'Coyhaique'),
                      const SizedBox(height: 14),
                      Semantics(
                        header: true,
                        child: Text(
                          es
                              ? '¿CÓMO QUIERES\nMOVERTE?'
                              : 'HOW WILL YOU\nGET AROUND?',
                          style: BcText.display(40).copyWith(height: 0.98),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        es
                            ? 'Elige cómo te vas a mover y te mostramos la ruta que corresponde a tu medio de transporte.'
                            : 'Choose how you will get around and we will show the route for your way of travelling.',
                        style: BcText.body(),
                      ),
                      const SizedBox(height: 26),
                      SizedBox(
                        height: BcTourCard.height,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          clipBehavior: Clip.none,
                          children: [
                            BcTourCard(
                              title: es ? 'A pie' : 'On foot',
                              image: BcPhoto.mountainHike,
                              tag: es ? 'Ruta a pie' : 'Walking route',
                              subtitle: es
                                  ? 'Plaza, senderos y miradores'
                                  : 'Plaza, trails and viewpoints',
                              onTap: () => Navigator.of(
                                context,
                              ).pop(RouteProfile.walking),
                            ),
                            const SizedBox(width: 12),
                            BcTourCard(
                              title: es ? 'En auto' : 'By car',
                              image: BcPhoto.cerroCastillo,
                              tag: es ? 'Ruta en auto' : 'Driving route',
                              subtitle: es
                                  ? 'Carretera y accesos a la ciudad'
                                  : 'Roads and access to town',
                              onTap: () => Navigator.of(
                                context,
                              ).pop(RouteProfile.driving),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 8, bottom: bottom + 20),
                child: Text(
                  es
                      ? 'Las rutas son referenciales: confirma el estado del camino y el clima antes de salir.'
                      : 'Routes are for reference only: check road and weather conditions before you leave.',
                  style: BcText.caption(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
