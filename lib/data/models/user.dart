class User {
  final String? id;
  final String email;
  final String? fullName;
  final String? country;
  final String? accountType; // "Business" or "Community"
  final String? hostingMode;
  final String? avatarUrl;

  User({
    this.id,
    required this.email,
    this.fullName,
    this.country,
    this.accountType,
    this.hostingMode,
    this.avatarUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['id'] ?? json['_id'] ?? json['userId'])?.toString(),
      email: json['email'] ?? '',
      fullName: json['fullName'],
      country: json['country'],
      accountType: json['accountType'] ?? json['account_type'],
      hostingMode: json['hostingMode'] ?? json['hosting_mode'],
      avatarUrl: json['avatarUrl'] ??
          json['avatar_url'], // Assuming the API might return this
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'country': country,
      'accountType': accountType,
      'hostingMode': hostingMode,
      'avatarUrl': avatarUrl,
    };
  }

  bool get isBusinessAccount => accountType?.toLowerCase() == 'business';
}
