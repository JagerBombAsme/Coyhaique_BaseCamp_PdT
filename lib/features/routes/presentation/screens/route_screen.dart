import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/widgets/basecamp/bc_motion.dart';
import '../../data/providers/route_provider.dart';

class RouteScreen extends ConsumerWidget {
  final ValueChanged<String> onRouteClick;

  const RouteScreen({
    super.key,
    required this.onRouteClick,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(languageProvider);
    final isSpanish = locale.languageCode == 'es';
    final routesAsync = ref.watch(routesProvider);

    return Scaffold(
      backgroundColor: AppTheme.slateLight,
      appBar: AppBar(
        title: Text(isSpanish ? 'Rutas de Aventura' : 'Adventure Routes'),
        backgroundColor: Colors.white,
      ),
      body: routesAsync.when(
        data: (routes) {
          if (routes.isEmpty) {
            return _ComingSoon(isSpanish: isSpanish);
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(routesProvider);
            },
            color: AppTheme.primaryDark,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              itemCount: routes.length,
              itemBuilder: (context, index) {
                final item = routes[index];
                return BcEntrance(
                  key: ValueKey(item.id),
                  index: index,
                  child: Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 2,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => onRouteClick(item.id),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  item.getTitle(isSpanish),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentLightBlue,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  item.getDifficulty(isSpanish),
                                  style: const TextStyle(
                                    color: AppTheme.accentBlue,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item.getDescription(isSpanish),
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.timer, size: 16, color: AppTheme.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                item.duration,
                                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                              ),
                              if (item.distanceKm != null) ...[
                                const SizedBox(width: 16),
                                const Icon(Icons.straighten, size: 16, color: AppTheme.textSecondary),
                                const SizedBox(width: 4),
                                Text(
                                  '${item.distanceKm} km',
                                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                                ),
                              ],
                              const Spacer(),
                              Text(
                                isSpanish ? 'Ver ruta ->' : 'View route ->',
                                style: const TextStyle(
                                  color: AppTheme.primaryDark,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryDark),
        ),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.redAccent),
              const SizedBox(height: 16),
              Text(
                isSpanish ? 'Error al cargar rutas' : 'Error loading routes',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryDark),
                onPressed: () => ref.invalidate(routesProvider),
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: Text(isSpanish ? 'Reintentar' : 'Retry', style: const TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Aviso mientras no hay rutas publicadas (HU-20 queda como trabajo futuro).
class _ComingSoon extends StatelessWidget {
  const _ComingSoon({required this.isSpanish});

  final bool isSpanish;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.hiking_rounded,
              size: 64,
              color: AppTheme.primaryDark,
            ),
            const SizedBox(height: 16),
            Text(
              isSpanish ? 'Próximamente' : 'Coming soon',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSpanish
                  ? 'Estamos preparando las rutas de aventura. Mientras tanto, explora las actividades y tours desde Explorar.'
                  : 'We are preparing the adventure routes. Meanwhile, explore activities and tours from Explore.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: Text(isSpanish ? 'Volver' : 'Back'),
            ),
          ],
        ),
      ),
    );
  }
}
