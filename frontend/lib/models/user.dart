enum UserRole { admin, accountant, viewer;

  static UserRole fromApi(String value) => UserRole.values.firstWhere(
        (e) => e.name == value,
        orElse: () => UserRole.viewer,
      );

  String get label {
    switch (this) {
      case UserRole.admin:
        return 'Administrateur';
      case UserRole.accountant:
        return 'Comptable';
      case UserRole.viewer:
        return 'Lecteur';
    }
  }

  /// Permissions dérivées du rôle — l'affichage seulement.
  /// La sécurité définitive reste appliquée côté backend.
  bool get canManageAccounting => this == UserRole.admin || this == UserRole.accountant;
  bool get canManageSettings => this == UserRole.admin;
}

class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.companyId,
  });

  final String id;
  final String email;
  final String fullName;
  final UserRole role;
  final String companyId;

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        email: json['email'] as String,
        fullName: json['full_name'] as String,
        role: UserRole.fromApi(json['role'] as String),
        companyId: json['company_id'] as String,
      );
}

class AuthTokens {
  const AuthTokens({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;

  factory AuthTokens.fromJson(Map<String, dynamic> json) => AuthTokens(
        accessToken: json['access_token'] as String,
        refreshToken: json['refresh_token'] as String,
      );
}
