import '../../../../core/models/category_model.dart';

/// Recurso visual de un lugar o actividad (tabla place_media_v2)
class PlaceMediaDto {
  final String id;
  final String placeId;
  final String? storagePath;
  final String? externalUrl;
  final String? author;
  final String? license;
  final String? altTextEs;
  final String? altTextEn;
  final int sortOrder;
  final bool isActive;

  const PlaceMediaDto({
    required this.id,
    required this.placeId,
    this.storagePath,
    this.externalUrl,
    this.author,
    this.license,
    this.altTextEs,
    this.altTextEn,
    this.sortOrder = 0,
    this.isActive = true,
  });

  factory PlaceMediaDto.fromJson(Map<String, dynamic> json) {
    final rawUrl = json['external_url']?.toString();
    final cleanUrl = (rawUrl != null && rawUrl.isNotEmpty && rawUrl != 'null') ? rawUrl : null;

    return PlaceMediaDto(
      id: json['id']?.toString() ?? '',
      placeId: json['place_id']?.toString() ?? '',
      storagePath: json['storage_path']?.toString(),
      externalUrl: cleanUrl,
      author: json['author']?.toString() != 'null' ? json['author']?.toString() : null,
      license: json['license']?.toString() != 'null' ? json['license']?.toString() : null,
      altTextEs: json['alt_text_es']?.toString(),
      altTextEn: json['alt_text_en']?.toString(),
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'place_id': placeId,
      'storage_path': storagePath,
      'external_url': externalUrl,
      'author': author,
      'license': license,
      'alt_text_es': altTextEs,
      'alt_text_en': altTextEn,
      'sort_order': sortOrder,
      'is_active': isActive,
    };
  }
}

/// Modelo de datos para un atractivo o actividad (tabla places_v2)
class PlaceDto {
  final String id;
  final String categoryId;
  final String? categorySlug;
  final String kind; // 'place' o 'activity'
  final String titleEs;
  final String? titleEn;
  final String? subtitleEs;
  final String? subtitleEn;
  final String? descriptionEs;
  final String? descriptionEn;
  final String? imageUrl;
  final String? address;
  final String? meetingPoint;
  final double? latitude;
  final double? longitude;
  final String? schedule;
  final String? referencePrice;
  final String? contactInfo;
  final String? websiteUrl;
  final DateTime? lastVerifiedDate;
  final double? rating;
  final bool isFeatured;
  final bool isPopular;
  final bool isActive;
  final List<PlaceMediaDto> media;
  final CategoryModel? category;

  const PlaceDto({
    required this.id,
    required this.categoryId,
    this.categorySlug,
    this.kind = 'place',
    required this.titleEs,
    this.titleEn,
    this.subtitleEs,
    this.subtitleEn,
    this.descriptionEs,
    this.descriptionEn,
    this.imageUrl,
    this.address,
    this.meetingPoint,
    this.latitude,
    this.longitude,
    this.schedule,
    this.referencePrice,
    this.contactInfo,
    this.websiteUrl,
    this.lastVerifiedDate,
    this.rating,
    this.isFeatured = false,
    this.isPopular = false,
    this.isActive = true,
    this.media = const [],
    this.category,
  });

  factory PlaceDto.fromJson(Map<String, dynamic> json) {
    // 1. Extraer medios (place_media_v2) si vienen en la consulta relacional
    List<PlaceMediaDto> mediaList = [];
    if (json['place_media_v2'] is List) {
      mediaList = (json['place_media_v2'] as List)
          .map((m) => PlaceMediaDto.fromJson(m as Map<String, dynamic>))
          .where((m) => m.isActive)
          .toList();
      mediaList.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    }

    // 2. Extraer categoría si viene en la consulta relacional
    CategoryModel? categoryModel;
    if (json['categories_v2'] is Map<String, dynamic>) {
      categoryModel = CategoryModel.fromJson(json['categories_v2']);
    }

    // 3. Resolver imagen principal
    String? resolvedImageUrl;
    if (json['image_url'] != null && json['image_url'].toString().isNotEmpty && json['image_url'] != 'null') {
      resolvedImageUrl = json['image_url'].toString();
    } else if (mediaList.isNotEmpty) {
      final validMedia = mediaList.firstWhere(
        (m) => m.externalUrl != null && m.externalUrl!.isNotEmpty && m.externalUrl != 'null',
        orElse: () => mediaList.first,
      );
      resolvedImageUrl = validMedia.externalUrl;
    }

    final rawNameEs = json['name_es'] ?? json['title_es'] ?? json['title'] ?? '';
    final rawNameEn = json['name_en'] ?? json['title_en'];
    final rawDescEs = json['description_es'] ?? json['description'];
    final rawDescEn = json['description_en'];
    final rawAddress = json['address']?.toString() != 'null' ? json['address']?.toString() : null;
    final rawMeeting = json['meeting_point']?.toString() != 'null' ? json['meeting_point']?.toString() : null;

    final subtitle = rawAddress ?? rawMeeting ?? json['subtitle_es'];

    return PlaceDto(
      id: json['id']?.toString() ?? '',
      categoryId: json['category_id']?.toString() ?? '',
      categorySlug: categoryModel?.slug ?? json['category_slug'] ?? json['category'] ?? '',
      kind: json['kind']?.toString() ?? 'place',
      titleEs: rawNameEs,
      titleEn: rawNameEn,
      subtitleEs: subtitle,
      subtitleEn: json['subtitle_en'] ?? subtitle,
      descriptionEs: rawDescEs,
      descriptionEn: rawDescEn,
      imageUrl: resolvedImageUrl,
      address: rawAddress,
      meetingPoint: rawMeeting,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      schedule: json['schedule']?.toString() != 'null' ? json['schedule']?.toString() : null,
      referencePrice: json['reference_price']?.toString() != 'null' ? json['reference_price']?.toString() : null,
      contactInfo: json['contact_info']?.toString() != 'null' ? json['contact_info']?.toString() : null,
      websiteUrl: json['website_url']?.toString() != 'null' ? json['website_url']?.toString() : null,
      lastVerifiedDate: json['last_verified_date'] != null
          ? DateTime.tryParse(json['last_verified_date'].toString())
          : null,
      rating: (json['rating'] as num?)?.toDouble() ?? 4.7,
      isFeatured: json['is_featured'] ?? false,
      isPopular: json['is_popular'] ?? false,
      isActive: json['is_active'] ?? true,
      media: mediaList,
      category: categoryModel,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_id': categoryId,
      'kind': kind,
      'name_es': titleEs,
      'name_en': titleEn,
      'description_es': descriptionEs,
      'description_en': descriptionEn,
      'address': address,
      'meeting_point': meetingPoint,
      'latitude': latitude,
      'longitude': longitude,
      'schedule': schedule,
      'reference_price': referencePrice,
      'contact_info': contactInfo,
      'website_url': websiteUrl,
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
    return subtitleEs ?? address ?? meetingPoint ?? '';
  }

  String getDescription(bool isSpanish) {
    if (!isSpanish && descriptionEn != null && descriptionEn!.isNotEmpty) {
      return descriptionEn!;
    }
    return descriptionEs ?? '';
  }
}
