class ActivityDto {
  final String id;
  final String categoryId;
  final String kind;

  final String nameEs;
  final String? nameEn;

  final String descriptionEs;
  final String? descriptionEn;

  final String? address;
  final String? meetingPoint;

  final double? latitude;
  final double? longitude;

  final String? schedule;
  final String? referencePrice;
  final String? contactInfo;
  final String? websiteUrl;

  final DateTime? lastVerifiedDate;

  final bool isActive;

  const ActivityDto({
    required this.id,
    required this.categoryId,
    required this.kind,
    required this.nameEs,
    this.nameEn,
    required this.descriptionEs,
    this.descriptionEn,
    this.address,
    this.meetingPoint,
    this.latitude,
    this.longitude,
    this.schedule,
    this.referencePrice,
    this.contactInfo,
    this.websiteUrl,
    this.lastVerifiedDate,
    required this.isActive,
  });

  factory ActivityDto.fromJson(
    Map<String, dynamic> json,
  ) {
    return ActivityDto(
      id: json['id']?.toString() ?? '',
      categoryId:
          json['category_id']?.toString() ?? '',
      kind:
          json['kind']?.toString() ?? '',

      nameEs:
          json['name_es']?.toString() ?? '',

      nameEn:
          json['name_en']?.toString(),

      descriptionEs:
          json['description_es']?.toString() ?? '',

      descriptionEn:
          json['description_en']?.toString(),

      address:
          _nullableString(json['address']),

      meetingPoint:
          _nullableString(json['meeting_point']),

      latitude:
          _toDouble(json['latitude']),

      longitude:
          _toDouble(json['longitude']),

      schedule:
          _nullableString(json['schedule']),

      referencePrice:
          _nullableString(json['reference_price']),

      contactInfo:
          _nullableString(json['contact_info']),

      websiteUrl:
          _nullableString(json['website_url']),

      lastVerifiedDate:
          json['last_verified_date'] != null
              ? DateTime.tryParse(
                  json['last_verified_date'].toString(),
                )
              : null,

      isActive:
          json['is_active'] == true,
    );
  }

  String getName(bool isSpanish) {
    if (!isSpanish &&
        nameEn != null &&
        nameEn!.trim().isNotEmpty) {
      return nameEn!;
    }

    return nameEs;
  }

  String getDescription(bool isSpanish) {
    if (!isSpanish &&
        descriptionEn != null &&
        descriptionEn!.trim().isNotEmpty) {
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

    return double.tryParse(
      value.toString(),
    );
  }
}