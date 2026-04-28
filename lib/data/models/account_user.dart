/// Modelo de usuario para cuenta
/// Contiene datos de suscripcion, facturacion y tipo de cuenta
class AccountUser {
  final String userId;
  final String email;
  final String accountType; // "Business" or "Community"
  final String hostingMode; // "SelfHosted" or "Cloud"
  final String billingStatus;
  final List<String> features;
  final DateTime? subscriptionExpiry;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? metadata;

  AccountUser({
    required this.userId,
    required this.email,
    required this.accountType,
    required this.hostingMode,
    this.billingStatus = 'active',
    this.features = const [],
    this.subscriptionExpiry,
    this.createdAt,
    this.updatedAt,
    this.metadata,
  });

  factory AccountUser.fromJson(Map<String, dynamic> json) {
    // Parsear fechas
    DateTime? subscriptionExpiry;
    if (json['subscriptionExpiry'] != null) {
      subscriptionExpiry = DateTime.tryParse(json['subscriptionExpiry']);
    }
    
    DateTime? createdAt;
    if (json['createdAt'] != null) {
      createdAt = DateTime.tryParse(json['createdAt']);
    }
    
    DateTime? updatedAt;
    if (json['updatedAt'] != null) {
      updatedAt = DateTime.tryParse(json['updatedAt']);
    }

    // Parsear features
    List<String> features = [];
    if (json['features'] != null) {
      if (json['features'] is List) {
        features = (json['features'] as List).map((e) => e.toString()).toList();
      }
    }

    // Parsear metadata
    Map<String, dynamic>? metadata;
    if (json['metadata'] != null) {
      metadata = json['metadata'] is Map<String, dynamic> 
          ? json['metadata'] as Map<String, dynamic>
          : Map<String, dynamic>.from(json['metadata']);
    }

    return AccountUser(
      userId: (json['userId'] ?? json['user_id'] ?? json['id'] ?? json['_id'])?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      accountType: json['accountType']?.toString() ?? 
                   json['account_type']?.toString() ?? 
                   'Community',
      hostingMode: json['hostingMode']?.toString() ?? 
                   json['hosting_mode']?.toString() ?? 
                   'Cloud',
      billingStatus: json['billingStatus']?.toString() ?? 
                     json['billing_status']?.toString() ?? 
                     'active',
      features: features,
      subscriptionExpiry: subscriptionExpiry,
      createdAt: createdAt,
      updatedAt: updatedAt,
      metadata: metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'email': email,
      'accountType': accountType,
      'hostingMode': hostingMode,
      'billingStatus': billingStatus,
      'features': features,
      'subscriptionExpiry': subscriptionExpiry?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  /// Crea una copia con campos actualizados
  AccountUser copyWith({
    String? userId,
    String? email,
    String? accountType,
    String? hostingMode,
    String? billingStatus,
    List<String>? features,
    DateTime? subscriptionExpiry,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return AccountUser(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      accountType: accountType ?? this.accountType,
      hostingMode: hostingMode ?? this.hostingMode,
      billingStatus: billingStatus ?? this.billingStatus,
      features: features ?? this.features,
      subscriptionExpiry: subscriptionExpiry ?? this.subscriptionExpiry,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Verifica si es cuenta Business
  bool get isBusinessAccount => 
      accountType.toLowerCase() == 'business' || 
      accountType.toLowerCase() == 'empresarial';

  /// Verifica si es cuenta Community
  bool get isCommunityAccount => 
      accountType.toLowerCase() == 'community' || 
      accountType.toLowerCase() == 'comunidad';

  /// Verifica si es modo SelfHosted
  bool get isSelfHosted => 
      hostingMode.toLowerCase() == 'selfhosted' || 
      hostingMode.toLowerCase() == 'self_hosted' ||
      hostingMode.toLowerCase() == 'autoalojado';

  /// Verifica si es modo Cloud
  bool get isCloud => 
      hostingMode.toLowerCase() == 'cloud' || 
      hostingMode.toLowerCase() == 'nube';

  /// Verifica si la suscripcion esta activa
  bool get isSubscriptionActive {
    if (billingStatus.toLowerCase() != 'active') return false;
    if (subscriptionExpiry == null) return true; // Sin fecha de expiracion = activa
    return subscriptionExpiry!.isAfter(DateTime.now());
  }

  /// Verifica si la suscripcion ha expirado
  bool get isSubscriptionExpired {
    if (subscriptionExpiry == null) return false;
    return subscriptionExpiry!.isBefore(DateTime.now());

  }

  /// Dias restantes de suscripcion
  int? get daysRemaining {
    if (subscriptionExpiry == null) return null;
    final now = DateTime.now();
    if (subscriptionExpiry!.isBefore(now)) return 0;
    return subscriptionExpiry!.difference(now).inDays;
  }

  /// Verifica si tiene una caracteristica especifica
  bool hasFeature(String feature) {
    return features.any((f) => f.toLowerCase() == feature.toLowerCase());
  }

  /// Verifica si tiene caracteristicas premium
  bool get hasPremiumFeatures {
    return isBusinessAccount || 
           hasFeature('premium') || 
           hasFeature('pro');
  }

  /// Obtiene el nombre de display del tipo de cuenta
  String get accountTypeDisplay {
    switch (accountType.toLowerCase()) {
      case 'business':
      case 'empresarial':
        return 'Business';
      case 'community':
      case 'comunidad':
      default:
        return 'Community';
    }
  }

  /// Obtiene el nombre de display del modo de hosting
  String get hostingModeDisplay {
    switch (hostingMode.toLowerCase()) {
      case 'selfhosted':
      case 'self_hosted':
      case 'autoalojado':
        return 'Self-Hosted';
      case 'cloud':
      case 'nube':
      default:
        return 'Cloud';
    }
  }

  @override
  String toString() {
    return 'AccountUser(userId: $userId, type: $accountType, hosting: $hostingMode, status: $billingStatus)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AccountUser && other.userId == userId;
  }

  @override
  int get hashCode => userId.hashCode;
}
