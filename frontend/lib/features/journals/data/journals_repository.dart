import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../models/journal.dart';

class JournalsRepository {
  JournalsRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<Journal>> list() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.journals);
      return (response.data as List).map((e) => Journal.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiClient.toApiException(e);
    }
  }

  Future<Journal> create(Journal draft) async {
    try {
      final response = await _apiClient.dio.post(ApiEndpoints.journals, data: draft.toCreateJson());
      return Journal.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.toApiException(e);
    }
  }
}
