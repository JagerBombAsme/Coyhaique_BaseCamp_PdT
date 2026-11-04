import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/models/informational_content_dto.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../categories/data/providers/places_provider.dart';
import '../../data/safety_content.dart';

/// Pantalla «Antes de tu viaje» (HU-25, RNF-14).
///
/// Reúne los números de emergencia, los avisos de uso seguro y el contenido
/// informativo de Supabase (prevención, restricciones de acceso, guías de
/// transporte y cultura). Funciona sin conexión con la copia descargada.
class TripInfoScreen extends ConsumerWidget {
  const TripInfoScreen({super.key});

  static const Color _ink = Color(0xFF2E5F73);

  /// Orden y títulos de los tipos de contenido informativo.
  static const List<(String, String, String, IconData)> _sections = [
    ('prevencion', 'Recomendaciones preventivas', 'Safety recommendations',
        Icons.health_and_safety_rounded),
    ('restriccion', 'Restricciones de acceso', 'Access restrictions',
        Icons.block_rounded),
    ('guia_transporte', 'Guías de transporte', 'Transport guides',
        Icons.directions_bus_rounded),
    ('historia', 'Cultura e historia', 'Culture and history',
        Icons.museum_rounded),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSpanish = ref.watch(languageProvider).languageCode == 'es';
    final contentAsync = ref.watch(informationalContentProvider(null));

    return Scaffold(
      appBar: AppBar(
        title: Text(isSpanish ? 'Antes de tu viaje' : 'Before your trip'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(informationalContentProvider(null));
          await ref.read(informationalContentProvider(null).future);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _SectionTitle(
              icon: Icons.emergency_rounded,
              text: isSpanish ? 'Números de emergencia' : 'Emergency numbers',
            ),
            Card(
              child: Column(
                children: [
                  for (final item in emergencyNumbers)
                    ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        backgroundColor: _ink.withValues(alpha: 0.1),
                        child: Text(
                          item.number,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _ink,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      title: Text(isSpanish ? item.nameEs : item.nameEn),
                      trailing: const Icon(Icons.call_rounded, color: _ink),
                      onTap: () => launchUrl(Uri(scheme: 'tel', path: item.number)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _SectionTitle(
              icon: Icons.warning_amber_rounded,
              text: isSpanish ? 'Uso seguro de la aplicación' : 'Safe use of the app',
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    for (final notice in safetyNotices)
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.check_circle_outline_rounded),
                        title: Text(isSpanish ? notice.es : notice.en),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ...contentAsync.when(
              data: (items) => _buildContent(context, items, isSpanish),
              loading: () => const [
                Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
              error: (error, _) => [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          isSpanish
                              ? 'No se pudieron cargar las recomendaciones. Sin conexión, se muestran las descargadas; si aún no las descargas, conéctate e intenta de nuevo.'
                              : 'Recommendations could not be loaded. Offline, downloaded ones are shown; if you have not downloaded them yet, connect and try again.',
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: () =>
                              ref.invalidate(informationalContentProvider(null)),
                          child: Text(isSpanish ? 'Reintentar' : 'Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildContent(
    BuildContext context,
    List<InformationalContentDto> items,
    bool isSpanish,
  ) {
    final widgets = <Widget>[];

    for (final (type, titleEs, titleEn, icon) in _sections) {
      final group = items.where((item) => item.contentType == type).toList()
        ..sort((a, b) => a.getTitle(isSpanish).compareTo(b.getTitle(isSpanish)));
      if (group.isEmpty) continue;

      widgets
        ..add(_SectionTitle(icon: icon, text: isSpanish ? titleEs : titleEn))
        ..addAll(group.map((item) => _ContentCard(item: item, isSpanish: isSpanish)))
        ..add(const SizedBox(height: 20));
    }

    return widgets;
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: Row(
        children: [
          Icon(icon, color: TripInfoScreen._ink),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: TripInfoScreen._ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContentCard extends StatelessWidget {
  const _ContentCard({required this.item, required this.isSpanish});

  final InformationalContentDto item;
  final bool isSpanish;

  @override
  Widget build(BuildContext context) {
    final url = item.referenceUrl;
    final hasUrl = url != null && url.isNotEmpty && url != 'null';

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.getTitle(isSpanish),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 6),
            Text(item.getDescription(isSpanish)),
            if (hasUrl)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => launchUrl(
                    Uri.parse(url),
                    mode: LaunchMode.externalApplication,
                  ),
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: Text(isSpanish ? 'Ver fuente' : 'View source'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
