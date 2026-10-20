class ActivityDto {
  final String id;
  final String categoryId;
  final String kind;

  final String nameEs;
  final String? nameEn;

  final String descriptionEs;
  final String? descriptionEn;

  final String? meetingPoint;
  final double? latitude;
  final double? longitude;

  final String? schedule;
  final String? referencePrice;
  final String? contactInfo;
  final String? websiteUrl;

  final String? imageUrl;

  final bool isActive;

  const ActivityDto({
    required this.id,
    required this.categoryId,
    required this.kind,
    required this.nameEs,
    this.nameEn,
    required this.descriptionEs,
    this.descriptionEn,
    this.meetingPoint,
    this.latitude,
    this.longitude,
    this.schedule,
    this.referencePrice,
    this.contactInfo,
    this.websiteUrl,
    this.imageUrl,
    required this.isActive,
  });

  factory ActivityDto.fromJson(Map<String, dynamic> json) {
    return ActivityDto(
      id: json['id']?.toString() ?? '',
      categoryId: json['category_id']?.toString() ?? '',
      kind: json['kind']?.toString() ?? '',
      nameEs: json['name_es']?.toString() ?? '',
      nameEn: _nullableString(json['name_en']),
      descriptionEs: json['description_es']?.toString() ?? '',
      descriptionEn: _nullableString(json['description_en']),
      meetingPoint: _nullableString(json['meeting_point']),
      latitude: _toCoordinate(json['latitude'], min: -90, max: 90),
      longitude: _toCoordinate(json['longitude'], min: -180, max: 180),
      schedule: _nullableString(json['schedule']),
      referencePrice: _nullableString(json['reference_price']),
      contactInfo: _nullableString(json['contact_info']),
      websiteUrl: _nullableUrl(json['website_url']),
      imageUrl: _nullableUrl(json['image_url']),
      isActive: _toBool(json['is_active']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_id': categoryId,
      'kind': kind,
      'name_es': nameEs,
      'name_en': nameEn,
      'description_es': descriptionEs,
      'description_en': descriptionEn,
      'meeting_point': meetingPoint,
      'latitude': latitude,
      'longitude': longitude,
      'schedule': schedule,
      'reference_price': referencePrice,
      'contact_info': contactInfo,
      'website_url': websiteUrl,
      'image_url': imageUrl,
      'is_active': isActive,
    };
  }

  // ===============================================================
  // GETTERS ÚTILES
  // ===============================================================

  /// true si la actividad tiene coordenadas válidas para mostrarla en el mapa.
  bool get hasLocation => latitude != null && longitude != null;

  bool get hasImage => imageUrl != null;

  // ===============================================================
  // TEXTOS POR IDIOMA
  // ===============================================================

  String getName(bool isSpanish) {
    final en = nameEn;
    if (!isSpanish && en != null && en.isNotEmpty) {
      return en;
    }
    return nameEs;
  }

  String getDescription(bool isSpanish) {
    final en = descriptionEn;
    if (!isSpanish && en != null && en.isNotEmpty) {
      return en;
    }
    return descriptionEs;
  }

  // ===============================================================
  // CONVERSIONES SEGURAS
  // ===============================================================

  static String? _nullableString(dynamic value) {
    if (value == null) return null;

    final text = value.toString().trim();
    final lower = text.toLowerCase();

    if (text.isEmpty || lower == 'null' || lower == 'n/a') {
      return null;
    }

    return text;
  }

  /// Solo acepta URLs http(s). Agrega https:// si empieza con "www.".
  static String? _nullableUrl(dynamic value) {
    final text = _nullableString(value);
    if (text == null) return null;

    final lower = text.toLowerCase();

    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      return text;
    }
    if (lower.startsWith('www.')) {
      return 'https://$text';
    }

    return null;
  }

  /// Convierte a double y descarta valores fuera de rango o no numéricos.
  static double? _toCoordinate(
    dynamic value, {
    required double min,
    required double max,
  }) {
    if (value == null) return null;

    final number = value is num
        ? value.toDouble()
        : double.tryParse(value.toString().trim().replaceAll(',', '.'));

    if (number == null || number.isNaN || number < min || number > max) {
      return null;
    }

    return number;
  }

  /// Acepta true/false, 1/0 y textos como "true", "t", "si".
  /// Si el campo no viene o no se entiende, usa [defaultValue].
  static bool _toBool(dynamic value, {bool defaultValue = true}) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is num) return value != 0;

    switch (value.toString().trim().toLowerCase()) {
      case 'true':
      case 't':
      case '1':
      case 'yes':
      case 'si':
      case 'sí':
        return true;
      case 'false':
      case 'f':
      case '0':
      case 'no':
        return false;
      default:
        return defaultValue;
    }
  }
}
