import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/language_provider.dart';

class RouteItem {
  final String id;
  final String title;
  final String description;
  final String duration;
  final String difficulty;

  const RouteItem({
    required this.id,
    required this.title,
    required this.description,
    required this.duration,
    required this.difficulty,
  });
}

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

    final routes = [
      RouteItem(
        id: '1',
        title: isSpanish ? 'Ruta Miradores' : 'Viewpoints Route',
        description: isSpanish
            ? 'Descubre los mejores miradores de Coyhaique con vistas panorámicas.'
            : 'Discover the best viewpoints of Coyhaique with panoramic views.',
        duration: '2h 30m',
        difficulty: isSpanish ? 'Baja' : 'Low',
      ),
      RouteItem(
        id: '2',
        title: isSpanish ? 'Sendero Los Leñeros' : 'Los Leñeros Trail',
        description: isSpanish
            ? 'Sendero corto con dos miradores hacia la ciudad de Coyhaique.'
            : 'Short trail with two viewpoints overlooking the city of Coyhaique.',
        duration: '1h 45m',
        difficulty: isSpanish ? 'Baja' : 'Low',
      ),
      RouteItem(
        id: '3',
        title: isSpanish ? 'Circuito 4 Lagunas' : '4 Lakes Circuit',
        description: isSpanish
            ? 'Recorrido completo que conecta las 4 lagunas de la Reserva Nacional.'
            : 'Full tour connecting the 4 lakes of the National Reserve.',
        duration: '4h 00m',
        difficulty: isSpanish ? 'Media' : 'Medium',
      ),
      RouteItem(
        id: '4',
        title: isSpanish ? 'Ascenso Cerro Cinchao' : 'Mount Cinchao Climb',
        description: isSpanish
            ? 'Desafío a la cima del cerro Cinchao (1.361 m) con vista panorámica.'
            : 'Challenge to the summit of Mount Cinchao (1,361 m) with panoramic views.',
        duration: '6h 00m',
        difficulty: isSpanish ? 'Alta' : 'High',
      ),
    ];

    return Scaffold(
      backgroundColor: AppTheme.slateLight,
      appBar: AppBar(
        title: Text(isSpanish ? 'Rutas de Aventura' : 'Adventure Routes'),
        backgroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: routes.length,
        itemBuilder: (context, index) {
          final item = routes[index];
          return Card(
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
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.accentLightBlue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            item.difficulty,
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
                      item.description,
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
          );
        },
      ),
    );
  }
}
