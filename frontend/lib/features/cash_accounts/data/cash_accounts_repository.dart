import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../models/cash_account.dart';

class CashAccountsRepository {
  CashAccountsRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<CashAccount>> list() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.cashAccounts);
      return (response.data as List).map((e) => CashAccount.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiClient.toApiException(e);
    }
  }

  Future<CashAccount> create(CashAccount draft) async {
    try {
      final response = await _apiClient.dio.post(ApiEndpoints.cashAccounts, data: draft.toCreateJson());
      return CashAccount.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.toApiException(e);
    }
  }
}
