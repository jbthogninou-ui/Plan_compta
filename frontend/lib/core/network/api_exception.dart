/// Erreur API normalisée, construite à partir d'une réponse d'erreur du backend.
///
/// Le backend est la seule autorité de validation : cette classe se contente
/// de porter son message jusqu'à l'UI, elle ne réinterprète jamais la règle métier.
class ApiException implements Exception {
  ApiException({required this.statusCode, required this.message, this.fieldErrors});

  final int? statusCode;
  final String message;
  final Map<String, String>? fieldErrors;

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isValidationError => statusCode == 422 || statusCode == 400;
  bool get isNetworkError => statusCode == null;

  @override
  String toString() => message;
}
