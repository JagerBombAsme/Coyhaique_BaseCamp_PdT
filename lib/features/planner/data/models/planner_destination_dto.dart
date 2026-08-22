class PlannerDestinationDto {
  final String id;
  final String name;
  final String? region;
  final String? description;

  const PlannerDestinationDto({
    required this.id,
    required this.name,
    this.region,
    this.description,
  });

  factory PlannerDestinationDto.fromJson(Map<String, dynamic> json) {
    return PlannerDestinationDto(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? json['nombre'] ?? json['title'] ?? '',
      region: json['region'],
      description: json['description'] ?? json['descripcion'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'region': region,
      'description': description,
    };
  }
}
