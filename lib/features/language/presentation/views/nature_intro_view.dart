import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class NatureIntroView extends StatefulWidget {
  const NatureIntroView({super.key});

  @override
  State<NatureIntroView> createState() => _NatureIntroViewState();
}

class _NatureIntroViewState extends State<NatureIntroView>
    with SingleTickerProviderStateMixin {
  static const List<String> _natureImages = [
    'assets/images/cerro_castillo_laguna.jpg',
    'assets/images/ventisquero_queulat.jpg',
    'assets/images/catedral_de_marmol.jpg',
    'assets/images/cordon_divisadero.jpg',
    'assets/images/miradores_coyhaique.jpg',
  ];

  late final String _backgroundImage;

  // Parámetros del slider horizontal
  static const double _horizontalMargin = 28.0;
  static const double _trackHeight = 74.0;
  static const double _buttonSize = 58.0;
  static const double _trackPadding = 8.0;

  // Ancho disponible del riel, calculado a partir del ancho de pantalla
  double _trackWidth = 290.0;

  double _dragOffset = 0.0;
  bool _isCompleted = false;

  late final AnimationController _returnController;
  late Animation<double> _returnAnimation;

  double get _maxDragDistance =>
      _trackWidth - _buttonSize - (_trackPadding * 2);

  @override
  void initState() {
    super.initState();
    // Elección aleatoria entre las 5 imágenes cada vez que se abre la app
    _backgroundImage = _natureImages[Random().nextInt(_natureImages.length)];

    _returnController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 260),
        )..addListener(() {
          setState(() {
            _dragOffset = _returnAnimation.value;
          });
        });
  }

  @override
  void dispose() {
    _returnController.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_isCompleted) return;

    // Detener animación de retorno si estaba activa
    if (_returnController.isAnimating) {
      _returnController.stop();
    }

    setState(() {
      // Arrastre hacia la derecha (delta.dx positivo aumenta la distancia recorrida)
      _dragOffset += details.primaryDelta ?? 0.0;
      _dragOffset = _dragOffset.clamp(0.0, _maxDragDistance);
    });

    // Si llega al extremo mientras arrastra
    if (_dragOffset >= _maxDragDistance * 0.90) {
      _completeSlide();
    }
  }

  void _onDragEnd(DragEndDetails details) {
    if (_isCompleted) return;

    // Si superó el 70 % del recorrido o la velocidad hacia la derecha es alta
    final velocity = details.primaryVelocity ?? 0.0;
    if (_dragOffset >= _maxDragDistance * 0.70 || velocity > 500) {
      _completeSlide();
    } else {
      // Regresar el botón a la posición inicial (izquierda)
      _returnAnimation = Tween<double>(begin: _dragOffset, end: 0.0).animate(
        CurvedAnimation(parent: _returnController, curve: Curves.easeOutCubic),
      );
      _returnController.forward(from: 0.0);
    }
  }

  void _completeSlide() {
    if (_isCompleted) return;
    _isCompleted = true;

    HapticFeedback.mediumImpact();

    // Animar hasta el extremo derecho
    _returnAnimation = Tween<double>(begin: _dragOffset, end: _maxDragDistance)
        .animate(
          CurvedAnimation(parent: _returnController, curve: Curves.easeOutQuad),
        );
    _returnController.forward(from: 0.0).then((_) {
      if (!mounted) return;
      // Navegar a la pantalla de selección de idioma
      context.go('/language-selection');
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final topPadding = MediaQuery.paddingOf(context).top;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    // El riel ocupa el ancho de la pantalla menos los márgenes laterales
    _trackWidth = size.width - (_horizontalMargin * 2);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Imagen de fondo aleatoria
          Image.asset(
            _backgroundImage,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) => Container(
              color: const Color(0xFF1B2E24),
              child: const Center(
                child: Icon(
                  Icons.nature_rounded,
                  color: Colors.white24,
                  size: 80,
                ),
              ),
            ),
          ),

          // 2. Degradado sutil para legibilidad de tipografía y slider
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.35, 0.65, 1.0],
                colors: [
                  Colors.black.withValues(alpha: 0.45),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.20),
                  Colors.black.withValues(alpha: 0.55),
                ],
              ),
            ),
          ),

          // 3. Tipografía superior izquierda
          Positioned(
            top: topPadding + 44,
            left: 28,
            right: 28,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Explore\nPure\nNature',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                    height: 1.08,
                    letterSpacing: -0.8,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'WITH US',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.8,
                    color: Color(0xEEFFFFFF),
                  ),
                ),
              ],
            ),
          ),

          // 4. Slider horizontal en la parte inferior
          Positioned(
            bottom: bottomPadding + 36,
            left: _horizontalMargin,
            right: _horizontalMargin,
            child: _buildHorizontalSliderTrack(),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalSliderTrack() {
    final progress = _maxDragDistance <= 0
        ? 0.0
        : (_dragOffset / _maxDragDistance).clamp(0.0, 1.0);

    return Container(
      width: _trackWidth,
      height: _trackHeight,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(_trackHeight / 2),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.22),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_trackHeight / 2),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Stack(
            children: [
              // Indicador de doble flecha hacia la derecha, en el extremo derecho
              Positioned(
                right: _trackPadding + 18,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Opacity(
                    opacity: (1.0 - progress).clamp(0.2, 0.9),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.keyboard_arrow_right_rounded,
                          color: Colors.white70,
                          size: 22,
                        ),
                        Icon(
                          Icons.keyboard_arrow_right_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Botón circular deslizante "Go"
              Positioned(
                left: _trackPadding + _dragOffset,
                top: (_trackHeight - _buttonSize) / 2,
                child: GestureDetector(
                  onHorizontalDragUpdate: _onDragUpdate,
                  onHorizontalDragEnd: _onDragEnd,
                  onTap: _completeSlide,
                  child: Container(
                    width: _buttonSize,
                    height: _buttonSize,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Go',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E1E1E),
                        letterSpacing: -0.2,
                      ),
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
