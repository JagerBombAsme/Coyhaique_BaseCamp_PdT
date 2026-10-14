/// Modelo DTO para la tabla informational_content_v2
/// según ANTIGRAVITY_AI_CONTEXT.md §11
class InformationalContentDto {
  final String id;
  final String contentType;
  final String titleEs;
  final String? titleEn;
  final String? category;
  final String? descriptionEs;
  final String? descriptionEn;
  final String? referenceUrl;
  final String? schedule;
  final String? referencePrice;
  final String? contactInfo;
  final bool isActive;
  final DateTime? createdAt;

  const InformationalContentDto({
    required this.id,
    required this.contentType,
    required this.titleEs,
    this.titleEn,
    this.category,
    this.descriptionEs,
    this.descriptionEn,
    this.referenceUrl,
    this.schedule,
    this.referencePrice,
    this.contactInfo,
    this.isActive = true,
    this.createdAt,
  });

  factory InformationalContentDto.fromJson(Map<String, dynamic> json) {
    return InformationalContentDto(
      id: json['id'] as String,
      contentType: json['content_type'] as String? ?? 'general',
      titleEs: json['title_es'] as String? ?? json['title'] as String? ?? '',
      titleEn: json['title_en'] as String?,
      category: json['category'] as String?,
      descriptionEs: json['description_es'] as String?,
      descriptionEn: json['description_en'] as String?,
      referenceUrl: json['reference_url'] as String?,
      schedule: json['schedule'] as String?,
      referencePrice: json['reference_price'] as String?,
      contactInfo: json['contact_info'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  String getTitle(bool isSpanish) {
    if (isSpanish) return titleEs;
    return (titleEn != null && titleEn!.isNotEmpty) ? titleEn! : titleEs;
  }

  String getDescription(bool isSpanish) {
    if (isSpanish) return descriptionEs ?? '';
    return (descriptionEn != null && descriptionEn!.isNotEmpty)
        ? descriptionEn!
        : (descriptionEs ?? '');
  }
}
