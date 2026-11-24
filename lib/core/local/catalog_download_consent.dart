import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/language_provider.dart';
import 'catalog_status_provider.dart';

/// Clave de SharedPreferences: la persona aceptó la descarga automática.
const String catalogDownloadAcceptedKey = 'catalog_download_accepted_v1';

/// Pide, una sola vez, aceptar la descarga del catálogo (HU-09, HU-10).
///
/// El mensaje explica qué se descarga, para qué y cada cuánto. Al aceptar,
/// se descarga de inmediato y, desde entonces, cada vez que se abre la app
/// (`main.dart`). Si la persona elige «Ahora no», no se descarga y el mensaje
/// vuelve a aparecer en la próxima apertura; el botón «Descargar
/// información» del inicio sigue disponible.
Future<void> askCatalogDownloadIfNeeded(
  BuildContext context,
  WidgetRef ref,
) async {
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool(catalogDownloadAcceptedKey) ?? false) return;
  if (!context.mounted) return;

  final es = ref.read(languageProvider).languageCode == 'es';
  final accepted = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      icon: const Icon(Icons.download_for_offline_rounded, size: 36),
      title: Text(
        es
            ? 'Descargar la información para usarla sin señal'
            : 'Download the information to use it without signal',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              es
                  ? 'Fuera de la ciudad suele no haber señal. Para que la aplicación funcione igual, vamos a guardar en tu teléfono:'
                  : 'There is often no signal outside the city. So the app keeps working, we will save on your phone:',
            ),
            const SizedBox(height: 8),
            Text(
              es
                  ? '• Lugares, actividades y servicios hasta 50 km de Coyhaique.\n• Traslados del aeropuerto.\n• Información preventiva y números de emergencia.'
                  : '• Places, activities and services up to 50 km from Coyhaique.\n• Airport transfers.\n• Safety information and emergency numbers.',
            ),
            const SizedBox(height: 12),
            Text(
              es
                  ? 'Se descarga ahora y se actualiza sola cada vez que abras la aplicación con conexión. Usa pocos datos y no guarda ningún dato tuyo. Los mapas y las rutas siguen necesitando conexión.'
                  : 'It downloads now and updates by itself every time you open the app with a connection. It uses little data and stores none of your data. Maps and routes still need a connection.',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(es ? 'Ahora no' : 'Not now'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(es ? 'Descargar' : 'Download'),
        ),
      ],
    ),
  );

  if (accepted != true) return;
  await prefs.setBool(catalogDownloadAcceptedKey, true);
  unawaited(ref.read(catalogStatusProvider.notifier).download());
}
