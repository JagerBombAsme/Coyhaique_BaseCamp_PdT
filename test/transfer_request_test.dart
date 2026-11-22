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
    verificationLevel: 'establecimiento',
  );

  TransferRequest request({TransferService s = service}) => TransferRequest(
        service: s,
        code: 'BC-7K2',
        pickupKind: TransferPickupKind.center,
        pickupEs: TransferPickupPoints.centerEs,
        pickupEn: TransferPickupPoints.centerEn,
        pickupAt: DateTime(2026, 12, 14, 6, 30),
        flight: 'LA123',
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
    expect(
      message.split('\n').first,
      '*SOLICITUD DE TRASLADO AL AEROPUERTO · BC-7K2*',
    );
    expect(message, contains('*Recogida:* Centro de Coyhaique, Plaza de Armas'));
    expect(message, contains('*Destino:* Aeropuerto de Balmaceda'));
    expect(
      message,
      contains('*Fecha y hora de recogida:* 14-12-2026 a las 06:30'),
    );
    expect(message, contains('*Vuelo:* LA123'));
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

  test('una empresa pendiente de validación no recibe solicitudes', () {
    const pending = TransferService(
      id: 'p',
      name: 'Pendiente',
      whatsappNumber: '56900000000',
      acceptsCash: true,
      qrEnabled: true,
    );
    expect(pending.canGenerateQr, isFalse);
    expect(request(s: pending).whatsappUri(), isNull);
  });

  test('sin QR habilitado no hay enlace', () {
    const noQr = TransferService(
      id: 'x',
      name: 'Sin QR',
      whatsappNumber: '56900000000',
      acceptsCash: true,
      verificationLevel: 'establecimiento',
    );
    expect(request(s: noQr).whatsappUri(), isNull);
  });

  test('un destino escrito a mano se limpia y pide confirmación al conductor', () {
    final typed = TransferRequest(
      service: service,
      code: 'BC-7K2',
      pickupKind: TransferPickupKind.other,
      pickupEs: TransferPickupPoints.cleanTyped('  *Los   Ñires*  _123_ '),
      pickupEn: TransferPickupPoints.cleanTyped('  *Los   Ñires*  _123_ '),
      pickupAt: DateTime(2026, 12, 14, 7, 0),
      passengers: 1,
      bigLuggage: false,
      payment: TransferPayment.cash,
      createdAt: DateTime(2026, 10, 30, 21, 58),
      pickupIsTyped: true,
    );
    final message = typed.driverMessage();
    expect(message, contains('*Recogida:* Los Ñires 123'));
    expect(message, contains('confírmala con él'));
    expect(request().driverMessage(), isNot(contains('confírmala con él')));
  });

  test('cleanTyped limita el largo y exige un mínimo', () {
    expect(TransferPickupPoints.cleanTyped('a' * 200).length, 80);
    expect(TransferPickupPoints.cleanTyped('x\ny'), 'x y');
    expect(TransferPickupPoints.isTypedValid('ab'), isFalse);
    expect(TransferPickupPoints.isTypedValid('  abc '), isTrue);
    expect(TransferPickupPoints.isTypedValid('***'), isFalse);
  });

  test('el vuelo es opcional y se limpia', () {
    final noFlight = TransferRequest(
      service: service,
      code: 'BC-7K2',
      pickupKind: TransferPickupKind.terminal,
      pickupEs: TransferPickupPoints.terminalEs,
      pickupEn: TransferPickupPoints.terminalEn,
      pickupAt: DateTime(2026, 12, 14, 7, 0),
      passengers: 1,
      bigLuggage: false,
      payment: TransferPayment.cash,
      createdAt: DateTime(2026, 10, 30, 21, 58),
    );
    expect(noFlight.driverMessage(), isNot(contains('*Vuelo:*')));
    expect(TransferPickupPoints.cleanFlight(' la  123*_ '), 'LA 123');
    expect(TransferPickupPoints.cleanFlight('x' * 30).length, 10);
    expect(TransferPickupPoints.cleanFlight('***'), '');
  });

  test('el código corto evita letras ambiguas', () {
    final code = TransferRequest.newCode(Random(1));
    expect(code, matches(RegExp(r'^BC-[A-HJKMNP-Z2-9]{3}$')));
  });
}
