import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../core/theme/basecamp_tokens.dart';

/// Imagen PNG del marcador de un lugar: un círculo azul con el ícono de su
/// categoría en blanco (cubiertos, cama, montaña…), sin fotografías. Se dibuja
/// en código para no depender de archivos, como el pin de destino.
///
/// El anillo blanco separa el marcador del mapa en cualquier estilo (claro,
/// satélite). El centro del círculo es el centro de la imagen.
Future<Uint8List> buildPlaceMarkerPng(IconData icon) async {
  const size = 96.0;
  const center = Offset(size / 2, size / 2);

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  // Sombra suave, anillo blanco y relleno azul.
  canvas.drawCircle(
    center + const Offset(0, 2),
    40,
    Paint()
      ..color = const Color(0x40000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
  );
  canvas.drawCircle(center, 40, Paint()..color = Colors.white);
  canvas.drawCircle(center, 34, Paint()..color = BcColors.glacierDeep);

  final glyph = TextPainter(
    textDirection: TextDirection.ltr,
    text: TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
        fontSize: 40,
        color: Colors.white,
      ),
    ),
  )..layout();
  glyph.paint(canvas, center - Offset(glyph.width / 2, glyph.height / 2));

  final image = await recorder.endRecording().toImage(
    size.toInt(),
    size.toInt(),
  );
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  if (data == null) throw StateError('No se pudo generar el marcador');
  return data.buffer.asUint8List();
}
