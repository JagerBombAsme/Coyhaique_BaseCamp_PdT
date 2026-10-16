import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/profile/data/providers/profile_provider.dart';
import '../theme/app_theme.dart';

class HomeHeader extends ConsumerWidget {
  final VoidCallback onProfileClick;

  const HomeHeader({
    super.key,
    required this.onProfileClick,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return Padding(
      padding: const EdgeInsets.only(top: 6.0, bottom: 22.0),
      child: Row(
        children: [
          Expanded(
            child: profileAsync.when(
              data: (profile) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hola, ${profile.fullName.split(' ').first}',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profile.role.toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.accentBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              loading: () => const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hola, Explorador',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Cargando perfil...',
                    style: TextStyle(
                      color: AppTheme.accentBlue,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              error: (_, _) => const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hola, Visitante',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Coyhaique BaseCamp',
                    style: TextStyle(
                      color: AppTheme.accentBlue,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: onProfileClick,
            child: Container(
              width: 60,
              height: 60,
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
              padding: const EdgeInsets.all(3),
              child: ClipOval(
                child: profileAsync.when(
                  data: (profile) => profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: profile.avatarUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (_, _, _) => const CircleAvatar(
                            backgroundColor: AppTheme.primaryDark,
                            child: Icon(Icons.person, color: Colors.white, size: 28),
                          ),
                        )
                      : const CircleAvatar(
                          backgroundColor: AppTheme.primaryDark,
                          child: Icon(Icons.person, color: Colors.white, size: 28),
                        ),
                  loading: () => const CircleAvatar(
                    backgroundColor: AppTheme.primaryDark,
                    child: Icon(Icons.person, color: Colors.white, size: 28),
                  ),
                  error: (_, _) => const CircleAvatar(
                    backgroundColor: AppTheme.primaryDark,
                    child: Icon(Icons.person, color: Colors.white, size: 28),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
