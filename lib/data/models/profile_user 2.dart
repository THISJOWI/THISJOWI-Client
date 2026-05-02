/// Modelo de usuario para perfil
/// Contiene datos personales y preferencias del usuario
class ProfileUser {
  final String userId;
  final String? fullName;
  final String? country;
  final String? birthDate;
  final String? avatarUrl;
  final String? publicKey;
  final Map<String, dynamic>? preferences;
  final DateTime? completedAt;
  final DateTime? updatedAt;
  final String? accountType;
  final String? hostingMode;

  ProfileUser({
    required this.userId,
    this.fullName,
    this.country,
    this.birthDate,
    this.avatarUrl,
    this.publicKey,
    this.preferences,
    this.completedAt,
    this.updatedAt,
    this.accountType,
    this.hostingMode,
  });

  factory ProfileUser.fromJson(Map<String, dynamic> json) {
    // El backend envuelve el perfil en un objeto 'profile'
    // o puede devolver el perfil directamente
    final profileData = json['profile'] ?? json;

    // Parsear fechas
    DateTime? completedAt;
    if (profileData['completedAt'] != null) {
      completedAt = DateTime.tryParse(profileData['completedAt']);
    }

    DateTime? updatedAt;
    if (profileData['updatedAt'] != null) {
      updatedAt = DateTime.tryParse(profileData['updatedAt']);
    }

    // Parsear preferencias
    Map<String, dynamic>? prefs;
    if (profileData['preferences'] != null) {
      prefs = profileData['preferences'] is Map<String, dynamic>
          ? profileData['preferences'] as Map<String, dynamic>
          : Map<String, dynamic>.from(profileData['preferences']);
    }

    return ProfileUser(
      userId: (profileData['userId'] ?? profileData['user_id'] ?? profileData['id'] ?? profileData['_id'])?.toString() ?? '',
      fullName: profileData['fullName'] ?? profileData['full_name'],
      country: profileData['country'],
      birthDate: profileData['birthDate'] ?? profileData['birth_date'],
      avatarUrl: profileData['avatarUrl'] ?? profileData['avatar_url'],
      publicKey: profileData['publicKey'] ?? profileData['public_key'],
      preferences: prefs,
      completedAt: completedAt,
      updatedAt: updatedAt,
      accountType: profileData['accountType'] ?? profileData['account_type'],
      hostingMode: profileData['hostingMode'] ?? profileData['hosting_mode'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'fullName': fullName,
      'country': country,
      'birthDate': birthDate,
      'avatarUrl': avatarUrl,
      'publicKey': publicKey,
      'preferences': preferences,
      'completedAt': completedAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'accountType': accountType,
      'hostingMode': hostingMode,
    };
  }

  /// Crea una copia con campos actualizados
  ProfileUser copyWith({
    String? userId,
    String? fullName,
    String? country,
    String? birthDate,
    String? avatarUrl,
    String? publicKey,
    Map<String, dynamic>? preferences,
    DateTime? completedAt,
    DateTime? updatedAt,
    String? accountType,
    String? hostingMode,
  }) {
    return ProfileUser(
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      country: country ?? this.country,
      birthDate: birthDate ?? this.birthDate,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      publicKey: publicKey ?? this.publicKey,
      preferences: preferences ?? this.preferences,
      completedAt: completedAt ?? this.completedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      accountType: accountType ?? this.accountType,
      hostingMode: hostingMode ?? this.hostingMode,
    );
  }

  /// Verifica si el perfil esta completo
  bool get isComplete {
    return fullName != null && 
           fullName!.isNotEmpty && 
           country != null && 
           country!.isNotEmpty;
  }

  /// Porcentaje de completitud del perfil (0-100)
  int get completionPercentage {
    int completedFields = 0;
    int totalFields = 4; // fullName, country, birthDate, avatarUrl
    
    if (fullName != null && fullName!.isNotEmpty) completedFields++;
    if (country != null && country!.isNotEmpty) completedFields++;
    if (birthDate != null && birthDate!.isNotEmpty) completedFields++;
    if (avatarUrl != null && avatarUrl!.isNotEmpty) completedFields++;
    
    return (completedFields / totalFields * 100).round();
  }

  /// Obtiene el nombre de visualizacion
  String get displayName => fullName ?? 'Usuario';

  /// Obtiene las iniciales para avatar placeholder
  String get initials {
    if (fullName == null || fullName!.isEmpty) return 'U';
    final parts = fullName!.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  String toString() {
    return 'ProfileUser(userId: $userId, fullName: $fullName, country: $country, completion: $completionPercentage%)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProfileUser && other.userId == userId;
  }

  @override
  int get hashCode => userId.hashCode;
}
