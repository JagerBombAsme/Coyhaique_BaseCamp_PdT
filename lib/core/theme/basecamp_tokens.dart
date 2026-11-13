import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Sistema de diseño «Coyhaique BaseCamp» (afiche de montaña).
///
/// Fuente única de colores, tipografía, radios y espaciado. Los valores son
/// los del sistema de diseño publicado (tokens.json). Las pantallas usan
/// estos tokens; no escriben colores ni tamaños a mano.
abstract final class BcColors {
  /// Texto principal y fondos oscuros (barra inferior, tiles oscuros).
  static const Color ink = Color(0xFF121416);

  /// Fondo de página: gris niebla.
  static const Color fog = Color(0xFFE8EBED);

  /// Cielo de niebla detrás del título del hero.
  static const Color fogDeep = Color(0xFFBFC6CA);

  /// Tarjetas claras, botones de esquina, búsqueda y campos.
  static const Color surface = Color(0xFFFFFFFF);

  /// Único acento. Solo como relleno, con texto [ink] encima (7,2:1).
  static const Color glacier = Color(0xFF3FA9F5);

  /// Acento como texto o ícono pequeño sobre fondo claro (5:1 sobre fog).
  static const Color glacierDeep = Color(0xFF1667A3);

  /// Texto secundario (4,8:1 sobre fog).
  static const Color muted = Color(0xFF5E676D);

  /// Bordes de campos y separadores.
  static const Color line = Color(0xFFD3D8DB);

  /// Texto sobre foto, siempre con [photoShade] debajo.
  static const Color onPhoto = Color(0xFFFFFFFF);

  /// Final del degradado oscuro bajo texto sobre foto.
  static const Color photoShade = Color(0xD9121416);

  /// Errores y acciones destructivas, siempre con ícono y texto.
  static const Color danger = Color(0xFFB3261E);
}

/// Paleta oscura para el modo oscuro de la Versión 2.0.
///
/// Aún no se usa en las pantallas: hoy todas leen [BcColors]. Queda definida
/// para migrar después sin volver a decidir colores. Mismos nombres que
/// [BcColors] para que el cambio sea uno a uno.
abstract final class BcDarkColors {
  /// Texto principal sobre fondos oscuros.
  static const Color ink = Color(0xFFE8EBED);

  /// Fondo de página.
  static const Color fog = Color(0xFF121416);

  /// Fondo hundido (detrás del título del hero).
  static const Color fogDeep = Color(0xFF0B0C0D);

  /// Tarjetas, botones de esquina, búsqueda y campos.
  static const Color surface = Color(0xFF1E2226);

  /// Acento: se mantiene, con texto oscuro encima.
  static const Color glacier = Color(0xFF3FA9F5);

  /// Acento como texto o ícono pequeño sobre fondo oscuro.
  static const Color glacierDeep = Color(0xFF7CC4F8);

  /// Texto secundario.
  static const Color muted = Color(0xFF9AA3A9);

  /// Bordes de campos y separadores.
  static const Color line = Color(0xFF2F363B);

  /// Texto sobre foto.
  static const Color onPhoto = Color(0xFFFFFFFF);

  /// Final del degradado oscuro bajo texto sobre foto.
  static const Color photoShade = Color(0xD9121416);

  /// Errores y acciones destructivas (versión clara para fondo oscuro).
  static const Color danger = Color(0xFFF2B8B5);
}

abstract final class BcRadius {
  static const double tag = 7;
  static const double control = 14;
  static const double field = 16;
  static const double tile = 20;
  static const double card = 24;
  static const double pill = 40;
}

abstract final class BcSpace {
  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;

  /// Margen lateral de página.
  static const double gutter = 20;

  /// Separación entre secciones.
  static const double section = 26;
}

/// Estilos de texto. Display: Inter 900 en MAYÚSCULAS (el texto se pasa ya
/// en mayúsculas con `.toUpperCase()`).
abstract final class BcText {
  static TextStyle display(double size, {Color color = BcColors.ink}) {
    return GoogleFonts.inter(
      fontSize: size,
      height: 0.9,
      fontWeight: FontWeight.w900,
      letterSpacing: size * -0.04,
      color: color,
    );
  }

  static TextStyle get displayHero => display(64, color: BcColors.onPhoto);
  static TextStyle get displaySection => display(46);
  static TextStyle get displayCard => display(27, color: BcColors.onPhoto);

  static TextStyle figure({Color color = BcColors.glacier}) =>
      display(50, color: color);

  static TextStyle label({Color color = BcColors.ink}) => GoogleFonts.inter(
    fontSize: 11,
    height: 1.3,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.9,
    color: color,
  );

  static TextStyle title({Color color = BcColors.ink}) => GoogleFonts.inter(
    fontSize: 15,
    height: 1.15,
    fontWeight: FontWeight.w700,
    color: color,
  );

  static TextStyle body({Color color = BcColors.muted}) => GoogleFonts.inter(
    fontSize: 14.5,
    height: 1.45,
    fontWeight: FontWeight.w400,
    color: color,
  );

  static TextStyle caption({Color color = BcColors.muted}) => GoogleFonts.inter(
    fontSize: 12.5,
    height: 1.3,
    fontWeight: FontWeight.w500,
    color: color,
  );

  static TextStyle button({Color color = BcColors.ink}) => GoogleFonts.inter(
    fontSize: 15,
    height: 1.2,
    fontWeight: FontWeight.w700,
    color: color,
  );
}

/// Tratamiento común de fotografía: desaturada a la mitad, +12 % de
/// contraste y −8 % de brillo.
abstract final class BcPhoto {
  static const ColorFilter filter = ColorFilter.matrix(<double>[
    0.5842, 0.4053, 0.0409, 0, -14.08, //
    0.1205, 0.8690, 0.0409, 0, -14.08, //
    0.1205, 0.4053, 0.5046, 0, -14.08, //
    0, 0, 0, 1, 0, //
  ]);

  /// Foto completa de Laguna Cerro Castillo y su recorte sin cielo (mismo
  /// encuadre), para que las cumbres corten el título del hero.
  ///
  static const String mountainHike = 'assets/images/mountain_hike.jpg';
  static const String cerroCastillo = 'assets/images/cerro_castillo_laguna.jpg';
  static const String cerroCastilloRecorte =
      'assets/images/cerro_castillo_recorte.webp';

  /// Montañistas: bienvenida y ubicación. [PENDIENTE] reemplazar por una
  /// foto de Aysén con licencia verificada.
  static const String montanistas = 'assets/images/climbers_language.jpg';

  static const String gauchosinr =
      'assets/images/gaucho_sinrostro.png'; // Gaucho sin rostro, para la sección de ubicación.
}

/// Logo BC (el excursionista dentro de la B).
abstract final class BcBrand {
  /// Logo en tinta, para fondos claros (fog, surface).
  static const String logoInk = 'assets/images/bc_logo_ink.png';

  /// Logo en blanco, para fondos oscuros y fotos.
  static const String logoWhite = 'assets/images/bc_logo_white.png';
}
