class Organization {
  final String id;
  final String domain;
  final String name;
  final String? description;
  final String ldapUrl;
  final String ldapBaseDn;
  final bool ldapEnabled;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Organization({
    required this.id,
    required this.domain,
    required this.name,
    this.description,
    required this.ldapUrl,
    required this.ldapBaseDn,
    required this.ldapEnabled,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
  });

  factory Organization.fromJson(Map<String, dynamic> json) {
    return Organization(
      id: json['id'] ?? '',
      domain: json['domain'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      ldapUrl: json['ldapUrl'] ?? '',
      ldapBaseDn: json['ldapBaseDn'] ?? '',
      ldapEnabled: json['ldapEnabled'] ?? true,
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'domain': domain,
      'name': name,
      'description': description,
      'ldapUrl': ldapUrl,
      'ldapBaseDn': ldapBaseDn,
      'ldapEnabled': ldapEnabled,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  @override
  String toString() => 'Organization(domain: $domain, name: $name)';
}
