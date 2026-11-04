import 'dart:math';

import 'package:coyhaique_basecamp_pt/features/transport/data/models/transfer_service.dart';
import 'package:coyhaique_basecamp_pt/features/transport/domain/transfer_request.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = TransferService(
    id: 'demo',
    name: 'Transfer de prueba',
    whatsappNumber: '56900000000',
    referenceFareClp: 25000,
    capacity: 6,
    acceptsCash: true,
    acceptsCard: true,
    qrEnabled: true,
  );

  TransferRequest request({TransferService s = service}) => TransferRequest(
        service: s,
        code: 'BC-7K2',
        destinationKind: TransferDestinationKind.center,
        destinationEs: TransferDestinations.centerEs,
        destinationEn: TransferDestinations.centerEn,
        passengers: 3,
        bigLuggage: true,
        payment: TransferPayment.card,
        createdAt: DateTime(2026, 10, 30, 21, 58),
      );

  test('formatClp usa punto de miles', () {
    expect(formatClp(25000), r'$25.000');
    expect(formatClp(1500000), r'$1.500.000');
    expect(formatClp(900), r'$900');
  });

  test('el mensaje del conductor no lleva datos personales y es legible', () {
    final message = request().driverMessage();
    expect(message.split('\n').first, '*NUEVO TRASLADO · BC-7K2*');
    expect(message, contains('*Destino:* Centro de Coyhaique, Plaza de Armas'));
    expect(message, contains('*Pasajeros:* 3'));
    expect(message, contains('*Equipaje grande:* Sí'));
    expect(message, contains('*Pago:* Tarjeta'));
    expect(message, contains(r'*Tarifa referencial:* $25.000'));
    expect(message, contains('30-10-2026 a las 21:58'));
  });

  test('el enlace abre WhatsApp de la empresa con el texto codificado', () {
    final uri = request().whatsappUri()!;
    expect(uri.host, 'wa.me');
    expect(uri.path, '/56900000000');
    expect(uri.toString(), isNot(contains('+')));
    expect(uri.queryParameters['text'], request().driverMessage());
  });

  test('sin QR habilitado no hay enlace', () {
    const noQr = TransferService(
      id: 'x',
      name: 'Sin QR',
      whatsappNumber: '56900000000',
      acceptsCash: true,
    );
    expect(request(s: noQr).whatsappUri(), isNull);
  });

  test('el código corto evita letras ambiguas', () {
    final code = TransferRequest.newCode(Random(1));
    expect(code, matches(RegExp(r'^BC-[A-HJKMNP-Z2-9]{3}$')));
  });
}
