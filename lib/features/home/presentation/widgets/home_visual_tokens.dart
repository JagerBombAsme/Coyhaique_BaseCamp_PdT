import 'package:flutter/material.dart';

abstract final class HomeVisualTokens {
  // ── Colores ────────────────────────────────────────────────────────────
  static const Color background = Color(0xFF171619);
  static const Color surface = Color(0xFF211F22);
  static const Color surfaceElevated = Color(0xFF29262C);
  static const Color surfaceMuted = Color(0xFF2C2A2F);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFC7C2CB);
  static const Color accent = Color(0xFFFFC857);
  static const Color sage = Color(0xFF8DA66D);

  /// Contorno de imágenes y controles: blanco puro al 10 % (UI oscura).
  /// Nunca un gris tintado: tomaría el color de la superficie y se vería sucio.
  static const Color outline = Color(0x1AFFFFFF);

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

  /// Radio concéntrico: interior = exterior − padding.
  static double innerRadius(double outerRadius, double padding) =>
      (outerRadius - padding).clamp(0.0, outerRadius).toDouble();

  // ── Movimiento ─────────────────────────────────────────────────────────
  static const double pressScale = 0.96;
  static const Duration pressDuration = Duration(milliseconds: 110);
  static const Duration stateDuration = Duration(milliseconds: 150);
  static const Duration iconDuration = Duration(milliseconds: 300);
  static const Curve iconCurve = Cubic(0.2, 0, 0, 1);

  // ── Sombras (elevación = sombra, no borde) ─────────────────────────────
  static const List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: Color(0x33000000),
      blurRadius: 24,
      offset: Offset(0, 10),
    ),
    BoxShadow(
      color: Color(0x14FFFFFF),
      blurRadius: 0,
      spreadRadius: 1,
    ),
  ];

  static const List<BoxShadow> softShadow = [
    BoxShadow(
      color: Color(0x26000000),
      blurRadius: 18,
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

  /// Con cifras tabulares: "8h 00m" no "baila" al cambiar de tarjeta.
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
    color: Color(0xB8FFFFFF),
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle tileLabel = TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.w600,
    fontSize: 14,
    height: 1.2,
    letterSpacing: -0.1,
  );
}
