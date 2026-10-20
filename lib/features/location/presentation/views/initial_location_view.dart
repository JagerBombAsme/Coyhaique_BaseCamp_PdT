import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/language_provider.dart';

/// Pantalla de selección/detección de ubicación inicial (HU-05) según USER_FLOWS.md
class InitialLocationView extends ConsumerStatefulWidget {
  const InitialLocationView({super.key});

  @override
  ConsumerState<InitialLocationView> createState() => _InitialLocationViewState();
}

class _InitialLocationViewState extends ConsumerState<InitialLocationView> {
  bool _isLoading = false;

  void _requestGpsLocation() async {
    setState(() => _isLoading = true);
    // Simula detección de GPS respetando HU-05
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _isLoading = false);
    context.go('/home');
  }

  void _setManualLocation(String locationName) {
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(languageProvider);
    final isSpanish = locale.languageCode == 'es';

    return Scaffold(
      backgroundColor: AppTheme.slateLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          tooltip: isSpanish ? 'Volver al acceso' : 'Back to access',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/auth');
            }
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryDark.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    size: 56,
                    color: AppTheme.primaryDark,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isSpanish ? 'Ubicación para explorar' : 'Location to explore',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isSpanish
                    ? 'Activa tu GPS para calcular distancias a atractivos y miradores, o selecciona tu ubicación manualmente.'
                    : 'Enable GPS to calculate distances to attractions and viewpoints, or select your location manually.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
              const Spacer(),

              // Botón GPS
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _requestGpsLocation,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location),
                label: Text(
                  isSpanish ? 'Usar mi ubicación GPS' : 'Use my GPS location',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryDark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Botón Ubicación Manual (Coyhaique Centro por defecto)
              OutlinedButton(
                onPressed: () => _setManualLocation('Coyhaique Centro'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textPrimary,
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  isSpanish ? 'Continuar en Coyhaique Centro' : 'Continue at Downtown Coyhaique',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
