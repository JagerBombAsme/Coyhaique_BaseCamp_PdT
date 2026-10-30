
import 'package:flutter/material.dart';

abstract final class HomeVisualTokens {
  // ── Paleta Coyhaique BaseCamp: hielo, nieve y agua patagónica ──────────
  static const Color background = Color(0xFFF7FCFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFF0F9FD);
  static const Color surfaceMuted = Color(0xFFE5F4FA);

  static const Color iceBlue = Color(0xFFDDF3FC);
  static const Color iceBlueMedium = Color(0xFFBFE6F4);
  static const Color accent = Color(0xFF67B7D1);
  static const Color accentStrong = Color(0xFF3D91AE);
  static const Color deepIce = Color(0xFF244E60);

  static const Color textPrimary = Color(0xFF244652);
  static const Color textSecondary = Color(0xFF6A8490);

  // Alias conservado para no romper widgets existentes.
  static const Color sage = iceBlueMedium;

  /// Contorno frío muy suave para superficies claras.
  static const Color outline = Color(0x335FA8C6);

  // ── Espaciado ──────────────────────────────────────────────────────────
  static const double pagePadding = 24;
  static const double sectionMargin = 12;
  static const double sectionGap = 12;
  static const EdgeInsets sectionPadding = EdgeInsets.fromLTRB(0, 22, 0, 22);

  // ── Radios ─────────────────────────────────────────────────────────────
  static const double sectionRadius = 32;
  static const double cardRadius = 24;
  static const double imageRadius = 20;
  static const double controlRadius = 16;

  static double innerRadius(double outerRadius, double padding) =>
      (outerRadius - padding).clamp(0.0, outerRadius).toDouble();

  // ── Movimiento ─────────────────────────────────────────────────────────
  static const double pressScale = 0.96;
  static const Duration pressDuration = Duration(milliseconds: 110);
  static const Duration stateDuration = Duration(milliseconds: 150);
  static const Duration iconDuration = Duration(milliseconds: 300);
  static const Curve iconCurve = Cubic(0.2, 0, 0, 1);

  // ── Sombras ─────────────────────────────────────────────────────────────
  static const List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: Color(0x1A3D91AE),
      blurRadius: 28,
      offset: Offset(0, 12),
    ),
    BoxShadow(
      color: Color(0x12000000),
      blurRadius: 10,
      offset: Offset(0, 3),
    ),
  ];

  static const List<BoxShadow> softShadow = [
    BoxShadow(
      color: Color(0x243D91AE),
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
  ];

  // ── Tipografía ─────────────────────────────────────────────────────────
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 25,
    height: 1.1,
    fontWeight: FontWeight.w800,
    color: textPrimary,
    letterSpacing: -0.7,
  );

  static const TextStyle cardTitle = TextStyle(
    color: textPrimary,
    fontSize: 16,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.25,
  );

  static const TextStyle caption = TextStyle(
    color: textSecondary,
    fontSize: 13,
    height: 1.25,
    fontWeight: FontWeight.w400,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle badge = TextStyle(
    fontSize: 12,
    height: 1,
    fontWeight: FontWeight.w700,
    color: accentStrong,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  // Etiquetas superpuestas a fotografías: blanco para asegurar contraste.
  static const TextStyle tileLabel = TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.w600,
    fontSize: 14,
    height: 1.2,
    letterSpacing: -0.1,
  );
}
