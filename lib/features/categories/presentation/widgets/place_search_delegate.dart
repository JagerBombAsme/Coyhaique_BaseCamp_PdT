import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/text_normalizer.dart';
import '../../data/models/place_dto.dart';
import '../../data/providers/places_provider.dart';

/// Búsqueda de lugares y actividades desde el inicio (HU-04).
///
/// Busca en el nombre (español e inglés), la categoría y la dirección o punto
/// de encuentro, sin distinguir mayúsculas ni tildes. Usa los mismos
/// providers del catálogo, así que también funciona sin conexión con la
/// copia descargada (HU-10).
class PlaceSearchDelegate extends SearchDelegate<void> {
  PlaceSearchDelegate({required this.isSpanish})
      : super(
          searchFieldLabel: isSpanish
              ? 'Buscar lugares y actividades'
              : 'Search places and activities',
        );

  final bool isSpanish;

  @override
  List<Widget>? buildActions(BuildContext context) {
    if (query.isEmpty) return null;
    return [
      IconButton(
        tooltip: isSpanish ? 'Borrar' : 'Clear',
        icon: const Icon(Icons.clear_rounded),
        onPressed: () {
          query = '';
          showSuggestions(context);
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      tooltip: isSpanish ? 'Volver' : 'Back',
      icon: const Icon(Icons.arrow_back_rounded),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) => _results(context);

  @override
  Widget buildResults(BuildContext context) => _results(context);

  Widget _results(BuildContext context) {
    return _SearchResults(
      query: query,
      isSpanish: isSpanish,
      onSelected: (place) {
        final router = GoRouter.of(context);
        close(context, null);
        router.push('/attractions/${place.id}');
      },
    );
  }
}

class _SearchResults extends ConsumerWidget {
  const _SearchResults({
    required this.query,
    required this.isSpanish,
    required this.onSelected,
  });

  final String query;
  final bool isSpanish;
  final ValueChanged<PlaceDto> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final term = normalizeForSearch(query);

    if (term.isEmpty) {
      return _Message(
        icon: Icons.search_rounded,
        text: isSpanish
            ? 'Escribe el nombre de un lugar, una actividad o una categoría.'
            : 'Type the name of a place, an activity or a category.',
      );
    }

    final placesAsync = ref.watch(placesProvider);
    final activitiesAsync = ref.watch(activitiesProvider);

    if (placesAsync.isLoading || activitiesAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (placesAsync.hasError && activitiesAsync.hasError) {
      return _Message(
        icon: Icons.cloud_off_rounded,
        text: isSpanish
            ? 'No hay conexión ni información descargada.'
            : 'There is no connection and no downloaded information.',
        actionLabel: isSpanish ? 'Reintentar' : 'Retry',
        onAction: () {
          ref.invalidate(placesProvider);
          ref.invalidate(activitiesProvider);
        },
      );
    }

    final all = <PlaceDto>[
      ...placesAsync.valueOrNull ?? const <PlaceDto>[],
      ...activitiesAsync.valueOrNull ?? const <PlaceDto>[],
    ];

    final results = all.where((place) => _matches(place, term)).toList()
      ..sort(
        (a, b) => normalizeForSearch(a.getTitle(isSpanish))
            .compareTo(normalizeForSearch(b.getTitle(isSpanish))),
      );

    if (results.isEmpty) {
      return _Message(
        icon: Icons.search_off_rounded,
        text: isSpanish
            ? 'Sin resultados para «$query».'
            : 'No results for "$query".',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: results.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final place = results[index];
        final category = place.category?.getNombre(isSpanish ? 'es' : 'en');
        final subtitle = [
          if (category != null && category.isNotEmpty) category,
          if (place.getSubtitle(isSpanish).isNotEmpty)
            place.getSubtitle(isSpanish),
        ].join(' · ');

        return ListTile(
          leading: Icon(
            place.kind == 'activity'
                ? Icons.directions_run_rounded
                : Icons.place_rounded,
          ),
          title: Text(place.getTitle(isSpanish)),
          subtitle: subtitle.isEmpty
              ? null
              : Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => onSelected(place),
        );
      },
    );
  }

  bool _matches(PlaceDto place, String term) {
    final fields = [
      place.titleEs,
      place.titleEn,
      place.category?.nameEs,
      place.category?.nameEn,
      place.address,
      place.meetingPoint,
    ];
    return fields.any((field) => normalizeForSearch(field).contains(term));
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
            Icon(icon, size: 40, color: Colors.black38),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
