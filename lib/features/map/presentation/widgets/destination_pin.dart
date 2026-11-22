import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../core/theme/basecamp_tokens.dart';

/// Imagen PNG del marcador de destino: un pin con una bandera. Se dibuja en
/// código (no hay archivo) y su forma lo distingue del punto azul de «mi
/// ubicación». La punta del pin queda abajo, en el centro.
Future<Uint8List> buildDestinationPinPng() async {
  const width = 120.0;
  const height = 160.0;
  const head = Offset(60, 58);

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  final pin = Path.combine(
    PathOperation.union,
    Path()..addOval(Rect.fromCircle(center: head, radius: 46)),
    Path()
      ..moveTo(60 - 36, 58 + 30)
      ..lineTo(60 + 36, 58 + 30)
      ..lineTo(60, 150)
      ..close(),
  );

  canvas.drawShadow(pin.shift(const Offset(0, 3)), Colors.black, 5, true);
  canvas.drawPath(pin, Paint()..color = BcColors.glacierDeep);
  canvas.drawPath(
    pin,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeJoin = StrokeJoin.round
      ..color = Colors.white,
  );
  canvas.drawCircle(head, 25, Paint()..color = Colors.white);

  const flag = Icons.flag_rounded;
  final glyph = TextPainter(
    textDirection: TextDirection.ltr,
    text: TextSpan(
      text: String.fromCharCode(flag.codePoint),
      style: TextStyle(
        fontFamily: flag.fontFamily,
        fontSize: 36,
        color: BcColors.glacierDeep,
      ),
    ),
  )..layout();
  glyph.paint(canvas, head - Offset(glyph.width / 2, glyph.height / 2));

  final image = await recorder.endRecording().toImage(
    width.toInt(),
    height.toInt(),
  );
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  if (data == null) throw StateError('No se pudo generar el pin de destino');
  return data.buffer.asUint8List();
}
