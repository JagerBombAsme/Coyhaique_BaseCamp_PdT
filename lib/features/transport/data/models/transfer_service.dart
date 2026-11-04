/// Ficha de un transfer desde el aeropuerto de Balmaceda (HU-18).
///
/// Viene de `transport_services_v2`. Es información referencial: la app no
/// reserva, no cobra y no guarda datos de pasajeros.
class TransferService {
  const TransferService({
    required this.id,
    required this.name,
    this.descriptionEs,
    this.descriptionEn,
    this.originEs = 'Aeropuerto de Balmaceda',
    this.originEn = 'Balmaceda Airport',
    this.standLocationEs,
    this.standLocationEn,
    this.whatsappNumber,
    this.referenceFareClp,
    this.fareNotesEs,
    this.fareNotesEn,
    this.capacity,
    this.acceptsCash = false,
    this.acceptsCard = false,
    this.scheduleEs,
    this.scheduleEn,
    this.imageUrl,
    this.verificationLevel = 'pendiente',
    this.qrEnabled = false,
    this.lastVerifiedDate,
  });

  final String id;
  final String name;
  final String? descriptionEs;
  final String? descriptionEn;
  final String originEs;
  final String originEn;
  final String? standLocationEs;
  final String? standLocationEn;

  /// Solo dígitos, con código de país (569XXXXXXXX).
  final String? whatsappNumber;
  final int? referenceFareClp;
  final String? fareNotesEs;
  final String? fareNotesEn;
  final int? capacity;
  final bool acceptsCash;
  final bool acceptsCard;
  final String? scheduleEs;
  final String? scheduleEn;
  final String? imageUrl;

  /// establecimiento · fuente_publica · pendiente
  final String verificationLevel;

  /// La empresa aceptó recibir viajes por QR (requiere WhatsApp).
  final bool qrEnabled;
  final DateTime? lastVerifiedDate;

  /// Pasajeros máximos del contador cuando la empresa no declaró capacidad.
  static const int defaultCapacity = 8;

  int get maxPassengers => capacity ?? defaultCapacity;

  bool get canGenerateQr =>
      qrEnabled && (whatsappNumber?.isNotEmpty ?? false);

  bool get isVerifiedByCompany => verificationLevel == 'establecimiento';

  bool get isPending => verificationLevel == 'pendiente';

  String origin(bool isSpanish) => isSpanish ? originEs : originEn;

  String? description(bool isSpanish) =>
      _pick(isSpanish, descriptionEs, descriptionEn);

  String? standLocation(bool isSpanish) =>
      _pick(isSpanish, standLocationEs, standLocationEn);

  String? fareNotes(bool isSpanish) =>
      _pick(isSpanish, fareNotesEs, fareNotesEn);

  String? schedule(bool isSpanish) =>
      _pick(isSpanish, scheduleEs, scheduleEn);

  static String? _pick(bool isSpanish, String? es, String? en) {
    final value = isSpanish ? es : (en ?? es);
    if (value == null || value.trim().isEmpty) return null;
    return value.trim();
  }

  factory TransferService.fromJson(Map<String, dynamic> json) {
    int? asInt(Object? value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString());
    }

    String? asText(Object? value) {
      final text = value?.toString();
      if (text == null || text.isEmpty || text == 'null') return null;
      return text;
    }

    return TransferService(
      id: json['id'].toString(),
      name: json['name']?.toString() ?? '',
      descriptionEs: asText(json['description_es']),
      descriptionEn: asText(json['description_en']),
      originEs: asText(json['origin_es']) ?? 'Aeropuerto de Balmaceda',
      originEn: asText(json['origin_en']) ?? 'Balmaceda Airport',
      standLocationEs: asText(json['stand_location_es']),
      standLocationEn: asText(json['stand_location_en']),
      whatsappNumber: asText(json['whatsapp_number']),
      referenceFareClp: asInt(json['reference_fare_clp']),
      fareNotesEs: asText(json['fare_notes_es']),
      fareNotesEn: asText(json['fare_notes_en']),
      capacity: asInt(json['capacity']),
      acceptsCash: json['accepts_cash'] == true,
      acceptsCard: json['accepts_card'] == true,
      scheduleEs: asText(json['schedule_es']),
      scheduleEn: asText(json['schedule_en']),
      imageUrl: asText(json['image_url']),
      verificationLevel: asText(json['verification_level']) ?? 'pendiente',
      qrEnabled: json['qr_enabled'] == true,
      lastVerifiedDate: DateTime.tryParse(
        asText(json['last_verified_date']) ?? '',
      ),
    );
  }
}

/// Monto en pesos chilenos con punto de miles: 25000 → «$25.000».
String formatClp(int amount) {
  final digits = amount.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    final fromEnd = digits.length - i;
    buffer.write(digits[i]);
    if (fromEnd > 1 && fromEnd % 3 == 1) buffer.write('.');
  }
  return '${amount < 0 ? '-' : ''}\$$buffer';
}

/// Fecha en formato dd-mm-aaaa.
String formatDate(DateTime date) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(date.day)}-${two(date.month)}-${date.year}';
}

/// Hora en 24 h (21:58).
String formatTime(DateTime date) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(date.hour)}:${two(date.minute)}';
}
