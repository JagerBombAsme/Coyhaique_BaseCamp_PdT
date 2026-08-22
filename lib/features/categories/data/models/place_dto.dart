class PlaceDto {
  final String id;
  final String categorySlug;
  final String titleEs;
  final String? titleEn;
  final String? subtitleEs;
  final String? subtitleEn;
  final String? descriptionEs;
  final String? descriptionEn;
  final String? imageUrl;
  final String? address;
  final double? rating;
  final bool isFeatured;
  final bool isPopular;
  final bool isActive;

  const PlaceDto({
    required this.id,
    required this.categorySlug,
    required this.titleEs,
    this.titleEn,
    this.subtitleEs,
    this.subtitleEn,
    this.descriptionEs,
    this.descriptionEn,
    this.imageUrl,
    this.address,
    this.rating,
    this.isFeatured = false,
    this.isPopular = false,
    this.isActive = true,
  });

  factory PlaceDto.fromJson(Map<String, dynamic> json) {
    return PlaceDto(
      id: json['id']?.toString() ?? '',
      categorySlug: json['category_slug'] ?? json['category'] ?? '',
      titleEs: json['title_es'] ?? json['title'] ?? json['titulo_es'] ?? '',
      titleEn: json['title_en'] ?? json['titulo_en'],
      subtitleEs: json['subtitle_es'] ?? json['subtitle'] ?? json['subtitulo_es'],
      subtitleEn: json['subtitle_en'] ?? json['subtitulo_en'],
      descriptionEs: json['description_es'] ?? json['description'] ?? json['descripcion_es'],
      descriptionEn: json['description_en'] ?? json['descripcion_en'],
      imageUrl: json['image_url'],
      address: json['address'] ?? json['direccion'],
      rating: (json['rating'] as num?)?.toDouble(),
      isFeatured: json['is_featured'] ?? false,
      isPopular: json['is_popular'] ?? false,
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_slug': categorySlug,
      'title_es': titleEs,
      'title_en': titleEn,
      'subtitle_es': subtitleEs,
      'subtitle_en': subtitleEn,
      'description_es': descriptionEs,
      'description_en': descriptionEn,
      'image_url': imageUrl,
      'address': address,
      'rating': rating,
      'is_featured': isFeatured,
      'is_popular': isPopular,
      'is_active': isActive,
    };
  }

  String getTitle(bool isSpanish) {
    if (!isSpanish && titleEn != null && titleEn!.isNotEmpty) {
      return titleEn!;
    }
    return titleEs;
  }

  String getSubtitle(bool isSpanish) {
    if (!isSpanish && subtitleEn != null && subtitleEn!.isNotEmpty) {
      return subtitleEn!;
    }
    return subtitleEs ?? '';
  }

  String getDescription(bool isSpanish) {
    if (!isSpanish && descriptionEn != null && descriptionEn!.isNotEmpty) {
      return descriptionEn!;
    }
    return descriptionEs ?? '';
  }
}
