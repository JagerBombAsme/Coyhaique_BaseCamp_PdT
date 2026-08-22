import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/language_provider.dart';
import '../../data/models/profile_dto.dart';
import '../../data/providers/profile_provider.dart';

class ProfileScreen extends ConsumerWidget {
  final VoidCallback onLanguageChangeClick;

  const ProfileScreen({
    super.key,
    required this.onLanguageChangeClick,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(languageProvider);
    final isSpanish = locale.languageCode == 'es';
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: profileAsync.when(
          data: (profile) => _buildProfileContent(context, ref, profile, isSpanish),
          loading: () => const Center(
            child: CircularProgressIndicator(
              color: AppTheme.primaryDark,
            ),
          ),
          error: (error, stackTrace) => _buildErrorWidget(context, ref, error, isSpanish),
        ),
      ),
    );
  }

  Widget _buildProfileContent(
    BuildContext context,
    WidgetRef ref,
    ProfileDto profile,
    bool isSpanish,
  ) {
    final locationText = [
      if (profile.city != null && profile.city!.isNotEmpty) profile.city,
      if (profile.country != null && profile.country!.isNotEmpty) profile.country,
    ].join(', ');

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(profileProvider);
      },
      color: AppTheme.primaryDark,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Column(
          children: [
            // Profile Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Avatar with fallback
                  Container(
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
                              placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              errorWidget: (context, url, error) => const Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.white,
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Name & Verified Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          profile.fullName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                          textAlign: TextAlign.center,
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

                  // Username
                  if (profile.username != null && profile.username!.isNotEmpty) ...[
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

                  // Role badge & Location
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                              Text(
                                locationText,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),

                  // Biography
                  if (profile.biography != null && profile.biography!.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      profile.biography!,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Buttons
                  Row(
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
                            onPressed: () {
                              // Action for edit profile
                            },
                            child: Text(
                              isSpanish ? 'Editar Perfil' : 'Edit Profile',
                              style: const TextStyle(color: AppTheme.primaryDark),
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
                            onPressed: onLanguageChangeClick,
                            child: Text(
                              isSpanish ? 'Elije un idioma' : 'Choose language',
                              style: const TextStyle(color: AppTheme.primaryDark),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Profile info items / Cards
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.language, color: AppTheme.primaryDark),
                        const SizedBox(height: 8),
                        Text(
                          isSpanish ? 'Idioma' : 'Language',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          profile.language.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          profile.isVerified ? Icons.verified_user : Icons.shield_outlined,
                          color: profile.isVerified ? Colors.green : AppTheme.textSecondary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isSpanish ? 'Verificación' : 'Verification',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          profile.isVerified
                              ? (isSpanish ? 'Verificado' : 'Verified')
                              : (isSpanish ? 'Pendiente' : 'Pending'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: profile.isVerified ? Colors.green : AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Patagonia Chile Banner / Card
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                color: AppTheme.primaryDark,
              ),
              padding: const EdgeInsets.all(20),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(
    BuildContext context,
    WidgetRef ref,
    Object error,
    bool isSpanish,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 16),
            Text(
              isSpanish ? 'Error al cargar el perfil' : 'Error loading profile',
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
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryDark,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              onPressed: () {
                ref.invalidate(profileProvider);
              },
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
}
