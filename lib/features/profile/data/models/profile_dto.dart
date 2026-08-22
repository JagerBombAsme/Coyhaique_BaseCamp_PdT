class ProfileDto {
  final String id;
  final String fullName;
  final String? username;
  final String? biography;
  final String? avatarUrl;
  final String language;
  final String? country;
  final String? city;
  final String role;
  final bool isVerified;

  const ProfileDto({
    required this.id,
    required this.fullName,
    this.username,
    this.biography,
    this.avatarUrl,
    required this.language,
    this.country,
    this.city,
    required this.role,
    required this.isVerified,
  });

  factory ProfileDto.fromJson(Map<String, dynamic> json) {
    return ProfileDto(
      id: json['id'],
      fullName: json['full_name'],
      username: json['username'],
      biography: json['biography'],
      avatarUrl: json['avatar_url'],
      language: json['language'] ?? 'es',
      country: json['country'],
      city: json['city'],
      role: json['role'] ?? 'tourist',
      isVerified: json['is_verified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'username': username,
      'biography': biography,
      'avatar_url': avatarUrl,
      'language': language,
      'country': country,
      'city': city,
      'role': role,
      'is_verified': isVerified,
    };
  }
}