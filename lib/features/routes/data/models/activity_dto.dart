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
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      schedule: _nullableString(json['schedule']),
      referencePrice: _nullableString(json['reference_price']),
      contactInfo: _nullableString(json['contact_info']),
      websiteUrl: _nullableString(json['website_url']),
      isActive: json['is_active'] == true,
    );
  }

  String getName(bool isSpanish) {
    if (!isSpanish && nameEn != null && nameEn!.isNotEmpty) {
      return nameEn!;
    }

    return nameEs;
  }

  String getDescription(bool isSpanish) {
    if (!isSpanish && descriptionEn != null && descriptionEn!.isNotEmpty) {
      return descriptionEn!;
    }

    return descriptionEs;
  }

  static String? _nullableString(dynamic value) {
    if (value == null) return null;

    final text = value.toString().trim();

    if (text.isEmpty ||
        text.toLowerCase() == 'null' ||
        text.toLowerCase() == 'n/a') {
      return null;
    }

    return text;
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
  }
}
