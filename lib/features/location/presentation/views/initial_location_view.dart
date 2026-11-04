import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/language_provider.dart';
import '../../../../core/theme/basecamp_tokens.dart';
import '../../../../core/widgets/basecamp/bc_widgets.dart';

/// Punto de partida (HU-05): permitir la ubicación o partir desde
/// Coyhaique Centro. La foto ocupa la mitad superior.
///
/// «Usar mi ubicación» pide el permiso real de Android. La ubicación no se
/// guarda: el mapa y el planificador la leen cuando la necesitan para
/// calcular distancias.
class InitialLocationView extends ConsumerStatefulWidget {
  const InitialLocationView({super.key});

  @override
  ConsumerState<InitialLocationView> createState() =>
      _InitialLocationViewState();
}

enum _LocationIssue { serviceOff, denied, deniedForever }

class _InitialLocationViewState extends ConsumerState<InitialLocationView> {
  bool _isLoading = false;
  _LocationIssue? _issue;

  Future<void> _useMyLocation() async {
    setState(() {
      _isLoading = true;
      _issue = null;
    });

    _LocationIssue? issue;
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        issue = _LocationIssue.serviceOff;
      } else {
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.deniedForever) {
          issue = _LocationIssue.deniedForever;
        } else if (permission == LocationPermission.denied) {
          issue = _LocationIssue.denied;
        }
      }
    } catch (_) {
      issue = _LocationIssue.denied;
    }

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _issue = issue;
    });

    if (issue == null) context.go('/home');
  }

  void _continueFromCenter() => context.go('/home');

  /// Transporte desde el aeropuerto: transfer y arriendo de vehículos.
  void _airportTransport() {
    context.go('/home');
    context.push('/categories/transporte');
  }

  /// Transporte propio: ruta Aeropuerto Balmaceda → Plaza de Armas.
  void _airportRoute() => context.go('/map?ruta=aeropuerto');

  @override
  Widget build(BuildContext context) {
    final isSpanish = ref.watch(languageProvider).languageCode == 'es';
    final size = MediaQuery.sizeOf(context);
    final top = MediaQuery.paddingOf(context).top;
    final photoHeight = (size.height * 0.5).clamp(320.0, 480.0);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: BcColors.fog,
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // =================================================
              // MITAD SUPERIOR: FOTO
              // =================================================
              SizedBox(
                height: photoHeight,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const BcPhotoImage(
                      source: BcPhoto.montanistas,
                      alignment: Alignment(0.28, -0.2),
                    ),
                    const BcPhotoShade(from: 0.5, topShade: 0.4),
                    Positioned(
                      left: BcSpace.gutter,
                      top: top + 14,
                      child: BcCornerButton(
                        icon: Icons.arrow_back_rounded,
                        semanticLabel:
                            isSpanish ? 'Volver al acceso' : 'Back to access',
                        onTap: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/auth-gateway');
                          }
                        },
                      ),
                    ),
                    Positioned(
                      left: BcSpace.gutter,
                      right: BcSpace.gutter,
                      bottom: 22,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          BcTag(
                            isSpanish ? 'Punto de partida' : 'Starting point',
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Icon(
                                Icons.place_rounded,
                                size: 34,
                                color: BcColors.onPhoto,
                              ),
                              const SizedBox(width: 8),
                              Text('45°34′S', style: BcText.figure()),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    isSpanish
                                        ? 'COYHAIQUE\nCENTRO'
                                        : 'DOWNTOWN\nCOYHAIQUE',
                                    style:
                                        BcText.label(color: BcColors.onPhoto),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // =================================================
              // MITAD INFERIOR: DECISIÓN
              // =================================================
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    BcSpace.gutter,
                    24,
                    BcSpace.gutter,
                    24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          isSpanish
                              ? '¿DESDE DÓNDE\nPARTES?'
                              : 'WHERE DO YOU\nSTART FROM?',
                          style: BcText.display(40).copyWith(height: 0.98),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isSpanish
                            ? 'Activa tu ubicación para calcular distancias a atractivos y miradores, o parte desde el centro de Coyhaique.'
                            : 'Turn on your location to calculate distances to attractions and viewpoints, or start from downtown Coyhaique.',
                        style: BcText.body(),
                      ),
                      if (_issue != null) ...[
                        const SizedBox(height: 14),
                        _IssueMessage(issue: _issue!, isSpanish: isSpanish),
                      ],
                      const SizedBox(height: 18),
                      BcButton(
                        style: BcButtonStyle.ink,
                        icon: Icons.my_location_rounded,
                        label: isSpanish
                            ? 'Usar mi ubicación'
                            : 'Use my location',
                        isLoading: _isLoading,
                        onPressed: _useMyLocation,
                      ),
                      const SizedBox(height: 12),
                      BcButton(
                        style: BcButtonStyle.surface,
                        icon: Icons.location_city_rounded,
                        label: isSpanish
                            ? 'Continuar desde Coyhaique Centro'
                            : 'Continue from downtown Coyhaique',
                        onPressed: _isLoading ? null : _continueFromCenter,
                      ),
                      const SizedBox(height: 22),
                      Semantics(
                        header: true,
                        child: Text(
                          isSpanish
                              ? 'RECIÉN LLEGAS A AYSÉN'
                              : 'JUST ARRIVED IN AYSÉN',
                          style: BcText.label(color: BcColors.muted),
                        ),
                      ),
                      const SizedBox(height: 10),
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: BcInfoTile(
                                icon: Icons.flight_land_rounded,
                                dark: true,
                                title: isSpanish
                                    ? '¿Estás en el aeropuerto?'
                                    : 'Are you at the airport?',
                                subtitle: isSpanish
                                    ? 'Conoce cómo llegar: transfer y arriendo de vehículos'
                                    : 'See how to get there: transfers and car rental',
                                onTap: _isLoading ? null : _airportTransport,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: BcInfoTile(
                                icon: Icons.directions_car_rounded,
                                title: isSpanish
                                    ? '¿Viajas en transporte propio?'
                                    : 'Travelling with your own driver?',
                                subtitle: isSpanish
                                    ? 'Dale estas indicaciones a tu chofer: ruta del aeropuerto al centro de Coyhaique'
                                    : 'Give your driver these directions: route from the airport to downtown Coyhaique',
                                onTap: _isLoading ? null : _airportRoute,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          const Icon(
                            Icons.lock_rounded,
                            size: 18,
                            color: BcColors.glacierDeep,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isSpanish
                                  ? 'Tu ubicación solo se usa en el teléfono para calcular distancias.'
                                  : 'Your location is only used on the phone to calculate distances.',
                              style: BcText.caption(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Explica por qué no se pudo usar la ubicación y cómo resolverlo.
class _IssueMessage extends StatelessWidget {
  const _IssueMessage({required this.issue, required this.isSpanish});

  final _LocationIssue issue;
  final bool isSpanish;

  @override
  Widget build(BuildContext context) {
    final (text, action, onAction) = switch (issue) {
      _LocationIssue.serviceOff => (
          isSpanish
              ? 'La ubicación del teléfono está apagada. Actívala o continúa desde Coyhaique Centro.'
              : 'The phone location is off. Turn it on or continue from downtown Coyhaique.',
          isSpanish ? 'Activar ubicación' : 'Turn on location',
          Geolocator.openLocationSettings,
        ),
      _LocationIssue.deniedForever => (
          isSpanish
              ? 'El permiso de ubicación está bloqueado. Puedes activarlo en los ajustes de la aplicación.'
              : 'Location permission is blocked. You can enable it in the app settings.',
          isSpanish ? 'Abrir ajustes' : 'Open settings',
          Geolocator.openAppSettings,
        ),
      _LocationIssue.denied => (
          isSpanish
              ? 'No se dio permiso de ubicación. Puedes continuar desde Coyhaique Centro.'
              : 'Location permission was not granted. You can continue from downtown Coyhaique.',
          null,
          null,
        ),
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: BcColors.surface,
        borderRadius: BorderRadius.circular(BcRadius.tile),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_off_rounded, color: BcColors.ink),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: BcText.caption(color: BcColors.ink))),
          if (action != null && onAction != null)
            TextButton(
              onPressed: () => onAction(),
              style: TextButton.styleFrom(foregroundColor: BcColors.glacierDeep),
              child: Text(action),
            ),
        ],
      ),
    );
  }
}
