import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/profile/data/models/profile_dto.dart';
import '../../features/profile/data/providers/profile_provider.dart';

import '../providers/auth/auth_user_provider.dart';
import '/core/theme/app_theme.dart';
import '../providers/language_provider.dart';

class HomeHeader extends ConsumerWidget {
  final VoidCallback onProfileClick;

  const HomeHeader({super.key, required this.onProfileClick});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(languageProvider);
    final isSpanish = locale.languageCode == 'es';

    final authUserAsync = ref.watch(authUserProvider);

    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 22),
      child: authUserAsync.when(
        // ============================================================
        // SESIÓN RESUELTA
        // ============================================================
        data: (user) {
          // ==========================================================
          // INVITADO
          // ==========================================================

          if (user == null) {
            return _buildHeader(
              isSpanish: isSpanish,
              title: isSpanish ? 'Hola, Explorador' : 'Hello, Explorer',
              subtitle: isSpanish ? 'Explora Coyhaique' : 'Explore Coyhaique',
              profile: null,
              onProfileClick: onProfileClick,
            );
          }

          // ==========================================================
          // USUARIO CON CUENTA
          // ==========================================================

          final profileAsync = ref.watch(profileProvider);

          return profileAsync.when(
            // ========================================================
            // PERFIL
            // ========================================================
            data: (profile) {
              // Cuenta creada pero todavía sin perfil personalizado.
              if (profile == null) {
                return _buildHeader(
                  isSpanish: isSpanish,
                  title: isSpanish ? 'Hola, Explorador' : 'Hello, Explorer',
                  subtitle: isSpanish ? 'Cuenta creada' : 'Account created',
                  profile: null,
                  onProfileClick: onProfileClick,
                );
              }

              return _buildHeader(
                isSpanish: isSpanish,
                title: _buildGreeting(profile, isSpanish),
                subtitle: profile.role.toUpperCase(),
                profile: profile,
                onProfileClick: onProfileClick,
              );
            },

            // ========================================================
            // CARGANDO PERFIL
            // ========================================================
            loading: () {
              return _buildHeader(
                isSpanish: isSpanish,
                title: isSpanish ? 'Hola, Explorador' : 'Hello, Explorer',
                subtitle: isSpanish
                    ? 'Cargando perfil...'
                    : 'Loading profile...',
                profile: null,
                onProfileClick: onProfileClick,
                loading: true,
              );
            },

            // ========================================================
            // ERROR DE PERFIL
            // ========================================================
            error: (error, stackTrace) {
              return _buildHeader(
                isSpanish: isSpanish,
                title: isSpanish ? 'Hola, Explorador' : 'Hello, Explorer',
                subtitle: 'Coyhaique BaseCamp',
                profile: null,
                onProfileClick: onProfileClick,
              );
            },
          );
        },

        // ============================================================
        // VERIFICANDO SESIÓN
        // ============================================================
        loading: () {
          return _buildHeader(
            isSpanish: isSpanish,
            title: isSpanish ? 'Hola, Explorador' : 'Hello, Explorer',
            subtitle: isSpanish ? 'Cargando...' : 'Loading...',
            profile: null,
            onProfileClick: onProfileClick,
            loading: true,
          );
        },

        // ============================================================
        // ERROR DE AUTENTICACIÓN
        // ============================================================
        error: (error, stackTrace) {
          return _buildHeader(
            isSpanish: isSpanish,
            title: isSpanish ? 'Hola, Visitante' : 'Hello, Visitor',
            subtitle: 'Coyhaique BaseCamp',
            profile: null,
            onProfileClick: onProfileClick,
          );
        },
      ),
    );
  }

  // =================================================================
  // HEADER
  // =================================================================

  Widget _buildHeader({
    required bool isSpanish,
    required String title,
    required String subtitle,
    required ProfileDto? profile,
    required VoidCallback onProfileClick,
    bool loading = false,
  }) {
    return Row(
      children: [
        // ============================================================
        // SALUDO
        // ============================================================
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.accentBlue,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 16),

        // ============================================================
        // AVATAR
        // ============================================================
        Semantics(
          button: true,
          label: isSpanish ? 'Abrir perfil' : 'Open profile',
          child: InkWell(
            onTap: onProfileClick,
            customBorder: const CircleBorder(),
            child: Container(
              width: 60,
              height: 60,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: loading ? _buildLoadingAvatar() : _buildAvatar(profile),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // =================================================================
  // SALUDO
  // =================================================================

  String _buildGreeting(ProfileDto profile, bool isSpanish) {
    final fullName = profile.fullName.trim();

    if (fullName.isEmpty) {
      return isSpanish ? 'Hola, Explorador' : 'Hello, Explorer';
    }

    final firstName = fullName.split(RegExp(r'\s+')).first;

    return isSpanish ? 'Hola, $firstName' : 'Hello, $firstName';
  }

  // =================================================================
  // AVATAR
  // =================================================================

  Widget _buildAvatar(ProfileDto? profile) {
    final avatarUrl = profile?.avatarUrl;

    if (avatarUrl == null || avatarUrl.trim().isEmpty) {
      return const CircleAvatar(
        backgroundColor: AppTheme.primaryDark,
        child: Icon(Icons.person, color: Colors.white, size: 28),
      );
    }

    return CachedNetworkImage(
      imageUrl: avatarUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) {
        return _buildLoadingAvatar();
      },
      errorWidget: (context, url, error) {
        return const CircleAvatar(
          backgroundColor: AppTheme.primaryDark,
          child: Icon(Icons.person, color: Colors.white, size: 28),
        );
      },
    );
  }

  Widget _buildLoadingAvatar() {
    return const CircleAvatar(
      backgroundColor: AppTheme.primaryDark,
      child: SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      ),
    );
  }
}
