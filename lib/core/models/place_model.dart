class PlaceModel {
  final String id;
  final String categorySlug;
  final String tituloEs;
  final String? tituloEn;
  final String? subtituloEs;
  final String? subtituloEn;
  final String? descripcionEs;
  final String? descripcionEn;
  final String? imageUrl;
  final bool isFeatured;
  final bool isPopular;
  final bool isActive;

  const PlaceModel({
    required this.id,
    required this.categorySlug,
    required this.tituloEs,
    this.tituloEn,
    this.subtituloEs,
    this.subtituloEn,
    this.descripcionEs,
    this.descripcionEn,
    this.imageUrl,
    this.isFeatured = false,
    this.isPopular = false,
    this.isActive = true,
  });

  String getTitulo(String language) {
    if (language == 'en' && tituloEn != null && tituloEn!.isNotEmpty) {
      return tituloEn!;
    }
    return tituloEs;
  }

  String getSubtitulo(String language) {
    if (language == 'en') {
      return subtituloEn ?? subtituloEs ?? '';
    }
    return subtituloEs ?? subtituloEn ?? '';
  }

  String getDescripcion(String language) {
    if (language == 'en') {
      return descripcionEn ?? descripcionEs ?? '';
    }
    return descripcionEs ?? descripcionEn ?? '';
  }
}
