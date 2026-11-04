import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/providers/auth/auth_user_provider.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/itinerary_models.dart';
import '../../data/providers/planner_provider.dart';
import 'planificacion_screen.dart';

/// «Mis itinerarios» (HU-07): itinerarios guardados del usuario.
///
/// Requiere sesión iniciada y conexión. Solo el propietario ve y modifica sus
/// itinerarios (RLS de itineraries_v2).
class SavedItinerariesScreen extends ConsumerWidget {
  const SavedItinerariesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSpanish = ref.watch(languageProvider).languageCode == 'es';
    final user = ref.watch(authUserProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppTheme.slateLight,
      appBar: AppBar(
        title: Text(isSpanish ? 'Mis itinerarios' : 'My itineraries'),
      ),
      body: user == null
          ? _Message(
              icon: Icons.lock_outline_rounded,
              text: isSpanish
                  ? 'Inicia sesión para ver tus itinerarios guardados. Puedes crear una propuesta sin cuenta.'
                  : 'Sign in to see your saved itineraries. You can create a proposal without an account.',
              actionLabel: isSpanish ? 'Iniciar sesión' : 'Sign in',
              onAction: () => context.push(
                '/auth?from=${Uri.encodeComponent(savedItinerariesRoute)}',
              ),
            )
          : _SavedList(isSpanish: isSpanish),
    );
  }
}

class _SavedList extends ConsumerWidget {
  const _SavedList({required this.isSpanish});

  final bool isSpanish;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itinerariesAsync = ref.watch(savedItinerariesProvider);

    return itinerariesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => _Message(
        icon: Icons.cloud_off_rounded,
        text: isSpanish
            ? 'No se pudieron cargar tus itinerarios. Los itinerarios guardados necesitan conexión a Internet.'
            : 'Your itineraries could not be loaded. Saved itineraries need an Internet connection.',
        actionLabel: isSpanish ? 'Reintentar' : 'Retry',
        onAction: () => ref.invalidate(savedItinerariesProvider),
      ),
      data: (items) {
        if (items.isEmpty) {
          return _Message(
            icon: Icons.map_outlined,
            text: isSpanish
                ? 'Aún no guardas itinerarios.'
                : 'You have not saved any itineraries yet.',
            actionLabel: isSpanish ? 'Crear una propuesta' : 'Create a proposal',
            onAction: () => _backToPlanner(context),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(savedItinerariesProvider);
            await ref.read(savedItinerariesProvider.future);
          },
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) => _ItineraryTile(
              item: items[index],
              isSpanish: isSpanish,
            ),
          ),
        );
      },
    );
  }
}

class _ItineraryTile extends ConsumerWidget {
  const _ItineraryTile({required this.item, required this.isSpanish});

  final SavedItinerarySummary item;
  final bool isSpanish;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = item.updatedAt == null
        ? null
        : DateFormat('dd-MM-yyyy').format(item.updatedAt!);
    final count = isSpanish
        ? '${item.itemCount} ${item.itemCount == 1 ? 'lugar' : 'lugares'}'
        : '${item.itemCount} ${item.itemCount == 1 ? 'place' : 'places'}';

    return Card(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 6, 4, 6),
        leading: const Icon(Icons.route_rounded, color: AppTheme.primaryDark),
        title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
          date == null
              ? count
              : isSpanish
                  ? '$count · actualizado el $date'
                  : '$count · updated $date',
        ),
        onTap: () => _open(context, ref),
        trailing: IconButton(
          tooltip: isSpanish ? 'Eliminar' : 'Delete',
          icon: const Icon(Icons.delete_outline_rounded),
          onPressed: () => _delete(context, ref),
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final detail = await ref.read(plannerProvider.notifier).loadSaved(item.id);
      if (!context.mounted) return;
      _backToPlanner(context);
      if (detail.missingPlaces > 0) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              isSpanish
                  ? '${detail.missingPlaces} ${detail.missingPlaces == 1 ? 'lugar ya no está disponible y se omitió' : 'lugares ya no están disponibles y se omitieron'}.'
                  : '${detail.missingPlaces} place(s) are no longer available and were left out.',
            ),
          ),
        );
      }
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            isSpanish
                ? 'No se pudo abrir el itinerario. Revisa tu conexión.'
                : 'The itinerary could not be opened. Check your connection.',
          ),
        ),
      );
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isSpanish ? 'Eliminar itinerario' : 'Delete itinerary'),
        content: Text(
          isSpanish
              ? '¿Eliminar «${item.name}»? Esta acción no se puede deshacer.'
              : 'Delete "${item.name}"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(isSpanish ? 'Cancelar' : 'Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(isSpanish ? 'Eliminar' : 'Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(itineraryRepositoryProvider).delete(item.id);
      // Si estaba abierto en el planificador, deja de estar vinculado.
      final planner = ref.read(plannerProvider);
      if (planner.savedItineraryId == item.id) {
        ref.read(plannerProvider.notifier).reset();
      }
      ref.invalidate(savedItinerariesProvider);
      messenger.showSnackBar(
        SnackBar(content: Text(isSpanish ? 'Itinerario eliminado.' : 'Itinerary deleted.')),
      );
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            isSpanish
                ? 'No se pudo eliminar. Revisa tu conexión.'
                : 'It could not be deleted. Check your connection.',
          ),
        ),
      );
    }
  }
}

void _backToPlanner(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go('/itinerary');
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.text,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: AppTheme.textSecondary),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryDark),
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
