import 'package:flutter/material.dart';

/// Paleta exclusiva de la barra de navegación inferior ([GlassNavBar]).
///
/// Centraliza todos los colores de la navbar para evitar valores
/// hardcodeados dispersos en el widget. Cada variante representa un
/// "cristal" con su scrim, borde y estados de selección, diseñados para
/// mantener contraste suficiente (apuntando a WCAG AA) sobre cualquier
/// fondo: fotos, mapas, fondos claros u oscuros.
///
/// Juego de colores de los iconos (paleta "azul hielo / azul / blanco",
/// equivalente a `HomeVisualTokens`): azul hielo para el icono inactivo,
/// azul para la píldora/píldora seleccionada y blanco para el icono
/// seleccionado sobre ella.
///
/// - Variante [light]: superficie oscura/translúcida con iconos claros
///   (ideal sobre fondos claros).
/// - Variante [dark]: superficie clara/translúcida con iconos oscuros
///   (ideal sobre fondos oscuros).
@immutable
class NavGlassColors extends ThemeExtension<NavGlassColors> {
  const NavGlassColors({
    required this.scrimTop,
    required this.scrimBottom,
    required this.border,
    required this.unselectedBackdrop,
    required this.unselectedForeground,
    required this.selectedContainer,
    required this.selectedForeground,
  });

  /// Tinte superior del degradado de la superficie de cristal (incluye alpha).
  final Color scrimTop;

  /// Tinte inferior del degradado de la superficie de cristal (incluye alpha).
  final Color scrimBottom;

  /// Borde sutil que separa la navbar del contenido que existe detrás.
  final Color border;

  /// Fondo del círculo que envuelve los iconos NO seleccionados.
  final Color unselectedBackdrop;

  /// Color de iconos/etiquetas NO seleccionados.
  final Color unselectedForeground;

  /// Fondo de la píldora/estado del elemento seleccionado.
  final Color selectedContainer;

  /// Color del icono/etiqueta seleccionada (equivalente a onPrimaryContainer).
  final Color selectedForeground;

  /// Variante por defecto para la app en modo claro (glass oscuro).
  static const light = NavGlassColors(
    // Slate azulado (deepIce) más transparente que antes: alpha ~58% / 46%.
    scrimTop: Color(0x94244E60),
    scrimBottom: Color(0x75244E60),
    // Borde blanco sutil (18%).
    border: Color(0x2EFFFFFF),
    // Círculo de apoyo de iconos no seleccionados: blanco 14%.
    unselectedBackdrop: Color(0x24FFFFFF),
    // Iconos no seleccionados: AZUL HIELO (iceBlue) 90%.
    unselectedForeground: Color(0xE6DDF3FC),
    // Píldora seleccionada: AZUL (accentBlue).
    selectedContainer: Color(0xFF2E7BB4),
    // Icono/label seleccionado: BLANCO (≈4.5:1 vs píldora).
    selectedForeground: Color(0xFFFFFFFF),
  );

  /// Variante lista para cuando la app use modo oscuro (glass claro).
  static const dark = NavGlassColors(
    // Hielo claro, más transparente que antes: alpha ~64% / 52%.
    scrimTop: Color(0xA3F0F9FD),
    scrimBottom: Color(0x85F0F9FD),
    // Borde azul profundo sutil (15%).
    border: Color(0x26244E60),
    // Círculo de apoyo de iconos no seleccionados: deepIce 10%.
    unselectedBackdrop: Color(0x1A244E60),
    // Iconos no seleccionados: AZUL (accentBlue) 90%.
    unselectedForeground: Color(0xE62E7BB4),
    // Píldora seleccionada: AZUL HIELO medio (iceBlueMedium).
    selectedContainer: Color(0xFFBFE6F4),
    // Icono/label seleccionado: azul profundo (deepIce) ≈6.8:1.
    selectedForeground: Color(0xFF244E60),
  );

  @override
  NavGlassColors copyWith({
    Color? scrimTop,
    Color? scrimBottom,
    Color? border,
    Color? unselectedBackdrop,
    Color? unselectedForeground,
    Color? selectedContainer,
    Color? selectedForeground,
  }) {
    return NavGlassColors(
      scrimTop: scrimTop ?? this.scrimTop,
      scrimBottom: scrimBottom ?? this.scrimBottom,
      border: border ?? this.border,
      unselectedBackdrop: unselectedBackdrop ?? this.unselectedBackdrop,
      unselectedForeground: unselectedForeground ?? this.unselectedForeground,
      selectedContainer: selectedContainer ?? this.selectedContainer,
      selectedForeground: selectedForeground ?? this.selectedForeground,
    );
  }

  @override
  NavGlassColors lerp(NavGlassColors? other, double t) {
    if (other is! NavGlassColors) {
      return this;
    }
    return NavGlassColors(
      scrimTop: Color.lerp(scrimTop, other.scrimTop, t)!,
      scrimBottom: Color.lerp(scrimBottom, other.scrimBottom, t)!,
      border: Color.lerp(border, other.border, t)!,
      unselectedBackdrop:
          Color.lerp(unselectedBackdrop, other.unselectedBackdrop, t)!,
      unselectedForeground:
          Color.lerp(unselectedForeground, other.unselectedForeground, t)!,
      selectedContainer: Color.lerp(selectedContainer, other.selectedContainer, t)!,
      selectedForeground:
          Color.lerp(selectedForeground, other.selectedForeground, t)!,
    );
  }
}
