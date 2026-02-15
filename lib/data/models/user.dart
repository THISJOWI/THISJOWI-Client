class User {
  final String? id;
  final String email;
  final String? fullName;
  final String? country;
  final String? accountType; // "Business" or "Community"
  final String? hostingMode;
  final String? avatarUrl;
  final String? orgId;
  final String? ldapUsername;
  final String? ldapDomain;
  final bool isLdapUser;
  final String? publicKey;

  User({
    this.id,
    required this.email,
    this.fullName,
    this.country,
    this.accountType,
    this.hostingMode,
    this.avatarUrl,
    this.orgId,
    this.ldapUsername,
    this.ldapDomain,
    this.isLdapUser = false,
    this.publicKey,
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
      orgId: json['orgId'],
      ldapUsername: json['ldapUsername'],
      ldapDomain: json['ldapDomain'],
      isLdapUser: json['isLdapUser'] ?? false,
      publicKey: json['publicKey'],
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
      'orgId': orgId,
      'ldapUsername': ldapUsername,
      'ldapDomain': ldapDomain,
      'isLdapUser': isLdapUser,
      'publicKey': publicKey,
    };
  }

  bool get isBusinessAccount => accountType?.toLowerCase() == 'business';
}
