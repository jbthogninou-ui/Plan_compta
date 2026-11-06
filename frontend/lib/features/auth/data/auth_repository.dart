import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/token_storage.dart';
import '../../../models/user.dart';

/// Couche d'accès API pour l'authentification.
/// Les écrans ne parlent jamais directement à Dio : ils passent par ce repository.
class AuthRepository {
  AuthRepository({required ApiClient apiClient, required TokenStorage tokenStorage})
      : _apiClient = apiClient,
        _tokenStorage = tokenStorage;

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<void> register({
    required String companyName,
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      await _apiClient.dio.post(
        ApiEndpoints.register,
        data: {
          'company_name': companyName,
          'email': email,
          'password': password,
          'full_name': fullName,
        },
        options: Options(extra: {'skipAuth': true}),
      );
    } on DioException catch (e) {
      throw ApiClient.toApiException(e);
    }
  }

  Future<void> login({required String email, required String password}) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.login,
        data: {'email': email, 'password': password},
        options: Options(extra: {'skipAuth': true}),
      );
      final tokens = AuthTokens.fromJson(response.data as Map<String, dynamic>);
      await _tokenStorage.saveTokens(accessToken: tokens.accessToken, refreshToken: tokens.refreshToken);
    } on DioException catch (e) {
      throw ApiClient.toApiException(e);
    }
  }

  Future<void> logout() => _tokenStorage.clear();

  Future<bool> get hasSession => _tokenStorage.hasSession;
}
