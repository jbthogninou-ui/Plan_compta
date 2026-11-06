import 'package:dio/dio.dart';

import 'api_endpoints.dart';
import 'api_exception.dart';
import 'token_storage.dart';

/// Client HTTP unique de l'application.
///
/// Toute la logique d'accès réseau (base URL, en-têtes, rafraîchissement de
/// token, normalisation des erreurs) vit ici. Les services de features ne
/// manipulent jamais Dio directement — ils passent par [ApiClient.dio].
class ApiClient {
  ApiClient({required TokenStorage tokenStorage})
      : _tokenStorage = tokenStorage,
        dio = Dio(
          BaseOptions(
            baseUrl: ApiEndpoints.baseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 20),
            headers: {'Content-Type': 'application/json'},
          ),
        ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final skipAuth = options.extra['skipAuth'] == true;
          if (!skipAuth) {
            final token = await _tokenStorage.accessToken;
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final isAuthCall = error.requestOptions.path.contains('/auth/');
          if (error.response?.statusCode == 401 && !isAuthCall) {
            final refreshed = await _tryRefresh();
            if (refreshed) {
              final retryRequest = await _retry(error.requestOptions);
              return handler.resolve(retryRequest);
            }
            await _tokenStorage.clear();
            onSessionExpired?.call();
          }
          handler.next(error);
        },
      ),
    );
  }

  final Dio dio;
  final TokenStorage _tokenStorage;

  /// Appelé quand le refresh token est lui-même invalide : l'UI doit renvoyer
  /// l'utilisateur vers l'écran de connexion.
  void Function()? onSessionExpired;

  bool _isRefreshing = false;
  Future<bool>? _refreshFuture;

  Future<bool> _tryRefresh() {
    if (_isRefreshing && _refreshFuture != null) return _refreshFuture!;
    _isRefreshing = true;
    _refreshFuture = _refresh().whenComplete(() => _isRefreshing = false);
    return _refreshFuture!;
  }

  Future<bool> _refresh() async {
    try {
      final refreshToken = await _tokenStorage.refreshToken;
      if (refreshToken == null) return false;

      final response = await dio.post(
        ApiEndpoints.refresh,
        data: {'refresh_token': refreshToken},
        options: Options(extra: {'skipAuth': true}),
      );

      final data = response.data as Map<String, dynamic>;
      await _tokenStorage.saveTokens(
        accessToken: data['access_token'] as String,
        refreshToken: data['refresh_token'] as String,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Response<dynamic>> _retry(RequestOptions requestOptions) async {
    final token = await _tokenStorage.accessToken;
    final options = Options(method: requestOptions.method, headers: {
      ...requestOptions.headers,
      'Authorization': 'Bearer $token',
    });
    return dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }

  /// Traduit une [DioException] en [ApiException] exploitable par l'UI.
  static ApiException toApiException(DioException error) {
    final response = error.response;
    if (response == null) {
      return ApiException(
        statusCode: null,
        message: 'Impossible de contacter le serveur. Vérifiez votre connexion.',
      );
    }

    final data = response.data;
    String message = 'Une erreur est survenue (${response.statusCode}).';
    Map<String, String>? fieldErrors;

    if (data is Map<String, dynamic>) {
      final detail = data['detail'];
      if (detail is String) {
        message = detail;
      } else if (detail is List) {
        // Erreurs de validation FastAPI/Pydantic : [{loc:[...], msg:...}, ...]
        fieldErrors = {};
        final messages = <String>[];
        for (final item in detail) {
          if (item is Map<String, dynamic>) {
            final loc = (item['loc'] as List?)?.whereType<String>().join('.') ?? '';
            final msg = item['msg']?.toString() ?? 'Champ invalide';
            if (loc.isNotEmpty) fieldErrors[loc] = msg;
            messages.add(msg);
          }
        }
        if (messages.isNotEmpty) message = messages.join('\n');
      }
    }

    return ApiException(statusCode: response.statusCode, message: message, fieldErrors: fieldErrors);
  }
}
