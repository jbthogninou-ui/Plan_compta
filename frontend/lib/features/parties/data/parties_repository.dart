import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../models/party.dart';

class PartiesRepository {
  PartiesRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<Party>> listCustomers() => _list(ApiEndpoints.customers);
  Future<List<Party>> listSuppliers() => _list(ApiEndpoints.suppliers);

  Future<Party> createCustomer(Party draft) => _create(ApiEndpoints.customers, draft);
  Future<Party> createSupplier(Party draft) => _create(ApiEndpoints.suppliers, draft);

  Future<List<Party>> _list(String path) async {
    try {
      final response = await _apiClient.dio.get(path);
      return (response.data as List).map((e) => Party.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiClient.toApiException(e);
    }
  }

  Future<Party> _create(String path, Party draft) async {
    try {
      final response = await _apiClient.dio.post(path, data: draft.toCreateJson());
      return Party.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.toApiException(e);
    }
  }
}
