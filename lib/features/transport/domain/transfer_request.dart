import 'dart:math';

import '../data/models/transfer_service.dart';

/// Tipo de destino que elige el pasajero. Nunca se pide una dirección
/// particular: solo alojamientos del catálogo o puntos de referencia.
enum TransferDestinationKind { lodging, center, terminal, locality }

/// Medio de pago que el pasajero le anuncia al conductor. La app no cobra.
enum TransferPayment { cash, card }

/// Puntos de referencia fijos por tipo de destino.
abstract final class TransferDestinations {
  static const String centerEs = 'Centro de Coyhaique, Plaza de Armas';
  static const String centerEn = 'Coyhaique town centre, Plaza de Armas';

  static const String terminalEs = 'Terminal de buses de Coyhaique';
  static const String terminalEn = 'Coyhaique bus terminal';

  /// Localidades cercanas al aeropuerto o a Coyhaique.
  static const List<String> localities = [
    'Puerto Aysén',
    'Puerto Chacabuco',
    'Villa Cerro Castillo',
    'Puerto Ingeniero Ibáñez',
    'Mañihuales',
    'Balmaceda',
  ];
}

/// Solicitud de traslado armada en el teléfono del pasajero (HU-18).
///
/// Contiene solo lo que el conductor necesita: código corto, destino,
/// pasajeros, equipaje y medio de pago. No lleva nombre, teléfono, correo,
/// dirección particular ni ubicación, y no se envía a ningún servidor: el
/// QR abre WhatsApp en el teléfono del conductor con el viaje ya escrito.
class TransferRequest {
  const TransferRequest({
    required this.service,
    required this.code,
    required this.destinationKind,
    required this.destinationEs,
    required this.destinationEn,
    required this.passengers,
    required this.bigLuggage,
    required this.payment,
    required this.createdAt,
  });

  final TransferService service;
  final String code;
  final TransferDestinationKind destinationKind;
  final String destinationEs;
  final String destinationEn;
  final int passengers;
  final bool bigLuggage;
  final TransferPayment payment;
  final DateTime createdAt;

  String destination(bool isSpanish) =>
      isSpanish ? destinationEs : destinationEn;

  String paymentLabel(bool isSpanish) => switch (payment) {
        TransferPayment.cash => isSpanish ? 'Efectivo' : 'Cash',
        TransferPayment.card => isSpanish ? 'Tarjeta' : 'Card',
      };

  String fareLabel(bool isSpanish) {
    final fare = service.referenceFareClp;
    if (fare == null) return isSpanish ? 'Por confirmar' : 'To be confirmed';
    return formatClp(fare);
  }

  /// Mensaje para el conductor, siempre en español (lo lee la empresa local).
  /// Usa el formato de WhatsApp: *negrita* y _cursiva_.
  String driverMessage() {
    final lines = <String>[
      '*NUEVO TRASLADO · $code*',
      'Coyhaique BaseCamp',
      '',
      '*Destino:* $destinationEs',
      '*Pasajeros:* $passengers',
      '*Equipaje grande:* ${bigLuggage ? 'Sí' : 'No'}',
      '*Pago:* ${paymentLabel(true)}',
      '*Tarifa referencial:* ${fareLabel(true)}',
      '',
      '_Creado el ${formatDate(createdAt)} a las ${formatTime(createdAt)} · '
          '${service.originEs}_',
    ];
    return lines.join('\n');
  }

  /// Enlace que abre WhatsApp con el mensaje listo para la empresa.
  /// null si la empresa no habilitó el QR.
  Uri? whatsappUri() {
    if (!service.canGenerateQr) return null;
    // encodeComponent deja los espacios como %20 (no «+»), que WhatsApp
    // muestra siempre como espacios.
    return Uri.parse(
      'https://wa.me/${service.whatsappNumber}'
      '?text=${Uri.encodeComponent(driverMessage())}',
    );
  }

  /// Código corto para que el conductor llame al pasajero («BC-7K2»).
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
