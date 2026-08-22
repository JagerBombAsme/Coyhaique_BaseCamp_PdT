class RouteDto {
  final String id;
  final String titleEs;
  final String? titleEn;
  final String descriptionEs;
  final String? descriptionEn;
  final String duration;
  final String difficultyEs;
  final String? difficultyEn;
  final double? distanceKm;
  final String? imageUrl;

  const RouteDto({
    required this.id,
    required this.titleEs,
    this.titleEn,
    required this.descriptionEs,
    this.descriptionEn,
    required this.duration,
    required this.difficultyEs,
    this.difficultyEn,
    this.distanceKm,
    this.imageUrl,
  });

  factory RouteDto.fromJson(Map<String, dynamic> json) {
    return RouteDto(
      id: json['id']?.toString() ?? '',
      titleEs: json['title_es'] ?? json['title'] ?? json['titulo_es'] ?? '',
      titleEn: json['title_en'] ?? json['titulo_en'],
      descriptionEs: json['description_es'] ?? json['description'] ?? json['descripcion_es'] ?? '',
      descriptionEn: json['description_en'] ?? json['descripcion_en'],
      duration: json['duration'] ?? json['duracion'] ?? '2h 00m',
      difficultyEs: json['difficulty_es'] ?? json['difficulty'] ?? json['dificultad_es'] ?? 'Media',
      difficultyEn: json['difficulty_en'] ?? json['dificultad_en'],
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      imageUrl: json['image_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title_es': titleEs,
      'title_en': titleEn,
      'description_es': descriptionEs,
      'description_en': descriptionEn,
      'duration': duration,
      'difficulty_es': difficultyEs,
      'difficulty_en': difficultyEn,
      'distance_km': distanceKm,
      'image_url': imageUrl,
    };
  }

  String getTitle(bool isSpanish) {
    if (!isSpanish && titleEn != null && titleEn!.isNotEmpty) {
      return titleEn!;
    }
    return titleEs;
  }

  String getDescription(bool isSpanish) {
    if (!isSpanish && descriptionEn != null && descriptionEn!.isNotEmpty) {
      return descriptionEn!;
    }
    return descriptionEs;
  }

  String getDifficulty(bool isSpanish) {
    if (!isSpanish && difficultyEn != null && difficultyEn!.isNotEmpty) {
      return difficultyEn!;
    }
    return difficultyEs;
  }
}
