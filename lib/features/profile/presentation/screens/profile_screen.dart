import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/providers/auth/auth_user_provider.dart';
import '../../../../core/providers/language_provider.dart';

import '../../../home/presentation/widgets/home_visual_tokens.dart';

import '../../data/models/profile_dto.dart';
import '../../data/providers/profile_provider.dart';
import '../widgets/profile_ui.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(languageProvider);
    final isSpanish = locale.languageCode == 'es';

    final authUserAsync = ref.watch(authUserProvider);

    return Scaffold(
      backgroundColor: HomeVisualTokens.background,
      body: ProfileBackground(
        child: SafeArea(
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
                    return _buildAccountWithoutProfile(
                      context,
                      user,
                      isSpanish,
                    );
                  }

                  // Cuenta + perfil.
                  return _buildProfileContent(context, ref, profile, isSpanish);
                },
                loading: () => const ProfileLoading(),
                error: (error, stackTrace) {
                  return _buildErrorWidget(context, ref, error, isSpanish);
                },
              );
            },

            loading: () => const ProfileLoading(),

            error: (error, stackTrace) {
              return _buildAuthErrorWidget(error, isSpanish);
            },
          ),
        ),
      ),
    );
  }

  // =================================================================
  // INVITADO
  // =================================================================

  Widget _buildGuestProfile(BuildContext context, bool isSpanish) {
    return _buildScrollBody(
      children: [
        _buildHeader(context, isSpanish, showSettings: false),

        const SizedBox(height: 16),

        _buildMainCard(
          children: [
            _defaultAvatar(),

            const SizedBox(height: 16),

            _buildName(isSpanish ? 'Explorador invitado' : 'Guest explorer'),

            const SizedBox(height: 8),

            Text(
              isSpanish
                  ? 'Puedes explorar Coyhaique sin crear una cuenta. Para personalizar tu perfil debes registrarte.'
                  : 'You can explore Coyhaique without creating an account. To personalize your profile, you need to register.',
              textAlign: TextAlign.center,
              style: ProfileUi.body,
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

        const SizedBox(height: 16),

        _buildInfoRow(
          isSpanish,
          accountIcon: Icons.person_outline_rounded,
          accountValue: isSpanish ? 'Sin cuenta' : 'No account',
          accountActive: false,
        ),

        const SizedBox(height: 16),

        _buildBaseCampBanner(isSpanish),
      ],
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

    return _buildScrollBody(
      children: [
        // IMPORTANTE:
        // Usuario autenticado => sí tiene configuración.
        _buildHeader(context, isSpanish, showSettings: true),

        const SizedBox(height: 16),

        _buildMainCard(
          children: [
            _defaultAvatar(),

            const SizedBox(height: 16),

            _buildName(
              isSpanish ? 'Tu cuenta está creada' : 'Your account is ready',
            ),

            if (email != null && email.isNotEmpty) ...[
              const SizedBox(height: 6),

              Text(
                email,
                textAlign: TextAlign.center,
                style: HomeVisualTokens.caption.copyWith(fontSize: 14),
              ),
            ],

            const SizedBox(height: 10),

            Text(
              isSpanish
                  ? 'Ahora puedes personalizar tu perfil.'
                  : 'You can now personalize your profile.',
              textAlign: TextAlign.center,
              style: ProfileUi.body,
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

        const SizedBox(height: 16),

        _buildInfoRow(
          isSpanish,
          accountIcon: Icons.check_circle_outline_rounded,
          accountValue: isSpanish ? 'Creada' : 'Created',
          accountActive: true,
        ),

        const SizedBox(height: 16),

        _buildBaseCampBanner(isSpanish),
      ],
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
      color: HomeVisualTokens.deepIce,
      backgroundColor: HomeVisualTokens.surface,
      strokeWidth: 2.4,
      child: _buildScrollBody(
        children: [
          _buildHeader(context, isSpanish, showSettings: true),

          const SizedBox(height: 16),

          _buildMainCard(
            children: [
              _buildAvatar(profile),

              const SizedBox(height: 16),

              // ==================================================
              // NOMBRE
              // ==================================================
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(child: _buildName(profile.fullName)),

                  if (profile.isVerified) ...[
                    const SizedBox(width: 6),

                    Icon(
                      Icons.verified_rounded,
                      color: HomeVisualTokens.accentStrong,
                      size: 20,
                      semanticLabel: isSpanish ? 'Verificado' : 'Verified',
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
                  style: HomeVisualTokens.caption.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],

              const SizedBox(height: 14),

              // ==================================================
              // ROL Y UBICACIÓN
              // ==================================================
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildChip(
                    label: profile.role.toUpperCase(),
                    background: HomeVisualTokens.iceBlue,
                    foreground: HomeVisualTokens.deepIce,
                    bold: true,
                  ),

                  if (locationText.isNotEmpty)
                    _buildChip(
                      icon: Icons.location_on_outlined,
                      label: locationText,
                      background: HomeVisualTokens.surfaceElevated,
                      foreground: HomeVisualTokens.textSecondary,
                    ),
                ],
              ),

              // ==================================================
              // BIO
              // ==================================================
              if (profile.biography != null &&
                  profile.biography!.isNotEmpty) ...[
                const SizedBox(height: 16),

                Text(
                  profile.biography!,
                  textAlign: TextAlign.center,
                  style: ProfileUi.body,
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

          const SizedBox(height: 16),

          _buildInfoRow(
            isSpanish,
            accountIcon: Icons.check_circle_outline_rounded,
            accountValue: isSpanish ? 'Creada' : 'Created',
            accountActive: true,
          ),

          const SizedBox(height: 16),

          _buildBaseCampBanner(isSpanish),
        ],
      ),
    );
  }

  // =================================================================
  // ESTRUCTURA COMÚN
  // =================================================================

  Widget _buildScrollBody({required List<Widget> children}) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      // Espacio inferior para que la navbar flotante no tape el banner.
      padding: const EdgeInsets.fromLTRB(
        HomeVisualTokens.sectionMargin + 4,
        12,
        HomeVisualTokens.sectionMargin + 4,
        120,
      ),
      child: Column(children: children),
    );
  }

  Widget _buildMainCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: ProfileUi.sectionDecoration,
      child: Column(children: children),
    );
  }

  Widget _buildName(String text) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: HomeVisualTokens.sectionTitle.copyWith(fontSize: 22),
    );
  }

  Widget _buildChip({
    required String label,
    required Color background,
    required Color foreground,
    IconData? icon,
    bool bold = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: bold ? 11 : 12,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: bold ? 0.6 : 0,
                color: foreground,
              ),
            ),
          ),
        ],
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
    return SizedBox(
      height: 48,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              isSpanish ? 'Mi perfil' : 'My profile',
              style: HomeVisualTokens.sectionTitle,
            ),
          ),

          if (showSettings)
            ProfileIconButton(
              icon: Icons.settings_outlined,
              semanticLabel: isSpanish ? 'Configuración' : 'Settings',
              onTap: () {
                context.push('/profile/edit');
              },
            ),
        ],
      ),
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
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ProfilePillButton(
            icon: Icons.edit_outlined,
            label: isSpanish
                ? 'Personaliza tu perfil'
                : 'Personalize your profile',
            onTap: onPersonalize,
          ),
        ),

        const SizedBox(height: 10),

        SizedBox(
          width: double.infinity,
          child: ProfilePillButton(
            icon: Icons.translate_rounded,
            filled: false,
            label: isSpanish ? 'Elige un idioma' : 'Choose language',
            onTap: () {
              context.push('/profile/language');
            },
          ),
        ),
      ],
    );
  }

  // =================================================================
  // AVATAR INVITADO
  // =================================================================

  Widget _defaultAvatar() {
    return _avatarFrame(
      child: const Icon(
        Icons.person_outline_rounded,
        size: 48,
        color: Colors.white,
      ),
    );
  }

  // =================================================================
  // AVATAR PERFIL
  // =================================================================

  Widget _buildAvatar(ProfileDto profile) {
    const fallback = Icon(Icons.person_rounded, size: 48, color: Colors.white);

    final hasImage =
        profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty;

    return _avatarFrame(
      child: hasImage
          ? CachedNetworkImage(
              imageUrl: profile.avatarUrl!,
              fit: BoxFit.cover,
              width: 96,
              height: 96,
              fadeInDuration: HomeVisualTokens.stateDuration,
              placeholder: (context, url) => const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
              errorWidget: (context, url, error) => fallback,
            )
          : fallback,
    );
  }

  /// Avatar circular: degradado de la paleta, anillo blanco y un contorno
  /// negro 10 % para que las fotos claras no se "pierdan" sobre el fondo.
  Widget _avatarFrame({required Widget child}) {
    return Container(
      width: 104,
      height: 104,
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: HomeVisualTokens.surface,
        boxShadow: HomeVisualTokens.softShadow,
      ),
      child: Container(
        foregroundDecoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
        ),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [HomeVisualTokens.accent, HomeVisualTokens.deepIce],
          ),
        ),
        child: ClipOval(child: Center(child: child)),
      ),
    );
  }

  // =================================================================
  // TARJETAS INFO
  // =================================================================

  Widget _buildInfoRow(
    bool isSpanish, {
    required IconData accountIcon,
    required String accountValue,
    required bool accountActive,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _buildInfoCard(
              icon: Icons.language_rounded,
              label: isSpanish ? 'Idioma' : 'Language',
              value: isSpanish ? 'Español' : 'English',
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: _buildInfoCard(
              icon: accountIcon,
              label: isSpanish ? 'Cuenta' : 'Account',
              value: accountValue,
              active: accountActive,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    bool active = false,
  }) {
    const padding = 16.0;

    return Container(
      padding: const EdgeInsets.all(padding),
      decoration: ProfileUi.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: active
                  ? HomeVisualTokens.iceBlueMedium
                  : HomeVisualTokens.iceBlue,
              // Radio concéntrico con la tarjeta (24 − 16 = 8) + margen óptico.
              borderRadius: BorderRadius.circular(
                HomeVisualTokens.innerRadius(
                      HomeVisualTokens.cardRadius,
                      padding,
                    ) +
                    4,
              ),
            ),
            child: Icon(icon, size: 22, color: HomeVisualTokens.deepIce),
          ),

          const SizedBox(height: 12),

          Text(label, style: HomeVisualTokens.caption.copyWith(fontSize: 12)),

          const SizedBox(height: 2),

          Text(value, style: HomeVisualTokens.cardTitle),
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
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(
          Radius.circular(HomeVisualTokens.cardRadius),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [HomeVisualTokens.deepIce, HomeVisualTokens.accentStrong],
        ),
        boxShadow: HomeVisualTokens.softShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(
                HomeVisualTokens.controlRadius - 4,
              ),
            ),
            child: const Icon(
              Icons.landscape_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Coyhaique BaseCamp',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    letterSpacing: -0.25,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  isSpanish
                      ? 'Tu compañero de aventuras en la Patagonia'
                      : 'Your adventure companion in Patagonia',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                    height: 1.3,
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
          backgroundColor: HomeVisualTokens.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HomeVisualTokens.sectionRadius),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: HomeVisualTokens.iceBlue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_add_alt_1_rounded,
                  color: HomeVisualTokens.deepIce,
                  size: 30,
                ),
              ),

              const SizedBox(height: 20),

              Text(
                isSpanish ? 'Crea una cuenta' : 'Create an account',
                textAlign: TextAlign.center,
                style: HomeVisualTokens.sectionTitle.copyWith(fontSize: 22),
              ),

              const SizedBox(height: 10),

              Text(
                isSpanish
                    ? 'Para personalizar tu perfil necesitas crear una cuenta primero.'
                    : 'To personalize your profile, you need to create an account first.',
                textAlign: TextAlign.center,
                style: ProfileUi.body,
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ProfilePillButton(
                  label: isSpanish ? 'Crear cuenta' : 'Create account',
                  onTap: () {
                    Navigator.of(dialogContext).pop();

                    context.push('/auth-gateway');
                  },
                ),
              ),

              const SizedBox(height: 8),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: HomeVisualTokens.textSecondary,
                    shape: const StadiumBorder(),
                  ),
                  child: Text(isSpanish ? 'Ahora no' : 'Not now'),
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
    return ProfileStatusView(
      isError: true,
      icon: Icons.cloud_off_rounded,
      title: isSpanish ? 'Error al cargar el perfil' : 'Error loading profile',
      message: error.toString(),
      action: ProfilePillButton(
        icon: Icons.refresh_rounded,
        label: isSpanish ? 'Reintentar' : 'Retry',
        onTap: () {
          ref.invalidate(profileProvider);
        },
      ),
    );
  }

  // =================================================================
  // ERROR AUTH
  // =================================================================

  Widget _buildAuthErrorWidget(Object error, bool isSpanish) {
    return ProfileStatusView(
      isError: true,
      icon: Icons.lock_outline_rounded,
      title: isSpanish
          ? 'No fue posible verificar la sesión'
          : 'Unable to verify session',
      message: error.toString(),
    );
  }
}
