import 'package:coyhaique_basecamp_pt/features/transport/data/models/transfer_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, dynamic> row([Map<String, dynamic> extra = const {}]) => {
        'id': 'abc',
        'name': 'Empresa de prueba',
        'is_authorized_verified': true,
        'authorization_verified_date': '2026-11-20',
        'authorization_source': 'Documento de prueba',
        'whatsapp_number': '56900000000',
        'phone': '56900000001',
        'website_url': 'https://ejemplo.cl/transfer',
        ...extra,
      };

  test('lee la habilitación verificada y sus datos', () {
    final service = TransferService.fromJson(row());
    expect(service.isAuthorizedVerified, isTrue);
    expect(service.authorizationVerifiedDate, DateTime(2026, 11, 20));
    expect(service.authorizationSource, 'Documento de prueba');
  });

  test('sin el campo, la empresa no figura como verificada', () {
    final service = TransferService.fromJson({'id': 'x', 'name': 'Vieja'});
    expect(service.isAuthorizedVerified, isFalse);
    expect(service.canGenerateQr, isFalse);
  });

  test('arma los enlaces de contacto', () {
    final service = TransferService.fromJson(row());
    expect(service.whatsappLink.toString(), 'https://wa.me/56900000000');
    expect(service.phoneLink.toString(), 'tel:+56900000001');
    expect(service.websiteLink.toString(), 'https://ejemplo.cl/transfer');
    expect(service.hasContact, isTrue);
  });

  test('descarta enlaces inválidos o sin https', () {
    final service = TransferService.fromJson(
      row({
        'whatsapp_number': '12',
        'phone': 'abc',
        'website_url': 'http://ejemplo.cl',
      }),
    );
    expect(service.whatsappLink, isNull);
    expect(service.phoneLink, isNull);
    expect(service.websiteLink, isNull);
    expect(service.hasContact, isFalse);
  });

  test('atiende ambos sentidos por defecto y respeta los campos', () {
    final both = TransferService.fromJson(row());
    expect(both.serves(toAirport: true), isTrue);
    expect(both.serves(toAirport: false), isTrue);

    final onlyFrom = TransferService.fromJson(
      row({'serves_to_airport': false}),
    );
    expect(onlyFrom.serves(toAirport: true), isFalse);
    expect(onlyFrom.serves(toAirport: false), isTrue);
  });
}
