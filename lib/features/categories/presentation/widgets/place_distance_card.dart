import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/basecamp_tokens.dart';
import '../../../planner/domain/itinerary_planner.dart';
import '../../data/models/place_dto.dart';
import '../../data/providers/place_distance_provider.dart';

/// Distancia en línea recta desde Plaza de Armas o desde la ubicación del
/// usuario, con el formato de la identidad: tarjeta ink y cifra en glacier.
class PlaceDistanceCard extends ConsumerWidget {
  const PlaceDistanceCard({
    super.key,
    required this.place,
    required this.isSpanish,
  });

  final PlaceDto place;
  final bool isSpanish;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lat = place.latitude;
    final lon = place.longitude;
    if (lat == null || lon == null) return const SizedBox.shrink();

    final fromLocation = ref.watch(placeDistanceOriginProvider);
    final position = fromLocation ? ref.watch(currentPositionProvider) : null;
    final loading = fromLocation && (position?.isLoading ?? false);
    final userOrigin = fromLocation ? position?.valueOrNull : null;
    final failed = fromLocation && !loading && userOrigin == null;

    final km = ItineraryPlanner.distanceKm(
      userOrigin?.latitude ?? ItineraryPlanner.coyhaique.latitude,
      userOrigin?.longitude ?? ItineraryPlanner.coyhaique.longitude,
      lat,
      lon,
    );

    final kmText = loading ? '—' : km.toStringAsFixed(1);
    final unit = loading ? '' : ' km';

    final caption = isSpanish
        ? (userOrigin != null
              ? 'En línea recta desde tu ubicación'
              : 'En línea recta desde Plaza de Armas')
        : (userOrigin != null
              ? 'Straight line from your location'
              : 'Straight line from Plaza de Armas');

    final note = loading
        ? (isSpanish ? 'Buscando tu ubicación…' : 'Finding your location…')
        : failed
        ? (isSpanish
              ? 'No se pudo obtener tu ubicación; se muestra la distancia desde Plaza de Armas.'
              : 'Your location could not be obtained; distance is shown from Plaza de Armas.')
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedButton<bool>(
          style: SegmentedButton.styleFrom(
            backgroundColor: BcColors.surface,
            foregroundColor: BcColors.ink,
            selectedBackgroundColor: BcColors.ink,
            selectedForegroundColor: BcColors.onPhoto,
            side: BorderSide.none,
          ),
          segments: [
            ButtonSegment(
              value: false,
              icon: const Icon(Icons.location_city_rounded),
              label: const Text('Plaza de Armas'),
            ),
            ButtonSegment(
              value: true,
              icon: const Icon(Icons.my_location_rounded),
              label: Text(isSpanish ? 'Mi ubicación' : 'My location'),
            ),
          ],
          selected: {fromLocation},
          onSelectionChanged: (value) => ref
              .read(placeDistanceOriginProvider.notifier)
              .setFromLocation(value.first),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: BcColors.ink,
            borderRadius: BorderRadius.circular(BcRadius.tile),
          ),
          child: Row(
            children: [
              const Icon(Icons.route_rounded, color: BcColors.glacier),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: kmText,
                            style: BcText.display(40, color: BcColors.glacier),
                          ),
                          TextSpan(
                            text: unit,
                            style: BcText.title(color: BcColors.glacier),
                          ),
                        ],
                      ),
                    ),
                    Text(caption, style: BcText.body(color: BcColors.onPhoto)),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (note != null) ...[
          const SizedBox(height: 8),
          Text(note, style: BcText.body(color: BcColors.muted)),
        ],
      ],
    );
  }
}
