import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../models/transaction.dart';

/// NOTE ARCHITECTURE : le backend V1 n'expose que `POST /transactions`.
/// Il n'y a pas encore de `GET /transactions` (liste) ni de `GET /journal-entries`
/// pour consulter l'écriture générée après coup. Cet écran ne peut donc
/// afficher que le résultat immédiat de la création — voir TODO_BACKEND.md.
class TransactionsRepository {
  TransactionsRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<AppTransaction> create(TransactionDraft draft) async {
    try {
      final response = await _apiClient.dio.post(ApiEndpoints.transactions, data: draft.toJson());
      return AppTransaction.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.toApiException(e);
    }
  }
}
