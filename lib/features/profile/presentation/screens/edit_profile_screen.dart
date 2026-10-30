import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/auth/auth_user_provider.dart';
import '../../../../core/providers/language_provider.dart';

import '../../../authentication/data/providers/auth_controller.dart';
import '../../../home/presentation/widgets/home_visual_tokens.dart';
import '../../../home/presentation/widgets/pressable_scale.dart';

import '../../data/models/profile_dto.dart';
import '../../data/providers/profile_provider.dart';
import '../widgets/profile_ui.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  bool _pauseNotifications = false;
  bool _darkMode = false;

  // ValueNotifier: el bottom sheet vive en otra ruta, por lo que
  // setState de esta pantalla no lo reconstruye.
  final ValueNotifier<bool> _isSaving = ValueNotifier(false);
  bool _isLoggingOut = false;

  // Sangría de divisores: alinea con el texto, no con el ícono.
  static const double _tileHorizontalPadding = 16;
  static const double _tileIconBox = 36;
  static const double _tileGap = 14;
  static const double _dividerIndent =
      _tileHorizontalPadding + _tileIconBox + _tileGap;

  @override
  void dispose() {
    _isSaving.dispose();
    super.dispose();
  }

  // ================================================================
  // CERRAR SESIÓN
  // ================================================================

  Future<void> _handleLogOut(BuildContext context, bool isSpanish) async {
    if (_isLoggingOut) return;

    setState(() {
      _isLoggingOut = true;
    });

    try {
      await ref.read(authControllerProvider.notifier).signOut();

      ref.invalidate(profileProvider);

      if (!context.mounted) return;

      context.go('/auth-gateway');
    } catch (_) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        _snackBar(
          isSpanish ? 'No fue posible cerrar la sesión.' : 'Unable to log out.',
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
      }
    }
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
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
              // SIN SESIÓN
              // =========================================================

              if (user == null) {
                return _buildNoSessionContent(context, isSpanish);
              }

              // =========================================================
              // CON SESIÓN
              // =========================================================

              final profileAsync = ref.watch(profileProvider);

              return profileAsync.when(
                data: (profile) {
                  // Cuenta existente, pero todavía sin fila en profiles.
                  if (profile == null) {
                    return _buildSettingsWithoutProfile(context, isSpanish);
                  }

                  return _buildSettingsContent(context, profile, isSpanish);
                },
                loading: () => const ProfileLoading(),
                error: (error, stackTrace) {
                  return _buildProfileError(context, error, isSpanish);
                },
              );
            },
            loading: () => const ProfileLoading(),
            error: (error, stackTrace) {
              return _buildProfileError(context, error, isSpanish);
            },
          ),
        ),
      ),
    );
  }

  // ================================================================
  // CONFIGURACIÓN CON PERFIL
  // ================================================================

  Widget _buildSettingsContent(
    BuildContext context,
    ProfileDto profile,
    bool isSpanish,
  ) {
    return _buildScaffoldBody(
      context,
      isSpanish,
      children: [
        _buildProfileCard(context, profile, isSpanish),

        // ====================================================
        // CONFIGURACIÓN GENERAL
        // ====================================================
        _buildGroupLabel(isSpanish ? 'General' : 'General'),

        _buildCardGroup([
          _buildSwitchTile(
            icon: Icons.notifications_none_rounded,
            title: isSpanish ? 'Pausar notificaciones' : 'Pause notifications',
            value: _pauseNotifications,
            onChanged: (value) {
              setState(() {
                _pauseNotifications = value;
              });
            },
          ),

          _buildDivider(),

          _buildNavigationTile(
            icon: Icons.edit_outlined,
            title: isSpanish ? 'Editar información' : 'Edit information',
            onTap: () {
              _showEditProfileModal(context, profile, isSpanish);
            },
          ),
        ]),

        // ====================================================
        // PREFERENCIAS
        // ====================================================
        _buildGroupLabel(isSpanish ? 'Preferencias' : 'Preferences'),

        _buildPreferencesGroup(context, isSpanish),

        // ====================================================
        // INFORMACIÓN Y LEGAL
        // ====================================================
        _buildGroupLabel(isSpanish ? 'Información' : 'Information'),

        _buildLegalGroup(context, isSpanish),

        const SizedBox(height: 28),

        _buildLogOutButton(context, isSpanish),
      ],
    );
  }

  // ================================================================
  // CONFIGURACIÓN SIN PERFIL
  // ================================================================

  Widget _buildSettingsWithoutProfile(BuildContext context, bool isSpanish) {
    return _buildScaffoldBody(
      context,
      isSpanish,
      children: [
        // ====================================================
        // CUENTA ACTIVA
        // ====================================================
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: ProfileUi.cardDecoration,
          child: Column(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: const BoxDecoration(
                  color: HomeVisualTokens.iceBlue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: HomeVisualTokens.deepIce,
                  size: 30,
                ),
              ),

              const SizedBox(height: 14),

              Text(
                isSpanish
                    ? 'Perfil sin personalizar'
                    : 'Profile not personalized',
                textAlign: TextAlign.center,
                style: HomeVisualTokens.cardTitle.copyWith(fontSize: 17),
              ),

              const SizedBox(height: 6),

              Text(
                isSpanish
                    ? 'Tu cuenta está activa. Puedes personalizar tu perfil cuando quieras.'
                    : 'Your account is active. You can personalize your profile whenever you want.',
                textAlign: TextAlign.center,
                style: ProfileUi.body.copyWith(fontSize: 13),
              ),
            ],
          ),
        ),

        // ====================================================
        // CONFIGURACIÓN GENERAL
        // ====================================================
        _buildGroupLabel(isSpanish ? 'General' : 'General'),

        _buildCardGroup([
          _buildSwitchTile(
            icon: Icons.notifications_none_rounded,
            title: isSpanish ? 'Pausar notificaciones' : 'Pause notifications',
            value: _pauseNotifications,
            onChanged: (value) {
              setState(() {
                _pauseNotifications = value;
              });
            },
          ),
        ]),

        _buildGroupLabel(isSpanish ? 'Preferencias' : 'Preferences'),

        _buildPreferencesGroup(context, isSpanish),

        _buildGroupLabel(isSpanish ? 'Información' : 'Information'),

        _buildLegalGroup(context, isSpanish),

        const SizedBox(height: 28),

        // ====================================================
        // CERRAR SESIÓN
        // ====================================================
        _buildLogOutButton(context, isSpanish),
      ],
    );
  }

  Widget _buildScaffoldBody(
    BuildContext context,
    bool isSpanish, {
    required List<Widget> children,
  }) {
    return Column(
      children: [
        _buildTopBar(context, isSpanish),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }

  // ================================================================
  // TOP BAR
  // ================================================================

  Widget _buildTopBar(BuildContext context, bool isSpanish) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          ProfileIconButton(
            icon: Icons.arrow_back_rounded,
            semanticLabel: isSpanish ? 'Volver' : 'Back',
            onTap: () => context.pop(),
          ),

          Expanded(
            child: Text(
              isSpanish ? 'Configuración' : 'Settings',
              textAlign: TextAlign.center,
              style: HomeVisualTokens.cardTitle.copyWith(fontSize: 19),
            ),
          ),

          // Contrapeso del botón atrás para centrar el título ópticamente.
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  // ================================================================
  // ETIQUETA DE GRUPO
  // ================================================================

  Widget _buildGroupLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        _tileHorizontalPadding + 4,
        24,
        _tileHorizontalPadding,
        8,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
            color: HomeVisualTokens.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }

  // ================================================================
  // PREFERENCIAS
  // ================================================================

  Widget _buildPreferencesGroup(BuildContext context, bool isSpanish) {
    return _buildCardGroup([
      _buildSwitchTile(
        icon: Icons.dark_mode_outlined,
        title: isSpanish ? 'Modo oscuro' : 'Dark mode',
        value: _darkMode,
        onChanged: (value) {
          setState(() {
            _darkMode = value;
          });
        },
      ),

      _buildDivider(),

      _buildNavigationTile(
        icon: Icons.translate_rounded,
        title: isSpanish ? 'Idioma' : 'Language',
        trailingText: isSpanish ? 'Español' : 'English',
        onTap: () {
          context.push('/profile/language');
        },
      ),

      _buildDivider(),

      _buildNavigationTile(
        icon: Icons.mail_outline_rounded,
        title: isSpanish ? 'Contacto' : 'Contact',
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            _snackBar(
              isSpanish
                  ? 'Contacto: soporte@coyhaiquebasecamp.cl'
                  : 'Contact: support@coyhaiquebasecamp.cl',
            ),
          );
        },
      ),
    ]);
  }

  // ================================================================
  // LEGAL Y AYUDA
  // ================================================================

  Widget _buildLegalGroup(BuildContext context, bool isSpanish) {
    return _buildCardGroup([
      _buildNavigationTile(
        icon: Icons.help_outline_rounded,
        title: isSpanish ? 'Preguntas frecuentes' : 'FAQ',
        onTap: () {
          _showInfoDialog(
            context,
            isSpanish ? 'Preguntas frecuentes' : 'FAQ',
            isSpanish
                ? 'Coyhaique BaseCamp es una aplicación turística e informativa orientada a Coyhaique.'
                : 'Coyhaique BaseCamp is a tourist and informational app focused on Coyhaique.',
          );
        },
      ),

      _buildDivider(),

      _buildNavigationTile(
        icon: Icons.description_outlined,
        title: isSpanish ? 'Términos del servicio' : 'Terms of service',
        onTap: () {
          _showInfoDialog(
            context,
            isSpanish ? 'Términos del servicio' : 'Terms of service',
            isSpanish
                ? 'Los términos y condiciones definitivos se incorporarán en esta sección.'
                : 'The final terms and conditions will be included in this section.',
          );
        },
      ),

      _buildDivider(),

      _buildNavigationTile(
        icon: Icons.privacy_tip_outlined,
        title: isSpanish ? 'Política de privacidad' : 'Privacy policy',
        onTap: () {
          _showInfoDialog(
            context,
            isSpanish ? 'Política de privacidad' : 'Privacy policy',
            isSpanish
                ? 'La política de privacidad definitiva se incorporará en esta sección.'
                : 'The final privacy policy will be included in this section.',
          );
        },
      ),
    ]);
  }

  // ================================================================
  // PERFIL CARD
  // ================================================================

  Widget _buildProfileCard(
    BuildContext context,
    ProfileDto profile,
    bool isSpanish,
  ) {
    const fallback = Icon(Icons.person_rounded, color: Colors.white, size: 28);

    final hasImage =
        profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty;

    return PressableScale(
      semanticLabel: isSpanish ? 'Editar información' : 'Edit information',
      onTap: () {
        _showEditProfileModal(context, profile, isSpanish);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: ProfileUi.cardDecoration,
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: HomeVisualTokens.iceBlueMedium,
              ),
              child: Container(
                foregroundDecoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.1),
                  ),
                ),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [HomeVisualTokens.accent, HomeVisualTokens.deepIce],
                  ),
                ),
                child: ClipOval(
                  child: hasImage
                      ? CachedNetworkImage(
                          imageUrl: profile.avatarUrl!,
                          fit: BoxFit.cover,
                          width: 52,
                          height: 52,
                          fadeInDuration: HomeVisualTokens.stateDuration,
                          errorWidget: (context, url, error) => fallback,
                        )
                      : fallback,
                ),
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: HomeVisualTokens.cardTitle,
                  ),

                  const SizedBox(height: 3),

                  Text(
                    profile.username != null && profile.username!.isNotEmpty
                        ? '@${profile.username}'
                        : (isSpanish
                              ? 'Toca para editar tu información'
                              : 'Tap to edit your information'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: HomeVisualTokens.caption,
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.chevron_right_rounded,
              color: HomeVisualTokens.textSecondary,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // CARD GROUP
  // ================================================================

  Widget _buildCardGroup(List<Widget> children) {
    return DecoratedBox(
      decoration: ProfileUi.cardDecoration,
      child: ClipRRect(
        // Recorta el ripple de cada fila a las esquinas de la tarjeta.
        borderRadius: BorderRadius.circular(HomeVisualTokens.cardRadius),
        child: Material(
          type: MaterialType.transparency,
          child: Column(children: children),
        ),
      ),
    );
  }

  Widget _buildTileIcon(IconData icon) {
    return Container(
      width: _tileIconBox,
      height: _tileIconBox,
      decoration: const BoxDecoration(
        color: HomeVisualTokens.iceBlue,
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      child: Icon(icon, color: HomeVisualTokens.deepIce, size: 20),
    );
  }

  // ================================================================
  // NAVIGATION TILE
  // ================================================================

  Widget _buildNavigationTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    String? trailingText,
  }) {
    return InkWell(
      onTap: onTap,
      splashColor: HomeVisualTokens.iceBlue.withValues(alpha: 0.6),
      highlightColor: HomeVisualTokens.surfaceElevated,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 60),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: _tileHorizontalPadding,
            vertical: 12,
          ),
          child: Row(
            children: [
              _buildTileIcon(icon),

              const SizedBox(width: _tileGap),

              Expanded(child: Text(title, style: _tileTitleStyle)),

              if (trailingText != null) ...[
                Text(trailingText, style: HomeVisualTokens.caption),
                const SizedBox(width: 4),
              ],

              const Icon(
                Icons.chevron_right_rounded,
                color: HomeVisualTokens.textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const TextStyle _tileTitleStyle = TextStyle(
    color: HomeVisualTokens.textPrimary,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.1,
  );

  // ================================================================
  // SWITCH TILE
  // ================================================================

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    // Toda la fila es tocable, no solo el interruptor.
    return MergeSemantics(
      child: InkWell(
        onTap: () => onChanged(!value),
        splashColor: HomeVisualTokens.iceBlue.withValues(alpha: 0.6),
        highlightColor: HomeVisualTokens.surfaceElevated,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              _tileHorizontalPadding,
              6,
              _tileHorizontalPadding - 4,
              6,
            ),
            child: Row(
              children: [
                _buildTileIcon(icon),

                const SizedBox(width: _tileGap),

                Expanded(child: Text(title, style: _tileTitleStyle)),

                Switch(
                  value: value,
                  onChanged: onChanged,
                  activeThumbColor: Colors.white,
                  activeTrackColor: HomeVisualTokens.accentStrong,
                  inactiveThumbColor: HomeVisualTokens.surface,
                  inactiveTrackColor: HomeVisualTokens.iceBlueMedium,
                  trackOutlineColor: const WidgetStatePropertyAll(
                    Colors.transparent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      color: HomeVisualTokens.outline,
      indent: _dividerIndent,
      endIndent: _tileHorizontalPadding,
    );
  }

  // ================================================================
  // LOGOUT
  // ================================================================

  Widget _buildLogOutButton(BuildContext context, bool isSpanish) {
    return SizedBox(
      width: double.infinity,
      child: ProfilePillButton(
        icon: Icons.logout_rounded,
        label: isSpanish ? 'Cerrar sesión' : 'Log out',
        loading: _isLoggingOut,
        backgroundOverride: ProfileUi.danger.withValues(alpha: 0.08),
        foregroundOverride: ProfileUi.danger,
        onTap: () {
          _confirmLogOut(context, isSpanish);
        },
      ),
    );
  }

  void _confirmLogOut(BuildContext context, bool isSpanish) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: HomeVisualTokens.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HomeVisualTokens.cardRadius),
          ),
          title: Text(
            isSpanish ? '¿Cerrar sesión?' : 'Log out?',
            style: HomeVisualTokens.cardTitle.copyWith(fontSize: 19),
          ),
          content: Text(
            isSpanish
                ? '¿Estás seguro de que deseas cerrar tu sesión en Coyhaique BaseCamp?'
                : 'Are you sure you want to log out of Coyhaique BaseCamp?',
            style: ProfileUi.body,
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: HomeVisualTokens.textSecondary,
                minimumSize: const Size(64, 44),
                shape: const StadiumBorder(),
              ),
              child: Text(isSpanish ? 'Cancelar' : 'Cancel'),
            ),

            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: ProfileUi.danger,
                foregroundColor: Colors.white,
                minimumSize: const Size(64, 44),
                shape: const StadiumBorder(),
              ),
              onPressed: () async {
                Navigator.of(dialogContext).pop();

                await _handleLogOut(context, isSpanish);
              },
              child: Text(isSpanish ? 'Cerrar sesión' : 'Log out'),
            ),
          ],
        );
      },
    );
  }

  // ================================================================
  // EDITAR PERFIL
  // ================================================================

  void _showEditProfileModal(
    BuildContext context,
    ProfileDto profile,
    bool isSpanish,
  ) {
    final nameController = TextEditingController(text: profile.fullName);

    final usernameController = TextEditingController(
      text: profile.username ?? '',
    );

    final bioController = TextEditingController(text: profile.biography ?? '');

    final cityController = TextEditingController(text: profile.city ?? '');

    final countryController = TextEditingController(
      text: profile.country ?? '',
    );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: HomeVisualTokens.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(HomeVisualTokens.sectionRadius),
        ),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 12,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: HomeVisualTokens.iceBlueMedium,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  isSpanish ? 'Editar información' : 'Edit information',
                  style: HomeVisualTokens.sectionTitle.copyWith(fontSize: 22),
                ),

                const SizedBox(height: 6),

                Text(
                  isSpanish
                      ? 'Así te verán otros exploradores.'
                      : 'This is how other explorers will see you.',
                  style: HomeVisualTokens.caption,
                ),

                const SizedBox(height: 20),

                _buildModalTextField(
                  label: isSpanish ? 'Nombre completo' : 'Full name',
                  controller: nameController,
                  textCapitalization: TextCapitalization.words,
                ),

                const SizedBox(height: 12),

                _buildModalTextField(
                  label: isSpanish ? 'Nombre de usuario' : 'Username',
                  controller: usernameController,
                  prefix: '@',
                ),

                const SizedBox(height: 12),

                _buildModalTextField(
                  label: isSpanish ? 'Biografía' : 'Biography',
                  controller: bioController,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _buildModalTextField(
                        label: isSpanish ? 'Ciudad' : 'City',
                        controller: cityController,
                        textCapitalization: TextCapitalization.words,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: _buildModalTextField(
                        label: isSpanish ? 'País' : 'Country',
                        controller: countryController,
                        textCapitalization: TextCapitalization.words,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                ValueListenableBuilder<bool>(
                  valueListenable: _isSaving,
                  builder: (context, isSaving, _) {
                    return SizedBox(
                      width: double.infinity,
                      child: ProfilePillButton(
                        label: isSpanish ? 'Guardar cambios' : 'Save changes',
                        loading: isSaving,
                        onTap: () async {
                          await _saveProfile(
                            context,
                            sheetContext,
                            profile,
                            nameController,
                            usernameController,
                            bioController,
                            cityController,
                            countryController,
                            isSpanish,
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ================================================================
  // GUARDAR PERFIL
  // ================================================================

  Future<void> _saveProfile(
    BuildContext context,
    BuildContext sheetContext,
    ProfileDto profile,
    TextEditingController nameController,
    TextEditingController usernameController,
    TextEditingController bioController,
    TextEditingController cityController,
    TextEditingController countryController,
    bool isSpanish,
  ) async {
    if (_isSaving.value) return;

    final user = ref.read(authUserProvider).value;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        _snackBar(
          isSpanish
              ? 'Debes iniciar sesión para actualizar tu perfil.'
              : 'You must log in to update your profile.',
        ),
      );

      return;
    }

    final name = nameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        _snackBar(
          isSpanish
              ? 'El nombre completo es obligatorio.'
              : 'Full name is required.',
        ),
      );

      return;
    }

    _isSaving.value = true;

    try {
      final updatedProfile = ProfileDto(
        id: user.id,
        fullName: name,
        username: usernameController.text.trim().isEmpty
            ? null
            : usernameController.text.trim(),
        biography: bioController.text.trim(),
        city: cityController.text.trim(),
        country: countryController.text.trim(),
        avatarUrl: profile.avatarUrl,
        language: profile.language,
        role: profile.role,
        isVerified: profile.isVerified,
      );

      final repository = ref.read(profileRepositoryProvider);

      await repository.updateProfile(userId: user.id, profile: updatedProfile);

      ref.invalidate(profileProvider);

      if (!context.mounted) return;

      if (sheetContext.mounted) Navigator.of(sheetContext).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        _snackBar(
          isSpanish
              ? 'Perfil actualizado correctamente.'
              : 'Profile updated successfully.',
        ),
      );
    } catch (_) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        _snackBar(
          isSpanish
              ? 'No fue posible actualizar el perfil.'
              : 'Unable to update profile.',
        ),
      );
    } finally {
      if (mounted) {
        _isSaving.value = false;
      }
    }
  }

  // ================================================================
  // TEXT FIELD
  // ================================================================

  Widget _buildModalTextField({
    required String label,
    required TextEditingController controller,
    String? prefix,
    int maxLines = 1,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    final radius = BorderRadius.circular(HomeVisualTokens.controlRadius);

    return TextField(
      controller: controller,
      maxLines: maxLines,
      textCapitalization: textCapitalization,
      cursorColor: HomeVisualTokens.accentStrong,
      style: const TextStyle(
        color: HomeVisualTokens.textPrimary,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefix,
        prefixStyle: const TextStyle(color: HomeVisualTokens.textSecondary),
        labelStyle: const TextStyle(
          color: HomeVisualTokens.textSecondary,
          fontSize: 14,
        ),
        floatingLabelStyle: const TextStyle(
          color: HomeVisualTokens.accentStrong,
          fontWeight: FontWeight.w600,
        ),
        filled: true,
        fillColor: HomeVisualTokens.surfaceElevated,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(borderRadius: radius),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: HomeVisualTokens.outline),
        ),
        // El borde se mantiene para el foco: comunica estado, no elevación.
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(
            color: HomeVisualTokens.accentStrong,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  // ================================================================
  // INFO DIALOG
  // ================================================================

  void _showInfoDialog(BuildContext context, String title, String message) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: HomeVisualTokens.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HomeVisualTokens.cardRadius),
          ),
          title: Text(
            title,
            style: HomeVisualTokens.cardTitle.copyWith(fontSize: 19),
          ),
          content: Text(message, style: ProfileUi.body),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              style: FilledButton.styleFrom(
                backgroundColor: HomeVisualTokens.deepIce,
                foregroundColor: Colors.white,
                minimumSize: const Size(64, 44),
                shape: const StadiumBorder(),
              ),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // ================================================================
  // SNACKBAR
  // ================================================================

  SnackBar _snackBar(String message) {
    return SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      backgroundColor: HomeVisualTokens.deepIce,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(HomeVisualTokens.controlRadius),
      ),
      duration: const Duration(seconds: 2),
    );
  }

  // ================================================================
  // SIN SESIÓN
  // ================================================================

  Widget _buildNoSessionContent(BuildContext context, bool isSpanish) {
    return ProfileStatusView(
      icon: Icons.lock_outline_rounded,
      title: isSpanish
          ? 'Debes crear una cuenta para acceder a esta configuración.'
          : 'You need an account to access these settings.',
      action: ProfilePillButton(
        icon: Icons.person_add_alt_1_rounded,
        label: isSpanish ? 'Crear cuenta' : 'Create account',
        onTap: () {
          context.go('/auth-gateway');
        },
      ),
    );
  }

  // ================================================================
  // ERROR
  // ================================================================

  Widget _buildProfileError(
    BuildContext context,
    Object error,
    bool isSpanish,
  ) {
    return ProfileStatusView(
      isError: true,
      icon: Icons.cloud_off_rounded,
      title: isSpanish
          ? 'No fue posible cargar el perfil.'
          : 'Unable to load profile.',
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
}
