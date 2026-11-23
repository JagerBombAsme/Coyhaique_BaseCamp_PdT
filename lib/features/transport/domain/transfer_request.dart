import 'dart:math';

import '../data/models/transfer_service.dart';

/// Lugar de recogida que elige el pasajero: un alojamiento (del catálogo o
/// uno escrito por él), un punto de referencia fijo, o cualquier otro lugar
/// que escribe a mano. Lo escrito a mano no se valida: lo confirma la empresa.
enum TransferPickupKind { lodging, center, terminal, other }

/// Medio de pago que el pasajero le anuncia a la empresa. La app no cobra.
enum TransferPayment { cash, card }

/// Puntos de referencia fijos de recogida.
abstract final class TransferPickupPoints {
  static const String centerEs = 'Centro de Coyhaique, Plaza de Armas';
  static const String centerEn = 'Coyhaique town centre, Plaza de Armas';

  static const String terminalEs = 'Terminal de buses de Coyhaique';
  static const String terminalEn = 'Coyhaique bus terminal';

  /// Largo máximo de un texto escrito a mano (recogida, fecha y vuelo).
  static const int maxTypedLength = 80;

  /// Largo máximo del número de vuelo.
  static const int maxFlightLength = 10;

  /// Deja el número de vuelo en mayúsculas, solo con letras, números, espacio
  /// y guion, en una línea y con el largo máximo. Vacío si no escribió nada.
  static String cleanFlight(String raw) {
    final cleaned = raw
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9 -]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return cleaned.length <= maxFlightLength
        ? cleaned
        : cleaned.substring(0, maxFlightLength).trim();
  }

  /// Largo mínimo para dar por escrito un texto.
  static const int minTypedLength = 3;

  /// Deja un texto escrito a mano listo para el mensaje de WhatsApp:
  /// una sola línea, sin los caracteres de formato (*, _, ~, `) que lo
  /// romperían, y con el largo máximo.
  static String cleanTyped(String raw) {
    final collapsed = raw
        .replaceAll(RegExp(r'[*_~`]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return collapsed.length <= maxTypedLength
        ? collapsed
        : collapsed.substring(0, maxTypedLength).trim();
  }

  /// Whether [raw] tiene texto suficiente una vez limpio.
  static bool isTypedValid(String raw) =>
      cleanTyped(raw).length >= minTypedLength;
}

/// Solicitud de traslado HACIA el aeropuerto, armada en el teléfono del
/// pasajero (HU-18). Se envía a la empresa por WhatsApp, con anticipación.
///
/// Contiene solo lo que la empresa necesita: código corto, lugar de
/// recogida, fecha y hora de recogida, vuelo (opcional), pasajeros, equipaje
/// y medio de pago. No
/// lleva nombre, teléfono, correo ni la ubicación del teléfono, y la app no
/// la guarda en ningún servidor. Si la recogida la escribió el pasajero
/// ([pickupIsTyped], p. ej. la dirección de su alojamiento), el mensaje le
/// pide a la empresa confirmarla. Ojo: al enviarla por WhatsApp la empresa
/// ve el número del pasajero, como en cualquier chat.
class TransferRequest {
  const TransferRequest({
    required this.service,
    required this.code,
    required this.pickupKind,
    required this.pickupEs,
    required this.pickupEn,
    required this.pickupAt,
    required this.passengers,
    required this.bigLuggage,
    required this.payment,
    required this.createdAt,
    this.flight,
    this.pickupIsTyped = false,
  });

  final TransferService service;
  final String code;
  final TransferPickupKind pickupKind;
  final String pickupEs;
  final String pickupEn;

  /// Fecha y hora de recogida que eligió el pasajero.
  final DateTime pickupAt;

  /// Número de vuelo, ya limpio. null o vacío si no lo indicó.
  final String? flight;
  final int passengers;
  final bool bigLuggage;
  final TransferPayment payment;
  final DateTime createdAt;

  /// Whether la recogida la escribió el pasajero (no viene del catálogo ni
  /// es un punto fijo), así que la empresa debe confirmarla.
  final bool pickupIsTyped;

  String pickup(bool isSpanish) => isSpanish ? pickupEs : pickupEn;

  String paymentLabel(bool isSpanish) => switch (payment) {
        TransferPayment.cash => isSpanish ? 'Efectivo' : 'Cash',
        TransferPayment.card => isSpanish ? 'Tarjeta' : 'Card',
      };

  String fareLabel(bool isSpanish) {
    final fare = service.referenceFareClp;
    if (fare == null) return isSpanish ? 'Por confirmar' : 'To be confirmed';
    return formatClp(fare);
  }

  /// Mensaje para la empresa, siempre en español (lo lee la empresa local).
  /// Usa el formato de WhatsApp: *negrita* y _cursiva_.
  String driverMessage() {
    final lines = <String>[
      '*SOLICITUD DE TRASLADO AL AEROPUERTO · $code*',
      'Coyhaique BaseCamp',
      '',
      '*Recogida:* $pickupEs',
      if (pickupIsTyped)
        '_Recogida escrita por el pasajero: confírmala con él._',
      '*Destino:* ${service.originEs}',
      '*Fecha y hora de recogida:* ${formatDate(pickupAt)} a las ${formatTime(pickupAt)}',
      if (flight != null && flight!.isNotEmpty) '*Vuelo:* $flight',
      '*Pasajeros:* $passengers',
      '*Equipaje grande:* ${bigLuggage ? 'Sí' : 'No'}',
      '*Pago:* ${paymentLabel(true)}',
      '*Tarifa referencial:* ${fareLabel(true)}',
      '',
      '_Creado el ${formatDate(createdAt)} a las ${formatTime(createdAt)}_',
    ];
    return lines.join('\n');
  }

  /// Enlace que abre WhatsApp con el mensaje listo para la empresa.
  /// null si la empresa no habilitó el QR o su ficha sigue pendiente.
  Uri? whatsappUri() {
    if (!service.canGenerateQr) return null;
    // encodeComponent deja los espacios como %20 (no «+»), que WhatsApp
    // muestra siempre como espacios.
    return Uri.parse(
      'https://wa.me/${service.whatsappNumber}'
      '?text=${Uri.encodeComponent(driverMessage())}',
    );
  }

  /// Código corto para identificar la solicitud («BC-7K2»).
  /// Sin letras que se confunden (0/O, 1/I/L).
  static String newCode([Random? random]) {
    const alphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
    final rng = random ?? Random.secure();
    final chars = List.generate(
      3,
      (_) => alphabet[rng.nextInt(alphabet.length)],
    ).join();
    return 'BC-$chars';
  }
}
