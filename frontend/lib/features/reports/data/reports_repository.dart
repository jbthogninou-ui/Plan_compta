import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../models/reports.dart';

class ReportsRepository {
  ReportsRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<TrialBalanceLine>> trialBalance() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.trialBalance);
      return (response.data as List).map((e) => TrialBalanceLine.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiClient.toApiException(e);
    }
  }

  Future<List<LedgerLine>> ledger({String? accountId}) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.ledger,
        queryParameters: accountId != null ? {'account_id': accountId} : null,
      );
      return (response.data as List).map((e) => LedgerLine.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiClient.toApiException(e);
    }
  }

  Future<BalanceSheet> balanceSheet() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.balanceSheet);
      return BalanceSheet.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.toApiException(e);
    }
  }

  Future<IncomeStatement> incomeStatement() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.incomeStatement);
      return IncomeStatement.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.toApiException(e);
    }
  }
}
