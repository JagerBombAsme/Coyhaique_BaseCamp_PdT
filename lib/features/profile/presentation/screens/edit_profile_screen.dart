import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/auth/auth_user_provider.dart';
import '../../../../core/providers/language_provider.dart';

import '../../../authentication/data/providers/auth_controller.dart';

import '../../data/models/profile_dto.dart';
import '../../data/providers/profile_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  bool _pauseNotifications = false;
  bool _darkMode = false;

  bool _isSaving = false;
  bool _isLoggingOut = false;

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

      if (!mounted) return;

      context.go('/auth-gateway');
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isSpanish
                ? 'No fue posible cerrar la sesión.'
                : 'Unable to log out.',
          ),
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
      backgroundColor: const Color(0xFF111113),
      body: SafeArea(
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
              loading: () => const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
              error: (error, stackTrace) {
                return _buildProfileError(context, error, isSpanish);
              },
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
          error: (error, stackTrace) {
            return _buildProfileError(context, error, isSpanish);
          },
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
    return Column(
      children: [
        _buildTopBar(context, isSpanish),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              children: [
                _buildProfileCard(context, profile, isSpanish),

                const SizedBox(height: 18),

                // ====================================================
                // CONFIGURACIÓN GENERAL
                // ====================================================
                _buildCardGroup([
                  _buildSwitchTile(
                    icon: Icons.notifications_none_rounded,
                    title: isSpanish
                        ? 'Pausar notificaciones'
                        : 'Pause notifications',
                    value: _pauseNotifications,
                    activeColor: const Color(0xFFC7F32D),
                    onChanged: (value) {
                      setState(() {
                        _pauseNotifications = value;
                      });
                    },
                  ),

                  _buildDivider(),

                  _buildNavigationTile(
                    icon: Icons.tune_rounded,
                    title: isSpanish
                        ? 'Editar información'
                        : 'Edit information',
                    onTap: () {
                      _showEditProfileModal(context, profile, isSpanish);
                    },
                  ),
                ]),

                const SizedBox(height: 16),

                // ====================================================
                // PREFERENCIAS
                // ====================================================
                _buildPreferencesGroup(context, isSpanish),

                const SizedBox(height: 16),

                // ====================================================
                // INFORMACIÓN Y LEGAL
                // ====================================================
                _buildLegalGroup(context, isSpanish),

                const SizedBox(height: 28),

                _buildLogOutButton(context, isSpanish),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ================================================================
  // CONFIGURACIÓN SIN PERFIL
  // ================================================================

  Widget _buildSettingsWithoutProfile(BuildContext context, bool isSpanish) {
    return Column(
      children: [
        _buildTopBar(context, isSpanish),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              children: [
                // ====================================================
                // CUENTA ACTIVA
                // ====================================================
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E22),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: const BoxDecoration(
                          color: Color(0xFF2A2A30),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_outline_rounded,
                          color: Colors.white70,
                          size: 32,
                        ),
                      ),

                      const SizedBox(height: 14),

                      Text(
                        isSpanish
                            ? 'Perfil sin personalizar'
                            : 'Profile not personalized',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        isSpanish
                            ? 'Tu cuenta está activa. Puedes personalizar tu perfil cuando quieras.'
                            : 'Your account is active. You can personalize your profile whenever you want.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // ====================================================
                // CONFIGURACIÓN GENERAL
                // ====================================================
                _buildCardGroup([
                  _buildSwitchTile(
                    icon: Icons.notifications_none_rounded,
                    title: isSpanish
                        ? 'Pausar notificaciones'
                        : 'Pause notifications',
                    value: _pauseNotifications,
                    activeColor: const Color(0xFFC7F32D),
                    onChanged: (value) {
                      setState(() {
                        _pauseNotifications = value;
                      });
                    },
                  ),
                ]),

                const SizedBox(height: 16),

                _buildPreferencesGroup(context, isSpanish),

                const SizedBox(height: 16),

                _buildLegalGroup(context, isSpanish),

                const SizedBox(height: 28),

                // ====================================================
                // CERRAR SESIÓN
                // ====================================================
                _buildLogOutButton(context, isSpanish),

                const SizedBox(height: 24),
              ],
            ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          InkWell(
            onTap: () => context.pop(),
            borderRadius: BorderRadius.circular(22),
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xFF202024),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),

          Expanded(
            child: Text(
              isSpanish ? 'Configuración' : 'Settings',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          const SizedBox(width: 44),
        ],
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
        activeColor: Colors.white,
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
        onTap: () {
          context.push('/profile/language');
        },
      ),

      _buildDivider(),

      _buildNavigationTile(
        icon: Icons.people_outline_rounded,
        title: isSpanish ? 'Contacto' : 'Contact',
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isSpanish
                    ? 'Contacto: soporte@coyhaiquebasecamp.cl'
                    : 'Contact: support@coyhaiquebasecamp.cl',
              ),
              duration: const Duration(seconds: 2),
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
        icon: Icons.info_outline_rounded,
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
    return InkWell(
      onTap: () {
        _showEditProfileModal(context, profile, isSpanish);
      },
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E22),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFF5B800), width: 2.2),
                color: const Color(0xFF2A2A30),
              ),
              child: ClipOval(
                child:
                    profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: profile.avatarUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => const Icon(
                          Icons.person_rounded,
                          color: Colors.white70,
                          size: 30,
                        ),
                      )
                    : const Icon(
                        Icons.person_rounded,
                        color: Colors.white70,
                        size: 30,
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
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  if (profile.username != null &&
                      profile.username!.isNotEmpty) ...[
                    const SizedBox(height: 3),

                    Text(
                      '@${profile.username}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white38,
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
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E22),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(children: children),
    );
  }

  // ================================================================
  // NAVIGATION TILE
  // ================================================================

  Widget _buildNavigationTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 21),

            const SizedBox(width: 14),

            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white38,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // SWITCH TILE
  // ================================================================

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
    required Color activeColor,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 21),

          const SizedBox(width: 14),

          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: activeColor,
            inactiveTrackColor: const Color(0xFF38383E),
            inactiveThumbColor: Colors.white70,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.white.withValues(alpha: 0.05),
      indent: 18,
      endIndent: 18,
    );
  }

  // ================================================================
  // LOGOUT
  // ================================================================

  Widget _buildLogOutButton(BuildContext context, bool isSpanish) {
    return InkWell(
      onTap: _isLoggingOut
          ? null
          : () {
              _confirmLogOut(context, isSpanish);
            },
      borderRadius: BorderRadius.circular(28),
      child: Container(
        height: 54,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: _isLoggingOut
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFFE53935),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.logout_rounded,
                    color: Color(0xFFE53935),
                    size: 20,
                  ),

                  const SizedBox(width: 8),

                  Text(
                    isSpanish ? 'Cerrar sesión' : 'Log out',
                    style: const TextStyle(
                      color: Color(0xFFE53935),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  void _confirmLogOut(BuildContext context, bool isSpanish) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E22),
          title: Text(
            isSpanish ? '¿Cerrar sesión?' : 'Log out?',
            style: const TextStyle(color: Colors.white),
          ),
          content: Text(
            isSpanish
                ? '¿Estás seguro de que deseas cerrar tu sesión en Coyhaique BaseCamp?'
                : 'Are you sure you want to log out of Coyhaique BaseCamp?',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: Text(
                isSpanish ? 'Cancelar' : 'Cancel',
                style: const TextStyle(color: Colors.white60),
              ),
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                foregroundColor: Colors.white,
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
      backgroundColor: const Color(0xFF1E1E22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                Text(
                  isSpanish ? 'Editar información' : 'Edit information',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 16),

                _buildModalTextField(
                  label: isSpanish ? 'Nombre completo' : 'Full name',
                  controller: nameController,
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
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _buildModalTextField(
                        label: isSpanish ? 'Ciudad' : 'City',
                        controller: cityController,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: _buildModalTextField(
                        label: isSpanish ? 'País' : 'Country',
                        controller: countryController,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    onPressed: _isSaving
                        ? null
                        : () async {
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
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : Text(
                            isSpanish ? 'Guardar cambios' : 'Save changes',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
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
    final user = ref.read(authUserProvider).value;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isSpanish
                ? 'Debes iniciar sesión para actualizar tu perfil.'
                : 'You must log in to update your profile.',
          ),
        ),
      );

      return;
    }

    final name = nameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isSpanish
                ? 'El nombre completo es obligatorio.'
                : 'Full name is required.',
          ),
        ),
      );

      return;
    }

    setState(() {
      _isSaving = true;
    });

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

      if (!mounted) return;

      Navigator.of(sheetContext).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isSpanish
                ? 'Perfil actualizado correctamente.'
                : 'Profile updated successfully.',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isSpanish
                ? 'No fue posible actualizar el perfil.'
                : 'Unable to update profile.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
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
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefix,
        prefixStyle: const TextStyle(color: Colors.white60),
        labelStyle: const TextStyle(color: Colors.white60, fontSize: 13),
        filled: true,
        fillColor: const Color(0xFF28282E),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
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
          backgroundColor: const Color(0xFF1E1E22),
          title: Text(title, style: const TextStyle(color: Colors.white)),
          content: Text(message, style: const TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('OK', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // ================================================================
  // SIN SESIÓN
  // ================================================================

  Widget _buildNoSessionContent(BuildContext context, bool isSpanish) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock_outline_rounded,
              color: Colors.white70,
              size: 58,
            ),

            const SizedBox(height: 16),

            Text(
              isSpanish
                  ? 'Debes crear una cuenta para acceder a esta configuración.'
                  : 'You need an account to access these settings.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                context.go('/auth-gateway');
              },
              child: Text(isSpanish ? 'Crear cuenta' : 'Create account'),
            ),
          ],
        ),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 58),

            const SizedBox(height: 16),

            Text(
              isSpanish
                  ? 'No fue posible cargar el perfil.'
                  : 'Unable to load profile.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),

            const SizedBox(height: 20),

            TextButton(
              onPressed: () {
                ref.invalidate(profileProvider);
              },
              child: Text(
                isSpanish ? 'Reintentar' : 'Retry',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
