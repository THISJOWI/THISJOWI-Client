/// Local profile entry for offline persistence.
/// Mirrors ProfileUser but flattened for Drift storage.
class ProfileEntry {
  final String userId;
  final String? fullName;
  final String? country;
  final String? avatarUrl;
  final String? birthDate;
  final String? publicKey;
  final String? preferences; // JSON string
  final String? accountType;
  final String? hostingMode;
  final String? updatedAt;

  const ProfileEntry({
    required this.userId,
    this.fullName,
    this.country,
    this.avatarUrl,
    this.birthDate,
    this.publicKey,
    this.preferences,
    this.accountType,
    this.hostingMode,
    this.updatedAt,
  });

  factory ProfileEntry.fromJson(Map<String, dynamic> json) {
    return ProfileEntry(
      userId: (json['userId'] ?? '').toString(),
      fullName: json['fullName']?.toString(),
      country: json['country']?.toString(),
      avatarUrl: json['avatarUrl']?.toString(),
      birthDate: json['birthDate']?.toString(),
      publicKey: json['publicKey']?.toString(),
      preferences: json['preferences']?.toString(),
      accountType: json['accountType']?.toString(),
      hostingMode: json['hostingMode']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'fullName': fullName,
      'country': country,
      'avatarUrl': avatarUrl,
      'birthDate': birthDate,
      'publicKey': publicKey,
      'preferences': preferences,
      'accountType': accountType,
      'hostingMode': hostingMode,
      'updatedAt': updatedAt,
    };
  }

  ProfileEntry copyWith({
    String? userId,
    String? fullName,
    String? country,
    String? avatarUrl,
    String? birthDate,
    String? publicKey,
    String? preferences,
    String? accountType,
    String? hostingMode,
    String? updatedAt,
  }) {
    return ProfileEntry(
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      country: country ?? this.country,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      birthDate: birthDate ?? this.birthDate,
      publicKey: publicKey ?? this.publicKey,
      preferences: preferences ?? this.preferences,
      accountType: accountType ?? this.accountType,
      hostingMode: hostingMode ?? this.hostingMode,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
