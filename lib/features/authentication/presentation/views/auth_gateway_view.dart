import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/language_provider.dart';

/// Pantalla de acceso:
/// - Continuar como invitado
/// - Iniciar sesión
/// - Crear cuenta
class AuthGatewayView extends ConsumerWidget {
  const AuthGatewayView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(languageProvider);
    final isSpanish = locale.languageCode == 'es';

    return Scaffold(
      backgroundColor: AppTheme.slateLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          tooltip: isSpanish
              ? 'Volver al selector de idioma'
              : 'Back to language selector',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/onboarding');
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
                  padding: const EdgeInsets.all(18),
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryDark,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.explore_rounded,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Text(
                isSpanish
                    ? 'Explora Coyhaique a tu manera'
                    : 'Explore Coyhaique your way',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  height: 1.2,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                isSpanish
                    ? 'Inicia sesión para guardar tus itinerarios favoritos o explora directamente como invitado.'
                    : 'Log in to save your favorite itineraries, or explore directly as a guest.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),

              const Spacer(),

              // =====================================================
              // 1. CONTINUAR COMO INVITADO
              // =====================================================
              ElevatedButton(
                onPressed: () {
                  context.push('/initial-location');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryDark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  isSpanish ? 'Continuar como invitado' : 'Continue as guest',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // =====================================================
              // 2. INICIAR SESIÓN
              // =====================================================
              OutlinedButton(
                onPressed: () {
                  context.push('/auth');
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryDark,
                  side: const BorderSide(
                    color: AppTheme.primaryDark,
                    width: 1.5,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  isSpanish ? 'Iniciar sesión' : 'Sign In',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // =====================================================
              // 3. CREAR CUENTA
              // =====================================================
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isSpanish
                            ? 'El registro se implementará en el siguiente módulo.'
                            : 'Sign up will be implemented in the next module.',
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );

                  // Futuro:
                  // context.push('/register');
                },
                child: Text(
                  isSpanish
                      ? '¿No tienes cuenta? Regístrate'
                      : "Don't have an account? Sign up",
                  style: const TextStyle(
                    color: AppTheme.primaryDark,
                    fontWeight: FontWeight.w600,
                  ),
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
