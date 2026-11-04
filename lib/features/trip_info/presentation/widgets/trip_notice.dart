import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/language_provider.dart';
import '../../../home/presentation/widgets/home_visual_tokens.dart';
import '../../../home/presentation/widgets/pressable_scale.dart';

/// Ruta de la pantalla «Antes de tu viaje».
const String tripInfoRoute = '/trip-info';

/// Contexto en que se muestra el aviso (RNF-14).
enum TripNoticeKind { home, transport, route }

/// Aviso de uso seguro en forma de tarjeta flotante.
///
/// Se cierra solo a los 4 segundos o con el botón
/// «Entendido, quiero comenzar mi viaje», que va dentro de la tarjeta.
/// El botón «Información antes de tu viaje» abre la pantalla de prevención.
class TripNotice {
  TripNotice._();

  static const Duration autoClose = Duration(seconds: 4);

  static OverlayEntry? _current;

  /// Avisos ya mostrados en esta sesión (inicio y transporte se muestran una
  /// vez por sesión; el de ruta, cada vez que se genera una ruta).
  static final Set<TripNoticeKind> _shownThisSession = {};

  /// Muestra el aviso. Con [oncePerSession] no se repite en la misma sesión.
  static void show(
    BuildContext context, {
    required TripNoticeKind kind,
    bool oncePerSession = false,
  }) {
    if (oncePerSession && _shownThisSession.contains(kind)) return;
    _shownThisSession.add(kind);

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    final isSpanish = ProviderScope.containerOf(context, listen: false)
            .read(languageProvider)
            .languageCode ==
        'es';
    final router = GoRouter.of(context);

    hide();

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _TripNoticeCard(
        kind: kind,
        isSpanish: isSpanish,
        onClose: () => _remove(entry),
        onOpenInfo: () {
          _remove(entry);
          router.push(tripInfoRoute);
        },
      ),
    );

    _current = entry;
    overlay.insert(entry);
  }

  /// Cierra el aviso visible, si existe.
  static void hide() {
    final entry = _current;
    if (entry != null) _remove(entry);
  }

  static void _remove(OverlayEntry entry) {
    if (entry.mounted) entry.remove();
    if (identical(_current, entry)) _current = null;
  }
}

class _TripNoticeCard extends StatefulWidget {
  const _TripNoticeCard({
    required this.kind,
    required this.isSpanish,
    required this.onClose,
    required this.onOpenInfo,
  });

  final TripNoticeKind kind;
  final bool isSpanish;
  final VoidCallback onClose;
  final VoidCallback onOpenInfo;

  @override
  State<_TripNoticeCard> createState() => _TripNoticeCardState();
}

class _TripNoticeCardState extends State<_TripNoticeCard>
    with SingleTickerProviderStateMixin {
  static const Color _ink = Color(0xFF2E5F73);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
  )..forward();

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(TripNotice.autoClose, _close);
  }

  Future<void> _close() async {
    _timer?.cancel();
    if (!mounted) return;
    await _controller.reverse();
    widget.onClose();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  (String, String, IconData) _content() {
    final es = widget.isSpanish;
    switch (widget.kind) {
      case TripNoticeKind.home:
        return (
          es ? 'Antes de tu viaje' : 'Before your trip',
          es
              ? 'La información es referencial: confirma horarios y condiciones con cada lugar. Descarga la información antes de salir a zonas sin señal.'
              : 'Information is for reference only: confirm hours and conditions with each place. Download the information before going to areas without signal.',
          Icons.info_outline_rounded,
        );
      case TripNoticeKind.transport:
        return (
          es ? 'Transporte' : 'Transport',
          es
              ? 'Horarios y tarifas son referenciales y pueden cambiar. Confirma con cada empresa antes de viajar; la aplicación no hace reservas.'
              : 'Schedules and fares are for reference only and may change. Confirm with each company before travelling; the app does not make bookings.',
          Icons.directions_bus_rounded,
        );
      case TripNoticeKind.route:
        return (
          es ? 'Ruta referencial' : 'Reference route',
          es
              ? 'No manipules el teléfono mientras conduces. La ruta no considera el estado del camino, el clima ni los cierres.'
              : 'Do not handle your phone while driving. The route does not consider road conditions, weather or closures.',
          Icons.warning_amber_rounded,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final (title, message, icon) = _content();
    final es = widget.isSpanish;

    return Positioned(
      left: 16,
      right: 16,
      bottom: MediaQuery.paddingOf(context).bottom + 96,
      child: FadeTransition(
        opacity: _controller,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.15),
            end: Offset.zero,
          ).animate(_controller),
          child: Material(
            color: Colors.white,
            elevation: 10,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: _ink),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(message, style: const TextStyle(height: 1.35)),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () {
                        _timer?.cancel();
                        widget.onOpenInfo();
                      },
                      icon: const Icon(Icons.health_and_safety_rounded, size: 18),
                      label: Text(
                        es
                            ? 'Información antes de tu viaje'
                            : 'Information before your trip',
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  FilledButton(
                    onPressed: _close,
                    style: FilledButton.styleFrom(backgroundColor: _ink),
                    child: Text(
                      es
                          ? 'Entendido, quiero comenzar mi viaje'
                          : 'Got it, I want to start my trip',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Muestra un aviso al abrir una pantalla, una vez por sesión.
class TripNoticeOnOpen extends StatefulWidget {
  const TripNoticeOnOpen({
    super.key,
    required this.kind,
    required this.child,
    this.enabled = true,
  });

  final TripNoticeKind kind;
  final Widget child;
  final bool enabled;

  @override
  State<TripNoticeOnOpen> createState() => _TripNoticeOnOpenState();
}

class _TripNoticeOnOpenState extends State<TripNoticeOnOpen> {
  @override
  void initState() {
    super.initState();
    if (!widget.enabled) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      TripNotice.show(context, kind: widget.kind, oncePerSession: true);
    });
  }

  @override
  void dispose() {
    TripNotice.hide();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Acceso permanente a «Antes de tu viaje» desde el inicio.
class TripInfoEntryCard extends ConsumerWidget {
  const TripInfoEntryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final es = ref.watch(languageProvider).languageCode == 'es';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        HomeVisualTokens.sectionMargin,
        12,
        HomeVisualTokens.sectionMargin,
        0,
      ),
      child: PressableScale(
        onTap: () => context.push(tripInfoRoute),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: HomeVisualTokens.surface,
            borderRadius: BorderRadius.circular(HomeVisualTokens.cardRadius),
            boxShadow: HomeVisualTokens.softShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: HomeVisualTokens.iceBlue,
                  // Concéntrico con la tarjeta: 24 − 12 = 12.
                  borderRadius: BorderRadius.circular(
                    HomeVisualTokens.innerRadius(
                      HomeVisualTokens.cardRadius,
                      12,
                    ),
                  ),
                ),
                child: const Icon(
                  Icons.health_and_safety_outlined,
                  color: HomeVisualTokens.deepIce,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      es
                          ? 'Información antes de tu viaje'
                          : 'Information before your trip',
                      style: HomeVisualTokens.cardTitle.copyWith(fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      es
                          ? 'Emergencias, prevención, restricciones y transporte'
                          : 'Emergencies, safety, restrictions and transport',
                      style: HomeVisualTokens.caption.copyWith(fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                color: HomeVisualTokens.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
