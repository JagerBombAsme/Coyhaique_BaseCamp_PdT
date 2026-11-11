import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/providers/guest_profile.dart';
import '../../../../core/theme/basecamp_tokens.dart';
import '../../../../core/widgets/basecamp/bc_widgets.dart';

/// Pantalla de inicio (splash) con el logo BC sobre gris niebla.
///
/// Continúa con la que sigue en el flujo de inicio después de 1,6 s.
class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with SingleTickerProviderStateMixin {
  static const Duration _duration = Duration(milliseconds: 1600);

  late final AnimationController _controller =
      AnimationController(vsync: this, duration: _duration)..forward();

  late final Animation<double> _logoIn = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.45, curve: Curves.easeOutCubic),
  );

  late final Animation<double> _textIn = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
  );

  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(_duration);
    if (!mounted) return;

    // Quien ya entró como invitado o tiene sesión no vuelve a la bienvenida.
    final returning = await GuestStore.isGuest() || _hasSession();
    if (!mounted) return;

    context.go(returning ? '/home' : '/intro');
  }

  bool _hasSession() {
    try {
      return Supabase.instance.client.auth.currentSession != null;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: BcColors.fog,
        body: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 5),

              // Logo BC: aparece con un leve desplazamiento hacia arriba.
              Semantics(
                label: 'Coyhaique BaseCamp',
                image: true,
                child: AnimatedBuilder(
                  animation: _logoIn,
                  builder: (context, child) {
                    final t = reduceMotion ? 1.0 : _logoIn.value;
                    return Opacity(
                      opacity: t,
                      child: Transform.translate(
                        offset: Offset(0, 16 * (1 - t)),
                        child: child,
                      ),
                    );
                  },
                  child: Image.asset(
                    BcBrand.logoInk,
                    width: (width * 0.62).clamp(180.0, 320.0),
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              FadeTransition(
                opacity: reduceMotion ? const AlwaysStoppedAnimation(1) : _textIn,
                child: Column(
                  children: [
                    Text(
                      'COYHAIQUE BASECAMP',
                      textAlign: TextAlign.center,
                      style: BcText.display(26),
                    ),
                    const SizedBox(height: 12),
                    const BcTag(
                      'Patagonia',
                      lead: 'Aysén',
                      style: BcTagStyle.ink,
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 6),

              // Avance de la carga, en el acento glaciar.
              Padding(
                padding: const EdgeInsets.fromLTRB(80, 0, 80, 32),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) => LinearProgressIndicator(
                      value: _controller.value,
                      minHeight: 3,
                      color: BcColors.glacierDeep,
                      backgroundColor: BcColors.line,
                    ),
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
