import 'dart:convert';

/// Lecture "best effort" du payload d'un JWT, uniquement pour affichage local
/// (ex. company_id). Ne remplace jamais la vérification de signature, qui
/// reste entièrement du ressort du backend.
class JwtDecoder {
  JwtDecoder._();

  static Map<String, dynamic>? payload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final normalized = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(normalized));
      return jsonDecode(decoded) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
