import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../categories/presentation/screens/place_detail_screen.dart';

/// Detalle de atractivo (HU-02) adaptado para GoRouter según USER_FLOWS.md
class AttractionDetailView extends StatelessWidget {
  final String attractionId;

  const AttractionDetailView({
    super.key,
    required this.attractionId,
  });

  @override
  Widget build(BuildContext context) {
    return PlaceDetailScreen(
      placeId: attractionId,
      onBack: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/home');
        }
      },
    );
  }
}
