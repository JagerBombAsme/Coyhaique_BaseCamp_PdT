/// Contenido fijo de seguridad de la pantalla «Antes de tu viaje» (HU-25,
/// RNF-14). El contenido preventivo variable (prevención, restricciones,
/// guías y cultura) viene de informational_content_v2.
///
/// Números de emergencia de Chile. Fuente secundaria: 24horas.cl (2026).
/// PENDIENTE: Franco verifica cada número con la fuente oficial de cada
/// institución antes del congelamiento (tarea «Redactar avisos de uso
/// seguro y contenidos de prevención»).
class EmergencyNumber {
  final String number;
  final String nameEs;
  final String nameEn;

  const EmergencyNumber(this.number, this.nameEs, this.nameEn);
}

const List<EmergencyNumber> emergencyNumbers = [
  EmergencyNumber('133', 'Carabineros', 'Police (Carabineros)'),
  EmergencyNumber('131', 'Ambulancia (SAMU)', 'Ambulance (SAMU)'),
  EmergencyNumber('132', 'Bomberos', 'Fire department'),
  EmergencyNumber('130', 'CONAF: incendios forestales', 'CONAF: forest fires'),
  EmergencyNumber('136', 'Socorro Andino', 'Andean rescue'),
  EmergencyNumber('137', 'Rescate marítimo', 'Maritime rescue'),
  EmergencyNumber(
    '134',
    'Policía de Investigaciones (PDI)',
    'Investigative police (PDI)',
  ),
];

/// Avisos de uso seguro (RNF-14).
class SafetyNotice {
  final String es;
  final String en;

  const SafetyNotice(this.es, this.en);
}

const List<SafetyNotice> safetyNotices = [
  SafetyNotice(
    'Coyhaique BaseCamp no es un servicio de emergencia ni entrega información en tiempo real. Ante una emergencia, llama a los números de esta pantalla.',
    'Coyhaique BaseCamp is not an emergency service and does not provide real-time information. In an emergency, call the numbers on this screen.',
  ),
  SafetyNotice(
    'La información es referencial: confirma horarios, precios y condiciones con cada establecimiento antes de ir. Cada ficha indica su fecha de verificación.',
    'Information is for reference only: confirm hours, prices and conditions with each business before going. Each listing shows its verification date.',
  ),
  SafetyNotice(
    'No manipules el teléfono mientras conduces. Revisa la ruta antes de salir o pide a un acompañante que la revise.',
    'Do not handle your phone while driving. Check the route before leaving or ask a passenger to check it.',
  ),
  SafetyNotice(
    'Las rutas son referenciales: no consideran el estado del camino (ripio, nieve o hielo), el clima ni los cierres.',
    'Routes are for reference only: they do not consider road conditions (gravel, snow or ice), weather or closures.',
  ),
  SafetyNotice(
    'Muchas zonas no tienen señal: descarga la información antes de salir. El mapa y las rutas necesitan conexión.',
    'Many areas have no signal: download the information before leaving. The map and routes need a connection.',
  ),
  SafetyNotice(
    'Respeta la propiedad privada y los accesos señalizados. Ingresa solo a lugares públicos o autorizados.',
    'Respect private property and marked access points. Only enter public or authorized places.',
  ),
];
