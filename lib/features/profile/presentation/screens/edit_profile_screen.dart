import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../authentication/data/providers/auth_controller.dart';
import '../../../../core/utils/language_provider.dart';
import '../../data/models/profile_dto.dart';
import '../../data/providers/profile_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  bool _pauseNotifications = true;
  bool _darkMode = false;
  Future<void> _handleLogOut(BuildContext context, bool isSpanish) async {
    try {
      await ref.read(authControllerProvider.notifier).signOut();

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
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(languageProvider);
    final isSpanish = locale.languageCode == 'es';
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF111113),
      body: SafeArea(
        child: profileAsync.when(
          data: (profile) => _buildSettingsContent(context, profile, isSpanish),
          loading: () => const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
          error: (error, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Error al cargar configuración',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => ref.invalidate(profileProvider),
                  child: const Text(
                    'Reintentar',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsContent(
    BuildContext context,
    ProfileDto profile,
    bool isSpanish,
  ) {
    return Column(
      children: [
        // 1. Top Navigation Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
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
                  isSpanish ? 'Settings' : 'Settings',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(
                width: 44,
              ), // Espaciador de balance para centrar título
            ],
          ),
        ),

        // 2. Body List
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 8.0,
            ),
            child: Column(
              children: [
                // Tarjeta 1: Perfil de usuario (Clickeable para editar datos)
                _buildProfileCard(context, profile, isSpanish),
                const SizedBox(height: 18),

                // Grupo 1: Notificaciones y General
                _buildCardGroup([
                  _buildSwitchTile(
                    icon: Icons.notifications_none_rounded,
                    title: isSpanish
                        ? 'Pause notifications'
                        : 'Pause notifications',
                    value: _pauseNotifications,
                    activeColor: const Color(
                      0xFFC7F32D,
                    ), // Verde lima exacto al mockup
                    onChanged: (val) {
                      setState(() => _pauseNotifications = val);
                    },
                  ),
                  _buildDivider(),
                  _buildNavigationTile(
                    icon: Icons.tune_rounded,
                    title: isSpanish ? 'General settings' : 'General settings',
                    onTap: () {
                      _showEditProfileModal(context, profile, isSpanish);
                    },
                  ),
                ]),
                const SizedBox(height: 16),

                // Grupo 2: Preferencias (Dark mode, Language, Contact)
                _buildCardGroup([
                  _buildSwitchTile(
                    icon: Icons.dark_mode_outlined,
                    title: isSpanish ? 'Dark mode' : 'Dark mode',
                    value: _darkMode,
                    activeColor: Colors.white,
                    onChanged: (val) {
                      setState(() => _darkMode = val);
                    },
                  ),
                  _buildDivider(),
                  _buildNavigationTile(
                    icon: Icons.translate_rounded,
                    title: isSpanish ? 'Language' : 'Language',
                    onTap: () => context.push('/onboarding'),
                  ),
                  _buildDivider(),
                  _buildNavigationTile(
                    icon: Icons.people_outline_rounded,
                    title: isSpanish ? 'My Contact' : 'My Contact',
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
                ]),
                const SizedBox(height: 16),

                // Grupo 3: FAQ, Términos, Políticas
                _buildCardGroup([
                  _buildNavigationTile(
                    icon: Icons.help_outline_rounded,
                    title: 'FAQ',
                    onTap: () {
                      _showInfoDialog(
                        context,
                        'FAQ',
                        isSpanish
                            ? 'Coyhaique BaseCamp es tu guía turística e informativa de Coyhaique y la región de Aysén.'
                            : 'Coyhaique BaseCamp is your tourist and informational guide for Coyhaique and Aysén.',
                      );
                    },
                  ),
                  _buildDivider(),
                  _buildNavigationTile(
                    icon: Icons.info_outline_rounded,
                    title: isSpanish ? 'Terms of service' : 'Terms of service',
                    onTap: () {
                      _showInfoDialog(
                        context,
                        isSpanish
                            ? 'Términos del servicio'
                            : 'Terms of service',
                        isSpanish
                            ? 'El uso de esta aplicación implica la aceptación de los términos y condiciones de turismo responsable en la Patagonia.'
                            : 'Using this app implies acceptance of responsible tourism terms in Patagonia.',
                      );
                    },
                  ),
                  _buildDivider(),
                  _buildNavigationTile(
                    icon: Icons.privacy_tip_outlined,
                    title: isSpanish ? 'User policy' : 'User policy',
                    onTap: () {
                      _showInfoDialog(
                        context,
                        isSpanish ? 'Política de privacidad' : 'User policy',
                        isSpanish
                            ? 'Tus datos están protegidos y sólo se usan para enriquecer tu experiencia en Coyhaique.'
                            : 'Your data is protected and used solely to enhance your Coyhaique experience.',
                      );
                    },
                  ),
                ]),
                const SizedBox(height: 28),

                // Botón inferior blanco de Log Out con texto e ícono rojo
                _buildLogOutButton(context, isSpanish),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard(
    BuildContext context,
    ProfileDto profile,
    bool isSpanish,
  ) {
    return InkWell(
      onTap: () => _showEditProfileModal(context, profile, isSpanish),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E22),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            // Avatar con borde vibrante amarillo / mostaza tal como la imagen
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
                  const SizedBox(height: 3),
                  Text(
                    '@${profile.username ?? 'coyhaique_user'}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 13,
                    ),
                  ),
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

  Widget _buildNavigationTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 15.0),
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

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
    required Color activeColor,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8.0),
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

  Widget _buildLogOutButton(BuildContext context, bool isSpanish) {
    return InkWell(
      onTap: () => _confirmLogOut(context, isSpanish),
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.logout_rounded,
              color: Color(0xFFE53935),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              isSpanish ? 'Log Out' : 'Log Out',
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
    showDialog(
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

  void _showInfoDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E22),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
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
                  isSpanish ? 'Editar Información' : 'Edit Information',
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
                  maxLines: 2,
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
                    onPressed: () async {
                      final updated = ProfileDto(
                        id: profile.id,
                        fullName: nameController.text.trim().isNotEmpty
                            ? nameController.text.trim()
                            : profile.fullName,
                        username: usernameController.text.trim().isNotEmpty
                            ? usernameController.text.trim()
                            : profile.username,
                        biography: bioController.text.trim(),
                        city: cityController.text.trim(),
                        country: countryController.text.trim(),
                        avatarUrl: profile.avatarUrl,
                        language: profile.language,
                        role: profile.role,
                        isVerified: profile.isVerified,
                      );

                      final messenger = ScaffoldMessenger.of(context);
                      Navigator.pop(ctx);

                      final repo = ref.read(profileRepositoryProvider);
                      await repo.updateProfile(updated);
                      ref.invalidate(profileProvider);

                      if (!mounted) return;
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            isSpanish
                                ? 'Perfil actualizado con éxito'
                                : 'Profile updated successfully',
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Text(
                      isSpanish ? 'Guardar Cambios' : 'Save Changes',
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
}
