import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../models/account.dart';

class AccountsRepository {
  AccountsRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<Account>> list() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.accounts);
      return (response.data as List).map((e) => Account.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiClient.toApiException(e);
    }
  }

  Future<Account> get(String id) async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.account(id));
      return Account.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.toApiException(e);
    }
  }

  Future<Account> create(Account draft) async {
    try {
      final response = await _apiClient.dio.post(ApiEndpoints.accounts, data: draft.toCreateJson());
      return Account.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.toApiException(e);
    }
  }
}
