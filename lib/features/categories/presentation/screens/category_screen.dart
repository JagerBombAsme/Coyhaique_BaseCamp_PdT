import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import 'alojamiento_screen.dart';
import 'cultura_screen.dart';
import 'gastronomia_screen.dart';
import 'transporte_screen.dart';

class CategoryScreen extends StatelessWidget {
  final String category;
  final ValueChanged<String> onPlaceClick;
  final VoidCallback onRoutesClick;

  const CategoryScreen({
    super.key,
    required this.category,
    required this.onPlaceClick,
    required this.onRoutesClick,
  });

  @override
  Widget build(BuildContext context) {
    switch (category) {
      case 'cultura':
        return CulturaScreen(onPlaceClick: onPlaceClick);
      case 'alojamientos':
      case 'alojamiento':
        return AlojamientoScreen(onPlaceClick: onPlaceClick);
      case 'transporte':
        return TransporteScreen(onPlaceClick: onPlaceClick);
      case 'gastronomia':
        return GastronomiaScreen(onPlaceClick: onPlaceClick);
      case 'aventura':
        // Redirects to routes screen
        WidgetsBinding.instance.addPostFrameCallback((_) {
          onRoutesClick();
        });
        return const SizedBox.shrink();
      default:
        return ComingSoonScreen(category: category);
    }
  }
}

class ComingSoonScreen extends StatelessWidget {
  final String category;

  const ComingSoonScreen({
    super.key,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final title = category.isEmpty
        ? 'Próximamente'
        : 'Próximamente: ${category[0].toUpperCase()}${category.substring(1)}';

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: AppTheme.accentLightBlue,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.accentBlue,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
