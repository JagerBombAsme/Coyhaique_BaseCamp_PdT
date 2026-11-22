import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/legal_links.dart';
import '../../../../core/local/catalog_status_provider.dart';
import '../../../../core/providers/auth/auth_user_provider.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/theme/basecamp_tokens.dart';
import '../../../../core/widgets/basecamp/bc_widgets.dart';
import '../../../authentication/data/providers/auth_controller.dart';
import '../../../categories/data/providers/places_provider.dart' as places;
import '../../../planner/data/providers/planner_provider.dart';
import '../../../planner/presentation/screens/planificacion_screen.dart'
    show savedItinerariesRoute;
import '../../../routes/data/providers/activity_provider.dart';
import '../../../trip_info/presentation/widgets/trip_notice.dart'
    show tripInfoRoute;
import '../../data/models/profile_dto.dart';
import '../../data/providers/profile_provider.dart';
import 'interests_screen.dart' show interestsRoute;

/// Mi perfil con la identidad «Coyhaique BaseCamp».
///
/// Tres estados: invitado, cuenta sin perfil y cuenta con perfil. La consulta
/// no exige cuenta (HU-16); la cuenta permite guardar itinerarios (HU-07).
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSpanish = ref.watch(languageProvider).languageCode == 'es';
    final authUserAsync = ref.watch(authUserProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: BcColors.fog,
        body: authUserAsync.when(
          loading: () => const _Loading(),
          error: (_, _) => _ErrorView(
            isSpanish: isSpanish,
            text: isSpanish
                ? 'No fue posible verificar la sesión.'
                : 'Unable to verify the session.',
            onRetry: () => ref.invalidate(authUserProvider),
          ),
          data: (user) {
            if (user == null) return _GuestProfile(isSpanish: isSpanish);

            return ref
                .watch(profileProvider)
                .when(
                  loading: () => const _Loading(),
                  error: (_, _) => _ErrorView(
                    isSpanish: isSpanish,
                    text: isSpanish
                        ? 'No fue posible cargar tu perfil. Revisa tu conexión.'
                        : 'Your profile could not be loaded. Check your connection.',
                    onRetry: () => ref.invalidate(profileProvider),
                  ),
                  data: (profile) => _AccountProfile(
                    isSpanish: isSpanish,
                    user: user,
                    profile: profile,
                  ),
                );
          },
        ),
      ),
    );
  }
}

// =================================================================
// ESTRUCTURA COMÚN: HERO + CUERPO
// =================================================================

class _ProfileLayout extends StatelessWidget {
  const _ProfileLayout({
    required this.tag,
    required this.title,
    required this.children,
    this.subtitle,
    this.avatarUrl,
    this.cornerAction,
    this.onRefresh,
  });

  final Widget tag;
  final String title;
  final String? subtitle;
  final String? avatarUrl;
  final Widget? cornerAction;
  final List<Widget> children;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    final scroll = SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: top + 250,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const BcPhotoImage(
                  source: BcPhoto.cerroCastillo,
                  alignment: Alignment(0, -0.3),
                ),
                const BcPhotoShade(from: 0.4, topShade: 0.35),
                if (cornerAction != null)
                  Positioned(
                    right: BcSpace.gutter,
                    top: top + 14,
                    child: cornerAction!,
                  ),
                Positioned(
                  left: BcSpace.gutter,
                  right: BcSpace.gutter,
                  bottom: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (avatarUrl != null && avatarUrl!.isNotEmpty) ...[
                            _Avatar(url: avatarUrl!),
                            const SizedBox(width: 10),
                          ],
                          tag,
                        ],
                      ),
                      const SizedBox(height: 12),
                      Semantics(
                        header: true,
                        child: Text(
                          title.toUpperCase(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: BcText.display(48, color: BcColors.onPhoto),
                        ),
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: BcText.caption(
                            color: BcColors.onPhoto.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              BcSpace.gutter,
              18,
              BcSpace.gutter,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ],
      ),
    );

    if (onRefresh == null) return scroll;
    return RefreshIndicator(
      onRefresh: onRefresh!,
      color: BcColors.ink,
      backgroundColor: BcColors.surface,
      edgeOffset: top,
      child: scroll,
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        color: BcColors.surface,
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          errorWidget: (_, _, _) => const ColoredBox(
            color: BcColors.ink,
            child: Icon(Icons.person_rounded, color: BcColors.onPhoto),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
      child: Text(
        text.toUpperCase(),
        style: BcText.label(color: BcColors.muted),
      ),
    );
  }
}

// =================================================================
// INVITADO
// =================================================================

class _GuestProfile extends StatelessWidget {
  const _GuestProfile({required this.isSpanish});

  final bool isSpanish;

  @override
  Widget build(BuildContext context) {
    const from = '/profile';

    return _ProfileLayout(
      tag: BcTag(
        isSpanish ? 'Sin cuenta' : 'No account',
        lead: isSpanish ? 'Invitado' : 'Guest',
        style: BcTagStyle.ink,
      ),
      title: isSpanish ? 'Explorador invitado' : 'Guest explorer',
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: BcColors.ink,
            borderRadius: BorderRadius.circular(BcRadius.tile),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isSpanish ? 'Guarda tus itinerarios' : 'Save your itineraries',
                style: BcText.title(color: BcColors.onPhoto),
              ),
              const SizedBox(height: 6),
              Text(
                isSpanish
                    ? 'Puedes usar toda la guía sin cuenta. Crea una para guardar tus itinerarios y verlos después.'
                    : 'You can use the whole guide without an account. Create one to save your itineraries and see them later.',
                style: BcText.caption(
                  color: BcColors.onPhoto.withValues(alpha: 0.82),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: BcButton(
                      height: 48,
                      label: isSpanish ? 'Crear cuenta' : 'Create account',
                      onPressed: () => context.push(
                        '/register?from=${Uri.encodeComponent(from)}',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: BcButton(
                      height: 48,
                      style: BcButtonStyle.surface,
                      label: isSpanish ? 'Iniciar sesión' : 'Sign in',
                      onPressed: () => context.push(
                        '/auth?from=${Uri.encodeComponent(from)}',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        _SectionLabel(isSpanish ? 'Preferencias' : 'Preferences'),
        _PreferencesGroup(isSpanish: isSpanish, includeInterests: true),
        _SectionLabel(isSpanish ? 'Información legal' : 'Legal'),
        _LegalGroup(isSpanish: isSpanish),
      ],
    );
  }
}

// =================================================================
// CON CUENTA
// =================================================================

class _AccountProfile extends ConsumerWidget {
  const _AccountProfile({
    required this.isSpanish,
    required this.user,
    required this.profile,
  });

  final bool isSpanish;
  final User user;

  /// null: la cuenta existe pero aún no completa su perfil.
  final ProfileDto? profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = profile;
    final saved = ref.watch(savedItinerariesProvider);
    final interests = ref.watch(places.validInterestsProvider);

    final savedText = saved.when(
      data: (items) => isSpanish
          ? '${items.length} ${items.length == 1 ? 'guardado' : 'guardados'}'
          : '${items.length} saved',
      loading: () => isSpanish ? 'Cargando…' : 'Loading…',
      error: (_, _) => isSpanish ? 'Requiere conexión' : 'Needs connection',
    );

    final city = p?.city?.trim() ?? '';
    final country = p?.country?.trim() ?? '';
    final username = p?.username?.trim() ?? '';
    final email = user.email?.trim() ?? '';

    final location = [
      if (city.isNotEmpty) city,
      if (country.isNotEmpty) country,
    ].join(', ');

    final subtitle = [
      if (username.isNotEmpty) '@$username' else if (email.isNotEmpty) email,
      if (location.isNotEmpty) location,
    ].join(' · ');

    return _ProfileLayout(
      tag: BcTag(isSpanish ? 'Cuenta activa' : 'Active account'),
      title: (p != null && p.fullName.trim().isNotEmpty)
          ? p.fullName
          : (isSpanish ? 'Mi perfil' : 'My profile'),
      subtitle: subtitle,
      avatarUrl: p?.avatarUrl,
      cornerAction: BcCornerButton(
        icon: Icons.edit_rounded,
        semanticLabel: isSpanish ? 'Editar perfil' : 'Edit profile',
        onTap: () => context.push('/profile/edit'),
      ),
      onRefresh: () async {
        ref.invalidate(profileProvider);
        ref.invalidate(savedItinerariesProvider);
      },
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: BcInfoTile(
                  dark: true,
                  icon: Icons.route_rounded,
                  title: isSpanish ? 'Mis itinerarios' : 'My itineraries',
                  subtitle: savedText,
                  onTap: () => context.push(savedItinerariesRoute),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: BcInfoTile(
                  icon: Icons.interests_rounded,
                  title: isSpanish ? 'Mis intereses' : 'My interests',
                  subtitle: interests.isEmpty
                      ? (isSpanish ? 'Sin elegir' : 'None selected')
                      : isSpanish
                      ? '${interests.length} ${interests.length == 1 ? 'categoría' : 'categorías'}'
                      : '${interests.length} ${interests.length == 1 ? 'category' : 'categories'}',
                  onTap: () => context.push(interestsRoute),
                ),
              ),
            ],
          ),
        ),
        _SectionLabel(isSpanish ? 'Preferencias' : 'Preferences'),
        _PreferencesGroup(isSpanish: isSpanish, includeInterests: false),
        _SectionLabel(
          isSpanish ? 'Cuenta y privacidad' : 'Account and privacy',
        ),
        BcListGroup(
          children: [
            BcListRow(
              icon: Icons.manage_accounts_rounded,
              label: p == null
                  ? (isSpanish ? 'Completa tu perfil' : 'Complete your profile')
                  : (isSpanish ? 'Editar perfil' : 'Edit profile'),
              onTap: () => context.push('/profile/edit'),
            ),
            BcListRow(
              icon: Icons.logout_rounded,
              label: isSpanish ? 'Cerrar sesión' : 'Sign out',
              showChevron: false,
              onTap: () => _confirmSignOut(context, ref),
            ),
            BcListRow(
              icon: Icons.delete_forever_rounded,
              label: isSpanish ? 'Eliminar cuenta' : 'Delete account',
              danger: true,
              showChevron: false,
              onTap: () => _confirmDeleteAccount(context, ref),
            ),
          ],
        ),
        _SectionLabel(isSpanish ? 'Información legal' : 'Legal'),
        _LegalGroup(isSpanish: isSpanish),
      ],
    );
  }

  /// Pide confirmación y elimina la cuenta: perfil, itinerarios guardados y
  /// el usuario de Auth (en el servidor). Luego cierra la sesión local.
  Future<void> _confirmDeleteAccount(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: BcColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BcRadius.tile),
        ),
        title: Text(
          isSpanish ? '¿Eliminar tu cuenta?' : 'Delete your account?',
          style: BcText.title().copyWith(fontSize: 18),
        ),
        content: Text(
          isSpanish
              ? 'Se borrarán tu perfil y todos tus itinerarios guardados. Esta acción no se puede deshacer.'
              : 'Your profile and all your saved itineraries will be deleted. This cannot be undone.',
          style: BcText.body(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            style: TextButton.styleFrom(foregroundColor: BcColors.ink),
            child: Text(isSpanish ? 'Cancelar' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: BcColors.ink,
              foregroundColor: BcColors.onPhoto,
            ),
            child: Text(isSpanish ? 'Eliminar' : 'Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    // Se toman antes del primer await: al cerrar sesión esta vista se
    // desmonta y ya no se pueden usar context ni ref (H-02).
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final repository = ref.read(profileRepositoryProvider);
    final auth = ref.read(authControllerProvider.notifier);

    try {
      await repository.deleteAccount();
    } catch (error) {
      debugPrint('ERROR eliminar cuenta: $error');
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            isSpanish
                ? 'No fue posible eliminar tu cuenta. Revisa tu conexión e inténtalo de nuevo.'
                : 'Unable to delete your account. Check your connection and try again.',
          ),
        ),
      );
      return;
    }

    // La cuenta ya no existe en el servidor: se limpia la sesión local.
    // profileProvider se recalcula solo al cambiar la sesión.
    try {
      await auth.signOut();
    } catch (error) {
      debugPrint('signOut tras eliminar cuenta: $error');
    }
    router.go('/auth-gateway');
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: BcColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BcRadius.tile),
        ),
        title: Text(
          isSpanish ? 'Cerrar sesión' : 'Sign out',
          style: BcText.title().copyWith(fontSize: 18),
        ),
        content: Text(
          isSpanish
              ? 'Podrás seguir usando la guía como invitado. Tus itinerarios quedan guardados en tu cuenta.'
              : 'You can keep using the guide as a guest. Your itineraries stay saved in your account.',
          style: BcText.body(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            style: TextButton.styleFrom(foregroundColor: BcColors.ink),
            child: Text(isSpanish ? 'Cancelar' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: BcColors.ink,
              foregroundColor: BcColors.onPhoto,
            ),
            child: Text(isSpanish ? 'Cerrar sesión' : 'Sign out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    // Se toman antes del await: al cerrar sesión esta vista se desmonta y
    // ya no se pueden usar context ni ref (H-08).
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final auth = ref.read(authControllerProvider.notifier);

    try {
      await auth.signOut();
    } catch (error) {
      debugPrint('ERROR cerrar sesión: $error');
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            isSpanish
                ? 'No fue posible cerrar la sesión. Revisa tu conexión.'
                : 'Unable to sign out. Check your connection.',
          ),
        ),
      );
      return;
    }
    // profileProvider se recalcula solo al cambiar la sesión.
    router.go('/auth-gateway');
  }
}

// =================================================================
// PREFERENCIAS (COMÚN)
// =================================================================

/// Política de privacidad y términos del servicio (HU-19, HU-30).
///
/// Visibles siempre, con o sin cuenta. Abren la página publicada en la
/// landing (--dart-define PRIVACY_POLICY_URL y TERMS_URL); si el build no
/// trae la URL, avisan que el documento está en preparación.
class _LegalGroup extends StatelessWidget {
  const _LegalGroup({required this.isSpanish});

  final bool isSpanish;

  @override
  Widget build(BuildContext context) {
    return BcListGroup(
      children: [
        BcListRow(
          icon: Icons.privacy_tip_rounded,
          label: isSpanish ? 'Política de privacidad' : 'Privacy policy',
          onTap: () => _open(
            context,
            LegalLinks.privacyPolicyUrl,
            isSpanish
                ? 'La política de privacidad se publicará en la página de Coyhaique BaseCamp.'
                : 'The privacy policy will be published on the Coyhaique BaseCamp website.',
          ),
        ),
        BcListRow(
          icon: Icons.description_rounded,
          label: isSpanish ? 'Términos del servicio' : 'Terms of service',
          onTap: () => _open(
            context,
            LegalLinks.termsUrl,
            isSpanish
                ? 'Los términos del servicio se publicarán en la página de Coyhaique BaseCamp.'
                : 'The terms of service will be published on the Coyhaique BaseCamp website.',
          ),
        ),
      ],
    );
  }

  Future<void> _open(BuildContext context, String url, String pending) async {
    final messenger = ScaffoldMessenger.of(context);
    if (url.isEmpty) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(pending)));
      return;
    }
    final opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!opened) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            isSpanish
                ? 'No se pudo abrir el enlace. Revisa tu conexión.'
                : 'The link could not be opened. Check your connection.',
          ),
        ),
      );
    }
  }
}

class _PreferencesGroup extends ConsumerWidget {
  const _PreferencesGroup({
    required this.isSpanish,
    required this.includeInterests,
  });

  final bool isSpanish;
  final bool includeInterests;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(catalogStatusProvider);
    final interests = ref.watch(places.validInterestsProvider);
    final date = status.lastSyncAt == null
        ? null
        : DateFormat('dd-MM-yyyy').format(status.lastSyncAt!);

    return BcListGroup(
      children: [
        BcListRow(
          icon: Icons.translate_rounded,
          label: isSpanish ? 'Idioma' : 'Language',
          value: isSpanish ? 'Español' : 'English',
          onTap: () => context.push('/profile/language'),
        ),
        // Modo oscuro: planificado para la Versión 2.0. Por ahora solo avisa.
        BcListRow(
          icon: Icons.dark_mode_rounded,
          label: isSpanish ? 'Modo oscuro' : 'Dark mode',
          value: isSpanish ? 'Versión 2.0' : 'Version 2.0',
          onTap: () => _showDarkModeSoon(context),
        ),
        if (includeInterests)
          BcListRow(
            icon: Icons.interests_rounded,
            label: isSpanish ? 'Mis intereses' : 'My interests',
            value: interests.isEmpty
                ? (isSpanish ? 'Sin elegir' : 'None')
                : (isSpanish ? 'En este teléfono' : 'On this phone'),
            onTap: () => context.push(interestsRoute),
          ),
        BcListRow(
          icon: status.usingOfflineData
              ? Icons.cloud_off_rounded
              : Icons.download_done_rounded,
          label: isSpanish ? 'Sin conexión' : 'Offline',
          value: status.isSyncing
              ? (isSpanish ? 'Descargando…' : 'Downloading…')
              : (date ?? (isSpanish ? 'Sin descargar' : 'Not downloaded')),
          trailing: status.isSyncing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: BcColors.ink,
                  ),
                )
              : const Icon(
                  Icons.refresh_rounded,
                  size: 20,
                  color: BcColors.muted,
                ),
          onTap: status.isSyncing ? null : () => _download(context, ref),
        ),
        BcListRow(
          icon: Icons.health_and_safety_rounded,
          label: isSpanish ? 'Antes de tu viaje' : 'Before your trip',
          onTap: () => context.push(tripInfoRoute),
        ),
      ],
    );
  }

  /// El modo oscuro llega en la Versión 2.0: siempre muestra el aviso.
  void _showDarkModeSoon(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            isSpanish
                ? 'Disponible en la Versión 2.0. ¡Espéranos y disfruta!'
                : 'Available in Version 2.0. Stay tuned and enjoy!',
          ),
        ),
      );
  }

  Future<void> _download(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await ref.read(catalogStatusProvider.notifier).download();

    if (ok) {
      ref.invalidate(places.categoriesProvider);
      ref.invalidate(places.placesProvider);
      ref.invalidate(places.activitiesProvider);
      ref.invalidate(activitiesProvider);
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? (isSpanish
                    ? 'Descarga completa. La información está disponible sin conexión.'
                    : 'Download complete. Information is available offline.')
              : (isSpanish
                    ? 'No se pudo descargar. Se conserva la información anterior.'
                    : 'Download failed. The previous information was kept.'),
        ),
      ),
    );
  }
}

// =================================================================
// CARGA Y ERROR
// =================================================================

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: BcColors.ink, strokeWidth: 2.5),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.isSpanish,
    required this.text,
    required this.onRetry,
  });

  final bool isSpanish;
  final String text;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: BcMessage(
        icon: Icons.cloud_off_rounded,
        text: text,
        actionLabel: isSpanish ? 'Reintentar' : 'Retry',
        onAction: onRetry,
      ),
    );
  }
}
