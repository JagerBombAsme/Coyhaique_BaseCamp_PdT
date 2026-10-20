import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/providers/auth/auth_user_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/language_provider.dart';

import '../../data/models/profile_dto.dart';
import '../../data/providers/profile_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(languageProvider);
    final isSpanish = locale.languageCode == 'es';

    final authUserAsync = ref.watch(authUserProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: authUserAsync.when(
          data: (user) {
            // =========================================================
            // INVITADO
            // =========================================================

            if (user == null) {
              return _buildGuestProfile(context, isSpanish);
            }

            // =========================================================
            // USUARIO AUTENTICADO
            // =========================================================

            final profileAsync = ref.watch(profileProvider);

            return profileAsync.when(
              data: (profile) {
                // Cuenta creada, pero todavía sin perfil.
                if (profile == null) {
                  return _buildAccountWithoutProfile(context, user, isSpanish);
                }

                // Cuenta + perfil.
                return _buildProfileContent(context, ref, profile, isSpanish);
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryDark),
              ),
              error: (error, stackTrace) {
                return _buildErrorWidget(context, ref, error, isSpanish);
              },
            );
          },

          loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryDark),
          ),

          error: (error, stackTrace) {
            return _buildAuthErrorWidget(error, isSpanish);
          },
        ),
      ),
    );
  }

  // =================================================================
  // INVITADO
  // =================================================================

  Widget _buildGuestProfile(BuildContext context, bool isSpanish) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        children: [
          _buildHeader(context, isSpanish, showSettings: false),

          const SizedBox(height: 10),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: _mainCardDecoration(),
            child: Column(
              children: [
                _defaultAvatar(),

                const SizedBox(height: 16),

                Text(
                  isSpanish ? 'Explorador invitado' : 'Guest explorer',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  isSpanish
                      ? 'Puedes explorar Coyhaique sin crear una cuenta. Para personalizar tu perfil debes registrarte.'
                      : 'You can explore Coyhaique without creating an account. To personalize your profile, you need to register.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: AppTheme.textSecondary,
                  ),
                ),

                const SizedBox(height: 24),

                _buildActionButtons(
                  context,
                  isSpanish,
                  onPersonalize: () {
                    _showAccountRequiredDialog(context, isSpanish);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.language,
                  label: isSpanish ? 'Idioma' : 'Language',
                  value: isSpanish ? 'Español' : 'English',
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: _buildInfoCard(
                  icon: Icons.person_outline_rounded,
                  label: isSpanish ? 'Cuenta' : 'Account',
                  value: isSpanish ? 'Sin cuenta' : 'No account',
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _buildBaseCampBanner(isSpanish),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // =================================================================
  // CUENTA EXISTENTE, PERO SIN PERFIL
  // =================================================================

  Widget _buildAccountWithoutProfile(
    BuildContext context,
    User user,
    bool isSpanish,
  ) {
    final email = user.email?.trim();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        children: [
          // IMPORTANTE:
          // Usuario autenticado => sí tiene configuración.
          _buildHeader(context, isSpanish, showSettings: true),

          const SizedBox(height: 10),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: _mainCardDecoration(),
            child: Column(
              children: [
                _defaultAvatar(),

                const SizedBox(height: 16),

                Text(
                  isSpanish ? 'Tu cuenta está creada' : 'Your account is ready',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),

                if (email != null && email.isNotEmpty) ...[
                  const SizedBox(height: 6),

                  Text(
                    email,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],

                const SizedBox(height: 10),

                Text(
                  isSpanish
                      ? 'Ahora puedes personalizar tu perfil.'
                      : 'You can now personalize your profile.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: AppTheme.textSecondary,
                  ),
                ),

                const SizedBox(height: 24),

                _buildActionButtons(
                  context,
                  isSpanish,
                  onPersonalize: () {
                    context.push('/profile/edit');
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.language,
                  label: isSpanish ? 'Idioma' : 'Language',
                  value: isSpanish ? 'Español' : 'English',
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: _buildInfoCard(
                  icon: Icons.check_circle_outline,
                  label: isSpanish ? 'Cuenta' : 'Account',
                  value: isSpanish ? 'Creada' : 'Created',
                  active: true,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _buildBaseCampBanner(isSpanish),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // =================================================================
  // PERFIL REAL
  // =================================================================

  Widget _buildProfileContent(
    BuildContext context,
    WidgetRef ref,
    ProfileDto profile,
    bool isSpanish,
  ) {
    final locationText = [
      if (profile.city != null && profile.city!.isNotEmpty) profile.city!,
      if (profile.country != null && profile.country!.isNotEmpty)
        profile.country!,
    ].join(', ');

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(profileProvider);
      },
      color: AppTheme.primaryDark,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          children: [
            _buildHeader(context, isSpanish, showSettings: true),

            const SizedBox(height: 10),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: _mainCardDecoration(),
              child: Column(
                children: [
                  _buildAvatar(profile),

                  const SizedBox(height: 16),

                  // ==================================================
                  // NOMBRE
                  // ==================================================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          profile.fullName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),

                      if (profile.isVerified) ...[
                        const SizedBox(width: 6),

                        const Icon(
                          Icons.check_circle,
                          color: Color(0xFF42A5F5),
                          size: 20,
                        ),
                      ],
                    ],
                  ),

                  // ==================================================
                  // USERNAME
                  // ==================================================
                  if (profile.username != null &&
                      profile.username!.isNotEmpty) ...[
                    const SizedBox(height: 4),

                    Text(
                      '@${profile.username}',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // ==================================================
                  // ROL Y UBICACIÓN
                  // ==================================================
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.accentLightBlue,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          profile.role.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.accentBlue,
                          ),
                        ),
                      ),

                      if (locationText.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: AppTheme.textSecondary,
                              ),

                              const SizedBox(width: 4),

                              Flexible(
                                child: Text(
                                  locationText,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),

                  // ==================================================
                  // BIO
                  // ==================================================
                  if (profile.biography != null &&
                      profile.biography!.isNotEmpty) ...[
                    const SizedBox(height: 14),

                    Text(
                      profile.biography!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  _buildActionButtons(
                    context,
                    isSpanish,
                    onPersonalize: () {
                      context.push('/profile/edit');
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    icon: Icons.language,
                    label: isSpanish ? 'Idioma' : 'Language',
                    value: isSpanish ? 'Español' : 'English',
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: _buildInfoCard(
                    icon: Icons.check_circle_outline,
                    label: isSpanish ? 'Cuenta' : 'Account',
                    value: isSpanish ? 'Creada' : 'Created',
                    active: true,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            _buildBaseCampBanner(isSpanish),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // =================================================================
  // HEADER
  // =================================================================

  Widget _buildHeader(
    BuildContext context,
    bool isSpanish, {
    required bool showSettings,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          isSpanish ? 'Mi perfil' : 'My profile',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),

        if (showSettings)
          IconButton(
            icon: const Icon(
              Icons.settings_outlined,
              color: AppTheme.textPrimary,
            ),
            tooltip: isSpanish ? 'Configuración' : 'Settings',
            onPressed: () {
              context.push('/profile/edit');
            },
          )
        else
          const SizedBox(width: 48, height: 48),
      ],
    );
  }

  // =================================================================
  // BOTONES PRINCIPALES
  // =================================================================

  Widget _buildActionButtons(
    BuildContext context,
    bool isSpanish, {
    required VoidCallback onPersonalize,
  }) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 48,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                side: const BorderSide(color: AppTheme.primaryDark),
              ),
              onPressed: onPersonalize,
              child: Text(
                isSpanish
                    ? 'Personaliza tu perfil'
                    : 'Personalize your profile',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.primaryDark,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: SizedBox(
            height: 48,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                side: const BorderSide(color: AppTheme.primaryDark),
              ),
              onPressed: () {
                context.push('/profile/language');
              },
              child: Text(
                isSpanish ? 'Elige un idioma' : 'Choose language',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.primaryDark),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // =================================================================
  // AVATAR INVITADO
  // =================================================================

  Widget _defaultAvatar() {
    return Container(
      width: 100,
      height: 100,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.primaryDark,
      ),
      child: const Icon(
        Icons.person_outline_rounded,
        size: 52,
        color: Colors.white,
      ),
    );
  }

  // =================================================================
  // AVATAR PERFIL
  // =================================================================

  Widget _buildAvatar(ProfileDto profile) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.primaryDark,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: profile.avatarUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) {
                  return const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                },
                errorWidget: (context, url, error) {
                  return const Icon(
                    Icons.person,
                    size: 50,
                    color: Colors.white,
                  );
                },
              )
            : const Icon(Icons.person, size: 50, color: Colors.white),
      ),
    );
  }

  // =================================================================
  // TARJETA INFO
  // =================================================================

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    bool active = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: active ? Colors.green : AppTheme.primaryDark),

          const SizedBox(height: 8),

          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),

          const SizedBox(height: 2),

          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: active ? Colors.green : AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // =================================================================
  // BANNER
  // =================================================================

  Widget _buildBaseCampBanner(bool isSpanish) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryDark,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Row(
        children: [
          const Icon(Icons.landscape, color: Colors.white, size: 40),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Coyhaique BaseCamp',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  isSpanish
                      ? 'Tu compañero de aventuras en la Patagonia'
                      : 'Your adventure companion in Patagonia',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =================================================================
  // DIÁLOGO INVITADO
  // =================================================================

  void _showAccountRequiredDialog(BuildContext context, bool isSpanish) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.primaryDark.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_add_alt_1_rounded,
                  color: AppTheme.primaryDark,
                  size: 32,
                ),
              ),

              const SizedBox(height: 20),

              Text(
                isSpanish ? 'Crea una cuenta' : 'Create an account',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                isSpanish
                    ? 'Para personalizar tu perfil necesitas crear una cuenta primero.'
                    : 'To personalize your profile, you need to create an account first.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: AppTheme.textSecondary,
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();

                    context.push('/auth-gateway');
                  },
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: AppTheme.primaryDark,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    isSpanish ? 'Crear cuenta' : 'Create account',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: Text(
                  isSpanish ? 'Ahora no' : 'Not now',
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // =================================================================
  // ERROR PERFIL
  // =================================================================

  Widget _buildErrorWidget(
    BuildContext context,
    WidgetRef ref,
    Object error,
    bool isSpanish,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.redAccent),

            const SizedBox(height: 16),

            Text(
              isSpanish ? 'Error al cargar el perfil' : 'Error loading profile',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),

            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: () {
                ref.invalidate(profileProvider);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryDark,
              ),
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: Text(
                isSpanish ? 'Reintentar' : 'Retry',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =================================================================
  // ERROR AUTH
  // =================================================================

  Widget _buildAuthErrorWidget(Object error, bool isSpanish) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 60, color: Colors.redAccent),

            const SizedBox(height: 16),

            Text(
              isSpanish
                  ? 'No fue posible verificar la sesión'
                  : 'Unable to verify session',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =================================================================
  // DECORACIÓN TARJETA
  // =================================================================

  BoxDecoration _mainCardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(40),
      boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
      ],
    );
  }
}
